defmodule ResponseSnapshot do
  @moduledoc """
  ResponseSnapshot is a testing tool for Elixir that captures the output of responses
  and ensures that they do not change in between test runs. The output is saved to disk,
  meant to be checked into source control. This output can be used by frontend and other tests
  to ensure proper integration between frontend and backend code, or to ensure that endpoint
  responses do not change over time.

  ## Usage

  The most basic is a simple call to `store_and_compare!/2` as such:

  ```
    response_json
      |> ResponseSnapshot.store_and_compare!(path: "test/location/i/want/output.json")
  ```

  This will cause the output to be written to disk the first time, and then compared
  using exact match in all future tests.

  ## Options

  * path - The path of the fixture on disk
  * mode - The comparison mode of the diff algorithm. Values must be: :exact, :keys
  * ignored_keys - Keys to ignore during comparison. Can be exact or wildcard matches

  ## Application Config

  In addition to being able to set configuration for each call, certain configuration
  can be achieved using the Application module. The following options are available:

  * path_base - The base of the path that all fixture paths will be relative to
  * mode - Same as mode option
  * ignored_keys - Same as ignored_keys options; the lists are combined

  Option values passed into the `store_and_compare!/2` function are used over the
  Application config values.

  ## Comparison Modes

  The `store_and_compare!/2` interface has 2 different modes, exact and keys. The `:exact`
  mode is default and requires both key and value of the comparison to match the stored
  snapshot. The `:keys` mode requires only the keys of the comparison to match the stored
  snapshot. This can be useful in testing that the shape of an endpoint doesn't change
  over time, without worrying about the test input.

  ## Ignored Keys

  It is possible to ignore keys that will change between test runs. This is most common
  for dynamic fields such as ids, timestamps, etc. Ignored keys can be done via an exact
  string comparison, or a wildcard-like implementation.

  ```
    response_json
      |> ResponseSnapshot.store_and_compare!(path: path, ignored_keys: ["exact.example", {"partial", :any_nesting}])
  ```

  The exact.example key requires that the shape of the JSON is exact -> key. The partial key
  allows for matches such as "partial", "partial.nested", or "nested.partial".

  Ignored keys will only ignore value changes, not key additions or removals. This is
  due to an addition or removal affecting the output shape, which would go against the
  goals of this library.
  """

  alias ResponseSnapshot.{Changes, Config, Diff, FileManager, SnapshotMismatchError}

  @doc """
  Compares the data to an existing fixture, following the mode and ignored keys.
  If the fixture doesn't exist, it will be written and no asserts will occur.
  """
  @spec store_and_compare!(any(), Keyword.t()) :: any()
  def store_and_compare!(data, opts) do
    path = Config.get_path(opts)
    mode = Config.get_mode(opts)
    ignored_keys = Config.get_ignored_keys(opts)

    case FileManager.fixture_exists?(path) do
      true ->
        compare_existing_fixture(data, path: path, mode: mode, ignored_keys: ignored_keys)
      false ->
        FileManager.write_fixture(path, data: data)
    end

    data
  end

  defp compare_existing_fixture(data, path: path, mode: mode, ignored_keys: ignored_keys) do
    %{"data" => existing_data} = FileManager.read_fixture(path)

    changes =
      Diff.compare(data, existing_data)
      |> adjust_changes_for_mode(mode)
      |> adjust_changes_for_ignored_keys(ignored_keys)

    case changes == Changes.empty() do
      true ->
        :ok

      false ->
        raise SnapshotMismatchError,
          path: path,
          changes: changes,
          existing_data: existing_data,
          new_data: data
    end
  end

  defp adjust_changes_for_mode(changes, :exact), do: changes

  defp adjust_changes_for_mode(changes, :keys), do: changes |> Changes.clear(:modifications)

  defp adjust_changes_for_ignored_keys(changes, ignored_keys) when is_list(ignored_keys) do
    changes
    |> remove_ignored_keys_from_changes(:modifications, ignored_keys)
  end

  defp remove_ignored_keys_from_changes(changes, field, ignored_keys) do
    modified_list =
      Map.get(changes, field)
      |> Enum.reject(fn path ->
        Enum.find(ignored_keys, fn ignored_key ->
          ignored_key_matches_path?(ignored_key, path)
        end)
      end)

    Map.put(changes, field, modified_list)
  end

  defp ignored_key_matches_path?(ignored_key, path) when is_bitstring(ignored_key) do
    ignored_key == path
  end

  defp ignored_key_matches_path?({ignored_key, :any_nesting}, path) when is_bitstring(ignored_key) do
    # start of string or . followed by ignored key followed by . or end of string
    path =~ Regex.compile!("(^|\.)(#{ignored_key})(\.|$)")
  end
end

defmodule ResponseSnapshot do
  @moduledoc """
  ResponseSnapshot is a testing tool for Elixir that captures the output of responses
  and ensures that they do not change in between test runs. The output is saved to disk,
  meant to be checked into source control, and can be used by frontend and other tests
  to ensure proper integration between frontend and backend code.
  """

  alias ResponseSnapshot.{Changes, Diff, FileManager, SnapshotMismatchError}

  def store_and_compare!(data, opts) do
    path = Keyword.fetch!(opts, :path)
    mode = Keyword.get(opts, :mode, :exact)
    ignored_keys = Keyword.get(opts, :ignored_keys, [])

    case FileManager.fixture_exists?(path) do
      true ->
        compare_existing_fixture(data, path: path, mode: mode, ignored_keys: ignored_keys)
      false ->
        FileManager.write_fixture(path, data: data)
    end
  end

  defp compare_existing_fixture(data, path: path, mode: mode, ignored_keys: ignored_keys) do
    %{"data" => existing_data} = FileManager.read_fixture(path)

    changes =
      Diff.compare(data, existing_data)
        |> adjust_changes_for_mode(mode)
        |> adjust_changes_for_ignored_keys(ignored_keys)

    case changes == Changes.empty() do
      true -> :ok
      false -> raise SnapshotMismatchError, path: path, changes: changes, existing_data: existing_data, new_data: data
    end
  end

  defp adjust_changes_for_mode(changes, :exact), do: changes

  defp adjust_changes_for_mode(changes, :keys), do: changes |> Changes.clear(:modifications)

  defp adjust_changes_for_ignored_keys(changes, ignored_keys) when is_list(ignored_keys) do
    changes
      |> remove_ignored_keys_from_changes(:additions, ignored_keys)
      |> remove_ignored_keys_from_changes(:removals, ignored_keys)
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

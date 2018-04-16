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

    case FileManager.fixture_exists?(path) do
      true ->
        compare_existing_fixture(data, path: path, mode: mode)
      false ->
        FileManager.write_fixture(path, data: data)
    end
  end

  defp compare_existing_fixture(data, path: path, mode: mode) do
    %{"data" => existing_data} = FileManager.read_fixture(path)

    changes =
      Diff.compare(data, existing_data)
        |> adjust_changes_for_mode(mode: mode)

    case changes == Changes.empty() do
      true -> :ok
      false -> raise SnapshotMismatchError, path: path, changes: changes, existing_data: existing_data, new_data: data
    end
  end

  defp adjust_changes_for_mode(changes, mode: :exact), do: changes

  defp adjust_changes_for_mode(changes, mode: :keys), do: changes |> Changes.clear(:modifications)
end

defmodule ResponseSnapshot do
  @moduledoc """
  ResponseSnapshot is a testing tool for Elixir that captures the output of responses
  and ensures that they do not change in between test runs. The output is saved to disk,
  meant to be checked into source control, and can be used by frontend and other tests
  to ensure proper integration between frontend and backend code.
  """

  alias ResponseSnapshot.{Changes, Diff, FileManager, SnapshotMismatchError}

  def store_and_compare!(data, path: path) do
    case FileManager.fixture_exists?(path) do
      true ->
        compare_existing_fixture(data, path: path)
      false ->
        FileManager.write_fixture(path, data: data)
    end
  end

  defp compare_existing_fixture(data, path: path) do
    %{"data" => existing_data} = FileManager.read_fixture(path)
    changes = Diff.compare(data, existing_data)
    case changes == Changes.empty() do
      true -> :ok
      false -> raise SnapshotMismatchError, path: path, changes: changes
    end
  end
end

defmodule ResponseSnapshot do
  @moduledoc """
  ResponseSnapshot is a testing tool for Elixir that captures the output of responses
  and ensures that they do not change in between test runs. The output is saved to disk,
  meant to be checked into source control, and can be used by frontend and other tests
  to ensure proper integration between frontend and backend code.
  """

  alias ResponseSnapshot.FileManager

  def store_and_compare!(data, path: path) do
    case FileManager.fixture_exists?(path) do
      true -> nil
      false ->
        FileManager.write_fixture(path, data: data)
    end
  end
end

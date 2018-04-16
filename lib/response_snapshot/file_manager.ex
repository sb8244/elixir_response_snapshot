defmodule ResponseSnapshot.FileManager do
  @moduledoc false

  @doc """
  Writes a snapshot fixture to disk. The folder structure for the path will be
  created if it does not exist. The data will be encoded through Poison.
  """
  def write_fixture(path, data: data) do
    create_folder_structure!(path)
    File.write!(path, writeable_data(data))
  end

  @doc """
  Read a fixture from disk, returning the file contents as a map.
  """
  def read_fixture(path) do
    File.read!(path)
    |> Poison.decode!()
  end

  @doc """
  Remove the fixture from disk. The path hierarchy is not cleaned up.
  """
  def cleanup_fixture(path) do
    File.rm!(path)
  end

  @doc """
  Return whether a fixture exists or not
  """
  def fixture_exists?(path) do
    File.exists?(path)
  end

  defp create_folder_structure!(path) do
    path
    |> String.split("/")
    |> Enum.drop(-1)
    |> Enum.join("/")
    |> File.mkdir_p!()
  end

  defp writeable_data(data) do
    %{
      recorded_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      file: first_test_file_in_stacktrace(),
      data: data
    }
    |> Poison.encode!(pretty: true)
  end

  defp first_test_file_in_stacktrace() do
    Process.info(self(), :current_stacktrace)
    |> elem(1)
    |> Enum.map(fn {_mod, _fn, _, opts} ->
      Keyword.get(opts, :file) |> to_string()
    end)
    |> Enum.find(fn file ->
      String.contains?(file, "test/")
    end)
  end
end

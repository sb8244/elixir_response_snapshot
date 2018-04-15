defmodule ResponseSnapshot.FileManager do
  def write_fixture(path, data: data) do
    create_folder_structure!(path)
    File.write!(path, writeable_data(data))
  end

  def read_fixture(path) do
    File.read!(path)
      |> Poison.decode!()
  end

  def cleanup_fixture(path) do
    File.rm!(path)
  end

  defp create_folder_structure!(path) do
    path
      |> String.split("/")
      |> Enum.drop(-1)
      |> Enum.join("/")
      |> File.mkdir_p!
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

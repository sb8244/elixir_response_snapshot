defmodule ResponseSnapshot.SnapshotMismatchError do
  defexception fixture_path: nil, message: ""

  def exception(path: path, changes: _changes) do
    %__MODULE__{fixture_path: path, message: generate_message(path)}
  end

  defp generate_message(path) do
    """
    Your snapshot has changed and must be re-recorded to pass the current test.

    Your fixture is located at #{path}
    """
  end
end

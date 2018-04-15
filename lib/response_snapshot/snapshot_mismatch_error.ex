defmodule ResponseSnapshot.SnapshotMismatchError do
  defexception fixture_path: nil, message: ""

  def exception(path: path, changes: changes) do
    %__MODULE__{fixture_path: path, message: generate_message(path, changes)}
  end

  defp generate_message(path, changes) do
    """
    Your snapshot has changed and must be re-recorded to pass the current test.

    The following keys were added: #{Enum.join(changes.additions, ", ")}
    The following keys were removed: #{Enum.join(changes.removals, ", ")}
    The following keys were modified: #{Enum.join(changes.modifications, ", ")}

    Your fixture is located at #{path}
    """
  end
end

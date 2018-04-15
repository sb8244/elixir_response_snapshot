defmodule ResponseSnapshot.SnapshotMismatchError do
  defexception fixture_path: nil, message: ""

  def exception(path: path, changes: changes, existing_data: existing_data, new_data: new_data) do
    %__MODULE__{fixture_path: path, message: generate_message(path, changes, existing_data, new_data)}
  end

  defp generate_message(path, changes, existing_data, new_data) do
    """
    Your snapshot has changed and must be re-recorded to pass the current test.

    Existing Snapshot JSON:

    #{Poison.encode!(existing_data, pretty: true)}

    Attempted Snapshot JSON:

    #{Poison.encode!(new_data, pretty: true)}

    The following keys were added: #{Enum.join(changes.additions, ", ")}
    The following keys were removed: #{Enum.join(changes.removals, ", ")}
    The following keys were modified: #{Enum.join(changes.modifications, ", ")}

    Your fixture is located at #{path}
    """
  end
end

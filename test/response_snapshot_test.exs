defmodule ResponseSnapshotTest do
  use ExUnit.Case

  alias ResponseSnapshot.FileManager

  describe "store_and_compare!/2" do
    test "a new path writes the data to disk" do
      path = "test/fixtures/integration_new.json"
      %{a: 1, b: 2} |> ResponseSnapshot.store_and_compare!(path: path)

      %{"data" => %{"a" => 1, "b" => 2}} = FileManager.read_fixture(path)
      FileManager.cleanup_fixture(path)
    end

    test "an existing fixture which matches does not alter the file on disk nor raise" do
      path = "test/fixtures/integration_existing.json"
      original_fixture = FileManager.read_fixture(path)
      %{a: 1, b: 2} |> ResponseSnapshot.store_and_compare!(path: path)

      assert FileManager.read_fixture(path) == original_fixture
    end

    test "an existing fixture which does not match raises an error" do
      path = "test/fixtures/integration_existing.json"
      original_fixture = FileManager.read_fixture(path)

      err =
        assert_raise(ResponseSnapshot.SnapshotMismatchError, fn ->
          %{a: 1, b: "changed"} |> ResponseSnapshot.store_and_compare!(path: path)
        end)

      assert FileManager.read_fixture(path) == original_fixture
      assert err.message ==
        """
        Your snapshot has changed and must be re-recorded to pass the current test.

        Existing Snapshot:

        {
          "b": 2,
          "a": 1
        }

        Attempted Snapshot:

        {
          "b": "changed",
          "a": 1
        }

        The following keys were added:#{" "}
        The following keys were removed:#{" "}
        The following keys were modified: b

        Your fixture is located at test/fixtures/integration_existing.json
        """
    end
  end
end

defmodule ResponseSnapshotTest do
  use ExUnit.Case

  alias ResponseSnapshot.FileManager

  describe "store_and_compare!/2" do
    test "a new path writes the data to disk" do
      path = "test/fixtures/integration_new.json"
      %{a: 1, b: 2}
        |> ResponseSnapshot.store_and_compare!(path: path)

      %{"data" => %{"a" => 1, "b" => 2}} = FileManager.read_fixture(path)
      FileManager.cleanup_fixture(path)
    end
  end
end

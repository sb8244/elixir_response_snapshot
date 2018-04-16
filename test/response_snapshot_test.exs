defmodule ResponseSnapshotTest do
  use ExUnit.Case

  alias ResponseSnapshot.FileManager

  @existing_snapshot_path "test/fixtures/integration_existing.json"
  @complex_snapshot_path "test/fixtures/integration_complex.json"

  describe "store_and_compare!/2" do
    test "a new path writes the data to disk" do
      path = "test/fixtures/integration_new.json"
      %{a: 1, b: 2} |> ResponseSnapshot.store_and_compare!(path: path)

      %{"data" => %{"a" => 1, "b" => 2}} = FileManager.read_fixture(path)
      FileManager.cleanup_fixture(path)
    end

    test "an existing fixture which matches does not alter the file on disk nor raise" do
      path = @existing_snapshot_path
      original_fixture = FileManager.read_fixture(path)
      %{a: 1, b: 2} |> ResponseSnapshot.store_and_compare!(path: path)

      assert FileManager.read_fixture(path) == original_fixture
    end

    test "an existing fixture which does not match raises an error" do
      path = @existing_snapshot_path
      original_fixture = FileManager.read_fixture(path)

      err =
        assert_raise(ResponseSnapshot.SnapshotMismatchError, fn ->
          %{a: 1, b: "changed"} |> ResponseSnapshot.store_and_compare!(path: path)
        end)

      assert FileManager.read_fixture(path) == original_fixture
      assert err.message ==
        """
        Your snapshot has changed and must be re-recorded to pass the current test.

        Existing Snapshot JSON:

        {
          "b": 2,
          "a": 1
        }

        Attempted Snapshot JSON:

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

    test "mode=keys cause a modification to not error" do
      %{a: 1, b: "changed"} |> ResponseSnapshot.store_and_compare!(path: @existing_snapshot_path, mode: :keys)
    end

    test "mode=keys cause an addition to error" do
      err =
        assert_raise(ResponseSnapshot.SnapshotMismatchError, fn ->
          %{a: 1, b: 2, c: 3} |> ResponseSnapshot.store_and_compare!(path: @existing_snapshot_path)
        end)

      assert err.message =~ "were added: c"
    end

    test "mode=keys cause a removal to error" do
      err =
        assert_raise(ResponseSnapshot.SnapshotMismatchError, fn ->
          %{a: 1} |> ResponseSnapshot.store_and_compare!(path: @existing_snapshot_path)
        end)

      assert err.message =~ "were removed: b"
    end

    test "ignored_keys cause any modification to not be counted, but additions and removals still are" do
      err =
        assert_raise(ResponseSnapshot.SnapshotMismatchError, fn ->
          %{b: "changed", c: "added"} |> ResponseSnapshot.store_and_compare!(path: @existing_snapshot_path, ignored_keys: ["a", "b", "c"])
        end)

      assert err.message =~ "were added: c\n"
      assert err.message =~ "were removed: a\n"
      assert err.message =~ "were modified: \n"
    end

    test "keys not ignored are still an error" do
      err =
        assert_raise(ResponseSnapshot.SnapshotMismatchError, fn ->
          %{b: "changed", c: "added", d: "oops"}
            |> ResponseSnapshot.store_and_compare!(path: @existing_snapshot_path, ignored_keys: ["a", "b", "c"])
        end)

      assert err.message =~ "were added: d"
    end

    test "ignored_keys which match the start of a path are not ignored" do
      err =
        assert_raise(ResponseSnapshot.SnapshotMismatchError, fn ->
          %{
            map: %{
              a: 2,
              b: [1, 2]
            },
            list: [1, %{a: 1}]
          } |> ResponseSnapshot.store_and_compare!(path: @complex_snapshot_path, ignored_keys: ["map"])
        end)

      assert err.message =~ "were modified: map.a"
    end

    test "map wildcards can be used to ignore any key no matter how it's nested" do
      %{
        map: %{
          a: 2,
          b: [1, 2]
        },
        list: [1, %{a: 1}]
      } |> ResponseSnapshot.store_and_compare!(path: @complex_snapshot_path, ignored_keys: [{"a", :any_nesting}])
    end
  end
end

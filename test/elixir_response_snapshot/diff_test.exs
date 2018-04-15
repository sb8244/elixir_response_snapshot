defmodule ElixirResponseSnapshot.DiffTest do
  use ExUnit.Case, async: true

  alias ElixirResponseSnapshot.Diff
  alias ElixirResponseSnapshot.Changes

  describe "compare/2 with simple maps" do
    test "two empty maps are identical" do
      assert Diff.compare(%{}, %{}) == Changes.empty()
    end

    test "a mismatch key appears as a diff and add" do
      assert Diff.compare(%{a: 1}, %{b: 2}) ==
        Changes.empty()
          |> Changes.addition("a")
          |> Changes.removal("b")
    end

    test "a modified key appears as a modification" do
      assert Diff.compare(%{a: 1}, %{a: 2}) ==
        Changes.empty()
          |> Changes.modification("a")
    end

    test "multiple map keys are iterated" do
      assert Diff.compare(%{a: 1, b: 2, in_source: true, another: true}, %{a: 2, b: 2, in_target: true}) ==
        Changes.empty()
          |> Changes.modification("a")
          |> Changes.addition("another")
          |> Changes.addition("in_source")
          |> Changes.removal("in_target")
    end
  end

  describe "compare/2 with nested maps" do
    test "two nested maps are identical" do
      assert Diff.compare(%{a: %{b: 1}}, %{a: %{b: 1}}) == Changes.empty()
    end

    test "two nested maps have a modification, addition, and removal" do
      assert Diff.compare(%{a: %{b: 1, in_source: true}}, %{a: %{b: 2, in_target: true}}) == Changes.empty()
        |> Changes.modification("a.b")
        |> Changes.addition("a.in_source")
        |> Changes.removal("a.in_target")
    end

    test "2 mismatch maps with an additional nesting layer have the entire set of changes enumerated" do
      assert Diff.compare(%{a: %{a: %{b: 1, in_source: true}}}, %{a: %{b: 2, in_target: true}}) ==
        Changes.empty()
          |> Changes.addition("a.a")
          |> Changes.removal("a.b")
          |> Changes.removal("a.in_target")
    end

    test "2 maps can be deeply nested" do
      assert Diff.compare(%{a: %{a: %{b: 1, in_source: true}}}, %{a: %{a: %{b: 2, in_target: true}}}) ==
        Changes.empty()
          |> Changes.modification("a.a.b")
          |> Changes.addition("a.a.in_source")
          |> Changes.removal("a.a.in_target")
    end
  end

  describe "compare/2 with lists" do
    test "two empty lists are identical" do
      assert Diff.compare([], []) == Changes.empty()
    end

    test "two equal lists are identical" do
      assert Diff.compare([1, 2, 3], [1, 2, 3]) == Changes.empty()
    end

    test "a value in source but not target is an addition" do
      assert Diff.compare([1], []) ==
        Changes.empty()
          |> Changes.addition("0")
    end

    test "a map in source but not target is an addition" do
      assert Diff.compare([%{a: 1}], []) ==
        Changes.empty()
          |> Changes.addition("0")
    end

    test "a value in target but not source is a removal" do
      assert Diff.compare([], [1]) ==
        Changes.empty()
          |> Changes.removal("0")
    end

    test "multiple values in target but not source are removals" do
      assert Diff.compare([1, 2, 3], [1, 2, 3, 4, 5]) ==
        Changes.empty()
          |> Changes.removal("3")
          |> Changes.removal("4")
    end

    test "nested lists can compute their own additions" do
      assert Diff.compare([1, [2]], [1, []]) ==
        Changes.empty()
          |> Changes.addition("1_0")
    end

    test "different maps compute their own changes" do
      assert Diff.compare([%{a: 1}], [%{b: 2}]) ==
        Changes.empty()
          |> Changes.addition("0.a")
          |> Changes.removal("0.b")
    end
  end

  describe "compare/2" do
    test "primitive (not map and not list) values are computed directly" do
      assert Diff.compare(1, 1) == Changes.empty()
      assert Diff.compare(1, 2) == Changes.empty() |> Changes.modification("")

      assert Diff.compare("a", "a") == Changes.empty()
      assert Diff.compare("a", "b") == Changes.empty() |> Changes.modification("")
    end

    test "a complex map structure calculates correctly" do
      a = %{
        a: [1, 2],
        b: [1, 2, %{additional: true}, "another"],
        c: %{
          a: 1,
          b: 2,
        },
        d: "only in source",
        f: ["a", 2]
      }

      b = %{
        a: [1, 2],
        b: [1, 2, %{}],
        c: %{
          a: 2,
          b: 2
        },
        e: "only in target",
        f: [1]
      }

      assert Diff.compare(a, b) ==
        Changes.empty()
          |> Changes.addition("b_2.additional")
          |> Changes.addition("b_3")
          |> Changes.modification("c.a")
          |> Changes.addition("d")
          |> Changes.removal("e")
          |> Changes.modification("f_0")
          |> Changes.addition("f_1")
    end
  end
end

defmodule ResponseSnapshot.Changes do
  @moduledoc """
  Structure for changes of a diff. An object which is completely identical will
  be equal to `Changes.empty()`. Any modifications, additions, and removals are
  accessible from this struct.

  Object traversal is notated with a `.`. Array traversal is notated with an `_`.
  For example, the follow would indicate that key "a" (list), index 1 was added:
  additions: ["a_1"].
  """

  @enforce_keys [:additions, :removals, :modifications]

  @doc """
  Defines the Changes struct:

  * additions - Paths that were added versus what is stored in the fixture
  * removals - Paths that were removed versus what is stored in the fixture
  * modified - Paths that were modified versus what is stored in the fixture
  * mode - Internal function helper, should always be nil
  """
  defstruct @enforce_keys ++ [mode: nil]

  @doc false
  def empty() do
    %__MODULE__{additions: [], removals: [], modifications: []}
  end

  @doc false
  def addition(changes = %{additions: additions}, path) do
    new = List.flatten([path | additions])
    Map.put(changes, :additions, new)
  end

  @doc false
  def removal(changes = %{removals: removals}, path) do
    new = List.flatten([path | removals])
    Map.put(changes, :removals, new)
  end

  @doc false
  def modification(changes = %{modifications: modifications}, path) do
    new = List.flatten([path | modifications])
    Map.put(changes, :modifications, new)
  end

  @doc false
  def clear(changes, :modifications) do
    Map.put(changes, :modifications, [])
  end

  @doc false
  def set_mode(changes, mode) when mode in [:addition, :removal, :modification, nil] do
    Map.put(changes, :mode, mode)
  end

  @doc false
  def insert_by_mode(changes = %{mode: :addition}, path), do: addition(changes, path)
  def insert_by_mode(changes = %{mode: :removal}, path), do: removal(changes, path)
  def insert_by_mode(changes = %{mode: :modification}, path), do: modification(changes, path)
  def insert_by_mode(changes = %{mode: nil}, path), do: modification(changes, path)
end

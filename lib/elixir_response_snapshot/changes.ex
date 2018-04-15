defmodule ElixirResponseSnapshot.Changes do
  @enforce_keys [:additions, :removals, :modifications]
  defstruct @enforce_keys ++ [mode: nil]

  def empty() do
    %__MODULE__{additions: [], removals: [], modifications: []}
  end

  def set_mode(changes, mode) when mode in [:addition, :removal, :modification, nil] do
    Map.put(changes, :mode, mode)
  end

  def insert_by_mode(changes = %{mode: :addition}, path), do: addition(changes, path)
  def insert_by_mode(changes = %{mode: :removal}, path), do: removal(changes, path)
  def insert_by_mode(changes = %{mode: :modification}, path), do: modification(changes, path)
  def insert_by_mode(changes = %{mode: nil}, path), do: modification(changes, path)

  def addition(changes = %{additions: additions}, path) do
    new = List.flatten([path | additions])
    Map.put(changes, :additions, new)
  end

  def removal(changes = %{removals: removals}, path) do
    new = List.flatten([path | removals])
    Map.put(changes, :removals, new)
  end

  def modification(changes = %{modifications: modifications}, path) do
    new = List.flatten([path | modifications])
    Map.put(changes, :modifications, new)
  end
end

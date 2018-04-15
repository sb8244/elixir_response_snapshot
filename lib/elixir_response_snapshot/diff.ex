defmodule ElixirResponseSnapshot.Diff do
  defmodule Changes do
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

  def compare(testing_value, historical_value) do
    compare(testing_value, historical_value, Changes.empty(), "")
  end

  # base case, identical values aren't different
  defp compare(source, source, changes = %Changes{}, _path), do: changes

  # recursive map comparison
  defp compare(source, target, changes = %Changes{}, path) when is_map(source) and is_map(target) do
    source_to_target_changes =
      Enum.reduce(source, changes, fn {key, source_value}, changes ->
        case Map.has_key?(target, key) do
          true ->
            target_value = Map.get(target, key)
            compare(source_value, target_value, Changes.set_mode(changes, :modification), build_path(path, key))
              |> Changes.set_mode(nil)
          false ->
            Changes.addition(changes, build_path(path, key))
        end
      end)

    Enum.reduce(target, source_to_target_changes, fn {key, _value}, changes ->
      case Map.has_key?(source, key) do
        true ->
          changes
        false ->
          Changes.removal(changes, build_path(path, key))
      end
    end)
  end

  # recursive list comparison
  defp compare(source, target, changes = %Changes{}, path) when is_list(source) and is_list(target) do
    source_to_target_changes =
      source
      |> Enum.with_index()
      |> Enum.reduce(changes, fn {source_value, index}, changes ->
        case Enum.at(target, index, :__missing_list_entry__) do
          :__missing_list_entry__ ->
            Changes.addition(changes, build_path(path, index, "_"))
          target_value ->
            compare(source_value, target_value, Changes.set_mode(changes, :modification), build_path(path, index, "_"))
              |> Changes.set_mode(nil)
        end
      end)

    case length(target) - length(source) do
      ignorable when ignorable <= 0 -> source_to_target_changes
      removal_count ->
        start_index = length(source) - 1
        Enum.reduce((1..removal_count), source_to_target_changes, fn removal_index, changes ->
          Changes.removal(changes, build_path(path, removal_index + start_index, "_"))
        end)
    end
  end

  defp compare(source, target, changes = %Changes{}, path) when source != target do
    Changes.insert_by_mode(changes, path)
  end

  defp build_path("", key), do: "#{key}"
  defp build_path(path, key), do: "#{path}.#{key}"
  defp build_path("", key, _), do: "#{key}"
  defp build_path(path, key, separator), do: "#{path}#{separator}#{key}"
end

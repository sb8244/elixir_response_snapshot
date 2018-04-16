defmodule ResponseSnapshot.Diff do
  @moduledoc false

  alias ResponseSnapshot.Changes

  @doc """
  Algorithm to compare a source and target value. The value can either be a primitive,
  map, or a list. The intent of this module is that JSON notation values are passed in.
  However, non-JSON compatible values may work correctly with this algorithm (such as
  keyword lists).

  A Changes struct is returned with the result of the comparison.
  """
  def compare(source, target) do
    compare(source, target, Changes.empty(), "")
  end

  defguardp both_are_maps(source, target) when is_map(source) and is_map(target)
  defguardp both_are_lists(source, target) when is_list(source) and is_list(target)

  # base case, identical values aren't different
  defp compare(source, source, changes = %Changes{}, _path), do: changes

  # recursive map comparison
  defp compare(source, target, changes = %Changes{}, path) when both_are_maps(source, target) do
    compare_keyword_lists(Map.to_list(source), Map.to_list(target), changes, path)
  end

  # recursive list comparison
  defp compare(source, target, changes = %Changes{}, path) when both_are_lists(source, target) do
    case Keyword.keyword?(source) && Keyword.keyword?(target) do
      true ->
        compare_keyword_lists(source, target, changes, path)
      false ->
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
  end

  # primitive value comparison
  defp compare(source, target, changes = %Changes{}, path) when source != target do
    Changes.insert_by_mode(changes, path)
  end

  # Keyword lists cover both maps (converted to lists) and tuple lists
  defp compare_keyword_lists(source, target, changes = %Changes{}, path) do
    source = atomize_keyword_list(source)
    target = atomize_keyword_list(target)

    source_to_target_changes =
      Enum.reduce(source, changes, fn {key, source_value}, changes ->
        case Keyword.has_key?(target, key) do
          true ->
            target_value = Keyword.get(target, key)
            compare(source_value, target_value, Changes.set_mode(changes, :modification), build_path(path, key))
              |> Changes.set_mode(nil)
          false ->
            Changes.addition(changes, build_path(path, key))
        end
      end)

    Enum.reduce(target, source_to_target_changes, fn {key, _value}, changes ->
      case Keyword.has_key?(source, key) do
        true ->
          changes
        false ->
          Changes.removal(changes, build_path(path, key))
      end
    end)
  end

  defp build_path("", key), do: "#{key}"
  defp build_path(path, key), do: "#{path}.#{key}"
  defp build_path("", key, _), do: "#{key}"
  defp build_path(path, key, separator), do: "#{path}#{separator}#{key}"

  defp atomize_keyword_list(list), do: Enum.map(list, fn {key, value} -> {to_atom(key), value} end)

  defp to_atom(a) when is_atom(a), do: a
  defp to_atom(s) when is_bitstring(s), do: String.to_atom(s)
end

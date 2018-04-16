defmodule ResponseSnapshot.Config do
  @moduledoc """
  Configuration for ResponseSnapshot is managed here. The following Application env
  configs are available:

  * path_base - The base of the path that all fixture paths will be relative to
  * mode - Same as mode option
  * ignored_keys - Same as ignored_keys options; the lists are combined

  Option values passed into the `store_and_compare!` function are used over the
  Application config values.
  """

  @config_key :response_snapshot

  @doc false
  def get_mode(opts) do
    Keyword.get(opts, :mode, Application.get_env(@config_key, :mode, :exact))
  end

  @doc false
  def get_path(opts) do
    path = Keyword.fetch!(opts, :path)
    path_base = Application.get_env(@config_key, :path_base, ".")
    Path.expand(path, path_base)
  end

  @doc false
  def get_ignored_keys(opts) do
    ignored_keys = Keyword.get(opts, :ignored_keys, [])
    Application.get_env(@config_key, :ignored_keys, []) ++ ignored_keys
  end
end

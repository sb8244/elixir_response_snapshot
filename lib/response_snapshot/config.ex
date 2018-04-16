defmodule ResponseSnapshot.Config do
  @moduledoc false

  @config_key :response_snapshot

  def get_mode(opts) do
    Keyword.get(opts, :mode, Application.get_env(@config_key, :mode, :exact))
  end

  def get_path(opts) do
    path = Keyword.fetch!(opts, :path)
    path_base = Application.get_env(@config_key, :path_base, ".")
    Path.expand(path, path_base)
  end

  def get_ignored_keys(opts) do
    ignored_keys = Keyword.get(opts, :ignored_keys, [])
    Application.get_env(@config_key, :ignored_keys, []) ++ ignored_keys
  end
end

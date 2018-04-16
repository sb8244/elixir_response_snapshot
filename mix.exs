defmodule ResponseSnapshot.MixProject do
  use Mix.Project

  def project do
    [
      app: :response_snapshot,
      version: "0.1.0",
      elixir: "~> 1.6",
      description: description(),
      package: package(),
      deps: deps(),
      name: "Response Snapshot",
      source_url: github_url()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 2.2 or ~> 3.0"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end

  defp description() do
    """
    ResponseSnapshot is a testing tool for Elixir that captures the output of responses
    and ensures that they do not change in between test runs.
    """
  end

  defp github_url() do
    "https://github.com/sb8244/elixir_response_snapshot"
  end

  defp package() do
    [
      # These are the default files included in the package
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Stephen Bussey (sb8244)"],
      licenses: ["MIT"],
      links: %{"GitHub" => github_url()}
    ]
  end
end

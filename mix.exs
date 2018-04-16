defmodule ResponseSnapshot.MixProject do
  use Mix.Project

  def project do
    [
      app: :response_snapshot,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
end

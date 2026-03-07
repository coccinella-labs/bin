defmodule PipelineBin.MixProject do
  use Mix.Project

  def project do
    [
      app: :pipeline_bin,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {PipelineBin.Application, []}
    ]
  end

  defp deps do
    [
      {:broadway, "~> 1.2"},
      {:nimble_csv, "~> 1.3"},
      {:oban, "~> 2.20"}
    ]
  end
end

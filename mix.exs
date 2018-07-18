defmodule Benny.Mixfile do
  use Mix.Project

  def project do
    [
      app: :benny,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Benny.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.2"},
      {:gen_state_machine, "~> 2.0"},
      {:stream_data, "~> 0.3", only: :test}
    ]
  end
end

defmodule CharonAbsinthe.MixProject do
  use Mix.Project

  def project do
    [
      app: :charon_absinthe,
      version: "0.0.0+development",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      description: """
      Absinthe integration for Charon.
      """,
      package: [
        licenses: ["Apache-2.0"],
        links: %{github: "https://github.com/weareyipyip/charon_absinthe"},
        source_url: "https://github.com/weareyipyip/charon_absinthe"
      ],
      source_url: "https://github.com/weareyipyip/charon_absinthe",
      name: "CharonAbsinthe",
      docs: [
        source_ref: "main",
        extras: ["./README.md"],
        main: "readme"
      ]
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
      {:ex_doc, "~> 0.21", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 1.0", only: [:dev], runtime: false},
      {:absinthe_plug, "~> 1.0"},
      {:charon, "~> 1.0-beta"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end

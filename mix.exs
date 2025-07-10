defmodule HeadlineMaker.MixProject do
  use Mix.Project

  def project do
    [
      app: :headline_maker,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: HeadlineMaker]
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
      {:httpoison, "~> 1.8.2"},
      {:quinn, "~> 1.1.3"},
      {:readability2, git: "https://github.com/rrcook/readability2"},
      {:prodigy_objects, git: "https://github.com/rrcook/prodigy_objects.git"},
      {:naplps_writer, git: "https://github.com/rrcook/naplps_writer.git"}
    ]
  end
end

defmodule ConfexParameterStore.MixProject do
  use Mix.Project

  @name "Confex Parameter Store Adapter"
  @version "1.1.0"
  @url "https://github.com/gpedic/confex_parameter_store"

  def project do
    [
      name: @name,
      app: :confex_parameter_store,
      version: @version,
      elixir: "~> 1.4",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      description: description(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test]
    ]
  end

  defp package() do
    [
      licenses: ["MIT"],
      maintainers: [
        "Goran Pedić"
      ],
      links: %{
        "GitHub" => @url
      }
    ]
  end

  defp docs() do
    [
      main: @name,
      source_ref: "v#{@version}",
      source_url: @url,
      extras: [
        "README.md"
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
      {:ex_doc, ">= 0.16.0", only: :dev, runtime: false},
      {:excoveralls, ">= 0.7.0", only: [:dev, :test]},
      {:confex, "~> 3.0"},
      {:ex_aws_ssm, "~> 2.0"},
      {:poison, "~> 3.0"},
      {:hackney, "~> 1.9"}
    ]
  end

  defp description do
    """
    An adapter for Confex to add support for fetching config values from the AWS Parameter Store.
    """
  end
end

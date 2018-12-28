defmodule Confex.Adapters.ParameterStore do
  @moduledoc """
  A [Confex](https://github.com/Nebo15/confex) adapter for [AWS Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html).

  This adapter allows us to retrieve parameters at runtime via their parameter store
  paths specified in system environment variables.

  Also check out the [Confex Documentation](https://hexdocs.pm/confex/readme.html)
  for more info on Confex itself.

  # Usage

  To have Confex fetch a value from the Parameter Store define your config value
  this adapter by defining it as a tuple `{:via, Confex.Adapters.ParameterStore}`.

  ```elixir
  alias Confex.Adapters.ParameterStore

  config :app, Example.Repo,
    adapter: Ecto.Adapters.Postgres,
    url: {{:via, ParameterStore}, "DB_URL"}

  config :app, Example.ApiClient,
    api_key: {{:via, ParameterStore}, "API_KEY"}
  ```

  The environment variables in turn contain the path of the parameter store value prefixed by `parameter:`.

  ```bash
  # will be fetched from parameter store
  DB_URL="parameter:/app/prod/db/url"
  API_KEY="parameter:/app/prod/api_key"
  ```

  ```elixir
  iex> Confex.fetch_env(:app, Example.Repo)
  {:ok, [url: "ecto://postgres:postgres@localhost:5432/exampledb?ssl=false&pool_size=2"]}

  iex> Confex.fetch_env!(:app, Example.ApiClient)
  [api_key: "dTmIczHsTcyrbL0lBbJY"]
  ```

  Any environment variables no prefixed by `parameter:` will be fetched as values the same
  way as if we defined them as `{:system, "ENV_NAME"}`, thus allowing us to for example set up dev
  enviromentes that don't use parameter store while still using environment variables.

  In other words if we exchage above parameter store paths with their actual values it would work
  just fine.

  ```bash
  DB_URL="ecto://postgres:postgres@localhost:5432/exampledb?ssl=false&pool_size=2"
  API_KEY="dTmIczHsTcyrbL0lBbJY"
  ```

  ```elixir
  iex> Confex.fetch_env(:app, Example.Repo)
  {:ok, [url: "ecto://postgres:postgres@localhost:5432/exampledb?ssl=false&pool_size=2"]}

  iex> Confex.fetch_env!(:app, Example.ApiClient)
  [api_key: "dTmIczHsTcyrbL0lBbJY"]
  ```

  # Hierarchies

  Following the [best practices layed out by AWS](https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-walk-hierarchies.html),
  and defining parameters hierarchically allows us to easily allow access to a whole parameter tree
  or restrict access to certain parts of a tree.

  As an example we can imagine an application deployed to different EC2 instances acting
  as separate deploy environments. We can create instance roles which allow access to
  certain trees like `/app/prod/*`, `/app/staging/*`, `/app/demo/*` depending on environment.

  # Caching

  Be sure to cache the returned value in some way if you retrieve it often and don't want
  the overhead of a http request as every time it is read a request will be made to AWS.
  """

  @provider Application.get_env(
              :confex_parameter_store,
              :provider,
              Confex.ParameterStore.ProviderImpl
            )

  @doc """
  Fetch value from the Parameter Store which path is specified in an environment variable.
  """
  @spec fetch_value(binary) :: {:ok, any()} | :error
  def fetch_value(key) do
    System.get_env(key)
    |> fetch_parameter
  end

  @spec fetch_parameter(binary) :: {:ok, binary} | :error
  defp fetch_parameter("parameter:" <> path), do: @provider.get_parameter(path)
  defp fetch_parameter("parameters_by_path:" <> path), do: @provider.get_parameters_by_path(path)
  defp fetch_parameter(value) when is_binary(value), do: {:ok, value}
  defp fetch_parameter(_), do: :error
end

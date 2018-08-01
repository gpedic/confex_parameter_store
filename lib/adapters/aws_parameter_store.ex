
defmodule Confex.ParameterStore.Adapter do
  use Confex.CachedAdapter, otp_app: :confex

  @cache Confex.ParameterStore.Cache
  @moduledoc """
  A [Confex](https://github.com/Nebo15/confex) adapter for [AWS Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html).

  This adapter allows us to retrieve parameters at runtime via their parameter store paths specified in system environment variables.

  Also check out the [Confex Documentation](https://hexdocs.pm/confex/readme.html) for more info on Confex itself.

  # Usage

  To make Confex fetch a value from the Parameter Store define your config value this adapter by defining it
  as a tuple `{:via, Confex.Adapters.ParameterStore}`.
  The example below shows how one would use it for retrieving datase configuration.

  ```elixir
  alias Confex.Adapters.ParameterStore

  config :backend, Example.Repo,
    adapter: Ecto.Adapters.Postgres,
    username: {{:via, ParameterStore}, "DB_USERNAME", "postgres"},
    password: {{:via, ParameterStore}, "DB_PASSWORD", "postgres"},
    database: {{:via, ParameterStore}, "DB_NAME", "enroll-dev"},
    hostname: {{:via, ParameterStore}, "DB_HOSTNAME", "localhost"},
    port: {{:via, ParameterStore}, :integer, "DB_PORT", 5432},
    pool_size: {:system, :integer, "DB_POOL_SIZE", 20}
  ```

  The environment variables contain the path of the parameter store value prefixed by `parameter:`.

  ```bash
  # will be fetched from parameter store
  DB_USERNAME="parameter:/app/prod/db/user"
  DB_PASSWORD="parameter:/app/prod/db/pass"

  # would be used as is
  DB_HOSTNAME="localhost"
  ```

  Parameter Store values are defined in a hierarchical fashion following [best practices defined by AWS](https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-walk-hierarchies.html),
  this allows us to restrict access up to a certain depth or to a certain branch only.

  For example EC2 instances where an application is deployed can be given access to only parameters defined under a path like `/app/prod/` or `/app/staging/`.

  Value not prefixed by `parameter:` are treated as regular string values and simply passed through the same as when using `:system`.


  # Caching

  In order not to have to fetch values from AWS every time they're requested we use a simple GenServer `Confex.Cache` to cache retrieved values
  in a map inside it's state. This effectively gives us a very simple in-memory key value store.
  """

  @doc """
  Fetch value from the Parameter Store which path is specified in an environment variable.

  ## Example

      iex> :ok = System.delete_env("PARAMETER_STORE_TEST_PATH")
      ...> :error = #{__MODULE__}.fetch_value("PARAMETER_STORE_TEST_PATH")
      ...> :ok = System.put_env("PARAMETER_STORE_TEST_PATH", "parameter:/app/path")
      ...> {:ok, "foo_bar"} = #{__MODULE__}.fetch_value("SOME_TEST_FILE")
      {:ok, "foo_bar"}
  """
  @spec fetch_value(binary) :: {:ok, binary} | :error
  def fetch_value(key) do
    value = System.get_env(key)

    cond do
      is_nil(value) -> :error
      is_parameter?(value) ->
        trim_parameter(value)
        |> fetch_parameter()
      value -> {:ok, value}
    end
  end

  @doc """
  Fetch value from the Parameter Store which path is specified in an environment variable.

  Currently only used by Guardian config
  """
  def fetch_value!(key) do
    case fetch_value(key) do
      {:ok, val} -> val
      :error -> raise "ParameterStore error: Cannot retrieve #{key}"
    end
  end

  @spec is_parameter?(binary) :: boolean
  defp is_parameter?(path) do
    path |> String.starts_with?("parameter:")
  end

  @spec trim_parameter(binary) :: binary
  defp trim_parameter(path) do
    path |> String.trim_leading("parameter:")
  end

  defp fetch_parameter(param_path) do
    param_value = case @cache.get(param_path) do
      nil -> Confex.Providers.ParameterStore.get_parameter(param_path)
      param -> param
    end

    case param_value do
      {:ok, value} -> {:ok, @cache.put(param_path, value)}
      value when is_binary(value) -> {:ok, value}
      _else -> :error
    end
  end
end

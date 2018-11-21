# Confex Parameter Store Adapter

This adapter allows Confex to fetch parameters from the [AWS Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `confex_parameter_store` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:confex_parameter_store, "~> 1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/confex_parameter_store](https://hexdocs.pm/confex_parameter_store).

## Testing
To run integration tests run the included `docker-compose.yml` using `docker-compose up`, this will start a local AWS SSM at `localhost:4583` using [localstack](https://github.com/localstack/localstack).
Now we can include integration tests by running `mix test` as:
```
$ mix test --include external:true
```

## Usage

Usage is the same as described in the original [Confex Usage section](https://github.com/Nebo15/confex#usage), we simply use the provided adapter.

```elixir
config :my_app, MyApp.MyQueue,
  queue: [
    name: {{:via, Confex.Adapters.ParameterStore}, :string, "OUT_QUEUE_NAME", "MyQueueOut"},
    routing_key: {{:via, Confex.Adapters.ParameterStore}, "OUT_ROUTING_KEY", ""},
    port: {{:via, Confex.Adapters.ParameterStore}, :integer, "OUT_PORT", 1234},
  ]
```

The content of the ENV variables has to contain the prefix `parameter:`

```
OUT_QUEUE_NAME=parameter:/queue/name
OUT_PORT=parameter:/queue/out/port
OUT_ROUTING_KEY=parameter:/queue/out/routing_key
```
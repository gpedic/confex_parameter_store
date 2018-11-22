[![Build Status](https://travis-ci.com/gpedic/confex_parameter_store.svg?branch=master)](https://travis-ci.com/gpedic/confex_parameter_store)
[![Coverage Status](https://coveralls.io/repos/github/gpedic/confex_parameter_store/badge.svg?branch=master)](https://coveralls.io/github/gpedic/confex_parameter_store?branch=master)

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

Usage is mostly the same as described in the original [Confex Usage section](https://github.com/Nebo15/confex#usage), we simply use the provided adapter.
Where it differes is when fetching parameters by path we need to provide a custom type tuple

## Single parameters


```elixir
config :my_app, MyApp.MyQueue,
  queue: [
    name: {{:via, Confex.Adapters.ParameterStore}, :string, "OUT_QUEUE_NAME", "MyQueueOut"},
    routing_key: {{:via, Confex.Adapters.ParameterStore}, "OUT_ROUTING_KEY", ""},
    port: {{:via, Confex.Adapters.ParameterStore}, :integer, "OUT_PORT", 1234},
  ]
```

The values of the ENV variables containing the paths we want to fetch from the parameter store must be prefixed by `parameter:`

```bash
OUT_QUEUE_NAME=parameter:/queue/out/name
OUT_PORT=parameter:/queue/out/port
OUT_ROUTING_KEY=parameter:/queue/out/routing_key
```

Assuming our parameter store values are:
```js
%{
  "InvalidParameters" => [],
  "Parameters" => [
    %{
      "Name" => "/queue/out/name",
      "Type" => "String",
      "Value" => "MyQueueName",
      "Version" => 1
    },
    %{
      "Name" => "/queue/out/port",
      "Type" => "String",
      "Value" => "1234",
      "Version" => 1
    },
    %{
      "Name" => "/queue/out/routing_key",
      "Type" => "String",
      "Value" => "test",
      "Version" => 1
    }
  ]
}
```

When fetched this will return

```elixir
iex> Confex.fetch_env(:my_app, MyApp.MyQueue)
{:ok, [
  queue: [
    name: "MyQueueName",
    port: 1234,
    routing_key: "test"
  ]
]}
```

## Recursive by path

When dealing with many parameters contained under a path it can be more efficient to request all parameters under the given path instead of each one individually.

To accompilsh this all we need to do is change our ENV variable prefix from `parameter:` to `parameters_by_path:`

```
OUT_QUEUE_PARAMS=parameters_by_path:/queue/out/
```

Now we can adjust our config to:

```elixir
config :my_app, MyApp.MyQueue,
  queue: {{:via, Confex.Adapters.ParameterStore}, "OUT_QUEUE_PARAMS"}
```

Fetching the config returns a similar result to fetching the values individually with the notable exception of `:port` which is now a string.



```elixir
iex> Confex.fetch_env(:my_app, MyApp.MyQueue)
{:ok, [
  queue: [
    name: "MyQueueName",
    port: "1234",
    routing_key: "test"
  ]
]}
```

The keys in the returned list are based on the values path, more specifically the last segment of the path, note that the list returned is flat and doesn't contained nested lists.

| path examples            | key          |
| ------------------------ | ------------ |
| `/queue/id`              | :id          |
| `/queue/out/name`        | :name        |
| `/queue/out/ext/timeout` | :timeout     |

The above example if queried by the path `/queue/` would thus return a list with the following values:
```elixir
[
  id: "someid",
  name: "somename",
  timeout: "sometimeout"
]
```

If multiple paths end in same key the returned list will contain duplicate keys, this may not be something you want.

As before all values default to strings, if we want to cast `port` to an integer we have to define a custom type using the included [Confex.ParameterStore.TypeResolver](lib/confex/parameter_store/type_resolver.ex) module.

The `cast` function it defines takes as argument a keyword list of atom names and the type to cast it to.

```elixir
use Mix.Config

alias Confex.ParameterStore.TypeResolver

config :my_app, MyApp.MyQueue,
  queue: {
    {:via, Confex.Adapters.ParameterStore},
    {TypeResolver, :cast, [[port: :integer]]},
    "OUT_QUEUE_PARAMS"
  }
```

The types are identical to regular Confex types.

  | Confex Type | Elixir Type       | Description |
  | ----------- | ----------------- | ----------- |
  | `:string`   | `String.t`        | Default.    |
  | `:integer`  | `Integer.t`       | Parse Integer value in string. |
  | `:float`    | `Float.t`         | Parse Float value in string. |
  | `:boolean`  | `true` or `false` | Cast "true", "1", "yes" to `true`; "false", "0", "no" to `false`. |
  | `:atom`     | `atom()`          | Cast string to atom. |
  | `:module`   | `module()`        | Cast string to module name. |
  | `:list`     | `List.t`          | Cast comma-separated string `"1,2,3"` to list `["1", "2", "3"]`. |


After this change `:port` will be returned as integer like before

```elixir
iex> Confex.fetch_env(:my_app, MyApp.MyQueue)
{:ok, [
  queue: [
    name: "MyQueueName",
    port: 1234,
    routing_key: "test"
  ]
]}
```

## IAM policy example
The following policy allows a user to successfully request and decrypt parameters stores under the path `/queue/out/staging/*`

We can only decrypt SecureString parameters if we have access to the key they were encrypted with.
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt",
                "ssm:GetParametersByPath",
                "ssm:GetParameter"
            ],
            "Resource": [
                "arn:aws:ssm:us-east-1:111122223333:parameter/queue/out/staging/*",
                "arn:aws:kms:us-east-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
            ]
        }
    ]
}
```
This policy can then be attached to any EC2 Instance IAM role, ECS Container Instance IAM role or Lambda Execution role we wish to give access to the parameters.
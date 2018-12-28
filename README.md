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

Docs can
be found at [https://hexdocs.pm/confex_parameter_store](https://hexdocs.pm/confex_parameter_store).

## Testing
To run integration tests run the included `docker-compose.yml` using `docker-compose up`, this will start a local AWS SSM at `localhost:4583` using [localstack](https://github.com/localstack/localstack).
Now we can include integration tests by running `mix test` as:
```
$ mix test --include external:true
```

## Usage

Usage is mostly the same as described in the original [Confex Usage docs](https://github.com/Nebo15/confex#usage) when parameters are fetched explicitly, we simply use the provided adapter.

There are some differences when parameters are fetched recursively which we will cover in that section of the docs.

## Single parameters

To have Confex fetch parameters from the parameter store define the ENV value as the parameter store path we want to fetch prefixed by `parameter:`

```bash
OUT_QUEUE_NAME=parameter:/queue/out/name
OUT_PORT=parameter:/queue/out/port
OUT_ROUTING_KEY=parameter:/queue/out/routing_key
```

Non prefixed ENV will simply be passed through as the case when using the `:system` adapter.

Now we can add the values to our `config.exs`
```elixir
use Mix.Config
alias Confex.Adapters.ParameterStore

config :my_app, MyApp.MyQueue,
  queue: [
    name: {{:via, ParameterStore}, :string, "OUT_QUEUE_NAME", "MyQueueOut"},
    port: {{:via, ParameterStore}, :integer, "OUT_PORT", 1234},
    routing_key: {{:via, ParameterStore}, "OUT_ROUTING_KEY", ""},
  ]
```

Let's say our parameter store values are:

| path | value |
| ---  | ----- |
|/queue/out/name   | "MyQueueName" |
|/queue/out/port   | "1234" |
|/queue/out/routing_key| "test" |

Then `fetch_env` will return the following:

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

All we need to do is change our ENV variable prefix from `parameter:` to `parameters_by_path:`

```
OUT_QUEUE_PARAMS=parameters_by_path:/queue/out/
```

Now we can adjust our config to:

```elixir
config :my_app, MyApp.MyQueue,
  queue: {{:via, Confex.Adapters.ParameterStore}, "OUT_QUEUE_PARAMS"}
```

Fetching the config returns a similar result to fetching the values individually before with the exception of `:port` being returned as a string.

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

Note that only the last segment of each returned path are used as keys.

| path examples            | returned key |
| ------------------------ | ------------ |
| `/queue/id`              | :id          |
| `/queue/out/name`        | :name        |
| `/queue/out/conf/port`   | :port        |

The above example if queried by the path `/queue/` thus returns the list:

```elixir
[
  id: "someid",
  name: "somename",
  port: "1234"
]
```

Note that if multiple paths end in same key the returned list will contain duplicate keys, this may not be something you want.

### Type casting
Type casting for parameters retrieved by path is a bit different as well.
If we want to for example cast the above `port` to integer we have to use the included [Confex.ParameterStore.TypeResolver](lib/confex/parameter_store/type_resolver.ex) module.


TypeResolver provides a `cast/1` which we give confex instead of a regular type, `cast/1` accepts a keyword list of atom names and types to cast them to.

```elixir
use Mix.Config

alias Confex.ParameterStore.TypeResolver

# cast /queue/out/conf/port to integer
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


## Caching

Consider using some form of caching for values that are retrieved repeatedly as there is a considerable network latency overhead as parameters are retrieved via http.
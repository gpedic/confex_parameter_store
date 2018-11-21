use Mix.Config

config :ex_aws,
  debug_requests: false,
  access_key_id: "notneeded",
  secret_access_key: "notneeded",
  region: "us-east-1"

config :ex_aws,
  ssm: [
    host: "localhost",
    scheme: "http://",
    port: 4583
  ]

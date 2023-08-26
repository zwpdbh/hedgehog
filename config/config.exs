# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

config :naive, Naive.Repo,
  database: "naive_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :binance,
  api_key: "xxx",
  secret_key: "xxx",
  # Add for the US API end point. The default is for "https://api.binance.com"
  end_point: "https://api.binance.us"

config :naive,
  ecto_repos: [Naive.Repo],
  binance_client: BinanceMock,
  trading: %{
    defaults: %{
      chunks: 5,
      budget: 1000,
      buy_down_interval: "0.0001",
      profit_interval: "-0.0012",
      rebuy_interval: "0.001"
    }
  }

config :logger, :console,
  # We could change log level to filter different level of log to display
  level: :debug,
  # level: :info,
  format: "$date $time [$level] $metadata$message\n"

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#

# Import secrets file with Binance keys if it exists
# secrets = Path.join([File.cwd!(), "config/secrets.exs"])

# if File.exists?(secrets) do
#   import_config(secrets)
# end

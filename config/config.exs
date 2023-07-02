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

config :logger, :console,
  # We could change log level to filter different level of log to display
  # level: :debug,
  level: :info,
  format: "$date $time [$level] $metadata$message\n"

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#

# Import secrets file with Binance keys if it exists
secrets = Path.join([File.cwd!(), "config/secrets.exs"])

if File.exists?(secrets) do
  import_config(secrets)
end

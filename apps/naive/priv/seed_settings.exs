require Logger

alias Decimal
alias Naive.Repo
alias Naive.Schema.Settings

# app_folder = File.cwd!()
# |> Path.dirname()
# |> Path.dirname()
# |> Path.dirname()

# config_file = Path.join([app_folder, "config", "config.exs"])

# config = Code.eval_file(config_file) |> IO.inspect(label: "#{__MODULE__} 14")
# binance_client = Keyword.get_in(config, [:naive, :binance_client])

# Understand how to read config file
# https://elixirforum.com/t/manually-load-an-elixir-config-file-at-runtime/30184/7

Application.compile_env(:naive, :binance_client) |> IO.inspect()
Application.compile_env(:naive, :ecto_repos) |> IO.inspect()
# binance_client = Application.compile_env(:naive, :binance_client)

# Logger.info("Fetching exchange info from Binance to create trading settings")
# {:ok, %{symbols: symbols}} = binance_client.get_exchange_info()

# # fetch default trading settings from the config file as well as the current timestamp:
# %{
#   chunks: chunks,
#   budget: budget,
#   buy_down_interval: buy_down_interval,
#   profit_interval: profit_interval,
#   rebuy_interval: rebuy_interval
# } = Application.compile_env(:naive, :trading).defaults

# timestamp = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

# base_settings = %{
#   symbol: "",
#   chunks: chunks,
#   budget: Decimal.new(budget),
#   buy_down_interval: Decimal.new(buy_down_interval),
#   profit_interval: Decimal.new(profit_interval),
#   rebuy_interval: Decimal.new(rebuy_interval),
#   status: "off",
#   inserted_at: timestamp,
#   updated_at: timestamp
# }

# # We will now map each of the retrieved symbols and inject them to the base_settings structs
# # and pushing all of those to the Repo.insert_all/3 function:
# # The reasone we need to set inserted_at and updated_at column manually because
# # Repo.insert_all/3 which is a bit more low-level function without those nice features like filling timestamps.

# Logger.info("Inserting default settings for symbols")
# maps = symbols
#   |> Enum.map(&(%{base_settings | symbol: &1["symbol"]}))

# {count, nil} = Repo.insert_all(Settings, maps)

# Logger.info("Inserted settings for #{count} symbols")
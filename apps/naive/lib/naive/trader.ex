defmodule Naive.Trader do

  use GenServer
  require Logger

  defmodule State do
    # This will ensure that we won’t create an invalid %State{} without those values.
    @enforce_keys [:symbol, :profit_interval, :tick_size]
    defstruct [
      :symbol,
      :buy_order,
      :sell_order,
      :profit_interval,
      :tick_size
    ]
  end

  def start_link(%{} = args) do

  end

  def init(%{symbol: symbol, profile_interval: profit_interval}) do
    symbol = String.upcase(symbol)
    Logger.info("Initializing new trader for #{symbol}")

    tick_size = fetch_tick_size(symbol)

    {:ok,
      %State{
        symbol: symbol,
        profit_interval: profit_interval,
        tick_size: tick_size
      }}
  end
end

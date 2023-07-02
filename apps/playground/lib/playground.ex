defmodule Playground do
  @moduledoc """
  This module is intented to be used to play features from other modules
  """
  alias Streamer
  alias Naive

  def chapter03_demo do
    # Currently, this will has error like HTTP timeout.
    # Because Binance.get_exchange_info() will timeout (we don't have Binance account).
    Streamer.start_streaming("ethusd")
    Naive.Trader.start_link(%{symbol: "ethusd", profile_interval: "0.01"})
    Naive.Trader.start_link(%{symbol: "xrpusdt", profile_interval: "0.02"})
  end
end

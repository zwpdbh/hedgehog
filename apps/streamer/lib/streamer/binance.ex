defmodule Streamer.Binance do
  use WebSockex
  require Logger

  @stream_endpoint "wss://stream.binance.us:9443/ws/"

  def start_link(symbol) do
    symbol = String.downcase(symbol)
    trade_stream = "#{@stream_endpoint}#{symbol}@trade"
    WebSockex.start_link(trade_stream, __MODULE__, nil)
  end

  def handle_frame({_type, msg}, state) do
    case Poison.decode(msg) do
      {:ok, event} -> process_event(event)
      {:error, _} -> Logger.error("Unable to parse msg: #{msg}")
    end

    {:ok, state}
  end

  defp process_event(%{"e" => "trade"} = event) do
    trade_event = %Streamer.Binance.TradeEvent{
      :event_type => event["e"],
      :event_time => event["E"],
      :symbol => event["s"],
      :trade_id => event["t"],
      :price => event["p"],
      :quantity => event["q"],
      :buyer_order_id => event["b"],
      :seller_order_id => event["a"],
      :trade_time => event["T"],
      :buyer_market_maker => event["m"]
    }

    Logger.debug(
      "Trade event received" <>
      "#{trade_event.symbol}@#{trade_event.price}"
    )
    Naive.send_event(trade_event)
  end
end

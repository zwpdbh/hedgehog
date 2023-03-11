defmodule Naive do
  @moduledoc """
  Documentation for `Naive`.
  """

  # alias Streamer.Binance.TradeEvent

  @doc """
  Hello world.

  ## Examples

      iex> Naive.hello()
      :world

  """
  def hello do
    :world
  end

  # # API
  # def send_event(%TradeEvent{} = event) do
  #   # what is the meaning of :trader atom here?
  #   GenServer.cast(:trader, event)
  # end
end

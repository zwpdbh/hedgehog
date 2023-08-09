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
    Naive.Trader.start_link(%{symbol: "ethusd", profit_interval: "0.01"})
    Naive.Trader.start_link(%{symbol: "xrpusdt", profit_interval: "0.02"})
    :ok
  end

  defmodule Person do
    defstruct [
      :first_name,
      :last_name,
      :cell_phone
    ]

    use ExConstructor
  end

  defmodule Customer do
    defstruct [
      :first_name,
      :last_name,
      :phone
    ]
  end

  def demo_convert_struct_to_another() do
    # Notice we have to `use ExConstructor` in Person struct's definition.
    # It will inject a constructor function into the module.
    p =
      Person.new(%{
        first_name: "zw",
        last_name: "pdbh",
        cell_phone: "123456"
      })

    %{
      struct(Playground.Customer, p |> Map.to_list())
      | phone: p.cell_phone
    }
  end

  def chapter_04_demo() do
    Streamer.start_streaming("ethusdt")
    Naive.Trader.start_link(%{symbol: "ETHUSDT", profit_interval: "-0.001"})
    :ok
  end
end

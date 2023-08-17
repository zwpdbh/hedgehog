defmodule Naive.Leader do
  use GenServer
  require Logger
  alias Naive.Trader

  alias Decimal, as: D

  @binance_client Application.compile_env(:naive, :binance_client)

  defmodule State do
    defstruct symbol: nil,
              settings: nil,
              traders: []
  end

  defmodule TraderData do
    defstruct pid: nil, ref: nil, state: nil
  end

  def start_link(symbol) do
    GenServer.start_link(
      __MODULE__,
      symbol,
      name: :"#{__MODULE__}-#{symbol}"
    )
  end

  @impl true
  def init(symbol) do
    {:ok, %State{symbol: symbol}, {:continue, :start_trader}}
  end

  @impl true
  def handle_continue(:start_trader, %{symbol: symbol} = state) do
    settings = fetch_symbol_settings(symbol)
    trader_state = fresh_trader_state(settings)

    # traders = for _i <- 1..settings.chunks, do: start_new_trader(trader_state)
    # Just start one trader at the start, rebuy logic will be triggered to start more traders
    traders = [start_new_trader(trader_state)]

    {:noreply, %{state | settings: settings, traders: traders}}
  end

  @impl true
  def handle_call(
        {:update_trader_state, new_trader_state},
        {trader_pid, _},
        %{traders: traders} = state
      ) do
    case Enum.find_index(traders, fn x -> x.pid == trader_pid end) do
      nil ->
        Logger.warn("Tried to update the state of trader that leader is not aware of")
        {:reply, :ok, state}

      index ->
        old_trader_data = Enum.at(traders, index)
        new_trader_data = %{old_trader_data | :state => new_trader_state}

        {:reply, :ok, %{state | :traders => List.replace_at(traders, index, new_trader_data)}}
    end
  end

  # callback for handle rebuy event
  @impl true
  def handle_call(
        {:rebuy_triggered, new_trader_state},
        {trader_pid, _},
        %{traders: traders, symbol: symbol, settings: settings} = state
      ) do
    case Enum.find_index(traders, fn x -> x.pid == trader_pid end) do
      nil ->
        Logger.warn("Rebuy triggered by trader that the leader is not aware of, ignored")
        {:reply, :ok, state}

      index ->
        # remember to update the state of the trader that triggered the rebuy inside the traders list
        old_trader_data = Enum.at(traders, index)
        new_trader_data = %{old_trader_data | :state => new_trader_state}
        updated_traders = List.replace_at(traders, index, new_trader_data)

        updated_traders =
          if settings.chunks == length(traders) do
            Logger.info("All traders already started for #{symbol}")
            updated_traders
          else
            Logger.info("Starting new trader for #{symbol} to rebuy")
            #  add the state of a new trader to that list.
            [start_new_trader(fresh_trader_state(settings)) | updated_traders]
          end

        {:reply, :ok, %{state | :traders => updated_traders}}
    end
  end

  @impl true
  def handle_info(
        {:DOWN, _ref, :process, trader_pid, :normal},
        %{traders: traders, symbol: symbol, settings: settings} = state
      ) do
    Logger.info("#{symbol} trader finished trade - restarting")

    case Enum.find_index(traders, fn x -> x.pid == trader_pid end) do
      nil ->
        Logger.warn(
          "Tried to restart finished #{symbol} " <>
            "trader that leader is not aware of"
        )

        {:noreply, state}

      index ->
        new_trader_data = start_new_trader(fresh_trader_state(settings))
        new_traders = List.replace_at(traders, index, new_trader_data)

        {:noreply, %{state | traders: new_traders}}
    end
  end

  @impl true
  def handle_info(
        {:DOWN, _ref, :process, trader_pid, reason},
        %{traders: traders, symbol: symbol} = state
      ) do
    Logger.error("#{symbol} trader died - reason #{reason} - trying to restart")

    case Enum.find_index(traders, &(&1.pid == trader_pid)) do
      nil ->
        Logger.warn(
          "Tried to restart #{symbol} trader " <>
            "but failed to find its cached state"
        )

        {:noreply, state}

      index ->
        trader_data = Enum.at(traders, index)
        new_trader_data = start_new_trader(trader_data.state)
        new_traders = List.replace_at(traders, index, new_trader_data)

        {:noreply, %{state | traders: new_traders}}
    end
  end

  defp fetch_symbol_filters(symbol) do
    symbol_filters =
      @binance_client.get_exchange_info()
      |> elem(1)
      |> Map.get(:symbols)
      |> Enum.find(fn x -> x["symbol"] == symbol end)
      |> Map.get("filters")

    tick_size =
      symbol_filters
      |> Enum.find(fn x -> x["filterType"] == "PRICE_FILTER" end)
      |> Map.get("tickSize")

    step_size =
      symbol_filters
      |> Enum.find(fn x -> x["filterType"] == "LOT_SIZE" end)
      |> Map.get("stepSize")

    %{
      tick_size: tick_size,
      step_size: step_size
    }
  end

  defp fetch_symbol_settings(symbol) do
    symbol_filters = fetch_symbol_filters(symbol)

    Map.merge(
      %{
        symbol: symbol,
        chunks: 5,
        budget: 100,
        buy_down_interval: "0.0001",
        profit_interval: "-0.0012",
        rebuy_notified: false
      },
      symbol_filters
    )
  end

  defp fresh_trader_state(settings) do
    # struct(Trader.State, settings)
    %{
      struct(Trader.State, settings)
      | id: :os.system_time(:millisecond),
        budget: D.div(settings.budget, settings.chunks),
        rebuy_notified: false
    }
  end

  defp start_new_trader(%Trader.State{} = state) do
    {:ok, pid} =
      DynamicSupervisor.start_child(
        :"Naive.DynamicTraderSupervisor-#{state.symbol}",
        {Naive.Trader, state}
      )

    ref = Process.monitor(pid)
    %TraderData{pid: pid, ref: ref, state: state}
  end

  def notify(:trader_state_updated, trader_state) do
    GenServer.call(:"#{__MODULE__}-#{trader_state.symbol}", {:update_trader_state, trader_state})
  end

  def notify(:rebuy_triggered, trader_state) do
    GenServer.call(:"#{__MODULE__}-#{trader_state.symbol}", {:rebuy_triggered, trader_state})
  end
end

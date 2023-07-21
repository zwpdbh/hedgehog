# Hedgehog

## About

This is my practise of [Hands-on Elixir & OTP: Cryptocurrency trading bot](https://book.elixircryptobot.com/)

## Key notes

### Chatper 01

- Created `Streamer.Binance` module which `use WebSockex` to listen incoming events from websocket.
- The progress is:
  - We could listen incoming symbol's event by `Streamer.Binance.start_link("ethusd")`.

### Chapter02

- Use a GenServer to represent a trader.

  - The state of a trader is composed by
    - symbol \
      The symbol from the market which represent the trading become two different kind of currency.
    - buy order
    - sell order
    - profit interval \
      What net profit % we would like to achieve when buying and selling an asset - single trade cycle
    - tick size
      - [Tick size](https://www.investopedia.com/terms/t/tick-size.asp) refers to the minimum price movement of a trading instrument in a market.
      - Tick size differs between symbols and it is the smallest acceptable price movement up or down.
  - It is initialized by a `symbol` and `profit_interval`.
  - During initialization, it fetch `tick_size` for that symbol.

- How a simple trader works?

  - The trader takes decision based on its own state and the incoming trade events.
    - First state - A new trader
      - At the beginner, there is no buy order or sell order stored in the trader's state.
      - We just grab the current price for a symbol and buy 100 quantity for it.
      - The request to Binance will give us a response `%Binance.OrderResponse{}` which will be stored in trader's state as `buy_order`.
      - Notice, we send buy order request and got response. However, this only means we placed the order. The deal is not complete. It is only complete if the incoming trade event matches our current state, see next.
    - Second state - Buy order placed
      - To get our buy order filled, we match the incoming event with our state of `buy_order`.
      - Once it matches, the buy order is filled. Now, we immediately compute our sell price using `calculate_sell_price(buy_price, profit_interval, tick_size)`.
      - Sell the same quantity (should be match quantity the buy order filled) with the sell price.
      - Update our `sell_order` in the state.
    - Third state - Sell order placed
      - Similar with buy order filled, we match incoming trade event with `sell_order`.
      - Notice: after a sell order get filled, a trade profit cycle is complete. We simply terminate the trader.
  - Do not forget to implement a default call back function at the bottom that just ignore all other incoming events.

- The progress is:
  - We created represent a trader using GenServer.
  - This trader will do a simple trade cycle and exit.
  - We send event directly from Streamer to Trader. -- This create a direct link between them, we will solve this in Chapter03.

### Chapter03

The focus of this chapter is to solve the problem we introduced in Chapter02. We need to decouple Streamer and Trader.

- In Chapter02, Streamer send events to Trader directly: `Naive.send_event(trade_event)`. \
  Streamer.Binance -send event-> Naive -GenServer.call(:trader, event)-> Naive.Trader

  It has two problems:

  - It only support one trader (because the trader's name is `:trader` and only one process can be registered under a single name).
  - Streamer needs to be aware of all processes that are interested in the streamed data and explicitly push that information to them.

- [PubSub](https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html) design \
  Streamer.Binance -broadcast-> Phoenix.PubSub -subscribe handle_info-> Naive.Trader

  - The streamer will broadcast trade events to the PubSub topic.
  - Whatever is interested in that data, can subscribe to the topic and it will receive the broadcasted messages.
  - There’s no coupling between the Streamer and Naive app anymore.
  - We can create multiple traders and each one can subscribe to different topic and receive different message from PubSub.

- Steps
  - Install `phoenix_pubsub` in both streamer and naive apps.
  - In Streamer
    - For each message broadcast it to its corresponding topic -- the trade event's symbol.
  - In Trader
    - During GenServer's init we pass the symbol, we could simply subscribe to its topic.
    - Use `GenServer.handle_info` to handle messages.

### [Chapter04](https://book.elixircryptobot.com/mock-the-binance-api.html#objectives-3)

- What features do we need for this BinanceMock ?

  - It need to cover the REST API call .
  - It need to broadcast fake events. \
    Make the BinanceMock process subscribe to the trade events stream and try to broadcast fake trade events whenever the price of orders would be matched.

- What state it needs to hold ?

  - `order_book`, a map for hold each trade symbol.

    - Each symbol has a `%OrderBook{}`
    - `%OrderBook{}` contains fields
      - `buy_side`: []
      - `sell_side`: []
      - `historical`: []

  - List of symbols that mock subscribed to. (BinanceMock will forward certain Binance events for certain symbols.)
  - Last generated id - for consistent generating of unique ids for fake trade events.

- The REST API features

  - `get_exchange_info` -- we will use `Binance.get_exchange_info()` since it is public available.
  - Place buy and sell orders

    - Generate a fake order based on symbol, quantity, price, and side.
    - Cast a message to the BinanceMock process to add the fake order.
    - Return a tuple with `%OrderResponse{}`.

- Implement order retrival (4.6)

  - Why we don't know the order's side

- Implement callback for incoming trade events -- from 4.7 \

  We need to handle incoming trade events streamed from the PubSub topic.

### Review Chapter04

So what we have built ? In general, we have build a event system with PubSub at its center:

- A streamer is a GenServer process

  - A streamer connect to a websocket(`WebSockex`) for a specific symbol's messages.
  - Use `handle_frame` to handle incoming messages from websocket, the streamer format it and use PubSub to broadcast to a corresponding channel.

- A trader is implemented as a GenServer process.

  - A trader initialize itself by subscribing to a symbol's topic from PubSub.
  - The trading events are sent to it and the trader handles it via `handle_info`.
  - A simple trade strategy is implemented.

- BinanceMock is configured in `config.exs`.

  - Trader will use BinanceMock or Binance via configuration of our umbrella project.

    ```elixir
    config :naive, :binance_client, BinanceMock
    ```

  - BinanceMock is also a GenServer process. It needs to handle two kinds of messages:

    - Messages from trader's call using `handle_cast`: This is the trade order request send from traders.

      - Subscribe the same trade event in PubSub as the trader.
      - Add order into an `%OrderBook{}`

    - Messages from PubSub using `handle_info`:

      - Those events are real Binance events from streamer. So, we don't need to figure out how to generate reasonable events.
      - We use those events to process the OrderBook.
      - Similate an order is filled and send trade event to PubSub.

        - So from a trader's point of view, its `handle_info` does not care where the trade events comes from. It is just a message delivered from subscription to PubSub.
        - That is the point of BinanceMock: A trader could configure its `@binance_client` to be Binance or BinanceMock. Other code remains the abolute unchanged.


## [Chapter05](https://book.elixircryptobot.com/enable-parallel-trading-on-multiple-symbols.html)

- Limition so far 
  -  We start the `Naive.Trader` process from `iex`. 
  -  So whenever a trader process terminates, a new one won't get started as it is not supervised. 

- Features we want 
  -  Allow multiple traders in parallel per symbol. 
     -  In system, we are trading multiple symbol. 
     -  For each symbol, there are multiple trader are working on it. 

- Design v1 
  - Use a supervisor to supervise the trader process.
  - Start a new trader process whenever the previous one finished/crashed.

- Design v2 
  - Introduce `Naive.Leader` to track trader's data.
  - `Naive.Leader` is also responsible for start and restart `Naive.Trader` via `Naive.DynamicTraderSupervisor`.
  - So far, our system could start and supervise multiple traders for a single symbol. 

- Design V3 
  - To support multiple symbol. We need to manage multiple: `Naive.Trader` + `Naive.DynamicTraderSupervisor` + multiple `Naive.Trader`.
    - In other words, we need to manage multiple `Naive.Leader` and `Naive.DynamicTraderSupervisor`.  
    - We introduce `Naive.SymbolSupervisor` to start both `Naive.Leader` and `NaiveDynamicTraderSupervisor`.  
    - One symbol for one `Naive.SymbolSupervisor`, so we need a way to manage multiple `Naive.SymbolSupervisor`. 
  - Similar in how to restart multiple trader situation: 
    - Whenever we need to use a service to manage a group of services, we don't do this directly. 
    - Instead, we use a service to start a supervisor and that supervisor start the worker services. 
  - Therefore, we use `Naive.Supervisor` to dynamically start a `Naive.DynamicSymbolSupervisor` and it start multiple `Naive.SymbolSupervisor`. 

- Supervisor vs DynamicSupervisor 
  - They can all manage children processes.
  - The differences is that: 
    - Supervisor is used to handle mostly static children that are started in the given order when supervisor starts. 
    - DynamicSupervisor starts with no children. Its children are started ON demand via `start_child/2` and there is NO ordering between children.
  - Summary
    - Supervisor is used to start children that can be planed: numbers and orders of children are fixed.
    - DynamicSupervisor is used to start children in response to event.
    - In our case: 
      - `SymbolSupervisor` is a Supervisor which its children are known: a `Naive.Leader` + `Naive.DynamicTraderSupervisor`.
      - `Naive.DynamicSupervisor` and `Naive.DynamicSymbolSupervisor` are DynamicSupervisor because their children are created on demand.
  - Read [How We Used Elixir's GenServers + Dynamic Supervisors to Build Concurrent, Fault Tolerant Workflows](https://www.thegreatcodeadventure.com/how-we-used-elixirs-genservers-dynamic-supervisors-to-build-concurrent-fault-tolerant-workflows/).

- How to see the supervision tree
  ```sh 
  iex -S mix 
  iex(1)> :observer.start()
  ```

  Then, click the "Application" tab at the top --> go to the list on the left and select `naive` application.

- To understand 
  - [https://book.elixircryptobot.com/enable-parallel-trading-on-multiple-symbols.html#finalizing-naive.leader-implementation](https://book.elixircryptobot.com/enable-parallel-trading-on-multiple-symbols.html#finalizing-naive.leader-implementation)

## Other Notes

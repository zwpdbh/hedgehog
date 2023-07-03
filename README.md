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
  - It is initialized by a `symbol` and `profile_interval`.
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

### Chapter04

## Other Notes

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

## Other Notes

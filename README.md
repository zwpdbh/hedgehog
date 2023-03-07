# Hedgehog

# Chatper 01 
## Summary
Created a module which implement WebSockex to use websocket to listen incoming events.

## Notes
1. Create umbrella project
```
mix new hedgehog --umbrella
```

2. Create a new supervised application called streamer inside our umbrella application
```
cd hedgehog/apps
mix new streamer --sup
```


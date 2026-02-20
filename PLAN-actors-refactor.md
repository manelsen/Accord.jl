# Refactoring Accord.jl to Actors.jl Architecture

This plan details the migration of Accord.jl's concurrency model from manual `Task`/`Channel` management to the formal Actor Model provided by `Actors.jl`. The goal is to match the resilience and scalability of Nostrum (Elixir) while maintaining Julia's performance characteristics.

## Core Objectives

1.  **Resilience**: Implement supervision trees where parent actors monitor children (Shards, RateLimiters) and restart them on failure.
2.  **State Isolation**: Remove shared mutable state (`ShardedStore` with locks) in favor of actor-owned state.
3.  **Scalability**: Enable easier distribution of components (though initially running in a single process).

## Architecture Overview

The system will be structured as a hierarchy of actors:

```
[System]
  ├── [Client/Supervisor]
  │     ├── [State Manager] (Owns the cache)
  │     ├── [Rate Limiter] (Owns the HTTP request queue)
  │     └── [Shard Supervisor]
  │           ├── [Shard 0] (WebSocket Connection)
  │           ├── [Shard 1]
  │           └── ...
```

## Component Refactoring

### 1. Dependencies
- Add `Actors.jl` to `Project.toml`.
- Remove manual `Channel` management in favor of `Actors.spawn` and `Actors.Link`.

### 2. State Management (`src/client/state.jl`)
- **Current**: `State` struct with `ShardedStore` (locks).
- **New**: `StateActor`.
    - **Behavior**: Receives `UpdateState(event)` messages from Shards.
    - **Interface**: `get_user(id)`, `get_guild(id)` become `call(state_actor, GetUser(id))` (synchronous) or `cast` (asynchronous updates).
    - **Benefit**: No locks, strictly sequential updates per actor, preventing race conditions.

### 3. Rate Limiter (`src/rest/ratelimiter.jl`)
- **Current**: `RateLimiter` struct with `Channel` and a background task loop.
- **New**: `RateLimiterActor`.
    - **Behavior**: Accepts `Request(route, params)` messages.
    - **State**: Holds the bucket states.
    - **Logic**: Processes requests, handles 429s, and replies to the sender when done.
    - **Benefit**: Simplified logic, failure in one bucket handling doesn't crash the whole client if properly supervised.

### 4. Gateway / Sharding (`src/gateway/`)
- **Current**: `Gateway` loop in a Task, piping to a Channel.
- **New**: `ShardActor`.
    - **Behavior**:
        - `Connect(token)`: Establishes WS connection.
        - `HeartbeatLoop`: Self-send messages or a separate timer actor.
        - `IncomingEvent(payload)`: Parsed and sent to `StateActor` and `Dispatch`.
    - **Supervision**: If the WS connection drops or parsing fails fatally, the actor crashes. The `ShardSupervisor` restarts it, re-establishing the connection (Resume/Identify).

### 5. Client (`src/client/client.jl`)
- **Current**: `Client` struct holds everything.
- **New**: `Client` struct becomes a wrapper around the `System` or Root Actor Link.
    - It exposes methods that `call` or `cast` to the underlying actors.
    - `start(c::Client)` spawns the supervision tree.

## Implementation Status

- [x] **Setup**: Added `Actors.jl` dependency.
- [x] **State Actor**: Implemented in `src/actors/state.jl`. Thread-safe cache via sequential message processing.
- [x] **Rate Limiter Actor**: Implemented in `src/actors/ratelimiter.jl`. Actor-based request queue.
- [x] **Event Dispatch Actor**: Implemented in `src/actors/dispatch.jl`. Centralized event handling.
- [x] **Shard Actor**: Implemented in `src/actors/shard.jl`. Supervises Gateway connections.
- [x] **Core Refactor**: 
    - Updated `Client` struct to use actor links.
    - Modified `gateway_connect` to use `cast(dispatch_actor, ...)` for events.
    - Updated REST and Gateway methods in `Client` to route through actors.
    - Removed manual `_event_loop` and `_supervisor_loop` tasks.

## Results
The project now uses a formal Actor Model for its core concurrency. This matches the architectural style of Nostrum (Elixir) and provides a foundation for high-scale, resilient Discord bots in Julia.


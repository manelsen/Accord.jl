# Changelog

All notable changes to this project will be documented in this file.

## [0.4.0] - Unreleased

### Breaking
- **CLI split out**: the `accord` command-line tool (`onboard`, `doctor`) moved to the `AccordCLI` package in `AccordCLI/`. `Accord` no longer depends on `Comonicon`, `Pkg` or `UUIDs`, and `Accord.AccordCLI` is gone.
- **Voice transport encryption**: only `aead_aes256_gcm_rtpsize` (preferred, when the CPU has hardware AES) and `aead_xchacha20_poly1305_rtpsize` are supported. The `xsalsa20_poly1305*` modes, discontinued by Discord on 2024-11-18, were removed together with their functions and `CRYPTO_SECRETBOX_*` constants. `Accord.Internals` exposes `encrypt_rtpsize`, `decrypt_rtpsize` and `aes256gcm_available` instead.
- Removed the unused `CodecZlib` dependency and the `GatewaySession.zlib_buffer` field (Accord never requested gateway compression).

### Fixed
- **Rate limit buckets**: bucket state is now keyed by Discord's bucket hash *plus* the major parameter, so channels sharing a hash no longer throttle each other. Minor IDs in substituted paths (message IDs, user IDs…) collapse to one bucket key, so per-resource routes are limited proactively instead of only after a 429.
- **Token leak in logs**: webhook and interaction tokens are replaced by a fingerprint in bucket keys, which appear in rate-limit log lines.
- **Duplicate POSTs**: network errors are retried only for idempotent methods (GET, HEAD, PUT, DELETE, OPTIONS).
- **File uploads on retry**: multipart bodies are rebuilt for every attempt instead of resending an exhausted stream.
- **Hung requests**: a request that still gets 429 after the last retry now returns that response instead of blocking forever.
- **Interaction callbacks with files**: `create_interaction_response` now sends `files` as multipart instead of silently dropping them.
- **HTTP diagnostics**: the friendly error boxes for known Discord error codes (50013, 50035, 10062…) now actually fire; they previously only matched an exception that could never be raised.
- **Gateway commands are sent immediately**: presence, voice-state and member requests were only flushed after the next incoming gateway frame (up to a heartbeat interval later). A per-connection pump now sends them right away.
- **Gateway writes are serialised** with a lock shared by the heartbeat, the receive loop and the command pump, and commands respect Discord's 120-per-60-seconds send limit.
- **Shard supervisor**: crashed shards are now actually restarted (the old check could never trigger), while intentional stops and fatal close codes are not retried. A `stop` issued during a reconnect back-off is no longer lost.
- **Ready with several shards**: `start` / `wait_until_ready` now wait for every shard, not only the first.
- **Voice packet nonce**: rtpsize packets now use the 4-byte incrementing nonce Discord specifies instead of a random 24-byte suffix.
- **Project templates**: the bot template and example projects declared `Accord = { path = ... }` under `[deps]`, which is not a valid Project.toml, so scaffolded bots could not be instantiated. They now use Accord's UUID (with `[sources]` for the in-repo examples).

### Changed
- **Concurrent REST**: requests in different rate-limit buckets run concurrently; requests in the same bucket stay ordered. The global limit (50 requests/s by default) is enforced proactively.
- **Bounded handler tasks**: new `Client(...; handler_backlog=64*handler_concurrency)` caps how many handler tasks exist at once; past that, the event loop applies back-pressure. Each event now costs one task instead of two.
- CI runs on pushes to `master` as well as pull requests, and the CLI has its own job.
- `ACCORD_VERSION` is read from `Project.toml` instead of being duplicated.
- README states that voice is unavailable until DAVE is supported, and its documentation links point to the right paths.

## [0.3.0] - 2026-02-27 (Reliability & Documentation Overhaul)

### Added
- **Fault Injection Suite**: Introduced deterministic failure testing for Rate Limiting (429) and Gateway heartbeats to ensure robust recovery.
- **Smoke Test Runner**: Added `scripts/run_all_smokes.jl` for consolidated validation of core bot functionality in sandbox environments.
- **New Gateway Events**: Added support for `VOICE_CHANNEL_STATUS_UPDATE` and `VOICE_CHANNEL_START_TIME_UPDATE`.
- **Configurable Safety Buffer**: Added `safety_buffer` parameter to `Client` and `RateLimiter` to tune 429 prevention based on network jitter.

### Fixed
- **Gateway Zombie Connections**: Forced aggressive WebSocket closure on missed heartbeats to trigger immediate reconnection.
- **Rate Limiter World Age**: Resolved world-age errors in tests by using `invokelatest` for request handlers.
- **Model Resilience**: Introduced `Maybe{T} = Union{T, Missing, Nothing}` to handle the high variability of Discord's optional/nullable fields without crashing.
- **Docstrings**: Total overhaul of documentation for all Types (Tiers A, B, and C) and functional API methods, reaching maturity parity with industry-standard Discord libraries.

### Changed
- **CI/CD Triggers**: Optimized CI to run exclusively on Pull Requests to `master`.
- **Internal namespace**: Refined `Accord.Internals` for explicit access to non-public symbols.


## [0.2.0] - 2026-02-17 (The "Developer Experience" Release)

### Added
- **Elm-like Diagnostics**: A new error reporting system (`src/diagnostics/`) that catches common errors (Missing Token, Invalid Intents, Shard Disconnects) and displays them with beautiful box-drawing, ANSI colors, and actionable hints.
- **Documentation**: Achieved 100% Example Coverage for the entire public API (`Client`, `Context`, `Components`, `Voice`).
- **Templates**: added polished, production-ready examples:
    - `accord_omni`: Reference architecture using `FunSQL.jl`.
    - `music_bot`: Async-ready voice player.
    - `ai_chat`: Non-blocking OpenAI integration.

### Fixed
- **Voice**: Fixed invalid `await` calls in voice connection logic in examples.
- **Concurrency**: Fixed blocking HTTP calls in event handlers in examples.
- **Build**: Resolved `InteractiveUtils` dependency issues in documentation build.

### Changed
- **Performance**: Optimized `Diagnoser.jl` to have zero runtime overhead when no errors occur.

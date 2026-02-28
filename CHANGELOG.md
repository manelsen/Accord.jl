# Changelog

All notable changes to this project will be documented in this file.

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

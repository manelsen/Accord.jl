# Changelog

All notable changes to this project will be documented in this file.

## [0.3.0-alpha] - 2026-02-24 (Early Adopters Stabilization)

### Added
- **Internal namespace**: Introduced `Accord.Internals` (also available as `Accord.internals`) to provide an explicit access point for non-public symbols used by advanced users and tests.

### Fixed
- **Test stability**: Removed hangs in contract tests by using mocked `RateLimiter` flows for forum tags and thread/poll validation tests.
- **Gateway robustness**: Hardened gateway payload parsing and heartbeat interval handling in `_gateway_loop` to avoid invalid payload paths.
- **Forum tags endpoints**: Fixed type handling for `ForumTag` operations (`create/modify/delete`) and corrected payload generation for `available_tags`.
- **Voice gateway safety**: Added explicit websocket connectivity checks before sending speaking/protocol payloads.
- **Diagnostics module**: Fixed internal module references for `HTTP`/`JSON3` used by `Diagnoser`.

### Changed
- **Version consistency**: Aligned module runtime version constant with package metadata (`0.3.0-alpha`).

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

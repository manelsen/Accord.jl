# Changelog

All notable changes to this project will be documented in this file.

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

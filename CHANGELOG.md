# Changelog

All notable changes to this project will be documented in this file.

## [0.4.0] - Unreleased

### Breaking
- **Smaller export list.** `using Accord` now exports types, events, the command macros (`@slash_command`, `@option`, `@check`, …) and Discord-specific functions (`create_message`, `wait_for`, `sync_commands!`, …). Generic names are `public` but no longer exported, so they cannot clash with other packages: `start`, `stop`, `on`, `on_error`, `@on`, `respond`, `defer`, `followup`, `target`, `custom_id`, `get_option(s)`, `selected_values`, `modal_values`, the check guards (`has_permissions`, `is_owner`, `is_in_guild`, `cooldown`), every component/embed builder (`button`, `action_row`, `embed`, `@embed`, `section`, `container`, …), `timestamp`, `has_flag`, `Optional`, `Nullable`, `Internals` and the voice verbs (`connect!`, `play!`, `stop!`, …). Use `Accord.respond(...)` or `using Accord: respond`.
- **Client-first REST API.** Every REST endpoint now accepts a `Client` in place of `(rl; token)`: `Accord.list_auto_moderation_rules(client, guild_id)` instead of `list_auto_moderation_rules(client.ratelimiter, guild_id; token=client.token)`. The `RateLimiter` form remains as the internal layer. Endpoints are public; the list is `Accord.REST_ENDPOINTS`.
- `create_message(client, ...)` accepts `poll`, `flags` and `allowed_mentions`.
- **CLI split out**: the `accord` command-line tool (`onboard`, `doctor`) moved to the `AccordCLI` package in `AccordCLI/`. `Accord` no longer depends on `Comonicon`, `Pkg` or `UUIDs`, and `Accord.AccordCLI` is gone.
- **Voice transport encryption**: only `aead_aes256_gcm_rtpsize` (preferred, when the CPU has hardware AES) and `aead_xchacha20_poly1305_rtpsize` are supported. The `xsalsa20_poly1305*` modes, discontinued by Discord on 2024-11-18, were removed together with their functions and `CRYPTO_SECRETBOX_*` constants. `Accord.Internals` exposes `encrypt_rtpsize`, `decrypt_rtpsize` and `aes256gcm_available` instead.
- Removed the unused `CodecZlib` dependency and the `GatewaySession.zlib_buffer` field (Accord never requested gateway compression).

### Fixed
- **Rate-limit majors come from the path.** `Route` reads the channel, guild and webhook id (and a token fingerprint) from the path itself; the 141 hand-written `major_params` arguments are gone. Nine endpoints had forgotten them (interaction follow-ups, `/users/@me/guilds/...`).
- **Gateway events no longer mutate their input.** Four event decoders `pop!`-ed `guild_id` out of the payload Dict they were given.
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
- **State cache crash**: `GUILD_CREATE` and `GUILD_MEMBER_ADD` crashed on members whose `user` is `null` (only `missing` was checked). Found by JET.
- **CI was red on current Julia**: JET was capped at 0.11, which cannot install on Julia 1.12+, so the test environment never resolved. The docs build also failed (undefined binding in an `@docs` block, 14 docstrings missing from the manual); unresolved cookbook `@ref`s are now warnings.
- **Project templates**: the bot template and example projects declared `Accord = { path = ... }` under `[deps]`, which is not a valid Project.toml, so scaffolded bots could not be instantiated. They now use Accord's UUID (with `[sources]` for the in-repo examples).

### Changed
- **Direct event decoding.** `@discord_struct` accepts a supertype, and 39 flat gateway events are declared with it and decode straight from the JSON string. That removes their hand-written constructors and every `JSON3.read(JSON3.write(x))` round trip on the event hot path. Timestamp fields on these events (`InviteCreate.created_at`, `GuildMemberUpdate.joined_at`, …) now return `DateTime`, like the same fields on resource types.
- **One message payload builder** (`_message_body`) behind `create_message`, `reply`, `edit_message`, `respond`, `followup`, `edit_response` and `defer`. `respond` and `followup` gained `flags`, `allowed_mentions`, `poll` and `tts`; `reply` forwards every `create_message` keyword. `edit_message(client, ...)` now omits keywords passed as `nothing` instead of sending `null`.
- Component and embed builders share one optional-field helper; the four entity select menus share one implementation. `user_select`, `role_select`, `mentionable_select` and `channel_select` are now public.
- `@user_command`/`@message_command` and the six `@slash_command` forms share one code path.
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

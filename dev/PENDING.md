# Pending work

Handoff notes for Accord.jl v0.4.0 (unreleased), written 2026-10-31. Delete
items as they are done; delete the file when it is empty.

## 1. Merge the open PRs, in order

| PR | Branch → base | What |
|---|---|---|
| #3 | `refactor/dedup` → `master` | Deduplication and idiomatic-Julia sweep |
| #4 | `feat/threads` → `master` | I/O loops on the `:interactive` pool, handlers in parallel (contains #3) |
| #5 | `feat/dave` → `feat/threads` | DAVE end-to-end encryption via libdave |
| #6 | `feat/dpy-parity` → `feat/dave` | API coverage aligned with discord.py 2.7 |

All four are drafts with green CI. Merge #3 → #4 → #5 → #6 with merge commits
(as #1 and #2 were). The repo has `delete_branch_on_merge = false`, so after
merging #4, retarget #5 to `master` (and #6 after #5), or delete the merged
branch so GitHub retargets automatically.

Afterwards delete the leftover branches: `fix/review-non-dave`,
`refactor/api-surface`, `ci/baseline`, and the merged feature branches.

## 2. Validate DAVE against Discord

CI only tests the state machine against a mock and libdave's local behaviour;
a real MLS handshake needs Discord's signed external sender.

1. Build libdave (commands in `docs/src/cookbook/05-voice.md`) and set
   `ACCORD_LIBDAVE` to the `.so`/`.dylib`.
2. Run a bot with `julia -t auto,1`, join a voice channel **with a human in
   it**, and `play!` something.
3. Expect the log line `DAVE: E2EE active` and audible audio. Then have a
   second person join and leave (exercises proposals → commit → transition).
4. Without `ACCORD_LIBDAVE`, Discord closes with 4017 and Accord logs how to
   fix it; check that message is clear.

Relevant code: `src/voice/dave.jl` (state machine), `src/voice/libdave.jl`
(ccall bindings), `src/voice/connection.jl` (voice gateway v8).

## 3. Ship libdave as a JLL

There is no `libdave_jll`. A draft, **untested** recipe is in
`dev/yggdrasil/L/libdave/build_tarballs.jl` (libdave v1.2.2 + mlspp built
from source against `OpenSSL_jll`, bypassing vcpkg). Submit it to
JuliaPackaging/Yggdrasil and iterate there. Once registered:

- add `libdave_jll` as a dependency and load it by default in `LibDave`;
- keep `ACCORD_LIBDAVE` / `LibDave.load!(path)` as an override;
- simplify the CI `dave` job (no source build) and the voice docs.

Until then, every user has to compile libdave themselves; discord.py,
discord.js and nostrum install a prebuilt DAVE implementation (`davey`).

## 4. Decide on the release

Registering 0.4.0 (`@JuliaRegistrator register` on the merge commit) is the
owner's call. `CHANGELOG.md` lists everything under `[0.4.0] - Unreleased`,
including the breaking changes.

## 5. Known bugs and gaps in the code

- **`Maybe` loses null vs absent on decode.** JSON3 reads a JSON `null` into a
  `Union{T, Missing, Nothing}` field as `missing`, not `nothing` (found in #6's
  tests: `primary_guild: null`, `accent_color: null`, `status: null`). So the
  distinction `Maybe` exists to keep does not survive parsing. Fix in the
  StructTypes/JSON3 layer (e.g. a custom construct for `Maybe` fields) and add
  round-trip tests; docstrings that promise `nothing` for null are then right.
  `Optional{Any}` fields (e.g. `Component.value`) do get `nothing`.
- **`CommandTree` has no lock.** Its handler dicts are mutated by
  `register_*!` and read by dispatch, which now runs on multiple threads (#4).
- **Example templates call functions that don't exist**: `fetch_guild` and
  `fetch_guild_channels` in `examples/templates/modules/{utils,music,starboard}/code.jl`
  and in a docstring example in `src/types/guild.jl:79`. Use `get_guild` /
  `get_guild_channels` (or the cache).
- **Select menus in modals** can't set `required` (Discord defaults it to
  true); add a `required` keyword to the select builders.
- **Voice receive is not implemented.** The DAVE `Decryptor` binding exists,
  but there is no audio receive path, so the transcription section of
  `docs/src/cookbook/05-voice.md` describes something Accord can't do (the
  page says so).

## 6. Discord API features still missing

Beyond discord.py 2.7 parity (#6), from Discord's changelog up to 2026-10-30:

- Guild message search (`GET /guilds/{id}/messages/search`).
- Effective permission endpoints (guild/channel × member/role, 2026-10-30).
- Invite target users (`target_user_ids`, add/remove/bulk endpoints).
- Editing attachments (`description`, `is_spoiler`) on existing messages.
- Large bot sharding: `max_concurrency` identify buckets, and the now
  mandatory `shard` query param of `get_current_user_guilds`.
- Identify `capabilities` (channel obfuscation opt-in, testing only).
- Smaller fields: `Application.flags_new`, `content_scan_metadata` on
  unfurled media, the `components` embed type.
- Docstrings still link to `discord.com/developers/docs/...`, which now
  redirects to `docs.discord.com/developers/...`.

## 7. Notes for whoever picks this up

- Test categories: `Pkg.test(test_args=["unit"|"integration"|"dave"|"quality"|"all"])`;
  the default skips Aqua and JET. Run with threads (`-t 4,1`); CI fails if
  the suite isn't actually multithreaded.
- The `dave` category with `ACCORD_REQUIRE_LIBDAVE=1` fails instead of
  skipping when libdave is missing.
- CI triggers on PRs to `master`, `feat/**` and `refactor/**`, so stacked PRs
  get CI.
- The cloud session that wrote this could not read raw GitHub Actions logs
  (403). It surfaced failures with a temporary wrapper,
  `.github/scripts/annotate_failure.sh` (see commit `9878ae5`), that turns
  failing output into annotations. Not needed where `gh run view --log` works.

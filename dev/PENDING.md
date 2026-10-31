# Pending work

Handoff notes for Accord.jl v0.4.0 (unreleased), written 2026-10-31. Delete
items as they are done; delete the file when it is empty.

## 1. Validate DAVE against Discord

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

## 2. Ship libdave as a JLL

There is no `libdave_jll`. A draft, **untested** recipe is in
`dev/yggdrasil/L/libdave/build_tarballs.jl` (libdave v1.2.2 + mlspp built
from source against `OpenSSL_jll`, bypassing vcpkg). Submit it to
JuliaPackaging/Yggdrasil and iterate there. Once registered:

- add `libdave_jll` as a dependency and load it by default in `LibDave`;
- keep `ACCORD_LIBDAVE` / `LibDave.load!(path)` as an override;
- simplify the CI `dave` job (no source build) and the voice docs.

Until then, every user has to compile libdave themselves; discord.py,
discord.js and nostrum install a prebuilt DAVE implementation (`davey`).

## 3. Decide on the release

Registering 0.4.0 (`@JuliaRegistrator register` on the merge commit) is the
owner's call. `CHANGELOG.md` lists everything under `[0.4.0] - Unreleased`,
including the breaking changes.

## 4. Known bugs and gaps in the code

- **Voice receive is not implemented.** The DAVE `Decryptor` binding exists,
  but there is no audio receive path, so the transcription section of
  `docs/src/cookbook/05-voice.md` describes something Accord can't do (the
  page says so).

## 5. Discord API features still missing

Beyond discord.py 2.7 parity (#6), from Discord's changelog up to 2026-10-30:

- Identify `capabilities` (channel obfuscation opt-in). Discord calls it a
  temporary, testing-only opt-in that will change before GA, so it was left out.
- `Application.flags_new`: there is no `Application` type yet
  (`get_current_application` returns a Dict), so the field is already readable.

## 6. Notes for whoever picks this up

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

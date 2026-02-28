# TODO (2026-02-26)

## QA Static Guild

- [ ] Create a dedicated QA bot/token (do not use production token).
- [ ] Revoke/rotate tokens already exposed in chat/log.
- [ ] Configure secrets (local `.env` and GitHub Actions) for live smoke tests.
- [ ] Create a single smoke runner (e.g., `scripts/run_all_smokes.jl` or `make smoke-live`) to execute:
    - [x] `scripts/smoketest_exercise.jl`
    - [x] `scripts/smoketest_slash.jl`
    - [x] `scripts/smoketest_endurance.jl` (with short `ENDURANCE_HOURS`)
- [ ] Add CI/manual workflow with these secrets to run smokes before release.
- [ ] Define release gate: only publish when `default + quality + smokes` are green.

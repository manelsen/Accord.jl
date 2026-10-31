# PLAN-reliability-sprint.md

Sprint plan to elevate Accord's reliability focusing on fixture-based contract tests.

Created at: 2026-02-25

---

## Sprint Objective

Create the operational base for broad Discord event coverage without depending on network in CI:

1. Detect parsing/serialization regressions before merge.
2. Reduce drift between real API payloads and internal models.
3. Increase predictability of refactors in gateway, types, and REST.

---

## Current Baseline (start of sprint)

- `EVENT_TYPES` mapped in gateway: 74.
- Gateway DISPATCH fixtures available: 7 (`HELLO` and `HEARTBEAT_ACK` not included).
- REST fixtures available: 9.
- Total payloads in manifest: 24 (average 1.33 per category).
- Categories with existing fixtures but no dedicated semantic validation:
  - `gateway_message_delete`
  - `gateway_message_update`
  - `gateway_thread_create`
  - `rest_get_emojis`

---

## Reliability Strategy (Cost x Benefit)

Sprint priority (execution order):

1. **Contract Drift Guard** (low cost, very high benefit)
2. **Expansion of real fixtures + semantic validation** (medium cost, high benefit)
3. **Deterministic replay + gateway fault injection** (medium cost, high benefit)
4. **Quality gates in CI (Aqua/JET + contract suites)** (low cost, high benefit)

The goal of total event coverage remains valid but will be achieved in phases.

---

## Deliverable Scope in 1 Sprint

### 1) Fixture coverage guardrails

- Add automatic checker (script or test) that:
  - reads `EVENT_TYPES`;
  - maps present gateway/rest fixtures;
  - fails when required category is missing;
  - generates text report for CI.

**Acceptance Criteria**
- PR fails if it removes a required fixture or if a new supported event lacks declared coverage.

### 2) Semantic validation of existing fixtures

- Create dedicated blocks for categories that currently only enter generic parsing:
  - `gateway_message_delete`
  - `gateway_message_update`
  - `gateway_thread_create`
  - `rest_get_emojis`

**Acceptance Criteria**
- Each existing category has at least 1 semantic test (not just "parse without crash").

### 3) High-risk fixtures expansion

- Gateway (sprint minimum target): add fixtures for high-impact operational events:
  - `GUILD_MEMBER_ADD`, `GUILD_MEMBER_UPDATE`, `GUILD_MEMBER_REMOVE`
  - `MESSAGE_REACTION_ADD`, `MESSAGE_REACTION_REMOVE`
  - `VOICE_STATE_UPDATE`, `VOICE_SERVER_UPDATE`
  - `AUTO_MODERATION_ACTION_EXECUTION` (real, not just optional)
- REST (sprint minimum target): expand fixtures for resources with higher payload volatility:
  - webhooks, invites, stickers, automod, scheduled events, soundboard

**Acceptance Criteria**
- +10 new fixture categories in the manifest (minimum target).
- Each new category with minimum semantic validation.

### 4) Deterministic fault injection

- Strengthen gateway/rate limiter tests with deterministic scenarios:
  - delayed/missing heartbeat;
  - reconnect and invalid session;
  - REST 429 response with bucket headers.

**Acceptance Criteria**
- Scenarios reproducible locally/CI without network dependency.

---

## Julia Tools (current project ecosystem)

- `Test` (stdlib): assertions, `@testset`, deterministic regression.
- `ReTestItems.jl`: granular execution by tags (`:unit`, `:integration`, `:quality`), parallelism, and JUnit report.
- `Aqua.jl`: package quality checks.
- `JET.jl`: static analysis of inference/errors.
- `JSON3.jl`: round-trip and payload contract validation.
- `HTTP.jl` internal mocks already used in REST suite.

No new mandatory dependencies for this sprint.

---

## Sprint Progress (Days 1-10)

- [x] **Day 1-2**: Implemented `fixture_coverage_check` + integration in runner (`test/integration/fixture_coverage_test.jl`).
- [x] **Day 3-4**: Semantic validation for `MESSAGE_DELETE`, `MESSAGE_UPDATE`, `THREAD_CREATE`, and `rest_get_emojis`.
- [x] **Day 5-7**: Captured fixtures for `VOICE_STATE_UPDATE`, `MESSAGE_REACTION_ADD`, `GUILD_MEMBER_UPDATE`, and internal voice events.
- [x] **Day 8**: Added deterministic **Fault Injection** scenarios (`test/unit/fault_injection_test.jl`) for 429/Rate Limiter and Missed Heartbeat.
- [x] **Day 9**: Created consolidated smoke test runner (`scripts/run_all_smokes.jl`).
- [x] **Day 10**: Review of core models (`User`, `Member`) and introduction of `Maybe{T}` type for resilience.

---

## Rollout Checklist (0.3.0 Stable)

- [x] Run `test/unit/fault_injection_test.jl` and ensure pass on 429/heartbeat.
- [x] Verify fixture coverage with `test/integration/fixture_coverage_test.jl`.
- [x] Execute `scripts/run_all_smokes.jl` in sandbox Guild with QA token.
- [x] Manually validate on Discord:
    - [x] Components (buttons/selects) in messages.
    - [x] Chained modals.
    - [x] Voice: join/leave and play short audio.
- [x] Rotate `DISCORD_TOKEN` if exposed in logs during the sprint.
- [x] Release tag and `CHANGELOG.md` update.

---

## Sprint Definition of Done

1. CI fails on fixture contract regression.
2. All existing fixture categories have dedicated semantic validation.
3. Manifest gains at least 10 new categories with tests.
4. Reliability suite runs offline (no token/network) and remains deterministic.
5. Operational documentation updated for fixture cycle maintenance.

---

## Next Steps (post-sprint)

1. Progressive coverage up to 100% of supported events in `EVENT_TYPES`.
2. Fixture refresh policy (e.g., biweekly or per release).
3. Optional: introduce property-based testing for events with highly combinatory payloads.

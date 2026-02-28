# DECISIONS.md — Accord.jl Architecture Decision Records

Formal record of design decisions with non-obvious impact.
Each entry follows the ADR (Architecture Decision Record) format.

---

## ADR-001 — HandlerGroup instead of Cogs system

**Date:** 2026-02-23
**Status:** Accepted
**Context:** v0.4.0 Planning (parity with discord.py)

### Context

The functional parity plan with discord.py (v0.4.0) included, as M6,
the implementation of a Cogs system — the discord.py abstraction that
groups related commands, event listeners, and state into a Python class
with a load/unload lifecycle.

The problem Cogs solve has three parts:
1. **Organization** — grouping related handlers into a named unit.
2. **Shared State** — a group of handlers (e.g., music module)
   needs common state (queues, players) accessible among them.
3. **Runtime load/unload** — enabling or disabling a set of
   features without restarting the bot.

### Decision

**Do not implement Cogs.** Implement `HandlerGroup` — a minimal
abstraction that solves only problem (3), the only one Julia doesn't
natively solve.

Approved API:

```julia
# Create named group
group = HandlerGroup("music")

# Register handlers in the group (same public API as always)
@slash_command group "play" "Plays a song" begin
    ...
end
@slash_command group "stop" "Stops playback" begin
    ...
end
@on group MessageCreate begin
    ...
end

# Load into the client (registers all group handlers at once)
load!(client, group)

# Unload at runtime (removes all group handlers)
unload!(client, "music")
```

### Justification

**Why Cogs don't make sense in Julia:**

Cogs exist in Python because the language offers no other mechanism for
associating functions with shared state without classes. The
`@commands.command` decorator on an instance method only works because there is a
class (`self`) underneath.

Julia already solves problems (1) and (2) with native mechanisms:

- **Organization (1):** Julia modules are the natural unit of namespacing.
  A `cogs/music.jl` file with `module Music ... end` already solves this
  without any library code.

- **Shared State (2):** closures capture state seamlessly.
  A `Dict` defined before the handlers is automatically accessible in all
  of them — no `self`, no class instance.

```julia
# Julia: shared state via closure, no extra abstraction
queue = Dict{Snowflake, Vector{String}}()

@slash_command client "play" "Play" begin
    push!(queue[ctx.guild_id], get_option(ctx, "url"))
end

@slash_command client "skip" "Skip" begin
    popfirst!(queue[ctx.guild_id])
end
```

The only problem Julia **doesn't** solve natively is (3): there is no
built-in mechanism to remove at runtime a named set of handlers
already registered in the `CommandTree`. `HandlerGroup` solves exactly this.

**Why not just Julia modules with `register!(client)`:**

This solves (1) and (2) but completely sacrifices (3). The bot would need
to restart to deactivate a module.

### Consequences on v0.4.0 plan

Requirements RF-009, RF-010, RF-011, and RS-003 of the original plan are
replaced:

| Original | Replaced by |
|---|---|
| RF-009 `load_cog!(client, cog)` | RF-009 `load!(client, group::HandlerGroup)` |
| RF-010 `unload_cog!(client, name)` | RF-010 `unload!(client, name::String)` |
| RF-011 `@cog` macro | RF-011 `HandlerGroup(name)` simple constructor |
| RS-003 cog name collision | RS-003 group name collision (no change) |

**Impact on exports:** replace `load_cog!`, `unload_cog!`, `@cog`,
`AbstractCog` with `load!`, `unload!`, `HandlerGroup`.

**Impact on files:** `src/interactions/cog.jl` → rename to
`src/interactions/handler_group.jl`.

### Alternatives considered

| Alternative | Reason for rejection |
|---|---|
| Direct port of Cogs (struct + `@cog` macro) | Python-OOP pattern without an idiomatic equivalent in Julia; adds complexity without benefit |
| Just Julia modules + `register!` convention | Doesn't solve runtime load/unload |
| No abstraction (without M6) | Large bots without a load/unload mechanism have poor DX for optional features |

### References

- Internal discussion: design meeting 2026-02-23
- discord.py Cogs: https://discordpy.readthedocs.io/en/stable/ext/commands/cogs.html
  (design reference, not Discord API reference)

---

## ADR-002 — Reliability Strategy based on Contract Tests with Fixtures

**Date:** 2026-02-25
**Status:** Accepted
**Context:** Parser/event/REST robustness against Discord API drift

### Context

Accord already has good unit coverage and integration with mocks, but
real fixtures still cover a fraction of the supported surface (gateway
and REST). This increases the risk of silent regression in changes to:

1. Types (`@discord_struct`, `Optional`/`Nullable`)
2. Event dispatch (`EVENT_TYPES`)
3. Parsing of REST responses

For a resilient library, the point of failure detection must be
the PR (CI), not production.

### Decision

Adopt as a reliability standard a hybrid model:

1. **Contract tests with fixtures** as the primary guardrail.
2. **Captured real fixtures** whenever feasible.
3. **Synthetic fixtures validated by contract** when an event is rare or
   difficult to reproduce in a capture environment.
4. **Coverage gate in CI** to prevent contract regression.

### Consequences

1. The project now requires active maintenance of the fixture inventory.
2. New supported events/routes must be accompanied by declared coverage
   (fixture + test).
3. Refactors in gateway/types/REST become safer and more predictable.
4. The initial cost of fixture curation increases, but with a reduction of
   integration bugs in the medium term.

### Scope of the first sprint

Initial execution is documented in:

- `docs/PLAN-reliability-sprint.md`

This plan defines the baseline, measurable goals, backlog by cost/benefit,
Julia tools used, and Definition of Done.

### Alternatives considered

| Alternative | Reason for rejection |
|---|---|
| Maintain only synthetic mocks | Good for route/method, weak against real payload drift |
| Aim for 100% real events in one sprint | Not realistic for rare/conditional events |
| Rely only on manual tests with online bot | High operational cost and low reproducibility |

### References

- Fixtures manifest: `test/integration/fixtures/_manifest.json`
- Supported events mapping: `src/gateway/events.jl` (`EVENT_TYPES`)
- Execution plan: `docs/PLAN-reliability-sprint.md`

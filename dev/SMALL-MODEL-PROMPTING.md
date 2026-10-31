# Small Model Prompting Manual

Practical guide to extract more useful answers from models with less context and limited planning capability.

Date: 2026-02-25

---

## 1) Core Principles

1. One task at a time.
2. Explicit and verifiable goal.
3. Clear scope boundaries (`what's allowed` and `what's not`).
4. Fixed output format.
5. Single validation command.
6. Definition of Done checklist.
7. Avoid vague language ("improve", "optimize everything", "make it better").

---

## 2) Standard Structure (Copy and fill)

```md
Context:
- Project: Accord.jl
- Relevant files: <paths>
- Current state: <1-3 lines>

Goal:
- <single and measurable result>

Constraints:
- Do not change: <files/areas>
- Compatibility: Julia 1.11+
- No network/real token (when applicable)

Tasks:
1. <objective action 1>
2. <objective action 2>
3. <objective action 3>

Response format:
1. What was done (3-6 lines)
2. Changed files
3. Executed validation command
4. Pending items/risks (if any)

Validation:
`<exact command>`

Definition of Done:
- [ ] <objective check 1>
- [ ] <objective check 2>
- [ ] <objective check 3>
```

---

## 3) Golden Rules to Reduce Error

1. Provide input and output examples.
2. Name exact files; don't say "in the gateway part".
3. Limit delivery size ("max 3 files", "no broad refactors").
4. Ask not to assume context outside the prompt.
5. Prefer numbered steps.
6. If the task is large, break it into independent phases.

---

## 4) Anti-patterns and Better Versions

### Bad
`Refactor this whole part and make it robust.`

### Better
`Change only src/gateway/dispatch.jl to standardize parse errors with three fields: what_failed, why, fix_now. Do not change public APIs. Add test in test/unit/gateway_test.jl.`

### Bad
`Fix the breaking tests.`

### Better
`Run only the default suite. Fix only failures in test/unit/parsing_test.jl. Do not change integration tests.`

### Bad
`Improve the lib onboarding.`

### Better
`Implement a minimal doctor command in src/diagnostics/Diagnoser.jl with checks for token/intents/voice libs. Return actionable messages with fix commands.`

---

## 5) Ready-to-use Templates (Accord.jl)

## Template A: Small and Safe Implementation

```md
Context:
- Project: Accord.jl
- Files: src/diagnostics/Diagnoser.jl, test/unit/<file>.jl

Goal:
- Implement <feature> without breaking public API.

Constraints:
- Do not change src/Accord.jl exports.
- Max 2 code files + 1 test file.

Tasks:
1. Implement <feature> in <file>.
2. Add tests covering success and failure.
3. Keep error messages action-oriented.

Validation:
`ACCORD_TEST_WORKERS=1 julia --project=. -e 'using Pkg; Pkg.test(test_args=["default"])'`

Definition of Done:
- [ ] Tests passing locally.
- [ ] No regression in existing behavior.
- [ ] Response lists files and risks.
```

## Template B: Update Kanban/backlog without ambiguity

```md
Update only KANBAN.md.

Goal:
- Reflect real state of items R3-R6.

Instructions:
1. Do not change sections P1/P2/P3.
2. Mark status only with evidence in code/tests.
3. Keep item IDs.

Response format:
1. Changed items
2. Reason for each change
3. Line references in the file
```

## Template C: Objective Debug

```md
Problem:
- <exact error>

Scope:
- Investigate only <files>.

Tasks:
1. Reproduce error with <command>.
2. Identify root cause in 1-2 lines.
3. Fix with smallest possible diff.
4. Add/adjust failing test.

Validation:
`<exact command>`
```

---

## 6) Recovery Protocol (when the model "gets lost")

Use this short prompt to reset:

```md
Stop and reset context.

You went out of scope. Continue only with:
- Goal: <goal>
- Allowed files: <list>
- Forbidden changes: <list>
- Mandatory validation: <command>

Respond only with:
1. 3-step plan
2. applied diff
3. validation result
```

---

## 7) "Good Prompt" Criteria (quick checklist)

- [ ] Has a single goal?
- [ ] Defines specific files?
- [ ] Defines what is out of scope?
- [ ] Requires validation with exact command?
- [ ] Defines response format?
- [ ] Defines Definition of Done?

If any item above is "no", rewrite before sending.

---

## 8) Low Credit Strategy (high yield per prompt)

1. Start with atomic tasks (20-40 min each).
2. Reuse templates; change only variables.
3. Avoid asking for broad exploration in the same prompt.
4. Require short and structured output.
5. Chain prompts in a pipeline:
   1. diagnosis
   2. minimal fix
   3. test
   4. documentation

---

## 9) Master Prompt (reusable)

```md
Project: Accord.jl

Goal:
- <single goal>

Allowed scope:
- <files>

Out of scope:
- <files/areas>

Technical constraints:
- Julia 1.11+
- Minimal change
- No real network/token

Mandatory deliverables:
1. Code
2. Test
3. Executed validation
4. Final summary with changed files

Mandatory validation:
`<command>`

Definition of Done:
- [ ] <item 1>
- [ ] <item 2>
- [ ] <item 3>
```

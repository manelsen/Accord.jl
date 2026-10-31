# PLAN: Documentation Overhaul (v0.3.0 → v0.4.0)

**Context:** Comparative analysis with discord.py, Discord.js, Serenity (Rust), and Nostrum (Elixir).

## 1. Goal: Parity with Industry Leaders
Accord.jl aims to be as intuitive as discord.py while maintaining the performance and type safety of Julia.

### 1.1. Missing Feature Gap
| Feature | Discord.py | Accord.jl | Priority |
|---|---|---|---|
| Context Menu Commands | ✅ | ❌ | High |
| Component Decorators | ✅ | ❌ | High |
| Cog-like modularity | ✅ | ⚠️ (Modules) | Medium |
| Webhook support | ✅ | ⚠️ (Partial) | Medium |

### 1.2. Documentation Standard
| Standard | Discord.py | Discord.js | Serenity | Accord.jl |
|---|---|---|---|---|
| Type annotations | ✅ | ✅ | ✅ | ⚠️ |
| Context phrase ("when/why") | ✅ | ✅ | ✅ | ❌ |
| Code examples per method | ✅ | ⚠️ | ⚠️ | ⚠️ |

## 2. Implementation Plan

### 2.1. Component UI Refresh
Implement a more ergonomic way to handle buttons and selects using Julia macros.

### 2.2. Documentation Overhaul
- Every docstring must have: 1 context phrase, main fields, link to Discord API docs.
- Create a "Why Julia?" section in the cookbook.

## 3. Backlog

1. **P1.1** Implement `@message_command` and `@user_command` macros.
2. **P1.2** Refactor Component handling to use a centralized state.
3. **P1.3** Context phrases in existing docstrings.
4. **P2.1** Cookbook: Recipe 15 (Why Julia?) and Recipe 16 (AI Agent).

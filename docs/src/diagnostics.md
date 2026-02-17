# Elm-like Diagnostics

Accord.jl takes inspiration from the Elm programming language's philosophy: **Error messages should be helpful, friendly, and didactic.**

Instead of dumping a raw stacktrace or a cryptic JSON error code, Accord.jl attempts to intercept common failure modes and present them in a structured, readable format.

## The "Double-Pareto" Philosophy

The Discord API defines hundreds of error codes. However, based on our analysis, **99% of developer support tickets** stem from fewer than 30 specific errors.

Accord.jl implements a "Double-Pareto" strategy:
1.  **Identify the Top 30 Errors** (The 20% of errors causing 80% of pain).
2.  **Provide Top-Tier Diagnostics** for these specific cases.
3.  **Fallback to Standard Errors** for the long tail of rare edge cases.

This ensures the library remains lightweight while maximizing developer experience (DX) where it matters most.

## Matcher Categories

### 1. Setup & Configuration (Startup)
These errors occur before the bot even connects.

| Error | Code | Explanation |
| :--- | :--- | :--- |
| **Missing Token** | N/A | Token string is empty. |
| **Invalid Token** | N/A | Token contains spaces or newlines. |
| **Disallowed Intents** | `4014` | Gateway connection refused due to privileged intent mismatch. |
| **Authentication Failed** | `4004` | Token is invalid or expired. |
| **Sharding Config** | N/A | Mismatch between `num_shards` and Gateway recommendation. |

### 2. Runtime & API (Interaction)
These errors occur while the bot is running, usually due to permissions or logic.

| Error | Code | Explanation |
| :--- | :--- | :--- |
| **Missing Permissions** | `50013` | Bot lacks permission to perform action (e.g., Ban). |
| **Unknown Channel** | `10003` | Sending message to a deleted channel. |
| **Unknown Message** | `10008` | Editing/Deleting a non-existent message. |
| **Unknown Interaction** | `10062` | Interaction token expired (taken >3s to respond). |
| **Rate Limit** | `429` | Global or bucket rate limit exceeded. |
| **Invalid Form Body** | `50035` | Validation error (e.g., Embed too big, Malformed payload). |
| **Empty Message** | `50006` | Sending a message with no content/embeds. |

### 3. Development & Logic
These are detected via static analysis hooks or runtime checks.

*   **Blocking Event Loop**: (Planned) Detects long-running blocking calls in async handlers.
*   **Handler Arity**: (Planned) Detects incorrect arguments for `@on_message`.

## Example Output

When a diagnostic is triggered, Accord.jl prints a box like this:

```text
┌── MISSING PRIVILEGED INTENT ───────────────────────────────┐
│                                                            │
│  I cannot access `message.content` because the             │
│  Message Content Intent is missing.                        │
│                                                            │
│   > defined at bot.jl:14                                   │
│                                                            │
│   14 |   if message.content == "!ping"                     │
│                     ^^^^^^^                                │
│                                                            │
│  Explanation:                                              │
│  Discord does not send message content unless the          │
│  privileged intent is enabled in both the Developer        │
│  Portal and your Client config.                            │
│                                                            │
│  Fix:                                                      │
│  1. Enable "Message Content Intent" in Dev Portal.         │
│  2. Add `intents=IntentMessageContent` to Client().        │
│                                                            │
│  Docs: https://manelsen.github.io/Accord.jl/dev/intents    │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

## API Reference

```@docs
Accord.Diagnoser.Diagnostic
Accord.Diagnoser.report
```

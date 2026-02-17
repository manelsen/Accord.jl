# Accord-Omni Capstone

Welcome to **Accord-Omni**, the "Gold Standard" architectural template for building complex, scalable Discord bots with **Accord.jl**.

This project demonstrates how to build a bot with the complexity of MEE6 or Avrae, using modern Julia patterns.

## 🏗️ Architecture

Accord-Omni uses a **Vertical Slice** architecture (Feature-First) combined with **Repository Pattern** and **FunSQL.jl** for data access.

### Why Vertical Slices?
Instead of separating code by technical layers (`commands/`, `events/`), we separate by **Feature** (`levels/`, `moderation/`).
This keeps related code together. If you want to delete the Music feature, you just delete `src/features/music/`.

### Directory Structure

```text
src/
├── core/                  # Shared infrastructure (DB, Types)
│   ├── database.jl        # SQLite connection
│   └── types.jl           # OmniState
├── features/              # Vertical Slices
│   ├── levels/            # XP & Ranking System
│   │   ├── mod.jl         # Controller (Commands & Events)
│   │   ├── service.jl     # Business Logic (Pure Julia)
│   │   └── repository.jl  # Data Access (FunSQL)
│   └── moderation/        # Ban/Kick/Warn System
│       ├── mod.jl
│       ├── service.jl
│       └── repository.jl
└── run.jl                 # Entry point
```

## 🛠️ Tech Stack

*   **Accord.jl**: The Discord library.
*   **FunSQL.jl**: A compositional SQL query builder. Safer and more powerful than raw strings, lighter than an ORM.
*   **SQLite.jl**: Robust local database.
*   **Layered Design**:
    *   **Controller (`mod.jl`)**: Handles Discord interactions (`ctx`, `Message`). Calls Service.
    *   **Service**: Pure business logic. Doesn't know about Discord. Calls Repository.
    *   **Repository**: Knows SQL/Database. Returns plain data (NamedTuples).

## 🚀 Getting Started

1.  **Instantiate Dependencies:**
    ```bash
    julia --project=. -e 'using Pkg; Pkg.instantiate()'
    ```

2.  **Run Tests (Verify Architecture):**
    ```bash
    julia --project=. test/runtests.jl
    ```

3.  **Run Bot:**
    ```bash
    export DISCORD_TOKEN="your_token_here"
    julia --project=. run.jl
    ```

## 📚 Key Concepts Demonstrated

*   **State Injection:** Using `ctx.client.state` to pass the Database connection.
*   **Repository Pattern:** Decoupling SQL from commands.
*   **Safe Data Access:** Using `FunSQL` to prevent SQL Injection and `coalesce` to handle missing data safely.
*   **Testability:** How to test bot logic without connecting to Discord (see `test/runtests.jl`).

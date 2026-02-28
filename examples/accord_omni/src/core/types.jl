module CoreTypes

using Accord
using SQLite

# Helper function to get DB connection from within a command
# In a real bot, this could be more complex (e.g., connection pooling)
struct OmniState
    db::SQLite.DB
    boot_time::Float64
end

# Each feature must implement an `install(client)` function
# to register its commands and handlers.

end

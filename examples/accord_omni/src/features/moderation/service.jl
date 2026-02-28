module Service

using Accord
using ..Repository

# Business Logic
function log_action(db, guild_id, target_id, mod_id, type, reason)
    return Repository.insert_log(db, guild_id, target_id, mod_id, type, reason)
end

function get_history(db, guild_id, target_id)
    return Repository.fetch_logs(db, guild_id, target_id)
end

function check_automod(content::String)
    # Simple example: prohibited word check
    prohibited = ["badword", "spamexample"]
    for word in prohibited
        if occursin(word, lowercase(content))
            return true
        end
    end
    return false
end

end

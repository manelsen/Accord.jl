module Service

using Dates
using ..Repository

# Lógica de Negócio

function log_action(db, guild_id::Int, user_id::Int, moderator_id::Int, type::String, reason::String)
    ts = datetime2unix(now())
    case_id = Repository.add_case(db, guild_id, user_id, moderator_id, type, reason, ts)
    return case_id
end

function get_history(db, guild_id::Int, user_id::Int)
    return Repository.get_user_history(db, guild_id, user_id)
end

function check_automod(content::String)
    # Lista proibida hardcoded (num bot real, viria do DB por guilda)
    bad_words = [r"badword", r"spam"]
    
    for pattern in bad_words
        if occursin(pattern, lowercase(content))
            return true
        end
    end
    return false
end

end

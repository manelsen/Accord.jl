module Service

using Dates
using ..Repository

const XP_COOLDOWN = 60.0 # segundos
const XP_PER_MSG = 15

"""
Tenta adicionar XP ao usuário. Retorna o novo total de XP se sucesso, ou nothing se em cooldown.
"""
function process_xp(db, user_id::Int, guild_id::Int)
    now_ts = datetime2unix(now())
    entry = Repository.get_entry(db, user_id, guild_id)
    
    if isnothing(entry)
        # Primeiro XP
        Repository.create_entry(db, user_id, guild_id, XP_PER_MSG, now_ts)
        return XP_PER_MSG
    else
        # Verifica Cooldown
        if (now_ts - entry.last_ts) < XP_COOLDOWN
            return nothing
        end
        
        new_xp = entry.xp + XP_PER_MSG
        Repository.update_xp(db, user_id, guild_id, new_xp, now_ts)
        return new_xp
    end
end

function get_user_rank(db, user_id::Int, guild_id::Int)
    return Repository.get_rank(db, user_id, guild_id)
end

end

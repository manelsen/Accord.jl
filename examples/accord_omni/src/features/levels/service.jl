module Service

using Accord
using ..Repository
using Dates

# Business Logic
const XP_COOLDOWN = 60.0 # seconds
const XP_PER_MSG = 15

"""
Attempts to add XP to a user. Returns the new XP total on success, or nothing on cooldown.
"""
function process_xp(db, user_id, guild_id)
    now_ts = datetime2unix(now())
    
    # Check cooldown
    last_ts = Repository.get_user_last_msg_ts(db, user_id, guild_id)
    
    if (now_ts - last_ts) < XP_COOLDOWN
        return nothing # Cooldown active
    end
    
    # Update XP
    current_xp = Repository.get_user_xp(db, user_id, guild_id)
    new_xp = current_xp + XP_PER_MSG
    Repository.update_user_xp(db, user_id, guild_id, new_xp, now_ts)
    
    return new_xp
end

function get_user_rank(db, user_id, guild_id)
    current_xp = Repository.get_user_xp(db, user_id, guild_id)
    rank_pos = Repository.get_rank_position(db, guild_id, current_xp)
    return current_xp, rank_pos
end

end

module Moderation

using Accord
using Dates

# Load local submodules
include("repository.jl")
include("service.jl")

using .Repository
using .Service

function install(client::Client)
    db = client.state.db
    Repository.init_tables(db)
    
    # --- Slash Commands ---
    
    @slash_command client "ban" "Ban a user" function(ctx)
        # Permission: Simple check (in a real bot use @check has_permissions)
        # if !has_permission(ctx.member, :BAN_MEMBERS) ... end
        
        target = get(ctx.options, "user", nothing)
        reason = get(ctx.options, "reason", "No reason specified")
        
        if isnothing(target)
            respond(ctx, "Invalid user.", ephemeral=true)
            return
        end
        
        # 1. Execute Action on Discord
        try
            ban_member(ctx.client, ctx.guild_id, target.id; reason=reason)
        catch e
            respond(ctx, "Failed to ban: $(e)", ephemeral=true)
            return
        end
        
        # 2. Log in DB (Service Layer)
        case_id = Service.log_action(db, Int(ctx.guild_id), Int(target.id), Int(ctx.user.id), "BAN", reason)
        
        # 3. Respond
        respond(ctx, "🔨 **Banned** $(target.username) (Case #$case_id)
📄 Reason: $reason")
    end
    
    @slash_command client "kick" "Kick a user" function(ctx)
        target = get(ctx.options, "user", nothing)
        reason = get(ctx.options, "reason", "No reason specified")

        if isnothing(target)
            respond(ctx, "Invalid user.", ephemeral=true)
            return
        end
        
        try
            kick_member(ctx.client, ctx.guild_id, target.id; reason=reason)
        catch e
            respond(ctx, "Failed to kick: $(e)", ephemeral=true)
            return
        end
        
        case_id = Service.log_action(db, Int(ctx.guild_id), Int(target.id), Int(ctx.user.id), "KICK", reason)
        respond(ctx, "👢 **Kicked** $(target.username) (Case #$case_id)
📄 Reason: $reason")
    end

    @slash_command client "warn" "Warn a user" function(ctx)
        target = get(ctx.options, "user", nothing)
        reason = get(ctx.options, "reason", "No reason specified")
        
        if isnothing(target)
            respond(ctx, "Invalid user.", ephemeral=true)
            return
        end
        
        # DB only, no Discord API action other than warning
        case_id = Service.log_action(db, Int(ctx.guild_id), Int(target.id), Int(ctx.user.id), "WARN", reason)
        
        respond(ctx, "⚠️ **Warned** $(target.username) (Case #$case_id)
📄 Reason: $reason")
        
        # Try to send DM to user (silently fails if DM is closed)
        try
            dm_channel = create_dm(ctx.client, target.id)
            create_message(ctx.client, dm_channel.id; content="You received a warning in $(ctx.guild_id): $reason")
        catch end
    end
    
    @slash_command client "modlogs" "View moderation history" function(ctx)
        target = get(ctx.options, "user", ctx.user)
        
        history = Service.get_history(db, Int(ctx.guild_id), Int(target.id))
        
        fields = []
        for row in history
            dt = unix2datetime(row.created_at)
            push!(fields, embed_field(
                "Case #$(row.case_id) - $(row.type)", 
                "**Reason:** $(row.reason)
**Mod:** <@$(row.moderator_id)>
**Date:** $(dt)", 
                false
            ))
        end
        
        if isempty(fields)
            respond(ctx, "No records found for $(target.username).")
        else
            embed_data = embed(
                title = "Moderation History: $(target.username)",
                color = 0xFF0000,
                fields = fields
            )
            respond(ctx; embeds=[embed_data])
        end
    end

    # --- Automod Listener ---
    on(client, MessageCreate) do c, event
        if event.message.author.bot return end
        
        if Service.check_automod(event.message.content)
            # 1. Delete the message
            delete_message(c, event.message.channel_id, event.message.id)
            
            # 2. Log the automatic Warn
            Service.log_action(db, Int(event.message.guild_id), Int(event.message.author.id), Int(c.user.id), "WARN", "Automod: Prohibited word")
            
            # 3. Warn in channel (temporary)
            msg = create_message(c, event.message.channel_id; content="⚠️ <@$(event.message.author.id)>, watch your language! (Warning recorded)")
            # In a real bot, we would delete this warning after 5s
        end
    end
    
    @info "Feature [Moderation] loaded."
end

end

module Levels

using Accord
# Load local submodules
include("repository.jl")
include("service.jl")

using .Repository
using .Service

function install(client::Client)
    db = client.state.db
    Repository.init_tables(db)
    
    # Event: XP
    Accord.on(client, MessageCreate) do c, event
        if event.message.author.bot return end
        if isnothing(event.message.guild_id) return end
        
        new_total = Service.process_xp(db, Int(event.message.author.id), Int(event.message.guild_id))
        
        if !isnothing(new_total) && (new_total % 100 == 0)
             create_message(c, event.message.channel_id; content="🎉 <@$(event.message.author.id)> leveled up to level $(div(new_total, 100))!")
        end
    end

    # Command: Rank
    @slash_command client "rank" "View your level and XP" function(ctx)
        target_id = Accord.get_option(ctx, "user")
        target = if isnothing(target_id)
            ctx.user
        else
            # Try to get user object from cache or API
            # get_user is cache-first, so it's efficient
            get_user(ctx.client, Snowflake(target_id))
        end
        
        xp, rank_pos = Service.get_user_rank(ctx.client.state.db, Int(target.id), Int(ctx.guild_id))
        
        embed_data = Accord.embed(
            title = "Rank for $(target.username)",
            color = 0xFFD700,
            fields = [
                Accord.embed_field("Total XP", "$xp", true),
                Accord.embed_field("Position", "#$rank_pos", true),
                Accord.embed_field("Level", "$(div(xp, 100))", true)
            ]
        )
        Accord.respond(ctx; embeds=[embed_data])
    end
    
    @info "Feature [Levels] loaded (v2 - Layered Architecture)."
end

end

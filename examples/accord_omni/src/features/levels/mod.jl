module Levels

using Accord
# Carrega submódulos locais
include("repository.jl")
include("service.jl")

using .Repository
using .Service

function install(client::Client)
    db = client.state.db
    Repository.init_tables(db)
    
    # Evento: XP
    on(client, MessageCreate) do c, event
        if event.message.author.bot return end
        if isnothing(event.message.guild_id) return end
        
        new_total = Service.process_xp(db, Int(event.message.author.id), Int(event.message.guild_id))
        
        if !isnothing(new_total) && (new_total % 100 == 0)
             create_message(c, event.message.channel_id; content="🎉 <@$(event.message.author.id)> subiu para o nível $(div(new_total, 100))!")
        end
    end

    # Comando: Rank
    @slash_command client "rank" "Veja seu nível e XP" function(ctx)
        target = get(ctx.options, "user", ctx.user)
        xp, rank_pos = Service.get_user_rank(ctx.client.state.db, Int(target.id), Int(ctx.guild_id))
        
        embed_data = embed(
            title = "Rank de $(target.username)",
            color = 0xFFD700,
            fields = [
                embed_field("XP Total", "$xp", true),
                embed_field("Posição", "#$rank_pos", true),
                embed_field("Nível", "$(div(xp, 100))", true)
            ]
        )
        respond(ctx; embeds=[embed_data])
    end
    
    @info "Feature [Levels] carregada (v2 - Layered Architecture)."
end

end

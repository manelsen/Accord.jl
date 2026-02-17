module Moderation

using Accord
using Dates

# Carrega submódulos locais
include("repository.jl")
include("service.jl")

using .Repository
using .Service

function install(client::Client)
    db = client.state.db
    Repository.init_tables(db)
    
    # --- Comandos Slash ---
    
    @slash_command client "ban" "Banir um usuário" function(ctx)
        # Permissão: Check simples (num bot real seria @check has_permissions)
        # if !has_permission(ctx.member, :BAN_MEMBERS) ... end
        
        target = get(ctx.options, "user", nothing)
        reason = get(ctx.options, "reason", "Sem motivo especificado")
        
        if isnothing(target)
            respond(ctx, "Usuário inválido.", ephemeral=true)
            return
        end
        
        # 1. Executa Ação no Discord
        try
            ban_member(ctx.client, ctx.guild_id, target.id; reason=reason)
        catch e
            respond(ctx, "Falha ao banir: $(e)", ephemeral=true)
            return
        end
        
        # 2. Loga no DB (Service Layer)
        case_id = Service.log_action(db, Int(ctx.guild_id), Int(target.id), Int(ctx.user.id), "BAN", reason)
        
        # 3. Responde
        respond(ctx, "🔨 **Banned** $(target.username) (Case #$case_id)
📄 Motivo: $reason")
    end
    
    @slash_command client "kick" "Expulsar um usuário" function(ctx)
        target = get(ctx.options, "user", nothing)
        reason = get(ctx.options, "reason", "Sem motivo especificado")

        if isnothing(target)
            respond(ctx, "Usuário inválido.", ephemeral=true)
            return
        end
        
        try
            kick_member(ctx.client, ctx.guild_id, target.id; reason=reason)
        catch e
            respond(ctx, "Falha ao expulsar: $(e)", ephemeral=true)
            return
        end
        
        case_id = Service.log_action(db, Int(ctx.guild_id), Int(target.id), Int(ctx.user.id), "KICK", reason)
        respond(ctx, "👢 **Kicked** $(target.username) (Case #$case_id)
📄 Motivo: $reason")
    end

    @slash_command client "warn" "Avisar um usuário" function(ctx)
        target = get(ctx.options, "user", nothing)
        reason = get(ctx.options, "reason", "Sem motivo especificado")
        
        if isnothing(target)
            respond(ctx, "Usuário inválido.", ephemeral=true)
            return
        end
        
        # Apenas DB, sem ação no Discord API além de avisar
        case_id = Service.log_action(db, Int(ctx.guild_id), Int(target.id), Int(ctx.user.id), "WARN", reason)
        
        respond(ctx, "⚠️ **Warned** $(target.username) (Case #$case_id)
📄 Motivo: $reason")
        
        # Tenta enviar DM pro usuário (falha silenciosamente se DM fechada)
        try
            dm_channel = create_dm(ctx.client, target.id)
            create_message(ctx.client, dm_channel.id; content="Você recebeu um aviso em $(ctx.guild_id): $reason")
        catch end
    end
    
    @slash_command client "modlogs" "Ver histórico de punições" function(ctx)
        target = get(ctx.options, "user", ctx.user)
        
        history = Service.get_history(db, Int(ctx.guild_id), Int(target.id))
        
        fields = []
        for row in history
            dt = unix2datetime(row.created_at)
            push!(fields, embed_field(
                "Case #$(row.case_id) - $(row.type)", 
                "**Motivo:** $(row.reason)
**Mod:** <@$(row.moderator_id)>
**Data:** $(dt)", 
                false
            ))
        end
        
        if isempty(fields)
            respond(ctx, "Nenhum registro encontrado para $(target.username).")
        else
            embed_data = embed(
                title = "Histórico de Moderação: $(target.username)",
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
            # 1. Deleta a mensagem
            delete_message(c, event.message.channel_id, event.message.id)
            
            # 2. Loga o Warn automático
            Service.log_action(db, Int(event.message.guild_id), Int(event.message.author.id), Int(c.user.id), "WARN", "Automod: Palavra proibida")
            
            # 3. Avisa no canal (temporário)
            msg = create_message(c, event.message.channel_id; content="⚠️ <@$(event.message.author.id)>, cuidado com o linguajar! (Aviso registrado)")
            # Em um bot real, deletaríamos esse aviso após 5s
        end
    end
    
    @info "Feature [Moderation] carregada."
end

end

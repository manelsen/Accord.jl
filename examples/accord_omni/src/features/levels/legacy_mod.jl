module Levels

using Accord
using SQLite
using DBInterface
using Dates
# Importamos o Core para acessar tipos compartilhados se necessário
# mas tentamos manter desacoplado.

# --- 1. Schemas & Models (Camada de Dados) ---
function init_tables(db::SQLite.DB)
    DBInterface.execute(db, """
        CREATE TABLE IF NOT EXISTS user_xp (
            user_id INTEGER,
            guild_id INTEGER,
            xp INTEGER DEFAULT 0,
            last_message_ts REAL DEFAULT 0,
            PRIMARY KEY (user_id, guild_id)
        );
    """)
end

# --- 2. Service Logic (Regras de Negócio) ---
const XP_COOLDOWN = 60.0 # segundos
const XP_PER_MSG = 15

function add_xp(db::SQLite.DB, user_id::Int, guild_id::Int)
    now_ts = datetime2unix(now())
    
    # Verifica cooldown (simples select)
    row = DBInterface.execute(db, "SELECT last_message_ts, xp FROM user_xp WHERE user_id = ? AND guild_id = ?", [user_id, guild_id]) |> first
    
    if !ismissing(row)
        last_ts = row.last_message_ts
        if (now_ts - last_ts) < XP_COOLDOWN
            return nothing # Em cooldown
        end
        new_xp = row.xp + XP_PER_MSG
        DBInterface.execute(db, "UPDATE user_xp SET xp = ?, last_message_ts = ? WHERE user_id = ? AND guild_id = ?", [new_xp, now_ts, user_id, guild_id])
        return new_xp
    else
        # Primeiro XP
        DBInterface.execute(db, "INSERT INTO user_xp (user_id, guild_id, xp, last_message_ts) VALUES (?, ?, ?, ?)", [user_id, guild_id, XP_PER_MSG, now_ts])
        return XP_PER_MSG
    end
end

function get_rank(db::SQLite.DB, user_id::Int, guild_id::Int)
    # Pega XP do usuário
    user_row = DBInterface.execute(db, "SELECT xp FROM user_xp WHERE user_id = ? AND guild_id = ?", [user_id, guild_id]) |> first
    if ismissing(user_row) return (0, 0) end
    
    # Calcula posição no ranking
    rank = DBInterface.execute(db, "SELECT COUNT(*) as rank FROM user_xp WHERE guild_id = ? AND xp > ?", [guild_id, user_row.xp]) |> first
    
    return (user_row.xp, rank.rank + 1)
end

# --- 3. Commands & Events (Camada de Apresentação) ---

function install(client::Client)
    db = client.state.db
    init_tables(db)
    
    # Evento: Ganhar XP ao falar
    on(client, MessageCreate) do c, event
        if event.message.author.bot return end
        if isnothing(event.message.guild_id) return end
        
        new_total = add_xp(db, Int(event.message.author.id), Int(event.message.guild_id))
        
        # Lógica simples de "Level Up" (Ex: a cada 100 xp)
        if !isnothing(new_total) && (new_total % 100 == 0)
             # Envia msg de parabéns (em um bot real, seria configurável)
             create_message(c, event.message.channel_id; content="🎉 Parabéns <@$(event.message.author.id)>! Você alcançou o nível $(div(new_total, 100))!")
        end
    end

    # Comando: Ver Rank
    @slash_command client "rank" "Veja seu nível e XP" function(ctx)
        target_user = get(ctx.options, "user", ctx.user)
        xp, rank_pos = get_rank(ctx.client.state.db, Int(target_user.id), Int(ctx.guild_id))
        
        embed_data = embed(
            title = "Rank de $(target_user.username)",
            description = "Aqui estão suas estatísticas neste servidor.",
            color = 0xFFD700,
            fields = [
                embed_field("XP Total", "$xp", true),
                embed_field("Posição", "#$rank_pos", true),
                embed_field("Nível", "$(div(xp, 100))", true)
            ]
        )
        
        respond(ctx; embeds=[embed_data])
    end
    
    @info "Feature [Levels] carregada com sucesso."
end

end

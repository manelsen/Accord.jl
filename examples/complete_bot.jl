using Accord
using Dates

# ─── 1. Estrutura de Estado (O "Coração" do seu Bot) ─────────────────────────
# Em Julia, evitamos variáveis globais. Injetamos este estado no Contexto.
mutable struct BotState
    start_time::DateTime
    commands_run::Int
    feedback_count::Int
    admin_users::Vector{Snowflake}
end

# ─── 2. Guardas Personalizados ────────────────────────────────────────────────
# Podemos criar nossos próprios checks reusáveis.
function is_bot_admin()
    return function(ctx)
        if ctx.state.commands_run > 1000 # Exemplo de lógica dinâmica
            return true
        end
        # Verifica na nossa lista de admins injetada no estado
        return ctx.user.id in ctx.state.admin_users
    end
end

# ─── 3. Inicialização ────────────────────────────────────────────────────────
state = BotState(now(), 0, 0, [Snowflake(0)]) # Adicione seu ID aqui

client = Client(get(ENV, "DISCORD_TOKEN", "SEU_TOKEN");
    intents = IntentGuilds | IntentGuildMessages | IntentMessageContent,
    state = state # Injeção de estado! Acessível via ctx.state
)

# ─── 4. Eventos de Ciclo de Vida ──────────────────────────────────────────────
on(client, ReadyEvent) do c, event
    @info "Bot conectado como $(event.user.username)"
    # Sincroniza comandos globalmente
    sync_commands!(c, c.command_tree)
end

# ─── 5. Comandos Slash com Opções ────────────────────────────────────────────
@slash_command client "stats" "Mostra estatísticas do bot" function(ctx)
    ctx.state.commands_run += 1
    uptime = canonicalize(Dates.CompoundPeriod(now() - ctx.state.start_time))
    
    embed_data = embed(
        title = "📊 Accord.jl Bot Stats",
        color = 0x5865F2,
        fields = [
            embed_field("Uptime", "$uptime", true),
            embed_field("Comandos", "$(ctx.state.commands_run)", true),
            embed_field("Feedbacks", "$(ctx.state.feedback_count)", true)
        ],
        footer = embed_footer("Powered by Julia")
    )
    
    respond(ctx; embeds=[embed_data])
end

# ─── 6. Comandos de Contexto (Clique Direito) ────────────────────────────────
@user_command client "Informações do Membro" function(ctx)
    target_user = target(ctx) # Pega o usuário que recebeu o clique
    respond(ctx; content="Você selecionou **$(target_user.username)** (ID: $(target_user.id))", ephemeral=true)
end

# ─── 7. Componentes e Modais ─────────────────────────────────────────────────
@slash_command client "feedback" "Envia um feedback para os desenvolvedores" function(ctx)
    # Mostra um botão para abrir o Modal
    btn = button(ButtonStyles.PRIMARY, "abrir_feedback"; label="Enviar Feedback")
    row = action_row([btn])
    
    respond(ctx; 
        content="Clique no botão abaixo para abrir o formulário de feedback.",
        components=[row],
        ephemeral=true
    )
end

# Handler do Botão
@button_handler client "abrir_feedback" function(ctx)
    # Abre um formulário (Modal)
    show_modal(ctx, "modal_feedback", "Formulário de Feedback", [
        action_row([
            text_input("fb_title", "Assunto"; placeholder="Ex: Bug no comando stats")
        ]),
        action_row([
            text_input("fb_body", "Mensagem"; style=TextInputStyles.PARAGRAPH)
        ])
    ])
end

# Handler do Modal
@modal_handler client "modal_feedback" function(ctx)
    vals = modal_values(ctx) # Dicionário com os inputs
    ctx.state.feedback_count += 1
    
    @info "Feedback recebido" titulo=vals["fb_title"] corpo=vals["fb_body"]
    
    respond(ctx; content="Obrigado pelo feedback! Registrado como #$(ctx.state.feedback_count)", ephemeral=true)
end

# ─── 8. Comandos Restritos (Checks) ──────────────────────────────────────────
@check is_owner() # Apenas o dono do bot
@slash_command client "shutdown" "Desliga o bot remotamente" function(ctx)
    respond(ctx; content="Encerrando processos... Tchau!")
    sleep(1.0)
    stop(ctx.client)
    exit(0)
end

# ─── 9. Execução ─────────────────────────────────────────────────────────────
@info "Iniciando bot..."
start(client)

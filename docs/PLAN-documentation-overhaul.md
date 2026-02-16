# Plano de Ação: Overhaul de Documentação — Accord.jl

**Data:** 2026-02-15
**Contexto:** Análise comparativa com discord.py, Discord.js, Serenity (Rust) e Nostrum (Elixir).

---

## Diagnóstico

| Dimensão | Accord.jl | Campo (média das 4 libs) |
|---|---|---|
| Cross-references resolvidas | 0 em docstrings, 3 em docs | Alta densidade em todas |
| Admonitions (`!!! note/warning`) | 0 no projeto inteiro | 3 de 4 libs usam callouts estruturados |
| Documentação de erros | 0 | Serenity e discord.py documentam sistematicamente |
| Frase de contexto ("when/why") | 0 | discord.py, Discord.js e Serenity abrem com contexto |
| Links para Discord API docs | 1 (cookbook/index.md) | Serenity e Discord.js linkam em cada struct |
| Docstrings em tipos | 3 de ~88 structs | Todas as libs documentam os tipos principais |
| Docstrings em REST endpoints | 18 de ~158 funções | Todas as libs documentam endpoints |
| Exemplos em docstrings | ~20 de ~157 entidades | Serenity ~35%, discord.py ~40% |

---

## Prioridades por Impacto

### P0 — Impacto Estrutural (desbloqueiam valor em cascata)

**0.1. Habilitar cross-references no Documenter.jl**
- Remover `:cross_references` do `warnonly` em `docs/make.jl`
- Converter backtick refs em docstrings para `[`Type`](@ref)` syntax
- Impacto: toda referência em docstring vira link clicável na doc renderizada

**0.2. Adotar admonitions nos Markdown docs**
- Adicionar `!!! note`, `!!! warning`, `!!! tip` nos 16 cookbooks e no api.md
- Cobrir: permissões necessárias, intents requeridas, breaking changes, gotchas
- Impacto: melhora escaneabilidade e alinhamento com padrão da indústria

### P1 — Alto Impacto (afetam a maioria dos usuários)

**1.1. Docstrings para os ~85 structs não documentados**
- Prioridade interna: tipos que usuários tocam diretamente primeiro
  - Tier A (core): Channel, Member, Role, Emoji, Interaction, Component, Embed, Attachment
  - Tier B (common): Invite, Webhook, Reaction, Ban, Overwrite, VoiceState
  - Tier C (specialized): AuditLog, AutoMod, ScheduledEvent, Sticker, Poll, Presence, etc.
- Cada docstring deve ter: 1 frase de contexto, campos principais, link para Discord API docs
- Modelo a seguir (Serenity): frase imperativa → link Discord docs → campos notáveis

**1.2. Docstrings para os ~140 REST endpoints não documentados**
- Prioridade interna por frequência de uso:
  - Tier A: channel.jl, guild.jl, interaction.jl (funções mais usadas)
  - Tier B: webhook.jl, emoji.jl, user.jl
  - Tier C: sticker.jl, automod.jl, invite.jl, audit_log.jl, voice.jl, soundboard.jl, scheduled_event.jl, stage_instance.jl, sku.jl
- Cada docstring deve ter: assinatura, parâmetros keyword, permissões necessárias, link Discord API
- Modelo a seguir (discord.py): descrição → params → returns → raises → permissions

**1.3. Frase de contexto em docstrings existentes**
- Adicionar uma frase "Use this when..." no início de cada docstring que hoje abre direto com descrição técnica
- Afeta ~157 docstrings existentes
- Modelo a seguir (Discord.js): frase de cenário antes da descrição técnica

### P2 — Médio Impacto (melhoram qualidade percebida)

**2.1. Seção `# Errors` nas docstrings de REST endpoints**
- Documentar o que cada endpoint pode lançar (HTTP 403, 404, rate limit)
- Modelo a seguir (Serenity): `# Errors` com variantes específicas

**2.2. Links para Discord API docs nos structs**
- Adicionar `[Discord docs](https://discord.com/developers/docs/resources/...)` em cada struct
- Modelo a seguir (Serenity): link no nível do struct, não no nível de campo

**2.3. Exemplos de código nas docstrings que não têm**
- Prioridade: funções do client.jl, context.jl, command_tree.jl, components.jl
- ~137 entidades sem exemplo; meta realista: cobrir as ~40 mais usadas
- Modelo a seguir (discord.py): exemplos completos e executáveis com imports

**2.4. Documentar os 10 @discord_flags sem docstring**
- Intents, Permissions, MessageFlags, UserFlags, SystemChannelFlags, ChannelFlags, etc.
- Cada uma deve listar as flags disponíveis e mostrar combinação com `|`

**2.5. Documentar os módulos de enums**
- enums.jl não tem nenhuma docstring
- Documentar pelo menos os enums mais usados: ChannelType, MessageType, InteractionType, ComponentType, etc.

### P3 — Baixo Impacto (polish)

**3.1. Admonitions nas docstrings de source (não só nos .md)**
- Julia docstrings suportam `!!! note` via Documenter.jl
- Adicionar warnings de permissão, notas sobre intents, etc.
- Modelo a seguir (Serenity): `**Note**: Requires the [Manage Guild] permission.`

**3.2. Versionamento nas docstrings**
- Adicionar `!!! compat "Accord 0.x"` para features adicionadas recentemente
- Modelo a seguir (discord.py): `.. versionadded::`, `.. versionchanged::`

**3.3. Documentar módulos internos (gateway, heartbeat, dispatch)**
- Baixa prioridade: usuários não interagem diretamente
- Mas útil para contribuidores

---

## Convenções de Estilo (a adotar)

Baseado nas melhores práticas observadas nas 4 libs:

```
"""
    function_name(args...; kwargs...) -> ReturnType

Brief context sentence: when/why to use this.

Technical description of what it does.

# Arguments
- `param::Type` — description.
- `kwarg::Type=default` — description.

# Errors
- Throws `ErrorType` if condition.

# Permissions
Requires `MANAGE_GUILD`.

# Example
```julia
result = function_name(arg1, arg2; kwarg=value)
```

See also: [`RelatedFunction`](@ref), [`RelatedType`](@ref).

[Discord docs](https://discord.com/developers/docs/resources/...)
"""
```

Para structs:
```
"""
    StructName

Brief context: what this represents and when you encounter it.

[Discord docs](https://discord.com/developers/docs/resources/...)

# Fields
- `field::Type` — description.
- `optional_field::Optional{Type}` — description. Only present when condition.
"""
```

---

## Ordem de Execução Recomendada

1. **P0.1** Cross-references (desbloqueia links em toda doc futura)
2. **P0.2** Admonitions nos .md (melhoria visual imediata nos cookbooks)
3. **P1.1 Tier A** Docstrings dos structs core (8 tipos mais tocados)
4. **P1.2 Tier A** Docstrings dos endpoints core (channel, guild, interaction)
5. **P1.3** Frases de contexto nas docstrings existentes
6. **P1.1 Tier B+C** Restante dos structs
7. **P1.2 Tier B+C** Restante dos endpoints
8. **P2.1–P2.5** Erros, links Discord, exemplos, flags, enums
9. **P3.1–P3.3** Polish final

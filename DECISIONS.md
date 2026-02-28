# DECISIONS.md — Accord.jl Architecture Decision Records

Registro formal de decisões de design com impacto não-óbvio.
Cada entrada segue o formato ADR (Architecture Decision Record).

---

## ADR-001 — HandlerGroup em vez de sistema de Cogs

**Data:** 2026-02-23
**Status:** Aceito
**Contexto:** Planejamento v0.4.0 (parity com discord.py)

### Contexto

O plano de paridade funcional com discord.py (v0.4.0) incluía, como M6,
a implementação de um sistema de Cogs — a abstração do discord.py que
agrupa comandos, event listeners e estado relacionados em uma classe Python
com ciclo de vida de load/unload.

O problema que Cogs resolvem tem três partes:
1. **Organização** — agrupar handlers relacionados em uma unidade nomeada.
2. **Estado compartilhado** — um grupo de handlers (ex: módulo de música)
   precisa de estado comum (filas, players) acessível entre eles.
3. **Load/unload em runtime** — habilitar ou desabilitar um conjunto de
   features sem reiniciar o bot.

### Decisão

**Não implementar Cogs.** Implementar `HandlerGroup` — uma abstração
mínima que resolve apenas o problema (3), o único que Julia não resolve
nativamente.

API aprovada:

```julia
# Criar grupo nomeado
group = HandlerGroup("music")

# Registrar handlers no grupo (mesma API pública de sempre)
@slash_command group "play" "Toca uma música" begin
    ...
end
@slash_command group "stop" "Para a reprodução" begin
    ...
end
@on group MessageCreate begin
    ...
end

# Carregar no client (registra todos os handlers do grupo de uma vez)
load!(client, group)

# Descarregar em runtime (remove todos os handlers do grupo)
unload!(client, "music")
```

### Justificativa

**Por que Cogs não fazem sentido em Julia:**

Cogs existem em Python porque a linguagem não oferece outro mecanismo para
associar funções a estado compartilhado sem classes. O decorador
`@commands.command` em um método de instância só funciona porque há uma
classe (`self`) por baixo.

Julia já resolve os problemas (1) e (2) com mecanismos nativos:

- **Organização (1):** módulos Julia são a unidade natural de namespacing.
  Um arquivo `cogs/music.jl` com `module Music ... end` já resolve isso
  sem nenhum código de biblioteca.

- **Estado compartilhado (2):** closures capturam estado sem cerimônia.
  Um `Dict` definido antes dos handlers é acessível em todos eles
  automaticamente — sem `self`, sem instância de classe.

```julia
# Julia: estado compartilhado via closure, sem abstração extra
queue = Dict{Snowflake, Vector{String}}()

@slash_command client "play" "Toca" begin
    push!(queue[ctx.guild_id], get_option(ctx, "url"))
end

@slash_command client "skip" "Pula" begin
    popfirst!(queue[ctx.guild_id])
end
```

O único problema que Julia **não** resolve nativamente é (3): não há
mecanismo built-in para remover em runtime um conjunto nomeado de handlers
já registrados no `CommandTree`. `HandlerGroup` resolve exclusivamente isso.

**Por que não apenas módulos com `register!(client)`:**

Isso resolve (1) e (2) mas sacrifica (3) completamente. O bot precisaria
reiniciar para desativar um módulo.

### Consequências no plano v0.4.0

Os requisitos RF-009, RF-010, RF-011 e RS-003 do plano original são
substituídos:

| Original | Substituído por |
|---|---|
| RF-009 `load_cog!(client, cog)` | RF-009 `load!(client, group::HandlerGroup)` |
| RF-010 `unload_cog!(client, name)` | RF-010 `unload!(client, name::String)` |
| RF-011 `@cog` macro | RF-011 `HandlerGroup(name)` construtor simples |
| RS-003 colisão de nome de cog | RS-003 colisão de nome de grupo (sem mudança) |

**Impacto em exports:** substituir `load_cog!`, `unload_cog!`, `@cog`,
`AbstractCog` por `load!`, `unload!`, `HandlerGroup`.

**Impacto em arquivos:** `src/interactions/cog.jl` → renomear para
`src/interactions/handler_group.jl`.

### Alternativas consideradas

| Alternativa | Motivo da rejeição |
|---|---|
| Port direto de Cogs (struct + macro `@cog`) | Padrão OOP-Python sem equivalente idiomático em Julia; adiciona complexidade sem benefício |
| Apenas módulos Julia + convenção `register!` | Não resolve load/unload em runtime |
| Nenhuma abstração (sem M6) | Bots grandes sem mecanismo de load/unload têm DX ruim para features opcionais |

### Referências

- Discussão interna: conversa de design de 2026-02-23
- discord.py Cogs: https://discordpy.readthedocs.io/en/stable/ext/commands/cogs.html
  (referência de design, não de API Discord)

---

## ADR-002 — Estratégia de Confiabilidade baseada em Testes de Contrato com Fixtures

**Data:** 2026-02-25
**Status:** Aceito
**Contexto:** Robustez de parser/eventos/REST frente a drift da API Discord

### Contexto

O Accord já possui boa cobertura unitária e integração com mocks, mas
fixtures reais ainda cobrem uma fração da superfície suportada (gateway
e REST). Isso aumenta risco de regressão silenciosa em mudanças de:

1. Tipos (`@discord_struct`, `Optional`/`Nullable`)
2. Dispatch de eventos (`EVENT_TYPES`)
3. Parsing de respostas REST

Para uma biblioteca resiliente, o ponto de detecção de falhas deve ser
o PR (CI), não produção.

### Decisão

Adotar como padrão de confiabilidade um modelo híbrido:

1. **Testes de contrato com fixtures** como guardrail principal.
2. **Fixtures reais capturadas** sempre que viável.
3. **Fixtures sintéticas validadas por contrato** quando evento é raro ou
   difícil de reproduzir em ambiente de captura.
4. **Gate de cobertura em CI** para impedir regressão de contrato.

### Consequências

1. O projeto passa a exigir manutenção ativa do inventário de fixtures.
2. Novos eventos/rotas suportados devem vir acompanhados de cobertura
   declarada (fixture + teste).
3. Refactors em gateway/tipos/REST tornam-se mais seguros e previsíveis.
4. O custo inicial de curadoria de fixtures aumenta, mas com redução de
   bugs de integração no médio prazo.

### Escopo da primeira sprint

A execução inicial está documentada em:

- `docs/PLAN-reliability-sprint.md`

Esse plano define baseline, metas mensuráveis, backlog por custo/benefício,
ferramentas Julia utilizadas e Definition of Done.

### Alternativas consideradas

| Alternativa | Motivo da rejeição |
|---|---|
| Manter apenas mocks sintéticos | Bom para rota/método, fraco contra drift real de payload |
| Buscar 100% de eventos reais em uma sprint | Não realista para eventos raros/condicionais |
| Confiar só em testes manuais com bot online | Alto custo operacional e baixa reprodutibilidade |

### Referências

- Manifesto de fixtures: `test/integration/fixtures/_manifest.json`
- Mapeamento de eventos suportados: `src/gateway/events.jl` (`EVENT_TYPES`)
- Plano de execução: `docs/PLAN-reliability-sprint.md`

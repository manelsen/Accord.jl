# PLAN-reliability-sprint.md

Plano de sprint para elevar a confiabilidade do Accord com foco em testes de contrato baseados em fixtures.

Data de criação: 2026-02-25

---

## Objetivo da Sprint

Criar a base operacional para cobertura ampla de eventos Discord sem depender de rede em CI:

1. Detectar regressão de parsing/serialização antes de merge.
2. Reduzir drift entre payload real da API e modelos internos.
3. Aumentar previsibilidade de refactors em gateway, tipos e REST.

---

## Baseline Atual (início da sprint)

- `EVENT_TYPES` mapeados no gateway: 74.
- Fixtures gateway DISPATCH disponíveis: 7 (`HELLO` e `HEARTBEAT_ACK` não entram nessa conta).
- Fixtures REST disponíveis: 9.
- Total de payloads no manifesto: 24 (média 1.33 por categoria).
- Categorias com fixture existente mas sem validação semântica dedicada:
  - `gateway_message_delete`
  - `gateway_message_update`
  - `gateway_thread_create`
  - `rest_get_emojis`

---

## Estratégia de Confiabilidade (Custo x Beneficio)

Prioridade da sprint (ordem de execucao):

1. **Contract Drift Guard** (baixo custo, beneficio muito alto)
2. **Expansao de fixtures reais + validacao semantica** (custo medio, beneficio alto)
3. **Replay deterministico + fault injection gateway** (custo medio, beneficio alto)
4. **Quality gates no CI (Aqua/JET + suites de contrato)** (baixo custo, beneficio alto)

Meta de cobertura total de eventos permanece valida, mas sera alcançada em fases.

---

## Escopo Entregavel em 1 Sprint

### 1) Guardrails de cobertura de fixture

- Adicionar verificador automatico (script ou teste) que:
  - lê `EVENT_TYPES`;
  - mapeia fixtures gateway/rest presentes;
  - falha quando categoria obrigatoria estiver faltando;
  - gera relatorio em texto para CI.

**Critério de aceite**
- PR falha se remover fixture obrigatoria ou se novo evento suportado ficar sem cobertura declarada.

### 2) Validacao semantica das fixtures ja existentes

- Criar blocos dedicados para categorias que hoje so entram no parse generico:
  - `gateway_message_delete`
  - `gateway_message_update`
  - `gateway_thread_create`
  - `rest_get_emojis`

**Critério de aceite**
- Cada categoria existente tem ao menos 1 teste semantico (nao apenas "parse sem crash").

### 3) Expansao de fixtures de alto risco

- Gateway (alvo minimo da sprint): adicionar fixtures para eventos de alto impacto operacional:
  - `GUILD_MEMBER_ADD`, `GUILD_MEMBER_UPDATE`, `GUILD_MEMBER_REMOVE`
  - `MESSAGE_REACTION_ADD`, `MESSAGE_REACTION_REMOVE`
  - `VOICE_STATE_UPDATE`, `VOICE_SERVER_UPDATE`
  - `AUTO_MODERATION_ACTION_EXECUTION` (real, nao apenas opcional)
- REST (alvo minimo da sprint): ampliar fixtures para recursos com maior volatilidade de payload:
  - webhooks, invites, stickers, automod, scheduled events, soundboard

**Critério de aceite**
- +10 novas categorias de fixture no manifesto (meta minima).
- Cada nova categoria com validacao semantica minima.

### 4) Fault injection deterministico

- Reforcar testes de gateway/rate limiter com cenarios deterministas:
  - heartbeat atrasado/ausente;
  - reconnect e invalid session;
  - resposta REST 429 com headers de bucket.

**Critério de aceite**
- Cenarios reprodutiveis local/CI sem dependencia de rede.

---

## Ferramentas Julia (ecossistema atual do projeto)

- `Test` (stdlib): assercoes, `@testset`, regressao deterministica.
- `ReTestItems.jl`: execucao granular por tags (`:unit`, `:integration`, `:quality`), paralelismo e relatorio JUnit.
- `Aqua.jl`: checks de qualidade de pacote.
- `JET.jl`: analise estatica de inferencia/erros.
- `JSON3.jl`: round-trip e validacao de contrato de payload.
- `HTTP.jl` mocks internos ja usados na suite REST.

Nenhuma dependencia nova e obrigatoria para esta sprint.

---

## Progresso da Sprint (Dias 1-10)

- [x] **Dia 1-2**: Implementado `fixture_coverage_check` + integração no runner (`test/integration/fixture_coverage_test.jl`).
- [x] **Dia 3-4**: Validação semântica para `MESSAGE_DELETE`, `MESSAGE_UPDATE`, `THREAD_CREATE` e `rest_get_emojis`.
- [x] **Dia 5-7**: Capturadas fixtures de `VOICE_STATE_UPDATE`, `MESSAGE_REACTION_ADD`, `GUILD_MEMBER_UPDATE` e eventos de voz internos.
- [x] **Dia 8**: Adicionados cenários de **Fault Injection** determinístico (`test/unit/fault_injection_test.jl`) para 429/Rate Limiter e Missed Heartbeat.
- [x] **Dia 9**: Criado runner consolidado de smoke tests (`scripts/run_all_smokes.jl`).
- [x] **Dia 10**: Revisão de modelos core (`User`, `Member`) e introdução do tipo `Maybe{T}` para resiliência.

---

## Checklist de Rollout (0.3.0-alpha)

- [x] Rodar `test/unit/fault_injection_test.jl` e garantir pass em 429/heartbeat.
- [x] Verificar cobertura de fixtures com `test/integration/fixture_coverage_test.jl`.
- [x] Executar `scripts/run_all_smokes.jl` em Guild sandbox com token de QA.
- [ ] Validar manualmente no Discord:
    - [ ] Componentes (botões/selects) em mensagens.
    - [ ] Modais com encadeamento.
    - [ ] Voz: entrar/sair e tocar áudio curto.
- [ ] Rotacionar `DISCORD_TOKEN` se exposto em logs durante o sprint.
- [ ] Tag de release e atualização do `CHANGELOG.md`.

---

## Definition of Done da Sprint

1. CI falha em regressao de contrato de fixture.
2. Todas as categorias de fixture existentes possuem validacao semantica dedicada.
3. Manifesto ganha pelo menos 10 novas categorias com testes.
4. Suite de confiabilidade executa offline (sem token/rede) e permanece deterministica.
5. Documentacao de operacao atualizada para manutencao do ciclo de fixtures.

---

## Proximos Passos (apos sprint)

1. Cobertura progressiva ate 100% dos eventos suportados em `EVENT_TYPES`.
2. Politica de refresh de fixtures (ex.: quinzenal ou por release).
3. Opcional: introduzir property-based testing para eventos com payload altamente combinatorio.

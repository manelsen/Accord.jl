module CoreTypes

using Accord
using SQLite
using DBInterface

const Context = InteractionContext

# O Estado Global do Bot (Injetado no Client)
mutable struct OmniState
    db::SQLite.DB
    start_time::Float64
end

# Função helper para pegar conexão do DB de dentro de um comando
get_db(ctx::Context) = ctx.client.state.db

# Interface para Features (Plugins)
# Cada feature deve implementar uma função `install(client)`
abstract type AbstractFeature end

end

#!/usr/bin/env julia

using JSON3
using Dates

mutable struct SanitizerState
    id_map::Dict{String, String}
    text_maps::Dict{String, Dict{String, String}}
    counters::Dict{String, Int}
end

SanitizerState() = SanitizerState(Dict{String, String}(), Dict{String, Dict{String, String}}(), Dict{String, Int}())

function next_counter!(state::SanitizerState, key::String)
    state.counters[key] = get(state.counters, key, 0) + 1
    return state.counters[key]
end

function map_snowflake!(state::SanitizerState, raw::AbstractString)
    value = String(raw)
    haskey(state.id_map, value) && return state.id_map[value]
    # Keep plausible Snowflake-like values while preserving referential integrity.
    mapped = string(900000000000000000 + length(state.id_map) + 1)
    state.id_map[value] = mapped
    return mapped
end

function map_text!(state::SanitizerState, domain::String, raw::AbstractString; prefix::Union{Nothing, String}=nothing)
    dict = get!(state.text_maps, domain, Dict{String, String}())
    value = String(raw)
    haskey(dict, value) && return dict[value]

    tag = isnothing(prefix) ? domain : prefix
    idx = next_counter!(state, "text:$tag")
    mapped = "$(tag)_$idx"
    dict[value] = mapped
    return mapped
end

function hex_token(state::SanitizerState, domain::String, n::Int=32)
    idx = next_counter!(state, "hex:$domain")
    return lpad(string(idx, base=16), n, '0')[1:n]
end

const SNOWFLAKE_RE = r"^\d{16,20}$"

const DIRECT_ID_KEYS = Set([
    "id", "application_id", "channel_id", "guild_id", "user_id", "owner_id",
    "message_id", "parent_id", "webhook_id", "role_id", "sku_id",
    "entitlement_id", "target_id", "identity_guild_id", "last_message_id",
    "source_guild_id",
])

const ARRAY_ID_KEYS = Set([
    "ids", "roles", "mention_roles", "member_ids_preview", "removed_member_ids",
    "sku_ids", "entitlement_ids", "applied_tags", "channel_ids", "default_channel_ids",
    "exempt_roles", "exempt_channels",
])

const TEXT_KEYS = Set([
    "username", "global_name", "nick", "name", "content", "topic", "tag", "code",
    "description",
])

const HASH_KEYS = Set([
    "avatar", "banner", "icon", "badge", "asset",
])

const URL_KEYS = Set([
    "url", "resume_gateway_url",
])

const SECRET_KEYS = Set([
    "token", "session_id", "nonce",
])

is_id_key(key::String) = key in DIRECT_ID_KEYS || endswith(key, "_id")
is_id_array_key(key::String) = key in ARRAY_ID_KEYS || endswith(key, "_ids")

function sanitize_string(state::SanitizerState, key::String, value::String)
    if occursin(r"^[0-9]+$", key) && occursin(SNOWFLAKE_RE, value)
        return map_snowflake!(state, value)
    end

    if is_id_key(key) && occursin(SNOWFLAKE_RE, value)
        return map_snowflake!(state, value)
    end

    if key in URL_KEYS
        if key == "resume_gateway_url"
            return "wss://gateway.discord.gg/?v=10&encoding=json"
        end
        if startswith(value, "wss://")
            return "wss://gateway.discord.gg/?v=10&encoding=json"
        end
        return "https://example.invalid/" * map_text!(state, key, value; prefix=key)
    end

    if key in SECRET_KEYS
        return map_text!(state, key, value; prefix=key)
    end

    if key in HASH_KEYS
        return hex_token(state, key, 32)
    end

    if key in TEXT_KEYS
        return map_text!(state, key, value; prefix=key)
    end

    if key == "email"
        return "redacted@example.invalid"
    end

    if occursin(r"^[a-f0-9]{32}$", value)
        return hex_token(state, "hash", 32)
    end

    return value
end

function sanitize_any!(state::SanitizerState, value, parent_key::String="")
    if value isa Dict
        for key_any in collect(keys(value))
            key = String(key_any)
            value[key_any] = sanitize_any!(state, value[key_any], key)
        end
        return value
    end

    if value isa Vector
        if is_id_array_key(parent_key)
            for i in eachindex(value)
                if value[i] isa AbstractString && occursin(SNOWFLAKE_RE, value[i])
                    value[i] = map_snowflake!(state, value[i])
                elseif value[i] isa Integer
                    value[i] = parse(Int, map_snowflake!(state, string(value[i])))
                else
                    value[i] = sanitize_any!(state, value[i], parent_key)
                end
            end
            return value
        end

        for i in eachindex(value)
            value[i] = sanitize_any!(state, value[i], parent_key)
        end
        return value
    end

    if value isa AbstractString
        return sanitize_string(state, parent_key, String(value))
    end

    return value
end

function sanitize_fixture_file!(state::SanitizerState, path::String)
    raw = read(path, String)
    data = JSON3.read(raw, Any)
    sanitized = sanitize_any!(state, data)
    open(path, "w") do io
        JSON3.pretty(io, sanitized)
    end
end

function sanitize_manifest!(path::String)
    isfile(path) || return
    manifest = JSON3.read(read(path, String), Dict{String, Any})
    manifest["sanitized_at"] = Dates.format(Dates.now(), dateformat"yyyy-mm-ddTHH:MM:SS")
    open(path, "w") do io
        JSON3.pretty(io, manifest)
    end
end

function sanitize_fixtures_main()
    fixtures_dir = isempty(ARGS) ? joinpath(@__DIR__, "..", "test", "integration", "fixtures") : ARGS[1]
    isdir(fixtures_dir) || error("Fixtures dir not found: $fixtures_dir")

    files = sort([
        joinpath(fixtures_dir, f)
        for f in readdir(fixtures_dir)
        if endswith(f, ".json") && !startswith(f, "_")
    ])

    state = SanitizerState()
    for path in files
        sanitize_fixture_file!(state, path)
    end
    sanitize_manifest!(joinpath(fixtures_dir, "_manifest.json"))

    println("Sanitized $(length(files)) fixture files in $fixtures_dir")
    println("Unique Snowflake IDs remapped: $(length(state.id_map))")
end

if abspath(PROGRAM_FILE) == @__FILE__
    sanitize_fixtures_main()
end

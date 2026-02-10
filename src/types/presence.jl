@discord_struct ActivityTimestamps begin
    start::Optional{Int}
    end_::Optional{Int}
end

@discord_struct ActivityEmoji begin
    name::String
    id::Optional{Snowflake}
    animated::Optional{Bool}
end

@discord_struct ActivityParty begin
    id::Optional{String}
    size::Optional{Vector{Int}}
end

@discord_struct ActivityAssets begin
    large_image::Optional{String}
    large_text::Optional{String}
    small_image::Optional{String}
    small_text::Optional{String}
end

@discord_struct ActivitySecrets begin
    join::Optional{String}
    spectate::Optional{String}
    match::Optional{String}
end

@discord_struct ActivityButton begin
    label::String
    url::String
end

@discord_struct Activity begin
    name::String
    type::Int
    url::Optional{String}
    created_at::Optional{Int}
    timestamps::Optional{ActivityTimestamps}
    application_id::Optional{Snowflake}
    details::Optional{String}
    state::Optional{String}
    emoji::Optional{ActivityEmoji}
    party::Optional{ActivityParty}
    assets::Optional{ActivityAssets}
    secrets::Optional{ActivitySecrets}
    instance::Optional{Bool}
    flags::Optional{Int}
    buttons::Optional{Vector{ActivityButton}}
end

@discord_struct ClientStatus begin
    desktop::Optional{String}
    mobile::Optional{String}
    web::Optional{String}
end

@discord_struct Presence begin
    user::Any  # partial User object
    guild_id::Optional{Snowflake}
    status::String
    activities::Vector{Activity}
    client_status::ClientStatus
end

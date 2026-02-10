@discord_struct Webhook begin
    id::Snowflake
    type::Int
    guild_id::Optional{Snowflake}
    channel_id::Nullable{Snowflake}
    user::Optional{User}
    name::Nullable{String}
    avatar::Nullable{String}
    token::Optional{String}
    application_id::Nullable{Snowflake}
    source_guild::Optional{Any}
    source_channel::Optional{Any}
    url::Optional{String}
end

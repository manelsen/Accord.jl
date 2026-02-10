@discord_struct IntegrationAccount begin
    id::String
    name::String
end

@discord_struct IntegrationApplication begin
    id::Snowflake
    name::String
    icon::Nullable{String}
    description::String
    bot::Optional{User}
end

@discord_struct Integration begin
    id::Snowflake
    name::String
    type::String
    enabled::Optional{Bool}
    syncing::Optional{Bool}
    role_id::Optional{Snowflake}
    enable_emoticons::Optional{Bool}
    expire_behavior::Optional{Int}
    expire_grace_period::Optional{Int}
    user::Optional{User}
    account::IntegrationAccount
    synced_at::Optional{String}
    subscriber_count::Optional{Int}
    revoked::Optional{Bool}
    application::Optional{IntegrationApplication}
    scopes::Optional{Vector{String}}
end

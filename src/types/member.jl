@discord_struct Member begin
    user::Optional{User}
    nick::Optional{String}
    avatar::Optional{String}
    roles::Vector{Snowflake}
    joined_at::String
    premium_since::Optional{String}
    deaf::Optional{Bool}
    mute::Optional{Bool}
    flags::Int
    pending::Optional{Bool}
    permissions::Optional{String}
    communication_disabled_until::Optional{String}
    avatar_decoration_data::Optional{Any}
end

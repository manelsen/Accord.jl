@discord_struct Emoji begin
    id::Nullable{Snowflake}
    name::Nullable{String}
    roles::Optional{Vector{Snowflake}}
    user::Optional{User}
    require_colons::Optional{Bool}
    managed::Optional{Bool}
    animated::Optional{Bool}
    available::Optional{Bool}
end

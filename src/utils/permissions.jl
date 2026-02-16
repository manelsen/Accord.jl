# Permission computation utilities
#
# Internal module: Computes effective permissions for guild members by combining
# role permissions and applying channel-specific overwrites, following Discord's
# permission hierarchy algorithm.

"""
    compute_base_permissions(member_roles::Vector{Snowflake}, guild_roles::Vector{Role}, owner_id::Snowflake, user_id::Snowflake) -> Permissions

Use this to determine what permissions a user has at the guild level before considering channel-specific restrictions.

Compute the base [`Permissions`](@ref) for a member in a guild (before channel overwrites).
Takes a list of [`Role`](@ref) IDs, all guild roles, the owner's [`Snowflake`](@ref), and the member's ID.

# Example
```julia
base = compute_base_permissions(member.roles, guild.roles, guild.owner_id, user.id)
has_flag(base, PermSendMessages)  # => true/false
```
"""
function compute_base_permissions(member_roles::Vector{Snowflake}, guild_roles::Vector{Role}, owner_id::Snowflake, user_id::Snowflake)
    # Guild owner has all permissions
    if user_id == owner_id
        return Permissions(typemax(UInt64))
    end

    # Start with @everyone role permissions
    everyone_role = findfirst(r -> r.id == guild_roles[1].id, guild_roles)
    permissions = if !isnothing(everyone_role)
        Permissions(parse(UInt64, guild_roles[everyone_role].permissions))
    else
        Permissions(0)
    end

    # Add role permissions
    for role_id in member_roles
        idx = findfirst(r -> r.id == role_id, guild_roles)
        if !isnothing(idx)
            role_perms = Permissions(parse(UInt64, guild_roles[idx].permissions))
            permissions = permissions | role_perms
        end
    end

    # Administrator overrides everything
    if has_flag(permissions, PermAdministrator)
        return Permissions(typemax(UInt64))
    end

    return permissions
end

"""
    compute_channel_permissions(base::Permissions, member_roles::Vector{Snowflake}, overwrites::Vector{Overwrite}, guild_id::Snowflake, user_id::Snowflake) -> Permissions

Use this to calculate final permissions by applying channel-specific overwrites to base guild permissions.

Apply channel [`Overwrite`](@ref)s to base [`Permissions`](@ref).

# Example
```julia
base = compute_base_permissions(member.roles, guild.roles, guild.owner_id, user.id)
channel_perms = compute_channel_permissions(base, member.roles, channel.permission_overwrites, guild.id, user.id)
has_flag(channel_perms, PermSendMessages)  # => true/false
```
"""
function compute_channel_permissions(base::Permissions, member_roles::Vector{Snowflake},
        overwrites::Vector{Overwrite}, guild_id::Snowflake, user_id::Snowflake)
    # Administrator bypasses all overwrites
    if has_flag(base, PermAdministrator)
        return Permissions(typemax(UInt64))
    end

    permissions = base

    # Apply @everyone overwrite
    everyone_overwrite = findfirst(o -> o.id == guild_id, overwrites)
    if !isnothing(everyone_overwrite)
        ow = overwrites[everyone_overwrite]
        deny = Permissions(parse(UInt64, ow.deny))
        allow = Permissions(parse(UInt64, ow.allow))
        permissions = Permissions(permissions.value & ~deny.value)
        permissions = permissions | allow
    end

    # Apply role overwrites (combined)
    role_allow = Permissions(0)
    role_deny = Permissions(0)
    for ow in overwrites
        if ow.type == 0 && ow.id in member_roles  # type 0 = role
            role_deny = role_deny | Permissions(parse(UInt64, ow.deny))
            role_allow = role_allow | Permissions(parse(UInt64, ow.allow))
        end
    end
    permissions = Permissions(permissions.value & ~role_deny.value)
    permissions = permissions | role_allow

    # Apply member-specific overwrite
    member_overwrite = findfirst(o -> o.type == 1 && o.id == user_id, overwrites)
    if !isnothing(member_overwrite)
        ow = overwrites[member_overwrite]
        deny = Permissions(parse(UInt64, ow.deny))
        allow = Permissions(parse(UInt64, ow.allow))
        permissions = Permissions(permissions.value & ~deny.value)
        permissions = permissions | allow
    end

    return permissions
end

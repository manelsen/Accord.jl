# Recipe 06 — Permissions

**Difficulty:** Intermediate
**What you will build:** Permission computation, guards for commands, and private channels via overwrites.

**Prerequisites:** [Recipe 03](03-slash-commands.md)

---

## 1. How Discord Permissions Work

Permissions are a layered system:

1. **Base permissions** — union of all role permissions for the member
2. **Channel overwrites** — @everyone overwrite → role overwrites → member-specific overwrite
3. **Special cases** — guild owner gets all permissions; `Administrator` bypasses everything

## 2. Permission Flags Reference

Accord.jl defines permissions as a `Permissions` bitfield type:

| Flag | Bit | Description |
|------|-----|-------------|
| `PermCreateInstantInvite` | 0 | Create channel invites |
| `PermKickMembers` | 1 | Kick members |
| `PermBanMembers` | 2 | Ban members |
| `PermAdministrator` | 3 | **Bypasses all** permission checks |
| `PermManageChannels` | 4 | Create/edit/delete channels |
| `PermManageGuild` | 5 | Change server settings |
| `PermAddReactions` | 6 | Add reactions to messages |
| `PermViewAuditLog` | 7 | View audit log |
| `PermViewChannel` | 10 | View channels |
| `PermSendMessages` | 11 | Send messages in text channels |
| `PermManageMessages` | 13 | Delete/pin other users' messages |
| `PermEmbedLinks` | 14 | Send embeds |
| `PermAttachFiles` | 15 | Upload files |
| `PermReadMessageHistory` | 16 | Read message history |
| `PermMentionEveryone` | 17 | @everyone / @here |
| `PermConnect` | 20 | Connect to voice channels |
| `PermSpeak` | 21 | Speak in voice channels |
| `PermMuteMembers` | 22 | Mute members in voice |
| `PermDeafenMembers` | 23 | Deafen members in voice |
| `PermMoveMembers` | 24 | Move members between voice channels |
| `PermManageRoles` | 28 | Create/edit roles below yours |
| `PermManageWebhooks` | 29 | Manage webhooks |
| `PermModerateMembers` | 40 | Timeout members |
| `PermSendVoiceMessages` | 46 | Send voice messages |
| `PermSendPolls` | 49 | Create polls |

### Checking Flags

```julia
perms = Permissions(0x00000800)  # PermSendMessages
has_flag(perms, PermSendMessages)  # true
has_flag(perms, PermBanMembers)    # false
```

### Combining Flags

```julia
required = PermSendMessages | PermEmbedLinks | PermAttachFiles
has_flag(user_perms, required)  # true only if ALL are set
```

## 3. Computing Base Permissions

```julia
function get_member_permissions(client, guild_id, user_id)
    guild = get_guild(client, guild_id)

    # Get member's roles
    member_store = get(client.state.members, guild_id, nothing)
    isnothing(member_store) && return Permissions(0)
    member = get(member_store, user_id)
    isnothing(member) && return Permissions(0)

    # Get guild roles from cache
    role_store = get(client.state.roles, guild_id, nothing)
    isnothing(role_store) && return Permissions(0)
    guild_roles = collect(values(role_store))

    member_roles = ismissing(member.roles) ? Snowflake[] : member.roles
    owner_id = guild.owner_id

    return compute_base_permissions(member_roles, guild_roles, owner_id, user_id)
end
```

## 4. Computing Channel Permissions

```julia
function get_channel_permissions(client, guild_id, channel_id, user_id)
    base = get_member_permissions(client, guild_id, user_id)

    channel = get_channel(client, channel_id)
    overwrites = ismissing(channel.permission_overwrites) ? Overwrite[] : channel.permission_overwrites

    member_store = get(client.state.members, guild_id, nothing)
    isnothing(member_store) && return base
    member = get(member_store, user_id)
    isnothing(member) && return base

    member_roles = ismissing(member.roles) ? Snowflake[] : member.roles

    return compute_channel_permissions(base, member_roles, overwrites, guild_id, user_id)
end
```

## 5. Permission Guard for Commands

### Using `@check` Guards (Recommended)

The cleanest way to protect commands — stack `@check` macros before `@slash_command`:

```julia
# Only users with BAN_MEMBERS permission can use this
@check has_permissions(:BAN_MEMBERS)
@slash_command client "ban" "Ban a user" options_ban function(ctx)
    target_id = Snowflake(get_option(ctx, "user", ""))
    reason = get_option(ctx, "reason", "No reason provided")

    create_guild_ban(ctx.client.ratelimiter, ctx.interaction.guild_id, target_id;
        token=ctx.client.token, body=Dict("delete_message_seconds" => 86400), reason=reason)

    respond(ctx; content="Banned <@$(target_id)>. Reason: $reason")
end
```

If the user lacks the required permission, an ephemeral "❌ You don't have permission"
message is sent automatically — no boilerplate needed.

#### Stacking Multiple Checks

```julia
@check is_in_guild()
@check has_permissions(:MANAGE_GUILD)
@check is_owner()
@slash_command client "nuke" "Extreme action — owner only" function(ctx)
    respond(ctx; content="💥 Done!")
end
```

All checks must pass. If any fails, subsequent checks and the handler are skipped.

#### Built-in Check Factories

| Check | Description |
|-------|-------------|
| `has_permissions(perms...)` | Require Discord permissions. Accepts `Permissions` constants or symbols (`:ADMINISTRATOR`, `:BAN_MEMBERS`). |
| `is_owner()` | Require the guild owner. |
| `is_in_guild()` | Require guild context (deny DMs). |

#### Accepts Both Permissions Constants and Symbols

```julia
# These are equivalent:
@check has_permissions(PermManageGuild | PermBanMembers)
@check has_permissions(:MANAGE_GUILD, :BAN_MEMBERS)
```

### Manual Approach (Legacy)

For full control, you can still check permissions manually:

```julia
function require_permissions(ctx, required::Permissions)
    guild_id = ctx.interaction.guild_id
    user_id = ctx.interaction.member.user.id

    perms = get_member_permissions(ctx.client, guild_id, user_id)
    if !has_flag(perms, required)
        respond(ctx; content="You don't have permission to use this command.", ephemeral=true)
        return false
    end
    return true
end

# Usage in a command
options_ban = [
    command_option(type=ApplicationCommandOptionTypes.USER, name="user", description="User to ban", required=true),
    command_option(type=ApplicationCommandOptionTypes.STRING, name="reason", description="Ban reason"),
]

@slash_command client "ban" "Ban a user" options_ban function(ctx)
    require_permissions(ctx, PermBanMembers) || return

    target_id = Snowflake(get_option(ctx, "user", ""))
    reason = get_option(ctx, "reason", "No reason provided")

    create_guild_ban(ctx.client.ratelimiter, ctx.interaction.guild_id, target_id;
        token=ctx.client.token, body=Dict("delete_message_seconds" => 86400), reason=reason)

    respond(ctx; content="Banned <@$(target_id)>. Reason: $reason")
end
```

## 6. Common Permission Patterns

### Mod-Only Command

```julia
# Using @check — clean and declarative
@check has_permissions(:KICK_MEMBERS)
@slash_command client "warn" "Warn a user" options_warn function(ctx)
    respond(ctx; content="User warned.")
end
```

### Admin-Only Command

```julia
@check has_permissions(:ADMINISTRATOR)
@slash_command client "config" "Configure the bot" function(ctx)
    respond(ctx; content="Config panel:", ephemeral=true)
end
```

### Owner-Only Command

```julia
@check is_owner()
@slash_command client "shutdown" "Shut down the bot" function(ctx)
    respond(ctx; content="Shutting down...")
    stop(ctx.client)
end
```

### Guild-Only (No DMs)

```julia
@check is_in_guild()
@slash_command client "server-info" "Show server info" function(ctx)
    respond(ctx; content="Guild: $(ctx.guild_id)")
end
```

## 7. Creating Private Channels via Overwrites

```julia
function create_private_channel(client, guild_id, name, user_id)
    # @everyone can't view, specific user can
    overwrites = [
        Dict(
            "id" => string(guild_id),    # @everyone role ID = guild ID
            "type" => 0,                  # role overwrite
            "deny" => string(PermViewChannel.value),
            "allow" => "0",
        ),
        Dict(
            "id" => string(user_id),
            "type" => 1,                  # member overwrite
            "deny" => "0",
            "allow" => string((PermViewChannel | PermSendMessages | PermReadMessageHistory).value),
        ),
    ]

    body = Dict(
        "name" => name,
        "type" => ChannelTypes.GUILD_TEXT,
        "permission_overwrites" => overwrites,
    )

    create_guild_channel(client.ratelimiter, guild_id; token=client.token, body)
end

# Usage
channel = create_private_channel(client, guild_id, "ticket-123", user_id)
create_message(client, channel.id; content="This channel is private to <@$(user_id)>.")
```

## 8. Bot Permission Self-Check

Ensure the bot has the permissions it needs:

```julia
on(client, GuildCreate) do c, event
    guild = event.guild
    me_id = c.state.me.id

    perms = get_member_permissions(c, guild.id, me_id)

    required = PermSendMessages | PermEmbedLinks | PermManageMessages
    if !has_flag(perms, required)
        missing_perms = String[]
        has_flag(perms, PermSendMessages) || push!(missing_perms, "Send Messages")
        has_flag(perms, PermEmbedLinks) || push!(missing_perms, "Embed Links")
        has_flag(perms, PermManageMessages) || push!(missing_perms, "Manage Messages")
        @warn "Missing permissions in guild" guild=guild.name missing=missing_perms
    end
end
```

---

**Next steps:** [Recipe 07 — Caching](07-caching.md) to optimize state management for your bot's size.

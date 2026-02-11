# Pre-execution checks (guards) for slash commands
#
# Checks are functions that receive an InteractionContext and return true (pass)
# or false (fail). When a check fails, the command handler is NOT invoked.
# If the check does not respond to the interaction, a default ephemeral
# "permission denied" message is sent automatically.

"""
    _PENDING_CHECKS

Module-level accumulator for `@check` macro. Each `@check` pushes a check
function here, and the next `@slash_command` drains it.
"""
const _PENDING_CHECKS = Function[]
const _CHECKS_LOCK = ReentrantLock()

"""
    drain_pending_checks!() -> Vector{Function}

Drain all pending checks accumulated by `@check` macros.
Called internally by `@slash_command`.
"""
function drain_pending_checks!()
    lock(_CHECKS_LOCK) do
        checks = copy(_PENDING_CHECKS)
        empty!(_PENDING_CHECKS)
        return checks
    end
end

# === Permission symbol mapping ===

const _PERM_SYMBOL_MAP = Dict{Symbol, Permissions}()

function _init_perm_map!()
    mapping = [
        # SCREAMING_SNAKE_CASE variants
        :CREATE_INSTANT_INVITE => PermCreateInstantInvite,
        :KICK_MEMBERS          => PermKickMembers,
        :BAN_MEMBERS           => PermBanMembers,
        :ADMINISTRATOR         => PermAdministrator,
        :MANAGE_CHANNELS       => PermManageChannels,
        :MANAGE_GUILD          => PermManageGuild,
        :ADD_REACTIONS         => PermAddReactions,
        :VIEW_AUDIT_LOG        => PermViewAuditLog,
        :VIEW_CHANNEL          => PermViewChannel,
        :SEND_MESSAGES         => PermSendMessages,
        :MANAGE_MESSAGES       => PermManageMessages,
        :EMBED_LINKS           => PermEmbedLinks,
        :ATTACH_FILES          => PermAttachFiles,
        :READ_MESSAGE_HISTORY  => PermReadMessageHistory,
        :MENTION_EVERYONE      => PermMentionEveryone,
        :CONNECT               => PermConnect,
        :SPEAK                 => PermSpeak,
        :MUTE_MEMBERS          => PermMuteMembers,
        :DEAFEN_MEMBERS        => PermDeafenMembers,
        :MOVE_MEMBERS          => PermMoveMembers,
        :MANAGE_ROLES          => PermManageRoles,
        :MANAGE_WEBHOOKS       => PermManageWebhooks,
        :MANAGE_GUILD_EXPRESSIONS => PermManageGuildExpressions,
        :USE_APPLICATION_COMMANDS => PermUseApplicationCommands,
        :MANAGE_EVENTS         => PermManageEvents,
        :MANAGE_THREADS        => PermManageThreads,
        :SEND_MESSAGES_IN_THREADS => PermSendMessagesInThreads,
        :MODERATE_MEMBERS      => PermModerateMembers,
        :SEND_VOICE_MESSAGES   => PermSendVoiceMessages,
        :SEND_POLLS            => PermSendPolls,
    ]
    for (sym, perm) in mapping
        _PERM_SYMBOL_MAP[sym] = perm
    end
end

"""Resolve a permission symbol or Permissions value to Permissions."""
function _resolve_perm(p::Permissions)
    return p
end

function _resolve_perm(s::Symbol)
    perm = get(_PERM_SYMBOL_MAP, s, nothing)
    isnothing(perm) && error("Unknown permission symbol :$s. Use e.g. :MANAGE_GUILD, :BAN_MEMBERS")
    return perm
end

function _resolve_perms(perms...)
    result = Permissions(0)
    for p in perms
        result = result | _resolve_perm(p)
    end
    return result
end

# === Built-in Check Factories ===

"""
    has_permissions(perms...) -> Function

Create a check that verifies the invoking user has all specified permissions.
Accepts `Permissions` values or symbols (`:MANAGE_GUILD`, `:BAN_MEMBERS`, etc.).

# Examples
```julia
@check has_permissions(PermManageGuild)
@check has_permissions(:MANAGE_GUILD, :BAN_MEMBERS)
@check has_permissions(PermManageGuild | PermBanMembers)
```
"""
function has_permissions(perms::Permissions)
    required = perms
    return function(ctx)
        guild_id = ctx.interaction.guild_id
        (ismissing(guild_id) || isnothing(guild_id)) && return false

        member = ctx.interaction.member
        (ismissing(member) || isnothing(member)) && return false

        user = _is_present(member.user) ? member.user : nothing
        isnothing(user) && return false

        # Get guild roles from cache
        role_store = get(ctx.client.state.roles, guild_id, nothing)
        isnothing(role_store) && return false
        guild_roles = collect(values(role_store))
        isempty(guild_roles) && return false

        # Get guild for owner check
        guild = get(ctx.client.state.guilds, guild_id)
        owner_id = (!isnothing(guild) && !ismissing(guild.owner_id)) ? guild.owner_id : Snowflake(0)

        member_roles = ismissing(member.roles) ? Snowflake[] : member.roles
        base_perms = compute_base_permissions(member_roles, guild_roles, owner_id, user.id)

        return has_flag(base_perms, required)
    end
end

function has_permissions(perms...)
    resolved = _resolve_perms(perms...)
    return has_permissions(resolved)
end

"""
    is_owner() -> Function

Create a check that verifies the invoking user is the guild owner.

# Example
```julia
@check is_owner()
@slash_command client "nuke" "Owner-only command" function(ctx)
    respond(ctx; content="Only the owner can do this!")
end
```
"""
function is_owner()
    return function(ctx)
        guild_id = ctx.interaction.guild_id
        (ismissing(guild_id) || isnothing(guild_id)) && return false

        guild = get(ctx.client.state.guilds, guild_id)
        isnothing(guild) && return false
        ismissing(guild.owner_id) && return false

        user = ctx.user
        isnothing(user) && return false

        return user.id == guild.owner_id
    end
end

"""
    is_in_guild() -> Function

Create a check that verifies the interaction was triggered inside a guild (not DMs).

# Example
```julia
@check is_in_guild()
@slash_command client "server-info" "Show server info" function(ctx)
    respond(ctx; content="Guild ID: \$(ctx.guild_id)")
end
```
"""
function is_in_guild()
    return function(ctx)
        guild_id = ctx.interaction.guild_id
        return !ismissing(guild_id) && !isnothing(guild_id)
    end
end

"""
    cooldown(seconds::Real; per::Symbol=:user) -> Function

Create a cooldown check. If the cooldown has not expired, sends an ephemeral
message with the remaining time and blocks execution.

`per` can be `:user`, `:guild`, `:channel`, or `:global`.

# Example
```julia
@check cooldown(5)                    # 5s per user
@check cooldown(30; per=:guild)       # 30s per guild
@slash_command client "roll" "Roll dice" handler
```
"""
function cooldown(seconds::Real; per::Symbol=:user)
    timestamps = Dict{UInt64, Float64}()
    lk = ReentrantLock()

    return function(ctx)
        key = _cooldown_key(ctx, per)
        now_t = time()

        lock(lk) do
            last = get(timestamps, key, 0.0)
            remaining = seconds - (now_t - last)
            if remaining > 0
                if !ctx.responded[]
                    respond(ctx;
                        content="Cooldown: wait $(round(remaining; digits=1))s.",
                        ephemeral=true)
                end
                return false
            end
            timestamps[key] = now_t
            return true
        end
    end
end

function _cooldown_key(ctx, per::Symbol)::UInt64
    if per == :user
        user = ctx.user
        isnothing(user) ? UInt64(0) : user.id.value
    elseif per == :guild
        gid = ctx.interaction.guild_id
        (ismissing(gid) || isnothing(gid)) ? UInt64(0) : gid.value
    elseif per == :channel
        cid = ctx.interaction.channel_id
        (ismissing(cid) || isnothing(cid)) ? UInt64(0) : cid.value
    elseif per == :global
        UInt64(0)
    else
        error("Unknown cooldown bucket type :$per. Use :user, :guild, :channel, or :global.")
    end
end

"""
    CheckFailedError

Error thrown internally when a pre-execution check fails.
Contains the name of the failed check for diagnostics.
"""
struct CheckFailedError <: Exception
    check_name::String
    message::String
end

CheckFailedError(name::String) = CheckFailedError(name, "Check '$name' failed.")

"""
    run_checks(checks::Vector{Function}, ctx::InteractionContext) -> Bool

Run all check functions against a context. Returns `true` if all pass.
If a check fails and the interaction hasn't been responded to, sends
a default ephemeral error message.
"""
function run_checks(checks::Vector{Function}, ctx)
    for check_fn in checks
        try
            result = check_fn(ctx)
            if !result
                # Send default error if not already responded
                if !ctx.responded[]
                    respond(ctx;
                        content="❌ You don't have permission to use this command.",
                        ephemeral=true
                    )
                end
                return false
            end
        catch e
            @error "Check function error" exception=(e, catch_backtrace())
            if !ctx.responded[]
                respond(ctx;
                    content="❌ An error occurred while checking permissions.",
                    ephemeral=true
                )
            end
            return false
        end
    end
    return true
end

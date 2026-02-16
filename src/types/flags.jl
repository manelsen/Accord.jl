# Bitfield flag types for Discord API v10

"""Use this to verify if a user has specific permissions or if certain flags are enabled.

Check if `a` has all flags in `b` set.

# Example
```julia
perms = PermSendMessages | PermEmbedLinks
has_flag(perms, PermSendMessages)   # => true
has_flag(perms, PermAdministrator)  # => false
```
"""
function has_flag end

"""
    @discord_flags Name begin
        FLAG_NAME = value
        ...
    end

Use this macro when creating new bitfield flag types for Discord API features.

Define a flags type backed by UInt64 with bitwise operations.
"""
macro discord_flags(name, block)
    # Parse the flag definitions
    defs = []
    for expr in block.args
        expr isa LineNumberNode && continue
        if expr isa Expr && expr.head == :(=)
            push!(defs, (expr.args[1], expr.args[2]))
        end
    end

    const_exprs = [:(const $(esc(n)) = $(esc(name))(UInt64($(esc(v))))) for (n, v) in defs]

    quote
        struct $(esc(name))
            value::UInt64
        end
        $(esc(name))(x::Integer) = $(esc(name))(UInt64(x))

        Base.:(|)(a::$(esc(name)), b::$(esc(name))) = $(esc(name))(a.value | b.value)
        Base.:(&)(a::$(esc(name)), b::$(esc(name))) = $(esc(name))(a.value & b.value)
        Base.xor(a::$(esc(name)), b::$(esc(name))) = $(esc(name))(xor(a.value, b.value))
        Base.:(~)(a::$(esc(name))) = $(esc(name))(~a.value)
        Base.:(==)(a::$(esc(name)), b::$(esc(name))) = a.value == b.value
        Base.hash(a::$(esc(name)), h::UInt) = hash(a.value, h)
        Base.iszero(a::$(esc(name))) = iszero(a.value)
        Base.zero(::Type{$(esc(name))}) = $(esc(name))(UInt64(0))

        $(@__MODULE__).has_flag(a::$(esc(name)), b::$(esc(name))) = (a & b) == b

        Base.show(io::IO, f::$(esc(name))) = print(io, $(string(name)), "(", f.value, ")")

        $(const_exprs...)
    end
end

"""Use this macro internally to enable JSON serialization for flag types.

Register integer-based StructTypes for a flags type.

# Example
```julia
@_flags_structtypes_int MyFlagsType
```
"""
macro _flags_structtypes_int(name)
    quote
        $StructTypes.StructType(::Type{$(esc(name))}) = $StructTypes.CustomStruct()
        $StructTypes.lower(f::$(esc(name))) = f.value
        $StructTypes.lowertype(::Type{$(esc(name))}) = UInt64
        $StructTypes.construct(::Type{$(esc(name))}, v::Integer) = $(esc(name))(UInt64(v))
    end
end

# --- Intents ---
@discord_flags Intents begin
    IntentGuilds                      = 1 << 0
    IntentGuildMembers                = 1 << 1
    IntentGuildModeration             = 1 << 2
    IntentGuildExpressions            = 1 << 3
    IntentGuildIntegrations           = 1 << 4
    IntentGuildWebhooks               = 1 << 5
    IntentGuildInvites                = 1 << 6
    IntentGuildVoiceStates            = 1 << 7
    IntentGuildPresences              = 1 << 8
    IntentGuildMessages               = 1 << 9
    IntentGuildMessageReactions       = 1 << 10
    IntentGuildMessageTyping          = 1 << 11
    IntentDirectMessages              = 1 << 12
    IntentDirectMessageReactions      = 1 << 13
    IntentDirectMessageTyping         = 1 << 14
    IntentMessageContent              = 1 << 15
    IntentGuildScheduledEvents        = 1 << 16
    IntentAutoModerationConfiguration = 1 << 20
    IntentAutoModerationExecution     = 1 << 21
    IntentGuildMessagePolls           = 1 << 24
    IntentDirectMessagePolls          = 1 << 25
end

"""
    Intents

Gateway intents allow you to subscribe to specific buckets of events sent by Discord.
Privileged intents (Members, Presences, MessageContent) must be enabled in the Developer Portal.

[Discord docs](https://discord.com/developers/docs/topics/gateway#gateway-intents)

# Example
```julia
# Combine intents using the | operator
intents = IntentGuilds | IntentGuildMessages | IntentMessageContent
```
"""
Intents

"""Use this constant to request all standard gateway intents when connecting your bot.

All non-privileged intents.

# Example
```julia
client = Client("Bot my_token"; intents=IntentAllNonPrivileged)
```
"""
const IntentAllNonPrivileged = IntentGuilds | IntentGuildModeration | IntentGuildExpressions |
    IntentGuildIntegrations | IntentGuildWebhooks | IntentGuildInvites |
    IntentGuildVoiceStates | IntentGuildMessages | IntentGuildMessageReactions |
    IntentGuildMessageTyping | IntentDirectMessages | IntentDirectMessageReactions |
    IntentDirectMessageTyping | IntentGuildScheduledEvents |
    IntentAutoModerationConfiguration | IntentAutoModerationExecution |
    IntentGuildMessagePolls | IntentDirectMessagePolls

"""Use this constant to request all gateway intents including privileged ones (requires enabling in Discord Developer Portal).

All intents including privileged (GuildMembers, GuildPresences, MessageContent).

# Example
```julia
client = Client("Bot my_token"; intents=IntentAll)
```
"""
const IntentAll = IntentAllNonPrivileged | IntentGuildMembers | IntentGuildPresences | IntentMessageContent

@_flags_structtypes_int Intents

# --- Permissions ---
@discord_flags Permissions begin
    PermCreateInstantInvite  = 1 << 0
    PermKickMembers          = 1 << 1
    PermBanMembers           = 1 << 2
    PermAdministrator        = 1 << 3
    PermManageChannels       = 1 << 4
    PermManageGuild          = 1 << 5
    PermAddReactions         = 1 << 6
    PermViewAuditLog         = 1 << 7
    PermPrioritySpeaker      = 1 << 8
    PermStream               = 1 << 9
    PermViewChannel          = 1 << 10
    PermSendMessages         = 1 << 11
    PermSendTTSMessages      = 1 << 12
    PermManageMessages       = 1 << 13
    PermEmbedLinks           = 1 << 14
    PermAttachFiles          = 1 << 15
    PermReadMessageHistory   = 1 << 16
    PermMentionEveryone      = 1 << 17
    PermUseExternalEmojis    = 1 << 18
    PermViewGuildInsights    = 1 << 19
    PermConnect              = 1 << 20
    PermSpeak                = 1 << 21
    PermMuteMembers          = 1 << 22
    PermDeafenMembers        = 1 << 23
    PermMoveMembers          = 1 << 24
    PermUseVAD               = 1 << 25
    PermChangeNickname       = 1 << 26
    PermManageNicknames      = 1 << 27
    PermManageRoles          = 1 << 28
    PermManageWebhooks       = 1 << 29
    PermManageGuildExpressions = 1 << 30
    PermUseApplicationCommands = 1 << 31
    PermRequestToSpeak       = 1 << 32
    PermManageEvents         = 1 << 33
    PermManageThreads        = 1 << 34
    PermCreatePublicThreads  = 1 << 35
    PermCreatePrivateThreads = 1 << 36
    PermUseExternalStickers  = 1 << 37
    PermSendMessagesInThreads = 1 << 38
    PermUseEmbeddedActivities = 1 << 39
    PermModerateMembers      = 1 << 40
    PermViewCreatorMonetizationAnalytics = 1 << 41
    PermUseSoundboard        = 1 << 42
    PermCreateGuildExpressions = 1 << 43
    PermCreateEvents         = 1 << 44
    PermUseExternalSounds    = 1 << 45
    PermSendVoiceMessages    = 1 << 46
    PermSendPolls            = 1 << 49
    PermUseExternalApps      = 1 << 50
end

"""
    Permissions

Discord permissions are stored as a bitmask. Accord.jl provides constant values for each permission.
Use [`has_flag`](@ref) to check if a set of permissions contains a specific one.

[Discord docs](https://discord.com/developers/docs/topics/permissions#permissions-bitwise-value-flags)

# Example
```julia
# Check for a specific permission
if has_flag(member_perms, PermAdministrator)
    println("User is an admin")
end

# Combine permissions
required = PermSendMessages | PermEmbedLinks
```
"""
Permissions

# Permissions come as strings in JSON (to handle >64-bit in future)
StructTypes.StructType(::Type{Permissions}) = StructTypes.CustomStruct()
StructTypes.lower(p::Permissions) = string(p.value)
StructTypes.lowertype(::Type{Permissions}) = String
StructTypes.construct(::Type{Permissions}, s::String) = Permissions(parse(UInt64, s))
StructTypes.construct(::Type{Permissions}, v::Integer) = Permissions(UInt64(v))

# --- Message Flags ---
@discord_flags MessageFlags begin
    MsgFlagCrossposted                        = 1 << 0
    MsgFlagIsCrosspost                        = 1 << 1
    MsgFlagSuppressEmbeds                     = 1 << 2
    MsgFlagSourceMessageDeleted               = 1 << 3
    MsgFlagUrgent                             = 1 << 4
    MsgFlagHasThread                          = 1 << 5
    MsgFlagEphemeral                          = 1 << 6
    MsgFlagLoading                            = 1 << 7
    MsgFlagFailedToMentionSomeRolesInThread   = 1 << 8
    MsgFlagSuppressNotifications              = 1 << 12
    MsgFlagIsVoiceMessage                     = 1 << 13
end

"""
    MessageFlags

Bitfield representing extra attributes of a message, such as whether it is ephemeral or crossposted.

[Discord docs](https://discord.com/developers/docs/resources/message#message-object-message-flags)
"""
MessageFlags

@_flags_structtypes_int MessageFlags

# --- User Flags ---
@discord_flags UserFlags begin
    UserFlagStaff                 = 1 << 0
    UserFlagPartner               = 1 << 1
    UserFlagHypeSquad             = 1 << 2
    UserFlagBugHunterLevel1       = 1 << 3
    UserFlagHypeSquadBravery      = 1 << 6
    UserFlagHypeSquadBrilliance   = 1 << 7
    UserFlagHypeSquadBalance      = 1 << 8
    UserFlagEarlyNitroSupporter   = 1 << 9
    UserFlagTeamPseudoUser        = 1 << 10
    UserFlagBugHunterLevel2       = 1 << 14
    UserFlagVerifiedBot           = 1 << 16
    UserFlagVerifiedDeveloper     = 1 << 17
    UserFlagCertifiedModerator    = 1 << 18
    UserFlagBotHTTPInteractions   = 1 << 19
    UserFlagActiveDeveloper       = 1 << 22
end

"""
    UserFlags

Bitfield representing public flags on a user's account, such as whether they are a Discord employee or a partner.

[Discord docs](https://discord.com/developers/docs/resources/user#user-object-user-flags)
"""
UserFlags

@_flags_structtypes_int UserFlags

# --- System Channel Flags ---
@discord_flags SystemChannelFlags begin
    SysChanSuppressJoinNotifications          = 1 << 0
    SysChanSuppressPremiumSubscriptions       = 1 << 1
    SysChanSuppressGuildReminderNotifications = 1 << 2
    SysChanSuppressJoinNotificationReplies    = 1 << 3
    SysChanSuppressRoleSubscriptionPurchaseNotifications       = 1 << 4
    SysChanSuppressRoleSubscriptionPurchaseNotificationReplies = 1 << 5
end

"""
    SystemChannelFlags

Bitfield representing which standard system notifications are disabled in a guild's system channel.

[Discord docs](https://discord.com/developers/docs/resources/guild#guild-object-system-channel-flags)
"""
SystemChannelFlags

@_flags_structtypes_int SystemChannelFlags

# --- Channel Flags ---
@discord_flags ChannelFlags begin
    ChanFlagPinned                 = 1 << 1
    ChanFlagRequireTag             = 1 << 4
    ChanFlagHideMediaDownloadOptions = 1 << 15
end

"""
    ChannelFlags

Bitfield representing extra attributes of a channel, such as whether it is pinned in a forum.

[Discord docs](https://discord.com/developers/docs/resources/channel#channel-object-channel-flags)
"""
ChannelFlags

@_flags_structtypes_int ChannelFlags

# --- Guild Member Flags ---
@discord_flags GuildMemberFlags begin
    MemberFlagDidRejoin            = 1 << 0
    MemberFlagCompletedOnboarding  = 1 << 1
    MemberFlagBypassesVerification = 1 << 2
    MemberFlagStartedOnboarding    = 1 << 3
    MemberFlagIsGuest              = 1 << 4
    MemberFlagStartedHomeActions   = 1 << 5
    MemberFlagCompletedHomeActions = 1 << 6
    MemberFlagAutomodQuarantinedUsername = 1 << 7
    MemberFlagDMSettingsUpsellAcknowledged = 1 << 9
end

"""
    GuildMemberFlags

Bitfield representing attributes of a guild member, such as whether they have completed onboarding.

[Discord docs](https://discord.com/developers/docs/resources/guild#guild-member-object-guild-member-flags)
"""
GuildMemberFlags

@_flags_structtypes_int GuildMemberFlags

# --- Role Flags ---
@discord_flags RoleFlags begin
    RoleFlagInPrompt = 1 << 0
end

"""
    RoleFlags

Bitfield representing attributes of a role, such as whether it is displayed in an onboarding prompt.

[Discord docs](https://discord.com/developers/docs/topics/permissions#role-object-role-flags)
"""
RoleFlags

@_flags_structtypes_int RoleFlags

# --- Attachment Flags ---
@discord_flags AttachmentFlags begin
    AttachFlagIsRemix = 1 << 2
end

"""
    AttachmentFlags

Bitfield representing attributes of an attachment, such as whether it is a remix.

[Discord docs](https://discord.com/developers/docs/resources/message#attachment-object-attachment-flags)
"""
AttachmentFlags

@_flags_structtypes_int AttachmentFlags

# --- SKU Flags ---
@discord_flags SKUFlags begin
    SKUFlagAvailable         = 1 << 2
    SKUFlagGuildSubscription = 1 << 7
    SKUFlagUserSubscription  = 1 << 8
end

"""
    SKUFlags

Bitfield representing attributes of a SKU, such as whether it is a user or guild subscription.

[Discord docs](https://discord.com/developers/docs/resources/sku#sku-object-sku-flags)
"""
SKUFlags

@_flags_structtypes_int SKUFlags

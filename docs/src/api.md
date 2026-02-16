```@meta
CurrentModule = Accord
```

# [Accord.jl — API Reference](@id api-reference)

> Discord API v10 library for Julia.
> Version: 0.1.0 | API Base: `https://discord.com/api/v10`

---

!!! note "Optional vs Nullable"
    Accord.jl uses two distinct type aliases for Discord's optional fields:
    
    - **`Optional{T}`** (`Union{T, Missing}`): Field may be absent from the JSON entirely. Check with `ismissing()`. Default value is `missing`.
    - **`Nullable{T}`** (`Union{T, Nothing}`): Field is present but may be JSON `null`. Check with `isnothing()`. Default value is `nothing`.
    
    This distinction mirrors Discord's API: some fields are omitted when not applicable, others are explicitly set to `null`.

---

## 1. Client

```@docs
Client
start
stop
on
on_error
wait_until_ready
wait_for
reply
update_presence
request_guild_members
activity
```

## 2. Events

```@docs
AbstractEvent
ReadyEvent
ResumedEvent
ChannelCreate
ChannelUpdate
ChannelDelete
ChannelPinsUpdate
ThreadCreate
ThreadUpdate
ThreadDelete
ThreadListSync
ThreadMemberUpdate
ThreadMembersUpdate
GuildCreate
GuildUpdate
GuildDelete
GuildAuditLogEntryCreate
GuildBanAdd
GuildBanRemove
GuildEmojisUpdate
GuildStickersUpdate
GuildIntegrationsUpdate
GuildMemberAdd
GuildMemberRemove
GuildMemberUpdate
GuildMembersChunk
GuildRoleCreate
GuildRoleUpdate
GuildRoleDelete
GuildScheduledEventCreate
GuildScheduledEventUpdate
GuildScheduledEventDelete
GuildScheduledEventUserAdd
GuildScheduledEventUserRemove
GuildSoundboardSoundCreate
GuildSoundboardSoundUpdate
GuildSoundboardSoundDelete
GuildSoundboardSoundsUpdate
SoundboardSounds
IntegrationCreate
IntegrationUpdate
IntegrationDelete
InteractionCreate
InviteCreate
InviteDelete
MessageCreate
MessageUpdate
MessageDelete
MessageDeleteBulk
MessageReactionAdd
MessageReactionRemove
MessageReactionRemoveAll
MessageReactionRemoveEmoji
MessagePollVoteAdd
MessagePollVoteRemove
PresenceUpdate
StageInstanceCreate
StageInstanceUpdate
StageInstanceDelete
TypingStart
UserUpdate
VoiceStateUpdateEvent
VoiceServerUpdate
VoiceChannelEffectSend
WebhooksUpdate
EntitlementCreate
EntitlementUpdate
EntitlementDelete
SubscriptionCreate
SubscriptionUpdate
SubscriptionDelete
AutoModerationRuleCreate
AutoModerationRuleUpdate
AutoModerationRuleDelete
AutoModerationActionExecution
```

## 3. State & Caching

```@docs
State
Store
CacheStrategy
CacheForever
CacheNever
CacheLRU
CacheTTL
update_state!
```

## 4. REST Endpoints

### Messages
```@docs
create_message
edit_message
delete_message
bulk_delete_messages
get_channel_message
get_channel_messages
crosspost_message
create_reaction
delete_own_reaction
delete_user_reaction
delete_all_reactions
delete_all_reactions_for_emoji
get_reactions
get_answer_voters
end_poll
pin_message
unpin_message
get_pinned_messages
```

### Channels & Guilds
```@docs
get_channel
modify_channel
delete_channel
edit_channel_permissions
delete_channel_permission
get_channel_invites
create_channel_invite
follow_announcement_channel
trigger_typing_indicator
get_guild
modify_guild
delete_guild
get_guild_channels
create_guild_channel
modify_guild_channel_positions
get_guild_preview
list_guild_members
search_guild_members
get_guild_member
add_guild_member
modify_guild_member
modify_current_member
remove_guild_member
add_guild_member_role
remove_guild_member_role
leave_guild
get_guild_bans
get_guild_ban
create_guild_ban
remove_guild_ban
bulk_guild_ban
get_guild_roles
get_guild_role
create_guild_role
modify_guild_role_positions
modify_guild_role
delete_guild_role
get_guild_prune_count
begin_guild_prune
get_guild_voice_regions
get_guild_invites
get_guild_integrations
delete_guild_integration
get_guild_widget_settings
modify_guild_widget
get_guild_widget
get_guild_vanity_url
get_guild_welcome_screen
modify_guild_welcome_screen
get_guild_onboarding
modify_guild_onboarding
```

### Threads
```@docs
start_thread_from_message
start_thread_without_message
start_thread_in_forum
join_thread
add_thread_member
leave_thread
remove_thread_member
get_thread_member
list_thread_members
list_public_archived_threads
list_private_archived_threads
list_joined_private_archived_threads
list_active_guild_threads
```

### Interactions
```@docs
get_global_application_commands
create_global_application_command
get_global_application_command
edit_global_application_command
delete_global_application_command
bulk_overwrite_global_application_commands
get_guild_application_commands
create_guild_application_command
get_guild_application_command
edit_guild_application_command
delete_guild_application_command
bulk_overwrite_guild_application_commands
get_guild_application_command_permissions
get_application_command_permissions
edit_application_command_permissions
create_interaction_response
get_original_interaction_response
edit_original_interaction_response
delete_original_interaction_response
create_followup_message
get_followup_message
edit_followup_message
delete_followup_message
```

### Users & Webhooks
```@docs
get_current_user
get_user
modify_current_user
get_current_user_guilds
get_current_user_guild_member
create_dm
get_current_user_connections
get_current_user_application_role_connection
update_current_user_application_role_connection
get_gateway_bot
create_webhook
get_channel_webhooks
get_guild_webhooks
get_webhook
get_webhook_with_token
modify_webhook
modify_webhook_with_token
delete_webhook
delete_webhook_with_token
execute_webhook
get_webhook_message
edit_webhook_message
delete_webhook_message
```

### Emoji & Stickers
```@docs
list_guild_emojis
get_guild_emoji
create_guild_emoji
modify_guild_emoji
delete_guild_emoji
list_application_emojis
get_application_emoji
create_application_emoji
modify_application_emoji
delete_application_emoji
get_sticker
list_sticker_packs
list_guild_stickers
get_guild_sticker
create_guild_sticker
modify_guild_sticker
delete_guild_sticker
```

### Invites, Audit Log & AutoMod
```@docs
get_invite
delete_invite
get_guild_audit_log
list_auto_moderation_rules
get_auto_moderation_rule
create_auto_moderation_rule
modify_auto_moderation_rule
delete_auto_moderation_rule
```

### Other REST
```@docs
list_scheduled_events
create_guild_scheduled_event
get_guild_scheduled_event
modify_guild_scheduled_event
delete_guild_scheduled_event
get_guild_scheduled_event_users
create_stage_instance
get_stage_instance
modify_stage_instance
delete_stage_instance
list_default_soundboard_sounds
list_guild_soundboard_sounds
get_guild_soundboard_sound
create_guild_soundboard_sound
modify_guild_soundboard_sound
delete_guild_soundboard_sound
send_soundboard_sound
list_voice_regions
list_skus
list_entitlements
create_test_entitlement
delete_test_entitlement
consume_entitlement
get_entitlement
list_sku_subscriptions
get_sku_subscription
get_guild_templates
create_guild_template
sync_guild_template
modify_guild_template
delete_guild_template
create_guild_from_template
get_current_application
modify_current_application
get_application_role_connection_metadata_records
update_application_role_connection_metadata_records
```

## 5. Interactions — DSL & Macros

```@docs
InteractionContext
Base.getproperty(::InteractionContext, ::Symbol)
CommandTree
sync_commands!
register_command!
register_component!
register_modal!
register_autocomplete!
dispatch_interaction!
@slash_command
@user_command
@message_command
@button_handler
@select_handler
@modal_handler
@autocomplete
@check
@option
@on_message
respond
defer
followup
edit_response
show_modal
get_options
get_option
custom_id
selected_values
modal_values
target
run_checks
drain_pending_checks!
cooldown
is_owner
is_in_guild
has_permissions
CheckFailedError
```

### Component & Embed Builders

```@docs
button
string_select
user_select
role_select
mentionable_select
channel_select
select_option
text_input
action_row
embed
embed_footer
embed_author
embed_field
thumbnail
command_option
container
section
text_display
separator
media_gallery
media_gallery_item
file_component
unfurled_media
```

## 6. Voice

```@docs
VoiceClient
connect!
disconnect!
update_voice_state
AudioPlayer
play!
stop!
pause!
resume!
is_playing
AbstractAudioSource
PCMSource
FileSource
FFmpegSource
SilenceSource
close_source
read_frame
OpusEncoder
OpusDecoder
opus_encode
opus_decode
set_bitrate!
set_signal!
init_sodium
random_nonce
```

## 7. Types

### Core
```@docs
Snowflake
timestamp
worker_id
process_id
increment
User
Member
Role
DiscordChannel
Message
Embed
Interaction
Emoji
Reaction
AutoModRule
Guild
Presence
Attachment
```

### Channel Types
```@docs
ThreadMetadata
ThreadMember
ForumTag
DefaultReaction
Overwrite
```

### Embed Types
```@docs
EmbedFooter
EmbedImage
EmbedThumbnail
EmbedVideo
EmbedField
EmbedAuthor
EmbedProvider
```

### Interaction & Command Types
```@docs
InteractionData
InteractionDataOption
ResolvedData
ApplicationCommand
ApplicationCommandOption
ApplicationCommandOptionChoice
CommandDefinition
```

### Component Types
```@docs
Component
SelectOption
```

### Guild Types
```@docs
GuildFeatures
RoleTags
Ban
GuildTemplate
```

### Activity & Presence Types
```@docs
Activity
ActivityTimestamps
ActivityEmoji
ActivityParty
ActivityAssets
ActivitySecrets
ActivityButton
ClientStatus
```

### Poll Types
```@docs
Poll
PollMedia
PollAnswer
PollAnswerCount
PollResults
RecurrenceRule
RecurrenceRuleNWeekday
```

### Audit Log Types
```@docs
AuditLog
AuditLogEntry
AuditLogEntryInfo
AuditLogChange
```

### AutoMod Types
```@docs
AutoModAction
AutoModActionMetadata
AutoModTriggerMetadata
```

### Sticker Types
```@docs
Sticker
StickerItem
StickerPack
```

### Invite & Webhook Types
```@docs
Invite
InviteMetadata
Webhook
```

### Voice Types
```@docs
VoiceState
VoiceRegion
```

### Stage, Sound & Connection Types
```@docs
StageInstance
SoundboardSound
Connection
ReactionCountDetails
```

### Monetization Types
```@docs
SKU
Entitlement
Subscription
```

### Scheduled Event Types
```@docs
ScheduledEvent
EntityMetadata
```

### Integration Types
```@docs
Integration
IntegrationAccount
IntegrationApplication
```

### Onboarding Types
```@docs
Onboarding
OnboardingPrompt
OnboardingPromptOption
```

## 8. Enums, Flags & Permissions

### Enums
```@docs
ChannelTypes
InteractionTypes
InteractionCallbackTypes
ApplicationCommandTypes
ApplicationCommandOptionTypes
ComponentTypes
ButtonStyles
TextInputStyles
ActivityTypes
MessageTypes
VerificationLevels
DefaultMessageNotificationLevels
ExplicitContentFilterLevels
MFALevels
NSFWLevels
PremiumTiers
PremiumTypes
StatusTypes
WebhookTypes
AuditLogEventTypes
AutoModTriggerTypes
AutoModEventTypes
AutoModActionTypes
AutoModKeywordPresetTypes
SortOrderTypes
ForumLayoutTypes
StickerTypes
StickerFormatTypes
InviteTargetTypes
ScheduledEventPrivacyLevels
ScheduledEventStatuses
ScheduledEventEntityTypes
StageInstancePrivacyLevels
OnboardingModes
SKUTypes
EntitlementTypes
AllowedMentionTypes
Locales
```

### Intents
```@docs
Intents
IntentGuilds
IntentGuildMembers
IntentGuildModeration
IntentGuildExpressions
IntentGuildIntegrations
IntentGuildWebhooks
IntentGuildInvites
IntentGuildVoiceStates
IntentGuildPresences
IntentGuildMessages
IntentGuildMessageReactions
IntentGuildMessageTyping
IntentDirectMessages
IntentDirectMessageReactions
IntentDirectMessageTyping
IntentMessageContent
IntentGuildScheduledEvents
IntentAutoModerationConfiguration
IntentAutoModerationExecution
IntentGuildMessagePolls
IntentDirectMessagePolls
IntentAllNonPrivileged
IntentAll
```

### Permissions Utilities
```@docs
Permissions
has_flag
compute_base_permissions
compute_channel_permissions
```

### Message Flags
```@docs
MessageFlags
MsgFlagCrossposted
MsgFlagIsCrosspost
MsgFlagSuppressEmbeds
MsgFlagSourceMessageDeleted
MsgFlagUrgent
MsgFlagHasThread
MsgFlagEphemeral
MsgFlagLoading
MsgFlagFailedToMentionSomeRolesInThread
MsgFlagSuppressNotifications
MsgFlagIsVoiceMessage
```

### User Flags
```@docs
UserFlags
UserFlagStaff
UserFlagPartner
UserFlagHypeSquad
UserFlagBugHunterLevel1
UserFlagHypeSquadBravery
UserFlagHypeSquadBrilliance
UserFlagHypeSquadBalance
UserFlagEarlyNitroSupporter
UserFlagTeamPseudoUser
UserFlagBugHunterLevel2
UserFlagVerifiedBot
UserFlagVerifiedDeveloper
UserFlagCertifiedModerator
UserFlagBotHTTPInteractions
UserFlagActiveDeveloper
```

### Channel Flags
```@docs
ChannelFlags
ChanFlagPinned
ChanFlagRequireTag
ChanFlagHideMediaDownloadOptions
```

### Guild Member Flags
```@docs
GuildMemberFlags
MemberFlagDidRejoin
MemberFlagCompletedOnboarding
MemberFlagBypassesVerification
MemberFlagStartedOnboarding
MemberFlagIsGuest
MemberFlagStartedHomeActions
MemberFlagCompletedHomeActions
MemberFlagAutomodQuarantinedUsername
MemberFlagDMSettingsUpsellAcknowledged
```

### System Channel Flags
```@docs
SystemChannelFlags
SysChanSuppressJoinNotifications
SysChanSuppressJoinNotificationReplies
SysChanSuppressPremiumSubscriptions
SysChanSuppressGuildReminderNotifications
SysChanSuppressRoleSubscriptionPurchaseNotifications
SysChanSuppressRoleSubscriptionPurchaseNotificationReplies
```

### Role Flags
```@docs
RoleFlags
RoleFlagInPrompt
```

### Attachment Flags
```@docs
AttachmentFlags
AttachFlagIsRemix
```

### SKU Flags
```@docs
SKUFlags
SKUFlagAvailable
SKUFlagGuildSubscription
SKUFlagUserSubscription
```

### Macros
```@docs
@discord_struct
@discord_flags
@_flags_structtypes_int
```

---

## 9. Event System

```@docs
EventHandler
EventWaiter
register_handler!
register_middleware!
dispatch_event!
parse_event
```

## 10. Gateway & Internals

### Gateway
```@docs
GatewaySession
ShardInfo
GatewayCommand
GatewayCloseCodes.can_reconnect
start_shard
stop_shard
send_to_shard
gateway_connect
shard_for_guild
```

### Rate Limiter
```@docs
RateLimiter
BucketState
RestJob
Route
url
start_ratelimiter!
stop_ratelimiter!
submit_rest
```

### HTTP Methods
```@docs
discord_get
discord_post
discord_put
discord_patch
discord_delete
discord_request
```

### Response Parsing
```@docs
parse_response
parse_response_array
```

### Voice Gateway
```@docs
VoiceGatewaySession
voice_gateway_connect
send_select_protocol
send_speaking
create_voice_udp
ip_discovery
select_encryption_mode
ENCRYPTION_MODES
send_voice_packet
```

### RTP & Codec
```@docs
rtp_header
parse_rtp_header
RTPPacket
```

### Encryption
```@docs
xsalsa20_poly1305_encrypt
xsalsa20_poly1305_decrypt
aead_xchacha20_poly1305_encrypt
aead_xchacha20_poly1305_decrypt
```

### Heartbeat
```@docs
start_heartbeat
stop_heartbeat!
heartbeat_ack!
heartbeat_latency
```

### Private Helpers
```@docs
_notify_waiters!
_PENDING_CHECKS
_resolve_perm
```

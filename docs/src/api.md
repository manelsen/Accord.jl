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
```

## 2. Events

```@docs
AbstractEvent
ReadyEvent
ResumedEvent
MessageCreate
InteractionCreate
GuildCreate
GuildMemberAdd
ChannelDelete
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
```

### Channels & Guilds
```@docs
get_channel
modify_channel
get_guild
modify_guild
delete_guild
get_guild_channels
create_guild_channel
modify_guild_channel_positions
list_guild_members
get_guild_member
add_guild_member
modify_guild_member
modify_current_member
remove_guild_member
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
get_original_interaction_response
edit_original_interaction_response
delete_original_interaction_response
create_followup_message
get_followup_message
edit_followup_message
delete_followup_message
```

### Other REST
```@docs
get_current_user
get_user
modify_current_user
get_current_user_guilds
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
modify_guild_sticker
delete_guild_sticker
get_invite
delete_invite
get_guild_audit_log
list_auto_moderation_rules
get_auto_moderation_rule
create_auto_moderation_rule
modify_auto_moderation_rule
delete_auto_moderation_rule
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
PCMSource
FileSource
FFmpegSource
SilenceSource
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
```

## 8. Enums, Flags & Permissions

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
Intents
Permissions
has_flag
```

---

## 9. Gateway Internals

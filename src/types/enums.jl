# All Discord API v10 enums

# --- Channel Types ---
"""
    ChannelTypes

Constants for the various types of channels in Discord.

[Discord docs](https://discord.com/developers/docs/resources/channel#channel-object-channel-types)
"""
module ChannelTypes
    const GUILD_TEXT           = 0
    const DM                   = 1
    const GUILD_VOICE          = 2
    const GROUP_DM             = 3
    const GUILD_CATEGORY       = 4
    const GUILD_ANNOUNCEMENT   = 5
    const ANNOUNCEMENT_THREAD  = 10
    const PUBLIC_THREAD        = 11
    const PRIVATE_THREAD       = 12
    const GUILD_STAGE_VOICE    = 13
    const GUILD_DIRECTORY      = 14
    const GUILD_FORUM          = 15
    const GUILD_MEDIA          = 16
end

# --- Message Types ---
"""
    MessageTypes

Constants for the various types of messages in Discord.

[Discord docs](https://discord.com/developers/docs/resources/message#message-object-message-types)
"""
module MessageTypes
    const DEFAULT                                      = 0
    const RECIPIENT_ADD                                = 1
    const RECIPIENT_REMOVE                             = 2
    const CALL                                         = 3
    const CHANNEL_NAME_CHANGE                          = 4
    const CHANNEL_ICON_CHANGE                          = 5
    const CHANNEL_PINNED_MESSAGE                       = 6
    const USER_JOIN                                    = 7
    const GUILD_BOOST                                  = 8
    const GUILD_BOOST_TIER_1                           = 9
    const GUILD_BOOST_TIER_2                           = 10
    const GUILD_BOOST_TIER_3                            = 11
    const CHANNEL_FOLLOW_ADD                           = 12
    const GUILD_DISCOVERY_DISQUALIFIED                 = 14
    const GUILD_DISCOVERY_REQUALIFIED                  = 15
    const GUILD_DISCOVERY_GRACE_PERIOD_INITIAL_WARNING = 16
    const GUILD_DISCOVERY_GRACE_PERIOD_FINAL_WARNING   = 17
    const THREAD_CREATED                               = 18
    const REPLY                                        = 19
    const CHAT_INPUT_COMMAND                           = 20
    const THREAD_STARTER_MESSAGE                       = 21
    const GUILD_INVITE_REMINDER                        = 22
    const CONTEXT_MENU_COMMAND                         = 23
    const AUTO_MODERATION_ACTION                       = 24
    const ROLE_SUBSCRIPTION_PURCHASE                   = 25
    const INTERACTION_PREMIUM_UPSELL                   = 26
    const STAGE_START                                  = 27
    const STAGE_END                                    = 28
    const STAGE_SPEAKER                                = 29
    const STAGE_TOPIC                                  = 31
    const GUILD_APPLICATION_PREMIUM_SUBSCRIPTION       = 32
    const GUILD_INCIDENT_ALERT_MODE_ENABLED            = 36
    const GUILD_INCIDENT_ALERT_MODE_DISABLED           = 37
    const GUILD_INCIDENT_REPORT_RAID                   = 38
    const GUILD_INCIDENT_REPORT_FALSE_ALARM            = 39
    const PURCHASE_NOTIFICATION                        = 44
    const POLL_RESULT                                  = 46
end

# --- Interaction Types ---
"""
    InteractionTypes

Constants for the various types of interactions in Discord.

[Discord docs](https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-type)
"""
module InteractionTypes
    const PING                             = 1
    const APPLICATION_COMMAND              = 2
    const MESSAGE_COMPONENT                = 3
    const APPLICATION_COMMAND_AUTOCOMPLETE = 4
    const MODAL_SUBMIT                     = 5
end

# --- Interaction Callback Types ---
"""
    InteractionCallbackTypes

Constants for the various ways to respond to an interaction.

[Discord docs](https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-response-object-interaction-callback-type)
"""
module InteractionCallbackTypes
    const PONG                                    = 1
    const CHANNEL_MESSAGE_WITH_SOURCE             = 4
    const DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE    = 5
    const DEFERRED_UPDATE_MESSAGE                 = 6
    const UPDATE_MESSAGE                          = 7
    const APPLICATION_COMMAND_AUTOCOMPLETE_RESULT = 8
    const MODAL                                   = 9
    const PREMIUM_REQUIRED                        = 10
    const LAUNCH_ACTIVITY                         = 12
end

# --- Application Command Types ---
"""
    ApplicationCommandTypes

Constants for the various types of application commands.

[Discord docs](https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-types)
"""
module ApplicationCommandTypes
    const CHAT_INPUT = 1
    const USER       = 2
    const MESSAGE    = 3
    const PRIMARY_ENTRY_POINT = 4
end

# --- Application Command Option Types ---
"""
    ApplicationCommandOptionTypes

Constants for the various types of options for application commands.

[Discord docs](https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-type)
"""
module ApplicationCommandOptionTypes
    const SUB_COMMAND       = 1
    const SUB_COMMAND_GROUP = 2
    const STRING            = 3
    const INTEGER           = 4
    const BOOLEAN           = 5
    const USER              = 6
    const CHANNEL           = 7
    const ROLE              = 8
    const MENTIONABLE       = 9
    const NUMBER            = 10
    const ATTACHMENT        = 11
end

# --- Component Types ---
"""
    ComponentTypes

Constants for the various types of message components.

[Discord docs](https://discord.com/developers/docs/interactions/message-components#component-object-component-types)
"""
module ComponentTypes
    const ACTION_ROW         = 1
    const BUTTON             = 2
    const STRING_SELECT      = 3
    const TEXT_INPUT          = 4
    const USER_SELECT        = 5
    const ROLE_SELECT         = 6
    const MENTIONABLE_SELECT = 7
    const CHANNEL_SELECT     = 8
    # Components V2
    const SECTION            = 9
    const TEXT_DISPLAY        = 10
    const THUMBNAIL          = 11
    const MEDIA_GALLERY      = 12
    const FILE               = 13
    const SEPARATOR          = 14
    const CONTAINER          = 17
end

# --- Button Styles ---
"""
    ButtonStyles

Constants for the various visual styles of buttons.

[Discord docs](https://discord.com/developers/docs/interactions/message-components#button-object-button-styles)
"""
module ButtonStyles
    const PRIMARY   = 1
    const SECONDARY = 2
    const SUCCESS   = 3
    const DANGER    = 4
    const LINK      = 5
    const PREMIUM   = 6
end

# --- Text Input Styles ---
"""
    TextInputStyles

Constants for the various visual styles of text inputs in modals.

[Discord docs](https://discord.com/developers/docs/interactions/message-components#text-input-object-text-input-styles)
"""
module TextInputStyles
    const SHORT     = 1
    const PARAGRAPH = 2
end

# --- Verification Levels ---
"""
    VerificationLevels

Constants for the various guild verification levels.

[Discord docs](https://discord.com/developers/docs/resources/guild#guild-object-verification-level)
"""
module VerificationLevels
    const NONE      = 0
    const LOW       = 1
    const MEDIUM    = 2
    const HIGH      = 3
    const VERY_HIGH = 4
end

# --- Default Message Notification Levels ---
"""
    DefaultMessageNotificationLevels

Constants for the various guild default message notification levels.

[Discord docs](https://discord.com/developers/docs/resources/guild#guild-object-default-message-notification-level)
"""
module DefaultMessageNotificationLevels
    const ALL_MESSAGES  = 0
    const ONLY_MENTIONS = 1
end

# --- Explicit Content Filter Levels ---
"""
    ExplicitContentFilterLevels

Constants for the various guild explicit content filter levels.

[Discord docs](https://discord.com/developers/docs/resources/guild#guild-object-explicit-content-filter-level)
"""
module ExplicitContentFilterLevels
    const DISABLED              = 0
    const MEMBERS_WITHOUT_ROLES = 1
    const ALL_MEMBERS           = 2
end

# --- MFA Levels ---
"""
    MFALevels

Constants for the various guild multi-factor authentication levels.

[Discord docs](https://discord.com/developers/docs/resources/guild#guild-object-mfa-level)
"""
module MFALevels
    const NONE     = 0
    const ELEVATED = 1
end

# --- NSFW Levels ---
"""
    NSFWLevels

Constants for the various guild NSFW levels.

[Discord docs](https://discord.com/developers/docs/resources/guild#guild-object-nsfw-level)
"""
module NSFWLevels
    const DEFAULT        = 0
    const EXPLICIT       = 1
    const SAFE           = 2
    const AGE_RESTRICTED = 3
end

# --- Premium Tiers ---
"""
    PremiumTiers

Constants for the various guild premium (Boost) tiers.

[Discord docs](https://discord.com/developers/docs/resources/guild#guild-object-premium-tier)
"""
module PremiumTiers
    const NONE   = 0
    const TIER_1 = 1
    const TIER_2 = 2
    const TIER_3 = 3
end

# --- Premium Types ---
"""
    PremiumTypes

Constants for the various user premium (Nitro) types.

[Discord docs](https://discord.com/developers/docs/resources/user#user-object-premium-types)
"""
module PremiumTypes
    const NONE          = 0
    const NITRO_CLASSIC = 1
    const NITRO          = 2
    const NITRO_BASIC   = 3
end

# --- Activity Types ---
"""
    ActivityTypes

Constants for the various types of presence activities.

[Discord docs](https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-types)
"""
module ActivityTypes
    const GAME      = 0
    const STREAMING = 1
    const LISTENING = 2
    const WATCHING  = 3
    const CUSTOM    = 4
    const COMPETING = 5
end

# --- Status Types ---
"""
    StatusTypes

Constants for the various presence status strings.

[Discord docs](https://discord.com/developers/docs/topics/gateway-events#update-presence-status-types)
"""
module StatusTypes
    const ONLINE    = "online"
    const DND       = "dnd"
    const IDLE      = "idle"
    const INVISIBLE = "invisible"
    const OFFLINE   = "offline"
end

# --- Webhook Types ---
"""
    WebhookTypes

Constants for the various types of webhooks.

[Discord docs](https://discord.com/developers/docs/resources/webhook#webhook-object-webhook-types)
"""
module WebhookTypes
    const INCOMING         = 1
    const CHANNEL_FOLLOWER = 2
    const APPLICATION      = 3
end

# --- Audit Log Event Types ---
"""
    AuditLogEventTypes

Constants for the various types of events recorded in the audit log.

[Discord docs](https://discord.com/developers/docs/resources/audit-log#audit-log-entry-object-audit-log-events)
"""
module AuditLogEventTypes
    const GUILD_UPDATE             = 1
    const CHANNEL_CREATE           = 10
    const CHANNEL_UPDATE           = 11
    const CHANNEL_DELETE           = 12
    const CHANNEL_OVERWRITE_CREATE = 13
    const CHANNEL_OVERWRITE_UPDATE = 14
    const CHANNEL_OVERWRITE_DELETE = 15
    const MEMBER_KICK              = 20
    const MEMBER_PRUNE             = 21
    const MEMBER_BAN_ADD           = 22
    const MEMBER_BAN_REMOVE        = 23
    const MEMBER_UPDATE            = 24
    const MEMBER_ROLE_UPDATE       = 25
    const MEMBER_MOVE              = 26
    const MEMBER_DISCONNECT        = 27
    const BOT_ADD                  = 28
    const ROLE_CREATE              = 30
    const ROLE_UPDATE              = 31
    const ROLE_DELETE              = 32
    const INVITE_CREATE            = 40
    const INVITE_UPDATE            = 41
    const INVITE_DELETE            = 42
    const WEBHOOK_CREATE           = 50
    const WEBHOOK_UPDATE           = 51
    const WEBHOOK_DELETE           = 52
    const EMOJI_CREATE             = 60
    const EMOJI_UPDATE             = 61
    const EMOJI_DELETE             = 62
    const MESSAGE_DELETE           = 72
    const MESSAGE_BULK_DELETE      = 73
    const MESSAGE_PIN              = 74
    const MESSAGE_UNPIN            = 75
    const INTEGRATION_CREATE       = 80
    const INTEGRATION_UPDATE       = 81
    const INTEGRATION_DELETE       = 82
    const STAGE_INSTANCE_CREATE    = 83
    const STAGE_INSTANCE_UPDATE    = 84
    const STAGE_INSTANCE_DELETE    = 85
    const STICKER_CREATE           = 90
    const STICKER_UPDATE           = 91
    const STICKER_DELETE           = 92
    const GUILD_SCHEDULED_EVENT_CREATE = 100
    const GUILD_SCHEDULED_EVENT_UPDATE = 101
    const GUILD_SCHEDULED_EVENT_DELETE = 102
    const THREAD_CREATE            = 110
    const THREAD_UPDATE            = 111
    const THREAD_DELETE            = 112
    const APPLICATION_COMMAND_PERMISSION_UPDATE = 121
    const SOUNDBOARD_SOUND_CREATE  = 130
    const SOUNDBOARD_SOUND_UPDATE  = 131
    const SOUNDBOARD_SOUND_DELETE  = 132
    const AUTO_MODERATION_RULE_CREATE  = 140
    const AUTO_MODERATION_RULE_UPDATE  = 141
    const AUTO_MODERATION_RULE_DELETE  = 142
    const AUTO_MODERATION_BLOCK_MESSAGE = 143
    const AUTO_MODERATION_FLAG_TO_CHANNEL = 144
    const AUTO_MODERATION_USER_COMMUNICATION_DISABLED = 145
    const CREATOR_MONETIZATION_REQUEST_CREATED = 150
    const CREATOR_MONETIZATION_TERMS_ACCEPTED  = 151
    const ONBOARDING_PROMPT_CREATE = 163
    const ONBOARDING_PROMPT_UPDATE = 164
    const ONBOARDING_PROMPT_DELETE = 165
    const ONBOARDING_CREATE        = 166
    const ONBOARDING_UPDATE        = 167
    const VOICE_CHANNEL_STATUS_UPDATE = 192
    const VOICE_CHANNEL_STATUS_DELETE = 193
end

# --- Auto Moderation ---
"""
    AutoModTriggerTypes

Constants for the various types of triggers for auto moderation rules.

[Discord docs](https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-rule-object-trigger-types)
"""
module AutoModTriggerTypes
    const KEYWORD        = 1
    const SPAM           = 3
    const KEYWORD_PRESET = 4
    const MENTION_SPAM   = 5
    const MEMBER_PROFILE = 6
end

"""
    AutoModEventTypes

Constants for the various event contexts where auto moderation rules are checked.

[Discord docs](https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-rule-object-event-types)
"""
module AutoModEventTypes
    const MESSAGE_SEND  = 1
    const MEMBER_UPDATE = 2
end

"""
    AutoModActionTypes

Constants for the various actions that auto moderation rules can take.

[Discord docs](https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-action-object-action-types)
"""
module AutoModActionTypes
    const BLOCK_MESSAGE      = 1
    const SEND_ALERT_MESSAGE = 2
    const TIMEOUT            = 3
    const BLOCK_MEMBER_INTERACTION = 4
end

"""
    AutoModKeywordPresetTypes

Constants for the various built-in word lists for auto moderation.

[Discord docs](https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-rule-object-keyword-preset-types)
"""
module AutoModKeywordPresetTypes
    const PROFANITY      = 1
    const SEXUAL_CONTENT = 2
    const SLURS          = 3
end

# --- Scheduled Event ---
"""
    ScheduledEventPrivacyLevels

Constants for the various privacy levels of guild scheduled events.

[Discord docs](https://discord.com/developers/docs/resources/guild-scheduled-event#guild-scheduled-event-object-guild-scheduled-event-privacy-level)
"""
module ScheduledEventPrivacyLevels
    const GUILD_ONLY = 2
end

"""
    ScheduledEventEntityTypes

Constants for the various types of entities associated with guild scheduled events.

[Discord docs](https://discord.com/developers/docs/resources/guild-scheduled-event#guild-scheduled-event-object-guild-scheduled-event-entity-types)
"""
module ScheduledEventEntityTypes
    const STAGE_INSTANCE = 1
    const VOICE          = 2
    const EXTERNAL       = 3
end

"""
    ScheduledEventStatuses

Constants for the various statuses of guild scheduled events.

[Discord docs](https://discord.com/developers/docs/resources/guild-scheduled-event#guild-scheduled-event-object-guild-scheduled-event-status)
"""
module ScheduledEventStatuses
    const SCHEDULED = 1
    const ACTIVE    = 2
    const COMPLETED = 3
    const CANCELED  = 4
end

# --- Stage Instance ---
"""
    StageInstancePrivacyLevels

Constants for the various privacy levels of Stage instances.

[Discord docs](https://discord.com/developers/docs/resources/stage-instance#stage-instance-object-privacy-level)
"""
module StageInstancePrivacyLevels
    const PUBLIC     = 1
    const GUILD_ONLY = 2
end

# --- Sticker ---
"""
    StickerTypes

Constants for the various types of stickers.

[Discord docs](https://discord.com/developers/docs/resources/sticker#sticker-object-sticker-types)
"""
module StickerTypes
    const STANDARD = 1
    const GUILD    = 2
end

"""
    StickerFormatTypes

Constants for the various formats of stickers.

[Discord docs](https://discord.com/developers/docs/resources/sticker#sticker-object-sticker-format-types)
"""
module StickerFormatTypes
    const PNG    = 1
    const APNG   = 2
    const LOTTIE = 3
    const GIF    = 4
end

# --- Invite Target Types ---
"""
    InviteTargetTypes

Constants for the various types of targets for voice channel invites.

[Discord docs](https://discord.com/developers/docs/resources/invite#invite-object-invite-target-types)
"""
module InviteTargetTypes
    const STREAM                     = 1
    const EMBED_APPLICATION       = 2
end

# --- Guild Features (as string constants) ---
"""
    GuildFeatures

String constants for the various features a guild can have enabled.

[Discord docs](https://discord.com/developers/docs/resources/guild#guild-object-guild-features)
"""
module GuildFeatures
    const ANIMATED_BANNER                  = "ANIMATED_BANNER"
    const ANIMATED_ICON                    = "ANIMATED_ICON"
    const APPLICATION_COMMAND_PERMISSIONS_V2 = "APPLICATION_COMMAND_PERMISSIONS_V2"
    const AUTO_MODERATION                  = "AUTO_MODERATION"
    const BANNER                           = "BANNER"
    const COMMUNITY                        = "COMMUNITY"
    const CREATOR_MONETIZABLE_PROVISIONAL  = "CREATOR_MONETIZABLE_PROVISIONAL"
    const CREATOR_STORE_PAGE               = "CREATOR_STORE_PAGE"
    const DEVELOPER_SUPPORT_SERVER         = "DEVELOPER_SUPPORT_SERVER"
    const DISCOVERABLE                     = "DISCOVERABLE"
    const FEATURABLE                       = "FEATURABLE"
    const INVITES_DISABLED                 = "INVITES_DISABLED"
    const INVITE_SPLASH                    = "INVITE_SPLASH"
    const MEMBER_VERIFICATION_GATE_ENABLED = "MEMBER_VERIFICATION_GATE_ENABLED"
    const MORE_STICKERS                    = "MORE_STICKERS"
    const NEWS                             = "NEWS"
    const PARTNERED                        = "PARTNERED"
    const PREVIEW_ENABLED                  = "PREVIEW_ENABLED"
    const RAID_ALERTS_DISABLED             = "RAID_ALERTS_DISABLED"
    const ROLE_ICONS                       = "ROLE_ICONS"
    const ROLE_SUBSCRIPTIONS_AVAILABLE_FOR_PURCHASE = "ROLE_SUBSCRIPTIONS_AVAILABLE_FOR_PURCHASE"
    const ROLE_SUBSCRIPTIONS_ENABLED       = "ROLE_SUBSCRIPTIONS_ENABLED"
    const TICKETED_EVENTS_ENABLED          = "TICKETED_EVENTS_ENABLED"
    const VANITY_URL                       = "VANITY_URL"
    const VERIFIED                         = "VERIFIED"
    const VIP_REGIONS                      = "VIP_REGIONS"
    const WELCOME_SCREEN_ENABLED           = "WELCOME_SCREEN_ENABLED"
end

# --- Locale ---
"""
    Locales

Constants for the various supported locales in Discord.

[Discord docs](https://discord.com/developers/docs/reference#locales)
"""
module Locales
    const INDONESIAN    = "id"
    const DANISH        = "da"
    const GERMAN        = "de"
    const ENGLISH_UK    = "en-GB"
    const ENGLISH_US    = "en-US"
    const SPANISH       = "es-ES"
    const SPANISH_LATAM = "es-419"
    const FRENCH        = "fr"
    const CROATIAN      = "hr"
    const ITALIAN       = "it"
    const LITHUANIAN    = "lt"
    const HUNGARIAN     = "hu"
    const DUTCH         = "nl"
    const NORWEGIAN     = "no"
    const POLISH        = "pl"
    const PORTUGUESE_BR = "pt-BR"
    const ROMANIAN      = "ro"
    const FINNISH       = "fi"
    const SWEDISH       = "sv-SE"
    const VIETNAMESE    = "vi"
    const TURKISH       = "tr"
    const CZECH         = "cs"
    const GREEK         = "el"
    const BULGARIAN     = "bg"
    const RUSSIAN       = "ru"
    const UKRAINIAN     = "uk"
    const HINDI         = "hi"
    const THAI          = "th"
    const CHINESE_CN    = "zh-CN"
    const JAPANESE      = "ja"
    const CHINESE_TW    = "zh-TW"
    const KOREAN        = "ko"
end

# --- SKU Types ---
"""
    SKUTypes

Constants for the various types of SKUs.

[Discord docs](https://discord.com/developers/docs/resources/sku#sku-object-sku-types)
"""
module SKUTypes
    const DURABLE          = 2
    const CONSUMABLE       = 3
    const SUBSCRIPTION     = 5
    const SUBSCRIPTION_GROUP = 6
end

# --- Entitlement Types ---
"""
    EntitlementTypes

Constants for the various types of entitlements.

[Discord docs](https://discord.com/developers/docs/resources/entitlement#entitlement-object-entitlement-types)
"""
module EntitlementTypes
    const PURCHASE                = 1
    const PREMIUM_SUBSCRIPTION    = 2
    const DEVELOPER_GIFT          = 3
    const TEST_MODE_PURCHASE      = 4
    const FREE_PURCHASE           = 5
    const USER_GIFT               = 6
    const PREMIUM_PURCHASE        = 7
    const APPLICATION_SUBSCRIPTION = 8
end

# --- Sort Order Types ---
"""
    SortOrderTypes

Constants for the various sort orders for forum and media channels.

[Discord docs](https://discord.com/developers/docs/resources/channel#channel-object-sort-order-types)
"""
module SortOrderTypes
    const LATEST_ACTIVITY = 0
    const CREATION_DATE   = 1
end

# --- Forum Layout Types ---
"""
    ForumLayoutTypes

Constants for the various forum layout views.

[Discord docs](https://discord.com/developers/docs/resources/channel#channel-object-forum-layout-types)
"""
module ForumLayoutTypes
    const NOT_SET      = 0
    const LIST_VIEW    = 1
    const GALLERY_VIEW = 2
end

# --- Onboarding Mode ---
"""
    OnboardingModes

Constants for the various guild onboarding modes.

[Discord docs](https://discord.com/developers/docs/resources/guild#guild-onboarding-object-onboarding-mode)
"""
module OnboardingModes
    const ONBOARDING_DEFAULT  = 0
    const ONBOARDING_ADVANCED = 1
end

# --- Allowed Mention Types ---
"""
    AllowedMentionTypes

Constants for the various types of allowed mentions.

[Discord docs](https://discord.com/developers/docs/resources/message#allowed-mentions-object-allowed-mention-types)
"""
module AllowedMentionTypes
    const ROLES    = "roles"
    const USERS    = "users"
    const EVERYONE = "everyone"
end

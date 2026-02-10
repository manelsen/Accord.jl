# All Discord API v10 enums

# --- Channel Types ---
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
module InteractionTypes
    const PING                             = 1
    const APPLICATION_COMMAND              = 2
    const MESSAGE_COMPONENT                = 3
    const APPLICATION_COMMAND_AUTOCOMPLETE = 4
    const MODAL_SUBMIT                     = 5
end

# --- Interaction Callback Types ---
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
module ApplicationCommandTypes
    const CHAT_INPUT = 1
    const USER       = 2
    const MESSAGE    = 3
    const PRIMARY_ENTRY_POINT = 4
end

# --- Application Command Option Types ---
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
module ButtonStyles
    const PRIMARY   = 1
    const SECONDARY = 2
    const SUCCESS   = 3
    const DANGER    = 4
    const LINK      = 5
    const PREMIUM   = 6
end

# --- Text Input Styles ---
module TextInputStyles
    const SHORT     = 1
    const PARAGRAPH = 2
end

# --- Verification Levels ---
module VerificationLevels
    const NONE      = 0
    const LOW       = 1
    const MEDIUM    = 2
    const HIGH      = 3
    const VERY_HIGH = 4
end

# --- Default Message Notification Levels ---
module DefaultMessageNotificationLevels
    const ALL_MESSAGES  = 0
    const ONLY_MENTIONS = 1
end

# --- Explicit Content Filter Levels ---
module ExplicitContentFilterLevels
    const DISABLED              = 0
    const MEMBERS_WITHOUT_ROLES = 1
    const ALL_MEMBERS           = 2
end

# --- MFA Levels ---
module MFALevels
    const NONE     = 0
    const ELEVATED = 1
end

# --- NSFW Levels ---
module NSFWLevels
    const DEFAULT        = 0
    const EXPLICIT       = 1
    const SAFE           = 2
    const AGE_RESTRICTED = 3
end

# --- Premium Tiers ---
module PremiumTiers
    const NONE   = 0
    const TIER_1 = 1
    const TIER_2 = 2
    const TIER_3 = 3
end

# --- Premium Types ---
module PremiumTypes
    const NONE          = 0
    const NITRO_CLASSIC = 1
    const NITRO          = 2
    const NITRO_BASIC   = 3
end

# --- Activity Types ---
module ActivityTypes
    const GAME      = 0
    const STREAMING = 1
    const LISTENING = 2
    const WATCHING  = 3
    const CUSTOM    = 4
    const COMPETING = 5
end

# --- Status Types ---
module StatusTypes
    const ONLINE    = "online"
    const DND       = "dnd"
    const IDLE      = "idle"
    const INVISIBLE = "invisible"
    const OFFLINE   = "offline"
end

# --- Webhook Types ---
module WebhookTypes
    const INCOMING         = 1
    const CHANNEL_FOLLOWER = 2
    const APPLICATION      = 3
end

# --- Audit Log Event Types ---
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
module AutoModTriggerTypes
    const KEYWORD        = 1
    const SPAM           = 3
    const KEYWORD_PRESET = 4
    const MENTION_SPAM   = 5
    const MEMBER_PROFILE = 6
end

module AutoModEventTypes
    const MESSAGE_SEND  = 1
    const MEMBER_UPDATE = 2
end

module AutoModActionTypes
    const BLOCK_MESSAGE      = 1
    const SEND_ALERT_MESSAGE = 2
    const TIMEOUT            = 3
    const BLOCK_MEMBER_INTERACTION = 4
end

module AutoModKeywordPresetTypes
    const PROFANITY      = 1
    const SEXUAL_CONTENT = 2
    const SLURS          = 3
end

# --- Scheduled Event ---
module ScheduledEventPrivacyLevels
    const GUILD_ONLY = 2
end

module ScheduledEventEntityTypes
    const STAGE_INSTANCE = 1
    const VOICE          = 2
    const EXTERNAL       = 3
end

module ScheduledEventStatuses
    const SCHEDULED = 1
    const ACTIVE    = 2
    const COMPLETED = 3
    const CANCELED  = 4
end

# --- Stage Instance ---
module StageInstancePrivacyLevels
    const PUBLIC     = 1
    const GUILD_ONLY = 2
end

# --- Sticker ---
module StickerTypes
    const STANDARD = 1
    const GUILD    = 2
end

module StickerFormatTypes
    const PNG    = 1
    const APNG   = 2
    const LOTTIE = 3
    const GIF    = 4
end

# --- Invite Target Types ---
module InviteTargetTypes
    const STREAM                     = 1
    const EMBEDDED_APPLICATION       = 2
end

# --- Guild Features (as string constants) ---
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
module SKUTypes
    const DURABLE          = 2
    const CONSUMABLE       = 3
    const SUBSCRIPTION     = 5
    const SUBSCRIPTION_GROUP = 6
end

# --- Entitlement Types ---
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
module SortOrderTypes
    const LATEST_ACTIVITY = 0
    const CREATION_DATE   = 1
end

# --- Forum Layout Types ---
module ForumLayoutTypes
    const NOT_SET      = 0
    const LIST_VIEW    = 1
    const GALLERY_VIEW = 2
end

# --- Onboarding Mode ---
module OnboardingModes
    const ONBOARDING_DEFAULT  = 0
    const ONBOARDING_ADVANCED = 1
end

# --- Allowed Mention Types ---
module AllowedMentionTypes
    const ROLES    = "roles"
    const USERS    = "users"
    const EVERYONE = "everyone"
end

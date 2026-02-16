"""
    OnboardingPromptOption

An option shown in an onboarding prompt that a user can select.

[Discord docs](https://discord.com/developers/docs/resources/guild#guild-onboarding-object-prompt-option-structure)

# Fields
- `id::Snowflake` — ID of the prompt option.
- `channel_ids::Vector{Snowflake}` — IDs for channels a member is added to when the option is selected.
- `role_ids::Vector{Snowflake}` — IDs for roles assigned to a member when the option is selected.
- `emoji::Optional{Emoji}` — Emoji of the option.
- `emoji_id::Optional{Snowflake}` — Emoji ID of the option.
- `emoji_name::Optional{String}` — Emoji name of the option.
- `emoji_animated::Optional{Bool}` — Whether the emoji is animated.
- `title::String` — Title of the option (1-50 characters).
- `description::Nullable{String}` — Description of the option (1-100 characters).
"""
@discord_struct OnboardingPromptOption begin
    id::Snowflake
    channel_ids::Vector{Snowflake}
    role_ids::Vector{Snowflake}
    emoji::Optional{Emoji}
    emoji_id::Optional{Snowflake}
    emoji_name::Optional{String}
    emoji_animated::Optional{Bool}
    title::String
    description::Nullable{String}
end

"""
    OnboardingPrompt

A prompt shown during onboarding that users respond to by selecting one or more options.

[Discord docs](https://discord.com/developers/docs/resources/guild#guild-onboarding-object-prompt-structure)

# Fields
- `id::Snowflake` — ID of the prompt.
- `type::Int` — Type of the prompt. See `OnboardingPromptTypes` in `src/types/enums.jl`.
- `options::Vector{OnboardingPromptOption}` — Options available within the prompt.
- `title::String` — Title of the prompt (1-50 characters).
- `single_select::Bool` — Whether users are limited to selecting one option.
- `required::Bool` — Whether the prompt is required before completing onboarding.
- `in_onboarding::Bool` — Whether the prompt is present in the onboarding flow.
"""
@discord_struct OnboardingPrompt begin
    id::Snowflake
    type::Int
    options::Vector{OnboardingPromptOption}
    title::String
    single_select::Bool
    required::Bool
    in_onboarding::Bool
end

"""
    Onboarding

Onboarding configuration for a guild. Helps new members understand the rules and select roles/channels.

[Discord docs](https://discord.com/developers/docs/resources/guild#guild-onboarding-object)

# Fields
- `guild_id::Snowflake` — ID of the guild this onboarding is part of.
- `prompts::Vector{OnboardingPrompt}` — Prompts shown during onboarding and in customize community.
- `default_channel_ids::Vector{Snowflake}` — Channel IDs that members get opted into automatically.
- `enabled::Bool` — Whether onboarding is enabled in the guild.
- `mode::Int` — Current mode of onboarding. See [`OnboardingModes`](@ref) module.
"""
@discord_struct Onboarding begin
    guild_id::Snowflake
    prompts::Vector{OnboardingPrompt}
    default_channel_ids::Vector{Snowflake}
    enabled::Bool
    mode::Int
end

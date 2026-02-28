"""
    OnboardingPromptOption

An individual choice within an onboarding prompt.

# Fields
- `id::Snowflake`: Unique ID of the option.
- `channel_ids::Vector{Snowflake}`: Channels assigned if selected.
- `role_ids::Vector{Snowflake}`: Roles assigned if selected.
- `title::String`: Label for the option.
- `description::Nullable{String}`: Help text for the option.

# See Also
- [Discord API: Onboarding Prompt Option](https://discord.com/developers/docs/resources/guild#guild-onboarding-object-prompt-option-structure)
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

A question or choice shown to new members during guild onboarding.

# See Also
- [Discord API: Onboarding Prompt Object](https://discord.com/developers/docs/resources/guild#guild-onboarding-object-prompt-structure)
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

The complete onboarding configuration for a guild.

# Fields
- `guild_id::Snowflake`: Guild ID.
- `prompts::Vector{OnboardingPrompt}`: Questions shown during flow.
- `default_channel_ids::Vector{Snowflake}`: Channels everyone gets.
- `enabled::Bool`: Whether onboarding is active.
- `mode::Int`: Onboarding mode (see [`OnboardingModes`](@ref)).

# See Also
- [Discord API: Onboarding Object](https://discord.com/developers/docs/resources/guild#guild-onboarding-object)
"""
@discord_struct Onboarding begin
    guild_id::Snowflake
    prompts::Vector{OnboardingPrompt}
    default_channel_ids::Vector{Snowflake}
    enabled::Bool
    mode::Int
end

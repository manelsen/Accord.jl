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

@discord_struct OnboardingPrompt begin
    id::Snowflake
    type::Int
    options::Vector{OnboardingPromptOption}
    title::String
    single_select::Bool
    required::Bool
    in_onboarding::Bool
end

@discord_struct Onboarding begin
    guild_id::Snowflake
    prompts::Vector{OnboardingPrompt}
    default_channel_ids::Vector{Snowflake}
    enabled::Bool
    mode::Int
end

@discord_struct EntityMetadata begin
    location::Optional{String}
end

@discord_struct RecurrenceRuleNWeekday begin
    n::Int
    day::Int
end

@discord_struct RecurrenceRule begin
    start::String
    end_::Optional{String}
    frequency::Int
    interval::Int
    by_weekday::Optional{Vector{Int}}
    by_n_weekday::Optional{Vector{RecurrenceRuleNWeekday}}
    by_month::Optional{Vector{Int}}
    by_month_day::Optional{Vector{Int}}
    by_year_day::Optional{Vector{Int}}
    count::Optional{Int}
end

@discord_struct ScheduledEvent begin
    id::Snowflake
    guild_id::Snowflake
    channel_id::Nullable{Snowflake}
    creator_id::Optional{Snowflake}
    name::String
    description::Optional{String}
    scheduled_start_time::String
    scheduled_end_time::Nullable{String}
    privacy_level::Int
    status::Int
    entity_type::Int
    entity_id::Nullable{Snowflake}
    entity_metadata::Nullable{EntityMetadata}
    creator::Optional{User}
    user_count::Optional{Int}
    image::Nullable{String}
    recurrence_rule::Nullable{RecurrenceRule}
end

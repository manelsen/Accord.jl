"""
    EntityMetadata

Additional metadata for a [`ScheduledEvent`](@ref) (e.g., location for external events).

# See Also
- [Discord API: Entity Metadata](https://discord.com/developers/docs/resources/guild-scheduled-event#guild-scheduled-event-object-guild-scheduled-event-entity-metadata)
"""
@discord_struct EntityMetadata begin
    location::Optional{String}
end

"""
    RecurrenceRuleNWeekday

The nth weekday of a month for a recurring event.

# See Also
- [Discord API: Recurrence Rule N-Weekday](https://discord.com/developers/docs/resources/guild-scheduled-event#guild-scheduled-event-recurrence-rule-object-guild-scheduled-event-recurrence-rule-nweekday-structure)
"""
@discord_struct RecurrenceRuleNWeekday begin
    n::Int
    day::Int
end

"""
    RecurrenceRule

Defines how a [`ScheduledEvent`](@ref) repeats over time.

# See Also
- [Discord API: Recurrence Rule Object](https://discord.com/developers/docs/resources/guild-scheduled-event#guild-scheduled-event-recurrence-rule-object)
"""
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

"""
    ScheduledEvent

Represents a Discord guild scheduled event (Voice, Stage, or External).

Scheduled events allow servers to plan and publicize future gatherings.

# Fields
- `id::Snowflake`: Unique ID of the event.
- `guild_id::Snowflake`: Guild where the event is hosted.
- `channel_id::Nullable{Snowflake}`: Hosting channel (null for external).
- `name::String`: The event name.
- `description::Optional{String}`: The event description.
- `scheduled_start_time::String`: ISO8601 start time.
- `scheduled_end_time::Nullable{String}`: ISO8601 end time.
- `privacy_level::Int`: Privacy level (see [`ScheduledEventPrivacyLevels`](@ref)).
- `status::Int`: Event status (see [`ScheduledEventStatuses`](@ref)).
- `entity_type::Int`: Type of event (see [`ScheduledEventEntityTypes`](@ref)).
- `entity_id::Nullable{Snowflake}`: ID of the associated entity (e.g., Stage ID).
- `entity_metadata::Nullable{EntityMetadata}`: Metadata for external events.
- `creator::Optional{User}`: The user who created the event.
- `user_count::Optional{Int}`: Number of users who signed up.
- `image::Nullable{String}`: Cover image hash.
- `recurrence_rule::Nullable{RecurrenceRule}`: How the event repeats.

# See Also
- [Discord API: Scheduled Event Object](https://discord.com/developers/docs/resources/guild-scheduled-event#guild-scheduled-event-object)
"""
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

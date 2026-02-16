"""
    EntityMetadata

Additional metadata for guild scheduled events.

[Discord docs](https://discord.com/developers/docs/resources/guild-scheduled-event#guild-scheduled-event-object-guild-scheduled-event-entity-metadata)

# Fields
- `location::Optional{String}` — Location of the event (1-100 characters). Only for external events.
"""
@discord_struct EntityMetadata begin
    location::Optional{String}
end

"""
    RecurrenceRuleNWeekday

Represents the nth weekday of a month (e.g., "first Monday", "third Friday").

[Discord docs](https://discord.com/developers/docs/resources/guild-scheduled-event#guild-scheduled-event-recurrence-rule-object-guild-scheduled-event-recurrence-rule-nweekday-structure)

# Fields
- `n::Int` — The week number (1-5) within the month.
- `day::Int` — The day of the week (0-6, where 0 is Monday).
"""
@discord_struct RecurrenceRuleNWeekday begin
    n::Int
    day::Int
end

"""
    RecurrenceRule

Represents how often a guild scheduled event will recur.

[Discord docs](https://discord.com/developers/docs/resources/guild-scheduled-event#guild-scheduled-event-recurrence-rule-object)

# Fields
- `start::String` — Starting time of the recurrence interval. ISO8601 timestamp.
- `end_::Optional{String}` — Ending time of the recurrence interval. ISO8601 timestamp. Named `end_` to avoid conflict with Julia keyword.
- `frequency::Int` — How often the event occurs. See `RecurrenceRuleFrequency` constants in `src/types/enums.jl`.
- `interval::Int` — The spacing between events. For `WEEKLY` frequency, this is in weeks. For `MONTHLY` frequency, this is in months.
- `by_weekday::Optional{Vector{Int}}` — Specific days within a specific week (1-5) to recur on. Maximum 7.
- `by_n_weekday::Optional{Vector{RecurrenceRuleNWeekday}}` — List of [`RecurrenceRuleNWeekday`](@ref) objects to recur on.
- `by_month::Optional{Vector{Int}}` — Months to recur on (1-12).
- `by_month_day::Optional{Vector{Int}}` — Days of the month to recur on (1-31).
- `by_year_day::Optional{Vector{Int}}` — Days of the year to recur on (1-366).
- `count::Optional{Int}` — Total number of times the event is allowed to recur before stopping.
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

A scheduled event in a guild. Can be used to manage events like voice channel events, stage events, or external events.

[Discord docs](https://discord.com/developers/docs/resources/guild-scheduled-event#guild-scheduled-event-object)

# Fields
- `id::Snowflake` — Unique ID of the scheduled event.
- `guild_id::Snowflake` — Guild ID which the scheduled event belongs to.
- `channel_id::Nullable{Snowflake}` — Channel ID in which the scheduled event will be hosted. `nothing` for external events.
- `creator_id::Optional{Snowflake}` — ID of the user that created the scheduled event.
- `name::String` — Name of the scheduled event (1-100 characters).
- `description::Optional{String}` — Description of the scheduled event (1-1000 characters).
- `scheduled_start_time::String` — ISO8601 timestamp of the scheduled event start time.
- `scheduled_end_time::Nullable{String}` — ISO8601 timestamp of the scheduled event end time. Required for external events.
- `privacy_level::Int` — Privacy level of the scheduled event. See [`ScheduledEventPrivacyLevels`](@ref) module.
- `status::Int` — Status of the scheduled event. See [`ScheduledEventStatuses`](@ref) module.
- `entity_type::Int` — Type of the scheduled event. See [`ScheduledEventEntityTypes`](@ref) module.
- `entity_id::Nullable{Snowflake}` — ID of an entity associated with a guild scheduled event. Currently only stage instances.
- `entity_metadata::Nullable{EntityMetadata}` — Additional metadata for the guild scheduled event. Only for external events.
- `creator::Optional{User}` — User that created the scheduled event.
- `user_count::Optional{Int}` — Number of users subscribed to the scheduled event.
- `image::Nullable{String}` — Cover image hash of the scheduled event.
- `recurrence_rule::Nullable{RecurrenceRule}` — Definition for how often the scheduled event should recur.
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

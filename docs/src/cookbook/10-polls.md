# Recipe 10 — Polls

**Difficulty:** Beginner
**What you will build:** Discord-native polls with vote tracking, result checking, and early endings.

**Prerequisites:** [Recipe 01](01-basic-bot.md), [Recipe 03](03-slash-commands.md)

---

## 1. How Discord Polls Work

Polls are sent as part of a [`Message`](@ref) via the `poll` field. Users vote using Discord's native UI — no buttons needed.

Required intent for vote events:

```julia
client = Client(token;
    intents = IntentGuilds | IntentGuildMessages | IntentGuildMessagePolls
)
```

## 2. Creating a Poll

!!! note "Poll Duration and Answer Limits"
    Discord imposes limits on polls:
    - **Duration**: 1 to 336 hours (14 days maximum)
    - **Answers**: Maximum 10 answer choices per poll
    - **Question**: Maximum 300 characters
    - **Answer text**: Maximum 55 characters

Polls use the `poll` body in [`create_message`](@ref):

```julia
body = Dict{String, Any}(
    "poll" => Dict(
        "question" => Dict("text" => "What's your favorite language?"),
        "answers" => [
            Dict("answer_id" => 1, "poll_media" => Dict("text" => "Julia")),
            Dict("answer_id" => 2, "poll_media" => Dict("text" => "Python")),
            Dict("answer_id" => 3, "poll_media" => Dict("text" => "Rust")),
            Dict("answer_id" => 4, "poll_media" => Dict("text" => "Other")),
        ],
        "duration" => 24,            # hours (1-336, max 14 days)
        "allow_multiselect" => false, # single choice
        "layout_type" => 1,           # DEFAULT layout
    )
)

# Must call the REST endpoint directly for poll body
discord_post(client.ratelimiter, "/channels/$(channel_id)/messages";
    token=client.token, body=body)
```

### Poll with Emoji

```julia
Dict(
    "poll" => Dict(
        "question" => Dict("text" => "Pick a fruit"),
        "answers" => [
            Dict("answer_id" => 1, "poll_media" => Dict("text" => "Apple", "emoji" => Dict("name" => "🍎"))),
            Dict("answer_id" => 2, "poll_media" => Dict("text" => "Banana", "emoji" => Dict("name" => "🍌"))),
            Dict("answer_id" => 3, "poll_media" => Dict("text" => "Cherry", "emoji" => Dict("name" => "🍒"))),
        ],
        "duration" => 1,
        "allow_multiselect" => true,
    )
)
```

## 3. Listening for Votes

```julia
on(client, [`MessagePollVoteAdd`](@ref)) do c, event
    @info "Vote added" user=event.user_id message=event.message_id answer=event.answer_id
end

on(client, [`MessagePollVoteRemove`](@ref)) do c, event
    @info "Vote removed" user=event.user_id message=event.message_id answer=event.answer_id
end
```

### Track Votes in Real Time

```julia
# Simple in-memory vote tracker
const vote_counts = Dict{[`Snowflake`](@ref), Dict{Int, Int}}()  # message_id → answer_id → count

on(client, [`MessagePollVoteAdd`](@ref)) do c, event
    msg_votes = get!(vote_counts, event.message_id, Dict{Int, Int}())
    msg_votes[event.answer_id] = get(msg_votes, event.answer_id, 0) + 1
end

on(client, MessagePollVoteRemove) do c, event
    msg_votes = get!(vote_counts, event.message_id, Dict{Int, Int}())
    msg_votes[event.answer_id] = max(0, get(msg_votes, event.answer_id, 0) - 1)
end
```

## 4. Getting Poll Results

```julia
# Get voters for a specific answer
voters = get_answer_voters(client.ratelimiter, channel_id, message_id, 1;
    token=client.token, limit=100)

# voters is a Dict with "users" key
for user_data in voters["users"]
    @info "Voter" id=user_data["id"] username=user_data["username"]
end
```

## 5. Ending a Poll Early

```julia
# End the poll and finalize results
result_msg = end_poll(client.ratelimiter, channel_id, message_id;
    token=client.token)
@info "Poll ended" message_id=result_msg.id
```

## 6. Practical Example: Poll Bot with Slash Commands

```julia
using Accord

token = ENV["DISCORD_TOKEN"]
client = Client(token;
    intents = IntentGuilds | IntentGuildMessages | IntentGuildMessagePolls
)

# /poll "Question?" "Option A" "Option B" ["Option C"] ["Option D"]
options_poll = [
    command_option(type=ApplicationCommandOptionTypes.STRING, name="question", description="Poll question", required=true),
    command_option(type=ApplicationCommandOptionTypes.STRING, name="option1", description="First option", required=true),
    command_option(type=ApplicationCommandOptionTypes.STRING, name="option2", description="Second option", required=true),
    command_option(type=ApplicationCommandOptionTypes.STRING, name="option3", description="Third option"),
    command_option(type=ApplicationCommandOptionTypes.STRING, name="option4", description="Fourth option"),
    command_option(type=ApplicationCommandOptionTypes.INTEGER, name="hours", description="Duration in hours (default: 24)", min_value=1, max_value=336),
    command_option(type=ApplicationCommandOptionTypes.BOOLEAN, name="multiselect", description="Allow multiple votes?"),
]

@slash_command client "poll" "Create a poll" options_poll function(ctx)
    question = get_option(ctx, "question", "")
    opt1 = get_option(ctx, "option1", "")
    opt2 = get_option(ctx, "option2", "")
    opt3 = get_option(ctx, "option3", nothing)
    opt4 = get_option(ctx, "option4", nothing)
    hours = get_option(ctx, "hours", 24)
    multi = get_option(ctx, "multiselect", false)

    answers = [
        Dict("answer_id" => 1, "poll_media" => Dict("text" => opt1)),
        Dict("answer_id" => 2, "poll_media" => Dict("text" => opt2)),
    ]
    !isnothing(opt3) && push!(answers, Dict("answer_id" => 3, "poll_media" => Dict("text" => opt3)))
    !isnothing(opt4) && push!(answers, Dict("answer_id" => 4, "poll_media" => Dict("text" => opt4)))

    # Create the poll in the channel
    channel_id = ctx.interaction.channel_id
    body = Dict{String, Any}(
        "poll" => Dict(
            "question" => Dict("text" => question),
            "answers" => answers,
            "duration" => hours,
            "allow_multiselect" => multi,
            "layout_type" => 1,
        )
    )

    defer(ctx)
    discord_post(ctx.client.ratelimiter, "/channels/$(channel_id)/messages";
        token=ctx.client.token, body=body)
    respond(ctx; content="Poll created!", ephemeral=true)
end

# /endpoll <message_id>
options_end = [
    command_option(type=ApplicationCommandOptionTypes.STRING, name="message_id", description="Message ID of the poll", required=true),
]

@slash_command client "endpoll" "End a poll early" options_end function(ctx)
    msg_id = Snowflake(get_option(ctx, "message_id", ""))
    channel_id = ctx.interaction.channel_id

    end_poll(ctx.client.ratelimiter, channel_id, msg_id; token=ctx.client.token)
    respond(ctx; content="Poll ended!", ephemeral=true)
end

# Vote tracking
on(client, MessagePollVoteAdd) do c, event
    @info "Vote" user=event.user_id answer=event.answer_id message=event.message_id
end

on(client, [`ReadyEvent`](@ref)) do c, event
    sync_commands!(c, c.command_tree)
    @info "Poll bot ready!"
end

start(client)
```

---

**Next steps:** [Recipe 11 — Architectural Patterns](11-architectural-patterns.md) for structuring a production bot.

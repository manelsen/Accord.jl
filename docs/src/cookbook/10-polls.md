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

create_message(client, channel_id; poll=body["poll"])
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
Accord.on(client, [`MessagePollVoteAdd`](@ref)) do c, event
    @info "Vote added" user=event.user_id message=event.message_id answer=event.answer_id
end

Accord.on(client, [`MessagePollVoteRemove`](@ref)) do c, event
    @info "Vote removed" user=event.user_id message=event.message_id answer=event.answer_id
end
```

### Track Votes in Real Time

```julia
# Simple in-memory vote tracker
const vote_counts = Dict{[`Snowflake`](@ref), Dict{Int, Int}}()  # message_id → answer_id → count

Accord.on(client, [`MessagePollVoteAdd`](@ref)) do c, event
    msg_votes = get!(vote_counts, event.message_id, Dict{Int, Int}())
    msg_votes[event.answer_id] = get(msg_votes, event.answer_id, 0) + 1
end

Accord.on(client, MessagePollVoteRemove) do c, event
    msg_votes = get!(vote_counts, event.message_id, Dict{Int, Int}())
    msg_votes[event.answer_id] = max(0, get(msg_votes, event.answer_id, 0) - 1)
end
```

## 4. Getting Poll Results

```julia
# Get voters for a specific answer
voters = Accord.get_answer_voters(client, channel_id, message_id, 1;
    limit=100)

# voters is a Dict with "users" key
for user_data in voters["users"]
    @info "Voter" id=user_data["id"] username=user_data["username"]
end
```

## 5. Ending a Poll Early

```julia
# End the poll and finalize results
result_msg = Accord.end_poll(client, channel_id, message_id)
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
    Accord.command_option(type=ApplicationCommandOptionTypes.STRING, name="question", description="Poll question", required=true),
    Accord.command_option(type=ApplicationCommandOptionTypes.STRING, name="option1", description="First option", required=true),
    Accord.command_option(type=ApplicationCommandOptionTypes.STRING, name="option2", description="Second option", required=true),
    Accord.command_option(type=ApplicationCommandOptionTypes.STRING, name="option3", description="Third option"),
    Accord.command_option(type=ApplicationCommandOptionTypes.STRING, name="option4", description="Fourth option"),
    Accord.command_option(type=ApplicationCommandOptionTypes.INTEGER, name="hours", description="Duration in hours (default: 24)", min_value=1, max_value=336),
    Accord.command_option(type=ApplicationCommandOptionTypes.BOOLEAN, name="multiselect", description="Allow multiple votes?"),
]

@slash_command client "poll" "Create a poll" options_poll function(ctx)
    question = Accord.get_option(ctx, "question", "")
    opt1 = Accord.get_option(ctx, "option1", "")
    opt2 = Accord.get_option(ctx, "option2", "")
    opt3 = Accord.get_option(ctx, "option3", nothing)
    opt4 = Accord.get_option(ctx, "option4", nothing)
    hours = Accord.get_option(ctx, "hours", 24)
    multi = Accord.get_option(ctx, "multiselect", false)

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

    Accord.defer(ctx)
    create_message(ctx.client, channel_id; poll=body["poll"])
    Accord.respond(ctx; content="Poll created!", ephemeral=true)
end

# /endpoll <message_id>
options_end = [
    Accord.command_option(type=ApplicationCommandOptionTypes.STRING, name="message_id", description="Message ID of the poll", required=true),
]

@slash_command client "endpoll" "End a poll early" options_end function(ctx)
    msg_id = Snowflake(Accord.get_option(ctx, "message_id", ""))
    channel_id = ctx.interaction.channel_id

    Accord.end_poll(ctx.client, channel_id, msg_id)
    Accord.respond(ctx; content="Poll ended!", ephemeral=true)
end

# Vote tracking
Accord.on(client, MessagePollVoteAdd) do c, event
    @info "Vote" user=event.user_id answer=event.answer_id message=event.message_id
end

Accord.on(client, [`ReadyEvent`](@ref)) do c, event
    sync_commands!(c, c.command_tree)
    @info "Poll bot ready!"
end

Accord.start(client)
```

---

**Next steps:** [Recipe 11 — Architectural Patterns](11-architectural-patterns.md) for structuring a production bot.

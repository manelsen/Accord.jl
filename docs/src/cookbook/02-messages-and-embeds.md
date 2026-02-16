# Recipe 02 — Rich Messages

**Difficulty:** Beginner
**What you will build:** Embeds with all fields, reactions, file attachments, message editing/deletion, and a reaction-role system.

**Prerequisites:** [Recipe 01](01-basic-bot.md)

---

## 1. Simple Messages

```julia
# Plain text
create_message(client, channel_id; content="Hello, world!")

# With a reply reference
create_message(client, channel_id;
    content="Replying to you!",
    message_reference=Dict(
        "message_id" => string(original_message_id)
    )
)
```

## 2. Building Embeds

The `embed()` helper returns a `Dict` ready for the API:

```julia
e = embed(
    title="My Embed",
    description="A rich embed with all the trimmings.",
    url="https://github.com/your-org/Accord.jl",
    color=0x5865F2,  # Discord blurple
    timestamp=string(Dates.now()) * "Z",
    footer=Dict("text" => "Footer text", "icon_url" => "https://example.com/icon.png"),
    thumbnail=Dict("url" => "https://example.com/thumb.png"),
    image=Dict("url" => "https://example.com/image.png"),
    author=Dict(
        "name" => "Bot Author",
        "url" => "https://example.com",
        "icon_url" => "https://example.com/avatar.png"
    ),
    fields=[
        Dict("name" => "Field 1", "value" => "Value 1", "inline" => true),
        Dict("name" => "Field 2", "value" => "Value 2", "inline" => true),
        Dict("name" => "Wide Field", "value" => "This spans the full width."),
    ]
)

create_message(client, channel_id; embeds=[e])
```

### Color Reference

```julia
const COLORS = Dict(
    :blurple => 0x5865F2,
    :green   => 0x57F287,
    :yellow  => 0xFEE75C,
    :fuchsia => 0xEB459E,
    :red     => 0xED4245,
    :white   => 0xFFFFFF,
    :black   => 0x23272A,
)
```

## 3. Multiple Embeds

!!! note "Embed Limits"
    Discord imposes limits on embeds:
    - **Total characters**: 6000 across all embeds in a message
    - **Fields**: Maximum 25 per embed
    - **Field name**: 256 characters maximum
    - **Field value**: 1024 characters maximum
    - **Description**: 4096 characters maximum
    - **Up to 10 embeds per message**

```julia
embeds = [
    embed(title="Embed 1", description="First", color=0xED4245),
    embed(title="Embed 2", description="Second", color=0x57F287),
    embed(title="Embed 3", description="Third", color=0x5865F2),
]

create_message(client, channel_id; embeds=embeds)
```

## 4. Reactions

```julia
# Unicode emoji
create_reaction(client, channel_id, message_id, "👍")

# Custom emoji — use format name:id
create_reaction(client, channel_id, message_id, "custom_emoji:123456789012345678")
```

### Reaction-Role System

```julia
# Map emoji to role IDs
const REACTION_ROLES = Dict(
    "🎮" => [`Snowflake`](@ref)(111111111111111111),  # Gamer role
    "🎨" => [`Snowflake`](@ref)(222222222222222222),  # Artist role
    "🎵" => [`Snowflake`](@ref)(333333333333333333),  # Music role
)

const ROLE_MESSAGE_ID = [`Snowflake`](@ref)(444444444444444444)  # the message to watch

on(client, [`MessageReactionAdd`](@ref)) do c, event
    event.message_id != ROLE_MESSAGE_ID && return
    ismissing(event.member) && return

    # Get emoji name
    emoji_name = event.emoji.name
    ismissing(emoji_name) && return

    role_id = get(REACTION_ROLES, emoji_name, nothing)
    isnothing(role_id) && return
    ismissing(event.guild_id) && return

    add_guild_member_role(c.ratelimiter, event.guild_id, event.member.user.id, role_id;
        token=c.token)
    @info "Added role" role=role_id user=event.member.user.id
end

on(client, [`MessageReactionRemove`](@ref)) do c, event
    event.message_id != ROLE_MESSAGE_ID && return

    emoji_name = event.emoji.name
    ismissing(emoji_name) && return

    role_id = get(REACTION_ROLES, emoji_name, nothing)
    isnothing(role_id) && return
    ismissing(event.guild_id) && return

    remove_guild_member_role(c.ratelimiter, event.guild_id, event.user_id, role_id;
        token=c.token)
    @info "Removed role" role=role_id user=event.user_id
end
```

## 5. Editing and Deleting Messages

```julia
# Edit a message
edit_message(client, channel_id, message_id;
    content="Updated content!",
    embeds=[embed(title="Updated", color=0x57F287)]
)

# Delete a single message
delete_message(client, channel_id, message_id)

# Bulk delete messages
message_ids = [Snowflake(id1), Snowflake(id2), Snowflake(id3)]
bulk_delete_messages(client.ratelimiter, channel_id;
    token=client.token, message_ids=message_ids)

!!! warning "bulk_delete_messages Constraints"
    - Must delete between **2 and 100 messages** at a time
    - Messages must be **less than 14 days old**
    - Messages older than 14 days must be deleted individually with [`delete_message`](@ref)
```

## 6. File Attachments

Send files using the `files` parameter as a vector of `(filename, data)` tuples:

```julia
# Send a text file
create_message(client, channel_id;
    content="Here's a log file:",
    files=[("log.txt", Vector{UInt8}(codeunits("Line 1\nLine 2\nLine 3")))]
)

# Send an image from disk
img_data = read("chart.png")
create_message(client, channel_id;
    content="Today's chart:",
    files=[("chart.png", img_data)]
)

# Multiple files
create_message(client, channel_id;
    content="Multiple attachments:",
    files=[
        ("data.csv", Vector{UInt8}(codeunits("a,b,c\n1,2,3"))),
        ("readme.txt", Vector{UInt8}(codeunits("See attached data."))),
    ]
)
```

## 7. Embed with Attached Image

Reference an attached image inside an embed using `attachment://filename`:

```julia
img_data = read("banner.png")
e = embed(
    title="Welcome!",
    image=Dict("url" => "attachment://banner.png"),
    color=0x5865F2,
)
create_message(client, channel_id;
    embeds=[e],
    files=[("banner.png", img_data)]
)
```

## 8. Practical Example: Info Command

```julia
using Dates

on(client, MessageCreate) do c, event
    msg = event.message
    ismissing(msg.author) && return
    ismissing(msg.content) && return
    !ismissing(msg.author.bot) && msg.author.bot == true && return

    if msg.content == "!serverinfo"
        ismissing(msg.guild_id) && return

        guild = get_guild(c, msg.guild_id)
        member_count = ismissing(guild.approximate_member_count) ? "N/A" : string(guild.approximate_member_count)

        e = embed(
            title=guild.name,
            description="Server information",
            color=0x5865F2,
            thumbnail=isnothing(guild.icon) ? nothing : Dict(
                "url" => "https://cdn.discordapp.com/icons/$(guild.id)/$(guild.icon).png"
            ),
            fields=[
                Dict("name" => "Owner", "value" => "<@$(guild.owner_id)>", "inline" => true),
                Dict("name" => "ID", "value" => string(guild.id), "inline" => true),
                Dict("name" => "Created", "value" => string(timestamp(guild.id)), "inline" => true),
                Dict("name" => "Verification", "value" => string(guild.verification_level), "inline" => true),
            ],
            footer=Dict("text" => "Requested at $(Dates.format(now(), "HH:MM:SS"))"),
        )
        create_message(c, msg.channel_id; embeds=[e])
    end
end
```

---

**Next steps:** [Recipe 03 — Slash Commands](03-slash-commands.md) to replace prefix commands with Discord's native slash commands.

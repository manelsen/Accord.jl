# Starboard Module
# Automatically highlights popular messages in a dedicated channel.
# Needs the Guild Message Reactions intent, and Message Content to copy the text.

using Accord

function setup_starboard(client::Client)
    # Configuration
    star_emoji = "⭐"
    threshold = 3  # Number of stars required to post
    starboard_channel_name = "starboard"

    # Messages already posted, so a fourth star doesn't post them again
    posted = Set{Snowflake}()
    posted_lock = ReentrantLock()

    Accord.on(client, Accord.MessageReactionAdd) do c, event
        isequal(event.emoji.name, star_emoji) || return
        ismissing(event.guild_id) && return
        lock(() -> event.message_id in posted, posted_lock) && return

        # Fetch the message to read the full reaction count
        msg = Accord.get_channel_message(c, event.channel_id, event.message_id)
        reactions = ismissing(msg.reactions) ? Accord.Reaction[] : msg.reactions
        stars = findfirst(r -> isequal(r.emoji.name, star_emoji), reactions)
        (isnothing(stars) || reactions[stars].count < threshold) && return

        # Look for a channel named 'starboard'
        channels = Accord.get_guild_channels(c, event.guild_id)
        idx = findfirst(ch -> isequal(ch.name, starboard_channel_name), channels)
        isnothing(idx) && return

        # Two stars can arrive at once; only the first to get here posts
        first_post = lock(posted_lock) do
            event.message_id in posted && return false
            push!(posted, event.message_id)
            return true
        end
        first_post || return

        jump_url = "https://discord.com/channels/$(event.guild_id)/$(msg.channel_id)/$(msg.id)"
        e = Accord.embed(
            title="⭐ Starboard Highlight",
            description=coalesce(msg.content, "") == "" ? "*No content*" : msg.content,
            color=0xFEE75C,  # Yellow
            footer=Accord.embed_footer("ID: $(msg.id)"),
            author=Accord.embed_author(ismissing(msg.author) ? "Unknown" : msg.author.username),
            fields=[Accord.embed_field("Source", "[Jump to message]($jump_url)")],
        )
        create_message(c, channels[idx].id; embeds=[e])
    end

    println("⭐ Starboard module loaded (Threshold: $threshold stars).")
end

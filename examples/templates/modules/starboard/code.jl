# Starboard Module
# Automatically highlights popular messages in a dedicated channel.

using Accord

function setup_starboard(client::Client)
    # Configuration
    const STAR_EMOJI = "⭐"
    const THRESHOLD = 3 # Number of stars required to post
    const STARBOARD_CHANNEL_NAME = "starboard"

    on(client, MessageReactionAdd) do c, event
        # Only care about stars
        if !ismissing(event.emoji.name) && event.emoji.name == STAR_EMOJI
            # Fetch the message to check full reaction count
            msg = fetch_message(c, event.channel_id, event.message_id)
            
            # Find the star reaction count
            star_reaction = findfirst(r -> !ismissing(r.emoji.name) && r.emoji.name == STAR_EMOJI, msg.reactions)
            
            if !isnothing(star_reaction) && star_reaction.count >= THRESHOLD
                # Look for a channel named 'starboard'
                guild_channels = fetch_guild_channels(c, event.guild_id)
                starboard_ch = findfirst(ch -> !ismissing(ch.name) && ch.name == STARBOARD_CHANNEL_NAME, guild_channels)
                
                if !isnothing(starboard_ch)
                    # Prepare the embed
                    author_name = ismissing(msg.author) ? "Unknown" : msg.author.username
                    e = embed(
                        title="⭐ Starboard Highlight",
                        description=ismissing(msg.content) ? "*No content*" : msg.content,
                        color=0xFEE75C, # Yellow
                        footer=embed_footer("ID: \$(msg.id)"),
                        author=embed_author(name=author_name)
                    )
                    
                    # Add jump link
                    jump_url = "https://discord.com/channels/\$(event.guild_id)/\$(msg.channel_id)/\$(msg.id)"
                    push!(e.fields, embed_field(name="Source", value="[Jump to message](\$jump_url)"))
                    
                    # Post to starboard
                    create_message(c.ratelimiter, starboard_ch.id; token=c.token, embeds=[e])
                end
            end
        end
    end

    println("⭐ Starboard module loaded (Threshold: \$THRESHOLD stars).")
end

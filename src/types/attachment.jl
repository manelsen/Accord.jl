"""
    Attachment

A file attached to a message. Received when a user uploads files or when the bot receives messages with attachments.

[Discord docs](https://discord.com/developers/docs/resources/message#attachment-object)

# Fields
- `id::Snowflake` — attachment ID.
- `filename::String` — name of the file attached.
- `title::Optional{String}` — title of the file (for audio files).
- `description::Optional{String}` — description for the file (max 1024 characters).
- `content_type::Optional{String}` — MIME type of the content.
- `size::Int` — size of the file in bytes.
- `url::String` — source URL of the file.
- `proxy_url::String` — proxied URL of the file.
- `height::Optional{Int}` — height of the file (if image).
- `width::Optional{Int}` — width of the file (if image).
- `ephemeral::Optional{Bool}` — whether this attachment is ephemeral. Ephemeral attachments will automatically be removed after a set period of time.
- `duration_secs::Optional{Float64}` — duration of the audio file (currently for voice messages).
- `waveform::Optional{String}` — base64 encoded bytearray representing a sampled waveform (currently for voice messages).
- `flags::Optional{Int}` — attachment flags combined as a bitfield.
"""
@discord_struct Attachment begin
    id::Snowflake
    filename::String
    title::Optional{String}
    description::Optional{String}
    content_type::Optional{String}
    size::Int
    url::String
    proxy_url::String
    height::Optional{Int}
    width::Optional{Int}
    ephemeral::Optional{Bool}
    duration_secs::Optional{Float64}
    waveform::Optional{String}
    flags::Optional{Int}
end

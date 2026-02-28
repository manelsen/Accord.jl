"""
    Attachment

Represents a file attached to a Discord message. This can be an image, video,
audio file, or any other type of file.

# Fields
- `id::Snowflake`: The unique ID of the attachment.
- `filename::String`: The name of the file (e.g., "cat.png").
- `title::Optional{String}`: The title of the file (usually for audio files).
- `description::Optional{String}`: A description for the file (alt text, max 1024 characters).
- `content_type::Optional{String}`: The MIME type of the file (e.g., "image/png").
- `size::Int`: The size of the file in bytes.
- `url::String`: The source URL of the file.
- `proxy_url::String`: A proxied URL of the file.
- `height::Optional{Int}`: The height of the file (if it is an image).
- `width::Optional{Int}`: The width of the file (if it is an image).
- `ephemeral::Optional{Bool}`: Whether this attachment is ephemeral (removed after a period).
- `duration_secs::Optional{Float64}`: The duration of the audio file (for voice messages).
- `waveform::Optional{String}`: Base64 encoded waveform data (for voice messages).
- `flags::Optional{Int}`: Attachment flags (see [`AttachmentFlags`](@ref)).

# See Also
- [Discord API: Attachment Object](https://discord.com/developers/docs/resources/message#attachment-object)
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

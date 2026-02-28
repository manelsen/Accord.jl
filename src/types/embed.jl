"""
    EmbedFooter

The footer section of an [`Embed`](@ref).

# Fields
- `text::String`: The footer text (max 2048 characters).
- `icon_url::Optional{String}`: URL of the footer icon (http/https/attachments only).
- `proxy_icon_url::Optional{String}`: A proxied URL of the footer icon.

# See Also
- [Discord API: Embed Footer](https://discord.com/developers/docs/resources/message#embed-object-embed-footer-structure)
"""
@discord_struct EmbedFooter begin
    text::String
    icon_url::Optional{String}
    proxy_icon_url::Optional{String}
end

"""
    EmbedImage

Image information within an [`Embed`](@ref).

# Fields
- `url::String`: Source URL of the image.
- `proxy_url::Optional{String}`: A proxied URL of the image.
- `height::Optional{Int}`: Height of the image.
- `width::Optional{Int}`: Width of the image.

# See Also
- [Discord API: Embed Image](https://discord.com/developers/docs/resources/message#embed-object-embed-image-structure)
"""
@discord_struct EmbedImage begin
    url::String
    proxy_url::Optional{String}
    height::Optional{Int}
    width::Optional{Int}
end

"""
    EmbedThumbnail

Thumbnail information for an [`Embed`](@ref), displayed at the top right.

# Fields
- `url::String`: Source URL of the thumbnail.
- `proxy_url::Optional{String}`: A proxied URL of the thumbnail.
- `height::Optional{Int}`: Height of the thumbnail.
- `width::Optional{Int}`: Width of the thumbnail.

# See Also
- [Discord API: Embed Thumbnail](https://discord.com/developers/docs/resources/message#embed-object-embed-thumbnail-structure)
"""
@discord_struct EmbedThumbnail begin
    url::String
    proxy_url::Optional{String}
    height::Optional{Int}
    width::Optional{Int}
end

"""
    EmbedVideo

Video information within an [`Embed`](@ref).

# See Also
- [Discord API: Embed Video](https://discord.com/developers/docs/resources/message#embed-object-embed-video-structure)
"""
@discord_struct EmbedVideo begin
    url::Optional{String}
    proxy_url::Optional{String}
    height::Optional{Int}
    width::Optional{Int}
end

"""
    EmbedProvider

Provider information for an [`Embed`](@ref) (e.g., YouTube, Twitter).

# See Also
- [Discord API: Embed Provider](https://discord.com/developers/docs/resources/message#embed-object-embed-provider-structure)
"""
@discord_struct EmbedProvider begin
    name::Optional{String}
    url::Optional{String}
end

"""
    EmbedAuthor

Author information for an [`Embed`](@ref), displayed at the top.

# Fields
- `name::String`: Name of the author (max 256 characters).
- `url::Optional{String}`: URL of the author (links the name).
- `icon_url::Optional{String}`: URL of the author's icon.
- `proxy_icon_url::Optional{String}`: A proxied URL of the author's icon.

# See Also
- [Discord API: Embed Author](https://discord.com/developers/docs/resources/message#embed-object-embed-author-structure)
"""
@discord_struct EmbedAuthor begin
    name::String
    url::Optional{String}
    icon_url::Optional{String}
    proxy_icon_url::Optional{String}
end

"""
    EmbedField

A key-value field within an [`Embed`](@ref). Up to 25 fields can be added.

# Fields
- `name::String`: Name of the field (max 256 characters).
- `value::String`: Value of the field (max 1024 characters).
- `inline::Optional{Bool}`: Whether the field should display inline with others.

# See Also
- [Discord API: Embed Field](https://discord.com/developers/docs/resources/message#embed-object-embed-field-structure)
"""
@discord_struct EmbedField begin
    name::String
    value::String
    inline::Optional{Bool}
end

"""
    Embed

Represents a rich embed object that can be sent with messages. 

Embeds allow bots to present structured content with colors, images, and 
multiple fields.

# Fields
- `title::Optional{String}`: Title of the embed (max 256 characters).
- `type::Optional{String}`: Type of embed (default "rich").
- `description::Optional{String}`: Main content of the embed (max 4096 characters).
- `url::Optional{String}`: URL of the embed (links the title).
- `timestamp::Optional{String}`: ISO8601 timestamp displayed in the embed.
- `color::Optional{Int}`: Color code of the embed (integer).
- `footer::Optional{EmbedFooter}`: Footer information.
- `image::Optional{EmbedImage}`: Main image information.
- `thumbnail::Optional{EmbedThumbnail}`: Thumbnail information.
- `video::Optional{EmbedVideo}`: Video information (read-only).
- `provider::Optional{EmbedProvider}`: Provider information (read-only).
- `author::Optional{EmbedAuthor}`: Author information.
- `fields::Optional{Vector{EmbedField}}`: Up to 25 fields.

# Example
```julia
embed = Embed(
    title = "System Status",
    description = "All systems operational.",
    color = 0x00ff00
)
push!(embed.fields, EmbedField(name="CPU", value="15%", inline=true))
```

# See Also
- [Discord API: Embed Object](https://discord.com/developers/docs/resources/message#embed-object)
"""
@discord_struct Embed begin
    title::Optional{String}
    type::Optional{String}
    description::Optional{String}
    url::Optional{String}
    timestamp::Optional{String}
    color::Optional{Int}
    footer::Optional{EmbedFooter}
    image::Optional{EmbedImage}
    thumbnail::Optional{EmbedThumbnail}
    video::Optional{EmbedVideo}
    provider::Optional{EmbedProvider}
    author::Optional{EmbedAuthor}
    fields::Optional{Vector{EmbedField}}
end

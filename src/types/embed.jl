"""
    EmbedFooter

Footer information for an embed, displayed at the bottom.

[Discord docs](https://discord.com/developers/docs/resources/message#embed-object-embed-footer-structure)

# Fields
- `text::String` — footer text. Max 2048 characters.
- `icon_url::Optional{String}` — URL of footer icon. Only supports http(s) and attachments.
- `proxy_icon_url::Optional{String}` — proxied URL of footer icon.
"""
@discord_struct EmbedFooter begin
    text::String
    icon_url::Optional{String}
    proxy_icon_url::Optional{String}
end

"""
    EmbedImage

Image information for an embed.

[Discord docs](https://discord.com/developers/docs/resources/message#embed-object-embed-image-structure)

# Fields
- `url::String` — source URL of the image. Only supports http(s) and attachments.
- `proxy_url::Optional{String}` — proxied URL of the image.
- `height::Optional{Int}` — height of the image.
- `width::Optional{Int}` — width of the image.
"""
@discord_struct EmbedImage begin
    url::String
    proxy_url::Optional{String}
    height::Optional{Int}
    width::Optional{Int}
end

"""
    EmbedThumbnail

Thumbnail information for an embed, displayed at the top right.

[Discord docs](https://discord.com/developers/docs/resources/message#embed-object-embed-thumbnail-structure)

# Fields
- `url::String` — source URL of the thumbnail. Only supports http(s) and attachments.
- `proxy_url::Optional{String}` — proxied URL of the thumbnail.
- `height::Optional{Int}` — height of the thumbnail.
- `width::Optional{Int}` — width of the thumbnail.
"""
@discord_struct EmbedThumbnail begin
    url::String
    proxy_url::Optional{String}
    height::Optional{Int}
    width::Optional{Int}
end

"""
    EmbedVideo

Video information for an embed.

[Discord docs](https://discord.com/developers/docs/resources/message#embed-object-embed-video-structure)

# Fields
- `url::Optional{String}` — source URL of the video.
- `proxy_url::Optional{String}` — proxied URL of the video.
- `height::Optional{Int}` — height of the video.
- `width::Optional{Int}` — width of the video.
"""
@discord_struct EmbedVideo begin
    url::Optional{String}
    proxy_url::Optional{String}
    height::Optional{Int}
    width::Optional{Int}
end

"""
    EmbedProvider

Provider information for an embed (e.g., YouTube, Twitter).

[Discord docs](https://discord.com/developers/docs/resources/message#embed-object-embed-provider-structure)

# Fields
- `name::Optional{String}` — name of the provider.
- `url::Optional{String}` — URL of the provider.
"""
@discord_struct EmbedProvider begin
    name::Optional{String}
    url::Optional{String}
end

"""
    EmbedAuthor

Author information for an embed, displayed at the top.

[Discord docs](https://discord.com/developers/docs/resources/message#embed-object-embed-author-structure)

# Fields
- `name::String` — name of the author. Max 256 characters.
- `url::Optional{String}` — URL of the author.
- `icon_url::Optional{String}` — URL of author icon. Only supports http(s) and attachments.
- `proxy_icon_url::Optional{String}` — proxied URL of author icon.
"""
@discord_struct EmbedAuthor begin
    name::String
    url::Optional{String}
    icon_url::Optional{String}
    proxy_icon_url::Optional{String}
end

"""
    EmbedField

A field in an embed. Up to 25 fields can be added to an embed.

[Discord docs](https://discord.com/developers/docs/resources/message#embed-object-embed-field-structure)

# Fields
- `name::String` — name of the field. Max 256 characters.
- `value::String` — value of the field. Max 1024 characters.
- `inline::Optional{Bool}` — whether this field should display inline.
"""
@discord_struct EmbedField begin
    name::String
    value::String
    inline::Optional{Bool}
end

"""
    Embed

A rich embed object that can be sent with messages. Embeds provide a structured way to present content with titles, descriptions, images, fields, and more.

[Discord docs](https://discord.com/developers/docs/resources/message#embed-object)

# Fields
- `title::Optional{String}` — title of the embed. Max 256 characters.
- `type::Optional{String}` — type of embed (always "rich" for webhook embeds).
- `description::Optional{String}` — description of the embed. Max 4096 characters.
- `url::Optional{String}` — URL of the embed.
- `timestamp::Optional{String}` — ISO8601 timestamp of the embed content.
- `color::Optional{Int}` — color code of the embed as an integer.
- `footer::Optional{EmbedFooter}` — footer information.
- `image::Optional{EmbedImage}` — image information.
- `thumbnail::Optional{EmbedThumbnail}` — thumbnail information.
- `video::Optional{EmbedVideo}` — video information.
- `provider::Optional{EmbedProvider}` — provider information.
- `author::Optional{EmbedAuthor}` — author information.
- `fields::Optional{Vector{EmbedField}}` — fields information. Max 25 fields.
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

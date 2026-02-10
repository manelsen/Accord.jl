@discord_struct EmbedFooter begin
    text::String
    icon_url::Optional{String}
    proxy_icon_url::Optional{String}
end

@discord_struct EmbedImage begin
    url::String
    proxy_url::Optional{String}
    height::Optional{Int}
    width::Optional{Int}
end

@discord_struct EmbedThumbnail begin
    url::String
    proxy_url::Optional{String}
    height::Optional{Int}
    width::Optional{Int}
end

@discord_struct EmbedVideo begin
    url::Optional{String}
    proxy_url::Optional{String}
    height::Optional{Int}
    width::Optional{Int}
end

@discord_struct EmbedProvider begin
    name::Optional{String}
    url::Optional{String}
end

@discord_struct EmbedAuthor begin
    name::String
    url::Optional{String}
    icon_url::Optional{String}
    proxy_icon_url::Optional{String}
end

@discord_struct EmbedField begin
    name::String
    value::String
    inline::Optional{Bool}
end

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

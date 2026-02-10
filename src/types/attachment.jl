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

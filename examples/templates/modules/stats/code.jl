# Stats Module
# Leverages Julia's mathematical power for quick statistics.

using Accord
using Statistics

function setup_stats(client::Client)

    @slash_command client "stats" "Summary statistics of a list of numbers" [
        @option String "numbers" "Numbers separated by commas or spaces" required=true
    ] function(ctx)
        raw = split(Accord.get_option(ctx, "numbers"), r"[,\s]+"; keepempty=false)
        xs = tryparse.(Float64, raw)
        if isempty(xs) || any(isnothing, xs)
            return Accord.respond(ctx; content="❌ Give a list of numbers, like `3, 1.5, 4`.", ephemeral=true)
        end
        xs = Float64.(xs)

        fmt(x) = string(round(x; sigdigits=6))
        fields = [
            Accord.embed_field("Count", string(length(xs)); inline=true),
            Accord.embed_field("Mean", fmt(mean(xs)); inline=true),
            Accord.embed_field("Median", fmt(median(xs)); inline=true),
            Accord.embed_field("Std. dev.", length(xs) > 1 ? fmt(std(xs)) : "–"; inline=true),
            Accord.embed_field("Min", fmt(minimum(xs)); inline=true),
            Accord.embed_field("Max", fmt(maximum(xs)); inline=true),
        ]
        Accord.respond(ctx; embeds=[Accord.embed(title="📈 Statistics", color=0x5865F2, fields)])
    end

    println("📈 Stats module loaded.")
end

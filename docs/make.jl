using Documenter, Accord


# Doctests see what a user sees after `using Accord`, plus the public names
# they would import explicitly (`using Accord: has_flag, timestamp, …`).
const _PUBLIC_UNEXPORTED = filter(n -> Base.ispublic(Accord, n) && !Base.isexported(Accord, n),
                                  names(Accord; all=true))
DocMeta.setdocmeta!(Accord, :DocTestSetup,
    Expr(:block, :(using Accord),
         Expr(:using, Expr(:(:), Expr(:., :Accord), [Expr(:., n) for n in _PUBLIC_UNEXPORTED]...)));
    recursive=true)

makedocs(;
    modules = [Accord],
    sitename = "Accord.jl",
    authors = "Accord.jl Contributors",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://manelsen.github.io/Accord.jl",
        size_threshold = 1024 * 1024, # 1MB
    ),
    # Cookbook pages link to many symbols that have no docstring yet; report
    # those as warnings instead of failing the whole build.
    warnonly = [:cross_references],
    pages = [
        "Home" => "index.md",
        "Cookbook" => [
            "cookbook/index.md",
            "Your First Bot" => "cookbook/01-basic-bot.md",
            "Rich Messages" => "cookbook/02-messages-and-embeds.md",
            "Slash Commands" => "cookbook/03-slash-commands.md",
            "Buttons, Selects & Modals" => "cookbook/04-buttons-selects-modals.md",
            "Voice" => "cookbook/05-voice.md",
            "Permissions" => "cookbook/06-permissions.md",
            "Caching" => "cookbook/07-caching.md",
            "Sharding" => "cookbook/08-sharding.md",
            "Auto-Moderation" => "cookbook/09-automod.md",
            "Polls" => "cookbook/10-polls.md",
            "Architectural Patterns" => "cookbook/11-architectural-patterns.md",
            "Performance" => "cookbook/12-performance.md",
            "Deployment" => "cookbook/13-deploy.md",
            "Troubleshooting" => "cookbook/14-troubleshooting.md",
            "Why Julia?" => "cookbook/15-why-julia.md",
            "AI Agent Bot" => "cookbook/16-ai-agent.md",
        ],
        "API Reference" => "api.md",
        "Diagnostics" => "diagnostics.md",
        "Release Notes" => "release-notes.md",
    ],
)

deploydocs(;
    repo = "github.com/manelsen/Accord.jl.git",
    devbranch = "master",
    push_preview = true,
)

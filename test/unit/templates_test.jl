@testitem "Project templates load" tags=[:unit] begin
    using Accord

    templates = joinpath(pkgdir(Accord), "examples", "templates")
    modules_dir = joinpath(templates, "modules")
    module_names = sort(readdir(modules_dir))

    # Packages a template needs that the test environment doesn't have
    unavailable(code) = [String(m.captures[1]) for m in eachmatch(r"^using (\w+)"m, code)
                         if m.captures[1] != "DotEnv" && isnothing(Base.find_package(String(m.captures[1])))]

    # Every `Accord.name` a template uses must exist
    function accord_refs(ex, out=Symbol[])
        if ex isa Expr
            if ex.head == :. && length(ex.args) == 2 && ex.args[1] == :Accord && ex.args[2] isa QuoteNode
                push!(out, ex.args[2].value)
            end
            foreach(a -> accord_refs(a, out), ex.args)
        end
        return out
    end

    function has_parse_error(ex)
        ex isa Expr || return false
        ex.head in (:error, :incomplete) && return true
        return any(has_parse_error, ex.args)
    end

    # The bot module scaffolded by AccordCLI, with every module the test env can load
    runnable = filter(module_names) do name
        isempty(unavailable(read(joinpath(modules_dir, name, "code.jl"), String)))
    end

    # Fill in the placeholders AccordCLI substitutes when scaffolding
    fill_placeholders(code) = replace(code, "{{BOT_NAME}}" => "TemplateBot",
                                      "{{MODULE_INCLUDES}}" => "", "{{MODULE_SETUPS}}" => "")

    files = [joinpath(root, f) for (root, _, fs) in walkdir(templates) for f in fs if endswith(f, ".jl")]
    @testset "parses and names exist: $(relpath(f, templates))" for f in files
        code = fill_placeholders(read(f, String))
        ex = Meta.parseall(code; filename=f)
        @test !has_parse_error(ex)
        missing_names = filter(n -> !isdefined(Accord, n), unique(accord_refs(ex)))
        @test isempty(missing_names)
    end

    @testset "modules register their commands" begin
        for name in runnable
            sandbox = Module(Symbol("Template_", name))
            Core.eval(sandbox, :(using Accord))
            Base.include_string(sandbox, read(joinpath(modules_dir, name, "code.jl"), String),
                                joinpath(modules_dir, name, "code.jl"))
            client = Client("Bot test_token_fake")
            redirect_stdout(devnull) do
                Base.invokelatest(Base.invokelatest(getfield, sandbox, Symbol("setup_", name)), client)
            end
            tree = client.command_tree
            n_commands = length(tree.commands) + length(tree.component_handlers) + length(tree.modal_handlers)
            n_events = sum(length, values(client.event_handler.handlers); init=0)
            @test n_commands + n_events > 0
        end
    end

    @testset "core template wires the modules in" begin
        core = read(joinpath(templates, "core", "src", "{{BOT_NAME}}.jl"), String)
        includes = join((read(joinpath(modules_dir, n, "code.jl"), String) for n in runnable), "\n")
        setups = join(("    setup_$n(client)" for n in runnable), "\n")
        code = replace(core, "{{BOT_NAME}}" => "TemplateBot", "{{MODULE_INCLUDES}}" => includes,
                       "{{MODULE_SETUPS}}" => setups,
                       # Stop before connecting to Discord
                       "Accord.start(client)" => "return client")
        sandbox = Module(:CoreTemplate)
        Base.include_string(sandbox, code, "core/src/TemplateBot.jl")
        bot = Base.invokelatest(getfield, sandbox, :TemplateBot)
        client = redirect_stdout(devnull) do
            Base.invokelatest(bot.run, "Bot test_token_fake")
        end
        @test client isa Client
        @test haskey(client.command_tree.commands, "server_info")
        @test haskey(client.command_tree.commands, "stats")
    end

    @testset "standalone bot: $name" for name in ("basic", "ai_chat", "music")
        code = read(joinpath(templates, name, "bot.jl"), String)
        if !isempty(unavailable(code))
            @test_skip "needs $(unavailable(code))"
            continue
        end
        sandbox = Module(Symbol("Standalone_", name))
        # DotEnv isn't installed here: stand in for it, and stop before connecting
        Core.eval(sandbox, :(module DotEnv; config() = nothing; end))
        code = replace(code, r"^using DotEnv\r?$"m => "",r"\r?\nAccord\.start\(client\)\s*$" => "\n")
        withenv("DISCORD_TOKEN" => "Bot test_token_fake") do
            Base.include_string(sandbox, code, joinpath(templates, name, "bot.jl"))
        end
        client = Base.invokelatest(getfield, sandbox, :client)
        @test !isempty(client.command_tree.commands)
    end
end

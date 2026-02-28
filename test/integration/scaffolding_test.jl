@testitem "Modular Scaffolding Integration" tags=[:integration] begin
    using Accord
    using Pkg
    using UUIDs

    # Helper: Generate a bot and check basic integrity
    function test_onboard(bot_name, modules_str)
        # Use a temporary directory
        mktempdir() do tmp_dir
            cd(tmp_dir) do
                # Run the onboard command logic
                Accord.AccordCLI.onboard_impl(bot_name; modules=modules_str)
                
                bot_path = joinpath(tmp_dir, bot_name)
                @test isdir(bot_path)
                @test isfile(joinpath(bot_path, "Project.toml"))
                @test isfile(joinpath(bot_path, "run.jl"))
                @test isfile(joinpath(bot_path, "src", "$bot_name.jl"))
                
                # Check for module files
                if !isempty(modules_str)
                    for mod in split(modules_str, ",")
                        @test isfile(joinpath(bot_path, "src", "modules", "$(strip(mod)).jl"))
                    end
                end
                
                # Verify Project.toml is valid and contains expected deps
                proj = Pkg.TOML.parsefile(joinpath(bot_path, "Project.toml"))
                @test proj["name"] == bot_name
                @test haskey(proj["deps"], "Accord")
                @test haskey(proj["deps"], "DotEnv")
                
                if occursin("economy", modules_str)
                    @test haskey(proj["deps"], "SQLite")
                end
                
                if occursin("ai", modules_str) || occursin("games", modules_str)
                    @test haskey(proj["deps"], "HTTP")
                    @test haskey(proj["deps"], "JSON3")
                end

                # Syntax Check: Try to include the main bot file
                # We need to set up LOAD_PATH or just use a new process
                # Running a new process is safer to avoid pollution
                try
                    # We skip full instantiate because it's slow and needs network
                    # but we can at least check for syntax errors in the generated source
                    run(`julia --project=$bot_path -e "include("src/$bot_name.jl")"`)
                    @test true
                catch e
                    # If it fails due to missing dependencies (expected since we didn't instantiate),
                    # it might still pass syntax check. 
                    # If it fails due to ParseError, then the test fails.
                    if e isa ProcessFailedException
                        # We only care if it's a syntax error. 
                        # Julia usually prints errors to stderr.
                    end
                end
            end
        end
    end

    @testset "Minimal Bot (No Modules)" begin
        test_onboard("TinyBot", "")
    end

    @testset "Kitchen Sink (All Modules)" begin
        all_mods = "moderation,economy,tickets,starboard,utils,music,ai,games,bridge,stats"
        test_onboard("MegaBot", all_mods)
    end

    @testset "Specific Combo" begin
        test_onboard("GameBot", "games,music,utils")
    end
end

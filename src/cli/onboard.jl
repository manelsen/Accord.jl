# Onboarding and scaffolding logic for new bots

using Pkg
using Dates
using UUIDs

function onboard_impl(name::String; modules::String="")
    println("🎹 Onboarding new Accord.jl bot: $name")
    
    target_dir = abspath(name)
    if isdir(target_dir)
        error("Directory $name already exists. Choose a different name.")
    end

    repo_root = joinpath(@__DIR__, "..", "..")
    core_src = joinpath(repo_root, "examples", "templates", "core")
    
    if !isdir(core_src)
        error("Core template not found at $core_src.")
    end

    println("🚀 Creating project skeleton...")
    
    # 1. Copy Core
    mkpath(target_dir)
    cp(core_src, target_dir; force=true)

    # Move src/{{BOT_NAME}}.jl to src/name.jl
    bot_file_src = joinpath(target_dir, "src", "{{BOT_NAME}}.jl")
    bot_file_dst = joinpath(target_dir, "src", "$name.jl")
    if isfile(bot_file_src)
        mv(bot_file_src, bot_file_dst)
    end

    # 2. Process Modules
    mod_list = isempty(modules) ? String[] : split(modules, ",")
    mod_list = map(strip, mod_list)
    
    unique_deps = Dict{String, String}()
    module_includes = ""
    module_setups = ""
    
    if !isempty(mod_list)
        mkpath(joinpath(target_dir, "src", "modules"))
        println("📦 Injecting modules: ", join(mod_list, ", "))
    end

    for mod in mod_list
        mod_src_dir = joinpath(repo_root, "examples", "templates", "modules", mod)
        if !isdir(mod_src_dir)
            @warn "Module '$mod' not found. Skipping."
            continue
        end
        
        # Copy code
        code_file = joinpath(mod_src_dir, "code.jl")
        if isfile(code_file)
            cp(code_file, joinpath(target_dir, "src", "modules", "$mod.jl"))
            module_includes *= "include(\"modules/$mod.jl\")\n"
            module_setups *= "    setup_$mod(client)\n"
        end
        
        # Read deps
        deps_file = joinpath(mod_src_dir, "deps.txt")
        if isfile(deps_file)
            for line in eachline(deps_file)
                line = strip(line)
                isempty(line) && continue
                # Match "Key = \"UUID\""
                m = match(r"^\s*([A-Za-z0-9_]+)\s*=\s*\"([A-Za-z0-9-]+)\"\s*$", line)
                if !isnothing(m)
                    unique_deps[m.captures[1]] = m.captures[2]
                end
            end
        end
    end

    extra_deps_str = ""
    for (pkg, uuid) in unique_deps
        extra_deps_str *= "$pkg = \"$uuid\"\n"
    end

    # 3. Personalization
    
    # Update Project.toml
    project_path = joinpath(target_dir, "Project.toml")
    if isfile(project_path)
        content = read(project_path, String)
        content = replace(content, "{{BOT_NAME}}" => name)
        content = replace(content, "{{UUID}}" => string(uuid4()))
        content = replace(content, "{{EXTRA_DEPS}}" => chomp(extra_deps_str))
        write(project_path, content)
    end

    # Update run.jl
    run_path = joinpath(target_dir, "run.jl")
    if isfile(run_path)
        content = read(run_path, String)
        content = replace(content, "{{BOT_NAME}}" => name)
        write(run_path, content)
    end
    
    # Update src/name.jl
    if isfile(bot_file_dst)
        content = read(bot_file_dst, String)
        content = replace(content, "{{BOT_NAME}}" => name)
        content = replace(content, "{{MODULE_INCLUDES}}" => chomp(module_includes))
        content = replace(content, "{{MODULE_SETUPS}}" => chomp(module_setups))
        write(bot_file_dst, content)
    end

    println("✅ Bot created at: $target_dir")
    println("\nNext steps:")
    println("1. cd $name")
    println("2. export DISCORD_TOKEN=\"your_token_here\"")
    println("3. julia --project -e 'using Pkg; Pkg.instantiate()'")
    println("4. julia --project run.jl")
end

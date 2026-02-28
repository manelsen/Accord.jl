# Onboarding and scaffolding logic for new bots

using Pkg
using Dates

function onboard_impl(name::String; template::String="basic")
    println("🎹 Onboarding new Accord.jl bot: $name")
    
    target_dir = abspath(name)
    if isdir(target_dir)
        error("Directory $name already exists. Choose a different name.")
    end

    # Source templates from the examples directory
    # Assuming the CLI is run from the project root or Accord is installed
    repo_root = joinpath(@__DIR__, "..", "..")
    template_src = joinpath(repo_root, "examples", "templates", template)
    
    if !isdir(template_src)
        error("Template '$template' not found in $template_src. Available: basic, music, ai_chat.")
    end

    println("🚀 Creating project from template: $template...")
    
    # Simple recursive copy
    mkpath(target_dir)
    cp(template_src, target_dir; force=true)

    # Personalization: Update the Project.toml name
    project_path = joinpath(target_dir, "Project.toml")
    if isfile(project_path)
        content = read(project_path, String)
        # Use regex to find and replace the project name
        content = replace(content, r"name\s*=\s*\"[^\"]*\"" => "name = \"$name\"")
        write(project_path, content)
    end

    println("✅ Bot created at: $target_dir")
    println("\nNext steps:")
    println("1. cd $name")
    println("2. export DISCORD_TOKEN=\"your_token_here\"")
    println("3. julia --project -e 'using Pkg; Pkg.instantiate()'")
    println("4. julia --project run.jl")
end

module AccordCLI

using Comonicon
using ..Accord

include("onboard.jl")
include("doctor.jl")

"""
Onboard a new Accord.jl bot project.

# Arguments
- `name`: The name of your new bot project.

# Options
- `-m, --modules <list>`: Comma-separated list of modules to include (e.g., moderation, economy, tickets).
"""
@cast function onboard(name::String; modules::String="")
    onboard_impl(name; modules)
end

"""
Check your environment for Accord.jl compatibility and common issues.
"""
@cast function doctor()
    doctor_impl()
end

"""
Accord.jl — The high-performance Discord API framework.
"""
Comonicon.@main

end # module

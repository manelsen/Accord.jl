using Accord
using Accord: JSON3, Message, Snowflake, User, Optional
using StructTypes

const PAYLOAD = Dict{Symbol, Any}(
    :id => "111111111111111111",
    :channel_id => "222222222222222222",
    :author => Dict(
        :id => "444444444444444444",
        :username => "TestUser"
    ),
    :content => "Hello",
    :type => 0
)

println("Testing StructTypes.constructfrom(Message, PAYLOAD)...")

try
    msg = StructTypes.constructfrom(Message, PAYLOAD)
    println("Success!")
    println("  ID: ", msg.id)
    println("  Author: ", msg.author.username)
    println("  Content: ", msg.content)
catch e
    @error "Failed constructfrom" exception=(e, catch_backtrace())
end

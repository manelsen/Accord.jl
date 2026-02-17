using Accord
using Accord: JSON3, parse_event, MessageCreate, Message
using InteractiveUtils
using Dates

# ─── Mocks ───────────────────────────────────────────────────────────────────

const MESSAGE_CREATE_PAYLOAD = Dict{String, Any}(
    "id" => "111111111111111111",
    "channel_id" => "222222222222222222",
    "guild_id" => "333333333333333333",
    "author" => Dict(
        "id" => "444444444444444444",
        "username" => "TestUser",
        "discriminator" => "0000",
        "avatar" => "abcdef1234567890",
        "bot" => false
    ),
    "content" => "Hello, world! This is a benchmark message.",
    "timestamp" => "2023-10-27T10:00:00.000000+00:00",
    "edited_timestamp" => nothing,
    "tts" => false,
    "mention_everyone" => false,
    "mentions" => [],
    "mention_roles" => [],
    "attachments" => [],
    "embeds" => [],
    "pinned" => false,
    "type" => 0
)

# ─── Benchmarks ──────────────────────────────────────────────────────────────

function benchmark_parsing(n::Int)
    println("Benchmarking parsing of MessageCreate (Dict input, n=$n)...")
    
    # Warmup
    parse_event("MESSAGE_CREATE", MESSAGE_CREATE_PAYLOAD)
    
    t_start = time_ns()
    for _ in 1:n
        parse_event("MESSAGE_CREATE", MESSAGE_CREATE_PAYLOAD)
    end
    t_end = time_ns()
    
    total_time_sec = (t_end - t_start) / 1e9
    ops_sec = n / total_time_sec
    
    println("  Throughput: $(round(Int, ops_sec)) ops/sec")
    println("  Latency:    $(round(1000/ops_sec * 1000, digits=2)) μs/op")
    return ops_sec
end

function benchmark_new_parsing(n::Int)
    println("\nBenchmarking NEW parsing (String input, n=$n)...")
    json_str = JSON3.write(MESSAGE_CREATE_PAYLOAD)
    
    # Warmup
    parse_event("MESSAGE_CREATE", json_str)
    
    t_start = time_ns()
    for _ in 1:n
        parse_event("MESSAGE_CREATE", json_str)
    end
    t_end = time_ns()
    
    total_time_sec = (t_end - t_start) / 1e9
    ops_sec = n / total_time_sec
    
    println("  Throughput: $(round(Int, ops_sec)) ops/sec")
    println("  Latency:    $(round(1000/ops_sec * 1000, digits=2)) μs/op")
    return ops_sec
end

function benchmark_ideal(n::Int)
    println("\nBenchmarking IDEAL parsing (JSON string -> Struct directly)...")
    json_str = JSON3.write(MESSAGE_CREATE_PAYLOAD)
    
    # Warmup
    JSON3.read(json_str, Message)
    
    t_start = time_ns()
    for _ in 1:n
        JSON3.read(json_str, Message)
    end
    t_end = time_ns()
    
    total_time_sec = (t_end - t_start) / 1e9
    ops_sec = n / total_time_sec
    
    println("  Throughput: $(round(Int, ops_sec)) ops/sec")
    println("  Latency:    $(round(1000/ops_sec * 1000, digits=2)) μs/op")
    return ops_sec
end

# ─── Main ────────────────────────────────────────────────────────────────────

println("=== Accord.jl Micro-Benchmarks ===")
println("Julia Version: $VERSION")
println("Threads: $(Threads.nthreads())")

const N = 100_000

old_throughput = benchmark_parsing(N)
new_throughput = benchmark_new_parsing(N)
ideal_throughput = benchmark_ideal(N)

println("\n" * "="^40)
println("RESULTS")
println("="^40)
println("Speedup (Dict -> String): $(round(new_throughput / old_throughput, digits=1))x")
println("Efficiency vs Ideal:    $(round(new_throughput / ideal_throughput * 100, digits=1))%")
println("="^40)

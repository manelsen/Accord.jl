"""
    Snowflake

Use this type to work with Discord's unique identifier format for all Discord objects.

Discord Snowflake ID type — a UInt64 wrapper with timestamp extraction.
Discord sends snowflakes as JSON strings; we parse them to UInt64.

# Example
```julia
id = Snowflake("1234567890123456789")
id = Snowflake(1234567890123456789)
```
"""
struct Snowflake
    value::UInt64
end

Snowflake(s::AbstractString) = Snowflake(parse(UInt64, s))
Snowflake(n::Integer) = Snowflake(UInt64(n))
Snowflake(s::Snowflake) = s

const DISCORD_EPOCH = 1420070400000  # ms since Unix epoch (2015-01-01T00:00:00Z)

"""Use this to find out when a Discord object was created based on its ID.

Extract the creation timestamp from a Snowflake.

# Example
```julia
id = Snowflake("175928847299117063")
timestamp(id)  # => 2016-04-30T11:18:36.163
```
"""
timestamp(s::Snowflake) = Dates.unix2datetime(((s.value >> 22) + DISCORD_EPOCH) / 1000)

"""Use this for debugging or analyzing how Discord distributes ID generation across workers.

Extract the internal worker ID.

# Example
```julia
worker_id(Snowflake("175928847299117063"))  # => 1
```
"""
worker_id(s::Snowflake) = (s.value >> 17) & 0x1F

"""Use this for debugging or analyzing how Discord distributes ID generation across processes.

Extract the internal process ID.

# Example
```julia
process_id(Snowflake("175928847299117063"))  # => 0
```
"""
process_id(s::Snowflake) = (s.value >> 12) & 0x1F

"""Use this for debugging or understanding the sequence of IDs generated within the same millisecond.

Extract the increment.

# Example
```julia
increment(Snowflake("175928847299117063"))  # => 7
```
"""
increment(s::Snowflake) = s.value & 0xFFF

Base.:(==)(a::Snowflake, b::Snowflake) = a.value == b.value
Base.hash(s::Snowflake, h::UInt) = hash(s.value, h)
Base.show(io::IO, s::Snowflake) = print(io, "Snowflake(", s.value, ")")
Base.print(io::IO, s::Snowflake) = print(io, s.value)
Base.string(s::Snowflake) = string(s.value)
Base.convert(::Type{Snowflake}, s::AbstractString) = Snowflake(s)
Base.convert(::Type{Snowflake}, n::Integer) = Snowflake(n)
Base.isless(a::Snowflake, b::Snowflake) = isless(a.value, b.value)
Base.UInt64(s::Snowflake) = s.value

# JSON3/StructTypes integration — Snowflakes are strings in JSON
StructTypes.StructType(::Type{Snowflake}) = StructTypes.CustomStruct()
StructTypes.lower(s::Snowflake) = string(s.value)
StructTypes.lowertype(::Type{Snowflake}) = String
function StructTypes.construct(::Type{Snowflake}, s::String)
    Snowflake(parse(UInt64, s))
end

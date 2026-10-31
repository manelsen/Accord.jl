@testitem "Payload helpers" tags=[:unit] begin
    using Accord, JSON3

    @testset "_message_body: new messages omit empty fields" begin
        b = Accord._message_body(; content="hi", embeds=[], components=[], poll=nothing)
        @test b == Dict{String, Any}("content" => "hi")
    end

    @testset "_message_body: edits keep empty values (they clear fields)" begin
        b = Accord._message_body(; omit_empty=false, content="", embeds=[], components=nothing)
        @test b["content"] == ""
        @test b["embeds"] == []
        @test !haskey(b, "components")
    end

    @testset "_message_body: flags and ephemeral are combined" begin
        @test Accord._message_body(; ephemeral=true)["flags"] == 64
        b = Accord._message_body(; ephemeral=true, flags=MsgFlagSuppressEmbeds)
        @test b["flags"] == 64 | 4
        @test !haskey(Accord._message_body(; content="x"), "flags")
        @test Accord._message_body(; tts=true)["tts"] == true
    end

    @testset "_with_set leaves out unset values only" begin
        d = Accord._with_set(Dict{String, Any}("type" => 1);
            a="", b=[], c=nothing, d=false, e=0, f="x", g=true)
        @test d == Dict{String, Any}("type" => 1, "e" => 0, "f" => "x", "g" => true)
    end

    @testset "select builders share one shape" begin
        for f in (Accord.user_select, Accord.role_select, Accord.mentionable_select)
            s = f(; custom_id="pick", placeholder="Choose")
            @test s["custom_id"] == "pick"
            @test s["placeholder"] == "Choose"
            @test s["min_values"] == 1 && s["max_values"] == 1
            @test !haskey(s, "disabled")
        end
        c = Accord.channel_select(; custom_id="ch", channel_types=[0])
        @test c["channel_types"] == [0]
    end

    @testset "parse_event does not mutate the input Dict" begin
        data = Dict{String, Any}("guild_id" => "10", "user" => Dict("id" => "20", "username" => "u"),
                                 "roles" => [], "joined_at" => "2024-01-01T00:00:00Z")
        before = deepcopy(data)
        ev = Accord.parse_event("GUILD_MEMBER_ADD", data)
        @test ev isa GuildMemberAdd
        @test ev.guild_id == Snowflake(10)
        @test data == before
    end

    @testset "flat events decode straight from JSON" begin
        json = """{"guild_id":"1","role_id":"2"}"""
        ev = Accord.parse_event("GUILD_ROLE_DELETE", json)
        @test ev isa Accord.GuildRoleDelete
        @test ev.role_id == Snowflake(2)

        json = """{"user_id":"1","channel_id":"2","message_id":"3","emoji":{"name":"👍"}}"""
        ev = Accord.parse_event("MESSAGE_REACTION_ADD", json)
        @test ev isa Accord.MessageReactionAdd
        @test ev.burst == false
        @test ev.type == 0
        @test ismissing(ev.guild_id)
    end
end

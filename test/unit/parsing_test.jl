@testitem "Offline Parsing (Fixtures)" tags=[:unit] begin
    using Accord, JSON3

    # Helper to convert JSON3 object to Dict{String, Any} for parse_event
    to_dict(obj) = JSON3.read(JSON3.write(obj), Dict{String, Any})

    fixtures_dir = joinpath(dirname(@__DIR__), "integration", "fixtures")
    
    @testset "Gateway Payloads" begin
        # READY
        ready_json = read(joinpath(fixtures_dir, "gateway_ready.json"), String)
        ready_list = JSON3.read(ready_json)
        ready_data = ready_list[1]
        ready_event = Accord.parse_event("READY", to_dict(ready_data.d))
        @test ready_event isa ReadyEvent
        @test ready_event.user.username != ""
        @test length(ready_event.guilds) >= 0

        # GUILD_CREATE
        guild_json = read(joinpath(fixtures_dir, "gateway_guild_create.json"), String)
        guild_list = JSON3.read(guild_json)
        guild_data = guild_list[1]
        guild_event = Accord.parse_event("GUILD_CREATE", to_dict(guild_data.d))
        @test guild_event isa GuildCreate
        @test guild_event.guild.id isa Snowflake
        @test !isempty(guild_event.guild.name)

        # MESSAGE_CREATE
        msg_json = read(joinpath(fixtures_dir, "gateway_message_create.json"), String)
        msg_list = JSON3.read(msg_json)
        msg_data = msg_list[1]
        msg_event = Accord.parse_event("MESSAGE_CREATE", to_dict(msg_data.d))
        @test msg_event isa MessageCreate
        @test !ismissing(msg_event.message.content)
        @test msg_event.message.author.username != ""

        # MESSAGE_UPDATE
        msg_upd_json = read(joinpath(fixtures_dir, "gateway_message_update.json"), String)
        msg_upd_list = JSON3.read(msg_upd_json)
        msg_upd_data = msg_upd_list[1]
        msg_upd_event = Accord.parse_event("MESSAGE_UPDATE", to_dict(msg_upd_data.d))
        @test msg_upd_event isa Accord.MessageUpdate
        @test msg_upd_event.message.id isa Snowflake
        @test msg_upd_event.message.channel_id isa Snowflake
        @test ismissing(msg_upd_event.message.edited_timestamp) || msg_upd_event.message.edited_timestamp isa String

        # MESSAGE_DELETE
        msg_del_json = read(joinpath(fixtures_dir, "gateway_message_delete.json"), String)
        msg_del_list = JSON3.read(msg_del_json)
        msg_del_data = msg_del_list[1]
        msg_del_event = Accord.parse_event("MESSAGE_DELETE", to_dict(msg_del_data.d))
        @test msg_del_event isa Accord.MessageDelete
        @test msg_del_event.id isa Snowflake
        @test msg_del_event.channel_id isa Snowflake

        # THREAD_CREATE
        thread_json = read(joinpath(fixtures_dir, "gateway_thread_create.json"), String)
        thread_list = JSON3.read(thread_json)
        thread_data = thread_list[1]
        thread_event = Accord.parse_event("THREAD_CREATE", to_dict(thread_data.d))
        @test thread_event isa Accord.ThreadCreate
        @test thread_event.channel.id isa Snowflake
        @test thread_event.channel.type isa Int
        if !ismissing(thread_event.channel.thread_metadata)
            meta = thread_event.channel.thread_metadata
            @test meta.archived isa Bool
            @test meta.locked isa Bool
            @test meta.auto_archive_duration isa Int
        end

        # PRESENCE_UPDATE (payload may omit "user" in some edge cases)
        presence_payload = Dict{String, Any}(
            "guild_id" => "200",
            "status" => "online",
            "activities" => Any[],
            "client_status" => Dict("desktop" => "online"),
        )
        presence_event = Accord.parse_event("PRESENCE_UPDATE", presence_payload)
        @test presence_event isa PresenceUpdate
        @test presence_event.presence.status == "online"
        @test presence_event.presence.user isa Dict
    end

    @testset "REST Payloads" begin
        # Get Me (User)
        me_json = read(joinpath(fixtures_dir, "rest_get_me.json"), String)
        me_list = JSON3.read(me_json)
        # REST fixtures are [ {"items": [...]} ] or [ {...} ]
        me_data = haskey(me_list[1], :items) ? me_list[1].items[1] : me_list[1]
        me = JSON3.read(JSON3.write(me_data), User)
        @test me isa User
        @test me.id isa Snowflake

        # Get Guild
        guild_json = read(joinpath(fixtures_dir, "rest_get_guild.json"), String)
        guild_list = JSON3.read(guild_json)
        guild_data = haskey(guild_list[1], :items) ? guild_list[1].items[1] : guild_list[1]
        guild = JSON3.read(JSON3.write(guild_data), Guild)
        @test guild isa Guild
        @test guild.id isa Snowflake

        # List Members
        members_json = read(joinpath(fixtures_dir, "rest_get_members.json"), String)
        members_list = JSON3.read(members_json)
        # Members fixture is [ {"items": [member1, member2...]} ]
        members_data = members_list[1].items
        members = JSON3.read(JSON3.write(members_data), Vector{Member})
        @test members isa Vector{Member}
        @test length(members) > 0
        @test members[1].user isa User

        # Get Emojis
        emojis_json = read(joinpath(fixtures_dir, "rest_get_emojis.json"), String)
        emojis_list = JSON3.read(emojis_json)
        emojis_data = haskey(emojis_list[1], :items) ? emojis_list[1].items : emojis_list
        emojis = JSON3.read(JSON3.write(emojis_data), Vector{Emoji})
        @test emojis isa Vector{Emoji}
        @test length(emojis) > 0
        @test emojis[1].id isa Snowflake
    end

    @testset "Interaction Payloads" begin
        # Interaction Create (Slash Command)
        int_json = read(joinpath(fixtures_dir, "gateway_interaction_create.json"), String)
        int_list = JSON3.read(int_json)
        int_data = int_list[1]
        int_event = Accord.parse_event("INTERACTION_CREATE", to_dict(int_data.d))
        @test int_event isa InteractionCreate
        @test int_event.interaction.type == InteractionTypes.APPLICATION_COMMAND
        @test !ismissing(int_event.interaction.data)
    end
end

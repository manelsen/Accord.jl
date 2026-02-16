@testitem "REST Events and Voice Endpoints" tags=[:integration] begin
    include("rest_test_utils.jl")
    using Accord, HTTP

    @testset "Scheduled Event Endpoints" begin
        g_id = Snowflake(200)
        ev_id = Snowflake(1200)

        @testset "list_scheduled_events" begin
            handler, cap = capture_handler(mock_json([scheduled_event_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.list_scheduled_events(rl, g_id; token)
                @test result isa Vector{ScheduledEvent}
                @test cap[][1] == "GET"
            end
        end

        @testset "create_guild_scheduled_event" begin
            handler, cap = capture_handler(mock_json(scheduled_event_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.create_guild_scheduled_event(rl, g_id; token, body=Dict("name" => "Event"))
                @test result isa ScheduledEvent
                @test cap[][1] == "POST"
            end
        end

        @testset "get_guild_scheduled_event" begin
            handler, cap = capture_handler(mock_json(scheduled_event_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_scheduled_event(rl, g_id, ev_id; token)
                @test result isa ScheduledEvent
                @test cap[][1] == "GET"
            end
        end

        @testset "modify_guild_scheduled_event" begin
            handler, cap = capture_handler(mock_json(scheduled_event_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.modify_guild_scheduled_event(rl, g_id, ev_id; token, body=Dict("name" => "Updated"))
                @test result isa ScheduledEvent
                @test cap[][1] == "PATCH"
            end
        end

        @testset "delete_guild_scheduled_event" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_guild_scheduled_event(rl, g_id, ev_id; token)
                @test cap[][1] == "DELETE"
            end
        end

        @testset "get_guild_scheduled_event_users" begin
            handler, cap = capture_handler(mock_json(Dict("users" => [])))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_scheduled_event_users(rl, g_id, ev_id; token)
                @test result isa Dict
                @test cap[][1] == "GET"
            end
        end
    end

    @testset "Stage Instance Endpoints" begin
        @testset "create_stage_instance" begin
            handler, cap = capture_handler(mock_json(stage_instance_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.create_stage_instance(rl; token, body=Dict("channel_id" => "300", "topic" => "Test"))
                @test result isa StageInstance
                @test cap[][1] == "POST"
            end
        end

        @testset "get_stage_instance" begin
            handler, cap = capture_handler(mock_json(stage_instance_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_stage_instance(rl, Snowflake(300); token)
                @test result isa StageInstance
                @test cap[][1] == "GET"
            end
        end

        @testset "modify_stage_instance" begin
            handler, cap = capture_handler(mock_json(stage_instance_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.modify_stage_instance(rl, Snowflake(300); token, body=Dict("topic" => "Updated"))
                @test result isa StageInstance
                @test cap[][1] == "PATCH"
            end
        end

        @testset "delete_stage_instance" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_stage_instance(rl, Snowflake(300); token)
                @test cap[][1] == "DELETE"
            end
        end
    end

    @testset "Soundboard Endpoints" begin
        g_id = Snowflake(200)
        snd_id = Snowflake(1400)

        @testset "list_default_soundboard_sounds" begin
            handler, cap = capture_handler(mock_json([soundboard_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.list_default_soundboard_sounds(rl; token)
                @test result isa Vector{SoundboardSound}
                @test cap[][1] == "GET"
            end
        end

        @testset "list_guild_soundboard_sounds" begin
            handler, cap = capture_handler(mock_json(Dict("items" => [soundboard_json()])))
            with_mock_rl(handler) do rl, token
                result = Accord.list_guild_soundboard_sounds(rl, g_id; token)
                @test result isa Dict
                @test cap[][1] == "GET"
            end
        end

        @testset "get_guild_soundboard_sound" begin
            handler, cap = capture_handler(mock_json(soundboard_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.get_guild_soundboard_sound(rl, g_id, snd_id; token)
                @test result isa SoundboardSound
                @test cap[][1] == "GET"
            end
        end

        @testset "create_guild_soundboard_sound" begin
            handler, cap = capture_handler(mock_json(soundboard_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.create_guild_soundboard_sound(rl, g_id; token, body=Dict("name" => "test", "sound" => "data:..."))
                @test result isa SoundboardSound
                @test cap[][1] == "POST"
            end
        end

        @testset "modify_guild_soundboard_sound" begin
            handler, cap = capture_handler(mock_json(soundboard_json()))
            with_mock_rl(handler) do rl, token
                result = Accord.modify_guild_soundboard_sound(rl, g_id, snd_id; token, body=Dict("name" => "renamed"))
                @test result isa SoundboardSound
                @test cap[][1] == "PATCH"
            end
        end

        @testset "delete_guild_soundboard_sound" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.delete_guild_soundboard_sound(rl, g_id, snd_id; token)
                @test cap[][1] == "DELETE"
            end
        end

        @testset "send_soundboard_sound" begin
            handler, cap = capture_handler(HTTP.Response(204))
            with_mock_rl(handler) do rl, token
                Accord.send_soundboard_sound(rl, Snowflake(300); token, body=Dict("sound_id" => "1400"))
                @test cap[][1] == "POST"
                @test contains(cap[][2], "/send-soundboard-sound")
            end
        end
    end

    @testset "Voice Endpoints" begin
        @testset "list_voice_regions" begin
            handler, cap = capture_handler(mock_json([voice_region_json()]))
            with_mock_rl(handler) do rl, token
                result = Accord.list_voice_regions(rl; token)
                @test result isa Vector{VoiceRegion}
                @test cap[][1] == "GET"
                @test contains(cap[][2], "/voice/regions")
            end
        end
    end
end

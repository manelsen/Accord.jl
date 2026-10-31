@testitem "Discord API 2025–26 additions" tags=[:unit] begin
    using Accord, JSON3, HTTP
    using Accord: InteractionContext, modal_values, modal_files, _message_body, parse_event,
        _resolve_perm, label, file_upload, radio_group, checkbox_group, checkbox,
        text_input, select_option, container, text_display, action_row, button, has_flag,
        PermSetVoiceChannelStatus, PermPinMessages, PermBypassSlowmode, PermUseExternalApps,
        MsgFlagHasSnapshot, AttachFlagIsSpoiler, AttachFlagContainsSelfHarmContent,
        AuditLogEventTypes

    function modal_ctx(payload::AbstractString)
        client = Client("Bot test_token_fake")
        client.ratelimiter.request_handler = (m, u, h, b) -> HTTP.Response(200, "{}")
        InteractionContext(client, JSON3.read(payload, Interaction))
    end

    @testset "permissions, message and attachment flags" begin
        @test PermSetVoiceChannelStatus.value == UInt64(1) << 48
        @test PermPinMessages.value == UInt64(1) << 51
        @test PermBypassSlowmode.value == UInt64(1) << 52
        @test _resolve_perm(:PIN_MESSAGES) == PermPinMessages
        @test _resolve_perm(:BYPASS_SLOWMODE) == PermBypassSlowmode
        @test _resolve_perm(:USE_EXTERNAL_APPS) == PermUseExternalApps
        @test has_flag(Permissions(parse(UInt64, "6755399441055744")), PermPinMessages)  # bits 51+52
        @test MsgFlagIsComponentsV2.value == 1 << 15
        @test MsgFlagHasSnapshot.value == 1 << 14
        @test AttachFlagIsSpoiler.value == 1 << 3
        @test AttachFlagContainsSelfHarmContent.value == 1 << 7
    end

    @testset "constants match Discord's numbering" begin
        @test (ComponentTypes.LABEL, ComponentTypes.FILE_UPLOAD, ComponentTypes.RADIO_GROUP,
               ComponentTypes.CHECKBOX_GROUP, ComponentTypes.CHECKBOX) == (18, 19, 21, 22, 23)
        @test AuditLogEventTypes.CHANNEL_POSITION_UPDATE == 16
        @test AuditLogEventTypes.ROLE_POSITION_UPDATE == 33
        @test AuditLogEventTypes.AUTO_MODERATION_QUARANTINE_USER == 146
        @test AuditLogEventTypes.HOME_SETTINGS_UPDATE == 191
        @test Accord.GatewayOpcodes.REQUEST_SOUNDBOARD_SOUNDS == 31
        @test Accord.GatewayOpcodes.REQUEST_CHANNEL_INFO == 43
        @test MessageReferenceTypes.FORWARD == 1
    end

    @testset "modal builders" begin
        ti = text_input(custom_id="name")
        @test !haskey(ti, "label")                       # the question lives in the Label
        @test text_input(custom_id="n", label="Old")["label"] == "Old"

        opts = [select_option(label="A", value="a"), select_option(label="B", value="b")]
        l = label("Pick", radio_group(custom_id="rg", options=opts); description="one")
        @test l["type"] == 18 && l["label"] == "Pick" && l["description"] == "one"
        @test l["component"]["type"] == 21 && l["component"]["required"] === true
        @test !haskey(label("Q", ti), "description")

        cg = checkbox_group(custom_id="cg", options=opts; min_values=0)
        @test (cg["type"], cg["min_values"], cg["max_values"]) == (22, 0, 2)

        cb = checkbox(custom_id="cb")
        @test cb["type"] == 23 && !haskey(cb, "default") && !haskey(cb, "required")
        @test checkbox(custom_id="cb", default=true)["default"] === true

        fu = file_upload(custom_id="f", max_values=3, file_types=["image", ".pdf"])
        @test (fu["type"], fu["max_values"], fu["file_types"]) == (19, 3, ["image", ".pdf"])
        @test !haskey(file_upload(custom_id="f"), "file_types")
    end

    @testset "modal_values reads every input type" begin
        payload = """
        {"id": "1", "application_id": "2", "type": 5, "token": "t", "version": 1,
         "data": {"custom_id": "form", "components": [
            {"type": 18, "id": 1, "component": {"type": 4, "id": 2, "custom_id": "name", "value": "Ana"}},
            {"type": 18, "id": 3, "component": {"type": 21, "id": 4, "custom_id": "day", "value": "sat"}},
            {"type": 18, "id": 5, "component": {"type": 21, "id": 6, "custom_id": "maybe", "value": null}},
            {"type": 18, "id": 7, "component": {"type": 22, "id": 8, "custom_id": "sessions", "values": ["talks", "dinner"]}},
            {"type": 18, "id": 9, "component": {"type": 23, "id": 10, "custom_id": "remind", "value": true}},
            {"type": 18, "id": 11, "component": {"type": 3, "id": 12, "custom_id": "pick", "values": []}},
            {"type": 18, "id": 13, "component": {"type": 19, "id": 14, "custom_id": "photo", "values": ["555"]}},
            {"type": 1, "components": [{"type": 4, "custom_id": "legacy", "value": "old style"}]}
         ],
         "resolved": {"attachments": {"555": {"id": "555", "filename": "me.png", "size": 10,
                                              "url": "https://cdn/x", "proxy_url": "https://media/x"}}}}}
        """
        ctx = modal_ctx(payload)
        v = modal_values(ctx)
        @test v["name"] == "Ana"
        @test v["day"] == "sat"
        @test haskey(v, "maybe") && v["maybe"] === nothing
        @test v["sessions"] == ["talks", "dinner"]
        @test v["remind"] === true
        @test v["pick"] == String[]
        @test v["legacy"] == "old style"
        files = modal_files(ctx, "photo")
        @test length(files) == 1 && only(files).filename == "me.png" && only(files).id == Snowflake(555)
        @test isempty(modal_files(ctx, "name"))
        @test isempty(modal_files(ctx, "absent"))
    end

    @testset "Components V2 messages get the flag automatically" begin
        v2 = _message_body(; components=[container([text_display("hi")])])
        @test v2["flags"] == 1 << 15
        both = _message_body(; components=[text_display("hi")], ephemeral=true)
        @test both["flags"] == (1 << 15) | (1 << 6)
        legacy = _message_body(; components=[action_row([button(label="x", custom_id="x")])])
        @test !haskey(legacy, "flags")
        @test !haskey(_message_body(; content="plain"), "flags")
    end

    @testset "container accent colour is read" begin
        c = JSON3.read("""{"type": 17, "accent_color": 5793266, "components": []}""", Component)
        @test c.accent_color == 5793266
        @test JSON3.read("""{"type": 17, "accent_color": null}""", Component).accent_color === nothing
    end

    @testset "forwarded messages, server tags and role colours" begin
        m = JSON3.read("""
            {"id": "10", "channel_id": "20", "type": 0, "content": "", "flags": 16384,
             "message_reference": {"type": 1, "message_id": "5", "channel_id": "6"},
             "message_snapshots": [{"message": {"type": 0, "content": "original text",
                 "embeds": [], "attachments": [], "timestamp": "2026-10-31T12:00:00+00:00",
                 "flags": 0, "mentions": [], "mention_roles": []}}]}
            """, Message)
        @test m.message_reference.type == MessageReferenceTypes.FORWARD
        @test only(m.message_snapshots).message.content == "original text"
        @test has_flag(MessageFlags(m.flags), MsgFlagHasSnapshot)

        u = JSON3.read("""{"id": "1", "username": "x", "primary_guild":
            {"identity_guild_id": "99", "identity_enabled": true, "tag": "JULI", "badge": "abc"}}""", User)
        @test u.primary_guild.tag == "JULI" && u.primary_guild.identity_guild_id == Snowflake(99)
        @test JSON3.read("""{"id": "1", "username": "x", "primary_guild": null}""", User).primary_guild === nothing

        r = JSON3.read("""{"id": "1", "name": "grad", "color": 255, "hoist": false, "position": 1,
            "permissions": "0", "managed": false, "mentionable": false, "flags": 0,
            "colors": {"primary_color": 255, "secondary_color": 65280, "tertiary_color": null}}""", Role)
        @test (r.colors.primary_color, r.colors.secondary_color, r.colors.tertiary_color) == (255, 65280, nothing)
    end

    @testset "RATE_LIMITED and CHANNEL_INFO events" begin
        e = parse_event("RATE_LIMITED",
            """{"opcode": 8, "retry_after": 27.5, "meta": {"guild_id": "42", "nonce": "n1"}}""")
        @test e isa RateLimited
        @test e.opcode == 8 && e.retry_after == 27.5
        @test_logs (:warn, r"rate-limited request_guild_members") Accord._warn_rate_limited(e)

        ci = parse_event("CHANNEL_INFO", """{"guild_id": "1", "channels": [
            {"id": "2", "status": "Raid night", "voice_start_time": 1761912000},
            {"id": "3", "status": null}]}""")
        @test ci isa ChannelInfo
        @test ci.channels[1].status == "Raid night" && ci.channels[1].voice_start_time == 1761912000
        @test ci.channels[2].status === nothing
    end

    @testset "forward_message builds a forward reference" begin
        client = Client("Bot test_token_fake")
        sent = Ref{Any}(nothing)
        client.ratelimiter.request_handler = (m, u, h, b) -> begin
            sent[] = (m, u, JSON3.read(b))
            HTTP.Response(200, """{"id": "11", "channel_id": "77"}""")
        end
        Accord.start_ratelimiter!(client.ratelimiter)
        try
            orig = Message(id=Snowflake(5), channel_id=Snowflake(6), guild_id=Snowflake(7))
            forward_message(client, Snowflake(77), orig)
            m, u, body = sent[]
            @test m == "POST" && endswith(u, "/channels/77/messages")
            ref = body[:message_reference]
            @test ref[:type] == 1 && ref[:message_id] == "5" && ref[:channel_id] == "6" && ref[:guild_id] == "7"
            @test !haskey(body, :content)
        finally
            Accord.stop_ratelimiter!(client.ratelimiter)
        end
    end
end

@testitem "Invite target users, attachment edits and scanned media" tags=[:unit] begin
    using Accord, HTTP, JSON3

    # A client whose requests go to `respond(method, url)` instead of Discord.
    # Each call records (method, path after /v10, body as a String).
    function with_client(f, respond)
        client = Client("Bot test_token_fake")
        calls = Tuple{String, String, String}[]
        client.ratelimiter.request_handler = (m, u, h, b) -> begin
            body = b === nothing ? "" : b isa AbstractString ? String(b) : String(read(b))
            push!(calls, (m, last(split(u, "/v10")), body))
            respond(m, u)
        end
        Accord.start_ratelimiter!(client.ratelimiter)
        try
            f(client, calls)
        finally
            Accord.stop_ratelimiter!(client.ratelimiter)
        end
    end
    ok(m, u) = HTTP.Response(204)

    @testset "target user endpoints" begin
        with_client(ok) do client, calls
            code = "abc123"
            Accord.add_invite_target_user(client, code, Snowflake(7))
            Accord.remove_invite_target_user(client, code, Snowflake(7))
            Accord.bulk_add_invite_target_users(client, code, [Snowflake(1), 2])
            Accord.bulk_delete_invite_target_users(client, code, [Snowflake(3)])
            Accord.update_invite_target_users(client, code, [Snowflake(4), Snowflake(5)])
            @test [(m, p) for (m, p, _) in calls] == [
                ("PUT", "/invites/abc123/target-users/7"),
                ("DELETE", "/invites/abc123/target-users/7"),
                ("POST", "/invites/abc123/target-users/bulk-add"),
                ("POST", "/invites/abc123/target-users/bulk-delete"),
                ("PUT", "/invites/abc123/target-users"),
            ]
            @test JSON3.read(calls[3][3]).user_ids == ["1", "2"]
            # The CSV upload is a multipart field named target_users_file, one id per line
            form = calls[5][3]
            @test occursin("name=\"target_users_file\"", form)
            @test occursin("4\n5", form)
            @test_throws ArgumentError Accord.bulk_add_invite_target_users(client, code, 1:1001)
        end
    end

    @testset "reading target users and the job status" begin
        csv(m, u) = HTTP.Response(200, "user_id\n10\n20\n")
        with_client(csv) do client, _
            @test Accord.get_invite_target_users(client, "abc") == [Snowflake(10), Snowflake(20)]
        end
        job(m, u) = HTTP.Response(200, """{"status": 2, "total_users": 3, "processed_users": 3,
            "created_at": "2026-10-31T10:00:00+00:00", "completed_at": null, "error_message": null}""")
        with_client(job) do client, calls
            j = Accord.get_invite_target_users_job_status(client, "abc")
            @test calls[1][2] == "/invites/abc/target-users/job-status"
            @test j isa InviteTargetUsersJob
            @test j.status == InviteTargetUsersJobStatuses.COMPLETED && j.processed_users == 3
            @test j.completed_at === nothing && j.error_message === nothing
        end
    end

    @testset "create_channel_invite with a target users file" begin
        created(m, u) = HTTP.Response(200, """{"type": 0, "code": "xyz", "flags": 1,
            "roles": [{"id": "9", "name": "Guest", "position": 1, "color": 0}]}""")
        with_client(created) do client, calls
            inv = Accord.create_channel_invite(client, Snowflake(300);
                body=Dict("max_age" => 0, "role_ids" => ["9"]), target_users_file=[Snowflake(11), Snowflake(12)])
            @test inv.flags == 1 && only(inv.roles).name == "Guest"
            m, path, form = only(calls)
            @test (m, path) == ("POST", "/channels/300/invites")
            @test occursin("name=\"payload_json\"", form) && occursin("\"role_ids\"", form)
            @test occursin("name=\"target_users_file\"", form) && occursin("11\n12", form)
        end
    end

    @testset "attachment_edit" begin
        a = Attachment(id=Snowflake(55), filename="cat.png", url="u", proxy_url="p")
        @test Accord.attachment_edit(a) == Dict("id" => "55")
        @test Accord.attachment_edit(a; description="A cat", spoiler=true) ==
              Dict("id" => "55", "description" => "A cat", "is_spoiler" => true)
        @test Accord.attachment_edit(56; spoiler=false)["is_spoiler"] === false

        edited(m, u) = HTTP.Response(200, """{"id": "1", "channel_id": "2"}""")
        with_client(edited) do client, calls
            edit_message(client, Snowflake(2), Snowflake(1); attachments=[Accord.attachment_edit(a; spoiler=true)])
            @test JSON3.read(only(calls)[3]).attachments[1].is_spoiler == true
        end
    end

    @testset "components embeds and content scan metadata" begin
        e = JSON3.read("""{"type": "components", "flags": 16, "components": [{"type": 17, "components": [
            {"type": 12, "items": [{"media": {"url": "https://x/a.png", "width": null,
                                              "content_scan_metadata": {"flags": 1}}, "spoiler": true}]},
            {"type": 11, "media": {"url": "https://x/t.png", "attachment_id": "77"}}]}]}""", Embed)
        @test e.flags & EmbedFlags.CONTAINS_EXPLICIT_CONTENT != 0
        gallery, thumb = only(e.components).components
        item = only(gallery.items)
        @test item isa MediaGalleryItem && item.spoiler === true
        @test item.media.url == "https://x/a.png" && item.media.width === nothing
        @test item.media.content_scan_metadata.flags & ContentScanFlags.IS_EXPLICIT_CONTENT != 0
        @test thumb.media isa UnfurledMediaItem && thumb.media.attachment_id == Snowflake(77)
        @test ismissing(thumb.media.content_scan_metadata)
    end
end

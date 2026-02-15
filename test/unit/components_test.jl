@testitem "Component Builders" tags=[:unit] begin
    using Accord

    @testset "button" begin
        btn = button(label="Click me", custom_id="btn_1", style=ButtonStyles.PRIMARY)
        @test btn["type"] == ComponentTypes.BUTTON
        @test btn["label"] == "Click me"
        @test btn["custom_id"] == "btn_1"
        @test btn["style"] == ButtonStyles.PRIMARY

        # Link button
        link_btn = button(label="Visit", url="https://example.com", style=ButtonStyles.LINK)
        @test link_btn["url"] == "https://example.com"
    end

    @testset "action_row" begin
        row = action_row([
            button(label="A", custom_id="a"),
            button(label="B", custom_id="b"),
        ])
        @test row["type"] == ComponentTypes.ACTION_ROW
        @test length(row["components"]) == 2
    end

    @testset "string_select" begin
        sel = string_select(
            custom_id="color_select",
            options=[
                select_option(label="Red", value="red"),
                select_option(label="Blue", value="blue", description="Ocean color"),
            ],
            placeholder="Choose a color",
        )
        @test sel["type"] == ComponentTypes.STRING_SELECT
        @test sel["custom_id"] == "color_select"
        @test length(sel["options"]) == 2
        @test sel["options"][1]["label"] == "Red"
        @test sel["options"][2]["description"] == "Ocean color"
    end

    @testset "text_input" begin
        ti = text_input(
            custom_id="feedback",
            label="Your feedback",
            style=TextInputStyles.PARAGRAPH,
            placeholder="Type here...",
        )
        @test ti["type"] == ComponentTypes.TEXT_INPUT
        @test ti["custom_id"] == "feedback"
        @test ti["style"] == TextInputStyles.PARAGRAPH
    end

    @testset "embed builder" begin
        e = embed(
            title="Test",
            description="A description",
            color=0xFF0000,
            fields=[
                Dict("name" => "Field 1", "value" => "Val 1", "inline" => true),
            ]
        )
        @test e["title"] == "Test"
        @test e["description"] == "A description"
        @test e["color"] == 0xFF0000
        @test length(e["fields"]) == 1
    end

    @testset "command_option" begin
        opt = command_option(
            type=ApplicationCommandOptionTypes.STRING,
            name="query",
            description="Search query",
            required=true,
        )
        @test opt["type"] == ApplicationCommandOptionTypes.STRING
        @test opt["name"] == "query"
        @test opt["required"] == true
    end

    @testset "@option macro" begin
        opt = @option String "query" "Search query" required=true
        @test opt["type"] == ApplicationCommandOptionTypes.STRING
        @test opt["name"] == "query"
        @test opt["description"] == "Search query"
        @test opt["required"] == true

        opt2 = @option Integer "count" "How many" min_value=1 max_value=25
        @test opt2["type"] == ApplicationCommandOptionTypes.INTEGER
        @test opt2["min_value"] == 1
        @test opt2["max_value"] == 25
        @test !haskey(opt2, "required")

        opt3 = @option Boolean "verbose" "Verbose output"
        @test opt3["type"] == ApplicationCommandOptionTypes.BOOLEAN
        @test opt3["name"] == "verbose"

        # Works inside a vector (as used with @slash_command)
        opts = [
            @option String "name" "Your name" required=true
            @option Integer "age" "Your age"
        ]
        @test length(opts) == 2
        @test opts[1]["type"] == ApplicationCommandOptionTypes.STRING
        @test opts[2]["type"] == ApplicationCommandOptionTypes.INTEGER
    end

    @testset "embed_field" begin
        f = embed_field("Name", "Value")
        @test f["name"] == "Name"
        @test f["value"] == "Value"
        @test !haskey(f, "inline")

        f_inline = embed_field("Name", "Value"; inline=true)
        @test f_inline["inline"] == true
    end

    @testset "embed_footer" begin
        ft = embed_footer("Footer text")
        @test ft["text"] == "Footer text"
        @test !haskey(ft, "icon_url")

        ft2 = embed_footer("Footer text"; icon_url="https://example.com/icon.png")
        @test ft2["icon_url"] == "https://example.com/icon.png"
    end

    @testset "embed_author" begin
        a = embed_author("Author Name")
        @test a["name"] == "Author Name"
        @test !haskey(a, "url")

        a2 = embed_author("Author"; url="https://example.com", icon_url="https://example.com/a.png")
        @test a2["url"] == "https://example.com"
        @test a2["icon_url"] == "https://example.com/a.png"
    end

    @testset "embed with helpers" begin
        e = embed(
            title="Test",
            description="Desc",
            color=0x5865F2,
            fields=[
                embed_field("F1", "V1"; inline=true),
                embed_field("F2", "V2"),
            ],
            footer=embed_footer("footer text"),
            author=embed_author("bot"),
        )
        @test e["title"] == "Test"
        @test length(e["fields"]) == 2
        @test e["fields"][1]["inline"] == true
        @test e["footer"]["text"] == "footer text"
        @test e["author"]["name"] == "bot"
    end

    @testset "activity" begin
        a = activity("Playing Accord.jl")
        @test a["name"] == "Playing Accord.jl"
        @test a["type"] == ActivityTypes.GAME
        @test !haskey(a, "url")

        a2 = activity("Streaming", ActivityTypes.STREAMING; url="https://twitch.tv/test")
        @test a2["type"] == ActivityTypes.STREAMING
        @test a2["url"] == "https://twitch.tv/test"
    end

    # === Components V2 ===

    @testset "container" begin
        c = container([text_display("Hello")])
        @test c["type"] == ComponentTypes.CONTAINER
        @test length(c["components"]) == 1
        @test !haskey(c, "accent_color")
        @test !haskey(c, "spoiler")

        c2 = container([text_display("Hi")]; color=0xFF0000, spoiler=true)
        @test c2["accent_color"] == 0xFF0000
        @test c2["spoiler"] == true
    end

    @testset "section" begin
        s = section([text_display("Content")])
        @test s["type"] == ComponentTypes.SECTION
        @test length(s["components"]) == 1
        @test !haskey(s, "accessory")

        thumb = thumbnail(media=unfurled_media("https://example.com/img.png"))
        s2 = section([text_display("With thumb")]; accessory=thumb)
        @test s2["accessory"]["type"] == ComponentTypes.THUMBNAIL
    end

    @testset "text_display" begin
        td = text_display("Hello, world!")
        @test td["type"] == ComponentTypes.TEXT_DISPLAY
        @test td["content"] == "Hello, world!"
    end

    @testset "thumbnail" begin
        m = unfurled_media("https://example.com/img.png")
        t = thumbnail(media=m)
        @test t["type"] == ComponentTypes.THUMBNAIL
        @test t["media"]["url"] == "https://example.com/img.png"
        @test !haskey(t, "description")
        @test !haskey(t, "spoiler")

        t2 = thumbnail(media=m, description="A thumbnail", spoiler=true)
        @test t2["description"] == "A thumbnail"
        @test t2["spoiler"] == true
    end

    @testset "media_gallery" begin
        items = [
            media_gallery_item(media=unfurled_media("https://example.com/1.png")),
            media_gallery_item(media=unfurled_media("https://example.com/2.png"), description="Image 2", spoiler=true),
        ]
        mg = media_gallery(items)
        @test mg["type"] == ComponentTypes.MEDIA_GALLERY
        @test length(mg["items"]) == 2
        @test mg["items"][2]["description"] == "Image 2"
        @test mg["items"][2]["spoiler"] == true
        @test !haskey(mg["items"][1], "description")
    end

    @testset "file_component" begin
        m = unfurled_media("https://example.com/doc.pdf")
        f = file_component(media=m)
        @test f["type"] == ComponentTypes.FILE
        @test f["file"]["url"] == "https://example.com/doc.pdf"
        @test !haskey(f, "spoiler")

        f2 = file_component(media=m, spoiler=true)
        @test f2["spoiler"] == true
    end

    @testset "separator" begin
        s = separator()
        @test s["type"] == ComponentTypes.SEPARATOR
        @test s["divider"] == true
        @test !haskey(s, "spacing")

        s2 = separator(divider=false, spacing=2)
        @test s2["divider"] == false
        @test s2["spacing"] == 2
    end

    @testset "unfurled_media" begin
        m = unfurled_media("https://example.com/test.png")
        @test m["url"] == "https://example.com/test.png"
    end

    @testset "v2 composition" begin
        # Build a full v2 layout
        layout = container([
            section([text_display("Welcome!")]; accessory=thumbnail(media=unfurled_media("https://example.com/avatar.png"))),
            separator(),
            media_gallery([
                media_gallery_item(media=unfurled_media("https://example.com/1.png")),
            ]),
        ]; color=0x5865F2)

        @test layout["type"] == ComponentTypes.CONTAINER
        @test length(layout["components"]) == 3
        @test layout["components"][1]["type"] == ComponentTypes.SECTION
        @test layout["components"][2]["type"] == ComponentTypes.SEPARATOR
        @test layout["components"][3]["type"] == ComponentTypes.MEDIA_GALLERY
        @test layout["accent_color"] == 0x5865F2
    end
end

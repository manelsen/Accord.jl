@testset "Component Builders" begin
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
end

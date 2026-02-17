@testitem "Macros" tags=[:unit] begin
    using Accord, JSON3, StructTypes, Dates
    using Accord: has_flag, @discord_flags, @discord_struct, @_flags_structtypes_int, drain_pending_checks!, _CHECKS_LOCK, _PENDING_CHECKS, CommandTree

    # Flags macro types need to be defined at module/top-level scope because they
    # generate `const` declarations that are not allowed inside local scopes.
    # We define them here and test them in the @testset blocks below.

    # --- @discord_flags test types (top-level) ---
    @discord_flags TestFlags begin
        FLAG_A = 1 << 0
        FLAG_B = 1 << 1
        FLAG_C = 1 << 2
    end

    @discord_flags TestFlagsZero begin
        TF_X = 1
    end

    @discord_flags TestFlagsOr begin
        TFO_A = 1 << 0
        TFO_B = 1 << 1
    end

    @discord_flags TestFlagsAnd begin
        TFA_A = 1 << 0
        TFA_B = 1 << 1
        TFA_C = 1 << 2
    end

    @discord_flags TestFlagsXor begin
        TFX_A = 1 << 0
        TFX_B = 1 << 1
    end

    @discord_flags TestFlagsNot begin
        TFN_A = 1 << 0
    end

    @discord_flags TestFlagsEq begin
        TFE_A = 1
        TFE_B = 2
    end

    @discord_flags TestFlagsShow begin
        TFS_X = 42
    end

    @discord_flags TestFlagsInt begin
        TFI_A = 1
    end

    @discord_flags TestFlagsLarge begin
        TFL_HIGH = UInt64(1) << 63
    end

    @discord_flags TestFlagsSingle begin
        SINGLE = 1
    end

    @discord_flags TestFlagsHasZero begin
        TFHZ_A = 1
    end

    # --- @_flags_structtypes_int test types (top-level) ---
    @discord_flags TestSTFlags begin
        TST_A = 1
        TST_B = 2
    end
    @_flags_structtypes_int TestSTFlags

    # --- @discord_struct test types (top-level) ---
    # These also generate struct definitions which must be at top-level

    @discord_struct TestBasicStruct begin
        name::String
        value::Int
    end

    @discord_struct TestOptionalStruct begin
        name::String
        tag::Optional{String}
    end

    @discord_struct TestNullableStruct begin
        id::Int
        avatar::Nullable{String}
    end

    @discord_struct TestVectorStruct begin
        items::Vector{String}
    end

    @discord_struct TestDefaultStruct begin
        count::Int = 42
        label::String = "default"
    end

    @discord_struct TestBoolFloatStruct begin
        active::Bool
        score::Float64
    end

    @discord_struct TestSnowflakeStruct begin
        id::Snowflake
    end

    @discord_struct TestAnyStruct begin
        data::Any
    end

    @discord_struct TestMutableCheck begin
        x::Int
    end

    @discord_struct TestStructTypesCheck begin
        x::Int
    end

    @discord_struct TestMixedStruct begin
        id::Snowflake
        name::String
        nick::Optional{String}
        avatar::Nullable{String}
        roles::Vector{Int}
        active::Bool
        score::Float64
    end

    @discord_struct TestKWStruct begin
        name::String
        value::Int
        tag::Optional{String}
    end

    struct CustomInner
        v::Int
    end

    @discord_struct TestUnknownTypeStruct begin
        custom::CustomInner = CustomInner(0)
    end

    @discord_struct TestJSONStruct begin
        name::String
        count::Int
        active::Bool
        tag::Optional{String}
    end

    @discord_struct TestSmallNumStruct begin
        x::Float32
        y::Int32
    end


    @testset "@discord_struct" begin

        @testset "basic struct generation" begin
            s = TestBasicStruct()
            @test s.name == ""
            @test s.value == 0
            s.name = "hello"
            @test s.name == "hello"
        end

        @testset "Optional fields default to missing" begin
            s = TestOptionalStruct()
            @test s.name == ""
            @test ismissing(s.tag)
        end

        @testset "Nullable fields default to nothing" begin
            s = TestNullableStruct()
            @test s.id == 0
            @test isnothing(s.avatar)
        end

        @testset "Vector fields default to empty vector" begin
            s = TestVectorStruct()
            @test s.items == String[]
            @test isempty(s.items)
        end

        @testset "explicit defaults are preserved" begin
            s = TestDefaultStruct()
            @test s.count == 42
            @test s.label == "default"
        end

        @testset "Bool and Float defaults" begin
            s = TestBoolFloatStruct()
            @test s.active == false
            @test s.score == 0.0
        end

        @testset "Snowflake fields get default" begin
            s = TestSnowflakeStruct()
            @test s.id == Snowflake(0)
        end

        @testset "Any fields need explicit default" begin
            # _default_for_type returns nothing for :Any, but the macro
            # uses nothing as sentinel for "no default found", so Any fields
            # without an explicit default require the keyword at construction.
            @test_throws UndefKeywordError TestAnyStruct()
            # With explicit value it works fine:
            s = TestAnyStruct(data=42)
            @test s.data == 42
        end

        @testset "struct is mutable" begin
            s = TestMutableCheck()
            s.x = 99
            @test s.x == 99
        end

        @testset "struct has StructTypes.Mutable" begin
            @test StructTypes.StructType(TestStructTypesCheck) == StructTypes.Mutable()
        end

        @testset "mixed Optional, Nullable, Vector, and concrete fields" begin
            s = TestMixedStruct()
            @test s.id == Snowflake(0)
            @test s.name == ""
            @test ismissing(s.nick)
            @test isnothing(s.avatar)
            @test isempty(s.roles)
            @test s.active == false
            @test s.score == 0.0
        end

        @testset "keyword construction with overrides" begin
            s = TestKWStruct(name="test", value=10, tag="v1")
            @test s.name == "test"
            @test s.value == 10
            @test s.tag == "v1"
        end

        @testset "unknown type with explicit default" begin
            s = TestUnknownTypeStruct()
            @test s.custom.v == 0
        end

        @testset "JSON round-trip with @discord_struct" begin
            s = TestJSONStruct(name="hello", count=5, active=true)
            json_str = JSON3.write(s)
            s2 = JSON3.read(json_str, TestJSONStruct)
            @test s2.name == "hello"
            @test s2.count == 5
            @test s2.active == true
            @test ismissing(s2.tag)
        end

        @testset "Float32 and Int32 defaults" begin
            s = TestSmallNumStruct()
            @test s.x == Float32(0.0)
            @test s.y == Int32(0)
        end
    end

    @testset "@discord_flags" begin

        @testset "basic flag creation" begin
            @test FLAG_A.value == 1
            @test FLAG_B.value == 2
            @test FLAG_C.value == 4
        end

        @testset "zero and iszero" begin
            z = zero(TestFlagsZero)
            @test iszero(z)
            @test z.value == 0
        end

        @testset "bitwise OR" begin
            combined = TFO_A | TFO_B
            @test combined.value == 3
            @test has_flag(combined, TFO_A)
            @test has_flag(combined, TFO_B)
        end

        @testset "bitwise AND" begin
            ab = TFA_A | TFA_B
            bc = TFA_B | TFA_C
            result = ab & bc
            @test has_flag(result, TFA_B)
            @test !has_flag(result, TFA_A)
            @test !has_flag(result, TFA_C)
        end

        @testset "bitwise XOR" begin
            ab = TFX_A | TFX_B
            result = xor(ab, TFX_A)
            @test !has_flag(result, TFX_A)
            @test has_flag(result, TFX_B)
        end

        @testset "bitwise NOT" begin
            inv = ~TFN_A
            @test !iszero(inv)
            @test inv.value == ~UInt64(1)
        end

        @testset "equality and hashing" begin
            @test TFE_A == TestFlagsEq(1)
            @test TFE_A != TFE_B
            @test hash(TFE_A) == hash(TestFlagsEq(1))
        end

        @testset "show representation" begin
            io = IOBuffer()
            show(io, TFS_X)
            @test String(take!(io)) == "TestFlagsShow(42)"
        end

        @testset "integer constructor" begin
            f = TestFlagsInt(5)
            @test f.value == UInt64(5)
        end

        @testset "large bit shifts" begin
            @test TFL_HIGH.value == UInt64(1) << 63
            @test !iszero(TFL_HIGH)
        end

        @testset "single flag" begin
            @test SINGLE.value == 1
            @test has_flag(SINGLE, SINGLE)
        end

        @testset "has_flag with zero" begin
            z = zero(TestFlagsHasZero)
            @test has_flag(TFHZ_A, z)   # every flag has the zero flag
            @test !has_flag(z, TFHZ_A)  # zero does not have any flag
        end
    end

    @testset "@_flags_structtypes_int" begin
        @test StructTypes.StructType(TestSTFlags) == StructTypes.CustomStruct()

        @testset "lower produces UInt64" begin
            @test StructTypes.lower(TST_A) == UInt64(1)
        end

        @testset "lowertype is UInt64" begin
            @test StructTypes.lowertype(TestSTFlags) == UInt64
        end

        @testset "construct from integer" begin
            f = StructTypes.construct(TestSTFlags, 2)
            @test f == TST_B
        end
    end

    @testset "@option" begin

        @testset "all valid types" begin
            for (sym, expected) in [
                (:String, ApplicationCommandOptionTypes.STRING),
                (:Integer, ApplicationCommandOptionTypes.INTEGER),
                (:Boolean, ApplicationCommandOptionTypes.BOOLEAN),
                (:User, ApplicationCommandOptionTypes.USER),
                (:Channel, ApplicationCommandOptionTypes.CHANNEL),
                (:Role, ApplicationCommandOptionTypes.ROLE),
                (:Mentionable, ApplicationCommandOptionTypes.MENTIONABLE),
                (:Number, ApplicationCommandOptionTypes.NUMBER),
                (:Attachment, ApplicationCommandOptionTypes.ATTACHMENT),
            ]
                opt = @eval @option $sym "test_name" "test_desc"
                @test opt["type"] == expected
                @test opt["name"] == "test_name"
                @test opt["description"] == "test_desc"
            end
        end

        @testset "invalid type throws error" begin
            @test_throws Exception @eval @option InvalidType "x" "y"
        end

        @testset "with keyword arguments" begin
            opt = @option String "query" "Search query" required=true
            @test opt["required"] == true

            opt2 = @option Integer "count" "Number" min_value=1 max_value=100
            @test opt2["min_value"] == 1
            @test opt2["max_value"] == 100
        end

        @testset "without any kwargs" begin
            opt = @option Boolean "flag" "A flag"
            @test opt["type"] == ApplicationCommandOptionTypes.BOOLEAN
            @test opt["name"] == "flag"
            @test opt["description"] == "A flag"
            @test !haskey(opt, "required")
        end

        @testset "inside a vector literal" begin
            opts = [
                @option String "name" "Your name" required=true
                @option Integer "age" "Your age"
            ]
            @test length(opts) == 2
            @test opts[1]["type"] == ApplicationCommandOptionTypes.STRING
            @test opts[1]["required"] == true
            @test opts[2]["type"] == ApplicationCommandOptionTypes.INTEGER
        end
    end

    @testset "@slash_command" begin

        @testset "3-arg form (name, desc, handler)" begin
            tree = CommandTree()
            mock_client = (; command_tree=tree)

            @slash_command mock_client "ping" "Ping command" function(ctx) end

            @test haskey(tree.commands, "ping")
            @test tree.commands["ping"].name == "ping"
            @test tree.commands["ping"].description == "Ping command"
        end

        @testset "4-arg form with options (name, desc, options, handler)" begin
            tree = CommandTree()
            mock_client = (; command_tree=tree)

            @slash_command mock_client "search" "Search for items" [
                @option String "query" "Search query" required=true
            ] function(ctx) end

            @test haskey(tree.commands, "search")
            cmd = tree.commands["search"]
            @test cmd.name == "search"
            @test length(cmd.options) == 1
            @test cmd.options[1]["name"] == "query"
        end

        @testset "too few args throws error" begin
            @test_throws Exception @eval @slash_command client "only_name"
        end

        @testset "too many args throws error" begin
            @test_throws Exception @eval @slash_command client a b c d e f
        end
    end

    @testset "@button_handler" begin
        tree = CommandTree()
        mock_client = (; command_tree=tree)

        @button_handler mock_client "btn_1" function(ctx) end
        @test haskey(tree.component_handlers, "btn_1")

        @testset "overwrites handler for same custom_id" begin
            called = Ref(false)
            @button_handler mock_client "btn_1" function(ctx) called[] = true end
            @test haskey(tree.component_handlers, "btn_1")
            tree.component_handlers["btn_1"](nothing)
            @test called[]
        end
    end

    @testset "@select_handler" begin
        tree = CommandTree()
        mock_client = (; command_tree=tree)

        @select_handler mock_client "sel_1" function(ctx) end
        @test haskey(tree.component_handlers, "sel_1")
    end

    @testset "@modal_handler" begin
        tree = CommandTree()
        mock_client = (; command_tree=tree)

        @modal_handler mock_client "modal_1" function(ctx) end
        @test haskey(tree.modal_handlers, "modal_1")
    end

    @testset "@autocomplete" begin
        tree = CommandTree()
        mock_client = (; command_tree=tree)

        @autocomplete mock_client "search" function(ctx) end
        @test haskey(tree.autocomplete_handlers, "search")
    end

    @testset "@on_message macro expansion" begin
        expr = @macroexpand @on_message client (c, msg) -> nothing
        @test expr isa Expr
        expr_str = string(expr)
        @test occursin("MessageCreate", expr_str)
    end

    @testset "@user_command" begin

        @testset "2-arg form (name, handler)" begin
            tree = CommandTree()
            mock_client = (; command_tree=tree)

            @user_command mock_client "User Info" function(ctx) end

            @test haskey(tree.commands, "User Info")
            cmd = tree.commands["User Info"]
            @test cmd.name == "User Info"
            @test cmd.type == ApplicationCommandTypes.USER
            @test cmd.description == ""
            @test isempty(cmd.options)
        end

        @testset "3-arg form with guild_id" begin
            tree = CommandTree()
            mock_client = (; command_tree=tree)

            @user_command mock_client 123456789 "Warn User" function(ctx) end

            @test haskey(tree.commands, "Warn User")
            cmd = tree.commands["Warn User"]
            @test cmd.type == ApplicationCommandTypes.USER
            @test cmd.guild_id == Snowflake(123456789)
        end

        @testset "drains pending checks" begin
            drain_pending_checks!()
            tree = CommandTree()
            mock_client = (; command_tree=tree)

            lock(_CHECKS_LOCK) do
                push!(_PENDING_CHECKS, ctx -> true)
            end

            @user_command mock_client "Check User" function(ctx) end

            cmd = tree.commands["Check User"]
            @test length(cmd.checks) == 1
            @test isempty(_PENDING_CHECKS)
        end

        @testset "invalid args throws error" begin
            tree = CommandTree()
            mock_client = (; command_tree=tree)
            @test_throws Exception @eval @user_command $mock_client
        end
    end

    @testset "@message_command" begin

        @testset "2-arg form (name, handler)" begin
            tree = CommandTree()
            mock_client = (; command_tree=tree)

            @message_command mock_client "Bookmark" function(ctx) end

            @test haskey(tree.commands, "Bookmark")
            cmd = tree.commands["Bookmark"]
            @test cmd.name == "Bookmark"
            @test cmd.type == ApplicationCommandTypes.MESSAGE
            @test cmd.description == ""
            @test isempty(cmd.options)
        end

        @testset "3-arg form with guild_id" begin
            tree = CommandTree()
            mock_client = (; command_tree=tree)

            @message_command mock_client 987654321 "Report" function(ctx) end

            @test haskey(tree.commands, "Report")
            cmd = tree.commands["Report"]
            @test cmd.type == ApplicationCommandTypes.MESSAGE
            @test cmd.guild_id == Snowflake(987654321)
        end

        @testset "drains pending checks" begin
            drain_pending_checks!()
            tree = CommandTree()
            mock_client = (; command_tree=tree)

            lock(_CHECKS_LOCK) do
                push!(_PENDING_CHECKS, ctx -> true)
                push!(_PENDING_CHECKS, ctx -> false)
            end

            @message_command mock_client "Pin Message" function(ctx) end

            cmd = tree.commands["Pin Message"]
            @test length(cmd.checks) == 2
            @test isempty(_PENDING_CHECKS)
        end
    end

    @testset "@on" begin
        expr = @macroexpand @on client ReadyEvent (c, e) -> nothing
        @test expr isa Expr
        expr_str = string(expr)
        @test occursin("ReadyEvent", expr_str)
    end

    @testset "@embed" begin
        e = @embed begin
            title("Test Title")
            description("Test Desc")
            color(:green)
            field("Field1", "Value1", inline=true)
            footer("Footer", icon="https://icon.png")
            timestamp()
        end

        @test e["title"] == "Test Title"
        @test e["description"] == "Test Desc"
        @test e["color"] == 0x57F287
        @test length(e["fields"]) == 1
        @test e["fields"][1]["name"] == "Field1"
        @test e["fields"][1]["inline"] == true
        @test e["footer"]["text"] == "Footer"
        @test e["footer"]["icon_url"] == "https://icon.png"
        @test haskey(e, "timestamp")
    end

    @testset "@group and @subcommand" begin
        struct MockClient <: Accord.AbstractClient
            command_tree::CommandTree
        end
        
        tree = CommandTree()
        mock_client = MockClient(tree)
        called = Ref(false)

        @group mock_client "admin" "Admin group" begin
            @subcommand "test" "Test sub" (ctx) -> (called[] = true)
        end

        @test haskey(tree.commands, "admin")
        cmd = tree.commands["admin"]
        @test length(cmd.options) == 1
        @test cmd.options[1]["name"] == "test"
        @test cmd.options[1]["type"] == 1 # SUB_COMMAND
        
        # Test routing via dispatch
        interaction = Interaction(
            id=Snowflake(1), application_id=Snowflake(100),
            type=InteractionTypes.APPLICATION_COMMAND,
            data=InteractionData(id=Snowflake(10), name="admin", options=[InteractionDataOption(name="test", type=1)]),
            token="tok", version=1
        )
        dispatch_interaction!(tree, mock_client, interaction)
        @test called[]
    end
end

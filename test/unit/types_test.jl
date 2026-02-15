@testitem "Types JSON round-trip" tags=[:fast] begin
    using Accord, JSON3

    @testset "User" begin
        json = """{"id":"123456789","username":"testuser","discriminator":"0","global_name":"Test User","avatar":"abc123","bot":false}"""
        user = JSON3.read(json, User)
        @test user.id == Snowflake(123456789)
        @test user.username == "testuser"
        @test user.global_name == "Test User"
        @test user.avatar == "abc123"
        @test user.bot == false

        # Re-serialize
        json2 = JSON3.write(user)
        user2 = JSON3.read(json2, User)
        @test user2.id == user.id
        @test user2.username == user.username
    end

    @testset "Role" begin
        json = """{"id":"111","name":"Admin","color":16711680,"hoist":true,"position":1,"permissions":"8","managed":false,"mentionable":true,"flags":0}"""
        role = JSON3.read(json, Role)
        @test role.id == Snowflake(111)
        @test role.name == "Admin"
        @test role.color == 16711680
        @test role.hoist == true
        @test role.permissions == "8"
    end

    @testset "Emoji" begin
        json = """{"id":"222","name":"custom_emoji","animated":true}"""
        emoji = JSON3.read(json, Emoji)
        @test emoji.id == Snowflake(222)
        @test emoji.name == "custom_emoji"
        @test emoji.animated == true
    end

    @testset "Channel" begin
        json = """{"id":"333","type":0,"guild_id":"444","name":"general","position":0}"""
        ch = JSON3.read(json, DiscordChannel)
        @test ch.id == Snowflake(333)
        @test ch.type == Accord.ChannelTypes.GUILD_TEXT
        @test ch.guild_id == Snowflake(444)
        @test ch.name == "general"
    end

    @testset "Member" begin
        json = """{"user":{"id":"555","username":"member1","avatar":null},"roles":["111","222"],"joined_at":"2023-01-01T00:00:00Z","flags":0}"""
        member = JSON3.read(json, Member)
        @test member.user.id == Snowflake(555)
        @test length(member.roles) == 2
        @test member.joined_at == "2023-01-01T00:00:00Z"
    end

    @testset "Message" begin
        json = """{
            "id":"666",
            "channel_id":"333",
            "author":{"id":"555","username":"sender","avatar":null},
            "content":"Hello, world!",
            "timestamp":"2023-06-15T12:00:00Z",
            "tts":false,
            "mention_everyone":false,
            "mentions":[],
            "mention_roles":[],
            "attachments":[],
            "embeds":[],
            "pinned":false,
            "type":0
        }"""
        msg = JSON3.read(json, Message)
        @test msg.id == Snowflake(666)
        @test msg.channel_id == Snowflake(333)
        @test msg.content == "Hello, world!"
        @test msg.type == Accord.MessageTypes.DEFAULT
    end

    @testset "Embed" begin
        json = """{"title":"Test Embed","description":"A test","color":65535,"fields":[{"name":"Field 1","value":"Value 1","inline":true}]}"""
        emb = JSON3.read(json, Embed)
        @test emb.title == "Test Embed"
        @test emb.description == "A test"
        @test emb.color == 65535
        @test length(emb.fields) == 1
        @test emb.fields[1].name == "Field 1"
        @test emb.fields[1].inline == true
    end

    @testset "Overwrite" begin
        json = """{"id":"777","type":0,"allow":"1024","deny":"0"}"""
        ow = JSON3.read(json, Overwrite)
        @test ow.id == Snowflake(777)
        @test ow.type == 0
        @test ow.allow == "1024"
    end

    @testset "Guild (minimal)" begin
        json = """{"id":"888","name":"Test Guild","icon":null,"splash":null,"discovery_splash":null}"""
        guild = JSON3.read(json, Guild)
        @test guild.id == Snowflake(888)
        @test guild.name == "Test Guild"
        @test isnothing(guild.icon)
    end

    @testset "UnavailableGuild" begin
        json = """{"id":"999","unavailable":true}"""
        ug = JSON3.read(json, UnavailableGuild)
        @test ug.id == Snowflake(999)
        @test ug.unavailable == true
    end

    @testset "VoiceState" begin
        json = """{"guild_id":"888","channel_id":"333","user_id":"555","session_id":"abc","deaf":false,"mute":false,"self_deaf":false,"self_mute":true,"self_video":false,"suppress":false,"request_to_speak_timestamp":null}"""
        vs = JSON3.read(json, VoiceState)
        @test vs.user_id == Snowflake(555)
        @test vs.self_mute == true
        @test vs.deaf == false
    end

    @testset "Attachment" begin
        json = """{"id":"1001","filename":"image.png","size":12345,"url":"https://cdn.example.com/image.png","proxy_url":"https://proxy.example.com/image.png"}"""
        att = JSON3.read(json, Attachment)
        @test att.id == Snowflake(1001)
        @test att.filename == "image.png"
        @test att.size == 12345
    end

    @testset "Sticker" begin
        json = """{"id":"2001","name":"wave","description":"A waving sticker","tags":"wave,hi","type":1,"format_type":1}"""
        sticker = JSON3.read(json, Sticker)
        @test sticker.id == Snowflake(2001)
        @test sticker.name == "wave"
        @test sticker.type == Accord.StickerTypes.STANDARD
    end

    @testset "StageInstance" begin
        json = """{"id":"3001","guild_id":"888","channel_id":"333","topic":"Music Session","privacy_level":2}"""
        si = JSON3.read(json, StageInstance)
        @test si.id == Snowflake(3001)
        @test si.topic == "Music Session"
    end

    @testset "GuildTemplate" begin
        json = """{
            "code":"abc123",
            "name":"Test Template",
            "description":"A test template",
            "usage_count":5,
            "creator_id":"999",
            "created_at":"2024-01-01T00:00:00+00:00",
            "updated_at":"2024-06-01T00:00:00+00:00",
            "source_guild_id":"888"
        }"""
        tmpl = JSON3.read(json, GuildTemplate)
        @test tmpl.code == "abc123"
        @test tmpl.name == "Test Template"
        @test tmpl.description == "A test template"
        @test tmpl.usage_count == 5
        @test tmpl.creator_id == Snowflake(999)
        @test tmpl.source_guild_id == Snowflake(888)

        # Round-trip
        json2 = JSON3.write(tmpl)
        tmpl2 = JSON3.read(json2, GuildTemplate)
        @test tmpl2.code == tmpl.code
        @test tmpl2.name == tmpl.name
        @test tmpl2.usage_count == tmpl.usage_count
    end

    @testset "GuildTemplate defaults" begin
        tmpl = GuildTemplate()
        @test tmpl.code == ""
        @test tmpl.name == ""
        @test ismissing(tmpl.description)
        @test tmpl.usage_count == 0
        @test ismissing(tmpl.creator)
        @test ismissing(tmpl.is_dirty)
    end
end

@testitem "State & Cache" tags=[:unit] begin
    using Accord
    using Accord: State, Store, CacheForever, CacheNever, CacheLRU, CacheTTL,
        update_state!, GuildCreate, GuildDelete, GuildMemberAdd, GuildMemberRemove,
        GuildMemberUpdate, ChannelCreate, ChannelDelete, ReadyEvent,
        Guild, DiscordChannel, User, Member, Role, Emoji, VoiceState,
        Snowflake, UnavailableGuild

    # ── Store Strategy Tests ─────────────────────────────────────────────────────

    @testset "Cache Strategies" begin

        @testset "CacheForever" begin
            store = Store{String}(CacheForever())
            store[Snowflake(1)] = "a"
            store[Snowflake(2)] = "b"
            
            @test get(store, Snowflake(1)) == "a"
            @test get(store, Snowflake(2)) == "b"
            @test length(store) == 2
            
            delete!(store, Snowflake(1))
            @test get(store, Snowflake(1)) === nothing
            @test length(store) == 1
        end

        @testset "CacheNever" begin
            store = Store{String}(CacheNever())
            store[Snowflake(1)] = "a"
            
            @test get(store, Snowflake(1)) === nothing
            @test length(store) == 0
        end

        @testset "CacheLRU" begin
            store = Store{String}(CacheLRU(2)) # Max size 2
            store[Snowflake(1)] = "a"
            store[Snowflake(2)] = "b"
            
            @test get(store, Snowflake(1)) == "a"
            @test get(store, Snowflake(2)) == "b"
            
            # Insert 3rd item, should evict LRU (1)
            store[Snowflake(3)] = "c"
            
            @test get(store, Snowflake(1)) === nothing # Evicted
            @test get(store, Snowflake(2)) == "b"
            @test get(store, Snowflake(3)) == "c"
            @test length(store) == 2
        end

        @testset "CacheTTL" begin
            store = Store{String}(CacheTTL(0.1)) # 100ms TTL
            store[Snowflake(1)] = "a"
            
            @test get(store, Snowflake(1)) == "a"
            
            sleep(0.15) # Wait for expiry
            
            @test get(store, Snowflake(1)) === nothing
            # Store cleans up on access, so length might update only after access
            @test length(store) == 0
        end
    end

    # ── State Update Tests ───────────────────────────────────────────────────────

    # Helpers to create minimal structs
    mock_user(id) = User(id=Snowflake(id), username="u$id", discriminator="0000")
    mock_member(uid) = Member(user=mock_user(uid), roles=[])
    mock_channel(id, gid) = DiscordChannel(id=Snowflake(id), guild_id=Snowflake(gid), type=0)
    mock_role(id) = Role(id=Snowflake(id), name="r$id", permissions="0", color=0, hoist=false, position=0, managed=false, mentionable=false)

    @testset "State Updates" begin
        
        @testset "ReadyEvent" begin
            state = State()
            user = mock_user(1)
            g1 = UnavailableGuild(id=Snowflake(100), unavailable=true)
            # ReadyEvent is a standard struct, so we use positional args
            # v, user, guilds, session_id, resume_url, shard, application
            ready = ReadyEvent(
                10, user, [g1], "s", "url", [0, 1], nothing
            )
            
            update_state!(state, ready)
            
            @test state.me.id == Snowflake(1)
            @test haskey(state.guilds, Snowflake(100))
            @test state.guilds[Snowflake(100)].unavailable == true
        end

        @testset "GuildCreate" begin
            state = State()
            gid = Snowflake(100)
            
            # Construct a rich Guild object
            g = Guild(
                id=gid, name="Test", owner_id=Snowflake(1),
                channels=[mock_channel(200, 100)],
                members=[mock_member(1)],
                roles=[mock_role(300)],
                emojis=[],
                threads=[],
                stickers=[]
            )
            
            update_state!(state, GuildCreate(g))
            
            # Guild cached?
            @test haskey(state.guilds, gid)
            @test state.guilds[gid].name == "Test"
            
            # Channel cached?
            @test haskey(state.channels, Snowflake(200))
            @test state.channels[Snowflake(200)].guild_id == gid
            
            # User & Member cached?
            @test haskey(state.users, Snowflake(1))
            @test haskey(state.members, gid)
            @test haskey(state.members[gid], Snowflake(1))
            
            # Role cached?
            @test haskey(state.roles, gid)
            @test haskey(state.roles[gid], Snowflake(300))
        end

        @testset "GuildDelete" begin
            state = State()
            gid = Snowflake(100)
            state.guilds[gid] = Guild(id=gid, name="Test")
            state.members[gid] = Store{Member}()
            
            evt = GuildDelete(UnavailableGuild(id=gid, unavailable=true))
            update_state!(state, evt)
            
            @test !haskey(state.guilds, gid)
            @test !haskey(state.members, gid)
        end

        @testset "GuildMemberAdd/Remove" begin
            state = State()
            gid = Snowflake(100)
            uid = Snowflake(1)
            
            # Add
            evt_add = GuildMemberAdd(mock_member(1), gid)
            update_state!(state, evt_add)
            
            @test haskey(state.users, uid)
            @test haskey(state.members[gid], uid)
            
            # Remove
            evt_rem = GuildMemberRemove(gid, mock_user(1))
            update_state!(state, evt_rem)
            
            @test !haskey(state.members[gid], uid)
            # User should remain in global user cache (might be in other guilds)
            @test haskey(state.users, uid)
        end

        @testset "GuildMemberUpdate" begin
            state = State()
            gid = Snowflake(100)
            uid = Snowflake(1)
            
            # Pre-populate
            m = mock_member(1)
            m.nick = "Old"
            store = Store{Member}()
            store[uid] = m
            state.members[gid] = store
            
            # Update
            u = mock_user(1)
            evt = GuildMemberUpdate(gid, [], u, "New", missing, missing, missing, missing, missing, missing, missing, missing)
            update_state!(state, evt)
            
            updated = state.members[gid][uid]
            @test updated.nick == "New"
            @test updated.user.id == uid
        end

        @testset "ChannelCreate/Delete" begin
            state = State()
            cid = Snowflake(200)
            gid = Snowflake(100)
            
            evt_create = ChannelCreate(mock_channel(200, 100))
            update_state!(state, evt_create)
            
            @test haskey(state.channels, cid)
            
            evt_delete = ChannelDelete(mock_channel(200, 100))
            update_state!(state, evt_delete)
            
            @test !haskey(state.channels, cid)
        end
    end
end

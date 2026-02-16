# Discord Gateway Opcodes
module GatewayOpcodes
    const DISPATCH              = 0
    const HEARTBEAT             = 1
    const IDENTIFY              = 2
    const PRESENCE_UPDATE       = 3
    const VOICE_STATE_UPDATE    = 4
    const RESUME                = 6
    const RECONNECT             = 7
    const REQUEST_GUILD_MEMBERS = 8
    const INVALID_SESSION       = 9
    const HELLO                 = 10
    const HEARTBEAT_ACK         = 11
end

# Discord Gateway Close Event Codes
module GatewayCloseCodes
    const UNKNOWN_ERROR         = 4000
    const UNKNOWN_OPCODE        = 4001
    const DECODE_ERROR          = 4002
    const NOT_AUTHENTICATED     = 4003
    const AUTHENTICATION_FAILED = 4004
    const ALREADY_AUTHENTICATED = 4005
    const INVALID_SEQ           = 4007
    const RATE_LIMITED          = 4008
    const SESSION_TIMED_OUT     = 4009
    const INVALID_SHARD         = 4010
    const SHARDING_REQUIRED     = 4011
    const INVALID_API_VERSION   = 4012
    const INVALID_INTENTS       = 4013
    const DISALLOWED_INTENTS    = 4014

    """Check if a close code allows reconnection.

    # Example
    ```julia
    GatewayCloseCodes.can_reconnect(4000)  # => true (unknown error)
    GatewayCloseCodes.can_reconnect(4004)  # => false (auth failed)
    ```
    """
    function can_reconnect(code::Integer)
        code ∉ (AUTHENTICATION_FAILED, INVALID_SHARD, SHARDING_REQUIRED,
                INVALID_API_VERSION, INVALID_INTENTS, DISALLOWED_INTENTS)
    end
end

# Voice Gateway Opcodes
module VoiceOpcodes
    const IDENTIFY            = 0
    const SELECT_PROTOCOL     = 1
    const READY               = 2
    const HEARTBEAT           = 3
    const SESSION_DESCRIPTION = 4
    const SPEAKING            = 5
    const HEARTBEAT_ACK       = 6
    const RESUME              = 7
    const HELLO               = 8
    const RESUMED             = 9
    const DAVE_MLS_EXTERNAL_SENDER = 10
    const DAVE_MLS_KEY_PACKAGE     = 11
    const DAVE_MLS_PROPOSALS       = 12
    const DAVE_MLS_COMMIT_WELCOME  = 13
    const DAVE_MLS_ANNOUNCE_COMMIT_TRANSITION = 14
    const DAVE_MLS_WELCOME         = 15
    const DAVE_MLS_INVALID_COMMIT_WELCOME     = 16
    const CLIENT_DISCONNECT   = 13
    const DAVE_PREPARE_TRANSITION    = 21
    const DAVE_EXECUTE_TRANSITION    = 22
    const DAVE_TRANSITION_READY      = 23
    const DAVE_PREPARE_EPOCH         = 24
end

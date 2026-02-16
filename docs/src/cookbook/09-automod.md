# Recipe 09 — Auto-Moderation

**Difficulty:** Intermediate
**What you will build:** Keyword filters, spam protection, mention limits, and alert channels using Discord's Auto-Moderation system.

**Prerequisites:** [Recipe 01](01-basic-bot.md), [Recipe 03](03-slash-commands.md)

---

## 1. How Auto-Moderation Works

!!! note "AutoMod Rule Limits"
    Discord limits guilds to:
    - **6 keyword rules** per guild (keyword filter + keyword preset combined)
    - **1 spam rule** per guild
    - **1 mention spam rule** per guild
    
    Plan your moderation strategy accordingly. Combine similar keywords into single rules rather than creating many small rules.

Discord's AutoMod system lets you create rules that automatically act on messages:

- **Trigger** — what to look for (keywords, spam, mention spam, presets)
- **Action** — what to do (block message, send alert, timeout user)
- **Exemptions** — roles/channels that bypass the rule

Your bot needs these [`Intents`](@ref):

```julia
client = Client(token;
    intents = IntentGuilds | IntentAutoModerationConfiguration | IntentAutoModerationExecution
)
```

## 2. Trigger Types

| Type | Constant | Description |
|------|----------|-------------|
| Keyword | `AutoModTriggerTypes.KEYWORD` (1) | Match custom keywords/regex |
| Spam | `AutoModTriggerTypes.SPAM` (3) | Generic spam detection |
| Keyword Preset | `AutoModTriggerTypes.KEYWORD_PRESET` (4) | Discord's built-in word lists |
| Mention Spam | `AutoModTriggerTypes.MENTION_SPAM` (5) | Too many mentions |
| Member Profile | `AutoModTriggerTypes.MEMBER_PROFILE` (6) | Profile content match |

## 3. Action Types

| Type | Constant | Description |
|------|----------|-------------|
| Block Message | `AutoModActionTypes.BLOCK_MESSAGE` (1) | Prevent the message from being sent |
| Send Alert | `AutoModActionTypes.SEND_ALERT_MESSAGE` (2) | Send alert to a channel |
| Timeout | `AutoModActionTypes.TIMEOUT` (3) | Timeout the user |

## 4. Creating a Keyword Filter

```julia
ALERT_CHANNEL = Snowflake(999999999999999999)

body = Dict(
    "name" => "Bad Words Filter",
    "event_type" => AutoModEventTypes.MESSAGE_SEND,
    "trigger_type" => AutoModTriggerTypes.KEYWORD,
    "trigger_metadata" => Dict(
        "keyword_filter" => ["badword1", "badword2", "*slur*"],
        "regex_patterns" => ["b[a@]d\\s*w[o0]rd"],  # regex support
        "allow_list" => ["badword1_but_ok"],          # exceptions
    ),
    "actions" => [
        Dict(
            "type" => AutoModActionTypes.BLOCK_MESSAGE,
            "metadata" => Dict(
                "custom_message" => "This message was blocked by AutoMod."
            )
        ),
        Dict(
            "type" => AutoModActionTypes.SEND_ALERT_MESSAGE,
            "metadata" => Dict(
                "channel_id" => string(ALERT_CHANNEL)
            )
        ),
    ],
    "enabled" => true,
    "exempt_roles" => [],     # roles that bypass this rule
    "exempt_channels" => [],  # channels that bypass this rule
)

rule = create_auto_moderation_rule(client.ratelimiter, guild_id;
    token=client.token, body=body)
@info "Created rule" name=rule.name id=rule.id
```

### Keyword Matching Patterns

| Pattern | Matches | Doesn't Match |
|---------|---------|---------------|
| `"test"` | "test", "testing" | "atest" |
| `"*test"` | "atest", "test" | "testa" |
| `"test*"` | "test", "testing" | "atest" |
| `"*test*"` | "atest", "testing", "atesting" | — |

## 5. Preset Keyword Lists

Discord provides built-in word lists:

```julia
body = Dict(
    "name" => "Content Filter",
    "event_type" => AutoModEventTypes.MESSAGE_SEND,
    "trigger_type" => AutoModTriggerTypes.KEYWORD_PRESET,
    "trigger_metadata" => Dict(
        "presets" => [
            AutoModKeywordPresetTypes.PROFANITY,       # 1
            AutoModKeywordPresetTypes.SEXUAL_CONTENT,   # 2
            AutoModKeywordPresetTypes.SLURS,            # 3
        ],
        "allow_list" => ["damn", "hell"],  # words to allow despite presets
    ),
    "actions" => [
        Dict("type" => AutoModActionTypes.BLOCK_MESSAGE),
    ],
    "enabled" => true,
)

create_auto_moderation_rule(client.ratelimiter, guild_id;
    token=client.token, body=body)
```

## 6. Mention Spam Protection

Block messages with excessive mentions:

```julia
body = Dict(
    "name" => "Mention Spam Protection",
    "event_type" => AutoModEventTypes.MESSAGE_SEND,
    "trigger_type" => AutoModTriggerTypes.MENTION_SPAM,
    "trigger_metadata" => Dict(
        "mention_total_limit" => 5,                    # max mentions per message
        "mention_raid_protection_enabled" => true,     # enable raid protection
    ),
    "actions" => [
        Dict("type" => AutoModActionTypes.BLOCK_MESSAGE),
        Dict(
            "type" => AutoModActionTypes.TIMEOUT,
            "metadata" => Dict(
                "duration_seconds" => 300  # 5 minute timeout
            )
        ),
    ],
    "enabled" => true,
)

create_auto_moderation_rule(client.ratelimiter, guild_id;
    token=client.token, body=body)
```

## 7. Listening for AutoMod Actions

When an [`AutoModRule`](@ref) triggers, you get an `AutoModerationActionExecution` event:

```julia
on(client, AutoModerationActionExecution) do c, event
    @info "AutoMod triggered" rule_id=event.rule_id user_id=event.user_id

    # event fields:
    #   guild_id, action, rule_id, rule_trigger_type, user_id
    #   channel_id, message_id, alert_system_message_id
    #   content, matched_keyword, matched_content

    if !ismissing(event.matched_keyword) && !ismissing(event.content)
        @warn "AutoMod match" keyword=event.matched_keyword content=event.content user=event.user_id
    end
end
```

### Custom Alert Embed

```julia
on(client, AutoModerationActionExecution) do c, event
    ALERT_CHANNEL = Snowflake(999999999999999999)

    matched = ismissing(event.matched_keyword) ? "N/A" : event.matched_keyword
    content = ismissing(event.content) ? "N/A" : event.content
    channel = ismissing(event.channel_id) ? "N/A" : "<#$(event.channel_id)>"

    e = embed(
        title="AutoMod Action",
        color=0xED4245,
        fields=[
            Dict("name" => "User", "value" => "<@$(event.user_id)>", "inline" => true),
            Dict("name" => "Channel", "value" => channel, "inline" => true),
            Dict("name" => "Rule ID", "value" => string(event.rule_id), "inline" => true),
            Dict("name" => "Matched Keyword", "value" => matched),
            Dict("name" => "Content", "value" => length(content) > 200 ? content[1:200] * "..." : content),
        ]
    )
    create_message(c, ALERT_CHANNEL; embeds=[e])
end
```

## 8. Managing Rules

### List All Rules

```julia
rules = list_auto_moderation_rules(client.ratelimiter, guild_id; token=client.token)
for rule in rules
    @info "Rule" name=rule.name id=rule.id enabled=rule.enabled trigger_type=rule.trigger_type
end
```

### Modify a Rule

```julia
modify_auto_moderation_rule(client.ratelimiter, guild_id, rule_id;
    token=client.token,
    body=Dict(
        "name" => "Updated Filter",
        "trigger_metadata" => Dict(
            "keyword_filter" => ["newbadword1", "newbadword2"],
        ),
    )
)
```

### Delete a Rule

```julia
delete_auto_moderation_rule(client.ratelimiter, guild_id, rule_id;
    token=client.token)
```

### Add Exempt Roles/Channels

```julia
modify_auto_moderation_rule(client.ratelimiter, guild_id, rule_id;
    token=client.token,
    body=Dict(
        "exempt_roles" => [string(mod_role_id), string(admin_role_id)],
        "exempt_channels" => [string(bot_testing_channel_id)],
    )
)
```

## 9. Slash Command for Managing AutoMod

```julia
options_automod = [
    command_option(
        type=ApplicationCommandOptionTypes.SUB_COMMAND,
        name="list",
        description="List all AutoMod rules"
    ),
    command_option(
        type=ApplicationCommandOptionTypes.SUB_COMMAND,
        name="toggle",
        description="Enable/disable a rule",
        options=[
            command_option(type=ApplicationCommandOptionTypes.STRING, name="rule_id", description="Rule ID", required=true),
            command_option(type=ApplicationCommandOptionTypes.BOOLEAN, name="enabled", description="Enable or disable", required=true),
        ]
    ),
]

@slash_command client "automod" "Manage auto-moderation" options_automod function(ctx)
    data = ctx.interaction.data
    ismissing(data) && return
    ismissing(data.options) && return

    sub = data.options[1]
    guild_id = ctx.interaction.guild_id

    if sub.name == "list"
        defer(ctx; ephemeral=true)
        rules = list_auto_moderation_rules(ctx.client.ratelimiter, guild_id; token=ctx.client.token)

        if isempty(rules)
            respond(ctx; content="No AutoMod rules configured.")
            return
        end

        fields = [
            Dict(
                "name" => "$(rule.name) ($(rule.enabled ? "ON" : "OFF"))",
                "value" => "ID: `$(rule.id)` | Trigger: $(rule.trigger_type)",
            )
            for rule in rules
        ]
        e = embed(title="AutoMod Rules", color=0x5865F2, fields=fields)
        respond(ctx; embeds=[e])

    elseif sub.name == "toggle"
        sub_opts = Dict{String, Any}()
        if !ismissing(sub.options)
            for opt in sub.options
                !ismissing(opt.value) && (sub_opts[opt.name] = opt.value)
            end
        end

        rule_id = Snowflake(sub_opts["rule_id"])
        enabled = sub_opts["enabled"]

        modify_auto_moderation_rule(ctx.client.ratelimiter, guild_id, rule_id;
            token=ctx.client.token, body=Dict("enabled" => enabled))

        respond(ctx; content="Rule `$rule_id` $(enabled ? "enabled" : "disabled").", ephemeral=true)
    end
end
```

---

**Next steps:** [Recipe 10 — Polls](10-polls.md) for Discord's native poll system, or [Recipe 11 — Architectural Patterns](11-architectural-patterns.md) for production structure.

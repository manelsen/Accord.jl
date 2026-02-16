# Recipe 13 — Deployment

**Difficulty:** Intermediate
**What you will build:** Production deployment with systemd, Docker, sysimages, and health checks.

**Prerequisites:** [Recipe 11](11-architectural-patterns.md)

---

## 1. Environment Management

### .env File

!!! warning "Token Exposure Risk"
    **Never commit tokens to version control.** Tokens are credentials that grant access to your bot. If exposed:
    - Malicious users could control your bot
    - Your bot could be used for spam/abuse
    - Discord may reset the token and ban the application
    
    Use environment variables or a `.env` file (in `.gitignore`), never hardcode tokens.

```bash
# .env — NEVER commit this file
DISCORD_TOKEN=Bot XXXXXXXXXXXXXXXXXXXXXXXXXX.XXXXXX.XXXXXXXXXXXXXXXXXXXXXXXX
OPENAI_API_KEY=sk-...
DATABASE_URL=sqlite:///data/bot.db
```

### .gitignore

```gitignore
.env
*.db
Manifest.toml
bot_sysimage.so
/data/
/logs/
```

### Loading in Julia

```julia
function load_env(path=".env")
    isfile(path) || return
    for line in eachline(path)
        stripped = strip(line)
        (isempty(stripped) || startswith(stripped, '#')) && continue
        eq_pos = findfirst('=', stripped)
        isnothing(eq_pos) && continue
        key = strip(stripped[1:eq_pos-1])
        value = strip(stripped[eq_pos+1:end])
        ENV[key] = value
    end
end
```

## 2. Systemd Service

### Service Unit File

```ini
# /etc/systemd/system/discord-bot.service
[Unit]
Description=Accord.jl Discord Bot
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=botuser
Group=botuser
WorkingDirectory=/opt/mybot
EnvironmentFile=/opt/mybot/.env
ExecStart=/usr/local/bin/julia --project=/opt/mybot --threads=4 /opt/mybot/bin/run.jl
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=discord-bot

# Security hardening
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/mybot/data /opt/mybot/logs
PrivateTmp=yes

[Install]
WantedBy=multi-user.target
```

### With Sysimage (Fast Startup)

```ini
ExecStart=/usr/local/bin/julia --sysimage=/opt/mybot/bot_sysimage.so --project=/opt/mybot --threads=4 /opt/mybot/bin/run.jl
```

### Managing the Service

```bash
sudo systemctl daemon-reload
sudo systemctl enable discord-bot
sudo systemctl start discord-bot
sudo systemctl status discord-bot
sudo journalctl -u discord-bot -f      # follow logs
sudo journalctl -u discord-bot --since "1 hour ago"
```

## 3. Docker

### Dockerfile

```dockerfile
# Multi-stage build for smaller image

# Stage 1: Build sysimage
FROM julia:1.11 AS builder

WORKDIR /app
COPY Project.toml Manifest.toml ./
RUN julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

COPY . .

# Optional: create sysimage for fast startup
RUN julia --project=. -e '
    using PackageCompiler
    create_sysimage(
        ["Accord", "HTTP", "JSON3"],
        sysimage_path="bot_sysimage.so",
        precompile_execution_file="precompile_script.jl",
    )
'

# Stage 2: Runtime
FROM julia:1.11-slim

# Install ffmpeg for voice support
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy project and sysimage
COPY --from=builder /app /app

# Create data directory
RUN mkdir -p /app/data /app/logs

# Run as non-root
RUN useradd -m botuser
USER botuser

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD julia -e 'exit(isfile("/app/data/healthcheck") && time() - mtime("/app/data/healthcheck") < 60 ? 0 : 1)'

ENTRYPOINT ["julia", "--sysimage=/app/bot_sysimage.so", "--project=/app", "--threads=4", "bin/run.jl"]
```

### Dockerfile (Simple, No Sysimage)

```dockerfile
FROM julia:1.11

RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY Project.toml Manifest.toml ./
RUN julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

COPY . .
RUN mkdir -p /app/data

ENTRYPOINT ["julia", "--project=/app", "--threads=4", "bin/run.jl"]
```

### docker-compose.yml

```yaml
version: "3.8"

services:
  bot:
    build: .
    env_file: .env
    restart: always
    volumes:
      - bot-data:/app/data
      - bot-logs:/app/logs
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  bot-data:
  bot-logs:
```

### Running

```bash
# Build and start
docker compose up -d --build

# View logs
docker compose logs -f bot

# Restart
docker compose restart bot

# Update
git pull
docker compose up -d --build
```

## 4. PackageCompiler Sysimage

!!! tip "Sysimage Creation for Faster Startup"
    PackageCompiler.jl can create a custom sysimage that pre-compiles Accord.jl and its dependencies. This reduces startup time from ~10 seconds to ~1 second — critical for production deployments where quick restarts matter.

Create a sysimage for near-instant startup (~1s vs ~10s):

```julia
# build_sysimage.jl
using PackageCompiler

create_sysimage(
    ["Accord", "HTTP", "JSON3"],
    sysimage_path="bot_sysimage.so",
    precompile_execution_file="precompile_script.jl",
)
```

```julia
# precompile_script.jl
using Accord

# Exercise the code paths that matter
client = [`Client`](@ref)("Bot fake"; intents=[`IntentGuilds`](@ref))
tree = [`CommandTree`](@ref)()

# Components
[`embed`](@ref)(title="T", color=0x5865F2)
[`button`](@ref)(label="B", custom_id="b")
[`action_row`](@ref)([[`button`](@ref)(label="X", custom_id="x")])
[`string_select`](@ref)(custom_id="s", options=[[`select_option`](@ref)(label="L", value="V")])
[`text_input`](@ref)(custom_id="ti", label="L")
[`command_option`](@ref)(type=3, name="n", description="d")

println("Precompilation complete")
```

Build:

```bash
julia --project=. build_sysimage.jl
```

## 5. Health Checks

### Simple File-Based Health Check

```julia
# In your bot, write a timestamp file periodically
@async begin
    while client.running
        write("data/healthcheck", string(time()))
        sleep(30)
    end
end
```

### HTTP Health Endpoint

```julia
import HTTP

function start_health_server(client; port=8080)
    @async HTTP.serve("0.0.0.0", port) do request
        if request.target == "/health"
            status = client.running ? 200 : 503
            body = JSON3.write(Dict(
                "status" => client.running ? "ok" : "down",
                "guilds" => length(client.state.guilds),
                "uptime_s" => round(Int, time() - start_time),
            ))
            return HTTP.Response(status, ["Content-Type" => "application/json"], body)
        end
        return HTTP.Response(404, "Not found")
    end
end

const start_time = time()

on(client, [`ReadyEvent`](@ref)) do c, event
    start_health_server(c)
    @info "Health endpoint running on :8080/health"
end
```

## 6. Log Rotation

### With systemd (automatic via journald)

```bash
# journald handles rotation automatically
# Configure limits in /etc/systemd/journald.conf:
# SystemMaxUse=500M
# MaxRetentionSec=30day
```

### Manual File Logging

```julia
using Logging, Dates

function setup_file_logging(path="logs/bot.log")
    mkpath(dirname(path))
    io = open(path, "a")
    logger = SimpleLogger(io, Logging.Info)
    global_logger(logger)
    return io
end

# Rotate daily
function rotate_logs(base_path="logs/bot.log")
    date_str = Dates.format(today(), "yyyy-mm-dd")
    archive = "logs/bot-$(date_str).log"
    isfile(base_path) && mv(base_path, archive; force=true)
end
```

## 7. Update Workflow

### Manual Deployment

```bash
# SSH into server
ssh botserver

# Pull latest code
cd /opt/mybot
git pull

# Update dependencies
julia --project=. -e 'using Pkg; Pkg.update(); Pkg.precompile()'

# Rebuild sysimage (optional, takes a few minutes)
julia --project=. build_sysimage.jl

# Restart
sudo systemctl restart discord-bot
sudo journalctl -u discord-bot -f  # watch for errors
```

### Docker Deployment

```bash
ssh botserver
cd /opt/mybot
git pull
docker compose up -d --build
docker compose logs -f bot
```

---

**Next steps:** [Recipe 14 — Troubleshooting](14-troubleshooting.md) for debugging common issues.

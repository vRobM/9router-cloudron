# 9Router

AI router and token saver for coding tools.

## What it does

9Router sits between your AI coding tools (Claude Code, Codex, Cursor, Cline, Copilot, and more) and 40+ AI providers (OpenAI, Anthropic, Google, DeepSeek, Groq, and more). It routes requests intelligently, saves tokens, and gives you a single dashboard to manage all your AI provider accounts.

### Key features

- **RTK Token Saver** — Automatically compresses tool_result content to save 20-40% of tokens on every request
- **Multi-provider routing** — Route requests across 40+ providers with format translation
- **3-tier fallback** — Subscription providers → Cheap providers → Free providers, tried in order
- **Multi-account round-robin** — Use multiple API keys per provider for higher rate limits
- **Quota tracking** — Monitor usage and costs across all providers in real time
- **MITM proxy** — Transparently intercept and route traffic from CLI tools without configuration
- **OpenAI-compatible API** — Drop-in replacement for any tool that speaks the OpenAI API format

## After installation

### 1. Open the dashboard

Visit `https://<your-domain>/dashboard` to access the 9Router web interface. The default password is `123456` — change it immediately in Profile settings.

### 2. Add your AI providers

Go to **Providers** and add your API keys for the services you use:

- **OpenAI** — Add your API key for GPT-4, GPT-4o, etc.
- **Anthropic** — Add your API key for Claude models
- **Google** — Add your Gemini API key
- **DeepSeek** — Add your DeepSeek API key for cost-effective routing
- **Groq** — Free tier available for fast inference

You can add multiple accounts per provider for round-robin load balancing.

### 3. Configure your coding tool

Point your AI coding tool to use 9Router as its API endpoint:

**Claude Code:**
```bash
export ANTHROPIC_BASE_URL=https://<your-domain>/v1
```

**Codex / OpenAI tools:**
```bash
export OPENAI_BASE_URL=https://<your-domain>/v1
```

**Cursor / Cline / Copilot:**
Set the API base URL to `https://<your-domain>/v1` in your tool's settings.

### 4. Set up fallback (optional)

In the dashboard, configure provider combos to automatically fall back between providers. For example:
- Primary: Anthropic (Claude) → Fallback: OpenAI (GPT-4) → Last resort: DeepSeek

### 5. Enable Token Saver (optional)

The RTK Token Saver compresses tool_result content automatically. Enable it in **Dashboard → Token Saver** to save 20-40% on token costs.

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `20128` | HTTP listen port |
| `INITIAL_PASSWORD` | `123456` | Default admin password (change after first login) |
| `JWT_SECRET` | auto-generated | Session cookie secret |
| `DATA_DIR` | `/app/data` | Persistent data directory |

## Data storage

All data (provider configs, API keys, usage logs) is stored in SQLite at `/app/data/db/data.sqlite` and is backed up automatically by Cloudron's localstorage addon.

## Links

- **Upstream:** https://github.com/decolua/9router
- **License:** MIT
- **Issues:** https://github.com/decolua/9router/issues

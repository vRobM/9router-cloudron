## 9Router is installed

**1. Open the dashboard** at `https://<your-app-domain>/dashboard`

Default password: `123456` — change it in Profile settings immediately.

**2. Add your AI providers**

Go to **Providers** and add API keys for:
- OpenAI
- Anthropic
- Google (Gemini)
- DeepSeek
- Groq
- And 40+ more supported providers

**3. Point your coding tools** to `https://<your-app-domain>/v1` as the API base URL:

**Claude Code:**
```bash
export ANTHROPIC_BASE_URL=https://<your-app-domain>/v1
```

**OpenAI-compatible tools (Cursor, Cline, etc.):**
```bash
export OPENAI_BASE_URL=https://<your-app-domain>/v1
```

**4. Enable Token Saver** in Dashboard → Token Saver to save 20-40% on tokens by compressing tool results.

See [full documentation](https://github.com/decolua/9router/blob/main/README.md) for advanced configuration.

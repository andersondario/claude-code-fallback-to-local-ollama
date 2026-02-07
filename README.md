# Claude Code + Ollama Fallback

Switch Claude Code between Anthropic API and a local Ollama instance when the API is down or you want to use local models.

## Prerequisites

- [Node.js](https://nodejs.org/) (for npm)
- [Ollama](https://ollama.com/) running on your network — you can run it on [CasaOS](https://casaos.zimaspace.com/), a Raspberry Pi, or any local server on your LAN
- [jq](https://jqlang.github.io/jq/) (optional, for better JSON handling)

## Installation

```bash
git clone https://github.com/yourusername/claude-code-fallback-to-local-ollama.git
cd claude-code-fallback-to-local-ollama
./install.sh
source ~/.zshrc
```

This will:
1. Install [claude-code-router](https://github.com/musistudio/claude-code-router) globally
2. Copy config to `~/.claude-code-router/config.json`
3. Install `claude-switch` script to `~/bin/`
4. Add `~/bin` to your PATH

## Configuration

### Set Your Ollama Host

After installing, replace `YOUR_OLLAMA_HOST` with the IP or hostname of your Ollama server in both:

- `~/.claude-code-router/config.json`
- `~/bin/claude-switch`

For example, if Ollama runs on `192.168.1.100`:

```bash
sed -i '' 's/YOUR_OLLAMA_HOST/192.168.1.100/g' ~/.claude-code-router/config.json ~/bin/claude-switch
```

### Config File Structure

The router configuration lives at `~/.claude-code-router/config.json` and defines two providers:

```jsonc
{
  "LOG": true,                   // Enable request logging
  "API_TIMEOUT_MS": 120000,      // Request timeout (120s) — increase for slow models
  "providers": [
    {
      "name": "anthropic",
      "api_base_url": "https://api.anthropic.com/v1/messages",
      "api_key": "$ANTHROPIC_API_KEY",   // Reads from your environment variable
      "models": ["claude-sonnet-4-20250514", "claude-opus-4-5-20250514"]
    },
    {
      "name": "ollama",
      "api_base_url": "http://YOUR_OLLAMA_HOST:11434/v1/chat/completions",
      "api_key": "ollama",               // Ollama doesn't need a real key
      "models": [
        "qwen3:32b", "qwen3:14b", "qwen3:8b",
        "qwen2.5-coder:32b", "qwen2.5-coder:14b", "qwen2.5-coder:7b",
        "deepseek-coder-v2:16b", "deepseek-coder-v2:lite",
        "deepseek-coder:33b", "deepseek-coder:6.7b",
        "codellama:34b", "codellama:13b", "codellama:7b",
        "starcoder2:15b", "starcoder2:7b", "starcoder2:3b",
        "codegemma:7b", "codegemma:2b",
        "granite-code:34b", "granite-code:20b", "granite-code:8b",
        "yi-coder:9b",
        "phi3:14b", "phi3:mini",
        "llama3.1:70b", "llama3.1:8b",
        "mistral:7b", "mixtral:8x7b"
      ]
    }
  ],
  "router": {
    "default": "anthropic,claude-sonnet-4-20250514"  // format: provider,model
  }
}
```

### Key Settings

| Field | Description |
|-------|-------------|
| `LOG` | Enables logging of routed requests. Set to `false` to disable. |
| `API_TIMEOUT_MS` | Timeout in milliseconds. Increase if large models take long to respond. |
| `providers[].api_key` | For Anthropic, uses `$ANTHROPIC_API_KEY` from your environment. For Ollama, any non-empty string works. |
| `providers[].models` | List of models the router will accept for each provider. You only need to list the models you have pulled in Ollama. |
| `router.default` | The provider and model used on startup, in `provider,model` format. |

### Customizing

- **Add/remove Ollama models** — Edit the `models` array under the `ollama` provider to match what you have pulled. Only listed models can be selected via `/model`.
- **Change the default model** — Update `router.default` to any `provider,model` combo (e.g. `"ollama,qwen3:32b"` to default to local).
- **Add another provider** — Add a new object to the `providers` array with its own `name`, `api_base_url`, `api_key`, and `models`. Any OpenAI-compatible API works (e.g. OpenRouter, LM Studio).

## Usage

### Quick Commands

```bash
# Check current status and test Ollama connectivity
claude-switch status

# Switch to local Ollama
claude-switch ollama

# Switch back to Anthropic API
claude-switch anthropic

# Test Ollama connectivity only
claude-switch test
```

### Using the Router

```bash
# Start Claude Code via router
ccr code

# Or activate router environment and run claude normally
eval "$(ccr activate)"
claude
```

### Switch Models Inside Claude Code

```
/model ollama,deepseek-coder-v2:latest
/model ollama,qwen2.5-coder:7b
/model anthropic,claude-sonnet-4-20250514
```

## Pulling Models

Pull coding models to your Ollama instance:

```bash
# Via API (from any machine)
curl -X POST http://YOUR_OLLAMA_IP:11434/api/pull -d '{"name": "qwen2.5-coder:7b"}'

# Or SSH to Ollama host
ollama pull qwen2.5-coder:7b
ollama pull deepseek-coder-v2
```

### Recommended Models

| Model | Size | VRAM | Notes |
|-------|------|------|-------|
| qwen2.5-coder:7b | 4GB | 5GB | Fast, good quality |
| qwen2.5-coder:14b | 9GB | 10GB | Better quality |
| qwen2.5-coder:32b | 18GB | 20GB | Best Qwen coder |
| deepseek-coder-v2 | 8GB | 10GB | Great for code |
| codellama:7b | 4GB | 5GB | Meta's code model |
| starcoder2:7b | 4GB | 5GB | Good alternative |

## Files

| File | Location | Purpose |
|------|----------|---------|
| `config.json` | `~/.claude-code-router/` | Router configuration |
| `claude-switch` | `~/bin/` | Switching script |

## Troubleshooting

### Ollama not reachable

```bash
# Test connectivity
curl http://YOUR_OLLAMA_IP:11434/api/tags

# Check if Ollama is running
docker ps | grep ollama
```

### Models not showing

```bash
# List installed models
curl http://YOUR_OLLAMA_IP:11434/api/tags | jq '.models[].name'
```

### Router not working

```bash
# Check if installed
which ccr

# Reinstall
npm install -g @musistudio/claude-code-router
```

## Links

- [Claude Code Router](https://github.com/musistudio/claude-code-router)
- [Ollama](https://ollama.com/)
- [Medium Article](https://medium.com/@luongnv89/run-claude-code-on-local-cloud-models-in-5-minutes-ollama-openrouter-llama-cpp-6dfeaee03cda)

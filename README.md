# Claude Code + Ollama Fallback

Switch Claude Code between Anthropic API and a local Ollama instance when the API is down or you want to use local models.

## Prerequisites

- [Node.js](https://nodejs.org/) (for npm)
- [Ollama](https://ollama.com/) running on your network — you can run it on [CasaOS](https://casaos.zimaspace.com/), a Raspberry Pi, or any local server on your LAN
- [jq](https://jqlang.github.io/jq/) (optional, for better JSON handling)
- **A GPU is strongly recommended.** CPU-only inference is very slow, even with small models. See [Hardware Notes](#hardware-notes) below.

## Installation

```bash
git clone https://github.com/andersondario/claude-code-fallback-to-local-ollama.git
cd claude-code-fallback-to-local-ollama
./install.sh
source ~/.zshrc
```

This will:
1. Install [claude-code-router](https://github.com/musistudio/claude-code-router) globally
2. Copy config and `strip-thinking` plugin to `~/.claude-code-router/`
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
  "transformers": [              // Custom transformer plugins
    {
      "path": "/absolute/path/to/.claude-code-router/plugins/strip-thinking.js"
    }
  ],
  "Providers": [
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
      "transformer": {
        "use": ["strip-thinking"]        // Required: strips thinking params local models don't support
      },
      "models": [
        "qwen2.5-coder:1.5b", "qwen2.5-coder:7b",
        "qwen2.5-coder:14b", "qwen2.5-coder:32b",
        "deepseek-coder-v2:16b", "deepseek-coder-v2:lite",
        "codellama:7b", "codellama:13b"
      ]
    }
  ],
  "Router": {
    "default": "anthropic,claude-sonnet-4-20250514"  // format: provider,model
  }
}
```

> **Important:** Config keys `Providers` and `Router` must be PascalCase (required by `ccr` v2.x). Lowercase keys will be silently ignored.

> **Important:** The `transformers[].path` must be an absolute path. The `install.sh` script handles this automatically, but if you edit the config manually, make sure to use the full path (not `~`).

### The `strip-thinking` Plugin

Claude Code sends "extended thinking" parameters with its API requests. Local models don't support this and will reject the request with an error like `"model does not support thinking"`. The included `strip-thinking` plugin removes these parameters before they reach Ollama.

### Key Settings

| Field | Description |
|-------|-------------|
| `LOG` | Enables logging of routed requests. Set to `false` to disable. |
| `API_TIMEOUT_MS` | Timeout in milliseconds. Increase if large models take long to respond. |
| `Providers[].api_key` | For Anthropic, uses `$ANTHROPIC_API_KEY` from your environment. For Ollama, any non-empty string works. |
| `Providers[].models` | List of models the router will accept for each provider. Only list models you have pulled in Ollama. |
| `Router.default` | The provider and model used on startup, in `provider,model` format. |

### Customizing

- **Add/remove Ollama models** — Edit the `models` array under the `ollama` provider to match what you have pulled. Only listed models can be selected via `/model`.
- **Change the default model** — Update `Router.default` to any `provider,model` combo (e.g. `"ollama,qwen2.5-coder:7b"` to default to local).
- **Add another provider** — Add a new object to the `Providers` array with its own `name`, `api_base_url`, `api_key`, and `models`. Any OpenAI-compatible API works (e.g. OpenRouter, LM Studio).

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

After switching, restart the router for changes to take effect:

```bash
ccr restart
```

### Using the Router

**You must start Claude Code through the router** — running `claude` directly bypasses it entirely.

```bash
# Start Claude Code via router
ccr code

# Or activate router environment and run claude normally
eval "$(ccr activate)"
claude
```

### Switch Models Inside Claude Code

```
/model ollama,qwen2.5-coder:7b
/model ollama,qwen2.5-coder:1.5b
/model anthropic,claude-sonnet-4-20250514
```

## Pulling Models

Pull coding models to your Ollama instance:

```bash
# Via API (from any machine)
curl -X POST http://YOUR_OLLAMA_HOST:11434/api/pull -d '{"name": "qwen2.5-coder:7b"}'

# Or SSH to Ollama host
ollama pull qwen2.5-coder:7b
```

### Recommended Models

| Model | Size | VRAM | Notes |
|-------|------|------|-------|
| qwen2.5-coder:1.5b | 1GB | 2GB | Fastest, lower quality. Good for CPU-only. |
| qwen2.5-coder:7b | 4GB | 5GB | Good balance of speed and quality |
| qwen2.5-coder:14b | 9GB | 10GB | Better quality |
| qwen2.5-coder:32b | 18GB | 20GB | Best Qwen coder |
| deepseek-coder-v2 | 8GB | 10GB | Great for code |
| codellama:7b | 4GB | 5GB | Meta's code model |

## Hardware Notes

Running LLMs locally requires significant compute power. A **GPU is strongly recommended** — CPU-only inference is very slow even for small models (1.5B).

| Setup | Performance | Notes |
|-------|-------------|-------|
| CPU only | Very slow | Minutes per response, not practical for interactive use |
| NVIDIA GPU (e.g. RTX 3060 12GB) | Good | Native CUDA support via standard Ollama |
| AMD GPU (RX 6600+, gfx900+) | Good | Requires Ollama ROCm build. Older AMD GPUs (RX 570/580, Polaris) are **not supported** by ROCm |
| Apple Silicon | Good | Ollama uses Metal acceleration natively |

## Files

| File | Location | Purpose |
|------|----------|---------|
| `config.json` | `~/.claude-code-router/` | Router configuration |
| `plugins/strip-thinking.js` | `~/.claude-code-router/plugins/` | Strips thinking params for local models |
| `claude-switch` | `~/bin/` | Switching script |

## Troubleshooting

### Ollama not reachable

```bash
# Test connectivity
curl http://YOUR_OLLAMA_HOST:11434/api/tags

# Check if Ollama is running
docker ps | grep ollama
```

### "Does not support thinking" error

Make sure the `strip-thinking` transformer is configured for the Ollama provider in your `config.json`. See [Config File Structure](#config-file-structure) above.

### Router ignoring config / still using Anthropic

1. Make sure config keys are PascalCase: `Providers` (not `providers`), `Router` (not `router`)
2. Restart the router after config changes: `ccr restart`
3. Start Claude Code through the router: `ccr code` (not `claude` directly)

### Check GPU usage in Ollama

```bash
# Shows size_vram > 0 if GPU is being used
curl http://YOUR_OLLAMA_HOST:11434/api/ps
```

### Models not showing

```bash
# List installed models
curl http://YOUR_OLLAMA_HOST:11434/api/tags | jq '.models[].name'
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

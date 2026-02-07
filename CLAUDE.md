# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A utility for switching Claude Code between the Anthropic API and a local Ollama instance. It wraps the [`@musistudio/claude-code-router`](https://github.com/musistudio/claude-code-router) npm package with a configuration file, a custom transformer plugin, and a bash switching script.

## Architecture

There is no build system or application code. The project consists of:

- **`config.json`** - Router configuration defining two providers (Anthropic and Ollama) with their endpoints, API keys, model lists, and transformer config. Gets installed to `~/.claude-code-router/config.json`.
- **`plugins/strip-thinking.js`** - Custom ccr transformer that strips `reasoning` and `thinking` parameters from requests before sending to Ollama (local models don't support Claude's extended thinking). Gets installed to `~/.claude-code-router/plugins/`.
- **`claude-switch`** - Bash CLI script that switches between providers by updating `config.json` (via `jq` or `sed` fallback). Installed to `~/bin/claude-switch`.
- **`install.sh`** - Setup script that installs `claude-code-router` globally via npm, copies config, plugin, and switch script to their target locations, resolves `$HOME` in config paths, and adds `~/bin` to PATH in `~/.zshrc`.

## Key Details

- Ollama host placeholder is `YOUR_OLLAMA_HOST` in both `claude-switch` and `config.json` -- users must edit these after install.
- The router config keys are PascalCase (`Providers`, `Router`) as required by `ccr` v2.x. Lowercase keys are silently ignored.
- The `transformers[].path` in config must be an absolute path -- Node.js `require()` doesn't expand `~` or `$HOME`. The install script handles this with `sed`.
- The `strip-thinking` transformer is essential for Ollama -- without it, requests fail with "does not support thinking".
- The router config default is `"anthropic,claude-sonnet-4-20250514"` (format: `provider,model`).
- Claude Code must be started via `ccr code` (not `claude` directly) for routing to work.
- After config changes, run `ccr restart` for them to take effect.
- The `claude-switch` script accepts aliases: `cloud`/`api` for anthropic, `local` for ollama. Default command (no args) is `status`.
- `jq` is optional -- the script falls back to `sed` for JSON manipulation when `jq` is unavailable.

## Installation

```bash
./install.sh
source ~/.zshrc
```

## Usage

```bash
claude-switch status      # Show current mode and test Ollama
claude-switch ollama      # Switch to local Ollama
claude-switch anthropic   # Switch to Anthropic API
claude-switch test        # Test Ollama connectivity only
ccr restart               # Apply config changes
```

Start Claude Code via router: `ccr code` or `eval "$(ccr activate)" && claude`

Switch models inside Claude Code: `/model ollama,qwen2.5-coder:7b`

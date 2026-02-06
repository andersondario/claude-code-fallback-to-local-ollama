# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A utility for switching Claude Code between the Anthropic API and a local Ollama instance. It wraps the [`@musistudio/claude-code-router`](https://github.com/musistudio/claude-code-router) npm package with a configuration file and a bash switching script.

## Architecture

There is no build system or application code. The project consists of:

- **`config.json`** - Router configuration defining two providers (Anthropic and Ollama) with their endpoints, API keys, and model lists. Gets installed to `~/.claude-code-router/config.json`.
- **`claude-switch`** - Bash CLI script that switches between providers by updating `config.json` (via `jq` or `sed` fallback) and managing environment variables (`ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN`). Installed to `~/bin/claude-switch`.
- **`install.sh`** - Setup script that installs `claude-code-router` globally via npm, copies config and switch script to their target locations, and adds `~/bin` to PATH in `~/.zshrc`.

## Key Details

- Ollama host placeholder is `YOUR_OLLAMA_HOST` in both `claude-switch` and `config.json` -- users must edit these after install.
- The router config default is `"anthropic,claude-sonnet-4-20250514"` (format: `provider,model`).
- `claude-switch` runs in the current shell but prints `export`/`unset` instructions for the user to apply manually (environment variable changes don't persist from the script).
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
```

Start Claude Code via router: `ccr code` or `eval "$(ccr activate)" && claude`

Switch models inside Claude Code: `/model ollama,qwen2.5-coder:7b`

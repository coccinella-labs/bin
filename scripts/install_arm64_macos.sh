#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() {
  printf '[install] %s\n' "$1"
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This installer is for macOS (Darwin) only." >&2
  exit 1
fi

if [[ "$(uname -m)" != "arm64" ]]; then
  echo "This installer targets Apple Silicon (arm64)." >&2
  echo "Current architecture: $(uname -m)" >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  log "Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew installation did not complete successfully." >&2
  exit 1
fi

log "Installing Erlang and Elixir with Homebrew..."
brew install erlang elixir

if ! command -v erl >/dev/null 2>&1; then
  log "erl command not found; attempting to fix Homebrew link..."
  brew link --overwrite erlang || true
fi

if ! command -v mix >/dev/null 2>&1; then
  echo "mix command not found after installation." >&2
  exit 1
fi

log "Using Elixir: $(elixir -v | head -n 1)"
log "Using Mix: $(mix -v | tail -n 1)"

cd "$ROOT_DIR"

log "Fetching project dependencies..."
mix deps.get

log "Running test suite..."
mix test

log "Done. Project is ready on arm64 macOS."

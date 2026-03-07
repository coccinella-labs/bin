#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

log() {
  printf '[pre-push] %s\n' "$1"
}

log "Validating GitHub Actions workflow YAML syntax"
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/ci-cd.yml"); puts "workflow YAML OK"'

log "Fetching dependencies"
mix deps.get

log "Compiling with warnings as errors"
mix compile --warnings-as-errors

log "Running tests"
mix test

log "All checks passed"

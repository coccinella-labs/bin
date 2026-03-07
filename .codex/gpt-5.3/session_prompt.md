# GPT-5.3 Project Session Prompt

Work in `/Users/niladri/Desktop/bin` on `pipeline_bin`.

## Priorities

1. Keep pipeline modules composable and test-driven.
2. Preserve registry-driven execution (`PipelineBin.Pipelines` + `PipelineBin.Runner`).
3. Keep ingestion adapters and execution logs stable.
4. Update `.codex/repro.json` and `README.md` when behavior changes.

## Quick verify

- `mix deps.get`
- `mix test`

## Environment note

If sandboxed `mix` fails with `:eperm` (Mix.PubSub TCP socket), rerun with elevated permissions.

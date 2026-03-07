# pipeline_bin Session Prompt

You are working in `/Users/niladri/Desktop/bin` on the `pipeline_bin` Elixir project.

## Session goals

- Preserve the existing pipeline architecture:
  - `PipelineBin.Pipeline` for step execution
  - `PipelineBin.Runner` for named pipeline execution
  - `PipelineBin.Pipelines` as the registry
- Keep pipelines modular under `lib/pipeline_bin/pipelines/`.
- Reuse `PipelineBin.Pipelines.StepHelpers` for common validation/normalization patterns.
- Keep file ingestion logic in `PipelineBin.Adapters.FileInput`.
- Keep step-level persistence in `PipelineBin.ExecutionLog`.

## Environment constraints

- Runtime baseline: Elixir `1.19.5`, Erlang/OTP `28.4`, `arm64`.
- In this environment, sandboxed `mix` can fail with `:eperm` due Mix.PubSub TCP socket usage.
- If `mix` fails in sandbox, rerun with elevated permissions.

## Verification checklist

1. Run `mix deps.get` if dependencies changed.
2. Run `mix test` after code changes.
3. Update `README.md` for user-facing behavior changes.
4. Update `.codex/repro.json` if runtime/setup/structure changes.

## Current pipelines

- `user_ingest`
- `order_ingest`

## Output expectations

- Keep modules small and composable.
- Prefer explicit step names and deterministic error tuples.
- Add focused ExUnit coverage for every new pipeline behavior.

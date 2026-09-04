<p align="center">
  <img src="https://raw.githubusercontent.com/basebin/bin/main/.github/assets/thumbnail.png" alt="bin" width="100%">
</p>

# pipeline_bin

A lightweight Elixir project to keep and run reusable data pipelines.

## License

- Apache-2.0 (`LICENSE`)
- Ethical use guidance: `ETHICAL_USE.md`
- Attribution notice: `NOTICE`

## Prerequisites

- Elixir `~> 1.16`
- Erlang/OTP compatible with your Elixir version

## Setup

```bash
mix deps.get
mix test
```

Pre-push CI parity check:

```bash
./scripts/check_before_push.sh
```

ARM64 macOS one-command setup:

```bash
./scripts/install_arm64_macos.sh
```

Version manager sync files:
- `.tool-versions` (asdf)
- `.mise.toml` (mise)

## CI/CD

- Workflow file: `.github/workflows/ci-cd.yml`
- CI runs on pull requests and pushes to `main` (compile + test).
- CD runs on tags matching `v*` and creates a GitHub Release after tests pass.

## Libraries

- `Broadway`: concurrent pipeline execution for row batches.
- `NimbleCSV`: robust CSV parsing (replaces manual split parsing).
- `Oban`: job worker support for scheduled/retryable pipeline runs.

## Security

- See `SECURITY.md` for reporting and hardening notes.
- Dynamic atom creation from user input is blocked:
  - pipeline names are resolved against registry keys
  - unknown JSON/CSV keys remain strings instead of becoming atoms

## Warning

- In sandboxed sessions, `mix` commands may fail with `:eperm` because Mix.PubSub opens a local TCP socket.
- If that happens, rerun `mix deps.get` / `mix test` with elevated permissions in the session.

## Notes

- Homebrew had a symlink conflict (`/opt/homebrew/bin/typer`) during Erlang setup; fixed with `brew link --overwrite erlang`.
- In this environment, `mix` commands require elevated permissions due sandbox TCP socket restrictions.

Evidence from this environment:

- `uname -a` showed `arm64`.
- Homebrew installed ARM bottles (for example `elixir--1.19.5.arm64_tahoe` and `erlang--28.4.arm64_tahoe`).

## FAQ

Q: `elixir -v` fails with `exec: erl: not found` after install.  
A: Erlang was not fully linked. Run `brew link --overwrite erlang`.

Q: `mix deps.get` or `mix test` fails with `failed to open a TCP socket` / `:eperm`.  
A: In sandboxed sessions, rerun `mix` commands with elevated permissions.

Q: `mix pipeline.run` crashes with JSON encoding error for tuple reasons.  
A: Fixed in `lib/mix/tasks/pipeline.run.ex` by serializing error reasons via `inspect/1` before JSON encoding.

Q: Broadway producer compilation fails with missing `:acknowledger` on `%Broadway.Message{}`.  
A: Fixed in `lib/pipeline_bin/broadway/runner/producer.ex` by setting `acknowledger: {Broadway.NoopAcknowledger, nil, nil}`.

Q: CSV pipeline runs return zero rows or treat the first data row as header after NimbleCSV migration.  
A: Fixed in `lib/pipeline_bin/csv.ex` by correctly unwrapping `{:ok, rows}` in `with` and parsing stream with `skip_headers: false`.

Q: Is untrusted input allowed to create atoms at runtime?  
A: No. `String.to_atom/1` was removed from user-controlled paths to prevent atom table exhaustion.

Bug handling rule:
- When a bug is found and fixed, add an entry to this FAQ with the symptom and exact fix.

## Run an example in IEx

```bash
iex -S mix
```

Then:

```elixir
registry = PipelineBin.Pipelines.registry()

input = %{
  external_id: "user-123",
  name: "  Ada    Lovelace ",
  email: " ADA@EXAMPLE.COM "
}

PipelineBin.Runner.run(registry, :user_ingest, input)
# => {:ok, %{external_id: "user-123", name: "Ada Lovelace", email: "ada@example.com", ingested_at: ...}}
```

## Run pipelines from files

```elixir
PipelineBin.Adapters.FileInput.run_file(
  PipelineBin.Pipelines.registry(),
  :order_ingest,
  "data/orders.csv",
  %{log_path: "var/pipeline_execution.log"}
)
```

`FileInput` supports:
- `.json`: object or array of objects
- `.csv`: header row + data rows

## CLI

Run pipelines from terminal:

```bash
mix pipeline.run user_ingest data/users.json --no-persist-logs
mix pipeline.run order_ingest data/orders.csv --log-path var/pipeline_execution.log
```

Broadway batch example from IEx:

```elixir
rows = [
  %{order_id: "ord-1", user_id: "usr-1", amount_cents: 2500, currency: "usd"},
  %{order_id: "ord-2", user_id: "usr-2", amount_cents: 0, currency: "usd"}
]

PipelineBin.Broadway.Runner.run_batch(
  PipelineBin.Pipelines.registry(),
  :order_ingest,
  rows,
  %{persist_logs?: false}
)
```

Oban worker enqueue example:

```elixir
%{"pipeline" => "user_ingest", "path" => "data/users.json"}
|> PipelineBin.Workers.RunPipelineWorker.new()
|> Oban.insert()
```

## Structure

- `lib/pipeline_bin/pipeline.ex`: Pipeline struct + execution engine
- `lib/pipeline_bin/runner.ex`: Named-pipeline registry runner
- `lib/pipeline_bin/pipelines.ex`: Pipeline registry
- `lib/pipeline_bin/pipelines/step_helpers.ex`: Reusable step builders
- `lib/pipeline_bin/pipelines/user_ingest.ex`: Example production-style pipeline
- `lib/pipeline_bin/pipelines/order_ingest.ex`: Order ingestion pipeline
- `lib/pipeline_bin/adapters/file_input.ex`: JSON/CSV adapter for batch pipeline runs
- `lib/pipeline_bin/csv.ex`: NimbleCSV parsing helpers
- `lib/pipeline_bin/broadway/runner.ex`: Broadway concurrent batch runner
- `lib/pipeline_bin/broadway/runner/producer.ex`: In-memory Broadway producer
- `lib/pipeline_bin/workers/run_pipeline_worker.ex`: Oban worker for file-based runs
- `lib/mix/tasks/pipeline.run.ex`: `mix` task to execute a pipeline over a file
- `lib/pipeline_bin/execution_log.ex`: Persistent step-level execution logs
- `lib/pipeline_bin.ex`: Public convenience API
- `SECURITY.md`: Security reporting and hardening guidance
- `LICENSE`: Apache-2.0 license
- `ETHICAL_USE.md`: Ethical use policy for organizations
- `NOTICE`: Apache-2.0 attribution notice
- `.github/pull_request_template.md`: PR checklist with ethics and security review gates
- `.github/workflows/ci-cd.yml`: GitHub Actions CI/CD pipeline
- `.vscode/settings.json`: Workspace editor defaults
- `.vscode/extensions.json`: Recommended VS Code extensions
- `.vscode/tasks.json`: VS Code task shortcuts for setup/test/pipeline runs
- `.tool-versions`: asdf version pins for Erlang/Elixir
- `.mise.toml`: mise version pins for Erlang/Elixir
- `.codex/gpt-5.3/profile.json`: GPT-5.3 session profile metadata
- `.codex/gpt-5.3/session_prompt.md`: GPT-5.3 reusable project prompt
- `scripts/install_arm64_macos.sh`: Apple Silicon installer/bootstrap script
- `scripts/check_before_push.sh`: Local pre-push CI parity checks (workflow YAML + compile + tests)
- `data/users.json`: Sample user input data
- `data/orders.csv`: Sample order input data
- `test/`: ExUnit tests for core behavior

# Security Notes

## Reporting

If you find a security issue, report it privately to the maintainers and avoid opening a public issue with exploit details.

## Current hardening in this repo

- Avoids dynamic atom creation from untrusted input:
  - Pipeline names are resolved through `PipelineBin.Pipelines.resolve_name/2`.
  - JSON/CSV keys are converted with `String.to_existing_atom/1` and otherwise kept as strings.
- File input accepts only `.json` and `.csv` extensions.
- Pipeline execution errors are serialized safely for CLI output.

## Operational recommendations

- Do not process untrusted files without size limits and external scanning.
- Route logs to protected storage; avoid logging raw sensitive payloads.
- Run scheduled jobs with least-privilege credentials.

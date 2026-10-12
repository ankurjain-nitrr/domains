# domains

Protobuf domain models and gRPC service definitions, one directory per domain (`<domain>/v1/*.proto`).
Built with `buf` (see `Makefile`, `buf.yaml`); generated code goes to `gen/` and is not committed.

## API design

- Follow the repo conventions in [docs/api-conventions.md](docs/api-conventions.md):
  `google.protobuf.Timestamp` for all times, `int64 page_size` / `string page_token` for lists,
  delete RPCs return the deleted resource, multi-field update RPCs take an `update_mask`, and field rules are
  protovalidate annotations, using the shared rules in `validation/v1/rules.proto`.
- For anything not covered there, follow the Google API Improvement Proposals: https://google.aip.dev/

## Checks

- `buf format -w`, `buf lint` and `buf build` must be clean before committing; CI (`.github/workflows/buf.yml`) checks all three on pushes to main and on pull requests.

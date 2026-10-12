# domains

Protobuf domain models and gRPC service definitions, one directory per domain (`<domain>/v1/*.proto`).
Built with `buf` (see `Makefile`, `buf.yaml`); generated code goes to `gen/` and is not committed.

## API design

- Follow the repo conventions in [docs/api-conventions.md](docs/api-conventions.md):
  `google.protobuf.Timestamp` for all times, `int64 page_size` / `string page_token` for lists,
  and delete RPCs return the deleted resource.
- For anything not covered there, follow the Google API Improvement Proposals: https://google.aip.dev/

## Checks

- `buf lint` and `buf build` must pass before committing.

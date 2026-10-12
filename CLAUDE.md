# domains

Protobuf domain models and gRPC service definitions, one directory per domain (`<domain>/v1/*.proto`).
Built with `buf` (see `Makefile`, `buf.yaml`); generated code goes to `gen/` and is not committed.

## API design

- Follow the repo conventions in [docs/api-conventions.md](docs/api-conventions.md):
  `google.protobuf.Timestamp` for all times, `int64 page_size` / `string page_token` for lists,
  delete RPCs return the deleted resource, multi-field update RPCs take an `update_mask`, and field rules are
  protovalidate annotations, using the shared rules in `validation/v1/rules.proto`.
- For anything not covered there, follow the Google API Improvement Proposals: https://google.aip.dev/
- api-linter expects: a resource's lifecycle enum nested in it as `State` (AIP-216); no `Create*` name on an RPC
  that doesn't take the resource (use a verb like `Generate`); "relative to" in `*_offset` Duration comments;
  file-level comments above `syntax`.

## Interoperability

All domains must interoperate through entities and ARNs, not through knowledge of each other's types.

- An entity is any resource a domain owns (`Product`, `Content`, `Brand`, `User`, ...). Its ARN is
  `tenant:entity_type:entity_id`, where `entity_type` is the resource's message name, e.g. `shop:Product:p_123`.
  Validate ARN fields with `(buf.validate.field).string.(validation.v1.entity_arn) = true`.
- Generic capabilities (likes, dislikes, follows, comments, feed, permissions) take an `entity_arn` and must accept
  any entity type. A like works on a `Product` exactly as on a social `Content` post. Never couple them to one
  domain: no `post_id` fields, no `LikeProduct` RPCs, no imports of another domain's resource messages.
- Use an ARN wherever a field can point at more than one entity type; use a plain `<entity>_id` only when the type
  is fixed (e.g. `user_id` of the acting user).
- Behavior specific to an entity type belongs to the domain that owns that entity, not to the generic capability.

## Checks

- Run `make check` before committing; it runs everything CI (`.github/workflows/buf.yml`) runs: `buf format`,
  `buf lint` (STANDARD + COMMENTS), Google `api-linter`, the `buf.lock` check, and generating and compiling Go and Java.
- Every message, field, enum, value, oneof, service and RPC needs a leading `//` comment (not trailing).
- `.api-linter.yaml` lists the AIP rules this repo deliberately doesn't follow, with reasons. For a one-off
  exception, disable the rule inline on the element with an `aip.dev/not-precedent` reason.
- `make check` generates with remote BSR plugins and can fail with `resource_exhausted`; retry after ~60s.
- To test protovalidate rules, use a scratch Go module requiring `buf.build/go/protovalidate` with
  `replace github.com/ankurjain-nitrr/domains/gen/proto/go => <repo>/gen/proto/go`, after `make generate`.
- Plugin versions are pinned in `buf.gen.yaml`; keep `build/go/go.mod` and `build/java/pom.xml` runtimes in step.

## Skills

- Skills come from https://github.com/ankurjain-nitrr/skills (enabled in `.claude/settings.json`). Run `/reflect:reflect` at the end of a session to save its learnings here.

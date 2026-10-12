# API Conventions

Conventions every proto in this repo must follow. Where this guide is silent, follow the
[Google API Improvement Proposals (AIP)](https://google.aip.dev/).

## Timestamps

Use `google.protobuf.Timestamp` for every point in time. Do not use `int64` epochs or `string`s.

```proto
import "google/protobuf/timestamp.proto";

message Comment {
  google.protobuf.Timestamp create_time = 5;
  google.protobuf.Timestamp update_time = 6;
}
```

- Applies to resource fields (`create_time`, `update_time`, `entry_time`, ...), request/response fields
  (e.g. token expiry), and shared types such as `commons.v1.TimeRange`.
- Timestamps are always UTC; never carry a time zone offset in a separate field.
- Name timestamp fields `<imperative verb>_time`: `create_time`, `update_time`, `delete_time`,
  `expire_time`, `moderate_time`. Do not use `created_at` / `updated_at` style names.
- Ranges over a timestamp field are named after it: `create_time_range` (type `commons.v1.TimeRange`).

Reference: [AIP-142 Time and duration](https://google.aip.dev/142).

## Pagination

List requests and responses use these exact fields and types:

```proto
message ListThingsRequest {
  // filters ...
  int64 page_size = N;   // max items to return; server applies a default and a cap
  string page_token = M; // opaque token from a previous response's next_page_token
}

message ListThingsResponse {
  repeated Thing things = 1;
  string next_page_token = 2; // empty when there are no more pages
}
```

- `page_size` is `int64`, never `int32` or `string`.
- `page_token` / `next_page_token` are `string` and opaque to clients.

Reference: [AIP-158 Pagination](https://google.aip.dev/158).

## Delete

Delete RPCs return the deleted resource, not a `bool success`. Failures are reported with gRPC
status codes (e.g. `NOT_FOUND`).

```proto
message DeleteBrandResponse {
  brand.v1.Brand brand = 1; // the deleted brand
}
```

The same applies to "undo"-style RPCs (`UndoLike`, `Unfollow`, ...): return the removed resource.

Reference: [AIP-135 Delete](https://google.aip.dev/135), [AIP-164 Soft delete](https://google.aip.dev/164).

## Update

Update RPCs on resources with several independently editable fields take a `google.protobuf.FieldMask`
so clients can send only the fields they changed.

```proto
import "google/protobuf/field_mask.proto";

message UpdateBrandRequest {
  brand.v1.Brand brand = 1;
  // fields to update; if omitted, all fields set in brand are updated (AIP-134)
  google.protobuf.FieldMask update_mask = 2;
}
```

- If `update_mask` is omitted, update every field that is set on the resource in the request.
- `update_mask` of `*` replaces the whole resource, clearing fields that are not set.
- Fields owned by a dedicated RPC (e.g. `User.roles` via `AssignRole`, bank account state via
  `MarkBankAccountAs*`) are not updatable through the mask; document this on the request.
- Enforce that with a CEL rule on `update_mask`, e.g. `!this.paths.exists(p, p in ['state', 'publish_time'])`, and
  keep `*` allowed; the server never writes those fields from Update, with or without a mask.
- Skip the mask when it adds nothing: resources with a single editable field (e.g. `Comment.content`),
  and resources that should not be updated at all (e.g. posted ledger entries).

Reference: [AIP-134 Update](https://google.aip.dev/134), [AIP-161 Field masks](https://google.aip.dev/161).

## Validation

Field rules are declared on the protos with [protovalidate](https://protovalidate.com/) annotations and enforced by
the protovalidate runtime (Go, Java, Python, C++, TypeScript), so every service checks the same rules. `buf lint`
compiles every rule and CEL expression, so a broken rule fails CI.

```proto
import "buf/validate/validate.proto";
import "validation/v1/rules.proto";

message BusinessEntity {
  string pan_number = 4 [
    (buf.validate.field).ignore = IGNORE_IF_ZERO_VALUE,
    (buf.validate.field).string.(validation.v1.pan) = true
  ];
}
```

### Where each kind of rule goes

| Rule | Put it on | Why |
|---|---|---|
| Format (pattern, email, PAN, range) | the resource field, with `ignore = IGNORE_IF_ZERO_VALUE` | applies wherever the resource appears, and partial updates that omit the field still pass |
| Enum must be a known value | the resource field: `enum.defined_only = true` | `UNSPECIFIED` stays allowed, so partial updates pass |
| Required at creation | the `Create*Request` resource field, as a CEL rule | the same resource in an update with a field mask may legitimately omit it |
| Required ids, filters, page sizes | the request field: `required = true`, `int64.gte = 0` | requests are never partial |
| Exactly one of a `oneof` | `option (buf.validate.oneof).required = true;` | for oneof members use `string.min_len = 1`, not `required` |
| Cross-field rules | `option (buf.validate.message).cel` on the message | only if it holds for partial payloads, e.g. guard with `this.x == ''` |

Create-time requirements, as CEL on the request's resource field:

```proto
message CreateBrandRequest {
  brand.v1.Brand brand = 1 [
    (buf.validate.field).required = true,
    (buf.validate.field).cel = {id: "brand.name", message: "name is required", expression: "this.name != ''"}
  ];
}
```

### Shared rules

`validation/v1/rules.proto` holds reusable string rules (protovalidate predefined rules) for identifiers used across
domains: `entity_arn`, `pan`, `gstin`, `cin`, `ifsc`, `pincode`, `aadhaar`, `din`, `phone_e164`, `calling_code`,
`http_url`. Use them as `(buf.validate.field).string.(validation.v1.<name>) = true`. Add a rule there instead of
repeating a pattern when a format is used in more than one place. The file is proto2, because predefined rules are
extensions. Extension numbers come from the private range 50000-99999 and must be unique per extended message.

### Rule ids

Every CEL rule has an `id` in the form `<resource>.<rule>` (e.g. `business_entity.gstin_matches_pan`). Clients can
match on it to map violations to form fields, so treat ids as part of the API and don't rename them.

### Rules defined at runtime

When rules are themselves data, e.g. catalog attributes defined per category, store them as `buf.validate.FieldRules`
rather than inventing a constraint schema (see `catalog.v1.AttributeConstraints`). Services enforce them by building
a descriptor at runtime whose field carries the stored rules as its `(buf.validate.field)` option, then running the
same protovalidate validator.

Reference: [protovalidate](https://protovalidate.com/), [predefined rules](https://protovalidate.com/schemas/predefined-rules/),
[AIP-203 Field behavior](https://google.aip.dev/203).

# API Conventions

Conventions every proto in this repo must follow. Where this guide is silent, follow the
[Google API Improvement Proposals (AIP)](https://google.aip.dev/).

## Timestamps

Use `google.protobuf.Timestamp` for every point in time. Do not use `int64` epochs or `string`s.

```proto
import "google/protobuf/timestamp.proto";

message Comment {
    google.protobuf.Timestamp created_at = 5;
    google.protobuf.Timestamp updated_at = 6;
}
```

- Applies to resource fields (`created_at`, `updated_at`, `entry_date`, ...), request/response fields
  (e.g. token expiry), and shared types such as `commons.v1.TimeRange`.
- Timestamps are always UTC; never carry a time zone offset in a separate field.

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

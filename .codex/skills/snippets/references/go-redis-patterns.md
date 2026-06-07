# Go Redis Patterns

> last_verified: 2025-06 | sdk: github.com/go-redis/redis/v8

## Table of Contents
- [SCAN Pattern](#scan-pattern)
- [List-to-Hash Migration](#list-to-hash-migration)

---

## SCAN Pattern

Iterate keys matching a pattern without blocking the server (unlike `KEYS`).

```go
import (
    "context"
    "github.com/go-redis/redis/v8"
)

func scanKeys(ctx context.Context, db *redis.Client, pattern string) []string {
    var keys []string
    var cursor uint64

    for {
        matchedKeys, nextCursor, err := db.Scan(ctx, cursor, pattern, 100).Result()
        if err != nil {
            break
        }
        keys = append(keys, matchedKeys...)
        cursor = nextCursor
        if cursor == 0 {
            break
        }
    }
    return keys
}
```

### Pitfalls
- `SCAN` with count=100 is a hint, not a guarantee — the server may return
  more or fewer keys per iteration.
- Always check `cursor == 0` to detect iteration completion.

---

## List-to-Hash Migration

Useful for consolidating multiple Redis List keys into a single Hash.

```go
func listToHash(ctx context.Context, db *redis.Client) {
    patterns := []string{
        "jobs:servers:history:*:processing",
        "jobs:servers:history:*:paused",
    }

    m := map[string]string{}
    for _, pattern := range patterns {
        for _, key := range scanKeys(ctx, db, pattern) {
            data, err := db.LRange(ctx, key, 0, -1).Result()
            if err != nil {
                continue
            }
            for _, value := range data {
                m[value] = "history"
            }
        }
    }

    db.HSet(ctx, "jobs:servers:history:temp:active", m)
}
```

### Pitfalls
- `LRange(key, 0, -1)` fetches all elements — safe for small lists, but
  for large lists consider paginating with `LLEN` + batched `LRANGE`.
- `HSet` with a map is atomic per call but not transactional across
  multiple calls. Use a pipeline or `MULTI/EXEC` if consistency matters.

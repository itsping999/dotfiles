---
name: snippets
description: >
  Curated, battle-tested code snippets for third-party API integrations and
  infrastructure patterns. Use when implementing payment gateways (Alipay,
  WeChat Pay, ABC Bank), cloud services (Aliyun OSS, DirectMail), messaging
  (WeChat Official Account templates), real-time communication (WebRTC),
  cryptography (RSA signing, 3DES-CBC), or Redis data migration patterns.
  Also use when the user asks to add, update, or review integration snippets.
  Load the relevant reference file for the domain being worked on.
---

# Snippets

Verified Go integration snippets with pitfalls documented. Each reference file
contains working code and a "Pitfalls" section for non-obvious gotchas.

## Reference Files

| Domain | File | Covers |
|--------|------|--------|
| Payment | [go-payment.md](references/go-payment.md) | Alipay (App/Page/Precreate), WeChat Pay V3 (H5/App/Native), ABC Bank (PKCS12 + GBK + SHA1withRSA) |
| Cloud | [go-aliyun.md](references/go-aliyun.md) | Aliyun OSS upload, DirectMail email sending |
| Messaging | [go-wechat-mp.md](references/go-wechat-mp.md) | WeChat Official Account template message with miniprogram link |
| Realtime | [go-webrtc.md](references/go-webrtc.md) | WebRTC DataChannel via gorilla/websocket signaling |
| Crypto | [go-crypto.md](references/go-crypto.md) | 3DES-CBC decryption, RSA2048 signing (PKCS1/PKCS8) |
| Data | [go-redis-patterns.md](references/go-redis-patterns.md) | SCAN pattern, List-to-Hash migration |

## Workflow

1. Identify the domain from the user's request.
2. Load only the relevant reference file — do not load all of them.
3. Adapt the snippet to the user's project: replace constants, wire up env vars,
   adjust error handling to match local conventions.
4. If the snippet involves a pitfall noted in the file, call it out explicitly
   when delivering the code.

## Adding New Snippets

When the user asks to add a new snippet (e.g. "把这个也加到 snippets 里"):

1. **Choose the target file**: pick an existing `references/go-*.md` if the domain
   matches (e.g. a new payment SDK goes into `go-payment.md`). Create a new
   `references/go-<domain>.md` only for a genuinely new domain.
2. **Follow the file structure**:
   - `> last_verified: YYYY-MM | sdk: <module>@<version>` metadata at the top.
   - `## Table of Contents` entry if the file has 3+ sections.
   - Code block with minimal, runnable snippet (no testing boilerplate).
   - `### Pitfalls` subsection with non-obvious gotchas.
3. **Update this SKILL.md**: add a row to the Reference Files table above.
4. **Sync**: run `bash ~/dotfiles/skills.sh` to push changes to `~/.codex/skills/`.

### Snippet Quality Bar

- Include only code that has been verified to compile and work against a real API
  or infra endpoint.
- Every snippet must have at least one Pitfall entry — if nothing is non-obvious,
  the snippet probably does not belong here.
- Prefer minimal snippets over complete programs. Strip boilerplate (test harness,
  unused imports, commented-out code).

## Maintenance

Each snippet carries `last_verified` and `sdk_version` metadata. When a snippet
is used, check whether the SDK version is still current. If stale, flag it
rather than silently using outdated API patterns.

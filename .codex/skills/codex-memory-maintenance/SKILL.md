---
name: codex-memory-maintenance
description: Maintain Codex memory safely by adding explicit ad-hoc notes, reviewing consolidation artifacts, and keeping durable memory self-contained without preserving obsolete source labels.
---

# Codex Memory Maintenance

Use this skill when the user asks to remember, forget, update, prune, consolidate, or inspect Codex memory.

## Rules

- Direct remember/update/forget requests are handled by adding one small note under `~/.codex/memories/extensions/ad_hoc/notes/`.
- Do not edit `MEMORY.md` or `memory_summary.md` directly for ad-hoc user requests.
- Keep durable facts self-contained: store the reusable conclusion, not only where it came from.
- Do not promote canceled categories, obsolete source labels, or source-bound organization into new memory.
- Never store secrets, tokens, cookies, phone numbers, channel IDs, private message text, or exact credential strings.
- Add dates for drift-prone facts such as live infrastructure, endpoint behavior, provider state, model availability, and subscriptions.

## Workflow

1. Read `~/.codex/memories/memory_summary.md` from the prompt context when available.
2. Search `~/.codex/memories/MEMORY.md` for task-relevant keywords with `rg`.
3. Open only the directly relevant memory spans or rollout summaries.
4. For explicit remember/update/forget requests, create one concise Markdown note in:

   ```text
   ~/.codex/memories/extensions/ad_hoc/notes/<YYYYMMDD-HHMM-short-slug>.md
   ```

5. For consolidation or pruning work, re-read exact current spans before patching generated artifacts; stale spans are a common failure mode.
6. If current artifacts already reflect the new evidence, report a no-op rather than forcing a content change.

## Note Format

```markdown
# <short title>

Date: YYYY-MM-DD

Instruction:
- <one durable instruction or correction>

Scope:
- <where it applies>

Reason:
- <why this belongs in durable memory>
```

## Output

Report:

- Files changed or skipped.
- Whether any memory update was only an ad-hoc note.
- Any facts that still need live verification.

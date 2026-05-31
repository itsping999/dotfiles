---
name: codex-provider-recovery
description: Repair local Codex session visibility after switching providers by backing up and normalizing provider metadata across SQLite and JSONL session stores.
---

# Codex Provider Recovery

Use this skill when the user says old Codex sessions disappeared after switching between providers, accounts, or model-provider names, or asks to unify existing sessions to the current provider.

## Inputs

- Target provider value, usually inferred from the currently active `~/.codex` state.
- Confirmation of the affected Codex home, defaulting to `~/.codex`.

Do not persist provider counts, session IDs, or backup paths into long-term memory; they are run-specific.

## Workflow

1. Inspect current provider values before editing:

   ```bash
   sqlite3 ~/.codex/state_5.sqlite "select model_provider, count(*) from threads group by model_provider;"
   rg -n '"model_provider"|"provider"' ~/.codex/session_index.jsonl ~/.codex/sessions ~/.codex/archived_sessions
   ```

2. Create a timestamped backup:

   ```bash
   backup="$HOME/.codex/backups/provider-migration-$(date +%Y%m%d-%H%M%S)"
   mkdir -p "$backup"
   cp ~/.codex/state_5.sqlite ~/.codex/session_index.jsonl "$backup"/
   rsync -a ~/.codex/sessions ~/.codex/archived_sessions "$backup"/
   ```

3. Normalize `threads.model_provider` in `~/.codex/state_5.sqlite` to the target provider.

4. Patch matching JSONL metadata in:

   - `~/.codex/session_index.jsonl`
   - `~/.codex/sessions`
   - `~/.codex/archived_sessions`

   Preserve all non-provider fields and file layout.

5. Verify:

   ```bash
   sqlite3 ~/.codex/state_5.sqlite "select model_provider, count(*) from threads group by model_provider;"
   sqlite3 ~/.codex/state_5.sqlite "pragma quick_check;"
   rg -n '"model_provider"' ~/.codex/session_index.jsonl ~/.codex/sessions ~/.codex/archived_sessions
   ```

## Safety

- Back up before changing SQLite or JSONL files.
- Patch SQLite and JSONL stores together; changing only one store leaves inconsistent session metadata.
- Do not delete session files while repairing provider metadata.
- Do not print private conversation content; inspect only metadata needed for the repair.

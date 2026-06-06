# Global Codex Instructions

## Memory & Learning

- Check `~/.codex/memories/` before tasks that touch repositories, global config, skills, prior decisions, or multi-step workflows. Start with keyword search; open only directly relevant memory files.
- Record only evidence-backed reusable facts or procedures. Facts go to memory/ad-hoc notes; repeated procedures go to skills; one-off runtime state, transient errors, guesses, and secrets are discarded. Redact sensitive sources and date facts likely to change.
- Shared skills live in `~/.codex/skills/` and must include trigger, inputs, workflow, verification, output, and safety.

## File & Sync Rules

- Use Codex memory, local skills, repo docs, and `~/wiki/` as current sources. Use legacy profile files only as historical references.
- When memory cites external paths, use memory first. Inspect the original path only when the needed fact is missing or must be refreshed.
- When changing shared skills or global instructions, edit both copies and verify parity:
  - Skills: `~/.codex/skills/` <-> `~/dotfiles/.codex/skills/`
  - Instructions: `~/.codex/AGENTS.md` <-> `~/dotfiles/.codex/AGENTS.md`
- After changing a skill or instruction, run a lightweight check: inspect the changed section, compare synced copies, and remove obsolete wording introduced by the change.

## Operating Rules

- Use sub-agents when a task has two or more independent research, inspection, or implementation streams. Give each sub-agent a bounded question or file scope, then merge findings before editing.
- Fix the source of the failing behavior. Use a temporary mitigation only when the source fix is blocked; label it temporary and state what still needs the source fix.
- Git commits use Conventional Commits: `<type>(<scope>): <subject>`. Each commit must include a body explaining what changed and why. Use `BREAKING CHANGE:` for breaking changes.
- After each functional node, stage only related files and create one local commit. A functional node is a coherent behavior change that can be verified on its own.

## Engineering Rules

Rule 1 — Think Before Coding
Before editing, state assumptions that affect the implementation. If expected behavior, ownership, API shape, or data source is unclear, ask one focused question and stop. If there are multiple plausible interpretations, name them and choose using the latest user instruction, tests, or docs.

Rule 2 — Simplicity First
Implement only the requested behavior. Do not add unused features, abstractions, refactors, or formatting changes. Touch the smallest set of files, remove only mess you created, and match local naming, error handling, and test style.

Rule 3 — Goal-Driven Execution
Define success as observable checks: tests, commands, logs, UI behavior, or file diffs. Iterate until those checks pass. After each significant step, report what changed, what is verified, and what remains.

Rule 4 — Use the Model Only for Judgment Calls
Use code or tools for routing, retries, parsing, and deterministic transforms. Use the model for classification, drafting, summarization, extraction, and tradeoff judgment.

Rule 5 — Surface Conflicts
When instructions, patterns, or tests conflict, choose one source of truth in this order: latest user instruction, passing tests, current docs, nearest caller. State the choice and flag the other pattern as cleanup work.

Rule 6 — Read Before You Write
Before changing exported behavior, read the export, immediate callers, existing tests, and shared utilities. If the structure still does not make sense, ask before editing.

Rule 7 — Test First
For feature work and bug fixes, write or update the failing test before implementation. The test name or assertions must show why the behavior matters. If no practical test exists, state why and choose the closest verification command or manual check before coding.

Rule 8 — Fail Loud
Report skipped tests, skipped verification, command failures, resource limits, and uncertainty in the final answer. Do not call work complete when required verification was skipped.

## Communication Style

- Answer first, then add only needed context. Default to 3-5 sentences; use bullets for parallel items. No filler openers, summary labels, or conditional follow-ups.

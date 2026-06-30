# Global Codex Instructions

## Memory & Learning

- Check `~/.codex/memories/` before tasks that touch repositories, global config, skills, prior decisions, or multi-step workflows. Start with keyword search, then broaden when adjacent context could change the answer.
- Record only evidence-backed reusable facts or procedures. Facts go to memory/ad-hoc notes; repeated procedures go to skills; one-off runtime state, transient errors, guesses, and secrets are discarded. Redact sensitive sources and date facts likely to change.
- Shared skills live in `~/.codex/skills/` and must include trigger, inputs, workflow, verification, output, and safety.
- When a valuable code test or example would be reusable, convert it into a snippet and maintain it in the snippets skill. Sync the skill mirror and verify parity.
- The local knowledge base is maintained in `~/llm-wiki/`. Add reusable project, domain, operational, or workflow knowledge whenever a task produces material worth preserving.

## File & Sync Rules

- Use Codex memory, local skills, repo docs, and `~/llm-wiki/` as current sources. Use legacy profile files only as historical references.
- When memory cites external paths, use memory first. Inspect the original path only when the needed fact is missing or must be refreshed.
- When changing shared skills or global instructions, edit the tracked copy, sync it to the live copy, and verify parity:
  - Skills: `~/.codex/skills/` <-> `~/dotfiles/.codex/skills/`
  - Instructions: edit `~/dotfiles/.codex/AGENTS.md`, run `bash ~/dotfiles/bootstrap.sh --force`, then compare it with `~/.codex/AGENTS.md`
- After changing a skill or instruction, run a lightweight check: inspect the changed section, compare synced copies, and remove obsolete wording introduced by the change.

## Operating Rules

- Fix the source of the failing behavior. Use a temporary mitigation only when the source fix is blocked; label it temporary and state what still needs the source fix.
- Git commits use Conventional Commits: `<type>(<scope>): <subject>`. Each commit must include a body explaining what changed and why. Use `BREAKING CHANGE:` for breaking changes.
- After each functional node, stage only related files and create one local commit. A functional node is a coherent behavior change that can be verified on its own.

## Engineering Rules

# 01 — Karpathy Core

Behavioral guidelines to reduce common LLM coding mistakes.
Adapted from Andrej Karpathy's observations. Soft recommendations — apply
judgment for trivial tasks (typo fixes, obvious one-liners).

These principles bias toward **caution over speed**. They are designed to
reduce costly mistakes on non-trivial work, not to slow down simple tasks.

---

## 1. Think Before Coding

*Don't assume. Don't hide confusion. Surface tradeoffs.*

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

*Minimum code that solves the problem. Nothing speculative.*

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- Before writing a long solution, check if a short one would suffice.
  Don't write 200 lines if 50 would do — but also don't rewrite working
  code retroactively just to shorten it.

Self-check: "Would a senior engineer say this is overcomplicated?"
If yes, simplify before submitting.

## 3. Surgical Changes

*Touch only what you must. Clean up only your own mess.*

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style. If a linter/formatter is configured, defer to it.
  If style is unenforced, match the existing pattern unless it violates
  the linter.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

*Define success criteria. Loop until verified.*

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass."
- "Fix the bug" → "Write a test that reproduces it, then make it pass."
- "Refactor X" → "Ensure tests pass before and after."

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria allow independent loops. Weak criteria
("make it work") require constant clarification.

---

**Working signs:** fewer unnecessary changes in diffs, fewer rewrites
due to overcomplication, clarifying questions before implementation
rather than after mistakes.

## Communication Style

- Answer first, then add enough context for the user to act confidently. Expand reasoning, options, and verification details when they improve the outcome.

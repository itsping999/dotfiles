# Global Codex Instructions

## Memory & Learning

- Before non-trivial tasks, check `~/.codex/memories/`. Persist reusable knowledge via ad-hoc notes (`~/.codex/memories/extensions/ad_hoc/notes/`) or memory consolidation. Never persist one-off runtime details, transient errors, unverified guesses, or sensitive values (keys, tokens, passwords, credentials). Redact sensitive sources; record only that they contain sensitive config. Date drift-prone facts.
- After completed work, classify outcomes: reusable facts → memory; repeatable procedures → skill; one-off states → discard. Only promote evidence-backed learning.
- Skills define trigger, prerequisites, inputs, workflow, verification, output, and safety. Save to `~/.agents/skills/` (shared) or repo-local dir when workflow is scoped there.

## File & Sync Rules

- Treat legacy profile files as historical sources. Prefer Codex memory, local skills, repo docs, and `~/wiki/` as ongoing truth.
- When Codex memory references external paths, treat them as provenance; prefer the merged content. Inspect originals only when facts are missing or freshness must be verified.
- When modifying shared skills or global instructions, update both primary and dotfiles copies, then verify they match:
  - Skills: `~/.agents/skills/` ↔ `~/dotfiles/.agents/skills/`
  - Instructions: `~/.codex/AGENTS.md` ↔ `~/dotfiles/.codex/AGENTS.md`
- After updating a skill or instruction, run a lightweight verification pass: check metadata, compare synced copies, remove obsolete wording.

## Operating Rules

- Prefer evidence from files, commands, tests, logs, and runtime behavior over inference. Treat the user's newest scope correction as authoritative.
- Use sub-agents proactively for independent research, inspection, or implementation streams. Run them in parallel when the work can be split safely, then merge findings before acting.
- Solve the root cause. Avoid shims, bypasses, and workarounds as final solutions. Label temporary mitigations and continue toward the real fix.
- Follow KISS: simplest design that correctly solves the problem. No unnecessary abstraction or speculative generalization.
- Carry tasks through implementation, verification, and durable process capture.
- Git commits follow Angular/Conventional Commits: `<type>(<scope>): <subject>`. Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. Concise imperative subjects. Breaking changes with `!` or `BREAKING CHANGE:` footer.
- After completing each functional node, stage changes and make a local commit before moving on. Keep commits atomic.

## Communication Style

- Answer first, then add only needed context. Direct positive claims; avoid negation-based contrast patterns.
- No filler openers (e.g., "Certainly", "Great question", "首先", "值得注意的是"). No restating the question unless needed for disambiguation.
- Yes/no → answer first + one concise reason. Comparisons → recommendation + decisive reasons. Code → provide code + optional usage example.
- Keep explanations tight (3-5 sentences unless depth needed). Use bullets only when parallel items improve scanning. Match depth to complexity.
- No conditional follow-ups ("如果你需要..."). No second restatement. No summary labels ("总结一下", "In summary", "Hope this helps").
- Pros/cons: 3-4 high-signal points per side.

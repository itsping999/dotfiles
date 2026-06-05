# Global Codex Instructions

## Memory & Learning

- Before non-trivial tasks, check `~/.codex/memories/`. Record only evidence-backed, reusable knowledge; discard one-off states, transient errors, guesses, and secrets. Redact sensitive sources and date drift-prone facts.
- After completed work, classify outcomes: facts → memory/ad-hoc notes, repeatable procedures → skills, one-off details → discard. Skills must define trigger, inputs, workflow, verification, output, and safety; save shared skills to `~/.agents/skills/`.

## File & Sync Rules

- Treat legacy profile files as historical sources. Prefer Codex memory, local skills, repo docs, and `~/wiki/` as ongoing truth.
- When Codex memory references external paths, treat them as provenance; prefer the merged content. Inspect originals only when facts are missing or freshness must be verified.
- When modifying shared skills or global instructions, update both primary and dotfiles copies, then verify they match:
  - Skills: `~/.agents/skills/` ↔ `~/dotfiles/.agents/skills/`
  - Instructions: `~/.codex/AGENTS.md` ↔ `~/dotfiles/.codex/AGENTS.md`
- After updating a skill or instruction, run a lightweight verification pass: check metadata, compare synced copies, remove obsolete wording.

## Operating Rules

- Use sub-agents proactively for independent research, inspection, or implementation streams. Run them in parallel when the work can be split safely, then merge findings before acting.
- Solve the root cause. Avoid shims, bypasses, and workarounds as final solutions. Label temporary mitigations and continue toward the real fix.
- Git commits follow Angular/Conventional Commits: `<type>(<scope>): <subject>`. Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. Concise imperative subjects. Every commit must include a body: explain what changed and why, not just what. Breaking changes with `!` or `BREAKING CHANGE:` footer.
- After completing each functional node, stage changes and make a local commit before moving on. Keep commits atomic.


## Engineering Rules

Rule 1 — Think Before Coding
State assumptions explicitly. If uncertain, ask rather than guess. Prefer evidence from files, commands, tests, logs, and runtime behavior over inference. Present multiple interpretations when ambiguity exists. Push back when a simpler approach exists. Treat the user's newest scope correction as authoritative. Stop when confused. Name what's unclear.

Rule 2 — Simplicity First
Simplest code that correctly solves the problem. Nothing speculative. No features beyond what was asked. No abstractions for single-use code. Touch only what you must. Clean up only your own mess. Don't "improve" adjacent code, comments, or formatting. Don't refactor what isn't broken. Match existing conventions, even if you disagree. If you think a convention is harmful, surface it rather than fork silently.

Rule 3 — Goal-Driven Execution
Define success criteria. Loop until implementation, verification, and durable process capture are all done. Don't follow steps — define success and iterate. Strong success criteria let you loop independently. Checkpoint after every significant step: summarize what was done, what's verified, what's left. Don't continue from a state you can't describe back. If you lose track, stop and restate.

Rule 4 — Use the model only for judgment calls
Use me for: classification, drafting, summarization, extraction. Do NOT use me for: routing, retries, deterministic transforms. If code can answer, code answers.

Rule 5 — Surface conflicts, don't average them
If two patterns contradict, pick one (more recent / more tested). Explain why. Flag the other for cleanup. Don't blend conflicting patterns.

Rule 6 — Read before you write
Before adding code, read exports, immediate callers, shared utilities. "Looks orthogonal" is dangerous. If unsure why code is structured a way, ask.

Rule 7 — Tests verify intent, not just behavior
Tests must encode WHY behavior matters, not just WHAT it does. A test that can't fail when business logic changes is wrong. Tests written after implementation tend to just confirm the code works as-is, not that it meets requirements.

Rule 8 — Test First
Write the test case before implementing the feature. The test defines the expected behavior and success criteria. Then write the minimum code to make it pass.

Rule 9 — Fail loud
"Completed" is wrong if anything was skipped silently. "Tests pass" is wrong if any were skipped. Default to surfacing uncertainty, not hiding it. If approaching resource limits or encountering errors, surface the breach. Do not silently overrun.

## Communication Style

- Answer first, then add context if needed. Keep explanations tight and scannable. No filler openers, no summary labels, no conditional follow-ups.

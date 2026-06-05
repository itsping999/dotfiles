---
name: project-agents-md
description: Create, update, audit, or maintain project AGENTS.md files for Codex or other coding agents. Use when the user asks to generate repo instructions, improve agent guidance, add nested AGENTS.md files, or verify existing AGENTS.md quality.
---

# Project AGENTS.md

Use this skill to create or update project-level `AGENTS.md` files.

## Goal

Produce concise, evidence-backed instructions that help agents work inside a specific repository:

- Where important code, docs, scripts, generated files, and risky areas live.
- Which commands verify tests, lint, format, typecheck, build, or smoke behavior.
- Which project conventions are not already obvious from config files.
- Which workflows, boundaries, and completion criteria matter for this repo.

Prefer a short root `AGENTS.md` plus nested `AGENTS.md` files for subprojects with different stacks or rules.

## Source Order

Inspect repository evidence before writing:

1. Existing `AGENTS.md` files, nearest first.
2. `README*`, `CONTRIBUTING*`, docs indexes, runbooks, and architecture notes.
3. Manifests and lock files: `package.json`, `pnpm-lock.yaml`, `go.mod`, `Cargo.toml`, `pyproject.toml`, `requirements*.txt`, `pom.xml`, `build.gradle*`, and similar.
4. `Makefile`, task runners, shell scripts, Docker/Compose files, deployment scripts, and CI workflows.
5. Source layout, test layout, generated-code markers, schema/migration directories, and configuration boundaries.

Use `rg` and `rg --files` for discovery. Verify command names and referenced paths from files, not memory.

## Writing Rules

- Keep only project-specific guidance.
- Reference existing docs instead of copying long procedures.
- Do not restate generic coding advice, global Codex behavior, or obvious formatter/linter rules.
- Do not include secrets, tokens, private credentials, cookie values, or exact sensitive runtime config.
- Prefer concrete paths and commands over abstract principles.
- Prefer focused package/module commands when the repo supports them; name when full-suite checks are required.
- If a command is expensive, flaky, environment-dependent, or requires credentials, say that plainly.
- Remove obsolete commands or paths only after verifying they are obsolete.
- Preserve user-authored intent unless it conflicts with current repository evidence.

## Recommended Shape

```markdown
# Agent Instructions

## Project Map
- `path/` - what agents need to know.

## Commands
| Task | Command |
| --- | --- |
| Test | `...` |
| Lint | `...` |
| Build | `...` |

## Workflow
- ...

## Conventions
- ...

## Verification
- ...

## Boundaries
- ...
```

Omit sections that do not add useful repo-specific information.

## Creation Workflow

1. State assumptions and success criteria briefly.
2. Inspect source files listed in Source Order.
3. Draft the shortest useful root `AGENTS.md`.
4. Add nested `AGENTS.md` files only when a subtree has distinct commands, stack, generated outputs, or ownership boundaries.
5. If updating an existing file, edit narrowly and keep valid instructions.
6. Verify all referenced commands, files, and directories exist.
7. Run lightweight validation available for the file type, such as Markdown lint, syntax checks, or simple grep/path checks.
8. Report changed files, verification performed, and any commands that were not run.

## Quality Checklist

- The file answers "what should an agent do differently in this repo?"
- Commands are copied from repo evidence or explicitly marked as inferred.
- Referenced paths exist or are intentionally future-facing and labeled.
- The file is short enough to be read during every task.
- It avoids duplicating README, CI, formatter, and linter details.
- It names completion checks and high-risk boundaries.
- Nested files do not conflict with the root file.

## Output

When finished, report:

- `AGENTS.md` files created or updated.
- Source evidence used.
- Verification commands run.
- Any unresolved repo-specific assumptions.

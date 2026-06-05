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
- Which source files are the single source of truth for registries, schemas, templates, generated sections, or metadata.
- Which repeatable contribution flows deserve step-by-step instructions because missing a step commonly breaks the repo.

Prefer a short root `AGENTS.md` plus nested `AGENTS.md` files for subprojects with different stacks or rules.

## Mandatory Code Understanding

Before creating or updating any project `AGENTS.md`, inspect and understand the actual project code. Reading only `README`, docs, existing `AGENTS.md`, package manifests, or CI files is insufficient.

At minimum, examine representative source files for the main runtime paths, entrypoints, module boundaries, tests, and any subsystem that the generated instructions will mention. Trace how important concepts are wired through code before describing them. If the repository is too large to inspect exhaustively, sample each major subsystem and state the coverage used.

## Source Order

Inspect repository evidence before writing:

1. Existing `AGENTS.md` files, nearest first.
2. `README*`, `CONTRIBUTING*`, docs indexes, runbooks, and architecture notes.
3. Manifests and lock files: `package.json`, `pnpm-lock.yaml`, `go.mod`, `Cargo.toml`, `pyproject.toml`, `requirements*.txt`, `pom.xml`, `build.gradle*`, and similar.
4. `Makefile`, task runners, shell scripts, Docker/Compose files, deployment scripts, and CI workflows.
5. Real source files: entrypoints, core modules, immediate callers, tests, generated-code markers, schema/migration directories, and configuration boundaries.
6. Registry files, plugin/integration declarations, manifests, code generators, template directories, and files with managed-section markers.
7. Issue, branch, PR, review, release, and contribution docs when the user wants workflow guidance.

Use `rg` and `rg --files` for discovery. Verify command names and referenced paths from files, not memory.

## What To Extract

Look for high-signal patterns like these:

- **Project purpose**: one short paragraph that orients future agents without replacing the README.
- **Architecture map**: a compact tree or bullets for the modules agents must understand before editing.
- **Single source of truth**: registries, manifests, schema files, config files, generated-section delimiters, and metadata owners.
- **Standard contribution flows**: concrete steps for adding integrations, commands, plugins, routes, migrations, generated assets, or tests.
- **Required fields and formats**: tables for class attributes, config keys, frontmatter fields, placeholder syntax, or file naming rules.
- **Variant matrix**: when different languages, package managers, output formats, or agent/tool integrations follow different rules.
- **Special cases**: components that intentionally override the standard path and need extra setup, teardown, merge, or post-processing.
- **Pitfalls**: short bullets for common mistakes that are easy for agents to make and costly to debug.
- **Human workflow**: branch names, PR review response rules, release gates, or comment etiquette only when the repo documents them.
- **Maintenance trigger**: a note saying the `AGENTS.md` should be updated when the documented workflow or integration changes.

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
- Prefer decision tables over prose when agents must choose between base classes, formats, commands, or workflows.
- Put examples next to rules when a wrong shape is plausible.
- Name the file that owns each rule when future agents must edit that file too.

## Recommended Shape

```markdown
# Agent Instructions

## Project Purpose
- ...

## Project Map
- `path/` - what agents need to know.

## Source Of Truth
| Concern | File/Directory | Notes |
| --- | --- | --- |
| ... | `...` | ... |

## Commands
| Task | Command |
| --- | --- |
| Test | `...` |
| Lint | `...` |
| Build | `...` |

## Common Workflows
### Add ...
1. ...

## Conventions
- ...

## Variants And Formats
| Variant | Format/Path | Notes |
| --- | --- | --- |
| ... | ... | ... |

## Verification
- ...

## Common Pitfalls
- ...

## Boundaries
- ...
```

Omit sections that do not add useful repo-specific information.

## Creation Workflow

1. State assumptions and success criteria briefly.
2. Inspect source files listed in Source Order, including real code paths and representative tests before drafting.
3. Identify the repo-specific rules future agents would otherwise miss: source-of-truth files, standard flows, variants, special cases, and pitfalls.
4. Draft the shortest useful root `AGENTS.md`.
5. Add nested `AGENTS.md` files only when a subtree has distinct commands, stack, generated outputs, or ownership boundaries.
6. If updating an existing file, edit narrowly and keep valid instructions.
7. Verify all referenced commands, files, and directories exist.
8. Run lightweight validation available for the file type, such as Markdown lint, syntax checks, or simple grep/path checks.
9. Report changed files, verification performed, and any commands that were not run.

## Quality Checklist

- The file answers "what should an agent do differently in this repo?"
- Commands are copied from repo evidence or explicitly marked as inferred.
- Claimed architecture, workflows, boundaries, and pitfalls are backed by inspected source code, not docs alone.
- Referenced paths exist or are intentionally future-facing and labeled.
- The file is short enough to be read during every task.
- It avoids duplicating README, CI, formatter, and linter details.
- It names completion checks and high-risk boundaries.
- Nested files do not conflict with the root file.
- Step-by-step workflows include every registration, generated file, context update, and test file that repo evidence requires.
- Format or placeholder differences are explicit when variants exist.
- Common pitfalls are actionable and tied to repo evidence.

## Output

When finished, report:

- `AGENTS.md` files created or updated.
- Source evidence used.
- Verification commands run.
- Any unresolved repo-specific assumptions.

# After Task: Project-Local Prose Style Review Skill

## Goal

Learn from `yzhao062/agent-style` and give the drmTMB team a compact writing
standard for README text, vignettes, pkgdown pages, after-task notes, release
notes, design docs, and manuscript-style prose.

## Implemented

- Added `.agents/skills/prose-style-review/SKILL.md`.
- Updated `AGENTS.md` with a writing-style section for the whole team.
- Updated `CLAUDE.md` so Claude Code sees the same prose expectations.
- Updated `docs/design/10-after-task-protocol.md` and
  `.agents/skills/after-task-audit/SKILL.md` so prose-heavy tasks trigger a
  prose-style pass before closing.
- Updated Pat, Rose, documentation-writer, and pkgdown-editor agent configs.

## Provenance

No files or text were copied from `yzhao062/agent-style`. The new skill is a
project-local adaptation of useful review principles: name the reader, lead
with purpose, use concrete claims, keep terms stable, support claims with
evidence, avoid over-bulleted prose, and make public docs recoverable for
users. `agent-style` is not a package dependency.

Sources consulted:

- `https://github.com/yzhao062/agent-style`
- `https://github.com/yzhao062/agent-style/blob/main/RULES.md`

## Files Changed

- `.agents/skills/prose-style-review/SKILL.md`
- `.agents/skills/after-task-audit/SKILL.md`
- `.codex/agents/user-tester.toml`
- `.codex/agents/systems-auditor.toml`
- `.codex/agents/documentation-writer.toml`
- `.codex/agents/pkgdown-editor.toml`
- `AGENTS.md`
- `CLAUDE.md`
- `docs/design/10-after-task-protocol.md`
- `docs/dev-log/check-log.md`

## Checks Run

- TOML parse check over `.codex/agents/*.toml`: passed.
- `git diff --check`: passed.
- Wording scans checked dependency wording, pkgdown role drift, and
  terminology drift around `skew` and `tau`.

No R tests were run because no R code, package metadata, namespace, compiled
code, tests, or likelihood files changed.

## Consistency Audit

- `AGENTS.md`, `CLAUDE.md`, the after-task protocol, the operational
  `after-task-audit` skill, and the new `prose-style-review` skill now all
  point in the same direction.
- Pat's concerns about `tau`, `coscale`, and error recoverability were added to
  the shared standard.
- Rose's concerns about provenance, dependency wording, and pkgdown role drift
  were resolved.

## What Did Not Go Smoothly

- The first pass added the prose gate to the design protocol but not to the
  operational `after-task-audit` skill. Rose caught this before close.
- The first pass listed `skew` too casually even though the GAMLSS naming design
  keeps `nu` as the canonical first shape parameter. The skill now treats
  `skew` as an interpretation or documented alias only.
- The first pass used a narrower dependency phrase. The wording now says
  "package dependency".

## Team Learning

- Pat should review prose standards, not just user tutorials, because she sees
  hidden jargon quickly.
- Rose should check whether a new process rule reaches the skills agents
  actually invoke.
- The writing standard should make docs clearer without turning every note into
  a long checklist; tiny prose-only tasks can use compact reports.

## Known Limitations

- This is not an automatic linter.
- The standard improves future writing only when agents remember to invoke the
  skill or when `after-task-audit` pulls it into the phase gate.

## Next Actions

- Use `prose-style-review` on the next equation-plus-R-syntax vignette update.
- Later, consider a lightweight script or phrase scan only if repeated prose
  problems remain visible after manual review.

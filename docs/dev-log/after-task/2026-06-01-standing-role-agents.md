# After-Task Report: Launchable agents for the seven standing-only roles

## Task goal

Complete the team mirror. After the first mirror, six standing review names were
already carried by job-function agents (Gauss, Curie, Rose, Grace, Jason, Pat),
but seven review-only perspectives (Ada, Boole, Noether, Darwin, Florence, Emmy,
Fisher) existed only as prose in `AGENTS.md` with no launchable agent in either
runtime. This task gives each of them a dedicated agent so the full standing-role
team is launchable from Codex and Claude Code alike.

## Files created or changed

- New, in both runtimes (7 pairs, verbatim-matched bodies):
  - `integration-reviewer` (Ada) — orchestration / cross-artifact consistency
  - `formula-reviewer` (Boole) — R API and formula grammar
  - `math-consistency-reviewer` (Noether) — equations vs syntax vs TMB code
  - `audience-reviewer` (Darwin) — ecology/evolution reader fit
  - `figure-reviewer` (Florence) — figure quality and honest uncertainty
  - `architecture-reviewer` (Emmy) — S3 methods, extractors, internal APIs
  - `inference-reviewer` (Fisher) — simulations, comparators, profiles, identifiability
  - Files: `.codex/agents/<name>.toml` and `.claude/agents/<name>.md`.
- Edited: `AGENTS.md` and `CLAUDE.md` — updated the mirror note (all standing
  names now launchable) and fixed the stale `literature_curator`/Curie mapping
  to `simulation_tester`/Curie.

## Mapping decisions

- Bodies derived from the `AGENTS.md` standing-roles table (each role's "primary
  question"), in the same style as the existing agents: numbered checks, a "do
  not implement unless asked" guard for reviewers, and a fixed return shape
  (P0–P3 for code reviewers; blocking/friction/polish for the audience reviewer).
- `model`: high-reasoning reviewers → `opus`; the two reader/figure perspectives
  (Darwin, Florence) → `sonnet`.
- `tools`: read-only (`Read, Grep, Glob`) for pure reviewers; `Bash` added for
  the agents that need to run things (Ada checks git state; Florence renders;
  Fisher runs simulations/profiles).

## Checks run and exact outcomes

- `ls .codex/agents | wc -l` and `ls .claude/agents | wc -l` → 17 each (parity).
- Per-pair body diff (codex TOML `developer_instructions` vs `.claude` md body)
  → identical for all 7 new pairs.
- `rg -n '^(name|description|model|tools):' .claude/agents/{new}.md` → valid
  frontmatter on every new file.
- Terminology scan `rg -n "\btau\b|meta_gaussian|rho ~" .codex/agents .claude/agents`
  → clean; `rho12`/`sigma` used where referenced.
- `git status` → only intended new/edited files; no R/src/tests changes.
- R toolchain absent in this web container; `devtools::*` not run. This change is
  developer tooling and touches no R or C++ code.

## What did not go smoothly

While updating the mirror note, found that the merged `CLAUDE.md` still mapped
`literature_curator` to Curie (pre-resolution wording). Corrected here so the
Curie binding is consistent across `AGENTS.md`, `CLAUDE.md`, and the agent files.

## Team learning and process improvements

The standing-role table is now the single source the agent files must match. A
future check: when the table changes, both `.codex/agents/` and `.claude/agents/`
plus the `AGENTS.md`/`CLAUDE.md` mapping notes must be updated together.

## Known limitations and next actions

- The seven new agents are review perspectives; they are not wired to a
  workflow and run only when launched for a bounded task.
- The web-readiness SessionStart hook (separate follow-up) is pending explicit
  owner authorization because it is an auto-running mechanism.

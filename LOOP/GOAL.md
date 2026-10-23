# GOAL — dinnage-2 (IMMUTABLE — re-read at the top of EVERY arc)
Read this first, every cycle. Auto-compact eats messages, not this file. Unsure after a compaction?
Re-read THIS, then checkpoint.md, then continue.
## Mission
On branch `claude/audit-dinnage-wave1-20260913` (draft PR #1361), land the four owed Dinnage-audit items as
surgical commits: M1 (eleven non-Bernoulli `mi()` quadrature sites weight the mixture, per-family
invariance test), M2 (`sigma()`/`predict()`/`residuals()`/`simulate()` report the soft-clamped scale),
S6 (design note 274, no code), S2 (design note 275 under D-252, then the exact
`drm_constant_residual_sigma()` fix if Fisher concurs), plus the S3 help page (log-scale MAP told
truthfully). Close with an after-task report, a Melissa plan-actual row, and a handover.
## Headline
M1 — the only audit finding that biases a point estimate through the likelihood; eleven sites still do.
## Invariants
One lane, this worktree only. Builders never run `devtools::document()` (Ada runs it once). No builder
recompiles `src/` while another runs `load_all` (M1b waits for M2). Every new test is shown RED on the
pre-fix code, with the output saved. Every diff gets a fresh-context Opus (Fisher) review before it counts.
Only the orchestrator writes NEWS.md. ≤5 live sub-agents; scouts spawn nothing. No message to Russell.
## Authoritative WHAT
-> ultra-plan.md (slice table, briefs, decisions locked). This file wins on "what must never be lost".
## Definition of done
All `.unlazy/dinnage-2` leaf gates green under `--reverify`; `R CMD check --as-cran` on a clean export
0 errors; branch pushed to PR #1361; after-task + plan-actual + handover written; vault D-entries for
S3 (= document) and M4 (= confirm) and AGENT_LOG appended.
## Pre-authorisation
Scoped edits in this worktree; load_all/test/document; one TMB recompile; as-cran on a clean export; local
commits; push of this branch to the existing draft PR; status comments on our own issues #1307, #1308,
#1312, #1315, #1301 drafted to files first.
## Must stop for
Merge; release; any public claim beyond those comments; a campaign or run >30 min other than the package
check; M1 algebra at a site that differs from the template; a Fisher REJECT on M1b/M2/S2b that a bounded
repair does not clear.

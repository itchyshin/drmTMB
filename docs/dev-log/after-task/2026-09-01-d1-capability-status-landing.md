# After-task — D1: land the stranded R<->Julia capability-status board

**Lane:** `claude/rev-parity-d1-capability-status`, Claude, drmTMB reverse-parity ARC D.
**Base:** `origin/main` @ `27073059e`. Docs-only. Closes the substance of drmTMB#1079.

## What landed

`docs/design/capability-status.md` — drmTMB's half of the R<->Julia parity board —
now exists on a branch off `main`. It had existed only on two unmerged branches
since 2026-07-18, while DRM.jl's counterpart landed on its own `main` a month ago
and declares that it matches rows *by name* against a file no consumer of drmTMB's
`main` could see.

## The issue over-scoped the work, and that is worth recording

drmTMB#1079 step 1 asks which of `claude/capability-surface-aghq-parity` and
`codex/pr794-reconcile` carries the version to keep, since "they may have
diverged". They have not: `git diff` between the two refs for this path is
**empty** — the copies are byte-identical. So this was a pure cherry-pick, not a
reconciliation. Taken from `codex/pr794-reconcile` (the later ref) for provenance;
the choice is immaterial to content.

## The row-name verification (issue step 3) — the part that mattered

| | count |
|---|---:|
| rows in drmTMB's file | 42 |
| rows in DRM.jl's file | 46 |
| matched exactly | **42** |
| near-misses (case/punctuation/spacing only) | **0** |
| only in drmTMB | **0** |
| only in DRM.jl | 4 |

Every drmTMB row has an exact counterpart in the twin and nothing differs
cosmetically, so the mission-control join is sound. Three of the four DRM.jl-only
rows name Julia-side algorithm choices (`:em`, `:natgrad`, `lc_metric`) rather
than model capabilities, and correctly have no R counterpart.

**One finding for a human.** The fourth, `Non-Gaussian phylogenetic
location-scale (mu + log sigma)`, is a *model capability* the twin lists and this
board does not, and it is not resolvable as a naming difference. Whether drmTMB
implements it, rejects it by design, or has merely not projected it onto this
board is a model-surface-ledger question, out of scope here. Recorded, not
resolved; no status asserted.

## Verification

Docs-only; no code path touched, so no test or `R CMD check` was run — correct
scope for this slice. The row comparison was computed mechanically from both
files' markdown tables rather than read by eye, and its counts are reproducible
from the two refs named above.

## NOT claimed

**A documentation-landing task, not a capability promotion.** No row is promoted.
No parity claim is earned. No change to `inst/extdata/julia-capabilities.tsv`, the
model-surface ledger, or `docs/dev-log/coordination-board.md`. No release action —
D-164 holds drmTMB's CRAN submission; this is reversible package work, which D-164
explicitly still allows. DRM.jl was read only and not modified. Not merged to
`main`.

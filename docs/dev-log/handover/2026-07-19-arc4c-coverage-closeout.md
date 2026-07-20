# Session Handoff: Arc 4c three-family mu-slope coverage complete

Meta: 2026-07-19 · from Codex · evidence and promotion closeout

## Critical Context

Arc 4c certifies the ordinary independent `mu` random-slope SD profile interval
for skew-normal `mc-0464`, Tweedie `mc-0539`, and zero-one beta `mc-0575`.
Every cell promotes independently from `point_fit_recovery` to
`inference_ready_with_caveats`, retains `estimator=ML`, and has certified floor
M=16. This is not a `supported` claim and does not expand formula grammar,
families, or estimators.

## What Was Accomplished

- Merged PR-A #797 and its narrow R-library-order repair #798.
- Ran preflight, twelve N=1 smokes, mechanical selection, 1,320 Fir array tasks,
  and an independent `afterok` aggregation from clean source `46affaee`.
- Retained 13,200 exact attempts. Every non-exploratory cell had 1,200 finite
  profiles and met the frozen coverage gate at M=16, 32, and 64.
- Replayed all nine promoted family-by-M cells locally; profile endpoints agreed
  within `1.56e-10`.
- Completed fresh Fisher, Rose, and Noether D-43 reviews, ledger promotion,
  generated-surface regeneration, adjacent documentation repair, full package
  tests, package check, pkgdown check, and reconciliation.

## Statistical Result

| Cell | M=16 | M=32 | M=64 | Decision |
|---|---:|---:|---:|---|
| skew-normal `mc-0464` | 0.9275 | 0.9317 | 0.9575 | promote; floor 16 |
| Tweedie `mc-0539` | 0.9267 | 0.9425 | 0.9475 | promote; floor 16 |
| zero-one beta `mc-0575` | 0.9292 | 0.9400 | 0.9517 | promote; floor 16 |

Exact intervals, all-attempt denominators, smoke outcomes, family diagnostics,
checksums, and provenance are in
`docs/dev-log/simulation-artifacts/2026-07-19-arc4c-mu-slope-coverage/`.
Full shards and logs remain under the authenticated Fir `/project` run root.

## Decisions And Caveats

- Profile coverage is the frozen primary gate. The campaign makes no point-bias
  or Wald-coverage claim because duplicate TMB report names left those optional
  diagnostics missing. The prospective extractor is repaired and tested; the
  immutable campaign was not backfilled.
- D-43 was 3/3 PROMOTE for skew-normal and Tweedie. Zero-one beta received two
  PROMOTE and one WITHHOLD verdict, so it promotes under the frozen rule. Rare
  machine-exact ones from nominally interior beta draws remain an explicit
  caveat.
- Before claiming an exactly 15% observed-boundary zero-one-beta DGP, use a
  deterministic strictly-interior sampler and obtain new compute approval.
- O3/AGHQ, Cox-Reid expansion, supported-tier calibration, other SDs, other
  grids, and other random-effect structures remain separate future arcs.

## Verification Receipt

- Arc 4c focused tests: 245/245.
- Capability ledger: 30 generated outputs consistent; unittest 37/37.
- Full package tests: 39,466 passed, 0 failed, 0 errors, 62 established
  warnings, 24 skips.
- `devtools::check()`: 0 errors, 0 warnings, one existing report-only spelling
  transcript NOTE.
- Isolated worktree install plus full `pkgdown::build_site()`: all 33 articles,
  home, roadmap, NEWS, maps, and family references rendered; final problem and
  stale-text checks passed.
- Capability runtime: 18 verified routes, G0=G1=G2=0.
- Mission Control: `mission_control_ok`; `git diff --check`: clean.

## Current Working State

The Arc 4c evidence branch is `codex/arc4c-mu-slope-coverage-evidence`, based on
PR #799's merged documentation commit `1744b0a9`. It changes prose-only status
rows in six existing vignettes, but leaves every R chunk, `_pkgdown.yml`, all
33 article placements, and the reader-learning-path taxonomy unchanged. The
dirty root checkout on `claude/handover-freshness-0718` was never edited,
staged, or cleaned.

## Next Recommended Arc

Finish the reader-facing plotting surface as the next package-completion arc:
issue #58 / D2 already has a bounded design in
`docs/dev-log/handover/2026-07-19-claude-reader-docs-arc-handover.md`. The
existing gallery is substantial but demonstrates only one of six public plot
functions. Add examples for `plot_corpairs()`, `worm_plot()`, `qq_plot()`,
`centile_chart()`, and `plot.profile.drmTMB()` without adding a seventh helper
or restructuring the gallery. Keep the zero-one-beta strictly-interior rerun as
a separate narrow validation-debt gate.

## Resume

```sh
cd '/Users/z3437171/Dropbox/Github Local/drmTMB-wt-arc4c-evidence'
git fetch origin --prune
git status --short --branch
sed -n '1,220p' docs/dev-log/simulation-artifacts/2026-07-19-arc4c-mu-slope-coverage/README.md
sed -n '1,220p' docs/dev-log/after-task/2026-07-19-arc4c-mu-slope-coverage-promotion.md
```

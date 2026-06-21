# After Task: biv_q4_phylo_reml defended-partial (q4 phylo REML through the bridge)

**Date:** 2026-06-21 (autonomous; Ada orchestrating, session 5)
**Worktree:** `/Users/z3437171/.codex/worktrees/540b/drmTMB`, branch
`shannon/overnight-audit-gaps-20260619`.
**Lane:** Julia-via-R bridge (the cell) + a direct-DRM.jl recovery pilot (the
estimator the bridge forwards). No native-TMB claim, no interval-coverage / power /
release / CRAN claim.

## Goal

Advance the `biv_q4_phylo_reml` mission-control cell (one of the partial cells).
The honest ceiling is a DEFENDED PARTIAL: `covered` (engine-vs-engine parity) is
structurally impossible because native TMB rejects q4 phylo REML.

## Key reframe (owner's insight)

The DRM.jl #18 property is "REML >= ML on all four among-axis SDs." That inequality
is BRITTLE: it assumes ML is downward-biased, which fails on a weakly-identified
scale axis where ML can OVERSHOOT. A single poorly-conditioned draw (random
coalescent tree, p=16) had ML axis-4 SD = 7.1 vs true 0.4, and REML correctly
pulled it DOWN to 4.0 — REML < ML, yet closer to truth. The right diagnostic is
"closer to truth," not the inequality. The owner caught this; it reframed the whole
deliverable.

## What was done

- **Recovery pilot** (`docs/dev-log/simulation-artifacts/2026-06-21-q4-reml-recovery-pilot/`,
  seeded 40-rep direct-DRM.jl Monte Carlo + results.md): on the well-conditioned
  balanced-tree DGP, ML is downward-biased on all four among-axis SDs; REML is
  closer to truth on all four (REML MAE 0.127 vs ML 0.133; REML closer in 57-62% of
  draws). Labeled a PILOT, not a full calibration. `run.jl` prints per-axis
  Monte-Carlo SE + z so the bias significance is reproducible.
- **Live bridge q4 REML test** (`tests/testthat/test-julia-biv-q4-reml.R`, 10/10):
  engine='julia' REML=TRUE forwards faithfully (effective_REML, estimator 'REML'),
  ML+REML both converge, finite among-axis SDs, REML genuinely differs from ML, and
  Wald CIs for the Sigma_a targets are correctly unavailable at the singular q4
  boundary. Asserts faithful forwarding + honest status — NOT recovery, NOT the
  brittle inequality.
- **Registry frame correction** (`R/julia-bridge.R` biv_q4_phylo_reml claim_boundary
  + next_action): covered structurally impossible (native rejects q4 phylo REML);
  partial backed by the live test + the recovery pilot. Cell stays `partial`.
  Both capability TSVs regenerated.

## Verification

- Live test 10/10 (`NOT_CRAN=true` + `DRM_JL_PATH`). Gate test
  `test-julia-gate-vs-engine.R` 113/113; `tools/validate-mission-control.py` green.
- Recovery pilot reproducible (seeded `run.jl`, same draws on re-run).
- Native rejection confirmed at `R/drmTMB.R` ("REML for bivariate Gaussian models
  currently supports fixed-effect mean models only").

## Review

- **Rose (claim-boundary): GO** — frame accurate, no silent promotion (still
  partial), pilot honestly scoped, lanes not conflated, live test does not
  overclaim. (should-fix: this after-task + check-log — addressed.)
- **Fisher (inference): GO** — REML-less-biased / closer-to-truth supported by the
  reproducible MAE table; the "closer-to-truth, not REML>=ML" reframing is
  statistically correct; the live test asserts the right robust facts. (should-fix:
  results.md's "2-4 MC SE" line was not regenerable from run.jl and not uniformly
  true for sigma1 — addressed by adding per-axis MC-SE + z to run.jl and restating
  results.md to the computed values; the per-draw win-rate is descriptive, not
  significant at R=40 — noted in results.md.)

## Boundaries respected

Bridge lane (cell) + direct-DRM.jl lane (pilot), explicitly not conflated.
`covered` = engine-vs-engine parity (impossible here). No interval coverage / power
/ release claim. Only the biv_q4 cell changed in the registry.

## Next (further gaps, not this slice)

A full (>= 200-rep) recovery calibration; profile/bootstrap among-axis SD-interval
CIs through the bridge; bridge==direct numeric faithfulness parity.

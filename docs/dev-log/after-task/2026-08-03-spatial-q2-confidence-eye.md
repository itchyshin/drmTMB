# After Task: Spatial q2 Confidence Eye

## Goal

Finish the fixed-kappa bivariate-Gaussian spatial q2 interval arc after PR #893:
calibrate 95% endpoint profile-likelihood intervals jointly for
`sd_spatial1`, `sd_spatial2`, and latent `rho_spatial`, retain every attempted
dataset, and expose only the evidence-earned interval surface.

## Implemented

The prospective Fir campaign completed all 1,500 datasets and all 4,500 direct
target outcomes. M = 36 sites x 3 observations and H = 36 x 8 passed the joint
coverage and finite-profile gates; L = 12 x 3 failed. `mc-0199` and `mc-0672`
are promoted to `inference_ready_with_caveats` for the exact tested M/H
baseline-ring configurations. The article now fits the M configuration with
REML, computes the three endpoint profile intervals, and displays them as a
three-facet Confidence Eye.

## Mathematical Contract

The protected target vector is

\[
\left(\sigma_{u_1},\ \sigma_{u_2},\ \rho_u\right),
\]

where the two standard deviations and correlation parameterize the latent
two-response coordinate-spatial intercept block. The preregistered truths are
`sigma_u1 = 0.55`, `sigma_u2 = 0.55`, and `rho_u = 0.45`; residual truths are
`sigma1 = 0.18`, `sigma2 = 0.20`, and `rho12 = -0.10`. PASS requires each
target at a rung to have all-attempt coverage in `[0.925, 0.975]` and a finite
profile rate of at least 0.95. The common floor is the lowest jointly passing
rung for which every higher tested rung also passes.

## Files Changed

- The prospective design, runner, reconciler, SLURM launchers, packet builders,
  and focused contract test define and execute the immutable campaign.
- `docs/dev-log/simulation-artifacts/2026-08-03-spatial-q2-confidence-eye/`
  contains retained outcomes, summaries, decisions, receipts, manifests, and
  review provenance.
- `docs/dev-log/dashboard/capability-ledger/` records the two exact promotions.
- `vignettes/spatial-models.Rmd` contains the calibrated M example and
  Confidence Eye.
- `vignettes/bivariate-nongaussian.Rmd` removes the repeated horizontal CI line
  from the association Confidence Eyes and enlarges the hollow markers.
- README, NEWS, ROADMAP, formula grammar, generated pkgdown surfaces, and the
  capability-ledger regression test now describe the same exact boundary.
- `docs/dev-log/figure-audits/2026-08-03-spatial-q2-confidence-eye/` preserves
  the rendered figure and Florence verdict.

## Checks Run

- Fir smoke: 60/60 datasets completed, 180/180 target outcomes retained;
  Grace `APPROVE_FULL`.
- Fir full campaign: setup `52570123`, array `52570124`, corrected closeout
  `52574025`; 1,500/1,500 datasets completed and 4,500 target outcomes retained.
- Reconciler: joint floor M; M/H PASS and L FAIL.
- Focused test: `test-spatial-q2-confidence-eye-contract.R`, 35 expectations,
  PASS.
- Capability-ledger suite: 51 tests, PASS.
- Live-source pkgdown renders: `spatial-models`, `formula-grammar`, and home
  surfaces, PASS.
- Noether/Fisher pre-compute review: APPROVE/APPROVE.
- Grace packet review: APPROVE_SMOKE and APPROVE_FULL.
- Same-panel D43 review after remediation: Noether/Fisher/Rose 3/3 PROMOTE.
- Final direct-PNG visual review: `FLORENCE_VISUAL_FINAL = APPROVE` and
  `PUFF_VISUAL_FINAL = APPROVE`, using the animal/phylogenetic/relmat pkgdown
  exemplars as visual references.
- Live-source `bivariate-nongaussian` article rerender after repeated-eye repair:
  PASS.

## Tests Of The Tests

The ledger regression suite initially failed because its historical assertions
still required `interval_feasible`. The expectations were changed only for
`mc-0199` and `mc-0672`; the `mc-0673` rejected remainder and neighboring
relmat/animal rows remain asserted. The updated tests require the new
coverage-study evidence IDs, exact M/H boundary, explicit L failure, baseline
ring geometry, and the withheld mesh/geometry/`supported` claims.

## Consistency Audit

The exact scan was:

```sh
rg -n "point-only|Point estimate only|calibration remains planned|interval calibration.*planned|coverage remain planned|spatial q2|Confidence Eye|mc-0199|mc-0672" README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml vignettes/spatial-models.Rmd pkgdown-site/articles/spatial-models.html
```

It found stale exact-cell wording in README, ROADMAP, NEWS, and both formula
grammar surfaces. Those statements were synchronized. Historical notes that
remain true at their recorded time and unrelated planned intervals were kept.

## GitHub Issue Maintenance

Open-issue inspection found #682 as the closest existing umbrella issue for
featured profile intervals and boundary calibration. It remains broader than
this one fixed-kappa spatial q2 cell, so it should receive the final PR evidence
comment but should not be closed by this arc. No duplicate issue was opened.

## What Did Not Go Smoothly

The first article build used a stale installed package and failed before the
new section at `spatial_coords()`. Loading the live source namespace fixed that
environment issue. Two render iterations then exposed the real public return
shapes of `profile_targets()` and `confint()`, which were corrected to use
`parm`/`estimate` and `lower`/`upper`. The first ledger-test patch matched an
earlier assertion too broadly; the immediate rerun caught it, and the edit was
re-scoped to the exact Arc 1b-S1 block. The original full-run wall receipt used
an ambiguous timestamp parser and reported zero; the original receipt was
retained and a committed exact-UTC parser produced the corrected 0.2063889-hour
receipt.
The first Confidence Eye filled each facet with a pale rectangle and therefore
read as point-only. A second revision added a horizontal CI line, repeating a
known association-article error. User review rejected both. The final figure
returns to the trademark grammar: coloured tapered lens, larger hollow point,
no CI line, and a dotted zero reference only for correlation. The same line was
removed from the association article. Fresh image-fed Florence and Puff reviews
approved the final rendered PNGs.

## Team Learning

Campaign packets should ship the timestamp parser and a receipt-schema fixture,
not depend on host-local date parsing. Promotion tests should assert cell IDs
and evidence IDs in the same scoped block rather than editing repeated tier
strings. Reader figures should be rendered only after the statistical panel
passes, then reviewed from the actual bitmap rather than source code alone.

## Known Limitations

The result does not cover L = 12 x 3, mesh intervals, estimated range, spatial
slopes, q4+, non-Gaussian spatial models, spatial sigma models, derived observed
correlations, other geometries or information configurations, or `supported`.
Wald intervals are diagnostic only; bootstrap remains a separate non-rescue
route. The source archive is retained locally and on Fir, not committed to Git.

## Next Actions

Open the evidence-complete PR, require package/docs CI and mergeability, comment
the final evidence on #682 without closing it, merge, and verify post-merge
`origin/main`. Any geometry-robustness or estimated-range work starts as a new
symbolic and prospective calibration arc.

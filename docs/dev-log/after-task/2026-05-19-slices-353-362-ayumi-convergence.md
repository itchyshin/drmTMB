# Slices 353-362 Ayumi Convergence Stress Test

## Task Goal

Run the local Ayumi bivariate lightness data through the current bivariate
Gaussian location-scale and correlation paths, then record a sober status call:
what works now, what needs convergence guidance, and what should not yet be
used as a showcase example.

## Files Created Or Changed

- `tools/ayumi-convergence-stress.R`
- `docs/dev-log/ayumi-convergence/2026-05-19-slices-353-362-ayumi-convergence.md`
- `docs/dev-log/ayumi-convergence/slices-353-362/tree-preflight.csv`
- `docs/dev-log/ayumi-convergence/slices-353-362/fit-summary.csv`
- `docs/dev-log/ayumi-convergence/slices-353-362/check-rows.csv`
- `docs/dev-log/ayumi-convergence/slices-353-362/corpairs.csv`
- `docs/dev-log/ayumi-convergence/slices-353-362/profile-targets.csv`
- `docs/dev-log/ayumi-convergence/slices-353-362/profile-intervals.csv`
- `docs/dev-log/ayumi-convergence/slices-353-362/fit-conditions.csv`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format tools/ayumi-convergence-stress.R`: passed.
- `Rscript tools/ayumi-convergence-stress.R`: passed and wrote the committed
  summary CSVs.
- `Rscript -e "devtools::test(filter = 'phylo-gaussian|corpairs|profile-targets|check-drm')"`:
  passed with 963 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.

## Consistency Audit

The stress script keeps local data outside the package and records the exact
default `DRMTMB_TEST_DIR`. The report explicitly separates residual `rho12`,
phylogenetic mean-mean correlation, and q4 latent correlations. It also states
that forced ultrametricity is a stress-test device rather than a formal
rate-smoothing method.

The Phase 18 programme now records slices 353-362 so later simulation planning
does not forget why stable residual-`rho12` examples can proceed while q4
phylogenetic location-scale fits need a separate hard-identifiability lane.

## Tests Of The Tests

The script intentionally includes one failing preflight scenario:
`agg_phylo_mean_raw_tree_80`. It should fail before fitting because the raw
pruned tree is not ultrametric. That row confirms the artifact ledger can
record a structural data problem rather than only successful fits.

The script also exports all non-ok `check_drm()` rows, so false convergence,
large gradients, non-positive-definite Hessians, non-finite SEs, boundary
`rho12`, and near-boundary q4 correlations remain visible as data, not prose
memory.

## What Did Not Go Smoothly

The first implementation captured the printed `phytools::force.ultrametric()`
note instead of the returned tree. Ada fixed the script so the returned tree
and the cautionary printed note are both recorded.

The substantive modeling result was also not flattering: the q4 phylogenetic
location-scale variants run, but they produce exactly the diagnostics that say
"do not interpret this as a finished applied model."

## Team Learning

Ada's orchestration lesson is that convergence stress tests need committed
artifacts even when the conclusion is "not ready." Fisher's inference lesson is
that a fitted q4 table without Hessian and gradient evidence is too easy to
misread. Gauss and Noether's math-contract lesson is to keep residual,
phylogenetic mean, and q4 latent correlations in separate rows and separate
claims. Pat's user lesson is that Ayumi-style examples need a tree-preflight
and simplification workflow before a full q4 model appears in docs. Grace's
release lesson is to commit small summaries, not raw external data. Rose's
systems lesson is that warm starts need a real design slice before they become
part of the convergence story.

## Design-Doc Updates

`docs/design/41-phase-18-simulation-programme.md` now records slices 353-362:
local data discovery, stress script, non-ultrametric tree preflight, stable
residual-`rho12` fits, boundary phylogenetic mean correlation, q4 convergence
failures, residual-`rho12` profile interval evidence, row-level boundary
failure, warm-start boundary, and after-task closeout.

## pkgdown And Documentation Updates

No pkgdown article was added in this slice. That is deliberate: the stable
non-phylogenetic residual-`rho12` path can feed the next simulation wave, but
the full q4 Ayumi-style model should not be promoted to reader-facing examples
until the convergence workflow exists.

## Known Limitations And Next Actions

- The forced ultrametric tree is not a scientific preprocessing
  recommendation.
- The stress test uses deterministic 80-species subsets to keep the run local
  and repeatable; it is not a full data analysis.
- q4 phylogenetic location-scale fits should stay out of showcase examples
  until profiles, simulations, or simplification workflows support them.
- A warm-start or multistart contract remains future work; optimizer presets
  did not rescue the q4 stress cases here.

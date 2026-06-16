# After Task: Scale-Side Phylogenetic Identifiability Guidance (q4, Ayumi)

## Goal

Give users an honest, actionable answer when a phylogenetic field on the *scale*
(`sigma`) is weakly identified: a `check_drm()` note that steers them to "Model A"
(phylogeny on the mean, fixed-effect scale), plus a design note documenting the
finding. No model or likelihood change.

## Why (Curie q4 validation)

On pruned real beak/tarsus data (n = 300-600), the q4 model with a phylo field on
`sigma1`/`sigma2` fails (`convergence = 1`, `pdHess = FALSE`) because the
scale-side phylo SD hits its lower boundary -- the data (about one observation per
tip plus a rich `sigma` predictor) cannot identify a phylogenetic field on the
scale. This is not a coupling problem (a separable "Model D" fails the same way
for the full spec), not a correlation-start problem (`theta_phylo = 0` is already
the identity correlation in the R/TMB implementation, so an off-diagonal start
does not help), and not a warm-start problem. The tractable path is Model A:
`phylo(1 | pl | id)` on `mu1`/`mu2` only, fixed-effect `sigma1`/`sigma2`
(`convergence = 0`, `pdHess = TRUE`, strong mean-level phylo signal).

Also clarified: `fit$corpars$phylo` is the structural correlation
(`split_tmb_corpars` from `theta_phylo`; identity at `theta = 0`). A
"phylogenetic correlation near +/-1" reported elsewhere is an empirical
correlation among fitted random-effect predictions, not the structural parameter.

## Implemented

- `R/check.R`: `check_scale_phylo_identifiability()`, added to `check_drm()`.
  Returns NULL unless the model places a phylo field on the scale; emits an "ok"
  row when `pdHess = TRUE`; otherwise a **note** (not a warning -- the Hessian
  check already warns) pointing to a fixed-effect scale / more observations per
  group / doc 171.
- `docs/design/171-scale-side-phylo-identifiability-model-a.md`: the diagnosis,
  the Model A recommendation, and the structural-vs-empirical correlation
  clarification.
- `tests/testthat/test-scale-phylo-identifiability.R`: NULL when phylo is on the
  mean only; "ok" when `pdHess = TRUE`; "note" with Model A guidance when not;
  NULL without an sdreport.

## Mathematical Contract

No likelihood, parameterization, or formula-grammar change. Public terms
(`sigma`, `rho12`, `phylo()`, `mu`) unchanged. The new check is a `status = "note"`
diagnostic that does not flip `attr(check_drm(...), "ok")` (the existing Hessian
check owns the warning).

## Files Changed

- `R/check.R`
- `tests/testthat/test-scale-phylo-identifiability.R`
- `docs/design/171-scale-side-phylo-identifiability-model-a.md`
- `docs/dev-log/check-log.md`
- this report

## Checks Run

```sh
Rscript -e "devtools::test(filter = 'scale-phylo-identifiability|check-drm', reporter = 'summary')"
Rscript -e "devtools::document()"
git diff --check
```

Focused tests pass (no failures, output pristine). The full suite runs on CI
(this is an additive R-only diagnostic; it returns NULL for every model without a
scale-side phylo field, so it cannot affect existing fits).

## Tests Of The Tests

Branches are exercised deterministically by setting `fit$sdr$pdHess` on a real
scale-phylo fit, so the test does not depend on whether the near-degenerate
fixture happens to converge.

## What Did Not Go Smoothly

The near-degenerate scale-phylo fixture emits "NaNs produced" while fitting (this
worktree has no log-sigma clamp -- that is the separate clamp slice). The warning
is incidental to testing the check, so the fixture fit is wrapped in
`suppressWarnings()` with an explanatory comment.

## Known Limitations / Next Actions

- Pairs with the log-sigma clamp slice (doc 170), which prevents the univariate
  full-data overflow; this slice is the q4-side guidance.
- A runnable Model A worked example (vignette / example) for users is a follow-up.
- Off-diagonal start and Model-D-as-the-fix were investigated and dropped (they do
  not help in the R/TMB implementation / for the full spec).

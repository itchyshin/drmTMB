# After Task: Q8 And Skew-Normal Diagnostic Hardening

## Goal

Finish the first two systematic capability slices from the post-CRAN-hold queue:
Q8-1 diagnostic isolation for ordinary bivariate Gaussian q8 endpoint blocks,
and SN-1 fixed-effect contract polish for `skew_normal()`.

## Implemented

`check_drm()` now reports a q>4 bivariate endpoint covariance diagnostic row
for fitted ordinary Gaussian q8 blocks. The row records the block size, pair
count, replication, fitted component-SD scale, boundary, eigenvalue, and
condition-number diagnostics needed to explain weak q8 fits before changing
optimizers or parameterizations.

The q8 Phase 18 endpoint summary now writes optimizer, objective, gradient,
fitted SD, max-correlation, and reconstructed correlation-matrix diagnostics
into the replicate-level table. This makes future q8 artifact audits filterable
without reopening every RDS file.

The fixed-effect `skew_normal()` first slice now has source tests for weighted
likelihood equality, the TMB CDF-tail floor, fixed-effect `nu` intervals through
`profile_targets()`, `confint()`, `summary(conf.int = TRUE)`, and
`predict_parameters()`, plus a clearer unsupported-neighbour error for
backticked `skew(id) ~ ...` syntax.

## Mathematical Contract

Q8 remains the ordinary bivariate Gaussian endpoint covariance block with eight
group-level endpoint members and 28 latent correlations. The new diagnostics
reconstruct the fitted latent correlation matrix from the reported pairwise
correlations and report eigenvalue/condition-number summaries. They do not
change the likelihood or promote q8 intervals, coverage, or power.

`skew_normal()` remains public-moment parameterized:
`mu = E[y]`, `sigma = SD[y]`, and `nu` is the residual slant. TMB still
transforms to native `xi`, `omega`, and `alpha = nu`. The documented
implementation uses `log(Phi(nu * z) + 1e-300)` for finite automatic
differentiation in the extreme lower tail; source tests check equivalence to
the exact log-CDF away from that floor.

## Files Changed

- `R/check.R`
- `R/drmTMB.R`
- `inst/sim/fit/sim_summarise_biv_gaussian_q8_endpoint.R`
- `tests/testthat/test-biv-gaussian.R`
- `tests/testthat/test-phase18-biv-gaussian-q8-endpoint.R`
- `tests/testthat/helper-skew-normal-density.R`
- `tests/testthat/test-skew-normal-density-contract.R`
- `tests/testthat/test-skew-normal-location-scale.R`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/03-likelihoods.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/source-map.Rmd`

The working tree already had unrelated dirty files from the broader local
CRAN/skew-normal sprint; this task did not revert them.

## Checks Run

- `Rscript --vanilla -e 'devtools::test(filter = "skew-normal", reporter = "summary")'`
  passed after correcting one expected status string.
- `Rscript --vanilla -e 'devtools::test(filter = "phase18-biv-gaussian-q8-endpoint", reporter = "summary")'`
  passed before formatting.
- `air format R/check.R R/drmTMB.R inst/sim/fit/sim_summarise_biv_gaussian_q8_endpoint.R tests/testthat/helper-skew-normal-density.R tests/testthat/test-skew-normal-density-contract.R tests/testthat/test-skew-normal-location-scale.R tests/testthat/test-biv-gaussian.R tests/testthat/test-phase18-biv-gaussian-q8-endpoint.R`
  completed without output.
- Post-format, `Rscript --vanilla -e 'devtools::test(filter = "skew-normal|phase18-biv-gaussian-q8-endpoint", reporter = "summary")'`
  passed.
- Post-format, `Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-biv-gaussian.R", reporter = "summary")'`
  passed.
- `git diff --check` passed.

## Tests Of The Tests

The q8 tests assert that a live q8 fit now emits exactly one
`biv_qgt2_random_effect_covariance` check row with `max_q=8`,
`max_pairs=28`, and correlation-matrix diagnostics. The Phase 18 q8 endpoint
test asserts that the summary artifact includes the optimizer, gradient, SD,
correlation, eigenvalue, and condition-number columns and that the q8 smoke
fit fills them with finite values.

The skew-normal tests compare the fitted weighted objective against an
independent R likelihood calculation, check that the CDF-floor reference is
ordinary-density equivalent away from the far tail, verify that fixed-effect
`nu` intervals appear through the public interval APIs, and assert the
malformed `skew(id)` path.

## Consistency Audit

Updated `NEWS.md`, `ROADMAP.md`, `docs/design/03-likelihoods.md`,
`docs/design/157-capability-completion-worklist.md`,
`docs/dev-log/known-limitations.md`, and `vignettes/source-map.Rmd`.

Stale wording scans:

```sh
rg -n 'q=8 random-slope endpoint blocks remain invisible|q8 random-slope endpoint blocks can wait|skew_normal.*interval-status|skew-normal.*interval-status|Latent skewness syntax|1e-300|biv_qgt2_random_effect_covariance|q>4' ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes/source-map.Rmd R/check.R R/drmTMB.R tests/testthat inst/sim/fit
rg -n 'q8.*(coverage|power|diagnostic|hold)|skew\(id\)|skew_normal\(\).*fixed-effect|fixed-effect `skew_normal`|latent `skew\(id\)`' NEWS.md ROADMAP.md docs/design/157-capability-completion-worklist.md docs/dev-log/known-limitations.md vignettes/source-map.Rmd docs/design/03-likelihoods.md
```

The remaining hits are intended boundary statements or implemented diagnostic
names: q8 remains diagnostic/no coverage/no power, and latent `skew(id)`
remains unsupported.

## GitHub Issue Maintenance

Open issue search found existing coverage:

- #3 covers skew-normal.
- #491 covers the broad local-R capability queue.
- #33 covers remaining structured and bivariate random-slope work.

No new issue or duplicate comment was needed for this local slice; the local
check-log and after-task report carry the detailed evidence.

## What Did Not Go Smoothly

One test expected `predict_parameters()` to report
`interval_source = "fixed_effect_wald"`, but the live API vocabulary is
`"wald"`. The test was corrected to the actual public status string.

A stale-wording `rg` command was first run with shell-interpreted Markdown
backticks; it was rerun with single quotes before recording the final evidence.

## Team Learning

Q8 should continue with diagnostic grid presets and staged starts before any
coverage or power run. The current diagnostic columns are the right substrate
for deciding whether failures are mostly replication, SD scale, boundary
correlation, or correlation-matrix conditioning problems.

For skew-normal, the fixed-effect first slice is now more than "fits a model":
weights, interval inventory, and the numerical CDF floor are tested. The next
useful evidence slice is recovery/false-positive simulation, not more parser
surface.

## Known Limitations

Q8 convergence, positive Hessians, Wald intervals, coverage, and power remain
unresolved. The new work makes failure modes visible; it does not rescue weak
q8 fits.

`skew_normal()` remains fixed-effect and univariate. Random effects,
structured effects, known sampling covariance, bivariate skew-normal models,
residual `rho12`, latent `skew(id)`, formal recovery, false-positive checks,
diagnostics, and a user-facing example remain future work.

## Next Actions

1. Q8-2: add diagnostic grid presets that vary group count, repeats, SD ratios,
   residual `rho12`, and latent correlation regime.
2. SN-2: add a CRAN-safe skew-normal recovery/false-positive grid with
   positive, negative, weak, and strong skew plus Gaussian-limit cells.

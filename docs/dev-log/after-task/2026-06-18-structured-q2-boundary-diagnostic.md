# After Task: Structured Q2 Boundary Diagnostic

## Goal

Extend the `drmTMB#59` numerical-guard ledger from ordinary q2 covariance
routes to the already fitted structured q2 location-covariance routes, while
keeping the claim diagnostic-only.

## Implemented

`check_drm()` now reports fitted-boundary diagnostics for bivariate Gaussian
coordinate-spatial, `animal()`, and `relmat()` q2 location covariance rows:
`biv_spatial_q2_covariance`, `biv_animal_q2_covariance`, and
`biv_relmat_q2_covariance`. The existing `biv_phylo_mu_covariance` row remains
unchanged for the phylogenetic q2 route.

The artifact
`docs/dev-log/simulation-artifacts/2026-06-18-structured-q2-boundary-diagnostic/`
adds a self-contained runner and committed output tables for three already
fitted structured q2 location-covariance surfaces:

- bivariate Gaussian coordinate-spatial `mu1`/`mu2` q2 covariance;
- bivariate Gaussian `animal()` `mu1`/`mu2` q2 covariance;
- bivariate Gaussian `relmat()` `mu1`/`mu2` q2 covariance.

Each surface is crossed with true latent correlations 0, 0.4, 0.9, and 0.98.
The runner uses the default Phase 18 q2 fitting helpers and records warnings,
failures, convergence, `pdHess`, fixed gradients, log likelihood, AIC/BIC,
route-specific fitted correlations, boundary distances, and full `check_drm()`
rows.

## Mathematical Contract

The q2 structured covariance routes use the same open-interval transform family
as other latent correlations:

```r
rho = 0.999999 * tanh(eta)
```

The transform keeps fitted correlations inside `(-1, 1)`. This task does not
claim that one-replicate fitted correlations recover the true correlations.
It only checks whether fitted near-boundary status is visible in diagnostics.

## Files Changed

- `R/check.R`
- `man/check_drm.Rd`
- `tests/testthat/test-spatial-gaussian.R`
- `tests/testthat/test-animal-relmat-gaussian.R`
- `NEWS.md`
- `docs/dev-log/simulation-artifacts/2026-06-18-structured-q2-boundary-diagnostic/`
- `docs/design/176-numerical-guard-simulation-audit.md`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-18-structured-q2-boundary-diagnostic.md`

No TMB likelihood, formula grammar, optimizer, controls, examples, pkgdown
navigation, or mission-control count changed.

## Checks Run

- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-18-structured-q2-boundary-diagnostic/run-pilot.R`
- `air format R/check.R tests/testthat/test-spatial-gaussian.R tests/testthat/test-animal-relmat-gaussian.R`
- `Rscript --vanilla -e 'devtools::test(filter = "check-drm|spatial-gaussian|animal-relmat-gaussian", reporter = "summary")'`
- `Rscript --vanilla -e 'devtools::document()'`
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null`
- `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null`
- `python3 tools/validate-mission-control.py`
- `git diff --check`
- `git diff -U0 | rg -n 'CRAN ready|CRAN-ready|release ready|release-ready|coverage claim|power claim|calibrated interval|engine_control|AI-REML|Julia bridge parity|Julia-side algorithm|random effects in `rho12`|recovery accuracy|promote|promotion' || true`
- `Rscript --vanilla -e "pkgdown::check_pkgdown()"`
- `rg -n "biv_(spatial|animal|relmat)_q2_covariance|structured q2 boundary|structured q2 fitted-boundary|structured q2 recovery|q2 location covariance|q2 location-covariance" README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml docs/design/157-capability-completion-worklist.md docs/design/168-r-julia-finish-capability-matrix.md docs/design/176-numerical-guard-simulation-audit.md docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json docs/dev-log/check-log.md`
- `rg -n "structured q2.*(coverage|power|recovery|release|CRAN|Julia bridge|AI-REML|REML)|biv_(spatial|animal|relmat)_q2_covariance" README.md ROADMAP.md NEWS.md docs vignettes R tests`
- `rg -n "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" README.md ROADMAP.md NEWS.md docs vignettes R tests`

Result: the artifact rerun reproduced 12 cells, 0 fit errors, 11 optimizer
convergences, 12 positive Hessians, 12 gradient-ok rows, and five covariance
warnings. Focused tests passed. Both dashboard JSON files parsed cleanly.
Mission-control validation passed with `25/68 banked_or_verified`, `1 active`,
`0 blocked`, and `1 deferred`. `git diff --check` passed. The claim-boundary
scan only hit negative or out-of-scope wording. `pkgdown::check_pkgdown()`
reported no problems. Status-inventory scans found the intended new diagnostic
rows and explicit diagnostic-only guardrails; the meta-analysis scan found only
existing `meta_V()` / deprecated `meta_known_V()` compatibility text and
intentional guardrails against `meta_gaussian()`, `tau ~`, and `rho ~`.

## Tests Of The Tests

The focused tests exercise both the ordinary ok rows and the fitted-boundary
warning path. They mutate fitted structured q2 correlation parameters to
`0.995` for spatial, animal, and `relmat()` fits, then confirm that the
corresponding `check_drm()` row becomes a warning, reports `rho_abs=0.9950`,
names the default `boundary=0.9800`, and sets the table-level `ok` attribute
to `FALSE`.

The artifact itself is also executable diagnostic evidence: it fits all 12
surface-cell pairs and writes the observed diagnostic rows. The animal true
`rho = 0.9` cell retained optimizer non-convergence while also showing
`pdHess = TRUE`, a small fixed gradient, and a fitted correlation at the
numerical guard. The artifact keeps that mixed status visible rather than
treating `pdHess = TRUE` as a promotion.

## Consistency Audit

The numerical-guard audit, finish capability worklist, R-Julia finish matrix,
mission-control status, dashboard sweep, NEWS, help page, check log, and
after-task note now name the structured q2 boundary diagnostic. The wording
keeps recovery accuracy, interval coverage, power, q4/q8 covariance intervals,
random effects in `rho12`, Julia bridge parity, release readiness, CRAN
readiness, and non-Gaussian REML/AI-REML out of scope. A prose-style pass kept
the reader as an R package contributor or statistical-method reviewer: purpose
comes before mechanics, numerical claims point to local artifacts or check
outputs, and the negative claim boundaries stay attached to the evidence.

## GitHub Issue Maintenance

No issue was closed. `drmTMB#59` remains open as the parent numerical-guard
and simulation evidence ledger. I did not add a GitHub issue comment in this
local slice; the focused PR should add the public breadcrumb after CI evidence
exists.

## What Did Not Go Smoothly

`devtools::document()` regenerated unrelated roxygen artifacts, including a
`DESCRIPTION` `RoxygenNote` and several man pages. I removed that unrelated
generated drift and kept only the `check_drm()` help update tied to this
diagnostic change.

The artifact was first generated under a UTC-date path, then moved to the
local-date project convention and rerun from the final path. The committed
tables therefore describe the final artifact location.

## Team Learning

Fisher and Rose should treat this as fitted-boundary visibility evidence only.
A structured surface can report `pdHess = TRUE` and a small fixed gradient while
the optimizer status still says `false convergence (8)`. The dashboard should
keep those fields side by side instead of collapsing them into a single green
claim.

## Known Limitations

This is a 12-fit diagnostic pilot with one replicate per surface-cell pair. It
does not estimate bias, RMSE, coverage, power, Monte Carlo standard error, or
runtime distributions. It does not exercise q4/q8 covariance intervals, random
effects in `rho12`, non-Gaussian covariance, profile intervals, bootstrap
intervals, or Julia bridge parity.

## Next Actions

Finish local validation, open a focused PR for this diagnostic visibility
change, and monitor PR CI. After that PR is green and merged, the next safe
`drmTMB#59` slice is still evidence depth, not promotion: scale-side phylogeny,
bivariate scale routes, Student-t calibration depth, additional guard-grid
depth, or a deliberately sized calibration pilot for one already banked guard
class.

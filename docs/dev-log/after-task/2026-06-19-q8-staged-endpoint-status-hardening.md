# After Task: Q8 Staged Endpoint-Status Hardening

## Goal

Harden the native R/TMB q8 staged diagnostic artifact so cold and staged q8
fits report endpoint availability and optimizer failure modes explicitly,
without promoting q8 recovery, intervals, coverage, power, speed, release
readiness, CRAN readiness, direct Julia parity, or Julia-via-R bridge parity.

## Implemented

The staged diagnostic now writes an endpoint-status table beside the existing
metrics, deltas, provenance, scope, manifest, and failures tables. For each
cold and staged fit, the table records the eight direct q8 random-effect SD
endpoints, the 28 derived q8 random-effect correlations, and the separate
residual `rho12` row. Each row carries point availability, truth, estimate,
error, boundary distance, interval status, optimizer convergence, `pdHess`,
fixed-gradient status, maximum gradient, warning fields, and failure mode.

The private staged-fit metric row now also records optimizer-attempt summaries,
budget status, sdreport status, `se` request status when available,
fixed-gradient status, maximum gradient component, gradient tolerance, failure
mode, and failure detail.

After Ada review, the maximum-gradient component guard was tightened so an
unnamed numeric gradient records the selected component index instead of
failing before the diagnostic row is written.

## Mathematical Contract

The q8 target remains the same bivariate Gaussian endpoint model:

```r
bf(
  mu1 = y1 ~ x + (1 + x | p | id),
  mu2 = y2 ~ x + (1 + x | p | id),
  sigma1 = ~ x + (1 + x | p | id),
  sigma2 = ~ x + (1 + x | p | id),
  rho12 = ~ 1
)
```

The group-level q8 vector has eight direct SD endpoints and 28 derived
group-level correlations. Residual `rho12` remains the row-level residual
correlation and is recorded separately from the q8 random-effect correlations.

## Files Changed

- `R/drmTMB.R`
- `inst/sim/run/sim_write_biv_gaussian_q8_endpoint_staged_diagnostic_grid.R`
- `tests/testthat/test-phase18-biv-gaussian-q8-staged-diagnostic.R`
- `docs/design/03-likelihoods.md`
- `docs/design/35-optimizer-start-map-multistart.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-19-q8-staged-endpoint-status-hardening.md`

## Checks Run

```sh
air format R/drmTMB.R inst/sim/run/sim_write_biv_gaussian_q8_endpoint_staged_diagnostic_grid.R tests/testthat/test-phase18-biv-gaussian-q8-staged-diagnostic.R
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "phase18-biv-gaussian-q8-staged-diagnostic", reporter = "summary")'
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "optimizer-contract|phase18-biv-gaussian-q8-endpoint|phase18-biv-gaussian-q8-staged-diagnostic|phase18-actions-runner|phase18-structured-workflow-registry", reporter = "summary")'
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "clamp|check-drm|phase18-biv-gaussian-q8|julia-gate-vs-engine", reporter = "summary")'
/usr/local/bin/Rscript --vanilla -e 'devtools::test(reporter = "summary")'
/usr/local/bin/Rscript --vanilla - <<'RS'
# load_all() real one-replicate q8 staged diagnostic writer
RS
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
tools/validate-mission-control.py
git diff --check
RSTUDIO_PANDOC=/opt/homebrew/bin /usr/local/bin/Rscript --vanilla -e "pkgdown::check_pkgdown()"
/usr/local/bin/Rscript --vanilla -e 'devtools::check(error_on = "never")'
air format R/drmTMB.R tests/testthat/test-phase18-biv-gaussian-q8-staged-diagnostic.R
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "phase18-biv-gaussian-q8-staged-diagnostic", reporter = "summary")'
```

The focused staged diagnostic test passed. The broader optimizer, q8 endpoint,
actions-runner, and structured-workflow-registry subset passed. A temporary
installed-package verification also passed: `R CMD INSTALL` installed the
current dirty worktree into a temporary library, and
`sim_run_actions_cell.R` wrote the q8 staged endpoint-status CSV from that
installed package. The installed output had 74 endpoint-status rows: 16 q8
direct-SD rows, 56 q8 derived-correlation rows, and 2 separate
residual-`rho12` rows.

The real one-replicate `load_all()` q8 staged writer produced the same
endpoint-status denominator. In the real smoke, all point rows were deliberately
tagged `diagnostic_estimate_with_fit_warnings` because both cold and staged
fits were optimizer-nonconverged with very large fixed gradients.

The broad clamp, `check_drm`, q8, and Julia gate-vs-engine subset passed. Full
`devtools::test(reporter = "summary")` also passed with exit code 0; it
reported five existing skips in Julia bridge and sigma-phylo REML boundary
tests and 26 warnings in known numerical-warning paths. Dashboard JSON parsing,
mission-control validation, and `git diff --check` passed. Mission-control
validation reported 25/68 banked_or_verified, 1 active, 17 matrix rows, 11
finish rows, 15 Julia gate rows, and 9 Julia capability rows.
`pkgdown::check_pkgdown()` found no problems. `devtools::check(error_on =
"never")` completed in 15m 9.9s with exit code 0; the devtools summary reported
0 errors, 0 warnings, and 1 note for future timestamp verification, while the
raw R CMD check stream also printed a report-only spelling snapshot NOTE and
an installed-size INFO.

## Tests Of The Tests

The fake staged diagnostic test now supplies captured cold and staged fit
objects with q8 SDs, q8 derived correlations, residual `rho12`, and gradient
values. The test asserts that the artifact returns 74 endpoint-status rows, all
finite point estimates remain visibly diagnostic through `point_status`, all
interval statuses are `not_requested`, and the endpoint-status CSV is written.

The real one-replicate smoke uses actual fitted q8 objects through
`devtools::load_all()` and confirms the endpoint-status table is populated
from real `sdpars`, `corpars`, and `rho12()` output.

The unnamed-gradient regression test supplies a fake q8 staged fit whose
`obj$gr()` result is a numeric vector without names. The test confirms the
metric row records `max_gradient_component = "2"` and
`failure_mode = "fixed_gradient_warning"` instead of erroring before status
serialization.

## Consistency Audit

The change is artifact and internal-diagnostic plumbing only. It does not alter
the likelihood, formula grammar, TMB source, public control surface, public
warm-start API, q8 DGP, q8 recovery runner, or Julia bridge code.

The staged artifact still labels itself diagnostic-only. The endpoint-status
table makes interval unavailability explicit through `interval_status =
"not_requested"` and keeps residual `rho12` separate from q8 group-level
correlations. `docs/design/03-likelihoods.md` now states that the ordinary q8
location-scale endpoint route is fitted and diagnostic-artifact-ready only,
with recovery, intervals, coverage, power, bridge parity, and release claims
left as separate gates.

## GitHub Issue Maintenance

Posted the missing Big 4 block 3 breadcrumb to `drmTMB#59`:
https://github.com/itchyshin/drmTMB/issues/59#issuecomment-4753048610.
The breadcrumb records the 74-row endpoint-status denominator, the
diagnostic-only point-status boundary, the unnamed-gradient guard follow-up,
and the remaining final branch-validation requirement before PR.

## What Did Not Go Smoothly

The first fake-test update failed because the helper closure looked for q8 DGP
helper functions in the wrong test frame. The test now uses self-contained q8
labels for fake fits.

A direct local call to `inst/sim/run/sim_run_actions_cell.R` first picked up
the previously installed package namespace rather than the current worktree and
could not find the new private staged diagnostic. Installing the current
worktree into a temporary library and rerunning the same actions-cell task
fixed that local namespace problem and verified the installed-package path.

## Team Learning

For q8, a fit-level success word is too coarse. Endpoint availability,
optimizer budget, sdreport/Hessian status, fixed-gradient status, and failure
mode need to travel together. The new endpoint-status table makes that review
possible without implying that any endpoint is ready for inference.

Gauss pushed the optimizer schema beyond simple convergence and `pdHess`;
Noether kept the eight SD endpoints, 28 derived correlations, and residual
`rho12` boundary separate; Fisher kept the decision label at status-map only;
Grace kept native R/TMB, direct Julia, and Julia-via-R evidence separated.

## Known Limitations

This is native R/TMB diagnostic endpoint-status plumbing only. It does not
support q8 recovery accuracy, q8 interval coverage, q8 power, public q8
warm-start support, structured q8, random effects in residual `rho12`, direct
Julia parity, Julia-via-R parity, release readiness, CRAN readiness, or
non-Gaussian REML/AI-REML.

## Next Actions

Use this q8 endpoint-status table as status-map evidence only. The next Big 4
slice should move to the fixed-effect skew-normal guard grid unless review
finds a defect in the already-banked bivariate scale, ordinary q2, or q8
diagnostic evidence.

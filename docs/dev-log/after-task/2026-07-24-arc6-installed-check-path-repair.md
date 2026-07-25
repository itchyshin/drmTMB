# After Task: Arc 6 installed-package CI-context repair

## 1. Goal

Repair the two Arc 6 tests and one executable vignette that failed only under `R CMD check`, without
changing the direct-lognormal estimator, interval API, simulation design, or
evidence claim.

## 2. Implemented

Both source-tree tests now resolve their source input first and skip only when
that input is unavailable in an installed-package test tree. The coverage smoke
still runs from a development checkout; the documentation guard still checks
all five public source surfaces there.
The real penguin vignette now uses explicit `drmTMB::` calls for its executable
direct-lognormal example.

## 3a. Decisions and Rejected Alternatives

The campaign driver and documentation sources are deliberately source-only
development assets, not installed package runtime files. The correct installed
package behaviour is an explicit skip, not copying campaign code or private
development documents into the installed package solely for tests.
A vignette is rebuilt without attaching its own package, so executable calls
use explicit namespace qualification rather than relying on a development
session's search path.

## 4. Files Touched

- `tests/testthat/test-biv-lognormal-rho12-coverage-driver.R`
- `tests/testthat/test-biv-lognormal-rho12-coverage-docs.R`
- `vignettes/bivariate-nongaussian.Rmd`
- `docs/dev-log/check-log.md`

## 5. Checks Run

The two focused tests pass from a source checkout. `R CMD build
--no-build-vignettes .` succeeds. A fresh installation into an isolated
temporary R library rendered `bivariate-nongaussian.Rmd` successfully without
`devtools::load_all()`. Local `R CMD check` reaches installation but cannot
complete because this machine cannot resolve CRAN and therefore lacks the
optional `palmerpenguins` Suggests package; main-branch Linux CI is the final
installed-package check.

## 6. Tests of the Tests

The coverage test still executes the nine-cell, 81-bootstrap-refit smoke when
the driver exists. The documentation test still reads each declared public
surface when those files exist. The new guards cover the distinct installed
package context that caused the regression. The isolated render tests the
vignette in a package-installed, non-`load_all()` environment.

## 7a. Issue Ledger

No issue status changed. This is a post-merge CI repair for the Arc 6 evidence
lane, not a new capability or evidence-tier promotion.

## 8. Consistency Audit

No likelihood, parameterisation, interval method, simulation grid, artifact,
or reader-facing claim changed. The direct `rho12` evidence boundary remains
the one recorded in the Arc 6 coverage after-task report.

## 9. What Did Not Go Smoothly

The source-only tests passed locally before merge, but that did not reproduce
the installed-package test layout used by `R CMD check`. The first repair then
exposed that the newly executable vignette had the parallel namespace
assumption. Both check-context boundaries are now explicit.

## 10. Known Residuals

The local environment's DNS failure prevents a complete offline check with the
optional penguin tutorial dependency. The pushed Linux CI, which installs
Suggests in its configured dependency environment, must be green before this
repair is closed.

## 11. Team Learning

For development-only campaign drivers and source documentation, each test must
state whether it verifies a source checkout or an installed package. A passing
source-path test is not evidence that the same test can run after installation.

## 12. Cross-Product Coverage

This repair covers only the two direct-lognormal Arc 6 source-path tests and
the penguin vignette's installed-package namespace path. It does NOT cover or alter the evidence boundaries for direct `rho12`, Student-t, staged
eta, random effects, missingness, or cross-family associations.

## Next Action

Commit, fast-forward the narrow repair to `main`, and inspect the new
main-branch R-CMD-check result.

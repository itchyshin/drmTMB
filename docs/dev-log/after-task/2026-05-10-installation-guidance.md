# After Task: Landing-Page Installation Guidance

## Goal

Make the landing page usable for someone who wants to install `drmTMB` in R,
load it, fit a first model, and know which dependencies are required before
they start reporting usability bugs and ideas.

## Files Created Or Changed

- `README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-installation-guidance.md`

## What Changed

The README now includes an `Install` section before the tiny model example. It
tells users that `drmTMB` is not on CRAN yet, gives a GitHub installation
command through `remotes::install_github()`, and includes a local Gaussian
location-scale smoke test using `summary()` and `sigma()`.

The dependency prose names the main constraints a first-time user is likely to
hit: R 4.1.0 or newer, a compiler toolchain for TMB, runtime dependencies
installed automatically, and optional packages used by articles, comparators,
tests, and site checks.

## Checks Run

- `Rscript -e "devtools::load_all(quiet = TRUE); set.seed(1); dat <- data.frame(y = rnorm(80), x1 = rnorm(80)); fit <- drmTMB(drm_formula(y ~ x1, sigma ~ x1), family = gaussian(), data = dat); print(head(sigma(fit)))"`:
  returned finite fitted `sigma` values.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `rg -n "Install|install_github|R 4\.1\.0|Rtools|Core runtime dependencies|pkgdown" README.md pkgdown-site/index.html`:
  confirmed the install, compiler, dependency, and rendered-site text.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `git diff --check`: clean.
- Commit, push, and GitHub Actions are pending until this report is committed.

## Tests Of The Tests

The smoke test uses simulated data and the public `drmTMB()`,
`drm_formula()`, `summary()`, and `sigma()` interface. It exercises the first
workflow a new user will probably try after installation, rather than only
checking that the package namespace loads.

## Consistency Audit

The new prose keeps `sigma` as the public residual scale parameter and does
not introduce new formula grammar. It describes installation and dependency
requirements only.

## What Did Not Go Smoothly

The previous landing page had no installation route at all. That omission
would block user testing and make the first usability loop harder than it
needed to be.

## Team Learning

Pat should treat installation as part of the first tutorial, not as outside
the package story. Grace should keep compiler-toolchain and dependency
expectations visible before users file installation issues.

## Design-Doc And Pkgdown Updates

No design document, formula grammar, likelihood, or navigation change was
needed. Rebuilding pkgdown will render the README change on the landing page.

## Known Limitations And Next Actions

The installation section gives a general compiler-toolchain note, not a full
operating-system troubleshooting guide. If users report repeated installation
failures, the next step is a short `installation` article with
platform-specific fixes and a copy-paste issue template.

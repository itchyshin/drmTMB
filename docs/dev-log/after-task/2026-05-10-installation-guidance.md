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
tells users that `drmTMB` is not on CRAN yet, gives a primary GitHub
installation command through `pak::pak()`, keeps
`remotes::install_github()` as a fallback, and includes a local Gaussian
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
- `rg -n 'Development status|development version|0\.0\.0\.9000|0\.1\.0|pak::pak|install_github|development build; 0\.1\.0 preview planned' README.md _pkgdown.yml pkgdown-site/index.html`:
  confirmed the source and rendered version-status and install-path text.
- Chrome/Playwright layout sanity check over `pkgdown-site/index.html`: desktop
  viewport `1280 x 900` had `scrollWidth = 1280` and showed the development
  badge; mobile viewport `390 x 844` had `scrollWidth = 390` and hid the badge
  while keeping the `Development status`, `Install`, and `Tiny example`
  sections visible.
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

A follow-up user read caught a related Pat and Rose miss: pkgdown still showed
`0.0.0.9000` in the header, which is technically correct for the current
development build but not clear to a user expecting the planned `0.1.0`
preview. The fix is to explain the development version visibly rather than
bump `DESCRIPTION` before the release checklist closes.

The same follow-up read caught another Grace miss: the first installation
draft used `remotes::install_github()` as the primary route. The corrected
landing page now recommends `pak::pak("itchyshin/drmTMB")` first and keeps
`remotes` only as a fallback for users who already rely on it.

The layout check also had to go back to basics. The repo-local Node context
did not have Playwright, and the bundled Playwright browser cache did not have
the default Chromium executable. The final check used the bundled Playwright
package with the installed Chrome channel and recorded desktop and mobile
scroll widths.

## Team Learning

Pat should treat installation as part of the first tutorial, not as outside
the package story. Grace should keep compiler-toolchain and dependency
expectations visible before users file installation issues. Rose should add
version-status wording to every release-readiness scan, because an accurate
version number can still be confusing when the roadmap is talking about the
next release. Ada should call a short review huddle for landing-page install
text whenever it affects first contact: Pat reads it as a new user, Grace
checks current installation practice, and Rose checks version-status wording.

## Rose Failure-Pattern Rule

When a page is meant to help users start using `drmTMB`, Rose should scan for
three linked failure patterns before the task closes:

- the recommended install path is stale, old, or less user-friendly than the
  current R package practice;
- the visible package version, release target, and roadmap language can be
  read as contradictory even when each sentence is technically true;
- a page tells users what the package can do but omits the first action they
  need to take in R.

If any of those appear, the fix should be reader-facing prose or navigation,
not only a private dev-log note.

## Back-To-Basics Review

After the follow-up correction, Ada paused the landing-page edit and checked
the first user path again:

- What version is this? The page now says this is development version
  `0.0.0.9000`, with `0.1.0` as the preview target.
- How do I install it? The page now recommends `pak::pak("itchyshin/drmTMB")`
  first and keeps `remotes` as a fallback.
- What should I try first? The page gives a small Gaussian location-scale
  smoke test immediately after installation.

This review is deliberately basic. The lesson is that release-facing polish
should not outrun the first five minutes of a user's experience.

## Design-Doc And Pkgdown Updates

No design document, formula grammar, likelihood, or navigation change was
needed. Rebuilding pkgdown will render the README change on the landing page.

## Known Limitations And Next Actions

The installation section gives a general compiler-toolchain note, not a full
operating-system troubleshooting guide. If users report repeated installation
failures, the next step is a short `installation` article with
platform-specific fixes and a copy-paste issue template.

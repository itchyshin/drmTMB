# After Task: Slice 53 Direct Profile Robustness

## Goal

Make direct profile-likelihood failures clearer before adding more interval
surfaces. The slice should harden `TMB::tmbprofile()` wrappers, target-selection
errors, and failure messages while keeping the supported target set unchanged.

## Implemented

- Added `drm_tmbprofile()` around direct `TMB::tmbprofile()` calls.
- Added `drm_tmbprofile_confint()` around profile-interval extraction.
- Reused the wrapper for direct `parm` profiles and row-specific `newdata`
  response-scale profiles.
- Rejected `obj`, `name`, `lincomb`, and `trace` in `...`, because those
  arguments identify the profile target and are supplied by `drmTMB`.
- Added focused tests for target-override errors and a forced TMB profile
  failure.
- Updated `confint()` documentation, `NEWS.md`, `ROADMAP.md`, the profile-CI
  design note, and this check log.

## Mathematical Contract

No likelihood or interval transformation changed. Direct targets are still
one-dimensional profile-likelihood targets from `profile_targets(fit)`.
`drmTMB` now makes the target ownership explicit:

- users choose the target with `parm`;
- users may tune profile controls such as `ystep`, `ytol`, `maxit`, and
  `parm.range`;
- `drmTMB` supplies `obj`, `name`, `lincomb`, and `trace` internally for the
  chosen target.

If TMB fails to construct the profile, the error names the public target. If a
profile exists but `confint()` cannot extract bounds, the extraction failure is
reported separately.

## Files Changed

- `R/profile.R`
- `tests/testthat/test-profile-targets.R`
- `man/confint.drmTMB.Rd`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-15-slice-53-direct-profile-robustness.md`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(filter = "profile-targets", reporter = "summary")'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::document()'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md man/confint.drmTMB.Rd`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(filter = "profile-targets|summary|corpairs", reporter = "summary")'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(reporter = "summary")'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_site()'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`
- `git diff --check`
- `rg -n "Profile target selection is controlled|Profile likelihood failed while profiling target|Could not extract a profile confidence interval|Direct Profile Robustness|Slice 53|obj.*name.*lincomb.*trace|ystep|parm.range" R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md man/confint.drmTMB.Rd pkgdown-site/ROADMAP.html pkgdown-site/reference/confint.drmTMB.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json'`

## Tests Of The Tests

The new failure test forces a TMB profile construction error with `ystep = 0`.
That would previously expose a low-level error; it now checks that the message
names the `profile_targets()` target. The target-override test checks a
malformed input path before TMB is called.

## Consistency Audit

The source docs and rendered pkgdown pages agree that `parm` owns target
selection, while `ystep`, `ytol`, `maxit`, and `parm.range` remain user-tunable
profile controls. The supported interval set did not change, so known
limitations around derived q4 and nonlinear summaries remain accurate.

## What Did Not Go Smoothly

After the previous resume, the shell PATH did not include `Rscript`; Grace used
the explicit `/usr/local/bin:/opt/homebrew/bin` PATH for checks. That should be
kept in future long runs when the desktop shell environment resets.

## Team Learning

- Ada should keep Phase 6 focused on one boundary at a time: namespace first,
  direct profile robustness second, broader interval surfaces later.
- Boole should make error messages say who owns target selection: `parm`, not
  low-level TMB arguments.
- Gauss should keep TMB failures wrapped with enough original error text to
  diagnose numerical issues.
- Noether should keep target transformations unchanged unless the likelihood
  or profile scale actually changes.
- Fisher should treat failed profiles as inference diagnostics, not just
  programming errors.
- Pat should be able to recover from errors by reading the target name and the
  suggested profile controls.
- Grace should use explicit PATH prefixes after interrupted desktop sessions.
- Rose should watch for future docs that mention `TMB::tmbprofile()` but omit
  the `parm` target namespace.

## Known Limitations

Slice 53 does not add profile intervals for ordinal cutpoints, q4 correlations,
ICCs, repeatability, phylogenetic signal, or other derived summaries. It also
does not add profile plots or automatic fallback methods for failed profiles.

## Next Actions

Slice 54 should extend and test row-specific `newdata` profile intervals for
`sigma`, `sigma1`, `sigma2`, `rho12`, and fitted q2 `corpair()` rows, with
clear rejection of ambiguous multi-parameter requests.

# After Phase: Phase 13 Derived Inference Foundation Closure

Date: 2026-05-15

## Goal

Close the local Phase 13 foundation for double-hierarchical derived inference
without claiming nonlinear derived confidence intervals. The closed surface is
the current point-estimate and interval-status contract for derived summaries,
covariance summaries, profile targets, `summary()`, and `corpairs()`.

## Implemented

- `summary(fit)$derived` reports simple Gaussian random-intercept
  repeatability and univariate phylogenetic signal as derived variance-ratio
  point estimates.
- `profile_targets()` lists those derived summaries with `target_type =
  "derived"` and `profile_note = "derived_target"`, and keeps them out of
  `ready_only = TRUE`.
- `summary(conf.int = TRUE)` marks unsupported derived intervals with
  `conf.status = "derived_interval_unavailable"` instead of silently omitting
  interval information.
- `summary(fit)$covariance` reports fitted registry-backed variance and
  covariance point summaries for currently fitted covariance blocks, including
  the first bivariate phylogenetic `mu1`/`mu2` mean-mean row.
- `corpairs(conf.int = TRUE)` attaches direct intervals only to profile-ready
  correlation rows and marks modelled or derived rows with explicit interval
  status.

## Scope Boundary

This closure is not a nonlinear derived-interval method. Derived intervals for
covariance rows, q=4 unstructured correlations, repeatability, phylogenetic
signal with multiple variance components, total variance, and complete
double-hierarchical slope-scale summaries remain planned until a valid
fix-and-refit or reparameterized direct-target method is implemented.

## Mathematical Contract

The closed foundation reports derived point estimates such as:

```text
repeatability = sigma_group^2 / (sigma_group^2 + sigma_residual^2)
phylogenetic_signal = sigma_phylo^2 / (sigma_phylo^2 + sigma_residual^2)
covariance = correlation * sd_from * sd_to
```

These quantities are nonlinear functions of fitted parameters. The current
contract reports the point estimate and explicit interval status. It does not
construct Wald intervals by combining component standard errors.

## Standing Review Closure

- Ada: close the reporting and status foundation, not derived interval
  estimation.
- Boole: `summary()`, `corpairs()`, `confint()`, and `profile_targets()` share
  the same target/status vocabulary.
- Gauss: direct SD and correlation intervals remain distinct from nonlinear
  derived covariance intervals.
- Noether: derived formulas, profile-target rows, summary columns, and
  unavailable-status values agree.
- Darwin: applied users can report repeatability, phylogenetic signal, and
  covariance point estimates while seeing which intervals are not yet valid.
- Fisher: no Wald shortcut is advertised for nonlinear boundary-sensitive
  variance ratios or covariance functions.
- Pat: missing intervals are labelled as unavailable, not absent by accident.
- Jason: the design note keeps fix-and-refit and reparameterized direct
  targets as future methods.
- Curie: tests cover derived target inventory, summary derived rows, q=4
  derived target status, covariance summaries, and direct interval attachment.
- Emmy: output tables carry stable status columns for future interval methods.
- Grace: local tests, pkgdown, and package check are the gate; GitHub Actions
  remains the PR-side gate.
- Rose: stale wording should not claim derived intervals for q=4 correlations,
  covariance rows, repeatability, phylogenetic signal, or total variance.

## Files Changed In Gate Slice

- `ROADMAP.md`
- `docs/design/34-validation-debt-register.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-phase/2026-05-15-phase-13-derived-inference-foundation-closure.md`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format ROADMAP.md docs/design/34-validation-debt-register.md docs/dev-log/check-log.md docs/dev-log/after-phase/2026-05-15-phase-13-derived-inference-foundation-closure.md`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(filter = "profile-targets|summary|biv-gaussian|phylo-gaussian|spatial-gaussian|check-drm|gaussian-random-intercepts", reporter = "summary")'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_site()'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::check(error_on = "never", env_vars = c("_R_CHECK_SYSTEM_CLOCK_" = "FALSE"))'`
- `git diff --check`
- Source and rendered scans for Phase 13 closure wording and stale overclaims
  about derived nonlinear intervals.

All tests and checks passed. `pkgdown::check_pkgdown()` found no problems.
`devtools::check()` passed with 0 errors, 0 warnings, and 0 notes in 2m 24s.

## Tests Of The Tests

The focused gate exercises the derived-summary inventory, derived variance
ratios, q=4 derived unstructured-correlation targets, covariance summary
columns, direct interval attachment for supported SD/correlation rows, and
explicit unavailable statuses for unsupported derived intervals.

## Consistency Audit

The ROADMAP now records the local Phase 13 foundation closure and keeps
nonlinear derived intervals planned. The validation-debt register points to this
report while keeping the row partial because valid derived interval methods are
still future work. The stale-overclaim scan found no source or rendered claim
that derived nonlinear intervals are implemented.

## What Did Not Go Smoothly

The main risk is wording. "Derived inference" can sound like intervals are
implemented; the closed foundation is point estimates plus status, not
confidence intervals for nonlinear derived targets.

## Known Limitations

- Nonlinear derived intervals remain planned.
- q=4 unstructured correlations remain derived targets and are not
  profile-ready.
- Derived covariance intervals remain unavailable.
- Repeatability, phylogenetic signal, and total variance intervals need a
  valid direct-target or fix-and-refit method.
- GitHub Actions remains the PR-side gate.

## Next Actions

1. Design one fix-and-refit derived interval path before exposing derived
   interval claims.
2. Keep q=4 derived status visible in `profile_targets()`, `summary()`, and
   `corpairs()`.
3. Add complete double-hierarchical total-variance summaries only after the
   fitted q=6/q=8 slope endpoints exist.

# After Phase: Phase 6 Profile-Likelihood Inference Closure

Date: 2026-05-15

## Goal

Close the scoped Phase 6 profile-likelihood inference work with source, tests,
pkgdown, local check, roadmap, and known-limitation evidence aligned.

The closure goal was not to make every `drmTMB` quantity profile-ready. It was
to make the supported direct targets discoverable, testable, and honest in
output, while marking derived or unsupported interval requests clearly.

## Implemented

- `profile_targets()` is the public inventory for direct versus derived
  profile targets, with controlled `target_type`, `profile_ready`,
  `profile_note`, and `transformation` values.
- `confint()` returns Wald fixed-effect intervals by default and profile
  intervals for explicit direct targets.
- Row-specific `confint(..., method = "profile", newdata = ...)` routes cover
  response-scale `sigma`, `sigma1`, `sigma2`, `rho12`, and fitted q=2 ordinary
  or phylogenetic `corpair()` values.
- `summary(conf.int = TRUE, method = "profile")` and
  `corpairs(conf.int = TRUE)` attach intervals only where the target is
  profile-ready and otherwise report explicit statuses such as
  `profile_ready`, `newdata_required`, `derived_interval_unavailable`, or
  `wald_unavailable`.
- Successful profile interval rows carry `profile.boundary` and
  `profile.message`; failed profile errors name boundary, one-sided,
  non-monotone, and failed-inner-optimization profiles as possible causes.
- Derived variance-ratio summaries for simple Gaussian repeatability and
  univariate phylogenetic signal are reported as point estimates without
  claiming derived profile intervals.
- README, known limitations, model workflow, model map, bivariate coscale, and
  structured-dependence prose now teach the same interval-status vocabulary.

## Mathematical Contract

For a direct scalar target \(\theta\), the profile interval is based on the
usual one-dimensional likelihood-ratio set:

```text
logLik_hat - logLik_profile(theta) <= qchisq(level, df = 1) / 2
```

All nuisance parameters are re-optimized at each profiled value. Direct
targets can be passed to `TMB::tmbprofile()` or to a one-row linear predictor
profile. Derived targets such as q=4 pairwise correlations, repeatability, and
phylogenetic signal combine multiple fitted quantities; Phase 6 reports those
point estimates and status rows, but does not claim their intervals.

## Files Changed In Gate Slice

- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-phase/2026-05-15-phase-6-profile-likelihood-closure.md`

## Checks Run

- `Rscript -e 'devtools::test(reporter = "summary")'`: passed.
- `Rscript -e 'pkgdown::build_site()'`: passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `Rscript -e 'devtools::check(error_on = "never", env_vars = c("_R_CHECK_SYSTEM_CLOCK_" = "FALSE"))'`:
  passed with 0 errors, 0 warnings, and 0 notes.
- `git diff --check`: passed.
- Source and rendered-site scans confirmed the Phase 6 closure status and
  interval vocabulary.
- Stale-claim scans found no remaining claim that all profile CIs are complete,
  that all six q=4 correlations are profile-ready, or that derived q=4
  intervals are direct profile intervals.

## Consistency Audit

- `ROADMAP.md` now marks Phase 6 as closure-audited for the scoped
  direct-profile inference surfaces.
- `NEWS.md` records the user-facing `confint()`, `summary()`, `corpairs()`,
  `profile_targets()`, and profile-diagnostic changes made during Phase 6.
- `docs/design/12-profile-likelihood-cis.md` records the Slice 51-59 design
  and implementation boundary.
- `docs/dev-log/known-limitations.md` still states that q=4 derived
  correlation intervals, one-sided intervals, profile recovery, bootstrap
  fallback, and conditional random-effect mode intervals remain future work.
- Rendered pkgdown pages include the updated roadmap and profile-inference
  tutorial language.

## What Did Not Go Smoothly

The main process risk was scope creep. Phase 6 could easily have turned into a
general uncertainty rewrite. Keeping q=4 correlations and variance-ratio rows as
explicit derived targets prevented the docs from overclaiming what direct TMB
profiles can currently support.

## Team Learning

- Ada: close inference phases through explicit status rows and evidence, not
  broad confidence-interval claims.
- Boole: public target names should stay user-facing; users should not have to
  know raw TMB parameter blocks to ask for an interval.
- Gauss: direct profile intervals belong to direct scalar TMB or linear
  predictor targets; derived covariance summaries need a separate method.
- Noether: output status, equations, and profile-target transformations now
  tell the same story.
- Fisher: profile likelihood is the right default advice for bounded SD and
  correlation targets, but boundary and non-monotone cases still need stronger
  methods.
- Pat: users now have a practical reading order: `profile_targets()`, then
  `conf.status`, then `profile.boundary` and `profile.message`.
- Grace: full local tests, pkgdown, local `R CMD check`, and GitHub Actions are
  the right closure gate for inference-facing changes.
- Rose: the key stale phrase to keep hunting is any wording that turns derived
  q=4 point estimates into profile-ready intervals.

## Known Limitations

- Phase 6 does not make every package parameter profile-ready.
- Derived q=4 ordinary and phylogenetic correlations are point estimates with
  unavailable interval status.
- Repeatability and phylogenetic signal currently have point estimates and
  status rows, not confidence intervals.
- One-sided intervals, profile recovery for non-monotone paths, parametric
  bootstrap fallback, conditional random-effect mode intervals, and marginal
  mean uncertainty remain future work.

## Next Actions

1. Phase 6b should improve tutorials and examples around the implemented
   surfaces, using the interval-status vocabulary from Phase 6.
2. Phase 6c should design random-slope examples and slope-related profile
   targets without prematurely claiming slope-correlation intervals.
3. Phase 6d should start the audit-response hardening lane: stable-core matrix,
   validation-debt register, failure-safe `sdreport()` controls, optimizer/start
   strategy, dense covariance guards, count-kernel audit, and C++ source map.

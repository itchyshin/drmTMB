# After Task: Poisson relatedness-matrix SD regression

## 1. Goal

Admit one predictor-dependent SD formula for a non-inflated Poisson location
intercept with a relatedness matrix, reusing the existing structured-SD
machinery and checking its public outputs.

## 2. Implemented

The Poisson builder now recognizes `sd_relmat(id)` alongside the existing
phylogenetic SD route. Marginal simulation admits modeled structured SDs for
q=1 Poisson `phylo()` and `relmat()` location effects. The fitted model uses
`sd(id, level = "relmat") ~ z` with `relmat(1 | id, K = K)`.

## 3a. Decisions and Rejected Alternatives

The builder reuses the existing structured-SD parser, group mapping, and TMB
likelihood. No C++ or Julia source changed. The first recovery fixture used a
smoothly increasing group predictor with a smooth relatedness kernel; its
estimated slope missed truth by 0.43. I changed the fixture to a balanced
alternating contrast and kept the absolute tolerance at 0.30. I did not extend
the route to ordinary `sd()` terms, zero inflation, other providers, or
structured slopes.

## 4. Files Touched

- `R/drmTMB.R`
- `R/methods.R`
- `tests/testthat/test-poisson-relmat-sd-regression.R`
- `README.md`, `NEWS.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/34-validation-debt-register.md`
- `docs/dev-log/internal-roadmap.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/check-log.d/2026-10-20-poisson-relmat-sd-regression.md`
- `.unlazy/general-sd-regression/GATES.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `LOOP/lanes/general-sd-regression/arcs.md`
- `vignettes/formula-grammar.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/predictor-dependent-random-sd.Rmd`
- This report

## 5. Checks Run

- Test-first admission check failed as expected with `Unsupported parameter:
  "sd_relmat(id)"`.
- `Rscript -e 'devtools::test(filter = "poisson-relmat-sd-regression",
  stop_on_failure = TRUE)'`: 19 expectations passed; zero failures, warnings,
  or skips.
- Neighbor command
  `Rscript -e 'devtools::test(filter =
  "poisson-(relmat|phylo)-sd-regression|binomial-relmat-sd",
  stop_on_failure = TRUE)'`: 46 expectations passed in 21.4 seconds; zero
  failures, warnings, or skips.
- The tutorial rendered from `devtools::load_all()` to
  `/private/tmp/predictor-dependent-random-sd-check-20261020.html`.
- `pkgdown::check_pkgdown()` found no problems. Existing Pandoc
  `--mathml` deprecation warnings remain.
- `pkgdown::build_site(preview = FALSE)` stopped because DNS could not resolve
  `cloud.r-project.org` in this network-restricted environment. Nothing was
  published.
- Scoped `git diff --check` passed.
- `graft build` completed and refreshed the local source map.
- `slop_check.py` found zero issues in the after-task report and check-log
  detail file; scanned project prose remained under its review threshold.
- The after-task structure checker initially rejected the first report draft
  because its section names did not match the repository template. This report
  now uses all required headings and a full downstream coverage boundary.
- `CHECK_AFTER_TASK_ACTIVE=1` rerun: report structure passed; programme ledger
  reverification was skipped to avoid recursive gate checking.
- `node /Users/z3437171/.codex/skills/unlazy/scripts/gate-check.mjs --status
  .unlazy/general-sd-regression/GATES.md`: 8 programme gates, 7 unmet; G2 is
  met and G5 interval coverage remains deferred.

## 6. Tests of the Tests

The first regression test failed at formula admission before the builder
change. The original smooth-predictor fixture exposed weak separation from the
low-frequency kernel structure, so I changed the predictor pattern without
loosening the recovery tolerance. The final test checks convergence, seeded
SD-slope recovery, coefficient names, group-SD and parameter prediction,
random-effect scaling, marginal simulation, save/reload prediction, and
constant-SD equivalence. The fixture now multiplies its covariance by 1.7 and
checks recovery of the SD intercept, so it detects accidental normalization of
the supplied relatedness covariance.

## 7a. Issue Ledger

Open issue searches for `Poisson relmat SD`, `random-effect scale`, and
`general SD-regression` found no issue dedicated to this implementation slice.
No issue was opened, commented on, or closed.

## 8. Consistency Audit

The formula grammar, model map, roadmap, NEWS, README, validation-debt register,
known-limitations page, and tutorial describe the same complete-data, q=1,
non-inflated Poisson `relmat()` slice. The predictor is constant within group.
The documented covariance is `D K D`. Julia parity and interval calibration
remain unestablished. I ran the status inventory search recorded in
`docs/dev-log/check-log.d/2026-10-20-poisson-relmat-sd-regression.md`.

## 9. What Did Not Go Smoothly

The first standalone tutorial render loaded an older installed package from
another worktree and failed before reaching the changed section. The
source-loaded render passed. The full site build also needed an external CRAN
lookup that is unavailable in this environment.

## 10. Known Residuals

This is one native Poisson q=1 `relmat()` intercept. It does not establish
interval calibration, Julia parity, other structured Poisson providers,
zero-inflated Poisson, ordinary plus structured SDs, structured slopes, or
broad recovery across designs. Julia's existing Poisson related-matrix route
normalizes supplied matrices to correlations, whereas native TMB preserves the
supplied covariance scale. That engine-level difference remains open; this
native test does not establish non-unit-scale cross-engine parity. The overall
general SD-regression goal remains active.

## 11. Team Learning

For tutorial renders in a multi-worktree R setup, load the exact candidate
source before rendering. For a recovery fixture with a smooth covariance
kernel, check whether the predictor is confounded with low-frequency latent
variation before interpreting a single-seed slope miss.

## 12. Cross-Product Coverage

Native R/TMB fitting, extraction, prediction, marginal simulation, and
save/reload prediction were checked for the one Poisson `relmat()` cell. The
neighboring Poisson phylogenetic and Bernoulli relmat tests passed. This slice
does NOT cover Julia, Beta, binomial, ordinary random effects, Poisson
`phylo()` SD regression, spatial, animal, phylogenetic-interaction, bivariate
endpoints, missing-response or missing-predictor paths, REML, profiles,
bootstrap, or calibrated intervals. No cross-engine parity is claimed.

## 13. Prose Assessment

Style: 2/10, medium confidence; the report uses concrete model details and
short sentences. Genre/coverage: implementation after-task report, read in
full. Evidence/repair: the added covariance-scale test result and cross-engine
limitation match the current test and source audit. Gates: science = pass for
the stated q=1 contract; facts = pass against the test output and source;
references = not applicable because no external citations appear. Provenance:
self-review, version 3, 2026-10-21; related tests and design notes were
inspected.

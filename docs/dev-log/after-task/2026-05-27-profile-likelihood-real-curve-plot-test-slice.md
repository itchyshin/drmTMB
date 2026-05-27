# After Task: Profile-Likelihood Real Curve Plot Test Slice

## Goal

Add the first focused tests and durable rendered evidence for
`profile.drmTMB()` and `plot.profile.drmTMB()` using one cheap real Gaussian
profile, while leaving article integration for a later slice.

## Implemented

This slice adds `tests/testthat/test-profile-plots.R`, covering:

- a real `stats::profile()` call for the Gaussian `sigma` target;
- returned `"profile.drmTMB"` class and profile-curve columns;
- target-scale metadata for positive response-scale `sigma`;
- character and numeric profile target matching;
- `plot.profile.drmTMB()` output for single-pass curves;
- coarse/dense pass plot separation;
- input-validation errors; and
- clear missing-`ggplot2` messaging.

The implementation also fixes two issues found by the tests:

- `profile_match_targets()` now accepts numeric target-row positions, matching
  the documented `parm` contract.
- pass-comparison plots no longer pass `colour = NULL` into geoms, so mapped
  coarse/dense colours work cleanly.

Single-pass plots now omit unused colour and linetype labels.

## Mathematical Contract

No likelihood parameterization changed. The real profile test checks one
Gaussian model:

```r
drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
```

The profiled target is constant residual `sigma`, reported on the public
positive response scale. The plotted y-axis is likelihood-ratio distance:

```text
delta_deviance = 2 * (profile_nll - min(profile_nll))
```

The profile endpoints in the rendered evidence come from
`stats::confint()` applied to the `TMB::tmbprofile()` object.

## Files Changed

- `R/profile.R`
- `tests/testthat/test-profile-plots.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-27-profile-likelihood-real-curve-plot-test-slice.md`
- `docs/dev-log/figure-audits/2026-05-27-profile-likelihood-sigma/figure-audit.md`
- `docs/dev-log/figure-audits/2026-05-27-profile-likelihood-sigma/sigma-profile-curve.csv`
- `docs/dev-log/figure-audits/2026-05-27-profile-likelihood-sigma/sigma-profile-curve.png`

## Checks Run

```sh
air format R/profile.R tests/testthat/test-profile-plots.R
Rscript --vanilla -e "files <- c('R/profile.R', 'tests/testthat/test-profile-plots.R'); invisible(lapply(files, parse)); cat('ok parse profile plot files\n')"
Rscript --vanilla -e "devtools::test(filter = '^profile-plots$', reporter = 'summary')"
Rscript --vanilla - <<'RSCRIPT'
devtools::load_all(quiet = TRUE)
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("ggplot2 is required for profile plot evidence")
}
out_dir <- file.path("docs", "dev-log", "figure-audits", "2026-05-27-profile-likelihood-sigma")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
set.seed(20260527)
n <- 80
x <- stats::rnorm(n)
dat <- data.frame(y = 0.2 + 0.5 * x + stats::rnorm(n, sd = 0.7), x = x)
fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
prof <- stats::profile(fit, parm = "sigma", level = 0.80, trace = FALSE, profile_precision = "fast")
utils::write.csv(prof, file = file.path(out_dir, "sigma-profile-curve.csv"), row.names = FALSE)
p <- plot(prof) + ggplot2::ggtitle("Gaussian sigma profile-likelihood curve") + ggplot2::theme_minimal(base_size = 11)
ggplot2::ggsave(file.path(out_dir, "sigma-profile-curve.png"), p, width = 6.4, height = 4.0, dpi = 180)
RSCRIPT
sips -g pixelWidth -g pixelHeight docs/dev-log/figure-audits/2026-05-27-profile-likelihood-sigma/sigma-profile-curve.png
wc -l docs/dev-log/figure-audits/2026-05-27-profile-likelihood-sigma/sigma-profile-curve.csv
git diff --check
```

- The first focused test run failed because the pass-comparison plot path
  exposed a real colour-mapping bug, and one validation test was not preserving
  S3 dispatch.
- After the fix, `devtools::test(filter = '^profile-plots$')` passed.
- The rendered PNG is 1152 by 720 pixels.
- The profile CSV has 31 curve rows plus one header row.

## Tests Of The Tests

The first focused test run failed before the plot fix. That failure checked a
real visual-output path: coarse/dense pass plots should map colour through
`profile_pass` rather than suppress the mapping with an empty colour argument.

The validation test also caught a test-design issue: `transform()` dropped the
profile class before dispatch. The test now mutates the column while preserving
the `"profile.drmTMB"` class.

## Consistency Audit

The tests stay within the existing profile-target and plotting conventions:
`profile_targets()` remains the target inventory, `TMB::tmbprofile()` supplies
the curve, `stats::confint()` supplies endpoints, and `plot()` returns a
`ggplot` object. No README, NEWS, ROADMAP, formula grammar, or likelihood
design claim changed in this slice.

The figure-audit note records the current visual limitation: the generic x-axis
label is acceptable for the method but the later article figure should name the
specific target, `sigma`.

## GitHub Issue Maintenance

No issue comment was added. Release issue #342 remains the relevant open gate
for the broader profile-likelihood demonstration because this slice adds test
and figure evidence but not article integration.

## What Did Not Go Smoothly

The pass-comparison plot initially produced ggplot warnings because mapped
colour was overridden by `colour = NULL`. The fix builds geom argument lists and
only supplies fixed colour for single-pass plots. This also made the focused
test output quiet.

## Team Learning

- Ada kept the slice to one real profile and one test file.
- Fisher checked that the plot is likelihood-ratio evidence, not posterior or
  Wald evidence.
- Gauss and Noether checked that `sigma` stays on the positive response scale.
- Florence inspected the PNG and found it readable enough as method evidence.
- Pat noted the article should replace the generic x-axis wording with a
  target-specific cue.
- Grace ran formatting, parse, focused tests, image dimension, row-count, and
  whitespace checks.
- Rose recorded the colour-mapping bug as a pattern for future ggplot S3
  methods.
- No spawned subagents were running.

## Known Limitations

This slice did not run full `devtools::test()`, `pkgdown::build_site()`,
`pkgdown::check_pkgdown()`, or article rendering. The figure evidence uses one
cheap Gaussian `sigma` profile; random-effect SDs, correlations, coarse/dense
real-profile comparisons, and article text are still unreviewed.

## Next Actions

The next small slice should integrate one compact profile-likelihood figure
into `vignettes/model-workflow.Rmd`, render that article or a focused local
HTML, and show the rendered page/figure evidence before touching broader
release notes.

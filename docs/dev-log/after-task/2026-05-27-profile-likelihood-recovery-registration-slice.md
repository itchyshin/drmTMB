# After Task: Profile-Likelihood Recovery And S3 Registration Slice

## Goal

Recover from the interrupted profile-likelihood plotting run by rebuilding the
repo state from durable evidence, writing a checkpoint, and making the existing
`R/profile.R` profile/plot helpers dispatchable before attempting real fitted
profiles or article work.

## Implemented

This micro-slice registers and documents two S3 methods already present in the
dirty `R/profile.R` diff:

- `profile.drmTMB()`, which returns full `TMB::tmbprofile()` curve data for
  direct `profile_targets()` rows; and
- `plot.profile.drmTMB()`, which draws likelihood-ratio distance against the
  profiled target value with estimate, cutoff, and interval endpoint guides.

The slice also adds both topics to `_pkgdown.yml` and records recovery state in
`docs/dev-log/recovery-checkpoints/2026-05-27-073103-codex-checkpoint.md`.

## Mathematical Contract

No likelihood parameterization changed. The plotted diagnostic remains the
existing profile-likelihood scale:

```text
delta_deviance = 2 * (profile_nll - min(profile_nll))
```

The x-axis is transformed with the same target-scale conventions already used
by `profile_targets()` and `confint.drmTMB()`: fixed effects stay on the linear
predictor scale, SD and scale targets use the positive response scale, and
correlations use the guarded correlation scale.

## Files Changed

- `R/profile.R`
- `NAMESPACE`
- `_pkgdown.yml`
- `man/profile.drmTMB.Rd`
- `man/plot.profile.drmTMB.Rd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-27-profile-likelihood-recovery-registration-slice.md`
- `docs/dev-log/recovery-checkpoints/2026-05-27-073103-codex-checkpoint.md`

## Checks Run

```sh
git status --short --branch
git log --oneline -5 --decorate
git diff --stat
git diff -- R/profile.R
Rscript tools/codex-checkpoint.R --goal "recover interrupted profile-likelihood plotting slice" --next "inspect R/profile.R helper diff, run a narrow parse/source sanity pass, then decide the smallest documented/tested profile-likelihood figure step"
Rscript --vanilla -e "parse('R/profile.R'); cat('ok parse R/profile.R\n')"
Rscript --vanilla -e "devtools::load_all(quiet = TRUE); x <- data.frame(parm = 'sigma', level = 0.95, profile_value = c(0.7, 1, 1.3), delta_deviance = c(3.84, 0, 3.84), estimate = 1, profile_pass = 'profile', elapsed = 0.01, profile_controls = 'synthetic', profile_source = 'synthetic source', conf.low = 0.7, conf.high = 1.3, conf.status = 'profile'); class(x) <- c('profile.drmTMB', class(x)); p <- plot(x); stopifnot(inherits(p, 'ggplot') || inherits(p, 'ggplot2::ggplot')); cat('ok synthetic profile plot dispatch\n')"
Rscript --vanilla -e "devtools::document()"
git diff --check
gh issue list --repo itchyshin/drmTMB --state open --search "profile likelihood OR profile-likelihood OR profile.drmTMB OR profile_targets" --limit 20 --json number,title,state,url,labels
rg -n "profile\\.drmTMB|plot\\.profile\\.drmTMB|profile-likelihood curves|profile likelihood curve|profile_targets" README.md NEWS.md ROADMAP.md docs/design vignettes _pkgdown.yml R/profile.R NAMESPACE tests/testthat -g '!*.html'
```

- The checkpoint command wrote
  `docs/dev-log/recovery-checkpoints/2026-05-27-073103-codex-checkpoint.md`.
- `R/profile.R` parsed successfully.
- The synthetic `plot()` dispatch check failed before `NAMESPACE` regeneration,
  then passed after `devtools::document()` registered the S3 methods.
- `git diff --check` was clean.

## Tests Of The Tests

The synthetic dispatch check is intentionally narrow. It failed in the
pre-registration state by falling through to the wrong plotting method and then
passed once `plot.profile.drmTMB()` was registered. It does not prove that a
real fitted-model `TMB::tmbprofile()` curve is numerically correct.

## Consistency Audit

The `_pkgdown.yml` reference index now includes `profile.drmTMB` next to
`profile_targets()` and `plot.profile.drmTMB` under Visualization. Existing
source and documentation searches show broad `profile_targets()` usage and the
new S3 method names in `R/profile.R`, `NAMESPACE`, and `_pkgdown.yml`.

No README, NEWS, ROADMAP, formula grammar, or likelihood design-doc claim was
changed because this slice only registers plotting infrastructure that remains
incomplete until real profile tests, rendered figure evidence, and article
integration are added.

## GitHub Issue Maintenance

The issue search found release issue #342 as the current open
profile-likelihood demonstration gate. No issue comment was added because this
slice only fixed recovery/registration plumbing and does not yet satisfy the
requested figure evidence.

## What Did Not Go Smoothly

The first synthetic plot check failed because the new method was present in
`R/profile.R` but absent from `NAMESPACE`. Running `devtools::document()` fixed
that, but also generated unrelated Rd link churn and a local `RoxygenNote`
line. Those unrelated generated edits were removed so the slice stayed focused
on method registration and new documentation topics.

## Team Learning

- Ada kept the slice to recovery, registration, and dispatch.
- Fisher kept the validation claim narrow: this is plot-method plumbing, not a
  profile-interval operating-characteristic result.
- Gauss and Noether still need to review a real fitted profile curve before the
  helper can be called inference-complete.
- Florence still needs rendered plot evidence before the figure gate passes.
- Pat and Darwin still need article-context review when the figure appears in a
  user-facing page.
- Grace checked parse, documentation generation, S3 dispatch, `_pkgdown.yml`,
  issue overlap, and whitespace.
- Rose recorded the failure mode so later slices do not forget the
  roxygen-to-NAMESPACE step.
- No spawned subagents were running.

## Known Limitations

This slice did not add tests, did not run full `devtools::test()`, did not run a
real `profile(fit, ...)` call, did not render a profile-likelihood plot from a
model, and did not build or check pkgdown. The feature is not done.

## Next Actions

The next small slice should add a focused `tests/testthat/test-profile-plots.R`
file that exercises one cheap Gaussian fit, checks `profile(fit, parm =
"sigma", profile_precision = "fast")`, verifies the returned columns and S3
class, verifies error paths for missing `parm` and malformed plot data, and
saves a temporary rendered plot for Florence review without yet changing an
article.

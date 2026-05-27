# After Task: Profile-Likelihood 95 Percent Cutoff Support Test Slice

## Goal

Add the missing QA gate for the rendered profile-likelihood curve: for the
user-facing 95% profile interval, the sampled full curve should extend beyond
the likelihood-ratio cutoff on both the lower and upper sides.

## Implemented

`tests/testthat/test-profile-plots.R` now defines
`expect_profile_extends_beyond_cutoff()`. The helper reads the stored profile
level, computes `stats::qchisq(level, df = 1)`, and requires sampled profile
rows below `conf.low` and above `conf.high` whose `delta_deviance` exceeds that
cutoff.

The real Gaussian `sigma` profile test now uses `level = 0.95` instead of
`level = 0.80`. It still profiles the same fitted target with
`profile_precision = "fast"` and now asserts successful profile endpoints plus
the two-sided support-beyond-cutoff condition.

## Mathematical Contract

No likelihood, transformation, or interval engine changed. The test still uses:

```r
drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
```

The profiled target is constant residual `sigma` on the public positive
response scale. The support gate uses likelihood-ratio distance,
`2 * (profile_nll - min(profile_nll))`, and the 95% one-parameter cutoff,
`stats::qchisq(0.95, df = 1)`.

## Files Changed

- `tests/testthat/test-profile-plots.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-27-profile-likelihood-95-cutoff-support-test-slice.md`

## Checks Run

```sh
air format tests/testthat/test-profile-plots.R
Rscript --vanilla -e "devtools::test(filter = '^profile-plots$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(reporter = 'summary')"
git diff --check
gh issue view 342 --json number,title,state,url,labels
gh issue list --search "profile likelihood" --state open --json number,title,url --limit 10
```

- Focused `profile-plots` tests passed.
- Full `devtools::test()` passed.
- `git diff --check` was clean.
- Issue #342, `Release drmTMB 0.2.0`, is open and remains the relevant release
  ledger for the broader profile-likelihood bundle.

## Tests Of The Tests

Before this slice, the real profile test checked finite profile rows,
`min(delta_deviance) == 0`, and successful endpoint extraction, but it did not
prove that the sampled curve crossed beyond the 95% cutoff on both sides of the
interval. The new helper turns that visual QA rule into a mechanical test.

## Consistency Audit

This is a test-strengthening slice only. It does not change public syntax,
formula grammar, likelihood parameterization, pkgdown navigation, README,
NEWS, ROADMAP, or known-limitations text. Existing article and reference docs
already describe the public 95% profile interval.

## GitHub Issue Maintenance

`gh issue view 342` confirmed that release issue #342 is open. A search for
open issues matching `profile likelihood` also returned #342 plus related
structured-effect and diagnostics issues. No duplicate issue was opened and no
comment was added because this slice only tightens the local test gate.

## What Did Not Go Smoothly

The first exploratory one-line R command accidentally let the shell expand
`$profile_value` and tried to summarize a data frame. I reran the check through
a quoted heredoc before editing the test.

## Team Learning

- Ada kept the slice small and tied it to the previous profile QA lane.
- Fisher kept 95% as the default reporting and documentation target.
- Gauss and Noether confirmed that the change is a test gate, not an interval
  parameterization change.
- Curie made the support-beyond-cutoff rule explicit in a reusable local test
  helper.
- Grace reran focused and full tests plus whitespace hygiene.
- Rose recorded the 95% decision and avoided duplicating issue-ledger entries.
- No spawned subagents were running.

## Known Limitations

This test covers one cheap Gaussian constant-`sigma` profile. It does not add a
99% stress gate, random-effect SD profile gate, correlation profile gate, or
`devtools::check()` run.

## Next Actions

Stage the profile-likelihood bundle when ready, or run `devtools::check()` as
a separate CRAN-style gate before publishing the branch.

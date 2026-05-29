# After Task: Bootstrap Correlation Draw-Scale Audit

## Goal

Audit the direct-correlation bootstrap percentile scale after the positive
target log-scale slice, without changing the bootstrap API or interval
calculation.

## Implemented

`tests/testthat/test-profile-targets.R` now locks the existing behavior for
direct correlation bootstrap percentiles. Both random-effect correlations with
`transformation = "tanh"` and residual `rho12` targets with
`transformation = "rho12_tanh"` keep percentile endpoints on the response-scale
refit correlations returned in `estimate`.

`docs/design/12-profile-likelihood-cis.md` now says the same thing in prose:
positive scale and SD targets use log-scale bootstrap percentiles, but direct
correlation targets keep response-scale refit correlations rather than
switching to Fisher-z or another link-scale percentile rule.

## Source Contract

`bootstrap_uses_link_percentiles()` still returns `TRUE` only for direct
`exp`-transformed targets. Correlation profile targets continue to store both
`estimate` and `link_estimate`, but bootstrap percentile extraction uses
`estimate` for `tanh` and `rho12_tanh`.

The regression test chooses asymmetric link-scale draws where response-scale
and transformed link-scale percentile endpoints differ, then asserts that the
bootstrap interval equals the response-scale quantiles. That makes a future
change to Fisher-z or link-scale correlation percentiles visible in the
targeted test suite.

## Files Changed

- `tests/testthat/test-profile-targets.R`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-29-bootstrap-correlation-draw-scale-audit.md`

## Checks Run

```sh
air format tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md
Rscript --vanilla -e "devtools::test(filter = 'profile-targets', reporter = 'summary')"
rg -n "bootstrap.*correlation|correlation.*bootstrap|Fisher.?z.*bootstrap|bootstrap.*Fisher.?z|link-scale.*correlation|response-scale refit correlations|target-specific scales|positive scale and SD targets|direct correlation targets" README.md NEWS.md ROADMAP.md docs/design R tests/testthat man --glob '!docs/dev-log/**'
gh issue list --repo itchyshin/drmTMB --state open --search 'bootstrap correlation scale rho12 Fisher z percentile' --limit 20 --json number,title,state,url,labels
git diff --check
```

Result: `test-profile-targets.R` passed, `git diff --check` was clean, the
stale-wording scan found compatible current wording, and the GitHub issue
search returned `[]`.

## Tests Of The Tests

The new test compares response-scale quantiles with transformed link-scale
quantiles for both `tanh` and `rho12_tanh`. The two intervals are deliberately
not equal, so the test guards the existing response-scale bootstrap rule rather
than only checking that a helper returns a numeric interval.

## Consistency Audit

The scan found the expected NEWS and help text that Fisher-z/atanh is used for
Wald-style correlation intervals, and the expected profile-design wording that
positive scale and SD bootstrap intervals use log-scale percentiles. No public
document now says that bootstrap correlation percentiles use Fisher-z,
atanh-scale, or a generic target-specific scale rule.

## GitHub Issue Maintenance

The issue search for bootstrap correlation scale, `rho12`, Fisher-z, and
percentile overlap returned `[]`. No issue action was needed.

## What Did Not Go Smoothly

The first targeted test run failed because `expect_gt()` in the local testthat
version does not accept an `info` argument. The assertion was unchanged after
removing that unsupported argument, and the next `profile-targets` run passed.

## Team Learning

Ada kept the slice to one interval-scale audit. Fisher and Noether checked that
the test distinguishes response-scale correlation quantiles from link-scale
correlation quantiles. Grace kept validation to `profile-targets`, stale-wording
scans, issue search, and `git diff --check`. Rose checked that the design doc
does not overclaim bootstrap coverage.

No spawned subagents were running.

## Known Limitations

This slice does not prove correlation bootstrap coverage, add a simulation
comparison against link-scale percentiles, or route bootstrap intervals through
`summary()`, `corpairs()`, prediction tables, q4 derived correlations,
repeatability, or phylogenetic signal. Link-scale correlation percentiles remain
a later simulation question, not a behavior change in this audit.

## Next Actions

Continue with the next small profile/bootstrap hardening slice after this PR is
merged and GitHub Actions is green.

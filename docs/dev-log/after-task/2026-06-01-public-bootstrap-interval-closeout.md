# After Task: Public Bootstrap Interval Closeout

## Goal

Close #265 by tying the public bootstrap interval API to existing code, tests,
documentation, limitations, and roadmap boundaries.

## Implemented

This is a documentation and status closeout. It adds
`docs/design/153-public-bootstrap-interval-closeout.md` as the #265 ledger and
updates the ROADMAP to record that the first public direct-target bootstrap
boundary is complete.

## Mathematical Contract

Bootstrap intervals are percentile intervals from simulated and refitted
responses. For positive scale and standard-deviation targets, percentile
endpoints are taken on the fitted log scale and transformed back with `exp()`.
Correlation targets report percentiles on the public correlation scale. These
intervals are refit-distribution summaries, not proof of coverage or automatic
recovery from weak Hessians.

## Files Changed

- `ROADMAP.md`
- `docs/design/153-public-bootstrap-interval-closeout.md`
- `docs/dev-log/after-task/2026-06-01-public-bootstrap-interval-closeout.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format NEWS.md ROADMAP.md docs/design/153-public-bootstrap-interval-closeout.md docs/dev-log/after-task/2026-06-01-public-bootstrap-interval-closeout.md docs/dev-log/check-log.md
Rscript --vanilla -e "devtools::test(filter = '^profile-targets$|^control$', reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
rg -n '#265|Public bootstrap interval closeout|confint\(\.\.\., method = "bootstrap"\)|bootstrap\.n|bootstrap\.failed|bootstrap\.parallel|bootstrap\.workers|direct fitted-object targets|bootstrap_unavailable|summary\(conf\.int = TRUE, method = "bootstrap"\)|corpairs\(conf\.int = TRUE, method = "bootstrap"\)' ROADMAP.md docs/design/153-public-bootstrap-interval-closeout.md docs/dev-log/after-task/2026-06-01-public-bootstrap-interval-closeout.md docs/design/12-profile-likelihood-cis.md docs/dev-log/known-limitations.md R/profile.R tests/testthat/test-profile-targets.R NEWS.md
rg -n 'bootstrap intervals are not implemented|public interval methods limited to Wald and profile|bootstrap.*rescues every|bootstrap.*automatically (rescues|fixes|recovers)|summary\(.*method = "bootstrap".*(implemented|supported)|corpairs\(.*method = "bootstrap".*(implemented|supported)|prediction.*bootstrap.*(implemented|supported)|derived.*bootstrap.*(implemented|supported)' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R man tests/testthat
git diff --check
```

Results:

- Focused `profile-targets` and `control` tests passed.
- `pkgdown::check_pkgdown()` returned `No problems found`.
- The positive scan found the #265 closeout ledger, ROADMAP row, current
  direct-bootstrap design notes, implementation metadata columns, and focused
  tests.
- The stale scan returned only intentional hits: ROADMAP's generic statement
  that bootstrap routes are supported or deliberately unavailable, and the
  reusable scan recipe in `docs/design/69-comprehensive-function-page-figure-audit.md`.
- `git diff --check` passed.

## Tests Of The Tests

The closeout relies on existing focused tests for direct bootstrap intervals,
unsupported derived bootstrap targets, q4 derived-unavailable boundaries,
bootstrap worker metadata, and explicit non-positive-definite Hessian status.

## Consistency Audit

The status claim is intentionally narrow: `confint(..., method = "bootstrap")`
exists for selected direct fitted-object targets. It does not add bootstrap
support to `summary()`, `corpairs()`, prediction tables, `newdata`, q4 derived
correlations, repeatability, phylogenetic signal, or simulation coverage
claims.

## GitHub Issue Maintenance

This report supports closing #265 through the linked PR.

## What Did Not Go Smoothly

The bootstrap implementation was already present, so the main risk was stale
status bookkeeping rather than code. The closeout therefore records evidence
handles instead of changing interval behavior.

## Team Learning

Rose's status audit matters here: a feature can be implemented but still look
unfinished if the roadmap and issue ledger do not say exactly which boundary
is complete.

## Known Limitations

Derived intervals, bootstrap routing through summaries and extractors,
prediction-table bootstrap intervals, and operating-characteristic evidence
remain out of scope for this closeout.

## Next Actions

- Keep derived interval design separate from direct `confint()` bootstrap
  intervals.
- Route coverage, power, MCSE, and runtime evidence through Phase 18 issue #59.

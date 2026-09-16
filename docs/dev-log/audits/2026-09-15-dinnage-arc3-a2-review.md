# Independent review: PR #1369 Wave A2 check.R

Date: 2026-09-15
Reviewer: Cursor reviewer subagent, independent of the builder
PR: <https://github.com/itchyshin/drmTMB/pull/1369>
Builder branch reviewed: `cursor/dinnage-arc3-a2-check-20260915`
Review branch: `cursor/dinnage-arc3-a2-review-20260915`

## Verdict

REQUEST CHANGES.

The Mi-5 production wording is acceptable after a test repair, but the A-8
implementation does not reliably diagnose fitted objects after the original data
has gone out of scope. The PR's own targeted regression command also reports
failures.

## Per-finding decisions

### #1338 A-8 dropped random-effect groups

Decision: REJECT.

Severity: P1.

`check_dropped_rows()` now depends on `check_fit_input_data()` re-evaluating
`object$call$data` from the call or formula environment (`R/check.R:1216-1233`).
That is not fit-owned state. When the fit is built in a local function and
returned, the original `dat` object is no longer resolvable, so
`check_fit_input_data()` returns `NULL`, `check_dropped_group_levels()` returns
the empty table, and `check_drm()` falls back to the old row-only message. The
new `groups_lost=` value is therefore absent in an ordinary post-fit workflow.

Reproducer run at the PR ref:

```r
fit_in_function <- function() {
  set.seed(1338)
  n_id <- 40L
  n_each <- 8L
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n_id * n_each)
  )
  dat$y <- stats::rnorm(n_id * n_each)
  dat$y[dat$id %in% 1:6] <- NA_real_
  drmTMB(bf(y ~ x + (1 | id), sigma ~ 1), family = gaussian(), data = dat)
}
fit <- fit_in_function()
drmTMB:::check_fit_input_data(fit)
drmTMB:::check_dropped_group_levels(fit)
check_drm(fit)[check_drm(fit)$check == "dropped_rows", ]
```

Observed:

```text
NULL
[0 rows]
nobs=272; dropped=48
Rows were dropped by complete-case or known-covariance filtering.
```

This is also why the PR's own `test_that()` case fails at
`tests/testthat/test-dinnage-audit-wave4a.R:37-38`: inside the test context the
diagnostic does not find the original data, so it does not report
`groups_lost=6`.

The stable route should not re-evaluate the user's original data expression from
`check_drm()`. It needs fit-owned metadata sufficient for this diagnostic, for
example original grouping values or per-term original group-level counts stored
when the model frame and `keep` vector are built. Re-evaluating `call$data` also
means `check_drm()` can change if the user mutates or removes a same-named data
object after fitting.

### #1343 Mi-5 residual rho12 boundary wording

Decision: ACCEPT-WITH-CHANGES.

Severity: P2.

The production change in `drm_wald_confint()` splits residual `rho12` boundary
warnings from random-effect SD and correlation boundary warnings
(`R/profile.R:2245-2267`). The residual-correlation path no longer recommends
`confint(method = "profile")`; a direct probe at the PR ref returned
`conf.status == "wald_at_boundary"` and warned:

```text
Profile intervals for residual rho12 at this boundary are usually identical
to Wald; read conf.status on the returned table instead of switching method.
```

That addresses Mi-5's user-facing confusion and preserves `rho12` as the
residual bivariate correlation name. The matching `check_rho12_boundary()`
message in `R/check.R:1516-1520` is consistent with the new advice.

The regression test is broken, however. `tests/testthat/test-dinnage-audit-wave4a.R:60-63`
passes the string `"residual-correlation boundary"` as the second argument to
`testthat::capture_warnings()`. In the installed testthat version that argument
is treated as `ignore_deprecation`, producing:

```text
Error in ignore_deprecation && is_deprecation(condition):
  invalid 'x' type in 'x && y'
```

Use a warning capture pattern that is compatible with the package's testthat
version, such as `expect_warning()` plus value capture, or
`withCallingHandlers()` with explicit message filtering.

## Scope and package-contract review

The PR stays inside drmTMB's univariate and bivariate DRM scope. It does not add
a likelihood, distribution family, parameter transform, random-effect grammar,
or public API. No design document update is required for the intended scope.

The A-8 change is diagnostic-only, but it needs a reliable fitted-object data
contract before merge. The Mi-5 change is diagnostic and interval-warning prose
only; no likelihood or interval calculation changes were found.

## Checks run

```sh
gh pr view 1369 --json number,title,headRefName,baseRefName,author,body,commits,files,mergeStateStatus,reviewDecision,url
gh pr diff 1369 --patch
git fetch origin pull/1369/head:refs/remotes/pr/1369
git worktree add /tmp/drmTMB-pr1369-review refs/remotes/pr/1369
cd /tmp/drmTMB-pr1369-review
Rscript -e 'devtools::load_all(); devtools::test(filter = "dinnage-audit-wave4a")'
```

Targeted test result:

```text
[ FAIL 3 | WARN 0 | SKIP 0 | PASS 1 ]
```

The failures were the missing `groups_lost=6` assertions for A-8 and the
`capture_warnings()` error for Mi-5.

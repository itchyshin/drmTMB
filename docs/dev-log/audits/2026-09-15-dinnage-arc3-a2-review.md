# Independent review: PR #1369 Wave A2 check.R

Date: 2026-09-15
Reviewer: Cursor reviewer subagent, independent of the builder
PR: <https://github.com/itchyshin/drmTMB/pull/1369>
Builder branch reviewed: `cursor/dinnage-arc3-a2-check-20260915`
Review branch: `cursor/dinnage-arc3-a2-review-20260915`

## Verdict

ACCEPT.

Re-reviewed at PR head `b6714135d5193bacdd8c2f10118de344e0db3c54`, which is
the builder's request-changes repair commit. The previous blocking A-8
local-scope failure is fixed, and the Wave4a regression test now passes with 11
assertions. No remaining P0/P1/P2 finding was found in the changed diagnostic
and warning paths.

## Per-finding decisions

### #1338 A-8 dropped random-effect groups

Decision: ACCEPT.

Severity: none remaining.

The repair no longer re-evaluates `object$call$data` from `check_drm()`.
`drmTMB()` stores the fit-time `input_data` aligned with the full `spec$keep`
vector, and `check_fit_input_data()` reads `object$model$input_data`. The
storage control path also drops this internal copy when
`drm_control(keep_data = FALSE)` is requested.

Local-scope reproduction at `b6714135d`:

```r
devtools::load_all(quiet = TRUE)
fit <- local({
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
})
drmTMB:::check_fit_input_data(fit)
drmTMB:::check_dropped_group_levels(fit)
check_drm(fit)[check_drm(fit)$check == "dropped_rows", ]
```

Observed:

```text
input_rows=320
lost_rows=1
  variable n_lost example
1       id      6       1
nobs=272; dropped=48; groups_lost=6
Rows were dropped by complete-case or known-covariance filtering. At least one
grouping variable lost every row for one or more levels: id lost 6 levels (for
example 1).
```

The Wave4a test now puts the fit inside `local({ ... })`, checks that
`check_fit_input_data(fit)` sees all 320 input rows, and verifies the public
`groups_lost=6` / `id lost 6 levels` diagnostic. This covers the exact
regression from the prior review.

### #1343 Mi-5 residual rho12 boundary wording

Decision: ACCEPT.

Severity: none remaining.

The production change in `drm_wald_confint()` splits residual `rho12` boundary
warnings from random-effect SD and correlation boundary warnings
(`R/profile.R:2245-2267`). The residual-correlation path no longer recommends
`confint(method = "profile")`; it tells users to read `conf.status` instead.
The matching `check_rho12_boundary()` message is consistent with the same
advice.

The previous test bug is fixed: the Wave4a test uses `expect_warning()` and
then checks `conditionMessage(warn)`, avoiding the incompatible unnamed
`capture_warnings()` argument.

## Scope and package-contract review

The PR stays inside drmTMB's univariate and bivariate DRM scope. It does not add
a likelihood, distribution family, parameter transform, random-effect grammar,
or public API. No design document update is required for the intended scope.

The A-8 change is diagnostic bookkeeping, and the Mi-5 change is diagnostic and
interval-warning prose only. No likelihood or interval calculation change was
found. Simulation tests are not required for this PR because it does not alter a
likelihood, estimator, or fitted parameter transformation; the focused
regression tests exercise the changed behaviour.

## Checks run

```sh
gh pr view 1369 --json number,title,headRefName,headRefOid,baseRefName,state,mergeStateStatus,author,url,latestReviews,comments
gh pr diff 1369 --name-only
gh pr diff 1369 --patch
git fetch origin pull/1369/head:refs/remotes/origin/pr/1369
git -C /private/tmp/drmTMB-pr1369-review checkout --detach b6714135d5193bacdd8c2f10118de344e0db3c54
Rscript -e 'devtools::load_all(); devtools::test(filter = "dinnage-audit-wave4a")'
Rscript - <<'EOF'
devtools::load_all(quiet = TRUE)
set.seed(1338)
fit <- local({
  n_id <- 40L
  n_each <- 8L
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n_id * n_each)
  )
  dat$y <- stats::rnorm(n_id * n_each)
  dat$y[dat$id %in% 1:6] <- NA_real_
  drmTMB(bf(y ~ x + (1 | id), sigma ~ 1), family = gaussian(), data = dat)
})
cat("input_rows=", nrow(check_fit_input_data(fit)), "\n", sep = "")
cat("lost_rows=", nrow(check_dropped_group_levels(fit)), "\n", sep = "")
print(check_dropped_group_levels(fit))
row <- check_drm(fit)[check_drm(fit)$check == "dropped_rows", ]
print(row)
EOF
```

Targeted Wave4a result:

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 11 ]
```

Manual local-scope reproduction:

```text
input_rows=320
lost_rows=1
  variable n_lost example
1       id      6       1
nobs=272; dropped=48; groups_lost=6
```

`git diff --check origin/main...HEAD` also reported no whitespace errors. Full
`devtools::test()`, `devtools::check()`, and pkgdown checks were not run for
this narrow re-review.

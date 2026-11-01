# After Task: #1513 Engine A (merge main, abort every term, C++ notes)

Reader: Shinichi, checking Engine A's five blockers on draft PR #1513.

## Goal

Clear the dirty merge with `main`, make the quadrature abort watch every
`mi()` term, skip the Gamma `weights = 2` fit on CRAN, keep the two C++
notes (`u_max` drop and AD vs FD where Newton branch B wins), recertify
C17, and run the full suite before pushing. Do not merge the PR. Do not
build a Beta low-mu runtime guard. Refs lines only.

## Implemented

`origin/main` (`d89db5097`) was merged into `cursor/triage-i-mi` as a
normal merge commit (`5525f0e99`). `simulate()` keeps the `mi()` weights
abort and takes main's lme4 `re.form` meanings.

`drm_spec_uses_mi_quadrature_abort()` now returns true when either
`missing_predictor` or `missing_predictor2` is an enabled Gamma, Beta,
or zero-one-Beta term. A Gaussian first slot no longer hides a Gamma
second slot.

A Gamma `mi()` node with `u_raw > 500` still reports a finite `x` at
the cap and now drops its `w cosh(t)` weight (`log_term -> -1e300`) in
both `src/drmTMB.cpp` and the R mirror. `n_cpp` is 46L. The huge-mu
paired guard expects at least one floor term.

Newton stays five steps. A compiled Gamma `mi()` tape pinned at the
pole (`y = 2.05`, prior mean 10, CV 0.5) — the geometry where branch B
wins — matches a central-difference gradient to `1e-5`.

Beta `mu = 0.02` stays the labelled skip. No low-mu guard.

## Mathematical Contract

Unnormalised log integrand: `log p_gamma(e^u) + log f(y | e^u) + u`.
Nodes `u_q = mode + sigma_u sinh(t_q)` with `t` on `[-5, 4]`. If
`u_raw > 500`, `x_q = exp(500)` is reported and that node's weight is
dropped so the cap is not quadrature mass.

## Files Changed

- `src/drmTMB.cpp`, `R/missing-data.R`: drop capped-node weight.
- `R/mi-weights.R`: abort helper checks both `mi()` slots.
- `tests/testthat/test-mi-quadrature-1476-1477.R`: every-term abort
  unit test; B-wins AD vs FD.
- `tests/testthat/test-guard-branch-continuity.R`: `n_cpp = 46L`;
  huge-mu floor term.
- `tests/testthat/test-mi-weights-1459.R`: `skip_on_cran()` on the
  Gamma `weights = 2` fit.
- `docs/design/03-likelihoods.md`, `NEWS.md`: cap drop and abort-every
  term.
- C17 receipt
  `docs/dev-log/implementation-recovery/2026-10-18-mi-quadrature-1513-r5-main-c17c2-c14-final-source-compatibility`.

## Checks Run

Focused (R 4.3.3, TMB 1.9.25, `NOT_CRAN=true`):
`test-mi-quadrature-1476-1477.R` 0 fail / 167 pass / 2 labelled skips;
`test-guard-branch-continuity.R` 0 fail / 69 pass; `test-mi-weights-1459.R`
0 fail / 55 pass.

C17 `--label mi-quadrature-1513-r5-main --tolerance 1e-10`: `|change|
0.000e+00` on mc-0568 / 0569 / 0576.
`--check-c14-receipt-equivalence` OK.

Full `testthat::test_dir()`: FAIL 67 / WARN 26 / SKIP 343 / PASS 46170.
All 67 failures are this VM's missing Suggests (`ape`, `emmeans`,
`mvtnorm`, `tweedie`, `JuliaCall`). Touched mi() files had 0 fail.

## Tests Of The Tests

The every-term abort test fails if only the first slot is read (a
Gaussian first + Gamma second used to return false). The huge-mu test
fails if a capped node keeps its `w cosh(t)` weight. The B-wins test
counts Newton branch B on the R mirror before comparing compiled
`obj$gr` to finite differences at the pole.

## Consistency Audit

```
rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" .
rg ":1301|:1342|:4556" R/mi-weights.R NEWS.md docs/design/03-likelihoods.md
```

Unweighted prior cites stay `:1434`, `:1475`, `:4678`. Beta rule
unchanged. No `Fixes` lines.

## GitHub Issue Maintenance

No issue filed. CV `>= 3` leftover stays
`docs/dev-log/2026-10-12-gamma-mi-cv-gt1-pole-follow-up-issue.md`
(refs #1477). Beta `mu = 0.02` stays refs #1476 / #1531.

## What Did Not Go Smoothly

The merge conflicted in NEWS, `simulate()`, check-log, and the C17 TSV
because both sides prepended. `simulate()` had to keep our `mi()`
weights abort on top of main's lme4 `re.form` default. C17 dest
`mi-quadrature-1513-r5` already existed, so this recert used label
`mi-quadrature-1513-r5-main`.

## Team Learning

A `pull_request` workflow does not run on a branch push until the PR
head moves. Merge `main` before asking CI to turn green.

## Known Limitations

Beta `mu = 0.02` vs `integrate()` is `4.81e-3` on the frozen 15-node
rule. CV `>= 3` remains the follow-up draft. No Beta low-mu runtime
guard (waits on Shinichi).

## Next Actions

Push `cursor/triage-i-mi` (no force). Keep the PR draft. Confirm CI
on the new head. Do not merge.

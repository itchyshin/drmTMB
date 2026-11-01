# After Task: #1513 Round 5 closeout (C17 and CV >= 3 skip)

Reader: Shinichi, deciding whether draft PR #1513 can stay as the
quadrature closeout or needs another round.

## Goal

Recertify C17 after the sinh-mapped Gamma `mi()` rule, keep a labelled
skip for CV `>= 3` that names the docs/dev-log draft issue (refs #1477),
and remeasure the Round 5 blockers against `integrate()` at absolute
`1e-4` per row. Do not merge. Refs lines only.

## Implemented

No further change to the quadrature. `src/drmTMB.cpp` still evaluates
the integrand, score and Hessian on `u = log(x)`, includes the Jacobian
`+u`, runs exactly five safeguarded Newton steps from `log(mu)`, and
places the 51 sinh-mapped nodes after step 5. This closeout adds the
CV `>= 3` skip, refreshes the env-skip census, recertifies C17, and
records the remeasured errors.

## Mathematical Contract

Unnormalised log integrand: `log p_gamma(e^u) + log f(y | e^u) + u`.
Score starts at `shape - x / scale` (the `+u` Jacobian cancels the
`-1` in `shape - 1`). Nodes `u_q = mode + sigma_u sinh(t_q)` with
`t` equally spaced on `[-5, 4]`. At CV `<= 1` that integrand is
smooth and single-mode.

## Files Changed

- `tests/testthat/test-mi-quadrature-1476-1477.R`: unconditional
  labelled skip for CV `>= 3`, naming
  `docs/dev-log/2026-10-12-gamma-mi-cv-gt1-pole-follow-up-issue.md`
  (refs #1477).
- `inst/extdata/env-skip-census.tsv`: one new `runtime-conditional`
  site on that file.
- C17 receipt
  `docs/dev-log/implementation-recovery/2026-10-18-mi-quadrature-1513-r5-c17c2-c14-final-source-compatibility`
  and rewired
  `docs/dev-log/dashboard/capability-ledger/2026-08-08-c17c2-c14-final-source-compatibility.tsv`
  (`current_source_sha = 3b4ac1054`).
- `docs/dev-log/known-limitations.md` and the follow-up issue draft:
  CV `>= 3` scan is 12% of 80 rows, worst `1.47`.

## Checks Run

Remeasured at `3b4ac1054`, R 4.3.3, TMB 1.9.25:

| Row | Before (Round 4) | After (Round 5) |
| --- | --- | --- |
| Gamma pole CV 0.5, `y = 2.05` | `4.0e-3` | `1.05e-8` |
| Gamma pole CV 1, `y = 2.05` | `0.28` | `1.82e-7` |
| Poisson CV 2, `y = 0` | abort / `8.3e-2` | `2.12e-5` |

Worst asserted row: Gaussian CV 2 `y = 2.2` at `2.48e-5`. All asserted
Gaussian CV 0.05--2 and Poisson CV 0.2--2 rows (`y` = 0, 1, 4, 30) are
under `1e-4`. Mode residual after step 5 at the pole: CV 0.5 `1.83e-3`,
CV 1 `4.47e-7`, CV 2 `-3.9e-13`.

`test-mi-quadrature-1476-1477.R` 0 fail, 1 labelled skip (CV `>= 3`).
`test-guard-branch-continuity.R` 0 fail (`n_cpp = 45L`). Compiled
per-row vs `integrate()` ran with `NOT_CRAN=true`.

C17 `python3 tools/recertify-c17.py --label mi-quadrature-1513-r5 --tolerance 1e-10`:
`|change| 0.000e+00` on mc-0568 / 0569 / 0576. Tracked run-1 was moved
aside, then restored. `python3 tools/capability_ledger.py --check-c14-receipt-equivalence`
prints OK (mc-0568 included). `source_fingerprint` is unchanged
(`5ab7a9640a93…`); the sinh map sits outside the authenticated
model-15 anchors.

Full suite follows this commit.

## Tests Of The Tests

The asserted rows compare each missing-x log marginal to a log-space
`integrate()` reference, including the pole (`y = 2.05` at `x* = 0.1`)
and near-mode (`y = 2.2`, `2.5`, `3.5`) geometry. The compiled path
reads the same marginal as `nll(with row) - nll(without row)` at fixed
parameters. The CV `>= 3` skip is a named follow-up, not a loosened
bar: an 80-row random scan at CV 3 still fails 12% (worst `1.47`).

## Consistency Audit

```sh
rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" .
rg "CV >= 3|sinh-mapped|1e-4" docs/dev-log/known-limitations.md docs/dev-log/2026-10-12-gamma-mi-cv-gt1-pole-follow-up-issue.md tests/testthat/test-mi-quadrature-1476-1477.R
```

Known-limitations, the follow-up draft, the skip message, and the
remeasured tables name the same leftover: CV `>= 3` and Poisson
`exp(eta)` at the prior mean of about `1e3`. Headers
`src/drm_numeric.h` and `src/drm_response_kernels.h` were not edited.
Unweighted Gaussian priors stay at `:1301`, `:1342`, `:4556`.

## GitHub Issue Maintenance

No GitHub issue was opened, commented on, or closed. The CV `>= 3`
follow-up stays the docs/dev-log draft (refs #1477). PR #1513 remains
draft and must not be merged. Refs lines only, never Fixes.

## What Did Not Go Smoothly

This VM booted without R on PATH. `r-base` 4.3.3, TMB 1.9.25, and
`libuv1-dev` (for `fs` / `testthat`) were installed locally. C17
run-1 is hardcoded; it was moved aside, not deleted, then restored.

## Team Learning

Recertify C17 last after the pin-file freeze, and treat the hardcoded
run-1 directory as a tracked artefact that must come back. A skip that
only fires when a convenient row fails can pass by accident; the
CV `>= 3` skip is now unconditional and names the draft issue.

## Known Limitations

CV `>= 3` (12% of an 80-row random scan over `1e-4`, worst `1.47`).
Poisson with `exp(eta)` at the prior mean of about `1e3` or more (CV
0.5 `4.53e-2`, CV 1.5 `1.55`). Poisson times Gamma is not reachable
through `drmTMB()`. U-shaped Beta remains #1531. The PR is `dirty`
against `main`.

## Next Actions

Run the full suite, push, and leave #1513 draft. Do not merge. Do not
raise the Newton step count without a decision. File or keep #1532
for the CV `>= 3` leftover.

# After Task: Julia input gates for weights, control defaults, and Hessian convergence

Reader: the next drmTMB contributor checking draft PR #1502, and an applied
user who calls `engine = "julia"` from a wrapper.

## Goal

Make three Julia-engine input checks agree with the values the user passed.
`weights = NULL` means no weights. A `drm_control()` value that equals the
default is the default. `is_converged(include_hessian = TRUE)` must look at
the covariance, not only the optimizer code.

## Implemented

`drmTMB()` now sets `weights_missing` with `drm_julia_weights_absent()`.
A missing argument and an evaluated `NULL` both count as no weights. An
expression that cannot be evaluated still counts as supplied, so the
weights refusal runs before Julia starts. The native TMB path still uses
`missing(weights)` only to capture `substitute(weights)` for the TMB data.

The Julia control comparison uses exact numeric equality after
`as.numeric()`, so `3L` matches `3` and `c(-12L, 12L)` matches
`c(-12, 12)`. An empty list matches `NULL` only for `start`. The
all-or-nothing gate is "no non-default fields". The joint adapter calls
the same helper. A value that differs, including `4L`, `c(-20, 20)`, and
a named start list, is still refused.

`is_converged()` for `drmTMB_julia` and `drmTMB_julia_xfam` validates
`include_hessian` and rejects extra arguments with the same messages as
the native method. The default call still reports optimizer code 0 only.
`include_hessian = TRUE` also requires a finite positive-definite
`object$vcov`, checked with `chol()`. Joint fits inherit the `drmTMB_julia`
method. A missing or non-positive-definite covariance returns `FALSE`.

`%||%` is defined in `R/zzz.R` as `if (is.null(x)) y else x`. Formula
marshalling and `drm_mspl_link_name()` already called it. Without the
definition, an open weights or control gate died with
`could not find function "%||%"` before the JuliaCall check.

## Mathematical Contract

No likelihood, link, or formula grammar changed. Location, scale, shape,
and residual correlation `rho12` are unchanged. The Hessian check is the
usual positive-definite test: `chol()` succeeds on a finite square numeric
matrix. It is stricter than a tolerance on the smallest eigenvalue, so a
covariance that is positive definite only up to rounding can return `FALSE`.

## Files Changed

- `R/drmTMB.R`: Julia return passes `drm_julia_weights_absent(weights)`.
- `R/julia-bridge.R`: weights helper, numeric control comparison, shared
  `is_converged` implementation.
- `R/julia-joint-missing.R`: joint default-control gate delegates to the
  shared helper.
- `R/zzz.R`: defines `%||%`.
- `R/check.R` and `man/is_converged.Rd`: document the Julia covariance rule.
  Roxygen was not re-run; the Rd page was edited to match the roxygen.
- `NEWS.md`: one bug-fix entry per user-visible change.
- `tests/testthat/test-julia-input-handling.R`: no-Julia regression tests.
- C17 receipt
  `docs/dev-log/implementation-recovery/2026-10-08-triage-c-bridge-inputs-c17c2-c14-final-source-compatibility/`
  and the manifest
  `docs/dev-log/dashboard/capability-ledger/2026-08-08-c17c2-c14-final-source-compatibility.tsv`.
- This report and `docs/dev-log/check-log.md`.

## Sibling paths

Weights: one flag feeds five refusals. Ordinary bridge, bivariate q2
structured, structured, cross-family, and `drm_julia_joint_prepare`.
Penalty, impute, and missing-predictor arguments were already checked by
value. There is no third engine.

Control: `drm_julia_translate_control`, `drm_julia_default_control`,
`drm_julia_nondefault_control_fields` (including optimizer subfields), and
`drm_julia_joint_default_control`. The empty-list-equals-NULL rule is
`start` only, so an empty optimizer list cannot hide a real optimizer setting.

Convergence: `is_converged.drmTMB_julia`, the `drmTMB_julia_xfam` override
(it must not keep the old one-line method), and joint fits, which inherit
the parent class. `predict` and `summary` do not implement
`include_hessian`. Stored-gradient reporting (#1452) was left untouched.

`%||%` is also used by Julia formula marshalling, the bridge payload, Julia
diagnostics, the family registry, and `drm_mspl_link_name()`.

## Checks Run

R 4.3.3 from apt. Julia was not installed. Expectations are `testthat`
`passed` counts.

| File or group | passed | failed | error | skipped | Environment |
| --- | ---: | ---: | ---: | ---: | --- |
| `test-julia-input-handling.R` | 92 | 0 | 0 | 0 | JuliaCall absent |
| same file | 92 | 0 | 0 | 0 | local JuliaCall stub, no Julia |
| 15 `test-missing-response*.R` | 1087 | 0 | 0 | 1 | JuliaCall absent |
| 11 CI mock-glue files | 1211 | 0 | 0 | 12 | JuliaCall stub |
| `test-julia-joint-call.R` alone | 2 | 0 | 1 | 0 | JuliaCall absent |
| same file inside the glue set | 4 | 0 | 0 | 0 | JuliaCall stub |
| `test-mspl-link-dispatch.R` | 18 | 0 | 0 | 0 | JuliaCall absent |
| `test-julia-optimizer-controls.R` | 58 | 0 | 0 | 0 | JuliaCall absent |
| `test-julia-control-refusal-names.R` | 99 | 0 | 0 | 0 | JuliaCall absent |
| `test-julia-joint-missing.R` | 39 | 0 | 0 | 0 | JuliaCall absent |
| `test-julia-joint-dispatch.R` | 8 | 0 | 0 | 0 | JuliaCall absent |
| `test-julia-joint-methods.R` | 47 | 0 | 0 | 0 | JuliaCall absent |
| `test-julia-joint-prediction-labels.R` | 8 | 0 | 0 | 0 | JuliaCall absent |
| `test-julia-bridge.R` | 139 | 0 | 0 | 2 | JuliaCall absent |
| `test-julia-structured-inference.R` | 4 | 0 | 0 | 1 | JuliaCall absent |
| same file inside the glue set | 48 | 0 | 0 | 0 | JuliaCall stub |
| `test-julia-sigma-phylo-reml.R` | 58 | 0 | 0 | 1 | JuliaCall absent |
| `test-coefficient-labels.R` | 122 | 0 | 0 | 5 | JuliaCall absent |
| `test-fit-convergence-warning.R` | 16 | 0 | 0 | 0 | JuliaCall absent |
| `test-check-drm.R` | 263 | 0 | 0 | 1 | JuliaCall absent |

The joint-call error without JuliaCall is `there is no package called 'JuliaCall'`
inside `local_mocked_bindings(.package = "JuliaCall")`. That test is in CI's
mock-glue step, and CI installs suggested packages, including JuliaCall. With
a namespace stub the same file passed 4 expectations.

`tools/recertify-c17.py --label triage-c-bridge-inputs --tolerance 1e-10`
reproduced model 15. `|change|` in `mean_tau_relative_error` was 3.030e-12
(mc-0568), 1.322e-11 (mc-0569), and 5.263e-12 (mc-0576). The fingerprint
stayed `5ab7a9640a9356b872086acc15fc431b839e9c2b710d7afe7ff667efb0fad61c`.
`python3 tools/capability_ledger.py --check` passed.
`python3 -m unittest tools/tests/test_capability_ledger.py` passed
(80 tests). The historical
`2026-08-01-lane-c-c17c1-c14-model15-compatibility-run-1` directory was
moved aside for the runner and restored. The full package check was not run
locally.

## Tests Of The Tests

Before `%||%` existed, the five open-gate expectations in
`test-julia-input-handling.R` failed with `could not find function "%||%"`.
That message is not a weights or control refusal, so those gates had already
opened. The closed-gate expectations in the same file passed on that run:
a real weight vector and `logsigma_clamp_margin = 4L` still match
"does not support" or the field name and do not match "JuliaCall".
The Hessian cases use constructed objects and do not dispatch to Julia.
A later edit accepts either the missing-JuliaCall message or the
missing-DRModels.jl message, because CI installs JuliaCall and then stops
on the checkout. Both environments passed 92 expectations.

## Consistency Audit

No formula-grammar or likelihood edit, so
`docs/design/01-formula-grammar.md` and `docs/design/03-likelihoods.md`
were not changed. `?is_converged` now states the Julia covariance rule.
NEWS names each behaviour change. Searched R, Rd, and docs for
`does not support weights yet` and for a claim that Julia
`include_hessian` is ignored. The remaining `missing(weights)` uses are the
helper's missing-argument branch and the native `substitute(weights)` line.
`.scratch/` copies were not edited.

## GitHub Issue Maintenance

No open pull request already covered #1450, #1471, or #1483. The draft PR
uses `Fixes` for all three because each requested behaviour is implemented
and tested without Julia. This task did not comment on or close the issues.
#1452 (stored gradient) stays open and out of scope.

## What Did Not Go Smoothly

The first open-gate failures were a missing `%||%`, not a wrong weights
test. `graft` is not installed in this environment. Installing `fs` from
source failed; apt supplied `fs`, `pkgload`, and `testthat`. The C17 runner
writes into a tracked historical directory, so that directory had to be
set aside and restored. The new test first required the string "JuliaCall",
which fails once JuliaCall is installed and the next stop is the DRModels
checkout.

## Team Learning

A Julia input gate is not proven by the absence of a refusal string if an
earlier missing operator aborts the same call. The regression test has to
reach the pre-dispatch requirement that sits after the gate.

## Known Limitations

No live Julia fit was run. `chol()` can reject a covariance that is only
numerically singular. `%||%` does not replace empty vectors, only `NULL`.
`is_converged(fit)` without `include_hessian` is unchanged, so a Julia fit
with optimizer code 0 and a bad covariance still returns `TRUE` under the
default. Cross-family objects store no `vcov`, so
`include_hessian = TRUE` returns `FALSE` for them.

## Next Actions

Watch the draft PR's `R CMD check`. Do not merge it from this task, and do
not close the three issues until that check is green and a reviewer accepts
the behaviour changes above.

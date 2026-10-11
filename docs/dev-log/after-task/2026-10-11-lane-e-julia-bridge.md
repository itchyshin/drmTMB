# Lane E: Julia-bridge R-side fixes (2026-10-11 bug-fix campaign)

## Goal

Close or triage the eight Julia-bridge issues assigned to lane E: #1498,
#1483, #1471, #1454, #1450, #1157, #1190, and #1148. The reader is the
maintainer merging the campaign's lane PRs, who needs to know which issue each
change closes, which issues are already handled by another open PR, and which
need an owner decision.

## Implemented

**#1498 (AIC/BIC/aicc skip the REML guard on `engine = "julia"`).** A bridge
fit has class `"drmTMB_julia"` and does not inherit `"drmTMB"`, so `AIC()`,
`BIC()` and `aicc()` fell through to `stats::AIC.default()`,
`stats::BIC.default()` and `aicc.default()`. None of them ran
`drm_warn_information_criterion()`, although the julia route fits REML and
records `estimator = "REML"`. The fix adds `AIC.drmTMB_julia()`,
`BIC.drmTMB_julia()` and `aicc.drmTMB_julia()` in `R/model-comparison.R`.
Each runs the guard and then `NextMethod()`, so values and the caller's row
names are unchanged. `drm_warn_information_criterion()` in `R/methods.R` now
reads julia fits too, so `AIC(tmb_reml_fit, julia_fit)` also warns from the
native side. `logLik.drmTMB_julia()` now attaches the `estimator` and `REML`
attributes that `logLik.drmTMB()` attaches. The secondary point in the issue,
an integrator-mismatch check (GHQ against Laplace), is not addressed: the
issue itself did not establish that the julia fit records its integrator.

**#1157 (first Julia call prints a wall of output).** The issue names two
sources of noise. The roughly fifteen lines of bridge internals, such as
`drmTMB_drm_bridge (generic function with 1 method)`, came from
`JuliaCall::julia_command()`, which displays a command's value unless the
command ends in `;` (upstream signature:
`julia_command(cmd, show_value = !endsWith(trimws(cmd, "right"), ";"))`).
The nine setup commands in `drm_julia_setup()` now go through
`drm_julia_setup_command()`, which appends `;`. Errors still propagate. The
red `LogExpFunctions` extension-load stacktrace is printed by Julia while it
loads the DRModels.jl environment inside `Base.require()`. Filtering it needs
Julia-side logger code that cannot be run in this container or in CI (no
runner has Julia), so it is left as a decision item rather than shipped
untested in the setup path.

## Not changed here, because another open PR already fixes them

Each finding was checked against `main` (`75845a3d`) with the installed main
build. All reproduce: `drm_control(logsigma_clamp_margin = 3L)` and
`drm_control(start = list())` are refused by `drm_julia_translate_control()`
(#1471). `is_converged(stub, include_hessian = TRUE)` returns `TRUE` for a
non-positive-definite `vcov`, and `include_hessian = "x"` is accepted (#1483).
`drmTMB(bf(y ~ x), data = d, engine = "julia", weights = NULL)` aborts with
"does not support `weights` yet" (#1450). Draft PR #1502 fixes all three, with
tests and green CI, so this lane does not re-implement them. Its
`drm_julia_weights_absent()` turns `weights_missing` into "no non-NULL
weights", and the joint route still refuses on `!isTRUE(weights_missing)`
(`R/julia-joint-missing.R`). Weighted joint `mi()` fits therefore stay refused,
which matches lane A's planned refusal in `drmTMB_julia_joint_bridge()` as
long as that refusal keys on the same flag.

#1454 (Julia NA alignment) is fixed by draft PR #1504, whose
`test-julia-missing-alignment.R` covers all four items of the issue:
cross-family staggered NAs, structured `response = "drop"`, q2 refusal of
incomplete rows, and a recorded complete-case count for `check_drm()`.

## Needs an owner decision

**#1190 (rho12 guard constants 0.999999, 0.99999999, 1 - 1e-12).** The issue
asks for a deliberate cross-engine decision. Aligning the constants changes
`rho12` point estimates and intervals on every committed bivariate receipt,
and the TMB constant lives in `src/` (lane B). Proposal: adopt DRModels.jl's
`0.99999999` in TMB and in the bridge back-transform in one coordinated change
that also re-pins the bivariate receipts, or keep the constants and document
the predicted offset `(G_jl - G_tmb) * rho / (1 - rho^2)` as the parity
tolerance on the `rho12` axis.

**#1148 (cold refit per profiled coefficient).** The issue states the fix
needs DRModels.jl to return a reusable fit handle or to accept several
targets in one call, and that it should wait for the DRModels.jl profile fix.
Proposal: add a multi-target `drm_bridge_fixef_inference` in DRModels.jl, then
batch `confint(parm = ...)` into one bridge call on the R side.

## Files Changed

`R/model-comparison.R`, `R/methods.R` (guard reads julia fits),
`R/julia-bridge.R` (`logLik.drmTMB_julia()` attributes and the quiet setup
helper), `NAMESPACE`, `man/model-comparison.Rd`,
`tests/testthat/test-model-comparison.R`,
`tests/testthat/test-julia-module-compat.R`, the regenerated C17 receipt, this
report, and its `docs/dev-log/check-log.d/` row.

## Checks Run

The new tests fail on an installed build of `main` (nine failures in
`test-model-comparison.R`; `drm_julia_quiet_command` not found in
`test-julia-module-compat.R`) and pass on the branch:
`test-model-comparison.R` 62 passed, 2 live-Julia skips. The JuliaCall-mocked
setup test that now also asserts every command ends in `;` skips here because
JuliaCall is not installable, but it runs in CI's mock-driven glue step.
`python3 tools/recertify-c17.py --label lane-e --tolerance 1e-10` reproduced
the receipt within 1.322e-11 on mc-0569, the same drift #1502 measured on
`main`. The full-suite totals are in the PR comment.

## What Did Not Go Smoothly

Roxygen 7.3.1 in this container differs from the repository's 7.3.2 and
rewrote 45 unrelated man pages; only `NAMESPACE` and
`man/model-comparison.Rd` were kept. `tools/recertify-c17.py` refuses to run
while the tracked `...-run-1` receipt directory exists, so it was moved aside
for the run and restored from git afterwards.

## Team Learning

Before starting a campaign lane, search open PRs for the lane's issue numbers:
four of eight issues here already had draft fixes with green CI.

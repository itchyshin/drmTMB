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

## Added after owner decisions and review (2026-10-11, later)

**#1190, settled by the owner.** The residual `rho12` guard in `src/drmTMB.cpp`
stays `0.999999`. The Julia bridge back-transform is aligned to it:
`drm_julia_residual_rho12_corpair()` now uses
`guarded_correlation_link(rho, guard = 0.999999)`, where it used `atanh(rho)`
with a `1 - 1e-12` clamp. The random-effect correlation guards are raised from
`0.999999` to `0.99999999` at the four families `rho_mu_re`, `rho_sigma_re`,
`rho_mu_sigma_re`, and `rho_mu_group` (17 sites in `src/drmTMB.cpp`).
Phylogenetic guards (`rho_phylo`, `rho_node`, `rho_block`, `rho_phylo_group`)
and the unguarded covariance-block partial correlations are unchanged.

R sites changed to the new `DRM_RE_CORR_GUARD <- 0.99999999` (defined in
`R/methods.R`), so R and TMB report the same response-scale correlation:
`rho_response()` callers for `atanh_re_guarded` and the `tanh` delta-method
derivative (`R/methods.R`), the `atanh_re_guarded` inverse-link derivative
(`R/predict-parameters.R`), five `DRM_CORR_GUARD` uses in `R/profile.R`
(all random-effect targets; the lane-C owner approved this minimal edit), and
the random-effect correlation reconstruction in `R/drmTMB.R`
(`split_tmb_corpars()`, `modelled_corpair_values()`,
`transform_mu_random_effects()` and the two sigma/mu-sigma transforms). The
test `test-re-correlation-guard.R` checks that R's `rho_response()` and
`split_tmb_corpars()` equal TMB's reported `rho_mu_re` at `eta` from -30 to 30.

Evidence on `nlme::Soybean` and `nlme::Loblolly` (the issue's boundary fits;
exact ML from `lme4` and DRModels.jl is `-949.534104140` and `-207.487513730`):

| fit | `main` logLik | this branch | gap before | gap after |
| --- | --- | --- | --- | --- |
| Soybean | -949.534171655 | -949.534104819 | 6.75e-5 | 6.8e-7 |
| Loblolly | -207.487516019 | -207.487513756 | 2.29e-6 | 2.6e-8 |

The branch reaches `1e-8` on Loblolly but not on Soybean. The shortfall is
proportional to `1 - guard`, so `0.99999999` leaves `6.8e-7`; a `1e-8` match on
Soybean needs a guard near `1 - 1e-10`. That is the owner's call and is listed
in the PR body. The likelihood-evidence question (boundary fits below `lme4`)
otherwise stays a separate follow-up.

**Review items on #1507.** The stale `parity-matrix.md` line citations are
regenerated with `tools/write-parity-matrix.R` at the pinned DRModels.jl commit
`da8b3f87` (it needs a UTF-8 locale); `test-parity-matrix.R` now runs its
"regenerates byte-identically" test instead of skipping it, and it passes. The
native-first `AIC()`/`BIC()` order is pinned by a test that fails if the
pre-filter in `drm_information_criterion()` is restored (checked by mutation).
`drm_ic_fixed_effect_signature()` now sorts dpar block names, so identical
bivariate fixed effects no longer trigger a false REML warning across engines
(native lists `mu1, mu2, sigma1, sigma2, rho12`; the bridge sorts alphabetically).

**#1521 item 1 (Windows `objective_at()` gap), analysis only, no code change.**
Not reproduced on Linux: `objective_at()` and `-logLik()` agree to `3e-9`. The
`phylo_penalty` is `0` here, so the penalty is not the cause. The inner Laplace
objective is start-independent to `6e-9` (cold start, warm start, and a start
shifted by 0.5 on all 126 random effects), so warm-start sensitivity is not the
cause on Linux either. The Windows numbers in #1521 are informative:
`objective_at()` gave `123.649519`, within `4e-6` of this machine's `123.649523`,
while Windows' stored `-logLik` is `123.649469`, `5.4e-5` lower than both. So on
Windows the stored `opt$objective` is not reproducible by re-evaluating
`fn(opt$par)`, which points at how the optimizer path (multistart selection or
the Newton polish in `drm_newton_polish()`) pairs `par` with `objective`, not at
`objective_at()` itself. One Windows run discriminates: print `fit$opt$objective`,
`fn(fit$opt$par)` after `drm_pin_tmb_object_to_optimum()`, the same call from a
cold inner start, `max(abs(gr(fit$opt$par)))`, and `fit$optimizer_attempts`. If
`fn(opt$par)` from the pinned state equals `123.649519`, a fix that re-anchors
`opt$objective <- fn(opt$par)` after the polish makes the stored `logLik`
re-evaluable by construction. It would shift stored logLik values by about `1e-9`
on Linux and touches the fit core in `R/drmTMB.R`, so it needs a Windows
confirmation first. The tolerance is not loosened.

**Not done here.** DRModels.jl #1057 matches the animal-model `A` by labels. The
bridge sends `A` with `dimnames` removed (`R/julia-bridge.R`, structured route),
so bridged animal fits will log the one-time "unlabelled A" warning. Sending the
`dimnames` as `ids =` needs the keyword name from DRModels.jl #1057, which is not
on its `main` yet, so it is a follow-up.

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

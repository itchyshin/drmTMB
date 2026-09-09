# After Task: temporal AR1 C1 dense boundary diagnosis

**Branch:** `codex/temporal-ou-v1-20260908`

**Date:** 2026-09-09
**Scope:** independently diagnose the retained AR1 C1 fixed-effect Wald interval failure before widening temporal inference claims.

## 1. Goal

Determine whether C1 seed `2026091002` loses its full observed-Hessian covariance because the latent-state TMB optimization is faulty or because the Gaussian marginal likelihood is nonregular at residual variance zero.

## 2. Implemented

Added two retained diagnostic runners. The first fixes residual SD in the native latent-state fit. The second independently evaluates the analytically marginalized Gaussian block likelihood, profiles the three mean coefficients by GLS, and optimizes the ordinary-intercept SD, temporal AR1 SD, and signed persistence. Its fixed-SD grid retains four starts at each of ten residual SD values; its free-SD run retains four starts.

## 3a. Decisions and Rejected Alternatives

The dense marginal profile is the deciding diagnostic because the native fits at the smallest fixed SD did not converge. It reproduces the native objective at converged `sigma = 0.1` and converges at every declared fixed SD. A higher positive-definite candidate near the boundary was not adopted for inference: it has a larger objective and would change the ML fit. No public inference rule or arbitrary near-zero warning threshold was added. The existing temporal Wald guard remains the honest interface until a boundary-inference method is separately designed and validated.

## 4. Files Touched

`tools/diagnose-temporal-ar1-c1-boundary.R` retains the original native fixed-scale attempts. `tools/diagnose-temporal-ar1-c1-dense-profile.R` and `docs/dev-log/simulation-artifacts/2026-09-08-temporal-ar1-c1-dense-marginal-profile/` retain the independent calculation, inputs, attempts, results, provenance, and R session. The OU gate ledger, check log, and dense-profile interpretation record the consequence.

## 5. Checks Run

| Check | Outcome |
| --- | --- |
| `Rscript --vanilla tools/diagnose-temporal-ar1-c1-boundary.R` | `TEMPORAL_AR1_C1_PROFILE_PASS`; lowest fixed-scale native attempts are retained as non-converged. |
| `Rscript --vanilla tools/diagnose-temporal-ar1-c1-dense-profile.R` | `TEMPORAL_AR1_C1_DENSE_PROFILE_PASS`; 40 fixed-SD and 4 free-SD dense attempts retained. |
| Dense versus native at fixed `sigma = 0.1` | Objectives agree to approximately `3e-10`. |
| `Rscript --vanilla -e 'parse(file = ...)'` for both runners | PASS: `TEMPORAL_C1_DIAGNOSTIC_PARSE_PASS`. |

## 6. Tests of the Tests

The dense runner would fail if any declared fixed-SD profile had no converged finite fit, if its 40 profile or 4 free attempts were not retained, or if the output directory already existed. It uses direct Cholesky evaluation of `s_b^2 11^T + s_a^2 R(phi) + sigma^2 I`, rather than the latent-state TMB implementation. Agreement at the converged fixed scale provides the bridge between the two likelihood calculations.

## 7a. Issue Ledger

No issue was opened or edited. This is an unpushed local diagnostic lane.

## 8. Consistency Audit

The gate ledger now identifies the dense profile as the evidence that reconciles the inherited C1 failure. The public OU documentation continues to state that its covariance and Wald intervals are unavailable. No documentation claims a qualified AR1 or OU interval.

## 9. What Did Not Go Smoothly

The native fixed-SD runner produced non-converged attempts at the smallest residual SD, so it cannot alone establish a likelihood boundary. The independent marginal calculation resolved that ambiguity: its objective is effectively flat from `1e-7` through `1e-4` and then increases with residual SD.

## 10. Known Residuals

The dense finite grid does not establish whether a finite residual-SD MLE exists exactly at zero. C1's full-Hessian Wald covariance remains unqualified. G7 through G9 and G14 through G15 remain open, and no recovery or coverage campaign was launched.

## 11. Team Learning

For a latent Gaussian model, a non-PD Hessian near a variance boundary needs an independent marginal-likelihood calculation before it is attributed to the optimizer. A converged dense profile can show the likelihood geometry without converting a boundary diagnostic into a new inference claim.

## 12. Cross-Product Coverage

This task covers the retained C1 combined random-intercept-plus-AR1 calibration seed only. It does NOT cover an inferential repair, variance-component intervals, OU Wald intervals, recovery thresholds, coverage, forecasts, non-Gaussian models, REML, or a remote campaign.

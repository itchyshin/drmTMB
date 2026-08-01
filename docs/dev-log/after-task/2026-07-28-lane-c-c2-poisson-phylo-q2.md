# After Task: Lane C C2 Poisson phylogenetic labelled q2 covariance

## 1. Goal

Implement C0-07 only and retain local technical point-recovery evidence for
ordinary Poisson labelled phylogenetic intercept--slope covariance.

## 2. Implemented

The exact `phylo(1 + x | p | species, tree = tree)` Poisson `mu` route now has
two latent SDs and one latent correlation. Its model-type-6 TMB branch uses the
joint q2 (Q^{-1}\otimes\Sigma) density, including determinant and
cross-precision terms.

## 3a. Decisions and Rejected Alternatives


((b_0,b_1)^\top \sim N\{0,\Sigma(\tau_0,\tau_1,\rho)\otimes Q^{-1}\}),
where (\rho=.999999\tanh(\eta_{cor})). At (\rho=0), the joint density is
exactly the previous independent q-vector density.

| Symbol | Formula / implementation | DGP | Extractor | Truth |
| --- | --- | --- | --- | --- |
| `beta0`, `beta1` | fixed `count ~ x` log-mean terms | `eta` intercept and slope | `coefficients$mu` | `1.00`, `0.35` |
| `b0`, `b1` | labelled `phylo(1 + x | p | species)` q2 field | `t(chol(K)) %*% Z %*% chol(Sigma)` | two `sdpars$mu` entries | latent fields |
| `tau0`, `tau1` | `exp(log_sd_phylo)` | diagonal of `Sigma` | named phylo SDs | `0.60`, `0.50` |
| `rho` | `.999999 * tanh(eta_cor_phylo)` | off-diagonal of `Sigma` | `corpars$phylo` | `0.50` |
| `Y` | Poisson log-mean likelihood | `rpois(exp(eta))` | objective/oracle only | Poisson response |

Kept the C0-04 q2 architecture as an explicit Poisson-only branch rather than
introducing a provider-general count covariance engine. Rejected C0-08 spatial,
C0-09 animal, C0-10 relmat, zero inflation, ordinary-RE coexistence, scale-side
work, profiles, intervals, bootstrap, coverage, remote compute, and any public
capability promotion.

## 4. Files Touched

`R/drmTMB.R`, `src/drmTMB.cpp`, `tests/testthat/test-count-structured-mu.R`,
the C2 runner and retained receipt, design map, C2 ultra-plan, plan-vs-actual,
and this report.

## 5. Checks Run

- Lane preflight: no Claude lane detected in its 12-hour window; weak evidence.
- Focused `count-structured-mu` test file: passed after the C2 tests were added.
- C2 local three-seed runner: 3/3 valid attempts and
  `PASS_POINT_RECOVERY_LOCAL`.
- C2 IID DGP control: `PASS_IID_DGP_CONTROL`.
- `git diff --check`: passed before closeout artifacts were added.

## 6. Tests of the Tests

The independent dense Poisson oracle reconstructs both the likelihood and the
joint q2 prior. It checks zero-correlation reduction, nonzero-correlation
liveness, and a central finite-difference gradient against TMB. Rejection tests
cover C0-08–10 and the nearby unsupported formula forms.

## 7a. Issue Ledger

Resolved the C0-07 implementation gap. The other 38 unimplemented intake cells
remain deferred; no issue or capability status changed. GitHub issue lookup was
attempted but unavailable because the local client could not reach the API.

## 8. Consistency Audit

The formula validator, data flag, shared map, correlation extractor, and C++
Poisson penalty agree on the same exact phylo-only q2 predicate. The independent
Poisson loop remains the fallback for all other shapes.

## 9. What Did Not Go Smoothly

The first runner invocation used a non-symbol tree expression and generated
three parser errors before any model fit. Those files are retained under
`initial-runner-error/`; the runner was corrected and the frozen fixture then
ran unchanged. A temporary C++ patch was also placed in a neighbouring branch
and removed before focused compilation/testing.

## 10. Known Residuals

This is one small local receipt for C0-07. It is not evidence for C0-08–10,
zero inflation, scale-side structures, ordinary-RE coexistence, q4, intervals,
profiles, bootstrap, coverage, association, or public capability.

## 11. Team Learning

The C0-04 q2 penalty was genuinely reusable, but its validation predicate had
to be widened only to ordinary Poisson, not to a provider-general count route.
Formula objects in retained runners must use named objects, not `$` expressions.

## 12. Cross-Product Coverage

Covers only ordinary univariate `poisson()` `mu`, one labelled phylogenetic
intercept--slope q2 covariance block, named latent SDs/correlation, deterministic
tests, and a retained local point-recovery fixture. It does not cover either
other Lane C provider, any interval or coverage grade, Lane A, Lane B, or a
public/default/API expansion.

## Next Actions

Obtain fresh focused review of the candidate, then commit only scoped Lane C
files. A new plan is required before considering any remaining C2 provider.

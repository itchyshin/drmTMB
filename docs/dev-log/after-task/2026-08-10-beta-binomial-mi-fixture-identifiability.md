# After-task — `main` CI unblocked: the beta-binomial `mi()` fixture could not identify `sigma_mi`

Date: 2026-08-10 · Platform: Claude Code · Branch: `claude/fix-beta-binomial-mi-fixture-conditioning`

## 1. Goal

Return `origin/main` to a green `R CMD check`. It had been red since `fddb82105` (PR #972), which
blocked every open PR against it and therefore the whole 0.7.0 release path.

## 2. Implemented

One change, to one fixture function: `missing_predictor_beta_binomial_data()` in
`tests/testthat/test-missing-predictor-beta-binomial.R` now generates **genuine extra-binomial
variation** deterministically, by drawing the latent success probability from Beta quantiles at one
permuted level and the count from binomial quantiles at another:

```r
sigma_mi_true <- 0.35
phi <- 1 / sigma_mi_true^2
mu_mi <- stats::plogis(-0.25 + 0.85 * z)
latent_level <- ppoints(n)[order(order(cos(2 * seq_len(n))))]
count_level  <- ppoints(n)[order(order(sin(seq_len(n))))]
p <- stats::qbeta(latent_level, mu_mi * phi, (1 - mu_mi) * phi)
success_full <- stats::qbinom(count_level, size = trials, prob = p)
```

No `set.seed`, no stochastic draw — the fixture stays deterministic, matching the other
missing-predictor fixtures. `qbinom()` is evaluated row-wise, so `success <= trials` holds by
construction even though `trials` varies per row.

## 3a. Decisions and Rejected Alternatives

Shinichi chose **harden the fixture** over three alternatives: widening the assertion to accept
`sdreport_non_pd_hessian`, `skip_on_ci()`, and treating the near-singularity as a real defect in the
`mi()` route. Rationale: only hardening leaves a green CI meaning something.

**A rejected fix that looked right and was measurably wrong.** The first proposal was to copy the
`nbinom2` siblings' de-correlation idiom — permute the `qbinom` quantile levels and shrink them off
0/1 — on the theory that `cor(cover, z) = 0.993` was the problem. Fisher refuted it in Phase-2 plan
review *before it was implemented*, and the refutation was reproduced independently:

| fixture | Pearson dispersion | VIF(cover\|z) | argmin `sigma_mi` | boundary profile deviance |
|---|---|---|---|---|
| current (on `main`) | 0.201 | 71.2 | 0.001 (edge) | **0.000** |
| rejected proposal | 0.611 | 4.34 | 0.001 (edge) | **0.000** |
| adopted (latent Beta) | 1.994 | 2.11 | **0.35** | **13.234** |

The rejected proposal fixes the collinearity (VIF 71 → 4.3) and **leaves the actual defect exactly
untouched**. That is the whole lesson of this task.

## 4. Files Touched

- `tests/testthat/test-missing-predictor-beta-binomial.R` — fixture only (21 insertions, 2 deletions).
- `docs/dev-log/simulation-artifacts/2026-08-10-beta-binomial-fixture-identifiability/` — the two
  measurement scripts and their output, so the numbers above have a receipt rather than living only
  in a commit message.
- This report; `docs/dev-log/check-log.md`.

No `R/`, `src/`, `man/`, `NAMESPACE`, or ledger change. `capability_ledger.py --check` → `OK (31
generated outputs)`, unchanged.

## 5. Checks Run

| check | result |
|---|---|
| `test-missing-predictor-beta-binomial.R` (whole file, 30 assertions) | **PASS**, and the three pre-existing `false convergence (8)` warnings are **gone** |
| `test-missing-predictor-gaussian.R` (109) | PASS |
| `test-missing-predictor-binary.R` (24) | PASS |
| `test-missing-predictor-categorical.R` (26) | PASS |
| `test-missing-data-robustness.R` (15) | PASS |
| `python3 -B tools/capability_ledger.py --check` | `OK (31 generated outputs)` |

Acceptance table on the fit at line 138 (the one that was red):

| criterion | before | after | gate |
|---|---|---|---|
| convergence warning | `false convergence (8)` | **none** | none |
| `sdr$pdHess` | TRUE (marginal) | TRUE | TRUE |
| max eigen `cov.fixed` | ≈ 320 | **0.0255** | < 100 |
| condition number | **3.63e+07** | **2,318** | — |
| `se(log_sigma_mi)` | — (unidentified) | **0.159** | < 1 |
| `uncertainty_status` | `sdreport_non_pd_hessian` | `ok` | `ok` |
| recovered `sigma_mi` | boundary (→ 0) | **0.297** (truth 0.35) | identified |

## 6. Tests of the Tests

The gate-zero diagnostic runs with **no package load and no fit** — it is a property of the DGP
alone, so it cannot be confounded by the optimizer. It was validated by running it on the *current*
fixture first and reproducing the known-bad numbers (dispersion 0.201, boundary deviance 0.000)
before trusting it on the candidates. The `success <= trials` invariant is asserted inside the
diagnostic, not assumed.

## 7a. Issue Ledger

No ledger cell, census, capability promotion, or release rung moved. `DESCRIPTION` stays 0.6.0.

## 8. Consistency Audit

The inherited handover (`2026-08-10-claude-handover.md`, on `claude/07-hash-ledger`) attributed this
failure to a missing Julia package `Suppressor` and proposed two Julia-side fixes. That was verified
wrong and corrected in `062250f19`: the `LoadError` is Julia **teardown noise** printed after
`Execution halted`, all Julia tests skipped correctly (305 skips), and **neither** proposed Julia fix
would have turned `main` green — they address at most the `jl_*` temp-directory NOTE.

## 9. What Did Not Go Smoothly

Two diagnoses were wrong before the right one, and both were wrong in the same *direction* — they
blamed a visible surface statistic instead of the likelihood. The handover blamed Julia because a
Julia error string was the last thing in the log. The first repair proposal blamed collinearity
because `cor(cover, z) = 0.993` is conspicuous. Neither was the flat direction. What settled it was
profiling the actual parameter (`sigma_mi`) rather than inspecting summaries of the design.

Two acceptance criteria in the first plan were also measuring the wrong end of the spectrum:
`min eigen(cov.fixed) > 1e-4` (a flat direction inflates the *max* covariance eigenvalue, not the
min) and `cor(cover, z) < 0.3` (unreachable — no proposed variant got below 0.65, so the plan would
have self-terminated). Both were replaced on Fisher's review.

## 10. Known Residuals

- **The MD7f `0:n_i` summation is still only lightly exercised.** `y` is a noiseless function of
  `cover` and `z`, so the posterior over the support is near a point mass (≈ 1.0–1.8 effective
  support points out of 9–17). `rowSums(probs) == 1` and `estimate ∈ [0,1]` therefore certify less
  than they appear to. Giving `y` a residual of order `1.15/n_i` would make it a real test — **scope
  change, needs its own decision.** Flagged, not done.
- The existing `skip_on_cran()` calls and their BLAS/LAPACK comments are **kept**. They cite R-hub
  clang-sanitizer containers that cannot be re-run here, so removing them would be unevidenced —
  even though the underlying `lgamma` cancellation that motivated them is much reduced now that
  `phi ≈ 8` rather than `phi → 10^6`.
- The Julia guard question (`skip_if_not_installed("JuliaCall")` vs installing Julia in CI) and the
  `jl_*` detritus NOTE remain open and belong to the Julia lane.
- Green ubuntu CI on the PR is the only evidence that actually settles a BLAS-dependent failure;
  local macOS success is necessary, not sufficient.

## 11. Team Learning

**A parameter pinned at its boundary and a badly conditioned design look identical in `cov.fixed`,
and the cheap summary statistics point at the wrong one.** The distinguishing measurement is a
one-dimensional profile of the suspect parameter — here, profile deviance at the boundary, which was
*exactly* 0.000 both before and after the plausible-looking repair. It costs milliseconds and needs
no model fit.

Second: **`q<dist>(ppoints(n), ...)` generates a distribution's quantiles, not its variability.**
Using `qbinom` to build a fixture for a *beta*-binomial model produced data that were under-dispersed
(0.20) relative to the binomial the overdispersion parameter is supposed to extend, so that parameter
had no likelihood information at all. Any family with a dispersion parameter needs a fixture that
actually generates dispersion.

Third, on process: the Phase-2 plan review paid for itself. Fisher's refutation arrived **before**
any code was written, on a plan that had already survived a scope/claims review.

## 12. Cross-Product Coverage

`DRM.jl` carries the beta-binomial likelihood (`src/betabinomial.jl`) but not this R test fixture; no
port is implied. `gllvmTMB` has no analogue of the missing-predictor fixture family. The lesson in
§11 is repo-general and applies to any fixture for a dispersion-parameter family.

# After Task: MSPL Wald standard errors

Date: 2026-08-09 · Lane: MSPL inference promotion ·
Branch: `claude/mspl-binomial-inference-promotion` · Platform: Claude Code

## 1. Goal

Make `drmTMB(..., estimator = "mspl")` report standard errors for drmTMB 0.7.0,
**claim-bounded**: a standard error is a reported quantity, an interval is a coverage claim, and
only the first ships. Owner decision, 2026-08-09.

## 2. Implemented

The estimand was fixed in `docs/design/251-mspl-wald-covariance-alignment.md` **before** any code,
and the contract it contradicted was amended explicitly rather than silently unlocked
(`250`, "Phase 4 amendment").

```
V = [ −∇²ℓ_L(θ) |_{θ = θ̃} ]⁻¹ ,   SE_j = √V_jj
```

the inverse observed information of the **unpenalized** Laplace log-likelihood at the MSPL estimate.
The penalized Hessian stays a diagnostic: it adds the penalty's curvature to the likelihood's, which
shrinks standard errors most in exactly the separated directions where the penalty is carrying the fit.

| Surface | State |
|---|---|
| `vcov()` | **unlocked** — full outer-parameter block |
| `summary()$coefficients$std_error` | **unlocked** |
| `confint()`, `profile()`, `logLik()`, `AIC`, `BIC`, `anova()`, `summary(conf.int=TRUE)` | **still error**, verified individually |

Reused rather than rebuilt: `drm_mspl_hessian_diagnostics()` was already generic in `obj`, and
`drm_mspl_unpenalized_objective()` already returned the unpenalized ADFun. The new work is the SPD
gate, the inversion, and the surface.

## 3a. Decisions and rejected alternatives

- **Rejected the penalized Hessian** as the reported covariance — it is the optimizer's curvature,
  not the likelihood's, and using it would understate uncertainty precisely where uncertainty is
  greatest.
- **No sign flip.** `obj$fn` for a `random=` TMB object is the *negative* log-likelihood, so
  `optimHess` already returns the observed information. Stated at the inversion site and enforced by
  a test.
- **SPD-gate failure returns NA plus a typed `drmTMB_mspl_wald_unavailable` warning**, not a hard
  error and not a fabricated number. It fires on exactly the strongly separated fits MSPL exists for,
  so `summary()` must stay usable. Mirrors the shipped `drmTMB_profile_boundary_warning` idiom rather
  than inventing a pattern.
- **`vcov()` dimnames rebuilt.** TMB names every fixed-effect outer parameter `beta_mu`, so the raw
  names were duplicated and un-indexable. Reuses `coefficient_labels()`; `vcov(fit)["mu:x","mu:x"]`
  now works and `sqrt(diag(V))` matches `summary()` exactly.
- **Did not generalise to probit/cloglog.** Scoped to 0.7.1 — see
  `docs/design/252-binomial-link-generalisation.md`.

## 4. The oracle — what actually proves this correct

On a **non-separated** fixture where the penalty is negligible, MSPL standard errors match ordinary
ML `sdreport()` standard errors:

| coefficient | ML SE | MSPL SE | relative difference |
|---|---|---|---|
| `mu:(Intercept)` | 0.15591 | 0.15650 | **0.38 %** |
| `mu:x` | 0.11808 | 0.11810 | **0.01 %** |

And it converges the way theory says it must — a size ladder `n = 48 / 180 / 480 / 960` gives
`1.7 % / 0.4 % / 0.1 % / 0.04 %`, shrinking monotonically as `c_n = 2√(p/n_eff)` vanishes. That is
the evidence that the correct Hessian is being inverted, not a single lucky fixture.

**The predicted irregularity also showed up.** Design 251 §3 says the unpenalized score cannot be zero
at the MSPL estimate, because that estimate maximises the *penalized* criterion. Measured:
`unpenalized_gradient_max_abs = 0.1321`, against a penalized-criterion convergence gradient of
`2.03e-06`. Both are now printed by `summary()`, labelled, because a reader seeing only the near-zero
number could reasonably conclude the stationarity concern was handled. It is not.

## 5. Checks run

- `devtools::document()` — exit 0, clean; regenerated `drmTMB.Rd` and `model-fit-extractors.Rd`.
- Focused set (`mspl|binomial|summary|vcov|methods|profile|confint|coxreid`): **209 files, 1958 pass,
  0 fail, 0 error, 3 routine skips**.
- Post-review-fix set (`mspl|coxreid|summary`): **71 files, 655 pass, 0 fail, 0 error**.
- `--as-cran`: see §5a.
- Spelling: the test is `error = FALSE` (report-only) by design, so new prose cannot fail the check.

### 5a. `--as-cran`

`rcmdcheck::rcmdcheck(args = "--as-cran", error_on = "never")` on the exact final commit
**`24abee2fd4be24d5276d5a1b4b3361a999a6592f`**, working tree clean:

```
ERRORS: 0   WARNINGS: 0   NOTES: 1

N: checking CRAN incoming feasibility ... [4s/22s] NOTE
   Maintainer: 'Shinichi Nakagawa <itchyshin@gmail.com>'
   New submission
```

The single NOTE is the unavoidable first-CRAN-release marker and is not actionable.

Run twice, deliberately. The first run covered `1d6cd5330` (the implementation commit) and returned
the same `0 / 0 / 1`. The review fixes then landed as `24abee2fd`, so that first result described
code that no longer shipped; it was re-run rather than reported with a caveat. Both results agree,
which also confirms the review fixes introduced nothing.

## 6. Tests of the tests

Six obligated tests from design 251 §9, all added: the ML oracle above; a **sign-convention** test
that fails against a negated implementation; penalized ≠ unpenalized Hessian with `vcov` provably
derived from the unpenalized one; separated fixtures asserting large-and-finite **or**
NA-with-warning and never silently small; `unpenalized_gradient_max_abs` recorded and non-zero; and
naming consistency between `vcov()` and `summary()`.

The ~8 pre-existing assertions that asserted the *absence* of standard errors were **split**, not
deleted — `vcov`/`std_error` flipped to positive assertions, every other fence kept asserting its
error and class.

## 7a. Claim boundary — binding

- **A standard error is reported. An interval is not claimed, and is not implied.** Enforced in code:
  `vcov()` lifts, `confint()` does not.
- **q1 and q2 are NOT validated to the same standard.** q1 has an external ML-`sdreport()` oracle.
  **q2 has only internal `vcov`-vs-`summary` self-consistency** — no independent comparator. Do not
  describe them as equally evidenced. (Fisher.)
- **"SEs are reported" and "SEs are usable" are different claims, and only the first is tested.** The
  oracle proves the right Hessian is inverted *in the zero-penalty limit*. It says nothing about SE
  quality when the penalty is not negligible — i.e. the separated regime MSPL exists for. The
  separated-fixture tests deliberately check only "large-and-finite or NA", never correctness.
- **No coverage, calibration, recovery, bias, or RMSE claim.** Those need the separately authorized
  campaign.
- **No capability-ledger or census movement.** MSPL remains experimental.

## 7b. Open question this arc does not answer

There is **no enforced threshold** on `unpenalized_gradient_max_abs`, and no scale-free
interpretation of it. Design 251 says record; the code records; the test asserts only finite and
`> 0`. Whether 0.13 is "large" is **unanswerable from this repository** — there is no calibration
linking gradient magnitude to SE distortion, and no comparator at that magnitude. Fisher raised this
and it is recorded as open rather than resolved by assertion. A future arc could normalise it (by the
score SD or by the information) and set a gate.

## 8. Reviews

- **Fisher** — `SUPPORTS-SHIP-WITH-NARROWING`. Would have **refused** one item: `?drmTMB` still said
  Wald SEs "are deliberately unavailable", a factual error about shipped behaviour on the most-read
  help page. Fixed, along with the missing extractor-doc caveat and the single-gradient display.
- **Noether** — `ALIGNED-WITH-CAVEATS`, **no mathematically required change**. Verified the sign
  convention by tracing the C++: `src/drmTMB.cpp:501` initialises `nll = 0`, `:3344-3346` accumulates
  the joint NLL unconditionally, and `:5018-5019` adds the penalty only when `use_mspl == 1`, so
  `use_mspl = 0` genuinely yields `−ℓ_L`. Two precision fixes applied: design 251 §1 had reused note
  250's phrase "frozen Cholesky coordinates" for `ψ`, ambiguous because the penalty lives on
  `(log L11, log L22, L21)` while the Wald covariance is on the optimisation coordinates
  `(β, log_sd_mu, eta_cor_mu)`; and two comments overstated their mechanism.

Both reviewers' findings **narrowed the claim or corrected the docs**; none were argued away.

## 9. What did not go smoothly

**My reconcile broke a test and I did not catch it in the reconcile slice.**
`test-reml-binomial-coxreid.R` is **new on main from #953**, so the MSPL branch had never seen it, and
my neighbour-test filter during the reconcile did not include it. It carried **two** assertions of the
pre-widening wording of `validate_binomial_mu_random_terms()`, which changed when the experimental
unlabelled correlated q = 2 block was admitted. The sub-agent reported it as "pre-existing, confirmed
on the stashed baseline" — technically true but misleading, since stashing only its own changes left
the reconcile in place. Both models are still **rejected** under REML (verified directly); only the
message moved, and the new one names the actual reason. Then swept the class: no assertion of the old
wording survives anywhere.

**A shipped helper had duplicated dimnames.** `vcov()` returned TMB's raw `beta_mu, beta_mu,
log_sd_mu`, so a user could not index it. Caught on independent verification, not by the producer.

## 10. Known residuals

- q2 Wald SEs lack an external oracle (§7a).
- No gradient-diagnostic threshold (§7b).
- `vcov()` shape differs between MSPL and ordinary fits — documented, but a latent break for code that
  assumes a portable `vcov()` dimension. (Fisher.)
- probit/cloglog and the link-general Jeffreys penalty are 0.7.1 work.
- No PR opened: Doc B reserves push/PR/merge on this lane to the owner.

## 11. Team learning

**Fixing the estimand before the code paid for itself twice.** Design 251 predicted, from the algebra
alone, that the unpenalized score would be non-zero at the MSPL estimate — and the implementation then
measured 0.13 against a convergence gradient of 2e-06. Because the prediction existed first, that
number was a *confirmation* rather than a puzzle, and it became a printed diagnostic instead of an
unexplained anomaly.

**The same lesson as the separation lane, in a different costume:** a return contract that asks for
conclusions invites narration; one that asks for pasted command output invites execution. Every
sub-agent number in this arc was re-run independently, and doing so caught a real defect the producer
had reported as clean.

## 12. Cross-product coverage

Covers the experimental binomial-logit MSPL estimator's Wald standard errors only. Does **not** cover
probit/cloglog, multinomial, penalized-profile intervals, parametric bootstrap, coverage or
calibration, REML, `zi`/`hu`, gllvmTMB, DRM.jl, the capability ledger or census, `DESCRIPTION`,
release wording, CI, or any CRAN action.

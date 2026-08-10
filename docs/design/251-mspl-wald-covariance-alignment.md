# MSPL Wald covariance — symbolic alignment

Status: **design only**. Nothing in this note is implemented. It fixes the estimand,
the gate, and the claim boundary *before* code, so the implementation has something to
be checked against rather than derived alongside.

Companion to `docs/design/250-mspl-binomial-logit-alignment.md`, which froze the MSPL
point-estimation contract. **§7 below records an amendment 250 requires**, because 250
as written forbids exposing what this note designs.

## 1. Notation

Following 250 §"penalty form", for the admitted binomial-logit surface:

| symbol | meaning |
|---|---|
| `β` | fixed-effect coefficients, `p` of them |
| `ψ` | covariance parameters in the **optimisation** coordinates: `log_sd_mu`, plus `eta_cor_mu` for a q = 2 block |
| `θ = (β, ψ)` | the **outer** parameter vector, after Laplace marginalisation of the random effects |
| `ℓ_L(θ)` | the **unpenalized** Laplace-approximate log-likelihood |
| `P_f(β)` | fixed-effect Jeffreys term |
| `P_v(·)` | negative-Huber term, on the **penalty** coordinates — see the warning below |
| `c_n = 2√(p / n_eff)` | softness scale, `n_eff = Σ fᵢ mᵢ` |

> **Two coordinate systems, and they are not the same one.** Note 250 writes the
> negative-Huber penalty on the derived Cholesky entries `(log L11, log L22, L21)`
> (`R/mspl.R`, `src/drmTMB.cpp`). The Wald covariance in this note is **not** on those.
> It is on the coordinates the optimizer actually varies — `(β, log_sd_mu, eta_cor_mu)` —
> because the Hessian is taken directly on `opt$par`. No Jacobian or delta-method step is
> applied, and none is needed, precisely because the two never mix. An earlier draft of
> this table reused 250's phrase "frozen Cholesky coordinates" for `ψ`, which was
> ambiguous; the implementation was always correct. (Noether, C5 review.)

The MSPL criterion and its maximiser:

```
ℓ_MSPL(θ) = ℓ_L(θ) + c_n { P_f(β) + P_v(ψ) }
θ̃        = argmax ℓ_MSPL(θ)
```

## 2. The estimand

**The reported covariance is the inverse observed information of the *unpenalized*
Laplace log-likelihood, evaluated at the MSPL estimate:**

```
V  =  [ −∇²ℓ_L(θ) |_{θ = θ̃} ]⁻¹
SE_j = sqrt( V_jj )
```

This is the method-paper target named in the MSPL handover: *"invert the Hessian of the
independently evaluated unpenalized Laplace approximate likelihood at the MSPL estimate.
The penalized Hessian remains an optimizer diagnostic, not the primary frequentist
covariance."*

**Why not the penalized Hessian.** `−∇²ℓ_MSPL` adds the penalty's curvature to the
likelihood's. The penalty is a device for obtaining a finite estimate, not a statement
about sampling variability, so including it makes the information matrix *larger* and
therefore the standard errors *smaller* — and it does so most aggressively in exactly the
separated directions where the penalty is carrying the fit. Using it would understate
uncertainty precisely where uncertainty is greatest. It stays a diagnostic.

**What honest behaviour looks like under separation.** In a separated direction `ℓ_L` is
monotone with vanishing curvature, so `V` has a large diagonal entry there and the
reported SE is enormous. **That is the correct answer, not a defect** — it is the model
saying the coefficient is not identified by the data. Implementations must not "fix" it.

## 3. The known irregularity — state it, do not paper over it

`θ̃` maximises `ℓ_MSPL`, **not** `ℓ_L`. Therefore

```
∇ℓ_L(θ̃) ≠ 0   in general.
```

The textbook Wald justification evaluates the observed information *at the MLE*, where the
score vanishes. Here it is evaluated at a penalized estimate, and under separation the
unpenalized MLE does not exist at all, so there is no MLE to evaluate at. The method-paper
choice is deliberate and defensible, but the usual asymptotic argument does not transfer
unmodified.

**Consequence for the implementation:** record `‖∇ℓ_L(θ̃)‖∞` as
`fit$mspl$wald$unpenalized_gradient_max_abs`. It is a diagnostic the user and reviewer can
see; a large value is a signal that the penalty moved the estimate far from the likelihood's
own stationary region.

**Consequence for the claim:** this is one of two independent reasons coverage is not
claimed. The other is §4.

## 4. The coverage boundary — binding

`projects/deep-research/dr32-separation-rare-species-jsdm-distilled.md:121` quotes
Kosmidis & Firth directly:

> "will fail to cover regardless of the nominal level"

and records that the failure **persists even for profile penalized-likelihood intervals**.
`memory/ENGINEERING-NOTEBOOK.md:1071` supplies the mechanism: because the penalized estimator
*and its standard error* are always finite over a finite set of possible responses, the
pathology follows from finiteness itself, not merely from separation.

Therefore, in this package:

- **A standard error is a reported quantity.** It ships.
- **An interval is a coverage claim.** It does not ship, and is not implied by shipping the SE.

The distinction is enforced in code (§5), not only in prose, because prose is not a gate.

## 5. The surface

`drm_abort_mspl_inference()` (`R/mspl-estimator.R:16`) is already wired **separately** into
each inference entry point, which makes a selective unlock possible without inventing a new
mechanism.

| Entry point | After this design | Rationale |
|---|---|---|
| `vcov()` | **unlocked** | the estimand of §2 |
| `summary()$coefficients$std_error` | **unlocked** | currently asserted `NA` by `test-mspl-estimator.R:311` |
| `confint()` | **stays fenced** | an interval is a coverage claim (§4) |
| `profile()` | **stays fenced** | penalized profile is a separate design |
| `logLik()`, `AIC`, `BIC` | **stay fenced** | 250 forbids exposing the stored unpenalized objective as a likelihood |
| `anova()` | **stays fenced** | LRT between penalized criteria is not a likelihood-ratio |

Blocking `vcov()` while printing standard errors would be incoherent — a user can always
form `coef ± 1.96·SE` by hand. The honest posture is: give the number, refuse the interval,
and warn.

## 6. The SPD gate and its failure behaviour

```
H  ←  optimHess(θ̃, uobj$fn, uobj$gr)        # uobj from drm_mspl_unpenalized_objective()
```

**Sign convention, stated because it is easy to get wrong.** For a TMB object with
`random =`, `obj$fn` returns the *negative* Laplace log-likelihood. Hence
`optimHess(...) = ∇²(−ℓ_L) = −∇²ℓ_L`, which **is** the observed information. No sign flip
is applied; `V = solve(H)` directly. An implementation that negates here is wrong and the
tests must catch it.

Gate, all conditions required:

1. `H` finite in every entry;
2. `H` symmetric to tolerance (symmetrise as `(H + Hᵀ)/2` only after the check, never before);
3. Cholesky succeeds — i.e. `H` positive definite;
4. reciprocal condition number above tolerance.

Pass → `V = chol2inv(chol(H))`. Fail → **`NA` standard errors plus a typed warning**, class
`drmTMB_mspl_wald_unavailable`, mirroring the existing `drmTMB_profile_boundary_warning`
idiom (shipped 2026-08-05, PR #924) rather than inventing a pattern. `summary()` already
carries an `NA` `std_error` column, so the surface supports this today.

The gate fires most often in strongly separated designs — that is, on exactly the fits MSPL
exists to handle. It must therefore degrade to a clear, typed, documented `NA`, never to a
fabricated number and never to a hard error that makes `summary()` unusable.

## 7. Amendment required to design 250

`docs/design/250-mspl-binomial-logit-alignment.md:261-264` currently states that in Phase 3
`logLik()`, AIC, BIC, profile, `confint()`, **Wald standard errors**, and `anova()` must
either error or be marked unsupported.

This design contradicts that clause for **Wald standard errors and `vcov()` only**. It must
be landed as an explicit **Phase 4 amendment to 250**, not as a silent unlock. The other six
fences in that clause are retained verbatim and are re-asserted in §5.

## 8. Implementation sketch — reuse, do not rebuild

Everything needed already exists except the Hessian call:

- `drm_mspl_unpenalized_objective()` (`R/mspl-estimator.R:298-311`) already re-builds the
  ADFun with `use_mspl = 0` and `random =` retained. It currently takes only a scalar
  objective; add the `optimHess` call there.
- `drm_mspl_hessian_diagnostics()` (`:269`) already does exactly this shape on the
  *penalized* object — mirror it, do not duplicate it.
- `drm_finalize_mspl_fit()` (`:313`) assembles `fit$mspl`; add a `wald` element holding
  `hessian`, `vcov`, `std_error`, `spd`, `rcond`, `unpenalized_gradient_max_abs`, `status`.
- `drm_compute_uncertainty()` (`R/drmTMB.R:2553-2565`) currently skips `sdreport()` for MSPL
  with an explanatory message. That message becomes inaccurate and must be updated in the
  same change — `sdreport()` stays skipped, but "point estimation only" no longer describes
  the fit.

## 9. Tests this design obligates

Roughly eight assertions in `test-mspl-estimator.R` currently assert the *absence* of what
§5 unlocks — including `expect_true(all(is.na(summary(fit)$coefficients$std_error)))` at
`:311` and the `drmTMB_mspl_inference_unsupported` expectations at `:303-310`. They must be
**split**, not deleted: `vcov`/`std_error` flip to positive assertions; `confint`, `profile`,
`logLik`, `AIC`, `BIC`, `anova` keep asserting the error.

New tests required:

1. On a non-separated fixture where MSPL ≈ ML, MSPL SEs agree with the ML `sdreport()` SEs
   to a stated tolerance — the oracle that proves the right Hessian was inverted.
2. The **sign convention** of §6: a deliberately negated implementation must fail.
3. Penalized and unpenalized Hessians are *different*, and the reported `vcov` comes from
   the unpenalized one.
4. Under strong separation, SEs are large and finite, or `NA` with the typed warning — never
   silently small.
5. `unpenalized_gradient_max_abs` is recorded and non-zero (§3).
6. Every retained fence still errors.

## 10. Out of scope

Penalized-profile intervals, parametric bootstrap, any coverage or calibration claim, any
Totoro/DRAC campaign, any capability-ledger or census movement, any `DESCRIPTION` bump, and
any public README/NEWS/pkgdown wording. Those remain owned by later arcs and, where
applicable, by the release lane.

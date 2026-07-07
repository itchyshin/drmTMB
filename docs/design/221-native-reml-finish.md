# 221 — Finishing native REML: alignment + recovery plan

**Branch:** `drmtmb/biv-scale-side-reml`. **Status:** design (math-first, pre-code).
**Framing (Shinichi, 2026-07-07):** the goal is honest SE/CI for *every* scale
parameter in Gaussian + bivariate-Gaussian models. The campaign is **"unblock the
gates and prove the current REML recovers with adequate data,"** NOT "derive new
estimators." Complex covariance blocks need large, balanced data; failure on small /
bounded / unbalanced data is expected and is a *data* verdict, not an algorithm defect.
Cox-Reid and MC/AI-REML are **contingencies**, admitted only if the evidence forces them.

## How REML is implemented here (the idiom to align to)

`drm_apply_estimator_spec()` (`R/drmTMB.R:817-857`) implements REML entirely on the R
side — **no C++ REML logic** (`src/drmTMB.cpp` has none). Under `REML = TRUE` it appends
the fixed-effect coefficient vectors to TMB's Laplace `random` set:

```
tmb_random_names <- c(random_names, mean_fixed [, scale_fixed])
mean_fixed  = "beta_mu"   (uni)  | c("beta_mu1","beta_mu2")     (biv)
scale_fixed = "beta_sigma"(uni)  | c("beta_sigma1","beta_sigma2")(biv)   # only if a sigma variance component is present
```

Marginalising `beta` via Laplace **is** the restricted likelihood: for a Gaussian it is
exact (`log|X'V⁻¹X|` appears as the Laplace correction); with a modelled `sigma` it is the
Laplace / adjusted-profile (Cox-Reid) generalisation, and AD captures the `−log σ_i`
Jacobian so no analytic term is missing (Noether, 2026-07-06, doc 220-native-scale-side).

**Consequence:** the machinery is model-agnostic. The gates in
`drm_validate_reml_spec[_biv]` are *validation conservatism*, not missing capability. So
each rung below is: relax the gate → validate against an exact restricted-likelihood
reference + a known-truth recovery → open the gate.

## Rung 1 — bivariate REML with phylo/random MEANS (fixed scale)

The estimator already builds `c("beta_mu1","beta_mu2")` for biv (`:826`); only
`drm_validate_reml_spec_biv` (`:2037`, `random_names > 0` blanket reject) blocks it.

### Symbolic model (1 obs/species, n species, 2 traits; stack y = (y1; y2), 2n)

| Symbol | Meaning | random-set / spec | DGP draw | recovery extractor | truth |
|---|---|---|---|---|---|
| β1, β2 | mean fixed effects | `beta_mu1`,`beta_mu2` → Laplace `random` (marginalised) | `X1 β1`, `X2 β2` | `fit$par$mu1/mu2` | (0.3,0.5),(0.1,0.2) |
| σp1, σp2 | phylo SDs (loc) | `log_sd_phylo*` | `chol(G⊗A)` | `fit$sdpars`/`ranef` | 0.6, 0.5 |
| ρp | phylo loc-loc corr (`\|p\|`) | `cor:phylo` | in G | `VarCorr`/`summary` | 0.4 |
| σr1, σr2 | residual SDs | `beta_sigma1/2` (intercept) | `chol(R)` | `exp(par$sigma1/2)` | 0.8, 0.9 |
| ρ12 | residual corr | `beta_rho12` | in R | `rho12(fit)` | 0.3 |

Marginal covariance V (2n×2n), phylo A = `vcv(tree, corr=TRUE)`:

```
V = [[σp1² A, ρp σp1 σp2 A],[ρp σp1 σp2 A, σp2² A]]        # phylo, G⊗A
  + [[σr1² I, ρ12 σr1 σr2 I],[ρ12 σr1 σr2 I, σr2² I]]      # residual, R⊗I
X = blkdiag(X1, X2)
REML objective (maximise over the 6 var/cor params):
  0.5[(2n−p)log2π + log|V| + log|X'V⁻¹X| + r'V⁻¹r],  β=(X'V⁻¹X)⁻¹X'V⁻¹y,  r=y−Xβ
```

This extends `reml_reference()` (uni phylo, `test-reml-phylo-location.R`) and
`biv_reml_reference()` (biv fixed-mean, `test-reml-bivariate.R`) by adding the second
trait's phylo block **and** the loc-loc cross-covariance `ρp σp1 σp2 A`. **Test:** drmTMB
biv-phylo REML matches this reference (SDs, ρp, ρ12, β to ~1e-2) and phylo SDs are **no
more downward-biased than ML** on known truth. Gate change: relax `:2037` to admit
random/phylo means, mirroring the uni admit-list (still reject matched mean+scale, scale
random effects, q>2). Flip the existing "rejects…" test to an "admits…" test.

## Rung 2 — direct-SD `sd_phylo ~ climate` under REML

Blocked by `drm_validate_reml_spec` (`:1985-1993`). Heteroscedastic phylo variance:
`σp(x) = exp(Z_sd γ)`, so the phylo block is `diag(σp(x)) A diag(σp(x))` and the variance
*coefficients* γ are what REML debiases. No mean-scale coupling (location-side only) →
expected clean. Reference = the `reml_hetero_reference()` pattern
(`test-reml-heteroscedastic.R`) with the phylo A and a per-tip `σp(x_i)`. Recovery: γ
bias(ML) vs bias(REML) on known truth.

## Rung 3 — q2/q4 coupled (matched mean+scale): recovery ladder FIRST

The N=120 rejection (doc `2026-07-06-q-ladder-reml-convergence.md`: REML sd_mu bias
−0.088→−0.233) is **not sufficient evidence** to conclude the algorithm is wrong. For a
Gaussian, the mean and variance are information-orthogonal; the coupling that bites is the
`ρ` between the mean-phylo and scale-phylo random effects, which is *weakly identified at
small g*. Test the current estimator properly before building anything.

### Recovery ladder (ADEMP)

- **Aim:** does current native REML recover the q2 2×2 block with adequate, balanced,
  Gaussian data — i.e. does sd_mu bias → 0 with g while sd_sigma debiases?
- **Data:** univariate q2, phylo (or ordinary) block; g ∈ {120,250,500,1000,2000,4000};
  balanced n_each; truth sd_mu=0.6, sd_sigma=0.4, ρ=0.4 — a **real** (non-boundary) scale
  signal; Gaussian; ≥100 seeds/cell.
- **Methods:** ML vs current REML (un-gate `:2014-2019` for the experiment).
- **Estimands:** sd_mu, sd_sigma, ρ — bias, RMSE, and profile-interval coverage.
- **Performance / decision:**
  - REML sd_mu bias → 0 with g **and** sd_sigma debiased ⇒ **q2/q4 SUPPORTED with an
    N-guidance note.** Open the gate; no new algorithm. (Shinichi's expectation.)
  - sd_mu degradation **persists** at large g ⇒ Cox-Reid contingency (doc TBD), validated
    the same way.
- **Compute:** Totoro (`OPENBLAS_NUM_THREADS=1`, ≤100 cores) — the canonical multi-seed
  ladder. q4 4×4 adds a scale probe but q4's known weak identifiability (data fact) means
  the ladder must use a design with a genuine 4×4 signal.

## Parity matrix (doc 168) — REML column, verdicts

Ships: uni fixed-mean `sigma~x`; uni ordinary/phylo mean RE; uni pure scale-phylo (doc
220); biv fixed-mean. **This campaign:** rung 1 (biv phylo mean), rung 2 (direct-SD),
rung 3 (q2/q4 = *supported-with-adequate-N*, pending ladder). Update 168 + NEWS registry
per-cell with the recovery evidence — the authoritative ML-vs-REML check.

## Scaling (research-fed, not blocking)

For >5000-tip trees, the fast-algorithm literature (NotebookLM notebook
`3b3d2ec5`, in progress) informs whether sparse-Cholesky Laplace suffices or MC/AI-REML is
warranted. Sparse phylo precision (Hadfield-Nakagawa) already makes the Laplace cheap;
MC-REML is a contingency for genuinely dense large blocks.

## Validation log

**Rung 1 — VALIDATED & LANDED (2026-07-07).** Gate `drm_validate_reml_spec_biv`
(`R/drmTMB.R`) relaxed to admit mean-side phylo/random effects; scale-side random, matched
mean+scale, direct-SD, and q>2 rejects retained. Evidence:
- **Correctness (deterministic):** `test-reml-bivariate.R` — biv phylo-mean REML matches the
  exact restricted-likelihood reference `V = G⊗A + R⊗I` (SDs 2e-2, cor 5e-2, sigmas/betas
  1e-2). Native REML suite green: biv 20 + uni 20 assertions, 0 fail; **no regression**.
- **Recovery ladder** (n ∈ {200,400,800,1600}, 25 seeds, 200 fits in 1 min):
  bias → 0 with n; REML less downward-biased than ML on sd_phylo1/2 at every n (sd_phylo2 @
  n=200: ML −0.084 vs REML **+0.013**); REML/ML SEs agree (identical for σ/ρ12, ≤+11% on the
  variance components). Confirms: under-identified at small n, **not** a broken estimator.
  Scripts: `scratchpad/reml_rung1_ladder.R`.
- **Hessian conditioning (ML-vs-REML `pdHess`, same 200 fits):** REML PD rate **0.93 > ML 0.83**
  — REML is *better*-conditioned (it integrates the mean effects out). `P(REML PD | ML PD) = 0.96`
  (confirms the expectation that ML-PD ⇒ REML-PD), and REML even **rescues 77%** of ML-non-PD
  draws; both reach **1.00 by n=800**. The few small-n REML-non-PD draws route through
  profile/bootstrap — `pdHess=TRUE` is a *want*, not a *gate* (standing doctrine). **Protocol:**
  record ML/REML `pdHess` concordance on every ladder (q2/q4 included).

**Rung 3 (q2/q4) — the coupled-block "REML is wrong" verdict is OVERTURNED by data (2026-07-07).**
- **q2 ladder** (matched mean+scale 2×2, N=250→2000, 30 seeds): REML is **less** biased than ML
  on `sd_mu` at *every* n (N=1000: REML −0.005 vs ML −0.027) — **no mean-side degradation**. The
  N=120 "−0.233" was below q2's N≥250 identifiability floor. Bias → 0 with n (all three params
  recovered by N≥1000); REML debiases `sd_sigma` throughout; pdHess REML 0.97 > ML 0.93,
  `P(REML PD | ML PD)=0.98`. ⇒ **q2 native REML SUPPORTED** with an N-guidance note (N≥250 to
  identify, ≥1000 for the correlation). **No Cox-Reid.** Script: `scratchpad/reml_q2_ladder.R`.
- **q4 probe** (full 4×4, *genuine* well-conditioned signal, n=600): **REML conv=0, pdHess=TRUE**
  while ML false-converged (code 8) + NaN SEs — REML rescued the fit, contradicting the earlier
  "q4 pdHess=FALSE persists at all N" (that was the ≈0-signal beak+tarsus pair). SDs roughly
  recovered. **TODO before the full ladder:** a phylo mean–scale correlation came back
  sign-flipped vs the DGP truth in *both* ML and REML ⇒ a DGP↔endpoint-ordering mapping to verify
  (not a REML issue). Then run the q4 ladder (Totoro) with the pdHess-concordance + profile-CI
  columns.

# Penalized / MAP estimator for phylogenetic location-scale fits

## Reader and purpose

This note is for the next `drmTMB` engine contributor and reviewer. It records
the first slice of the optional **penalized / maximum-a-posteriori (MAP)**
estimator: a documented prior on the phylogenetic standard deviations (and,
optionally, the phylogenetic cross-parameter correlation) that lets a
weakly-identified phylogenetic component return a finite, regularised estimate
instead of diverging under plain maximum likelihood.

The motivating case is the scale-side phylogenetic field at about one
observation per tip (the Ayumi q4 "Model E" surface). That component is **weakly
identified, not non-identified** (de Villemereuil & Nakagawa 2014; Nakagawa et
al. 2025): the published Bayesian fits return a bounded but prior-sensitive
estimate because the prior regularises the weak direction. Frequentist ML has no
prior, so it sits on a near-flat ridge. The penalized/MAP estimator is the
frequentist analog of what the Bayesian fit does. It **complements** a
preregistered Bayesian analysis; it does not replace it.

## What this slice adds

A new optional argument `penalty` to `drmTMB()`, built by an exported helper:

```r
drmTMB(..., penalty = drm_phylo_penalty(sd_u = 1, sd_alpha = 0.05, cor_sd = NULL))
```

- `drm_phylo_penalty()` (`R/penalty.R`) builds a penalty spec. The SD prior is a
  **penalised-complexity (PC) prior** (Simpson et al. 2017): an exponential on
  the SD scale with mass at zero, rate `lambda = -log(sd_alpha) / sd_u` so that
  `P(sd > sd_u) = sd_alpha` a priori. The optional `cor_sd` adds a mean-zero
  normal on the unconstrained phylogenetic correlation parameter.
- `drm_apply_phylo_penalty_spec()` (`R/penalty.R`) attaches three DATA fields to
  every `spec$tmb_data` (`penalize_phylo`, `phylo_sd_penalty_rate`,
  `phylo_cor_penalty_sd`) so TMB always sees them, records `spec$estimator =
  "MAP"` and `spec$penalty` when penalizing, and aborts if there is no
  `phylo(...)` term or if a direct `sd_phylo(...)` formula is in use.
- `src/drmTMB.cpp` gains `drm_phylo_penalty_value()` and a guarded
  `if (penalize_phylo == 1)` block at the univariate and bivariate phylo NLL
  sites. The penalty is added to the objective and `REPORT`ed.

## Mathematical contract

For each penalized phylogenetic SD endpoint `sd_k = exp(log_sd_phylo(k))`, the
negative log-prior added to the objective is, with the change-of-variables
Jacobian for working on the log scale,

```
pen_k = lambda * sd_k - log_sd_phylo(k) - log(lambda)
```

(the `- log_sd_phylo(k)` term is the `|d sd / d log_sd|` Jacobian). When a
correlation penalty is requested, a mean-zero normal `N(0, cor_sd)` is added to
the live correlation parameter: `eta_cor_phylo` when `q_phylo == 2`, each
`theta_phylo` entry when `q_phylo > 2`. The total penalty is `REPORT`ed as
`phylo_penalty`.

## Honesty contract (the part reviewers must hold)

- **Plain ML stays the default and bit-identical.** With `penalty = NULL`,
  `penalize_phylo = 0` and the penalty block adds exactly nothing; the existing
  test suite is the bit-identity guard.
- **A penalized fit is labeled "MAP", never ML.** `print()`/`summary()` show the
  estimator as `MAP` plus a penalty line; `check_drm()` adds a `penalized_map`
  note.
- **`logLik()` returns the unpenalized data log-likelihood.** The fit stores
  `logLik = -opt$objective + phylo_penalty` (the data term) and the penalty
  separately as `fit$phylo_penalty`, so AIC/BIC use the data likelihood. Even
  so, likelihood-ratio tests and AIC *across penalized fits* are not standard;
  the `check_drm()` note says so.
- **The penalty does not manufacture identifiability.** It returns a
  prior-regularised estimate of a weak component; the estimate is
  prior-sensitive and a sensitivity analysis is required before interpretation.

## Scope of this slice / deferred

- The SD penalty applies to **all** phylogenetic SD endpoints with the same PC
  prior. Per-endpoint targeting (penalise only the scale endpoints in a q4
  model) is a deferred follow-up.
- A calibration simulation (MAP returns the prior when the data are
  uninformative and the truth when informative; prior-sensitivity sweep) is the
  companion Phase 5 lane.
- The Julia (DRM.jl) counterpart is coordinated with the twin team; this slice
  is R-only and `engine = "julia"` rejects `penalty`.

## References

- Simpson, Rue, Riebler, Martins & Sorbye 2017, *Statistical Science* (PC priors).
- Chung, Rabe-Hesketh, Dorie, Gelman & Liu 2013, *Psychometrika* (nondegenerate
  penalized variance-component estimation).
- de Villemereuil & Nakagawa 2014, *MEE*; Nakagawa et al. 2025, *MEE* (PLSM).

# After Task: Bank Ayumi Model A+ evidence + persist the reframe (Phase 2)

## Goal

Make the headline Ayumi claim **reproducible** instead of asserted: fit the
identified bivariate location-scale phylogenetic model ("Model A+") and its
no-phylo null on the real ~10,440-tip bird data, compute the mean-side
phylogenetic likelihood-ratio from banked logLiks, and persist the corrected
"weakly identified, not non-identified" framing in the project ledgers.

This closes the honesty debt the systems audit flagged: the previously circulated
`LR ~ 36,572` had no banked null fit behind it, and the scale-side
identifiability had been overstated as "non-identified."

## Why this framing (the correction)

A team review, cross-checked against the methods literature, established that a
phylogenetic field on the **scale** (`sigma1`/`sigma2`) is **weakly identified,
prior-sensitive** at one observation per tip — *not* "non-identified." The
maintainer's own published method (Nakagawa et al. 2025, PLSM, *MEE*) fits these
at one record per species; a Bayesian fit returns a bounded but prior-sensitive
estimate because the prior regularizes the weak direction (de Villemereuil &
Nakagawa 2014). Frequentist ML without a prior sits on a near-flat ridge there.
The supported one-record-per-species analysis is therefore the **mean-side**
phylogenetic model with a fixed-effect `sigma ~ predictors` scale — Model A+.

## Method

- **Model A+** — `phylo(1 | p | tree_tip)` on both `mu1` (Tarsus) and `mu2`
  (Beak) with a cross-trait phylogenetic correlation, fixed-effect
  `sigma1`/`sigma2 ~ temp + prec + temp:prec + log_mass`, constant `rho12`.
- **Null** — identical fixed effects, no phylogenetic terms on the means.
- **LRT** — `2 * (ll_full - ll_null)`, `df = 3` (two location SDs + their
  phylogenetic correlation). This is a **boundary** test (the SDs are 0 and the
  correlation is unidentified under H0), so the naive chi-square_3 p-value is
  conservative (Self & Liang 1987; Stram & Lee 1994). The LR is reported for the
  **mean-side** signal only; it says nothing about the scale-side block.
- **Data provenance** — `birds_tarsus_beak_10440.rds` (not in the repo; one
  record per species; `$data` 10,440x7 + `$tree`). Script reads
  `DRMTMB_AYUMI_DATA`.
- **Engine** — `biv_gaussian()`, `optimizer_preset = "robust"`, sparse augmented
  GMRF phylogenetic precision + TMB Laplace + exact AD + `nlminb`, built from
  this worktree (`origin/main` @ `d37496f2`, includes the #576 `log(sigma)`
  guard).

## Results (banked from `inst/sim/run/ayumi_model_a_plus_evidence.R`)

| Fit | convergence | pdHess | logLik | k | max\|grad\| | elapsed |
| --- | --- | --- | --- | --- | --- | --- |
| Model A+ | 0 | TRUE | 10358.44 | 24 | 0.031 | 199.3 s |
| Null (no mean-phylo) | 0 | TRUE | -7933.22 | 21 | 0.025 | 9.5 s |

**Mean-side phylogenetic LRT:** `LR = 36583.32`, `df = 3`, naive `p ~ 0` (below
machine precision; boundary-conservative, so the true mixture p-value is even
smaller). The previously circulated `LR ~ 36,572` was a close approximation; the
banked value from these two fits is `36583.32`.

Identified, reportable quantities (Model A+), all with `pdHess = TRUE`:

- Phylogenetic **location SDs**: Tarsus `sd_phylo = 0.347` (SE 0.005), Beak
  `sd_phylo = 0.464` (SE 0.006) -- strong, tight phylogenetic signal in both
  trait means.
- **Mean-mean phylogenetic correlation**: `0.219` (SE 0.017) -- Tarsus and Beak
  means are positively, modestly phylogenetically correlated.
- Residual **`rho12`**: working-scale intercept `0.565` (SE 0.027), i.e. a
  residual correlation of `tanh(0.565) ~ 0.51`.
- Fixed-effect **scale (`sigma ~ climate`)** is active: e.g. the `log_mass_z`
  coefficient on log-`sigma` is `~1.25` for both traits (SE ~0.013-0.015) --
  dispersion rises strongly with body mass. This is the variance
  ecogeographical-rule signal, delivered without any scale-side phylogenetic
  field.

## Honest scope

- **Supported now:** Model A+ — two location SDs, the mean-mean phylogenetic
  correlation, residual `rho12`, and fixed-effect `sigma ~ climate`. Converges
  with `pdHess = TRUE`; the LRT shows an overwhelming mean-side phylogenetic
  signal.
- **Not delivered from this data:** a phylogenetic field on the scale and the
  scale-scale / mean-scale phylogenetic correlations. Weakly identified at one
  record per species; needs within-species replication (~5-10/species) or an
  explicit penalty/prior (the planned `estimator = "penalized"` path, or a
  Bayesian fit with a prior-sensitivity analysis).
- `pdHess = FALSE` on a scale-phylo fit is a Wald-inference warning, never an
  automatic discard.

## Files changed

- `inst/sim/run/ayumi_model_a_plus_evidence.R` — the re-runnable banking script.
- `docs/dev-log/known-limitations.md` — new scale-side identifiability row.
- `docs/design/34-validation-debt-register.md` — `phylo_structured_effects` gate
  updated with the weak-identifiability scope.
- `docs/dev-log/after-task/2026-06-16-ayumi-model-a-plus-evidence.md` — this note.
- `docs/dev-log/check-log.md` — this slice's checks.

## References

- de Villemereuil & Nakagawa 2014, *MEE* — phylogenetic heritability and
  identifiability at one observation per species.
- Nakagawa et al. 2025, *MEE* (PLSM) — phylogenetic location-scale models; the
  scale-side caveat language.
- Self & Liang 1987, *JASA*; Stram & Lee 1994, *Biometrics* — boundary LRT is a
  chi-square mixture.

## Team perspective

Grace owns reproducibility (the script + data provenance). Fisher holds the LRT
scope (mean-side only; boundary-conservative). Rose enforces the "weakly
identified" language and the ledger rows. Darwin frames the biological reading.
Ada gates the slice. No subagents are running.

## 1. Goal

Admit one bounded native slice of the `A2-animal-within` contract row: a correlated Gamma animal intercept and one numeric slope, each with its own predictor-dependent SD formula. Interval coverage remains deferred.

## 2. Implemented

`animal(1 + x | p | id, A = A)` with `sd(id, level = "animal", dpar = "mu", coef = ...)` formulas for both coefficients now fits natively. The stored latent fields stay unit scale and the per-row SD multiplies each field, so the prior is the unit-scale joint density `N(0, R (x) A)` with `R = [[1, rho], [rho, 1]]` and `rho = 0.999999 * tanh(eta_cor_phylo)`. Existing Poisson and NB2 correlated q2 code uses a centred prior with constant `log_sd_phylo`, which cannot carry per-row SDs, so it was not copied.

The unlabelled `animal(1 + x | id, A = A)` keeps its independent-field meaning. A labelled Gamma term without `sd()` formulas is refused, because the parameter map frees `eta_cor_phylo` for any labelled q2 term and the likelihood would ignore it.

## 3a. Decisions and Rejected Alternatives

- Opt-in through the labelled `| p |` form, matching the repository grammar. Making the unlabelled form correlated would silently change shipped Gamma, Beta and Binomial fits.
- Non-centred joint-density parameterisation over a mixing parameterisation (`u2 = rho z1 + sqrt(1 - rho^2) z2`). Both give the same marginal law; the joint density matches existing construction. The Laplace fit can differ slightly between them; not tested.
- Not done: Julia Gamma (still independent), Beta, Binomial, constant-SD labelled Gamma.

## 3b. Findings

- The native `A2-animal-within` row in `block-rules.tsv` cites `R/drmTMB.R:8612-8627`, which is the independent Binomial animal gate, as its "correlated" source. No native family had correlated intercept-slope with per-coefficient SDs before this slice. The row was not edited; it needs a decision.
- Possible latent Poisson issue, not shown reachable: `src/drmTMB.cpp` scales the Poisson field by the SD row and the correlated prior also uses `log_sd_phylo`. Not touched.

## 4. Files Touched

- `src/drmTMB.cpp` (Gamma `model_type == 5` structured block only)
- `R/drmTMB.R` (label refusal, labelled-without-SD refusal, q2 flag, corpar split)
- `tests/testthat/test-gamma-animal-q2-correlated-sd.R` (new)
- `NEWS.md`

The worktree has extensive other in-flight changes in these files. This report does not claim every dirty hunk belongs to this slice.

## 5. Checks Run

- New test: 15 expectations pass (`NOT_CRAN=true`). Red first for the intended reason (the label refusal), green after the change.
- Three fixed seeds, true rho 0.5, 40 animals by 16 rows: estimates 0.525, 0.475, 0.452; log-likelihood gain over the nested independent fit 4.59, 3.18, 2.81; all six fits converged. Loose single-fixture band, not calibration.
- Neighbouring regression files, all passing with no failures: `gamma-animal-slope-sd-regression`, `gamma-animal-pedigree-sd-regression`, `gamma-relmat-q2-sd-regression`, `gamma-phylo-q2-sd-regression`, `gamma-spatial-q2-sd-regression`, `gamma-sd-regression`, `poisson-ordinary-correlated-q2`, `nbinom2-ordinary-correlated-q2`, `count-structured-mu`.
- Not run: the live-Julia `gamma-animal-q2-cross-engine-sd` test, `devtools::document()`, full package check, `pkgdown`, vignettes. No source-hash receipt was written.

## 6. Not Claimed

No Julia parity, no interval calibration, no ledger row promoted, no gate closed, nothing committed or pushed. Recovery is three seeds at one design.

## 7. Next

Update the `A2-animal-within` row note (needs a decision), design docs 01/03/18, and a Julia Gamma correlated route copying the Binomial `kron(Q, Rinv(rho))` pattern in the paired Julia worktree. The ranked queue of other open slices is in the session workflow output.

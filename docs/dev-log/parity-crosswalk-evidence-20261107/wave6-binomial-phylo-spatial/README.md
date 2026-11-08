# Wave 6: Binomial phylo and spatial coefficient-SD q2, R vs Julia

Route: `y ~ x + phylo(1 + x | g)` / `spatial(1 + x | g)` with `sd(g, level, coef(intercept)) ~ z0`,
`sd(g, level, coef(x)) ~ z1`; two independent unit fields, rho fixed 0. Julia branch
`claude/binomial-phylo-spatial-q2-20261108` (DRModels.jl, from `claude/wave4-merge-20261108` e5ae24539).
R: drmTMB 0.8.1 (private library `agree-poisson-q2/lib`). ML, both engines, Julia 1.10.0, Mac Studio.

## What R 0.8.1 fits and refuses (probe: `refusal-probe/`)
Fits: logit link, unweighted 0/1 Bernoulli response, phylo and spatial (unlabelled), also the
intercept-only q1 forms. Refuses (verbatim first lines):
- probit / cloglog, phylo and spatial: "Binomial `phylo()` `mu` effects currently support only an intercept-only q1 term." (spatial: "Binomial `spatial()` `mu` effects currently support only an intercept-only q1 term.")
- cauchit: "drmTMB binomial models support `binomial(link = "logit")`, `binomial(link = "probit")`, and `binomial(link = "cloglog")`."
- `cbind(k, fail)` trials, and `cbind(y, 1 - y)` too, with logit: "Binomial structured intercept-slope SD regression requires unweighted 0/1 Bernoulli responses."
- labelled `spatial(1 + x | p | g)`: "Binomial `spatial()` `mu` effects currently support only an unlabelled q1 intercept." R's labelled `phylo(1 + x | p | g)` is accepted but prints no rho coefficient and reached a different optimum on the probe data; not compared here (R oddity, flagged).

## Julia refusal before this work (verbatim)
- phylo, logit: "Binomial SD regression currently supports ordinary random intercepts, numeric slopes, and correlated intercept-slope blocks only; structured covariance inputs are not used."
- spatial, logit: "Binomial spatial SD regression currently requires exactly one `sd(group, spatial) ~ …` formula."
- probit: "Binomial links other than :logit are currently supported for ordinary IID SD models, and :probit and :cloglog are additionally supported for one phylogenetic SD target ..."

## What was built
`_drm_binomial_phylo_spatial_q2_sd` (src/binomial_sd_regression.jl): shared kernel helper
`_structured_q2_kernel` (phylo = ape::vcv corr; spatial = exp(-d/median d) + 1e-6 I; 600-coordinate cap), the Binomial animal q2
Laplace code with `correlated = false` (no rho parameter), second start for spatial (as Poisson), bootstrap simulator,
predict/predict_parameters/bridge reuse. Julia now refuses what R refuses (probit/cloglog, cbind trials, labelled form, mesh) with explanatory messages.

## Agreement (22 datasets: 1 single-dataset case, seed 20261108, plus seeds 1-10, per kernel)
64 tips x 30 Bernoulli rows; truth beta (0.3, 0.5), sd0 = exp(log 0.9 + 0.4 z0), sd1 = exp(log 0.8 - 0.4 z1).
Flags fixed before reading results (see `compare.R`): |dll| > 1e-3; max abs coef diff > 0.01; max |diff|/SE_R > 0.01;
max |SE_J/SE_R - 1| > 0.10; any non-finite SE; non-convergence; fitted group SD < 0.01 (boundary).

Final run (`summary.csv`, `detail.csv`, `out/`): max over the 11 datasets per kernel

| kernel | max abs dll | max abs coef diff | max abs diff in R-SE | max abs SE rel diff | non-finite SE (R/J) | flags |
|---|---|---|---|---|---|---|
| phylo | 8.1e-07 | 1.4e-04 | 3.0e-04 | 4.1e-03 | 0/0 | none |
| spatial | 5.3e-07 | 3.3e-04 | 3.4e-04 | 4.3e-03 | 0/0 | none |

All 22 Julia and R fits converged, no boundary fits (smallest group SD 0.025).

### Disagreement found and fixed (run 1, `run1-default-fd-step/`)
With the default finite-difference Hessian step (about 5e-4) coefficients and loglik agreed identically but Julia's SEs were
up to 9.4% (phylo) and 19.2% (spatial) below R's on 3 spatial datasets (the slope-SD coefficients; SE flag count 3).
Cause: the inner Newton solve cannot go below a 1e-7 relative step, so the Laplace objective carries noise that the small
step amplifies when the slope SD is weakly identified. For spatial seed 8, steps 3e-3 to 3e-2 gave SEs equal to R's to 3 digits
(sd1 intercept 1.3269 vs R 1.3248). This route now uses step 3e-3 (animal q2 untouched); rerun gives the table above.

## Honest gaps
- A first probe dataset (64 tips x 16 rows, slope SD about 0.3-0.5, `refusal-probe/mk.R` earlier version) put the slope SD at the boundary:
  R reached loglik -641.18394 (interior, SEs 4-5), Julia stopped at -641.29367 with `converged = false` (slope SD coefficient -7.8), 0.11 worse.
  Second start did not rescue it. Not part of the 22-dataset study (those have an identified slope SD). Julia can stall on a
  boundary-flat ridge where R's optimiser finds the better point; recorded, not fixed.
- Scope is R's: logit, 0/1 only. Julia's animal q2 supports probit/cloglog/trials; this route does not, because R does not fit them.
- Labelled (correlated) forms and mesh/SPDE are refused.

# Arc 1 slice S3: live model-identity sweep receipt

PRE-RUN: cells=3 elapsed_s=68.681 extrapolated_total_min=23.275
POSITIVE-CONTROL-BEFORE-S4: DIFFERENT_MODEL

## Summary

Full sweep ran (extrapolated total was within the 30-minute D-139 budget).

Counts by classification:
- DIFFERENT_INTEGRATOR: 1
- DIFFERENT_MODEL: 5
- NO_NATIVE_TWIN: 2
- REFUSED: 21
- SAME_MODEL: 33

Total cells: 62 (including the #1267 probe, not part of the census).

## DIFFERENT_MODEL cells
- biv_gaussian | bivariate q4 block-diagonal phylo | mu1,mu2,sigma1,sigma2: native_df=13 bridge_df=17 native_n=13 bridge_n=17 names_match=FALSE (native names: mu:mu1:phylo(1 | p | sp),mu:mu2:phylo(1 | p | sp),mu:sigma1:phylo(1 | p | sp),mu:sigma2:phylo(1 | p | sp),mu1:(Intercept),mu1:x,mu2:(Intercept),mu2:x,phylo:cor(mu1:(Intercept),mu2:(Intercept) | p | sp),phylo:cor(sigma1:(Intercept),sigma2:(Intercept) | ps | sp),rho12:(Intercept),sigma1:(Intercept),sigma2:(Intercept) || bridge names: mu1:(Intercept),mu1:x,mu2:(Intercept),mu2:x,phylocov:Sigma_a:L11,phylocov:Sigma_a:L21,phylocov:Sigma_a:L22,phylocov:Sigma_a:L31,phylocov:Sigma_a:L32,phylocov:Sigma_a:L33,phylocov:Sigma_a:L41,phylocov:Sigma_a:L42,phylocov:Sigma_a:L43,phylocov:Sigma_a:L44,rho12:(Intercept),sigma1:(Intercept),sigma2:(Intercept))
- gaussian | (1|g) | mu: native_df=4 bridge_df=4 native_n=4 bridge_n=4 names_match=FALSE (native names: mu:(1 | g),mu:(Intercept),mu:x,sigma:(Intercept) || bridge names: mu:(Intercept),mu:g,mu:x,sigma:(Intercept))
- gaussian | (1+x|g) | mu: native_df=6 bridge_df=6 native_n=6 bridge_n=3 names_match=FALSE (native names: mu:(1 + x | g):(Intercept),mu:(1 + x | g):x,mu:(Intercept),mu:cor((Intercept),x | g),mu:x,sigma:(Intercept) || bridge names: mu:(Intercept),mu:x,sigma:(Intercept))
- biv_gaussian | bivariate q2 phylo | mu1,mu2: native_df=10 bridge_df=10 native_n=10 bridge_n=10 names_match=FALSE (native names: mu:mu1:phylo(1 | sp),mu:mu2:phylo(1 | sp),mu1:(Intercept),mu1:x,mu2:(Intercept),mu2:x,phylo:cor(mu1:(Intercept),mu2:(Intercept) | phylo | sp),rho12:(Intercept),sigma1:(Intercept),sigma2:(Intercept) || bridge names: mu1:(Intercept),mu1:x,mu2:(Intercept),mu2:x,phylocov:Sigma_a:L11,phylocov:Sigma_a:L21,phylocov:Sigma_a:L22,rho12:(Intercept),sigma1:(Intercept),sigma2:(Intercept))
- biv_gaussian | bivariate q4 dense phylo | mu1,mu2,sigma1,sigma2: native_df=17 bridge_df=17 native_n=17 bridge_n=17 names_match=FALSE (native names: mu:mu1:phylo(1 | p | sp),mu:mu2:phylo(1 | p | sp),mu:sigma1:phylo(1 | p | sp),mu:sigma2:phylo(1 | p | sp),mu1:(Intercept),mu1:x,mu2:(Intercept),mu2:x,phylo:cor(mu1:(Intercept),mu2:(Intercept) | p | sp),phylo:cor(mu1:(Intercept),sigma1:(Intercept) | p | sp),phylo:cor(mu1:(Intercept),sigma2:(Intercept) | p | sp),phylo:cor(mu2:(Intercept),sigma1:(Intercept) | p | sp),phylo:cor(mu2:(Intercept),sigma2:(Intercept) | p | sp),phylo:cor(sigma1:(Intercept),sigma2:(Intercept) | p | sp),rho12:(Intercept),sigma1:(Intercept),sigma2:(Intercept) || bridge names: mu1:(Intercept),mu1:x,mu2:(Intercept),mu2:x,phylocov:Sigma_a:L11,phylocov:Sigma_a:L21,phylocov:Sigma_a:L22,phylocov:Sigma_a:L31,phylocov:Sigma_a:L32,phylocov:Sigma_a:L33,phylocov:Sigma_a:L41,phylocov:Sigma_a:L42,phylocov:Sigma_a:L43,phylocov:Sigma_a:L44,rho12:(Intercept),sigma1:(Intercept),sigma2:(Intercept))

### Reading the five DIFFERENT_MODEL cells: one new-ish finding, four already-documented gaps

A9's bar is mechanical (names AND count AND df all match, or it is not
SAME_MODEL/DIFFERENT_INTEGRATOR), and this sweep reports that mechanical
result honestly. But the five cells above are not five new surprises:

- **`biv_gaussian` q4 block-diagonal phylo (the positive control)** is the
  one genuine structural difference this row is FOR: df itself differs
  (13 native vs 17 bridge). This directly reproduces finding 5 (measured
  under REML in docs/dev-log/evidence/julia-r-parity/reml-uncited/receipt.md;
  confirmed here under ML for the first time) -- the bridge fits the DENSE
  q4 model for a formula that names TWO phylo covariance-block tags
  (`p` on the means, `ps` on the scales), silently answering a different
  question.
- **`gaussian` `(1|g)` on mu** has MATCHING count and df (4 = 4); the ONLY
  difference is that the group-SD parameter is labelled `mu:(1 | g)`
  natively and `mu:g` on the bridge -- exactly the labelling convention
  already recorded on the `gaussian_random_intercept_mu` ledger row
  ("Julia's sdpars label is the bare group name... where native uses
  mu.(1 | g)"). Not a new finding.
- **`biv_gaussian` q2 phylo and q4 dense phylo** also have MATCHING count
  and df (10 = 10, 17 = 17 respectively) once the bridge's `phylocov` field
  is included (see `sweep_flatten_phylocov()`'s comment for why that field
  needs its own extraction path). The remaining name mismatch is a
  PARAMETERIZATION-FORMAT gap: the bridge reports the among-axis covariance
  as ten raw log-Cholesky entries (`phylocov:Sigma_a:L11`, ...); native
  decomposes the SAME 10-parameter block into named correlations
  (`corpars$phylo`) and SDs (`sdpars$mu`). The q4 dense case is the SAME
  shape the `biv_q4_phylo_reml` ledger row already calls "the SAME
  restricted likelihood" under REML; this sweep's ML result is consistent
  with that, not a contradiction of it.
- **`gaussian` `(1+x|g)` on mu (the random slope)** is the one REAL count
  mismatch among the four (native_n=6, bridge_n=3): the bridge's `sdpars`
  and `corpars` are genuinely EMPTY for this shape, already recorded as a
  "REPORTING GAP" on the `gaussian_random_slope_mu` ledger row. This sweep
  reproduces that gap live rather than finding a new one.

So of the five, ONE is a live-confirmed structural difference (the
positive control) and FOUR are already-known reporting/labelling gaps,
re-measured here for the first time under this sweep's own fixture. None
of the four should be read as new evidence of a differently-fit model.

## ERROR cells (message quoted)
(none)

## #1267 probe (poisson() + hu ~ 1)

classification=NO_NATIVE_TWIN native_df=NA bridge_df=3 names_match= note=Poisson models only support `mu` and optional `zi`. | Unsupported parameter: "hu". | Name each parameter formula in `bf()`, such as `bf(y ~ x, sigma ~ x)`.

**Reading this probe.** `engine = "tmb"` refuses `poisson()` + `hu ~ 1`
outright (the message above). `engine = "julia"` ADMITS it and FITS it,
`bridge_df = 3` (2 mu parameters + 1 hu parameter), i.e. it silently fits a
hurdle-Poisson-shaped model with no native counterpart to compare against.
This is a LIVE CONFIRMATION of issue #1267's exact concern and of the
`unadmitted_predictor_dpar` gate's own evidence comment
(R/julia-bridge.R, `drm_julia_intentional_gates()`), which already names
this pattern: "`engine = \"julia\"` is still MORE PERMISSIVE than native
about count modifiers: nbinom2() + hu and poisson() + hu route through the
bridge and are refused natively." The census (S2) never exercised this
`hu`-on-`poisson()` cell at all -- it is not a registered dpar-scope gate
target -- so NO_NATIVE_TWIN is the correct mechanical classification, but
the substance is: the bridge admits and fits a model the user's own written
family does not support, without saying so.

## Environment
- Julia: julia version 1.13.0
- DRModels.jl pin (measured): da8b3f8711beb5ef3186b890544c2e7850c7f194
- DRM_JL_PATH: /Users/z3437171/local-scratch/lanes/DRModels-pin-da8b3f871
- threads: OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=4

## Limitations

Values are never compared (D-234); this sweep only compares parameter-name
sets, parameter count, and df. The integrator label is a small, documented
lookup (see `sweep_integrator_bridge()` in tools/julia-model-identity-sweep.R),
not a field read off the fit object -- DRM.jl's internal `marginal` tag
never crosses the JuliaCall boundary, so this sweep cannot independently
verify the GHQ claim for nbinom2/binomial/gamma/beta ordinary random
effects; it applies the Poisson-documented, plan-predicted fact to that
cohort and says so here rather than silently assuming it.

## Conductor addendum (2026-09-24, after reverify)

Reclassification. The first pass labelled a cell DIFFERENT_MODEL when parameter names, reported count, or df differed. Model identity is read from df, the number of free parameters, so the rule now reads: df differs, DIFFERENT_MODEL; equal df and integrator with differing names or reported count, DIFFERENT_REPORTING. `sweep_reclassify_tsv()` re-derived the classes from the recorded columns without a second Julia run. Counts after reclassification: SAME_MODEL 33, REFUSED 21, DIFFERENT_REPORTING 4, NO_NATIVE_TWIN 2, DIFFERENT_MODEL 1, DIFFERENT_INTEGRATOR 1. The one DIFFERENT_MODEL cell is the positive control, q4 block-diagonal phylo (df 13 native, 17 bridge). The four DIFFERENT_REPORTING cells (Gaussian `(1|g)` and `(1+x|g)` on `mu`; bivariate q2 and q4 dense phylo) match in df and are reporting gaps already named on their ledger rows. The summary counts above this addendum predate the reclassification.

Integrator column. `integrator_bridge` is assigned by a documented rule per family, structure and dpar (`sweep_integrator_bridge()`, citing DRModels source comments), not read from the fit object. It is evidence of what DRModels documents, not a measurement.

Fit-time refusals. All 21 REFUSED cells passed R's pre-Julia admission (census ADMIT) and then stopped inside Julia with an error and stack trace: 9 bridge coefficient-label errors (`coef_labels is missing an entry for dpar resd` or `recov`: ordinary `(1|g)` and `(1+x|g)` on non-Gaussian families), 4 bivariate q4 with ordinary random effects, 6 non-Gaussian `sigma` random effects, 1 multi-term `sigma` random effect, 1 binomial non-mean random effect. None fits a different model silently; each is a late, loud failure that Arc 1 turns into an R-side refusal with a named gate. Making these routes work is Arc 2.

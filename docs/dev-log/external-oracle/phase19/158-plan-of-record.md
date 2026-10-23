# Phase 19 plan-of-record extract (for PR 2)

Reader: whoever builds PR 2 on branch `claude/external-oracle-intervals`. Purpose: pull
the canonical Phase 19 plan out of `docs/design/158-phase-19-comparator-matrix.md`,
`docs/design/05-testing-strategy.md`, and issue #60 so PR 2 builds on it rather than
re-deriving it, and flag what doc 158 does not yet know about because the external-oracle
harness (`tests/testthat/test-comparators-external-oracle.R`) landed after it was last
edited.

Sources read in full:
- `docs/design/158-phase-19-comparator-matrix.md` (136 lines)
- `docs/design/05-testing-strategy.md` (~L1-247, esp. L35-41 on where full comparator
  sweeps belong)
- `gh issue view 60`
- `tests/testthat/test-comparators-external-oracle.R` (396 lines, the just-landed harness)
- `docs/design/242-external-comparator-evidence-class.md` (referenced from the test file's
  header, needed to interpret the "stale" section honestly)

## (a) Scale-Conversion Reference — verbatim, doc 158 L38-49

| Family | `drmTMB` public | Internal mapping | Typical comparator scale | Conversion to compare |
| --- | --- | --- | --- | --- |
| `gaussian()` | residual SD `sigma` | `log(sigma)` linear predictor | `glmmTMB` dispersion / `gamlss` `sigma` | `gamlss` `sigma` is the SD directly; `glmmTMB`'s `dispformula` coefficients are also `log(sigma)` (SD scale, not `log(sigma^2)`) — compare `coef(fit, "sigma")` to `glmmTMB::fixef(fit)$disp` directly, no squaring (corrected 2026-07-25, see note below) |
| `student()` | `sigma`, `nu` | `nu = 2 + exp(eta_nu)` (df) | `gamlss` `TF`, `brms` `student` | match `nu` to df; `sigma` to scale |
| `lognormal()` | `sigma` on `log(y)` | identity `mu` on `log(y)` | `glmmTMB`/`lm` on `log(y)` | compare on the log scale; `sigma` is the log-scale SD |
| `Gamma(link="log")` | `sigma` | shape `= 1 / sigma^2` | `glmmTMB`/`glm` Gamma shape or dispersion | `shape = 1/sigma^2`; `glm` dispersion `= sigma^2` |
| `tweedie()` | `sigma`, `nu` | `phi = sigma^2`, `nu = 1 + plogis(eta_nu)` power | `glmmTMB::tweedie` (dispersion, power) | `phi = sigma^2`; power matches `nu` (see doc 126 for weights/offset boundary) |
| `beta()` | `sigma` | precision `phi = 1 / sigma^2` | `betareg`/`glmmTMB` beta precision `phi` | `phi = 1/sigma^2` |
| `beta_binomial()` | `sigma` | precision `phi = 1/sigma^2`, row trials | `glmmTMB` betabinomial | match precision; align trials column |
| `stats::binomial()` | event probability `mu` | logit-mean only; row trials from 0/1 or `cbind(success, failure)` | base `stats::glm()` binomial | compare coefficients, standard errors, `logLik`, AIC, and BIC directly |
| `nbinom2()` | `sigma` | size `= 1 / sigma^2` | `glmmTMB::nbinom2` / `MASS::glm.nb` theta | `theta (size) = 1/sigma^2` |
| `meta_V(V=V)` | fixed/random means, heterogeneity | known `V` added to residual | `metafor::rma.mv` with `V` | `V` is input data in both; compare heterogeneity `tau^2` notation explicitly |

**Flagged unverified (doc 158's own words, L51-70, "Correction, 2026-07-25"):**
The `gaussian()` row's `gamlss` half ("`gamlss` `sigma` is the SD directly") is
explicitly marked **unverified** in the doc itself: "no test in this repository
exercises `gamlss`; treat it as unverified rather than re-confirmed." The `glmmTMB`
half of that same row (`log(sigma)`, unsquared, compared to `fixef(fit)$disp`) IS
verified — cited to `tests/testthat/test-comparators.R:780-784` and `:831-835`.
The correction also flags that `glmmTMB::sigma()` (the accessor) is untested against
this claim and should not be assumed to follow it: "do not extend this correction to
it without a test." The `tweedie()` row's conversion is cross-checked against
`test-tweedie-location-scale.R:204-208`, which shows `glmmTMB`'s tweedie dispersion
coefficients are `2 * coef(fit, "sigma")` — i.e. `log(phi)`, not `log(sigma)` — so
doc 158 itself warns "always check the family, not just the package" when reusing the
gaussian row's pattern for another family.

No other row in the table carries an explicit verified/unverified flag in doc 158; only
the gaussian/gamlss half is called out.

## (b) Comparator Matrix — verbatim (doc 158 L74-94) + done/planned split

| `drmTMB` surface | Comparator package(s) | Matched target | What cannot be matched |
| --- | --- | --- | --- |
| Gaussian location-scale (`mu`, `sigma ~ x`) | `glmmTMB` (dispformula), `gamlss` (NO) | location + modelled scale | base `lm`/`glmmTMB` without dispformula cannot model `sigma ~ x` |
| Gaussian `mu` random intercepts/slopes | `glmmTMB`, `lme4` | RE SDs, fixed effects | modelled `sigma` alongside RE not in `lme4` |
| Gaussian `sigma` random effects | `gamlss` (random terms) | scale RE SD | few packages fit random effects in the scale |
| Residual `rho12` (bivariate) | `brms` (multivariate), `MCMCglmm` | residual response-response correlation | predictor-dependent `rho12 ~ x` has essentially no frequentist comparator |
| Bivariate covariance blocks (`corpairs()`) | `brms`, `MCMCglmm` | group-level cross-response correlations | matching `drmTMB` labelled-block semantics exactly is approximate |
| `meta_V(V=V)` | `metafor::rma.mv` | pooled mean, heterogeneity | keep `V` as known input; compare `tau^2` notation |
| Poisson `mu` (RE) | `glmmTMB`, `lme4` | counts, RE SD | — |
| NB2 (`mu`, `sigma`) | `glmmTMB::nbinom2`, `MASS::glm.nb` | mean, overdispersion (`theta=1/sigma^2`) | `glm.nb` has no RE |
| Zero-inflated/hurdle counts | `glmmTMB` (ziformula) | ZI/hurdle probability | — |
| `beta()` | `betareg`, `glmmTMB` | mean, precision (`phi=1/sigma^2`) | `betareg` has no RE; use `glmmTMB` for RE |
| `beta_binomial()` | `glmmTMB` (betabinomial) | mean, precision, trials | — |
| `stats::binomial()` fixed-effect | `stats::glm()` | event probability, fixed logit coefficients, likelihood constants | no random effects, no modelled scale, no Julia bridge promotion in the first slice |
| `lognormal()` / `Gamma(link="log")` | `glmmTMB`, base `glm` | mean, dispersion | compare lognormal on the log scale |
| `tweedie()` | `glmmTMB::tweedie` | mean, power, dispersion | weights/offsets out of first pass (doc 126) |
| `cumulative_logit()` | `ordinal::clm`, `MASS::polr`, `brms` | cutpoints, location | scale/discrimination not modelled here |
| Phylogenetic `mu` | `MCMCglmm`, `brms` (phylo), `phylolm`, `phyr` | phylogenetic SD / signal | Bayesian comparators differ in prior; `phylolm` is fixed-effect only |
| Coordinate-spatial `mu` | `spaMM`, `INLA` | spatial field | `drmTMB` coordinate fields vs SPDE/Matern differ in parameterization |
| `animal()` / `relmat()` | `MCMCglmm`, `ASReml`, `brms` | additive-genetic variance, heritability | ASReml is licensed; MCMCglmm/brms are Bayesian |
| `skew_normal()` fixed-effect | `gamlss` (SN1/SN2), `sn` package | response mean, response SD, residual slant | `drmTMB` uses public moment parameters, so comparators must map native location/scale/skewness to `mu = E[y]`, `sigma = SD[y]`, and `nu` before comparing estimates |

**Done vs planned, per doc 158's own "Executed Comparator Artifacts" / "Definition Of
Done" sections (L96-135) and cross-checked against `docs/design/05-testing-strategy.md`
L43-111:**

- **Done and banked as a Phase 19 artifact:** only the plain binomial fixed-effect row,
  via `stats::glm()`. Artifact at
  `docs/dev-log/comparator-results/2026-06-16-binomial-glm-parity/` (`n=320`, `n_rep=3`,
  seed `20260616`). Doc 158 states explicitly: "This is a parity artifact only. It does
  not support interval-calibration, speed, random-effect, structured-effect, bivariate,
  mixed-response, or Julia bridge claims."
- **Implemented as fast in-suite comparator *smoke tests* (doc 05, L43-104), which is a
  narrower thing than a banked Phase 19 timing/matched-scale artifact:** Gaussian `mu`
  random intercepts/slopes and correlated slope blocks vs `lme4::lmer`; Gaussian REML
  random intercepts and slope blocks vs `lme4::lmer(REML=TRUE)`; Gaussian REML known-`V`
  meta-analysis vs manual restricted likelihoods (cross-checked to `metafor`); Gaussian
  location-scale (fixed + random intercept) vs `glmmTMB` dispformula; Gaussian ML
  meta-analysis vs `metafor::rma.uni(method="ML")`; dense known-covariance vs
  `metafor::rma.mv`; lognormal, Gamma, Beta, Poisson, NB2 fixed-effect likelihoods vs
  independent `stats::d*()` calculations; Gamma-mean and Poisson-mean coefficients vs
  `stats::glm()`; Poisson `mu` RE vs `lme4::glmer`; zero-inflated/zero-truncated/hurdle
  NB2 vs independent pointwise calculations; NB2 vs `MASS::glm.nb()`; NB2 Poisson-limit
  behaviour.
- **Planned, not yet implemented (doc 05, L105-111):** bivariate meta-analysis with known
  within-study covariance vs `metafor::rma.mv`; dense known sampling covariance vs
  `glmmTMB::equalto()`.
- **Not yet started for the remaining Comparator Matrix rows** (no artifact, no smoke
  test found in doc 05's implemented list): `student()`, `tweedie()`,
  `beta_binomial()`, `cumulative_logit()`, phylogenetic `mu`, coordinate-spatial `mu`,
  `animal()`/`relmat()`, `skew_normal()`, residual `rho12` bivariate, bivariate
  covariance blocks (`corpairs()`).

Doc 05, L35-41 states where full sweeps belong: "Full comparator sweeps belong in
optional local scripts or scheduled CI, because package conventions, likelihood
constants, priors, and optimizer settings can differ. The current optional Gaussian
location-scale sweep is `tools/replicate-location-scale-gaussian.R`."

## (c) Issue #60 — Definition of Done and guardrails (verbatim)

**Definition of done:**
> Phase 19 is done when the comparator matrix, one-off datasets, model fits, scale
> conversions, timing summaries, limitations, pkgdown article or design note, check log,
> after-phase report, and CI evidence are present.

**Guardrails:**
> - Do not imply that every `drmTMB` model has a one-to-one comparator.
> - Do not compare parameters on different scales without explicit conversion,
>   especially `sigma`, variance, NB2 size/theta, and meta-analysis heterogeneity
>   notation.
> - Keep timing comparisons reproducible: record package versions, platform, core
>   count, seed, and model options.
> - Avoid large repeated simulations in this phase unless a separate design decision is
>   made.

Issue metadata: `#60`, "Phase 19: comparator-package benchmark and model-fit
comparison", state OPEN, author itchyshin, labels `documentation`, `enhancement`.

## (d) What doc 158 is now STALE about, given the external-oracle harness

`tests/testthat/test-comparators-external-oracle.R` landed on branch
`claude/external-oracle-intervals` (git log: `3b9939696` "test(oracle): validate against
lme4/glmmTMB shipped corpora, including intervals", then `764d30152` "fix(test): stop
the oracle suite leaking lme4 onto the search path"). Doc 158 was last substantively
edited by the 2026-07-25 gaussian-dispersion correction and does not mention this file
or its evidence at all. Concretely stale/missing relative to doc 158:

1. **A second executed comparator artifact exists that doc 158's "Executed Comparator
   Artifacts" section (L96-118) does not list.** Doc 158 currently states only one
   artifact is banked (the binomial `glm()` parity bundle). The external-oracle suite
   adds Gaussian random-slope/random-intercept point agreement against `lme4`'s own
   shipped `test_data/models.rda` fixtures (`fm_us1`, `fm_diag2` twins: fixed effects, RE
   SDs, RE correlation, `sigma`, `logLik`, all at `tolerance = 1e-4`) — this is new
   coverage of the "Gaussian `mu` random intercepts/slopes" comparator-matrix row (L77)
   using `lme4`'s own regression fixtures rather than a fresh simulated dataset, which
   doc 158's Principle 1 ("Phase 19 reuses a small set of representative simulated or
   tutorial datasets from Phase 18") did not anticipate as a source.

2. **Doc 158 has no row or language for interval/profile-CI comparator evidence at all**,
   but the harness now asserts profile-CI endpoint agreement against `lme4`'s shipped
   `fm1P` reference matrix (`sleepstudy`, `Reaction ~ Days + (Days | Subject)`, 4
   targets: `sd(Intercept)`, `sd(Days)`, `cor`, `sigma`) at a 5e-4 absolute bound. This
   is new ground doc 158's matrix and "Definition Of Done" (which only requires "model
   fits on matched scales" and "timing summaries") do not cover, and — per
   `docs/design/242-external-comparator-evidence-class.md`'s 2026-08-15 amendment — this
   evidence is deliberately kept OUT of the capability ledger as a test-only regression
   guard, not promoted to an `external_comparator` ledger row, because a row would have
   to declare in `claim_boundary` that it excludes intervals, which would be false for
   this specific test. Doc 158 should either add an explicit note pointing to doc 242's
   amendment or state its own position; right now a reader of doc 158 alone would not
   know this evidence exists.

3. **The harness's own header states an unresolved provenance problem** doc 158 has no
   mechanism to record: `fm1P`/`fm1B`'s generating estimator (ML vs REML) is not
   recoverable from `lme4`'s shipped fixture — "a converged REML/bobyqa refit reproduces
   fm1P to 5.63e-5 — better than two of three ML reconstructions" — so the test explicitly
   disclaims proving which estimator drmTMB is being checked against. Doc 158's
   Scale-Conversion Reference and Comparator Matrix both assume a known, statable
   estimator per comparator cell; this is the first case in the repo where that
   assumption doesn't hold for the reference itself, independent of drmTMB.

4. **The harness explicitly does NOT assert REML interval parity** (its own comment,
   L19-23): "Fisher's review measured a real ~5% profile-CI gap on 3 of 4 targets ...
   in a single REML-vs-REML spot check." Doc 158's matched-scale table has no REML/ML
   column at all — every row is scale-conversion only, silent on estimator. PR 2 should
   not read the ML point-agreement success in this file as implying REML interval
   agreement; the harness itself forbids that inference.

5. **Minor:** doc 158's "Executed Comparator Artifacts" section frames artifacts as living
   under `docs/dev-log/comparator-results/...`, but the external-oracle evidence and its
   audit trail live under `docs/dev-log/external-oracle/` (see doc 242's amendment,
   which cites `docs/dev-log/external-oracle/` as "Evidence for it"). Doc 158 does not
   mention this second artifact-storage location; PR 2 should decide whether to fold it
   in or keep it separate, and doc 158 should say which.

## Recommendation for PR 2 (scout observation, not a decision)

Doc 158 is the plan-of-record for the *matrix and conversions*, and nothing above
contradicts it — the scale conversions and matched targets are still correct. What is
stale is completeness: the "Executed Comparator Artifacts" and "Definition Of Done"
sections do not yet reflect the external-oracle point-agreement and interval work that
already landed. PR 2 should update doc 158's L96-118 to list the second artifact and
add a short cross-reference to doc 242's 2026-08-15 amendment for the interval-evidence
policy, rather than re-deriving the comparator matrix from scratch.

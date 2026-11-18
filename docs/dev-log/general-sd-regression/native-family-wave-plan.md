# Bounded implementation plan: predictor-dependent random-effect SDs

## Aim and boundary

Deliver fixed-predictor random-effect SD regression through the existing `sd()`
formula grammar. Start with native Bernoulli, then admit each currently supported
family and effect shape through a separate evidence row. Treat R/TMB and DRM.jl
as separate execution engines with shared target and output contracts.

This plan does not claim that every mathematical combination is identifiable.
Structural exclusions need a mathematical argument; missing implementation stays
open work. The first slices are ordinary location random-intercept SD regressions.
Do not add response families, more than two responses, random effects inside the
SD formula, or new correlation-regression models in this wave.

## Current verified position

- Native Bernoulli ordinary intercept formulas and selector-aware outputs have
  passed source and compiled workflow checks. The 3,000-attempt first calibration
  look returned `look2_required`: 12 gates passed and one coverage gate remained
  ambiguous, so overall qualification is false. Three adapter probe fits have
  since run and passed their per-fit diagnostics, but their overall qualification
  remains `INCOMPLETE / NOT_QUALIFIED` because whole-run elapsed time was not
  retained. The independent audit, source-bound results, and probe-attempt record
  are under `evidence/calibration-20261017/`. The 9,000-row production second look
  has not run, and requires a fresh source-pinned qualification with recorded
  whole-run timing.
- Native Poisson ordinary intercept SD regression, a unique labelled intercept,
  and a separate numeric slope-only slice have focused compiled checks. The slope
  slice is commit `425bee81572c625a634b2b083050c5c57c1dc1f1`; it is not calibrated.
- Lognormal ordinary-intercept SD regression has an independent marginal
  reference and a compiled Totoro integration pass (24 expectations) for source
  archive SHA-256 `bad56b4bf70e56972bc1fde2a10a578690789ccca6159e131e09e54176870ffa`.
  The current test and helper hashes exactly match the tested archive members, so
  the fresh-effect variance-ratio assertion is included in that compiled pass.
- Native NB2 ordinary-`mu` SD regression now has intercept and one independent
  numeric-slope slices with compiled synthetic recovery, an independent
  groupwise Laplace likelihood oracle, constant-SD equivalence, and
  prediction/simulation/save-reload/profile/bootstrap-refit smoke checks. A
  separate zero-inflated NB2 `mu` route has its own intercept and slope tests.
  A restricted `sigma`-endpoint route is also present for complete data with
  fixed `mu`, no zero-inflation formula, and one independent sigma intercept or
  slope. These checks are point-recovery and workflow evidence, not interval
  calibration. Structured/correlated effects, missing-data combinations, other
  endpoint combinations, and Julia parity remain open. The prior compiled
  receipts are not source-hash-bound to the current dirty C++ and R files, so a
  fresh source-bound run is still needed before claiming current-source compiled
  evidence.
- Native Beta-binomial ordinary-intercept SD regression now has a compiled
  recovery fit, an independent groupwise marginal-likelihood quadrature oracle,
  a wrong-group-index negative control, constant-SD equivalence, prediction,
  simulation, save/reload, profile, and bootstrap-refit checks. The existing
  Beta-binomial regression suite is being rerun alongside this change. This is
  not interval-calibration evidence; the initial admission is complete-response
  `mu` intercepts only, with trial-count semantics retained.
- Native zero-one-beta ordinary-intercept SD regression now has a compiled
  recovery fit, an independent marginal-likelihood quadrature check, a
  wrong-group-index control, constant-SD equivalence, and prediction,
  simulation, save/reload, profile, and bootstrap-refit smoke checks. This is
  not interval-calibration evidence. One seeded `se = TRUE` fit converged with
  `pdHess = TRUE`; this is a fit-health check, not coverage evidence. The
  admission is complete responses and
  one ordinary `mu` intercept, with no other random effects or structured
  effects in the model.
- Native cumulative-logit ordinary-intercept SD regression now has compiled
  synthetic recovery, independent groupwise Gaussian integration, a
  wrong-group-index control, constant-SD equivalence, prediction, simulation,
  and save/reload checks. This is not interval-calibration evidence. The first
  admission requires complete responses and one ordinary `mu` intercept; other
  random effects and structured effects remain outside this slice.
- Native zero-truncated NB2 ordinary-intercept SD regression now has compiled
  synthetic recovery, independent groupwise integration of the truncated
  likelihood, a wrong-group-index control, constant-SD equivalence, prediction,
  simulation, and save/reload checks. This is not interval-calibration
  evidence. The first admission requires complete responses, one ordinary
  `mu` intercept, and no hurdle formula or other random effects.
- Native Student-t ordinary location-intercept SD regression has source and
  compiled recovery, group-SD prediction/extraction, constant-SD equivalence,
  an independent fixed-parameter Laplace oracle with a wrong-group negative
  control, and profile/bootstrap target-routing smoke checks. Native TMB now
  also admits one complete-data independent location-slope SD target. Its
  synthetic recovery, slope-loading Laplace oracle, wrong-group control,
  constant-SD equivalence, prediction, simulation, save/reload, and
  profile/bootstrap target-routing checks pass. Interval calibration remains
  open. Correlated blocks, structured effects, random effects on `sigma` or
  `nu`, response masking, and imputation remain outside this slice. Julia has
  the matching ordinary Student intercept or independent-slope route with
  fixed `sigma ~ 1` and `nu ~ 1`; a same-data slope comparison now passes
  through the R bridge. Calibration and broader target shapes remain open.
- DRM.jl has a private Bernoulli numerical module and a clean public-integration
  lane. A read-only audit found that the helper was not included or reachable by
  public `drm()`. Public dispatch and group-SD prediction are now under
  implementation; public profile/bootstrap, interval validation and calibrated
  uncertainty remain open until tested and reviewed.

## Bounded waves

| Wave | Scope | Admission conditions | Minimum acceptance before the next family |
|---|---|---|---|
| 0. Contract and baseline | Pin source versions, target identity, formula coding, group-constant SD design rule, kernel interpretation, output fields, and required family/effect inventory | No unsupported capability is counted as identified merely because code is absent | Reviewed symbol-to-R-to-C++ contract; executable row ledger; existing constant-SD and public-output baselines retained |
| 1. Bernoulli vertical slice | Native and Julia ordinary independent location intercept; fixed SD predictors; Bernoulli link scale | Complete data initially; one scalar coefficient target per group; fixed residual convention for each engine documented | Matching independent marginal likelihood or independent integration oracle; wrong-index controls; recovery over frozen positive/null/negative effects; profile or bootstrap interval calibration; prediction/extraction/refit parity; exact documentation and reviewer readback |
| 2. Remaining native ordinary intercept families | Lognormal, NB2, Student, skew-normal, Gamma, Tweedie, then any additional univariate/bivariate families in the pinned inventory | One family and endpoint per slice. Preserve its link, parameter transform, fixed likelihood, and existing random-effect covariance. Start with complete-data `mu`; add other dpars only in later slices | Source admission tests; exact/quadrature/external likelihood oracle appropriate to family; constant-SD reduction; fit health and one predeclared recovery DGP; group labels, intervals, prediction, simulation, save/reload and refit tests. Family-level calibration before inference-ready wording |
| 3. Ordinary effect expansion | Independent numeric slopes; correlated blocks; labelled and cross-parameter blocks; crossed/nested layouts | One covariance shape and one layout per row. Predictor design must identify each SD coefficient separately | Independent covariance/marginal oracle, wrong-member/index controls, constant-SD equivalence, positive-definite/correlation checks, recovery and uncertainty for the named estimands |
| 4. Structured providers | Phylogenetic, animal/relatedness, spatial, interaction and sparse/projected routes | Preserve each provider's current kernel and scaling. Report multiplier SD separately from marginal SD when kernel diagonal differs from one | Dense/sparse or exact covariance oracle, provider label alignment, kernel diagonal and prediction checks, fit recovery and uncertainty on each admitted route |
| 5. Other distributional endpoints and bivariate routes | `sigma`, shape, inflation/hurdle and supported second-response endpoints | One endpoint combination at a time; exclude random effects inside SD predictors and new correlation regression | Family-specific likelihood oracle, target-aware simulation/extraction/profile/bootstrap checks, calibrated intervals for each advertised endpoint |
| 6. Julia public integration | Public constructor/dispatcher, fitted object metadata, prediction, extraction, refitting, profiles and bridge for each admitted row | Resolve shared-file ownership before touching canonical dispatcher or bridge. Preserve Julia's residual-scale convention or define and test its mapping to R | Independent Julia-vs-oracle checks first; then matched R/Julia comparisons where approximations align; public workflow tests and calibrated uncertainty per advertised row |
| 7. Release-quality closeout | Full capability reconciliation, documentation, examples, platform checks and independent review | No unresolved required row is silently relabelled diagnostic-only | Re-run every row's gates, full R and Julia checks, rendered-doc review, exact evidence/hash audit and explicit remaining-work report |

## Family order within Wave 2

Use the source map in `native-family-sd-adapter-map.md` as a cost hypothesis,
not as a support claim:

1. **Lognormal, NB2, Gamma, Tweedie, zero-one beta, Student-t, and skew-normal ordinary intercepts** are admitted in native R/TMB. Their current slices have family-specific compiled checks. Independent likelihood oracles and interval calibration remain open for Tweedie and skew-normal; Student-t now has an independent fixed-parameter Laplace oracle but still lacks interval calibration. NB2 and Gamma have groupwise Laplace oracles; Beta, beta-binomial, and zero-one beta have independent marginal quadrature. Keep effect-shape expansion separate and review each source path before broadening capability claims.
2. **Skew-normal**. Add the predictor-side scale mechanism to its constant-SD branch while preserving shape parameters.
3. **Gamma** and **Tweedie**. Preserve the mean/dispersion maps and Tweedie power
   constraints; use family-specific independent likelihood checks.
4. **Beta-binomial** ordinary intercept is implemented in native TMB for
   complete responses. Keep its denominator and trial-count semantics distinct
   from the ordinary Beta `mu` SD route; calibrated uncertainty and broader
   effects/endpoints remain open.
5. Reconcile the remainder of the pinned univariate/bivariate inventory by
   exact response-family and endpoint row. Do not infer support from shared TMB
   model types or generic extractor code.

## Bernoulli variance-regression precedent

The `dhglm` package is a close prior-art comparator for the first Bernoulli
slice. Its official reference manual allows `RespDist = "binomial"` and fixed
covariates in `LinPredRandVariance` for random-effect variances. With its
documented log-variance link, `log(lambda_g) = W_g gamma`; since
`lambda_g = tau_g^2`, the equivalent log-SD coefficient is
`alpha = gamma / 2`. This means the general model idea is established prior
art. The manual documents h-likelihood or first-order Laplace estimation for
fixed effects and adjusted profile likelihood for dispersion parameters, so
it is not a drop-in oracle for drmTMB's marginal-likelihood objective or its
profile/bootstrap intervals. Use it to sharpen the model and output comparison;
require an objective and target-scale reconciliation before numerical
cross-package comparison. Source detail and limitations are in
[`research.md`](research.md#dhglm-prior-art-correction-and-cited-notebooklm-review-2026-10-20).

## Pinned response-family map

The programme inventory contains20 routes at the pinned source versions. The
family labels below are source-universe rows, not promises that every endpoint
or backend admits the same SD term. Ordinary `mu` intercepts are the first
post-Bernoulli target; the remaining endpoints listed in the family ledger stay
open as separate rows.

| Inventory family route | Bounded follow-up wave | Route-specific check before admission |
|---|---|---|
| `binomial` / Bernoulli | Wave1 | Link-scale random-intercept SD; no free residual `sigma`; compare native and Julia residual conventions |
| `poisson` | Wave2, after lognormal/NB2 | Count likelihood oracle; retain the separate verified numeric slope-only slice |
| `gaussian` | Baseline/contract and regression reference | Preserve constant-SD covariance blocks, predictors, and fitted likelihood exactly |
| `lognormal` | Wave2 first | Exact log-response marginal covariance and response Jacobian; fixed residual `sigma` |
| `nbinom2` | Current native candidate implements ordinary-`mu` intercept/numeric-slope slices and a separately fenced `sigma` endpoint; source-bound compiled rerun remains | Preserve overdispersion `sigma` transform and correlated-effect row map; structured effects, missing-data combinations, Julia parity, and calibration remain open |
| `student` | Wave2; complete-data ordinary location intercept and one independent numeric location-slope SD target delivered in native TMB and Julia; the independent-slope cell has a live same-data R-bridge comparison with fixed `sigma ~ 1` and `nu ~ 1` | Tail parameter `nu`, scale clamp, and random location effect remain distinct. Native slope recovery, independent Laplace oracle, target-routing checks, and one cross-engine point comparison pass; correlated/structured SD effects and calibration remain open |
| `skew_normal` | Wave2 | Skew parameter and location-scale likelihood remain unchanged |
| `gamma` | Wave2 | Ordinary `mu` intercept and independent-slope SD slices, selected structured `mu` routes, and one ordinary `sigma` random-intercept SD route have focused native checks. A fixed-seed `sigma`-endpoint recovery smoke test now covers coefficient recovery, group-SD prediction, link decomposition, simulation, and save/reload. Other `sigma` effect shapes/providers, Julia `sigma` parity, and interval calibration remain open. Preserve the mean/CV parameterization and log-scale residual effects |
| `tweedie` | Wave2 | Power `nu`, `phi=sigma^2` mapping, and zero-mass likelihood remain unchanged |
| `beta` | Native Wave2 ordinary intercept complete; Julia ordinary intercept point-fit slice delivered | Strict `(0,1)` support; ordinary location SD remains separate from the narrow phylogenetic `mc-0017` exception. Julia has recovery, prediction, constant-SD equivalence, independent quadrature, bootstrap-refit, and live bridge parity checks; interval calibration and broader effects remain open |
| `beta_binomial` | Wave2 | Trial denominators and overdispersion remain distinct from Bernoulli |
| `cumulative_logit` | Wave2 special likelihood route; complete-response ordinary-intercept SD slice delivered in native TMB | Ordered cutpoints and fixed latent logistic residual scale are retained; no interval-calibration claim |
| `zero_one_beta` | Wave2 special likelihood route; complete-data ordinary-intercept SD slice delivered in native TMB | Interior beta location SD is predictor-dependent only in the admitted slice; `sigma`, exact-boundary `zoi`, and conditional `coi` remain fixed-effect only there |
| `truncated_nbinom2` | Wave2 special likelihood route; complete-response ordinary-intercept SD slice delivered in native TMB | The group-specific latent location effect enters both the NB2 likelihood and zero-truncation normalization; hurdle SDs remain open |
| `zi_poisson` | Native complete-data ordinary `mu` intercept SD slice delivered; broader endpoint wave remains open | `sd(group) ~ predictors` scales one ordinary `mu` intercept; structural-zero `zi` stays fixed-effect only. Recovery, independent groupwise integration, wrong-index control, constant-SD equivalence, and workflow checks pass; interval calibration, other random-effect types, missing responses, and Julia ZIP remain open. |
| `zi_nbinom2` | Current native candidate implements ordinary-`mu` intercept/numeric-slope slices; source-bound compiled rerun remains | Conditional count `mu`, overdispersion `sigma`, and structural-zero `zi` are distinct targets; other endpoints, structured effects, Julia parity, and calibration remain open |
| `hurdle_nbinom2` | Wave5 endpoint wave | Truncated count component and hurdle `hu` likelihood checked independently |
| `biv_gaussian` | Wave5 bivariate wave | `mu1`, `mu2`, `sigma1`, `sigma2`, residual `rho12`, and supported cross-parameter blocks get separate rows |
| `biv_lognormal` | Wave5 bivariate wave | Positive-pair likelihood, log-scale covariance, and response Jacobian |
| `biv_student` | Wave5 bivariate wave | Both tail parameters, residual dependence, and joint integration are separately identified |

For every row, enumerate every endpoint present in `family-endpoints.tsv`; the
univariate `mu` first-wave priority does not drop other endpoints. Those include
`mu1`/`mu2`, `sigma`/`sigma1`/`sigma2`, `nu`, `zi`, `zoi`, `coi`, `hu`, and
`rho12` where present in the fitted specification. The required universe also
crosses each route with effect type, provider, response dimension and backend.
The ledger's19,118 rows remain the denominator until source pins or reviewed
structural identifiability findings change it.

## Evidence and gates

For every family/effect/endpoint/backend row, retain: source pin; formula and
symbolic contract; positive and negative assembly tests; independently generated
DGP; independent likelihood/covariance oracle; all attempted fit outcomes;
constant-SD baseline; prediction/extraction/refit behavior; interval method and
calibration denominator; docs and independent review. A single successful fit is
point-fit evidence only. A shared calibration mechanism can support another row
only when a reviewer confirms the link, target mapping, integration and uncertainty
procedure match, and held-out row checks pass.

Simulation campaigns must state a runtime estimate and test that detects a wrong
answer before launch. A campaign estimated above3h needs a measured pre-run and
specific approval. Do not use GitHub Actions for recovery or calibration.

## Immediate next actions

1. Student scalar SD parity: complete for the ordinary location intercept and
   selected independent numeric slope. The R-to-Julia payload now uses the
   canonical `sd` label for this admitted route; the target selector and public
   identity are preserved. The direct Julia Student oracle suite passed 36/36,
   and the live R/TMB–Julia filter passed both Student routes. This is point and
   output workflow evidence, not interval calibration.
2. Priority-family smoke wave: current focused Julia runs passed Bernoulli /
   Binomial (203/203) and Beta (43/43); the Beta R/TMB–Julia bridge ran two live
   tests with no failures. Native ordinary NB2, truncated NB2, and ZI-NB2 test
   filters passed on the current candidate. Gamma now has one native `sigma`
   random-intercept SD recovery smoke test; Julia `sigma` parity remains open.
   Continue the five-family priority wave (Gaussian, Binomial, Poisson, NB2,
   Gamma) by taking the next uncovered endpoint/backend row, then reconcile the
   high-value Beta / beta-binomial extensions across both engines.
3. For each next family/effect slice, verify exact source pins, target mapping,
   independent oracle, constant-SD equivalence, public outputs, and
   existing-model regression before broadening the route. Keep families,
   effect shapes, endpoints, providers and engines that have not been tested in
   the required-row ledger.
4. Keep the Bernoulli second-look interval-calibration adapter as a later
   programme follow-up. Do not treat fit recovery or workflow smoke tests as
   calibrated uncertainty. Refresh required-row evidence after each wave and
   leave the goal open until the full approved capability universe is covered.

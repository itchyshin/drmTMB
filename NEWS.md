# drmTMB 0.6.0 (development)

## Reader-facing plotting surface complete (issue #58)

* The figure gallery now demonstrates all six public plotting functions.
  Alongside the existing `plot_parameter_surface()`, it adds worked examples of
  `worm_plot()` and `qq_plot()` (on a correctly specified fit paired with a
  deliberately mis-specified one, so a reader can see what misfit looks like),
  `centile_chart()`, `plot.profile.drmTMB()` via `profile()`, and a fitted
  `plot_corpairs()` correlation row with a computed profile interval.
* The gallery's hand-typed illustrative figures now declare themselves as
  fixtures in their own titles, not only in captions, so a screenshot cannot be
  mistaken for a fitted result. A long-standing inverted axis label on the
  simulation bias panel is corrected. Documentation only; no code change.

## Arc 4c ordinary `mu` random-slope profile coverage

* The exact independent `mu` random-slope cells for `skew_normal()`
  (`mc-0464`), `tweedie()` (`mc-0539`), and `zero_one_beta()` (`mc-0575`) are
  now `inference_ready_with_caveats` for the standard ML-Laplace profile
  interval. A retained 1,200-attempt-per-M Fir campaign supports a deployment
  floor of M=16 for each family at true slope SD 0.50. The ledger estimator
  remains `ML`; no cell earns `supported` status.
* This narrow result does not cover other SDs, observation counts, group grids,
  correlated or labelled slopes, scale/shape random effects, structured
  effects, REML, or AGHQ. Skew-normal retains slant-identification risk,
  Tweedie retains small-M zero-boundary profiles, and zero-one beta needs a
  deterministic strictly-interior-generator rerun before claiming exactly 15%
  observed boundary mass. Campaign point-bias and Wald coverage are unavailable
  because of a disclosed reporting defect; profile coverage is unaffected and
  the prospective extractor is repaired.

## Beta q1 phylogenetic location intercept

* Native univariate ML `beta()` now admits one unlabelled intercept-only
  `phylo(1 | species, tree = tree)` term in `mu`. Family `sigma` remains a
  fixed-effect formula and controls `phi = sigma^(-2)`; it is distinct from
  the constant latent phylogenetic location-effect SD.
* An independent `dbeta()` plus augmented-GMRF joint-likelihood oracle and
  central-difference gradient check cover the exact implementation. A fresh,
  predeclared 800-fit Totoro campaign retained 400 attempts at each of
  `g = 512, m = 4` and `g = 1024, m = 4`; all fits converged with
  `pdHess = TRUE`. The log-latent-SD recovery gate held at `g = 512` and
  passed only at the exact tested `g = 1024, m = 4` cell.
* This is a `point_fit_recovery` admission only for that exact tested regime,
  not `g >= 1024` or a universal minimum species count. Moderate-information
  `g = 256` and `g = 512` results remain explicit HOLDs. REML, q2/q4, labels,
  phylogenetic slopes, phylogeny in family `sigma`, direct `sd()` regression,
  `zero_one_beta()`, missing/external data, intervals, coverage, and broader
  Beta or all-family claims remain outside this PR.

## Exact supplied-relatedness q2 REML intercept (Arc 1b-S2R)

* `drmTMB(..., REML = TRUE)` now admits one exact bivariate-Gaussian
  supplied-relatedness location cell: matching labelled
  `relmat(1 | p | id, K = K)` intercepts in `mu1` and `mu2`. Both formulas
  must use the same label, group ordering, and supplied covariance matrix `K`;
  `sigma1`, `sigma2`, and `rho12` must be intercept-only; response pairs must
  be complete; weights must equal one; and no known `meta_V()`, additional
  random effect, direct-SD formula, or `corpair()` regression may be present.
* An independent dense restricted-likelihood oracle matches the native TMB
  objective at the optimum and two displaced parameter vectors. A deliberately
  wrong precision orientation fails materially. The predeclared 2,400-fit
  Totoro campaign retained every attempt; every fit converged with
  `pdHess = TRUE`, and all structured-SD, structured-correlation, and RMSE
  gates passed.
* This is a `point_fit_recovery` admission only. Supplied precision `Q`,
  `animal()`, slopes, scale-side blocks, q4 or larger blocks, non-Gaussian
  families, intervals, coverage, AI-REML, and `supported` claims remain outside
  this arc.

## Exact bivariate-spatial q2 REML intercept (Arc 1b-S1)

* `drmTMB(..., REML = TRUE)` now admits one exact bivariate-Gaussian
  coordinate-spatial location cell: matching labelled
  `spatial(1 | p | site, coords = coords)` terms in `mu1` and `mu2`, with
  intercept-only `sigma1`, `sigma2`, and `rho12`, complete response pairs,
  unit weights, no known `meta_V()` covariance, and no additional ordinary
  random effect, direct-SD formula, or `corpair()` regression. The spatial
  covariance is fixed by the coordinates; range estimation is not part of
  this slice.
* An independent dense restricted-likelihood oracle matches the native TMB
  objective at the optimum and displaced parameter vectors. A predeclared
  1,200-fit Totoro campaign completed without fit or convergence failures;
  1,198 fits had positive-definite Hessians, and the high-information cells
  passed all structured-SD and latent-correlation recovery gates.
* This is a `point_fit_recovery` admission only. Spatial slopes, range
  estimation, animal-model bivariate REML, supplied-`Q` relatedness REML,
  scale-side q2, q4 or larger blocks, intervals, coverage, AI-REML, and
  `supported` claims remain outside this spatial arc. Arc 1b-S2R subsequently
  admits only the exact matching supplied-`K` `relmat()` q2 location-intercept
  cell at the same evidence tier.

## Positive-continuous q1 structured location intercepts (Arc 3a)

* Native univariate ML now fits one unlabelled q1 structured intercept in
  `mu` for Gamma-`phylo()`, lognormal-`phylo()`, and
  lognormal-`relmat()` using `K` or `Q`. The effect enters the Gamma log-mean or lognormal
  log-response location predictor. Gamma-`relmat()` retains its existing
  intercept and independent one-slope route.
* Focused likelihood, extractor, prediction-decomposition, K/Q parity, and
  rejection-neighbour tests are green. A 6,000-fit primary Totoro campaign
  certified lognormal-`relmat()` and retained the predeclared phylogenetic
  intercept-RMSE HOLD. A separate, freshly seeded 2,400-fit phylogenetic
  addendum then passed its design-conditioned GLS-oracle and structured-field
  projection gates without relaxing the original threshold. All three new
  cells are therefore `point_fit_recovery`; no interval tier is implied.
* New-route slopes, labels/q2+, `sigma` structure, joint `mu`/`sigma`,
  simultaneous structured providers, spatial/animal, bivariate responses, REML, intervals, coverage,
  and `supported` claims remain outside this arc.

## Exact-Gaussian REML for mean-side structured providers (Arc 1a)

* `drmTMB(..., REML = TRUE)` now admits pure-`mu`, univariate Gaussian
  `spatial()`, `animal()`, and `relmat()` terms as an unlabelled intercept or an
  independent intercept plus one numeric slope. These routes require
  `sigma ~ 1` with no sigma random effect.
* Independent restricted-likelihood oracles, representation-parity fixtures,
  and Totoro recovery and profile campaigns support the three cells at
  `inference_ready_with_caveats`. The campaigns used spatial coordinates,
  animal `A`, and relmat `K`: spatial and relmat cover exactly `M={8,16,32}`;
  the animal `A` campaign covers one fixed `M=8`; all use `n_each=20`, where
  `M` is the number of structured levels (and hence the matrix dimension) and
  `n_each` is the number of observations per structured level. Pedigree and
  `Ainv` animal inputs and relmat `Q` have deterministic representation-parity
  evidence only, not multi-seed campaign coverage.
  Coverage clears the pre-specified small-sample floors but is not
  nominal-exact, so `supported` is withheld.
* The fitted structured SD scale `s_j` gives latent-field covariance
  `s_j^2 K_h`; a node's marginal SD is `s_j sqrt(K_h[ii])`, so it equals
  `s_j` only when that diagonal entry is one. Slope-only,
  labelled or multiple slopes, sigma random effects, matched `mu+sigma`,
  bivariate and non-Gaussian routes remain outside this Arc 1a claim.

## Residual-scale random intercepts for lognormal and Gamma (Arc 2c)

* `predict(..., dpar = "sigma")` now includes the fitted residual-scale random
  intercept for `lognormal()` and `Gamma(link = "log")` models; `sigma()`,
  printed fit summaries, and the emmeans preflight use the same corrected
  capability detection.
* A residual-scale (`sigma`) random intercept `sigma ~ ... + (1 | id)` is now
  accepted for `lognormal()` and `Gamma(link = "log")`, joining `gaussian()`
  (full) and `nbinom2()` (intercept-only) as the families that allow a
  random effect on a dispersion parameter.
* As with the mean random effects, the `sigma`-SD is fit by maximum likelihood
  with the Laplace approximation and can be biased downward when the number of
  groups or the per-group replication is small. Point recovery at 40 groups
  has -3% to -4% relative bias. The separate Arc 4a iid campaign promotes only
  the lognormal route to `inference_ready_with_caveats` for true SD 0.4,
  `n_each=12`, and exactly `M={16,32,64}`; coverage is mildly
  anti-conservative, not nominal. Gamma retains point-recovery evidence only.
  See `docs/dev-log/simulation-artifacts/2026-07-12-arc2c-sigma-recovery/` and
  `docs/dev-log/simulation-artifacts/2026-07-12-dg3-re-sd-coverage/README-profile-iid-v2.md`.
  Sentinels remain in `tests/testthat/test-arc2c-sigma-random-intercept.R`.
* Scope (first gate): one independent `sigma` random intercept only. A `sigma`
  random slope, labelled covariance blocks, and combining a `sigma` random
  effect with a `mu` random effect in the same model remain rejected until joint
  recovery tests exist. The other non-Gaussian families still reject `sigma`
  random effects.

## Random slopes for the intercept-only families (Arc 2b)

* One independent `mu` random slope `(0 + x | id)` is now accepted for the five
  families that gained a random intercept in Arc 2a: `binomial()`,
  `cumulative_logit()`, `skew_normal()`, `tweedie()`, and `zero_one_beta()`.
  Combined with Arc 2a, every fitted univariate family now supports both a mean
  random intercept and an independent mean random slope.
* Random-effect standard deviations for these families are fit by maximum
  likelihood with the Laplace approximation and can be biased downward when the
  number of groups or the per-group replication is small. All five have point
  recovery from a 60-seed sweep (per-family relative slope-SD bias of -2% to
  -9% at 40 groups). A separate Arc 4a iid campaign promoted the binomial
  route to `inference_ready_with_caveats` at true SD 0.6, 12 observations and
  12 trials per observation, and exactly `M={32,64}`; it is coverage-backed but
  mildly anti-conservative rather than certified nominal. Point-recovery
  evidence is in
  `docs/dev-log/simulation-artifacts/2026-07-12-arc2b-slope-recovery/`, with
  single-seed DG2 sentinels in `tests/testthat/test-arc2b-mu-random-slope.R`;
  corrected binomial coverage evidence is in
  `docs/dev-log/simulation-artifacts/2026-07-12-dg3-re-sd-coverage/README-profile-iid-v2.md`.
  Later campaigns promoted cumulative-logit (`mc-0227`) and the three Arc 4c
  cells above under their own exact design-specific caveats.
* Scope: one independent `mu` slope only. Correlated intercept-slope blocks
  `(1 + x | id)`, labelled covariance blocks `(0 + x | p | id)`, and
  `sigma`/shape/inflation-dpar random effects remain rejected for these families.

## Random intercepts for every family (Arc 2a)

* An ordinary `mu` random intercept `(1 | group)` is now accepted for the five
  families that previously rejected all random effects: `binomial()`,
  `cumulative_logit()`, `skew_normal()`, `tweedie()`, and `zero_one_beta()`.
  Every fitted family now supports at least a mean random intercept, joining the
  families (`gaussian()`, `poisson()`, `nbinom2()`, `gamma()`, `lognormal()`,
  `beta()`, `beta_binomial()`, `student()`, `truncated_nbinom2()`) that already
  did.
* Fits are by maximum likelihood (Laplace). Random-effect standard deviations
  are recovered at a known data-generating point (per-family DG2 sentinels in
  `tests/testthat/test-arc2a-mu-random-intercept.R`). With few or small clusters
  the random-effect standard deviation can be biased low under the Laplace
  approximation; adaptive Gauss-Hermite quadrature is the standard remedy for
  the non-Gaussian families and remains planned.
* Scope: `mu`-side intercepts only. Random slopes, `sigma`/shape/inflation-dpar
  random effects, labelled covariance blocks, and (for `cumulative_logit`)
  combining a phylogenetic effect with an ordinary intercept remain rejected in
  this slice.

## Distributional output & adequacy layer (#747, #748)

* Every fitted family now exposes a shared fitted-distribution foundation:
  `drm_family_dpq()` (internal registry) and `fitted_distribution()` return
  per-row density (`d`), CDF (`p`), and quantile (`q`) closures at the
  fitted, fixed-effect distributional parameters. All 18 fitted `model_type`
  values are promoted to `status = "reference"`, including bivariate
  `biv_gaussian` (marginal-only: `response = 1` or `2` selects which
  response's `N(mu_k, sigma_k)` marginal is returned; the joint distribution
  and `rho12` are out of scope).
* `residuals(fit, type = "quantile")` returns Dunn-Smyth (1996) randomized
  quantile residuals, `qnorm(F(y; theta_hat))`, for every family; `worm_plot()`
  and `qq_plot()` draw the corresponding detrended and ordinary QQ diagnostics,
  with an optional `nsim` multi-realization seed envelope so a single
  randomized draw is not over-read.
* `predict(fit, type = "quantile", prob = )` returns conditional response
  quantiles; `exceedance(fit, threshold, newdata)` returns `Pr(Y > threshold)`
  (or its complement) as a thin wrapper over the shared CDF; `centile_chart()`
  draws model-conditional centile curves against one covariate. All three, and
  the plug-in prediction intervals, carry `attr(., "calibrated") <- FALSE`;
  none of these outputs propagate `theta_hat` uncertainty.
* **What the diagnostic detects, and what it does not (see
  `docs/dev-log/simulation-artifacts/2026-07-12-dg3-power-arm-gated/`,
  400-seed gated campaign across all 18 families; tweedie: 99 of 400 seeds
  locally, 66/99 dispersion-arm non-convergence, full run deferred to
  Totoro).** Under a correctly
  specified fixed-effect model, type-I error stays near or below the nominal
  rate (Type-I 0.0025-0.025 across families at alpha = 0.05; the KS+PIT
  statistic is conservative, so power is understated, not overstated). Under
  a genuine distributional shape/atom mis-specification that a family cannot
  reabsorb through its own free parameters -- heavy tails fit as Gaussian
  (power 0.925-0.995), overdispersion or zero-inflation ignored by a family
  with no free dispersion parameter (Poisson: 0.9625-0.9825), truncation
  ignored and a plain count model fit instead (`truncated_nbinom2` vs plain
  `nbinom2`: 1.0), a zero/one atom ignored and a plain beta fit instead
  (`zero_one_beta`/`tweedie`: 0.99-1.0) -- power is high, typically >= 0.8 at
  n = 300-400 per arm. There is a genuine **structural blind spot**, not a
  bug: a mis-specification that a fitted family's own free nuisance or
  dispersion parameter can absorb leaves the fitted-model residual marginally
  N(0,1) and is **not detectable** by this diagnostic -- e.g.
  heteroscedasticity absorbed by Student-t `nu` (power 0.035 at n = 300,
  versus 1.0 for the same heteroscedasticity under Gaussian, which has no
  absorbing parameter), missing zero-inflation absorbed by `nbinom2` `sigma`
  (power 0.035, versus 0.9625 for the same missing zero-inflation under
  Poisson), and fitting a plain `nbinom2`/beta-binomial/Tweedie to data whose
  TRUE dispersion actually varies with a covariate, which its own constant
  dispersion parameter partially soaks up (power 0.01-0.14, versus 0.81-1.0
  for the same mis-specification in Gamma/beta/lognormal, which lack a
  matching absorbing structure). Detecting an absorbed mis-specification is a
  mean-structure diagnostic's job, not this one's. Zero-inflation/hurdle/
  zero-one-inflation *mechanism* mis-specification (a constant inflation
  probability fit when it truly varies with a covariate) splits into two
  patterns under the n-ladder (tested to n = 3000): for `hurdle_nbinom2`/
  `zero_one_beta` power stays flat at or below about 0.01 at every n -- a
  genuine structural blind spot; for `zi_nbinom2`/`zi_poisson` power rises
  with n (to about 0.11/0.06 at n = 3000), so the marginal is not identical
  under the mechanism mis-spec, but power stays far below the >= 0.8
  detectable benchmark even at n = 3000, so it remains impractical to detect
  at realistic sample sizes. Neither pattern should be relied on as an
  adequacy check for the mechanism.
  `gamma`-vs-`lognormal` wrong-family detection is sample-size limited rather
  than structurally blind: power rises from about 0.19 at n = 300 to 0.79 at
  n = 1000 and 1.0 at n = 3000, so this specific mis-specification needs n
  well above 1000 to be reliably caught.
* Honest-scope invariants apply throughout: intervals are labelled
  `calibrated = FALSE`; a pass is worded "no detectable departure", never
  "adequate" or "the model is correct"; and a distributional-output/adequacy
  (DG) tick on a family never changes or implies anything about that family's
  own inference-tier status (e.g. skew-normal's `diagnostic_hold` fit-quality
  status is unaffected by its DG2/DG3 promotion) -- see
  `tests/testthat/test-dg-firewall.R`.
* This is fixed-effect adequacy only: for random-effect or structured fits,
  quantile residuals are conditional on the fixed-effect prediction, not
  marginal, so a departure (or its absence) is evidence about fixed-effect
  adequacy only. Calibrated coverage (DG4/DG5), uncertainty beyond
  `theta_hat`, random-effect/structured residual adequacy, and bivariate
  joint (non-marginal) outputs remain separately authorized future work.

## Missing responses: MR-T7 certification

* The generated capability ledger and live runtime oracle now reconcile all 18
  fitted response routes at G3 recovery-verified, with zero G0 routes. The
  capability page, missing-data article, design inventory, NEWS, roadmap, and
  machine-readable evidence are regenerated from the same route state. This
  closeout adds no family, formula grammar, estimator, interval, or coverage
  claim: each tick remains bounded to its documented fixed, random, or
  structured route, and G4/G5 remain separate future evidence tiers.

## Missing responses: MR-T6 count mixtures

* `response = "include"` now masks fixed-effect zero-inflated Poisson,
  zero-inflated NB2, and hurdle NB2 responses. Each route guards its complete
  zero-or-positive mixture contribution before response classification, uses
  observed-only starts, and has separate missing-zero and missing-positive
  parity tests. Zero-versus-positive sentinel retapes, row/extractor contracts,
  and exact fixed-seed 25% MCAR recovery promote all three routes to G3. All 18
  fitted response routes are now G3 recovery-verified for their documented
  masking slice; random/structured mixture routes, response plus `mi()`, REML,
  intervals, and coverage remain outside this arc.

## Missing responses: MR-T5 truncated counts

* `response = "include"` now masks positive-count responses for the non-hurdle
  `truncated_nbinom2()` route. The complete NB2 density and zero-truncation
  normalization are skipped together for masked rows; positive sentinels,
  observed-only starts, row/extractor contracts, and exact fixed-seed 25% MCAR
  recovery promote the ordinary `mu` random-intercept route to G3. Hurdle,
  `sigma`-random, structured, response-plus-`mi()`, interval, and coverage
  claims remain outside this tranche.

## Missing responses: MR-T4 encoded responses

* `response = "include"` now masks beta-binomial and cumulative-logit
  responses. A missing success or failure count masks the entire beta-binomial
  row, including its derived trials; ordered-factor levels remain declared and
  any observed subset with an empty category rejects before cutpoints are
  built. Coordinated encoded-sentinel retapes, row/extractor contracts, and
  exact fixed-seed 25% MCAR recovery promote both routes to G3. Integer ordinal
  masking, broader random/structured routes, response plus `mi()`, intervals,
  and coverage remain outside this tranche.

## Missing responses: MR-T3 atom and boundary families

* `response = "include"` now masks missing Tweedie and zero-one beta
  responses. Tweedie tests retape masked rows as a zero atom and a positive
  continuous value; zero-one beta tests zero and one atoms against an interior
  value. Observed-only starts, full mixture guards, row/extractor contracts,
  and exact fixed-seed 25% MCAR recovery promote both fixed-effect routes to
  G3. Random effects, structured effects, response plus `mi()`, intervals, and
  coverage remain outside this tranche.

## Missing responses: MR-T2 continuous families

* `response = "include"` now masks missing Student-t, skew-normal, lognormal,
  and Gamma responses. Plain data-time likelihood guards prevent masked values
  from reaching density or positive-support transformations; observed-only
  starts, direct sentinel invariance, row/extractor contracts, and fixed-seed
  25% MCAR recovery promote all four routes to G3. Student-t, lognormal, and
  Gamma are verified through their ordinary random-intercept routes;
  skew-normal remains fixed-effect only. This does not promote structured
  effects, intervals, or coverage.

## Missing responses: MR-T1 verification

* The six previously admitted `response = "include"` routes—univariate and
  bivariate Gaussian, binomial, Poisson, NB2, and beta—now share direct
  retaped-sentinel tests, original-row and extractor contracts, and fixed-seed
  25% MCAR recovery tests. Univariate residuals are `NA` on masked response
  rows while fitted values retain the original row length. These tests promote
  the six routes to the capability ledger's G3 recovery-verified tier; they do
  not claim interval calibration or coverage.

# drmTMB 0.5.0

`drmTMB` 0.5.0 is the **first CRAN release** (not 1.0). The honest version number
reflects that much of the family and inference surface is still scaffolded or
recovery-grade. Throughout the dev-log and the "Q-Series v1.0" ledger, **"v1.0"
is reserved for the later maturity milestone** that 0.5.0 deliberately does not
yet claim. This entry accumulates the 0.4.x development cycle (docs/ledger
alignment, non-Gaussian coverage validation, the missing-data non-Gaussian arc)
into the release; earlier tagged development lines appear below.

## Missing data: non-Gaussian responses and predictors

The likelihood-based missing-data layer now extends beyond Gaussian responses.
Both modes are validated per family against single sources of truth
(`drm_missing_response_families()`, `drm_missing_predictor_families()`), and an
anti-drift test asserts that every family outside those allow-lists still rejects
loudly, so an unsupported request never silently degrades to a wrong likelihood.
See `vignette("missing-data")` for the full capability matrix.

* **Missing-response masking (FIML) for non-Gaussian responses.** `missing =
  miss_control(response = "include")` now marginalises missing responses out of
  the joint likelihood for `binomial()`, `poisson()`, `nbinom2()`, and `beta()`
  fits, in addition to the existing univariate and bivariate Gaussian routes.
  Masked rows keep their complete predictors and row identity but contribute no
  response density (a plain data guard in the TMB kernel, so the placeholder is
  never taped). Valid under ignorable (MCAR/MAR) missingness.

* **Missing-predictor `mi()` for non-Gaussian responses.** `missing =
  miss_control(predictor = "model")` with an `impute` model now supports one
  binary (Bernoulli/logit) missing predictor on `binomial()`, `nbinom2()`, and
  `beta()` responses, joining the existing Poisson route. The missing predictor
  is marginalised by an exact 2-point sum inside the same joint likelihood, with
  the response density carrying its family dispersion (`nbinom2()`
  `size = exp(-2*log_sigma)`; `beta()` `phi = exp(-2*log_sigma)`). Point-fit
  recovery of the mean, dispersion, and predictor-model coefficients is tested at
  scale for each family.

* **Pluggable response-density leaf.** The `mi()` quadrature now routes each
  family's response density through one shared kernel
  (`drm_response_log_density`), so a non-Gaussian response reuses the same
  integration loop. The Gaussian extraction was a byte-identical refactor
  (verified by golden capture on the log-likelihood, gradient, and objective),
  and the per-family leaves replicate their inline densities exactly, including
  the `beta()` boundary nudge and shape floor.

## Bug fixes

* Structured `sigma` random effects for `family = nbinom2()`
  (`sigma ~ phylo()`/`spatial()`/`animal()`/`relmat()`) now correctly modify the
  scale predictor. They were previously applied to the *mean* predictor (the TMB
  kernel's `model_type == 7` branch lacked the scale-side dispatch the beta
  family already had), so a `sigma ~ phylo(...)` fit silently matched a
  mean-phylo fit while reporting a `*_sigma` SD. Point-fit recovery is now
  verified (`tests/testthat/test-nbinom2-sigma-structured-recovery.R`); intervals
  and coverage remain out of scope (recovery-grade).

## Coverage validation

* A simulation coverage campaign (400 seeds, n-ladder 50–800; see
  `docs/dev-log/simulation-artifacts/2026-07-09-nongaussian-unstructured-coverage-pilot/`)
  confirms that unstructured (fixed-effect) non-Gaussian confidence intervals are
  calibrated. The mean coefficients of `binomial()`, `poisson()`, `beta()`, and
  `nbinom2()` — including rare-event and low-count stress — and the location-scale
  `sigma` coefficients of `nbinom2()` all show finite-rate ≈ 1.0 and near-nominal
  Wald coverage. `beta()` location-scale intervals are calibrated for interior
  proportions; exact 0/1 observations require `zero_one_beta()`.

## Documentation and release-ledger alignment

* `README.md`, `ROADMAP.md`, and `docs/dev-log/known-limitations.md` now state
  the exact REML structured-effect boundary shipped across 0.2.0/0.3.0:
  univariate Gaussian REML accepts phylogenetic mean-side, scale-side, and
  matched q2 mean-and-scale blocks, plus univariate spatial/animal/relmat
  scale-side blocks. Arc 1a additionally admits the exact pure-`mu`
  spatial/animal/relmat intercept and independent one-slope cells over the
  documented discrete domains; other non-phylogenetic mean-side or mixed
  mean+scale structured effects, sparse-fixed designs, Gaussian row
  aggregation, and ordinary direct-SD formulae remain rejected. Bivariate Gaussian REML
  accepts phylogenetic structured effects in every covariance layout,
  including the dense q4 block, and rejects spatial/animal/relmat entirely.
  REML remains rejected outright for every non-Gaussian family.
* `ROADMAP.md` corrects the Q-Series `inference_ready` anchor count from five
  rows to eight, adding the three q1 `mu:(Intercept)` anchors (phylo,
  spatial, relmat) that the release ledger already carried but the roadmap
  text had not listed. Two of the eight rows -- the phylo and relmat q2
  `mu1:x`/`mu2:x` slope-SD rows -- are `inference_ready` only through the
  bias-corrected `confint()` channel; their raw uncorrected Wald intervals
  fail coverage. No structured row is `supported`, and non-Gaussian
  structured rows remain point-recovery evidence only, with no intervals,
  coverage, or `supported` claim.
* `docs/dev-log/known-limitations.md` records that `nbinom2()` structured
  `sigma` terms (`phylo`/`spatial`/`animal`/`relmat`) now correctly target the
  scale predictor `log_sigma` (the routing fix announced under *Bug fixes*
  above); earlier versions mis-targeted the mean predictor. These four rows are
  recovery-grade only -- point-fit recovery is verified, but intervals and
  coverage remain out of scope.

## Inference guidance

* **Historical note, superseded by the cell-specific 0.6.0 guidance above.**
  This release originally described profile likelihood as the headline method
  for structured covariance targets. The retained evidence does not support
  that blanket recommendation: q1 `mu` and the exact phylo/relmat slope-only
  q2 `mu1:x`/`mu2:x` SD rows use the default location-axis bias-corrected,
  small-sample-t Wald channel; q1 `sigma` uses raw uncorrected log-SD Wald-z
  evidence and its profile channel is diagnostic-only at `g = 8`; Arc 1a REML
  uses direct structured-SD profiles only over its tested discrete domains. A
  target appearing in
  `profile_targets()` means that it can be computed, not that its profile
  interval is validated for reporting.

# drmTMB 0.3.0

## Large direct-SD models: uncertainty no longer scales with the square of the group count

Reported by Ayumi Mizuno on a 10,440-tip bivariate phylogenetic fit, where
`TMB::sdreport()` exhausted 48 GB of memory.

* **Breaking (default change).** A direct-SD surface (`sd(group, level =
  "phylogenetic") ~ .`, formerly `sd_phylo()`) previously `ADREPORT`ed one
  standard deviation *per group*, so the joint `ADREPORT` covariance was
  `n_group x n_group`. Under `REML = TRUE` the fixed effects are integrated into
  the Laplace `random` block and `vcov()` reads exactly that covariance, so a
  bivariate fit at ten thousand tips needed roughly 14 GB for it alone. Those
  per-group standard errors are now **opt-in** via
  `drm_control(se_group_sd = TRUE)`. The fitted per-group standard deviations
  themselves are unchanged and always available. Parameter standard errors,
  `vcov()`, `summary()`, and `pdHess` now work under REML at that scale.

* New `drm_control(se_report_covariance = )` and
  `drm_control(se_skip_delta_method = )` pass through to the `getReportCovariance`
  and `skip.delta.method` arguments of `TMB::sdreport()`, for further control over
  the cost of uncertainty on large models.

* `REML = TRUE` no longer rejects an explicitly-passed `missing =` control when
  the data contain no missing values. The gate tested the *setting* rather than
  whether the missing-data engine actually engages, and
  `miss_control(response = "include")` is an exact no-op on complete-case data.
  REML combined with a missing-data engine that genuinely engages is still
  rejected, as that combination remains unvalidated.

* `sigma ~ z + (1 + x | p | id)` again reports the specific "labelled
  residual-scale random-slope covariance blocks are not implemented yet" error
  rather than a generic shape error. The behaviour (rejection) is unchanged.

## Unified `sd(..., level = )` scale grammar

* **`sd(group, level = "phylogenetic")` is the new generic spelling** for the
  phylogenetic direct-SD targets (`sd1(...)` / `sd2(...)` for the bivariate
  endpoints). The legacy `sd_phylo()` / `sd_phylo1()` / `sd_phylo2()` spellings are
  soft-deprecated: they keep working and emit a one-time deprecation warning.
  Reserved `level` values (`"spatial"`, `"animal"`, `"relmat"`) are parsed but not
  yet implemented.

## More REML coverage (Gaussian location-scale)

Restricted maximum likelihood now covers substantially more of the location-scale
family, debiasing scale-side variance components with adequate within-group
replication. Every combination admitted under REML is also admitted under ML
(`docs/dev-log/ml-reml-coverage-2026-07-07.md`).

* **Matched mean-and-scale phylogenetic block (q2) under REML.** A univariate
  `mu` + `sigma` model with a correlated `phylo(1 | p | id)` block is now admitted; a
  sample-size ladder shows REML is less biased than ML (N >= 250 to identify,
  N >= 1000 for the location-scale correlation). This supersedes the earlier small-`N`
  "REML degrades the mean" verdict.

* **Block-diagonal bivariate location-scale phylogenetic layout under REML.** A phylo
  mean block and a phylo scale block with distinct labels (`1 | p | id` on the means,
  `1 | ps | id` on the scales) are admitted; the scale-side random phylo is
  identifiable with per-group replication (it collapses at one observation per
  species, where a fixed `sd_phylo()` scale should be used instead). At this
  intermediate point the dense block stayed rejected; the later dense-q4 entry
  below supersedes that state with recovery evidence at adequate information.

* **Ordinary sigma random effects under REML.** A residual-scale random intercept
  `(1 | id)`, an independent random slope `(0 + x | id)`, the correlated mean-scale
  block `(1 | p | id)`, and a bivariate labelled scale-side block `(1 | s | id)` are
  now admitted; REML debiases the scale-side variance component with adequate
  within-group replication (at very low replication it can underperform ML).

* **Dense (unstructured) q4 phylogenetic location-scale block under REML.** The
  previous "sign-flip" verdict is superseded: the DGP-to-endpoint mapping is correct
  (a single nonzero simulated correlation lands on the right pair with the right
  sign), and the apparent flip was an under-powered fit whose variance component
  collapsed. With adequate information (roughly `n_tip >= 200` and per-species
  replication `n_each >= 10`) the dense q4 converges and recovers, and REML is
  *strictly better* than ML there -- higher convergence/`pdHess` rate and variance
  components debiased toward truth. At one observation per species it still collapses;
  use the block-diagonal layout or a fixed `sd(level = "phylogenetic")` scale.

* **Bivariate mean-scale random-effect correlations and `q > 2` labelled location
  covariance blocks under REML.** Both are now admitted; REML is consistently less
  biased than ML on the block standard deviations. **ML/REML parity is now complete
  for every implemented cell** (`docs/dev-log/ml-reml-coverage-2026-07-07.md`).

* **Scale-side spatial / animal / relatedness structured effects under REML.**
  `sigma ~ spatial(...)`, `sigma ~ animal(...)`, and `sigma ~ relmat(...)` now fit
  under `REML = TRUE`. A recovery + coverage campaign shows REML debiases the
  scale-side intercept standard deviation in every cell (bias approaching zero as the
  group count grows) and profile-CI coverage clears the small-sample floor. Mean-side
  non-phylogenetic structured effects under REML were unvalidated and rejected at
  the time of this entry. **Superseded in 0.6.0:** the Arc 1a spatial, animal, and
  `relmat()` unlabelled mean-intercept and independent intercept-plus-one-numeric-
  slope REML cells are now admitted only over their recorded discrete recovery
  domains; slope-only, labelled, multiple-slope, q > 1, simultaneous-provider,
  and adjacent structured cells remain rejected.

* **Degrees of freedom under REML now count the marginalised scale fixed effects.**
  A scale-side REML fit marginalises `beta_sigma` as well as `beta_mu`; `logLik()`'s
  `df` (and therefore `AIC()` / `BIC()`) now counts both, matching the ML parameter
  count. Fits without a sigma variance component are unchanged.

## New: `check_drm()` diagnostics for weak identification and direct-SD surfaces

* `phylo_mu_diagnostics` no longer reports a false `error` for a fitted
  `sd(group, level = "phylogenetic") ~ .` surface (which has no scalar phylogenetic
  standard deviation). It now summarises the fitted per-group SD surface and errors
  only on genuinely non-finite or non-positive fitted standard deviations.

* New `standard_errors_inflated` check flags a finite-but-inflated Wald standard error
  on a converged, positive-definite-Hessian fit -- the signature of a weakly identified,
  near-flat direction such as a boundary correlation. The bivariate phylogenetic
  mean-mean boundary warning now names the same symptom in words. A clean `pdHess` is
  necessary, not sufficient.

* New "Choosing between maximum likelihood and REML" guidance in the *Improving
  convergence* article: ML is the default; REML's `p / n` correction to variance
  components matters mainly at small group counts, and it leaves the mean coefficients
  essentially unchanged.

## New: correlated residual-scale random slopes

* **`sigma ~ x + (1 + x | id)` -- a correlated residual-scale intercept-slope block --
  is now implemented** (and the multi-slope `(1 + x1 + x2 | id)` generalisation).
  Previously only *independent* residual-scale slopes (`(0 + x | id)`) were supported.
  The univariate TMB likelihood now applies the same-dpar correlation conditioning to
  the `sigma` random effects, mirroring the `mu` side. Recovery of the intercept SD,
  slope SD, and their correlation is validated against known truth.

* Consequently **the ordinary two-level DHGLM with correlated random slopes on BOTH the
  location and the scale** -- `y ~ x + (1 + x | id)` with `sigma ~ x + (1 + x | id)` --
  now fits, under ML and REML. The remaining piece of the full q12 is the *labelled*
  cross-formula `mu`-`sigma` **slope** block (the mean-scale slope cross-correlation),
  which is still planned.

# drmTMB 0.2.0

## REML for Gaussian and bivariate-Gaussian location-scale models

Restricted maximum likelihood (`REML = TRUE`) now covers more of the phylogenetic
location-scale model family, debiasing the variance components and giving
better-conditioned, honest scale-side standard errors. Validated by exact
restricted-likelihood references and known-truth recovery ladders
(`docs/design/221-native-reml-finish.md`); the native REML test suite is green.

* **Bivariate Gaussian REML with phylogenetic / random location effects.**
  `drmTMB(..., REML = TRUE)` now fits `biv_gaussian()` models whose means carry
  correlated `phylo()` (or ordinary) random effects (the "correlate the means" model),
  matching an exact bivariate restricted-likelihood reference. A sample-size recovery
  ladder shows REML is less downward-biased than ML on the variance components at every
  sample size, and its standard errors track ML's. At the time of this 0.2.0 entry,
  scale-side random effects, matched mean-and-scale phylogenetic effects, and `q > 2`
  labelled covariance blocks remained rejected. Later 0.3.0/current entries supersede
  that boundary with row-specific point-fit or recovery evidence.

* **Phylogenetic direct-SD scale (`sd_phylo(...) ~ predictors`) under REML.** The
  heteroscedastic phylogenetic-variance model -- a predictor (e.g. climate) on the
  phylogenetic SD -- is now admitted under REML for univariate and bivariate Gaussian
  models, matching an exact restricted-likelihood reference. This is the scale side of
  the corrected ecogeographic location-scale model.

* **Correct REML standard errors for direct-SD coefficients.** `vcov()` and `summary()`
  previously returned `NA` standard errors for the `sd_phylo` coefficients under REML
  (they are absent from the sdreport ADREPORT joint covariance); they now fall back to
  the fixed-parameter covariance and report finite Wald standard errors.

Native phylogenetic location-scale fits with debiased variance components reduce the
need for an external Bayesian comparator (e.g. MCMCglmm) for this workflow.

# drmTMB 0.1.4

Current development claims in this NEWS section follow the finish-plan claim
registry in `docs/design/168-r-julia-finish-capability-matrix.md`; fitted,
planned, unsupported, and release-gate language should not be read more broadly
than that matrix.

* `drmTMB()` now fits three non-count family structured `mu` **one-slope** cells
  as native point-fit/extractor recovery-only routes: `Gamma()` with
  `relmat(1 + x | id, K = K)`, `student()` with
  `spatial(1 + x | id, coords = coords)`, and `beta()` with
  `animal(1 + x | id, pedigree = ped)`. Each extends the existing structured
  intercept gate to an unlabelled intercept-plus-one-slope term with no
  compiled-code change. On a crossed `n_lvl in {10,20,30}` x 30-seed ladder, a
  null-slope separability control, and a non-identity AR(1) relatedness check,
  both variance components recover with RMSE falling as levels increase (Gamma and
  beta 90/90 converged with positive-definite Hessian; Student-t 83/90, so use
  `n_levels >= 20`). This is recovery-only: labelled or multiple structured
  slopes, scale/shape/zero-inflation structured slopes, other families, intervals,
  coverage, `inference_ready`, `supported`, REML, AI-REML, and bridge support
  remain planned.

* Simultaneous **two-provider** structured count `mu` is now admitted at
  point-fit/recovery for NB2: `nbinom2()` with
  `spatial(1 | site, coords = coords) + relmat(1 | id, Q = Q)` on a crossed
  `site x id` design now builds and surfaces both structured fields
  (`ranef()` shows `spatial_mu` and `relmat_mu`; both SDs are direct
  `log_sd_phylo`/`log_sd_phylo2` profile targets). On the crossed ladder both
  fixed-covariance variance components recover with a positive-definite Hessian,
  and a non-crossed control shows the separability requirement (site and id must
  vary independently). This is recovery evidence only — it does not authorize
  interval reliability, coverage, `inference_ready`, STAN cross-check, REML,
  AI-REML, bridge parity, or `supported`. Joint identifiability rests on the
  crossed design.

* Structured **q12** two-slope all-four covariance is now admitted at
  point-fit/recovery for `phylo()`, `spatial()`, `animal()`, and `relmat()`:
  `(1 + x + z | p | id)` on `mu1`/`mu2`/`sigma1`/`sigma2` builds a twelve-endpoint
  (66-correlation) among-trait covariance that recovers a known covariance at
  adequate sample size. `pdHess=FALSE` is expected here (the 66-correlation block
  is weakly identified) and is not failure: the twelve SDs are direct profile
  targets and the 66 correlations route through profile/bootstrap (ELR excluded).
  This is recovery evidence only — it does not authorize interval reliability,
  coverage, STAN cross-check, REML, AI-REML, bridge parity, or `supported`. With
  this admission every Gaussian structured-random-effect row now holds a v1.0
  basic-working-or-better row-accounting role; the remaining rows outside that
  practical surface are non-Gaussian.

* Structured **q6** two-slope location covariance is now admitted at
  point-fit/recovery for `phylo()`, `spatial()`, `animal()`, and `relmat()`:
  `bf(mu1 = y1 ~ x + z + phylo(1 + x + z | p | id, tree = tree), mu2 = ...,
  sigma1 = ~1, sigma2 = ~1, rho12 = ~1)` builds a six-endpoint (15-correlation)
  among-trait covariance that recovers a known covariance with a positive-definite
  Hessian at adequate sample size. This is recovery evidence only: the six SDs are
  direct profile targets and the fifteen correlations are derived (no Wald
  interval), so it does not authorize interval reliability, coverage, STAN
  cross-check, REML, AI-REML, bridge parity, the structured q8 rows, or
  `supported` wording.

* The Q-Series v1.0 release status is now generated from the 104-row support-cell
  board and recorded in `docs/dev-log/release-audits/q-series-v1-release-status.md`.
  It separates implemented/basic-working Gaussian structured-effect rows, 27 non-Gaussian
  recovery rows, and 10 non-Gaussian diagnostic-only rows from post-v1.0
  `inference_ready` and
  `supported` validation. This is release-planning evidence only; it does not
  authorize coverage, q4/q8 promotion, broad bridge support, REML, AI-REML, or
  public-support wording.

* The Q-Series v1.0 practical surface now includes ten row-specific
  diagnostic-only gates outside the ordinary `mu` lanes: Student-t intercept-only
  `mu ~ spatial(1 | id, coords = coords)`, Student-t `nu ~ phylo(1 | id, tree = tree)`,
  cumulative-logit ordinal `mu ~ phylo(1 | id, tree = tree)`, truncated-NB2 hurdle
  `hu ~ relmat(1 | id, Q = Q)`, zero-inflated Poisson
  `zi ~ spatial(1 | id, coords = coords)`, zero-inflated Poisson fixed-`zi`
  `mu ~ spatial(1 | id, coords = coords)`, zero-inflated NB2 fixed-`zi`
  `mu ~ spatial(1 | id, coords = coords)`, Poisson slope-only
  `mu ~ spatial(0 + x | site, coords = coords)`, Poisson labelled-scalar
  `mu ~ spatial(1 | p | site, coords = coords)`, and Poisson
  `mu ~ spatial(1 | site, coords = coords) + (1 | id)`. These rows establish
  fit/extractor feasibility but not point-estimate recovery and are not interval,
  coverage, `inference_ready`, `supported`, bridge, REML, AI-REML, broad
  shape/inflation/ordinal/structured non-Gaussian support evidence, or
  neighbouring-row evidence.

* `truncated_nbinom2()` hurdle models now fit the row-specific Q-Series v1.0
  `hu ~ relmat(1 | id, Q = Q)` local gate. The fitted relatedness-field SD for
  the hurdle probability is exposed through `sdpars$hu` and
  `ranef("relmat_hu")`. This is local fit-only/extractor evidence; hurdle
  slopes, labelled covariance, broader hurdle structured effects, intervals,
  coverage, `inference_ready`, `supported`, REML, AI-REML, and bridge support
  remain closed.

* `cumulative_logit()` now fits the row-specific Q-Series v1.0 ordinal
  phylogenetic `mu` intercept gate, for formulas such as
  `bf(score ~ x + phylo(1 | species, tree = tree))`. The fitted phylogenetic
  ordinal location SD is exposed through `sdpars$mu`, `ranef("phylo_mu")`, and
  a direct `profile_targets()` row. This is local fit-only/extractor evidence;
  ordinal slopes, scale/discrimination formulas, bivariate ordinal models,
  intervals, coverage, `inference_ready`, and `supported` status remain
  planned.

* `nbinom2()` now fits the row-specific Q-Series v1.0 zero-inflated NB2
  fixed-`zi` spatial `mu` intercept gate, for formulas such as
  `bf(count ~ x + spatial(1 | site, coords = coords), sigma ~ 1, zi ~ 1)`.
  The fitted spatial `mu` SD is exposed through `sdpars$mu`,
  `ranef("spatial_mu")`, and a direct `profile_targets()` row. This is local
  fit-only/extractor evidence; zero-inflated NB2 structured slopes, labels,
  simultaneous providers, structured `zi`, structured `sigma`, intervals,
  coverage, `inference_ready`, `supported`, REML, AI-REML, and bridge support
  remain closed.

* `confint()` now applies the small-sample t(g - 1) width plus the simulation-calibrated `log(g/(g - 1))` centre shift by default for location-axis structured random-effect SD targets. This moves only the phylo and relmat bivariate q2 `mu1:x`/`mu2:x` slope SD cells to `inference_ready` for interval and coverage status; `supported` remains withheld because the engine grids still measure right-tail miss asymmetry and g-dependence. Spatial q2, animal q2, q4/q8, count, and non-Gaussian structured rows remain separate future arcs.

* The exact Gaussian q1 sigma one-slope `phylo()`, `animal()`, and `relmat()` rows are now `inference_ready` under the raw uncorrected log-SD Wald-z interval channel. The Nibi top-up, banked SR475 slope grid, and local animal SR1000 reconciliation show 100% fit/pdHess pass rates, Wald finite rates at or above 0.953, and Wald MCSE at or below 0.01; the caveat is that one-sided misses are asymmetric and sigma slope SDs over-cover, so this is not `supported`. Profile intervals remain diagnostic-only at deployment g=8 for low-finite sigma targets, and the location-axis bias+t correction does not apply to sigma.

* `drmTMB()` now fits ordinary Poisson and NB2 structured `mu` one-slope count cells with unlabelled `phylo(1 + x | ...)`, fixed-covariance `spatial(1 + x | ...)`, `animal(1 + x | ...)`, and `relmat(1 + x | ...)` terms. These are native TMB ML/Laplace point-fit and extractor cells for non-zero-inflated count means only. Exact q1 NB2 structured `sigma` intercept-plus-one-slope routes for those four providers are separately fitted at recovery grade; pure or multiple structured count slopes, labelled count covariance, zero-inflated structured effects beyond the exact Poisson spatial `zi`, Poisson fixed-`zi` spatial `mu`, and NB2 fixed-`zi` spatial `mu` local-fit gates, richer or labelled NB2 structured `sigma`, q2/q4 count covariance, bridge support, REML, AI-REML, intervals, coverage, and public-support promotion remain planned or unsupported.

* `biv_gaussian()` now fits the first phylogenetic all-four one-slope structured block when the same labelled `phylo(1 + x | p | species, tree = tree)` term appears in `mu1`, `mu2`, `sigma1`, and `sigma2`. The fitted block exposes eight endpoint SDs and 28 derived latent phylogenetic correlations through `sdpars$mu`, `corpars$phylo`, `corpairs(level = "phylogenetic")`, `summary()$covariance`, `profile_targets()`, and `structured_effects()`. This is native ML point-fit/extractor evidence plus deterministic same-target fixture parity for the exact shared-label phylo cell only; block-diagonal layouts, broad bridge support beyond the fixture, intervals, coverage, REML, AI-REML, and public-support promotion remain planned.

* `biv_gaussian()` now also fits the first fixed-covariance spatial all-four one-slope structured block when the same labelled `spatial(1 + x | p | site, coords = coords)` term appears in `mu1`, `mu2`, `sigma1`, and `sigma2`. The fitted block exposes the same eight endpoint SDs and 28 derived latent spatial correlations through the standard covariance extractors. This is native ML point-fit/extractor evidence plus deterministic same-target fixture parity for the exact fixed-covariance spatial cell only; range-estimating spatial support, block-diagonal layouts, broad bridge support beyond the fixture, intervals, coverage, REML, AI-REML, and public-support promotion remain planned.

* `biv_gaussian()` now fits the corresponding exact A-matrix animal and K/Q lower-level relatedness all-four one-slope blocks when the same labelled `animal(1 + x | p | id, A = A)` or `relmat(1 + x | p | id, K/Q = ...)` term appears in `mu1`, `mu2`, `sigma1`, and `sigma2`. These cells expose eight endpoint SDs and 28 derived latent animal or relatedness correlations through the standard covariance extractors. This is native ML point-fit/extractor evidence plus deterministic same-target fixture parity for the exact A-matrix animal and K-matrix relmat cells only; pedigree/Ainv bridge marshalling, relmat Q bridge marshalling, block-diagonal layouts, broad bridge support beyond the fixture, intervals, coverage, REML, AI-REML, and public-support promotion remain planned.

* The residual `rho12` correlation now uses the same `0.999999` (six-nines) `tanh` guard as every other latent correlation in the package, instead of an inconsistent `0.99999999` (eight-nines) bound (flagged in review). The guard is far from any realistic correlation, so fitted `rho12` values are unchanged to about seven decimal places; this is a numerical-consistency fix, not a behaviour change for interior fits.

* `drm_phylo_penalty_sweep()` runs a penalized (MAP) phylogenetic fit across a range of `cor_sd` correlation-penalty values and returns a tidy sensitivity summary (`convergence`, `pdHess`, `logLik` per `cor_sd`) plus the fitted objects for extracting the couplings. This turns the mandatory prior-sensitivity sweep -- the check of whether a weakly identified coupling is data-informed (stable across `cor_sd`) or prior-shaped (tracks `cor_sd`) -- into a single call; there is no universal `cor_sd`. (`drm_phylo_penalty()` and the new sweep are now both in the pkgdown reference.)

* `check_drm()` now reports a `logsigma_clamp_active` row that flags when the `log(sigma)` clamp is active at the optimum -- the diagnostic-surface complement to the fit-time clamp-active warning -- so a clamp-bound fit is visible in the standard diagnostic table (a `note` when the TMB object was dropped, an `ok` otherwise).
* `check_drm()` now warns when q2 random-effect covariance correlations are close to `+/-1`, including univariate `mu`/`sigma` covariance and bivariate q2 `mu`/`mu`, `sigma`/`sigma`, and same-response `mu`/`sigma` covariance rows. The diagnostic prints the fitted `rho_abs` and `rho_boundary` so a converged, positive-Hessian fit at the correlation guard is visible rather than silently labelled `ok`.
* `check_drm()` now reports fitted-boundary diagnostics for bivariate coordinate-spatial, `animal()`, and `relmat()` q2 location covariance rows (`biv_spatial_q2_covariance`, `biv_animal_q2_covariance`, and `biv_relmat_q2_covariance`). This changes diagnostic visibility only; it does not change fitting behaviour or promote structured q2 recovery, interval, or power claims.
* `biv_gaussian()` now fits the first structured slope-only q=2 `mu1`/`mu2` covariance cells for `phylo(0 + x | p | species, tree = tree)`, fixed-covariance `spatial(0 + x | p | site, coords = coords)`, `animal(0 + x | p | id, A/Ainv = ...)`, and `relmat(0 + x | p | id, K/Q = ...)`. The fitted SDs and `cor(mu1:x,mu2:x | p | group)` row are coefficient-aware in `sdpars$mu`, `corpars`, `corpairs()`, `summary()$covariance`, `profile_targets()`, and `structured_effects()`. This is native point-fit/extractor evidence plus deterministic same-target fixture parity for the exact slope-only q2 cells; it does not by itself promote separate intercept-plus-slope structured q4/q8 covariance cells, broad bridge support, interval reliability, coverage, REML, or AI-REML.
* `drmTMB()` now rejects combining `REML = TRUE` with `penalty =` (a penalized / MAP fit): a restricted-likelihood estimator and a maximum-a-posteriori estimator are different estimators of the variance components, so the combination is undefined.
* The Student-t `nu` documentation now states explicitly that the `nu > 2` (finite-variance) bound, required by the `sigma = SD` contract, means the family cannot represent the very heavy tails of `nu <= 2` (e.g. Cauchy); `check_drm()` warns as `nu` approaches the boundary.

* `drmTMB(..., REML = TRUE)` now fits **bivariate Gaussian fixed-effect location** models (`mu1`/`mu2`), marginalising both mean blocks (`beta_mu1`, `beta_mu2`) for an unbiased residual covariance. Validated against an exact restricted-likelihood reference (the OLS-residual covariance with the `n - p` correction): `sigma1`, `sigma2`, `rho12`, and both mean-coefficient blocks match, and the degrees of freedom count both marginalised blocks. At the time of this entry, bivariate random-effect and structured (`phylo`) means under REML were a later slice and rejected; later 0.2.0/0.3.0 entries supersede that boundary with row-specific q2/q4 evidence.

* REML now supports a fixed-effect heteroscedastic residual (`sigma ~ predictors`), not just an intercept-only `sigma`. REML restricts the likelihood for the mean fixed effects regardless of the scale model, so a Gaussian with residual variance `V = diag(sigma_i^2) + random-effect covariance` has an exact restricted likelihood; drmTMB's REML estimates match a hand-computed restricted-likelihood reference (random-effect SD, the `sigma` coefficients, and the mean coefficients), and the degrees of freedom count the marginalised mean fixed effects. At the time of this entry, scale-side random effects under REML remained rejected; later 0.3.0/current rows supersede that boundary with exact point-fit or recovery admissions.

* `drmTMB(..., REML = TRUE)` now fits **mean-side phylogenetic** location models -- a `phylo()` term on `mu` with an intercept-only `sigma` -- extending REML beyond the ordinary-random-effect slice. REML restricts the likelihood for the mean fixed effects (TMB marginalises `beta_mu` through its exact Gaussian Laplace step), giving a less downward-biased phylogenetic variance component. Estimates match a hand-computed restricted Gaussian likelihood (phylogenetic SD, residual `sigma`, and the mean coefficients). At the time of this historical entry, scale-side structured effects and non-phylogenetic structured effects (spatial, animal, relatedness) under REML remained rejected. **Superseded in 0.6.0:** the later scale-side work and Arc 1a admit only the exact tested cells and discrete domains named in the current capability guide; neighbouring slopes, q > 1 blocks, simultaneous providers, and untested cells remain rejected.

* `drm_control(fallback_optimizer = )` adds an opt-in fallback optimizer (an [stats::optim()] method such as `"BFGS"`) that is tried as a final attempt when no `nlminb()` preset converges. A different algorithm sometimes succeeds on a numerically awkward but identified problem. It is off by default (`NULL`), so the default fit uses only the `nlminb()` preset ladder; when enabled, the fallback attempt is recorded in `fit$optimizer_attempts` like any preset.

* `drm_control(multi_start = K)` enables multi-start fitting: each optimizer preset is run from `K` starting points -- the principled start plus `K - 1` reproducibly perturbed starts -- and the lowest-objective result is kept. This helps weakly identified models escape poor local optima. It is opt-in: `multi_start = 1` (the default) is the single-start fit and is unchanged, and the perturbations use a fixed internal seed with the caller's random stream saved and restored, so fits stay reproducible.

* The optimizer now escalates its preset ladder (`default` -> `careful` -> `robust`) when a preset returns a **non-converged** result, not only when it throws an error. Previously `drmTMB()` accepted the first preset that did not error -- even a false convergence (`convergence != 0`) or a non-finite objective -- so the `careful` and `robust` presets were effectively unreachable for the very cases they exist for. Now a non-converged attempt is recorded and the next preset is tried; the first cleanly-converged attempt is returned, or the best (lowest-objective) attempt if none converge. A clean first attempt is unchanged (no escalation, no warning). The full ladder is recorded in `fit$optimizer_attempts`, and the fit-time convergence warning now points there instead of suggesting a manual `robust` refit (the ladder is tried automatically).

* The Gaussian `sigma`-slope starting values are more robust for strong scale-heterogeneity models. The start heuristic previously discarded *all* scale slopes whenever its log-absolute-residual regression looked too large, handing a legitimately steep `sigma ~ x` model a flat intercept-only starting point; it now shrinks an over-large slope start toward zero (direction preserved, magnitude bounded) instead. This only changes the optimizer's starting point, not the objective, so converged fits are unchanged; it gives the optimizer a better start on hard scale models. Moderate and intercept-only `sigma` starts are unaffected.
* `drmTMB()` now warns at fit time if the optimized objective is not finite (`NaN`/`Inf`), instead of storing a non-finite log-likelihood and returning a broken fit silently. TMB normally returns a finite objective, so this is a defensive guard (class `drmTMB_nonfinite_objective_warning`); when it fires, the fit never reached a usable optimum and its estimates and standard errors are meaningless.

* The `log(sigma)` overflow soft-clamp now guards **every** scale-bearing family, not just Gaussian. Student, skew-normal, lognormal, gamma, Tweedie, beta, zero-one-beta, beta-binomial, and the negative-binomial family (NB2, truncated, hurdle, zero-inflated), plus the Gaussian row-aggregation path, all route `log(sigma)` through the same `use_logsigma_clamp`-gated soft-clamp before exponentiation. The clamp is exactly the identity inside the band, so every in-band fit is bit-identical to the unclamped fit (verified per family); the only change is that a runaway scale becomes a finite, clamp-flagged fit instead of an overflow to `NaN`. Previously this guard existed only for the Gaussian likelihood, leaving the other families' dispersion parameters unprotected. The same configurable band (`drm_control(logsigma_clamp = )`) and the clamp-active warning apply across families.
* `drmTMB()` now warns at fit time when the `log(sigma)` soft-clamp is active at the optimum -- the fitted `log(sigma)` reached or passed the identity band, so the clamp bent the scale. Such a fit can converge artificially: the saturated tail is flat, so the gradient vanishes and the optimizer may report convergence even though the scale ran to the bound, leaving estimates and standard errors near the clamp unreliable. The warning (class `drmTMB_clamp_active_warning`) names the value reached and the band and recommends rescaling the response, widening the band with `drm_control(logsigma_clamp = )`, adding within-group replication, or a penalized/MAP fit. It covers every clamp-guarded scale family (the detector reads the main `log_sigma`/`log_sigma1`/`log_sigma2` scales, ignoring the unclamped missing-predictor imputation scales) and is filtered by the simulation harness, which tracks scale state separately. This closes the case where a clamp-bound fit returned looking fine under a false `convergence = 0`.
* `confint(method = "wald")` now flags a Wald interval that sits at a variance-component or correlation boundary instead of presenting it as an ordinary interval. When a random-effect or structured standard deviation is within `sd_boundary` of zero, or a correlation is within `rho_boundary` of `+/-1`, the row's `conf.status` becomes `"wald_at_boundary"` and a warning (class `drmTMB_wald_boundary_warning`) points to `method = "profile"`, because the symmetric Wald interval undercovers under boundary (chi-square-mixture) inference. The interval is still returned -- a boundary is a warning, not an auto-discard -- and a residual or distributional scale near zero is regular and is not flagged. The thresholds are exposed as `confint(..., sd_boundary = 1e-4, rho_boundary = 0.98)`, matching the `check_drm()` defaults.
* `AIC()` and `BIC()` now have `drmTMB` methods that warn when the criterion is not a valid comparison. A REML fit warns that its restricted likelihood is comparable only across models with identical fixed effects (never ML versus REML, or different mean structures); a penalized (MAP) fit warns that the criterion is not standard, because `logLik()` returns the unpenalized data log-likelihood and a penalized parameter does not contribute a full degree of freedom. Previously these calls dispatched to `stats::AIC.default`, which reads the log-likelihood value and ignores the estimator, silently returning a meaningless number. For a plain maximum-likelihood fit the value is unchanged and no warning is emitted; the warnings carry condition classes `drmTMB_ic_reml_warning` and `drmTMB_ic_map_warning`.
* `drmTMB()` now warns at fit time when the optimizer reports non-convergence, instead of returning a non-converged fit that looks fine. The warning surfaces the `nlminb` code and message (for example "false convergence (8)"), points to `check_drm()`, and suggests the `robust` optimizer preset; `print()` annotates a non-zero convergence code with "(not converged; see check_drm())" rather than showing a bare integer next to a clean-looking coefficient table. The warning carries condition class `drmTMB_convergence_warning` so callers that do their own convergence bookkeeping (the simulation harness, or user code) can muffle just this signal while still seeing every other warning. This does not change any estimate; it makes a weak fit visible at the point of fitting.
* `drm_control()` now exposes the Gaussian `log(sigma)` overflow guard as a configurable knob: `logsigma_clamp = c(lo, hi)` sets the identity-in-band soft-clamp band (default `c(-12, 12)`, unchanged) and `logsigma_clamp_margin` its saturation margin (default `3`, saturating to `[-15, 15]`). `logsigma_clamp = NULL` disables the guard. Widen the band for legitimately huge-variance unstandardized responses, or disable it to inspect the raw overflow on a near-degenerate per-group scale model. The default is bit-identical to the previous fixed guard; the band is a numerical guard only and does not change identifiability (#570).
* `drmTMB()` now accepts an optional `penalty = drm_phylo_penalty(sd_u, sd_alpha, cor_sd)` argument that switches a phylogenetic fit to a penalized / maximum-a-posteriori (MAP) estimator: a penalised-complexity prior on each phylogenetic SD and an optional mean-zero normal on the phylogenetic correlation. This regularizes a weakly-identified phylogenetic variance or correlation (for example a scale-side phylogenetic field at about one observation per tip, or a coupled location-scale correlation pinned near `+/-1`) so the fit returns a finite, positive-definite estimate instead of stalling at a boundary. Plain maximum likelihood stays the default and bit-identical when `penalty = NULL`; a penalized fit is labelled `estimator = "MAP"`, `logLik()` returns the unpenalized data log-likelihood (the penalty is stored in `fit$phylo_penalty`), and `check_drm()` adds a `penalized_map` note. The penalty does not manufacture identifiability: `cor_sd` has no universal value and must be chosen by a prior-sensitivity sweep, likelihood-ratio tests or AIC across penalized fits are not standard, and within-group replication remains the clean route to a fully identified coupled model. A known-truth coupled-q4 recovery simulation backs this -- the penalty rescues the model to a positive-definite fit (which also restores Wald, profile, and bootstrap intervals) and recovers strong correlations near the right prior while over-shrinking weak ones. The `Improving convergence` article gains a penalized/MAP section, and `docs/design/174-controls-and-convergence.md` records the control catalog, the generalization-via-controls principle, and the interval-method guidance (#570).
* `drmTMB()` now fits the first primary Bernoulli/binomial response slice with native TMB `family = stats::binomial(link = "logit")`. Supported responses are explicit 0/1 event indicators and `cbind(successes, failures)` count responses; the fixed-effect likelihood includes the binomial normalizing constant so `logLik()`, AIC, and BIC match `stats::glm()` on overlapping logit models. Use `beta_binomial()` when successes out of known trials need extra-binomial variation through `sigma`. Non-logit links, factor-response ordering, proportions plus `weights`, `weights = trials`, `sigma`, random effects, structured effects, bivariate or mixed responses, and non-phylogenetic `engine = "julia"` binomial fits remain unsupported for this first slice (#569).
* `confint(method = "bootstrap")` now attaches a lightweight `"bootstrap.diagnostics"` attribute to returned bootstrap interval tables, with one row per bootstrap refit and target. The diagnostics record refit convergence, target availability, finite draw use, seed/backend/worker provenance, and refit-control flags while leaving the visible interval table at the usual target grain. The Ayumi q4 developer harness writes the same ledger to `bootstrap-diagnostics.csv`; this is troubleshooting evidence for failed or partial bootstrap runs, not a coverage or 10k-workflow claim (#555).
* `confint()` now warns when a default Wald interval is requested for the skew-normal slant `nu`, recommending `method = "profile"` (or `method = "bootstrap"`) instead. An ADEMP pilot found the Wald slant interval over-rejects near `nu = 0` (24-40% false positives versus the nominal 5%) because the Azzalini information is near-singular at `alpha = 0`. A later fixed-effect guard grid kept tail-floor exposure and fixed-gradient diagnostics visible rather than treating finite likelihoods as interval evidence. The warning is scoped to skew-normal `nu` only; Wald intervals for other families, including Student-t `nu` (tail shape) and Tweedie `nu` (power), are unchanged.
* `confint(method = "profile")` now accepts `profile_endpoint_max_eval` for direct scalar endpoint profiles, giving long variance-component or correlation diagnostics an explicit endpoint-evaluation budget. When the budget is reached, `confint()` returns an endpoint `profile_failed` row with missing endpoints instead of silently falling through to a full-profile fallback. The Ayumi q4 developer harness can pass the same budget through `DRMTMB_AYUMI_Q4_PROFILE_ENDPOINT_MAX_EVAL` and now separates returned-fit status from convergence/Hessian inference status (#555).
* `confint(method = "profile")` now returns an explicit row-level `conf.status = "profile_failed"` with missing endpoints when a direct numeric profile target fails during endpoint or `tmbprofile` evaluation, instead of aborting the whole interval request or labelling a non-finite interval as a successful profile. Focused regression tests keep bivariate q=4 phylogenetic location-scale sigma SDs visible as direct native-TMB ML profile targets, check weak-Hessian profile status for those sigma targets, and leave q4 phylogenetic correlations derived and not profile-ready (#551).
* Phase 18 now has a standalone fixed-effect skew-normal artifact lane (`skew_normal_fixed_effect`). The new DGP, summariser, smoke runner, grid writer, manual Actions task, and focused tests save aggregate, replicate-level, manifest, failure-ledger, fixed-effect Wald interval, optional profile, optional parametric-bootstrap, interval-evidence, interval-diagnostic, and interval-failure artifacts for `bf(y ~ x, sigma ~ z, nu ~ w), family = skew_normal()`. The default grid uses moderate shape-recovery sample sizes (`n = 720` and `1440`) because stochastic skewness recovery is sample-size dependent; this is repeatable smoke/grid infrastructure, not a formal 500- or 1000-replicate operating-characteristic result.
* `skew_normal()` now fits the first univariate fixed-effect skew-normal location-scale-shape route with public `mu = E[y]`, public `sigma = SD[y]`, and residual slant `nu` on the identity scale. The TMB likelihood transforms internally to native skew-normal `xi`, `omega`, and `alpha = nu`; focused tests cover density normalization, native-density comparison, Gaussian normal limit, positive and negative skew recovery, predictor-dependent `nu`, Gaussian false-positive behaviour, simulation, fixed-effect interval visibility, and malformed-neighbour rejection. Random effects, `sd(group)`, known sampling covariance, structured effects, bivariate skew-normal models, residual `rho12`, latent `skew(id)`, and `skew` aliases remain planned.
* `drmTMB()` now forwards `REML = TRUE` through the experimental `engine = "julia"` bridge for one route-specific bivariate q = 4 Gaussian phylogenetic location-scale DRM.jl cell when the installed DRM.jl build supports that Patterson-Thompson REML diagnostic. The bridge article now shows the glmmTMB-style top-level `REML = TRUE/FALSE` switch, the labelled four-axis `phylo()` syntax, and the current missing-response boundary. This bridge evidence does not establish native-TMB q4 REML; the native route has separate recovery evidence. It also does not establish HSquared AI-REML, non-Gaussian REML, broad R-to-Julia bridge support, public optimizer controls, q4 interval reliability, or q4 interval coverage; weights, missing-predictor imputation, non-default control, most non-Gaussian families, unsupported phylogenetic neighbours, `corpair()` entries, simulation, and persistent Julia handles remain native-TMB or future bridge work (#544).
* `drmTMB()` now records `estimator`, `REML`, `requested_REML`, and `effective_REML` on experimental Julia-engine fits, so downstream diagnostics can distinguish requested REML from the estimator actually fitted. Unsupported Julia REML requests now warn with the exact unsupported cell, fall back to ML, and state that native `engine = "tmb"` is only an REML fallback for its documented univariate Gaussian REML slice rather than for every rejected Julia cell (#555).
* `biv_gaussian()` now fits the first ordinary q8 all-endpoint location-scale slope covariance slice: matching labelled `(1 + x | p | id)` terms in `mu1`, `mu2`, `sigma1`, and `sigma2`. The fitted block has eight endpoint SDs and 28 latent group-level correlations across response-specific location intercepts, location slopes, scale intercepts, and scale slopes. The SDs appear in `sdpars$mu` and `sdpars$sigma`; the correlations appear in `corpars$re_cov`, `corpairs(level = "group", block = "p")`, `summary()$covariance`, `profile_targets()`, and `check_drm()`. The Phase 18 registry now exposes opt-in `biv_gaussian_q8_endpoint` and `biv_gaussian_q8_endpoint_recovery` Actions tasks; the recovery lane reports bias, RMSE, MCSE, and explicit interval unavailability. A 2026-06-07 local two-cell audit ran 20 replicates per cell and kept q8 at `hold_diagnostic`: 38/40 manifests completed, model-convergence rates were 0.263 and 0.158, positive-Hessian rates were 0 in both cells, two replicates failed with non-positive leading minors, and no Wald intervals were usable. Q8 still has no coverage result, power claim, predictor-dependent `corpair()` regression, random `rho12`, structured q8 sibling, or non-Gaussian q8 route.
* `biv_gaussian()` now fits the first same-response location-scale slope covariance slice: matching labelled `(0 + x | p | id)` terms in `mu1`/`sigma1` or `mu2`/`sigma2`. The location-slope SD appears in `sdpars$mu`, the scale-slope SD appears in `sdpars$sigma`, and the group-level `cor(mu1:x,sigma1:x | p | id)` or `cor(mu2:x,sigma2:x | p | id)` row appears in `corpars$mu_sigma`, `corpairs(class = "mean-scale-slope")`, `summary()$parameters`, `profile_targets()`, and `check_drm()`. Cross-response pairs, mismatched coefficients, and univariate labelled `sigma` slopes remain closed; the all-endpoint q8 route is a separate source-tested slice.
* The Phase 18 same-response bivariate Gaussian q=2 `mu`/`sigma` slope covariance lane now has smoke and multi-replicate recovery artifacts (`biv_gaussian_mu_sigma_slope` and `biv_gaussian_mu_sigma_slope_recovery`). The lane reuses the fitted matching `(0 + x | p | id)` terms in `mu1` and `sigma1`, reports 12 estimands, emits bias, RMSE, empirical SE, MCSE, and fixed-effect Wald coverage tables, and keeps the two slope SDs plus the derived `mu_sigma` correlation out of Wald interval claims. A local 2026-06-06 formal audit ran 500 replicates in each of the two default recovery cells and produced 1,000 `ok` manifest rows, but convergence/positive-Hessian rates were 0.856 and 0.884 and all-replicate fixed-effect Wald coverage was 0.796-0.850. A follow-up hardening audit regenerated and robust-refit the 130 weak replicates; none were rescued, all retained false-convergence and `pdHess = FALSE`, and estimates were unchanged. Among interval-available converged fits, fixed-effect Wald coverage was 0.930-0.972, and endpoint profiles succeeded on two clean representative fits for `rho12`, both slope SDs, and `cor(mu1:x,sigma1:x | p | id)`. This is diagnostic evidence and profile feasibility, not power-grid support.
* The ordinary NB2 `mu` random-effect surface now has a standalone recovery artifact lane (`nbinom2_mu_re_recovery`), parallel to the Poisson one: it runs the already-recovery-capable smoke summary at recovery-scale `n_rep` and emits isolated bias/RMSE/MCSE, Wald-coverage, and profile-coverage CSVs through an opt-in Actions task, as a `ready_grid` `random_slopes` registry row. (The truncated-NB2 `mu` random-intercept surface already had an equivalent standalone coverage-emitting lane through its existing `truncated_nbinom2_mu_random_intercept` task, so it needed no new writer.)
* The ordinary Poisson `mu` random-effect surface now has a standalone, dispatchable recovery artifact lane (`poisson_mu_re_recovery`) — the first non-Gaussian recovery artifact lane. The recovery contract (bias, RMSE, MCSE, Wald coverage for the fixed mean coefficients, and profile coverage for the random-effect SD) was already computed by the smoke summary; the new opt-in lane runs it at recovery-scale `n_rep` and emits isolated CSV artifacts instead of only riding the combined first-wave summary. It is a `ready_grid` `random_slopes` registry row.
* The Phase 18 bivariate Gaussian slope-only `mu1`/`mu2` covariance lane now has a multi-replicate recovery companion (`biv_gaussian_mu_slope_recovery`). It reuses the smoke DGP, fit, and runner for the matching `(0 + x | p | id)` block and reports bias, RMSE, empirical SE, Monte Carlo standard error, and Wald interval coverage across its 10 estimands. Wald coverage is reported only for the fixed `mu1`/`mu2` endpoints; the two slope random-effect SDs and the derived slope-slope correlation stay `derived_interval_unavailable`. The lane is a `ready_grid` `random_slopes` registry row with its own opt-in Actions task and grid writer.
* The Phase 18 bivariate Gaussian q=6 `mu1`/`mu2` location covariance lane now has a multi-replicate recovery companion (`biv_gaussian_q6_location_recovery`). It reuses the smoke DGP, fit, and runner for the matching `(1 + x + z | p | id)` block in both location formulas and reports bias, RMSE, empirical SE, Monte Carlo standard error, and Wald interval coverage across its 30 estimands. Wald coverage is reported only for the fixed `mu1`/`mu2` endpoints; the six location random-effect SDs and the fifteen derived location-location correlations stay `derived_interval_unavailable`. The lane is a `ready_grid` `random_slopes` registry row with its own opt-in Actions task and grid writer.
* The Phase 18 bivariate Gaussian q=2 residual-scale intercept covariance lane now has a multi-replicate recovery companion (`biv_gaussian_q2_scale_recovery`). It reuses the smoke DGP, fit, and runner, runs at recovery-scale `n_rep`, and reports bias, RMSE, empirical SE, Monte Carlo standard error, and Wald interval coverage. Wald coverage is reported only for the fixed `mu1`/`mu2` endpoints that carry a standard error; the random-effect scale SDs and the derived scale-scale correlation stay `derived_interval_unavailable`. The lane is registered as a `ready_grid` `correlation_blocks` row with its own opt-in Actions task and grid writer, and its design sheet is `docs/design/156-phase-18-bivariate-scale-q2-recovery-ademp.md`.
* The Phase 18 bivariate Gaussian q=2 residual-scale slope covariance lane now fits matching `sigma1 = ~ x + (0 + x | p | id)` and `sigma2 = ~ x + (0 + x | p | id)` blocks under `biv_gaussian()`. The two scale-slope SDs appear in `sdpars$sigma`, the group-level `cor(sigma1:x,sigma2:x | p | id)` row appears in `corpars$sigma`, `corpairs(class = "scale-scale")`, `summary()$parameters`, `profile_targets()`, and `check_drm()`, and residual `rho12` remains a separate row-level correlation. The `biv_gaussian_q2_scale_slope` and `biv_gaussian_q2_scale_slope_recovery` Phase 18 tasks report smoke, bias, RMSE, MCSE, and fixed-effect Wald coverage evidence, while q8 now has separate diagnostic smoke/recovery artifact tasks that do not promote coverage or power (#483).
* The Phase 18 bivariate Gaussian q=4 `mu1`/`mu2` location covariance lane now has a multi-replicate recovery companion (`biv_gaussian_q4_location_recovery`). It reuses the smoke DGP, fit, and runner for the matching `(1 + x | p | id)` block in both location formulas, runs at recovery-scale `n_rep`, and reports bias, RMSE, empirical SE, Monte Carlo standard error, and Wald interval coverage. Wald coverage is reported only for the fixed `mu1`/`mu2` endpoints; the four location random-effect SDs and the six derived location-location correlations stay `derived_interval_unavailable`. The lane is a `ready_grid` `random_slopes` registry row with its own opt-in Actions task and grid writer.
* The Phase 18 simulation programme now has a bivariate Gaussian q=2 residual-scale intercept covariance smoke lane (`biv_gaussian_q2_scale`). It fits the already-supported matching `sigma1 = ~ 1 + (1 | p | id)` and `sigma2 = ~ 1 + (1 | p | id)` block under `biv_gaussian()`, summarising the two direct scale SDs from `sdpars$sigma` and the derived scale-scale correlation from `corpars$sigma` while keeping residual `rho12` a separate layer. The lane is registered as a `correlation_blocks` row, has its own Actions task and grid writer, and provides one fittable scale-covariance prerequisite for the q8 endpoint gate.
* `biv_gaussian()` now fits matching ordinary `mu1`/`mu2` location covariance blocks beyond the slope-only route, including q=4 `(1 + x | p | id)` and q=6 `(1 + x + z | p | id)` blocks in both location formulas with Phase 18 smoke artifact routing. The location SDs appear in `sdpars$mu` as direct `log_sd_re_cov` profile targets, and the group-level correlations appear in `corpars$re_cov`, `corpairs()`, and `summary(fit)$covariance` as derived-unavailable interval rows; same-response q2 location-scale slope covariance and q8 all-endpoint covariance now have separate smoke/recovery lanes, while predictor-dependent slope `corpair()` regressions, broad q > 2 recovery, coverage, power, and non-Gaussian correlated slopes remain planned (#440, #446).
* `drmTMB()` now accepts `REML = TRUE` for the first univariate Gaussian mixed-model slices: dense ordinary `mu` fixed effects, ordinary `mu` random intercepts or slopes, diagonal or dense known sampling covariance through `meta_V(V = V)`, intercept-only `sigma`, complete responses, and no row aggregation, structured effects, or direct random-effect scale formulae. The ordinary mixed-model path is checked against `lme4::lmer(..., REML = TRUE)`; the known-`V` path matches manual full restricted Gaussian likelihoods and `metafor` REML estimates, with the expected fixed-design determinant shift in reported `metafor` log likelihoods.
* `drmTMB()` now retries optimizer-call errors from the default deterministic `nlminb()` budget with the existing `"careful"` and `"robust"` optimizer presets when no explicit optimizer controls were supplied. Successful retries warn and record the selected preset in `fit$optimizer_used` and all attempted presets in `fit$optimizer_attempts`, while nonzero convergence-code fits still return for diagnostic inspection rather than being silently rerun (#506).
* `drmTMB()` now treats namespace-qualified formula markers such as `drmTMB::phylo(...)` and `drmTMB::meta_V(...)` as their unqualified equivalents during formula parsing, fixing the cryptic length-3 condition error triggered by `drmTMB::phylo()` in bivariate formulas (#504).
* `is_converged()` now returns a compact no-rerun convergence flag for `drmTMB` fits, with `include_hessian = TRUE` available when downstream workflows need successful `TMB::sdreport()` output and `pdHess = TRUE` before using Wald-style uncertainty (#317).
* `structured_effects()` now returns a stable post-fit metadata table for fitted `phylo()`, `spatial()`, `animal()`, `relmat()`, and `phylo_interaction()` structured-effect markers, so downstream tools can inspect grouping variables, matrix attachments, matrix slot/source/role IDs, compact precision fingerprints, provider and observed levels, level-alignment policy, input scale, bridge-marshalling boundary, fitted blocks, endpoint sets, coefficient sets, and random-effect block names without grepping formula text (#335).
* `drmTMB()` now fits the first sigma-only Gaussian structured one-slope cells for `phylo(1 + x | species, tree = tree)`, fixed-covariance `spatial(1 + x | site, coords = coords)`, A-matrix `animal(1 + x | id, A = A)`, and `relmat(1 + x | id, K/Q = ...)` on the residual-scale formula. The same tranche opens matched `mu+sigma` one-slope native point-fit/extractor cells for those four providers by tracking `mu:(Intercept)`, `mu:x`, `sigma:(Intercept)`, and `sigma:x` as separate endpoint members, with deterministic same-target fixture parity banked for the sigma-only and matched cells. The fitted scale-side structured SDs appear in `sdpars$sigma`, `ranef()`, `profile_targets()`, and log-sigma predictions; broad bridge support beyond these fixtures, interval reliability, coverage, REML, and AI-REML remain planned.
* `tweedie()` now fits the first univariate fixed-effect route for non-negative semicontinuous responses with exact zeros and positive continuous values. The supported syntax is `bf(y ~ x, sigma ~ z, nu ~ 1)` with `log(mu)`, `log(sigma)`, public `sigma = sqrt(phi)`, `nu = 1 + plogis(eta_nu)`, `E[y] = mu`, and `Var(y) = sigma^2 * mu^nu`. Random effects, predictor-dependent `nu`, structured effects, bivariate or mixed-response Tweedie models, zero-inflation aliases, and hurdle aliases remain planned.
* `student()`, `lognormal()`, `Gamma(link = "log")`, `beta()`, `beta_binomial()`, and `truncated_nbinom2()` now support ordinary unlabelled independent numeric `mu` random slopes such as `(0 + x | id)` beside their first ordinary `mu` random-intercept slices. The fitted slope SD appears in `sdpars$mu`, `ranef(fit, "mu")`, `random_effects$mu`, direct `profile_targets()` rows, and `check_drm()` replication/design diagnostics; correlated slopes, labelled covariance, non-Gaussian `sigma` random effects beyond the NB2/lognormal/Gamma intercept gates or shape random effects beyond the exact Student-t phylo `nu` local-fit gate, broad structured effects, zero-one beta random effects, and hurdle/inflation random effects beyond the exact Poisson spatial `zi` local-fit gate remain planned.
* The non-Gaussian tutorial route now connects count, beta-binomial, beta, and zero-one beta examples through the getting-started article, model map, implemented source map, worked-example inventory, and pkgdown article navigation, while keeping correlated random slopes, zero-one beta random effects, structured bounded responses, known covariance, ordered beta, beta-binomial zero inflation, and mixed bounded-response models planned.
* The model-guide route now includes a model-selection article for AIC/BIC comparisons. It shows Gaussian versus Student-t, NB2 versus ZINB2, and constant versus predictor-dependent `sigma` candidates, and it reads a 200-replicate seeded Phase 18 article-support summary that keeps MCSEs, convergence, Hessian, and warning rates beside AIC/BIC target-selection rates. The table is documentation evidence, not a formal power or operating-characteristic grid.
* `zero_one_beta()` now fits the first fixed-effect route for continuous proportions on `[0, 1]` with structural exact 0 or 1 outcomes. The interior beta component uses `mu` and public scale `sigma`; `zoi` models the probability of an exact boundary outcome; `coi` models the probability that a boundary outcome is exactly 1; and `fitted()` returns the unconditional mean `(1 - zoi) * mu + zoi * coi`. Random effects, structured effects, denominator syntax, known covariance, and bivariate bounded-response models remain planned or blocked.
* `gr()` is now deprecated as a public formula marker. Existing direct calls warn and remain no-op placeholders for compatibility, while new known-relatedness formulas should use `relmat()` or the biological structured-effect markers `animal()`, `phylo()`, and `spatial()`.
* `meta_known_V()` is now deprecated as a formula marker. Existing direct calls and formulas warn, while fitted Gaussian known-covariance models continue to use the same additive known-`V` likelihood path; new code should use `meta_V(V = V)`.
* `miss_control()` now exposes the first missing-data control surface. The default `response = "drop"` keeps existing complete-case behaviour, while `response = "include"` retains missing-response rows for univariate Gaussian models and independent-observation bivariate Gaussian models with complete predictors. Univariate masked responses contribute zero Gaussian likelihood; bivariate partial-response rows contribute the appropriate marginal Gaussian likelihood, both-missing rows contribute zero response likelihood, and `fit$missing_data` stores original-row accounting and response-pattern counts. The first missing-predictor slices also support one numeric univariate Gaussian location term such as `mi(x)` with `impute = list(x = x ~ z)`, `impute = list(x = x ~ z + (1 | group))`, or an explicit intercept-only structured covariate model such as `impute = list(x = x ~ z + relmat(1 | line, Q = Q))` and `missing = miss_control(predictor = "model")`, integrating missing `x` values by TMB's Laplace approximation under a fixed-effect, one random-intercept, or one structured-intercept Gaussian predictor model. The first family-specific non-Gaussian predictor slices support one binary `mi(treatment)` term with `impute = list(treatment = impute_model(treatment ~ z, family = binomial()))`, one ordered categorical `mi(score)` term with `impute = list(score = impute_model(score ~ z, family = cumulative_logit()))`, one unordered categorical `mi(habitat)` term with `impute = list(habitat = impute_model(habitat ~ z, family = categorical()))`, one strict proportion `mi(cover)` term with `impute = list(cover = impute_model(cover ~ z, family = beta()))`, one boundary-proportion `mi(cover)` term with `impute = list(cover = impute_model(cover ~ z, family = zero_one_beta()))`, one denominator-aware proportion `mi(cover)` term with `impute = list(cover = impute_model(success ~ z, family = beta_binomial(), trials = trials))`, one Poisson count `mi(abundance)` term with `impute = list(abundance = impute_model(abundance ~ z, family = poisson()))`, one negative-binomial count `mi(abundance)` term with `impute = list(abundance = impute_model(abundance ~ z, family = nbinom2()))`, one zero-truncated negative-binomial count `mi(abundance)` term with `impute = list(abundance = impute_model(abundance ~ z, family = truncated_nbinom2()))`, one lognormal positive continuous `mi(biomass)` term with `impute = list(biomass = impute_model(biomass ~ z, family = lognormal()))`, one Gamma positive continuous `mi(biomass)` term with `impute = list(biomass = impute_model(biomass ~ z, family = Gamma(link = "log")))`, and one Tweedie semi-continuous `mi(biomass)` term with `impute = list(biomass = impute_model(biomass ~ z, family = tweedie()))`. Finite-state predictors sum exactly over possible missing states; strict beta/proportion predictors use deterministic quadrature over possible missing proportion values; zero-one beta boundary proportions use exact zero and one mass plus deterministic interior beta quadrature; beta-binomial denominator-aware proportions use deterministic finite summation over possible success counts; Poisson, negative-binomial, and zero-truncated negative-binomial count predictors use deterministic finite summation over count states; lognormal positive predictors use deterministic quadrature over log-scale states; Gamma positive predictors use deterministic quadrature under the Gamma mean-CV predictor model; Tweedie semi-continuous predictors use exact zero mass plus deterministic positive-support quadrature with fixed predictor-model power 1.5. `imputed()` reports fitted conditional modes for Gaussian missing predictors, fitted conditional probabilities for binary missing predictors, fitted conditional expected scores plus level probabilities for ordered missing predictors, fitted conditional modal categories plus level probabilities for unordered missing predictors, fitted conditional means for strict beta/proportion, boundary-proportion, beta-binomial, lognormal, Gamma, and Tweedie predictors, and fitted conditional expected counts for count predictors. Dense known-`V` partial-response slicing, structured covariate slopes, automatic response-structure inheritance, joint response-covariate structured correlations, multiple missing predictors, grouped or structured non-Gaussian predictor models, EM/profile engines, simulation-based imputed summaries, and measurement-error models remain planned.
* `miss_control(predictor = "model")` now has a first non-Gaussian response route: ordinary `family = poisson()` models can include one fixed-effect binary `mi(treatment)` predictor with `impute = list(treatment = impute_model(treatment ~ z, family = binomial()))`. The route sums over the two missing treatment states with the Poisson response likelihood; missing Poisson responses, zero-inflated Poisson response models, Poisson response random or structured effects with `mi()`, non-binary missing predictors in Poisson response models, and multiple missing predictors remain planned.
* `phylo_interaction()` now fits the first q=1 pair-level phylogenetic interaction slice for univariate Gaussian `mu` and ordinary Poisson/NB2 `mu` models, using a sparse Kronecker precision from the two partner phylogenies. Use a precomputed pair column with ordinary `(1 | pair_id)` for independent pair effects, and keep additive partner main phylogenies, binary/Bernoulli incidence models, structured pair slopes, labelled count covariance, and simultaneous structured layers as planned follow-up work (#447).
* The status and learning docs now consistently lead with `meta_V(V = V)` for known sampling covariance, keep `meta_known_V(V = V)` as a deprecated compatibility alias, and refresh known-limitations wording so constant spatial, animal-model, and `relmat()` q=4 routes plus ordinary Poisson/NB2 q=1 structured `mu` routes are described as bounded first slices rather than broad planned or broad fitted support.
* Phase 18 now exposes a manual-only `correlation_block_status` Actions task that writes read-only CSV status artifacts for residual `rho12`, ordinary and structured q=2 `corpairs()` rows, and q=4 diagnostic rows. It removes the correlation-block wrapper-target gap without running new models, promoting q=4 intervals, or changing the fitted support boundary (#446).
* Phase 18 now exposes manual-only `phylo_mu_slope`, `spatial_mu_slope`, `animal_mu_slope`, and `relmat_mu_slope` Actions tasks for the Gaussian structured `mu` one-slope grid writers. Historical note, superseded by current 0.6.0 evidence: q1 structured `sigma` one-slope routes now fit for all four providers, and exact non-Gaussian provider gates are recorded in the live ledger. The manual Gaussian tasks remain excluded from `task = "all"`; mesh/SPDE, sparse large-pedigree speed claims, additional multiple or labelled structured-slope layouts outside the exact fitted ledger cells, slope correlations, and non-Gaussian structured slopes outside the exact later gates stay out of their scope.
* Phase 18 now has a local phylogenetic Gaussian `mu` one-slope artifact writer. Historical note, superseded by current 0.6.0 evidence: the exact q1 phylogenetic `sigma` one-slope route and exact non-Gaussian phylogenetic gates are now fitted at their recorded tiers. The manual Gaussian task remains excluded from `task = "all"`; additional multiple or labelled phylogenetic-slope layouts outside the exact fitted ledger cells, slope correlations, and non-Gaussian phylogenetic effects outside the exact later gates stay out of its scope.
* Phase 18 now has a local dense-pedigree `animal()` Gaussian `mu` one-slope artifact writer. The DGP, smoke runner, summary helper, grid writer, manual `animal_mu_slope` task, and focused tests save aggregate, replicate-level, manifest, and failure-ledger artifacts for `animal(1 + x | id, pedigree = pedigree)`. Historical note, superseded by current 0.6.0 evidence: the exact A-matrix q1 `sigma` one-slope route is now fitted and inference-ready with caveats; pedigree/Ainv bridge marshalling, `task = "all"` inclusion, sparse large-pedigree speed claims, additional multiple or labelled animal-slope layouts outside the exact fitted ledger cells, and slope correlations remain out of scope.
* Phase 18 now has a local known-matrix `relmat()` Gaussian `mu` one-slope artifact writer. The DGP, smoke runner, summary helper, grid writer, manual `relmat_mu_slope` task, and focused tests save aggregate, replicate-level, manifest, and failure-ledger artifacts for `relmat(1 + x | id, Q = Q)`. Historical note, superseded by current 0.6.0 evidence: the exact K/Q q1 `sigma` one-slope route is now fitted and inference-ready with caveats; broader bridge claims, `task = "all"` inclusion, additional multiple or labelled `relmat()`-slope layouts outside the exact fitted ledger cells, and slope correlations remain out of scope.
* `drmTMB()` now exposes the fitted `TMB::sdreport()` object as both `$sdr` and `$sdreport`, making Hessian checks easier to discover. Wald standard errors, `vcov()`, and Wald confidence intervals are unavailable when `TMB::sdreport()` returns but `pdHess = FALSE`, so non-positive-definite Hessian fits keep point estimates but no longer advertise Hessian-based intervals.
* The bivariate coscale tutorial and correlation-pair design note now sharpen the reader boundary between residual `rho12`, singular `corpair()` formula markers, and plural `corpairs()` extraction rows, including fitted structured extraction rows while keeping random effects in `rho12` and unsupported `corpair()` regressions planned (#443).
* The ordinary Gaussian random-slope closeout now links the q=3 recovery, q=4 output-contract, extractor, `corpairs()`, `summary()`, `profile_targets()`, and independent log-`sigma` slope evidence before larger Phase 18 power simulations use those rows (#439).
* The random-slope support matrix now consistently separates fitted ordinary, bivariate slope-only, structured one-slope, selected non-Gaussian `mu`, and structured count q=1 routes from their planned neighbours (#438). Historical note, superseded by current 0.6.0 evidence: q1 structured `sigma` one-slope routes now fit for phylo/spatial/animal/relmat; phylo, A-matrix animal, and K/Q relmat are inference-ready with caveats, while spatial intervals remain blocked. Additional multiple or labelled structured-slope layouts outside the exact fitted ledger cells, slope correlations, and broader non-Gaussian neighbours remain planned.
* `confint(method = "profile")` now has `profile_engine = c("auto", "endpoint", "tmbprofile")`. The default `auto` route uses a faster endpoint-only scalar solver for direct constant scale, SD, and correlation targets, with curvature-seeded endpoint brackets and lower/upper endpoint splitting when a single endpoint target is profiled with Unix `parallel = "multicore"`. Fixed-effect profiles, `newdata` profiles, linear combinations, and derived targets remain on the existing `TMB::tmbprofile()` or status-only paths. Profile rows now record the engine in `profile.engine`, `parallel = "multicore"` uses about half the detected CPU cores when `workers = NULL`, and `bench/profile-scalar-endpoint.R` records endpoint-versus-`tmbprofile` timing evidence for the phylogenetic SD target.
* `confint()` now defaults to fast Wald intervals for fixed effects plus direct fitted scale, random-effect SD, random-effect correlation, and constant `rho12` targets when `TMB::sdreport()` is available. SD intervals use the fitted log-SD scale, correlation intervals use a guarded Fisher-z/atanh scale, `profile_precision = "fast"` supplies quicker profile controls for selected long-running targets, and `method = "bootstrap"` adds bounded simulate/refit percentile intervals with refit success/failure counts; positive scale and SD bootstrap intervals use fitted log-scale percentiles before exponentiating endpoints (reported from itchyshin/bergmann-drmTMB#2).
* `confint(method = "bootstrap")` now gives a direct-target-only error when a user requests a derived target such as a q4 unstructured correlation, modelled `sd(group)` surface, repeatability, or phylogenetic signal by exact name or by a broad alias such as `parm = "correlations"` or `parm = "variance_components"`, instead of reporting the target as unknown or silently dropping unsupported rows.
* `confint(method = "profile")` now forwards `parallel` and `workers` to the target loop and accepts `profile_maxit` as an explicit per-target `TMB::tmbprofile()` budget guard. Serial remains the default, Unix `multicore` can split independent profile targets, and user-supplied `maxit` in `...` is rejected when `profile_maxit` is also supplied.
* `profile()` now returns full profile-likelihood curve data for selected direct `profile_targets()` rows, and `plot()` draws the likelihood-ratio curve with the fitted estimate, likelihood-ratio cutoff, and profile confidence endpoints. The model-workflow article shows a 95% residual-`sigma` profile and the focused test suite now checks that the sampled curve extends beyond the cutoff on both sides of the interval.
* `profile_targets()` now reports fitted q=4 Julia bivariate phylogenetic SD estimates from the stored `phylocov` covariance instead of placeholder `0.5` values. The R-side Julia bridge target inventory now matches the fitted among-axis `Sigma_a` block before profile or bootstrap intervals are requested (#555).
* Univariate Gaussian models now fit residual-scale structured random intercepts with `sigma ~ phylo(...)`, `sigma ~ spatial(...)`, `sigma ~ animal(...)`, and `sigma ~ relmat(...)`. Matching intercept-only structured terms in `mu` and `sigma` estimate one latent structured `mu`-`sigma` correlation and report separate SD rows under `sdpars$mu` and `sdpars$sigma`, correlation rows under `corpars`, `corpairs()`, and `profile_targets()`. Historical note, superseded by the current 0.6.0 guidance: exact q1 `sigma` one-slope routes are now fitted for all four providers, with phylo, A-matrix animal, and K/Q relmat inference-ready with caveats; spatial sigma-slope intervals remain blocked. Additional multiple or labelled structured-sigma layouts outside the exact fitted ledger cells, direct-SD formulas combined with structured `sigma`, mesh/SPDE, and non-Gaussian residual-scale structured effects beyond the exact NB2 q1 recovery-grade routes remain planned.
* Bivariate `sigma()` output is now a roundable list for `biv_gaussian()` fits, so `round(sigma(fit), digits)` preserves the documented `$sigma1` and `$sigma2` components.
* The large phylogenetic benchmark runner can now include a real cell-level random intercept through `--cell-random-effect true`, giving speed checks a mixed-model path that is closer to applied repeated-cell data.
* `plot_corpairs()` now uses Confidence Eye regions by default for supported finite correlation intervals: the eye is a pale Fisher-z/atanh confidence region and the hollow circle is the point estimate. Conventional CI lines remain available with `interval_style = "line"` for diagnostic or reader-preference displays.
* The figure gallery now treats the default Confidence Eye as a stricter visual contract for selected row-wise interval summaries: pale finite confidence region plus hollow point-estimate circle, a dotted zero reference where zero is meaningful, a bottom scale axis, and no filled points, outlines, in-plot titles, or CI bars in default examples. Other figure classes keep purpose-specific grammar: raw-data displays, model surfaces, point summaries, simulation summaries, and support-boundary strips are judged case by case. Variance-component SD rows use log-SD Wald eyes, correlation rows use Fisher-z/atanh eyes, compact point summaries use point-interval displays, and the gallery surface example now labels the shared `sigma ~ temperature` curve explicitly rather than implying a habitat-specific scale effect.
* `poisson()` now fits the labelled-scalar spatial count route `bf(count ~ x + spatial(1 | p | site, coords = coords))`. The label is treated as a scalar covariance-block tag for the existing q1 spatial `mu` field and is exposed through `sdpars$mu`, `ranef("spatial_mu")`, and a direct `profile_targets()` row. This is local fit-only evidence only: q2/q4 count covariance, labelled slopes, simultaneous structured providers, intervals, coverage, `inference_ready`, `supported`, REML, AI-REML, bridge support, and public support remain out of scope.
* `nbinom2()` now fits the ordinary, non-zero-inflated q=1 phylogenetic `mu` intercept with syntax `bf(count ~ x + phylo(1 | species, tree = tree), sigma ~ z)`. The fitted effect is on the log-mean scale while `sigma` remains fixed-effect overdispersion; `sdpars$mu`, `ranef("phylo_mu")`, `profile_targets()` as a direct `log_sd_phylo` target, and `check_drm()` phylogenetic diagnostics expose the route. Historical note, superseded by current recovery evidence: exact q1 structured `sigma` intercept-plus-one-slope routes now fit for phylo/spatial/animal/relmat. Labelled q2/q4 count blocks, zero-inflated NB2 phylogeny, richer structured sigma blocks, structured-sigma intervals/coverage, simultaneous structured count types, and count cross-parameter covariance remain planned.
* `poisson()` and `nbinom2()` now fit q=1 `spatial()`, `animal()`, and `relmat()` `mu` intercepts for ordinary non-zero-inflated count models, extending the existing q=1 `phylo()` count route. The fitted log-mean structured SD appears in `sdpars$mu`, marker-specific `ranef()` blocks such as `ranef("spatial_mu")`, direct `profile_targets()` rows through `log_sd_phylo`, and `check_drm()` structured diagnostics. Historical note, superseded by current recovery evidence: exact q1 structured NB2 `sigma` intercept-plus-one-slope routes now fit for phylo/spatial/animal/relmat. Pure or multiple structured count slopes, labelled q2/q4 count covariance beyond the exact Poisson scalar-label gate, zero-inflated structured effects beyond the exact local-fit gates, simultaneous structured count types, richer structured sigma blocks, and structured-sigma intervals/coverage remain planned.
* Phase 18 now has an opt-in count structured q1 artifact lane for ordinary Poisson/NB2 `spatial()`, `animal()`, and `relmat()` `mu` intercepts. The new DGP, summariser, smoke runner, summary helper, grid writer, manual `count_structured_q1` Actions task, and focused tests save aggregate, replicate, manifest, failure-ledger, fixed-effect Wald interval, Wald coverage, direct `log_sd_phylo` profile-target, optional profile-interval, interval-evidence, interval-diagnostic, and interval-failure artifacts without adding zero-inflated structure, structured slopes, labelled count covariance, structured NB2 `sigma`, `task = "all"` inclusion, or formal recovery claims.
* `nbinom2()` now fits the first ordinary log-`sigma` random-intercept gate for non-zero-inflated models, with syntax such as `bf(count ~ x, sigma ~ z + (1 | id))`. The fitted effect models grouped overdispersion on the log-`sigma` scale and is exposed through `sdpars$sigma`, `random_effects$sigma`, `sigma()`, `predict(dpar = "sigma")`, direct `log_sd_sigma` profile targets, and `check_drm()` replication diagnostics. Historical note, superseded by current recovery evidence: exact q1 structured NB2 `sigma` intercept-plus-one-slope routes now fit for phylo/spatial/animal/relmat. Ordinary NB2 `sigma` slopes, labelled covariance blocks, joint `mu`/`sigma` random effects, zero-inflated/truncated/hurdle NB2 scale random effects, richer structured sigma blocks, structured-sigma intervals/coverage, and Poisson scale random effects remain planned or inapplicable.
* `beta()` and `beta_binomial()` now support ordinary unlabelled `mu` random intercepts and independent numeric slopes such as `bf(prop ~ x + (1 | id) + (0 + x | id), sigma ~ z)` for strict `(0, 1)` responses and `bf(cbind(success, failure) ~ x + (1 | id) + (0 + x | id), sigma ~ z)` for counted successes out of known trials. The fitted logit-mean or logit-success-probability SD appears in `sdpars$mu`, `random_effects$mu`, direct `profile_targets()` rows, and `check_drm()` replication diagnostics; correlated bounded-response random slopes, labelled covariance blocks, `sigma` random effects, exact 0/1 boundary mass, `zoi`/`coi`, structured effects, known covariance, and bivariate or mixed bounded-response models remain planned.
* `student()` now supports ordinary unlabelled `mu` random intercepts and independent numeric slopes such as `bf(y ~ x + (1 | id) + (0 + x | id), sigma ~ z, nu ~ 1)`. The fitted location SD appears in `sdpars$mu`, `random_effects$mu`, direct `profile_targets()` rows, and `check_drm()` replication diagnostics; correlated Student-t random slopes, labelled covariance blocks, `sigma` random effects, `nu` random effects beyond the exact phylo local-fit gate, broad structured effects, known covariance, and bivariate Student-t models remain planned.
* `lognormal()` and `Gamma(link = "log")` now support ordinary unlabelled `mu` random intercepts and independent numeric slopes such as `bf(y ~ x + (1 | id) + (0 + x | id), sigma ~ z)`. The fitted SDs appear in `sdpars$mu`, `random_effects$mu`, direct `profile_targets()` rows, and `check_drm()` replication diagnostics. This historical ordinary-effect entry is superseded in part by the exact Arc 3a q1 Gamma-phylo and lognormal-phylo/relmat intercept gates; correlated positive-continuous random slopes, labelled covariance blocks, `sigma` slopes, labelled or combined `sigma` random effects, other structured positive-continuous effects, known covariance, and bivariate or mixed positive-continuous models remain planned.
* Phase 18 now has a Student-t `mu` random-intercept artifact lane for `student()`. The new DGP, summariser, smoke runner, grid writer, first-wave runner inclusion, manual `student_mu_random_intercept` Actions task, and focused tests save aggregate, replicate, manifest, failure-ledger, fixed-effect Wald interval, Wald coverage, direct-SD profile interval, and profile coverage artifacts for ordinary `(1 | id)` in `mu` with fixed-effect `sigma` and `nu`, while keeping correlated Student-t random slopes, labelled covariance blocks, `sigma` random effects, `nu` random effects beyond the exact phylo local-fit gate, broad structured effects, known covariance, and bivariate Student-t models out of scope.
* Phase 18 now has a zero-truncated NB2 `mu` random-intercept artifact lane for `truncated_nbinom2()`. The new DGP, summariser, smoke runner, grid writer, first-wave runner inclusion, manual `truncated_nbinom2_mu_random_intercept` Actions task, and focused tests save aggregate, replicate, manifest, failure-ledger, fixed-effect Wald interval, Wald coverage, direct-SD profile interval, and profile coverage artifacts for ordinary `(1 | id)` in `mu`, while keeping correlated zero-truncated NB2 random slopes, labelled covariance blocks, `sigma` random effects, hurdle random effects, zero-inflated zero-truncated models, structured effects, and bivariate count models out of scope.
* Phase 18 now has a bounded-response `mu` random-intercept artifact lane for `beta()` and `beta_binomial()`. The new DGP, summariser, smoke runner, grid writer, first-wave runner inclusion, manual `bounded_response_mu_random_intercept` Actions task, and focused tests save aggregate, replicate, manifest, failure-ledger, fixed-effect Wald interval, Wald coverage, direct-SD profile interval, and profile coverage artifacts for ordinary `(1 | id)` in `mu`, while keeping correlated bounded-response random slopes, labelled covariance blocks, `sigma` random effects, exact 0/1 boundary mass, zero-one beta random effects, structured effects, known covariance, and mixed bounded-response models out of scope.
* Phase 18 now has a fixed-effect proportion artifact lane for `beta()` and `beta_binomial()`. The new DGP, summariser, smoke runner, grid writer, first-wave runner inclusion, manual `proportion_fixed_effect` Actions task, and focused tests save aggregate, replicate, manifest, failure-ledger, fixed-effect Wald interval, and Wald coverage artifacts while keeping exact 0/1 boundary mass, `zoi`/`coi`, correlated bounded-response random slopes, labelled covariance blocks, `sigma` random effects, structured bounded responses, and mixed-response bounded models out of scope.
* Phase 18 now has a fixed-effect positive-continuous artifact lane for `lognormal()` and `Gamma(link = "log")`. The new DGP, summariser, smoke runner, grid writer, first-wave runner inclusion, manual `positive_continuous_fixed_effect` Actions task, and focused tests save aggregate, replicate, manifest, failure-ledger, fixed-effect Wald interval, and Wald coverage artifacts while keeping Tweedie, generalized Gamma, positive-response random effects beyond the ordinary `mu` intercept slice, known-covariance positive responses, structured positive responses, and mixed-response positive-continuous models out of scope.
* Phase 18 now has a positive-continuous `mu` random-intercept artifact lane for `lognormal()` and `Gamma(link = "log")`. The new DGP, summariser, smoke runner, grid writer, first-wave runner inclusion, manual `positive_continuous_mu_random_intercept` Actions task, and focused tests save aggregate, replicate, manifest, failure-ledger, fixed-effect Wald interval, Wald coverage, direct-SD profile interval, and profile coverage artifacts for ordinary `(1 | id)` in `mu`, while keeping correlated positive-continuous random slopes, labelled covariance blocks, `sigma` random effects, Tweedie, generalized Gamma, structured effects, known covariance, and mixed positive-continuous models out of scope.
* Phase 18 added a fixed-effect ordinal artifact lane for `cumulative_logit()`. Historical note, superseded in part by later ordinary `mu` intercept/slope recovery and an exact phylogenetic intercept gate: this artifact lane itself covers only aggregate, replicate, manifest, failure-ledger, fixed-effect Wald interval, Wald coverage, cutpoint, and cutpoint-ordering outputs; correlated/labelled or other structured ordinal effects, ordinal scale/discrimination formulas, bivariate ordinal models, and mixed-response ordinal models remain out of scope.
* Phase 18 now has a fixed-effect zero-one beta artifact lane for `zero_one_beta()`. The new DGP, summariser, smoke runner, grid writer, first-wave runner inclusion, manual `zero_one_beta_fixed_effect` Actions task, and focused tests save aggregate, replicate, manifest, failure-ledger, fixed-effect Wald interval, and Wald coverage artifacts while keeping zero-one random effects, covariance blocks, denominator syntax, known covariance, structured bounded responses, and bivariate or mixed bounded-response models out of scope.
* Phase 18 Slice C now closes the count first-wave review lane as a documented evidence inventory rather than a new syntax lane. The new count-closure note ties together paired Poisson/NB2 `mu` random effects, NB2 log-`sigma` random intercepts, Poisson q1 phylo, NB2 q1 phylo, the NB2 `hold_smoke_only` formal gate, and the next Slice D choices while keeping COM-Poisson, generalized Poisson, Tweedie, zero-one beta, skew-normal, and new random-effect syntax out of scope.
* Phase 18 now has an overdispersion-aware NB2 phylogenetic q1 formal-admission lane for `bf(count ~ x + phylo(1 | species, tree = tree), sigma ~ z)`. The new ADEMP sheet, DGP, target-plus-grouped-comparator fitter, summariser, smoke runner, summary helper, grid writer, formal-grid spec/read-back QA helpers, promotion-decision helper, focused tests, and manual `nbinom2_phylo_q1_formal` Actions task save aggregate, replicate, manifest, failure-ledger, Wald interval, Wald coverage, direct `log_sd_phylo` profile-target, optional profile-interval, interval-evidence, interval-diagnostic, and interval-failure artifacts. This does not create formal recovery or coverage claims until the 500-replicate grid is run and audited.
* Phase 18 Slices 541-555 now record a local NB2 phylogenetic q1 formal-audit pass. The all-cell sentinel ran 288 formal cells once and the representative audit ran 24 formal-shaped cells with five replicates each, both with direct `log_sd_phylo` profiles and grouped-comparator rows. The artifacts passed read-back QA, all sentinel fits and all replicate-audit rows converged, and the promotion helper correctly keeps the route at `hold_smoke_only` because the 500-replicate formal recovery gate was not run. Profile failures at true `sd_phylo = 0` and fixed-`sigma` instability in low-count, low-overdispersion cells remain visible audit boundaries.
* Phase 18 formal phylogenetic q1 Actions tasks now accept one-based `condition_shard` and `condition_shards` inputs. The NB2 q1 full-grid singleton dispatch was cancelled after existing manifest timings implied a 27-31 hour run under optimistic ten-worker assumptions, so shard artifacts now record shard metadata and require a merged audit before any coverage claim.
* Phase 18 formal phylogenetic q1 Actions tasks now use shard-aware concurrency groups, so manually dispatched 16-shard NB2 q1 formal runs do not replace earlier pending shards. The supported non-Gaussian evidence goal is now recorded as an evidence closeout for fixed-effect non-Gaussian families plus first count mixed-model lanes, not as broad non-Gaussian random-effect or structured-effect parity.
* Phase 18 NB2 q1 formal shard artifacts have now been downloaded and audited together. The completed 16-shard x 500-replicate set has all 288 formal condition cells and 144,000 `ok` manifest rows, but the route remains `hold_smoke_only` because direct `log_sd_phylo` profile intervals are boundary-sensitive and low-count fixed-`sigma` recovery remains unstable.
* Phase 18 Slice D3 records the zero-one bounded-response design gate. The note separates strict `beta()`, denominator-aware `beta_binomial()`, and zero-one beta responses with exact 0/1 mass while keeping zero-one random effects, correlated or broader bounded-response random slopes, structured bounded responses, Tweedie, skew-normal, COM-Poisson, and generalized Poisson out of the fitted surface.
* `poisson(link = "log")` now fits the first structured non-Gaussian dependence slice: an ordinary, non-zero-inflated q=1 phylogenetic `mu` intercept with syntax `bf(count ~ x + phylo(1 | species, tree = tree))`. The fitted effect is on the log-mean scale and is exposed through `sdpars$mu`, `ranef("phylo_mu")`, `profile_targets()` as a direct `log_sd_phylo` target, and `check_drm()` phylogenetic diagnostics. This is intentionally not broad count parity: pure or multiple structured count slopes, labelled q=2/q=4 count blocks, zero-inflated structured count effects, simultaneous structured count types, and count cross-parameter covariance remain planned.
* `biv_gaussian()` now fits constant coordinate-spatial q=4 location-scale blocks when the same labelled `spatial(1 | p | site, coords = coords)` term appears in `mu1`, `mu2`, `sigma1`, and `sigma2`. The fitted route reports four spatial endpoint SDs and six derived latent spatial correlations through `corpairs(level = "spatial")`, `summary()$covariance`, `profile_targets()`, and `check_drm()`, with q=4 correlation intervals marked derived-unavailable. Historical note, superseded by the current 0.6.0 guidance: the q1 spatial `sigma` one-slope route now has point-fit/extractor evidence, although its interval gate remains blocked; mesh/SPDE, block-diagonal or broader intercept-plus-slope spatial covariance beyond the exact fixed-covariance all-four one-slope cell, additional multiple or labelled spatial-sigma layouts outside the exact fitted ledger cells, predictor-dependent spatial `corpair()` regression, direct spatial SD surfaces, and non-Gaussian spatial effects outside the exact ordinary Poisson/NB2 q1 spatial `mu` intercept-plus-one-slope, recovery-grade NB2 q1 spatial `sigma`, Student-t spatial `mu`, Poisson spatial `zi`, fixed-`zi` Poisson spatial `mu`, and fixed-`zi` NB2 spatial `mu` gates remain planned (#5).
* The implementation-map roadmap now records Slices 356-380 as the fitted spatial q4 closeout and Slices 381-388 as the first non-Gaussian structured front gate. The new Poisson q1 ADEMP sheet keeps the first structured non-Gaussian simulation gate to one non-zero-inflated Poisson `mu` phylogenetic intercept, while `zi`, `hu`, scale, shape, ordinal, bounded-response, mixed-response, spatial, animal, `relmat()`, slope, q2, and q4 structural layers remain planned rather than fitted.
* The implementation-map roadmap now records Slices 389-405 as the remaining non-Gaussian structured-dependence planning gates. These close the scale, shape, ordinal, known-covariance, extractor, diagnostic, simulation, interval, fallback, error-message, grammar, documentation, and issue-template contracts without adding new likelihood, TMB, or formula-grammar code.
* The implementation-map roadmap now records Slices 406-420 as route-specific non-Gaussian structured issue drafts. These add a Poisson q1 implementation issue body, Poisson q1 smoke-runner body, malformed-neighbour test body, documentation-sync body, NB2 q1 ADEMP skeleton, probability-component and scale/shape boundaries, and extractor/diagnostic name registries without opening new code.
* The implementation-map roadmap now records Slices 421-435 as the Poisson phylogenetic q1 runner contract. This names the direct `log_sd_phylo` target, `sdpars$mu` and `ranef("phylo_mu")` extractor checks, manifest and warning/error schemas, smoke and formal-grid gates, stale-doc corrections, malformed-neighbour error table, and focused test plan without adding new likelihood code.
* The implementation-map roadmap now records Slices 436-450 as Poisson phylogenetic q1 evidence-ledger synchronization. The source map, validation-debt register, Phase 18 programme, readiness matrix, and family registry now point to the runner contract before broad simulation claims.
* Phase 18 now has an opt-in Poisson phylogenetic q1 smoke surface for the ordinary non-zero-inflated `phylo(1 | species, tree = tree)` `mu` route. The new DGP, fitter, summariser, runner, summary helper, and focused tests return aggregate, replicate, manifest, failure-ledger, Wald fixed-effect interval, Wald coverage, and direct `log_sd_phylo` profile-target status tables; formal recovery grids remain future work.
* Phase 18 now has a repeatable grid-output writer for the Poisson phylogenetic q1 smoke surface, saving aggregate, replicate, manifest, failure-ledger, Wald interval, Wald coverage, and direct profile-target CSVs beside resumable per-replicate RDS files.
* Phase 18 Poisson phylogenetic q1 artifacts now include optional direct `log_sd_phylo` profile intervals, interval-evidence diagnostics, a formal-grid spec/read-back QA wrapper, a promotion-decision helper, and a manual `poisson_phylo_q1_formal` GitHub Actions task. The formal task is excluded from `task = "all"`; formal recovery or coverage claims still require the 500-replicate gate and artifact review.
* Phase 18 now has a separate ordinary NB2 log-`sigma` random-intercept smoke lane for `bf(count ~ x, sigma ~ z + (1 | id))`. The new DGP, summariser, runner, summary helper, and grid writer save aggregate, replicate, manifest, failure-ledger, Wald interval, Wald coverage, direct `log_sd_sigma` profile-target, optional profile-interval, interval-evidence, interval-diagnostics, and interval-failure artifacts beside resumable RDS results. Historical note, superseded by current 0.6.0 evidence: NB2 q1 structured `sigma` intercept-plus-one-slope routes for phylo/spatial/animal/relmat now have recovery-grade point-fit evidence. This is still not broad NB2 scale parity: ordinary NB2 `sigma` slopes, joint `mu`/`sigma` random effects, structured sigma intervals/coverage, richer structured blocks, and zero-inflated/truncated/hurdle scale random effects remain planned.
* The implementation-map roadmap now records Slices 526-540 as the NB2 phylogenetic q1 overdispersion-aware formal-admission lane. This adds the ADEMP sheet, DGP, target-plus-grouped-comparator fit, summariser, smoke runner, grid writer, formal-grid QA helpers, manual Actions task, tests, and docs sync while keeping formal recovery claims gated on a later 500-replicate run and audit.
* The implementation-map roadmap now records Slices 496-510 as the NB2 phylogenetic q1 implementation slice. This adds the ordinary non-zero-inflated NB2 `mu` phylogenetic intercept, TMB prior contribution, extractor/profile/diagnostic tests, and neighbouring-route guards. Historical note, superseded by current 0.6.0 evidence: NB2 q1 structured `sigma` intercept-plus-one-slope routes for phylo/spatial/animal/relmat now have recovery-grade point-fit evidence; their intervals/coverage, NB2 `zi`, richer structured slopes, and broader count covariance remain planned.
* The implementation-map roadmap now records Slices 341-355 as implementation-ready issue templates and acceptance gates for generic direct-SD syntax, p8/q8 slope covariance, spatial q4 parity, Poisson/NB2 q1 structured-count candidates, non-Gaussian structured ADEMP sheets, user documentation, review roles, and validation handoffs; these remain planning slices and do not add new fitted model surfaces.
* The implementation-map roadmap now records Slices 326-340 as pre-code specifications for generic direct-SD syntax, p8/q8 endpoint registries, spatial q4 parity, q4 diagnostics, Poisson/NB2 q1 structured-count candidates, user-route examples, and stale-claim checks; these remain planning slices and do not add new fitted model surfaces.
* The implementation-map roadmap now also records Slices 311-325 as design gates for generic structured direct-SD syntax, p8/q8 endpoint taxonomy, structured q=4 ordering, q=4 interval status, non-Gaussian structured-dependence candidate scoring, and user-route examples; these are planning slices, not new fitted likelihood claims.
* The implementation-map roadmap now records Slices 303-310 as planning and documentation gates rather than new likelihood work: generic `sd*()` design, p8/q8 location-scale planning, structured q=4 parity, q=4 interval policy, a no-fit decision for random effects in probability components such as `zi`, `hu`, `zoi`, and `coi`, a non-Gaussian structured-dependence candidate map, maintenance scans, and user-route guidance.
* The pkgdown site now includes an implementation map that separates fitted, first-slice, fixed-effect-only, planned, and blocked surfaces across families, random-effect layers, q, random slopes, `corpairs()`, `zi`, and `hu`, and uses it as the roadmap-facing ledger for future parity work.
* `biv_gaussian()` now fits the first ordinary bivariate random-slope covariance route: matching slope-only `mu1`/`mu2` blocks such as `(0 + x | p | id)` in both location formulas. The fitted slope-slope row appears in `sdpars$mu`, `corpars$mu`, `ranef()`, `corpairs()`, `summary()$covariance`, `profile_targets()`, and `check_drm()`; matching q=4 and q=6 `mu1`/`mu2` location blocks, same-response q2 location-scale slope covariance, and q8 all-endpoint covariance now have separate diagnostic artifact routes, while predictor-dependent slope `corpair()` regressions, q8 coverage/power evidence, and non-Gaussian structured slope covariance remain planned.
* The structural-dependence tutorial path now includes a focused coordinate-spatial page for fitted `spatial(coords = coords)` Gaussian `mu` intercept, residual-scale `sigma` intercept, one numeric `mu` slope, q=2 bivariate location-covariance, and constant q=4 location-scale routes. Historical note, superseded by the current 0.6.0 guidance: the q1 spatial `sigma` one-slope route now has point-fit/extractor evidence, although its interval gate remains blocked; mesh/SPDE inputs, additional multiple or labelled slope layouts outside the exact fitted ledger cells, direct spatial SD surfaces, spatial `corpair()` regressions, simultaneous phylo-plus-spatial layers, and non-Gaussian spatial effects outside the exact ordinary Poisson/NB2 q1 spatial `mu` intercept-plus-one-slope, recovery-grade NB2 q1 spatial `sigma`, Student-t spatial `mu`, Poisson spatial `zi`, fixed-`zi` Poisson spatial `mu`, and fixed-`zi` NB2 spatial `mu` gates remain planned.
* The structural-dependence tutorial path added a focused phylogenetic page for fitted Gaussian routes. Historical note, superseded in part by exact non-Gaussian gates: ordinary Poisson/NB2 q1 phylogenetic `mu` intercept-plus-one-slope, recovery-grade NB2 q1 phylogenetic `sigma`, Student-t q1 phylogenetic `nu`, and cumulative-logit q1 phylogenetic `mu` now fit at their recorded tiers; additional multiple or labelled slope layouts outside the exact fitted ledger cells, slope correlations, matrix-input phylogeny, combined phylo-plus-spatial layers, q4 `corpair()` regressions, and non-Gaussian phylogenetic neighbours outside those gates remain planned.
* The structural-dependence tutorial path now includes a focused `relmat()` page for fitted known-matrix Gaussian `mu` and `sigma` intercept slices, one-slope `mu` paths, matching q=2 bivariate location covariance, and constant q=4 location-scale covariance. Historical note, superseded by the current 0.6.0 guidance: the exact K/Q q1 `sigma` one-slope route is now fitted and inference-ready with caveats; broader bridge claims, additional multiple or labelled slope layouts outside the exact fitted ledger cells, slope correlations, predictor-dependent `corpair()` regression, and meta-analysis sampling covariance remain separate.
* The structural-dependence tutorial path now includes a focused animal-model page for the fitted `animal(pedigree/A/Ainv)` Gaussian `mu` and `sigma` intercept slices, one-slope `mu` paths, matching q=2 bivariate location covariance, and constant q=4 location-scale covariance. Historical note, superseded by the current 0.6.0 guidance: the exact A-matrix q1 `sigma` one-slope route is now fitted and inference-ready with caveats; pedigree/Ainv bridge marshalling, sparse pedigrees, additional multiple or labelled slope layouts outside the exact fitted ledger cells, slope correlations, and animal `corpair()` regression remain planned.
* The structural-dependence tutorial path now has a small overview article that helps readers choose between `animal()`, `phylo()`, coordinate `spatial()`, planned phylo-plus-spatial models, and `relmat()` before entering the longer technical tutorial.
* The figure gallery now shows spatial, animal, and `relmat()` q=2 fitted correlation rows beside residual `rho12`, ordinary group, and phylogenetic rows, and marks the constant spatial q=4 block as partly fitted beside still-planned structured correlation-regression and standalone scale extensions.
* `animal()` now fits a dense first pedigree route for Gaussian `mu` and `sigma` animal intercept effects: `animal(1 | id, pedigree = pedigree)` builds an additive relationship matrix from `id`, `dam`, and `sire` columns, one numeric `animal(1 + x | id, pedigree = pedigree)` `mu` slope fits as independent intercept and slope fields, and matching labelled `animal(1 | p | id, pedigree = pedigree)` terms work in the first bivariate q=2 location-covariance and constant q=4 location-scale paths. Historical note, superseded by the current 0.6.0 guidance: the exact A-matrix q1 `sigma` one-slope route is now fitted and inference-ready with caveats; pedigree/Ainv bridge marshalling, large-pedigree sparse precision construction, additional multiple or labelled structured-slope layouts outside the exact fitted ledger cells, slope correlations, predictor-dependent `corpair()` regressions, and generic direct-SD grammar remain planned (#147).
* `biv_gaussian()` now fits the first animal-model and lower-level relatedness q=2 known-matrix location covariance: matching `animal(1 | p | id, A = A)` / `animal(1 | p | id, Ainv = Ainv)` or `relmat(1 | p | id, K = K)` / `relmat(1 | p | id, Q = Q)` terms in `mu1` and `mu2`. The fitted rows appear in `sdpars$mu`, `corpars$animal` or `corpars$relmat`, `ranef("animal_mu")` or `ranef("relmat_mu")`, `corpairs()`, `summary()$covariance`, `profile_targets()`, and `check_drm()`. Historical note, superseded by the current 0.6.0 guidance: univariate Gaussian `sigma` intercepts, one numeric `mu` slope, and the exact A-matrix animal and K/Q relmat q1 `sigma` one-slope routes are fitted; the sigma slopes are inference-ready with caveats. Pedigree/Ainv bridge marshalling, additional multiple or labelled structured-slope layouts outside the exact fitted ledger cells, slope correlations, predictor-dependent `corpair()` regressions, and generic direct-SD grammar remain planned (#147).
* `biv_gaussian()` now also fits constant all-four q=4 animal-model and `relmat()` location-scale blocks when the same labelled known-matrix term appears in `mu1`, `mu2`, `sigma1`, and `sigma2`. These rows reuse the structured covariance backend and report four endpoint SDs and six derived latent correlations through `corpairs()`, `summary()$covariance`, `profile_targets()`, and `check_drm()`. Historical note, superseded by the current 0.6.0 guidance: exact q1 A-matrix animal and K/Q relmat `sigma` one-slope routes are now fitted and inference-ready with caveats; additional multiple or labelled structured-slope layouts outside the exact fitted ledger cells, slope correlations, predictor-dependent `corpair()` regressions, and direct-SD grammar remain planned (#147).
* The pkgdown workflow now builds the advertised single-site URL rather than publishing only the `dev/` subtree for development versions, so `https://itchyshin.github.io/drmTMB/` remains the public entry point.

# drmTMB 0.1.3 (2026-05-20)

* `animal()` and `relmat()` now fit the first known-relatedness Gaussian `mu` random-intercept slice: `animal(1 | id, A = A)`, `animal(1 | id, Ainv = Ainv)`, `relmat(1 | id, K = K)`, and `relmat(1 | id, Q = Q)`. The fitted latent scale appears in `sdpars$mu`, conditional effects appear in `ranef("animal_mu")` or `ranef("relmat_mu")`, direct scale targets appear in `profile_targets()`, and `check_drm()` reports replication and scale-ratio diagnostics. Historical note, superseded by current 0.6.0 evidence: one-slope `mu`, `sigma` intercept and exact q1 one-slope routes, and selected bivariate relatedness covariance are fitted where documented. Sparse large-pedigree construction, additional multiple or labelled structured-slope layouts outside the exact fitted ledger cells, broader covariance/bridge claims, and predictor-dependent `corpair()` regressions remain planned (#147).
* `biv_gaussian()` now fits the first coordinate-spatial q=2 `mu1`/`mu2` location covariance through matching `spatial(1 | p | site, coords = coords)` terms. The fitted spatial SDs appear in `sdpars$mu`, conditional fields in `ranef("spatial_mu")`, the spatial mean-mean row in `corpairs(level = "spatial")` and `summary()$covariance`, and direct SD/correlation targets in `profile_targets()`; mesh/SPDE, spatial `sigma`, spatial q=4, direct spatial SD surfaces, and predictor-dependent spatial `corpair()` regression remain planned (#5).

# drmTMB 0.1.2 (2026-05-16)

* `drm_control()` now has `optimizer_preset = "careful"` and `"robust"` for explicit `nlminb()` optimizer-budget presets. These expand to recorded `iter.max` and `eval.max` controls, keep the default fit fast, and can still be overridden with `optimizer = list(...)`.
* `drm_control()` now reserves fallback-optimizer control names such as `fallback_optimizer`, `fallback_optimizers`, and `optimizer_fallback` while documenting the future selected-optimizer provenance contract. Fallback BFGS or L-BFGS-B refits remain planned, not automatic.
* `drm_control()` now reserves warm-start control names such as `start_from`, `warm_start`, and `warm_start_from` so simpler-fit starts cannot be silently passed to `nlminb()` before the source-fit contract is implemented.
* Phase 18 private parametric-bootstrap helpers now accept serial or Unix `multicore` execution, cap actual workers at 10, and record requested versus actual core counts in bootstrap draw and interval tables; PSOCK remains excluded until fitted `TMB` object rebuilds are explicit.
* Phase 18 replicate execution now has a private bounded runner helper, with the Gaussian location-scale, `meta_V(V = V)`, Poisson and NB2 `mu` random-effect, Gaussian `mu` and `sigma` random-slope, coordinate spatial `mu` slope, Student-t shape, and bivariate residual `rho12` smoke surfaces wired through serial or Unix `multicore` execution capped at 10 workers; closure-heavy runners use a per-replicate summary factory to preserve profile and bootstrap seeds. Higher-level grid and count-gallery wrappers now forward runner settings, and Student-t shape plus bivariate residual `rho12` wrappers carry separate bootstrap backend settings with a guard against multicore replicate and multicore bootstrap layers running at the same time.
* The paired Poisson/NB2 `mu` random-effect Phase 18 lane now has a repeatable grid-output writer that saves aggregate, replicate, manifest, failure-ledger, Wald interval, Wald coverage, profile interval, and profile coverage CSV artifacts beside resumable per-replicate RDS files.
* The Phase 18 `meta_V(V = V)` lane now has a repeatable grid-output writer that saves aggregate, replicate, manifest, failure-ledger, Wald interval, and Wald coverage CSV artifacts beside resumable per-replicate RDS files.
* Phase 18 now also has repeatable simple grid-output writers for ordinary Gaussian `mu` random slopes, independent Gaussian `sigma` random slopes, and coordinate-spatial Gaussian `mu` slopes.
* Phase 18 grid writers now return an artifact manifest with path existence and CSV row counts, including zero-row handling for optional interval artifacts.
* Phase 18 artifact manifests can now be bound across grid-writer outputs and summarized by surface, giving report-staging code a compact check of present, missing, empty, and total CSV rows.
* Phase 18 first-wave report staging now has a private artifact-status writer that saves bound artifact-manifest and surface-status CSVs from multiple grid-writer outputs before a report reads the simulation tables.
* Phase 18 first-wave report staging now includes an artifact-status report template that reads the bound manifest and status CSVs first, renders a preflight page for complete outputs, and stops clearly when required artifacts are missing.
* Phase 18 first-wave report staging now has a private table-bundle writer that combines selected CSV artifacts across grid-writer outputs, preserving source surface and artifact names as leading columns while filling missing columns.
* Phase 18 first-wave report staging now includes a summary-report skeleton that reads artifact status, aggregate operating-characteristic rows, interval coverage, interval diagnostics, interval failures, manifests, and warning/error ledgers in one page, with priority columns, row caps, a compact aggregate-bias overview, compact interval-coverage summaries, run-manifest summaries, and compact warning/error summaries for table-first review.
* Phase 18 first-wave report staging now has a reusable private smoke runner that executes the Gaussian location-scale, `meta_V(V = V)`, paired Poisson/NB2 `mu` random-effect, ordinary Gaussian `mu` random-slope, ordinary Gaussian `sigma` random-slope, and coordinate-spatial Gaussian `mu` slope grid writers, stages the combined first-wave summary report, and records requested versus actual worker counts.
* Phase 18 interval-heavy report staging now has a separate private smoke runner for Student-t shape and bivariate residual `rho12` grid writers, keeping their Wald/profile/bootstrap interval artifacts separate from the baseline first-wave runner.
* Phase 18 first-wave report staging now has a render helper that writes artifact status, table bundles, and an optional HTML summary report from grid-writer outputs in one orchestration step.
* `check_drm()` now reports the largest fixed-gradient component label in the `fixed_gradient` diagnostic row, making non-converged or flat-surface fits easier to triage before Hessian or Wald inference is trusted.
* `biv_gaussian()` now fits multiple independent same-response labelled `mu`/`sigma` random-intercept covariance blocks in one two-response model, for example `mu1`/`sigma1` with label `p` and `mu2`/`sigma2` with label `q` plus residual `rho12`. `corpairs()`, `profile_targets()`, `summary()`, and `check_drm()` keep the two mean-scale rows separate from residual `rho12` and from same-parameter `mu1`/`mu2` or `sigma1`/`sigma2` blocks.
* Interval documentation now separates fitted-model Wald and profile intervals from Phase 18 Fisher-z simulation helpers, and tests confirm Student-t `nu` fixed-effect interval targets plus Fisher-z-scale correlation-helper output.
* `meta_V(V = V)` now has explicit full-matrix alias coverage with Wald fixed-effect interval checks, documentation points to it as the preferred known-covariance spelling, and `meta_V(V = V, scale = "exact")` now errors with guidance that the exact additive route is already selected by `meta_V(V = V)`.
* Bergmann-report follow-up now hardens invalid Wald standard-error rows, documents long-iteration triage, implements the labelled phylogenetic q4-to-two-q2 block-diagonal fallback, and records the Ayumi Mass + Beak fallback as a boundary/false-convergence diagnostic case. The earlier unsupported univariate `sigma ~ phylo(...)` boundary is now superseded by the fitted intercept-only structured `sigma` route described above.
* Structural-dependence docs now give a clearer user surface for planned `animal()` and `relmat()` models, including what fitted sensitivity model to use now and when a known matrix belongs to `meta_V(V = V)` instead of a future latent relatedness path.
* Structural-dependence design notes now separate dense covariance inputs (`A`, `K`) from sparse precision inputs (`Ainv`, `Q`) for future `animal()` and `relmat()` models, keeping large-pedigree or large-matrix speed claims blocked until sparse-precision recovery and scaling evidence exists.
* The family registry now has a Slice 283 family-and-parameter evidence map, listing each public family route, distributional-parameter link, shape or coscale slot, fitted random-effect allowance, and test evidence state before later count, proportion, shape, ordinal, or mixed-response hardening work expands those rows.
* Count-family tests now assert Wald fixed-effect interval rows for Poisson, NB2, zero-truncated NB2, zero-inflated Poisson, zero-inflated NB2, and hurdle NB2 dpars, and the count tutorial now names ordinary non-zero-inflated Poisson/NB2 `mu` random intercepts and independent slopes as the current fitted mixed-count route.
* Proportion-family tests now assert Wald fixed-effect interval rows for beta and beta-binomial `mu` and `sigma` coefficients, and the proportion tutorial now states that fixed-effect `beta()` and `beta_binomial()` plus ordinary unlabelled `mu` random intercepts and independent numeric slopes are fitted while zero-one inflation, correlated bounded-response random slopes, labelled covariance blocks, `sigma` random effects, and `meta_V(V = V)` bounded-response routes remain planned or blocked.
* Continuous-shape design notes now separate fitted fixed-effect Student-t `nu`, fitted fixed-effect skew-normal `nu`, planned skew-t `nu`/`tau`, and future latent-effect `skew(id) ~ ...`, keeping shape and skewness random effects out of Phase 18 simulation until likelihood, recovery, diagnostic, and interval evidence exists.
* Ordinal readiness docs recorded the original fixed-effect `cumulative_logit()` evidence ledger. Historical note, superseded in part by later ordinary `mu` intercept/slope recovery and an exact phylogenetic intercept gate: broader ordinal covariance and scale/discrimination formulas remain planned.
* Mixed-response bivariate family docs now keep Gaussian-count, Gaussian-proportion, count-proportion, ordinal mixed, and other two-response combinations planned until a joint likelihood or copula/latent-variable contract, prediction, simulation, extractors, intervals, examples, and comparator checks exist; tests cover mixed-family errors for `c()` and `list()` spellings.
* `corpairs()` now returns `conf.status` and `interval_source` columns by default, matching the prediction-table provenance contract. `plot_corpairs()` now draws finite bounds only when those columns mark a real interval source, so compatible pair tables cannot imply confidence intervals from bare numeric limits alone.
* User-facing docs now share a status vocabulary for stable, first slice, opt-in, planned or reserved, and unsupported or blocked surfaces across README, the model-map article, the package reference topic, getting-started article, source-map guidance, and pkgdown reference groups.
* The pre-simulation readiness matrix now includes a Slice 291 evidence-ledger gate: every public stable-core row is mapped to implementation evidence, tests or diagnostics, user-facing boundaries, and Phase 18 admission status before comprehensive simulation design can treat it as admitted.
* The Phase 18 simulation programme now has a Slice 292 comprehensive design map covering continuous, proportion, count, ordinal, meta-analysis, bivariate, random-slope, shape, phylogenetic, spatial, `animal()`, and `relmat()` lanes, while keeping planned or blocked lanes in the failure ledger instead of fitted grids.
* Phase 18 now has its first one-page ADEMP sheet for the admitted Gaussian location-scale lane, tying the existing `phase18_dgp_gaussian_ls()` helper to aims, DGP conditions, estimands, methods, performance measures, and Williams-style reporting checks before larger grids run.
* Phase 18 now has a one-page ADEMP sheet for the admitted Gaussian `meta_V(V = V)` lane, keeping known sampling covariance as input data and public residual `sigma` as the fitted heterogeneity estimand before vector or dense known-`V` grids expand.
* Phase 18 now has a one-page ADEMP sheet for the paired Poisson/NB2 `mu` random-effect lane, keeping the first count grid to ordinary non-zero-inflated `mu` random intercepts and independent numeric slopes while zero-inflated, hurdle, zero-truncated, structured, correlated-slope, and labelled covariance count models remain failure-ledger rows.
* Phase 18 now has a one-page ADEMP sheet for the fixed-effect proportion lane, separating strict continuous `beta()` responses from denominator-aware `beta_binomial()` success counts while keeping exact 0/1 boundary mass outside that earlier beta/beta-binomial artifact lane. Random effects beyond the beta and beta-binomial ordinary `mu` intercept/slope slices, structured effects, known sampling covariance, and mixed-response bounded models remain in the failure ledger.
* Phase 18 added a one-page ADEMP sheet for the fixed-effect ordinal lane. Historical note, superseded in part by later ordinary `mu` intercept/slope recovery and an exact phylogenetic intercept gate: correlated/labelled or other structured ordinal effects, scale/discrimination formulas, cutpoint-specific predictors, bivariate ordinal models, and mixed-response ordinal models remain in the failure ledger.
* Phase 18 now has a one-page ADEMP sheet for the bivariate Gaussian residual `rho12` lane, defining the response-specific mean and scale DGP, residual covariance matrix, response-scale `rho12` grids, and boundary diagnostics while keeping group-level `corpairs()`, structured correlations, known sampling covariance, random effects in `rho12`, mixed-response families, and bivariate random-slope covariance in separate design or failure-ledger lanes.
* Broader bivariate random-slope combination boundaries now have focused error coverage for unsupported residual-scale slope variants, cross-response or coefficient-mismatched same-response location-scale slope combinations, and all-four q=8-style slope requests while the matching q2 `sigma1`/`sigma2` scale-slope route is fitted separately.
* Structured random-slope boundaries now have parser and fit-time audit coverage:
  one-slope `animal()` and `relmat()` markers are readable as planned grammar,
  and multiple structured slopes are rejected. Only coordinate spatial Gaussian
  `mu` one-slope models are fitted for Phase 18 admission.
* Shape and inflation random-effect boundaries now have random-slope-specific test coverage: Student-t `nu`, zero-inflation `zi`, hurdle `hu`, and planned bounded-response `zoi`/`coi` random slopes still error before fitting, so Phase 18 will not treat those paths as implemented.
* Gaussian `sigma` random-effect documentation now states the independent residual-scale slope boundary more explicitly: separate terms such as `sigma ~ z + (0 + w_id | id) + (0 + w_site | site)` are fitted with direct `log_sd_sigma` profile targets. Historical note, superseded by the current 0.6.0 guidance: unlabelled ordinary correlated blocks such as `(1 + x | id)` are now fitted; labelled residual-scale slope covariance remains planned.
* Ordinary Gaussian `mu` random-slope documentation now states the q > 2 boundary more explicitly: multi-slope blocks such as `(1 + x1 + x2 + x3 | id)` are fitted, their SDs are direct profile targets, and their block correlations are derived-unavailable for direct profile intervals until a dedicated interval method exists.
* Phase 18 now has a pre-simulation capability audit table that records implemented, tested, planned, and unsupported status for Gaussian, non-Gaussian, shape, inflation, bivariate, random-slope, meta-analysis, phylogenetic, spatial, animal, and `relmat()` model classes before broad simulation grids admit them.
* Phase 18 now has an optional resumable replicate runner under `inst/sim/` that captures warnings, errors, elapsed time, session metadata, and optional RDS output for pilot simulation cells.
* Phase 18 now has a Simulation & Comparison plot-grammar article for bias, RMSE, coverage, power, convergence, runtime, and warning/error ledgers across continuous, proportion, count, and meta-analysis examples.
* `plot_corpairs()` now has a `label` argument so publication figures can use short row labels while keeping full correlation metadata in the source table.
* Phase 18 replicate results can now be reduced to a warning/error failure ledger so failed fits and warning-bearing replicates remain visible beside aggregate summaries.
* Phase 18 saved replicate directories can now be reloaded into result lists, allowing manifests and failure ledgers to be rebuilt from RDS output after a resumable simulation run.
* Phase 18 simulation results can now be reduced to a compact manifest table with cell id, replicate, seed, status, skipped/resumed flag, warning count, error message, and elapsed time.
* Phase 18 summary-smoke helpers now return run manifests and warning/error ledgers beside aggregate bias, RMSE, and MCSE tables.
* Developer design notes now include ASReml efficiency lessons for future `animal()` and `relmat()` work, emphasizing sparse precision matrices, explicit row-name matching, matrix-orientation metadata, and honest speed claims.
* `nbinom2()` now supports ordinary non-zero-inflated `mu` random intercepts and independent numeric random slopes such as `bf(count ~ x + (1 | id) + (0 + x | id), sigma ~ z)`. The fitted SDs appear in `sdpars$mu`, `random_effects$mu`, and direct `profile_targets()` rows. Historical note, superseded by current 0.6.0 evidence: NB2 q1 structured `sigma` intercept-plus-one-slope routes for phylo/spatial/animal/relmat now have recovery-grade point-fit evidence, and one exact fixed-`zi` NB2 `mu ~ spatial()` intercept is diagnostic-only. Correlated or labelled NB2 `mu` slopes, joint `mu`/`sigma` random effects, ordinary NB2 `sigma` slopes, structured sigma intervals/coverage or richer blocks, and zero-inflated NB2 random effects outside that exact diagnostic gate remain planned.
* Phase 18 now includes a smoke simulation report template under `inst/sim/reports/`, giving pilot surfaces a reader-facing structure for purpose, aggregate summaries, reader checks, and interpretation boundaries.
* Phase 18 now has a Gaussian `mu` q=3 random-slope smoke surface under `inst/sim/`, covering seeded data generation, `drmTMB()` fitting for `(1 + x1 + x2 | id)`, parameter summaries, aggregate output, manifests, and failure ledgers.
* Phase 18 now has a Gaussian `sigma` independent random-slope smoke surface under `inst/sim/`, covering seeded data generation, `drmTMB()` fitting for `sigma ~ z + (0 + w | id)`, parameter summaries, aggregate output, manifests, and failure ledgers.
* Phase 18 now has a structured-slope parity gate: coordinate spatial one-slope Gaussian `mu` models are fitted enough for focused smoke grids, while phylogenetic, animal, and `relmat()` one-slope models remain planned until their implementation, diagnostics, profile targets, recovery tests, and biological examples exist.
* Phase 18 now has a cross-distributional-parameter correlation gate: residual `rho12`, constant fitted random-effect block correlations, predictor-dependent q=2 `corpair()` routes, and known sampling covariance `V` remain separate layers, while non-Gaussian, slope-level, shape, inflation, hurdle, one-inflation, and `rho12` random-effect covariance surfaces stay outside Wave A until focused gates close.
* Phase 18 now has a coordinate spatial Gaussian `mu` one-slope smoke surface under `inst/sim/`, covering seeded data generation, `drmTMB()` fitting for `spatial(1 + x | site, coords = coords)`, parameter summaries, aggregate output, manifests, and failure ledgers.
* Phase 18 now has a non-zero-inflated Poisson `mu` random-effect smoke surface under `inst/sim/`, covering seeded data generation, `drmTMB()` fitting for `(1 | id) + (0 + x | id)`, parameter summaries, aggregate output, manifests, and failure ledgers.
* Phase 18 non-zero-inflated Poisson `mu` random-effect smoke output now includes Wald interval rows and coverage summaries for fixed log-mean coefficients, while random-effect SD rows remain visible as missing-SE interval rows until profile producers are attached.
* Phase 18 non-zero-inflated Poisson `mu` random-effect smoke output now includes direct profile-likelihood interval rows and coverage summaries for the fitted random-intercept and independent random-slope SD targets.
* Phase 18 now has a non-zero-inflated NB2 `mu` random-effect smoke surface under `inst/sim/`, covering seeded data generation, `drmTMB()` fitting for `(1 | id) + (0 + x | id)` with fixed-effect `sigma ~ z` overdispersion, parameter summaries, aggregate output, manifests, and failure ledgers.
* Phase 18 non-zero-inflated NB2 `mu` random-effect smoke output now includes Wald interval rows and coverage summaries for fixed log-mean and log-overdispersion coefficients, while random-effect SD rows remain visible as missing-SE interval rows until profile producers are attached.
* Phase 18 non-zero-inflated NB2 `mu` random-effect smoke output now includes direct profile-likelihood interval rows and coverage summaries for the fitted random-intercept and independent random-slope SD targets.
* NB2 `mu` random effects now have a focused weak-SD boundary diagnostic test, exercising `check_drm()` lower-boundary reporting for a near-zero fitted random-intercept SD before larger Phase 18 grids vary the true SD.
* Phase 18 Poisson and NB2 `mu` random-effect condition helpers now build true crossed condition grids, including random-effect SDs and, for NB2, overdispersion settings.
* Phase 18 now has a paired count-family `mu` random-effect pilot helper that combines ready Poisson and NB2 surfaces into one optional aggregate, manifest, failure-ledger, Wald-coverage, and profile-coverage output.
* Phase 18 now has a plot-data helper for paired Poisson/NB2 `mu` random-effect pilot outputs, preparing aggregate, coverage, manifest, and failure tables for later figure-gallery work.
* Phase 18 now has a count-pilot figure-gallery report template for bias, RMSE, interval coverage, manifests, and warning/error ledgers from paired Poisson/NB2 `mu` random-effect pilots.
* Phase 18 now has count-pilot gallery helper plumbing that writes plot-ready CSV inputs and renders a checked local HTML gallery artifact from a paired Poisson/NB2 `mu` random-effect pilot object.
* Phase 18 now has an end-to-end count-gallery smoke runner that executes a tiny paired Poisson/NB2 `mu` random-effect pilot and renders the Florence-facing HTML gallery from the resulting tables.
* The Phase 18 count-pilot gallery now has a first Florence visual-polish pass, with horizontal estimand labels, shared palette/theme helpers, captions, and MCSE-aware coverage ranges when available.
* The figure gallery now has a Florence visual-repair pass: inference summaries render as Confidence Eye displays where finite interval bounds are available, tutorial plots share explicit palettes, discrete comparison and empirical marginal displays no longer fall back to default black styling, status-strip labels have better contrast, and simulation coverage/power examples show replicate-block proportions plus aggregate binomial MCSE intervals instead of treating simulation uncertainty as required Confidence Eyes.
* The Simulation & Comparison plot-grammar article now carries the raincloud lesson into the Phase 18 simulation lane: bias displays show replicate-level errors plus mean/MCSE intervals in fixed surface facets, while RMSE keeps a separate aggregate point/MCSE panel instead of being visually collapsed with signed bias or mistaken for a mean absolute-error cloud.
* The Phase 18 count-pilot gallery now follows the same accuracy-display contract: bias and RMSE use fixed family facets, show MCSE intervals when available, and explain that replicate-error clouds require replicate-level output rather than aggregate CSVs alone.
* The figure gallery now keeps correlation layers visually separate, with faceted residual `rho12`, ordinary group, and phylogenetic `corpairs()`-style rows plus status-strip boundaries for structured-effect layers that were not yet fitted at the time of 0.1.3.
* The figure gallery now includes a source-map table that maps each display to its fitted object or fixture, extractor or plotter, interval source, and current support boundary.
* The figure gallery now shows the supported fixed-effect univariate `mu` `emmeans` route, including factor-conditioned and interaction grids, an empirical `marginal_parameters()` summary, and unsupported boundaries for non-`mu` or blocked `emmeans` targets.
* The figure gallery now separates residual `sigma`, ordinary group-level SDs, conditional random-slope deviations, and fitted `sd(site)` surfaces, with unavailable random-effect SD intervals shown as an explicit plotting boundary.
* The visualization grammar now records the Florence closeout: `plot_parameter_surface()` and `plot_corpairs()` remain the exported helpers, most gallery-specific displays stay as `ggplot2` recipes, and simulation or failure-ledger helpers wait for stable Phase 18 result schemas.
* The figure gallery now includes distributional-parameter panels for `mu`, `sigma`, Student-t `nu`, zero-inflation probability `zi`, and residual `rho12`, with explicit response-scale labels and interval provenance.
* The pkgdown site now includes a user-facing figure gallery for model interpretation plots, confidence bands, correlation displays, random-effect scale surfaces, and simulation operating-characteristic figures.
* The pkgdown site now includes an improving-convergence guide explaining when the default optimizer budget is enough, how to use `drm_control(optimizer = ...)`, how to interpret `check_drm()` rows, and when to separate optimization from Wald uncertainty with `se = FALSE`. The guide now also separates residual `rho12`, phylogenetic mean-mean, and ordinary group-level correlation boundaries for bivariate structured fits, and warns that larger data sets help only when they add information that separates those covariance layers.
* Phase 18 now has a pre-simulation readiness matrix that separates fitted, smoke-tested, interval-ready, weak-boundary-tested, planned, and blocked surfaces before broad simulation reports are written.
* Phase 18 now has a `meta_V(V = V)` summary-smoke runner that executes vector and dense known-covariance pilot replicates and returns grouped bias, RMSE, and Monte Carlo error summaries.
* Phase 18 now has a Gaussian location-scale summary-smoke runner that executes two or more pilot replicates and returns grouped bias, RMSE, and Monte Carlo error summaries from the smoke output.
* Phase 18 now has Monte Carlo uncertainty helpers for simulation summaries, including MCSEs for mean error, RMSE, proportions, and explicit interval-coverage summaries when lower and upper interval columns are present.
* Phase 18 now has a synthetic interval-coverage smoke helper for testing coverage-table plumbing before Wald, profile, or bootstrap interval methods are attached.
* Phase 18 smoke reports can now display optional aggregate, manifest, and warning/error ledger CSVs while still rendering when those files are not supplied.
* Phase 18 smoke report rendering is now covered by a skip-aware test with tiny aggregate, manifest, and warning/error ledger CSV fixtures.
* Phase 18 interval work now has a producer contract for Wald, profile, and bootstrap interval tables, including reported scale, method, status, and correlation-scale rules.
* Phase 18 now has a Fisher-z back-transformed Wald interval helper for correlation summaries, complementing raw-correlation Wald intervals from the generic helper.
* Phase 18 now has a generic Wald interval-table helper for parameter summaries that already contain estimates and standard errors, recording interval method, reported scale, status, and failure messages.
* Phase 18 now has a small aggregation helper for simulation parameter summaries, reporting replicate counts, bias, RMSE, absolute error, empirical standard error, convergence rate, Hessian rate, warning rate, and elapsed time by explicit grouping columns.
* Phase 18 now has a first end-to-end `meta_V(V = V)` smoke runner under `inst/sim/run/`, covering vector and dense known sampling covariance cells through DGP, `drmTMB()` fit, saved RDS output, and combined parameter summaries.
* Phase 18 `meta_V(V = V)` pilot summaries now carry standard errors for estimated `mu` coefficients and response-scale fitted residual `sigma`, while keeping known sampling covariance `V` out of interval targets.
* Phase 18 `meta_V(V = V)` summary-smoke output now includes Wald interval rows and coverage summaries for estimated `mu` coefficients and fitted residual `sigma`.
* Phase 18 now has a first end-to-end Gaussian location-scale smoke runner under `inst/sim/run/`, wiring the cell registry, seeded DGP, `drmTMB()` fit, pilot summariser, saved RDS output, and combined parameter table for one small surface.
* Phase 18 Gaussian location-scale pilot summaries now carry fixed-effect standard errors when the fitted model exposes them, preparing that surface for real Wald interval coverage checks.
* Phase 18 Gaussian location-scale summary-smoke output now includes formula-coefficient Wald interval rows and coverage summaries.
* Phase 18 now has a Gaussian meta-analysis `meta_V(V = V)` simulation pilot covering vector and dense known sampling covariance, including smoke tests that keep known `V` out of interval targets.
* Phase 18 now has a Gaussian location-scale simulation pilot: optional `inst/sim/` helpers generate `mu ~ x`, `sigma ~ z` data and summarise one fitted model into a truth/estimate/error table.
* Phase 18 now has an optional `inst/sim/` skeleton with reproducible seed-table and cell-registry helpers plus a CRAN-safe smoke test for simulation-run bookkeeping.
* Phase 18 now has an ADEMP-style simulation-programme blueprint in `docs/design/41-phase-18-simulation-programme.md`, including first-wave surfaces, estimands, methods, performance measures with Monte Carlo uncertainty, and the next three implementation slices.
* The meta-analysis tutorial and design examples now use `meta_V(V = V)` as the preferred known sampling covariance spelling, with `meta_known_V(V = V)` described only as a compatibility alias.
* `meta_V()` interval safety is now tested for Gaussian meta-analysis fits: `profile_targets()` keeps estimated `sigma`, random-effect SD, and bivariate `rho12` targets visible while never treating known sampling covariance `V` as an estimated confidence-interval target.
* `meta_V()` now gives a clearer reserved-boundary error for proportional sampling-variance arguments such as `meta_V(w = w, scale = "proportional")`, `meta_V(w = w)`, or `meta_V(V = V, scale = "exact")`. Diagonal/vector `meta_V(V = V)` can still use ordinary likelihood weights, while full matrix-`V` fits reject non-unit weights until joint-block weighting has a separate design.
* `meta_V(V = V)` is now accepted as the preferred additive known sampling covariance marker for Gaussian meta-analysis, routing to the same likelihood path as `meta_known_V(V = V)`. The proportional branch `meta_V(w = w, scale = "proportional")` remains deliberately unimplemented and errors before fitting.
* Slice 204 now records the `meta_V()` API decision: the preferred additive known-covariance spelling is `meta_V(V = V)`, without a positional response/value argument, and `meta_known_V(V = V)` is retained as a compatibility alias rather than a separate likelihood path.
* Slice 203 now records the post-202 Phase 17 return block for meta-analysis hardening. The next targets are the preferred `meta_V(V = V)` spelling and compatibility story, additive vector/matrix known `V`, proportional-variance design boundaries, interval safety, and reader examples.
* The Slice 202 pre-simulation gate now keeps broad Phase 18 comprehensive simulation closed until the post-202 Phase 17 hardening block is complete. A narrow Poisson `mu` random-effect pilot simulation is allowed, but meta-analysis hardening around `meta_V()`/known `V`, interval safety, and reader-facing examples should come before broad simulation claims.
* Focused Poisson random-effect recovery added a factor-predictor random-intercept case and a weak-SD boundary case. Historical note, superseded by later NB2, ordinal, and exact row-specific structured/component gates: this entry establishes only the ordinary Poisson `mu` path and does not define the current class-wide boundary.
* The validation-debt register now contains a Slice 201 non-Gaussian failure ledger. It names the convergence, boundary, identifiability, interval, and runtime risks that Phase 18 should measure or exclude before broad simulation claims are made.
* `animal()` and `relmat()` are now exported and documented as planned structured-effect markers, giving the reference index the intended animal -> phylo -> spatial -> lower-level known-dependence path while keeping `gr()` as a reserved legacy marker. These markers are parsed for roadmap examples and rejected by `drmTMB()` until fitted likelihood, diagnostics, profile-target, and recovery-test evidence exists (#147).
* `summary(conf.int = TRUE)` now handles fitted non-Gaussian models whose summary has no parameter rows to receive intervals, including cumulative-logit ordinal models. Wald fixed-effect intervals are still reported where fixed effects exist, and empty coefficient or parameter tables keep explicit interval-status columns instead of erroring.
* The model map, family chooser, and structural-dependence article now teach the structural-dependence ladder in biological order: `animal()`, `phylo()`, `spatial()`, combined phylogenetic-plus-spatial models, and lower-level `relmat()` known-dependence matrices. The same pages keep the non-Gaussian random-effect boundary visible before the comprehensive simulation phase.
* Shape random effects now have a dedicated unsupported-boundary message and Student-t test gate. Current Student-t `nu` formulas remain fixed-effect tail-shape models outside the exact Q-Series `nu ~ phylo(1 | id, tree = tree)` local-fit gate; skew-normal fixed-effect `nu` models residual slant, while skew-normal and skew-t shape random effects need separate likelihood recovery before `nu`/`tau` random effects or ID-level `skew(id) ~ x` style models are added.
* Poisson `mu` now supports ordinary unlabelled random intercepts and independent numeric random slopes for non-zero-inflated Poisson models, such as `(1 | group)` and `(0 + x | group)` on the log-mean predictor. The fitted SDs appear in `sdpars$mu`, `ranef()`/`random_effects$mu`, and `profile_targets()` as direct `log_sd_mu` targets; correlated Poisson random-slope blocks, labelled covariance blocks, zero-inflated Poisson random effects, and cross-parameter non-Gaussian covariance remain planned.
* Non-Gaussian `sigma` random effects have family-specific gates. Ordinary NB2, lognormal, and Gamma admit one independent log-`sigma` random intercept; Student-t, beta, beta-binomial, truncated NB2, and hurdle NB2 remain fixed-effect only. Slopes, labelled or combined scale effects, and structured scale effects still require likelihood, recovery, extractor, interval, and documentation evidence before fitting.
* Bivariate random-slope boundary errors now distinguish the fitted slope-only `mu1`/`mu2` target, the fitted matching q=2 `sigma1`/`sigma2` scale-slope target, the fitted same-response q2 `mu`/`sigma` slope target, the smoke-artifact-routed q=4 and q=6 location-only targets, the diagnostic-artifact-routed first q8 all-endpoint target, and broader p8/q8 endpoint variants that remain closed.
* Gaussian location random-slope blocks now support ordinary unstructured numeric multi-slope `mu` terms such as `(1 + x1 + x2 | id)` and labelled variants. The first public path has q=3 recovery, `sdpars$mu`, `corpars$re_cov`, `corpairs()`, `summary()`, and `profile_targets()` coverage; larger q blocks are advanced fits whose sample-size cost remains a simulation target.
* Gaussian location-scale models now fit more than one independent matched labelled `mu`/`sigma` random-intercept covariance block, for example matching `(1 | p | id)` and `(1 | q | site)` terms in both formulas. Each block reports its own `corpars$mu_sigma`, `corpairs(class = "mean-scale")`, `summary()`, and `profile_targets()` row.
* `check_drm()` and profile-interval tests now cover two independent univariate `mu`/`sigma` random-intercept covariance blocks, reporting one diagnostic row per mean-scale block and confirming the second `eta_cor_mu_sigma` profile target.
* Gaussian residual-scale random slopes now have an explicit multiple-independent-term boundary: `sigma ~ z + (1 | id) + (0 + w1 | id) + (0 + w2 | id)` fits separate log-`sigma` random-effect SDs with correlations fixed at zero. Historical note, superseded by the current 0.6.0 guidance: unlabelled ordinary correlated blocks such as `(1 + x | id)` and multi-slope variants are now fitted; labelled residual-scale slope covariance and cross-formula `mu`-`sigma` slope covariance remain planned.
* The earlier phylogenetic random-slope boundary was superseded by the structured-slope parity slices: `phylo(1 + x | species, tree = tree)` now fits one univariate Gaussian `mu` slope as an independent intercept and slope field. Historical note, superseded again by the current 0.6.0 guidance: the exact q1 phylogenetic `sigma` one-slope route is fitted and inference-ready with caveats; additional multiple or labelled phylogenetic-slope layouts outside the exact fitted ledger cells and structured slope correlations remain planned.
* Random-effect planning now includes a one-slope-per-layer gate before the non-Gaussian revisit, separating fitted ordinary Gaussian `mu`, Gaussian `sigma`, univariate mean-scale, bivariate intercept, phylogenetic intercept, and coordinate-spatial one-slope surfaces from the remaining Gaussian double-hierarchical limits.
* Spatial one-slope coverage now confirms a profile-likelihood interval for the coordinate-spatial `mu` slope-field SD. Historical note, superseded by the current 0.6.0 guidance: the q1 spatial `sigma` one-slope route now has point-fit/extractor evidence, but its interval gate remains blocked; additional multiple or labelled spatial-slope layouts outside the exact fitted ledger cells and spatial slope correlations remain planned.
* The double-hierarchical endpoint map now reflects the current Gaussian boundary after the random-slope gate: q > 2 ordinary `mu`, independent `sigma` slopes, multiple univariate mean-scale intercept blocks, coordinate-spatial one-slope support, matching bivariate q=4/q=6 location smoke routes, the matching bivariate q=2 scale-slope route, the first same-response q2 `mu`/`sigma` slope route, and the first q8 all-endpoint route are fitted, while q8 coverage/power evidence and spatial q=4 covariance surfaces remain planned.
* Non-Gaussian random-effect planning now has a first `mu` random-intercept gate: Poisson and NB2-style count likelihoods are the first candidates, while continuous, bounded, ordinal, zero-inflation, hurdle, shape, and structured non-Gaussian random-effect paths keep explicit unsupported messages until their recovery tests exist.
* `emmeans::emmeans()` now supports the first narrow `drmTMB` path: fixed-effect univariate `mu` estimated marginal means with retained model frames and fixed-effect covariance available. Generic `emmeans` pairwise contrasts on that returned `mu` grid are covered by a small parity test.
* The public `emmeans::emmeans()` boundary tests now confirm that transformed-response formulas such as `log(y) ~ x` error before an `emmGrid` is returned, keeping the first bridge limited to untransformed response formulas and explicit transformed-scale prediction tables through `prediction_grid()`.
* The public `emmeans::emmeans()` boundary tests now confirm that bivariate Gaussian fits error with the unsupported `"biv_gaussian"` model type before an `emmGrid` is returned, instead of falling through to a generic missing-`mu` message.
* The public `emmeans::emmeans()` boundary tests now confirm that cumulative-logit ordinal fits still error before an `emmGrid` is returned, with guidance toward `prediction_grid()` and `predict_parameters()` for explicit prediction tables.
* The public `emmeans::emmeans()` boundary tests now confirm that hurdle NB2 fits still error before an `emmGrid` is returned, with guidance toward `prediction_grid()` and `predict_parameters()` for explicit prediction tables.
* The public `emmeans::emmeans()` boundary tests now confirm that zero-inflated NB2 fits error with the unsupported `"zi_nbinom2"` model type before an `emmGrid` is returned, matching the existing zero-inflated Poisson boundary.
* The public `emmeans::emmeans()` boundary tests now confirm that zero-inflated Poisson fits still error before an `emmGrid` is returned, with guidance toward `prediction_grid()` and `predict_parameters()` for explicit prediction tables.
* The fixed-effect univariate `mu` `emmeans::emmeans()` path now explicitly checks the `type = "response"` argument path, so response-scale EMMs requested directly from `emmeans()` must match `predict(dpar = "mu", type = "response")`.
* Fixed-effect prediction matrices and the first univariate `mu` `emmeans::emmeans()` bridge now preserve fitted ordered-factor coding when `newdata` or an `emmeans` reference grid supplies the same levels as an ordinary factor, so ordered polynomial columns still align with fitted coefficients.
* Fixed-effect prediction matrices now accept character `newdata` values for fitted factor levels, ignore unused factor columns, and reject unknown or missing factor levels with a clear predictor-specific error before model-matrix construction.
* Fixed-effect prediction matrices now validate that `newdata` supplies every predictor required by the requested distributional parameter and that required predictor values are complete before model-matrix construction.
* Fixed-effect prediction matrices now reject non-finite numeric values such as `Inf` in required predictors before model-matrix construction.
* Fixed-effect prediction matrices now reject `newdata` values that produce non-finite transformed-predictor columns, such as `log(size)` when `size = 0`, before returning a non-finite prediction.
* `marginal_parameters()` and `predict_parameters()` now have explicit coverage for fitted random-effect scale model names such as `sd(id)`, returning the `random-effect-sd-model` component, preserving row labels in long prediction tables, and averaging supplied direct-SD rows in marginal summaries.
* `prediction_grid()` now has explicit integration coverage for fitted direct-SD predictors: grids over predictors such as `w` in `sd(id) ~ w` can feed `predict_parameters(..., dpar = "sd(id)")` and `marginal_parameters(..., by = "w")`.
* Random-effect scale predictions now accept character `newdata` values for fitted `sd(group)` factor levels and reject unknown levels with a predictor-specific error before random-effect scale model-matrix construction.
* Random-effect scale predictions now have explicit boundary coverage for `newdata` containers: non-data-frame inputs error, while zero-row data frames return named length-zero numeric vectors on both link and response scales.
* Random-effect scale predictions now have explicit coverage that multi-row `newdata` returns one value per supplied row, preserves `rownames(newdata)`, uses response scale by default, and matches `exp(link)` when compared with `type = "link"`.
* Random-effect scale predictions now have explicit multiple-target coverage: when a fit includes formulas such as `sd(id) ~ w_id` and `sd(site) ~ w_site`, each requested `dpar` validates its own required predictors, ignores sibling-target extras, and names the missing target-specific predictor.
* Random-effect scale predictions now validate the raw predictors required by `sd(group)` formulas in supplied `newdata`, so missing columns, missing values, and non-finite numeric values error before random-effect scale model-matrix construction.
* Random-effect scale predictions such as `predict(fit, dpar = "sd(id)", newdata = ...)` now reject `newdata` values that produce non-finite transformed-predictor columns, such as `log(w_pos)` when `w_pos = 0`, before returning an infinite link- or response-scale SD prediction.
* The fixed-effect univariate `mu` `emmeans::emmeans()` path now explicitly checks factor-conditioned reference grids such as `emmeans(fit, ~ habitat | season, at = list(x = 0.25))`, so conditional EMM rows must match `predict(dpar = "mu")` with the same factor levels.
* The fixed-effect univariate `mu` `emmeans::emmeans()` path now explicitly checks interaction formulas such as `habitat * x` on an explicit reference grid, so conditional EMMs must match `predict(dpar = "mu")` at the same interaction design point.
* The fixed-effect univariate `mu` `emmeans::emmeans()` path now explicitly checks multiple numeric `at` values, so conditional grids such as `emmeans(fit, ~ habitat | x, at = list(x = c(-0.25, 0.75)))` must match row-wise `predict(dpar = "mu")` on the same grid.
* The fixed-effect univariate `mu` `emmeans::emmeans()` path now explicitly checks `cov.reduce = FALSE`, so EMMs that average over unreduced numeric covariate levels must match `predict(dpar = "mu")` averaged over the same reference grid.
* The fixed-effect univariate `mu` `emmeans::emmeans()` path now explicitly checks custom numeric covariate reduction, so `cov.reduce = stats::median` must move the reference grid to `median(x)` rather than the default mean.
* The fixed-effect univariate `mu` `emmeans::emmeans()` path now explicitly checks the default numeric covariate-reduction rule, so `emmeans(fit, ~ habitat)` must match `predict(dpar = "mu")` at the mean of the numeric covariate used by the reference grid.
* The fixed-effect univariate `mu` `emmeans::emmeans()` path now has explicit parity coverage for formulas with `offset(log(exposure))`, so exposure-adjusted count-rate grids must match `predict(dpar = "mu")` on both link and response scales.
* The fixed-effect univariate `mu` `emmeans::emmeans()` path now has explicit recover-data coverage for transformed predictors such as `log(size)`, so reference grids supplied through `at` are checked against `predict(dpar = "mu")`.
* Bivariate, zero-inflated, hurdle, ordinal expected-score, random-effect,
  structured-effect, non-`mu`, slope, and interval-specialized `emmeans`
  targets still error before an `emmGrid` is returned.
* The model-workflow article now shows the first optional `emmeans::emmeans()` example for fixed-effect univariate `mu`, keeping adjusted means separate from `predict_parameters()` tables and from unsupported `sigma`, random-effect, bivariate, zero-inflated, hurdle, ordinal, and slope workflows. Broader drmTMB-specific contrast helpers remain a separate future contract.
* The model-workflow article now shows how to build an explicit `prediction_grid()` for a fitted random-effect scale model such as `sd(site) ~ reef_cover`, then pass that grid through `predict_parameters(..., dpar = "sd(site)")` and `marginal_parameters(..., by = "reef_cover")` without treating random-effect SDs as residual `sigma` or raw responses.
* The model-map article now routes fitted random-effect SD surfaces through `prediction_grid()`, `predict_parameters(..., dpar = "sd(group)")`, and `marginal_parameters()`, with the `random-effect-sd-model` component kept separate from residual `sigma`.
* `predict_parameters(conf.int = TRUE)` now adds Wald fixed-effect confidence
  intervals for supplied `newdata` grids when the requested distributional
  parameter has an ordinary fixed-effect basis. The table fills `std.error`,
  `conf.low`, `conf.high`, `conf.level`, `conf.status = "wald"`, and
  `interval_source = "wald"` for supported rows, while fitted-row requests and
  direct random-effect scale models keep explicit unavailable interval status.
* Installation docs now point tagged-preview users to `pak::pak("itchyshin/drmTMB@v0.1.2")`.
* `docs/design/39-visualization-grammar.md` now records the Phase 17
  visualization and marginal-effects research contract. The note uses
  `ggplot2`, `tidybayes`, `ggdist`, `emmeans`, `ggeffects`,
  `marginaleffects`, diagnostic plotting packages, and figure-composition
  tools as design sources while keeping `drmTMB` data-first and
  dependency-light. The model-workflow article now states that
  `predict_parameters()` and `marginal_parameters()` are data tables that
  plotting helpers can consume, not plotters themselves.
* `plot_corpairs()` now provides the first optional `ggplot2` display for explicit `corpairs()` tables. It draws one point per fitted correlation row, adds interval segments only when finite `conf.low` and `conf.high` bounds have supported interval provenance, can facet by a supplied table column such as `level`, and keeps correlation `level`, `class`, display interval status, and interval source attached to the plotted data.
* `plot_parameter_surface()` now provides the first optional `ggplot2` plotting
  helper for long tables returned by `predict_parameters()`. It plots existing
  point estimates, keeps interval provenance columns attached to the data, and
  leaves EMMs, contrasts, and slope plots for later tested helpers.
* `plot_parameter_surface()` now draws confidence bands for continuous x-values
  and interval bars for discrete x-values when the supplied table already
  contains finite `conf.low` and `conf.high` bounds with real `conf.status` and
  `interval_source` provenance. It still does not compute confidence intervals,
  and rows with `interval_source = "not_available"` remain visibly
  interval-free.
* The model-workflow and model-map articles now show prediction-surface
  confidence bands as a table-first workflow:
  `prediction_grid()` -> `predict_parameters(conf.int = TRUE)` ->
  `plot_parameter_surface()`, with `conf.status`, `conf.level`, and
  `interval_source` left visible.
* `plot_parameter_surface()` now labels single-parameter panels with the fitted distributional parameter and prediction scale, such as `sigma estimate (response scale)`, while keeping the generic `Estimate` label when multiple parameters are plotted together.
* `prediction_grid()` now builds explicit `newdata` grids for
  `predict_parameters()` and `marginal_parameters()`. The first contract
  supports focal predictors, supplied values, conditioned nuisance predictors,
  mean-reference grids, and empirical counterfactual grids while recording the
  grid rule as metadata.
* The bivariate-coscale tutorial now shows a fitted `corpairs()` table flowing into `plot_corpairs(..., facet = "level")`, separating residual `rho12` from group-level correlation rows in the displayed workflow.
* `docs/design/39-visualization-grammar.md` now records the pre-export contract that `plot_corpairs()` follows: consume explicit `corpairs()` tables, keep correlation levels/classes visible, draw intervals only from finite confidence bounds with supported provenance, and test residual, ordinary group-level, phylogenetic, derived-unavailable, empty-table, and missing-`ggplot2` cases before export.
* The model-map article now includes a Phase 17 visualization decision table that routes raw responses, fitted parameter surfaces, empirical marginal summaries, correlations, interval tables, and diagnostics to the current data helpers before readers choose a plotting style.
* The Reference index now makes the post-fit path explicit: fitting, checking, summaries, predictions, uncertainty, and extractors are grouped under "Model fitting and post-fit tools", while exported plotting helpers appear under "Visualization". The current exported plotting helpers are `plot_parameter_surface()` and `plot_corpairs()`.
* `predict_parameters()` and `marginal_parameters()` now include interval
  provenance columns. The first contract reports `conf.status =
  "not_requested"` and `interval_source = "not_available"` so downstream tables
  and future plots cannot imply confidence intervals that were not computed.
* `confint()`, `summary()`, and `corpairs()` originally rejected bootstrap interval methods while the simulate-refit contract was still untested. That boundary is now superseded for `confint(..., method = "bootstrap")` on selected direct fitted-object targets; `method = "parametric_bootstrap"` and bootstrap routing through `summary()` or `corpairs()` still fail explicitly.
* `summary()` now reports delta-method standard errors for direct response-scale parameter rows, including constant `sigma`, residual `rho12`, random-effect SDs, and random-effect correlations, when `TMB::sdreport()` succeeds. Descriptive fitted ranges and derived variance ratios keep missing standard errors. This release originally recommended profile likelihood broadly for fitted SD and correlation targets; the cell-specific 0.6.0 guidance above supersedes that blanket recommendation.
* `summary()` profile summaries now keep fixed-effect Wald 95% confidence intervals while adding profile-likelihood 95% confidence intervals for selected direct targets such as `sigma`. Printed parameter tables no longer show duplicated `minimum` and `maximum` columns for constant direct parameters where those values equal the estimate.
* The model-workflow article now includes a compact guide to reading ordinary `summary()` output. The guide maps `coefficients`, `parameters`, `covariance`, `derived`, and `confint` components to the interpretation task and then points readers to `fixef()`, `sigma()`, `rho12()`, `ranef()`, `corpairs()`, and `profile_targets()` when they need more detail.
* The model-workflow article now shows empirical marginalization with
  `prediction_grid(..., margin = "empirical")` and
  `marginal_parameters(..., by = "temperature")`, separating conditioned
  prediction rows from averages over the fitted-row covariate distribution.
* The model-workflow article now adds raw-data-plus-model display rules for Phase 17: show observed responses on the observed-response scale, draw fitted `mu` and `sigma` surfaces from an explicit `predict_parameters()` table, keep interval provenance visible, and do not place raw response points on `sigma`, `sigma^2`, `rho12`, random-effect SD, or correlation axes.
* The Gaussian location-scale tutorial now includes a response-scale interpretation ladder for fixed mean slopes, residual-SD and residual-variance ratios, random-slope SDs, residual-scale random-slope SDs, and `sd(group)` slopes. It also adds a trait-named parrot beak-length equation block defining `mu`, `sigma`, body mass, forest habitat, and scale coefficients before the worked growth example. The worked growth example shows `profile_targets(fit_growth)` and a compact fitted translation table so readers can report mean growth, predictability, and among-group variation on the correct scale.
* The phylogenetic-spatial tutorial is now framed as a structural-dependence route: first phylogeny, then coordinate spatial dependence, then the planned phylogeny-plus-spatial endpoint. The article defines the conceptual combined equation, names the phylogenetic and spatial SDs, and keeps simultaneous `phylo()` plus `spatial()` syntax marked as planned until multiple structural `mu` layers have implementation and identifiability checks.

# drmTMB 0.1.1 (2026-05-10)

* `docs/design/34-validation-debt-register.md` now backs the stable-core matrix with an evidence and debt ledger. Each advertised surface is marked as covered, partial, opt-in, or blocked, with tests, diagnostics, interval status, docs, and explicit debt recorded before the project expands the surface.
* README and the "What can I fit today?" model-map article now include a stable-core feature matrix. The matrix separates stable fitted surfaces, first-slice implementations, opt-in large-data controls, and planned or rejected neighbouring syntax, with interval and diagnostic status attached to each row.
* `check_drm()` now reports full-matrix `meta_known_V(V = V)` fits as dense known-covariance notes with retained dimension, storage, density, size, rank, and conditioning, making clear that dense known covariance is a small-to-moderate path until sparse or block-sparse `V` storage has implementation and benchmark evidence.
* `confint()` profile rows now include lightweight profile diagnostics through `profile.boundary` and `profile.message`. Successful intervals currently report `"ok"` unless transformed SD intervals are close to zero or transformed correlation intervals are close to the correlation boundary; profile failure messages now explicitly point to boundary, one-sided, non-monotone, or failed-inner-optimization profiles as possible causes.
* `confint()` and `summary()` now use an explicit `conf.status` column for interval output. Successful `confint()` rows report `conf.status = "wald"` or `"profile"`, while `summary(conf.int = TRUE)` marks parameter rows that need `newdata`, are derived-only, are ready but not selected in the current call, or are unavailable for Wald intervals.
* `summary()` and `profile_targets()` now expose the first derived variance-ratio summaries without claiming derived confidence intervals. Simple Gaussian random-intercept repeatability and univariate phylogenetic signal appear as point-estimate rows with `target_type = "derived"`, `transformation = "variance_ratio"`, and `profile_note = "derived_target"`. When intervals are requested, these rows report `derived_interval_unavailable`; `confint(..., method = "profile")` fails before launching an unsupported derived profile.
* Direct profile-likelihood intervals for random-effect SDs and correlations now have focused Slice 55 coverage across the currently fitted ordinary, phylogenetic, and coordinate-spatial surfaces. The tests verify the first spatial `sd:mu:spatial(1 | site)` interval, ordinary and phylogenetic constant `corpairs(conf.int = TRUE)` rows, bivariate phylogenetic SD and mean-mean correlation targets in `summary(conf.int = TRUE, method = "profile")`, and the continued separation of derived covariance intervals from direct SD/correlation intervals.
* Row-specific profile-likelihood intervals now have focused coverage for response-scale `sigma`, `sigma1`, `sigma2`, residual `rho12`, and fitted q=2 ordinary or phylogenetic `corpair()` values supplied through `newdata`. The tests verify multi-row bivariate scale intervals, fitted latent-correlation intervals for both ordinary and phylogenetic q=2 `corpair()` routes, and early errors for ambiguous `newdata` requests such as multiple `parm` values, non-data-frame inputs, or empty grids.
* `profile_targets()` now treats its returned table as a tested namespace contract. Target rows use controlled `target_type`, `profile_ready`, `profile_note`, and `transformation` values, and memory-light fits created with `drm_control(keep_tmb_object = FALSE)` now keep listing direct target names while marking them with `profile_note = "tmb_object_required"` instead of implying that direct profile intervals can be run.
* `confint()` now wraps direct `TMB::tmbprofile()` calls with clearer target-specific errors. Users can still tune profile controls such as `ystep`, `ytol`, and `parm.range`, but `drmTMB` now blocks attempts to override the internal `obj`, `name`, `lincomb`, or `trace` arguments through `...` and reports the `profile_targets()` name when profiling or profile-interval extraction fails.
* `drm_control(se = FALSE)` now skips `TMB::sdreport()` while keeping optimized fits usable for coefficients, fitted values, residuals, prediction, simulation, log-likelihood, and profile-likelihood routes that retain `fit$obj`. Fits also survive `sdreport()` failure with `fit$uncertainty$status = "failed"`, while `summary()`, `vcov()`, and `check_drm()` report the skipped or failed uncertainty state explicitly.
* `drm_control()` now reserves future start, fixed-parameter map, fallback-optimizer, and multi-start control names so they cannot be silently passed to `nlminb()` through a plain optimizer list. Profile-likelihood calls also re-pin the TMB object to the selected `opt$par` before profiling, keeping mutable TMB state aligned with the chosen optimum.
* `drm_control(aggregate_gaussian = TRUE)` now fits the first sufficient-statistic aggregation path for univariate Gaussian fixed-effect models. Repeated rows are grouped by processed `mu` and `sigma` design state, TMB evaluates the Gaussian likelihood with `n`, `sum(y)`, and `sum(y^2)` cells, and fitted-row predictions and residuals remain one value per original model row. Random effects, direct-SD formulas, structured effects, known sampling covariance, bivariate models, non-Gaussian families, non-unit likelihood weights, and combined sparse fixed-effect matrices remain planned.
* `drm_control(keep_model_frame = FALSE)` now also drops nested model-frame caches for direct random-effect SD models and fitted q=2 `corpair()` regression models after their model matrices and group metadata have been retained. This keeps the memory-light fitted-object path aligned with `sd_phylo()` and latent-correlation features.
* `drm_control(sparse_fixed = TRUE)` now fits the first sparse fixed-effect path for univariate Gaussian `mu` fixed effects with intercept-only `sigma`. The fitted object keeps the `mu` design as a sparse `Matrix`, prediction follows the fitted sparse flag, and `check_drm()` reports sparse fixed-effect design matrices; random effects, known covariance, phylogenetic or spatial terms, bivariate models, non-Gaussian models, and sparse `sigma` remain planned.
* `bench/large-phylo-location.R` now records `aggregate_gaussian`, requested and fitted aggregation-cell counts, aggregation compression ratio, and largest aggregation cell size, and can run a non-phylogenetic aggregation smoke benchmark with `--structured none --aggregate-gaussian true --aggregation-cells 100`.
* `bench/large-phylo-location.R` now records `structured` and `sparse_fixed` settings and can run a non-phylogenetic sparse fixed-effect smoke benchmark with `--structured none --factor-heavy true --sparse-fixed true`.
* `check_drm()` now includes the density of the largest retained fixed-effect design block in the `fixed_effect_design_size` row, making high-cardinality mostly-zero designs easier to distinguish from genuinely dense designs and confirming when a fitted object retains sparse fixed-effect matrices.
* The optional `bench/large-phylo-location.R` benchmark now records the largest retained fixed-effect design block, its column count, nonzero count, and density, and `bench/summarize-results.R` includes those fields when present.
* Univariate Gaussian phylogenetic location models now support the Family B direct-SD formula `sd_phylo(species) ~ x_species`. The implementation uses a non-centred unit phylogenetic base effect scaled at observed tips by species-level SD predictors, giving marginal tip covariance `D_tip A_tip D_tip` without assigning predictors to internal tree nodes. `coef()`, `predict()`, `sdpars`, and `profile_targets()` expose the fitted SD surface.
* Bivariate Gaussian phylogenetic location models now support Family B direct-SD formulas `sd_phylo1(species) ~ x_species` and `sd_phylo2(species) ~ x_species` for matching `mu1` and `mu2` phylogenetic location effects. The implementation keeps the latent phylogenetic mean-mean correlation constant, exposes response-specific species SD surfaces through `coef()`, `predict()`, and `sdpars`, and rejects mixtures with all-four q=4 phylogenetic location-scale blocks.
* `biv_gaussian()` now supports Family B direct location random-effect SD formulas for labelled bivariate location random intercepts: `sd1(id) ~ x_group` targets the `mu1` random-effect SD and `sd2(id) ~ x_group` targets the `mu2` random-effect SD. Predictors must be constant within the named group, and unsupported scale-random-effect SD names such as `sd_sigma1()` / `sd_sigma2()` plus same-group q=4 Family A mixtures are rejected to avoid mixing direct SD models with scale-formula random effects.
* `biv_gaussian()` now supports the first predictor-dependent latent random-effect correlation models for q=2 location blocks. Ordinary grouped blocks use `corpair(id, level = "group", block = "p", from = "mu1", to = "mu2") ~ x_group`; phylogenetic blocks use `corpair(species, level = "phylogenetic", block = "p", from = "mu1", to = "mu2") ~ ecology` beside matching `phylo(1 | p | species, tree = tree)` terms. The fitted link-scale coefficients appear in `coef()`, `summary()`, `vcov()`, and `profile_targets()`, while `corpairs()` reports the response-scale mean, range, and number of group/species correlation values. Predictors must be constant within group/species; location-scale, scale-scale, q=4, and spatial `corpair()` regressions remain planned.
* The fitted q=2 phylogenetic `corpair()` route uses two independent unit phylogenetic fields with species-specific loadings. This gives a positive-definite nonstationary covariance model, preserves the same-species local correlation interpretation, and reduces to the existing constant bivariate phylogenetic covariance when the correlation predictor is constant. A CRAN-safe broad-trend recovery test now checks that a positive species-level correlation predictor recovers the ordering of fitted phylogenetic correlations without hitting the correlation guard. The first implementation target is `mu1`-`mu2`; phylogenetic location-scale and scale-scale correlation regressions remain q=4 extensions.
* A new large-data workflow article documents current memory-light fit controls, practical post-fit output cautions, and the optional `bench/large-phylo-location.R` benchmark harness for Gaussian phylogenetic location models.
* `check_drm()` now reports optimizer evaluation counts, dense fixed-effect design size, finite fixed-effect standard errors, near-boundary random-effect standard deviations, univariate `mu`/`sigma` mean-scale covariance diagnostics, bivariate same-response `mu`/`sigma` diagnostics, bivariate `mu1`/`mu2` and `sigma1`/`sigma2` random-intercept covariance diagnostics, ordinary q=4 bivariate location-scale covariance diagnostics, bivariate phylogenetic `mu1`/`mu2` covariance diagnostics, phylogenetic q=4 location-scale covariance diagnostics, coordinate-spatial `mu` diagnostics, and univariate or bivariate `sd_phylo*()` direct-SD surface diagnostics, helping users diagnose large, difficult, or weakly identified fits before interpreting estimates.
* `biv_gaussian()` now fits matching intercept-only `phylo(1 | species, tree = tree)` or labelled `phylo(1 | p | species, tree = tree)` terms in `mu1` and `mu2` as correlated phylogenetic location effects. It also fits the first matching labelled all-four phylogenetic q=4 block across `mu1`, `mu2`, `sigma1`, and `sigma2`, reporting four endpoint SDs and all six latent phylogenetic correlations while keeping residual `rho12` separate. Partial, unlabelled, mismatched, and slope phylogenetic q=4 forms remain rejected.
* `profile_targets()` lists the fitted-model target names that can be passed to `confint()`, including whether each target is ready for direct profile-likelihood intervals. It distinguishes group-level covariance targets such as `cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)`, `cor:mu_sigma:cor(mu1:(Intercept),sigma1:(Intercept) | p | id)`, `cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)`, `cor:sigma:cor(sigma1:(Intercept),sigma2:(Intercept) | p | id)`, and `cor:phylo:cor(mu1:(Intercept),mu2:(Intercept) | phylo | species)` from residual `rho12`. Ordinary q=4 `theta_re_cov` correlations and full phylogenetic q=4 `theta_phylo` correlations are listed as derived unstructured-correlation targets, while block-diagonal phylogenetic q=4 fallback fits expose direct constant block-correlation targets.
* `confint()` now returns Wald fixed-effect confidence intervals by default and can compute profile-likelihood intervals for explicit direct targets such as `fixef:mu:x`, constant `sigma`, `sd:mu:(1 + x | id):(Intercept)`, `sd:mu:phylo(1 | species)`, `cor:mu:cor((Intercept),x | id)`, the first univariate `mu`/`sigma`, bivariate `mu1`/`mu2`, bivariate `sigma1`/`sigma2`, block-diagonal bivariate phylogenetic `mu1`/`mu2` and `sigma1`/`sigma2` random-effect correlations, and constant residual `rho12`. It also profiles row-specific response-scale `sigma`, `sigma1`, `sigma2`, `rho12`, and fitted q=2 ordinary or phylogenetic `corpair()` values when `newdata` is supplied. Full phylogenetic q=4 correlations are currently reported as derived targets, and direct fallback targets still need fit-specific profile diagnostics before being interpreted as usable intervals.
* `corpairs()` now accepts `conf.int = TRUE` for profile-likelihood correlation-pair intervals where the fitted target is profile-ready. Rows that are not interval-ready, such as predictor-dependent residual `rho12` summaries that need `newdata` or derived q=4 unstructured-correlation rows, now carry an explicit `conf.status` instead of silently omitting bounds.
* `biv_gaussian()` now fits the first bivariate group-level covariance blocks: matching labelled random intercepts in `mu1`/`mu2` and in `sigma1`/`sigma2`. The fitted group-level SDs appear in `sdpars$mu` or `sdpars$sigma`, the same-parameter random-intercept correlations appear in `corpars$mu` or `corpars$sigma` and `corpairs()`, and residual `rho12` remains a separate within-observation correlation.
* `biv_gaussian()` now fits same-response cross-parameter random-intercept covariance blocks, such as matching `(1 | p | id)` terms in `mu1` and `sigma1`, or a separate `(1 | q | id)` pair in `mu2` and `sigma2`. The fitted mean-scale correlations appear in `corpars$mu_sigma`, `corpairs()`, and `profile_targets()`.
* `biv_gaussian()` now fits an intercept-only ordinary q=4 location-scale covariance block when the same labelled `(1 | p | id)` term appears in `mu1`, `mu2`, `sigma1`, and `sigma2`. The block estimates four group-level SDs and all six latent random-effect correlations while keeping residual `rho12` separate.
* `corpairs()` now accepts `group` and `block` filters so users can directly subset fitted group-level covariance rows while keeping residual `rho12` rows separate. It also accepts location-class aliases such as `class = "location-location"` and `class = "location-scale"` for the existing `mean-mean` and `mean-scale` rows, matching the reserved `corpair()` formula terminology without renaming current output.
* `drm_control()` is now exported and provides the first large-data storage controls for `drmTMB()`: users can pass optimizer settings through `optimizer = list(...)`, drop stored complete-case data with `keep_data = FALSE`, drop stored model frames after fitting with `keep_model_frame = FALSE`, and drop the retained TMB automatic-differentiation object with `keep_tmb_object = FALSE`.
* `drm_formula()` now reserves explicit coefficient-specific random-effect SD syntax such as `sd(id, dpar = "mu", coef = "x1") ~ x_group` for future random-slope scale models. `drmTMB()` rejects these formulas until the likelihood, covariance diagnostics, and simulation tests exist.
* `drm_formula()` now uses singular endpoint-specific `corpair(group, level = "...", block = "...", from = "mu1", to = "mu2") ~ x` syntax for predictor-dependent latent random-effect correlations. The first fitted paths are ordinary and phylogenetic q=2 `mu1`/`mu2`; spatial, location-scale, scale-scale, and q=4 variants remain parsed or documented as later targets. Use `rho12 = ~ x` for residual correlation and `corpairs()` to extract fitted latent correlations.
* `drmTMB()` now fits the first labelled cross-formula covariance block for univariate Gaussian location-scale models: matching `y ~ x + (1 | p | id)` and `sigma ~ z + (1 | p | id)` random intercepts. The fitted mean-scale correlation appears in `corpars$mu_sigma` and `corpairs()`.
* Gaussian residual-scale random slopes are now implemented for univariate Gaussian `sigma` formulas as independent terms such as `sigma ~ z + (0 + w | id)`. Historical note, superseded by the current 0.6.0 guidance: unlabelled ordinary correlated blocks such as `(1 + x | id)` are now fitted; labelled residual-scale slope covariance and cross-formula `mu`-`sigma` slope covariance remain planned.
* Installation docs now point tagged-preview users to `pak::pak("itchyshin/drmTMB@v0.1.1")`.
* `marginal_parameters()` averages long-format distributional-parameter predictions over fitted rows or supplied `newdata` groups, providing the first simple marginalisation surface for mean, scale, shape, and residual-correlation summaries.
* `nbinom2()` and the zero-inflated, zero-truncated, and hurdle NB2 routes now share an internal count-kernel helper that avoids observed-count loops for large counts while preserving the small-overdispersion Poisson limit. Deterministic high-count tests compare the optimized objective against independent `stats::dnbinom()` calculations.
* Developer documentation now includes a C++ modularization source map that identifies safe header-only helper extraction, hidden `model_type` probe branches, required test gates, and the template pieces that should not move during the first refactor pass.
* Phase 6d stable-core validation is locally closed with a stable-core feature matrix, validation-debt register, failure-safe `sdreport()` controls, optimizer/start/map contract, dense covariance guardrails, count-kernel hardening, and a C++ modularization source map. GitHub Actions remains the PR-side gate.
* `predict_parameters()` returns long-format predictions for fitted distributional parameters such as `mu`, `sigma`, `nu`, and `rho12`, giving interpretation tables and future plotting or marginalisation helpers one shared data surface.
* `summary()` now reports a response-scale parameter table for fitted scale, shape, random-effect SD, and correlation quantities, with opt-in Wald or profile-likelihood confidence intervals through `conf.int = TRUE`, including direct profile intervals for the first fitted group-level covariance rows. It also includes a `covariance` component with fitted random-effect variance and covariance point summaries for currently fitted registry-backed covariance blocks and the first bivariate phylogenetic `mu1`/`mu2` mean-mean row; derived covariance intervals remain unavailable until a nonlinear interval method is implemented, and the covariance table marks that interval status explicitly.

# drmTMB 0.1.0 (2026-05-10)

* `bf()` now stores parsed formula entries for distributional parameters, including bivariate `rho12`, meta-analysis `meta_known_V(V = V)`, and random-effect scale syntax.
* `beta()` now fits fixed-effect beta mean-scale models for strict continuous proportions in `(0, 1)`, using `logit(mu)`, `log(sigma)`, and internal precision `phi = 1 / sigma^2`; `fitted()` returns `mu` and `sigma(fit)` returns the public scale parameter.
* `beta_binomial()` now fits fixed-effect beta-binomial mean-overdispersion models for `cbind(successes, failures)` responses, using `logit(mu)`, `log(sigma)`, and internal beta precision `phi = 1 / sigma^2`. `fitted()` returns the success probability `mu`, and `sigma(fit)` returns the public extra-binomial variation scale.
* `biv_gaussian()` now fits fixed-effect bivariate Gaussian location-scale-coscale models with separate `mu1`, `mu2`, `sigma1`, `sigma2`, and predictor-dependent `rho12` formulas.
* `check_drm()` now provides a first-pass diagnostic table for optimizer convergence, fixed gradients, Hessian status, dropped rows, scale positivity, `rho12` boundaries, Student-t `nu` boundary behaviour, known sampling covariance summaries, random-effect replication, and weak random-slope design checks.
* `corpairs()` now returns a long table of fitted correlation pairs that already exist in a `drmTMB` fit, currently residual bivariate `rho12` summaries and ordinary group-level `mu` random-effect correlations.
* `drm_formula()` is now the primary formula constructor; `bf()` remains a short alias.
* `drm_formula(mvbind(y1, y2) ~ x)` is now implemented as shorthand for identical bivariate Gaussian location formulas, expanding internally to `mu1 = y1 ~ x` and `mu2 = y2 ~ x`.
* `drmTMB()` now fits Gaussian location-scale models with fixed effects, random intercepts, labelled random intercepts such as `(1 | p | id)`, independent numeric random slopes, and ordinary labelled or unlabelled correlated random intercept-slope blocks in the `mu` formula, such as `bf(y ~ x1 + (1 | id) + (0 + x1 | id), sigma ~ x1)`, `bf(y ~ x1 + (1 + x1 | id), sigma ~ x1)`, and `bf(y ~ x1 + (1 + x1 | p | id), sigma ~ x1)`.
* `cumulative_logit()` now fits fixed-effect univariate ordinal location models for ordered responses, using ordered cutpoints, `Pr(y_i <= k) = logit^-1(theta_k - mu_i)`, and a fixed latent logistic scale. `fitted()` returns the expected ordered-category score, and ordinal scale/discrimination formulas remain planned.
* `drmTMB()` now fits fixed-effect Gamma mean-CV models for positive responses with `family = Gamma(link = "log")`, where `mu` is the response mean and `sigma` is the coefficient of variation.
* `drmTMB()` now fits fixed-effect Poisson mean models for count responses with `family = poisson(link = "log")`, including standard R exposure offsets in the `mu` formula such as `count ~ habitat + offset(log(trap_nights))`. The same family route supports fixed-effect zero-inflated Poisson models via `zi ~ predictors`, where `mu` is the conditional Poisson mean, `zi` is the structural-zero probability, and `fitted()` returns `(1 - zi) * mu`. Overdispersion, random effects, known sampling covariance, and bivariate count models remain planned for this route.
* `drmTMB()` now supports a top-level `weights =` argument for non-negative row log-likelihood multipliers, with `weights(fit)` returning the processed weights after model-row filtering. Known sampling variance or covariance remains separate and should use `meta_V(V = V)`, with `meta_known_V(V = V)` as a compatibility alias.
* `nbinom2()` now fits fixed-effect negative-binomial 2 mean-dispersion models for overdispersed counts, with `log(mu)`, `log(sigma)`, and `Var(y) = mu + sigma^2 * mu^2`. The `mu` formula supports standard R exposure offsets such as `count ~ habitat + offset(log(trap_nights))`. Here `sigma` is an overdispersion scale, not a residual standard deviation or size parameter. The same family route supports fixed-effect zero-inflated NB2 models via `zi ~ predictors`.
* `drmTMB()` now accepts `family = c(gaussian(), gaussian())` and `family = list(gaussian(), gaussian())`, routing both to the implemented bivariate Gaussian location-coscale likelihood. Mixed composed families such as `c(gaussian(), poisson())` remain planned and currently error clearly.
* Gaussian residual-scale random intercepts are implemented in the `sigma` formula, for example `bf(y ~ x1 + (1 | id), sigma ~ x1 + (1 | id))`. These model residual-scale heterogeneity and are distinct from random-effect scale formulae such as `sd(id) ~ x_group`.
* Gaussian random-effect scale formulae are implemented for one or more distinct unlabelled `mu` random intercepts, for example `bf(y ~ x1 + (1 | id) + (1 | site), sigma ~ x2, sd(id) ~ x_group, sd(site) ~ site_type)`. Each `sd(group)` predictor must be constant within the named group after missing-row filtering.
* Gaussian known-covariance meta-analysis with `meta_known_V(V = V)` is now covered by targeted validation when combined with random-effect scale formulae such as `sd(id) ~ x_group`, using an independent dense marginal-likelihood comparator.
* Gaussian `mu` random-effect correlations from correlated blocks are exposed as `corpars$mu`, keeping group-level labels such as `p` separate from residual bivariate `rho12`.
* Profile-likelihood confidence intervals are documented as a planned inference phase with an explicit target namespace, such as `sd:mu:(1 | id)`, `cor:mu:cor((Intercept),x | id)`, and `fixef:rho12:(Intercept)`, plus boundary flags and nonlinear derived-quantity guidance.
* `deviance()`, `df.residual()`, and `nobs()` now work for `drmTMB` fits, making base-R model summaries and comparison helpers more complete.
* `fitted()` now returns family-specific response summaries: `mu` for implemented Gaussian-like, Gamma, beta, beta-binomial, Poisson, and NB2 mean models, the expected ordered-category score for cumulative-logit ordinal models, the arithmetic response mean for lognormal models, `(1 - zi) * mu` for zero-inflated Poisson and zero-inflated NB2 models, `(1 - hu) * mu / (1 - Pr_NB2(0))` for hurdle NB2 models, and a two-column `mu1`/`mu2` matrix for bivariate Gaussian models.
* `fixef()` now returns distributional fixed-effect coefficients and acts as a mixed-model-friendly alias for `coef()`.
* `lognormal()` now fits fixed-effect univariate lognormal location-scale models for positive responses, with `mu` and `sigma` defined on the log-response scale, `fitted()` returning the arithmetic response mean, and simulation plus likelihood tests checked against `stats::dlnorm()`.
* `meta_known_V(V = V)` now fits Gaussian meta-analysis with diagonal or dense full known sampling covariance using `family = gaussian()`.
* `meta_vcov_bivariate()` now builds row-paired dense sampling covariance matrices for bivariate Gaussian meta-analysis with known within-study covariance, and `meta_known_V(V = V)` now fits complete-row bivariate Gaussian known-`V` models by adding that sampling covariance to the fitted residual covariance from `sigma1`, `sigma2`, and `rho12`.
* `ranef()` now returns fitted conditional random-effect blocks, including ordinary `mu`, residual-scale `sigma`, `phylo_mu`, and the first `spatial_mu` blocks when present.
* `rho12()` now returns response-scale residual correlations from bivariate Gaussian location-coscale fits, with `type = "link"` available for Fisher-z-like linear predictors using the guarded transform `rho12 = 0.999999 * tanh(eta_rho12)`.
* `student()` now fits fixed-effect univariate Student-t location-scale-shape models with `mu`, `sigma`, and `nu` formulas. The `nu` parameter is modelled as `nu = 2 + exp(eta_nu)` for a stable finite-variance robust continuous family.
* `truncated_nbinom2()` now fits zero-truncated negative-binomial 2 models for positive counts, with ordinary `mu` random intercepts and independent numeric slopes allowed in non-hurdle models. `mu` and `sigma` describe the untruncated NB2 component, `fitted()` returns the conditional positive-count mean `mu / (1 - Pr_NB2(0))`, and `sigma(fit)` returns the NB2 overdispersion scale. Adding `hu ~ predictors` still fits the corresponding fixed-effect hurdle NB2 model; hurdle random effects outside the exact Q-Series `hu ~ relmat(1 | id, Q = Q)` local-fit gate, correlated zero-truncated random slopes, and `sigma` random effects remain planned.
* `drmTMB()` now fits phylogenetic random intercepts and one numeric phylogenetic random slope in the univariate Gaussian location formula with `phylo(1 | species, tree = tree)` and `phylo(1 + x | species, tree = tree)`, using an ultrametric branch-length tree and the sparse augmented A-inverse path. It also fits coordinate-based spatial random intercepts and one numeric spatial `mu` slope in the univariate Gaussian location formula with `spatial(1 | site, coords = coords)` and `spatial(1 + x | site, coords = coords)`. The slope paths estimate independent intercept and slope fields with the same fixed structured precision and separate SDs, labelled with terms such as `phylo(1 | species)`, `phylo(0 + x | species)`, `spatial(1 | site)`, and `spatial(0 + x | site)`.
* `animal()` and `relmat()` now fit one numeric univariate Gaussian `mu` slope beside their fitted random-intercept paths, for example `animal(1 + x | id, pedigree = ped)` and `relmat(1 + x | id, K = K)`, using independent intercept and slope fields with separate SDs. Planned structured-effect markers outside the first fitted one-slope paths, such as standalone or partial phylogenetic scale terms, spatial terms in `sigma`, `spatial(1 | site, mesh = mesh)`, multiple structured slopes, slope correlations, spatial q=4 blocks, and predictor-dependent spatial `corpair()` formulas, are parsed by `drm_formula()` and rejected by `drmTMB()` with planned-feature errors until their TMB likelihoods and recovery tests are implemented.
* The "Which scale are you modelling?" tutorial now includes a copy-run scale audit with fitted output and interpretations for `sigma ~`, `weights =`, preferred `meta_V(V = V)`, `sd(group) ~`, and bivariate `rho12 ~` syntax.
* Tutorial prose now clarifies that ordinary likelihood weights and known sampling covariance are separate concepts, and that dense full `meta_V(V = V)` paths currently reject non-unit weights; deprecated `meta_known_V(V = V)` remains only a compatibility alias.
* The Gaussian location-scale tutorial now includes a worked growth example with equations, fitted `summary()` output, response-scale `sigma` interpretation, and a table mapping mean growth and residual SD back to the biological question.
* The bivariate location-coscale tutorial now includes worked activity-boldness equations, output-reading guidance for `rho12`, and a response-scale residual-correlation curve along a disturbance gradient.
* The bivariate Gaussian coscale phase now has a closure audit in the roadmap: `rho12()`, `corpairs()`, bivariate known sampling covariance, row likelihood weights, `mvbind()` shorthand, residual diagnostics, and unsupported bivariate random-effect syntax are all documented as implemented or planned in one place.
* The response-family tutorial now starts with an at-a-glance table that maps common measurement processes to implemented families, distributional parameters, the meaning of `sigma`, and the main current limitation.
* The meta-analysis tutorial now includes a worked restoration example with equations, fitted `summary()` output, response-scale residual heterogeneity interpretation, and a clearer distinction between preferred `meta_V(V = V)` and ordinary likelihood `weights =`.
* The phylogenetic-spatial tutorial now includes a worked thermal-tolerance example for the implemented `phylo(1 | species, tree = tree)` path, with equations, fitted output, tree/species validation guidance, bivariate phylogenetic and coordinate-spatial reading guidance for `corpairs()`, `summary(fit)$covariance`, direct profile targets, the first labelled q=4 phylogenetic location-scale syntax, and clearer marking of implemented coordinate-spatial intercept, one-slope, and q=2 bivariate location paths versus planned mesh/SPDE and spatial q=4 paths.
* The getting-started article and pkgdown tutorial menu now provide a clearer learning path from biological or statistical questions to the matching tutorial and distributional parameter.
* Public documentation now pairs symbolic model equations with matching R syntax for the first Gaussian location-scale, random-effect scale, bivariate `rho12`, meta-analysis, and phylogenetic examples, and clarifies planned spatial `coords` versus `mesh` inputs.
* The likelihood design now includes a central TMB `model_type` routing table, aligned with the implemented source map, including the hidden phylogenetic prior parity branch used only by tests.
* `residuals()` now returns whitened Pearson residuals for bivariate Gaussian fits, and `vcov()` now uses coefficient-level row and column names.
* Initial project scaffold.

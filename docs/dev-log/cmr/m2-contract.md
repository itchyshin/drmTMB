# M2 contract: predictions, conditional simulation and fixed-effect uncertainty

Status: parent-frozen implementation scope for M2, derived from the approved M0-M6 CJS plan. This supplements the hash-locked core likelihood contract; it does not expand the model class.

## Mathematical alignment

For process-specific designs on the requested rows,

\[
\eta^\phi_{it}=x^\phi_{it}{}^T\widehat\beta_\phi+o^\phi_{it},\quad
s_{it}=\operatorname{logit}^{-1}(\eta^\phi_{it}),\quad
\Phi_{it}=s_{it}^{\Delta_{it}},\\
\eta^p_{it}=x^p_{it}{}^T\widehat\beta_p+o^p_{it},\quad
p_{it}=\operatorname{logit}^{-1}(\eta^p_{it}).
\]

Prediction reports the process-specific link values, unit-time survival, interval survival and detection. It never converts these into an unconditional population prediction. Intervals remain in the fit's declared unit; supplied prediction units must match that label.

Simulation holds each observed first-capture time, pre-capture record, administrative endpoint, survey mask and predictor layout fixed. Beginning alive immediately after first capture, it draws one survival transition per interval, raises unit-time survival to that interval's \(\Delta\), then draws detection conditional on alive and surveyed. Death is absorbing. An unobserved survey emits `missing`/`NA` but still advances the latent state. History frequencies expand to independent unit-frequency simulated histories. The likelihood's first-capture emission remains conditioned upon and is never redrawn.

The fixed-effect estimate is the maximum-likelihood vector \(\widehat\beta\), with model-specific observed negative-log-likelihood Hessian \(H(\widehat\beta)\). Wald intervals use \(\widehat\beta_j\pm z_{1-\alpha/2}\sqrt{[H^{-1}]_{jj}}\) only when the optimizer converges, the gradient is small, the Hessian is finite positive definite, and no fitted probability is flagged at the boundary. They are local asymptotic intervals, not a calibration claim.

Profile intervals fix one named coefficient \(\beta_j=b\), reoptimize every other free coefficient against the native CJS negative log likelihood, and invert \(2\{\ell(\widehat\beta)-\ell_j(b)\}\le\chi^2_{1,1-\alpha}\). Report failed/non-crossing endpoints explicitly. There is no ordinary-response Hessian substitution.

Parametric bootstrap draws histories from the fitted CJS model conditional on the stored capture layout, refits the same model, retains every attempted/converged/usable fit, and forms percentile intervals on coefficient scale only when the requested minimum usable count is met. It is an available computational route, not a calibrated route, until the frozen recovery and coverage gates pass. Boundary, singular, nonconverged and failed fits remain in attempt accounting.

## Public interfaces

- R: `predict(fit, newdata = NULL, type = c("response", "link"))`; process-specific tables are supplied as `list(phi = <data.frame>, p = <data.frame>, units = "years")`. The `phi` table has `id`, `interval_start`, `interval_end`, `interval_length` and formula predictors; `p` has `id`, `occasion` and formula predictors. With `newdata = NULL`, return contributing training rows only. Return named process tables with keys, eta for `type="link"`; response type adds `phi_unit`, `phi_interval`, or `p`. `drm_cjs()` accepts optional process-specific `contrasts` and retains fitted coding for bootstrap refits.
- Julia: `StatsAPI.predict(fit, newdata=nothing; type=:response)`; the equivalent input is a named tuple `(; phi=<table>, p=<table>, units="years")`. Return the same keys and response/link quantities. The training default returns contributing rows only.
- R `simulate(fit, nsim=1L, seed=NULL)` returns one `cmr_simulation` record per replicate with history data and keyed predictor tables ready to pass to `drm_cjs()`.
- Julia `simulate(fit; nsim=1, seed=nothing, rng=Random.default_rng())` returns the corresponding per-replicate record ready for `cjs()`.
- R `coef()`, `vcov()` and `confint(method = "wald" | "profile" | "bootstrap")`; Julia `coef`, `StatsAPI.vcov`, and `StatsAPI.confint(method=:wald | :profile | :bootstrap)`. Bootstrap controls expose the number requested, seed/RNG and minimum usable count. Return attempt counts and status for every target.
- A supplied seed gives repeatable draws without changing the caller's RNG stream. With no supplied seed, use and advance the caller/default RNG normally.

All design construction reuses fitted formula/schema, factor coding, contrasts and offsets. Prediction accepts new individual IDs and new occasion/interval keys because this is fixed-effects prediction; it does not require those keys to occur in the training histories. It rejects unseen factor levels, missing/non-finite required predictors, duplicate keys, nonpositive interval lengths, unknown units, aliasing and incompatible coefficient columns with actionable errors. No factor level, offset, mask, end or unit is inferred by positional coincidence.

For cross-language prediction, `phi` link output has `id`, `interval_start`, `interval_end`, `interval_length`, `eta`; response output has those keys plus `phi_unit` and `phi_interval` (without `eta`). `p` link output has `id`, `occasion`, `eta`; response output has `id`, `occasion`, `p` (without `eta`). Both implementations consume `docs/dev-log/cmr/fixtures/prediction-m2.csv`, which pins fixed coefficients, factor coding, offsets, irregular interval lengths, terminal constraints and predictions on new keys.

## Gates and limits

Fixed-coefficient predictions match the shared literal fixture and direct link calculations in both languages. Conditional simulations retain first-capture/end/mask layouts and satisfy a fixed-seed test while no-seed calls advance their RNG. Wald eligibility uses a shared boundary tolerance of 1e-8 and a relative Hessian eigenvalue threshold of 1e-10; Wald endpoints match the stated formula using each fit's returned covariance matrix. This checks interval construction and a shared availability policy, not independent curvature accuracy or calibration. Successful profile endpoints meet the stated likelihood-ratio cutoff, and bootstrap attempts reconcile with their failure/status ledger; bootstrap replicate and minimum-usable counts are positive integers. A minimum greater than the requested count is allowed and returns an insufficient-usable status. The R defaults are 200 requested / 100 minimum usable; Julia defaults are 199 requested / 80% minimum usable, so callers seeking matched requests set these controls explicitly. Small known-DGP pilots check fit mechanics only; they do not establish coefficient recovery, 2,000-replicate qualification, nominal coverage, calibration, boundary validity or performance.

This contract does not add random effects, unknown-entry animals, selection correction, abundance, survival-detection correlation or bridge routes. Those remain at their approved later stages or deferred boundaries.

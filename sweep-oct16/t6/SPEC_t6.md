# t6 test specification: `predict()` and `simulate()` methods

Lane t6 of the 16 Oct 2026 sweep. Pins: drmTMB `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a`,
DRModels.jl `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7`. This file fixes the
test definitions so the R harness and the Julia harness measure the same
things. The receipt (`RECEIPT_t6.md`) reports against it.

## Cells

14 univariate families common to both engines, each without (`fixed`) and
with (`ri`) an ordinary mean random intercept `(1 | g)`: 28 cells.
Data: `data/<family>_<re>.csv` (from `R/00_make_data.R`); cell index, seed and
R seed in `data/cells.csv`. n = 240, 24 groups of 10. Columns: `x` numeric,
`f` character with levels a/b/c, `g` character g01..g24, response `y`
(or `successes`, `failures`, `trials` for the two binomial families).

| family | R family | Julia family | mu formula RHS | other dpars |
|---|---|---|---|---|
| gaussian | `gaussian()` | `Gaussian()` | `x + f` | sigma ~ x |
| student | `student()` | `Student()` | `x + f` | sigma ~ x, nu ~ 1 |
| skew_normal | `skew_normal()` | `SkewNormal()` | `x + f` | sigma ~ x, nu ~ 1 |
| lognormal | `lognormal()` | `LogNormal()` | `x + f` | sigma ~ x |
| gamma | `Gamma(link = "log")` or the drmTMB gamma spelling | `Gamma()` | `x + f` | sigma ~ x |
| beta | `beta_family()` | `Beta()` | `x + f` | sigma ~ x |
| zero_one_beta | `zero_one_beta()` | `ZeroOneBeta()` | `x + f` | sigma ~ x, zoi ~ 1, coi ~ 1 |
| beta_binomial | `beta_binomial()` | `BetaBinomial()` | `cbind(successes, failures) ~ x + f` | sigma ~ x |
| binomial | `binomial()` | `Binomial()` | `cbind(successes, failures) ~ x + f` | none |
| poisson | `poisson()` | `Poisson()` | `x + f` | none |
| nbinom2 | `nbinom2()` | `NegBinomial2()` | `x + f` | sigma ~ x |
| truncated_nbinom2 | `truncated_nbinom2()` | `TruncatedNegBinomial2()` | `x + f` | sigma ~ x |
| tweedie | `tweedie()` | `Tweedie()` | `x + f` | sigma ~ x, nu ~ 1 |
| cumulative_logit | `cumulative_logit()` | `CumulativeLogit()` | `x + f` (intercept dropped by the family) | none |

`ri` cells add `+ (1 | g)` to the mu formula only. If an engine refuses a
cell, record the refusal verbatim; then retry once with `sigma ~ 1` (and record
that fallback). A refusal of something the other engine fits, or of something
the engine's docs say is supported, is a candidate finding.

For `ri` cells the Julia harness fits the default marginal approximation
*and* `marginal = :Laplace` (TMB's convention) where accepted; cross-engine
fit-vs-fit numbers use the Laplace fit.

## Tests (IDs used in results and receipt)

**P1 in-sample predict.** For every distributional parameter `d` of the fit
(R: `names(coef(fit))`; Julia: blocks with a formula), `type = link` and
`type = response`, no newdata. Check `response == invlink_d(link)` (documented
link per dpar) and `link == X_d %*% beta_d` (+ the fitted `Z b` when the
engine documents in-sample conditional prediction for that dpar). Check
`fitted()` against the documented response mean (e.g. zero_one_beta
`(1 - zoi) mu + zoi coi`; cumulative_logit expected score). Tolerance 1e-10.

**P2 newdata with unseen group levels.** `data/nd_main.csv` (18 rows: x in
{-1, 0, 1.5} x f in {a, b, c} x g in {g01 (seen), gNEW (unseen)}). Every dpar,
link and response. Must not error; must equal the population-level
`X_new beta` (tolerance 1e-10); seen and unseen g rows with the same (x, f)
must agree unless the engine documents conditional newdata prediction.
Also predict with the `g` column removed: must give the same values (or a
documented refusal).

**P3 level subset.** `data/nd_subset.csv` (only f = b), supplied as
character, as `factor(levels = "b")`, and as `factor(levels = c("a","b","c"))`
(Julia: `Vector{String}` and, if available, a categorical vector). Must equal
the matching `nd_main` rows (1e-10) or refuse with a clear message. Silent
wrong values are a finding.

**P4 unseen fixed-effect level.** `data/nd_unseen_f.csv` (f = "d"). Must
refuse with a message naming the factor or level. A silent numeric answer
is a finding. Record the message.

**P5 character vs factor predictors.** Refit with `f` as character (base),
as a factor with default levels, and as a factor with levels c("c","a","b").
Coefficients of char vs default factor must match to 1e-10; predictions on
`nd_main` from all three must agree (1e-6 relative for the releveled fit, which
is a reparameterisation). Cross-type newdata: fit with factor, predict with
character newdata, and vice versa. Julia: `String` column vs categorical (if a
categorical type is loadable), and an `Int` x column vs `Float64`.

**P6 quantile predictions (R).** `predict(type = "quantile", prob =
c(0.025, 0.5, 0.975))` in-sample and on `nd_main` versus the family quantile
function at the predicted parameters (1e-8). Julia: record whether an
equivalent exists.

**P7 standard errors.** R: record whether `predict()` offers `se.fit` (formal
argument), and what `predict(fit, se.fit = TRUE)` returns (known: #1536 says
unused `...` are silently dropped). Check `predict_parameters()` and any other
exported prediction helper for SEs. Julia: `predict(...; se = true)` and
`predict_parameters(...; se = true)` versus an independent delta-method
computation from `vcov(fit)`: link `sqrt(diag(X V_d X'))`; response multiplies
by `|d invlink / d eta|` (1e-8 relative). If both engines give SEs, compare
across engines on the fit-vs-fit pair (report relative difference).

**P8 simulate moments.** `nsim = 1000`. Julia seed = cell seed + 100
(`Random.Xoshiro(seed)`); R seed = R cell seed + 100 passed as `simulate(seed=)`.
R `ri` cells: run both the default (`re.form = NA`, marginal: fresh random
effects per draw) and `re.form = NULL` (conditional on fitted modes). Julia:
the default (docstring says draws are conditional on random effects = 0;
verify what `fit.means[:mu]` actually holds).

Expected per-row moments at the fitted parameters (mu, sigma etc. on the
response scale as each engine defines them):

| family | E[y] | Var[y] |
|---|---|---|
| gaussian | mu | sigma^2 |
| student | mu | sigma^2 nu/(nu-2) (nu > 2; skip variance test otherwise) |
| skew_normal (moment form) | mu | sigma^2 |
| lognormal (mu = meanlog) | exp(mu + sigma^2/2) | (exp(sigma^2) - 1) exp(2 mu + sigma^2) |
| gamma (shape 1/sigma^2) | mu | sigma^2 mu^2 |
| beta (phi = 1/sigma^2) | mu | mu(1-mu)/(1+phi) |
| zero_one_beta | (1-zoi) mu + zoi coi | E[y^2] - E[y]^2 with E[y^2] = zoi coi + (1-zoi)(Var_beta + mu^2) |
| beta_binomial (counts) | m mu | m mu(1-mu)(1 + (m-1)/(phi+1)) |
| binomial (counts) | m mu | m mu (1-mu) |
| poisson | mu | mu |
| nbinom2 (size 1/sigma^2) | mu | mu + sigma^2 mu^2 |
| truncated_nbinom2 | mu/(1-p0) | (mu + sigma^2 mu^2 + mu^2)/(1-p0) - E[y]^2, p0 = (k/(k+mu))^k, k = 1/sigma^2 |
| tweedie (phi = sigma^2, power nu) | mu | sigma^2 mu^nu |
| cumulative_logit (category k = 1..K) | sum k p_k | sum k^2 p_k - E^2 |

m = trials. If an engine's simulate returns proportions rather than counts for
binomial-type families, convert and record it. For marginal (`re.form = NA`)
draws, integrate the conditional moments over b ~ N(0, sd_g^2) by 64-node
Gauss-Hermite: E = E_b[m(eta + b)], Var = E_b[v(eta + b)] + Var_b[m(eta + b)].

Pass rule (the lane's "within 3 Monte Carlo SE"), per cell and simulate mode:
- global mean: per-draw grand mean G_s = mean_i y_is; z = (mean_s G_s -
  mean_i E_i) / (sd_s(G_s)/sqrt(nsim)); pass if |z| < 3.
- global variance: split the 1000 draws into 40 batches of 25; in each batch
  compute V_b = mean_i s^2_i (row-wise unbiased variance over the 25 draws);
  z = (mean_b V_b - mean_i Var_i) / (sd_b(V_b)/sqrt(40)); pass if |z| < 3.
  Batch means are valid under any within-draw dependence (shared b).
- diagnostics (not pass/fail alone): per-row z_i for the mean using the row's
  own MC SE; report max |z_i| and the count with |z_i| > 3 against the
  binomial expectation n * 0.0027. Also regress (ybar_i - E_i) on x and on f
  dummies; report the largest |t|. Flag if > 4.
Also record the class/shape of the returned object and its column names, and
check that `seed=` reproduces (two calls, same seed, identical output) and
leaves the global RNG state as documented.

**P9 R-vs-Julia predict at shared parameters (the 1e-8 parity).** Inject the
R fit's coefficient vector for each dpar into the Julia fit object (by
position after checking the column-name correspondence; R `fb` <-> Julia
`f: b`) and evaluate Julia `predict` / `predict_parameters` on `nd_main`
(link and response). Compare with R `predict(newdata = nd_main)`. Pass:
max abs difference <= 1e-8. This isolates the prediction layer (design
matrix, contrasts, links) from optimizer agreement. Where response-scale
semantics differ by design (e.g. lognormal mu), compare on the link scale,
and report the semantic difference separately.

**P10 fit-vs-fit predict parity.** Each engine's own fit (Julia ri: the
Laplace fit), `nd_main`, every shared dpar, link and response: report max abs
and relative difference, max coefficient difference, logLik difference, and
whether the 1e-8 bar is met. A gap that is explained by coefficient
differences at optimizer tolerance is not a predict defect; say so with the
numbers.

**P11 bridge same-fit parity.** For cells `drmTMB(..., engine = "julia")`
admits: `predict()` on the bridge fit vs DRModels.jl `predict` on the same
data and formula fitted natively in Julia (same optimizer path). Pass: 1e-8.

## Output contract

Per cell and engine: `results/<engine>_<family>_<re>.json` with keys
`family, re, engine, formula, fallback, fit_ok, fit_error, converged, loglik,
coef` (dpar -> {names, values}), and `tests` (P1..P11 -> {status in
PASS/FAIL/NA/ERROR, metric, value, notes}). Predictions on `nd_main` in
`results/<engine>_<family>_<re>_pred.csv` (columns: row, dpar, type, value,
se). Logs in `logs/`.

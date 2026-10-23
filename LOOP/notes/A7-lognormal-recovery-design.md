# A7 — Recovery test design: `mp-lognormal-bernoulli`

**Status.** Design only (2026-08-27). Curie. No C++ in this note.
**Sibling.** `67a70b94` owns engine (`has_mi` on `model_type == 4`, spec
mi-setup, whitelist **after** C++, ledger row). Do not implement C++ here.
**Mirror.** `tests/testthat/test-missing-predictor-gamma-response.R`
(`mp-gamma-bernoulli`, #1088 / `6e553879`).
**Cell.** lognormal **response** × one Bernoulli `mi()` predictor × k = 1.

Do not confuse with `mp-gaussian-lognormal` (Gaussian response × lognormal
*predictor*) or `mr-lognormal` (missing **response** masking). Those already
exist.

---

## Verdict (read this first)

Ship four tests in a new file
`tests/testthat/test-missing-predictor-lognormal-response.R`, cloned from
the Gamma response file. Start tolerances at Gamma's **0.15 MCAR / 0.20 MAR**.
Do not loosen first.

The one place a clone will silently lie: **lognormal `mu` is identity-link
meanlog**, not Gamma's log-mean. `drm_response_log_density` today has **no
`case 4`** (default returns `0.0`). The logLik-identity test is the gate
that catches a Gamma-clone that either `exp(eta)`s the location or forgets
the leaf.

Recommended tolerances: **MCAR 0.15, MAR 0.20, logLik 1e-6, sentinel 1e-8**.

---

## 1. What this cell is (and is not)

| | |
|---|---|
| **Ledger id** | `mp-lognormal-bernoulli` |
| **Response** | `lognormal()` — `model_type == 4` |
| **Predictor** | one binary `mi()`, `impute_model(..., family = binomial())` |
| **k** | 1 |
| **Evidence target** | G3 `point_fit_recovery` (same as Gamma) |
| **Not this slice** | continuous missing predictor; k ≥ 2; `impute_joint`; FIML across a SEM; student / zi-* / tweedie; `mi()` on `sigma`; RE / structured on the response |

Whitelist (`drm_missing_predictor_families()`) gains `"lognormal"` **only
after** C++ `has_mi && mi_family == 1` exists in the lognormal block **and**
`drm_build_lognormal_ls_spec` calls `drm_prepare_gaussian_mi_setup` with the
same Bernoulli-only abort Gamma uses. Whitelist-only is the #962 failure
mode.

---

## 2. Parameterization contract (do not copy Gamma's `exp(eta)`)

Lognormal location-scale (`docs/dev-log/after-task/2026-05-08-lognormal-location-scale.md`,
`test-lognormal-location-scale.R`):

```text
log(y_i) | μ_i, σ_i  ~  Normal(μ_i, σ_i²)
μ_i  =  X_μ[i, ] β_μ          # identity; this IS meanlog
log(σ_i)  =  X_σ[i, ] β_σ     # σ_i = sdlog
log f(y_i)  =  log φ(log y_i; μ_i, σ_i) − log y_i
            =  dlnorm(y_i; meanlog = μ_i, sdlog = σ_i)
E[y_i]  =  exp(μ_i + σ_i² / 2)   # fitted(); NOT what coef(mu) recovers
```

Gamma (the clone source) is different:

```text
η_i  =  X_μ[i, ] β_μ          # log-mean
μ_i  =  exp(η_i)
shape = 1/CV²,  scale = μ · CV²
```

| Object | Gamma cell | Lognormal cell |
|---|---|---|
| `coef(fit, "mu")` | log-mean intercept / slopes | **meanlog** intercept / slopes |
| `coef(fit, "sigma")` | `log(CV)` | `log(sdlog)` |
| 2-point location | `eta1 = eta_base + β_x (1 − x_base)` then `μ = exp(eta)` inside the leaf | same `eta1` algebra, but the leaf treats `eta` as **meanlog** (no `exp`) |
| Main-loop density | Gamma mean-CV | `dnorm(log y, mu, sigma) − log y` |

Engine sibling must:

1. Add `case 4` to `src/drm_response_kernels.h`. Leaf argument `eta_val` is
   meanlog. Do **not** `exp(eta_val)` before `dnorm`.
2. Clone Gamma's `has_mi == 1 && mi_family == 1` 2-point sum into
   `model_type == 4`, updating the **meanlog** vector (`mu` in the current
   lognormal block, not a new `exp(eta)`).
3. Add the skip mask on the main loop:
   `!(has_mi == 1 && mi_family != 0 && mi_observed(i) == 0)` so missing-`x`
   rows are not double-counted.
4. Clamp `log_sigma` **before** the 2-point sum (Gamma comment: beta lesson).

If (1) is missing, `drm_response_log_density` returns `0.0` and the
identity test fails by ~the response logLik. If (2) uses `exp(eta)`, MCAR
recovers garbage near `exp(0.4)` instead of `0.4`. Do not loosen
tolerances to hide either bug.

---

## 3. Test file and four required cases

New file (do not append to `test-missing-predictor-lognormal.R` — that file
is **lognormal-as-predictor** under a Gaussian response).

| # | `test_that` | Role | n | Seed | Tol |
|---|---|---|---:|---:|---|
| 1 | `"binary mi() predictor works with a lognormal response likelihood"` | G2 logLik identity | 90 | deterministic | `1e-6` |
| 2 | `"Lognormal-response mi() recovers the meanlog, sdlog, and predictor model under MCAR"` | G3 MCAR | 3000 | 13 | **0.15** |
| 3 | `"Lognormal-response mi() recovers under outcome-dependent MAR"` | G3 MAR | 3000 | 21 | **0.20** |
| 4 | `"Lognormal-response mi() still refuses a non-binary predictor"` | fail-loud | 90 | — | error |

Optional fifth (recommended, cheap): dummy-fill / sentinel invariance at
missing-predictor rows — see §6.

Reuse Gamma's seeds (13 / 21) so a copy-paste of `rgamma` is still a
different family, not a coincidental pass.

---

## 4. DGPs

### 4.1 Identity fixture (n = 90)

Same design as Gamma. `y` need only be strictly positive; it does not need
to be lognormal-distributed.

```r
n <- 90
z <- seq(-1.6, 1.7, length.out = n)
treatment_full <- as.numeric(sin(seq_len(n) * 1.3) + 0.3 * z > 0)
eta <- 0.3 + 0.4 * z + 0.6 * treatment_full          # meanlog, not log-mean
y <- exp(eta + 0.2 * cos(seq_len(n) / 4))            # strictly positive
# treatment[c(8, 19, 31, 46, 57, 70, 83)] <- NA
```

Fit:

```r
drmTMB(
  bf(y ~ z + mi(treatment), sigma ~ 1),
  family = lognormal(),
  data = dat,
  impute = list(
    treatment = impute_model(treatment ~ z, family = binomial())
  ),
  missing = miss_control(predictor = "model"),
  control = drm_control(se = FALSE)
)
```

### 4.2 Manual 2-point-sum logLik

Clone `manual_gamma_response_binary_mi_loglik`. Swap only the response leaf.

```r
lognormal_response_log_density <- function(y, eta, log_sigma) {
  # eta = meanlog (identity). sigma = exp(log_sigma) = sdlog.
  stats::dlnorm(y, meanlog = eta, sdlog = exp(log_sigma), log = TRUE)
}
```

Observed-`x` row:

```text
ℓ_i  =  log π(x_i | z_i)  +  dlnorm(y_i; η_base,i , σ)
```

Missing-`x` row (log-sum-exp over {0,1}):

```text
η_{i,1}  =  η_base,i + β_x (1 − x_base,i)
η_{i,0}  =  η_base,i + β_x (0 − x_base,i)
ℓ_i  =  log(  π_{i,1} f(y_i | η_{i,1})  +  π_{i,0} f(y_i | η_{i,0})  )
```

`η_base = offset_μ + X_μ β_μ`, `β_x = β_μ[mi_col]`, `x_base = X_μ[, mi_col]`
(the dummy fill at missing rows). `π_{i,1} = logit⁻¹(X_mi β_mi)`.

Assert `logLik(fit) == manual_*(fit)` to `1e-6`.

Also assert:

- `fit$missing_data$predictors$treatment$family == "bernoulli"`
- `nobs(fit) == nrow(dat)`
- finite `coef(mu)` and `coef(mi_treatment)`

`missing_data$version` string is the engine sibling's choice (Gamma used
`"MD-gamma-mi"`). Do not invent it here; identity the likelihood, not the
label.

### 4.3 MCAR recovery (n = 3000, seed 13)

```text
z_i     ~  N(0, 1)
x_i     ~  Bern( logit⁻¹(0.3 + 0.8 z_i) )
η_i     =  0.4 + 0.5 z_i + 0.7 x_i          # meanlog
σ       =  0.3                               # sdlog (constant)
y_i     ~  LogNormal(η_i, σ)
x_i     ←  NA   with probability 0.20 (MCAR)
```

```r
set.seed(13)
n <- 3000
z <- rnorm(n)
x <- rbinom(n, 1, stats::plogis(0.3 + 0.8 * z))
eta <- 0.4 + 0.5 * z + 0.7 * x
sdlog <- 0.3
y <- stats::rlnorm(n, meanlog = eta, sdlog = sdlog)
d <- data.frame(y = y, z = z, x = factor(x, levels = c(0, 1)))
d$x[sample(n, round(0.2 * n))] <- NA
```

Truth to recover:

| Extractor | Truth | Tol |
|---|---|---|
| `unname(coef(fit, "mu"))` | `c(0.4, 0.5, 0.7)` | **0.15** |
| `unname(coef(fit, "sigma"))` | `log(0.3)` | **0.15** |
| `unname(coef(fit, "mi_x"))` | `c(0.3, 0.8)` | **0.15** |

`sdlog = 0.3` mirrors Gamma's `CV = 0.3`. Lognormal CV is
`√(exp(σ²) − 1) ≈ 0.307`, so the noise scale is comparable.

### 4.4 Outcome-dependent MAR (n = 3000, seed 21)

Same complete-data DGP. Missingness depends on `log(y)` (the lognormal
location scale; Gamma already used this):

```text
P(R_i = 0 | y_i)  =  logit⁻¹( −0.8 + 0.6 · scale(log y)_i )
```

```r
set.seed(21)
# ... same z, x, eta, y as MCAR ...
p_miss <- stats::plogis(-0.8 + 0.6 * scale(log(y))[, 1])
d$x[stats::runif(n) < p_miss] <- NA
expect_true(mean(is.na(d$x)) > 0.1)
```

Same three coefficient assertions at **tolerance 0.20**.

MCAR-only is plumbing. MAR is required to claim the cell (A7 consumer
contract §3.6; Gamma DoD).

---

## 5. Tolerances — start at Gamma's 0.15 / 0.20

House standard for one-binary-predictor G3
(`mp-nbinom2-bernoulli`, `mp-beta-bernoulli`, `mp-binomial-bernoulli`,
`mp-gamma-bernoulli`):

| Mechanism | Tol | Why |
|---|---|---|
| logLik identity | `1e-6` | same leaf, same 2-point sum; not Monte Carlo |
| MCAR n = 3000 | **0.15** | ~600 missing binary rows; FE only |
| MAR n = 3000 | **0.20** | outcome-dependent slack Gamma already needed |
| sentinel fn/gr | `1e-8` | retaped objective; see §6 |

**Do not loosen on first failure.** Partition:

1. Identity fails, recovery wild → missing `case 4` leaf (returns 0) or
   skip-mask missing (double count).
2. Identity passes, `coef(mu)` near `exp(0.4)` ≈ 1.5 → engine `exp(eta)`'d
   a meanlog. Fix C++, not the test.
3. Identity passes, `sigma` off by `log` vs raw → extractor / link
   mismatch (`log(0.3)` vs `0.3`).
4. All three coefs miss by ~0.16–0.18 on one seed → then, and only then,
   consider `0.18` / `0.22` with a note. Do not jump to 0.25 (that is the
   k=2 Gaussian MAR band).

This is a single-seed point-fit recovery, not G4/G5 coverage. Over-coverage
rules in the validation harness do not apply.

Speed: two n = 3000 FE fits + one n = 90 identity + one refuse. Same cost
as the Gamma file. Totoro-local is enough; no replicated grid.

---

## 6. Sentinel-invariance — applicable, cheap, not in the Gamma file

### Applicable: missing-**predictor** dummy fill

Binary `mi()` does not store a continuous latent `x_miss`. The 2-point sum
must ignore whatever placeholder sits in `tmb_data$mi_x` (and the dummy in
`X_μ[, mi_col]`) at `mi_observed == 0`. Gamma omitted this check; the k=2
Gaussian file has the pattern
(`test-missing-predictor-two-gaussian.R`, helper
`missing_response_retaped_object`).

Recommended fifth test:

```r
test_that("lognormal-response binary mi() is dummy-fill invariant at missing rows", {
  dat <- missing_predictor_lognormal_response_data()
  fit <- fit_missing_predictor_lognormal_response(dat)
  tmb_data <- fit$model$tmb_data
  miss <- which(as.integer(tmb_data$mi_observed) == 0L)
  expect_true(length(miss) > 0L)

  data_a <- tmb_data
  data_b <- tmb_data
  data_a$mi_x[miss] <- 1
  data_b$mi_x[miss] <- 0
  expect_false(identical(data_a$mi_x[miss], data_b$mi_x[miss]))

  obj_a <- missing_response_retaped_object(fit, data_a)
  obj_b <- missing_response_retaped_object(fit, data_b)
  par <- fit$opt$par
  expect_equal(obj_a$fn(par), obj_b$fn(par), tolerance = 1e-8)
  expect_equal(obj_a$gr(par), obj_b$gr(par), tolerance = 1e-8, ignore_attr = TRUE)
})
```

If C++ reads `mi_x` on missing rows as if observed, fn/gr will diverge.
If the 2-point sum is correct, 0 vs 1 (or `1e6` vs `-1e6`) is invisible.

`X_μ` dummy cancellation is already in the identity algebra
(`β_x (x_state − x_base)`). A second retape that mutates `X_mu` at missing
rows is optional; `mi_x` is the cheaper catch.

### Not this cell: missing-**response** sentinel

`mr-lognormal` already has support-safe y-sentinel invariance
(`test-missing-response-continuous.R`). Gamma's first `mi()` slice
**aborts** `response = "include"` together with `predictor = "model"`.
Do not add a y-sentinel test here, and do not combine the two missingness
routes.

---

## 7. Fail-loud leftovers (must stay loud)

Required in the same file (case 4 above):

| Input | Must abort with |
|---|---|
| `mi(biomass)` + `impute_model(biomass ~ z, family = Gamma(link = "log"))` (or `gaussian()` / `lognormal()`) | `"binary missing predictor"` |

After the whitelist moves, these stay **outside** this cell — assert in
`test-missing-data-capability-gate.R` / existing leftovers, do not weaken:

| Leftover | Gate |
|---|---|
| student / tweedie / zi-* / beta_binomial **response** + `predictor = "model"` | still `"models are currently validated only"` |
| lognormal × k = 2 | `"exactly one"` / k-not-implemented |
| lognormal `mi()` + RE / structured on `mu` | Gamma's `"fixed-effect mu/sigma only"` clone |
| lognormal `mi()` + `miss_control(response = "include")` | Gamma's `"not implemented together"` clone |
| `mi()` on `sigma` | existing syntax refuse |

Capability-gate edits the engine sibling must land **with** the whitelist,
not before:

- Add `"lognormal"` to `predictor_validated` in
  `tests/testthat/test-missing-data-capability-gate.R`.
- Remove `"lognormal"` from the reject loop
  `for (ft in c("tweedie", "lognormal"))`.
- Update the user-facing abort in `R/drmTMB.R` (~398–407) to name
  lognormal among the one-binary-predictor responses.

Do not add student or zi-* to either list.

---

## 8. Ledger / consumer (engine sibling, not this note)

When recovery is green:

1. New `missing_predictor` row `mp-lognormal-bernoulli`, tier
   `point_fit_recovery` / G3, claim_boundary: not continuous predictor,
   not k ≥ 2, not `impute_joint`, not FIML, not student/zi-*.
2. Evidence id `ev-mp-lognormal-bernoulli-g3` pointing at this test file.
3. drmSEM consumer (separate lane) lifts `drm_impute_response_families()`
   only after that row exists. V-80 stays the anti-drift lock.

---

## 9. Paste-ready skeleton

Engine sibling fills this into
`tests/testthat/test-missing-predictor-lognormal-response.R`.
Helpers stay local to the file (Gamma style). Do not share a helper with
`test-missing-predictor-lognormal.R`.

```r
# S6 A7 / #962: missing-PREDICTOR mi() with a lognormal log-location
# response (model_type 4). One binary missing predictor. The 2-point-sum
# density is dlnorm(y; meanlog = eta, sdlog = exp(log_sigma)).
# eta is identity-link meanlog — do NOT exp(eta). Mirror of
# test-missing-predictor-gamma-response.R (mp-gamma-bernoulli).

lognormal_response_log_density <- function(y, eta, log_sigma) {
  stats::dlnorm(y, meanlog = eta, sdlog = exp(log_sigma), log = TRUE)
}

missing_predictor_lognormal_response_data <- function() {
  n <- 90
  z <- seq(-1.6, 1.7, length.out = n)
  treatment_full <- as.numeric(sin(seq_len(n) * 1.3) + 0.3 * z > 0)
  eta <- 0.3 + 0.4 * z + 0.6 * treatment_full
  y <- exp(eta + 0.2 * cos(seq_len(n) / 4))
  dat <- data.frame(
    y = y,
    z = z,
    treatment = factor(treatment_full, levels = c(0, 1))
  )
  dat$treatment[c(8, 19, 31, 46, 57, 70, 83)] <- NA
  dat
}

fit_missing_predictor_lognormal_response <- function(dat) {
  drmTMB(
    bf(y ~ z + mi(treatment), sigma ~ 1),
    data = dat,
    family = lognormal(),
    impute = list(
      treatment = impute_model(treatment ~ z, family = binomial())
    ),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
}

manual_lognormal_response_binary_mi_loglik <- function(fit) {
  dat <- fit$model$data
  model <- fit$model$missing_predictor
  observed_x <- fit$missing_data$predictors$treatment$observed
  beta_mu <- coef(fit, "mu")
  beta_mi <- coef(fit, "mi_treatment")
  log_sigma <- as.numeric(coef(fit, "sigma"))
  eta_x <- as.vector(model$X %*% beta_mi)
  log_p1 <- stats::plogis(eta_x, log.p = TRUE)
  log_p0 <- stats::plogis(eta_x, lower.tail = FALSE, log.p = TRUE)
  eta_base <- as.vector(fit$model$offset$mu + fit$model$X$mu %*% beta_mu)
  beta_x <- beta_mu[[model$mu_col]]
  x_base <- fit$model$X$mu[, model$mu_col]
  yv <- fit$model$y
  out <- numeric(nrow(dat))

  for (row in which(observed_x)) {
    x_row <- as.numeric(dat$treatment[[row]]) - 1
    out[[row]] <- if (x_row == 1) log_p1[[row]] else log_p0[[row]]
    out[[row]] <- out[[row]] +
      lognormal_response_log_density(yv[[row]], eta_base[[row]], log_sigma)
  }
  for (row in which(!observed_x)) {
    eta1 <- eta_base[[row]] + beta_x * (1 - x_base[[row]])
    eta0 <- eta_base[[row]] + beta_x * (0 - x_base[[row]])
    lp1 <- log_p1[[row]] +
      lognormal_response_log_density(yv[[row]], eta1, log_sigma)
    lp0 <- log_p0[[row]] +
      lognormal_response_log_density(yv[[row]], eta0, log_sigma)
    max_log <- max(lp1, lp0)
    out[[row]] <- max_log + log(exp(lp1 - max_log) + exp(lp0 - max_log))
  }
  sum(out)
}

test_that("binary mi() predictor works with a lognormal response likelihood", {
  dat <- missing_predictor_lognormal_response_data()
  fit <- fit_missing_predictor_lognormal_response(dat)

  expect_equal(fit$missing_data$predictors$treatment$family, "bernoulli")
  expect_equal(nobs(fit), nrow(dat))
  expect_true(all(is.finite(coef(fit, "mu"))))
  expect_true(all(is.finite(coef(fit, "mi_treatment"))))
  expect_equal(
    as.numeric(logLik(fit)),
    manual_lognormal_response_binary_mi_loglik(fit),
    tolerance = 1e-6
  )
})

test_that("Lognormal-response mi() recovers the meanlog, sdlog, and predictor model under MCAR", {
  set.seed(13)
  n <- 3000
  z <- rnorm(n)
  x <- rbinom(n, 1, stats::plogis(0.3 + 0.8 * z))
  eta <- 0.4 + 0.5 * z + 0.7 * x
  sdlog <- 0.3
  y <- stats::rlnorm(n, meanlog = eta, sdlog = sdlog)
  d <- data.frame(y = y, z = z, x = factor(x, levels = c(0, 1)))
  d$x[sample(n, round(0.2 * n))] <- NA

  fit <- drmTMB(
    bf(y ~ z + mi(x), sigma ~ 1),
    family = lognormal(),
    data = d,
    impute = list(x = impute_model(x ~ z, family = binomial())),
    missing = miss_control(predictor = "model")
  )
  expect_equal(unname(coef(fit, "mu")), c(0.4, 0.5, 0.7), tolerance = 0.15)
  expect_equal(unname(coef(fit, "sigma")), log(sdlog), tolerance = 0.15)
  expect_equal(unname(coef(fit, "mi_x")), c(0.3, 0.8), tolerance = 0.15)
})

test_that("Lognormal-response mi() recovers under outcome-dependent MAR", {
  set.seed(21)
  n <- 3000
  z <- rnorm(n)
  x <- rbinom(n, 1, stats::plogis(0.3 + 0.8 * z))
  eta <- 0.4 + 0.5 * z + 0.7 * x
  sdlog <- 0.3
  y <- stats::rlnorm(n, meanlog = eta, sdlog = sdlog)
  d <- data.frame(y = y, z = z, x = factor(x, levels = c(0, 1)))
  p_miss <- stats::plogis(-0.8 + 0.6 * scale(log(y))[, 1])
  d$x[stats::runif(n) < p_miss] <- NA
  expect_true(mean(is.na(d$x)) > 0.1)

  fit <- drmTMB(
    bf(y ~ z + mi(x), sigma ~ 1),
    family = lognormal(),
    data = d,
    impute = list(x = impute_model(x ~ z, family = binomial())),
    missing = miss_control(predictor = "model")
  )
  expect_equal(unname(coef(fit, "mu")), c(0.4, 0.5, 0.7), tolerance = 0.20)
  expect_equal(unname(coef(fit, "sigma")), log(sdlog), tolerance = 0.20)
  expect_equal(unname(coef(fit, "mi_x")), c(0.3, 0.8), tolerance = 0.20)
})

test_that("Lognormal-response mi() still refuses a non-binary predictor", {
  dat <- missing_predictor_lognormal_response_data()
  dat$biomass <- exp(dat$z)
  dat$biomass[c(4, 21)] <- NA

  expect_error(
    drmTMB(
      bf(y ~ z + mi(biomass), sigma ~ 1),
      data = dat,
      family = lognormal(),
      impute = list(
        biomass = impute_model(biomass ~ z, family = stats::Gamma(link = "log"))
      ),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "binary missing predictor"
  )
})
```

Optional sentinel block: paste from §6 after the identity test.

---

## 10. What this note did not do

- No C++. No whitelist edit. No ledger write. No package test run
  (engine cell does not exist yet; identity would abort at the gate).
- Did not edit `test-missing-predictor-lognormal.R` (wrong axis).
- Did not implement the test file in `tests/testthat/` — skeleton lives
  here for sibling `67a70b94` to land with the C++.
- drmSEM consumer lift is a later lane after the engine row exists.

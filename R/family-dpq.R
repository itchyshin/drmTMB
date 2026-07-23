# DO-T0a foundation for the distributional output & adequacy layer
# (issues #747/#748; see docs/dev-log/2026-07-12-distributional-output-adequacy-layer-ultra-plan.md).
#
# `drm_family_dpq()` is a model_type-keyed switch() that MIRRORS
# `drm_dpar_link()` (methods.R:5057-5097), for the same reason: only 11/18
# routes carry a `drm_family()` constructor object, so the per-family
# density/CDF/quantile registry cannot attach to that object either
# (methods.R:5057-5069 explains why the link table itself is a switch, not a
# field on `drm_family`). Add a case here in the SAME model_type order as
# `drm_dpar_link()` when a family is promoted; keep the two switches
# side-by-side in a reviewer's diff.
#
# Each switch case returns a list:
#   dpars     - character vector of native dpar names the closures consume
#               (read from the wide `params` data frame built by
#               fitted_distribution_params())
#   d, p, q   - function(y_or_u, params) closures: density, CDF, quantile,
#               evaluated at the per-row fitted parameters in `params`
#   discrete  - TRUE if the response is integer-valued
#   has_atom  - TRUE if the distribution places positive mass on isolated
#               points that are not the whole discrete support (e.g. Tweedie
#               1<nu<2 has an atom at 0 but is otherwise continuous)
#   atoms     - numeric vector of isolated atom LOCATIONS (DO-T3 batch C):
#               numeric(0) for atom-free/purely-discrete families, c(0) for
#               Tweedie/zi_poisson/zi_nbinom2/hurdle_nbinom2 (the atom at
#               y = 0 -- discrete count families carry this only for DG2's
#               atom-enumeration bookkeeping; drm_quantile_residual_u()'s
#               left-limit rule for them is the ordinary discrete F(y-1) rule,
#               not this field), c(0, 1) for zero_one_beta. Consumed by
#               drm_quantile_residual_u() (R/adequacy.R) to generalize the
#               Dunn-Smyth left limit F(y-) beyond a hardcoded atom-at-0
#               assumption; additive (every family sets it, frozen closure
#               signature unchanged).
#   status    - fixed enum "unimplemented" / "spike" / "reference":
#               "reference" = DG2/DG3 verified + promoted; "spike" =
#               feasibility-only, NOT promoted past diagnostic_hold;
#               "unimplemented" = no entry (drm_family_dpq() aborts before
#               returning). Consumers (DO-T1 residual gate, DO-T3 ledger
#               grader) read this to decide what to expose. As of DO-T3 batch
#               D, all 18 fitted model_type values are "reference"
#               (base-R-closed-form, hand-derived, atom/mixture-decomposition,
#               or bivariate-marginal DG2 pass; see the batch-A/B/C/D
#               after-task reports); the "unimplemented" abort branch is now
#               defensive-only (unreachable via any live drmTMB() fit's
#               model_type, kept so a future new model_type fails loudly
#               rather than silently). Enum locked at CP1.
#
# Noether's trap: the public -> native parameter map is family-specific and
# NON-identity. A generic `pFAMILY(y, mu, sigma)` is wrong. Each case below
# must use the exact transform the compiled `src/drmTMB.cpp` density uses, and
# is cross-checked against `exp(compiled log-density)` at fixed params (see
# the DO-T0a verification script referenced in the after-task report).
#
# Weights caveat (Noether, CP1): the d/p/q closures give the UNWEIGHTED
# per-observation distribution -- the correct object for quantile residuals,
# CDF, exceedance and quantiles. The compiled nll additionally multiplies by
# prior `weights(i)` (src/drmTMB.cpp:636), so `-sum(log(d(y)))` matches the
# compiled nll only for unit-weight fits; that is expected, not a discrepancy.

#' Per-family density/CDF/quantile registry (internal)
#'
#' `drm_family_dpq()` returns the `{d, p, q}` closures and atom metadata for a
#' fitted model's `model_type`. It is the single source of truth that
#' [fitted_distribution()] and downstream consumers (planned: quantile
#' residuals, `predict(type = "quantile")`, `exceedance()`) route through, so
#' the public-to-native parameter conversion is not re-derived in each caller.
#'
#' As of DO-T3 batch D, these 18 established fitted `model_type` values are
#' promoted
#' (`status = "reference"`): `"gaussian"`, `"student"`, `"skew_normal"`,
#' `"lognormal"`, `"gamma"`, `"tweedie"`, `"beta"`, `"zero_one_beta"`,
#' `"beta_binomial"`, `"binomial"`, `"cumulative_logit"`, `"poisson"`,
#' `"zi_poisson"`, `"nbinom2"`, `"truncated_nbinom2"`, `"hurdle_nbinom2"`,
#' `"zi_nbinom2"`, and `"biv_gaussian"`.
#' **`"skew_normal"` promotion is a distributional-output-axis result only**
#' (DG2/DG3 for `{d,p,q}` correctness); it does not certify the skew_normal
#' family's own fit-quality status (`diagnostic_hold` in `check_drmTMB()`),
#' which is a separate axis and is unchanged -- see the firewall note beside
#' `drm_family_dpq_skew_normal()`. **`"biv_gaussian"` is MARGINAL-only**: its
#' `{d,p,q}` describe one response's marginal `N(mu_k, sigma_k)` (exact,
#' independent of `rho12`), never the joint bivariate distribution -- see
#' `drm_family_dpq_biv_gaussian()` and [fitted_distribution()]'s `response`
#' argument, which selects `k`. The later exact-special development families
#' `"biv_lognormal"` and `"biv_student"` are deliberately excluded from this
#' marginal distribution-output registry; their density/CDF/quantile,
#' residual, and adequacy surfaces require separate validation.
#'
#' The `d`/`p`/`q` closures take `(y_or_u, params)`, where `params` is a wide,
#' one-row-per-observation data frame. This signature is **frozen** (CP1): a
#' family needing extra per-row context beyond its dpars -- binomial/
#' beta_binomial `trials`, cumulative_logit ordinal cutpoints (`CP1`..`CPk`),
#' truncation bounds, mixture weights -- attaches it as an extra `params`
#' column inside `fitted_distribution_params()`, never by changing the
#' closure signature.
#'
#' @param object A `drmTMB` fit.
#' @return A list with elements `dpars`, `d`, `p`, `q`, `discrete`,
#'   `has_atom`, `atoms`, `status`.
#' @keywords internal
drm_family_dpq <- function(object) {
  entry <- switch(
    object$model$model_type,
    gaussian = drm_family_dpq_gaussian(),
    student = drm_family_dpq_student(),
    skew_normal = drm_family_dpq_skew_normal(),
    lognormal = drm_family_dpq_lognormal(),
    gamma = drm_family_dpq_gamma(),
    tweedie = drm_family_dpq_tweedie(),
    beta = drm_family_dpq_beta(),
    zero_one_beta = drm_family_dpq_zero_one_beta(),
    beta_binomial = drm_family_dpq_beta_binomial(),
    binomial = drm_family_dpq_binomial(),
    cumulative_logit = drm_family_dpq_cumulative_logit(),
    poisson = drm_family_dpq_poisson(),
    zi_poisson = drm_family_dpq_zi_poisson(),
    nbinom2 = drm_family_dpq_nbinom2(),
    truncated_nbinom2 = drm_family_dpq_truncated_nbinom2(),
    hurdle_nbinom2 = drm_family_dpq_hurdle_nbinom2(),
    zi_nbinom2 = drm_family_dpq_zi_nbinom2(),
    biv_gaussian = drm_family_dpq_biv_gaussian(),
    cli::cli_abort(c(
      "{.fn drm_family_dpq} does not yet cover model type {.val {object$model$model_type}}.",
      i = "Per-family density/CDF/quantile rollout for the remaining model types is staged for a later phase (DO-T3)."
    ))
  )
  # `status` is a fixed enum consumers gate on; a returned entry is "spike" or
  # "reference" ("unimplemented" is the abort branch above).
  entry$status <- match.arg(entry$status, c("spike", "reference"))
  entry
}

# ---- gaussian (reference) --------------------------------------------------

drm_family_dpq_gaussian <- function() {
  list(
    dpars = c("mu", "sigma"),
    discrete = FALSE,
    has_atom = FALSE,
    atoms = numeric(0),
    status = "reference",
    d = function(y, params) {
      stats::dnorm(y, mean = params$mu, sd = drm_gaussian_obs_sigma(params))
    },
    p = function(y, params) {
      stats::pnorm(y, mean = params$mu, sd = drm_gaussian_obs_sigma(params))
    },
    q = function(u, params) {
      stats::qnorm(u, mean = params$mu, sd = drm_gaussian_obs_sigma(params))
    }
  )
}

# Gaussian total observation SD, matching src/drmTMB.cpp's
# `obs_sigma = sqrt(V_known + sigma * sigma)` (the meta-analysis known-sampling
# -variance case; V_known is 0 for ordinary gaussian fits). `params$V_known` is
# attached by `fitted_distribution_params()`; if absent (older caller), treat
# as an ordinary (non-meta) fit. Routes through `drm_total_obs_sd()`
# (R/methods.R), the SAME helper `observation_sigma()` (methods.R) calls, so
# the sqrt(V_known + sigma^2) formula has one source of truth instead of being
# re-derived here (Emmy's dedup, DO-T3 batch A prelude).
drm_gaussian_obs_sigma <- function(params) {
  v_known <- params$V_known
  if (is.null(v_known)) {
    v_known <- 0
  }
  drm_total_obs_sd(v_known, params$sigma)
}

# ---- tweedie (reference, atom family, DO-T3 batch C) -----------------------
#
# Compound Poisson-gamma with an atom at y = 0 for 1 < nu < 2. The compiled
# density is TMB's built-in `dtweedie(y, mu, phi, nu, log = TRUE)`
# (src/drmTMB.cpp model_type == 16), with public sigma -> native phi = sigma^2
# and native nu = 1 + plogis(eta_nu) (the "logit12" link). `tweedie::dtweedie`/
# `ptweedie`/`qtweedie` use the same (mu, phi, power) parameterization, so no
# transform beyond the public->native map above is needed. Requires the
# `tweedie` package (Suggests-guarded via `drm_require_tweedie()`, which
# aborts with a clear message if it is not installed -- unchanged by this
# batch's promotion; `{d,p,q}` correctness does not depend on adding a hard
# runtime dependency).
#
# DO-T3 batch C atom-decomposition DG2: the single atom is at y = 0
# (`atoms = c(0)`); normalization is `P(Y = 0) + integral_{(0,Inf)} d(y) dy
# = 1`, where `P(Y = 0) = tweedie::dtweedie(0, mu, phi, power)` (the compound
# Poisson-gamma's zero-count probability under a Poisson(mu^(2-power) /
# (phi*(2-power))) number of gamma jumps) -- this WAS the DO-T0a spike's
# original CDF-identity check (`p(0) == d(0)`, still true); batch C formalizes
# it as an explicit atom-decomposition test
# (tests/testthat/test-family-dpq-batchC.R) alongside the p-q inverse
# identity and DG3 smoke, and flips `status` to `"reference"`.

drm_family_dpq_tweedie <- function() {
  list(
    dpars = c("mu", "sigma", "nu"),
    discrete = FALSE,
    has_atom = TRUE,
    atoms = c(0),
    status = "reference",
    d = drm_tweedie_dpq(tweedie::dtweedie),
    p = drm_tweedie_dpq(tweedie::ptweedie),
    q = drm_tweedie_dpq(tweedie::qtweedie)
  )
}

drm_require_tweedie <- function() {
  if (!requireNamespace("tweedie", quietly = TRUE)) {
    cli::cli_abort(c(
      "The {.pkg tweedie} package is required for Tweedie {.fn d}/{.fn p}/{.fn q} evaluation.",
      i = "Install it with {.code install.packages(\"tweedie\")}."
    ))
  }
  invisible(TRUE)
}

# `tweedie::{d,p,q}tweedie()` require `power` to be a SINGLE scalar (their
# `sort_notation()` rejects a per-row power vector); this is a real limitation
# of the external package, not a bug in the fitted `nu`. When the fitted `nu`
# is row-constant (the common case: `nu ~ 1`), call the vectorised form
# directly; otherwise (row-varying `nu ~ x` formulas) fall back to one call
# per row.
drm_tweedie_dpq <- function(fun) {
  function(y, params) {
    drm_require_tweedie()
    n <- length(y)
    mu <- rep(params$mu, length.out = n)
    phi <- rep(params$sigma, length.out = n)^2
    power <- rep(params$nu, length.out = n)
    if (length(unique(power)) == 1L) {
      return(fun(y, mu = mu, phi = phi, power = power[1]))
    }
    vapply(
      seq_len(n),
      function(i) fun(y[i], mu = mu[i], phi = phi[i], power = power[i]),
      numeric(1)
    )
  }
}

# ---- skew_normal (reference, DO-T3 batch B) --------------------------------
#
# The CDF has no elementary closed form (it is Owen's-T:
# F(y) = Phi(z) - 2*T(z, nu), z = (y - xi) / omega). No `sn`-package
# dependency is added: `p()` numerically integrates the compiled density via
# `stats::integrate()`, and `q()` numerically inverts `p()` via
# `stats::uniroot()` -- this is unavoidable regardless of package, since even
# `sn::qsn()` numerically inverts `psn()`. The (xi, omega, alpha) native
# parameters are the SAME moment-inversion the compiled density
# (src/drmTMB.cpp:2441-2447, model_type == 17) and `rskew_normal_public()`
# (methods.R) use, via the single shared helper `drm_skew_normal_moments()`
# (Emmy's dedup, DO-T3 batch B prelude) -- both routes call it rather than
# each re-deriving delta/omega/xi.
#
# FIREWALL (Rose, DO-T3 batch B): promoting this {d,p,q} entry to
# `status = "reference"` certifies CDF/quantile correctness on the
# distributional-output axis (DG2: compiled-density agreement, an
# independent bivariate-normal CDF identity, and p-q inverse identity; DG3:
# a local quantile-residual smoke pass). It does NOT certify, and must not be
# read as certifying, that the skew_normal FAMILY is inference-ready: the
# family's own fit-quality gate (`check_drmTMB()`, `check_skew_normal_nu()`,
# R/check.R) is a SEPARATE axis and keeps its own `diagnostic_hold` status
# unchanged by this file. Do not touch `check_drmTMB()` or the family's
# `diagnostic_hold` status when working on this closure.

drm_family_dpq_skew_normal <- function() {
  list(
    dpars = c("mu", "sigma", "nu"),
    discrete = FALSE,
    has_atom = FALSE,
    atoms = numeric(0),
    status = "reference",
    d = function(y, params) {
      drm_skew_normal_density(y, params)
    },
    p = function(y, params) {
      drm_skew_normal_cdf(y, params)
    },
    q = function(u, params) {
      drm_skew_normal_quantile(u, params)
    }
  )
}

# (xi, omega, alpha, delta) moment inversion for the skew-normal, shared by
# the compiled density's native map, drm_skew_normal_native() (params-table
# path below) and rskew_normal_public() (methods.R simulate() path):
# alpha = nu, delta = alpha / sqrt(1 + alpha^2),
# omega = sigma / sqrt(1 - delta^2 * 2/pi), xi = mu - omega * delta * sqrt(2/pi).
drm_skew_normal_moments <- function(mu, sigma, nu) {
  alpha <- nu
  delta <- alpha / sqrt(1 + alpha^2)
  mean_shift <- delta * sqrt(2 / pi)
  omega <- sigma / sqrt(1 - mean_shift^2)
  xi <- mu - omega * mean_shift
  list(xi = xi, omega = omega, alpha = alpha, delta = delta)
}

drm_skew_normal_native <- function(params) {
  drm_skew_normal_moments(params$mu, params$sigma, params$nu)
}

drm_skew_normal_density <- function(y, params) {
  native <- drm_skew_normal_native(params)
  z <- (y - native$xi) / native$omega
  (2 / native$omega) * stats::dnorm(z) * stats::pnorm(native$alpha * z)
}

# Numeric-integration CDF, evaluated one row at a time (vectorised only over
# rows, not speed-optimised -- DO-T3 concern). DG2 normalization trap (found
# promoting to "reference" in batch B): `stats::integrate()`'s adaptive
# quadrature silently returns ~0 (not an error) when asked to integrate over
# an astronomically wide interval (e.g. `y` at `xi +/- 1e4*omega`, the kind
# of far-tail boundary DG2's normalization check uses for other continuous
# families) -- the density's mass is too concentrated relative to the
# interval width for the default subdivision budget to find it. `+/- 40
# * omega` already integrates to 1 (to float precision) since the
# skew-normal's tails decay at a Gaussian rate, so `y` beyond that band is
# clamped directly to 0/1 rather than handed to `integrate()`.
drm_skew_normal_cdf <- function(y, params) {
  native <- drm_skew_normal_native(params)
  n <- length(y)
  out <- numeric(n)
  for (i in seq_len(n)) {
    xi_i <- rep(native$xi, length.out = n)[i]
    omega_i <- rep(native$omega, length.out = n)[i]
    alpha_i <- rep(native$alpha, length.out = n)[i]
    lower <- xi_i - 40 * omega_i
    upper <- xi_i + 40 * omega_i
    if (y[i] <= lower) {
      out[i] <- 0
      next
    }
    if (y[i] >= upper) {
      out[i] <- 1
      next
    }
    dens_i <- function(t) {
      z <- (t - xi_i) / omega_i
      (2 / omega_i) * stats::dnorm(z) * stats::pnorm(alpha_i * z)
    }
    out[i] <- stats::integrate(
      dens_i,
      lower = lower,
      upper = y[i],
      rel.tol = 1e-8,
      subdivisions = 500L
    )$value
  }
  pmin(pmax(out, 0), 1)
}

drm_skew_normal_quantile <- function(u, params) {
  native <- drm_skew_normal_native(params)
  n <- length(u)
  out <- numeric(n)
  for (i in seq_len(n)) {
    xi_i <- rep(native$xi, length.out = n)[i]
    omega_i <- rep(native$omega, length.out = n)[i]
    alpha_i <- rep(native$alpha, length.out = n)[i]
    target <- function(t) {
      drm_skew_normal_cdf_native(t, xi_i, omega_i, alpha_i) - u[i]
    }
    lo <- xi_i - 40 * omega_i
    hi <- xi_i + 40 * omega_i
    out[i] <- stats::uniroot(target, lower = lo, upper = hi, tol = 1e-8)$root
  }
  out
}

drm_skew_normal_cdf_native <- function(y, xi, omega, alpha) {
  dens <- function(t) {
    z <- (t - xi) / omega
    (2 / omega) * stats::dnorm(z) * stats::pnorm(alpha * z)
  }
  stats::integrate(
    dens,
    lower = xi - 40 * omega,
    upper = y,
    rel.tol = 1e-8,
    subdivisions = 500L
  )$value
}

# ---- student (reference) ---------------------------------------------------
#
# Location-scale Student-t: sigma is a SCALE, NOT the response SD (Noether's
# trap). Compiled density (src/drmTMB.cpp:2404-2418, model_type == 3):
# z = (y - mu) / sigma, log_density = log(dt(z, df = nu)) - log(sigma). This
# is exactly `stats::dt(z, df = nu) / sigma` (the location-scale-t density),
# so F(y) = pt((y - mu) / sigma, df = nu) with no further transform. The same
# (mu, sigma, nu) native map is what `simulate.drmTMB()`'s student branch
# already uses (methods.R: `mu + sigma * rt(df = nu)`); no separate helper is
# needed since the map is an identity on (mu, sigma, nu), not a derived
# formula.

drm_family_dpq_student <- function() {
  list(
    dpars = c("mu", "sigma", "nu"),
    discrete = FALSE,
    has_atom = FALSE,
    atoms = numeric(0),
    status = "reference",
    d = function(y, params) {
      stats::dt((y - params$mu) / params$sigma, df = params$nu) / params$sigma
    },
    p = function(y, params) {
      stats::pt((y - params$mu) / params$sigma, df = params$nu)
    },
    q = function(u, params) {
      params$mu + params$sigma * stats::qt(u, df = params$nu)
    }
  )
}

# ---- lognormal (reference) -------------------------------------------------
#
# Compiled density (src/drmTMB.cpp:2494-2499, model_type == 4):
# `log_density = dnorm(log(y), mu, sigma, log = TRUE) - log(y)`, i.e. the
# lognormal density INCLUDING the `-log(y)` Jacobian of the log transform.
# `stats::dlnorm(y, meanlog, sdlog)` already applies this Jacobian internally,
# so `d()` below needs no extra term. Noether's trap: the CDF does NOT carry
# a `-log(y)` term (it is a monotone reparametrisation of a probability, not
# a density) -- `stats::plnorm(y, meanlog = mu, sdlog = sigma)` is exactly
# right and nothing must be added. Matches `simulate.drmTMB()`'s lognormal
# branch (methods.R: `stats::rlnorm(meanlog = mu, sdlog = sigma)`); the
# (mu, sigma) native map is an identity, so no separate helper is needed.

drm_family_dpq_lognormal <- function() {
  list(
    dpars = c("mu", "sigma"),
    discrete = FALSE,
    has_atom = FALSE,
    atoms = numeric(0),
    status = "reference",
    d = function(y, params) {
      stats::dlnorm(y, meanlog = params$mu, sdlog = params$sigma)
    },
    p = function(y, params) {
      stats::plnorm(y, meanlog = params$mu, sdlog = params$sigma)
    },
    q = function(u, params) {
      stats::qlnorm(u, meanlog = params$mu, sdlog = params$sigma)
    }
  )
}

# ---- gamma (reference) ------------------------------------------------------
#
# Public (mu, sigma) -> native (shape, scale): shape = 1 / sigma^2,
# scale = mu * sigma^2, matching the compiled density
# (src/drmTMB.cpp:2576-2578, model_type == 5). `drm_gamma_shape_scale()` is
# the SAME conversion `simulate.drmTMB()`'s gamma branch calls (methods.R,
# `simulate.drmTMB` gamma case) -- both routes call this one helper rather
# than each re-deriving `1 / sigma^2` / `mu * sigma^2`.

drm_gamma_shape_scale <- function(mu, sigma) {
  list(shape = 1 / sigma^2, scale = mu * sigma^2)
}

drm_family_dpq_gamma <- function() {
  list(
    dpars = c("mu", "sigma"),
    discrete = FALSE,
    has_atom = FALSE,
    atoms = numeric(0),
    status = "reference",
    d = function(y, params) {
      native <- drm_gamma_shape_scale(params$mu, params$sigma)
      stats::dgamma(y, shape = native$shape, scale = native$scale)
    },
    p = function(y, params) {
      native <- drm_gamma_shape_scale(params$mu, params$sigma)
      stats::pgamma(y, shape = native$shape, scale = native$scale)
    },
    q = function(u, params) {
      native <- drm_gamma_shape_scale(params$mu, params$sigma)
      stats::qgamma(u, shape = native$shape, scale = native$scale)
    }
  )
}

# ---- beta (reference) --------------------------------------------------------
#
# Public (mu, sigma) -> native (shape1, shape2): phi = 1 / sigma^2,
# shape1 = mu * phi, shape2 = (1 - mu) * phi, matching the compiled density
# (src/drmTMB.cpp:2740-2769, model_type == 10 -- the "beta" family; NOT
# model_type == 15, which is "zero_one_beta"). `drm_beta_shapes()` is the SAME
# conversion `simulate.drmTMB()`'s "beta" branch calls (methods.R). The
# compiled density additionally floors alpha/beta_shape at 1e-8
# (`CppAD::CondExpLt`) to guard against numeric underflow at extreme (mu,
# sigma); `stats::{d,p,q}beta()` does not apply that floor, so `d()`/`p()`/
# `q()` here can differ from the compiled density at pathological (near-0,
# near-1, huge-phi) parameter combinations. This is expected to be
# undetectable at the fixed theta vectors DG2 exercises (interior mu, modest
# phi) and is flagged as a residual uncertainty, not silently ignored.
# `"beta_binomial"`'s duplicate was closed in DO-T3 batch B and
# `"zero_one_beta"`'s in DO-T3 batch C (see each family's section below and
# its batch's dedup note); `simulate.drmTMB()`'s `"zero_one_beta"` branch now
# calls `drm_beta_shapes()` too.

drm_beta_shapes <- function(mu, sigma) {
  phi <- 1 / sigma^2
  list(shape1 = mu * phi, shape2 = (1 - mu) * phi)
}

drm_family_dpq_beta <- function() {
  list(
    dpars = c("mu", "sigma"),
    discrete = FALSE,
    has_atom = FALSE,
    atoms = numeric(0),
    status = "reference",
    d = function(y, params) {
      native <- drm_beta_shapes(params$mu, params$sigma)
      stats::dbeta(y, shape1 = native$shape1, shape2 = native$shape2)
    },
    p = function(y, params) {
      native <- drm_beta_shapes(params$mu, params$sigma)
      stats::pbeta(y, shape1 = native$shape1, shape2 = native$shape2)
    },
    q = function(u, params) {
      native <- drm_beta_shapes(params$mu, params$sigma)
      stats::qbeta(u, shape1 = native$shape1, shape2 = native$shape2)
    }
  )
}

# ---- zero_one_beta (reference, atom family, DO-T3 batch C) -----------------
#
# Zero-one-inflated beta: atoms at BOTH boundaries (y = 0, y = 1) plus an
# interior beta component. Public dpars `(mu, sigma, zoi, coi)`; `zoi` is
# `P(boundary) = P(Y in {0, 1})`, `coi` is `P(Y = 1 | boundary)`, matching the
# compiled kernel exactly (src/drmTMB.cpp:2782-2858, model_type == 15):
# `P(Y = 0) = zoi * (1 - coi)`, `P(Y = 1) = zoi * coi`, and the interior
# density for `0 < y < 1` is `(1 - zoi) * dbeta(y, shape1, shape2)` with
# `(shape1, shape2)` the SAME `drm_beta_shapes(mu, sigma)` conversion the
# "beta" family above uses (the compiled kernel's `phi(i) = exp(-2 *
# log_sigma(i))`, `alpha(i) = mu(i) * phi(i)`, `beta_shape(i) = (1 - mu(i)) *
# phi(i)`, floored at `1e-8` -- same undetected-at-DG2-tolerance floor gap
# flagged for "beta" above). Noether's trap: the compiled kernel additionally
# inflates `mu` away from the exact boundary by `1e-12`
# (`mu = 1e-12 + (1 - 2e-12) * plogis(eta_mu)`) purely to keep the AD tape
# well-defined at `mu` near 0/1; `predict(fit, dpar = "mu")` returns the plain
# `plogis(eta_mu)` (no epsilon), so `alpha`/`beta_shape` computed here can
# differ from the compiled kernel's by ~1e-12 * phi -- undetectable at DG2's
# `1e-8` density-agreement tolerance for the interior `mu`/modest `phi`
# fixed-theta vectors DG2 exercises, flagged here rather than silently
# ignored (same pattern as beta's `1e-8` floor gap).
#
# CDF: `F(y) = 0` for `y < 0`; `F(y) = P(Y = 0) + (1 - zoi) * pbeta(y, shape1,
# shape2)` for `0 <= y < 1` (this single formula already gives `F(0) =
# P(Y = 0)` exactly, since `pbeta(0, ...) = 0`); `F(y) = 1` for `y >= 1`.
# Quantile: `q(u) = qbeta((u - P(Y = 0)) / (1 - zoi), shape1, shape2)`
# clamped to `[0, 1]` before the `qbeta()` call -- this single closed-form
# expression is the correct right-inverse everywhere (clamped-to-0 input maps
# to `qbeta(0, ...) = 0` at/below the y = 0 atom's threshold, clamped-to-1
# input maps to `qbeta(1, ...) = 1` at/above `F(1-) = 1 - P(Y = 1)`), so no
# separate branch is needed for the two atoms, mirroring the "fraction"
# transform used by `zi_poisson`/`zi_nbinom2`/`hurdle_nbinom2` below.
#
# DG2 atom-decomposition (batch C): `atoms = c(0, 1)`; normalization is
# `P(Y = 0) + P(Y = 1) + integral_(0,1) (1 - zoi) * dbeta(y, ...) dy = 1`,
# i.e. `zoi * (1 - coi) + zoi * coi + (1 - zoi) * 1 = zoi + (1 - zoi) = 1`.
# External reference (independent of `simulate()`/the package's own
# likelihood): `stats::pbeta()` for the interior component plus the explicit
# `zoi`/`coi` atom-mass algebra above, hand-built in the test body (no single
# external package computes this exact zero-one-inflated-beta mixture).
#
# Emmy's batch-C dedup: `simulate.drmTMB()`'s `"zero_one_beta"` branch
# (methods.R) used to duplicate `phi <- 1 / sigma^2; shape1 <- mu * phi;
# shape2 <- (1 - mu) * phi` inline (flagged in batch A, left open in batch B);
# it now calls `drm_beta_shapes()` too, closing the last open duplicate of
# that formula.

drm_family_dpq_zero_one_beta <- function() {
  list(
    dpars = c("mu", "sigma", "zoi", "coi"),
    discrete = FALSE,
    has_atom = TRUE,
    atoms = c(0, 1),
    status = "reference",
    d = function(y, params) {
      native <- drm_beta_shapes(params$mu, params$sigma)
      zoi <- params$zoi
      coi <- params$coi
      interior <- (1 - zoi) *
        stats::dbeta(y, shape1 = native$shape1, shape2 = native$shape2)
      ifelse(y == 0, zoi * (1 - coi), ifelse(y == 1, zoi * coi, interior))
    },
    p = function(y, params) {
      native <- drm_beta_shapes(params$mu, params$sigma)
      zoi <- params$zoi
      coi <- params$coi
      p0 <- zoi * (1 - coi)
      y_clamped <- pmin(pmax(y, 0), 1)
      interior_cdf <- p0 +
        (1 - zoi) *
          stats::pbeta(y_clamped, shape1 = native$shape1, shape2 = native$shape2)
      ifelse(y < 0, 0, ifelse(y >= 1, 1, interior_cdf))
    },
    q = function(u, params) {
      native <- drm_beta_shapes(params$mu, params$sigma)
      zoi <- params$zoi
      coi <- params$coi
      p0 <- zoi * (1 - coi)
      frac <- pmin(pmax((u - p0) / (1 - zoi), 0), 1)
      stats::qbeta(frac, shape1 = native$shape1, shape2 = native$shape2)
    }
  )
}

# ---- beta_binomial (reference, discrete, DO-T3 batch B) ---------------------
#
# Beta-binomial: a beta-distributed success probability integrated out of a
# binomial count. Public (mu, sigma) -> native (alpha, beta_shape) is the
# SAME `drm_beta_shapes()` conversion the "beta" family above uses (phi =
# 1 / sigma^2, alpha = mu * phi, beta_shape = (1 - mu) * phi); phi is also
# the compiled kernel's `phi(i) = exp(-2 * log_sigma(i))`
# (src/drmTMB.cpp:2886-2892, model_type == 14). `drm_beta_binomial_dpmf()`
# below reproduces that block's exact lgamma pmf formula (no external
# dependency at runtime -- `extraDistr::dbbinom`/`pbbinom` are used only as
# the independent DG2 external reference in
# tests/testthat/test-family-dpq-batchB.R, a Suggests-guarded check, not a
# hard dependency of this closure). `p()`/`q()` are an exact `cumsum()` over
# the finite discrete support `0:trials` (per row, since `trials` varies by
# row) rather than a closed form -- there is no closed-form beta-binomial
# CDF. `trials` is attached as an extra `params` column (the SAME
# `drm_newdata_trials()` CP1-sanctioned pattern the "binomial" family below
# uses) since it is not a distributional parameter with a link. Emmy's
# batch-B dedup: `simulate.drmTMB()`'s "beta_binomial" branch (methods.R)
# used to duplicate `phi <- 1 / sigma^2; shape1 <- mu*phi; shape2 <-
# (1-mu)*phi` inline (flagged in batch A); it now calls `drm_beta_shapes()`
# too.

drm_beta_binomial_dpmf <- function(y, params) {
  native <- drm_beta_shapes(params$mu, params$sigma)
  alpha <- native$shape1
  beta_shape <- native$shape2
  phi <- alpha + beta_shape
  trials <- params$trials
  failures <- trials - y
  log_density <- lgamma(trials + 1) -
    lgamma(y + 1) -
    lgamma(failures + 1) +
    lgamma(phi) -
    lgamma(trials + phi) +
    lgamma(y + alpha) -
    lgamma(alpha) +
    lgamma(failures + beta_shape) -
    lgamma(beta_shape)
  exp(log_density)
}

# Row-wise exact cumsum of the pmf: for row i, sum drm_beta_binomial_dpmf()
# over k = 0..floor(y[i]), clamped to [0, trials[i]] (F(<0) = 0,
# F(>=trials) = 1). Looping per row (rather than vectorising over the
# response) keeps this simple and correct at the toy scale this closure is
# exercised at (DG2/DG3 local smoke); `trials` in these tests is a few dozen
# at most, so the per-row `0:k` pmf sum costs nothing observable.
drm_beta_binomial_p <- function(y, params) {
  n <- length(y)
  out <- numeric(n)
  for (i in seq_len(n)) {
    trials_i <- params$trials[i]
    k <- floor(y[i])
    if (k < 0) {
      out[i] <- 0
      next
    }
    if (k >= trials_i) {
      out[i] <- 1
      next
    }
    ks <- 0:k
    row_params <- list(
      mu = rep(params$mu[i], length(ks)),
      sigma = rep(params$sigma[i], length(ks)),
      trials = rep(trials_i, length(ks))
    )
    out[i] <- sum(drm_beta_binomial_dpmf(ks, row_params))
  }
  out
}

# Right-inverse quantile: the smallest k in 0:trials[i] with F(k) >= u[i],
# via the same per-row exact pmf/cumsum as drm_beta_binomial_p().
drm_beta_binomial_q <- function(u, params) {
  n <- length(u)
  out <- integer(n)
  for (i in seq_len(n)) {
    trials_i <- params$trials[i]
    ks <- 0:trials_i
    row_params <- list(
      mu = rep(params$mu[i], length(ks)),
      sigma = rep(params$sigma[i], length(ks)),
      trials = rep(trials_i, length(ks))
    )
    cdf <- cumsum(drm_beta_binomial_dpmf(ks, row_params))
    out[i] <- ks[which(cdf >= u[i])[1]]
  }
  out
}

drm_family_dpq_beta_binomial <- function() {
  list(
    dpars = c("mu", "sigma"),
    discrete = TRUE,
    has_atom = FALSE,
    atoms = numeric(0),
    status = "reference",
    d = function(y, params) drm_beta_binomial_dpmf(y, params),
    p = function(y, params) drm_beta_binomial_p(y, params),
    q = function(u, params) drm_beta_binomial_q(u, params)
  )
}

# ---- binomial (reference, discrete) -----------------------------------------
#
# Native map is the identity: mu IS the success probability (compiled density
# at src/drmTMB.cpp:2963-2980, model_type == 18); `d()`/`p()`/`q()` need only
# `mu` and the per-row `trials` denominator. `trials` is not a distributional
# parameter with a link (it has no entry in `drm_dpar_link()`), so it cannot
# be listed in `dpars`; it is attached as an extra `params` column inside
# [fitted_distribution_params()] instead, per the closure-signature-freeze
# contract (CP1) -- see that function's binomial branch below. Matches
# `simulate.drmTMB()`'s binomial branch (methods.R:
# `stats::rbinom(size = trials, prob = mu)`).

drm_family_dpq_binomial <- function() {
  list(
    dpars = c("mu"),
    discrete = TRUE,
    has_atom = FALSE,
    atoms = numeric(0),
    status = "reference",
    d = function(y, params) {
      stats::dbinom(y, size = params$trials, prob = params$mu)
    },
    p = function(y, params) {
      stats::pbinom(y, size = params$trials, prob = params$mu)
    },
    q = function(u, params) {
      stats::qbinom(u, size = params$trials, prob = params$mu)
    }
  )
}

# ---- cumulative_logit (reference, discrete, ordinal, DO-T3 batch B) --------
#
# Proportional-odds cumulative logit for K ordered categories, coded
# `1:K` matching `object$model$y` (see `ordinal_expected_score()`,
# methods.R). `mu` is the identity-link linear predictor (`drm_dpar_link()`:
# `cumulative_logit = c(mu = "identity")`); the natural distributional object
# is the CUMULATIVE category probability, not a location/scale pair, so the
# K-1 cutpoints -- not a dpar with a link -- are attached as extra `params`
# columns `CP1`..`CP(K-1)` inside [fitted_distribution_params()] (the
# CP1-sanctioned column-attachment pattern, same shape as binomial `trials`).
# Matches the compiled density exactly (src/drmTMB.cpp:2984-3048,
# model_type == 13): `logit(P(Y <= k)) = cutpoints[k] - mu`, i.e.
# `F(k) = plogis(cutpoints[k] - mu)` for `k = 1..K-1`, `F(K) = 1`, `F(0) = 0`;
# `d(k) = F(k) - F(k - 1)`. `drm_cumulative_logit_cutpoints()` reads the CPk
# columns back out of `params` (rather than needing the fitted `object`, kept
# out of the frozen `(y_or_u, params)` closure signature) so the same
# closure works for any fitted number of categories.

drm_cumulative_logit_cutpoints <- function(params) {
  cp_names <- grep("^CP[0-9]+$", names(params), value = TRUE)
  cp_order <- order(as.integer(sub("^CP", "", cp_names)))
  as.matrix(params[cp_names[cp_order]])
}

# F(k) = P(Y <= k), vectorised over rows; k = 0 -> 0, k >= n_categories -> 1.
drm_cumulative_logit_p <- function(y, params) {
  cp <- drm_cumulative_logit_cutpoints(params)
  n_categories <- ncol(cp) + 1L
  k <- round(y)
  k_idx <- pmin(pmax(k, 1L), ncol(cp))
  cp_at_k <- cp[cbind(seq_along(k), k_idx)]
  ifelse(
    k <= 0,
    0,
    ifelse(k >= n_categories, 1, stats::plogis(cp_at_k - params$mu))
  )
}

# Right-inverse quantile: the smallest category k in 1:n_categories with
# F(k) >= u.
drm_cumulative_logit_q <- function(u, params) {
  cp <- drm_cumulative_logit_cutpoints(params)
  n_categories <- ncol(cp) + 1L
  n <- nrow(cp)
  u <- rep(u, length.out = n)
  cdf <- matrix(1, nrow = n, ncol = n_categories)
  if (ncol(cp) > 0L) {
    cdf[, seq_len(ncol(cp))] <- stats::plogis(cp - params$mu)
  }
  vapply(seq_len(n), function(i) which(cdf[i, ] >= u[i])[1], integer(1))
}

drm_family_dpq_cumulative_logit <- function() {
  list(
    dpars = c("mu"),
    discrete = TRUE,
    has_atom = FALSE,
    atoms = numeric(0),
    status = "reference",
    d = function(y, params) {
      drm_cumulative_logit_p(y, params) - drm_cumulative_logit_p(y - 1, params)
    },
    p = function(y, params) drm_cumulative_logit_p(y, params),
    q = function(u, params) drm_cumulative_logit_q(u, params)
  )
}

# ---- poisson (reference, discrete) -------------------------------------------
#
# Native map is the identity: mu IS the Poisson rate (compiled density at
# src/drmTMB.cpp:3184-3195, model_type == 6, `dpois(y, mu)`). Matches
# `simulate.drmTMB()`'s poisson branch (methods.R:
# `stats::rpois(lambda = mu)`).

drm_family_dpq_poisson <- function() {
  list(
    dpars = c("mu"),
    discrete = TRUE,
    has_atom = FALSE,
    atoms = numeric(0),
    status = "reference",
    d = function(y, params) stats::dpois(y, lambda = params$mu),
    p = function(y, params) stats::ppois(y, lambda = params$mu),
    q = function(u, params) stats::qpois(u, lambda = params$mu)
  )
}

# ---- zi_poisson (reference, discrete, DO-T3 batch C) ------------------------
#
# Zero-inflated Poisson: `mu` is the identity-map Poisson rate (same as
# "poisson"), `zi` is the structural-zero probability, matching the compiled
# kernel exactly (src/drmTMB.cpp:3196-3258, model_type == 8):
# `P(Y = 0) = zi + (1 - zi) * dpois(0, mu)`, `P(Y = k) = (1 - zi) *
# dpois(k, mu)` for `k >= 1`. Fully discrete over the SAME non-negative-
# integer lattice "poisson" uses (the zero-inflation adds mass AT an existing
# support point, 0, rather than opening a new atom outside the discrete
# lattice), so `drm_quantile_residual_u()`'s ordinary discrete `F(y - 1)`
# left-limit rule (R/adequacy.R) already handles it correctly with no
# special-case code; `atoms = c(0)` is carried here only for DG2's
# atom-enumeration bookkeeping (verification-spec.md's "zi_*: {0}"), not
# consumed by the residual left-limit rule (see the field's doc comment at
# the top of this file).
#
# CDF: for y >= 0, `F(y) = zi + (1 - zi) * ppois(y, mu)` -- a single formula
# (no separate y = 0 case needed: `F(0) = zi + (1 - zi) * dpois(0, mu) = zi +
# (1 - zi) * ppois(0, mu)` already, since `ppois(0, mu) = dpois(0, mu)`).
# Quantile: solving `zi + (1 - zi) * ppois(y, mu) >= u` for the smallest
# integer y gives `y = qpois((u - zi) / (1 - zi), mu)`, clamped to `[0, 1]`
# before the `qpois()` call so `u <= zi` (below the atom's threshold) maps to
# `qpois(0, mu) = 0` and `u = 1` maps to `qpois(1, mu) = Inf` (ordinary
# `qpois()` boundary behaviour, unchanged).

drm_family_dpq_zi_poisson <- function() {
  list(
    dpars = c("mu", "zi"),
    discrete = TRUE,
    has_atom = FALSE,
    atoms = c(0),
    status = "reference",
    d = function(y, params) {
      zi <- params$zi
      base <- stats::dpois(y, lambda = params$mu)
      ifelse(y == 0, zi + (1 - zi) * base, (1 - zi) * base)
    },
    p = function(y, params) {
      zi <- params$zi
      ifelse(
        y < 0,
        0,
        zi + (1 - zi) * stats::ppois(y, lambda = params$mu)
      )
    },
    q = function(u, params) {
      zi <- params$zi
      frac <- pmin(pmax((u - zi) / (1 - zi), 0), 1)
      stats::qpois(frac, lambda = params$mu)
    }
  )
}

# ---- nbinom2 (reference, discrete) -------------------------------------------
#
# Public sigma -> native size: size = 1 / sigma^2 (the NB2 "alpha" the
# compiled `drm_nbinom2_log_density()` kernel uses is `sigma^2`, i.e. the
# reciprocal of the size `stats::{d,p,q}nbinom(..., size=, mu=)` expects --
# src/drm_count_kernels.h:31-41). `drm_nbinom2_size()` is the SAME conversion
# `simulate.drmTMB()`'s nbinom2 branch calls (methods.R:
# `stats::rnbinom(size = drm_nbinom2_size(sigma), mu = mu)`); both routes call
# this one helper. `truncated_nbinom2_p0()` (methods.R) used to duplicate the
# same `1 / sigma^2` formula inline for a then-not-yet-promoted family; DO-T3
# batch C promotes "truncated_nbinom2"/"hurdle_nbinom2"/"zi_nbinom2" (all
# built on this SAME nbinom2 kernel, `src/drmTMB.cpp` model_type == 11/12/9)
# and closes that duplicate too (Emmy's dedup) -- see each family's section
# below and the `truncated_nbinom2_p0()` comment in methods.R.

drm_nbinom2_size <- function(sigma) {
  1 / sigma^2
}

drm_family_dpq_nbinom2 <- function() {
  list(
    dpars = c("mu", "sigma"),
    discrete = TRUE,
    has_atom = FALSE,
    atoms = numeric(0),
    status = "reference",
    d = function(y, params) {
      stats::dnbinom(y, size = drm_nbinom2_size(params$sigma), mu = params$mu)
    },
    p = function(y, params) {
      stats::pnbinom(y, size = drm_nbinom2_size(params$sigma), mu = params$mu)
    },
    q = function(u, params) {
      stats::qnbinom(u, size = drm_nbinom2_size(params$sigma), mu = params$mu)
    }
  )
}

# ---- truncated_nbinom2 (reference, discrete, DO-T3 batch C) ----------------
#
# Zero-truncated NB2: support `{1, 2, ...}`, built on the SAME nbinom2 kernel
# ("mu"/"sigma" -> `size = drm_nbinom2_size(sigma)`) renormalized by the
# untruncated zero-mass `p0 = dnbinom(0, size, mu)`, matching the compiled
# kernel exactly (src/drmTMB.cpp:3463-3510, model_type == 11):
# `log_density(y) - log(1 - p0)` for `y >= 1`, via the SAME
# `drm_nbinom2_log_density()`/`drm_nbinom2_log_p0()` C++ helpers
# (src/drm_count_kernels.h) "nbinom2" itself uses. No isolated atom (the
# support is a proper, if renormalized, discrete lattice starting at 1, not a
# jump breaking an otherwise-continuous or otherwise-wider-discrete
# distribution), so `atoms = numeric(0)` and the ordinary discrete `F(y - 1)`
# left-limit rule in `drm_quantile_residual_u()` (R/adequacy.R) applies
# unchanged -- `F(0) = 0` below the truncated support, so `F(1 - 1) = F(0) =
# 0` is the correct left limit at the smallest supported value `y = 1`.
#
# CDF: `F(y) = (pnbinom(y, size, mu) - p0) / (1 - p0)` for `y >= 1`, `F(y) =
# 0` for `y < 1` (`d()` similarly floors at 0 below the support). Quantile:
# `q(u) = qnbinom(p0 + u * (1 - p0), size, mu)` -- the SAME transform
# `simulate.drmTMB()`'s truncated_nbinom2 branch already draws with (methods.R:
# `u <- p0 + pmax(runif, eps) * (1 - p0); qnbinom(u, ...)`), here as the
# deterministic right-inverse rather than a random draw.

drm_family_dpq_truncated_nbinom2 <- function() {
  list(
    dpars = c("mu", "sigma"),
    discrete = TRUE,
    has_atom = FALSE,
    atoms = numeric(0),
    status = "reference",
    d = function(y, params) {
      size <- drm_nbinom2_size(params$sigma)
      p0 <- stats::dnbinom(0, size = size, mu = params$mu)
      base <- stats::dnbinom(y, size = size, mu = params$mu)
      ifelse(y < 1, 0, base / (1 - p0))
    },
    p = function(y, params) {
      size <- drm_nbinom2_size(params$sigma)
      p0 <- stats::dnbinom(0, size = size, mu = params$mu)
      cdf <- (stats::pnbinom(y, size = size, mu = params$mu) - p0) / (1 - p0)
      ifelse(y < 1, 0, cdf)
    },
    q = function(u, params) {
      size <- drm_nbinom2_size(params$sigma)
      p0 <- stats::dnbinom(0, size = size, mu = params$mu)
      stats::qnbinom(p0 + u * (1 - p0), size = size, mu = params$mu)
    }
  )
}

# ---- hurdle_nbinom2 (reference, discrete, DO-T3 batch C) -------------------
#
# Hurdle NB2: `P(Y = 0) = hu`, `P(Y = k) = (1 - hu) * truncated_nb2_pmf(k)`
# for `k >= 1`, built directly on the SAME zero-truncated-NB2 route
# "truncated_nbinom2" above uses, matching the compiled kernel exactly
# (src/drmTMB.cpp:3511-3597, model_type == 12): `log_hu` for `y == 0`,
# `log(1 - hu) + log_density(y) - log(1 - p0)` for `y >= 1`. Fully discrete
# over the non-negative-integer lattice (the hurdle mechanism REPLACES, not
# adds to, the y = 0 mass, unlike zero-inflation's additive mixture), so
# `atoms = c(0)` is carried for DG2 bookkeeping only (same convention as
# "zi_poisson" above) -- the ordinary discrete `F(y - 1)` left-limit rule
# applies unchanged.
#
# CDF: `F(0) = hu`; for `y >= 1`, `F(y) = hu + (1 - hu) * truncated_F(y)`
# where `truncated_F(y) = (pnbinom(y, size, mu) - p0) / (1 - p0)` is the SAME
# truncated-CDF "truncated_nbinom2" computes. Quantile: solving for the
# smallest y with `F(y) >= u` gives `q(u) = qnbinom(p0 + (1 - p0) * frac,
# size, mu)` where `frac = (u - hu) / (1 - hu)` clamped to `[0, 1]` -- the
# same "fraction" transform as "zi_poisson"/"zi_nbinom2", composed with
# "truncated_nbinom2"'s own `p0 + (1 - p0) * (...)` quantile transform.

drm_family_dpq_hurdle_nbinom2 <- function() {
  list(
    dpars = c("mu", "sigma", "hu"),
    discrete = TRUE,
    has_atom = FALSE,
    atoms = c(0),
    status = "reference",
    d = function(y, params) {
      size <- drm_nbinom2_size(params$sigma)
      p0 <- stats::dnbinom(0, size = size, mu = params$mu)
      base <- stats::dnbinom(y, size = size, mu = params$mu)
      ifelse(y == 0, params$hu, (1 - params$hu) * base / (1 - p0))
    },
    p = function(y, params) {
      size <- drm_nbinom2_size(params$sigma)
      hu <- params$hu
      p0 <- stats::dnbinom(0, size = size, mu = params$mu)
      trunc_cdf <- pmax(
        (stats::pnbinom(pmax(y, 0), size = size, mu = params$mu) - p0) /
          (1 - p0),
        0
      )
      ifelse(y < 0, 0, hu + (1 - hu) * trunc_cdf)
    },
    q = function(u, params) {
      size <- drm_nbinom2_size(params$sigma)
      hu <- params$hu
      p0 <- stats::dnbinom(0, size = size, mu = params$mu)
      frac <- pmin(pmax((u - hu) / (1 - hu), 0), 1)
      stats::qnbinom(p0 + (1 - p0) * frac, size = size, mu = params$mu)
    }
  )
}

# ---- zi_nbinom2 (reference, discrete, DO-T3 batch C) -----------------------
#
# Zero-inflated NB2: the SAME additive zero-inflation mixture as "zi_poisson"
# above, over the NB2 base instead of Poisson, matching the compiled kernel
# exactly (src/drmTMB.cpp:3598-3668, model_type == 9):
# `P(Y = 0) = zi + (1 - zi) * dnbinom(0, size, mu)`, `P(Y = k) = (1 - zi) *
# dnbinom(k, size, mu)` for `k >= 1`. `atoms = c(0)` for DG2 bookkeeping only
# (same convention as "zi_poisson"); the ordinary discrete `F(y - 1)`
# left-limit rule applies unchanged.
#
# CDF/quantile: the SAME `zi + (1 - zi) * F_base(y)` / `qF_base((u - zi) /
# (1 - zi))` transforms as "zi_poisson", with `pnbinom`/`qnbinom` at
# `size = drm_nbinom2_size(sigma)` in place of `ppois`/`qpois`.

drm_family_dpq_zi_nbinom2 <- function() {
  list(
    dpars = c("mu", "sigma", "zi"),
    discrete = TRUE,
    has_atom = FALSE,
    atoms = c(0),
    status = "reference",
    d = function(y, params) {
      size <- drm_nbinom2_size(params$sigma)
      zi <- params$zi
      base <- stats::dnbinom(y, size = size, mu = params$mu)
      ifelse(y == 0, zi + (1 - zi) * base, (1 - zi) * base)
    },
    p = function(y, params) {
      size <- drm_nbinom2_size(params$sigma)
      zi <- params$zi
      ifelse(
        y < 0,
        0,
        zi + (1 - zi) * stats::pnbinom(y, size = size, mu = params$mu)
      )
    },
    q = function(u, params) {
      size <- drm_nbinom2_size(params$sigma)
      zi <- params$zi
      frac <- pmin(pmax((u - zi) / (1 - zi), 0), 1)
      stats::qnbinom(frac, size = size, mu = params$mu)
    }
  )
}

# ---- biv_gaussian (reference, MARGINAL-ONLY, DO-T3 batch D) ----------------
#
# The marginal of a bivariate normal for response k is EXACTLY
# N(mu_k, sigma_k), independent of rho12 -- a property of the multivariate
# normal (integrating the joint density over the other response leaves rho12
# out entirely), not an approximation. So biv_gaussian's {d,p,q} are the SAME
# univariate gaussian closures drm_family_dpq_gaussian() already provides,
# reused verbatim: no new density/CDF/quantile code, no new cascade.
#
# The response-selection step -- which of (mu1, sigma1) vs (mu2, sigma2)
# supplies the generic "mu"/"sigma" columns the reused closures read -- does
# NOT happen here. drm_family_dpq(object) has no `response` argument (its
# signature is unchanged by this batch); the {d,p,q} closures below are
# identical regardless of which response was selected upstream. Selection
# happens in fitted_distribution_params()'s biv_gaussian branch, driven by
# the `response` argument fitted_distribution()/fitted_distribution.drmTMB()
# add in this batch (REQUIRED for biv_gaussian, validated by
# drm_validate_fitted_distribution_response()).
#
# V_known: drm_gaussian_obs_sigma() (reused unchanged) reads params$V_known,
# which fitted_distribution_params() attaches via drm_biv_response_v_known()
# -- response k's n-row slice of the fit's row-paired 2n-length
# known_v_diag() (0 for a non-meta biv fit; the correct known sampling
# variance for a meta_V() biv fit's fitted rows). See that helper's comment
# for the length-mismatch bug this fixes.
drm_family_dpq_biv_gaussian <- function() {
  drm_family_dpq_gaussian()
}

# ---- fitted_distribution() shared accessor ---------------------------------

#' Fitted distribution accessor
#'
#' `fitted_distribution()` returns an object carrying, for each row of the
#' fitted data (or `newdata`), the fitted distributional-parameter estimates
#' from [predict_parameters()] together with density (`d`), CDF (`p`), and
#' quantile (`q`) functions evaluated at those fitted parameters. Downstream
#' consumers (quantile residuals, `predict(type = "quantile")`,
#' `exceedance()`) are meant to route through this accessor rather than
#' re-deriving the public-to-native parameter conversion.
#'
#' `fitted_distribution()` only supports `model_type`s with a promoted entry
#' in [drm_family_dpq()]: as of DO-T3 batch D all 18 fitted `model_type`
#' values are promoted (`status = "reference"`), including bivariate
#' `"biv_gaussian"` (see the `response` argument below). `newdata` support
#' inherits the same limitation as [predict_parameters()]: fixed-effect,
#' population-level predictions only. For meta-analysis gaussian fits
#' (`meta_V()`), the known sampling variance is taken from the fit for fitted
#' rows (`newdata = NULL`); when `newdata` is supplied it must carry a `V`
#' column giving the per-row known sampling variance, or an error is raised
#' (rather than silently assuming 0). Ordinary (non-meta) fits need no `V`
#' column. For binomial and beta_binomial fits, fitted rows reuse the fitted
#' `trials` denominator; `newdata` must carry a `trials` column giving the
#' per-row denominator, mirroring the meta_V() `V`-column contract. For
#' cumulative_logit fits, the fitted ordinal cutpoints are attached as
#' `CP1`..`CPk` columns (constant across rows, including `newdata` rows --
#' the cutpoints do not depend on covariates).
#'
#' `response` selects which response a bivariate `biv_gaussian` fit's
#' returned distribution describes: `1` for `(mu1, sigma1)`, `2` for `(mu2,
#' sigma2)`. It is **required** for `biv_gaussian` (an error names the two
#' valid values if omitted) and is **not used** for univariate `model_type`s
#' (passing a non-`NULL` value errors, rather than being silently ignored).
#' The returned distribution is the MARGINAL of that one response -- exactly
#' `N(mu_k, sigma_k)`, independent of `rho12` -- never the joint bivariate
#' distribution; there is no `response = "joint"` option. `newdata` for a
#' `biv_gaussian` fit inherits any known bivariate sampling covariance as
#' `V_known = 0` (marginal-only scope, matching DO-T2's original
#' `predict(type = "quantile")` documentation); fitted rows correctly use
#' response `k`'s slice of a `meta_V()` fit's known sampling variance.
#'
#' @param object A `drmTMB` fit.
#' @param newdata Optional data frame for prediction. If omitted, fitted rows
#'   are used.
#' @param response For a bivariate `biv_gaussian` fit, `1` or `2`, selecting
#'   which response's marginal distribution to return. Required for
#'   `biv_gaussian`; must be `NULL` (the default) for univariate model types.
#' @param ... Reserved for future options.
#'
#' @return An object of class `"drm_fitted_distribution"`: a list with
#'   `model_type`, `status`, `discrete`, `has_atom`, `atoms` (numeric vector of
#'   isolated atom locations, `numeric(0)` when none -- see
#'   [drm_family_dpq()]'s header comment), `params` (wide data frame of
#'   per-row native dpar estimates), and `d`, `p`, `q` (one-argument functions
#'   bound to `params`).
#'
#' @examples
#' dat <- data.frame(y = c(0.2, 0.5, 1.1, 1.4), x = c(-1, -0.5, 0, 0.5))
#' fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat)
#' fd <- fitted_distribution(fit)
#' fd$p(dat$y)
#' @export
fitted_distribution <- function(object, ...) {
  UseMethod("fitted_distribution")
}

#' @rdname fitted_distribution
#' @export
fitted_distribution.drmTMB <- function(object, newdata = NULL, response = NULL, ...) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("{.arg ...} is reserved for future options.")
  }
  response <- drm_validate_fitted_distribution_response(object, response)
  dpq <- drm_family_dpq(object)
  params <- fitted_distribution_params(
    object,
    newdata = newdata,
    dpars = dpq$dpars,
    response = response
  )
  structure(
    list(
      model_type = object$model$model_type,
      status = dpq$status,
      discrete = dpq$discrete,
      has_atom = dpq$has_atom,
      atoms = dpq$atoms,
      params = params,
      d = function(y) dpq$d(y, params),
      p = function(y) dpq$p(y, params),
      q = function(u) dpq$q(u, params)
    ),
    class = "drm_fitted_distribution"
  )
}

# `response` validation/normalization shared by fitted_distribution.drmTMB()
# and R/adequacy.R's drm_quantile_residuals() (both need the SAME rule:
# required + must be 1 or 2 for biv_gaussian, must be NULL otherwise) -- one
# source of truth for the error wording rather than two independently
# maintained checks. Returns response coerced to a single integer (1L/2L) for
# biv_gaussian, or NULL for a univariate model type.
drm_validate_fitted_distribution_response <- function(object, response) {
  is_biv <- identical(object$model$model_type, "biv_gaussian")
  if (!is_biv) {
    if (!is.null(response)) {
      cli::cli_abort(c(
        "{.arg response} is only used for bivariate model types.",
        i = "This fit's model type ({.val {object$model$model_type}}) is univariate; omit {.arg response} (or pass {.code NULL})."
      ))
    }
    return(NULL)
  }
  if (is.null(response)) {
    cli::cli_abort(c(
      "{.val biv_gaussian} is bivariate; pass {.code response = 1} or {.code response = 2} for the marginal distribution.",
      i = "The marginal of a bivariate normal is exactly N(mu_k, sigma_k), independent of rho12."
    ))
  }
  if (length(response) != 1L || is.na(response) || !(response %in% c(1, 2))) {
    cli::cli_abort("{.arg response} must be {.val 1} or {.val 2} for a bivariate {.val biv_gaussian} fit.")
  }
  as.integer(response)
}

# Wide (one row per observation) table of native dpar estimates, built from
# predict_parameters()'s long format. Also attaches `V_known` (the gaussian
# meta-analysis known sampling variance per row; 0 for ordinary fits and for
# any newdata rows) so gaussian's {d,p,q} can reconstruct the same total
# observation SD the compiled density uses (src/drmTMB.cpp:634) without a
# second V_known-handling code path.
#
# biv_gaussian (DO-T3 batch D): `dpars` is drm_family_dpq_biv_gaussian()'s
# generic c("mu", "sigma") (reused verbatim from the gaussian entry), but a
# biv_gaussian fit's coefficients are named "mu1"/"mu2"/"sigma1"/"sigma2" --
# not "mu"/"sigma". `request_dpars` translates the generic names to response
# `response`'s fit-specific names (e.g. c("mu1", "sigma1")) before calling
# predict_parameters(), then the returned columns are renamed back to the
# generic "mu"/"sigma" so the reused gaussian {d,p,q} closures (which read
# params$mu/params$sigma) work unchanged.
fitted_distribution_params <- function(object, newdata, dpars, response = NULL) {
  is_biv <- identical(object$model$model_type, "biv_gaussian")
  request_dpars <- if (is_biv) paste0(dpars, response) else dpars
  long <- predict_parameters(
    object,
    newdata = newdata,
    dpar = request_dpars,
    type = "response",
    include_newdata = FALSE
  )
  columns <- lapply(
    seq_along(dpars),
    function(i) long$estimate[long$dpar == request_dpars[[i]]]
  )
  names(columns) <- dpars
  lengths <- vapply(columns, length, integer(1))
  if (length(unique(lengths)) != 1L) {
    cli::cli_abort(
      "Internal error: fitted distributional parameters have inconsistent lengths."
    )
  }
  params <- as.data.frame(columns, stringsAsFactors = FALSE, check.names = FALSE)
  params$V_known <- if (is_biv) {
    drm_biv_response_v_known(object, newdata, response, nrow(params))
  } else if (is.null(newdata)) {
    known_v_diag(object)
  } else {
    drm_newdata_v_known(object, newdata, nrow(params))
  }
  if (object$model$model_type %in% c("binomial", "beta_binomial")) {
    params$trials <- if (is.null(newdata)) {
      object$model$trials
    } else {
      drm_newdata_trials(object, newdata, nrow(params))
    }
  }
  if (identical(object$model$model_type, "cumulative_logit")) {
    cutpoints <- unname(object$ordinal$cutpoints)
    for (j in seq_along(cutpoints)) {
      params[[paste0("CP", j)]] <- rep(cutpoints[[j]], nrow(params))
    }
  }
  params
}

# Known sampling variance for one `response` (1 or 2) of a biv_gaussian fit's
# FITTED rows (`newdata = NULL`); 0 for `newdata` rows (no per-row known
# bivariate sampling covariance is available for out-of-sample rows,
# mirroring DO-T2's original marginal-path scope note). known_v_diag()
# returns the fit's FULL row-paired 2n-length known variance vector
# (`y1[1], y2[1], y1[2], y2[2], ...`, matching biv_gaussian_start()'s
# V_known_diag convention, R/drmTMB.R) -- DO-T2 flagged that reusing it
# directly for a single response's n-row params table throws a length
# mismatch (`V_known` bug, R/distributional-outputs.R's DO-T2 comment).
# `unstack_biv_response()` (R/methods.R) is the SAME de-interleaving helper
# `bivariate_observation_covariance()`/`simulate.drmTMB()`'s biv_gaussian
# branch already use for the (y1, y2) response pair itself; reused here for
# V_known rather than re-deriving the seq.int(1L/2L, by = 2L, ...) indexing a
# third time. For a non-meta biv fit this is all zeros (known_v_diag()
# defaults to rep(0, 2n) for a non-meta fit).
drm_biv_response_v_known <- function(object, newdata, response, n) {
  if (!is.null(newdata)) {
    return(rep(0, n))
  }
  v_full <- known_v_diag(object)
  if (is.null(v_full)) {
    return(rep(0, n))
  }
  unstack_biv_response(v_full)[, response]
}

# Known sampling variance for `newdata` rows. Ordinary gaussian fits have none
# (V_known = 0). Meta-analysis fits (meta_V()) DO: silently using 0 would make
# the fitted distribution wrong for new rows, so require an explicit per-row
# `V` column in `newdata` (CP1 decision, 2026-07-12).
drm_newdata_v_known <- function(object, newdata, n) {
  v_fit <- known_v_diag(object)
  is_meta <- !is.null(v_fit) && any(v_fit != 0)
  if (!is_meta) {
    return(rep(0, n))
  }
  v <- newdata[["V"]]
  if (is.null(v)) {
    cli::cli_abort(c(
      "This meta-analysis fit (using {.fn meta_V}) needs a known sampling variance for every new row.",
      i = "Add a {.code V} column to {.arg newdata} giving the per-row known sampling variance.",
      i = "Ordinary (non-meta) gaussian fits do not need this."
    ))
  }
  v <- as.numeric(v)
  if (length(v) != n) {
    cli::cli_abort(
      "The {.code V} column in {.arg newdata} must have one value per row ({.val {n}})."
    )
  }
  if (any(v < 0, na.rm = TRUE) || anyNA(v)) {
    cli::cli_abort("The {.code V} column in {.arg newdata} must be non-negative and non-missing.")
  }
  v
}

# `trials` (the denominator of `cbind(success, failure) ~ ...`) for `newdata`
# rows, shared by "binomial" and "beta_binomial" (DO-T3 batch B extends this
# from binomial-only). Fitted rows reuse `object$model$trials` directly --
# the same vector `simulate.drmTMB()`'s binomial/beta_binomial branches read
# (methods.R). `newdata` carries no response to re-derive a denominator from
# (that is the point of out-of-sample prediction), so -- mirroring
# `drm_newdata_v_known()`'s `meta_V()` contract above -- an explicit per-row
# `trials` column is required rather than silently assuming a value
# (CP1-sanctioned extension pattern: attach as a `params` column, never by
# changing the {d,p,q} closure signature).
drm_newdata_trials <- function(object, newdata, n) {
  trials <- newdata[["trials"]]
  if (is.null(trials)) {
    cli::cli_abort(c(
      "This fit needs the number of trials for every new row.",
      i = "Add a {.code trials} column to {.arg newdata} giving the per-row denominator (the {.code cbind(success, failure)} total).",
      i = "Fitted rows do not need this; only {.arg newdata} rows do."
    ))
  }
  trials <- as.numeric(trials)
  if (length(trials) != n) {
    cli::cli_abort(
      "The {.code trials} column in {.arg newdata} must have one value per row ({.val {n}})."
    )
  }
  if (any(trials <= 0, na.rm = TRUE) || anyNA(trials)) {
    cli::cli_abort("The {.code trials} column in {.arg newdata} must be positive and non-missing.")
  }
  trials
}

# ---- Dunn-Smyth randomized quantile residual seed contract -----------------
#
# For discrete/atom families, F is a step function (or has isolated jumps), so
# a plain `u = F(y)` residual is not uniform even under the true model. The
# Dunn-Smyth (1996) fix draws `u ~ Uniform(F(y-), F(y)]`, where `F(y-)` is the
# left limit of F at y (0 for purely continuous families, the CDF evaluated
# just below the atom for atom families such as Tweedie at y = 0, and
# `F(y - 1)` for count families). `drm_dunn_smyth_u()` is the seed-contract
# primitive: it draws one uniform per row in the supplied [lower, upper]
# band, using the SAME `.Random.seed` save/restore idiom as
# `simulate.drmTMB()` (methods.R:2770-2792), so a `seed` argument is
# reproducible without permanently disturbing the caller's random state. This
# is the shared primitive DO-T1's `residuals(type = "quantile")` is expected
# to call for atom/discrete families; DO-T0a does not yet wire it into
# `residuals()`.
#
# Contract:
#   - `seed = NULL` (default): draws use the caller's current RNG stream, not
#     reset, not restored (ordinary R behaviour).
#   - `seed = <integer>`: `set.seed(seed)` is applied for the duration of the
#     call only; the caller's prior `.Random.seed` is saved before the call
#     and restored on exit (matching `simulate.drmTMB()`), so calling with a
#     fixed seed is deterministic AND side-effect-free on the global RNG
#     stream.
#   - Multi-realization envelopes (Fisher's DG3 requirement, planned for
#     DO-T1): call `drm_dunn_smyth_u()` `nsim` times with `nsim` distinct
#     seeds (e.g. `seed + 1, seed + 2, ...`) or without a seed inside a single
#     seeded outer block, and summarise the resulting u/QQ envelope.
drm_dunn_smyth_u <- function(lower, upper, seed = NULL) {
  if (length(lower) != length(upper)) {
    cli::cli_abort("{.arg lower} and {.arg upper} must have the same length.")
  }
  if (!is.null(seed)) {
    had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    old_seed <- if (had_seed) {
      get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    } else {
      NULL
    }
    on.exit(
      {
        if (had_seed) {
          assign(".Random.seed", old_seed, envir = .GlobalEnv)
        } else if (
          exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
        ) {
          rm(".Random.seed", envir = .GlobalEnv)
        }
      },
      add = TRUE
    )
    set.seed(seed)
  }
  lower + stats::runif(length(lower)) * (upper - lower)
}

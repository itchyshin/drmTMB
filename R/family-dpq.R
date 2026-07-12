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
#   status    - fixed enum "unimplemented" / "spike" / "reference":
#               "reference" = DG2/DG3 verified + promoted; "spike" =
#               feasibility-only, NOT promoted past diagnostic_hold;
#               "unimplemented" = no entry (drm_family_dpq() aborts before
#               returning). Consumers (DO-T1 residual gate, DO-T3 ledger
#               grader) read this to decide what to expose. Only "gaussian" is
#               "reference" as of DO-T0a. Enum locked at CP1.
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
#' As of DO-T0a, only `"gaussian"` is a promoted (`status = "reference"`)
#' entry. `"tweedie"` and `"skew_normal"` are feasibility spikes
#' (`status = "spike"`): the closures are correct for the cases exercised in
#' the DO-T0a verification script, but have not been through the DG2/DG3
#' evidence gates and are not promoted past `diagnostic_hold`. All other
#' `model_type` values are staged for DO-T3 and raise a clear "not yet
#' implemented" error.
#'
#' The `d`/`p`/`q` closures take `(y_or_u, params)`, where `params` is a wide,
#' one-row-per-observation data frame. This signature is **frozen** (CP1): a
#' family needing extra per-row context beyond its dpars -- binomial `trials`,
#' ordinal cutpoints, truncation bounds, mixture weights -- attaches it as an
#' extra `params` column inside [fitted_distribution_params()], never by
#' changing the closure signature.
#'
#' @param object A `drmTMB` fit.
#' @return A list with elements `dpars`, `d`, `p`, `q`, `discrete`,
#'   `has_atom`, `status`.
#' @keywords internal
drm_family_dpq <- function(object) {
  entry <- switch(
    object$model$model_type,
    gaussian = drm_family_dpq_gaussian(),
    tweedie = drm_family_dpq_tweedie(),
    skew_normal = drm_family_dpq_skew_normal(),
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
# as an ordinary (non-meta) fit.
drm_gaussian_obs_sigma <- function(params) {
  v_known <- params$V_known
  if (is.null(v_known)) {
    v_known <- 0
  }
  sqrt(v_known + params$sigma^2)
}

# ---- tweedie (feasibility spike) -------------------------------------------
#
# Compound Poisson-gamma with an atom at y = 0 for 1 < nu < 2. The compiled
# density is TMB's built-in `dtweedie(y, mu, phi, nu, log = TRUE)`
# (src/drmTMB.cpp model_type == 16), with public sigma -> native phi = sigma^2
# and native nu = 1 + plogis(eta_nu) (the "logit12" link). `tweedie::dtweedie`/
# `ptweedie`/`qtweedie` use the same (mu, phi, power) parameterization, so no
# transform beyond the public->native map above is needed. Requires the
# `tweedie` package (Suggests-only spike dependency here; promote to a formal
# Suggests entry if DO-T3 adopts this route for the family rollout).

drm_family_dpq_tweedie <- function() {
  list(
    dpars = c("mu", "sigma", "nu"),
    discrete = FALSE,
    has_atom = TRUE,
    status = "spike",
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

# ---- skew_normal (feasibility spike) ---------------------------------------
#
# The CDF has no elementary closed form (it is Owen's-T:
# F(y) = Phi(z) - 2*T(z, nu), z = (y - xi) / omega). The `sn` package is not
# installed on the development machine used for this spike, so `p()` here
# falls back to numeric integration of the compiled density via
# `stats::integrate()` (no new hard dependency). `q()` is numeric inversion of
# `p()` via `stats::uniroot()` -- this is unavoidable regardless of package,
# since even `sn::qsn()` numerically inverts `psn()`. The (xi, omega) native
# parameters are the SAME moment-inversion the compiled density and
# `rskew_normal_public()` already use (src/drmTMB.cpp:2441-2447,
# methods.R:3083-3093); this closure reuses that inversion rather than
# re-deriving it.

drm_family_dpq_skew_normal <- function() {
  list(
    dpars = c("mu", "sigma", "nu"),
    discrete = FALSE,
    has_atom = FALSE,
    status = "spike",
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

# (xi, omega) moment inversion shared with the compiled density and
# rskew_normal_public(): alpha = nu, delta = alpha / sqrt(1 + alpha^2),
# omega = sigma / sqrt(1 - delta^2 * 2/pi), xi = mu - omega * delta * sqrt(2/pi).
drm_skew_normal_native <- function(params) {
  alpha <- params$nu
  delta <- alpha / sqrt(1 + alpha^2)
  mean_shift <- delta * sqrt(2 / pi)
  omega <- params$sigma / sqrt(1 - mean_shift^2)
  xi <- params$mu - omega * mean_shift
  list(xi = xi, omega = omega, alpha = alpha)
}

drm_skew_normal_density <- function(y, params) {
  native <- drm_skew_normal_native(params)
  z <- (y - native$xi) / native$omega
  (2 / native$omega) * stats::dnorm(z) * stats::pnorm(native$alpha * z)
}

# Numeric-integration CDF, evaluated one row at a time (fixed-theta spike;
# vectorised only over rows, not speed-optimised -- DO-T3 concern).
drm_skew_normal_cdf <- function(y, params) {
  native <- drm_skew_normal_native(params)
  n <- length(y)
  out <- numeric(n)
  for (i in seq_len(n)) {
    xi_i <- rep(native$xi, length.out = n)[i]
    omega_i <- rep(native$omega, length.out = n)[i]
    alpha_i <- rep(native$alpha, length.out = n)[i]
    dens_i <- function(t) {
      z <- (t - xi_i) / omega_i
      (2 / omega_i) * stats::dnorm(z) * stats::pnorm(alpha_i * z)
    }
    lower <- xi_i - 40 * omega_i
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
#' As of DO-T0a, `fitted_distribution()` only supports `model_type`s with a
#' promoted or spike entry in [drm_family_dpq()] (currently `"gaussian"`,
#' `"tweedie"`, `"skew_normal"`); other families raise a clear "not yet
#' implemented" error. `newdata` support inherits the same limitation as
#' [predict_parameters()]: fixed-effect, population-level predictions only.
#' For meta-analysis gaussian fits (`meta_V()`), the known sampling variance is
#' taken from the fit for fitted rows (`newdata = NULL`); when `newdata` is
#' supplied it must carry a `V` column giving the per-row known sampling
#' variance, or an error is raised (rather than silently assuming 0). Ordinary
#' (non-meta) fits need no `V` column.
#'
#' @param object A `drmTMB` fit.
#' @param newdata Optional data frame for prediction. If omitted, fitted rows
#'   are used.
#' @param ... Reserved for future options.
#'
#' @return An object of class `"drm_fitted_distribution"`: a list with
#'   `model_type`, `status`, `discrete`, `has_atom`, `params` (wide data frame
#'   of per-row native dpar estimates), and `d`, `p`, `q` (one-argument
#'   functions bound to `params`).
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
fitted_distribution.drmTMB <- function(object, newdata = NULL, ...) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("{.arg ...} is reserved for future options.")
  }
  dpq <- drm_family_dpq(object)
  params <- fitted_distribution_params(object, newdata = newdata, dpars = dpq$dpars)
  structure(
    list(
      model_type = object$model$model_type,
      status = dpq$status,
      discrete = dpq$discrete,
      has_atom = dpq$has_atom,
      params = params,
      d = function(y) dpq$d(y, params),
      p = function(y) dpq$p(y, params),
      q = function(u) dpq$q(u, params)
    ),
    class = "drm_fitted_distribution"
  )
}

# Wide (one row per observation) table of native dpar estimates, built from
# predict_parameters()'s long format. Also attaches `V_known` (the gaussian
# meta-analysis known sampling variance per row; 0 for ordinary fits and for
# any newdata rows) so gaussian's {d,p,q} can reconstruct the same total
# observation SD the compiled density uses (src/drmTMB.cpp:634) without a
# second V_known-handling code path.
fitted_distribution_params <- function(object, newdata, dpars) {
  long <- predict_parameters(
    object,
    newdata = newdata,
    dpar = dpars,
    type = "response",
    include_newdata = FALSE
  )
  columns <- lapply(dpars, function(p) long$estimate[long$dpar == p])
  names(columns) <- dpars
  lengths <- vapply(columns, length, integer(1))
  if (length(unique(lengths)) != 1L) {
    cli::cli_abort(
      "Internal error: fitted distributional parameters have inconsistent lengths."
    )
  }
  params <- as.data.frame(columns, stringsAsFactors = FALSE, check.names = FALSE)
  params$V_known <- if (is.null(newdata)) {
    known_v_diag(object)
  } else {
    drm_newdata_v_known(object, newdata, nrow(params))
  }
  params
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

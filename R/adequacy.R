# DO-T1 randomized quantile residuals for the distributional output & adequacy
# layer (issue #747; see docs/dev-log/2026-07-12-distributional-output-adequacy-layer-ultra-plan.md).
#
# Built on the FROZEN DO-T0a foundation (R/family-dpq.R): all F/left-limit
# evaluation routes through fitted_distribution() so no family-specific CDF
# logic is re-derived here.
#
# Honesty (Fisher + Rose, DO-T0a CP1 / DO-T1 goal): fitted_distribution()
# evaluates F at predict_parameters()'s FIXED-EFFECT, population-level
# parameter estimates. For a fit with random effects or other structured
# components this makes the residual conditional on the fixed-effect
# prediction, not marginal on the full model -- it is not guaranteed to be
# marginally N(0,1) even when the fixed-effect distributional form is
# correctly specified. A departure (or its absence) is evidence about
# fixed-effect adequacy only. Everywhere in this file and its documentation:
# "no detectable departure", never "adequate"/"valid"/"correct" -- a DG tick
# never promotes a family's inference tier.

#' Randomized quantile residuals (internal)
#'
#' `drm_quantile_residuals()` computes Dunn-Smyth (1996) randomized quantile
#' residuals `r_i = qnorm(F(y_i; theta_hat_i))` from the fitted distribution
#' returned by [fitted_distribution()].
#'
#' For continuous, atom-free families `F` has no jumps, so the residual is
#' exact and deterministic: `u_i = F(y_i)`. For discrete families
#' (`fitted_distribution()$discrete`) or families with an isolated atom
#' (`$has_atom`), `F` has jumps, so a plain `F(y_i)` residual is not uniform
#' even under the true model. The Dunn-Smyth fix instead draws
#' `u_i ~ Uniform(F(y_i-), F(y_i)]` via [drm_dunn_smyth_u()], where `F(y_i-)`
#' is the left limit of `F` at `y_i`: `F(y_i - 1)` for a discrete/count family
#' (`fd$discrete`; the left limit of any discrete distribution's CDF is the
#' CDF at the previous integer, whatever the support -- this covers ordinary
#' counts, zero-inflated/hurdle counts, and zero-truncated counts uniformly,
#' since zero-inflation/hurdle mass sits AT an existing lattice point rather
#' than opening a new atom, and a zero-truncated `F` is 0 below its support).
#' For a continuous-with-isolated-atoms family (`fd$has_atom`, `fd$discrete ==
#' FALSE`), the left limit is `F(y_i)` unchanged away from every atom location
#' in `fd$atoms` (`F` is continuous there, so the Dunn-Smyth draw degenerates
#' to the plain continuous case automatically) and `F(a - epsilon)` (a small
#' fixed offset below the atom, evaluated via `fd$p()`) at each atom `a` --
#' Tweedie has one atom at `y = 0` (`F(-epsilon) = 0` exactly, since the
#' support starts at 0); `zero_one_beta` has two, at `y = 0` and `y = 1`
#' (`F(1 - epsilon)` is the interior beta CDF's left limit approaching the
#' upper atom, an epsilon-accurate approximation to the exact continuous limit
#' -- see `drm_atom_left_limit()`'s comment for the precision discussion).
#'
#' `fitted_distribution()$status == "spike"` families (feasibility spikes,
#' not yet DG2/DG3-verified) still compute a residual, but emit a one-time
#' [cli::cli_warn()] per `model_type` per session flagging that the residual
#' is exploratory, not DG-verified. `status == "unimplemented"` families
#' already raise a clear error inside `fitted_distribution()`, before this
#' function's body runs.
#'
#' @param object A `drmTMB` fit.
#' @param seed Optional single integer. Fixes the Dunn-Smyth randomization
#'   reproducibly (discrete/atom families only) without disturbing the
#'   caller's RNG stream; see [drm_dunn_smyth_u()]. Ignored for continuous,
#'   atom-free families, where the residual has no randomization to fix.
#' @param nsim Number of independent randomized realizations to draw (Fisher's
#'   multi-realization seed envelope). `nsim = 1` (default) returns a plain
#'   numeric vector. `nsim > 1` returns an `n`-by-`nsim` matrix, one column per
#'   realization, using `nsim` distinct derived seeds when `seed` is supplied
#'   (`seed, seed + 1, ..., seed + nsim - 1`). For continuous, atom-free
#'   families every column is identical (the residual has no randomization
#'   uncertainty to average over); the envelope is only non-degenerate for
#'   discrete/atom families.
#'
#' @return A numeric vector (`nsim = 1`) or an `n`-by-`nsim` matrix
#'   (`nsim > 1`) of approximately N(0,1) residuals under a correctly
#'   specified fixed-effect model. Missing-response rows (see
#'   [drm_mask_missing_response_values()]) are `NA`.
#' @keywords internal
drm_quantile_residuals <- function(object, seed = NULL, nsim = 1L) {
  if (!inherits(object, "drmTMB")) {
    cli::cli_abort("{.arg object} must be a {.cls drmTMB} fit.")
  }
  if (!is.null(seed) && (!is.numeric(seed) || length(seed) != 1L || is.na(seed))) {
    cli::cli_abort("{.arg seed} must be {.val NULL} or a single number.")
  }
  if (
    !is.numeric(nsim) ||
      length(nsim) != 1L ||
      is.na(nsim) ||
      nsim < 1L ||
      nsim != round(nsim)
  ) {
    cli::cli_abort("{.arg nsim} must be a single positive integer.")
  }
  nsim <- as.integer(nsim)

  fd <- fitted_distribution(object)
  drm_warn_adequacy_spike(fd$status, object$model$model_type)
  y <- object$model$y

  if (nsim == 1L) {
    u <- drm_quantile_residual_u(fd, y, seed = seed)
    return(drm_mask_missing_response_values(object, stats::qnorm(u)))
  }

  seeds <- if (is.null(seed)) {
    vector("list", nsim)
  } else {
    as.list(as.integer(seed) + seq_len(nsim) - 1L)
  }
  cols <- lapply(seeds, function(s) {
    u <- drm_quantile_residual_u(fd, y, seed = s)
    drm_mask_missing_response_values(object, stats::qnorm(u))
  })
  out <- matrix(unlist(cols), ncol = nsim)
  colnames(out) <- paste0("sim", seq_len(nsim))
  out
}

# u = F(y), or the Dunn-Smyth randomized draw when F has jumps -- see
# drm_quantile_residuals()'s documentation for the left-limit rule.
drm_quantile_residual_u <- function(fd, y, seed = NULL) {
  upper <- fd$p(y)
  if (!fd$discrete && !fd$has_atom) {
    return(upper)
  }
  lower <- if (fd$discrete) {
    ifelse(y <= 0, 0, fd$p(y - 1))
  } else {
    drm_atom_left_limit(fd, y, upper)
  }
  drm_dunn_smyth_u(lower, upper, seed = seed)
}

# F(y-) for a continuous-with-isolated-atoms family (fd$has_atom == TRUE,
# fd$discrete == FALSE; e.g. Tweedie, atoms = c(0), or zero_one_beta,
# atoms = c(0, 1)). Away from every atom location F is continuous, so the
# left limit equals F(y) (`upper`, unchanged); AT an atom `a`, the left limit
# is F(a - epsilon), a DO-T1 (batch A/B) generalization from the original
# hardcoded "atom at 0 only" rule to an arbitrary `fd$atoms` vector (DO-T3
# batch C -- required once `zero_one_beta`, with atoms at both 0 and 1, was
# registered in drm_family_dpq()).
#
# Exact left limit at an atom a: F(a-) = F(a) - P(Y = a) = upper - d(a).
# `fd$d()` at an atom row returns the point mass (not a density), so this is
# exact for BOTH zero_one_beta's atoms {0, 1} and Tweedie's atom at 0 -- with
# no epsilon and, crucially, no regime-dependent bias. (The earlier
# F(a - epsilon) form had error ~ (1 - zoi) * epsilon^shape2 at the upper atom,
# which is NOT negligible for a dispersed beta with shape2 < 1 -- e.g.
# shape2 = 0.1 gives epsilon^0.1 ~ 0.16 -- silently widening the Dunn-Smyth
# interval there; Noether, DO-T3 batch C.) `fd$d()` and `fd$p()` are per-row
# closures bound to the FULL params table (frozen `(y_or_u, params)`
# signature), so both are called once on the full length-n `y` vector and
# indexed at atom rows. Non-atom rows keep the plain continuous limit `upper`.
drm_atom_left_limit <- function(fd, y, upper) {
  atoms <- fd$atoms
  if (is.null(atoms) || length(atoms) == 0L) {
    return(upper)
  }
  at_any_atom <- rep(FALSE, length(y))
  for (a in atoms) {
    at_any_atom <- at_any_atom | (y == a)
  }
  lower <- upper
  if (any(at_any_atom)) {
    mass <- fd$d(y)
    lower[at_any_atom] <- upper[at_any_atom] - mass[at_any_atom]
  }
  lower
}

# One-time-per-model_type-per-session spike warning (new.env(parent =
# emptyenv()) session-state pattern, matching drm_julia_setup_state /
# drm_julia_phylo_payload_cache in R/julia-bridge.R).
drm_adequacy_warn_state <- new.env(parent = emptyenv())

drm_warn_adequacy_spike <- function(status, model_type) {
  if (!identical(status, "spike")) {
    return(invisible(FALSE))
  }
  if (exists(model_type, envir = drm_adequacy_warn_state, inherits = FALSE)) {
    return(invisible(FALSE))
  }
  assign(model_type, TRUE, envir = drm_adequacy_warn_state)
  cli::cli_warn(c(
    "Quantile residuals for {.val {model_type}} use a feasibility-grade {.fn fitted_distribution} entry (status = \"spike\").",
    "x" = "This family's density/CDF/quantile closures have not yet passed the DG2/DG3 evidence gates.",
    "i" = "Treat these residuals as exploratory, not DG-verified; see {.fn drm_family_dpq}."
  ))
  invisible(TRUE)
}

# Test-only reset (not exported): clears the one-time spike-warning state so
# tests can assert the warning fires without depending on test execution
# order within the session.
drm_reset_adequacy_warning_state <- function() {
  rm(
    list = ls(envir = drm_adequacy_warn_state, all.names = TRUE),
    envir = drm_adequacy_warn_state
  )
  invisible(NULL)
}

# ---- shared order-statistic table for worm_plot()/qq_plot() ---------------

# One row per (realization, rank): sorted residual, its N(0,1) order-statistic
# theoretical quantile (stats::ppoints()), and their difference. Both plots
# and their tests read this table rather than re-deriving it, so a numeric
# "does the trend depart from flat" assertion in tests uses exactly the data
# the plot draws.
drm_quantile_residual_qq_data <- function(object, seed = NULL, nsim = 1L) {
  z <- drm_quantile_residuals(object, seed = seed, nsim = nsim)
  if (is.null(dim(z))) {
    z <- matrix(z, ncol = 1L)
  }
  cols <- lapply(seq_len(ncol(z)), function(j) {
    zz <- sort(z[is.finite(z[, j]), j])
    m <- length(zz)
    data.frame(
      sim = j,
      rank = seq_len(m),
      theoretical = stats::qnorm(stats::ppoints(m)),
      sample = zz
    )
  })
  out <- do.call(rbind, cols)
  out$deviation <- out$sample - out$theoretical
  out
}

# Per-rank [min, max] envelope across realizations, for the "value" column
# ("sample" for qq_plot(), "deviation" for worm_plot()). Degenerates to a
# zero-width band when every realization is identical (continuous, atom-free
# families; nsim == 1).
drm_adequacy_envelope <- function(data, value) {
  by_rank <- split(data[[value]], data$rank)
  theoretical_by_rank <- split(data$theoretical, data$rank)
  ranks <- as.integer(names(by_rank))
  out <- data.frame(
    rank = ranks,
    theoretical = vapply(theoretical_by_rank, `[`, numeric(1), 1L),
    ymin = vapply(by_rank, min, numeric(1)),
    ymax = vapply(by_rank, max, numeric(1))
  )
  out[order(out$rank), , drop = FALSE]
}

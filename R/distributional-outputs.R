# DO-T2 distributional outputs for the distributional output & adequacy layer
# (issue #748; see docs/dev-log/2026-07-12-distributional-output-adequacy-layer-ultra-plan.md).
#
# Built on the FROZEN DO-T0a foundation (R/family-dpq.R): every surface here
# routes through fitted_distribution()/drm_family_dpq() so no family-specific
# CDF/quantile logic is re-derived (mirrors R/adequacy.R's DO-T1 idiom,
# including reuse of its one-time spike warning, drm_warn_adequacy_spike()).
#
# Honesty (Fisher, DO-T0a CP1 / DO-T2 goal): fitted_distribution() evaluates
# {d,p,q} at predict_parameters()'s FIXED-EFFECT, population-level parameter
# estimates theta_hat -- these are distributional (plug-in) outputs, not
# calibrated-coverage intervals, and they do not propagate theta_hat
# uncertainty. Every predict(type = "quantile") and exceedance() result
# carries attr(., "calibrated") <- FALSE. centile_chart() is a
# MODEL-CONDITIONAL curve at theta_hat for the fitted covariate range, not a
# WHO/population reference standard.
#
# Bivariate biv_gaussian scope (DO-T3 batch D): biv_gaussian IS now a
# registered model_type in drm_family_dpq() (drm_family_dpq_biv_gaussian(),
# reusing the gaussian {d,p,q} closures verbatim -- see R/family-dpq.R), so
# fitted_distribution() handles it directly via its `response` argument
# (REQUIRED for biv_gaussian: 1 selects (mu1, sigma1), 2 selects (mu2,
# sigma2)). Every surface below -- predict(type = "quantile"), exceedance(),
# and centile_chart() (which delegates to predict()) -- routes through the
# SAME registry entry, so there is no separate biv-only marginal code path
# any more (removed in this batch: the DO-T2-era
# drm_biv_gaussian_marginal_distribution() special case). predict(type =
# "quantile") keeps its existing `dpar`-based response selector ("mu1"/
# "sigma1" for response 1, "mu2"/"sigma2" for response 2 -- the established,
# tested convention) and translates it to `response` internally
# (drm_biv_gaussian_response_index()); centile_chart() delegates to predict()
# and so inherits the same `dpar` selector unchanged. exceedance() had no
# response selector at all before this batch (biv_gaussian was unregistered,
# so it only ever reached fitted_distribution()'s "not yet covered" error);
# it gains a `response` argument directly, matching fitted_distribution()'s.
# Each response's marginal is exactly univariate normal (mu<k>, sigma<k>)
# regardless of rho12 -- a MARGINAL-only output, never the joint bivariate
# distribution.

# ---- predict(type = "quantile") --------------------------------------------

drm_predict_quantile <- function(object, newdata, dpar, prob) {
  if (
    !is.numeric(prob) ||
      length(prob) < 1L ||
      anyNA(prob) ||
      any(prob <= 0) ||
      any(prob >= 1)
  ) {
    cli::cli_abort(
      "{.arg prob} must be one or more numbers strictly between 0 and 1."
    )
  }

  fd <- drm_response_fitted_distribution(object, newdata = newdata, dpar = dpar)
  drm_warn_adequacy_spike(fd$status, object$model$model_type)

  n <- nrow(fd$params)
  cols <- lapply(prob, function(p) fd$q(rep(p, n)))
  out <- do.call(cbind, cols)
  colnames(out) <- drm_quantile_prob_labels(prob)
  rownames(out) <- NULL
  attr(out, "calibrated") <- FALSE
  attr(out, "prob") <- prob
  attr(out, "label") <- "distributional (plug-in) interval"
  out
}

# Column labels matching stats::quantile()'s percentage convention (e.g.
# "2.5%", "50%", "97.5%").
drm_quantile_prob_labels <- function(prob) {
  paste0(format(100 * prob, trim = TRUE, drop0trailing = TRUE), "%")
}

# Resolves the fitted_distribution() for the response `dpar` identifies.
# Ordinary (non-bivariate) fits: `dpar` is not a response selector (it was
# already validated by predict.drmTMB()'s match.arg() against
# names(object$coefficients)), so this ignores it and calls
# fitted_distribution() directly (response = NULL, the univariate default).
# biv_gaussian fits: `dpar` selects response 1 ("mu1"/"sigma1") or response 2
# ("mu2"/"sigma2"), translated to fitted_distribution()'s `response` argument
# (DO-T3 batch D: the registry now covers biv_gaussian directly, replacing
# the DO-T2-era drm_biv_gaussian_marginal_distribution() special case).
drm_response_fitted_distribution <- function(object, newdata, dpar) {
  if (!identical(object$model$model_type, "biv_gaussian")) {
    return(fitted_distribution(object, newdata = newdata))
  }
  response <- drm_biv_gaussian_response_index(dpar)
  fitted_distribution(object, newdata = newdata, response = response)
}

drm_biv_gaussian_response_index <- function(dpar) {
  if (dpar %in% c("mu1", "sigma1")) {
    return(1L)
  }
  if (dpar %in% c("mu2", "sigma2")) {
    return(2L)
  }
  cli::cli_abort(c(
    "{.code type = \"quantile\"} on a bivariate {.val biv_gaussian} fit needs {.arg dpar} to identify a response.",
    i = "Use {.val mu1} or {.val sigma1} for response 1, {.val mu2} or {.val sigma2} for response 2.",
    i = "Bivariate quantiles are MARGINAL only: rho12 and any joint tail structure are ignored."
  ))
}

# ---- exceedance() -----------------------------------------------------------

#' Exceedance probability from a fitted model
#'
#' `exceedance()` returns `Pr(Y > threshold | x)` (or, with `lower.tail = TRUE`,
#' `Pr(Y <= threshold | x)`) at a fitted model's per-row conditional
#' distribution. It is a thin wrapper over the shared CDF exposed by
#' [fitted_distribution()]: `1 - fitted_distribution(object, newdata)$p(threshold)`
#' (or the `p(threshold)` complement for `lower.tail = TRUE`).
#'
#' `threshold` is evaluated with the standard CDF convention `F(c) = Pr(Y <=
#' c)`, so for atom-bearing families (e.g. Tweedie's point mass at `y = 0`) a
#' threshold exactly at the atom includes that atom's mass in `F(c)`:
#' `exceedance(fit, 0)` (the default `lower.tail = FALSE`) excludes the atom
#' at 0, matching `Pr(Y > 0)`; `exceedance(fit, 0, lower.tail = TRUE)` recovers
#' the atom mass `Pr(Y <= 0) = Pr(Y == 0)` when the family's support has no
#' continuous mass below the atom.
#'
#' This is a distributional (plug-in) output at [predict_parameters()]'s
#' fixed-effect, population-level parameter estimates `theta_hat`: the result
#' carries `attr(., "calibrated") <- FALSE` and does not propagate `theta_hat`
#' uncertainty. See [fitted_distribution()] for the `"spike"`/`"unimplemented"`
#' status gate this inherits (a `"spike"`-status family emits a one-time
#' warning) and for the `response` argument's contract on a bivariate
#' `biv_gaussian` fit (REQUIRED there: `1` or `2`, selecting which response's
#' MARGINAL exceedance to return; `rho12` and any joint tail structure are
#' ignored).
#'
#' @param object A `drmTMB` fit.
#' @param threshold Numeric threshold `c`. Either a single value (recycled
#'   across rows) or one value per row of `newdata` (or per fitted row when
#'   `newdata` is omitted).
#' @param newdata Optional data frame for prediction. If omitted, fitted rows
#'   are used; see [fitted_distribution()].
#' @param lower.tail Logical. If `FALSE` (default), returns `Pr(Y > threshold)`.
#'   If `TRUE`, returns `Pr(Y <= threshold)`.
#' @param response For a bivariate `biv_gaussian` fit, `1` or `2`, selecting
#'   which response's marginal exceedance to compute; see
#'   [fitted_distribution()]. Must be `NULL` (the default) for univariate
#'   model types.
#' @param ... Reserved for future options.
#'
#' @return A numeric vector, one value per row, with `attr(., "calibrated") ==
#'   FALSE`.
#' @seealso [fitted_distribution()], [predict.drmTMB()]
#'
#' @examples
#' dat <- data.frame(y = c(0.2, 0.5, 1.1, 1.4), x = c(-1, -0.5, 0, 0.5))
#' fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat)
#' exceedance(fit, threshold = 1)
#' @export
exceedance <- function(object, threshold, newdata = NULL, lower.tail = FALSE, ...) {
  UseMethod("exceedance")
}

#' @rdname exceedance
#' @export
exceedance.drmTMB <- function(
  object,
  threshold,
  newdata = NULL,
  lower.tail = FALSE,
  response = NULL,
  ...
) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("{.arg ...} is reserved for future options.")
  }
  if (!is.numeric(threshold) || length(threshold) < 1L || anyNA(threshold)) {
    cli::cli_abort("{.arg threshold} must be one or more non-missing numbers.")
  }
  if (!is.logical(lower.tail) || length(lower.tail) != 1L || is.na(lower.tail)) {
    cli::cli_abort("{.arg lower.tail} must be a single TRUE or FALSE value.")
  }

  fd <- fitted_distribution(object, newdata = newdata, response = response)
  drm_warn_adequacy_spike(fd$status, object$model$model_type)

  n <- nrow(fd$params)
  if (length(threshold) != 1L && length(threshold) != n) {
    cli::cli_abort(
      "{.arg threshold} must have length 1 or one value per row ({.val {n}})."
    )
  }
  threshold <- rep(threshold, length.out = n)

  below <- fd$p(threshold)
  out <- if (isTRUE(lower.tail)) below else 1 - below
  attr(out, "calibrated") <- FALSE
  attr(out, "lower.tail") <- lower.tail
  attr(out, "threshold") <- threshold
  out
}

# ---- centile_chart() --------------------------------------------------------

#' Model-conditional centile chart
#'
#' `centile_chart()` draws fitted response centile curves against one
#' covariate, holding every other predictor at a reference value (numeric
#' predictors at their fitted mean, factors at their first fitted level; see
#' [prediction_grid()]). Each curve is `predict(object, newdata = grid, type =
#' "quantile", prob = p)` for one `p` in `prob`.
#'
#' `centile_chart()` is a MODEL-CONDITIONAL summary at [predict_parameters()]'s
#' fixed-effect, population-level parameter estimates `theta_hat` -- it is
#' **not** a WHO-style or other population reference standard. The reference
#' values every non-focal covariate is held at are reported in the plot
#' subtitle so a reader is not left guessing what "conditional" means here.
#'
#' @param object A `drmTMB` fit.
#' @param covariate Character scalar naming the predictor to vary.
#' @param prob Numeric vector of probabilities in (0, 1) giving the centiles
#'   to draw.
#' @param dpar Distributional parameter identifying the response; see
#'   [predict.drmTMB()]. If `NULL`, the first fitted distributional parameter
#'   is used (for bivariate `biv_gaussian` fits, `dpar` selects the response
#'   -- see [predict.drmTMB()]'s Details for the marginal-only scope).
#' @param n Number of grid points spanning `covariate`'s fitted range; passed
#'   to [prediction_grid()].
#' @param ... Reserved for future options.
#'
#' @return A `ggplot` object.
#' @seealso [predict.drmTMB()], [prediction_grid()]
#'
#' @examples
#' set.seed(20260712)
#' n <- 60
#' x <- stats::rnorm(n)
#' dat <- data.frame(y = 0.5 + 0.8 * x + stats::rnorm(n), x = x)
#' fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   centile_chart(fit, covariate = "x")
#' }
#' @export
centile_chart <- function(
  object,
  covariate,
  prob = c(0.03, 0.15, 0.5, 0.85, 0.97),
  ...
) {
  UseMethod("centile_chart")
}

#' @rdname centile_chart
#' @export
centile_chart.drmTMB <- function(
  object,
  covariate,
  prob = c(0.03, 0.15, 0.5, 0.85, 0.97),
  dpar = NULL,
  n = 100L,
  ...
) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("{.arg ...} is reserved for future options.")
  }
  if (
    !is.character(covariate) ||
      length(covariate) != 1L ||
      is.na(covariate) ||
      !nzchar(covariate)
  ) {
    cli::cli_abort("{.arg covariate} must be a single, non-empty predictor name.")
  }
  drm_centile_require_ggplot2()

  grid <- prediction_grid(object, focal = covariate, margin = "mean_reference", n = n)
  qmat <- predict(object, newdata = grid, dpar = dpar, type = "quantile", prob = prob)

  ordered_prob <- sort(prob)
  long <- data.frame(
    x = rep(grid[[covariate]], times = length(prob)),
    prob = rep(prob, each = nrow(grid)),
    value = as.numeric(qmat)
  )
  long$centile <- factor(
    drm_quantile_prob_labels(long$prob),
    levels = drm_quantile_prob_labels(ordered_prob)
  )

  ggplot2::ggplot(
    long,
    ggplot2::aes(
      x = .data$x,
      y = .data$value,
      group = .data$centile,
      colour = .data$centile
    )
  ) +
    ggplot2::geom_line(linewidth = 0.6, na.rm = TRUE) +
    ggplot2::labs(
      x = covariate,
      y = "Fitted response quantile",
      colour = "Centile",
      title = "Model-conditional centile chart",
      subtitle = paste(
        "Distributional (plug-in) centiles at theta_hat -- NOT a WHO or other",
        "population reference standard.\n",
        drm_centile_reference_caption(grid, covariate)
      )
    )
}

drm_centile_require_ggplot2 <- function() {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.fn centile_chart} requires the {.pkg ggplot2} package.",
      i = "Install it with {.code install.packages(\"ggplot2\")}."
    ))
  }
  invisible(TRUE)
}

# Reports the reference values every non-focal covariate is held at, using
# prediction_grid()'s own "prediction_grid" attribute metadata (no re-derived
# logic).
drm_centile_reference_caption <- function(grid, covariate) {
  info <- attr(grid, "prediction_grid")
  reference_terms <- info$reference_terms
  if (length(reference_terms) == 0L) {
    return("No other covariates in the model.")
  }
  values <- vapply(reference_terms, function(term) {
    value <- grid[[term]][[1L]]
    if (is.numeric(value)) format(value, digits = 3) else as.character(value)
  }, character(1))
  paste0(
    "Other covariates held at reference values: ",
    paste(paste0(reference_terms, " = ", values), collapse = ", "),
    "."
  )
}

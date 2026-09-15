#' Predict distributional parameters in long format
#'
#' `predict_parameters()` returns predicted distributional parameters from a
#' `drmTMB` fit in one long data frame. It is a compact data surface for
#' interpretation tables, plotting helpers, and marginalisation helpers: the
#' same grid can hold location (which can differ from the response mean),
#' scale, shape, probability, and coscale quantities.
#'
#' The helper calls [predict.drmTMB()] for each requested distributional
#' parameter. With `newdata = NULL`, predictions use the fitted rows. With
#' `newdata` supplied, predictions are fixed-effect, population-level
#' predictions for those rows, matching [predict.drmTMB()]. Use this table when
#' the reader needs distributional-parameter values on an explicit covariate
#' grid. Use [marginal_parameters()] when the target is an average over rows
#' rather than a row-by-row prediction table.
#'
#' By default, the table includes interval provenance columns with
#' `conf.status = "not_requested"` and
#' `interval_source = "not_available"`. When `conf.int = TRUE` and `newdata` is
#' supplied for ordinary fixed-effect distributional parameters, the helper
#' adds Wald fixed-effect intervals from the fitted coefficient covariance and
#' records the requested confidence level. These are population-level intervals
#' for the supplied grid. Link-scale intervals are computed on the linear
#' predictor scale; response-scale intervals use the model link and a delta
#' method standard error. They do not include random-effect mode uncertainty,
#' profile-likelihood uncertainty, or uncertainty for direct random-effect scale
#' models.
#'
#' For a `sigma`/`sigma1`/`sigma2` dpar of a family whose scale is soft-clamped
#' (see `drm_control(logsigma_clamp = )`), a row whose raw linear predictor
#' already lies outside the clamp band carries `conf.status = "clamp_limited"`
#' and `std.error`/`conf.low`/`conf.high` of `NA`: the clamp bent that row,
#' so the raw-predictor Wald interval is not an interval for the reported
#' (clamped) quantity, and where the bend is strong no Wald interval is
#' defined at all. Rows inside the band are unaffected, because the clamp is
#' the identity inside the band and their Wald interval is unchanged. Note the
#' selection this implies: whether a row returns an interval depends on where
#' its *estimate* fell relative to the band, not on where the truth is, so
#' near the band edge the intervals that are returned are conditioned on that
#' selection (in the package's own check, coverage of the kept `"wald"` rows
#' fell from 0.985 to 0.882 as the true predictor approached the edge, against
#' 0.98 for the unconditional raw interval). Use [check_drm()] to see whether a fit's clamp
#' is active, and rescale the response or widen the band
#' (`drm_control(logsigma_clamp = )`) before trusting scale-parameter
#' intervals on a clamp-active fit.
#'
#' For native `drmTMB` fits, the stable core columns retain this relative order:
#' `row`, `row_label`, `dpar`, `component`, `type`, `estimate`, `conf.status`,
#' and `interval_source`. `conf.status` describes the requested interval result
#' or availability; `interval_source` identifies its provenance. Interval
#' columns appear only when `conf.int = TRUE`, in the established position after
#' `estimate` and before `conf.status`. Supplied `newdata` columns are appended
#' after the core and optional interval columns, with a `newdata_` prefix if
#' their names would collide with this schema and a stable suffix when two
#' supplied names would otherwise collide after prefixing.
#'
#' @param object A `drmTMB` fit.
#' @param newdata Optional data frame for prediction. If omitted, fitted rows
#'   are used.
#' @param dpar Optional character vector of distributional parameters to
#'   predict, such as `"mu"`, `"sigma"`, `"nu"`, `"rho12"`, `"sigma1"`, or
#'   `"sigma2"`, plus fitted random-effect scale model names such as
#'   `"sd(id)"`. `NULL` predicts all fitted distributional parameters.
#' @param type Prediction scale: `"response"` or `"link"`.
#' @param include_newdata Logical; when `TRUE` and `newdata` is supplied, append
#'   the supplied covariate columns to the returned table.
#' @param conf.int Logical; include Wald fixed-effect confidence intervals when
#'   available for the supplied prediction grid.
#' @param conf.level Confidence level for Wald intervals when
#'   `conf.int = TRUE`.
#' @param ... Reserved for future options.
#'
#' @return A data frame whose stable native core columns retain this relative
#'   order: `row`, `row_label`, `dpar`, `component`, `type`, `estimate`,
#'   `conf.status`, and `interval_source`. `conf.status` is an interval result
#'   or availability state; `interval_source` is interval provenance. Only when
#'   `conf.int = TRUE`, `std.error`, `conf.low`, `conf.high`, and `conf.level`
#'   are included after `estimate` and before the status/provenance columns.
#'   When `include_newdata = TRUE`, supplied `newdata` columns are appended
#'   after the schema columns and renamed with `newdata_` plus, when needed, a
#'   stable uniqueness suffix when they collide.
#'
#' @examples
#' set.seed(20260522)
#' n <- 36
#' x <- seq(-1.5, 1.5, length.out = n)
#' sigma <- exp(-0.35 + 0.2 * x)
#' dat <- data.frame(
#'   y = 0.4 + 0.7 * x + rnorm(n, sd = sigma),
#'   x = x
#' )
#' fit <- drmTMB(bf(y ~ x, sigma ~ x), data = dat)
#' grid <- data.frame(x = c(-1, 0, 1))
#' pred <- predict_parameters(
#'   fit,
#'   newdata = grid,
#'   dpar = c("mu", "sigma"),
#'   conf.int = TRUE
#' )
#' pred
#'
#' predict_parameters(
#'   fit,
#'   newdata = grid,
#'   dpar = "sigma",
#'   type = "link",
#'   include_newdata = FALSE,
#'   conf.int = TRUE
#' )
#' @export
predict_parameters <- function(object, ...) {
  UseMethod("predict_parameters")
}

#' @rdname predict_parameters
#' @export
predict_parameters.drmTMB <- function(
  object,
  newdata = NULL,
  dpar = NULL,
  type = c("response", "link"),
  include_newdata = TRUE,
  conf.int = FALSE,
  conf.level = 0.95,
  ...
) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("{.arg ...} is reserved for future options.")
  }
  type <- match.arg(type)
  validate_predict_parameters_newdata(newdata)
  validate_predict_parameters_include_newdata(include_newdata)
  validate_predict_parameters_conf_int(conf.int)
  if (
    conf.int &&
      object$model$model_type %in% c("biv_lognormal", "biv_student")
  ) {
    cli::cli_abort(
      "{.fn predict_parameters} confidence intervals are not implemented for model type {.val {object$model$model_type}}; interval and profile claims are deferred."
    )
  }
  validate_predict_parameters_conf_level(conf.level)
  dpar <- predict_parameters_dpars(object, dpar)

  rows <- lapply(dpar, function(one_dpar) {
    estimate <- predict(object, newdata = newdata, dpar = one_dpar, type = type)
    n <- length(estimate)
    interval <- predict_parameters_interval(
      object = object,
      newdata = newdata,
      dpar = one_dpar,
      type = type,
      estimate = as.numeric(estimate),
      conf.int = conf.int,
      conf.level = conf.level
    )
    out <- data.frame(
      row = seq_len(n),
      row_label = predict_parameters_row_labels(newdata, n),
      dpar = one_dpar,
      component = drm_dpar_component(one_dpar),
      type = type,
      estimate = as.numeric(estimate),
      conf.status = interval$conf.status,
      interval_source = interval$interval_source,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
    if (isTRUE(conf.int)) {
      out$std.error <- interval$std.error
      out$conf.low <- interval$conf.low
      out$conf.high <- interval$conf.high
      out$conf.level <- interval$conf.level
      out <- predict_parameters_order_columns(out)
    }
    out
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL

  if (isTRUE(include_newdata) && !is.null(newdata)) {
    out <- cbind(
      out,
      predict_parameters_newdata_columns(newdata, length(dpar)),
      stringsAsFactors = FALSE
    )
  }
  out
}

predict_parameters_dpars <- function(object, dpar) {
  available <- names(object$coefficients)
  if (is.null(dpar)) {
    return(available)
  }
  if (!is.character(dpar) || length(dpar) < 1L || anyNA(dpar)) {
    cli::cli_abort(
      "{.arg dpar} must be a non-empty character vector of fitted distributional parameters."
    )
  }
  unknown <- setdiff(dpar, available)
  if (length(unknown) > 0L) {
    cli::cli_abort(c(
      "Unknown distributional parameter{?s}: {.val {unknown}}.",
      i = "Available parameters: {.val {available}}."
    ))
  }
  dpar
}

validate_predict_parameters_newdata <- function(newdata) {
  if (!is.null(newdata) && !is.data.frame(newdata)) {
    cli::cli_abort("{.arg newdata} must be a data frame.")
  }
  invisible(newdata)
}

validate_predict_parameters_include_newdata <- function(include_newdata) {
  if (
    !is.logical(include_newdata) ||
      length(include_newdata) != 1L ||
      is.na(include_newdata)
  ) {
    cli::cli_abort(
      "{.arg include_newdata} must be a single {.code TRUE} or {.code FALSE}."
    )
  }
  invisible(include_newdata)
}

validate_predict_parameters_conf_int <- function(conf.int) {
  if (
    !is.logical(conf.int) ||
      length(conf.int) != 1L ||
      is.na(conf.int)
  ) {
    cli::cli_abort(
      "{.arg conf.int} must be a single {.code TRUE} or {.code FALSE}."
    )
  }
  invisible(conf.int)
}

validate_predict_parameters_conf_level <- function(conf.level) {
  if (
    !is.numeric(conf.level) ||
      length(conf.level) != 1L ||
      !is.finite(conf.level) ||
      conf.level <= 0 ||
      conf.level >= 1
  ) {
    cli::cli_abort("{.arg conf.level} must be one number between 0 and 1.")
  }
  invisible(conf.level)
}

predict_parameters_interval <- function(
  object,
  newdata,
  dpar,
  type,
  estimate,
  conf.int,
  conf.level
) {
  n <- length(estimate)
  if (!isTRUE(conf.int)) {
    return(predict_parameters_interval_unavailable(
      n,
      status = "not_requested"
    ))
  }
  if (is.null(newdata)) {
    return(predict_parameters_interval_unavailable(
      n,
      status = "newdata_required",
      conf.level = conf.level
    ))
  }
  if (is_random_scale_dpar(object, dpar)) {
    return(predict_parameters_interval_unavailable(
      n,
      status = "wald_unavailable",
      conf.level = conf.level
    ))
  }

  basis <- tryCatch(
    drm_fixed_effect_basis(
      object = object,
      newdata = newdata,
      dpar = dpar,
      covariance = TRUE
    ),
    error = function(e) e
  )
  if (inherits(basis, "error")) {
    return(predict_parameters_interval_unavailable(
      n,
      status = "wald_unavailable",
      conf.level = conf.level
    ))
  }

  se_link <- predict_parameters_link_se(basis, n)
  ok <- is.finite(se_link)
  z <- stats::qnorm(1 - (1 - conf.level) / 2)

  # Fisher's fresh-context review of 2a5b0665e (Dinnage audit M2 follow-up,
  # #1308; docs/dev-log/audits/2026-09-14-dinnage-wave3-review.md, "### M2
  # follow-up (2a5b0665e)", REQUIRED items 1-4) rejected clamping the Wald
  # endpoints through drm_clamped_sigma_eta(): it bought containment of the
  # clamped point estimate at the cost of coverage -- a clamp-bent row's
  # interval collapsed to a zero-width point on the clamp asymptote, unflagged
  # as "wald", and (response scale) its std.error disagreed with conf.low/
  # conf.high in the same row by up to 6.1e9x because the reported derivative
  # omitted the clamp's own derivative c'(eta). A Wald interval of the
  # clamped quantity is not defined at a clamp-bent row (the likelihood is
  # flat there), so instead: detect rows whose RAW eta already lies outside
  # the softclamp band (predict_parameters_clamp_bent(), same band-crossing
  # test drm_profile_direct_sd_clamp_trace() uses at R/profile.R:4374) and
  # give those rows NA endpoints flagged "clamp_limited" -- the status
  # drm_profile_clamp_limited_confint_row() already uses at
  # R/profile.R:3514-3530. Rows inside the band are untouched: the softclamp
  # (drm_softclamp_log_sd(), R/drmTMB.R:23038-23060) is the identity there, so
  # the clamped and raw eta coincide and the ordinary raw-eta Wald interval
  # below is exactly the clamped-quantity interval too.
  clamp_bent <- ok & predict_parameters_clamp_bent(object, dpar, basis$eta)

  # Guard (review item 4): compute the endpoints only for `ok` rows, so an `NA`
  # `se_link` (a `wald_unavailable` row) never reaches an arithmetic op whose
  # result would need to flow through a clamp helper downstream.
  lo_link <- rep(NA_real_, n)
  hi_link <- rep(NA_real_, n)
  lo_link[ok] <- basis$eta[ok] - z * se_link[ok]
  hi_link[ok] <- basis$eta[ok] + z * se_link[ok]

  if (identical(type, "link")) {
    std.error <- se_link
    conf.low <- lo_link
    conf.high <- hi_link
  } else {
    # Review item 2: the derivative is evaluated at the RAW eta, not a clamped
    # eta -- inside the band (the only place a "wald" row survives) the two
    # coincide, so this is unchanged from before 2a5b0665e.
    derivative <- rep(NA_real_, n)
    derivative[ok] <- predict_parameters_inverse_link_derivative(
      object,
      dpar,
      basis$eta[ok]
    )
    std.error <- abs(derivative) * se_link
    conf.low <- rep(NA_real_, n)
    conf.high <- rep(NA_real_, n)
    conf.low[ok] <- drm_inverse_link(object, dpar, lo_link[ok])
    conf.high[ok] <- drm_inverse_link(object, dpar, hi_link[ok])
  }

  std.error[!ok | clamp_bent] <- NA_real_
  conf.low[!ok | clamp_bent] <- NA_real_
  conf.high[!ok | clamp_bent] <- NA_real_

  conf.status <- rep("wald", n)
  conf.status[!ok] <- "wald_unavailable"
  conf.status[clamp_bent] <- "clamp_limited"

  interval_source <- rep("wald", n)
  interval_source[!ok | clamp_bent] <- "not_available"

  list(
    std.error = std.error,
    conf.low = conf.low,
    conf.high = conf.high,
    conf.level = rep(conf.level, n),
    conf.status = conf.status,
    interval_source = interval_source
  )
}

# Row-level clamp detection for the Wald interval above: TRUE where `eta`
# (the RAW, unclamped linear predictor) already lies outside the softclamp
# band for a sigma-type dpar of a clamped family -- i.e. drm_clamped_sigma_eta()
# would bend that row. Gated identically to drm_clamped_sigma_eta()
# (R/methods.R:6235) so the two agree on which rows the clamp ever touches;
# NA-safe (an eta of NA is never flagged) and always FALSE when the clamp is
# disabled or inapplicable, matching drm_logsigma_clamp_active()'s band read
# (R/drmTMB.R:3543-3547).
predict_parameters_clamp_bent <- function(object, dpar, eta) {
  bent <- rep(FALSE, length(eta))
  if (
    !dpar %in% c("sigma", "sigma1", "sigma2") ||
      !isTRUE(object$model$model_type %in% drm_clamped_scale_families())
  ) {
    return(bent)
  }
  tmb_data <- object$model$tmb_data
  enabled <- tmb_data$use_logsigma_clamp
  if (length(enabled) != 1L || !identical(as.integer(enabled), 1L)) {
    return(bent)
  }
  band <- tmb_data$logsigma_clamp
  if (length(band) < 2L || anyNA(band[1:2])) {
    return(bent)
  }
  lo <- band[[1L]]
  hi <- band[[2L]]
  finite <- is.finite(eta)
  bent[finite] <- eta[finite] < lo | eta[finite] > hi
  bent
}

predict_parameters_interval_unavailable <- function(
  n,
  status,
  conf.level = NA_real_
) {
  list(
    std.error = rep(NA_real_, n),
    conf.low = rep(NA_real_, n),
    conf.high = rep(NA_real_, n),
    conf.level = rep(conf.level, n),
    conf.status = rep(status, n),
    interval_source = rep("not_available", n)
  )
}

predict_parameters_link_se <- function(basis, n) {
  X <- as.matrix(basis$X)
  V <- as.matrix(basis$V)
  variances <- rowSums((X %*% V) * X)
  if (length(variances) != n) {
    return(rep(NA_real_, n))
  }
  se <- rep(NA_real_, n)
  ok <- is.finite(variances) & variances >= -sqrt(.Machine$double.eps)
  se[ok] <- sqrt(pmax(variances[ok], 0))
  se
}

predict_parameters_inverse_link_derivative <- function(object, dpar, eta) {
  link <- drm_dpar_link(object, dpar)
  switch(
    link,
    identity = rep(1, length(eta)),
    log = exp(eta),
    logit = {
      p <- stats::plogis(eta)
      p * (1 - p)
    },
    probit = stats::dnorm(eta),
    cloglog = exp(eta - exp(eta)),
    logm2 = exp(eta),
    logit12 = {
      p <- stats::plogis(eta)
      p * (1 - p)
    },
    atanh_guarded = 0.999999 * (1 - tanh(eta)^2),
    atanh_re_guarded = 0.999999 * (1 - tanh(eta)^2),
    cli::cli_abort(
      "Internal error: unknown inverse-link derivative {.val {link}}."
    )
  )
}

predict_parameters_order_columns <- function(data) {
  preferred <- c(
    "row",
    "row_label",
    "dpar",
    "component",
    "type",
    "estimate",
    "std.error",
    "std_error",
    "conf.low",
    "conf.high",
    "conf.level",
    "conf.status",
    "interval_source"
  )
  data[
    c(
      intersect(preferred, names(data)),
      setdiff(names(data), preferred)
    )
  ]
}

predict_parameters_row_labels <- function(newdata, n) {
  if (is.null(newdata)) {
    return(as.character(seq_len(n)))
  }
  labels <- row.names(newdata)
  if (is.null(labels) || length(labels) != n) {
    return(as.character(seq_len(n)))
  }
  labels
}

predict_parameters_newdata_columns <- function(newdata, n_dpar) {
  out <- newdata[rep(seq_len(nrow(newdata)), times = n_dpar), , drop = FALSE]
  reserved <- c(
    "row",
    "row_label",
    "dpar",
    "component",
    "type",
    "estimate",
    "std.error",
    "conf.low",
    "conf.high",
    "conf.level",
    "conf.status",
    "interval_source"
  )
  output_names <- ifelse(
    names(out) %in% reserved,
    paste0("newdata_", names(out)),
    names(out)
  )
  names(out) <- make.unique(output_names, sep = "_")
  row.names(out) <- NULL
  out
}

drm_dpar_component <- function(dpar) {
  if (dpar %in% c("mu", "mu1", "mu2")) {
    return("location")
  }
  if (dpar %in% c("sigma", "sigma1", "sigma2")) {
    return("distributional-scale")
  }
  if (identical(dpar, "rho12")) {
    return("residual-correlation")
  }
  if (identical(dpar, "nu")) {
    return("shape")
  }
  if (dpar %in% c("zi", "hu", "zoi", "coi")) {
    return("probability")
  }
  if (grepl("^sd\\(", dpar)) {
    return("random-effect-sd-model")
  }
  "distributional-parameter"
}

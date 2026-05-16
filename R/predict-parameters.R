#' Predict distributional parameters in long format
#'
#' `predict_parameters()` returns predicted distributional parameters from a
#' `drmTMB` fit in one long data frame. It is a compact data surface for
#' interpretation tables and future plotting or marginalisation helpers: the
#' same grid can hold location/mean, scale, shape, probability, and coscale
#' quantities.
#'
#' The helper calls [predict.drmTMB()] for each requested distributional
#' parameter. With `newdata = NULL`, predictions use the fitted rows. With
#' `newdata` supplied, predictions are fixed-effect, population-level
#' predictions for those rows, matching [predict.drmTMB()].
#'
#' This first table surface does not compute confidence intervals. It still
#' includes interval provenance columns: `conf.status = "not_requested"` and
#' `interval_source = "not_available"`. Later interval-aware helpers can fill
#' those columns without changing the long-table shape.
#'
#' @param object A `drmTMB` fit.
#' @param newdata Optional data frame for prediction. If omitted, fitted rows
#'   are used.
#' @param dpar Optional character vector of distributional parameters to
#'   predict, such as `"mu"`, `"sigma"`, `"nu"`, `"rho12"`, `"sigma1"`, or
#'   `"sigma2"`. `NULL` predicts all fitted distributional parameters.
#' @param type Prediction scale: `"response"` or `"link"`.
#' @param include_newdata Logical; when `TRUE` and `newdata` is supplied, append
#'   the supplied covariate columns to the returned table.
#' @param ... Reserved for future options.
#'
#' @return A data frame with columns `row`, `row_label`, `dpar`, `component`,
#'   `type`, `estimate`, `conf.status`, and `interval_source`. When
#'   `include_newdata = TRUE`, supplied `newdata` columns are appended after
#'   those core columns.
#'
#' @examples
#' dat <- data.frame(
#'   y = c(0.2, 0.5, 1.1, 1.4, 1.8, 2.2),
#'   x = c(-1, -0.5, 0, 0.5, 1, 1.5)
#' )
#' fit <- drmTMB(bf(y ~ x, sigma ~ x), data = dat)
#' grid <- data.frame(x = c(0, 1))
#' predict_parameters(fit, newdata = grid, dpar = c("mu", "sigma"))
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
  ...
) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("{.arg ...} is reserved for future options.")
  }
  type <- match.arg(type)
  validate_predict_parameters_newdata(newdata)
  validate_predict_parameters_include_newdata(include_newdata)
  dpar <- predict_parameters_dpars(object, dpar)

  rows <- lapply(dpar, function(one_dpar) {
    estimate <- predict(object, newdata = newdata, dpar = one_dpar, type = type)
    n <- length(estimate)
    data.frame(
      row = seq_len(n),
      row_label = predict_parameters_row_labels(newdata, n),
      dpar = one_dpar,
      component = drm_dpar_component(one_dpar),
      type = type,
      estimate = as.numeric(estimate),
      conf.status = "not_requested",
      interval_source = "not_available",
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
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
    "conf.status",
    "interval_source"
  )
  names(out) <- ifelse(
    names(out) %in% reserved,
    paste0("newdata_", names(out)),
    names(out)
  )
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
  if (dpar %in% c("zi", "hu")) {
    return("probability")
  }
  if (grepl("^sd\\(", dpar)) {
    return("random-effect-sd-model")
  }
  "distributional-parameter"
}

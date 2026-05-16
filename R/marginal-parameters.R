#' Marginal summaries of predicted distributional parameters
#'
#' `marginal_parameters()` averages predicted distributional parameters over
#' fitted rows or a supplied `newdata` grid. It is a simple plug-in summary
#' layer built on [predict_parameters()], intended for interpretation tables and
#' future emmeans-style marginalisation or plotting helpers.
#'
#' This helper does not compute uncertainty, contrasts, or profile intervals.
#' It reports unweighted averages of already-predicted parameter values. For
#' population-level summaries, supply an explicit `newdata` grid; with
#' `newdata = NULL`, the fitted-row prediction contract is the same as
#' [predict.drmTMB()].
#'
#' The returned table carries the same interval provenance columns as
#' [predict_parameters()]. In this first contract, marginal summaries are point
#' estimates with `conf.status = "not_requested"` and
#' `interval_source = "not_available"`.
#'
#' @param object A `drmTMB` fit.
#' @param newdata Optional data frame for prediction. If omitted, fitted rows
#'   are used.
#' @param dpar Optional character vector of distributional parameters to
#'   summarise. `NULL` summarises all fitted distributional parameters.
#' @param by Optional character vector of columns in `newdata` used to define
#'   marginal groups. `NULL` averages over all prediction rows for each
#'   distributional parameter.
#' @param type Prediction scale: `"response"` or `"link"`.
#' @param ... Reserved for future options.
#'
#' @return A data frame with one row per distributional parameter and grouping
#'   combination. The returned columns are `dpar`, `component`, `type`,
#'   optional `by` columns, `estimate`, `n`, `conf.status`, and
#'   `interval_source`.
#'
#' @examples
#' dat <- data.frame(
#'   y = c(0.2, 0.5, 1.1, 1.4, 1.8, 2.2),
#'   x = c(-1, -0.5, 0, 0.5, 1, 1.5),
#'   habitat = factor(rep(c("reef", "sand"), each = 3))
#' )
#' fit <- drmTMB(bf(y ~ x + habitat, sigma ~ x), data = dat)
#' grid <- expand.grid(
#'   x = c(0, 1),
#'   habitat = levels(dat$habitat)
#' )
#' marginal_parameters(fit, newdata = grid, dpar = c("mu", "sigma"), by = "habitat")
#' @export
marginal_parameters <- function(object, ...) {
  UseMethod("marginal_parameters")
}

#' @rdname marginal_parameters
#' @export
marginal_parameters.drmTMB <- function(
  object,
  newdata = NULL,
  dpar = NULL,
  by = NULL,
  type = c("response", "link"),
  ...
) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("{.arg ...} is reserved for future options.")
  }
  type <- match.arg(type)
  validate_marginal_parameters_newdata(newdata)
  by_info <- marginal_parameters_by_columns(newdata, by)

  pred <- predict_parameters(
    object,
    newdata = newdata,
    dpar = dpar,
    type = type,
    include_newdata = length(by_info$output) > 0L
  )
  marginalise_parameter_predictions(pred, by = by_info$output)
}

validate_marginal_parameters_newdata <- function(newdata) {
  if (!is.null(newdata) && !is.data.frame(newdata)) {
    cli::cli_abort("{.arg newdata} must be a data frame.")
  }
  invisible(newdata)
}

marginal_parameters_by_columns <- function(newdata, by) {
  if (is.null(by)) {
    return(list(input = character(), output = character()))
  }
  if (!is.character(by) || length(by) < 1L || anyNA(by)) {
    cli::cli_abort(
      "{.arg by} must be a character vector of columns in {.arg newdata}."
    )
  }
  if (is.null(newdata)) {
    cli::cli_abort("{.arg by} requires {.arg newdata}.")
  }
  missing <- setdiff(by, names(newdata))
  if (length(missing) > 0L) {
    cli::cli_abort(c(
      "Column{?s} named in {.arg by} {?is/are} not present in {.arg newdata}: {.val {missing}}.",
      i = "Available columns: {.val {names(newdata)}}."
    ))
  }
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
  output <- ifelse(by %in% reserved, paste0("newdata_", by), by)
  list(input = by, output = output)
}

marginalise_parameter_predictions <- function(pred, by) {
  group_cols <- c("dpar", "component", "type", by)
  keys <- do.call(
    paste,
    c(pred[group_cols], sep = "\r")
  )
  key_levels <- unique(keys)
  rows <- lapply(key_levels, function(key) {
    idx <- which(keys == key)
    first <- idx[[1L]]
    out <- pred[first, group_cols, drop = FALSE]
    out$estimate <- mean(pred$estimate[idx])
    out$n <- length(idx)
    out$conf.status <- "not_requested"
    out$interval_source <- "not_available"
    row.names(out) <- NULL
    out
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

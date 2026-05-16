#' Build prediction grids for distributional-parameter summaries
#'
#' `prediction_grid()` creates explicit `newdata` grids for
#' [predict_parameters()] and [marginal_parameters()]. It does not fit, predict,
#' average, or plot. The helper records which terms were varied, which terms
#' were fixed, and which grid rule was used so later interpretation and plotting
#' helpers do not hide those choices.
#'
#' With `margin = "mean_reference"`, focal terms vary across the requested grid
#' and all other predictors are set to reference values: numeric predictors use
#' their fitted-row mean, factors use their first fitted level, character
#' predictors use their first fitted value with fitted levels preserved, and
#' logical predictors use their first fitted value unless supplied through
#' `condition`.
#'
#' With `margin = "empirical"`, focal terms are crossed with the fitted model
#' rows. Non-focal predictors keep their observed fitted-row values unless
#' supplied through `condition`. This produces a counterfactual-style grid that
#' can be passed to `marginal_parameters(..., by = focal_terms)` for simple
#' empirical averaging.
#'
#' @param object A `drmTMB` fit that retained its fitted model data.
#' @param focal Optional character vector of predictor names to vary.
#' @param at Optional named list of values for focal predictors. Focal numeric
#'   predictors without an `at` entry use an evenly spaced sequence over the
#'   fitted range. Focal factors without an `at` entry use all fitted levels.
#' @param condition Optional named list of non-focal predictors to hold at
#'   supplied values.
#' @param margin Grid rule. `"mean_reference"` returns one row for each focal
#'   combination with nuisance predictors set to reference values.
#'   `"empirical"` crosses focal combinations with the fitted model rows.
#' @param n Number of points for automatically generated numeric focal grids.
#' @param weights Metadata label for later marginalisation helpers. The current
#'   function records the choice but does not compute weighted summaries.
#' @param ... Reserved for future options.
#'
#' @return A data frame with class `drm_prediction_grid`. The ordinary columns
#'   are valid `newdata` columns for the fitted model. Attribute
#'   `"prediction_grid"` stores `focal_terms`, `conditioned_terms`, `margin`,
#'   `weights`, `grid_source`, `reference_terms`, `predictor_terms`,
#'   `n_source_rows`, and `n_grid_rows`.
#'
#' @examples
#' dat <- data.frame(
#'   y = c(0.2, 0.5, 1.1, 1.4, 1.8, 2.2),
#'   x = c(-1, -0.5, 0, 0.5, 1, 1.5),
#'   habitat = factor(rep(c("reef", "kelp"), each = 3))
#' )
#' fit <- drmTMB(bf(y ~ x + habitat, sigma ~ x), data = dat)
#'
#' grid <- prediction_grid(
#'   fit,
#'   focal = "x",
#'   at = list(x = c(0, 1)),
#'   condition = list(habitat = "reef")
#' )
#' predict_parameters(fit, newdata = grid, dpar = c("mu", "sigma"))
#' @export
prediction_grid <- function(object, ...) {
  UseMethod("prediction_grid")
}

#' @rdname prediction_grid
#' @export
prediction_grid.drmTMB <- function(
  object,
  focal = NULL,
  at = list(),
  condition = list(),
  margin = c("mean_reference", "empirical"),
  n = 50L,
  weights = c("equal", "proportional"),
  ...
) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("{.arg ...} is reserved for future options.")
  }
  margin <- match.arg(margin)
  weights <- match.arg(weights)
  validate_prediction_grid_fit(object)
  n <- validate_prediction_grid_n(n)

  data <- object$data
  predictors <- prediction_grid_predictors(object)
  focal <- validate_prediction_grid_terms(
    focal,
    predictors,
    argument = "focal",
    allow_null = TRUE
  )
  at <- validate_prediction_grid_list(at, "at")
  condition <- validate_prediction_grid_list(condition, "condition")
  validate_prediction_grid_named_terms(names(at), predictors, "at")
  validate_prediction_grid_named_terms(
    names(condition),
    predictors,
    "condition"
  )
  extra_at <- setdiff(names(at), focal)
  if (length(extra_at) > 0L) {
    cli::cli_abort(c(
      "{.arg at} can only name focal predictors.",
      "x" = "Non-focal {?term/terms} in {.arg at}: {.val {extra_at}}.",
      "i" = "Move fixed non-focal values to {.arg condition}."
    ))
  }
  overlap <- intersect(focal, names(condition))
  if (length(overlap) > 0L) {
    cli::cli_abort(c(
      "A predictor cannot be both focal and conditioned.",
      "x" = "Overlapping {?term/terms}: {.val {overlap}}."
    ))
  }

  focal_values <- lapply(focal, function(term) {
    prediction_grid_values(data[[term]], at[[term]], n = n, term = term)
  })
  names(focal_values) <- focal
  focal_grid <- prediction_grid_expand(focal_values)

  out <- switch(
    margin,
    mean_reference = prediction_grid_mean_reference(
      data = data,
      predictors = predictors,
      focal = focal,
      focal_grid = focal_grid,
      condition = condition
    ),
    empirical = prediction_grid_empirical(
      data = data,
      predictors = predictors,
      focal = focal,
      focal_grid = focal_grid,
      condition = condition
    )
  )

  prediction_grid_attach_metadata(
    out,
    object = object,
    focal = focal,
    condition = condition,
    predictors = predictors,
    margin = margin,
    weights = weights
  )
}

validate_prediction_grid_fit <- function(object) {
  if (!inherits(object, "drmTMB")) {
    cli::cli_abort("{.arg object} must be a {.cls drmTMB} fit.")
  }
  if (is.null(object$data) || !is.data.frame(object$data)) {
    cli::cli_abort(
      "{.arg object} must retain its fitted model data to build a prediction grid."
    )
  }
  invisible(object)
}

validate_prediction_grid_n <- function(n) {
  if (
    !is.numeric(n) ||
      length(n) != 1L ||
      is.na(n) ||
      n < 1L ||
      n != floor(n)
  ) {
    cli::cli_abort("{.arg n} must be a positive whole number.")
  }
  as.integer(n)
}

validate_prediction_grid_terms <- function(
  terms,
  predictors,
  argument,
  allow_null = FALSE
) {
  if (is.null(terms)) {
    if (isTRUE(allow_null)) {
      return(character())
    }
    cli::cli_abort("{.arg {argument}} must name predictor columns.")
  }
  if (!is.character(terms) || anyNA(terms)) {
    cli::cli_abort("{.arg {argument}} must be a character vector.")
  }
  terms <- unique(terms)
  validate_prediction_grid_named_terms(terms, predictors, argument)
  terms
}

validate_prediction_grid_named_terms <- function(terms, predictors, argument) {
  if (length(terms) == 0L) {
    return(invisible(terms))
  }
  if (any(!nzchar(terms))) {
    cli::cli_abort("{.arg {argument}} names must be non-empty.")
  }
  unknown <- setdiff(terms, predictors)
  if (length(unknown) > 0L) {
    cli::cli_abort(c(
      "{.arg {argument}} contains unknown predictor {?name/names}: {.val {unknown}}.",
      i = "Available predictors: {.val {predictors}}."
    ))
  }
  invisible(terms)
}

validate_prediction_grid_list <- function(x, argument) {
  if (is.null(x)) {
    return(list())
  }
  if (!is.list(x) || is.data.frame(x)) {
    cli::cli_abort("{.arg {argument}} must be a named list.")
  }
  nms <- names(x)
  if (length(x) > 0L && (is.null(nms) || anyNA(nms) || any(!nzchar(nms)))) {
    cli::cli_abort("{.arg {argument}} must be a named list.")
  }
  x
}

prediction_grid_predictors <- function(object) {
  terms <- object$model$terms
  vars <- unique(unlist(
    lapply(terms, function(one_terms) {
      all.vars(stats::delete.response(one_terms))
    }),
    use.names = FALSE
  ))
  vars[vars %in% names(object$data)]
}

prediction_grid_values <- function(x, values, n, term) {
  if (is.null(values)) {
    return(prediction_grid_auto_values(x, n = n))
  }
  out <- prediction_grid_cast_values(values, x, term = term)
  if (length(out) < 1L || anyNA(out)) {
    cli::cli_abort(
      "{.arg at} values for {.val {term}} must be non-empty and non-missing."
    )
  }
  out
}

prediction_grid_auto_values <- function(x, n) {
  if (is.factor(x)) {
    return(factor(levels(x), levels = levels(x), ordered = is.ordered(x)))
  }
  if (inherits(x, "Date")) {
    finite <- x[!is.na(x)]
    if (length(unique(finite)) <= n) {
      return(sort(unique(finite)))
    }
    return(seq(min(finite), max(finite), length.out = n))
  }
  if (inherits(x, "POSIXt")) {
    finite <- x[!is.na(x)]
    if (length(unique(finite)) <= n) {
      return(sort(unique(finite)))
    }
    return(seq(min(finite), max(finite), length.out = n))
  }
  if (is.numeric(x)) {
    finite <- x[is.finite(x)]
    unique_values <- sort(unique(finite))
    if (length(unique_values) <= n) {
      return(unique_values)
    }
    return(seq(min(finite), max(finite), length.out = n))
  }
  if (is.logical(x)) {
    return(sort(unique(x[!is.na(x)])))
  }
  values <- unique(as.character(x[!is.na(x)]))
  factor(values, levels = values)
}

prediction_grid_cast_values <- function(values, template, term) {
  if (is.factor(template)) {
    out <- factor(
      as.character(values),
      levels = levels(template),
      ordered = is.ordered(template)
    )
    if (anyNA(out)) {
      cli::cli_abort(c(
        "{.arg at} or {.arg condition} contains invalid level{?s} for {.val {term}}.",
        i = "Allowed levels: {.val {levels(template)}}."
      ))
    }
    return(out)
  }
  if (inherits(template, "Date")) {
    return(as.Date(values))
  }
  if (inherits(template, "POSIXt")) {
    return(as.POSIXct(values, tz = prediction_grid_tz(template)))
  }
  if (is.integer(template)) {
    return(as.integer(values))
  }
  if (is.numeric(template)) {
    return(as.numeric(values))
  }
  if (is.logical(template)) {
    return(as.logical(values))
  }
  levels <- unique(as.character(template[!is.na(template)]))
  out <- factor(as.character(values), levels = levels)
  if (anyNA(out)) {
    cli::cli_abort(c(
      "{.arg at} or {.arg condition} contains invalid value{?s} for {.val {term}}.",
      i = "Allowed values: {.val {levels}}."
    ))
  }
  out
}

prediction_grid_reference_value <- function(x, term) {
  if (is.factor(x)) {
    return(factor(levels(x)[[1L]], levels = levels(x), ordered = is.ordered(x)))
  }
  if (inherits(x, "Date")) {
    return(as.Date(mean(as.numeric(x), na.rm = TRUE), origin = "1970-01-01"))
  }
  if (inherits(x, "POSIXt")) {
    value <- mean(as.numeric(x), na.rm = TRUE)
    return(as.POSIXct(
      value,
      origin = "1970-01-01",
      tz = prediction_grid_tz(x)
    ))
  }
  if (is.numeric(x)) {
    return(mean(x, na.rm = TRUE))
  }
  non_missing <- x[!is.na(x)]
  if (length(non_missing) < 1L) {
    cli::cli_abort("Predictor {.val {term}} has no non-missing fitted values.")
  }
  if (is.logical(x)) {
    return(non_missing[[1L]])
  }
  levels <- unique(as.character(non_missing))
  factor(levels[[1L]], levels = levels)
}

prediction_grid_expand <- function(values) {
  if (length(values) == 0L) {
    return(prediction_grid_empty_data_frame(1L))
  }
  out <- expand.grid(
    values,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  row.names(out) <- NULL
  out
}

prediction_grid_mean_reference <- function(
  data,
  predictors,
  focal,
  focal_grid,
  condition
) {
  n_rows <- nrow(focal_grid)
  if (length(predictors) == 0L) {
    return(prediction_grid_empty_data_frame(n_rows))
  }
  cols <- vector("list", length(predictors))
  names(cols) <- predictors
  for (term in predictors) {
    if (term %in% focal) {
      cols[[term]] <- focal_grid[[term]]
    } else if (term %in% names(condition)) {
      value <- prediction_grid_condition_value(
        condition[[term]],
        data[[term]],
        term
      )
      cols[[term]] <- rep(value, n_rows)
    } else {
      cols[[term]] <- rep(
        prediction_grid_reference_value(data[[term]], term),
        n_rows
      )
    }
  }
  out <- as.data.frame(cols, stringsAsFactors = FALSE, check.names = FALSE)
  row.names(out) <- NULL
  out
}

prediction_grid_empirical <- function(
  data,
  predictors,
  focal,
  focal_grid,
  condition
) {
  base <- if (length(predictors) == 0L) {
    prediction_grid_empty_data_frame(nrow(data))
  } else {
    data[predictors]
  }
  for (term in names(condition)) {
    value <- prediction_grid_condition_value(
      condition[[term]],
      data[[term]],
      term
    )
    base[[term]] <- rep(value, nrow(base))
  }
  rows <- lapply(seq_len(nrow(focal_grid)), function(i) {
    out <- base
    for (term in focal) {
      out[[term]] <- rep(focal_grid[[term]][i], nrow(base))
    }
    out
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

prediction_grid_empty_data_frame <- function(n) {
  out <- data.frame(.drm_row = seq_len(n))
  out$.drm_row <- NULL
  out
}

prediction_grid_condition_value <- function(values, template, term) {
  if (length(values) != 1L || anyNA(values)) {
    cli::cli_abort(
      "{.arg condition} values for {.val {term}} must have length 1 and cannot be missing."
    )
  }
  out <- prediction_grid_cast_values(values, template, term = term)
  if (anyNA(out)) {
    cli::cli_abort(
      "{.arg condition} values for {.val {term}} must have length 1 and cannot be missing."
    )
  }
  out
}

prediction_grid_attach_metadata <- function(
  out,
  object,
  focal,
  condition,
  predictors,
  margin,
  weights
) {
  reference_terms <- setdiff(predictors, c(focal, names(condition)))
  attr(out, "prediction_grid") <- list(
    focal_terms = focal,
    conditioned_terms = names(condition),
    margin = margin,
    weights = weights,
    grid_source = paste0(margin, "_prediction_grid"),
    reference_terms = reference_terms,
    predictor_terms = predictors,
    n_source_rows = nrow(object$data),
    n_grid_rows = nrow(out)
  )
  class(out) <- c("drm_prediction_grid", class(out))
  out
}

prediction_grid_tz <- function(x) {
  tz <- attr(x, "tzone")
  if (is.null(tz) || length(tz) == 0L || !nzchar(tz[[1L]])) {
    return("UTC")
  }
  tz[[1L]]
}

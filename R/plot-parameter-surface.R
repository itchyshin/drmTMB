#' Plot predicted distributional-parameter surfaces
#'
#' `plot_parameter_surface()` is a small `ggplot2` consumer for long tables
#' returned by [predict_parameters()]. It does not fit a model, build a grid,
#' compute predictions, compute confidence intervals, or choose an estimand.
#' Build an explicit grid with [prediction_grid()] or another data-frame
#' workflow first, then pass the resulting prediction table to this helper.
#'
#' The helper plots `estimate` against one supplied column. It expects the
#' interval provenance columns created by [predict_parameters()] so the plotted
#' data keep their uncertainty status attached, even though this first helper
#' does not draw intervals. When the filtered table contains a single
#' distributional parameter, the y-axis label names that parameter and, when
#' unique, the prediction scale.
#'
#' @param data A data frame returned by [predict_parameters()], or a compatible
#'   long table with columns `dpar`, `type`, `estimate`, `conf.status`, and
#'   `interval_source`.
#' @param x Character scalar naming the column to draw on the x-axis.
#' @param colour Optional character scalar naming a column to map to colour.
#' @param group Optional character scalar naming a column to group lines. If
#'   `NULL`, lines are grouped by `dpar`, `colour`, and `facet` columns when
#'   present.
#' @param facet Optional character scalar naming a column to facet by. Use
#'   `NULL` to suppress faceting. The default facets by `dpar`.
#' @param dpar Optional character vector of distributional parameters to keep.
#' @param type Optional character vector of prediction scales to keep, such as
#'   `"response"` or `"link"`.
#' @param line Logical; draw lines through the estimates.
#' @param point Logical; draw points at the estimates.
#' @param ... Reserved for future options.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' dat <- data.frame(
#'   y = c(0.2, 0.5, 1.1, 1.4, 1.8, 2.2),
#'   x = c(-1, -0.5, 0, 0.5, 1, 1.5)
#' )
#' fit <- drmTMB(bf(y ~ x, sigma ~ x), data = dat)
#' grid <- data.frame(x = seq(-1, 1.5, length.out = 6))
#' pred <- predict_parameters(fit, newdata = grid, dpar = c("mu", "sigma"))
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   plot_parameter_surface(pred, x = "x")
#' }
#' @export
plot_parameter_surface <- function(
  data,
  x,
  colour = NULL,
  group = NULL,
  facet = "dpar",
  dpar = NULL,
  type = NULL,
  line = TRUE,
  point = TRUE,
  ...
) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("{.arg ...} is reserved for future options.")
  }
  plot_parameter_surface_require_ggplot2()
  validate_plot_parameter_surface_data(data)
  x <- validate_plot_parameter_surface_column(x, data, "x")
  colour <- validate_plot_parameter_surface_column(colour, data, "colour")
  group <- validate_plot_parameter_surface_column(group, data, "group")
  facet <- validate_plot_parameter_surface_column(facet, data, "facet")
  line <- validate_plot_parameter_surface_flag(line, "line")
  point <- validate_plot_parameter_surface_flag(point, "point")
  if (!line && !point) {
    cli::cli_abort("At least one of {.arg line} or {.arg point} must be TRUE.")
  }

  data <- filter_plot_parameter_surface_data(data, dpar = dpar, type = type)
  y_label <- plot_parameter_surface_y_label(data)
  data <- add_plot_parameter_surface_columns(
    data,
    x = x,
    colour = colour,
    group = group,
    facet = facet
  )
  mapping <- plot_parameter_surface_mapping(has_colour = !is.null(colour))
  out <- ggplot2::ggplot(data, mapping)
  if (line) {
    out <- out + ggplot2::geom_line(na.rm = TRUE)
  }
  if (point) {
    out <- out + ggplot2::geom_point(na.rm = TRUE)
  }
  if (!is.null(facet)) {
    out <- out +
      ggplot2::facet_wrap(~.drmTMB_plot_facet, scales = "free_y")
  }
  out +
    ggplot2::labs(
      x = x,
      y = y_label,
      colour = colour
    )
}

plot_parameter_surface_require_ggplot2 <- function() {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.fn plot_parameter_surface} requires the {.pkg ggplot2} package.",
      i = "Install it with {.code install.packages(\"ggplot2\")}."
    ))
  }
  invisible(TRUE)
}

validate_plot_parameter_surface_data <- function(data) {
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame.")
  }
  required <- c("dpar", "type", "estimate", "conf.status", "interval_source")
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    cli::cli_abort(c(
      "{.arg data} is missing required prediction-table column{?s}: {.val {missing}}.",
      i = "Use {.fn predict_parameters} or supply a compatible long table."
    ))
  }
  if (!is.numeric(data$estimate)) {
    cli::cli_abort("{.arg data} column {.val estimate} must be numeric.")
  }
  invisible(data)
}

validate_plot_parameter_surface_column <- function(x, data, argument) {
  if (is.null(x)) {
    return(NULL)
  }
  if (!is.character(x) || length(x) != 1L || is.na(x)) {
    cli::cli_abort("{.arg {argument}} must be a single column name or NULL.")
  }
  if (!x %in% names(data)) {
    cli::cli_abort(c(
      "{.arg {argument}} must name a column in {.arg data}: {.val {x}}.",
      i = "Available columns: {.val {names(data)}}."
    ))
  }
  x
}

validate_plot_parameter_surface_flag <- function(x, argument) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    cli::cli_abort("{.arg {argument}} must be a single TRUE or FALSE value.")
  }
  x
}

filter_plot_parameter_surface_data <- function(data, dpar, type) {
  if (!is.null(dpar)) {
    if (!is.character(dpar) || length(dpar) < 1L || anyNA(dpar)) {
      cli::cli_abort("{.arg dpar} must be a non-empty character vector.")
    }
    unknown <- setdiff(dpar, unique(data$dpar))
    if (length(unknown) > 0L) {
      cli::cli_abort(c(
        "Unknown distributional parameter{?s}: {.val {unknown}}.",
        i = "Available parameters: {.val {unique(data$dpar)}}."
      ))
    }
    data <- data[data$dpar %in% dpar, , drop = FALSE]
  }
  if (!is.null(type)) {
    if (!is.character(type) || length(type) < 1L || anyNA(type)) {
      cli::cli_abort("{.arg type} must be a non-empty character vector.")
    }
    unknown <- setdiff(type, unique(data$type))
    if (length(unknown) > 0L) {
      cli::cli_abort(c(
        "Unknown prediction scale{?s}: {.val {unknown}}.",
        i = "Available scales: {.val {unique(data$type)}}."
      ))
    }
    data <- data[data$type %in% type, , drop = FALSE]
  }
  row.names(data) <- NULL
  data
}

plot_parameter_surface_y_label <- function(data) {
  dpar <- unique(as.character(data$dpar))
  dpar <- dpar[!is.na(dpar)]
  if (length(dpar) != 1L) {
    return("Estimate")
  }
  type <- unique(as.character(data$type))
  type <- type[!is.na(type)]
  if (length(type) == 1L) {
    return(sprintf("%s estimate (%s scale)", dpar, type))
  }
  sprintf("%s estimate", dpar)
}

add_plot_parameter_surface_columns <- function(data, x, colour, group, facet) {
  data$.drmTMB_plot_x <- data[[x]]
  if (!is.null(colour)) {
    data$.drmTMB_plot_colour <- data[[colour]]
  }
  if (!is.null(facet)) {
    data$.drmTMB_plot_facet <- data[[facet]]
  }
  if (!is.null(group)) {
    data$.drmTMB_plot_group <- data[[group]]
    return(data)
  }
  group_vars <- unique(c("dpar", colour, facet))
  group_vars <- group_vars[!is.na(group_vars)]
  data$.drmTMB_plot_group <- interaction(
    data[group_vars],
    drop = TRUE,
    lex.order = TRUE
  )
  data
}

plot_parameter_surface_mapping <- function(has_colour) {
  args <- list(
    x = as.name(".drmTMB_plot_x"),
    y = as.name("estimate"),
    group = as.name(".drmTMB_plot_group")
  )
  if (has_colour) {
    args$colour <- as.name(".drmTMB_plot_colour")
  }
  do.call(ggplot2::aes, args)
}

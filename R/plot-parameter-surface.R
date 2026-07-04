#' Plot predicted distributional-parameter surfaces
#'
#' `plot_parameter_surface()` is a small `ggplot2` consumer for long tables
#' returned by [predict_parameters()]. It does not fit a model, build a grid,
#' compute predictions, compute confidence intervals, or choose an estimand.
#' Build an explicit grid with [prediction_grid()] or another data-frame
#' workflow first, then pass the resulting prediction table to this helper.
#'
#' The helper plots `estimate` against one supplied column. It expects the
#' interval provenance columns created by [predict_parameters()]. When finite
#' `conf.low` and `conf.high` columns are present and the provenance columns
#' describe a real interval, it draws confidence bands for continuous x-values
#' and interval bars for discrete x-values. Rows without finite supported bounds
#' remain visible as point or line estimates only. When the filtered table
#' contains a single
#' distributional parameter, the y-axis label names that parameter and, when
#' unique, the prediction scale.
#'
#' @param data A data frame returned by [predict_parameters()], or a compatible
#'   long table with columns `dpar`, `type`, `estimate`, `conf.status`, and
#'   `interval_source`. If `conf.low` and `conf.high` are present, both must be
#'   numeric.
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
#' @param interval Logical; draw finite `conf.low`/`conf.high` intervals when
#'   those columns are present and `conf.status` plus `interval_source` indicate
#'   that an interval was actually computed.
#' @param ... Reserved for future options.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' x <- seq(-1, 1.5, length.out = 8)
#' pred <- rbind(
#'   data.frame(
#'     dpar = "mu",
#'     type = "response",
#'     estimate = 1 + 0.5 * x,
#'     conf.low = 0.85 + 0.5 * x,
#'     conf.high = 1.15 + 0.5 * x,
#'     conf.status = "wald",
#'     interval_source = "wald",
#'     x = x
#'   ),
#'   data.frame(
#'     dpar = "sigma",
#'     type = "response",
#'     estimate = 0.55 + 0.08 * x,
#'     conf.low = 0.47 + 0.08 * x,
#'     conf.high = 0.63 + 0.08 * x,
#'     conf.status = "wald",
#'     interval_source = "wald",
#'     x = x
#'   )
#' )
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   plot_parameter_surface(pred, x = "x", point = FALSE) +
#'     ggplot2::labs(
#'       title = "Predicted parameter surfaces",
#'       subtitle = "Ribbons are Wald intervals from the supplied table"
#'     ) +
#'     ggplot2::theme_minimal(base_size = 11)
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
  interval = TRUE,
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
  interval <- validate_plot_parameter_surface_flag(interval, "interval")
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
  has_colour <- !is.null(colour)
  mapping <- plot_parameter_surface_mapping(has_colour = has_colour)
  out <- ggplot2::ggplot(data, mapping)
  interval_ribbon <- FALSE
  if (isTRUE(interval)) {
    interval_data <- plot_parameter_surface_interval_data(data)
    if (nrow(interval_data) > 0L) {
      interval_ribbon <- plot_parameter_surface_interval_is_ribbon(
        interval_data
      )
      out <- out +
        plot_parameter_surface_interval_layer(
          interval_data,
          has_colour = has_colour,
          ribbon = interval_ribbon
        )
    }
  }
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
  out <- out +
    ggplot2::labs(
      x = x,
      y = y_label,
      colour = colour
    )
  if (interval_ribbon && has_colour) {
    out <- out + ggplot2::guides(fill = "none")
  }
  out
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
  interval_columns <- c("conf.low", "conf.high")
  has_interval_columns <- interval_columns %in% names(data)
  if (any(has_interval_columns) && !all(has_interval_columns)) {
    cli::cli_abort(
      "{.arg data} must contain both {.val conf.low} and {.val conf.high} or neither."
    )
  }
  if ("conf.low" %in% names(data) && !is.numeric(data$conf.low)) {
    cli::cli_abort("{.arg data} column {.val conf.low} must be numeric.")
  }
  if ("conf.high" %in% names(data) && !is.numeric(data$conf.high)) {
    cli::cli_abort("{.arg data} column {.val conf.high} must be numeric.")
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

plot_parameter_surface_interval_layer <- function(data, has_colour, ribbon) {
  if (ribbon) {
    return(ggplot2::geom_ribbon(
      data = data,
      mapping = plot_parameter_surface_interval_mapping(
        has_colour = has_colour,
        ribbon = TRUE
      ),
      inherit.aes = FALSE,
      alpha = 0.18,
      colour = NA,
      na.rm = TRUE
    ))
  }

  ggplot2::geom_errorbar(
    data = data,
    mapping = plot_parameter_surface_interval_mapping(
      has_colour = has_colour,
      ribbon = FALSE
    ),
    inherit.aes = FALSE,
    alpha = 0.7,
    width = 0.08,
    na.rm = TRUE
  )
}

plot_parameter_surface_interval_mapping <- function(has_colour, ribbon) {
  args <- list(
    x = as.name(".drmTMB_plot_x"),
    ymin = as.name("conf.low"),
    ymax = as.name("conf.high"),
    group = as.name(".drmTMB_plot_group")
  )
  if (has_colour) {
    if (ribbon) {
      args$fill <- as.name(".drmTMB_plot_colour")
    } else {
      args$colour <- as.name(".drmTMB_plot_colour")
    }
  }
  do.call(ggplot2::aes, args)
}

plot_parameter_surface_interval_data <- function(data) {
  if (!all(c("conf.low", "conf.high") %in% names(data))) {
    return(data[0L, , drop = FALSE])
  }
  keep <- is.finite(data$conf.low) &
    is.finite(data$conf.high) &
    plot_parameter_surface_interval_available(data)
  data[keep, , drop = FALSE]
}

plot_parameter_surface_interval_available <- function(data) {
  # bootstrap is a legitimate interval source (see interval_source_levels()), so
  # keep it in the available whitelist alongside wald and profile.
  unavailable_status <- c(
    "",
    setdiff(interval_status_levels(), c("wald", "profile", "bootstrap"))
  )
  status <- as.character(data$conf.status)
  source <- as.character(data$interval_source)
  !is.na(status) &
    nzchar(status) &
    !status %in% unavailable_status &
    !is.na(source) &
    nzchar(source) &
    source != "not_available"
}

plot_parameter_surface_interval_is_ribbon <- function(data) {
  x <- data$.drmTMB_plot_x
  is.numeric(x) || inherits(x, c("Date", "POSIXct", "POSIXlt"))
}

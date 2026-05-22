#' Plot fitted correlation-pair summaries
#'
#' `plot_corpairs()` is a small `ggplot2` consumer for tables returned by
#' [corpairs()]. It does not compute correlation pairs, fit intervals, or choose
#' a correlation layer. Build the table first with [corpairs()], then pass that
#' table to this helper.
#'
#' The helper draws one hollow point per correlation row. If the table contains
#' finite `conf.low` and `conf.high` bounds plus interval provenance columns
#' that describe a real interval, the default draws a pale Confidence Eye for
#' those rows only, using a guarded Fisher-z/atanh correlation scale to shape
#' the eye. Rows without supported bounds remain visible as point estimates and
#' keep their display interval status attached to the plotted data. Set
#' `interval_style = "line"` for a conventional CI-line variant.
#'
#' @param data A data frame returned by [corpairs()], or a compatible table with
#'   columns `level`, `class`, `parameter`, `estimate`, and `modelled`.
#'   `conf.status` and `interval_source` are optional for point-only tables, but
#'   finite intervals are drawn only when those columns mark a supported interval.
#' @param colour Optional character scalar naming a column to map to colour.
#'   Use `NULL` to suppress colour mapping.
#' @param facet Optional character scalar naming a column to facet by. Use
#'   `NULL` to suppress faceting.
#' @param label Optional character scalar naming a column to use for y-axis row
#'   labels. Use this for publication figures where the full
#'   `level | class | parameter` label is too long. If `NULL`, labels are built
#'   from `level`, `class`, and `parameter`.
#' @param interval Logical; draw finite `conf.low`/`conf.high` intervals when
#'   those columns are present.
#' @param interval_style Character scalar. `"eye"` draws the default Confidence
#'   Eye region plus hollow point estimate. `"line"` draws conventional interval
#'   segments. Ignored when `interval = FALSE`.
#' @param ... Reserved for future options.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' pairs <- data.frame(
#'   level = c("residual", "group", "phylo", "group"),
#'   class = c("residual", "mean-slope", "structured", "scale-scale"),
#'   parameter = c(
#'     "rho12",
#'     "cor((Intercept),x | p | id)",
#'     "cor(mu1,mu2 | species)",
#'     "cor(sigma1,sigma2 | site)"
#'   ),
#'   label = c(
#'     "residual rho12",
#'     "mean-slope cor",
#'     "phylo mu1-mu2",
#'     "sigma block"
#'   ),
#'   estimate = c(0.25, 0.45, -0.30, 0.12),
#'   modelled = c(FALSE, FALSE, FALSE, FALSE),
#'   conf.low = c(NA, 0.10, -0.55, -0.12),
#'   conf.high = c(NA, 0.72, -0.08, 0.34),
#'   conf.status = c("not_requested", "profile", "profile", "profile"),
#'   interval_source = c("not_available", "profile", "profile", "profile")
#' )
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   plot_corpairs(pairs, label = "label") +
#'     ggplot2::theme_minimal(base_size = 11)
#' }
#' @export
plot_corpairs <- function(
  data,
  colour = "level",
  facet = NULL,
  label = NULL,
  interval = TRUE,
  interval_style = c("eye", "line"),
  ...
) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("{.arg ...} is reserved for future options.")
  }
  plot_corpairs_require_ggplot2()
  validate_plot_corpairs_data(data)
  colour <- validate_plot_corpairs_column(colour, data, "colour")
  facet <- validate_plot_corpairs_column(facet, data, "facet")
  label <- validate_plot_corpairs_column(label, data, "label")
  interval <- validate_plot_corpairs_flag(interval, "interval")
  interval_style <- validate_plot_corpairs_interval_style(interval_style)

  data <- add_plot_corpairs_columns(
    data,
    colour = colour,
    facet = facet,
    label = label
  )
  mapping <- plot_corpairs_mapping(has_colour = !is.null(colour))
  out <- ggplot2::ggplot(data, mapping) +
    ggplot2::geom_vline(
      xintercept = 0,
      linetype = "dashed",
      colour = "grey70",
      linewidth = 0.3
    )
  if (isTRUE(interval)) {
    interval_data <- plot_corpairs_interval_data(data)
    if (nrow(interval_data) > 0L) {
      if (identical(interval_style, "line")) {
        out <- out +
          ggplot2::geom_segment(
            data = interval_data,
            mapping = plot_corpairs_interval_mapping(),
            inherit.aes = FALSE,
            linewidth = 0.6,
            colour = "grey35"
          )
      } else {
        eye_data <- plot_corpairs_eye_data(interval_data)
        if (!is.null(colour)) {
          out <- out +
            ggplot2::geom_ribbon(
              data = eye_data,
              mapping = plot_corpairs_eye_mapping(has_fill = TRUE),
              inherit.aes = FALSE,
              alpha = 0.24,
              colour = NA,
              show.legend = FALSE
            )
        } else {
          out <- out +
            ggplot2::geom_ribbon(
              data = eye_data,
              mapping = plot_corpairs_eye_mapping(has_fill = FALSE),
              inherit.aes = FALSE,
              fill = "grey75",
              alpha = 0.35,
              colour = NA
            )
        }
      }
    }
  }
  out <- out +
    ggplot2::geom_point(
      shape = 21,
      fill = "white",
      size = 2.4,
      stroke = 0.9,
      na.rm = TRUE
    ) +
    ggplot2::scale_y_continuous(
      breaks = data$.drmTMB_pair_y,
      labels = data$.drmTMB_pair_label,
      expand = ggplot2::expansion(add = 0.35)
    ) +
    ggplot2::coord_cartesian(xlim = c(-1, 1))
  if (!is.null(facet)) {
    out <- out +
      ggplot2::facet_wrap(~.drmTMB_plot_facet, scales = "free_y")
  }
  out +
    ggplot2::labs(
      x = "Correlation estimate",
      y = NULL,
      colour = colour
    )
}

plot_corpairs_require_ggplot2 <- function() {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.fn plot_corpairs} requires the {.pkg ggplot2} package.",
      i = "Install it with {.code install.packages(\"ggplot2\")}."
    ))
  }
  invisible(TRUE)
}

validate_plot_corpairs_data <- function(data) {
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame.")
  }
  required <- c("level", "class", "parameter", "estimate", "modelled")
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    cli::cli_abort(c(
      "{.arg data} is missing required {.fn corpairs} column{?s}: {.val {missing}}.",
      i = "Use {.fn corpairs} or supply a compatible table."
    ))
  }
  if (!is.numeric(data$estimate)) {
    cli::cli_abort("{.arg data} column {.val estimate} must be numeric.")
  }
  if (
    any(c("conf.low", "conf.high") %in% names(data)) &&
      !all(c("conf.low", "conf.high") %in% names(data))
  ) {
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

validate_plot_corpairs_column <- function(x, data, argument) {
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

validate_plot_corpairs_flag <- function(x, argument) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    cli::cli_abort("{.arg {argument}} must be a single TRUE or FALSE value.")
  }
  x
}

validate_plot_corpairs_interval_style <- function(x) {
  if (!is.character(x) || length(x) < 1L || is.na(x[[1L]])) {
    cli::cli_abort(
      "{.arg interval_style} must be {.val eye} or {.val line}."
    )
  }
  choices <- c("eye", "line")
  x <- x[[1L]]
  if (!x %in% choices) {
    cli::cli_abort(
      "{.arg interval_style} must be {.val eye} or {.val line}."
    )
  }
  x
}

add_plot_corpairs_columns <- function(data, colour, facet, label) {
  data$.drmTMB_pair_label <- plot_corpairs_labels(data, label = label)
  data$.drmTMB_pair_y <- rev(seq_len(nrow(data)))
  if (!"conf.status" %in% names(data)) {
    data$.drmTMB_conf_status <- rep("not_requested", nrow(data))
  } else {
    data$.drmTMB_conf_status <- data$conf.status
  }
  if (!"interval_source" %in% names(data)) {
    data$.drmTMB_interval_source <- rep("not_available", nrow(data))
  } else {
    data$.drmTMB_interval_source <- data$interval_source
  }
  if (!is.null(colour)) {
    data$.drmTMB_plot_colour <- data[[colour]]
  }
  if (!is.null(facet)) {
    data$.drmTMB_plot_facet <- data[[facet]]
  }
  data
}

plot_corpairs_labels <- function(data, label = NULL) {
  if (!is.null(label)) {
    return(data[[label]])
  }
  paste(data$level, data$class, data$parameter, sep = " | ")
}

plot_corpairs_mapping <- function(has_colour) {
  args <- list(
    x = as.name("estimate"),
    y = as.name(".drmTMB_pair_y")
  )
  if (has_colour) {
    args$colour <- as.name(".drmTMB_plot_colour")
  }
  do.call(ggplot2::aes, args)
}

plot_corpairs_interval_mapping <- function() {
  args <- list(
    x = as.name("conf.low"),
    xend = as.name("conf.high"),
    y = as.name(".drmTMB_pair_y"),
    yend = as.name(".drmTMB_pair_y")
  )
  do.call(ggplot2::aes, args)
}

plot_corpairs_eye_mapping <- function(has_fill) {
  args <- list(
    x = as.name(".drmTMB_eye_x"),
    ymin = as.name(".drmTMB_eye_ymin"),
    ymax = as.name(".drmTMB_eye_ymax"),
    group = as.name(".drmTMB_eye_group")
  )
  if (has_fill) {
    args$fill <- as.name(".drmTMB_plot_colour")
  }
  do.call(ggplot2::aes, args)
}

plot_corpairs_eye_data <- function(data, level = 0.95, n = 160, height = 0.26) {
  if (nrow(data) == 0L) {
    return(data.frame())
  }
  do.call(
    rbind,
    lapply(seq_len(nrow(data)), function(i) {
      row <- data[i, , drop = FALSE]
      plot_corpairs_eye_row(row, level = level, n = n, height = height)
    })
  )
}

plot_corpairs_eye_row <- function(row, level, n, height) {
  guard_rho <- function(x) pmin(pmax(x, -0.999999), 0.999999)
  z_estimate <- atanh(guard_rho(row$estimate))
  z_low <- atanh(guard_rho(row$conf.low))
  z_high <- atanh(guard_rho(row$conf.high))
  z_cutoff <- qnorm(1 - (1 - level) / 2)
  z_se <- max((z_high - z_low) / (2 * z_cutoff), .Machine$double.eps)
  cutoff <- 0.5 * qchisq(level, df = 1)
  z <- seq(
    z_estimate - sqrt(2 * cutoff) * z_se,
    z_estimate + sqrt(2 * cutoff) * z_se,
    length.out = n
  )
  compatibility <- pmax(cutoff - 0.5 * ((z - z_estimate) / z_se)^2, 0)
  half_height <- height * compatibility / cutoff
  out <- data.frame(
    .drmTMB_eye_x = tanh(z),
    .drmTMB_eye_ymin = row$.drmTMB_pair_y - half_height,
    .drmTMB_eye_ymax = row$.drmTMB_pair_y + half_height,
    .drmTMB_eye_group = row$.drmTMB_pair_y,
    stringsAsFactors = FALSE
  )
  if (".drmTMB_plot_colour" %in% names(row)) {
    out$.drmTMB_plot_colour <- row$.drmTMB_plot_colour
  }
  out
}

plot_corpairs_interval_data <- function(data) {
  if (!all(c("conf.low", "conf.high") %in% names(data))) {
    return(data[0L, , drop = FALSE])
  }
  keep <- is.finite(data$conf.low) &
    is.finite(data$conf.high) &
    plot_corpairs_interval_available(data)
  data[keep, , drop = FALSE]
}

plot_corpairs_interval_available <- function(data) {
  unavailable_status <- c(
    "",
    setdiff(interval_status_levels(), c("wald", "profile"))
  )
  status <- as.character(data$.drmTMB_conf_status)
  source <- as.character(data$.drmTMB_interval_source)
  !is.na(status) &
    nzchar(status) &
    !status %in% unavailable_status &
    !is.na(source) &
    nzchar(source) &
    source != "not_available"
}

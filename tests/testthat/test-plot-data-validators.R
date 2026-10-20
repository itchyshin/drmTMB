# Fit-free characterisation of the input validators and data helpers behind
# plot_corpairs() and plot_parameter_surface(). Every table is hand-built; no
# model is fitted and nothing is drawn. The *_mapping() helpers need
# ggplot2::aes() and stay in test-plot-corpairs.R and
# test-plot-parameter-surface.R, so this file needs no skip and adds no row to
# the env-skip census.

new_validator_corpairs_table <- function() {
  data.frame(
    level = c("residual", "group"),
    class = c("residual", "mean-slope"),
    parameter = c("rho12", "cor((Intercept),x | p | id)"),
    estimate = c(0.25, 0.45),
    modelled = c(FALSE, FALSE),
    conf.low = c(NA, 0.10),
    conf.high = c(NA, 0.72),
    conf.status = c("not_requested", "profile"),
    interval_source = c("not_available", "profile"),
    stringsAsFactors = FALSE
  )
}

new_validator_surface_table <- function() {
  data.frame(
    dpar = c("mu", "mu", "sigma", "sigma"),
    type = c("link", "response", "link", "response"),
    x = c(1, 2, 1, 2),
    estimate = c(0.1, 0.2, -0.3, 0.7),
    conf.low = c(0, 0.1, -0.5, 0.5),
    conf.high = c(0.2, 0.3, -0.1, 0.9),
    conf.status = c("wald", "wald", "wald", "wald"),
    interval_source = c("wald", "wald", "wald", "wald"),
    stringsAsFactors = FALSE
  )
}

# ---- plot_corpairs validators -----------------------------------------------

test_that("validate_plot_corpairs_data() rejects a non-data-frame", {
  expect_error(
    drmTMB:::validate_plot_corpairs_data(list(estimate = 1)),
    "must be a data frame"
  )
  expect_error(
    drmTMB:::validate_plot_corpairs_data(matrix(1, 1, 1)),
    "must be a data frame"
  )
})

test_that("validate_plot_corpairs_data() names every missing column", {
  data <- new_validator_corpairs_table()[, c("level", "estimate")]
  expect_error(
    drmTMB:::validate_plot_corpairs_data(data),
    "missing required.*column"
  )
  err <- tryCatch(
    drmTMB:::validate_plot_corpairs_data(data),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "class", fixed = TRUE)
  expect_match(err, "parameter", fixed = TRUE)
  expect_match(err, "modelled", fixed = TRUE)
  expect_false(grepl("estimate", sub("column.*", "", err)))
})

test_that("validate_plot_corpairs_data() requires numeric estimate and bounds", {
  data <- new_validator_corpairs_table()
  data$estimate <- as.character(data$estimate)
  expect_error(
    drmTMB:::validate_plot_corpairs_data(data),
    "estimate.*must be numeric"
  )

  data <- new_validator_corpairs_table()
  data$conf.low <- as.character(data$conf.low)
  expect_error(
    drmTMB:::validate_plot_corpairs_data(data),
    "conf.low.*must be numeric"
  )

  data <- new_validator_corpairs_table()
  data$conf.high <- as.character(data$conf.high)
  expect_error(
    drmTMB:::validate_plot_corpairs_data(data),
    "conf.high.*must be numeric"
  )
})

test_that("validate_plot_corpairs_data() needs both interval columns or neither", {
  base <- new_validator_corpairs_table()
  only_low <- base[, setdiff(names(base), "conf.high")]
  only_high <- base[, setdiff(names(base), "conf.low")]
  expect_error(
    drmTMB:::validate_plot_corpairs_data(only_low),
    "both.*conf.low.*conf.high.*or neither"
  )
  expect_error(
    drmTMB:::validate_plot_corpairs_data(only_high),
    "both.*conf.low.*conf.high.*or neither"
  )
})

test_that("validate_plot_corpairs_data() returns valid tables invisibly", {
  data <- new_validator_corpairs_table()
  expect_invisible(out <- drmTMB:::validate_plot_corpairs_data(data))
  expect_identical(out, data)

  no_interval <- data[, c("level", "class", "parameter", "estimate", "modelled")]
  expect_identical(drmTMB:::validate_plot_corpairs_data(no_interval), no_interval)
})

test_that("validate_plot_corpairs_column() handles NULL, bad input and names", {
  data <- new_validator_corpairs_table()
  expect_null(drmTMB:::validate_plot_corpairs_column(NULL, data, "colour"))
  for (bad in list(1, c("level", "class"), NA_character_, TRUE)) {
    expect_error(
      drmTMB:::validate_plot_corpairs_column(bad, data, "colour"),
      "single column name or NULL"
    )
  }
  expect_error(
    drmTMB:::validate_plot_corpairs_column("nope", data, "facet"),
    "facet.*must name a column"
  )
  expect_error(
    drmTMB:::validate_plot_corpairs_column("nope", data, "facet"),
    "Available columns"
  )
  expect_identical(
    drmTMB:::validate_plot_corpairs_column("level", data, "colour"),
    "level"
  )
})

test_that("validate_plot_corpairs_flag() accepts one TRUE or FALSE only", {
  expect_true(drmTMB:::validate_plot_corpairs_flag(TRUE, "show_labels"))
  expect_false(drmTMB:::validate_plot_corpairs_flag(FALSE, "show_labels"))
  for (bad in list(NA, c(TRUE, FALSE), "TRUE", 1, NULL, logical(0))) {
    expect_error(
      drmTMB:::validate_plot_corpairs_flag(bad, "show_labels"),
      "show_labels.*single TRUE or FALSE"
    )
  }
})

test_that("validate_plot_corpairs_interval_style() accepts eye and line", {
  expect_identical(drmTMB:::validate_plot_corpairs_interval_style("eye"), "eye")
  expect_identical(drmTMB:::validate_plot_corpairs_interval_style("line"), "line")
  expect_identical(
    drmTMB:::validate_plot_corpairs_interval_style(c("line", "eye")),
    "line"
  )
  for (bad in list("box", NA_character_, 1, character(0), NULL)) {
    expect_error(
      drmTMB:::validate_plot_corpairs_interval_style(bad),
      "interval_style.*must be.*eye.*line"
    )
  }
})

# ---- plot_corpairs helpers ---------------------------------------------------

test_that("plot_corpairs_labels() uses a column or pastes the identifiers", {
  data <- new_validator_corpairs_table()
  expect_identical(
    drmTMB:::plot_corpairs_labels(data),
    c("residual | residual | rho12", "group | mean-slope | cor((Intercept),x | p | id)")
  )
  expect_identical(
    drmTMB:::plot_corpairs_labels(data, label = "parameter"),
    data$parameter
  )
})

test_that("add_plot_corpairs_columns() adds the internal plotting columns", {
  data <- new_validator_corpairs_table()
  out <- drmTMB:::add_plot_corpairs_columns(
    data,
    colour = "level",
    facet = "class",
    label = NULL
  )
  expect_identical(out$.drmTMB_pair_y, c(2L, 1L))
  expect_identical(out$.drmTMB_pair_label, drmTMB:::plot_corpairs_labels(data))
  expect_identical(out$.drmTMB_conf_status, data$conf.status)
  expect_identical(out$.drmTMB_interval_source, data$interval_source)
  expect_identical(out$.drmTMB_plot_colour, data$level)
  expect_identical(out$.drmTMB_plot_facet, data$class)
  expect_identical(out$estimate, data$estimate)
})

test_that("add_plot_corpairs_columns() fills defaults when status is absent", {
  data <- new_validator_corpairs_table()
  data$conf.status <- NULL
  data$interval_source <- NULL
  out <- drmTMB:::add_plot_corpairs_columns(
    data,
    colour = NULL,
    facet = NULL,
    label = "parameter"
  )
  expect_identical(out$.drmTMB_conf_status, rep("not_requested", 2L))
  expect_identical(out$.drmTMB_interval_source, rep("not_available", 2L))
  expect_false(".drmTMB_plot_colour" %in% names(out))
  expect_false(".drmTMB_plot_facet" %in% names(out))
  expect_identical(out$.drmTMB_pair_label, data$parameter)
})

test_that("plot_corpairs interval helpers keep only available finite rows", {
  data <- drmTMB:::add_plot_corpairs_columns(
    new_validator_corpairs_table(),
    colour = NULL,
    facet = NULL,
    label = NULL
  )
  expect_identical(
    drmTMB:::plot_corpairs_interval_available(data),
    c(FALSE, TRUE)
  )
  kept <- drmTMB:::plot_corpairs_interval_data(data)
  expect_identical(kept$parameter, "cor((Intercept),x | p | id)")

  no_interval <- data[, setdiff(names(data), c("conf.low", "conf.high"))]
  expect_identical(nrow(drmTMB:::plot_corpairs_interval_data(no_interval)), 0L)
})

test_that("plot_corpairs_eye_data() is empty for no rows and symmetric in z", {
  data <- drmTMB:::add_plot_corpairs_columns(
    new_validator_corpairs_table(),
    colour = "level",
    facet = NULL,
    label = NULL
  )
  expect_identical(
    drmTMB:::plot_corpairs_eye_data(data[0L, , drop = FALSE]),
    data.frame()
  )
  eye <- drmTMB:::plot_corpairs_eye_data(
    data[2L, , drop = FALSE],
    n = 21,
    height = 0.2
  )
  expect_identical(nrow(eye), 21L)
  expect_true(all(eye$.drmTMB_eye_ymax >= eye$.drmTMB_eye_ymin))
  expect_equal(max(eye$.drmTMB_eye_ymax - eye$.drmTMB_eye_ymin), 0.4)
  expect_identical(unique(eye$.drmTMB_eye_group), 1L)
  expect_true(".drmTMB_plot_colour" %in% names(eye))
})

test_that("validate_plot_parameter_surface_data() aborts on bad tables", {
  expect_error(
    drmTMB:::validate_plot_parameter_surface_data(1:3),
    "must be a data frame"
  )

  data <- new_validator_surface_table()[, c("dpar", "estimate")]
  err <- tryCatch(
    drmTMB:::validate_plot_parameter_surface_data(data),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "missing required prediction-table column")
  expect_match(err, "type", fixed = TRUE)
  expect_match(err, "conf.status", fixed = TRUE)
  expect_match(err, "interval_source", fixed = TRUE)

  data <- new_validator_surface_table()
  data$estimate <- as.character(data$estimate)
  expect_error(
    drmTMB:::validate_plot_parameter_surface_data(data),
    "estimate.*must be numeric"
  )
})

test_that("validate_plot_parameter_surface_data() checks interval columns", {
  base <- new_validator_surface_table()
  expect_error(
    drmTMB:::validate_plot_parameter_surface_data(
      base[, setdiff(names(base), "conf.high")]
    ),
    "both.*conf.low.*conf.high.*or neither"
  )
  expect_error(
    drmTMB:::validate_plot_parameter_surface_data(
      base[, setdiff(names(base), "conf.low")]
    ),
    "both.*conf.low.*conf.high.*or neither"
  )

  data <- base
  data$conf.low <- as.character(data$conf.low)
  expect_error(
    drmTMB:::validate_plot_parameter_surface_data(data),
    "conf.low.*must be numeric"
  )
  data <- base
  data$conf.high <- as.character(data$conf.high)
  expect_error(
    drmTMB:::validate_plot_parameter_surface_data(data),
    "conf.high.*must be numeric"
  )

  expect_identical(drmTMB:::validate_plot_parameter_surface_data(base), base)
  no_interval <- base[, setdiff(names(base), c("conf.low", "conf.high"))]
  expect_identical(
    drmTMB:::validate_plot_parameter_surface_data(no_interval),
    no_interval
  )
})

test_that("validate_plot_parameter_surface_column() mirrors the corpairs shape", {
  data <- new_validator_surface_table()
  expect_null(drmTMB:::validate_plot_parameter_surface_column(NULL, data, "x"))
  for (bad in list(1, c("x", "dpar"), NA_character_)) {
    expect_error(
      drmTMB:::validate_plot_parameter_surface_column(bad, data, "x"),
      "single column name or NULL"
    )
  }
  expect_error(
    drmTMB:::validate_plot_parameter_surface_column("nope", data, "x"),
    "must name a column"
  )
  expect_error(
    drmTMB:::validate_plot_parameter_surface_column("nope", data, "x"),
    "Available columns"
  )
  expect_identical(
    drmTMB:::validate_plot_parameter_surface_column("x", data, "x"),
    "x"
  )
})

test_that("validate_plot_parameter_surface_flag() accepts one TRUE or FALSE", {
  expect_true(drmTMB:::validate_plot_parameter_surface_flag(TRUE, "ribbon"))
  expect_false(drmTMB:::validate_plot_parameter_surface_flag(FALSE, "ribbon"))
  for (bad in list(NA, c(TRUE, TRUE), "yes", 0, NULL)) {
    expect_error(
      drmTMB:::validate_plot_parameter_surface_flag(bad, "ribbon"),
      "ribbon.*single TRUE or FALSE"
    )
  }
})

# ---- plot_parameter_surface helpers -----------------------------------------

test_that("filter_plot_parameter_surface_data() subsets and resets row names", {
  data <- new_validator_surface_table()
  expect_identical(
    drmTMB:::filter_plot_parameter_surface_data(data, NULL, NULL),
    data
  )

  by_dpar <- drmTMB:::filter_plot_parameter_surface_data(data, "sigma", NULL)
  expect_identical(by_dpar$dpar, c("sigma", "sigma"))
  expect_identical(row.names(by_dpar), c("1", "2"))

  both <- drmTMB:::filter_plot_parameter_surface_data(
    data,
    c("mu", "sigma"),
    "response"
  )
  expect_identical(both$estimate, c(0.2, 0.7))
  expect_identical(nrow(both), 2L)
})

test_that("filter_plot_parameter_surface_data() aborts on bad selections", {
  data <- new_validator_surface_table()
  expect_error(
    drmTMB:::filter_plot_parameter_surface_data(data, 1, NULL),
    "dpar.*non-empty character vector"
  )
  expect_error(
    drmTMB:::filter_plot_parameter_surface_data(data, character(0), NULL),
    "dpar.*non-empty character vector"
  )
  expect_error(
    drmTMB:::filter_plot_parameter_surface_data(data, c("mu", NA), NULL),
    "dpar.*non-empty character vector"
  )
  expect_error(
    drmTMB:::filter_plot_parameter_surface_data(data, "rho12", NULL),
    "Unknown distributional parameter"
  )
  expect_error(
    drmTMB:::filter_plot_parameter_surface_data(data, "rho12", NULL),
    "Available parameters"
  )
  expect_error(
    drmTMB:::filter_plot_parameter_surface_data(data, NULL, 1),
    "type.*non-empty character vector"
  )
  expect_error(
    drmTMB:::filter_plot_parameter_surface_data(data, NULL, "log"),
    "Unknown prediction scale"
  )
  expect_error(
    drmTMB:::filter_plot_parameter_surface_data(data, NULL, "log"),
    "Available scales"
  )
})

test_that("plot_parameter_surface_y_label() reflects the dpar and scale", {
  data <- new_validator_surface_table()
  expect_identical(drmTMB:::plot_parameter_surface_y_label(data), "Estimate")

  mu <- data[data$dpar == "mu", ]
  expect_identical(drmTMB:::plot_parameter_surface_y_label(mu), "mu estimate")

  mu_link <- mu[mu$type == "link", ]
  expect_identical(
    drmTMB:::plot_parameter_surface_y_label(mu_link),
    "mu estimate (link scale)"
  )

  mu_na_type <- mu_link
  mu_na_type$type <- NA_character_
  expect_identical(
    drmTMB:::plot_parameter_surface_y_label(mu_na_type),
    "mu estimate"
  )
  expect_identical(
    drmTMB:::plot_parameter_surface_y_label(data[0L, , drop = FALSE]),
    "Estimate"
  )
})

test_that("add_plot_parameter_surface_columns() builds x, colour, facet, group", {
  data <- new_validator_surface_table()
  data$arm <- c("a", "b", "a", "b")
  out <- drmTMB:::add_plot_parameter_surface_columns(
    data,
    x = "x",
    colour = "arm",
    group = NULL,
    facet = "type"
  )
  expect_identical(out$.drmTMB_plot_x, data$x)
  expect_identical(out$.drmTMB_plot_colour, data$arm)
  expect_identical(out$.drmTMB_plot_facet, data$type)
  expect_s3_class(out$.drmTMB_plot_group, "factor")
  expect_identical(
    as.character(out$.drmTMB_plot_group),
    paste(data$dpar, data$arm, data$type, sep = ".")
  )

  plain <- drmTMB:::add_plot_parameter_surface_columns(
    data,
    x = "x",
    colour = NULL,
    group = NULL,
    facet = NULL
  )
  expect_false(".drmTMB_plot_colour" %in% names(plain))
  expect_false(".drmTMB_plot_facet" %in% names(plain))
  expect_identical(as.character(plain$.drmTMB_plot_group), data$dpar)
})

test_that("add_plot_parameter_surface_columns() honours an explicit group", {
  data <- new_validator_surface_table()
  data$id <- c("p", "q", "p", "q")
  out <- drmTMB:::add_plot_parameter_surface_columns(
    data,
    x = "x",
    colour = NULL,
    group = "id",
    facet = NULL
  )
  expect_identical(out$.drmTMB_plot_group, data$id)
})

test_that("plot_parameter_surface interval helpers keep available rows", {
  data <- drmTMB:::add_plot_parameter_surface_columns(
    new_validator_surface_table(),
    x = "x",
    colour = NULL,
    group = NULL,
    facet = NULL
  )
  expect_identical(
    drmTMB:::plot_parameter_surface_interval_available(data),
    rep(TRUE, 4L)
  )
  data$conf.status[2L] <- "not_requested"
  data$conf.low[3L] <- NA
  kept <- drmTMB:::plot_parameter_surface_interval_data(data)
  expect_identical(kept$estimate, c(0.1, 0.7))

  no_interval <- data[, setdiff(names(data), c("conf.low", "conf.high"))]
  expect_identical(
    nrow(drmTMB:::plot_parameter_surface_interval_data(no_interval)),
    0L
  )
})

test_that("plot_parameter_surface_interval_is_ribbon() depends on the x type", {
  ribbon <- drmTMB:::plot_parameter_surface_interval_is_ribbon
  expect_true(ribbon(data.frame(.drmTMB_plot_x = c(1, 2))))
  expect_true(ribbon(data.frame(.drmTMB_plot_x = 1:2)))
  expect_true(ribbon(data.frame(.drmTMB_plot_x = as.Date("2026-01-01") + 0:1)))
  expect_true(ribbon(data.frame(
    .drmTMB_plot_x = as.POSIXct("2026-01-01", tz = "UTC") + 0:1
  )))
  expect_false(ribbon(data.frame(.drmTMB_plot_x = c("a", "b"))))
  expect_false(ribbon(data.frame(.drmTMB_plot_x = factor(c("a", "b")))))
})

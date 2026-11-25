# plot_corpairs validators from R/plot-corpairs.R.

valid_corpairs_df <- function() {
  drmTMB:::empty_corpairs()
}

test_that("validate_plot_corpairs_data() checks required columns", {
  base <- valid_corpairs_df()
  base <- rbind(
    base,
    data.frame(
      level = "residual",
      group = NA,
      block = NA,
      from_dpar = "mu",
      to_dpar = "mu",
      from_coef = "(Intercept)",
      to_coef = "(Intercept)",
      from_response = "y",
      to_response = "y",
      class = "mean-mean",
      parameter = "rho",
      estimate = 0.1,
      min = NA,
      max = NA,
      n_values = 1L,
      link_estimate = 0.1,
      link_min = NA,
      link_max = NA,
      modelled = TRUE,
      conf.status = "not_requested",
      interval_source = NA_character_,
      stringsAsFactors = FALSE
    )
  )
  expect_invisible(drmTMB:::validate_plot_corpairs_data(base))
  bad <- base[, setdiff(names(base), "estimate"), drop = FALSE]
  expect_error(drmTMB:::validate_plot_corpairs_data(bad), "estimate")
})

test_that("validate_plot_corpairs_column() validates optional aesthetics", {
  df <- valid_corpairs_df()
  df <- rbind(
    df,
    data.frame(
      level = "residual",
      group = NA,
      block = NA,
      from_dpar = "mu",
      to_dpar = "mu",
      from_coef = "b0",
      to_coef = "b0",
      from_response = "y",
      to_response = "y",
      class = "mean-mean",
      parameter = "a",
      estimate = 0.2,
      min = NA,
      max = NA,
      n_values = 1L,
      link_estimate = 0.2,
      link_min = NA,
      link_max = NA,
      modelled = TRUE,
      conf.status = "not_requested",
      interval_source = NA_character_,
      colour_col = "blue",
      stringsAsFactors = FALSE
    )
  )
  expect_null(drmTMB:::validate_plot_corpairs_column(NULL, df, "colour"))
  expect_equal(
    drmTMB:::validate_plot_corpairs_column("colour_col", df, "colour"),
    "colour_col"
  )
  expect_error(
    drmTMB:::validate_plot_corpairs_column("missing", df, "facet"),
    "column"
  )
  expect_error(
    drmTMB:::validate_plot_corpairs_column(1L, df, "colour"),
    "single column name"
  )
})

test_that("validate_plot_corpairs_flag() and interval_style()", {
  expect_true(drmTMB:::validate_plot_corpairs_flag(TRUE, "show_eyes"))
  expect_error(
    drmTMB:::validate_plot_corpairs_flag(NA, "show_eyes"),
    "TRUE or FALSE"
  )
  expect_equal(drmTMB:::validate_plot_corpairs_interval_style("eye"), "eye")
  expect_equal(drmTMB:::validate_plot_corpairs_interval_style("line"), "line")
  expect_error(
    drmTMB:::validate_plot_corpairs_interval_style("bar"),
    "eye"
  )
})

test_that("validate_plot_corpairs_data() rejects partial interval columns", {
  df <- valid_corpairs_df()
  df$conf.low <- numeric()
  expect_error(
    drmTMB:::validate_plot_corpairs_data(df),
    "conf.low"
  )
})
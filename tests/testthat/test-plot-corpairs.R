new_plot_corpairs_table <- function() {
  data.frame(
    level = c("residual", "group", "phylogenetic"),
    class = c("residual", "mean-slope", "mean-mean"),
    parameter = c(
      "rho12",
      "cor((Intercept),x | p | id)",
      "cor(mu1,mu2 | phylo | species)"
    ),
    estimate = c(0.25, 0.45, -0.20),
    modelled = c(FALSE, FALSE, FALSE),
    conf.low = c(NA, 0.10, -0.55),
    conf.high = c(NA, 0.72, 0.12),
    conf.status = c("not_requested", "profile", "profile"),
    stringsAsFactors = FALSE
  )
}

test_that("plot_corpairs() returns a ggplot for corpairs tables", {
  testthat::skip_if_not_installed("ggplot2")
  pairs <- new_plot_corpairs_table()

  out <- plot_corpairs(pairs)

  expect_s3_class(out, "ggplot")
  expect_equal(out$labels$x, "Correlation estimate")
  expect_equal(out$labels$colour, "level")
  expect_equal(out$data$.drmTMB_conf_status, pairs$conf.status)
  expect_match(out$data$.drmTMB_pair_label[[1L]], "residual")
  expect_length(out$layers, 3L)
  built <- ggplot2::ggplot_build(out)
  expect_equal(nrow(built$data[[2L]]), 2L)
  expect_equal(nrow(built$data[[3L]]), 3L)
})

test_that("plot_corpairs() can facet correlation rows", {
  testthat::skip_if_not_installed("ggplot2")
  pairs <- new_plot_corpairs_table()

  out <- plot_corpairs(pairs, facet = "level")

  expect_s3_class(out, "ggplot")
  expect_equal(out$data$.drmTMB_plot_facet, pairs$level)
  built <- ggplot2::ggplot_build(out)
  expect_equal(length(unique(built$layout$layout$PANEL)), 3L)
})

test_that("plot_corpairs() accepts concise publication labels", {
  testthat::skip_if_not_installed("ggplot2")
  pairs <- new_plot_corpairs_table()
  pairs$display <- factor(
    c("Residual\nrho12", "Group\nslope", "Phylogenetic\ntrait"),
    levels = c("Group\nslope", "Phylogenetic\ntrait", "Residual\nrho12")
  )

  out <- plot_corpairs(pairs, label = "display")

  expect_s3_class(out, "ggplot")
  expect_equal(out$data$.drmTMB_pair_label, pairs$display)
  built <- ggplot2::ggplot_build(out)
  expect_equal(nrow(built$data[[2L]]), 2L)
  expect_equal(nrow(built$data[[3L]]), 3L)
})

test_that("plot_corpairs() accepts point-only and empty tables", {
  testthat::skip_if_not_installed("ggplot2")
  pairs <- new_plot_corpairs_table()[c(
    "level",
    "class",
    "parameter",
    "estimate",
    "modelled"
  )]

  out <- plot_corpairs(pairs, colour = NULL)

  expect_s3_class(out, "ggplot")
  expect_null(out$labels$colour)
  expect_equal(out$data$.drmTMB_conf_status, rep("not_requested", nrow(pairs)))
  expect_length(out$layers, 2L)

  empty <- pairs[0L, , drop = FALSE]
  empty_plot <- plot_corpairs(empty)
  expect_s3_class(empty_plot, "ggplot")
  expect_equal(nrow(empty_plot$data), 0L)
})

test_that("plot_corpairs() validates inputs", {
  testthat::skip_if_not_installed("ggplot2")
  pairs <- new_plot_corpairs_table()

  expect_error(plot_corpairs(list()), "data frame")
  expect_error(
    plot_corpairs(pairs[setdiff(names(pairs), "level")]),
    "missing required"
  )
  expect_error(
    plot_corpairs(transform(pairs, estimate = as.character(estimate))),
    "estimate"
  )
  expect_error(
    plot_corpairs(pairs[setdiff(names(pairs), "conf.high")]),
    "both"
  )
  expect_error(
    plot_corpairs(pairs, colour = "missing"),
    "must name a column"
  )
  expect_error(
    plot_corpairs(pairs, facet = "missing"),
    "must name a column"
  )
  expect_error(
    plot_corpairs(pairs, label = "missing"),
    "must name a column"
  )
  expect_error(
    plot_corpairs(pairs, interval = NA),
    "TRUE or FALSE"
  )
  expect_error(
    plot_corpairs(pairs, unknown = TRUE),
    "reserved"
  )
})

test_that("plot_corpairs() reports missing ggplot2 clearly", {
  pairs <- new_plot_corpairs_table()
  testthat::local_mocked_bindings(
    plot_corpairs_require_ggplot2 = function() {
      cli::cli_abort("ggplot2 unavailable")
    }
  )

  expect_error(plot_corpairs(pairs), "ggplot2 unavailable")
})

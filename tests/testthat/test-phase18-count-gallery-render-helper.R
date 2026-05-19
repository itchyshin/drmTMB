phase18_count_gallery_pilot_fixture <- function() {
  list(
    aggregate = data.frame(
      surface = c("poisson_mu_random_effect", "nbinom2_mu_random_effect"),
      cell_id = c(
        "poisson_mu_random_effect_001",
        "nbinom2_mu_random_effect_001"
      ),
      parameter = c("mu:x", "sd:mu:(0 + x | id)"),
      bias = c(0.01, -0.03),
      rmse = c(0.05, 0.09),
      bias_mcse = c(0.004, 0.006),
      rmse_mcse = c(0.003, 0.007)
    ),
    wald_coverage = data.frame(
      surface = "poisson_mu_random_effect",
      cell_id = "poisson_mu_random_effect_001",
      parameter = "mu:x",
      coverage = 1,
      n_interval = 1L
    ),
    profile_coverage = data.frame(
      surface = "nbinom2_mu_random_effect",
      cell_id = "nbinom2_mu_random_effect_001",
      parameter = "sd:mu:(0 + x | id)",
      coverage = 1,
      n_interval = 1L
    ),
    manifest = data.frame(
      cell_id = c(
        "poisson_mu_random_effect_001",
        "nbinom2_mu_random_effect_001"
      ),
      replicate = c(1L, 1L),
      status = c("ok", "ok")
    ),
    failures = data.frame()
  )
}

test_that("Phase 18 count gallery helper writes plot-ready CSV inputs", {
  source(
    system.file("sim/R/sim_plot_data.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_gallery.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  output_dir <- tempfile("phase18-count-gallery-inputs-")
  withr::defer(unlink(output_dir, recursive = TRUE))

  paths <- phase18_write_count_mu_re_gallery_inputs(
    phase18_count_gallery_pilot_fixture(),
    output_dir = output_dir
  )

  expect_true(file.exists(paths$aggregate_csv))
  expect_true(file.exists(paths$coverage_csv))
  expect_true(file.exists(paths$manifest_csv))
  expect_true(file.exists(paths$failures_csv))
  expect_equal(nrow(read.csv(paths$aggregate_csv)), 2L)
  expect_equal(nrow(read.csv(paths$coverage_csv)), 2L)
  expect_equal(nrow(read.csv(paths$manifest_csv)), 2L)
  failures <- read.csv(paths$failures_csv)
  expect_equal(nrow(failures), 0L)
  expect_true(all(c("cell_id", "severity", "message") %in% names(failures)))
  expect_error(
    phase18_write_count_mu_re_gallery_inputs(
      phase18_count_gallery_pilot_fixture(),
      output_dir = output_dir
    ),
    "already exists"
  )
})

test_that("Phase 18 count gallery helper renders the report artifact", {
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available())

  source(
    system.file("sim/R/sim_plot_data.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_gallery.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  root_dir <- tempfile("phase18-count-gallery-render-root-")
  dir.create(root_dir)
  withr::defer(unlink(root_dir, recursive = TRUE))
  withr::local_dir(root_dir)
  output_dir <- "relative-gallery-output"

  out <- phase18_render_count_mu_re_gallery(
    phase18_count_gallery_pilot_fixture(),
    output_dir = output_dir,
    notes = "helper render smoke"
  )

  expect_true(file.exists(out$output_file))
  expect_true(file.exists(out$inputs$aggregate_csv))
  html <- paste(readLines(out$output_file, warn = FALSE), collapse = "\n")
  expect_true(grepl("helper render smoke", html, fixed = TRUE))
  expect_true(grepl("Florence Checks", html, fixed = TRUE))
})

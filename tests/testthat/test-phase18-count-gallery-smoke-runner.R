source_phase18_count_gallery_smoke <- function() {
  env <- parent.frame()
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/R/sim_plot_data.R",
    "sim/R/sim_gallery.R",
    "sim/dgp/sim_dgp_poisson_mu_random_effect.R",
    "sim/dgp/sim_dgp_nbinom2_mu_random_effect.R",
    "sim/fit/sim_summarise_poisson_mu_random_effect.R",
    "sim/fit/sim_summarise_nbinom2_mu_random_effect.R",
    "sim/run/sim_run_poisson_mu_random_effect_smoke.R",
    "sim/run/sim_run_nbinom2_mu_random_effect_smoke.R",
    "sim/run/sim_summary_poisson_mu_random_effect_smoke.R",
    "sim/run/sim_summary_nbinom2_mu_random_effect_smoke.R",
    "sim/run/sim_summary_count_mu_random_effect_pilot.R",
    "sim/run/sim_render_count_mu_gallery_smoke.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Phase 18 count gallery smoke runner renders a real pilot gallery", {
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available())

  source_phase18_count_gallery_smoke()

  output_dir <- tempfile("phase18-count-gallery-smoke-")
  withr::defer(unlink(output_dir, recursive = TRUE))

  out <- phase18_render_count_mu_re_gallery_smoke(
    output_dir = output_dir,
    poisson_conditions = phase18_poisson_mu_re_conditions(
      n_group = 36L,
      n_per_group = 9L
    ),
    nbinom2_conditions = phase18_nbinom2_mu_re_conditions(
      n_group = 44L,
      n_per_group = 10L
    ),
    n_rep = 1L,
    master_seed = 256L,
    notes = "real pilot gallery smoke"
  )

  expect_identical(out$surface, "count_mu_random_effect_gallery_smoke")
  expect_true(file.exists(out$gallery$output_file))
  expect_true(dir.exists(out$result_dir))
  expect_true(dir.exists(out$gallery_dir))
  expect_equal(nrow(out$pilot$aggregate), 10L)
  expect_equal(nrow(out$pilot$manifest), 2L)
  expect_equal(nrow(out$gallery$inputs$plot_data$aggregate), 10L)
  html <- paste(
    readLines(out$gallery$output_file, warn = FALSE),
    collapse = "\n"
  )
  expect_true(grepl("real pilot gallery smoke", html, fixed = TRUE))
  expect_true(grepl("Florence Checks", html, fixed = TRUE))
})

test_that("Phase 18 count mu random-effect plot data is tidy", {
  source(
    system.file("sim/R/sim_plot_data.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  pilot <- list(
    aggregate = data.frame(
      surface = c("poisson_mu_random_effect", "nbinom2_mu_random_effect"),
      cell_id = c(
        "poisson_mu_random_effect_001",
        "nbinom2_mu_random_effect_001"
      ),
      parameter = c("mu:x", "sd:mu:(1 | id)"),
      bias = c(0.02, -0.04),
      rmse = c(0.05, 0.08)
    ),
    replicates = data.frame(
      surface = c("poisson_mu_random_effect", "poisson_mu_random_effect"),
      cell_id = c(
        "poisson_mu_random_effect_001",
        "poisson_mu_random_effect_001"
      ),
      replicate = c(1L, 2L),
      parameter = c("mu:x", "sd:mu:(1 | id)"),
      truth = c(0.2, 0.4),
      estimate = c(0.23, 0.35),
      error = c(0.03, -0.05)
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
      parameter = "sd:mu:(1 | id)",
      coverage = 1,
      n_interval = 1L
    ),
    manifest = data.frame(
      cell_id = c(
        "poisson_mu_random_effect_001",
        "nbinom2_mu_random_effect_001"
      ),
      status = c("ok", "ok")
    ),
    failures = data.frame()
  )

  plot_data <- phase18_count_mu_re_plot_data(pilot)

  expect_named(
    plot_data,
    c("aggregate", "replicates", "coverage", "manifest", "failures")
  )
  expect_equal(plot_data$aggregate$family, c("Poisson", "NB2"))
  expect_equal(
    plot_data$aggregate$parameter_class,
    c("fixed_effect", "random_sd")
  )
  expect_equal(plot_data$aggregate$dpar, c("mu", "mu"))
  expect_equal(plot_data$aggregate$term, c("x", "(1 | id)"))
  expect_equal(plot_data$aggregate$abs_bias, c(0.02, 0.04))
  expect_equal(plot_data$aggregate$artifact_grain, rep("aggregate", 2L))
  expect_equal(plot_data$replicates$family, c("Poisson", "Poisson"))
  expect_equal(plot_data$replicates$abs_error, c(0.03, 0.05))
  expect_equal(plot_data$replicates$artifact_grain, rep("replicate", 2L))
  expect_equal(plot_data$coverage$interval_method, c("wald", "profile"))
  expect_equal(plot_data$coverage$family, c("Poisson", "NB2"))
})

test_that("Phase 18 count mu random-effect plot data validates inputs", {
  source(
    system.file("sim/R/sim_plot_data.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  expect_error(
    phase18_count_mu_re_plot_data(list(aggregate = data.frame())),
    "must contain"
  )
  expect_error(
    phase18_count_mu_re_add_plot_columns(data.frame(parameter = "mu:x")),
    "must contain"
  )
  expect_error(
    phase18_count_mu_re_add_replicate_columns(data.frame(parameter = "mu:x")),
    "must contain"
  )
  empty <- phase18_count_mu_re_plot_data(list(
    aggregate = data.frame(
      surface = "poisson_mu_random_effect",
      cell_id = "cell_001",
      parameter = "mu:x",
      bias = 0,
      rmse = 0
    ),
    wald_coverage = data.frame(
      surface = "poisson_mu_random_effect",
      cell_id = "cell_001",
      parameter = "mu:x",
      coverage = 1,
      n_interval = 1L
    ),
    profile_coverage = data.frame(
      surface = character(),
      cell_id = character(),
      parameter = character(),
      coverage = numeric(),
      n_interval = integer()
    ),
    manifest = data.frame(),
    failures = data.frame()
  ))
  expect_equal(nrow(empty$replicates), 0L)
  expect_true("artifact_grain" %in% names(empty$replicates))
})

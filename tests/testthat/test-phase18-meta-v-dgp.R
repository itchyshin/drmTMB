test_that("Phase 18 meta_V conditions separate vector and dense V cells", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file(
      "sim/dgp/sim_dgp_meta_v.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  conditions <- phase18_meta_v_conditions(
    n_study = c(24L, 48L),
    known_v_type = c("vector", "dense"),
    sigma = 0.2,
    sampling_sd = 0.15,
    sampling_rho = c(0, 0.3)
  )

  expect_true(all(conditions$known_v_type %in% c("vector", "dense")))
  expect_true(all(
    conditions$sampling_rho[conditions$known_v_type == "vector"] == 0
  ))
  expect_true(any(
    conditions$known_v_type == "dense" & conditions$sampling_rho == 0.3
  ))
})

test_that("Phase 18 meta_V DGP returns vector and dense known covariance", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file(
      "sim/dgp/sim_dgp_meta_v.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  dat_vec <- phase18_dgp_meta_v(
    n_study = 18,
    known_v_type = "vector",
    seed = 212,
    cell_id = "meta_v_001",
    replicate = 1L
  )
  dat_vec_again <- phase18_dgp_meta_v(
    n_study = 18,
    known_v_type = "vector",
    seed = 212,
    cell_id = "meta_v_001",
    replicate = 1L
  )
  V_vec <- attr(dat_vec, "V")
  truth_vec <- attr(dat_vec, "truth")

  dat_dense <- phase18_dgp_meta_v(
    n_study = 18,
    known_v_type = "dense",
    sampling_rho = 0.25,
    seed = 213
  )
  V_dense <- attr(dat_dense, "V")
  truth_dense <- attr(dat_dense, "truth")

  expect_equal(dat_vec, dat_vec_again)
  expect_equal(nrow(dat_vec), 18L)
  expect_equal(length(V_vec), 18L)
  expect_false(is.matrix(V_vec))
  expect_true(all(V_vec > 0))
  expect_identical(truth_vec$surface, "meta_v")
  expect_identical(truth_vec$known_v_type, "vector")

  expect_true(is.matrix(V_dense))
  expect_equal(dim(V_dense), c(18L, 18L))
  expect_true(all(
    eigen(V_dense, symmetric = TRUE, only.values = TRUE)$values > 0
  ))
  expect_equal(dat_dense$sampling_var, diag(V_dense))
  expect_identical(truth_dense$known_v_type, "dense")
})

test_that("Phase 18 meta_V pilot fits keep V out of interval targets", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file(
      "sim/dgp/sim_dgp_meta_v.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/fit/sim_summarise_meta_v.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  dat_vec <- phase18_dgp_meta_v(
    n_study = 64,
    known_v_type = "vector",
    beta_mu = c("(Intercept)" = 0.10, x = 0.35),
    sigma = 0.30,
    sampling_sd = 0.15,
    seed = 2026212,
    cell_id = "meta_v_001",
    replicate = 1L
  )
  V_vec <- attr(dat_vec, "V")
  fit_vec <- drmTMB(
    bf(yi ~ x + meta_V(V = V_vec), sigma ~ 1),
    family = gaussian(),
    data = dat_vec
  )
  targets_vec <- profile_targets(fit_vec)
  summary_vec <- phase18_summarise_meta_v_fit(
    fit_vec,
    attr(dat_vec, "truth"),
    cell_id = "meta_v_001",
    replicate = 1L
  )

  dat_dense <- phase18_dgp_meta_v(
    n_study = 48,
    known_v_type = "dense",
    beta_mu = c("(Intercept)" = 0.10, x = 0.35),
    sigma = 0.25,
    sampling_sd = 0.13,
    sampling_rho = 0.20,
    seed = 2026213,
    cell_id = "meta_v_002",
    replicate = 1L
  )
  V_dense <- attr(dat_dense, "V")
  fit_dense <- drmTMB(
    bf(yi ~ x + meta_V(V = V_dense), sigma ~ 1),
    family = gaussian(),
    data = dat_dense
  )
  targets_dense <- profile_targets(fit_dense)
  summary_dense <- phase18_summarise_meta_v_fit(
    fit_dense,
    attr(dat_dense, "truth"),
    cell_id = "meta_v_002",
    replicate = 1L
  )

  expect_equal(fit_vec$opt$convergence, 0)
  expect_equal(fit_dense$opt$convergence, 0)
  expect_true(fit_vec$sdr$pdHess)
  expect_true(fit_dense$sdr$pdHess)
  expect_true("sigma" %in% targets_vec$parm)
  expect_true("sigma" %in% targets_dense$parm)
  expect_false(any(grepl("V_known|meta", targets_vec$parm)))
  expect_false(any(grepl("V_known|meta", targets_dense$parm)))
  expect_equal(summary_vec$parameter, c("mu:(Intercept)", "mu:x", "sigma"))
  expect_equal(summary_dense$parameter, c("mu:(Intercept)", "mu:x", "sigma"))
  expect_true(all(summary_vec$converged))
  expect_true(all(summary_dense$converged))
  expect_lt(max(abs(summary_vec$error)), 0.35)
  expect_lt(max(abs(summary_dense$error)), 0.35)
})

test_that("Phase 18 meta_V DGP rejects malformed known-V inputs", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file(
      "sim/dgp/sim_dgp_meta_v.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/fit/sim_summarise_meta_v.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  expect_error(phase18_dgp_meta_v(0), "positive whole number")
  expect_error(phase18_dgp_meta_v(10, sigma = 0), "positive finite")
  expect_error(
    phase18_dgp_meta_v(10, known_v_type = "vector", sampling_rho = 0.2),
    "sampling_rho"
  )
  expect_error(
    phase18_summarise_meta_v_fit(list(), list(surface = "gaussian_ls")),
    "meta_V truth"
  )
})

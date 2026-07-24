source_phase18_meta_v_lss <- function(env = parent.frame()) {
  source(testthat::test_path("..", "..", "inst", "sim", "R", "sim_registry.R"), local = env)
  source(testthat::test_path("..", "..", "inst", "sim", "R", "sim_utils.R"), local = env)
  source(testthat::test_path("..", "..", "inst", "sim", "dgp", "sim_dgp_meta_v.R"), local = env)
  source(testthat::test_path("..", "..", "inst", "sim", "dgp", "sim_dgp_meta_v_lss.R"), local = env)
  source(testthat::test_path("..", "..", "inst", "sim", "fit", "sim_summarise_meta_v_lss.R"), local = env)
}

test_that("meta_V heterogeneity ladder has deterministic nested vector truth", {
  source_phase18_meta_v_lss()
  dat <- phase18_dgp_meta_v_lss(3, c(1L, 2L, 3L), layer = "LSSS", seed = 19)
  again <- phase18_dgp_meta_v_lss(3, c(1L, 2L, 3L), layer = "LSSS", seed = 19)
  expect_identical(dat, again)
  expect_equal(as.integer(table(dat$study)), c(2L, 4L, 6L))
  expect_true(is.factor(dat$study))
  expect_true(is.factor(dat$effect))
  expect_true(all(as.integer(table(dat$effect)) == 2L))
  expect_length(attr(dat, "V"), nrow(dat))
  expect_equal(attr(dat, "truth")$layer, "LSSS")
})

test_that("meta_V heterogeneity ladder accepts dense known V and records each layer", {
  source_phase18_meta_v_lss()
  dat <- phase18_dgp_meta_v_lss(3, 2, layer = "DH", known_v_type = "dense", sampling_rho = 0.3, seed = 8)
  expect_true(is.matrix(attr(dat, "V")))
  expect_equal(dim(attr(dat, "V")), rep(nrow(dat), 2L))
  targets <- phase18_meta_v_lss_targets(attr(dat, "truth"))
  expect_setequal(targets$parameter, c("mu:(Intercept)", "mu:x", "sigma:(Intercept)", "sigma:z", "sd:sigma_study", "known_V:sampling_sd"))
})

test_that("meta_V heterogeneity ladder rejects malformed nesting", {
  source_phase18_meta_v_lss()
  expect_error(phase18_dgp_meta_v_lss(3, c(1L, 2L)), "one per study")
  expect_error(phase18_dgp_meta_v_lss(3, c(1L, 0L, 2L)), "positive integer")
  expect_error(phase18_dgp_meta_v_lss(3, 2, sampling_rho = 0.2), "must be 0")
})

test_that("meta_V heterogeneity summariser retains formula-layer targets", {
  source_phase18_meta_v_lss()
  dat <- phase18_dgp_meta_v_lss(18, 1, layer = "LS", seed = 20260724)
  V <- attr(dat, "V")
  fit <- drmTMB(
    bf(yi ~ x + meta_V(V = V), sigma ~ z),
    family = gaussian(), data = dat
  )
  out <- phase18_summarise_meta_v_lss_fit(
    fit, dat, cell_id = "meta_v_ls", replicate = 1L
  )
  expect_setequal(
    out$parameter,
    c("mu:(Intercept)", "mu:x", "sigma:(Intercept)", "sigma:z", "known_V:sampling_sd")
  )
  expect_true(all(out$converged))
  expect_true(all(out$pdHess))
  expect_true(all(out$interval_status == "not_requested"))
  expect_true(is.na(out$estimate[out$parameter == "known_V:sampling_sd"]))
})

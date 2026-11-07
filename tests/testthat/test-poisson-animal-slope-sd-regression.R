poisson_animal_slope_sd_fixture <- function(seed = 20261022L, n_id = 96L, n_each = 16L) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(n_id))
  order <- c(seq.int(1L, n_id, by = 2L), seq.int(2L, n_id, by = 2L))
  A <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.35^abs(i - j))
  A <- A[order, order, drop = FALSE]
  dimnames(A) <- list(id_levels[order], id_levels[order])
  z_id <- stats::setNames(sample(rep(c(-1, 1), length.out = n_id)), id_levels)
  alpha <- c(`(Intercept)` = log(0.7), z = 0.35)
  slope <- as.vector(t(chol(A)) %*% stats::rnorm(n_id)) *
    exp(alpha[[1L]] + alpha[[2L]] * z_id[rownames(A)])
  names(slope) <- rownames(A)
  id <- factor(rep(id_levels, each = n_each), levels = id_levels)
  x <- rep(seq(-1, 1, length.out = n_each), times = n_id)
  z <- unname(z_id[as.character(id)])
  eta <- 0.25 + 0.2 * x + slope[as.character(id)] * x
  data <- data.frame(y = stats::rpois(length(eta), exp(eta)), id, x, z)
  list(data = data, A = A, alpha = alpha, z_id = z_id)
}

test_that("Poisson animal random-slope SDs can depend on group predictors", {
  skip_on_cran()
  fx <- poisson_animal_slope_sd_fixture()
  A <- fx$A
  fit <- drmTMB(
    bf(
      y ~ x + animal(0 + x | id, A = A),
      sd(id, level = "animal") ~ z
    ),
    family = stats::poisson(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, "sd_animal(id)"), c("(Intercept)", "z"))
  expect_lt(abs(coef(fit, "sd_animal(id)")[["z"]] - fx$alpha[["z"]]), 0.3)
  sd_prediction <- predict(fit, dpar = "sd_animal(id)")
  expect_named(sd_prediction, rownames(A))
  expect_equal(
    unname(sd_prediction),
    unname(exp(coef(fit, "sd_animal(id)")[["(Intercept)"]] +
      coef(fit, "sd_animal(id)")[["z"]] * fx$z_id[names(sd_prediction)])),
    tolerance = 1e-6
  )
  simulated <- simulate(fit, nsim = 1L, seed = 20261023L)
  expect_length(simulated[[1L]], nrow(fx$data))
  expect_true(all(is.finite(simulated[[1L]])))
  saved_fit <- tempfile(fileext = ".rds")
  on.exit(unlink(saved_fit), add = TRUE)
  saveRDS(fit, saved_fit)
  reloaded_fit <- readRDS(saved_fit)
  expect_equal(coef(reloaded_fit, "sd_animal(id)"), coef(fit, "sd_animal(id)"))
  expect_equal(
    predict(reloaded_fit, dpar = "sd_animal(id)"),
    sd_prediction,
    tolerance = 1e-6
  )

  constant_fit <- drmTMB(
    bf(
      y ~ x + animal(0 + x | id, A = A),
      sd(id, level = "animal") ~ 1
    ),
    family = stats::poisson(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  base_fit <- drmTMB(
    bf(y ~ x + animal(0 + x | id, A = A)),
    family = stats::poisson(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(constant_fit$opt$convergence, 0L)
  expect_equal(base_fit$opt$convergence, 0L)
  expect_equal(as.numeric(logLik(constant_fit)), as.numeric(logLik(base_fit)), tolerance = 2e-5)

  inconsistent <- fx$data
  inconsistent$z[1L] <- inconsistent$z[1L] + 1
  expect_error(
    drmTMB(
      bf(
        y ~ x + animal(0 + x | id, A = A),
        sd(id, level = "animal") ~ z
      ),
      family = stats::poisson(),
      data = inconsistent,
      control = drm_control(se = FALSE)
    ),
    "varies within id level"
  )
})

test_that("Binomial related-matrix random slopes support predictor-dependent SDs", {
  skip_on_cran()

  set.seed(20261028L)
  n_group <- 64L
  n_each <- 32L
  id_levels <- paste0("g", seq_len(n_group))
  K <- outer(seq_len(n_group), seq_len(n_group), function(i, j) 0.4^abs(i - j))
  dimnames(K) <- list(id_levels, id_levels)
  z_group <- sample(rep(c(-1, 1), length.out = n_group))
  alpha_sd <- c(`(Intercept)` = log(0.45), z = 0.5)
  slope_sd <- exp(alpha_sd[[1L]] + alpha_sd[[2L]] * z_group)
  unit_slope <- as.vector(t(chol(K)) %*% stats::rnorm(n_group))
  id_index <- rep(seq_len(n_group), each = n_each)
  id <- factor(id_levels[id_index], levels = id_levels)
  x <- rep(seq(-1.5, 1.5, length.out = n_each), times = n_group)
  eta <- -0.1 + 0.35 * x + x * (slope_sd * unit_slope)[id_index]
  y <- stats::rbinom(length(eta), 1L, stats::plogis(eta))
  dat <- data.frame(y, x, id, z = rep(z_group, each = n_each))

  fit <- drmTMB(
    bf(
      y ~ x + relmat(0 + x | id, K = K),
      sd(id, level = "relmat") ~ z
    ),
    family = stats::binomial(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  sd_coef <- coef(fit, "sd_relmat(id)")
  sd_prediction <- predict(fit, dpar = "sd_relmat(id)")
  expect_s3_class(fit, "drmTMB")
  expect_true(is_converged(fit))
  expect_named(sd_coef, names(alpha_sd))
  expect_lt(abs(sd_coef[["z"]] - alpha_sd[["z"]]), 0.4)
  expect_equal(unname(sd_prediction), exp(as.vector(
    stats::model.matrix(~z, data.frame(z = z_group)) %*% sd_coef
  )), tolerance = 1e-8)

  simulated <- simulate(fit, nsim = 2L, seed = 202610281L)
  expect_length(simulated, 2L)
  expect_true(all(vapply(simulated, length, integer(1L)) == nrow(dat)))
  expect_true(all(unlist(simulated, use.names = FALSE) %in% 0:1))

  save_file <- tempfile(fileext = ".rds")
  on.exit(unlink(save_file), add = TRUE)
  saveRDS(fit, save_file)
  restored <- readRDS(save_file)
  expect_equal(coef(restored, "sd_relmat(id)"), sd_coef)
  expect_equal(predict(restored, dpar = "sd_relmat(id)"), sd_prediction)
  expect_identical(
    simulate(restored, nsim = 2L, seed = 202610281L),
    simulated
  )
})

test_that("Binomial probit and cloglog related-matrix slopes support SD regression", {
  skip_on_cran()

  for (link in c("probit", "cloglog")) {
    set.seed(if (link == "probit") 20261050L else 20261051L)
    n_group <- 64L
    n_each <- 32L
    id_levels <- paste0("g", seq_len(n_group))
    K <- outer(seq_len(n_group), seq_len(n_group), function(i, j) 0.4^abs(i - j))
    dimnames(K) <- list(id_levels, id_levels)
    z_group <- sample(rep(c(-1, 1), length.out = n_group))
    alpha_sd <- c(`(Intercept)` = -0.75, z = 0.5)
    slope_sd <- exp(alpha_sd[[1L]] + alpha_sd[[2L]] * z_group)
    unit_slope <- as.vector(t(chol(K)) %*% stats::rnorm(n_group))
    id_index <- rep(seq_len(n_group), each = n_each)
    id <- factor(id_levels[id_index], levels = id_levels)
    x <- rep(seq(-1.5, 1.5, length.out = n_each), times = n_group)
    eta <- -0.1 + 0.35 * x + x * (slope_sd * unit_slope)[id_index]
    probability <- if (link == "probit") {
      stats::pnorm(eta)
    } else {
      -expm1(-exp(eta))
    }
    y <- stats::rbinom(length(eta), 1L, probability)
    dat <- data.frame(y, x, id, z = rep(z_group, each = n_each))

    fit <- drmTMB(
      bf(
        y ~ x + relmat(0 + x | id, K = K),
        sd(id, level = "relmat") ~ z
      ),
      family = stats::binomial(link = link),
      data = dat,
      control = drm_control(se = FALSE)
    )

    sd_coef <- coef(fit, "sd_relmat(id)")
    expect_true(is_converged(fit))
    expect_gt(sd_coef[["z"]], 0)
    expect_lt(abs(sd_coef[["z"]] - alpha_sd[["z"]]), 0.4)
    simulated <- simulate(fit, nsim = 2L, seed = 202610510L)
    expect_length(simulated, 2L)
    expect_true(all(vapply(simulated, length, integer(1L)) == nrow(dat)))
    expect_true(all(unlist(simulated, use.names = FALSE) %in% 0:1))
  }
})

check_drm_test_tree <- function() {
  structure(
    list(
      edge = matrix(
        c(
          5,
          6,
          5,
          7,
          6,
          1,
          6,
          2,
          7,
          3,
          7,
          4
        ),
        ncol = 2,
        byrow = TRUE
      ),
      edge.length = rep(1, 6),
      tip.label = paste0("sp_", 1:4),
      Nnode = 3L
    ),
    class = "phylo"
  )
}

check_drm_mu_sigma_cov_data <- function(
  n_id = 28,
  n_each = 6,
  sd_mu_id = 0.55,
  sd_sigma_id = 0.28,
  rho_mu_sigma = 0.4,
  seed = 2026051201
) {
  set.seed(seed)
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  u_mu <- stats::rnorm(n_id)
  u_sigma <- rho_mu_sigma * u_mu + sqrt(1 - rho_mu_sigma^2) * stats::rnorm(n_id)
  mu <- 0.2 + 0.45 * x + sd_mu_id * u_mu[id]
  sigma <- exp(log(0.55) + 0.18 * z + sd_sigma_id * u_sigma[id])

  data.frame(
    y = stats::rnorm(n, mean = mu, sd = sigma),
    x = x,
    z = z,
    id = id
  )
}

test_that("check_drm() reports core diagnostics for Gaussian fits", {
  set.seed(20260508)
  dat <- data.frame(
    y = stats::rnorm(80),
    x = stats::rnorm(80)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = dat
  )

  chk <- check_drm(fit)

  expect_s3_class(chk, "drm_check")
  expect_named(chk, c("check", "status", "value", "message"))
  expect_true(attr(chk, "ok"))
  expect_true(all(chk$status == "ok"))
  expect_true(all(
    c(
      "optimizer_convergence",
      "optimizer_budget",
      "finite_objective",
      "fixed_gradient",
      "hessian_positive_definite",
      "standard_errors_finite",
      "dropped_rows",
      "positive_scale"
    ) %in%
      chk$check
  ))
  printed <- NULL
  messages <- capture.output(
    printed <- capture.output(print(chk)),
    type = "message"
  )
  expect_match(paste(c(messages, printed), collapse = "\n"), "<drm_check")
})

test_that("check_drm() records dropped rows as notes", {
  dat <- data.frame(
    y = c(0.1, 0.3, NA, 0.5, 0.7, 0.9),
    x = c(-1, -0.5, 0, 0.5, NA, 1)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat
  )

  chk <- check_drm(fit)
  dropped <- chk[chk$check == "dropped_rows", ]

  expect_true(attr(chk, "ok"))
  expect_equal(dropped$status, "note")
  expect_match(dropped$value, "dropped=2")
})

test_that("check_drm() warns when residual rho12 is near a requested boundary", {
  set.seed(20260509)
  n <- 220
  dat <- data.frame(
    x = stats::rnorm(n),
    y1 = stats::rnorm(n)
  )
  dat$y2 <- 0.7 * dat$y1 + sqrt(1 - 0.7^2) * stats::rnorm(n)

  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~1),
    family = c(gaussian(), gaussian()),
    data = dat
  )
  chk <- check_drm(fit, rho_boundary = 0.2)
  rho_row <- chk[chk$check == "rho12_boundary", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(rho_row$status, "warning")
  expect_false(attr(chk, "ok"))
})

test_that("check_drm() reports Student-t nu diagnostics", {
  n <- 160
  x <- seq(-1, 1, length.out = n)
  z <- rep(c(-0.5, 0.5), length.out = n)
  nu_true <- 8
  dat <- data.frame(x = x, z = z)
  dat$y <- 0.2 +
    0.5 * x +
    exp(-0.4 + 0.2 * z) * stats::qt((seq_len(n) - 0.5) / n, df = nu_true)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ 1),
    family = student(),
    data = dat
  )
  stable <- fit
  stable$coefficients$nu[[1L]] <- log(6)

  chk <- check_drm(stable)
  nu <- chk[chk$check == "student_nu", ]

  expect_equal(nu$status, "ok")
  expect_match(nu$value, "range=")
  expect_true(attr(chk, "ok"))

  near_boundary <- fit
  near_boundary$coefficients$nu[[1L]] <- log(0.01)
  chk_boundary <- check_drm(near_boundary)
  nu_boundary <- chk_boundary[chk_boundary$check == "student_nu", ]
  expect_equal(nu_boundary$status, "warning")
  expect_match(nu_boundary$message, "finite-variance boundary")
  expect_false(attr(chk_boundary, "ok"))

  nearly_gaussian <- fit
  nearly_gaussian$coefficients$nu[[1L]] <- log(200)
  chk_gaussian <- check_drm(nearly_gaussian)
  nu_gaussian <- chk_gaussian[chk_gaussian$check == "student_nu", ]
  expect_equal(nu_gaussian$status, "note")
  expect_match(nu_gaussian$message, "Gaussian")
  expect_true(attr(chk_gaussian, "ok"))

  invalid <- fit
  invalid$coefficients$nu[[1L]] <- Inf
  chk_invalid <- check_drm(invalid)
  nu_invalid <- chk_invalid[chk_invalid$check == "student_nu", ]
  expect_equal(nu_invalid$status, "error")
  expect_match(nu_invalid$message, "non-finite")
  expect_false(attr(chk_invalid, "ok"))
})

test_that("check_drm() reports predictor-varying Student-t nu ranges", {
  n <- 180
  x <- seq(-1, 1, length.out = n)
  dat <- data.frame(x = x)
  dat$y <- 0.3 + 0.4 * x + stats::qt((seq_len(n) - 0.5) / n, df = 10)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ x),
    family = student(),
    data = dat
  )
  fit$coefficients$nu[] <- c(log(6), 0.5)

  chk <- check_drm(fit)
  nu <- chk[chk$check == "student_nu", ]

  expect_equal(nu$status, "ok")
  expect_match(nu$value, "range=\\[[0-9.]+,[0-9.]+\\]")
  expect_true(attr(chk, "ok"))
})

test_that("check_drm() reports random-effect replication notes", {
  set.seed(20260510)
  dat <- data.frame(
    id = factor(c("a", "a", "b", "b", "c", "d", "d", "e", "e", "e")),
    x = stats::rnorm(10)
  )
  dat$y <- 0.2 +
    0.4 * dat$x +
    c(a = -0.2, b = 0.1, c = 0.3, d = -0.1, e = 0.2)[dat$id] +
    stats::rnorm(10, sd = 0.15)

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1),
    family = gaussian(),
    data = dat
  )
  chk <- check_drm(fit)
  replication <- chk[chk$check == "mu_random_effect_replication", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(replication$status, "note")
  expect_match(replication$message, "one fitted observation")

  near_boundary <- fit
  near_boundary$sdpars$mu[] <- 1e-8
  chk_boundary <- check_drm(near_boundary)
  sd_boundary <- chk_boundary[
    chk_boundary$check == "random_effect_sd_boundary",
  ]
  expect_equal(sd_boundary$status, "warning")
  expect_match(sd_boundary$value, "boundary=")
  expect_match(sd_boundary$message, "lower boundary")
  expect_false(attr(chk_boundary, "ok"))

  bad_sd <- fit
  bad_sd$sdpars$mu[] <- 0
  chk_bad_sd <- check_drm(bad_sd)
  bad_sd_boundary <- chk_bad_sd[
    chk_bad_sd$check == "random_effect_sd_boundary",
  ]
  expect_equal(bad_sd_boundary$status, "error")
  expect_match(bad_sd_boundary$message, "non-positive")
  expect_false(attr(chk_bad_sd, "ok"))
})

test_that("check_drm() reports weak random-slope design notes", {
  set.seed(20260511)
  id <- factor(rep(letters[1:8], each = 3))
  x <- rep(seq(-1, 1, length.out = 8), each = 3)
  dat <- data.frame(id = id, x = x)
  dat$y <- 0.3 +
    0.5 * dat$x +
    rep(stats::rnorm(8, sd = 0.2), each = 3) +
    stats::rnorm(nrow(dat), sd = 0.2)

  fit <- drmTMB(
    bf(y ~ x + (1 + x | id), sigma ~ 1),
    family = gaussian(),
    data = dat
  )
  chk <- check_drm(fit)
  design <- chk[chk$check == "mu_random_effect_design", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(design$status, "note")
  expect_match(design$message, "weak within-group design variation")
  expect_true(attr(chk, "ok"))
})

test_that("check_drm() records known sampling covariance summaries", {
  set.seed(20260512)
  n <- 24
  dat <- data.frame(x = stats::rnorm(n))
  V <- 0.015 * outer(seq_len(n), seq_len(n), function(i, j) 0.35^abs(i - j))
  dat$yi <- stats::rnorm(n)

  fit <- drmTMB(
    bf(yi ~ x + meta_known_V(V = V)),
    family = gaussian(),
    data = dat
  )
  chk <- check_drm(fit)
  known_v <- chk[chk$check == "known_sampling_covariance", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(known_v$status, "ok")
  expect_match(known_v$value, "type=matrix")
  expect_match(known_v$value, "rank=24")
})

test_that("check_drm() notes wide dense fixed-effect designs", {
  set.seed(20260510)
  n <- 90
  dat <- data.frame(
    y = stats::rnorm(n),
    habitat = factor(rep(paste0("hab_", seq_len(45)), each = 2))
  )

  fit <- drmTMB(
    bf(y ~ habitat, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 120, iter.max = 120)
  )
  chk <- check_drm(fit)
  design <- chk[chk$check == "fixed_effect_design_size", ]

  expect_equal(design$status, "note")
  expect_match(design$value, "max_cols=45")
  expect_match(design$message, "high-cardinality factors")
  expect_true(attr(chk, "ok"))
})

test_that("check_drm() records phylogenetic replication notes", {
  set.seed(20260513)
  tree <- check_drm_test_tree()
  dat <- data.frame(
    species = factor(c("sp_1", "sp_2", "sp_2", "sp_3", "sp_3", "sp_4", "sp_4")),
    x = c(-1, -0.5, 0.5, -0.2, 0.3, -0.1, 0.7)
  )
  dat$y <- 0.2 +
    0.4 * dat$x +
    c(sp_1 = -0.1, sp_2 = 0.2, sp_3 = 0.05, sp_4 = -0.2)[dat$species] +
    stats::rnorm(nrow(dat), sd = 0.15)

  fit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
    family = gaussian(),
    data = dat
  )
  chk <- check_drm(fit)
  phylo <- chk[chk$check == "phylo_mu_replication", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(phylo$status, "note")
  expect_match(phylo$value, "min_species_n=1")
  expect_true(attr(chk, "ok"))
})

test_that("check_drm() reports univariate mu/sigma covariance diagnostics", {
  dat <- check_drm_mu_sigma_cov_data()
  fit <- drmTMB(
    bf(y ~ x + (1 | p | id), sigma ~ z + (1 | p | id)),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 250, iter.max = 250)
  )
  chk <- check_drm(fit)
  group_cov <- chk[chk$check == "mu_sigma_random_effect_covariance", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(group_cov$status, "ok")
  expect_match(group_cov$value, "term=\\(1 \\| p \\| id\\)")
  expect_match(group_cov$value, "n_groups=28")
  expect_match(group_cov$value, "min_group_n=6")
  expect_match(group_cov$message, "non-negligible")

  singleton <- fit
  singleton_rows <- which(singleton$model$random$sigma$index[, 1L] == 1L)[-1L]
  singleton$model$random$sigma$index[singleton_rows, 1L] <- 2L
  singleton_chk <- check_drm(singleton)
  singleton_cov <- singleton_chk[
    singleton_chk$check == "mu_sigma_random_effect_covariance",
  ]

  expect_equal(singleton_cov$status, "note")
  expect_match(singleton_cov$value, "singleton_groups=1")
  expect_match(singleton_cov$message, "fewer than two")
  expect_true(attr(singleton_chk, "ok"))

  weak_sd <- fit
  weak_sd$sdpars$sigma[[1L]] <- 0.001
  weak_chk <- check_drm(weak_sd)
  weak_cov <- weak_chk[weak_chk$check == "mu_sigma_random_effect_covariance", ]

  expect_equal(weak_cov$status, "note")
  expect_match(weak_cov$message, "tiny")
  expect_true(attr(weak_chk, "ok"))
})

test_that("check_drm() reports bivariate mu random-effect covariance diagnostics", {
  set.seed(2026051102)
  n_id <- 20
  n_each <- 5
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  sigma1 <- 0.25
  sigma2 <- 0.3
  sd_mu1 <- 0.7
  sd_mu2 <- 0.8
  rho_group <- 0.35
  rho12 <- 0.15

  u1 <- stats::rnorm(n_id)
  u2 <- rho_group * u1 + sqrt(1 - rho_group^2) * stats::rnorm(n_id)
  e1 <- stats::rnorm(n)
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  dat <- data.frame(id = id, x = x)
  dat$y1 <- 0.2 + 0.45 * x + sd_mu1 * u1[id] + sigma1 * e1
  dat$y2 <- -0.1 - 0.3 * x + sd_mu2 * u2[id] + sigma2 * e2

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + (1 | p | id),
      mu2 = y2 ~ x + (1 | p | id),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = list(eval.max = 250, iter.max = 250)
  )
  chk <- check_drm(fit)
  group_cov <- chk[chk$check == "biv_mu_random_effect_covariance", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(group_cov$status, "ok")
  expect_match(group_cov$value, "n_groups=20")
  expect_match(group_cov$value, "min_group_n=5")
  expect_match(group_cov$message, "non-negligible")

  singleton <- fit
  n_group <- singleton$model$random$mu$n_re / singleton$model$random$mu$n_terms
  singleton_rows <- which(singleton$model$random$mu$index[, 1L] == 1L)[-1L]
  singleton$model$random$mu$index[singleton_rows, 1L] <- 2L
  singleton$model$random$mu$index[singleton_rows, 2L] <- n_group + 2L
  singleton_chk <- check_drm(singleton)
  singleton_cov <- singleton_chk[
    singleton_chk$check == "biv_mu_random_effect_covariance",
  ]

  expect_equal(singleton_cov$status, "note")
  expect_match(singleton_cov$value, "singleton_groups=1")
  expect_match(singleton_cov$message, "fewer than two")
  expect_true(attr(singleton_chk, "ok"))

  weak_sd <- fit
  weak_sd$sdpars$mu[[1L]] <- mean(stats::sigma(fit)$sigma1) * 0.001
  weak_chk <- check_drm(weak_sd)
  weak_cov <- weak_chk[weak_chk$check == "biv_mu_random_effect_covariance", ]

  expect_equal(weak_cov$status, "note")
  expect_match(weak_cov$message, "tiny relative")
  expect_true(attr(weak_chk, "ok"))
})

test_that("check_drm() reports mutated diagnostic failure branches", {
  dat <- data.frame(y = stats::rnorm(24), x = stats::rnorm(24))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  nonconverged <- fit
  nonconverged$opt$convergence <- 1L
  nonconverged$opt$message <- "test convergence failure"
  nonconverged$opt$iterations <- 10L
  nonconverged$opt$evaluations["function"] <- 10L
  nonconverged$control$optimizer <- list(iter.max = 10, eval.max = 10)
  convergence <- check_drm(nonconverged)
  convergence <- convergence[convergence$check == "optimizer_convergence", ]
  expect_equal(convergence$status, "warning")
  expect_match(convergence$message, "test convergence failure")

  budget <- check_drm(nonconverged)
  budget <- budget[budget$check == "optimizer_budget", ]
  expect_equal(budget$status, "warning")
  expect_match(budget$value, "iterations=10; function=10")
  expect_match(budget$message, "evaluation or iteration limit")

  converged_budget <- nonconverged
  converged_budget$opt$convergence <- 0L
  budget_note <- check_drm(converged_budget)
  budget_note <- budget_note[budget_note$check == "optimizer_budget", ]
  expect_equal(budget_note$status, "note")

  nonfinite <- fit
  nonfinite$opt$objective <- Inf
  objective <- check_drm(nonfinite)
  objective <- objective[objective$check == "finite_objective", ]
  expect_equal(objective$status, "error")

  gradient_error <- fit
  gradient_error$obj$gr <- function(par) {
    stop("test gradient failure")
  }
  gradient <- check_drm(gradient_error)
  gradient <- gradient[gradient$check == "fixed_gradient", ]
  expect_equal(gradient$status, "warning")
  expect_match(gradient$message, "test gradient failure")

  bad_gradient <- fit
  bad_gradient$obj$gr <- function(par) {
    c(NA_real_, 0)
  }
  gradient <- check_drm(bad_gradient)
  gradient <- gradient[gradient$check == "fixed_gradient", ]
  expect_equal(gradient$status, "error")

  bad_hessian <- fit
  bad_hessian$sdr$pdHess <- FALSE
  hessian <- check_drm(bad_hessian)
  hessian <- hessian[hessian$check == "hessian_positive_definite", ]
  expect_equal(hessian$status, "warning")

  bad_se <- fit
  bad_se$sdr$cov.fixed[1, 1] <- Inf
  standard_errors <- check_drm(bad_se)
  standard_errors <- standard_errors[
    standard_errors$check == "standard_errors_finite",
  ]
  expect_equal(standard_errors$status, "warning")
  expect_match(standard_errors$message, "non-finite")

  bad_scale <- fit
  bad_scale$model$model_type <- "broken"
  scale <- check_drm(bad_scale)
  scale <- scale[scale$check == "positive_scale", ]
  expect_equal(scale$status, "warning")
})

test_that("check_drm() validates scalar diagnostic thresholds", {
  dat <- data.frame(y = stats::rnorm(20))
  fit <- drmTMB(bf(y ~ 1), family = gaussian(), data = dat)

  expect_error(check_drm(fit, gradient_tolerance = 0), "gradient_tolerance")
  expect_error(check_drm(fit, rho_boundary = 1), "rho_boundary")
  expect_error(check_drm(fit, sd_boundary = 0), "sd_boundary")
  expect_error(check_drm(fit, unknown_option = TRUE), "reserved")
})

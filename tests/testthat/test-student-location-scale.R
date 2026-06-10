student_test_data <- function(n = 600) {
  set.seed(20260509)
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  beta_mu <- c(0.25, 0.6)
  beta_sigma <- c(-0.3, 0.25)
  beta_nu <- log(6)
  mu <- beta_mu[[1L]] + beta_mu[[2L]] * dat$x
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  nu <- 2 + exp(beta_nu)
  q <- stats::qt((seq_len(n) - 0.5) / n, df = nu)
  dat$y <- mu + sigma * sample(q)
  list(
    data = dat,
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    beta_nu = beta_nu,
    nu = nu
  )
}

student_random_intercept_data <- function(
  n_id = 40,
  n_each = 10,
  seed = 20260629
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  dat <- data.frame(
    id = id,
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  beta_mu <- c(0.20, 0.48)
  beta_sigma <- c(-0.42, 0.18)
  beta_nu <- log(7)
  sd_id <- 0.52
  u_id <- stats::rnorm(n_id, sd = sd_id)
  u_id <- u_id - mean(u_id)
  names(u_id) <- levels(id)
  eta_mu <- beta_mu[[1L]] + beta_mu[[2L]] * dat$x + u_id[id]
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  nu <- 2 + exp(beta_nu)
  q <- stats::qt((seq_len(n) - 0.5) / n, df = nu)
  dat$y <- eta_mu + sigma * sample(q)
  list(
    data = dat,
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    beta_nu = beta_nu,
    nu = nu,
    sd_id = sd_id,
    u_id = u_id
  )
}

student_nll <- function(y, mu, sigma, nu) {
  -sum(stats::dt((y - mu) / sigma, df = nu, log = TRUE) - log(sigma))
}

test_that("drmTMB fits fixed-effect Student-t location-scale-shape models", {
  sim <- student_test_data()
  dat <- sim$data

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ 1),
    family = student(),
    data = dat
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_lt(max(abs(unname(coef(fit, "mu")) - sim$beta_mu)), 0.08)
  expect_lt(max(abs(unname(coef(fit, "sigma")) - sim$beta_sigma)), 0.08)
  expect_lt(max(abs(unname(coef(fit, "nu")) - sim$beta_nu)), 0.3)
  expect_true(all(predict(fit, dpar = "nu") > 2))
  expect_equal(
    predict(fit, dpar = "nu"),
    2 + exp(predict(fit, dpar = "nu", type = "link")),
    tolerance = 1e-12
  )
  expect_length(predict(fit, dpar = "mu"), nrow(dat))
  expect_length(stats::sigma(fit), nrow(dat))
  expect_s3_class(stats::logLik(fit), "logLik")
  expect_equal(stats::nobs(fit), nrow(dat))
})

test_that("Student-t mu supports ordinary random intercepts", {
  sim <- student_random_intercept_data()

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z, nu ~ 1),
    family = student(),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "student")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$random$mu$n_terms, 1L)
  expect_equal(fit$model$random$mu$labels, "(1 | id)")
  expect_named(fit$sdpars$mu, "(1 | id)")
  expect_gt(unname(fit$sdpars$mu[["(1 | id)"]]), 0.05)
  expect_lt(abs(unname(fit$sdpars$mu[["(1 | id)"]]) - sim$sd_id), 0.30)
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.20)
  expect_lt(max(abs(coef(fit, "sigma") - sim$beta_sigma)), 0.25)
  expect_lt(abs(unname(coef(fit, "nu")) - sim$beta_nu), 0.60)

  id_effects <- fit$random_effects$mu$terms[["(1 | id)"]]
  expect_equal(length(id_effects), length(sim$u_id))
  expect_gt(stats::cor(id_effects, sim$u_id), 0.45)
  expect_true(drmTMB:::has_ordinary_mu_random_effects(fit))
  expect_equal(drmTMB:::n_mu_random_effect_terms(fit), 1L)
  expect_equal(
    predict(fit, dpar = "mu"),
    as.vector(fit$model$X$mu %*% coef(fit, "mu")) +
      drmTMB:::mu_random_effect_contribution(fit),
    tolerance = 1e-8
  )

  targets <- profile_targets(fit)
  sd_target <- targets[targets$parm == "sd:mu:(1 | id)", , drop = FALSE]
  expect_equal(nrow(sd_target), 1L)
  expect_equal(sd_target$tmb_parameter, "log_sd_mu")
  expect_true(sd_target$profile_ready)

  chk <- check_drm(fit)
  replication <- chk[chk$check == "mu_random_effect_replication", ]
  expect_equal(replication$status, "ok")
  nu <- chk[chk$check == "student_nu", ]
  expect_equal(nu$status, "ok")
})

test_that("Student-t objective matches an independent R likelihood", {
  sim <- student_test_data(90)
  dat <- sim$data
  dat$w <- rep(seq(-0.5, 0.5, length.out = 9), length.out = nrow(dat))

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ w),
    family = student(),
    data = dat
  )
  mu <- as.vector(stats::model.matrix(~x, dat) %*% coef(fit, "mu"))
  sigma <- exp(as.vector(stats::model.matrix(~z, dat) %*% coef(fit, "sigma")))
  nu <- 2 + exp(as.vector(stats::model.matrix(~w, dat) %*% coef(fit, "nu")))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    fit$opt$objective,
    student_nll(dat$y, mu, sigma, nu),
    tolerance = 1e-8
  )
})

test_that("Student-t methods simulate and compute residuals", {
  sim <- student_test_data(120)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ 1),
    family = student(),
    data = sim$data
  )

  sims <- simulate(fit, nsim = 2, seed = 1)
  expect_s3_class(sims, "data.frame")
  expect_equal(dim(sims), c(nrow(sim$data), 2))
  expect_length(residuals(fit), nrow(sim$data))
  expect_length(residuals(fit, type = "pearson"), nrow(sim$data))
  expect_true(all(is.finite(residuals(fit, type = "pearson"))))
})

test_that("Student-t models reject unsupported early-phase terms clearly", {
  dat <- data.frame(
    y = stats::rnorm(12),
    x = stats::rnorm(12),
    id = rep(1:3, each = 4),
    V = rep(0.01, 12)
  )

  expect_error(
    drmTMB(
      bf(y ~ x + (1 + x | id), sigma ~ 1),
      family = student(),
      data = dat
    ),
    "Only independent"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | p | id), sigma ~ 1),
      family = student(),
      data = dat
    ),
    "random intercepts"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1 + (1 | id)),
      family = student(),
      data = dat
    ),
    "sigma.*random effects"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + meta_V(V = V), sigma ~ 1),
      family = student(),
      data = dat
    ),
    "not implemented"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1, sd(id) ~ 1), family = student(), data = dat),
    "Random-effect scale formulae"
  )
})

test_that("Student-t shape random effects have a specific boundary", {
  dat <- data.frame(
    y = stats::rnorm(20),
    x = stats::rnorm(20),
    id = rep(1:5, each = 4)
  )

  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, nu ~ x + (1 | id)),
      family = student(),
      data = dat
    ),
    "Shape random effects are not implemented"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, nu ~ x + (0 + x | id)),
      family = student(),
      data = dat
    ),
    "skew-normal fixed-effect"
  )
})

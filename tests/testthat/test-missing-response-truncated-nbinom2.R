mr_t5_truncated_data <- function(n = 640L, seed = 2026071501L) {
  set.seed(seed)
  dat <- data.frame(x = rnorm(n), z = rnorm(n))
  truth <- list(mu = c(0.45, -0.35), sigma = c(-0.70, 0.22))
  mu <- exp(truth$mu[[1L]] + truth$mu[[2L]] * dat$x)
  sigma <- exp(truth$sigma[[1L]] + truth$sigma[[2L]] * dat$z)
  p0 <- dnbinom(0, size = 1 / sigma^2, mu = mu)
  dat$count <- qnbinom(
    p0 + pmax(runif(n), .Machine$double.eps) * (1 - p0),
    size = 1 / sigma^2,
    mu = mu
  )
  list(data = dat, truth = truth)
}

mr_t5_truncated_ri_data <- function(
  n_id = 34L,
  n_each = 8L,
  sd_id = 0.35,
  seed = 20260624L
) {
  set.seed(seed)
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  dat <- data.frame(
    id = id,
    x = rep(seq(-1, 1, length.out = n_each), n_id) + rnorm(n, sd = 0.05),
    z = rnorm(n)
  )
  truth <- list(
    mu = c(0.35, -0.28),
    sigma = c(-0.65, 0.15),
    sd_id = sd_id
  )
  b_id <- rnorm(n_id, sd = sd_id)
  names(b_id) <- levels(id)
  eta_mu <- truth$mu[[1L]] + truth$mu[[2L]] * dat$x + b_id[dat$id]
  mu <- exp(eta_mu)
  sigma <- exp(truth$sigma[[1L]] + truth$sigma[[2L]] * dat$z)
  p0 <- dnbinom(0, size = 1 / sigma^2, mu = mu)
  dat$count <- qnbinom(
    p0 + pmax(runif(n), .Machine$double.eps) * (1 - p0),
    size = 1 / sigma^2,
    mu = mu
  )
  list(data = dat, truth = truth, u_id = b_id)
}

mr_t5_fit <- function(data, random = FALSE, missing = miss_control(), se = FALSE) {
  formula <- if (random) {
    bf(count ~ x + (1 | id), sigma ~ z)
  } else {
    bf(count ~ x, sigma ~ z)
  }
  drmTMB(
    formula,
    family = truncated_nbinom2(),
    data = data,
    missing = missing,
    control = drm_control(se = se)
  )
}

test_that("MR-T5 mask equals the observed-row truncated NB2 fit", {
  sim <- mr_t5_truncated_data()
  dat <- missing_response_mask_mcar(sim$data, "count", seed = 2026071502L)
  observed <- !is.na(dat$count)
  fit_mask <- mr_t5_fit(dat, missing = miss_control(response = "include"))
  fit_cc <- mr_t5_fit(dat[observed, , drop = FALSE])

  expect_equal(mean(!observed), 0.25)
  expect_equal(coef(fit_mask, "mu"), coef(fit_cc, "mu"), tolerance = 1e-6)
  expect_equal(
    coef(fit_mask, "sigma"), coef(fit_cc, "sigma"), tolerance = 1e-6
  )
  expect_equal(logLik(fit_mask), logLik(fit_cc), tolerance = 1e-6)
  expect_equal(fit_mask$missing_data$observed_y, observed)
  expect_equal(fit_mask$missing_data$response_sentinel, 1)
  expect_equal(fit_mask$missing_data$original_row, seq_len(nrow(dat)))
  expect_equal(fit_mask$missing_data$model_row, seq_len(nrow(dat)))
  expect_equal(nobs(fit_mask), sum(observed))
  expect_length(fitted(fit_mask), nrow(dat))
  expect_length(predict(fit_mask, dpar = "mu"), nrow(dat))
  expect_length(predict(fit_mask, dpar = "sigma"), nrow(dat))
  expect_true(all(is.na(residuals(fit_mask)[!observed])))
  expect_true(all(is.na(residuals(fit_mask, type = "pearson")[!observed])))
  expect_equal(
    fitted(fit_mask)[observed], fitted(fit_cc), tolerance = 1e-6,
    ignore_attr = TRUE
  )

  expect_missing_response_sentinel_invariant(fit_mask, sentinels = c(1, 7))

  sims <- simulate(fit_mask, nsim = 3, seed = 2026071503L)
  expect_equal(dim(sims), c(nrow(dat), 3L))
  expect_true(all(is.finite(as.matrix(sims))))
  expect_true(all(as.matrix(sims) >= 1))
  expect_true(all(as.matrix(sims) == round(as.matrix(sims))))
})

test_that("MR-T5 retains response-missing rows and drops predictor-missing rows", {
  dat <- mr_t5_truncated_data(n = 80L, seed = 2026071504L)$data
  dat$count[[1L]] <- NA_real_
  dat$x[[2L]] <- NA_real_
  fit <- mr_t5_fit(dat, missing = miss_control(response = "include"))

  expect_equal(fit$missing_data$original_row, setdiff(seq_len(80L), 2L))
  expect_true(1L %in% fit$missing_data$original_row)
  expect_equal(fit$missing_data$counts$missing_response, 1L)
  expect_equal(nobs(fit), 78L)
  expect_length(fitted(fit), 79L)
  expect_true(is.na(residuals(fit)[[1L]]))
})

test_that("MR-T5 validates only observed positive integer responses", {
  include <- miss_control(response = "include")
  dat <- mr_t5_truncated_data(n = 80L, seed = 2026071505L)$data

  expect_error(
    mr_t5_fit(transform(dat, count = NA_real_), missing = include),
    "At least one observed truncated NB2"
  )
  for (bad in c(0, -1, 1.5, Inf)) {
    malformed <- dat
    malformed$count[[1L]] <- NA_real_
    malformed$count[[2L]] <- bad
    expect_error(
      mr_t5_fit(malformed, missing = include),
      "positive integer",
      info = paste("bad response", bad)
    )
  }
})

test_that("MR-T5 recovers every fitted parameter with 25 percent MCAR", {
  sim <- mr_t5_truncated_ri_data()
  dat <- missing_response_mask_mcar_within_group(
    sim$data, "count", "id", seed = 2026071506L
  )
  fit <- mr_t5_fit(
    dat,
    random = TRUE,
    missing = miss_control(response = "include"),
    se = TRUE
  )

  expect_equal(mean(is.na(dat$count)), 0.25)
  expect_equal(fit$opt$convergence, 0L)
  expect_lt(max(abs(unname(coef(fit, "mu")) - sim$truth$mu)), 0.25)
  expect_lt(max(abs(unname(coef(fit, "sigma")) - sim$truth$sigma)), 0.35)
  expect_lt(abs(unname(fit$sdpars$mu[["(1 | id)"]]) - sim$truth$sd_id), 0.25)
  id_effects <- fit$random_effects$mu$terms[["(1 | id)"]]
  expect_gt(cor(id_effects, sim$u_id), 0.35)
})

test_that("MR-T5 retains neighbouring REML and mi gates", {
  include <- miss_control(response = "include")
  dat <- mr_t5_truncated_data(n = 80L, seed = 2026071507L)$data
  dat$count[[1L]] <- NA_real_

  expect_error(
    drmTMB(
      bf(count ~ x, sigma ~ z), truncated_nbinom2(), dat,
      missing = include, REML = TRUE
    ),
    "only for.*Gaussian"
  )

  dat$q <- rbinom(nrow(dat), 1, 0.5)
  dat$q[[2L]] <- NA_integer_
  expect_error(
    drmTMB(
      bf(count ~ x + mi(q), sigma ~ z), truncated_nbinom2(), dat,
      impute = list(q = impute_model(q ~ x, family = binomial())),
      missing = miss_control(response = "include", predictor = "model")
    ),
    "predictor.*model"
  )
})

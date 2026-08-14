mr_t4_beta_binomial_data <- function(
  n_id = 52L, n_each = 10L, seed = 20260631L
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  dat <- data.frame(
    id = id, x = rnorm(n), z = rnorm(n),
    trials = sample(18:34, n, replace = TRUE)
  )
  truth <- list(mu = c(-0.25, 0.65), sigma = c(-1.35, 0.15), sd = 0.60)
  u <- rnorm(n_id, sd = truth$sd)
  u <- u - mean(u)
  names(u) <- levels(id)
  mu <- plogis(truth$mu[[1L]] + truth$mu[[2L]] * dat$x + u[id])
  sigma <- exp(truth$sigma[[1L]] + truth$sigma[[2L]] * dat$z)
  phi <- 1 / sigma^2
  p <- rbeta(n, shape1 = mu * phi, shape2 = (1 - mu) * phi)
  dat$success <- rbinom(n, size = dat$trials, prob = p)
  dat$failure <- dat$trials - dat$success
  list(data = dat, truth = truth, u = u)
}

mr_t4_ordinal_data <- function(n = 900L, seed = 20260509L) {
  set.seed(seed)
  dat <- data.frame(x = rnorm(n))
  truth <- list(mu = c(x = 0.85), cutpoints = c(-0.90, 0.75))
  eta <- truth$mu[["x"]] * dat$x
  p1 <- plogis(truth$cutpoints[[1L]] - eta)
  p2 <- plogis(truth$cutpoints[[2L]] - eta) - p1
  prob <- cbind(p1, p2, 1 - plogis(truth$cutpoints[[2L]] - eta))
  draw <- vapply(seq_len(n), function(i) {
    sample.int(3L, 1L, prob = prob[i, ])
  }, integer(1L))
  dat$score <- ordered(
    c("low", "medium", "high")[draw],
    levels = c("low", "medium", "high")
  )
  list(data = dat, truth = truth)
}

mr_t4_fit <- function(route, data, missing = miss_control(), se = FALSE) {
  control <- drm_control(se = se)
  switch(
    route,
    beta_binomial = drmTMB(
      bf(cbind(success, failure) ~ x + (1 | id), sigma ~ z),
      beta_binomial(), data, missing = missing, control = control
    ),
    cumulative_logit = drmTMB(
      bf(score ~ x), cumulative_logit(), data,
      missing = missing, control = control
    )
  )
}

expect_beta_binomial_sentinel_invariant <- function(fit) {
  missing <- fit$model$tmb_data$observed_y == 0L
  expect_true(any(missing))
  data_a <- fit$model$tmb_data
  data_b <- fit$model$tmb_data
  data_a$y[missing] <- 0
  data_a$trials[missing] <- 1
  data_b$y[missing] <- 2
  data_b$trials[missing] <- 5
  obj_a <- missing_response_retaped_object(fit, data_a)
  obj_b <- missing_response_retaped_object(fit, data_b)
  par <- fit$opt$par
  expect_equal(obj_a$fn(par), obj_b$fn(par), tolerance = 1e-8)
  expect_equal(obj_a$gr(par), obj_b$gr(par), tolerance = 1e-8,
               ignore_attr = TRUE)
  opt_a <- nlminb(par, obj_a$fn, obj_a$gr)
  opt_b <- nlminb(par, obj_b$fn, obj_b$gr)
  expect_equal(opt_a$convergence, 0L)
  expect_equal(opt_b$convergence, 0L)
  expect_equal(unname(opt_a$par), unname(opt_b$par), tolerance = 1e-6)
  expect_equal(-opt_a$objective, -opt_b$objective, tolerance = 1e-6)
}

test_that("partial beta-binomial rows mask the whole encoded response", {
  case <- mr_t4_beta_binomial_data(n_id = 32L, n_each = 8L, seed = 2026071401L)
  base <- case$data
  set.seed(2026071402L)
  rows <- sample(seq_len(nrow(base)), nrow(base) / 4L)
  variants <- list(success = base, failure = base, both = base)
  variants$success$success[rows] <- NA_real_
  variants$failure$failure[rows] <- NA_real_
  variants$both$success[rows] <- NA_real_
  variants$both$failure[rows] <- NA_real_
  fits <- lapply(variants, function(dat) {
    mr_t4_fit(
      "beta_binomial", dat, missing = miss_control(response = "include")
    )
  })
  observed <- !(seq_len(nrow(base)) %in% rows)
  fit_cc <- mr_t4_fit("beta_binomial", base[observed, , drop = FALSE])

  for (fit in fits) {
    expect_equal(fit$missing_data$observed_y, observed)
    expect_equal(nobs(fit), sum(observed))
    expect_equal(fit$missing_data$response_sentinel,
                 c(successes = 0, failures = 1, trials = 1))
    expect_length(fitted(fit), nrow(base))
    expect_true(all(is.na(residuals(fit)[!observed])))
    expect_true(all(is.na(residuals(fit, type = "pearson")[!observed])))
  }
  expect_equal(unname(fits[[1L]]$opt$par), unname(fit_cc$opt$par),
               tolerance = 1e-6)
  expect_equal(as.numeric(logLik(fits[[1L]])), as.numeric(logLik(fit_cc)),
               tolerance = 1e-6)
  for (fit in fits[-1L]) {
    expect_equal(unname(fit$opt$par), unname(fits[[1L]]$opt$par),
                 tolerance = 1e-6)
    expect_equal(as.numeric(logLik(fit)), as.numeric(logLik(fits[[1L]])),
                 tolerance = 1e-6)
  }
  expect_beta_binomial_sentinel_invariant(fits[[1L]])
  sims <- simulate(fits[[1L]], nsim = 2, seed = 2026071403L)
  expect_true(all(is.na(sims[!observed, ])))
})

test_that("beta-binomial random-intercept response mask matches observed-data fit", {
  set.seed(2026081512)
  n_id <- 60L
  n_each <- 12L
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- rnorm(n)
  z <- rnorm(n)
  trials <- sample(20:30, n, replace = TRUE)
  truth_sd <- 0.6
  u <- rnorm(n_id, sd = truth_sd)
  mu <- plogis(-0.25 + 0.65 * x + u[id])
  sigma <- exp(-1.35 + 0.15 * z)
  p <- rbeta(n, mu / sigma^2, (1 - mu) / sigma^2)
  dat <- data.frame(success = rbinom(n, trials, p), x, z, id)
  dat$failure <- trials - dat$success
  masked <- missing_response_mask_mcar_within_group(
    dat, "success", "id", seed = 2026081513
  )
  masked$failure[is.na(masked$success)] <- NA_integer_
  observed <- !is.na(masked$success)

  fit_mask <- drmTMB(
    bf(cbind(success, failure) ~ x + (1 | id), sigma ~ z), beta_binomial(),
    masked, missing = miss_control(response = "include"), control = drm_control(se = FALSE)
  )
  fit_observed <- drmTMB(
    bf(cbind(success, failure) ~ x + (1 | id), sigma ~ z), beta_binomial(),
    masked[observed, ], control = drm_control(se = FALSE)
  )

  expect_equal(coef(fit_mask, "mu"), coef(fit_observed, "mu"), tolerance = 1e-6)
  expect_equal(coef(fit_mask, "sigma"), coef(fit_observed, "sigma"), tolerance = 1e-6)
  expect_equal(fit_mask$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-6)
  expect_equal(as.numeric(logLik(fit_mask)), as.numeric(logLik(fit_observed)), tolerance = 1e-6)
  expect_equal(nobs(fit_mask), sum(observed))
  expect_beta_binomial_sentinel_invariant(fit_mask)
  expect_lt(max(abs(unname(coef(fit_mask, "mu")) - c(-0.25, 0.65))), 0.25)
  expect_lt(max(abs(unname(coef(fit_mask, "sigma")) - c(-1.35, 0.15))), 0.2)
  expect_lt(abs(unname(fit_mask$sdpars$mu) - truth_sd), 0.2)
  expect_gt(cor(fit_mask$random_effects$mu$values, u), 0.6)
})

test_that("ordinal masks preserve declared levels and cutpoint branches", {
  case <- mr_t4_ordinal_data(n = 360L, seed = 2026071411L)
  dat <- missing_response_mask_mcar(case$data, "score", seed = 2026071412L)
  observed <- !is.na(dat$score)
  fit <- mr_t4_fit(
    "cumulative_logit", dat, missing = miss_control(response = "include")
  )
  cc <- mr_t4_fit("cumulative_logit", dat[observed, , drop = FALSE])
  expect_identical(fit$ordinal$levels, levels(case$data$score))
  expect_equal(unname(fit$opt$par), unname(cc$opt$par), tolerance = 1e-6)
  expect_equal(as.numeric(logLik(fit)), as.numeric(logLik(cc)), tolerance = 1e-6)
  expect_equal(nobs(fit), sum(observed))
  expect_length(fitted(fit), nrow(dat))
  expect_true(all(is.na(residuals(fit)[!observed])))
  expect_true(all(is.na(residuals(fit, type = "pearson")[!observed])))
  expect_missing_response_sentinel_invariant(fit, sentinels = c(1, 3))
  sims <- simulate(fit, nsim = 2, seed = 2026071413L)
  expect_true(all(vapply(sims, is.ordered, logical(1L))))
  expect_true(all(vapply(sims, function(x) identical(levels(x), levels(case$data$score)), logical(1L))))
})

test_that("ordinal random-slope response mask matches observed-data fit", {
  set.seed(2026081510)
  n_id <- 50L
  n_each <- 20L
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- rnorm(length(id))
  truth_sd <- 0.5
  u <- rnorm(n_id, sd = truth_sd)
  cutpoints <- c(-1, 0, 1)
  latent <- 0.8 * x + u[id] * x + rlogis(length(id))
  dat <- data.frame(
    score = ordered(findInterval(latent, cutpoints) + 1L, levels = 1:4), x, id
  )
  masked <- missing_response_mask_mcar_within_group(
    dat, "score", "id", seed = 2026081511
  )
  observed <- !is.na(masked$score)

  fit_mask <- drmTMB(
    bf(score ~ x + (0 + x | id)), cumulative_logit(), masked,
    missing = miss_control(response = "include"), control = drm_control(se = FALSE)
  )
  fit_observed <- drmTMB(
    bf(score ~ x + (0 + x | id)), cumulative_logit(), masked[observed, ],
    control = drm_control(se = FALSE)
  )

  expect_equal(unname(fit_mask$opt$par), unname(fit_observed$opt$par), tolerance = 1e-5)
  expect_equal(as.numeric(logLik(fit_mask)), as.numeric(logLik(fit_observed)), tolerance = 1e-5)
  expect_equal(nobs(fit_mask), sum(observed))
  expect_missing_response_sentinel_invariant(fit_mask, sentinels = c(1, 3))
  expect_lt(abs(unname(coef(fit_mask, "mu")) - 0.8), 0.2)
  expect_lt(abs(unname(fit_mask$sdpars$mu) - truth_sd), 0.2)
  expect_gt(cor(fit_mask$random_effects$mu$values, u), 0.5)
})

test_that("MR-T4 recovers every encoded-response parameter", {
  bb <- mr_t4_beta_binomial_data()
  dat_bb <- missing_response_mask_mcar(bb$data, "success", seed = 2026071421L)
  dat_bb$failure[is.na(dat_bb$success)] <- NA_real_
  expect_equal(mean(is.na(dat_bb$success)), 0.25)
  expect_false(any(tapply(!is.na(dat_bb$success), dat_bb$id, sum) == 0L))
  fit_bb <- mr_t4_fit(
    "beta_binomial", dat_bb, missing = miss_control(response = "include")
  )
  expect_lt(max(abs(unname(coef(fit_bb, "mu")) - bb$truth$mu)), 0.30)
  expect_lt(max(abs(unname(coef(fit_bb, "sigma")) - bb$truth$sigma)), 0.35)
  expect_lt(abs(unname(fit_bb$sdpars$mu) - bb$truth$sd), 0.35)
  expect_gt(cor(fit_bb$random_effects$mu$values, bb$u), 0.40)

  ord <- mr_t4_ordinal_data()
  dat_ord <- missing_response_mask_mcar(ord$data, "score", seed = 2026071422L)
  expect_equal(mean(is.na(dat_ord$score)), 0.25)
  expect_true(all(table(dat_ord$score, useNA = "no") > 0L))
  fit_ord <- mr_t4_fit(
    "cumulative_logit", dat_ord,
    missing = miss_control(response = "include")
  )
  expect_lt(abs(unname(coef(fit_ord, "mu")) - ord$truth$mu), 0.15)
  expect_equal(unname(fit_ord$ordinal$cutpoints), ord$truth$cutpoints,
               tolerance = 0.18)
})

test_that("ordinal masks reject unidentified or undeclared cutpoints", {
  dat <- mr_t4_ordinal_data(n = 180L, seed = 2026071431L)$data
  include <- miss_control(response = "include")
  for (level in c("medium", "high")) {
    masked <- dat
    masked$score[masked$score == level] <- NA
    expect_error(
      mr_t4_fit("cumulative_logit", masked, missing = include),
      "Every ordinal category|empty categor"
    )
  }
  numeric_dat <- transform(dat, score = as.integer(score))
  numeric_dat$score[[1L]] <- NA_integer_
  expect_error(
    mr_t4_fit("cumulative_logit", numeric_dat, missing = include),
    "ordered-factor response"
  )
})

test_that("MR-T4 retains response-missing rows but drops predictor-missing rows", {
  bb <- mr_t4_beta_binomial_data(n_id = 8L, n_each = 8L, seed = 2026071435L)$data
  bb$success[[1L]] <- NA_real_
  bb$x[[2L]] <- NA_real_
  fit_bb <- mr_t4_fit(
    "beta_binomial", bb, missing = miss_control(response = "include")
  )
  expect_equal(fit_bb$missing_data$original_row, setdiff(seq_len(64L), 2L))
  expect_equal(nobs(fit_bb), 62L)
  expect_true(is.na(residuals(fit_bb)[[1L]]))

  ord <- mr_t4_ordinal_data(n = 80L, seed = 2026071436L)$data
  ord$score[[1L]] <- NA
  ord$x[[2L]] <- NA_real_
  fit_ord <- mr_t4_fit(
    "cumulative_logit", ord, missing = miss_control(response = "include")
  )
  expect_equal(fit_ord$missing_data$original_row, setdiff(seq_len(80L), 2L))
  expect_equal(nobs(fit_ord), 78L)
  expect_true(is.na(residuals(fit_ord)[[1L]]))
})

test_that("MR-T4 rejects all-missing, malformed, and neighbouring routes", {
  include <- miss_control(response = "include")
  bb <- mr_t4_beta_binomial_data(n_id = 8L, n_each = 8L, seed = 2026071441L)$data
  bb$success <- NA_real_
  bb$failure <- NA_real_
  expect_error(
    mr_t4_fit("beta_binomial", bb, missing = include),
    "At least one complete observed"
  )
  ord <- mr_t4_ordinal_data(n = 80L, seed = 2026071442L)$data
  ord$score[] <- NA
  expect_error(
    mr_t4_fit("cumulative_logit", ord, missing = include),
    "At least one observed ordinal"
  )
  bad <- mr_t4_beta_binomial_data(n_id = 8L, n_each = 8L, seed = 2026071443L)$data
  bad$success[c(1L, 2L)] <- c(NA_real_, -1)
  expect_error(mr_t4_fit("beta_binomial", bad, missing = include),
               "finite non-negative integers")

  ord2 <- mr_t4_ordinal_data(n = 80L, seed = 2026071444L)$data
  ord2$score[[1L]] <- NA
  expect_error(
    drmTMB(bf(score ~ x), cumulative_logit(), ord2,
           missing = include, REML = TRUE),
    "Gaussian and binomial"
  )
  bb2 <- mr_t4_beta_binomial_data(n_id = 8L, n_each = 8L, seed = 2026071445L)$data
  bb2$success[[1L]] <- NA
  expect_error(
    drmTMB(
      bf(cbind(success, failure) ~ x + mi(q), sigma ~ z),
      beta_binomial(), transform(bb2, q = NA_real_),
      impute = list(q = q ~ x),
      missing = miss_control(response = "include", predictor = "model")
    ),
    "predictor.*model"
  )
})

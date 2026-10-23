mr_t2_fixed_data <- function(route, n = 600L) {
  seed <- match(route, c("student", "skew_normal", "lognormal", "gamma"))
  set.seed(2026071200 + seed)
  dat <- data.frame(x = rnorm(n), z = rnorm(n))
  if (identical(route, "student")) {
    truth <- list(mu = c(0.25, 0.6), sigma = c(-0.3, 0.25), nu = log(6))
    mu <- truth$mu[[1L]] + truth$mu[[2L]] * dat$x
    sigma <- exp(truth$sigma[[1L]] + truth$sigma[[2L]] * dat$z)
    q <- qt((seq_len(n) - 0.5) / n, df = 2 + exp(truth$nu))
    dat$y <- mu + sigma * sample(q)
  } else if (identical(route, "skew_normal")) {
    truth <- list(mu = c(0.2, 0.45), sigma = c(-0.35, 0.18), nu = 1.6)
    mu <- truth$mu[[1L]] + truth$mu[[2L]] * dat$x
    sigma <- exp(truth$sigma[[1L]] + truth$sigma[[2L]] * dat$z)
    native <- skew_normal_public_to_native(mu, sigma, truth$nu)
    dat$y <- native$xi + native$omega * (
      native$delta * abs(rnorm(n)) +
        sqrt(1 - native$delta^2) * rnorm(n)
    )
  } else if (identical(route, "lognormal")) {
    truth <- list(mu = c(0.35, 0.45), sigma = c(-0.65, 0.25))
    mu <- truth$mu[[1L]] + truth$mu[[2L]] * dat$x
    sigma <- exp(truth$sigma[[1L]] + truth$sigma[[2L]] * dat$z)
    dat$y <- rlnorm(n, meanlog = mu, sdlog = sigma)
  } else if (identical(route, "gamma")) {
    truth <- list(mu = c(0.2, 0.45), sigma = c(-0.75, 0.25))
    mu <- exp(truth$mu[[1L]] + truth$mu[[2L]] * dat$x)
    sigma <- exp(truth$sigma[[1L]] + truth$sigma[[2L]] * dat$z)
    dat$y <- rgamma(n, shape = 1 / sigma^2, scale = mu * sigma^2)
  } else {
    stop("Unknown MR-T2 route.")
  }
  list(data = dat, truth = truth)
}

mr_t2_fit <- function(route, data, missing = miss_control(), se = FALSE) {
  control <- drm_control(se = se)
  switch(
    route,
    student = drmTMB(
      bf(y ~ x, sigma ~ z, nu ~ 1), student(), data,
      missing = missing, control = control
    ),
    skew_normal = drmTMB(
      bf(y ~ x, sigma ~ z, nu ~ 1), skew_normal(), data,
      missing = missing, control = control
    ),
    lognormal = drmTMB(
      bf(y ~ x, sigma ~ z), lognormal(), data,
      missing = missing, control = control
    ),
    gamma = drmTMB(
      bf(y ~ x, sigma ~ z), Gamma(link = "log"), data,
      missing = missing, control = control
    )
  )
}

test_that("MR-T2 masks match explicit observed-row fits and row contracts", {
  routes <- c("student", "skew_normal", "lognormal", "gamma")
  for (route in routes) {
    case <- mr_t2_fixed_data(route)
    dat <- case$data
    set.seed(2026071210 + match(route, routes))
    missing_rows <- sample(seq_len(nrow(dat)), nrow(dat) / 4L)
    observed <- !(seq_len(nrow(dat)) %in% missing_rows)
    dat$y[missing_rows] <- NA_real_
    expect_equal(mean(!observed), 0.25, info = route)

    fit_mask <- mr_t2_fit(
      route,
      dat,
      missing = miss_control(response = "include")
    )
    fit_cc <- mr_t2_fit(route, dat[observed, , drop = FALSE])

    for (dpar in names(case$truth)) {
      expect_equal(
        unname(coef(fit_mask, dpar)),
        unname(coef(fit_cc, dpar)),
        tolerance = 1e-6,
        info = paste(route, dpar)
      )
    }
    expect_equal(
      as.numeric(logLik(fit_mask)),
      as.numeric(logLik(fit_cc)),
      tolerance = 1e-6,
      info = route
    )
    expect_equal(nobs(fit_mask), sum(observed), info = route)
    expect_equal(fit_mask$missing_data$observed_y, observed, info = route)
    expect_equal(
      fit_mask$missing_data$counts$missing_response,
      sum(!observed),
      info = route
    )
    expect_equal(
      fit_mask$missing_data$response_sentinel,
      if (route %in% c("lognormal", "gamma")) 1 else 0,
      info = route
    )
    expect_equal(
      fit_mask$missing_data$original_row,
      seq_len(nrow(dat)),
      info = route
    )
    expect_equal(
      fit_mask$missing_data$model_row,
      seq_len(nrow(dat)),
      info = route
    )
    expect_length(fitted(fit_mask), nrow(dat))
    expect_equal(
      fitted(fit_mask)[observed],
      fitted(fit_cc),
      tolerance = 1e-6,
      ignore_attr = TRUE,
      info = route
    )
    expect_true(all(is.na(residuals(fit_mask)[!observed])), info = route)
    expect_true(
      all(is.na(residuals(fit_mask, type = "pearson")[!observed])),
      info = route
    )

    if (route %in% c("lognormal", "gamma")) {
      expect_missing_response_sentinel_invariant(
        fit_mask, sentinels = c(1, 0)
      )
      expect_missing_response_sentinel_invariant(
        fit_mask, sentinels = c(1, -1)
      )
    } else {
      expect_missing_response_sentinel_invariant(
        fit_mask, sentinels = c(-1e6, 1e6)
      )
    }
  }
})

mr_t2_random_intercept_data <- function(route, seed) {
  set.seed(seed)
  n_id <- switch(route, student = 40L, lognormal = 36L, gamma = 42L)
  n_each <- switch(route, student = 10L, lognormal = 9L, gamma = 10L)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  dat <- data.frame(id = id, x = rnorm(n), z = rnorm(n))
  truth <- switch(
    route,
    student = list(mu = c(0.20, 0.48), sigma = c(-0.42, 0.18), sd = 0.52),
    lognormal = list(mu = c(0.25, 0.40), sigma = c(-0.75, 0.18), sd = 0.55),
    gamma = list(mu = c(0.15, 0.36), sigma = c(-0.85, 0.16), sd = 0.48)
  )
  u <- rnorm(n_id, sd = truth$sd)
  u <- u - mean(u)
  eta <- truth$mu[[1L]] + truth$mu[[2L]] * dat$x + u[id]
  sigma <- exp(truth$sigma[[1L]] + truth$sigma[[2L]] * dat$z)
  if (route == "student") {
    truth$nu <- log(7)
    q <- qt((seq_len(n) - 0.5) / n, df = 2 + exp(truth$nu))
    dat$y <- eta + sigma * sample(q)
  } else if (route == "lognormal") {
    dat$y <- rlnorm(n, meanlog = eta, sdlog = sigma)
  } else if (route == "gamma") {
    mu <- exp(eta)
    dat$y <- rgamma(n, shape = 1 / sigma^2, scale = mu * sigma^2)
  }
  complete <- dat
  dat <- missing_response_mask_mcar(dat, "y", seed = seed + 1L)
  if (any(tapply(!is.na(dat$y), dat$id, sum) == 0L)) {
    stop("Fixed-seed MCAR mask removed every response from a group.")
  }
  list(data = dat, complete = complete, truth = truth, u = u)
}

test_that("Student, lognormal, and Gamma masks recover random-intercept DGPs", {
  routes <- c("student", "lognormal", "gamma")
  for (i in seq_along(routes)) {
    route <- routes[[i]]
    case <- mr_t2_random_intercept_data(route, 2026071220 + i)
    dat <- case$data
    expect_equal(mean(is.na(dat$y)), 0.25, info = route)
    fit <- switch(
      route,
      student = drmTMB(
        bf(y ~ x + (1 | id), sigma ~ z, nu ~ 1),
        student(), dat,
        missing = miss_control(response = "include"),
        control = drm_control(se = FALSE)
      ),
      lognormal = drmTMB(
        bf(y ~ x + (1 | id), sigma ~ z),
        lognormal(), dat,
        missing = miss_control(response = "include"),
        control = drm_control(se = FALSE)
      ),
      gamma = drmTMB(
        bf(y ~ x + (1 | id), sigma ~ z),
        Gamma(link = "log"), dat,
        missing = miss_control(response = "include"),
        control = drm_control(se = FALSE)
      )
    )
    observed <- !is.na(dat$y)
    fit_observed <- switch(
      route,
      student = drmTMB(
        bf(y ~ x + (1 | id), sigma ~ z, nu ~ 1), student(),
        case$complete[observed, , drop = FALSE], control = drm_control(se = FALSE)
      ),
      lognormal = drmTMB(
        bf(y ~ x + (1 | id), sigma ~ z), lognormal(),
        case$complete[observed, , drop = FALSE], control = drm_control(se = FALSE)
      ),
      gamma = drmTMB(
        bf(y ~ x + (1 | id), sigma ~ z), Gamma(link = "log"),
        case$complete[observed, , drop = FALSE], control = drm_control(se = FALSE)
      )
    )

    for (dpar in intersect(names(case$truth), c("mu", "sigma", "nu"))) {
      expect_equal(
        unname(coef(fit, dpar)), unname(coef(fit_observed, dpar)),
        tolerance = 1e-6, info = paste(route, dpar, "observed-data equality")
      )
    }
    expect_equal(
      as.numeric(logLik(fit)), as.numeric(logLik(fit_observed)),
      tolerance = 1e-6, info = paste(route, "observed-data equality")
    )
    expect_missing_response_sentinel_invariant(
      fit,
      sentinels = if (route == "gamma") c(1, 0) else c(0, -1)
    )

    expect_lt(
      max(abs(unname(coef(fit, "mu")) - case$truth$mu)),
      switch(route, student = 0.20, lognormal = 0.18, gamma = 0.20)
    )
    expect_lt(
      max(abs(unname(coef(fit, "sigma")) - case$truth$sigma)),
      switch(route, student = 0.25, lognormal = 0.20, gamma = 0.25)
    )
    if (route == "student") {
      expect_lt(
        abs(unname(coef(fit, "nu")) - case$truth$nu),
        0.60
      )
    }
    expect_lt(
      abs(unname(fit$sdpars$mu) - case$truth$sd),
      switch(route, student = 0.30, lognormal = 0.25, gamma = 0.25)
    )
    expect_gt(
      cor(fit$random_effects$mu$values, case$u),
      switch(route, student = 0.45, lognormal = 0.50, gamma = 0.45)
    )
  }
})

mr_t2_random_slope_data <- function(route, seed) {
  set.seed(seed)
  n_id <- switch(route, student = 44L, skew_normal = 50L, lognormal = 42L, gamma = 46L)
  n_each <- 16L
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  dat <- data.frame(id = id, x = rnorm(n), z = rnorm(n))
  truth <- switch(
    route,
    student = list(mu = c(0.20, 0.48), sigma = c(-0.42, 0.18), nu = log(7), sd = 0.50),
    skew_normal = list(mu = c(0.20, 0.45), sigma = c(-0.35, 0.18), nu = 1.6, sd = 0.45),
    lognormal = list(mu = c(0.25, 0.40), sigma = c(-0.75, 0.18), sd = 0.50),
    gamma = list(mu = c(0.15, 0.36), sigma = c(-0.85, 0.16), sd = 0.48)
  )
  u <- rnorm(n_id, sd = truth$sd)
  eta <- truth$mu[[1L]] + (truth$mu[[2L]] + u[id]) * dat$x
  sigma <- exp(truth$sigma[[1L]] + truth$sigma[[2L]] * dat$z)
  if (route == "student") {
    q <- qt((seq_len(n) - 0.5) / n, df = 2 + exp(truth$nu))
    dat$y <- eta + sigma * sample(q)
  } else if (route == "skew_normal") {
    native <- skew_normal_public_to_native(eta, sigma, truth$nu)
    dat$y <- native$xi + native$omega * (
      native$delta * abs(rnorm(n)) + sqrt(1 - native$delta^2) * rnorm(n)
    )
  } else if (route == "lognormal") {
    dat$y <- rlnorm(n, meanlog = eta, sdlog = sigma)
  } else {
    mu <- exp(eta)
    dat$y <- rgamma(n, shape = 1 / sigma^2, scale = mu * sigma^2)
  }
  complete <- dat
  dat <- missing_response_mask_mcar_within_group(dat, "y", "id", seed = seed + 1L)
  list(data = dat, complete = complete, truth = truth, u = u)
}

test_that("continuous masks recover random-slope DGPs", {
  routes <- c("student", "skew_normal", "lognormal", "gamma")
  for (i in seq_along(routes)) {
    route <- routes[[i]]
    case <- mr_t2_random_slope_data(route, 2026081530L + i)
    dat <- case$data
    observed <- !is.na(dat$y)
    form <- switch(
      route,
      student = bf(y ~ x + (0 + x | id), sigma ~ z, nu ~ 1),
      skew_normal = bf(y ~ x + (0 + x | id), sigma ~ z, nu ~ 1),
      lognormal = bf(y ~ x + (0 + x | id), sigma ~ z),
      gamma = bf(y ~ x + (0 + x | id), sigma ~ z)
    )
    fit <- drmTMB(
      form, switch(route, student = student(), skew_normal = skew_normal(), lognormal = lognormal(), gamma = Gamma(link = "log")),
      dat, missing = miss_control(response = "include"), control = drm_control(se = FALSE)
    )
    fit_observed <- drmTMB(
      form, switch(route, student = student(), skew_normal = skew_normal(), lognormal = lognormal(), gamma = Gamma(link = "log")),
      case$complete[observed, , drop = FALSE], control = drm_control(se = FALSE)
    )
    for (dpar in names(coef(fit))) {
      expect_equal(coef(fit, dpar), coef(fit_observed, dpar), tolerance = 1e-5,
        info = paste(route, dpar, "observed-data equality"))
    }
    expect_equal(fit$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-5, info = route)
    expect_equal(as.numeric(logLik(fit)), as.numeric(logLik(fit_observed)), tolerance = 1e-5, info = route)
    expect_missing_response_sentinel_invariant(fit,
      sentinels = if (route == "gamma") c(1, 0) else c(0, -1))
    expect_lt(max(abs(unname(coef(fit, "mu")) - case$truth$mu)), 0.25)
    expect_lt(max(abs(unname(coef(fit, "sigma")) - case$truth$sigma)), 0.25)
    if (route == "student") expect_lt(abs(unname(coef(fit, "nu")) - case$truth$nu), 0.65)
    if (route == "skew_normal") expect_lt(abs(unname(coef(fit, "nu")) - case$truth$nu), 0.35)
    expect_lt(abs(unname(fit$sdpars$mu) - case$truth$sd), 0.28)
    slope_effects <- fit$random_effects$mu$terms[["(0 + x | id)"]]
    expect_gt(cor(slope_effects, case$u), 0.40)
  }
})

test_that("skew-normal masks recover fixed location, scale, and slant", {
  n <- 360L
  dat <- data.frame(
    x = seq(-1.2, 1.2, length.out = n),
    z = rep(seq(-1, 1, length.out = 24), length.out = n)
  )
  truth <- list(mu = c(0.2, 0.4), sigma = c(-0.3, 0.15), nu = 1.4)
  mu <- truth$mu[[1L]] + truth$mu[[2L]] * dat$x
  sigma <- exp(truth$sigma[[1L]] + truth$sigma[[2L]] * dat$z)
  index <- seq_len(n)
  u <- qnorm((index - 0.5) / n)
  v <- qnorm((((index * 37L) %% n) + 0.5) / n)
  native <- skew_normal_public_to_native(mu, sigma, truth$nu)
  dat$y <- native$xi + native$omega * (
    native$delta * abs(u) + sqrt(1 - native$delta^2) * v
  )
  dat <- missing_response_mask_mcar(dat, "y", seed = 2026071231)
  expect_equal(mean(is.na(dat$y)), 0.25)

  fit <- mr_t2_fit(
    "skew_normal",
    dat,
    missing = miss_control(response = "include")
  )
  expect_lt(max(abs(unname(coef(fit, "mu")) - truth$mu)), 0.15)
  expect_lt(max(abs(unname(coef(fit, "sigma")) - truth$sigma)), 0.15)
  expect_lt(abs(unname(coef(fit, "nu")) - truth$nu), 0.45)
})

test_that("MR-T2 masks reject all-missing and invalid observed responses", {
  include <- miss_control(response = "include")
  dat <- data.frame(y = rep(NA_real_, 8), x = seq(-1, 1, length.out = 8), z = 0)
  for (route in c("student", "skew_normal", "lognormal", "gamma")) {
    expect_error(
      mr_t2_fit(route, dat, missing = include),
      "At least one observed",
      info = route
    )
  }

  unbounded_bad <- transform(dat, y = c(0, NA, Inf, 1, 2, 3, 4, 5))
  expect_error(
    mr_t2_fit("student", unbounded_bad, missing = include),
    "finite observed response"
  )
  expect_error(
    mr_t2_fit("skew_normal", unbounded_bad, missing = include),
    "finite continuous response"
  )

  for (bad in c(0, -1)) {
    positive_bad <- transform(dat, y = c(1, NA, bad, 2, 3, 4, 5, 6))
    expect_error(
      mr_t2_fit("lognormal", positive_bad, missing = include),
      "positive finite response",
      info = paste("lognormal", bad)
    )
    expect_error(
      mr_t2_fit("gamma", positive_bad, missing = include),
      "positive finite response",
      info = paste("gamma", bad)
    )
  }
})

test_that("lognormal sigma random-intercept response mask matches observed data", {
  set.seed(2026081542L)
  n_id <- 60L
  n_each <- 20L
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- rnorm(length(id))
  truth_sd <- 0.38
  u <- rnorm(n_id, sd = truth_sd)
  dat <- data.frame(id, x)
  dat$y <- rlnorm(nrow(dat), meanlog = 0.25 + 0.40 * x, sdlog = exp(-0.70 + u[id]))
  masked <- missing_response_mask_mcar_within_group(dat, "y", "id", seed = 2026081543L)
  observed <- !is.na(masked$y)
  form <- bf(y ~ x, sigma ~ 1 + (1 | id))
  fit_mask <- drmTMB(form, lognormal(), masked,
    missing = miss_control(response = "include"), control = drm_control(se = FALSE))
  fit_observed <- drmTMB(form, lognormal(), masked[observed, , drop = FALSE],
    control = drm_control(se = FALSE))
  expect_equal(coef(fit_mask, "mu"), coef(fit_observed, "mu"), tolerance = 1e-6)
  expect_equal(coef(fit_mask, "sigma"), coef(fit_observed, "sigma"), tolerance = 1e-6)
  expect_equal(fit_mask$sdpars$sigma, fit_observed$sdpars$sigma, tolerance = 1e-6)
  expect_equal(as.numeric(logLik(fit_mask)), as.numeric(logLik(fit_observed)), tolerance = 1e-6)
  expect_missing_response_sentinel_invariant(fit_mask, sentinels = c(1, 0))
  expect_lt(max(abs(unname(coef(fit_mask, "mu")) - c(0.25, 0.40))), 0.15)
  expect_lt(abs(unname(coef(fit_mask, "sigma")) + 0.70), 0.18)
  expect_lt(abs(unname(fit_mask$sdpars$sigma) - truth_sd), 0.22)
  expect_gt(cor(fit_mask$random_effects$sigma$values, u), 0.40)
})

test_that("Gamma sigma random-intercept response mask matches observed data", {
  set.seed(2026081546L)
  n_id <- 60L
  n_each <- 20L
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- rnorm(length(id))
  truth_sd <- 0.36
  u <- rnorm(n_id, sd = truth_sd)
  dat <- data.frame(id, x)
  mu <- exp(0.15 + 0.36 * x)
  sigma <- exp(-0.85 + u[id])
  dat$y <- rgamma(nrow(dat), shape = 1 / sigma^2, scale = mu * sigma^2)
  masked <- missing_response_mask_mcar_within_group(dat, "y", "id", seed = 2026081547L)
  observed <- !is.na(masked$y)
  form <- bf(y ~ x, sigma ~ 1 + (1 | id))
  fit_mask <- drmTMB(form, Gamma(link = "log"), masked,
    missing = miss_control(response = "include"), control = drm_control(se = FALSE))
  fit_observed <- drmTMB(form, Gamma(link = "log"), masked[observed, , drop = FALSE],
    control = drm_control(se = FALSE))
  expect_equal(coef(fit_mask, "mu"), coef(fit_observed, "mu"), tolerance = 1e-6)
  expect_equal(coef(fit_mask, "sigma"), coef(fit_observed, "sigma"), tolerance = 1e-6)
  expect_equal(fit_mask$sdpars$sigma, fit_observed$sdpars$sigma, tolerance = 1e-6)
  expect_equal(as.numeric(logLik(fit_mask)), as.numeric(logLik(fit_observed)), tolerance = 1e-6)
  expect_missing_response_sentinel_invariant(fit_mask, sentinels = c(1, 0))
  expect_lt(max(abs(unname(coef(fit_mask, "mu")) - c(0.15, 0.36))), 0.18)
  expect_lt(abs(unname(coef(fit_mask, "sigma")) + 0.85), 0.18)
  expect_lt(abs(unname(fit_mask$sdpars$sigma) - truth_sd), 0.20)
  expect_gt(cor(fit_mask$random_effects$sigma$values, u), 0.40)
})

test_that("skew-normal random-intercept response mask matches observed data", {
  set.seed(2026081563L)
  n_id <- 50L
  n_each <- 32L
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- rnorm(n)
  z <- rnorm(n)
  truth_sd <- 0.45
  u <- rnorm(n_id, sd = truth_sd)
  mu <- 0.2 + 0.45 * x + u[id]
  sigma <- exp(-0.35 + 0.18 * z)
  nu <- 1.6
  native <- skew_normal_public_to_native(mu, sigma, nu)
  y <- native$xi + native$omega * (
    native$delta * abs(rnorm(n)) + sqrt(1 - native$delta^2) * rnorm(n)
  )
  dat <- data.frame(y, x, z, id)
  masked <- missing_response_mask_mcar_within_group(
    dat, "y", "id", seed = 2026081564L
  )
  observed <- !is.na(masked$y)
  form <- bf(y ~ x + (1 | id), sigma ~ z, nu ~ 1)
  fit_mask <- drmTMB(
    form, skew_normal(), masked,
    missing = miss_control(response = "include"), control = drm_control(se = FALSE)
  )
  fit_observed <- drmTMB(
    form, skew_normal(), masked[observed, ], control = drm_control(se = FALSE)
  )
  expect_equal(coef(fit_mask, "mu"), coef(fit_observed, "mu"), tolerance = 1e-5)
  expect_equal(coef(fit_mask, "sigma"), coef(fit_observed, "sigma"), tolerance = 1e-5)
  expect_equal(coef(fit_mask, "nu"), coef(fit_observed, "nu"), tolerance = 1e-5)
  expect_equal(fit_mask$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-5)
  expect_equal(as.numeric(logLik(fit_mask)), as.numeric(logLik(fit_observed)), tolerance = 1e-5)
  expect_equal(nobs(fit_mask), sum(observed))
  expect_missing_response_sentinel_invariant(fit_mask, sentinels = c(-1e6, 1e6))
  expect_lt(abs(unname(fit_mask$sdpars$mu) - truth_sd), 0.25)
  expect_gt(cor(fit_mask$random_effects$mu$values, u), 0.35)
})

test_that("MR-T2 masks retain response-missing rows but drop predictor-missing rows", {
  for (route in c("student", "skew_normal", "lognormal", "gamma")) {
    dat <- mr_t2_fixed_data(route, n = 80L)$data
    dat$y[[1L]] <- NA_real_
    dat$x[[2L]] <- NA_real_
    fit <- mr_t2_fit(
      route,
      dat,
      missing = miss_control(response = "include")
    )

    expect_equal(fit$missing_data$original_row, setdiff(seq_len(80L), 2L))
    expect_true(1L %in% fit$missing_data$original_row)
    expect_equal(fit$missing_data$counts$missing_response, 1L)
    expect_equal(nobs(fit), 78L)
    expect_length(fitted(fit), 79L)
    expect_true(is.na(residuals(fit)[[1L]]))
  }
})

test_that("MR-T2 response masks do not relax neighbouring model gates", {
  dat <- mr_t2_fixed_data("student", n = 80L)$data
  dat$y[[1L]] <- NA_real_
  dat$w <- rbinom(nrow(dat), 1, 0.5)
  dat$w[[2L]] <- NA_integer_
  both <- miss_control(response = "include", predictor = "model")

  for (route in c("student", "skew_normal", "lognormal", "gamma")) {
    family <- switch(
      route,
      student = student(),
      skew_normal = skew_normal(),
      lognormal = lognormal(),
      gamma = Gamma(link = "log")
    )
    expect_error(
      drmTMB(
        bf(y ~ x + mi(w), sigma ~ z),
        family,
        dat,
        impute = list(w = impute_model(w ~ x, family = binomial())),
        missing = both
      ),
      "predictor.*model",
      info = route
    )
    expect_error(
      drmTMB(
        bf(y ~ x, sigma ~ z),
        family,
        dat,
        missing = miss_control(response = "include"),
        REML = TRUE
      ),
      "Gaussian and binomial",
      info = route
    )
  }

  # A skew_normal `mu` random intercept is supported (Arc 2a), incl. masking.
  expect_no_error(
    suppressWarnings(drmTMB(
      bf(y ~ x + (1 | id), sigma ~ z),
      skew_normal(),
      transform(dat, id = factor(rep(1:8, each = 10))),
      missing = miss_control(response = "include")
    ))
  )
})

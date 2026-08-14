mr_t3_tweedie_data <- function(n = 500L, seed = 20260701L) {
  set.seed(seed)
  dat <- data.frame(x = runif(n, -1, 1), z = rnorm(n))
  truth <- list(mu = c(0.20, 0.45), sigma = c(-0.55, 0.20), nu = 1.35)
  mu <- exp(truth$mu[[1L]] + truth$mu[[2L]] * dat$x)
  sigma <- exp(truth$sigma[[1L]] + truth$sigma[[2L]] * dat$z)
  dat$y <- rtweedie_compound(n, mu = mu, phi = sigma^2, power = truth$nu)
  list(data = dat, truth = truth)
}

mr_t3_zero_one_beta_data <- function(n = 1600L, seed = 20260620L) {
  set.seed(seed)
  dat <- data.frame(
    x = rnorm(n), z = rnorm(n), w = rnorm(n), v = rnorm(n)
  )
  truth <- list(
    mu = c(-0.20, 0.65),
    sigma = c(-0.85, 0.22),
    zoi = c(-1.00, 0.45),
    coi = c(0.15, -0.55)
  )
  mu <- plogis(truth$mu[[1L]] + truth$mu[[2L]] * dat$x)
  sigma <- exp(truth$sigma[[1L]] + truth$sigma[[2L]] * dat$z)
  zoi <- plogis(truth$zoi[[1L]] + truth$zoi[[2L]] * dat$w)
  coi <- plogis(truth$coi[[1L]] + truth$coi[[2L]] * dat$v)
  dat$y <- rbeta(n, shape1 = mu / sigma^2, shape2 = (1 - mu) / sigma^2)
  boundary <- runif(n) < zoi
  dat$y[boundary] <- as.numeric(runif(sum(boundary)) < coi[boundary])
  list(data = dat, truth = truth)
}

mr_t3_fit <- function(route, data, missing = miss_control(), se = FALSE) {
  control <- drm_control(se = se)
  switch(
    route,
    tweedie = drmTMB(
      bf(y ~ x, sigma ~ z, nu ~ 1), tweedie(), data,
      missing = missing, control = control
    ),
    zero_one_beta = drmTMB(
      bf(y ~ x, sigma ~ z, zoi ~ w, coi ~ v), zero_one_beta(), data,
      missing = missing, control = control
    )
  )
}

test_that("MR-T3 masks match observed-row fits and preserve row contracts", {
  cases <- list(
    tweedie = mr_t3_tweedie_data(n = 320L, seed = 2026071301L),
    zero_one_beta = mr_t3_zero_one_beta_data(n = 640L, seed = 2026071302L)
  )
  for (route in names(cases)) {
    dat <- missing_response_mask_mcar(
      cases[[route]]$data,
      "y",
      seed = 2026071310L + match(route, names(cases))
    )
    observed <- !is.na(dat$y)
    expect_equal(mean(!observed), 0.25, info = route)

    fit_mask <- mr_t3_fit(
      route, dat, missing = miss_control(response = "include")
    )
    fit_cc <- mr_t3_fit(route, dat[observed, , drop = FALSE])

    for (dpar in names(cases[[route]]$truth)) {
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
    expect_equal(fit_mask$missing_data$response_sentinel, 0, info = route)
    expect_equal(fit_mask$missing_data$original_row, seq_len(nrow(dat)))
    expect_equal(fit_mask$missing_data$model_row, seq_len(nrow(dat)))
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

    if (route == "tweedie") {
      expect_missing_response_sentinel_invariant(
        fit_mask, sentinels = c(0, 1)
      )
    } else {
      expect_missing_response_sentinel_invariant(
        fit_mask, sentinels = c(0, 0.5)
      )
      expect_missing_response_sentinel_invariant(
        fit_mask, sentinels = c(1, 0.5)
      )
    }
  }
})

test_that("zero-one-beta mu random-intercept response mask matches observed data", {
  case <- mr_t3_zero_one_beta_data(n = 1600L, seed = 2026081516L)
  dat <- case$data
  set.seed(2026081517L)
  dat$id <- factor(rep(seq_len(50L), each = 32L))
  truth_sd <- 0.45
  u <- rnorm(50L, sd = truth_sd)
  mu <- plogis(case$truth$mu[[1L]] + case$truth$mu[[2L]] * dat$x + u[dat$id])
  sigma <- exp(case$truth$sigma[[1L]] + case$truth$sigma[[2L]] * dat$z)
  zoi <- plogis(case$truth$zoi[[1L]] + case$truth$zoi[[2L]] * dat$w)
  coi <- plogis(case$truth$coi[[1L]] + case$truth$coi[[2L]] * dat$v)
  dat$y <- rbeta(nrow(dat), mu / sigma^2, (1 - mu) / sigma^2)
  atom <- runif(nrow(dat)) < zoi
  dat$y[atom] <- as.numeric(runif(sum(atom)) < coi[atom])
  masked <- missing_response_mask_mcar_within_group(dat, "y", "id", seed = 2026081518L)
  observed <- !is.na(masked$y)
  form <- bf(y ~ x + (1 | id), sigma ~ z, zoi ~ w, coi ~ v)
  fit_mask <- drmTMB(form, zero_one_beta(), masked, missing = miss_control(response = "include"), control = drm_control(se = FALSE))
  fit_observed <- drmTMB(form, zero_one_beta(), masked[observed, ], control = drm_control(se = FALSE))
  expect_equal(coef(fit_mask, "mu"), coef(fit_observed, "mu"), tolerance = 1e-5)
  expect_equal(fit_mask$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-5)
  expect_equal(as.numeric(logLik(fit_mask)), as.numeric(logLik(fit_observed)), tolerance = 1e-5)
  expect_equal(nobs(fit_mask), sum(observed))
  expect_missing_response_sentinel_invariant(fit_mask, sentinels = c(0, 1))
  expect_lt(abs(unname(fit_mask$sdpars$mu) - truth_sd), 0.25)
  expect_gt(cor(fit_mask$random_effects$mu$values, u), 0.5)
})

test_that("zero-one-beta sigma random-intercept response mask matches observed data", {
  case <- mr_t3_zero_one_beta_data(n = 1600L, seed = 2026081562L)
  dat <- case$data
  set.seed(2026081563L)
  dat$id <- factor(rep(seq_len(50L), each = 32L))
  truth_sd <- 0.35
  u <- rnorm(50L, sd = truth_sd)
  mu <- plogis(case$truth$mu[[1L]] + case$truth$mu[[2L]] * dat$x)
  sigma <- exp(case$truth$sigma[[1L]] + u[dat$id])
  zoi <- plogis(case$truth$zoi[[1L]])
  coi <- plogis(case$truth$coi[[1L]])
  dat$y <- rbeta(nrow(dat), mu / sigma^2, (1 - mu) / sigma^2)
  atom <- runif(nrow(dat)) < zoi
  dat$y[atom] <- as.numeric(runif(sum(atom)) < coi[atom])
  masked <- missing_response_mask_mcar_within_group(dat, "y", "id", seed = 2026081564L)
  observed <- !is.na(masked$y)
  form <- bf(y ~ x, sigma ~ 1 + (1 | id), zoi ~ 1, coi ~ 1)
  fit_mask <- drmTMB(form, zero_one_beta(), masked, missing = miss_control(response = "include"), control = drm_control(se = FALSE))
  fit_observed <- drmTMB(form, zero_one_beta(), masked[observed, ], control = drm_control(se = FALSE))
  expect_equal(coef(fit_mask, "mu"), coef(fit_observed, "mu"), tolerance = 1e-5)
  expect_equal(coef(fit_mask, "sigma"), coef(fit_observed, "sigma"), tolerance = 1e-5)
  expect_equal(fit_mask$sdpars$sigma, fit_observed$sdpars$sigma, tolerance = 1e-5)
  expect_equal(as.numeric(logLik(fit_mask)), as.numeric(logLik(fit_observed)), tolerance = 1e-5)
  expect_missing_response_sentinel_invariant(fit_mask, sentinels = c(0, 1))
  expect_lt(abs(unname(fit_mask$sdpars$sigma) - truth_sd), 0.22)
  expect_gt(cor(fit_mask$random_effects$sigma$values, u), 0.35)
})

test_that("zero-one-beta zoi random-intercept response mask matches observed data", {
  set.seed(2026081566L); id <- factor(rep(seq_len(50L), each = 32L)); n <- length(id)
  x <- rnorm(n); u <- rnorm(50L, sd = .45); mu <- plogis(-.2 + .65*x); sig <- exp(-.85)
  zoi <- plogis(-1 + u[id]); y <- rbeta(n, mu/sig^2, (1-mu)/sig^2); y[runif(n)<zoi] <- 0
  d <- data.frame(y,x,id); m <- missing_response_mask_mcar_within_group(d,"y","id",seed=2026081568L); o <- !is.na(m$y)
  f <- bf(y~x,sigma~1,zoi~1+(1|id),coi~1)
  a <- drmTMB(f,zero_one_beta(),m,missing=miss_control(response="include"),control=drm_control(se=FALSE)); b <- drmTMB(f,zero_one_beta(),m[o,],control=drm_control(se=FALSE))
  expect_equal(coef(a,"zoi"),coef(b,"zoi"),tolerance=1e-5); expect_equal(a$sdpars$zoi,b$sdpars$zoi,tolerance=1e-5); expect_equal(as.numeric(logLik(a)),as.numeric(logLik(b)),tolerance=1e-5)
  expect_missing_response_sentinel_invariant(a,sentinels=c(0,1)); expect_lt(abs(unname(a$sdpars$zoi)-.45),.25); expect_gt(cor(a$random_effects$zoi$values,u),.35)
})

test_that("zero-one-beta coi random-intercept response mask matches observed data", {
  set.seed(2026081570L)
  id <- factor(rep(seq_len(50L), each = 32L))
  n <- length(id)
  x <- rnorm(n)
  truth_sd <- 0.45
  u <- rnorm(50L, sd = truth_sd)
  mu <- plogis(-0.2 + 0.65 * x)
  sigma <- exp(-0.85)
  zoi <- plogis(-1)
  coi <- plogis(0.2 + u[id])
  y <- rbeta(n, mu / sigma^2, (1 - mu) / sigma^2)
  atom <- runif(n) < zoi
  y[atom] <- as.numeric(runif(sum(atom)) < coi[atom])
  dat <- data.frame(y, x, id)
  masked <- missing_response_mask_mcar_within_group(
    dat, "y", "id", seed = 2026081571L
  )
  observed <- !is.na(masked$y)
  form <- bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1 + (1 | id))
  fit_mask <- drmTMB(
    form, zero_one_beta(), masked,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )
  fit_observed <- drmTMB(
    form, zero_one_beta(), masked[observed, ], control = drm_control(se = FALSE)
  )
  expect_equal(coef(fit_mask, "coi"), coef(fit_observed, "coi"), tolerance = 1e-5)
  expect_equal(fit_mask$sdpars$coi, fit_observed$sdpars$coi, tolerance = 1e-5)
  expect_equal(as.numeric(logLik(fit_mask)), as.numeric(logLik(fit_observed)), tolerance = 1e-5)
  expect_equal(nobs(fit_mask), sum(observed))
  expect_missing_response_sentinel_invariant(fit_mask, sentinels = c(0, 1))
  expect_lt(abs(unname(fit_mask$sdpars$coi) - truth_sd), 0.25)
  expect_gt(cor(fit_mask$random_effects$coi$values, u), 0.35)
})

test_that("zero-one-beta mu random-slope response mask matches observed data", {
  case <- mr_t3_zero_one_beta_data(n = 1600L, seed = 2026081520L)
  dat <- case$data
  set.seed(2026081521L)
  dat$id <- factor(rep(seq_len(50L), each = 32L))
  truth_sd <- 0.50
  u <- rnorm(50L, sd = truth_sd)
  mu <- plogis(case$truth$mu[[1L]] + (case$truth$mu[[2L]] + u[dat$id]) * dat$x)
  sigma <- exp(case$truth$sigma[[1L]] + case$truth$sigma[[2L]] * dat$z)
  zoi <- plogis(case$truth$zoi[[1L]] + case$truth$zoi[[2L]] * dat$w)
  coi <- plogis(case$truth$coi[[1L]] + case$truth$coi[[2L]] * dat$v)
  dat$y <- rbeta(nrow(dat), mu / sigma^2, (1 - mu) / sigma^2)
  atom <- runif(nrow(dat)) < zoi
  dat$y[atom] <- as.numeric(runif(sum(atom)) < coi[atom])
  masked <- missing_response_mask_mcar_within_group(dat, "y", "id", seed = 2026081522L)
  observed <- !is.na(masked$y)
  form <- bf(y ~ x + (0 + x | id), sigma ~ z, zoi ~ w, coi ~ v)
  fit_mask <- drmTMB(form, zero_one_beta(), masked, missing = miss_control(response = "include"), control = drm_control(se = FALSE))
  fit_observed <- drmTMB(form, zero_one_beta(), masked[observed, ], control = drm_control(se = FALSE))
  expect_equal(coef(fit_mask, "mu"), coef(fit_observed, "mu"), tolerance = 1e-5)
  expect_equal(fit_mask$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-5)
  expect_equal(as.numeric(logLik(fit_mask)), as.numeric(logLik(fit_observed)), tolerance = 1e-5)
  expect_equal(nobs(fit_mask), sum(observed))
  expect_missing_response_sentinel_invariant(fit_mask, sentinels = c(0, 1))
  expect_lt(abs(unname(fit_mask$sdpars$mu) - truth_sd), 0.25)
  slope_effects <- fit_mask$random_effects$mu$terms[["(0 + x | id)"]]
  expect_gt(cor(slope_effects, u), 0.5)
})

test_that("Tweedie mu random-slope response mask matches observed data", {
  set.seed(2026081524L)
  n_id <- 48L
  n_each <- 32L
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  dat <- data.frame(id = id, x = runif(n, -1, 1), z = rnorm(n))
  truth <- list(mu = c(0.20, 0.45), sigma = c(-0.55, 0.20), nu = 1.35, sd = 0.48)
  u <- rnorm(n_id, sd = truth$sd)
  mu <- exp(truth$mu[[1L]] + (truth$mu[[2L]] + u[id]) * dat$x)
  sigma <- exp(truth$sigma[[1L]] + truth$sigma[[2L]] * dat$z)
  dat$y <- rtweedie_compound(n, mu = mu, phi = sigma^2, power = truth$nu)
  masked <- missing_response_mask_mcar_within_group(dat, "y", "id", seed = 2026081525L)
  observed <- !is.na(masked$y)
  form <- bf(y ~ x + (0 + x | id), sigma ~ z, nu ~ 1)
  fit_mask <- drmTMB(form, tweedie(), masked, missing = miss_control(response = "include"), control = drm_control(se = FALSE))
  fit_observed <- drmTMB(form, tweedie(), masked[observed, ], control = drm_control(se = FALSE))
  expect_equal(coef(fit_mask, "mu"), coef(fit_observed, "mu"), tolerance = 1e-5)
  expect_equal(coef(fit_mask, "sigma"), coef(fit_observed, "sigma"), tolerance = 1e-5)
  expect_equal(coef(fit_mask, "nu"), coef(fit_observed, "nu"), tolerance = 1e-5)
  expect_equal(fit_mask$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-5)
  expect_equal(as.numeric(logLik(fit_mask)), as.numeric(logLik(fit_observed)), tolerance = 1e-5)
  expect_equal(nobs(fit_mask), sum(observed))
  expect_missing_response_sentinel_invariant(fit_mask, sentinels = c(0, 1))
  expect_lt(max(abs(unname(coef(fit_mask, "mu")) - truth$mu)), 0.20)
  expect_lt(max(abs(unname(coef(fit_mask, "sigma")) - truth$sigma)), 0.20)
  expect_lt(abs(unname(coef(fit_mask, "nu")) - truth$nu), 0.15)
  expect_lt(abs(unname(fit_mask$sdpars$mu) - truth$sd), 0.25)
  slope_effects <- fit_mask$random_effects$mu$terms[["(0 + x | id)"]]
  expect_gt(cor(slope_effects, u), 0.45)
})

test_that("MR-T3 masks recover every fixed distributional parameter", {
  tweedie_case <- mr_t3_tweedie_data()
  tweedie_dat <- missing_response_mask_mcar(
    tweedie_case$data, "y", seed = 2026071321L
  )
  expect_equal(mean(is.na(tweedie_dat$y)), 0.25)
  expect_gt(sum(is.na(tweedie_dat$y) & tweedie_case$data$y == 0), 0L)
  expect_gt(sum(is.na(tweedie_dat$y) & tweedie_case$data$y > 0), 0L)
  tweedie_fit <- mr_t3_fit(
    "tweedie", tweedie_dat, missing = miss_control(response = "include")
  )
  expect_lt(
    max(abs(unname(coef(tweedie_fit, "mu")) - tweedie_case$truth$mu)),
    0.15
  )
  expect_lt(
    max(abs(unname(coef(tweedie_fit, "sigma")) - tweedie_case$truth$sigma)),
    0.15
  )
  expect_lt(
    abs(unique(predict(tweedie_fit, dpar = "nu")) - tweedie_case$truth$nu),
    0.12
  )

  zoib_case <- mr_t3_zero_one_beta_data()
  zoib_dat <- missing_response_mask_mcar(
    zoib_case$data, "y", seed = 2026071322L
  )
  missing <- is.na(zoib_dat$y)
  expect_equal(mean(missing), 0.25)
  expect_gt(sum(missing & zoib_case$data$y == 0), 0L)
  expect_gt(sum(missing & zoib_case$data$y == 1), 0L)
  expect_gt(sum(missing & zoib_case$data$y > 0 & zoib_case$data$y < 1), 0L)
  zoib_fit <- mr_t3_fit(
    "zero_one_beta", zoib_dat,
    missing = miss_control(response = "include")
  )
  expect_lt(max(abs(unname(coef(zoib_fit, "mu")) - zoib_case$truth$mu)), 0.10)
  expect_lt(
    max(abs(unname(coef(zoib_fit, "sigma")) - zoib_case$truth$sigma)),
    0.12
  )
  expect_lt(max(abs(unname(coef(zoib_fit, "zoi")) - zoib_case$truth$zoi)), 0.12)
  expect_lt(max(abs(unname(coef(zoib_fit, "coi")) - zoib_case$truth$coi)), 0.22)
})

test_that("MR-T3 masks reject malformed observed responses", {
  include <- miss_control(response = "include")
  tw <- mr_t3_tweedie_data(n = 40L, seed = 2026071331L)$data
  zoib <- mr_t3_zero_one_beta_data(n = 80L, seed = 2026071332L)$data

  expect_error(
    mr_t3_fit("tweedie", transform(tw, y = NA_real_), missing = include),
    "At least one observed Tweedie"
  )
  expect_error(
    mr_t3_fit(
      "zero_one_beta", transform(zoib, y = NA_real_), missing = include
    ),
    "At least one observed zero-one beta"
  )

  tw$y[c(1L, 2L)] <- c(NA_real_, -0.1)
  expect_error(
    mr_t3_fit("tweedie", tw, missing = include),
    "non-negative finite"
  )
  zoib$y[c(1L, 2L)] <- c(NA_real_, 1.1)
  expect_error(
    mr_t3_fit("zero_one_beta", zoib, missing = include),
    "closed interval"
  )
  zoib$y <- rep(c(0, 1, NA_real_, 0), length.out = nrow(zoib))
  expect_error(
    mr_t3_fit("zero_one_beta", zoib, missing = include),
    "at least one interior"
  )
})

test_that("MR-T3 retains response-missing rows but drops predictor-missing rows", {
  cases <- list(
    tweedie = mr_t3_tweedie_data(n = 80L, seed = 2026071341L)$data,
    zero_one_beta = mr_t3_zero_one_beta_data(n = 80L, seed = 2026071342L)$data
  )
  for (route in names(cases)) {
    dat <- cases[[route]]
    dat$y[[1L]] <- NA_real_
    dat$x[[2L]] <- NA_real_
    fit <- mr_t3_fit(
      route, dat, missing = miss_control(response = "include")
    )
    expect_equal(fit$missing_data$original_row, setdiff(seq_len(80L), 2L))
    expect_true(1L %in% fit$missing_data$original_row)
    expect_equal(fit$missing_data$counts$missing_response, 1L)
    expect_equal(nobs(fit), 78L)
    expect_length(fitted(fit), 79L)
    expect_true(is.na(residuals(fit)[[1L]]))
  }
})

test_that("MR-T3 response masks do not relax neighbouring gates", {
  include <- miss_control(response = "include")
  tw <- mr_t3_tweedie_data(n = 80L, seed = 2026071351L)$data
  zoib <- mr_t3_zero_one_beta_data(n = 80L, seed = 2026071352L)$data
  tw$y[[1L]] <- NA_real_
  zoib$y[[1L]] <- NA_real_

  for (case in list(
    list(data = tw, family = tweedie(), formula = bf(y ~ x, sigma ~ z, nu ~ 1)),
    list(
      data = zoib,
      family = zero_one_beta(),
      formula = bf(y ~ x, sigma ~ z, zoi ~ w, coi ~ v)
    )
  )) {
    expect_error(
      drmTMB(
        case$formula, case$family, case$data,
        missing = include, REML = TRUE
      ),
      "Gaussian and binomial"
    )
  }

  tw$q <- rbinom(nrow(tw), 1, 0.5)
  tw$q[[2L]] <- NA_integer_
  zoib$q <- rbinom(nrow(zoib), 1, 0.5)
  zoib$q[[2L]] <- NA_integer_
  for (case in list(
    list(
      data = tw,
      family = tweedie(),
      formula = bf(y ~ x + mi(q), sigma ~ z, nu ~ 1)
    ),
    list(
      data = zoib,
      family = zero_one_beta(),
      formula = bf(y ~ x + mi(q), sigma ~ z, zoi ~ w, coi ~ v)
    )
  )) {
    expect_error(
      drmTMB(
        case$formula, case$family, case$data,
        impute = list(q = impute_model(q ~ x, family = binomial())),
        missing = miss_control(response = "include", predictor = "model")
      ),
      "predictor.*model"
    )
  }

  # A `mu` random intercept `(1 | id)` is supported for these families (Arc 2a),
  # including under response masking; it is no longer a rejected gate.
  tw$id <- factor(rep(1:8, each = 10))
  expect_no_error(
    suppressWarnings(drmTMB(
      bf(y ~ x + (1 | id), sigma ~ z, nu ~ 1), tweedie(), tw,
      missing = include
    ))
  )
  zoib$id <- factor(rep(1:8, each = 10))
  expect_no_error(
    suppressWarnings(drmTMB(
      bf(y ~ x + (1 | id), sigma ~ z, zoi ~ w, coi ~ v),
      zero_one_beta(), zoib, missing = include
    ))
  )
})

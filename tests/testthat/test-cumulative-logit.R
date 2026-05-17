new_ordinal_data <- function(n = 900, seed = 20260509) {
  set.seed(seed)
  dat <- data.frame(x = stats::rnorm(n))
  beta_mu <- c(x = 0.85)
  cutpoints <- c(`low|medium` = -0.90, `medium|high` = 0.75)
  eta <- beta_mu[["x"]] * dat$x
  p_low <- stats::plogis(cutpoints[[1L]] - eta)
  p_medium <- stats::plogis(cutpoints[[2L]] - eta) - p_low
  prob <- cbind(p_low, p_medium, 1 - stats::plogis(cutpoints[[2L]] - eta))
  draw <- vapply(
    seq_len(n),
    function(i) {
      sample.int(3L, size = 1L, prob = prob[i, ])
    },
    integer(1)
  )
  dat$score <- ordered(
    c("low", "medium", "high")[draw],
    levels = c("low", "medium", "high")
  )
  list(data = dat, beta_mu = beta_mu, cutpoints = cutpoints)
}

ordinal_prob_from_fit <- function(fit) {
  eta <- predict(fit, dpar = "mu", type = "link")
  cutpoints <- unname(fit$ordinal$cutpoints)
  cumulative <- stats::plogis(
    matrix(
      cutpoints,
      nrow = length(eta),
      ncol = length(cutpoints),
      byrow = TRUE
    ) -
      eta
  )
  prob <- cbind(
    cumulative[, 1L],
    cumulative[, -1L, drop = FALSE] -
      cumulative[, -ncol(cumulative), drop = FALSE],
    1 - cumulative[, ncol(cumulative)]
  )
  colnames(prob) <- fit$ordinal$levels
  prob
}

test_that("drmTMB fits fixed-effect cumulative-logit ordinal models", {
  sim <- new_ordinal_data()

  fit <- drmTMB(
    bf(score ~ x),
    family = cumulative_logit(),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "cumulative_logit")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$df, length(fit$opt$par))
  expect_named(coef(fit), "mu")
  expect_named(coef(fit, "mu"), "x")
  expect_lt(abs(coef(fit, "mu")[["x"]] - sim$beta_mu[["x"]]), 0.15)
  expect_equal(
    unname(fit$ordinal$cutpoints),
    unname(sim$cutpoints),
    tolerance = 0.18
  )
  expect_true(all(diff(fit$ordinal$cutpoints) > 0))
})

test_that("cumulative-logit likelihood matches independent category probabilities", {
  sim <- new_ordinal_data(n = 360, seed = 20260510)
  fit <- drmTMB(
    bf(score ~ x),
    family = cumulative_logit(),
    data = sim$data
  )

  prob <- ordinal_prob_from_fit(fit)
  y <- as.integer(fit$model$y)
  ll_independent <- sum(log(prob[cbind(seq_along(y), y)]))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(as.numeric(logLik(fit)), ll_independent, tolerance = 1e-6)

  w <- seq(0.5, 1.5, length.out = nrow(sim$data))
  fit_w <- drmTMB(
    bf(score ~ x),
    family = cumulative_logit(),
    data = sim$data,
    weights = w
  )
  prob_w <- ordinal_prob_from_fit(fit_w)
  y_w <- as.integer(fit_w$model$y)
  ll_weighted <- sum(w * log(prob_w[cbind(seq_along(y_w), y_w)]))

  expect_equal(fit_w$opt$convergence, 0)
  expect_equal(as.numeric(logLik(fit_w)), ll_weighted, tolerance = 1e-6)
})

test_that("cumulative-logit methods return latent location and ordinal summaries", {
  sim <- new_ordinal_data(n = 220, seed = 20260511)
  fit <- drmTMB(
    bf(score ~ x),
    family = cumulative_logit(),
    data = sim$data
  )

  prob <- ordinal_prob_from_fit(fit)
  expected_score <- as.vector(prob %*% seq_len(ncol(prob)))
  score_variance <- as.vector(prob %*% (seq_len(ncol(prob))^2)) -
    expected_score^2

  expect_equal(
    predict(fit, dpar = "mu"),
    predict(fit, dpar = "mu", type = "link"),
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, dpar = "mu", type = "link"),
    as.vector(fit$model$X$mu %*% coef(fit, "mu")),
    tolerance = 1e-12
  )
  expect_equal(fitted(fit), expected_score, tolerance = 1e-12)
  expect_equal(residuals(fit), fit$model$y - expected_score, tolerance = 1e-12)
  expect_equal(
    residuals(fit, type = "pearson"),
    (fit$model$y - expected_score) / sqrt(score_variance),
    tolerance = 1e-12
  )
  expect_equal(sigma(fit), rep(1, nobs(fit)))

  newdata <- data.frame(x = c(-1, 0, 1))
  expect_equal(
    predict(fit, newdata = newdata, dpar = "mu", type = "link"),
    as.vector(stats::model.matrix(~ x - 1, newdata) %*% coef(fit, "mu")),
    tolerance = 1e-12
  )
  prob_new <- drmTMB:::ordinal_category_probabilities(fit, newdata = newdata)
  expect_equal(dim(prob_new), c(nrow(newdata), length(fit$ordinal$levels)))
  expect_equal(colnames(prob_new), fit$ordinal$levels)
  expect_equal(rowSums(prob_new), rep(1, nrow(newdata)), tolerance = 1e-12)
  expect_equal(
    drmTMB:::ordinal_expected_score(fit, newdata = newdata),
    as.vector(prob_new %*% seq_len(ncol(prob_new))),
    tolerance = 1e-12
  )
  expect_equal(
    drmTMB:::ordinal_score_variance(fit, newdata = newdata),
    as.vector(prob_new %*% (seq_len(ncol(prob_new))^2)) -
      drmTMB:::ordinal_expected_score(fit, newdata = newdata)^2,
    tolerance = 1e-12
  )

  sims <- simulate(fit, nsim = 2, seed = 20260512)
  expect_equal(dim(sims), c(nrow(fit$data), 2L))
  expect_named(sims, c("sim_1", "sim_2"))
  expect_true(is.ordered(sims$sim_1))
  expect_equal(levels(sims$sim_1), fit$ordinal$levels)
  expect_equal(
    simulate(fit, nsim = 2, seed = 20260512),
    simulate(fit, nsim = 2, seed = 20260512)
  )
})

test_that("cumulative-logit accepts integer scores and factor predictors", {
  set.seed(20260513)
  n <- 600
  group <- factor(rep(c("control", "treatment"), each = n / 2))
  beta_mu <- c(grouptreatment = 0.80)
  cutpoints <- c(-0.70, 0.85)
  eta <- beta_mu[[1L]] * (group == "treatment")
  p1 <- stats::plogis(cutpoints[[1L]] - eta)
  p2 <- stats::plogis(cutpoints[[2L]] - eta) - p1
  prob <- cbind(p1, p2, 1 - stats::plogis(cutpoints[[2L]] - eta))
  score <- vapply(
    seq_len(n),
    function(i) {
      sample.int(3L, size = 1L, prob = prob[i, ])
    },
    integer(1)
  )
  dat <- data.frame(score = score, group = group)

  fit <- drmTMB(
    bf(score ~ group),
    family = cumulative_logit(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$ordinal$levels, c("1", "2", "3"))
  expect_equal(unname(coef(fit, "mu")), unname(beta_mu), tolerance = 0.18)
  expect_true(all(diff(fit$ordinal$cutpoints) > 0))
})

test_that("cumulative-logit handles more than three ordered categories", {
  set.seed(20260517)
  n <- 720
  x <- stats::rnorm(n)
  beta_mu <- c(x = 0.65)
  cutpoints <- c(-1.25, -0.20, 0.90)
  eta <- beta_mu[["x"]] * x
  cumulative <- stats::plogis(
    matrix(cutpoints, nrow = n, ncol = length(cutpoints), byrow = TRUE) - eta
  )
  prob <- cbind(
    cumulative[, 1L],
    cumulative[, -1L, drop = FALSE] -
      cumulative[, -ncol(cumulative), drop = FALSE],
    1 - cumulative[, ncol(cumulative)]
  )
  draw <- vapply(
    seq_len(n),
    function(i) {
      sample.int(4L, size = 1L, prob = prob[i, ])
    },
    integer(1)
  )
  dat <- data.frame(
    score = ordered(
      c("low", "medium_low", "medium_high", "high")[draw],
      levels = c("low", "medium_low", "medium_high", "high")
    ),
    x = x
  )

  fit <- drmTMB(
    bf(score ~ x),
    family = cumulative_logit(),
    data = dat
  )

  prob_fit <- ordinal_prob_from_fit(fit)
  y <- as.integer(fit$model$y)

  expect_equal(fit$opt$convergence, 0)
  expect_equal(length(fit$ordinal$cutpoints), 3L)
  expect_equal(ncol(prob_fit), 4L)
  expect_equal(rowSums(prob_fit), rep(1, nrow(prob_fit)), tolerance = 1e-12)
  expect_lt(abs(coef(fit, "mu")[["x"]] - beta_mu[["x"]]), 0.15)
  expect_equal(
    as.numeric(logLik(fit)),
    sum(log(prob_fit[cbind(seq_along(y), y)])),
    tolerance = 1e-6
  )
})

test_that("cumulative-logit handles missing rows and sparse nonempty categories", {
  sim <- new_ordinal_data(n = 90, seed = 20260514)
  dat <- sim$data
  dat$score[c(1, 2)] <- NA
  dat$x[c(3, 4)] <- NA

  fit <- drmTMB(
    bf(score ~ x),
    family = cumulative_logit(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(nobs(fit), nrow(dat) - 4L)
  expect_equal(sum(!fit$model$keep), 4L)
  expect_equal(length(fitted(fit)), nobs(fit))
  expect_true(all(table(fit$model$y) > 0))

  sparse <- data.frame(
    score = ordered(
      c(rep("low", 45), rep("medium", 5), rep("high", 45)),
      levels = c("low", "medium", "high")
    )
  )
  sparse_fit <- drmTMB(
    bf(score ~ 1),
    family = cumulative_logit(),
    data = sparse
  )

  expect_equal(sparse_fit$opt$convergence, 0)
  expect_true(all(diff(sparse_fit$ordinal$cutpoints) > 0))
  expect_true(all(is.finite(fitted(sparse_fit))))

  sparse_start <- data.frame(
    score = ordered(
      c("low", "medium", rep("high", 98)),
      levels = c("low", "medium", "high")
    )
  )
  sparse_start_fit <- drmTMB(
    bf(score ~ 1),
    family = cumulative_logit(),
    data = sparse_start
  )

  expect_equal(sparse_start_fit$opt$convergence, 0)
  expect_true(all(is.finite(sparse_start_fit$model$start$theta_ord)))
  expect_true(all(diff(sparse_start_fit$ordinal$cutpoints) > 0))

  expect_error(
    drmTMB(
      bf(score ~ x),
      family = cumulative_logit(),
      data = transform(sim$data, score = NA)
    ),
    "No complete observations"
  )
})

test_that("cumulative-logit probabilities stay stable for close cutpoints and extreme locations", {
  sim <- new_ordinal_data(n = 120, seed = 20260515)
  fit <- drmTMB(
    bf(score ~ x),
    family = cumulative_logit(),
    data = sim$data
  )
  fit$ordinal$cutpoints <- c(`low|medium` = -0.001, `medium|high` = 0.001)
  fit$coefficients$mu <- c(x = 8)

  prob <- drmTMB:::ordinal_category_probabilities(
    fit,
    newdata = data.frame(x = c(-5, 0, 5))
  )

  expect_true(all(is.finite(prob)))
  expect_true(all(prob >= 0))
  expect_equal(rowSums(prob), rep(1, nrow(prob)), tolerance = 1e-12)
  expect_true(all(prob[, "medium"] > 0))

  sims <- simulate(fit, nsim = 1, seed = 20260516)
  expect_true(is.ordered(sims$sim_1))
  expect_true(all(as.character(sims$sim_1) %in% fit$ordinal$levels))
})

test_that("cumulative-logit objective handles extreme middle-category probabilities", {
  dat <- data.frame(
    score = ordered(
      c("low", "medium", "high"),
      levels = c("low", "medium", "high")
    ),
    x = c(0, 0, 0)
  )
  fit <- drmTMB(bf(score ~ x), family = cumulative_logit(), data = dat)

  par_high <- fit$obj$par
  par_high[["beta_mu"]] <- 0
  par_high[2:3] <- c(999, 0)
  par_low <- par_high
  par_low[2:3] <- c(-1000, 0)

  expect_true(is.finite(fit$obj$fn(par_high)))
  expect_true(all(is.finite(fit$obj$gr(par_high))))
  expect_true(is.finite(fit$obj$fn(par_low)))
  expect_true(all(is.finite(fit$obj$gr(par_low))))

  fit$ordinal$cutpoints <- c(`low|medium` = 999, `medium|high` = 1000)
  prob_high <- drmTMB:::ordinal_category_probabilities(fit)
  fit$ordinal$cutpoints <- c(`low|medium` = -1000, `medium|high` = -999)
  prob_low <- drmTMB:::ordinal_category_probabilities(fit)

  expect_true(all(is.finite(prob_high)))
  expect_true(all(is.finite(prob_low)))
  expect_equal(rowSums(prob_high), rep(1, nrow(prob_high)), tolerance = 1e-12)
  expect_equal(rowSums(prob_low), rep(1, nrow(prob_low)), tolerance = 1e-12)
})

test_that("cumulative-logit validates ordinal scope and malformed responses", {
  dat <- data.frame(
    y = ordered(c("low", "medium", "high", "low", "medium", "high")),
    unordered = factor(c("low", "medium", "high", "low", "medium", "high")),
    x = c(-1, 0, 1, -0.5, 0.5, 1.5),
    id = factor(c(1, 1, 2, 2, 3, 3))
  )

  expect_error(
    drmTMB(bf(unordered ~ x), family = cumulative_logit(), data = dat),
    "ordered response"
  )
  expect_error(
    drmTMB(
      bf(y_char ~ x),
      family = cumulative_logit(),
      data = transform(dat, y_char = as.character(y))
    ),
    "ordered factor or integer category"
  )
  expect_error(
    drmTMB(
      bf(y_binary ~ x),
      family = cumulative_logit(),
      data = transform(
        dat,
        y_binary = ordered(
          c("low", "high", "low", "high", "low", "high"),
          levels = c("low", "high")
        )
      )
    ),
    "at least three ordered categories"
  )
  expect_error(
    drmTMB(
      bf(y_num ~ x),
      family = cumulative_logit(),
      data = transform(dat, y_num = c(0, 1, 2, 3, 1, 2))
    ),
    "starting at 1"
  )
  expect_error(
    drmTMB(
      bf(y_num ~ x),
      family = cumulative_logit(),
      data = transform(dat, y_num = c(1, 2, 3.5, 1, 2, 3))
    ),
    "integer category"
  )
  expect_error(
    drmTMB(
      bf(y_sparse ~ x),
      family = cumulative_logit(),
      data = transform(
        dat,
        y_sparse = ordered(
          c("low", "high", "low", "high", "low", "high"),
          levels = c("low", "medium", "high")
        )
      )
    ),
    "empty categor"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = cumulative_logit(), data = dat),
    "support only"
  )
  expect_error(
    drmTMB(bf(y ~ x + (1 | id)), family = cumulative_logit(), data = dat),
    "Ordinal random effects"
  )
  expect_error(
    drmTMB(bf(y ~ x + (0 + x | id)), family = cumulative_logit(), data = dat),
    "Ordinal random effects"
  )
  expect_error(
    drmTMB(bf(y ~ x, sd(id) ~ 1), family = cumulative_logit(), data = dat),
    "Random-effect scale"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + meta_known_V(V = rep(0.1, nrow(dat)))),
      family = cumulative_logit(),
      data = dat
    ),
    "meta_known_V"
  )
  expect_error(
    drmTMB(bf(mvbind(y, y) ~ x), family = cumulative_logit(), data = dat),
    "one ordered response"
  )
  expect_error(
    drmTMB(
      bf(cbind(success, failure) ~ x),
      family = cumulative_logit(),
      data = data.frame(success = 1:6, failure = 6:1, x = dat$x)
    ),
    "single ordered response"
  )
})

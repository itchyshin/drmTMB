emmeans_methods_control <- function(se = TRUE, keep_model_frame = TRUE) {
  drm_control(
    se = se,
    keep_model_frame = keep_model_frame,
    optimizer = list(eval.max = 120L, iter.max = 120L)
  )
}

emmeans_methods_data <- function(n = 60L) {
  x <- rep(c(-0.5, 0.5), length.out = n)
  habitat <- factor(rep(c("reef", "kelp", "sand"), length.out = n))
  data.frame(
    y = 0.2 + 0.4 * x + 0.3 * (habitat == "kelp") + stats::rnorm(n, sd = 0.1),
    x = x,
    habitat = habitat,
    id = factor(rep(seq_len(12L), length.out = n))
  )
}

expect_emmeans_mu_prediction_parity <- function(fit, dat, tolerance = 1e-10) {
  emm <- emmeans::emmeans(fit, ~habitat, at = list(x = 0))
  link <- summary(emm)
  response <- summary(emm, type = "response")
  grid <- data.frame(
    x = 0,
    habitat = factor(link$habitat, levels = levels(dat$habitat))
  )
  response_estimate <- if ("response" %in% names(response)) {
    response$response
  } else {
    response$emmean
  }

  expect_equal(
    link$emmean,
    unname(predict(fit, newdata = grid, dpar = "mu", type = "link")),
    tolerance = tolerance
  )
  expect_equal(
    response_estimate,
    unname(predict(fit, newdata = grid, dpar = "mu", type = "response")),
    tolerance = tolerance
  )
  expect_true(all(is.finite(link$SE)))
  expect_equal(link$df, rep(Inf, nrow(link)))
}

test_that("emmeans method matches fixed-effect mu predictions", {
  testthat::skip_if_not_installed("emmeans")
  set.seed(20260537)
  dat <- emmeans_methods_data()
  fit <- drmTMB(
    bf(y ~ x + habitat, sigma ~ 1),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )

  emm <- emmeans::emmeans(fit, ~habitat, at = list(x = 0))
  out <- summary(emm)
  grid <- data.frame(
    x = 0,
    habitat = factor(out$habitat, levels = levels(dat$habitat))
  )

  expect_equal(
    out$emmean,
    unname(predict(fit, newdata = grid, dpar = "mu", type = "link")),
    tolerance = 1e-10
  )
  expect_true(all(is.finite(out$SE)))
  expect_equal(out$df, rep(Inf, nrow(out)))
})

test_that("emmeans pairwise contrasts use the returned mu grid", {
  testthat::skip_if_not_installed("emmeans")
  set.seed(20260542)
  dat <- emmeans_methods_data()
  fit <- drmTMB(
    bf(y ~ x + habitat, sigma ~ 1),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )

  pairwise <- emmeans::emmeans(fit, pairwise ~ habitat, at = list(x = 0))
  means <- summary(pairwise$emmeans)
  contrasts <- summary(pairwise$contrasts)
  emmean_by_habitat <- stats::setNames(means$emmean, means$habitat)
  expected <- vapply(
    strsplit(as.character(contrasts$contrast), " - ", fixed = TRUE),
    function(parts) {
      emmean_by_habitat[[parts[[1L]]]] -
        emmean_by_habitat[[parts[[2L]]]]
    },
    numeric(1)
  )

  expect_equal(contrasts$estimate, expected, tolerance = 1e-10)
  expect_true(all(is.finite(contrasts$SE)))
  expect_equal(contrasts$df, rep(Inf, nrow(contrasts)))
})

test_that("emmeans method uses default numeric covariate reduction", {
  testthat::skip_if_not_installed("emmeans")
  set.seed(20260547)
  dat <- emmeans_methods_data(n = 75L)
  dat$x <- seq(0.15, 1.35, length.out = nrow(dat))
  dat$y <- 0.2 +
    0.4 * dat$x +
    0.3 * (dat$habitat == "kelp") -
    0.1 * (dat$habitat == "sand") +
    stats::rnorm(nrow(dat), sd = 0.1)
  fit <- drmTMB(
    bf(y ~ x + habitat, sigma ~ 1),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )

  emm <- emmeans::emmeans(fit, ~habitat)
  link <- summary(emm)
  grid <- data.frame(
    x = mean(dat$x),
    habitat = factor(link$habitat, levels = levels(dat$habitat))
  )

  expect_equal(
    link$emmean,
    unname(predict(fit, newdata = grid, dpar = "mu", type = "link")),
    tolerance = 1e-10
  )
  expect_true(all(is.finite(link$SE)))
  expect_equal(link$df, rep(Inf, nrow(link)))
})

test_that("emmeans method honors custom numeric covariate reduction", {
  testthat::skip_if_not_installed("emmeans")
  set.seed(20260549)
  dat <- emmeans_methods_data(n = 81L)
  dat$x <- c(rep(-0.75, 21L), seq(0.05, 2.05, length.out = 60L))
  dat$y <- 0.2 +
    0.5 * dat$x +
    0.25 * (dat$habitat == "kelp") -
    0.15 * (dat$habitat == "sand") +
    stats::rnorm(nrow(dat), sd = 0.15)
  fit <- drmTMB(
    bf(y ~ x + habitat, sigma ~ 1),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )

  emm <- emmeans::emmeans(fit, ~habitat, cov.reduce = stats::median)
  link <- summary(emm)
  grid <- data.frame(
    x = stats::median(dat$x),
    habitat = factor(link$habitat, levels = levels(dat$habitat))
  )

  expect_equal(
    link$emmean,
    unname(predict(fit, newdata = grid, dpar = "mu", type = "link")),
    tolerance = 1e-10
  )
  expect_true(all(is.finite(link$SE)))
  expect_equal(link$df, rep(Inf, nrow(link)))
})

test_that("emmeans method can average over unreduced numeric covariate levels", {
  testthat::skip_if_not_installed("emmeans")
  set.seed(20260550)
  dat <- data.frame(
    x = rep(c(-0.5, 0.25, 1.5), times = 9L),
    habitat = factor(rep(c("reef", "kelp", "sand"), each = 9L))
  )
  dat$y <- 0.2 +
    0.45 * dat$x +
    0.25 * (dat$habitat == "kelp") -
    0.12 * (dat$habitat == "sand") +
    stats::rnorm(nrow(dat), sd = 0.05)
  fit <- drmTMB(
    bf(y ~ x + habitat, sigma ~ 1),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )

  emm <- emmeans::emmeans(fit, ~habitat, cov.reduce = FALSE)
  link <- summary(emm)
  grid <- expand.grid(
    x = sort(unique(dat$x)),
    habitat = factor(link$habitat, levels = levels(dat$habitat))
  )
  predicted <- stats::aggregate(
    predict(fit, newdata = grid, dpar = "mu", type = "link"),
    list(habitat = grid$habitat),
    mean
  )
  predicted <- predicted[match(as.character(link$habitat), predicted$habitat), ]

  expect_equal(link$emmean, unname(predicted$x), tolerance = 1e-10)
  expect_true(all(is.finite(link$SE)))
  expect_equal(link$df, rep(Inf, nrow(link)))
})

test_that("emmeans method honors multiple explicit numeric at values", {
  testthat::skip_if_not_installed("emmeans")
  set.seed(20260551)
  dat <- emmeans_methods_data(n = 90L)
  dat$y <- 0.2 +
    0.4 * dat$x +
    0.3 * (dat$habitat == "kelp") -
    0.1 * (dat$habitat == "sand") +
    stats::rnorm(nrow(dat), sd = 0.1)
  fit <- drmTMB(
    bf(y ~ x + habitat, sigma ~ 1),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )

  emm <- emmeans::emmeans(
    fit,
    ~ habitat | x,
    at = list(x = c(-0.25, 0.75))
  )
  link <- summary(emm)
  grid <- data.frame(
    x = link$x,
    habitat = factor(link$habitat, levels = levels(dat$habitat))
  )

  expect_equal(
    link$emmean,
    unname(predict(fit, newdata = grid, dpar = "mu", type = "link")),
    tolerance = 1e-10
  )
  expect_true(all(is.finite(link$SE)))
  expect_equal(link$df, rep(Inf, nrow(link)))
})

test_that("emmeans response scale follows the fitted mu inverse link", {
  testthat::skip_if_not_installed("emmeans")
  set.seed(20260538)
  dat <- emmeans_methods_data(n = 75L)
  lambda <- exp(0.2 + 0.4 * dat$x + 0.3 * (dat$habitat == "kelp"))
  dat$count <- stats::rpois(nrow(dat), lambda = lambda)
  fit <- drmTMB(
    bf(count ~ x + habitat),
    family = stats::poisson(link = "log"),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )

  emm <- emmeans::emmeans(fit, ~habitat, at = list(x = 0))
  link <- summary(emm)
  response <- summary(emm, type = "response")
  grid <- data.frame(
    x = 0,
    habitat = factor(link$habitat, levels = levels(dat$habitat))
  )
  eta <- unname(predict(fit, newdata = grid, dpar = "mu", type = "link"))
  mu <- unname(predict(fit, newdata = grid, dpar = "mu", type = "response"))

  expect_equal(link$emmean, eta, tolerance = 1e-10)
  expect_equal(response$response, mu, tolerance = 1e-10)
})

test_that("emmeans type argument can request response-scale mu summaries", {
  testthat::skip_if_not_installed("emmeans")
  set.seed(20260548)
  dat <- emmeans_methods_data(n = 90L)
  eta <- 0.1 +
    0.4 * dat$x +
    0.3 * (dat$habitat == "kelp") -
    0.1 * (dat$habitat == "sand")
  dat$count <- stats::rpois(nrow(dat), lambda = exp(eta))
  fit <- drmTMB(
    bf(count ~ x + habitat),
    family = stats::poisson(link = "log"),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )

  link <- summary(emmeans::emmeans(
    fit,
    ~habitat,
    at = list(x = 0),
    type = "link"
  ))
  response <- summary(
    emmeans::emmeans(fit, ~habitat, at = list(x = 0), type = "response")
  )
  grid <- data.frame(
    x = 0,
    habitat = factor(link$habitat, levels = levels(dat$habitat))
  )

  expect_equal(
    link$emmean,
    unname(predict(fit, newdata = grid, dpar = "mu", type = "link")),
    tolerance = 1e-10
  )
  expect_equal(
    response$response,
    unname(predict(fit, newdata = grid, dpar = "mu", type = "response")),
    tolerance = 1e-10
  )
  expect_equal(response$df, rep(Inf, nrow(response)))
})

test_that("emmeans method carries mu offsets into the returned grid", {
  testthat::skip_if_not_installed("emmeans")
  set.seed(20260543)
  dat <- emmeans_methods_data(n = 72L)
  dat$exposure <- rep(c(1.0, 1.7, 2.3), length.out = nrow(dat))
  eta <- -0.2 +
    0.35 * dat$x +
    0.25 * (dat$habitat == "kelp") -
    0.10 * (dat$habitat == "sand") +
    log(dat$exposure)
  dat$count <- stats::rpois(nrow(dat), lambda = exp(eta))
  fit <- drmTMB(
    bf(count ~ x + habitat + offset(log(exposure))),
    family = stats::poisson(link = "log"),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )

  emm <- emmeans::emmeans(fit, ~habitat, at = list(x = 0, exposure = 2))
  link <- summary(emm)
  response <- summary(emm, type = "response")
  grid <- data.frame(
    x = 0,
    habitat = factor(link$habitat, levels = levels(dat$habitat)),
    exposure = 2
  )

  expect_equal(
    link$emmean,
    unname(predict(fit, newdata = grid, dpar = "mu", type = "link")),
    tolerance = 1e-10
  )
  expect_equal(
    response$response,
    unname(predict(fit, newdata = grid, dpar = "mu", type = "response")),
    tolerance = 1e-10
  )
  expect_true(all(is.finite(link$SE)))
  expect_equal(link$df, rep(Inf, nrow(link)))
})

test_that("emmeans method carries transformed mu predictors into the grid", {
  testthat::skip_if_not_installed("emmeans")
  set.seed(20260545)
  dat <- emmeans_methods_data(n = 90L)
  dat$size <- exp(seq(log(0.8), log(2.4), length.out = nrow(dat)))
  eta <- 0.1 +
    0.5 * log(dat$size) +
    0.25 * (dat$habitat == "kelp") -
    0.10 * (dat$habitat == "sand")
  dat$y <- eta + stats::rnorm(nrow(dat), sd = 0.1)
  fit <- drmTMB(
    bf(y ~ log(size) + habitat, sigma ~ 1),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )

  emm <- emmeans::emmeans(fit, ~habitat, at = list(size = 1.5))
  link <- summary(emm)
  response <- summary(emm, type = "response")
  grid <- data.frame(
    size = 1.5,
    habitat = factor(link$habitat, levels = levels(dat$habitat))
  )

  expect_equal(
    link$emmean,
    unname(predict(fit, newdata = grid, dpar = "mu", type = "link")),
    tolerance = 1e-10
  )
  expect_equal(
    response$emmean,
    unname(predict(fit, newdata = grid, dpar = "mu", type = "response")),
    tolerance = 1e-10
  )
  expect_true(all(is.finite(link$SE)))
  expect_equal(link$df, rep(Inf, nrow(link)))
})

test_that("emmeans response scale handles logit mu families", {
  testthat::skip_if_not_installed("emmeans")
  set.seed(20260540)
  dat <- emmeans_methods_data(n = 90L)
  mu <- stats::plogis(-0.2 + 0.5 * dat$x + 0.4 * (dat$habitat == "kelp"))
  sigma <- 0.35
  dat$prop <- stats::rbeta(
    nrow(dat),
    shape1 = mu / sigma^2,
    shape2 = (1 - mu) / sigma^2
  )
  fit <- drmTMB(
    bf(prop ~ x + habitat, sigma ~ 1),
    family = beta(),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )

  emm <- emmeans::emmeans(fit, ~habitat, at = list(x = 0))
  link <- summary(emm)
  response <- summary(emm, type = "response")
  grid <- data.frame(
    x = 0,
    habitat = factor(link$habitat, levels = levels(dat$habitat))
  )
  eta <- unname(predict(fit, newdata = grid, dpar = "mu", type = "link"))
  fitted_mu <- unname(
    predict(fit, newdata = grid, dpar = "mu", type = "response")
  )

  expect_equal(link$emmean, eta, tolerance = 1e-10)
  expect_equal(response$response, fitted_mu, tolerance = 1e-10)
})

test_that("emmeans method covers remaining admitted univariate families", {
  testthat::skip_if_not_installed("emmeans")
  set.seed(20260541)
  dat <- emmeans_methods_data(n = 96L)
  eta <- 0.15 +
    0.45 * dat$x +
    0.25 * (dat$habitat == "kelp") -
    0.10 * (dat$habitat == "sand")

  dat$student_y <- eta + 0.20 * stats::rt(nrow(dat), df = 7)
  student_fit <- drmTMB(
    bf(student_y ~ x + habitat, sigma ~ 1),
    family = student(),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )
  expect_emmeans_mu_prediction_parity(student_fit, dat)

  dat$lognormal_y <- exp(eta + stats::rnorm(nrow(dat), sd = 0.15))
  lognormal_fit <- drmTMB(
    bf(lognormal_y ~ x + habitat, sigma ~ 1),
    family = lognormal(),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )
  expect_emmeans_mu_prediction_parity(lognormal_fit, dat)

  gamma_mu <- exp(eta)
  dat$gamma_y <- stats::rgamma(
    nrow(dat),
    shape = 4,
    scale = gamma_mu / 4
  )
  gamma_fit <- drmTMB(
    bf(gamma_y ~ x + habitat, sigma ~ 1),
    family = stats::Gamma(link = "log"),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )
  expect_emmeans_mu_prediction_parity(gamma_fit, dat)

  count_mu <- exp(eta)
  dat$count <- stats::rnbinom(nrow(dat), size = 4, mu = count_mu)
  nbinom_fit <- drmTMB(
    bf(count ~ x + habitat, sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )
  expect_emmeans_mu_prediction_parity(nbinom_fit, dat)

  p0 <- stats::dnbinom(0, size = 4, mu = count_mu)
  dat$positive_count <- stats::qnbinom(
    p0 + stats::runif(nrow(dat)) * (1 - p0),
    size = 4,
    mu = count_mu
  )
  truncated_fit <- drmTMB(
    bf(positive_count ~ x + habitat, sigma ~ 1),
    family = truncated_nbinom2(),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )
  expect_emmeans_mu_prediction_parity(truncated_fit, dat)

  prob <- stats::plogis(eta)
  trials <- rep(12:17, length.out = nrow(dat))
  phi <- 18
  sampled_prob <- stats::rbeta(
    nrow(dat),
    shape1 = prob * phi,
    shape2 = (1 - prob) * phi
  )
  dat$success <- stats::rbinom(nrow(dat), size = trials, prob = sampled_prob)
  dat$failure <- trials - dat$success
  beta_binomial_fit <- drmTMB(
    bf(cbind(success, failure) ~ x + habitat, sigma ~ 1),
    family = beta_binomial(),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )
  expect_emmeans_mu_prediction_parity(beta_binomial_fit, dat)
})

test_that("emmeans method rejects unsupported drmTMB paths", {
  testthat::skip_if_not_installed("emmeans")
  set.seed(20260539)
  dat <- emmeans_methods_data()
  fit <- drmTMB(
    bf(y ~ x + habitat, sigma ~ x),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )

  expect_error(
    emmeans::emmeans(fit, ~habitat, at = list(x = 0), dpar = "sigma"),
    "dpar = \"mu\""
  )

  transformed_dat <- dat
  transformed_dat$positive_y <- exp(transformed_dat$y + 1)
  transformed_fit <- drmTMB(
    bf(log(positive_y) ~ x + habitat, sigma ~ 1),
    data = transformed_dat,
    control = emmeans_methods_control(se = TRUE)
  )
  transformed_error <- expect_error(
    emmeans::emmeans(transformed_fit, ~habitat, at = list(x = 0)),
    "transformed responses"
  )
  expect_match(conditionMessage(transformed_error), "prediction_grid\\(\\)")

  no_se_fit <- drmTMB(
    bf(y ~ x + habitat, sigma ~ 1),
    data = dat,
    control = emmeans_methods_control(se = FALSE)
  )
  expect_error(
    emmeans::emmeans(no_se_fit, ~habitat, at = list(x = 0)),
    "Refit with"
  )

  no_frame_fit <- drmTMB(
    bf(y ~ x + habitat, sigma ~ 1),
    data = dat,
    control = emmeans_methods_control(keep_model_frame = FALSE)
  )
  expect_error(
    emmeans::emmeans(no_frame_fit, ~habitat, at = list(x = 0)),
    "keep_model_frame = TRUE"
  )

  zi_dat <- dat
  eta <- 0.2 +
    0.4 * zi_dat$x +
    0.25 * (zi_dat$habitat == "kelp") -
    0.1 * (zi_dat$habitat == "sand")
  zi_dat$count <- stats::rpois(nrow(zi_dat), lambda = exp(eta))
  zi_dat$count[seq(1L, nrow(zi_dat), by = 5L)] <- 0L
  zi_fit <- drmTMB(
    bf(count ~ x + habitat, zi ~ habitat),
    family = stats::poisson(link = "log"),
    data = zi_dat,
    control = emmeans_methods_control(se = TRUE)
  )
  zi_error <- expect_error(
    emmeans::emmeans(zi_fit, ~habitat, at = list(x = 0)),
    "zi_poisson"
  )
  expect_match(conditionMessage(zi_error), "prediction_grid\\(\\)")

  zi_nb_dat <- dat
  zi_nb_eta <- 0.3 +
    0.4 * zi_nb_dat$x +
    0.25 * (zi_nb_dat$habitat == "kelp") -
    0.1 * (zi_nb_dat$habitat == "sand")
  zi_nb_dat$count <- stats::rnbinom(
    nrow(zi_nb_dat),
    size = 4,
    mu = exp(zi_nb_eta)
  )
  zi_nb_dat$count[seq(1L, nrow(zi_nb_dat), by = 6L)] <- 0L
  zi_nb_fit <- drmTMB(
    bf(count ~ x + habitat, sigma ~ 1, zi ~ habitat),
    family = nbinom2(),
    data = zi_nb_dat,
    control = emmeans_methods_control(se = TRUE)
  )
  zi_nb_error <- expect_error(
    emmeans::emmeans(zi_nb_fit, ~habitat, at = list(x = 0)),
    "zi_nbinom2"
  )
  expect_match(conditionMessage(zi_nb_error), "prediction_grid\\(\\)")

  hurdle_dat <- dat
  hurdle_eta <- 0.3 +
    0.4 * hurdle_dat$x +
    0.2 * (hurdle_dat$habitat == "kelp") -
    0.1 * (hurdle_dat$habitat == "sand")
  positive_count <- stats::rnbinom(
    nrow(hurdle_dat),
    size = 4,
    mu = exp(hurdle_eta)
  )
  positive_count[positive_count == 0L] <- 1L
  hurdle_zero <- stats::rbinom(
    nrow(hurdle_dat),
    size = 1L,
    prob = stats::plogis(-1.1 + 0.2 * (hurdle_dat$habitat == "sand"))
  )
  hurdle_dat$count <- ifelse(hurdle_zero == 1L, 0L, positive_count)
  hurdle_fit <- drmTMB(
    bf(count ~ x + habitat, hu ~ habitat),
    family = truncated_nbinom2(),
    data = hurdle_dat,
    control = emmeans_methods_control(se = TRUE)
  )
  hurdle_error <- expect_error(
    emmeans::emmeans(hurdle_fit, ~habitat, at = list(x = 0)),
    "hurdle_nbinom2"
  )
  expect_match(conditionMessage(hurdle_error), "prediction_grid\\(\\)")

  ordinal_dat <- dat
  ordinal_eta <- -0.1 +
    0.6 * ordinal_dat$x +
    0.25 * (ordinal_dat$habitat == "kelp") -
    0.15 * (ordinal_dat$habitat == "sand")
  ordinal_latent <- ordinal_eta + stats::rlogis(nrow(ordinal_dat))
  ordinal_dat$ordinal <- cut(
    ordinal_latent,
    breaks = c(-Inf, -0.6, 0.4, Inf),
    labels = c("low", "mid", "high"),
    ordered_result = TRUE
  )
  ordinal_fit <- drmTMB(
    bf(ordinal ~ x + habitat),
    family = cumulative_logit(),
    data = ordinal_dat,
    control = emmeans_methods_control(se = TRUE)
  )
  ordinal_error <- expect_error(
    emmeans::emmeans(ordinal_fit, ~habitat, at = list(x = 0)),
    "cumulative_logit"
  )
  expect_match(conditionMessage(ordinal_error), "prediction_grid\\(\\)")

  biv_dat <- dat
  biv_dat$y1 <- 0.2 +
    0.4 * biv_dat$x +
    0.2 * (biv_dat$habitat == "kelp") +
    stats::rnorm(nrow(biv_dat), sd = 0.2)
  biv_dat$y2 <- -0.1 +
    0.3 * biv_dat$x -
    0.15 * (biv_dat$habitat == "sand") +
    stats::rnorm(nrow(biv_dat), sd = 0.25)
  biv_fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + habitat,
      mu2 = y2 ~ x + habitat,
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = biv_dat,
    control = emmeans_methods_control(se = TRUE)
  )
  biv_error <- expect_error(
    emmeans::emmeans(biv_fit, ~habitat, at = list(x = 0)),
    "biv_gaussian"
  )
  expect_match(conditionMessage(biv_error), "prediction_grid\\(\\)")

  random_fit <- drmTMB(
    bf(y ~ x + habitat + (1 | id), sigma ~ 1),
    data = dat,
    control = emmeans_methods_control(se = TRUE)
  )
  expect_error(
    emmeans::emmeans(random_fit, ~habitat, at = list(x = 0)),
    "mu random effects"
  )
})

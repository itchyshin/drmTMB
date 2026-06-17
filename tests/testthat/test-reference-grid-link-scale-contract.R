reference_grid_control <- function() {
  drm_control(
    se = FALSE,
    optimizer = list(eval.max = 120L, iter.max = 120L)
  )
}

manual_response_from_link <- function(fit, dpar, eta) {
  link <- drmTMB:::drm_dpar_link(fit, dpar)
  switch(
    link,
    identity = eta,
    log = exp(eta),
    logit = stats::plogis(eta),
    logm2 = 2 + exp(eta),
    atanh_guarded = 0.999999 * tanh(eta),
    atanh_re_guarded = 0.999999 * tanh(eta),
    stop("Unhandled link in test helper: ", link, call. = FALSE)
  )
}

expect_reference_grid_link_contract <- function(fit, grid, dpar = NULL) {
  expect_s3_class(grid, "drm_prediction_grid")
  info <- attr(grid, "prediction_grid")
  expect_type(info, "list")
  expect_equal(info$n_grid_rows, nrow(grid))
  expect_match(info$margin, "^(mean_reference|empirical)$")

  if (is.null(dpar)) {
    dpar <- names(fit$coefficients)
  }
  link <- predict_parameters(
    fit,
    newdata = grid,
    dpar = dpar,
    type = "link"
  )
  response <- predict_parameters(
    fit,
    newdata = grid,
    dpar = dpar,
    type = "response"
  )

  core <- c("row", "row_label", "dpar", "component")
  expect_equal(response[core], link[core])
  expect_equal(link$type, rep("link", nrow(link)))
  expect_equal(response$type, rep("response", nrow(response)))
  expect_equal(unique(response$conf.status), "not_requested")
  expect_equal(unique(response$interval_source), "not_available")

  expected <- mapply(
    function(one_dpar, eta) {
      manual_response_from_link(fit, one_dpar, eta)
    },
    link$dpar,
    link$estimate,
    USE.NAMES = FALSE
  )
  expect_equal(response$estimate, expected, tolerance = 1e-10)
}

test_that("reference grids preserve link-response contracts for implemented univariate families", {
  set.seed(20260525)
  n <- 72
  x <- seq(-1.2, 1.2, length.out = n)
  z <- rep(c(-0.75, 0.25, 1), length.out = n)
  habitat <- factor(rep(c("reef", "kelp", "sand"), length.out = n))
  control <- reference_grid_control()

  gaussian_dat <- data.frame(
    y = 0.4 + 0.6 * x + 0.2 * (habitat == "kelp") + stats::rnorm(n, sd = 0.15),
    x = x,
    z = z,
    habitat = habitat
  )
  gaussian_fit <- drmTMB(
    bf(y ~ x + habitat, sigma ~ z),
    family = gaussian(),
    data = gaussian_dat,
    control = control
  )
  gaussian_grid <- prediction_grid(
    gaussian_fit,
    focal = "x",
    at = list(x = c(-0.5, 0.5)),
    condition = list(habitat = "reef")
  )
  expect_reference_grid_link_contract(gaussian_fit, gaussian_grid)

  student_dat <- data.frame(
    y = 0.2 + 0.5 * x + stats::rt(n, df = 7),
    x = x,
    z = z
  )
  student_fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ 1),
    family = student(),
    data = student_dat,
    control = control
  )
  student_grid <- prediction_grid(
    student_fit,
    focal = "x",
    at = list(x = c(-0.5, 0.5))
  )
  expect_reference_grid_link_contract(student_fit, student_grid)

  lognormal_dat <- data.frame(
    y = exp(0.2 + 0.35 * x + stats::rnorm(n, sd = 0.12)),
    x = x,
    z = z
  )
  lognormal_fit <- drmTMB(
    bf(y ~ x, sigma ~ z),
    family = lognormal(),
    data = lognormal_dat,
    control = control
  )
  lognormal_grid <- prediction_grid(
    lognormal_fit,
    focal = "x",
    at = list(x = c(-0.5, 0.5))
  )
  expect_reference_grid_link_contract(lognormal_fit, lognormal_grid)

  gamma_mu <- exp(0.3 + 0.4 * x)
  gamma_sigma <- 0.45
  gamma_dat <- data.frame(
    y = stats::rgamma(
      n,
      shape = 1 / gamma_sigma^2,
      scale = gamma_mu * gamma_sigma^2
    ),
    x = x,
    z = z
  )
  gamma_fit <- drmTMB(
    bf(y ~ x, sigma ~ z),
    family = stats::Gamma(link = "log"),
    data = gamma_dat,
    control = control
  )
  gamma_grid <- prediction_grid(
    gamma_fit,
    focal = "x",
    at = list(x = c(-0.5, 0.5))
  )
  expect_reference_grid_link_contract(gamma_fit, gamma_grid)

  beta_mu <- stats::plogis(-0.1 + 0.5 * x)
  beta_sigma <- 0.45
  beta_dat <- data.frame(
    y = stats::rbeta(
      n,
      shape1 = beta_mu / beta_sigma^2,
      shape2 = (1 - beta_mu) / beta_sigma^2
    ),
    x = x,
    z = z
  )
  beta_fit <- drmTMB(
    bf(y ~ x, sigma ~ z),
    family = beta(),
    data = beta_dat,
    control = control
  )
  beta_grid <- prediction_grid(
    beta_fit,
    focal = "x",
    at = list(x = c(-0.5, 0.5))
  )
  expect_reference_grid_link_contract(beta_fit, beta_grid)
})

test_that("reference grids preserve link-response contracts for counts, proportions, ordinal, and bivariate fits", {
  set.seed(20260526)
  n <- 72
  x <- seq(-1.2, 1.2, length.out = n)
  z <- rep(c(-0.75, 0.25, 1), length.out = n)
  habitat <- factor(rep(c("reef", "kelp", "sand"), length.out = n))
  control <- reference_grid_control()

  trials <- rep(c(8L, 10L, 12L), length.out = n)
  beta_binomial_mu <- stats::plogis(-0.15 + 0.5 * x)
  beta_binomial_dat <- data.frame(
    success = stats::rbinom(n, size = trials, prob = beta_binomial_mu),
    failure = trials,
    x = x,
    z = z
  )
  beta_binomial_dat$failure <- trials - beta_binomial_dat$success
  beta_binomial_fit <- drmTMB(
    bf(cbind(success, failure) ~ x, sigma ~ z),
    family = beta_binomial(),
    data = beta_binomial_dat,
    control = control
  )
  beta_binomial_grid <- prediction_grid(
    beta_binomial_fit,
    focal = "x",
    at = list(x = c(-0.5, 0.5))
  )
  expect_reference_grid_link_contract(beta_binomial_fit, beta_binomial_grid)

  ordinal_eta <- 0.8 * (habitat == "kelp") - 0.3 * x
  ordinal_cutpoints <- c(-0.6, 0.9)
  p1 <- stats::plogis(ordinal_cutpoints[[1L]] - ordinal_eta)
  p2 <- stats::plogis(ordinal_cutpoints[[2L]] - ordinal_eta) - p1
  ordinal_prob <- cbind(
    p1,
    p2,
    1 - stats::plogis(ordinal_cutpoints[[2L]] - ordinal_eta)
  )
  score <- vapply(
    seq_len(n),
    function(i) {
      sample(
        c("low", "medium", "high"),
        size = 1,
        prob = ordinal_prob[i, ]
      )
    },
    character(1)
  )
  score <- ordered(score, levels = c("low", "medium", "high"))
  ordinal_dat <- data.frame(score = score, x = x, habitat = habitat)
  ordinal_fit <- drmTMB(
    bf(score ~ x + habitat),
    family = cumulative_logit(),
    data = ordinal_dat,
    control = control
  )
  ordinal_grid <- prediction_grid(
    ordinal_fit,
    focal = "x",
    at = list(x = c(-0.5, 0.5)),
    condition = list(habitat = "reef")
  )
  expect_reference_grid_link_contract(ordinal_fit, ordinal_grid)

  poisson_dat <- data.frame(
    y = stats::rpois(n, lambda = exp(0.2 + 0.4 * x)),
    x = x
  )
  poisson_fit <- drmTMB(
    bf(y ~ x),
    family = stats::poisson(link = "log"),
    data = poisson_dat,
    control = control
  )
  poisson_grid <- prediction_grid(
    poisson_fit,
    focal = "x",
    at = list(x = c(-0.5, 0.5))
  )
  expect_reference_grid_link_contract(poisson_fit, poisson_grid)

  zip_dat <- poisson_dat
  zip_dat$habitat <- habitat
  zip_dat$y[habitat == "sand" & seq_len(n) %% 2L == 0L] <- 0L
  zip_fit <- drmTMB(
    bf(y ~ x, zi ~ habitat),
    family = stats::poisson(link = "log"),
    data = zip_dat,
    control = control
  )
  zip_grid <- prediction_grid(
    zip_fit,
    focal = "x",
    at = list(x = c(-0.5, 0.5)),
    condition = list(habitat = "reef")
  )
  expect_reference_grid_link_contract(zip_fit, zip_grid)

  nbinom_mu <- exp(0.3 + 0.4 * x)
  nbinom_sigma <- 0.55
  nbinom_dat <- data.frame(
    y = stats::rnbinom(n, size = 1 / nbinom_sigma^2, mu = nbinom_mu),
    x = x,
    z = z
  )
  nbinom_fit <- drmTMB(
    bf(y ~ x, sigma ~ z),
    family = nbinom2(),
    data = nbinom_dat,
    control = control
  )
  nbinom_grid <- prediction_grid(
    nbinom_fit,
    focal = "x",
    at = list(x = c(-0.5, 0.5))
  )
  expect_reference_grid_link_contract(nbinom_fit, nbinom_grid)

  trunc_dat <- nbinom_dat
  trunc_dat$y <- pmax(1L, trunc_dat$y)
  trunc_fit <- drmTMB(
    bf(y ~ x, sigma ~ z),
    family = truncated_nbinom2(),
    data = trunc_dat,
    control = control
  )
  trunc_grid <- prediction_grid(
    trunc_fit,
    focal = "x",
    at = list(x = c(-0.5, 0.5))
  )
  expect_reference_grid_link_contract(trunc_fit, trunc_grid)

  hurdle_dat <- trunc_dat
  hurdle_dat$habitat <- habitat
  hurdle_dat$y[seq(1, n, by = 5L)] <- 0L
  hurdle_fit <- drmTMB(
    bf(y ~ x, sigma ~ z, hu ~ habitat),
    family = truncated_nbinom2(),
    data = hurdle_dat,
    control = control
  )
  hurdle_grid <- prediction_grid(
    hurdle_fit,
    focal = "x",
    at = list(x = c(-0.5, 0.5)),
    condition = list(habitat = "reef")
  )
  expect_reference_grid_link_contract(hurdle_fit, hurdle_grid)

  zinb_dat <- nbinom_dat
  zinb_dat$habitat <- habitat
  zinb_dat$y[habitat == "sand" & seq_len(n) %% 2L == 0L] <- 0L
  zinb_fit <- drmTMB(
    bf(y ~ x, sigma ~ z, zi ~ habitat),
    family = nbinom2(),
    data = zinb_dat,
    control = control
  )
  zinb_grid <- prediction_grid(
    zinb_fit,
    focal = "x",
    at = list(x = c(-0.5, 0.5)),
    condition = list(habitat = "reef")
  )
  expect_reference_grid_link_contract(zinb_fit, zinb_grid)

  y1 <- 0.4 + 0.5 * x + stats::rnorm(n, sd = 0.25)
  y2 <- -0.2 +
    0.3 * x +
    0.35 * scale(y1)[, 1] +
    stats::rnorm(n, sd = 0.25)
  biv_dat <- data.frame(y1 = y1, y2 = y2, x = x, z = z)
  biv_fit <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~z,
      sigma2 = ~z,
      rho12 = ~x
    ),
    family = c(gaussian(), gaussian()),
    data = biv_dat,
    control = control
  )
  biv_grid <- prediction_grid(
    biv_fit,
    focal = "x",
    at = list(x = c(-0.5, 0.5))
  )
  expect_reference_grid_link_contract(biv_fit, biv_grid)
})

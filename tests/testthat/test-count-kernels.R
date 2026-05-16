count_kernel_eval_loglik <- function(fit, beta_mu, beta_sigma, beta_zi = NULL) {
  par <- fit$obj$par
  par[["beta_mu"]] <- beta_mu
  par[["beta_sigma"]] <- beta_sigma
  if (!is.null(beta_zi)) {
    par[["beta_zi"]] <- beta_zi
  }
  -fit$obj$fn(par)
}

test_that("nbinom2 high-count kernel matches stats::dnbinom()", {
  dat <- data.frame(y = c(0, 1, 20, 51, 120, 500))
  fit <- drmTMB(
    bf(y ~ 1, sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  mu <- 80
  sigma <- 0.75
  ll_independent <- sum(stats::dnbinom(
    dat$y,
    size = 1 / sigma^2,
    mu = mu,
    log = TRUE
  ))

  expect_equal(
    count_kernel_eval_loglik(fit, log(mu), log(sigma)),
    ll_independent,
    tolerance = 1e-6
  )
})

test_that("zero-truncated nbinom2 high-count kernel matches stats::dnbinom()", {
  dat <- data.frame(y = c(1, 20, 51, 120, 500))
  fit <- drmTMB(
    bf(y ~ 1, sigma ~ 1),
    family = truncated_nbinom2(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  mu <- 80
  sigma <- 0.75
  p0 <- stats::dnbinom(0, size = 1 / sigma^2, mu = mu)
  ll_independent <- sum(
    stats::dnbinom(dat$y, size = 1 / sigma^2, mu = mu, log = TRUE) -
      log1p(-p0)
  )

  expect_equal(
    count_kernel_eval_loglik(fit, log(mu), log(sigma)),
    ll_independent,
    tolerance = 1e-6
  )
})

test_that("hurdle nbinom2 high-count kernel matches independent calculation", {
  dat <- data.frame(y = c(0, 0, 1, 51, 120, 500))
  fit <- drmTMB(
    bf(y ~ 1, sigma ~ 1, hu ~ 1),
    family = truncated_nbinom2(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  mu <- 80
  sigma <- 0.75
  hu <- 0.25
  p0 <- stats::dnbinom(0, size = 1 / sigma^2, mu = mu)
  positive_ll <- stats::dnbinom(
    dat$y,
    size = 1 / sigma^2,
    mu = mu,
    log = TRUE
  ) -
    log1p(-p0)
  ll_independent <- sum(ifelse(
    dat$y == 0,
    log(hu),
    log1p(-hu) + positive_ll
  ))

  expect_equal(
    count_kernel_eval_loglik(fit, log(mu), log(sigma), stats::qlogis(hu)),
    ll_independent,
    tolerance = 1e-6
  )
})

test_that("zero-inflated nbinom2 high-count kernel matches independent calculation", {
  dat <- data.frame(y = c(0, 0, 1, 51, 120, 500))
  fit <- drmTMB(
    bf(y ~ 1, sigma ~ 1, zi ~ 1),
    family = nbinom2(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  mu <- 80
  sigma <- 0.75
  zi <- 0.25
  nb_ll <- stats::dnbinom(dat$y, size = 1 / sigma^2, mu = mu, log = TRUE)
  ll_independent <- sum(ifelse(
    dat$y == 0,
    log(zi + (1 - zi) * exp(nb_ll)),
    log1p(-zi) + nb_ll
  ))

  expect_equal(
    count_kernel_eval_loglik(fit, log(mu), log(sigma), stats::qlogis(zi)),
    ll_independent,
    tolerance = 1e-6
  )
})

test_that("zero-inflated nbinom2 keeps the high-count near-Poisson limit stable", {
  dat <- data.frame(y = c(0, 0, 1, 12, 51))
  fit <- drmTMB(
    bf(y ~ 1, sigma ~ 1, zi ~ 1),
    family = nbinom2(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  mu <- 5
  zi <- 0.3
  eta_zi <- stats::qlogis(zi)
  pois_ll <- stats::dpois(dat$y, lambda = mu, log = TRUE)
  ll_independent <- sum(ifelse(
    dat$y == 0,
    log(zi + (1 - zi) * exp(pois_ll)),
    log1p(-zi) + pois_ll
  ))

  expect_equal(
    count_kernel_eval_loglik(fit, log(mu), -20, eta_zi),
    ll_independent,
    tolerance = 1e-6
  )
  expect_true(is.finite(fit$obj$fn(fit$obj$par)))
})

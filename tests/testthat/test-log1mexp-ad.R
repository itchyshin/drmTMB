# #1472: drm_log1mexp() records both CondExp branches. For a cloglog success
# with eta <= -40 the unselected branch used to be log(0), so fn() and gr()
# stayed finite while he() was NaN. The same composition is the zero-truncated
# NB2 log(1 - p0) term. Both are checked through the compiled objective. No Julia.

test_that("cloglog success at eta <= -40 has a finite gradient and Hessian (#1472)", {
  dat <- data.frame(y = rep(1, 5))
  fit <- drmTMB(
    bf(y ~ 1),
    family = stats::binomial(link = "cloglog"),
    data = dat,
    control = drm_control(se = FALSE)
  )
  for (eta in c(-30, -37, -40, -60)) {
    par <- fit$obj$par
    par[["beta_mu"]] <- eta
    nll <- fit$obj$fn(par)
    grad <- as.numeric(fit$obj$gr(par))
    hess <- fit$obj$he(par)
    expect_true(is.finite(nll), info = paste("fn", eta))
    expect_true(all(is.finite(grad)), info = paste("gr", eta))
    expect_true(all(is.finite(hess)), info = paste("he", eta))
    # log(mu) = log(1 - exp(-exp(eta))) ~ eta for large negative eta,
    # so the negative log-likelihood of five successes is about -5 * eta.
    expect_equal(nll, -5 * eta, tolerance = 1e-4, info = paste("value", eta))
  }

  # Failure rows do not multiply by log(mu). They stay finite too.
  dat0 <- data.frame(y = rep(0, 5))
  fit0 <- drmTMB(
    bf(y ~ 1),
    family = stats::binomial(link = "cloglog"),
    data = dat0,
    control = drm_control(se = FALSE)
  )
  par0 <- fit0$obj$par
  par0[["beta_mu"]] <- -60
  expect_true(all(is.finite(fit0$obj$he(par0))))
})

test_that("zero-truncated NB2 at eta_mu <= -38 has a finite Hessian (#1472)", {
  dat <- data.frame(y = c(1, 2, 4))
  fit <- drmTMB(
    bf(y ~ 1, sigma ~ 1),
    family = truncated_nbinom2(),
    data = dat,
    control = drm_control(se = FALSE, logsigma_clamp = NULL)
  )
  for (eta_mu in c(-37, -38, -44)) {
    par <- fit$obj$par
    par[["beta_mu"]] <- eta_mu
    par[["beta_sigma"]] <- 0
    expect_true(is.finite(fit$obj$fn(par)), info = paste("fn", eta_mu))
    expect_true(all(is.finite(fit$obj$gr(par))), info = paste("gr", eta_mu))
    expect_true(all(is.finite(fit$obj$he(par))), info = paste("he", eta_mu))
  }
})

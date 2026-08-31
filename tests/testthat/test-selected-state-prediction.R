# Stored conditional predictions must not depend on the Hessian stencil used
# to calculate standard errors. Dense Gaussian conditioning is an independent
# oracle for the random-intercept cells below.
selected_state_fixture <- function() {
  set.seed(202608302L)
  labels <- c('z', 'a', 'm', 'b', 'x', 'c', 'w', 'd', 'v', 'e', 'u', 'f')
  g <- factor(rep(labels, each = 12L), levels = c('unused', rev(sort(labels))))
  x <- runif(length(g), -1, 1)
  b <- setNames(rnorm(length(labels), sd = 0.8), labels)
  y <- 0.3 + 0.6*x + b[as.character(g)] + rnorm(length(g), sd = exp(-0.5 + 0.15*x))
  data.frame(y, x, g)[sample.int(length(g)), , drop = FALSE]
}

selected_state_dense_mu <- function(fit, varying_scale) {
  dat <- fit$data
  X <- model.matrix(~ x, dat)
  S <- model.matrix(if (varying_scale) ~ x else ~ 1, dat)
  Z <- model.matrix(~ 0 + droplevels(g), dat)
  mu <- drop(X %*% fit$coefficients$mu)
  variance <- exp(2 * drop(S %*% fit$coefficients$sigma))
  stopifnot(length(fit$sdpars$mu) == 1L)
  sb2 <- unname(fit$sdpars$mu[[1L]])^2
  V <- diag(variance) + sb2 * tcrossprod(Z)
  as.numeric(mu + drop(sb2 * tcrossprod(Z) %*% solve(V, dat$y-mu)))
}

test_that('Gaussian conditional predictions use the selected state with SEs', {
  dat <- selected_state_fixture()
  for (varying in c(FALSE, TRUE)) {
    form <- if (varying) bf(y ~ x + (1 | g), sigma ~ x) else bf(y ~ x + (1 | g), sigma ~ 1)
    a <- drmTMB(form, data = dat)
    b <- drmTMB(form, data = dat, control = drm_control(se = FALSE))
    expect_equal(a$opt$par, b$opt$par, tolerance = 1e-12)
    expect_equal(a$coefficients, b$coefficients, tolerance = 1e-12)
    expect_equal(predict(a, dpar = 'mu'), predict(b, dpar = 'mu'), tolerance = 1e-12)
    expect_equal(as.numeric(predict(a, dpar = 'mu')), selected_state_dense_mu(a, varying), tolerance = 1e-8)
    expect_true(!is.null(a$sdr))
  }
})

test_that('selected-state extraction preserves fixed-effect and REML neighbours', {
  dat <- selected_state_fixture()
  fe <- bf(y ~ x, sigma ~ x)
  a <- drmTMB(fe, data = dat)
  b <- drmTMB(fe, data = dat, control = drm_control(se = FALSE))
  expect_equal(a$opt$par, b$opt$par, tolerance = 1e-12)
  expect_equal(predict(a, dpar = 'mu'), predict(b, dpar = 'mu'), tolerance = 1e-12)
  re <- bf(y ~ x + (1 | g), sigma ~ 1)
  a <- drmTMB(re, data = dat, REML = TRUE)
  b <- drmTMB(re, data = dat, REML = TRUE, control = drm_control(se = FALSE))
  expect_equal(a$opt$par, b$opt$par, tolerance = 1e-12)
  expect_equal(a$coefficients, b$coefficients, tolerance = 1e-12)
  expect_equal(predict(a, dpar = 'mu'), predict(b, dpar = 'mu'), tolerance = 1e-12)
  expect_equal(as.numeric(predict(a, dpar = 'mu')), selected_state_dense_mu(a, FALSE), tolerance = 1e-8)
  expect_true(!is.null(a$sdr))
})

test_that('selected-state oracle ignores a damaged mutable Hessian state', {
  dat <- selected_state_fixture()
  fit <- drmTMB(bf(y ~ x + (1 | g), sigma ~ x), data = dat)
  selected_before <- selected_tmb_par_list(fit)
  mutable_before <- fit$obj$env$parList(fit$opt$par)

  fit$obj$env$last.par <- fit$obj$env$last.par +
    seq_along(fit$obj$env$last.par) * 1e-3

  mutable_after <- fit$obj$env$parList(fit$opt$par)
  expect_false(isTRUE(all.equal(mutable_after, mutable_before, tolerance = 0)))
  expect_equal(selected_tmb_par_list(fit), selected_before, tolerance = 0)
})

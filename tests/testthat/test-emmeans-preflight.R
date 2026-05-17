emmeans_preflight_control <- function(se = TRUE) {
  drm_control(
    se = se,
    optimizer = list(eval.max = 120L, iter.max = 120L)
  )
}

emmeans_preflight_data <- function(n = 54L) {
  x <- seq(-1.2, 1.2, length.out = n)
  habitat <- factor(rep(c("reef", "kelp", "sand"), length.out = n))
  data.frame(
    y = 0.2 + 0.5 * x + 0.2 * (habitat == "kelp") + stats::rnorm(n, sd = 0.12),
    x = x,
    habitat = habitat,
    id = factor(rep(seq_len(9L), length.out = n))
  )
}

test_that("emmeans mu basis preflight returns the fixed-effect basis", {
  set.seed(20260529)
  dat <- emmeans_preflight_data()
  fit <- drmTMB(
    bf(y ~ x + habitat, sigma ~ x),
    data = dat,
    control = emmeans_preflight_control(se = TRUE)
  )
  newdata <- data.frame(
    x = c(-0.5, 0.5),
    habitat = factor(c("reef", "sand"), levels = levels(dat$habitat))
  )

  out <- drmTMB:::drm_emmeans_mu_basis(
    fit,
    newdata = newdata,
    type = "response"
  )

  expect_equal(out$dpar, "mu")
  expect_equal(out$type, "response")
  expect_equal(out$basis$dpar, "mu")
  expect_equal(colnames(out$basis$X), names(coef(fit, "mu")))
  expect_equal(
    out$basis$eta,
    unname(predict(fit, newdata = newdata, dpar = "mu", type = "link"))
  )
  expect_equal(dim(out$basis$V), rep(length(coef(fit, "mu")), 2L))
})

test_that("emmeans mu basis preflight rejects unsupported targets", {
  set.seed(20260530)
  dat <- emmeans_preflight_data()
  fit <- drmTMB(
    bf(y ~ x + habitat, sigma ~ x),
    data = dat,
    control = emmeans_preflight_control(se = TRUE)
  )
  newdata <- data.frame(
    x = c(-0.5, 0.5),
    habitat = factor(c("reef", "sand"), levels = levels(dat$habitat))
  )

  expect_error(
    drmTMB:::drm_emmeans_mu_basis(fit, newdata = newdata, dpar = "sigma"),
    "dpar = \"mu\""
  )

  transformed_dat <- dat
  transformed_dat$positive_y <- exp(transformed_dat$y + 1)
  transformed_fit <- drmTMB(
    bf(log(positive_y) ~ x + habitat, sigma ~ 1),
    data = transformed_dat,
    control = emmeans_preflight_control(se = TRUE)
  )
  expect_error(
    drmTMB:::drm_emmeans_mu_basis(transformed_fit, newdata = newdata),
    "transformed responses"
  )

  no_se_fit <- drmTMB(
    bf(y ~ x + habitat),
    data = dat,
    control = emmeans_preflight_control(se = FALSE)
  )
  expect_error(
    drmTMB:::drm_emmeans_mu_basis(no_se_fit, newdata = newdata),
    "Refit with"
  )
})

test_that("emmeans mu basis preflight rejects unsupported model structures", {
  set.seed(20260531)
  dat <- emmeans_preflight_data()
  newdata <- data.frame(
    x = c(-0.5, 0.5),
    habitat = factor(c("reef", "sand"), levels = levels(dat$habitat))
  )

  zi_dat <- transform(dat, y = stats::rpois(nrow(dat), lambda = exp(0.2 + x)))
  zi_dat$y[seq(1L, nrow(zi_dat), by = 4L)] <- 0L
  zi_fit <- drmTMB(
    bf(y ~ x + habitat, zi ~ habitat),
    family = stats::poisson(link = "log"),
    data = zi_dat,
    control = emmeans_preflight_control(se = TRUE)
  )
  expect_error(
    drmTMB:::drm_emmeans_mu_basis(zi_fit, newdata = newdata),
    "zi_poisson"
  )

  random_fit <- drmTMB(
    bf(y ~ x + habitat + (1 | id)),
    data = dat,
    control = emmeans_preflight_control(se = TRUE)
  )
  expect_error(
    drmTMB:::drm_emmeans_mu_basis(random_fit, newdata = newdata),
    "mu random effects"
  )
})

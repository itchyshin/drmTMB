fixed_effect_basis_control <- function(se = TRUE) {
  drm_control(
    se = se,
    optimizer = list(eval.max = 120L, iter.max = 120L)
  )
}

fixed_effect_basis_data <- function(n = 60L) {
  x <- seq(-1.2, 1.2, length.out = n)
  habitat <- factor(rep(c("reef", "kelp", "sand"), length.out = n))
  exposure <- rep(c(1.0, 1.4, 1.8), length.out = n)
  eta <- -0.1 + 0.4 * x + 0.25 * (habitat == "kelp") + log(exposure)
  data.frame(
    y = stats::rpois(n, lambda = exp(eta)),
    x = x,
    habitat = habitat,
    exposure = exposure
  )
}

test_that("fixed-effect basis matches prediction matrix, offset, and covariance", {
  set.seed(20260527)
  dat <- fixed_effect_basis_data()
  fit <- drmTMB(
    bf(y ~ x + habitat + offset(log(exposure))),
    family = stats::poisson(link = "log"),
    data = dat,
    control = fixed_effect_basis_control(se = TRUE)
  )
  newdata <- data.frame(
    x = c(-0.5, 0.75),
    habitat = factor(c("reef", "kelp"), levels = levels(dat$habitat)),
    exposure = c(1.2, 1.6)
  )

  basis <- drmTMB:::drm_fixed_effect_basis(
    fit,
    newdata = newdata,
    dpar = "mu",
    covariance = TRUE
  )
  beta <- coef(fit, "mu")
  expected_vcov <- vcov(fit)[
    paste0("mu:", names(beta)),
    paste0("mu:", names(beta)),
    drop = FALSE
  ]
  dimnames(expected_vcov) <- list(names(beta), names(beta))

  expect_equal(basis$dpar, "mu")
  expect_equal(colnames(basis$X), names(beta))
  expect_equal(basis$bhat, beta)
  expect_equal(basis$offset, log(newdata$exposure))
  expect_equal(basis$eta, as.numeric(basis$X %*% beta) + basis$offset)
  expect_equal(
    basis$eta,
    unname(predict(fit, newdata = newdata, dpar = "mu", type = "link"))
  )
  expect_equal(basis$link, "log")
  expect_equal(basis$coefficient_labels, paste0("mu:", names(beta)))
  expect_equal(basis$V, expected_vcov)
})

test_that("fixed-effect basis handles covariance as an explicit opt-in", {
  set.seed(20260528)
  dat <- fixed_effect_basis_data()
  fit <- drmTMB(
    bf(y ~ x + habitat),
    family = stats::poisson(link = "log"),
    data = dat,
    control = fixed_effect_basis_control(se = FALSE)
  )
  newdata <- data.frame(
    x = c(-0.25, 0.25),
    habitat = factor(c("reef", "sand"), levels = levels(dat$habitat))
  )

  basis <- drmTMB:::drm_fixed_effect_basis(
    fit,
    newdata = newdata,
    dpar = "mu"
  )

  expect_null(basis$V)
  expect_equal(
    basis$eta,
    unname(predict(fit, newdata = newdata, dpar = "mu", type = "link"))
  )
  expect_error(
    drmTMB:::drm_fixed_effect_basis(
      fit,
      newdata = newdata,
      dpar = "mu",
      covariance = TRUE
    ),
    "Refit with"
  )
  expect_error(
    drmTMB:::drm_fixed_effect_basis(
      fit,
      newdata = newdata,
      dpar = "mu",
      covariance = NA
    ),
    "covariance"
  )
})

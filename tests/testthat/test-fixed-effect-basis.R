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

test_that("fixed-effect basis preserves ordered factor coding in newdata", {
  set.seed(20260556)
  dat <- fixed_effect_basis_data(n = 90L)
  dat$condition <- ordered(
    rep(c("low", "mid", "high"), length.out = nrow(dat)),
    levels = c("low", "mid", "high")
  )
  dat$y <- 0.1 +
    0.35 * dat$x +
    0.2 * as.numeric(dat$condition) +
    stats::rnorm(nrow(dat), sd = 0.08)
  fit <- drmTMB(
    bf(y ~ x + condition, sigma ~ 1),
    data = dat,
    control = fixed_effect_basis_control(se = TRUE)
  )
  newdata <- data.frame(
    x = c(-0.25, 0.5),
    condition = factor(c("low", "high"), levels = levels(dat$condition))
  )
  expected_newdata <- newdata
  expected_newdata$condition <- ordered(
    expected_newdata$condition,
    levels = levels(dat$condition)
  )

  basis <- drmTMB:::drm_fixed_effect_basis(
    fit,
    newdata = newdata,
    dpar = "mu"
  )
  expected_X <- stats::model.matrix(fit$model$terms$mu, expected_newdata)

  expect_equal(colnames(basis$X), names(coef(fit, "mu")))
  expect_equal(basis$X, expected_X)
  expect_equal(
    basis$eta,
    as.numeric(expected_X %*% coef(fit, "mu"))
  )
})

test_that("fixed-effect basis validates factor levels in newdata", {
  set.seed(20260557)
  dat <- fixed_effect_basis_data()
  fit <- drmTMB(
    bf(y ~ x + habitat),
    family = stats::poisson(link = "log"),
    data = dat,
    control = fixed_effect_basis_control(se = TRUE)
  )
  newdata <- data.frame(
    x = c(-0.25, 0.5),
    habitat = c("reef", "sand")
  )
  expected_newdata <- newdata
  expected_newdata$habitat <- factor(
    expected_newdata$habitat,
    levels = levels(dat$habitat)
  )

  basis <- drmTMB:::drm_fixed_effect_basis(
    fit,
    newdata = newdata,
    dpar = "mu"
  )
  expected_X <- stats::model.matrix(fit$model$terms$mu, expected_newdata)

  expect_equal(basis$X, expected_X)
  expect_equal(
    basis$eta,
    as.numeric(expected_X %*% coef(fit, "mu"))
  )
  expect_error(
    drmTMB:::drm_fixed_effect_basis(
      fit,
      newdata = data.frame(x = 0, habitat = "forest"),
      dpar = "mu"
    ),
    "unknown factor level"
  )
  expect_error(
    predict(fit, newdata = data.frame(x = 0, habitat = "forest"), dpar = "mu"),
    "forest"
  )
  expect_error(
    predict(
      fit,
      newdata = data.frame(x = 0, habitat = NA_character_),
      dpar = "mu"
    ),
    "missing value"
  )
})

test_that("fixed-effect basis validates required newdata variables", {
  set.seed(20260559)
  dat <- fixed_effect_basis_data()
  fit <- drmTMB(
    bf(y ~ x + habitat),
    family = stats::poisson(link = "log"),
    data = dat,
    control = fixed_effect_basis_control(se = TRUE)
  )

  expect_error(
    drmTMB:::drm_fixed_effect_basis(
      fit,
      newdata = data.frame(x = 0),
      dpar = "mu"
    ),
    "missing required predictor"
  )
  expect_error(
    predict(
      fit,
      newdata = data.frame(x = NA_real_, habitat = "reef"),
      dpar = "mu"
    ),
    "missing value"
  )
  expect_error(
    predict(
      fit,
      newdata = data.frame(x = Inf, habitat = "reef"),
      dpar = "mu"
    ),
    "non-finite value"
  )
  expect_no_error(
    predict(
      fit,
      newdata = data.frame(x = 0, habitat = "reef", extra = NA_real_),
      dpar = "mu"
    )
  )
})

test_that("fixed-effect basis validates transformed predictor values", {
  set.seed(20260560)
  dat <- fixed_effect_basis_data()
  dat$size <- seq(0.4, 3.2, length.out = nrow(dat))
  fit <- drmTMB(
    bf(y ~ log(size) + habitat),
    family = stats::poisson(link = "log"),
    data = dat,
    control = fixed_effect_basis_control(se = TRUE)
  )
  bad_newdata <- data.frame(size = 0, habitat = "reef")

  expect_error(
    drmTMB:::drm_fixed_effect_basis(
      fit,
      newdata = bad_newdata,
      dpar = "mu"
    ),
    "log\\(size\\)"
  )
  expect_error(
    predict(fit, newdata = bad_newdata, dpar = "mu"),
    "non-finite design-matrix"
  )
})

test_that("fixed-effect basis finite matrix validation handles sparse matrices", {
  sparse <- Matrix::sparseMatrix(
    i = 1,
    j = 2,
    x = Inf,
    dims = c(2, 2),
    dimnames = list(NULL, c("(Intercept)", "log(size)"))
  )

  expect_equal(
    drmTMB:::drm_nonfinite_prediction_matrix_terms(sparse),
    "log(size)"
  )
})

test_that("fixed-effect basis ignores unused factor columns in newdata", {
  set.seed(20260558)
  dat <- fixed_effect_basis_data()
  dat$unused <- factor(rep(c("a", "b"), length.out = nrow(dat)))
  fit <- drmTMB(
    bf(y ~ x + habitat),
    family = stats::poisson(link = "log"),
    data = dat,
    control = drm_control(
      se = TRUE,
      keep_model_frame = FALSE,
      optimizer = list(eval.max = 120L, iter.max = 120L)
    )
  )
  newdata <- data.frame(
    x = 0,
    habitat = "reef",
    unused = "forest"
  )

  expect_no_error(
    drmTMB:::drm_fixed_effect_basis(fit, newdata = newdata, dpar = "mu")
  )
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

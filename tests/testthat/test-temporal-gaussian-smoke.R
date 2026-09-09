temporal_smoke_data <- function(with_intercept = FALSE) {
  set.seed(20260908)
  dat <- expand.grid(
    id = sprintf("site_%02d", seq_len(8L)),
    occasion = c(0L, 1L, 3L, 4L),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  dat$treatment <- rep(rep(c(0, 1), each = 4L), length.out = nrow(dat))
  dat$y <- 0.4 + 0.6 * dat$treatment + stats::rnorm(nrow(dat), sd = 0.5)
  dat
}

test_that("Gaussian AR1 temporal random effects fit with and without a stable intercept", {
  dat <- temporal_smoke_data()
  ar1_only <- drmTMB(
    bf(y ~ treatment + temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
    data = dat,
    family = gaussian(),
    REML = FALSE
  )
  expect_s3_class(ar1_only, "drmTMB")
  expect_true(is.finite(stats::logLik(ar1_only)))

  combined <- drmTMB(
    bf(y ~ treatment + (1 | id) + temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
    data = dat,
    family = gaussian(),
    REML = FALSE
  )
  expect_s3_class(combined, "drmTMB")
  expect_true(is.finite(stats::logLik(combined)))
})

test_that("temporal AR1 data checks preserve the intended admission boundary", {
  dat <- temporal_smoke_data()
  duplicated <- rbind(dat, dat[1L, ])
  expect_error(
    drmTMB(
      bf(y ~ temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
      data = duplicated, family = gaussian(), REML = FALSE
    ),
    "keys must be unique"
  )
  dat$occasion <- as.numeric(dat$occasion) + 0.5
  expect_error(
    drmTMB(
      bf(y ~ temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
      data = dat, family = gaussian(), REML = FALSE
    ),
    "finite integers"
  )
})

test_that("temporal AR1 exposes labelled components and mean-only Wald inference", {
  dat <- temporal_smoke_data()
  dat <- dat[rep(seq_len(nrow(dat)), 3L), , drop = FALSE]
  dat$id <- paste(dat$id, rep(seq_len(3L), each = 32L), sep = "_")
  fit <- suppressWarnings(drmTMB(
    bf(y ~ treatment + temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
    data = dat, family = gaussian(), REML = FALSE
  ))
  expect_named(fit$sdpars$mu, temporal_mu_sd_label(fit$model$structured$temporal_mu))
  expect_named(fit$corpars$temporal, fit$model$structured$temporal_mu$label)
  expect_named(fit$random_effects$temporal, c("values", "latent", "terms"))
  expect_identical(
    rownames(stats::vcov(fit)),
    c("mu:(Intercept)", "mu:treatment")
  )
  expect_identical(
    colnames(stats::vcov(fit)),
    c("mu:(Intercept)", "mu:treatment")
  )
  intervals <- stats::confint(fit, method = "wald")
  expect_setequal(intervals$parm, c("fixef:mu:(Intercept)", "fixef:mu:treatment"))
  expect_error(stats::confint(fit, method = "profile"), "Wald intervals only")
  expect_error(stats::confint(fit, method = "bootstrap"), "Wald intervals only")
  expect_length(stats::fitted(fit), nrow(dat))
  expect_error(
    stats::predict(fit, newdata = dat[1L, , drop = FALSE]),
    "fitted observations"
  )
  expect_identical(dim(stats::simulate(fit, nsim = 2L, seed = 1L)), c(nrow(dat), 2L))
  expect_identical(
    dim(stats::simulate(fit, nsim = 2L, seed = 1L, re.form = NA)),
    c(nrow(dat), 2L)
  )
})

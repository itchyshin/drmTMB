gaussian_aggregation_data <- function() {
  base <- expand.grid(
    habitat = factor(c("forest", "reef", "grass")),
    season = factor(c("dry", "wet")),
    effort = factor(c("low", "high")),
    rep = seq_len(4)
  )
  mu <- 0.4 +
    c(forest = 0.1, reef = -0.2, grass = 0.3)[base$habitat] +
    c(dry = -0.05, wet = 0.08)[base$season]
  sigma <- exp(-0.6 + c(low = -0.1, high = 0.12)[base$effort])
  base$y <- mu + sigma * rep(c(-1.2, -0.4, 0.3, 1.1), length.out = nrow(base))
  base
}

test_that("Gaussian aggregation helper preserves fixed-coefficient log-likelihood", {
  dat <- gaussian_aggregation_data()
  mf_mu <- stats::model.frame(y ~ habitat + season, data = dat)
  mf_sigma <- stats::model.frame(~effort, data = dat)
  X_mu <- stats::model.matrix(stats::terms(mf_mu), mf_mu)
  X_sigma <- stats::model.matrix(stats::terms(mf_sigma), mf_sigma)
  parity <- drmTMB:::drm_gaussian_aggregation_parity(
    y = dat$y,
    X_mu = X_mu,
    X_sigma = X_sigma,
    beta_mu = c(0.3, -0.1, 0.2, 0.05),
    beta_sigma = c(-0.5, 0.2)
  )

  expect_equal(parity$aggregation$n_original, nrow(dat))
  expect_equal(parity$aggregation$n_cells, 12)
  expect_equal(max(parity$aggregation$n), 4)
  expect_equal(parity$difference, 0, tolerance = 1e-12)
})

test_that("Gaussian aggregation fitting matches full-row Gaussian fits", {
  dat <- gaussian_aggregation_data()
  form <- bf(y ~ habitat + season, sigma ~ effort)

  dense <- drmTMB(
    form,
    data = dat,
    control = drm_control(optimizer = list(eval.max = 200, iter.max = 200))
  )
  aggregated <- drmTMB(
    form,
    data = dat,
    control = drm_control(
      aggregate_gaussian = TRUE,
      optimizer = list(eval.max = 200, iter.max = 200)
    )
  )

  expect_equal(dense$opt$convergence, 0L)
  expect_equal(aggregated$opt$convergence, 0L)
  expect_equal(
    aggregated$model$aggregation$gaussian$n_original,
    nrow(dat)
  )
  expect_equal(aggregated$model$aggregation$gaussian$n_cells, 12)
  expect_equal(aggregated$model$tmb_data$use_gaussian_aggregation, 1L)
  expect_equal(nrow(aggregated$model$tmb_data$X_mu_agg), 12)
  expect_equal(coef(aggregated, "mu"), coef(dense, "mu"), tolerance = 1e-5)
  expect_equal(
    coef(aggregated, "sigma"),
    coef(dense, "sigma"),
    tolerance = 1e-5
  )
  expect_equal(
    as.numeric(logLik(aggregated)),
    as.numeric(logLik(dense)),
    tolerance = 1e-6
  )
  expect_equal(stats::AIC(aggregated), stats::AIC(dense), tolerance = 1e-6)
  expect_equal(stats::vcov(aggregated), stats::vcov(dense), tolerance = 1e-5)
  expect_equal(fitted(aggregated), fitted(dense), tolerance = 1e-5)
  expect_equal(residuals(aggregated), residuals(dense), tolerance = 1e-5)

  chk <- check_drm(aggregated)
  aggregation <- chk[chk$check == "gaussian_aggregation", , drop = FALSE]
  expect_equal(aggregation$status, "ok")
  expect_match(aggregation$value, "aggregation_cells=12")
  expect_match(aggregation$message, "compressed repeated")
})

test_that("Gaussian aggregation works with memory-light fitted objects", {
  dat <- gaussian_aggregation_data()
  fit <- drmTMB(
    bf(y ~ habitat + season, sigma ~ effort),
    data = dat,
    control = drm_control(
      aggregate_gaussian = TRUE,
      keep_data = FALSE,
      keep_model_frame = FALSE,
      keep_tmb_object = FALSE,
      optimizer = list(eval.max = 200, iter.max = 200)
    )
  )

  expect_null(fit$data)
  expect_null(fit$model$model_frame)
  expect_null(fit$obj)
  expect_equal(length(fitted(fit)), nrow(dat))
  expect_equal(length(residuals(fit)), nrow(dat))
  expect_equal(length(predict(fit, dpar = "sigma")), nrow(dat))
})

test_that("Gaussian aggregation rejects unsupported first-slice models", {
  dat <- gaussian_aggregation_data()
  dat$id <- factor(rep(seq_len(6), length.out = nrow(dat)))
  dat$v <- rep(0.02, nrow(dat))
  tree <- structure(
    list(
      edge = matrix(
        c(7, 1, 7, 2, 8, 3, 8, 4, 9, 5, 9, 6),
        ncol = 2,
        byrow = TRUE
      ),
      edge.length = rep(1, 6),
      tip.label = as.character(seq_len(6)),
      Nnode = 3L
    ),
    class = "phylo"
  )

  expect_snapshot(
    error = TRUE,
    drmTMB(
      bf(y ~ habitat + (1 | id), sigma ~ 1),
      data = dat,
      control = drm_control(aggregate_gaussian = TRUE)
    )
  )
  expect_snapshot(
    error = TRUE,
    drmTMB(
      bf(y ~ habitat + meta_V(V = v), sigma ~ 1),
      data = dat,
      control = drm_control(aggregate_gaussian = TRUE)
    )
  )
  expect_snapshot(
    error = TRUE,
    drmTMB(
      bf(y ~ habitat + phylo(1 | id, tree = tree), sigma ~ 1),
      data = dat,
      control = drm_control(aggregate_gaussian = TRUE)
    )
  )
  expect_snapshot(
    error = TRUE,
    drmTMB(
      bf(y ~ habitat, sigma ~ 1),
      data = dat,
      weights = rep(c(1, 2), length.out = nrow(dat)),
      control = drm_control(aggregate_gaussian = TRUE)
    )
  )
  expect_snapshot(
    error = TRUE,
    drmTMB(
      bf(y ~ habitat, sigma ~ 1),
      data = dat,
      control = drm_control(
        aggregate_gaussian = TRUE,
        sparse_fixed = TRUE
      )
    )
  )
  expect_snapshot(
    error = TRUE,
    drmTMB(
      bf(y ~ habitat),
      family = poisson(),
      data = transform(dat, y = as.integer(abs(y) * 10) + 1L),
      control = drm_control(aggregate_gaussian = TRUE)
    )
  )
  expect_snapshot(
    error = TRUE,
    drmTMB(
      drm_formula(
        mu1 = y ~ habitat,
        mu2 = y2 ~ habitat,
        sigma1 = ~1,
        sigma2 = ~1,
        rho12 = ~1
      ),
      family = c(gaussian(), gaussian()),
      data = transform(dat, y2 = y + 0.1),
      control = drm_control(aggregate_gaussian = TRUE)
    )
  )
})

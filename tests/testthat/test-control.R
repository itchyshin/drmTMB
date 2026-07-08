control_balanced_ultrametric_tree <- function(n_tip = 8L) {
  stopifnot(n_tip >= 2L, log2(n_tip) == floor(log2(n_tip)))
  edges <- matrix(integer(), ncol = 2L)
  edge_lengths <- numeric()
  next_node <- n_tip + 1L

  build <- function(tips) {
    if (length(tips) == 1L) {
      return(tips)
    }
    node <- next_node
    next_node <<- next_node + 1L
    mid <- length(tips) / 2L
    left <- build(tips[seq_len(mid)])
    right <- build(tips[seq.int(mid + 1L, length(tips))])
    edges <<- rbind(edges, c(node, left), c(node, right))
    edge_lengths <<- c(edge_lengths, 1, 1)
    node
  }

  build(seq_len(n_tip))
  structure(
    list(
      edge = edges,
      edge.length = edge_lengths,
      tip.label = paste0("sp_", seq_len(n_tip)),
      Nnode = n_tip - 1L
    ),
    class = "phylo"
  )
}

test_that("drm_control() validates optimizer and storage settings", {
  ctrl <- drm_control(
    optimizer = list(eval.max = 25),
    keep_data = FALSE,
    keep_tmb_object = FALSE
  )

  expect_s3_class(ctrl, "drm_control")
  expect_equal(ctrl$optimizer$eval.max, 25)
  expect_true(ctrl$se)
  expect_false(drm_control(se = FALSE)$se)
  expect_false(ctrl$keep_data)
  expect_true(ctrl$keep_model_frame)
  expect_false(ctrl$keep_tmb_object)
  expect_false(drm_control(keep_model_frame = FALSE)$keep_model_frame)
  expect_error(drm_control(optimizer = 1), "optimizer")
  expect_error(drm_control(optimizer = list(25)), "named list")
  expect_error(drm_control(se = NA), "se")
  expect_error(drm_control(keep_data = NA), "keep_data")
  expect_error(drm_control(keep_model_frame = NA), "keep_model_frame")
  expect_error(
    drmTMB(
      bf(y ~ 1),
      data = data.frame(y = 1:4),
      control = list(se = FALSE)
    ),
    "reserved"
  )
})

test_that("plain control lists remain optimizer controls", {
  dat <- data.frame(
    y = c(-0.2, 0.0, 0.3, 0.6, 0.8, 1.2),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5)
  )

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 100, iter.max = 100)
  )

  expect_s3_class(fit$control, "drm_control")
  expect_equal(fit$control$optimizer$eval.max, 100)
  expect_equal(fit$control$optimizer$iter.max, 100)
  expect_equal(fit$data$y, dat$y)
  expect_false(is.null(fit$obj))
})

test_that("memory-light storage keeps core post-fit methods working", {
  dat <- data.frame(
    y = c(-0.2, 0.0, 0.3, 0.6, 0.8, 1.2),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5)
  )

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(
      optimizer = list(eval.max = 100, iter.max = 100),
      keep_data = FALSE,
      keep_model_frame = FALSE,
      keep_tmb_object = FALSE
    )
  )

  expect_null(fit$data)
  expect_null(fit$model$data)
  expect_null(fit$model$model_frame)
  expect_null(fit$obj)
  expect_length(predict(fit, dpar = "mu"), nrow(dat))
  expect_length(fitted(fit), nrow(dat))
  expect_length(residuals(fit), nrow(dat))
  expect_equal(dim(simulate(fit, nsim = 2, seed = 1)), c(nrow(dat), 2L))

  chk <- check_drm(fit)
  fixed_gradient <- chk[chk$check == "fixed_gradient", ]
  expect_true(attr(chk, "ok"))
  expect_equal(fixed_gradient$status, "note")
  expect_match(fixed_gradient$message, "not retained")
})

test_that("se = FALSE skips sdreport while keeping core methods usable", {
  dat <- data.frame(
    y = c(-0.2, 0.0, 0.3, 0.6, 0.8, 1.2),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5)
  )

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(
      optimizer = list(eval.max = 100, iter.max = 100),
      se = FALSE
    )
  )

  expect_null(fit$sdr)
  expect_null(fit$sdreport)
  expect_equal(fit$uncertainty$status, "skipped")
  expect_error(stats::vcov(fit), "sdreport")
  expect_error(stats::confint(fit), "sdreport")
  expect_length(predict(fit, dpar = "mu"), nrow(dat))
  expect_length(fitted(fit), nrow(dat))
  expect_length(residuals(fit), nrow(dat))
  expect_equal(dim(simulate(fit, nsim = 2, seed = 1)), c(nrow(dat), 2L))
  expect_true(any(profile_targets(fit)$profile_ready))
  profile_ci <- stats::confint(
    fit,
    parm = "fixef:mu:(Intercept)",
    method = "profile",
    trace = FALSE
  )
  expect_equal(profile_ci$conf.status, "profile")

  smry <- summary(fit)
  expect_true(all(is.na(smry$coefficients$std_error)))
  expect_equal(
    smry$coefficients$std_error.status,
    rep("sdreport_skipped", nrow(smry$coefficients))
  )

  wald_smry <- summary(fit, conf.int = TRUE, method = "wald")
  expect_equal(
    wald_smry$coefficients$conf.status,
    rep("wald_unavailable", nrow(wald_smry$coefficients))
  )
  expect_s3_class(wald_smry$confint, "data.frame")
  expect_equal(nrow(wald_smry$confint), 0L)

  chk <- check_drm(fit)
  expect_true(attr(chk, "ok"))
  expect_equal(
    chk$status[chk$check == "sdreport_status"],
    "note"
  )
  expect_equal(
    chk$status[chk$check == "hessian_positive_definite"],
    "note"
  )
  expect_equal(
    chk$status[chk$check == "standard_errors_finite"],
    "note"
  )
})

test_that("failed sdreport state is explicit in summaries and diagnostics", {
  dat <- data.frame(
    y = c(-0.2, 0.0, 0.3, 0.6, 0.8, 1.2),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5)
  )

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 100, iter.max = 100)
  )
  fit$sdr <- NULL
  fit$sdreport <- NULL
  fit$uncertainty <- list(
    status = "failed",
    se = TRUE,
    message = "TMB::sdreport() failed: synthetic failure",
    sdr_error = "synthetic failure"
  )

  expect_error(stats::vcov(fit), "synthetic failure")
  smry <- summary(fit)
  expect_true(all(is.na(smry$coefficients$std_error)))
  expect_equal(
    smry$coefficients$std_error.status,
    rep("sdreport_failed", nrow(smry$coefficients))
  )

  chk <- check_drm(fit)
  expect_false(attr(chk, "ok"))
  expect_equal(
    chk$status[chk$check == "sdreport_status"],
    "warning"
  )
  expect_equal(
    chk$status[chk$check == "hessian_positive_definite"],
    "warning"
  )
  expect_equal(
    chk$status[chk$check == "standard_errors_finite"],
    "warning"
  )
})

test_that("non-positive Hessian state is explicit in summaries and intervals", {
  dat <- data.frame(
    y = c(-0.2, 0.0, 0.3, 0.6, 0.8, 1.2),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5)
  )

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 100, iter.max = 100)
  )
  fit$sdr$pdHess <- FALSE
  fit$sdreport <- fit$sdr

  expect_error(stats::vcov(fit), "positive-definite Hessian")
  smry <- summary(fit)
  expect_true(all(is.na(smry$coefficients$std_error)))
  expect_equal(
    smry$coefficients$std_error.status,
    rep("sdreport_non_pd_hessian", nrow(smry$coefficients))
  )
  expect_true(all(is.na(smry$parameters$std_error)))

  wald_smry <- summary(fit, conf.int = TRUE)
  expect_equal(
    wald_smry$coefficients$conf.status,
    rep("wald_unavailable", nrow(wald_smry$coefficients))
  )
  expect_equal(
    wald_smry$parameters$conf.status,
    rep("wald_unavailable", nrow(wald_smry$parameters))
  )
  expect_equal(nrow(wald_smry$confint), 0L)
})

test_that("memory-light storage drops direct-SD phylogenetic model frames", {
  n_tip <- 8L
  n_each <- 4L
  tree <- control_balanced_ultrametric_tree(n_tip)
  species_values <- tree$tip.label
  species <- rep(species_values, each = n_each)
  z_species <- seq(-1, 1, length.out = n_tip)
  x <- rep(seq(-0.5, 0.5, length.out = n_each), times = n_tip)
  y <- 0.2 + 0.3 * x + rep(seq(-0.4, 0.4, length.out = n_tip), each = n_each)
  y <- y + rep(c(-0.08, 0.05, -0.03, 0.04), times = n_tip)
  dat <- data.frame(
    y = y,
    x = x,
    species = species,
    z_species = z_species[match(species, species_values)]
  )

  fit <- drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree),
      sigma ~ 1,
      sd_phylo(species) ~ z_species
    ),
    family = gaussian(),
    data = dat,
    control = drm_control(
      optimizer = list(eval.max = 200, iter.max = 200),
      keep_data = FALSE,
      keep_model_frame = FALSE,
      keep_tmb_object = FALSE
    )
  )

  expect_null(fit$data)
  expect_null(fit$model$model_frame)
  expect_null(fit$model$random_scale$phylo$model_frame)
  expect_null(fit$model$random_scale$phylo$model_frame_list)
  expect_null(fit$obj)
  expect_length(predict(fit, dpar = "sd_phylo(species)"), n_tip)
  expect_length(stats::sigma(fit), nrow(dat))
  expect_s3_class(check_drm(fit), "drm_check")
})

test_that("memory-light storage drops latent-correlation model frames", {
  n_id <- 8L
  n_each <- 5L
  id_values <- paste0("id_", seq_len(n_id))
  id <- rep(id_values, each = n_each)
  ecology_group <- seq(-1, 1, length.out = n_id)
  ecology <- ecology_group[match(id, id_values)]
  x <- rep(seq(-0.75, 0.75, length.out = n_each), times = n_id)
  u1 <- seq(-0.35, 0.35, length.out = n_id)
  u2 <- 0.45 * u1 + seq(0.20, -0.20, length.out = n_id)
  y1 <- 0.1 +
    0.3 * x +
    u1[match(id, id_values)] +
    rep(c(-0.05, 0.04, -0.02, 0.03, 0.00), times = n_id)
  y2 <- -0.2 -
    0.2 * x +
    u2[match(id, id_values)] +
    rep(c(0.04, -0.03, 0.02, -0.01, 0.00), times = n_id)
  dat <- data.frame(y1 = y1, y2 = y2, x = x, id = id, ecology = ecology)
  cor_dpar <- paste0(
    'corpair(id, level = "group", block = "p", ',
    'from = "mu1", to = "mu2")'
  )

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + (1 | p | id),
      mu2 = y2 ~ x + (1 | p | id),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1,
      corpair(id, level = "group", block = "p", from = "mu1", to = "mu2") ~
        ecology
    ),
    family = c(gaussian(), gaussian()),
    data = dat,
    control = drm_control(
      optimizer = list(eval.max = 250, iter.max = 250),
      keep_data = FALSE,
      keep_model_frame = FALSE,
      keep_tmb_object = FALSE
    )
  )

  expect_null(fit$data)
  expect_null(fit$model$model_frame)
  expect_null(fit$model$random$mu$cor_model$model_frame_list)
  expect_null(fit$obj)
  expect_length(predict(fit, dpar = cor_dpar), n_id)
  expect_equal(nrow(corpairs(fit, level = "group")), 1L)
  expect_s3_class(check_drm(fit), "drm_check")
})

test_that("memory-light storage keeps bivariate known-V methods working", {
  n <- 10
  dat <- data.frame(
    x = seq(-1, 1, length.out = n)
  )
  dat$y1 <- 0.2 +
    0.4 * dat$x +
    c(
      -0.20,
      0.10,
      -0.05,
      0.15,
      -0.10,
      0.05,
      0.20,
      -0.15,
      0.10,
      -0.05
    )
  dat$y2 <- -0.1 -
    0.3 * dat$x +
    c(
      0.15,
      -0.10,
      0.05,
      -0.05,
      0.10,
      -0.15,
      0.05,
      0.20,
      -0.10,
      0.00
    )
  V <- meta_vcov_bivariate(
    v1 = rep(0.01, n),
    v2 = rep(0.015, n),
    cor12 = 0.25
  )

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + meta_V(V = V),
      mu2 = y2 ~ x,
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = dat,
    control = drm_control(
      optimizer = list(eval.max = 100, iter.max = 100),
      keep_data = FALSE,
      keep_model_frame = FALSE,
      keep_tmb_object = FALSE
    )
  )

  expect_null(fit$data)
  expect_null(fit$model$data)
  expect_null(fit$model$model_frame)
  expect_null(fit$obj)
  expect_equal(fit$model$V_known_type, "matrix")
  expect_equal(dim(fit$model$V_known), c(2L * n, 2L * n))
  expect_equal(dim(fitted(fit)), c(n, 2L))
  expect_equal(dim(residuals(fit, type = "pearson")), c(n, 2L))
  expect_equal(dim(simulate(fit, nsim = 2, seed = 1)), c(n, 4L))
  expect_length(sigma(fit)$sigma1, n)
  expect_length(sigma(fit)$sigma2, n)
  expect_length(rho12(fit), n)

  pairs <- corpairs(fit)
  expect_equal(pairs$from_response, "y1")
  expect_equal(pairs$to_response, "y2")

  chk <- check_drm(fit)
  known_v <- chk[chk$check == "known_sampling_covariance", ]
  fixed_gradient <- chk[chk$check == "fixed_gradient", ]
  expect_equal(known_v$status, "note")
  expect_match(known_v$value, "storage=dense")
  expect_match(known_v$message, "sparse or block-sparse")
  expect_equal(fixed_gradient$status, "note")
})

test_that("core methods tolerate manually removed model frames", {
  dat <- data.frame(
    y = c(-0.2, 0.0, 0.3, 0.6, 0.8, 1.2),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 100, iter.max = 100)
  )
  fit$model$model_frame <- NULL

  expect_length(predict(fit, dpar = "mu"), nrow(dat))
  expect_length(predict(fit, newdata = data.frame(x = c(0, 1))), 2L)
  expect_length(fitted(fit), nrow(dat))
  expect_length(residuals(fit), nrow(dat))
  expect_equal(dim(simulate(fit, nsim = 2, seed = 1)), c(nrow(dat), 2L))
  expect_length(sigma(fit), nrow(dat))
  expect_s3_class(check_drm(fit), "drm_check")
})

test_that("offset prediction tolerates manually removed model frames", {
  dat <- data.frame(
    y = c(0L, 1L, 2L, 3L, 1L, 4L),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5),
    exposure = c(1, 1.5, 2, 2.5, 3, 3.5)
  )
  fit <- drmTMB(
    bf(y ~ x + offset(log(exposure))),
    family = poisson(),
    data = dat,
    control = list(eval.max = 100, iter.max = 100)
  )
  fit$model$model_frame <- NULL

  pred <- predict(
    fit,
    newdata = data.frame(x = c(0, 1), exposure = c(2, 4)),
    dpar = "mu"
  )
  expect_length(pred, 2L)
  expect_true(all(is.finite(pred)))
  expect_length(residuals(fit), nrow(dat))
  expect_equal(dim(simulate(fit, nsim = 2, seed = 1)), c(nrow(dat), 2L))
})

test_that("representative family methods tolerate manually removed model frames", {
  beta_binomial_dat <- data.frame(
    success = c(2L, 4L, 6L, 8L, 3L, 5L, 7L, 9L, 4L, 6L),
    failure = c(8L, 6L, 4L, 2L, 7L, 5L, 3L, 1L, 6L, 4L),
    x = seq(-1, 1, length.out = 10)
  )
  beta_binomial_fit <- drmTMB(
    bf(cbind(success, failure) ~ x, sigma ~ 1),
    family = beta_binomial(),
    data = beta_binomial_dat,
    control = list(eval.max = 100, iter.max = 100)
  )
  beta_binomial_fit$model$model_frame <- NULL

  expect_length(
    predict(beta_binomial_fit, dpar = "mu"),
    nrow(beta_binomial_dat)
  )
  expect_length(
    predict(beta_binomial_fit, newdata = data.frame(x = c(0, 1)), dpar = "mu"),
    2L
  )
  expect_length(residuals(beta_binomial_fit), nrow(beta_binomial_dat))
  expect_equal(
    dim(simulate(beta_binomial_fit, nsim = 2, seed = 1)),
    c(nrow(beta_binomial_dat), 2L)
  )

  ordinal_dat <- data.frame(
    score = ordered(
      rep(c("low", "medium", "high"), each = 4),
      levels = c("low", "medium", "high")
    ),
    x = rep(c(-1, -0.5, 0.5, 1), times = 3)
  )
  ordinal_fit <- drmTMB(
    bf(score ~ x),
    family = cumulative_logit(),
    data = ordinal_dat,
    control = list(eval.max = 100, iter.max = 100)
  )
  ordinal_fit$model$model_frame <- NULL

  expect_length(predict(ordinal_fit, dpar = "mu"), nrow(ordinal_dat))
  expect_length(
    predict(ordinal_fit, newdata = data.frame(x = c(0, 1)), dpar = "mu"),
    2L
  )
  expect_length(fitted(ordinal_fit), nrow(ordinal_dat))
  expect_length(residuals(ordinal_fit), nrow(ordinal_dat))
  expect_equal(
    dim(simulate(ordinal_fit, nsim = 2, seed = 1)),
    c(nrow(ordinal_dat), 2L)
  )

  biv_dat <- data.frame(
    y1 = c(-0.4, -0.1, 0.2, 0.4, 0.7, 1.0, 1.2, 1.5),
    y2 = c(0.3, 0.2, 0.4, 0.5, 0.9, 1.1, 1.0, 1.4),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5, 2, 2.5)
  )
  biv_fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
    family = c(gaussian(), gaussian()),
    data = biv_dat,
    control = list(eval.max = 100, iter.max = 100)
  )
  biv_fit$model$model_frame <- NULL

  expect_equal(dim(fitted(biv_fit)), c(nrow(biv_dat), 2L))
  expect_equal(dim(residuals(biv_fit)), c(nrow(biv_dat), 2L))
  expect_length(rho12(biv_fit), nrow(biv_dat))
  expect_equal(dim(simulate(biv_fit, nsim = 2, seed = 1)), c(nrow(biv_dat), 4L))
  pairs <- corpairs(biv_fit)
  expect_equal(pairs$from_response, "y1")
  expect_equal(pairs$to_response, "y2")
})

test_that("se_report_covariance and se_skip_delta_method reach TMB::sdreport()", {
  skip_on_cran()
  # Reported by A. Mizuno (2026-07-08): a bivariate direct-SD phylo fit ADREPORTs
  # one SD per tip per response, so `getReportCovariance = TRUE` (TMB's default)
  # builds an R x R dense matrix with R = 4 * n_tip + 13. At 10,440 tips that is
  # ~14 GB. These controls expose the two TMB switches that avoid it.
  ctrl <- drm_control(se_report_covariance = FALSE, se_skip_delta_method = TRUE)
  expect_false(ctrl$se_report_covariance)
  expect_true(ctrl$se_skip_delta_method)

  # Defaults preserve the previous behaviour exactly.
  expect_true(drm_control()$se_report_covariance)
  expect_false(drm_control()$se_skip_delta_method)

  expect_error(drm_control(se_report_covariance = NA), "must be")
  expect_error(drm_control(se_skip_delta_method = "yes"), "must be")

  set.seed(20260708)
  n <- 60L
  dat <- data.frame(
    id = rep(paste0("g", seq_len(10L)), each = 6L),
    x = stats::rnorm(n)
  )
  dat$y <- stats::rnorm(n, 0.3 + 0.5 * dat$x, sd = 0.4)

  fit_default <- drmTMB(bf(y ~ x + (1 | id)), family = gaussian(), data = dat)
  fit_nocov <- drmTMB(
    bf(y ~ x + (1 | id)),
    family = gaussian(),
    data = dat,
    control = drm_control(se_report_covariance = FALSE)
  )

  # The R x R ADREPORT covariance is dropped. TMB does not remove `$cov`; it
  # leaves a logical scalar in its place, so assert on shape, not on NULL.
  expect_true(is.matrix(fit_default$sdr$cov))
  expect_false(is.matrix(fit_nocov$sdr$cov))
  expect_length(fit_nocov$sdr$cov, 1L)

  # ... while the per-quantity ADREPORT standard errors survive ...
  expect_true(all(is.finite(fit_nocov$sdr$sd)))
  expect_equal(fit_default$sdr$sd, fit_nocov$sdr$sd, tolerance = 1e-8)

  # ... and fixed-effect standard errors are unchanged.
  expect_equal(
    sqrt(diag(stats::vcov(fit_default))),
    sqrt(diag(stats::vcov(fit_nocov))),
    tolerance = 1e-8
  )

  # A legacy plain-list `control` must keep the TRUE default (field absent = NULL).
  fit_legacy <- drmTMB(
    bf(y ~ x + (1 | id)),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 500)
  )
  expect_true(is.matrix(fit_legacy$sdr$cov))
})

test_that("REML rejects a missing-data engine only when it actually engages", {
  skip_on_cran()
  # Reported by A. Mizuno (2026-07-08): the gate tested the `missing` SETTING, so
  # `miss_control(response = "include")` on complete-case data was rejected even
  # though it is an exact no-op there. Narrow the gate; do not remove it.
  set.seed(20260708)
  n <- 60L
  dat <- data.frame(
    id = rep(paste0("g", seq_len(10L)), each = 6L),
    x = stats::rnorm(n)
  )
  dat$y <- stats::rnorm(n, 0.3 + 0.5 * dat$x, sd = 0.4)

  # No missing values: the engine is a no-op, so REML is admitted.
  expect_no_error(suppressWarnings(
    drmTMB(
      bf(y ~ x + (1 | id)),
      family = gaussian(),
      data = dat,
      missing = miss_control(response = "include"),
      REML = TRUE
    )
  ))

  # Real missingness: the engine engages and REML is still unvalidated with it.
  dat_na <- dat
  dat_na$y[c(3L, 17L)] <- NA_real_
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id)),
      family = gaussian(),
      data = dat_na,
      missing = miss_control(response = "include"),
      REML = TRUE
    ),
    "missing-data engine"
  )

  # The default control still drops incomplete rows and fits under REML.
  expect_no_error(suppressWarnings(
    drmTMB(bf(y ~ x + (1 | id)), family = gaussian(), data = dat_na, REML = TRUE)
  ))
})

test_that("se_group_sd keeps the per-group direct-SD ADREPORT out of sdreport", {
  skip_on_cran()
  # Reported by A. Mizuno (2026-07-08). `sd_phylo(...) ~ .` ADREPORTs one SD per
  # group, so the joint ADREPORT covariance is n_group x n_group. Under REML the
  # fixed effects move into the Laplace `random` block and `vcov()` reads exactly
  # that covariance -- at 10,440 tips a bivariate fit needs ~14 GB for it.
  # Default is now opt-in; the SD *values* remain available via REPORT().
  n_tip <- 8L
  n_each <- 4L
  tree <- control_balanced_ultrametric_tree(n_tip)
  species_values <- tree$tip.label
  species <- rep(species_values, each = n_each)
  z_species <- seq(-1, 1, length.out = n_tip)
  x <- rep(seq(-0.5, 0.5, length.out = n_each), times = n_tip)
  y <- 0.2 + 0.3 * x + rep(seq(-0.4, 0.4, length.out = n_tip), each = n_each)
  y <- y + rep(c(-0.08, 0.05, -0.03, 0.04), times = n_tip)
  dat <- data.frame(
    y = y,
    x = x,
    species = species,
    z_species = z_species[match(species, species_values)]
  )

  fit_it <- function(reml, group_sd) {
    suppressWarnings(drmTMB(
      bf(
        y ~ x + phylo(1 | species, tree = tree),
        sigma ~ 1,
        sd_phylo(species) ~ z_species
      ),
      family = gaussian(),
      data = dat,
      REML = reml,
      control = drm_control(
        optimizer = list(eval.max = 300, iter.max = 300),
        se_group_sd = group_sd
      )
    ))
  }

  expect_false(drm_control()$se_group_sd)

  fit_off <- fit_it(FALSE, FALSE)
  fit_on <- fit_it(FALSE, TRUE)

  # Opting in adds 2 * n_tip entries (`sd_phylo_group` and `log_sd_phylo_group`).
  expect_equal(
    length(fit_on$sdr$value) - length(fit_off$sdr$value),
    2L * n_tip
  )
  expect_false(any(grepl("sd_phylo_group", names(fit_off$sdr$value))))
  expect_true(any(grepl("sd_phylo_group", names(fit_on$sdr$value))))

  # The per-group SD values themselves are unaffected: they are REPORT()ed and
  # recomputed in R, not read from the ADREPORT vector.
  expect_equal(
    fit_off$obj$report()$sd_phylo_group,
    fit_on$obj$report()$sd_phylo_group,
    tolerance = 1e-6
  )

  # Under REML `vcov()` reads the joint ADREPORT covariance, so the default must
  # keep it small AND keep vcov() working.
  reml_off <- fit_it(TRUE, FALSE)
  expect_identical(reml_off$estimator, "REML")
  expect_true(is.matrix(reml_off$sdr$cov))
  expect_lt(nrow(reml_off$sdr$cov), 2L * n_tip)
  expect_true(all(is.finite(sqrt(diag(stats::vcov(reml_off))))))
  expect_true(all(is.finite(summary(reml_off)$coefficients$std_error)))
})

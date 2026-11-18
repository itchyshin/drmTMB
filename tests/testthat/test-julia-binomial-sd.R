test_that("Julia Binomial SD predictions use the canonical target and group grain", {
  dat <- data.frame(
    y = c(0, 1, 0, 1, 1, 0),
    x = c(-1, 0, 1, -1, 0, 1),
    w = c(-1, -1, -1, 1, 1, 1),
    g = factor(rep(c("low", "high"), each = 3L),
               levels = c("low", "high"))
  )
  form <- drm_formula(y ~ x + (1 | g), sd(g) ~ w)
  object <- list(
    formula = form,
    data = dat,
    coefficients = list(
      mu = c("(Intercept)" = 0, x = 0.2),
      sd = c("(Intercept)" = log(0.5), w = log(2))
    )
  )

  link <- drm_julia_predict_sd(object, "sd(g)", type = "link")
  response <- drm_julia_predict_sd(object, "sd(g)", type = "response")
  expect_named(link, c("sd(g):low", "sd(g):high"))
  expect_equal(unname(link), c(log(0.5) - log(2), log(0.5) + log(2)))
  expect_equal(unname(response), exp(unname(link)))
  expect_equal(
    drm_julia_sdpars(object$coefficients, form, dat)[["sd(g)"]],
    response
  )
  coef_names <- c("mu_(Intercept)", "mu_x", "sd_(Intercept)", "sd_w")
  public_object <- new_drmTMB_julia(
    result = list(
      coef_names = coef_names,
      coefficients = c(0, 0.2, log(0.5), log(2)),
      vcov = diag(4L),
      loglik = -4,
      aic = 16,
      bic = 18,
      df = 4L,
      nobs = nrow(dat),
      fitted = rep(0.5, nrow(dat)),
      residuals = rep(0, nrow(dat)),
      sigma = numeric(),
      corpairs = list(),
      converged = TRUE,
      opt = list(convergence = 0L)
    ),
    call = quote(drmTMB(form, data = dat, engine = "julia")),
    formula = form,
    family = stats::binomial(),
    data = dat,
    family_type = "binomial"
  )
  expect_equal(public_object$sdpars[["sd(g)"]], response)
  expect_equal(coef.drmTMB_julia(public_object, "sd(g)"),
               object$coefficients$sd)
  public_prediction <- predict(public_object, dpar = "sd(g)")
  expect_named(public_prediction, c("low", "high"))
  expect_equal(unname(public_prediction), unname(response))
  table <- predict_parameters(
    public_object, dpar = "sd(g)", include_newdata = FALSE
  )
  expect_identical(table$dpar, rep("sd(g)", 2L))
  expect_identical(table$row_label, c("low", "high"))
  expect_equal(table$estimate, unname(response))
  table_newdata <- predict_parameters(
    public_object,
    newdata = dat,
    dpar = "sd(g)",
    include_newdata = FALSE,
    conf.int = TRUE
  )
  expect_equal(nrow(table_newdata), nrow(dat))
  expect_true(all(table_newdata$conf.status == "wald_unavailable"))
  distribution <- fitted_distribution(public_object)
  expect_s3_class(distribution, "drm_fitted_distribution")
  expect_named(distribution$params, c("mu", "trials"))
  expect_equal(distribution$params$trials, rep(1, nrow(dat)))

  newdata <- dat[c(4L, 1L, 5L, 2L), , drop = FALSE]
  predicted <- drm_julia_predict_sd(object, "sd(g)", newdata, type = "response")
  expect_named(predicted, row.names(newdata))
  expect_equal(unname(predicted), c(1, 0.25, 1, 0.25))
})

test_that("binomial q2 bridge labels its correlation working parameter", {
  dat <- data.frame(
    y = c(0, 1, 0, 1),
    x = c(-1, 1, -1, 1),
    w = c(-1, -1, 1, 1),
    v = c(-1, 1, -1, 1),
    id = factor(rep(c("a", "b"), each = 2L))
  )
  formula <- bf(
    y ~ x + (1 + x | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w,
    sd(id, dpar = "mu", coef = "x") ~ v
  )

  labels <- drm_julia_bridge_payload_coef_labels(
    formula = formula,
    data = dat,
    env = environment(),
    family_type = "binomial"
  )

  expect_identical(labels[["recov"]], "id:atanh_rho")

  public <- drm_julia_structured_parameters(
    stats::setNames(atanh(0.35), "recov_id:atanh_rho"),
    formula
  )
  expect_named(public$corpars$mu, "cor((Intercept),x | id)")
  expect_equal(
    unname(public$corpars$mu),
    0.99999999 * 0.35,
    tolerance = 1e-12
  )

  expect_null(drm_julia_ordinary_binomial_recov_label(formula, "poisson"))
  expect_null(drm_julia_ordinary_binomial_recov_label(
    bf(y ~ x + (1 | id)), "binomial"
  ))
  expect_null(drm_julia_ordinary_binomial_recov_label(
    bf(y ~ x + (1 + x | p | id)), "binomial"
  ))
  expect_null(drm_julia_ordinary_binomial_recov_label(
    bf(y ~ x + (1 + x | id) + (1 + x | site)), "binomial"
  ))
})

test_that("Julia Bernoulli q2 correlation is an inference target", {
  dat <- data.frame(
    y = c(0L, 1L, 0L, 1L),
    x = c(-1, 1, -1, 1),
    id = factor(rep(c("a", "b"), each = 2L))
  )
  form <- bf(y ~ x + (1 + x | id))
  fit <- structure(
    list(
      formula = form,
      model = list(model_type = "binomial"),
      coefficients = list(mu = c("(Intercept)" = 0, x = 0.2)),
      sdpars = list(mu = numeric(), sigma = numeric()),
      corpars = list(mu = c("cor((Intercept),x | id)" = 0.99999999 * 0.35)),
      bridge_payload = list(
        formula = form,
        data = dat,
        tree = NULL,
        matrix = NULL,
        kwarg = NULL,
        options = list()
      )
    ),
    class = "drmTMB_julia"
  )

  targets <- profile_targets(fit)
  target <- targets[
    targets$target_class == "random-effect-correlation",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(target), 1L)
  expect_identical(target$parm, "cor:mu:cor((Intercept),x | id)")
  expect_equal(target$estimate, 0.99999999 * 0.35)
  expect_equal(target$link_estimate, atanh(0.35), tolerance = 1e-12)
  expect_identical(target$transformation, "tanh")
  expect_true(target$profile_ready)

  testthat::local_mocked_bindings(
    drm_julia_call_fixef_inference = function(
      object, target, method, level, R, seed, threads
    ) {
      expect_identical(target$dpar, "recov")
      expect_identical(target$term, "id:atanh_rho")
      raw_limits <- atanh(c(0.1, 0.6) / 0.99999999)
      c(
        list(lower = raw_limits[[1L]], upper = raw_limits[[2L]]),
        list(
          status = if (method == "profile") "profile" else "bootstrap",
          message = "synthetic coefficient-scale limits",
          threaded = FALSE,
          worker_threads = 1L,
          julia_threads = 1L,
          blas_threads = 1L,
          elapsed = 0.1,
          attempted = 10L,
          used = 9L,
          failed = 1L
        )
      )
    }
  )

  profile <- confint(
    fit,
    parm = target$parm,
    method = "profile",
    level = 0.95
  )
  expect_equal(profile$lower, 0.1, tolerance = 1e-12)
  expect_equal(profile$upper, 0.6, tolerance = 1e-12)
  expect_identical(profile$transformation, "tanh")

  bootstrap <- confint(
    fit,
    parm = target$parm,
    method = "bootstrap",
    R = 10L,
    level = 0.95
  )
  expect_equal(bootstrap$lower, 0.1, tolerance = 1e-12)
  expect_equal(bootstrap$upper, 0.6, tolerance = 1e-12)
  expect_equal(bootstrap$bootstrap.n, 9L)
  expect_equal(bootstrap$bootstrap.failed, 1L)
  expect_error(
    confint(fit, parm = target$parm, method = "wald"),
    "Wald intervals.*not available"
  )
})

test_that("Julia bridge preserves correlated Bernoulli SD targets on reload", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")

  set.seed(20261018)
  groups <- 24L
  repeats <- 8L
  id <- factor(rep(seq_len(groups), each = repeats))
  x <- stats::rnorm(length(id))
  w_group <- seq(-1, 1, length.out = groups)
  v_group <- rep(c(-1, 1), length.out = groups)
  w <- rep(w_group, each = repeats)
  v <- rep(v_group, each = repeats)
  rho <- 0.35
  z0 <- stats::rnorm(groups)
  z1 <- stats::rnorm(groups)
  b0 <- exp(-0.35 + 0.25 * w_group) * z0
  b1 <- exp(-0.65 + 0.2 * v_group) *
    (rho * z0 + sqrt(1 - rho^2) * z1)
  y <- stats::rbinom(
    length(id), 1L,
    stats::plogis(0.15 + 0.3 * x + b0[as.integer(id)] + b1[as.integer(id)] * x)
  )
  dat <- data.frame(y, x, w, v, id)
  key_intercept <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
  key_slope <- 'sd(id, dpar = "mu", coef = "x")'
  formula <- bf(
    y ~ x + (1 + x | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w,
    sd(id, dpar = "mu", coef = "x") ~ v
  )

  fit <- drmTMB(formula, family = stats::binomial(), data = dat, engine = "julia")
  expect_true(is_converged(fit))
  expect_named(fit$corpars$mu, "cor((Intercept),x | id)")
  expect_true(is.finite(unname(fit$corpars$mu)))
  expect_true(all(is.finite(coef(fit, key_intercept))))
  expect_true(all(is.finite(coef(fit, key_slope))))
  pred_intercept <- predict(fit, newdata = dat[1:8, ], dpar = key_intercept)
  pred_slope <- predict(fit, newdata = dat[1:8, ], dpar = key_slope)
  expect_true(all(is.finite(pred_intercept)))
  expect_true(all(is.finite(pred_slope)))

  path <- tempfile(fileext = ".rds")
  saveRDS(fit, path)
  restored <- readRDS(path)
  expect_identical(coef(restored), coef(fit))
  expect_identical(
    predict(restored, newdata = dat[1:8, ], dpar = key_intercept),
    pred_intercept
  )
  expect_identical(
    predict(restored, newdata = dat[1:8, ], dpar = key_slope),
    pred_slope
  )
})

test_that("correlated Bernoulli q2 SD point and outputs compare across engines", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")

  # Reuse the native correlated-q2 synthetic design. This is a point/output
  # comparison only: 64 group-level latent draws do not establish that all
  # seven fitted parameters are practically well identified.
  set.seed(2026101819L)
  groups <- 64L
  repeats <- 32L
  id <- factor(rep(seq_len(groups), each = repeats))
  x <- stats::rnorm(length(id))
  w_group <- seq(-1, 1, length.out = groups)
  v_group <- rep(c(-1, 1), length.out = groups)
  w <- rep(w_group, each = repeats)
  v <- rep(v_group, each = repeats)
  tau0 <- exp(log(0.55) + 0.4 * w_group)
  tau1 <- exp(log(0.32) - 0.6 * v_group)
  rho <- 0.4
  z0 <- stats::rnorm(groups)
  z1 <- stats::rnorm(groups)
  b0 <- tau0 * z0
  b1 <- tau1 * (rho * z0 + sqrt(1 - rho^2) * z1)
  y <- stats::rbinom(
    length(id), 1L,
    stats::plogis(-0.15 + 0.3 * x + b0[as.integer(id)] +
                    b1[as.integer(id)] * x)
  )
  dat <- data.frame(y, x, w, v, id)
  key_intercept <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
  key_slope <- 'sd(id, dpar = "mu", coef = "x")'
  formula <- bf(
    y ~ x + (1 + x | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w,
    sd(id, dpar = "mu", coef = "x") ~ v
  )

  native <- drmTMB(
    formula, family = stats::binomial(), data = dat, engine = "tmb"
  )
  julia <- drmTMB(
    formula, family = stats::binomial(), data = dat, engine = "julia"
  )

  expect_true(is_converged(native))
  expect_true(is_converged(julia))
  expect_true(isTRUE(native$sdr$pdHess))
  expect_true(all(is.finite(coef(native, key_intercept))))
  expect_true(all(is.finite(coef(native, key_slope))))
  expect_true(all(is.finite(coef(julia, key_intercept))))
  expect_true(all(is.finite(coef(julia, key_slope))))
  expect_named(native$corpars$mu, "cor((Intercept),x | id)")
  expect_named(julia$corpars$mu, names(native$corpars$mu))

  # The engines use different integration approximations. Compare the
  # shared fixed effects, coefficient-specific SD regressions, and latent
  # correlation at point-estimate scale; likelihood equality is not required.
  expect_equal(coef(julia, "mu"), coef(native, "mu"), tolerance = 0.2)
  expect_equal(
    coef(julia, key_intercept), coef(native, key_intercept), tolerance = 0.25
  )
  expect_equal(
    coef(julia, key_slope), coef(native, key_slope), tolerance = 0.25
  )
  expect_equal(
    unname(julia$corpars$mu), unname(native$corpars$mu), tolerance = 0.2
  )
  for (target in c(key_intercept, key_slope)) {
    native_prediction <- predict_parameters(
      native, dpar = target, include_newdata = FALSE
    )
    julia_prediction <- predict_parameters(
      julia, dpar = target, include_newdata = FALSE
    )
    expect_identical(julia_prediction$row_label, native_prediction$row_label)
    expect_equal(
      julia_prediction$estimate, native_prediction$estimate, tolerance = 0.35
    )
  }

  # This checks that the full bridge retains the q2 correlation as a
  # response-scale inference target. One profile and five bootstrap refits are
  # plumbing checks only; they do not measure interval coverage.
  correlation_parm <- "cor:mu:cor((Intercept),x | id)"
  correlation_target <- profile_targets(julia)
  correlation_target <- correlation_target[
    correlation_target$parm == correlation_parm,
    ,
    drop = FALSE
  ]
  expect_equal(nrow(correlation_target), 1L)
  expect_true(correlation_target$profile_ready)
  expect_equal(
    correlation_target$estimate,
    unname(julia$corpars$mu),
    tolerance = 1e-12
  )
  expect_false(any(grepl("recov", rownames(vcov(julia)), fixed = TRUE)))

  profile_interval <- confint(
    julia,
    parm = correlation_parm,
    method = "profile"
  )
  expect_identical(profile_interval$parm, correlation_parm)
  expect_true(is.finite(profile_interval$lower))
  expect_true(is.finite(profile_interval$upper))
  expect_lt(profile_interval$lower, profile_interval$upper)
  expect_true(abs(profile_interval$lower) < 1)
  expect_true(abs(profile_interval$upper) < 1)

  bootstrap_interval <- confint(
    julia,
    parm = correlation_parm,
    method = "bootstrap",
    R = 5L,
    seed = 2026101919L
  )
  expect_identical(bootstrap_interval$parm, correlation_parm)
  expect_equal(
    bootstrap_interval$bootstrap.n + bootstrap_interval$bootstrap.failed,
    5L
  )
  expect_true(bootstrap_interval$bootstrap.n >= 2L)
  expect_true(is.finite(bootstrap_interval$lower))
  expect_true(is.finite(bootstrap_interval$upper))
  expect_lt(bootstrap_interval$lower, bootstrap_interval$upper)
  expect_true(abs(bootstrap_interval$lower) < 1)
  expect_true(abs(bootstrap_interval$upper) < 1)
})

test_that("Julia Binomial SD prediction refuses within-group predictor changes", {
  dat <- data.frame(
    y = c(0, 1, 0, 1), x = c(-1, 1, -1, 1),
    w = c(-1, -1, 1, 1), g = rep(c("a", "b"), each = 2L)
  )
  object <- list(
    formula = drm_formula(y ~ x + (1 | g), sd(g) ~ w), data = dat,
    coefficients = list(mu = c("(Intercept)" = 0, x = 0.2),
                        sd = c("(Intercept)" = 0, w = 0.4))
  )
  newdata <- dat
  newdata$w[[2L]] <- 0.5
  expect_error(
    drm_julia_predict_sd(object, "sd(g)", newdata),
    "constant within each random-effect group"
  )
})

test_that("public Julia Bernoulli SD outputs match the fitted target", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")

  # At 120 groups this seed had a log-SD slope error of 0.30 (about 2.2 SE).
  # Keep the recovery smoke in the higher-information part of the n ladder.
  sim <- binomial_sd_fixture(groups = 300L, repeats = 12L, seed = 1701L)
  form <- bf(y ~ x + (1 | id), sd(id) ~ w)
  native_fit <- drmTMB(
    form, family = stats::binomial(), data = sim$data, engine = "tmb"
  )
  fit <- drmTMB(
    form,
    family = stats::binomial(), data = sim$data, engine = "julia"
  )

  alpha <- coef(fit, dpar = "sd(id)")
  native_alpha <- coef(native_fit, dpar = "sd(id)")
  expect_named(alpha, c("(Intercept)", "w"))
  expect_named(native_alpha, names(alpha))
  expect_equal(unname(alpha), unname(sim$alpha), tolerance = 0.25)
  expect_equal(unname(native_alpha), unname(sim$alpha), tolerance = 0.25)
  # A single paired high-information fixture checks engine alignment only; it
  # does not establish interval calibration or broader capability parity.
  expect_equal(unname(alpha), unname(native_alpha), tolerance = 0.05)
  expect_equal(native_fit$opt$convergence, 0L)
  expect_true(native_fit$sdr$pdHess)
  expect_equal(fit$opt$convergence, 0L)
  expect_true(isTRUE(fit$bridge$converged))
  expect_named(fit$sdpars[["sd(id)"]], paste0("sd(id):", levels(sim$data$id)))
  expect_equal(
    unname(fit$sdpars[["sd(id)"]]),
    unname(predict(fit, dpar = "sd(id)")),
    tolerance = 1e-10
  )
  expect_equal(
    unname(predict(native_fit, dpar = "sd(id)")),
    unname(predict(fit, dpar = "sd(id)")),
    tolerance = 0.05
  )
  expect_equal(
    predict(fit, dpar = "sd(id)", type = "response"),
    exp(predict(fit, dpar = "sd(id)", type = "link")),
    tolerance = 1e-12
  )
  sd_table <- predict_parameters(
    fit, dpar = "sd(id)", include_newdata = FALSE
  )
  expect_identical(unique(sd_table$dpar), "sd(id)")
  expect_equal(nrow(sd_table), nlevels(sim$data$id))
  expect_setequal(sd_table$row_label, levels(sim$data$id))
  fresh <- sim$data[c(2L, 1L, 14L, 13L), , drop = FALSE]
  fresh_sd <- predict(fit, newdata = fresh, dpar = "sd(id)")
  expect_length(fresh_sd, nrow(fresh))
  expect_named(fresh_sd, row.names(fresh))
  expect_equal(unname(fresh_sd[c(1L, 2L)]),
               rep(unname(fit$sdpars[["sd(id)"]][[1L]]), 2L))
  expect_length(sigma(fit), 0L)
  expect_named(fit$bridge$dpars, "mu")
  distribution_params <- fitted_distribution_params(
    fit, newdata = NULL, dpars = "mu"
  )
  expect_named(distribution_params, c("mu", "trials"))
  expect_equal(nrow(distribution_params), nrow(sim$data))
  expect_equal(distribution_params$trials, rep(1, nrow(sim$data)))
  distribution <- fitted_distribution(fit)
  expect_s3_class(distribution, "drm_fitted_distribution")
  expect_named(distribution$params, c("mu", "trials"))
  expect_equal(nrow(distribution$params), nrow(sim$data))
  expect_equal(distribution$params$trials, rep(1, nrow(sim$data)))
  expect_false(any(c("sd", "sd_group", "sd_group_index", "aghq_nodes") %in%
                   names(distribution_params)))
  expect_true(any(grepl("^sd_", rownames(vcov(fit)))))

  path <- tempfile(fileext = ".rds")
  saveRDS(fit, path)
  restored <- readRDS(path)
  expect_equal(predict(restored, dpar = "sd(id)"), predict(fit, dpar = "sd(id)"))

  # The Julia bridge profiles an SD-regression coefficient as an ordinary
  # coefficient in its `sd` block. Accept the native canonical name and keep
  # the returned target attached to that coefficient block.
  targets <- profile_targets(fit)
  expect_true("fixef:sd:w" %in% targets$parm)
  ci_sd_slope <- confint(
    fit, parm = "fixef:sd(id):w", method = "profile", level = 0.80
  )
  expect_equal(ci_sd_slope$parm, "fixef:sd:w")
  expect_equal(ci_sd_slope$method, "profile")

  # A tiny parametric-bootstrap smoke check confirms the same canonical
  # coefficient target survives simulation and refitting. This is plumbing
  # evidence only, not an interval-calibration result.
  ci_sd_slope_boot <- confint(
    fit, parm = "fixef:sd(id):w", method = "bootstrap", R = 3L,
    seed = 1702L, level = 0.80
  )
  expect_equal(ci_sd_slope_boot$parm, "fixef:sd:w")
  expect_equal(ci_sd_slope_boot$method, "bootstrap")
})

test_that("public Julia Bernoulli SD regression recovers an independent random slope", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")

  set.seed(20261018L)
  groups <- 100L
  repeats <- 30L
  id <- factor(rep(seq_len(groups), each = repeats))
  w_group <- rep(c(-1, 1), each = groups / 2L)
  w <- rep(w_group, each = repeats)
  x <- rep(rep(c(-1, 1), length.out = repeats), groups)
  alpha <- c("(Intercept)" = -0.7, w = 0.4)
  group_sd <- exp(alpha[[1L]] + alpha[["w"]] * w_group)
  group_slope <- stats::rnorm(groups, sd = group_sd)
  eta <- 0.2 + x * (0.6 + rep(group_slope, each = repeats))
  dat <- data.frame(y = stats::rbinom(length(eta), 1L, stats::plogis(eta)),
                    x = x, w = w, id = id)

  fit <- drmTMB(
    bf(y ~ x + (0 + x | id), sd(id) ~ w),
    family = stats::binomial(), data = dat, engine = "julia"
  )
  tmb_fit <- drmTMB(
    bf(y ~ x + (0 + x | id), sd(id) ~ w),
    family = stats::binomial(), data = dat, engine = "tmb"
  )

  expect_true(is_converged(fit))
  expect_named(coef(fit, dpar = "sd(id)"), c("(Intercept)", "w"))
  expect_equal(unname(coef(fit, dpar = "sd(id)")), unname(alpha),
               tolerance = 0.35)
  expect_true(is_converged(tmb_fit))
  expect_equal(
    unname(coef(fit, dpar = "sd(id)")),
    unname(coef(tmb_fit, dpar = "sd(id)")),
    tolerance = 0.35
  )
  expect_equal(
    unname(predict(fit, dpar = "sd(id)")),
    unname(predict(tmb_fit, dpar = "sd(id)")),
    tolerance = 0.45
  )
  expect_named(fit$sdpars[["sd(id)"]], paste0("sd(id):", levels(id)))
  expected_sd <- exp(alpha[[1L]] + alpha[["w"]] * w_group)
  expect_equal(unname(fit$sdpars[["sd(id)"]]), expected_sd,
               tolerance = 0.45)
  sd_table <- predict_parameters(fit, dpar = "sd(id)", include_newdata = FALSE)
  expect_identical(unique(sd_table$dpar), "sd(id)")
  expect_setequal(sd_table$row_label, levels(id))
  expect_equal(unname(predict(fit, dpar = "sd(id)")),
               unname(fit$sdpars[["sd(id)"]]), tolerance = 1e-10)

  # This is a point-recovery and public-output check, not an interval
  # calibration result. The intercept route above separately exercises
  # profile and bootstrap refitting through the bridge.
  path <- tempfile(fileext = ".rds")
  saveRDS(fit, path)
  restored <- readRDS(path)
  expect_equal(predict(restored, dpar = "sd(id)"),
               predict(fit, dpar = "sd(id)"), tolerance = 1e-12)
})

test_that("Julia bridge fits separate Bernoulli SD targets on one group", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")

  set.seed(20261019L)
  # Match the information level of the independently passing Julia q=2
  # recovery fixture: the random-slope SD regression needs repeated within-
  # group observations as well as many groups.
  groups <- 60L
  repeats <- 40L
  id <- factor(rep(seq_len(groups), each = repeats))
  w_intercept_group <- rep(c(-1, 1), each = groups / 2L)
  w_slope_group <- rep(rep(c(-1, 1), each = groups / 4L), 2L)
  w_intercept <- w_intercept_group[as.integer(id)]
  w_slope <- w_slope_group[as.integer(id)]
  x <- stats::rnorm(groups * repeats)
  alpha_intercept <- c(-0.7, 0.35)
  alpha_slope <- c(-0.9, 0.45)
  b_intercept <- stats::rnorm(groups,
    sd = exp(alpha_intercept[[1L]] + alpha_intercept[[2L]] * w_intercept_group)
  )
  b_slope <- stats::rnorm(groups,
    sd = exp(alpha_slope[[1L]] + alpha_slope[[2L]] * w_slope_group)
  )
  eta <- 0.2 + 0.3 * x + b_intercept[as.integer(id)] +
    x * b_slope[as.integer(id)]
  dat <- data.frame(y = stats::rbinom(length(eta), 1L, stats::plogis(eta)),
                    x = x, w_intercept = w_intercept, w_slope = w_slope,
                    id = id)
  fit <- drmTMB(
    bf(
      y ~ x + (1 | id) + (0 + x | id),
      sd(id, dpar = "mu", coef = "(Intercept)") ~ w_intercept,
      sd(id, dpar = "mu", coef = "x") ~ w_slope
    ),
    family = stats::binomial(), data = dat, engine = "julia"
  )

  expect_true(is_converged(fit))
  expect_equal(
    unname(coef(fit, dpar = 'sd(id, dpar = "mu", coef = "(Intercept)")')),
    unname(alpha_intercept), tolerance = 0.45
  )
  expect_equal(
    unname(coef(fit, dpar = 'sd(id, dpar = "mu", coef = "x")')),
    unname(alpha_slope), tolerance = 0.45
  )
  sd_intercept <- predict(fit, dpar = 'sd(id, dpar = "mu", coef = "(Intercept)")')
  sd_slope <- predict(fit, dpar = 'sd(id, dpar = "mu", coef = "x")')
  expect_length(sd_intercept, groups)
  expect_length(sd_slope, groups)
  expect_true(all(is.finite(sd_intercept) & sd_intercept > 0))
  expect_true(all(is.finite(sd_slope) & sd_slope > 0))

  # The target descriptor must survive coefficient selection and profile /
  # bootstrap refits, not only the initial fit and prediction calls.
  slope_target <- 'sd(id, dpar = "mu", coef = "x")'
  slope_profile_name <- paste0("fixef:", slope_target, ":w_slope")
  expect_true(slope_profile_name %in% profile_targets(fit)$parm)
  slope_profile <- confint(
    fit, parm = slope_profile_name, method = "profile", level = 0.80
  )
  expect_equal(slope_profile$parm, slope_profile_name)
  expect_equal(slope_profile$method, "profile")
  slope_bootstrap <- confint(
    fit, parm = slope_profile_name, method = "bootstrap", R = 3L,
    seed = 20261020L, level = 0.80
  )
  expect_equal(slope_bootstrap$parm, slope_profile_name)
  expect_equal(slope_bootstrap$method, "bootstrap")
  expect_equal(slope_bootstrap$conf.status, "bootstrap")
  expect_equal(
    slope_bootstrap$bootstrap.n + slope_bootstrap$bootstrap.failed,
    3L
  )
  expect_gte(slope_bootstrap$bootstrap.n, 1L)
  expect_gte(slope_bootstrap$bootstrap.failed, 0L)
  expect_true(is.finite(slope_bootstrap$lower))
  expect_true(is.finite(slope_bootstrap$upper))
})

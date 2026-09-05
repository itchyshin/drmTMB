test_that("Julia bridge serializes drm_formula() objects", {
  form <- bf(y ~ x, sigma ~ z)
  spec <- drmTMB:::drm_julia_formula_spec(form)

  expect_equal(names(spec), c("mu", "sigma"))
  expect_equal(spec$mu, "y ~ x")
  expect_equal(spec$sigma, "sigma ~ z")

  biform <- bf(
    mu1 = y1 ~ x,
    mu2 = y2 ~ x,
    sigma1 = ~z,
    sigma2 = ~1,
    rho12 = ~x
  )
  bispec <- drmTMB:::drm_julia_formula_spec(biform)

  expect_equal(
    bispec,
    list(
      mu1 = "y1 ~ x",
      mu2 = "y2 ~ x",
      sigma1 = "sigma1 ~ z",
      sigma2 = "sigma2 ~ 1",
      rho12 = "rho12 ~ x"
    )
  )

  tree <- structure(
    list(
      edge = matrix(
        c(7, 5, 7, 6, 5, 1, 5, 2, 6, 3, 6, 4),
        ncol = 2,
        byrow = TRUE
      ),
      edge.length = rep(1, 6),
      tip.label = paste0("sp_", 1:4),
      Nnode = 3L
    ),
    class = "phylo"
  )
  phylo_form <- bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)
  phylo_spec <- drmTMB:::drm_julia_formula_spec(phylo_form)

  expect_equal(
    phylo_spec,
    list(
      mu = "y ~ x + phylo(1 | species)",
      sigma = "sigma ~ 1"
    )
  )
})

test_that("bivariate parameter aliases are not required data columns", {
  form <- bf(
    mu1 = y1 ~ x,
    mu2 = y2 ~ x,
    sigma1 = sigma1 ~ 1,
    sigma2 = sigma2 ~ 1,
    rho12 = rho12 ~ 1
  )
  dat <- data.frame(y1 = c(1, 2, 3), y2 = c(4, 5, 6), x = c(-1, 0, 1))

  marshalled <- drmTMB:::drm_julia_bridge_data(dat, form)

  expect_identical(names(marshalled), c("y1", "x", "y2"))
  expect_equal(marshalled, dat[, c("y1", "x", "y2")])
})

test_that("Julia bridge marshals one phylogenetic tree", {
  tree <- structure(
    list(
      edge = matrix(
        c(7, 5, 7, 6, 5, 1, 5, 2, 6, 3, 6, 4),
        ncol = 2,
        byrow = TRUE
      ),
      edge.length = rep(1, 6),
      tip.label = paste0("sp_", 1:4),
      Nnode = 3L
    ),
    class = "phylo"
  )
  dat <- data.frame(
    y = seq_len(6),
    x = seq(-1, 1, length.out = 6),
    species = factor(
      c("sp_3", "sp_1", "sp_4", "sp_2", "sp_1", "sp_3"),
      levels = c("sp_3", "sp_1", "sp_4", "sp_2")
    ),
    unused = letters[seq_len(6)]
  )
  form <- bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)
  cache <- get("drm_julia_phylo_payload_cache", asNamespace("drmTMB"))
  rm(list = ls(cache, all.names = TRUE), envir = cache)
  on.exit(rm(list = ls(cache, all.names = TRUE), envir = cache), add = TRUE)

  tree_payload <- drmTMB:::drm_julia_phylo_tree_payload(tree)
  cache$payload$newick <- "cached-tree;"
  expect_identical(
    drmTMB:::drm_julia_phylo_tree_payload(tree)$newick,
    "cached-tree;"
  )
  rm(list = ls(cache, all.names = TRUE), envir = cache)

  phylo_payload <- drmTMB:::drm_julia_phylo_payload(
    formula = form,
    family_type = "gaussian",
    data = dat,
    env = environment()
  )
  cache$full_payload$newick <- "cached-full-tree;"
  expect_identical(
    drmTMB:::drm_julia_phylo_payload(
      formula = form,
      family_type = "gaussian",
      data = dat,
      env = environment()
    )$newick,
    "cached-full-tree;"
  )
  expect_equal(phylo_payload$row_order, c(2L, 5L, 4L, 1L, 6L, 3L))
  rm(list = ls(cache, all.names = TRUE), envir = cache)

  payload <- drmTMB:::drm_julia_bridge_payload(
    formula = form,
    family_type = "gaussian",
    data = dat,
    env = environment()
  )

  expect_equal(payload$formula$mu, "y ~ x + phylo(1 | species)")
  expect_match(payload$tree, "^\\(\\(sp_1:1")
  expect_equal(names(payload$data), c("y", "x", "species"))
  expect_equal(drm_test_options_sans_labels(payload$options), list(g_tol = 1e-8))
  expect_true(is.list(payload$options$coef_labels))
  expect_equal(
    payload$structured_sd_scales,
    c("phylo(1 | species)" = sqrt(2)),
    tolerance = 1e-12
  )
  expect_equal(
    payload$data$species,
    c("sp_1", "sp_1", "sp_2", "sp_3", "sp_3", "sp_4")
  )
  expect_type(payload$data$species, "character")

  result <- list(
    fitted = seq_along(payload$row_order),
    residuals = seq_along(payload$row_order) + 10,
    sigma = seq_along(payload$row_order) + 20
  )
  restored <- drmTMB:::drm_julia_restore_row_order(result, payload$row_order)
  expect_equal(restored$fitted, c(4, 1, 6, 3, 2, 5))
  expect_equal(restored$residuals, c(14, 11, 16, 13, 12, 15))
  expect_equal(restored$sigma, c(24, 21, 26, 23, 22, 25))

  # The sigma ~ 1 fence for phylogenetic bridge fits is LIFTED (DRM.jl#548
  # fixed and parity-verified): a predictor-dependent residual scale now
  # ROUTES instead of refusing, tagged with its own locscale mode.
  expect_no_error(drmTMB:::drm_julia_bridge_payload(
    formula = bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ x),
    family_type = "gaussian",
    data = dat,
    env = environment()
  ))
})

test_that("Julia bridge object exposes standard fitted-model methods", {
  result <- list(
    coef_names = c("mu_(Intercept)", "mu_x", "sigma_(Intercept)", "sigma_x"),
    coefficients = c(0.1, 0.4, -0.2, 0.3),
    vcov = diag(c(0.01, 0.02, 0.03, 0.04)),
    loglik = -12.5,
    aic = 33,
    bic = 35,
    df = 4L,
    nobs = 6L,
    converged = TRUE,
    fitted = seq_len(6),
    residuals = rep(0.1, 6),
    sigma = rep(0.8, 6),
    corpairs = list()
  )

  fit <- drmTMB:::new_drmTMB_julia(
    result = result,
    call = quote(drmTMB(bf(y ~ x, sigma ~ x), data = dat, engine = "julia")),
    formula = bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = data.frame(y = seq_len(6), x = seq_len(6)),
    family_type = "gaussian"
  )

  expect_s3_class(fit, "drmTMB_julia")
  expect_equal(fit$estimator, "ML")
  expect_false(fit$REML)
  expect_false(fit$requested_REML)
  expect_false(fit$effective_REML)
  expect_equal(coef(fit, "mu"), c("(Intercept)" = 0.1, x = 0.4))
  expect_equal(coef(fit, "sigma"), c("(Intercept)" = -0.2, x = 0.3))
  expect_equal(fixef(fit), coef(fit))
  expect_equal(dim(stats::vcov(fit)), c(4L, 4L))
  expect_s3_class(stats::logLik(fit), "logLik")
  expect_equal(stats::nobs(fit), 6L)
  expect_equal(stats::df.residual(fit), 2L)
  expect_equal(stats::deviance(fit), 25)
  expect_equal(stats::fitted(fit), seq_len(6))
  expect_equal(stats::residuals(fit), rep(0.1, 6))
  expect_equal(stats::sigma(fit), rep(0.8, 6))
  # These deliberately disagree with the fixture's raw `fitted` and `sigma`
  # slots above.  Julia bridge prediction reconstructs the fixed-effect dpar
  # from the retained formula and coefficients, rather than returning a slot
  # whose scale/conditional semantics may differ by engine route.
  expect_equal(predict(fit, dpar = "mu"), 0.1 + 0.4 * seq_len(6))
  expect_equal(predict(fit, dpar = "sigma"), exp(-0.2 + 0.3 * seq_len(6)))
  expect_true(is_converged(fit))
  expect_error(rho12(fit), "no residual")
  # newdata mu prediction is population-level (RE = 0); identity link here, so
  # the response equals the fixed-effect linear predictor 0.1 + 0.4 * x.
  expect_equal(predict(fit, newdata = data.frame(x = 1)), 0.5)
  expect_equal(
    predict(fit, newdata = data.frame(x = 1), type = "link"),
    0.5
  )
  expect_equal(
    predict(fit, newdata = data.frame(x = 1), dpar = "sigma"),
    exp(-0.2 + 0.3)
  )
})

test_that("Julia bivariate residual bridge exposes Hopper #5 result-shape methods", {
  # Offline reconstruction of DRM.jl drm_bridge flatten keys for Route B —
  # Gaussian biv residual rho12, no phylo. Live TMB parity stays in
  # test-julia-tmb-parity.R (skips without JuliaCall).
  n <- 6L
  result <- list(
    coef_names = c(
      "mu1_(Intercept)",
      "mu1_x",
      "mu2_(Intercept)",
      "mu2_x",
      "sigma1_(Intercept)",
      "sigma2_(Intercept)",
      "rho12_(Intercept)"
    ),
    coefficients = c(0.1, 0.4, -0.1, 0.3, 0.0, 0.1, 0.2),
    vcov = diag(7),
    loglik = -20.5,
    aic = 55,
    bic = 56.5,
    df = 7L,
    nobs = n,
    converged = TRUE,
    fitted = list(mu1 = seq_len(n), mu2 = seq_len(n) + 0.5),
    residuals = list(mu1 = rep(0.1, n), mu2 = rep(-0.1, n)),
    sigma = list(sigma1 = rep(0.8, n), sigma2 = rep(0.9, n)),
    corpairs = rep(tanh(0.2), n)
  )
  form <- bf(
    mu1 = y1 ~ x,
    mu2 = y2 ~ x,
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1
  )
  dat <- data.frame(
    y1 = seq_len(n),
    y2 = seq_len(n) + 0.5,
    x = seq_len(n)
  )

  fit <- drmTMB:::new_drmTMB_julia(
    result = result,
    call = quote(drmTMB(form, data = dat, family = biv_gaussian(), engine = "julia")),
    formula = form,
    family = biv_gaussian(),
    data = dat,
    family_type = "biv_gaussian"
  )

  expect_s3_class(fit, "drmTMB_julia")
  expect_equal(fit$model$model_type, "biv_gaussian")
  expect_equal(coef(fit, "mu1"), c("(Intercept)" = 0.1, x = 0.4))
  expect_equal(coef(fit, "mu2"), c("(Intercept)" = -0.1, x = 0.3))
  expect_equal(coef(fit, "sigma1"), c("(Intercept)" = 0.0))
  expect_equal(coef(fit, "sigma2"), c("(Intercept)" = 0.1))
  expect_equal(coef(fit, "rho12"), c("(Intercept)" = 0.2))
  expect_equal(dim(stats::vcov(fit)), c(7L, 7L))
  expect_equal(as.numeric(stats::logLik(fit)), -20.5)
  expect_equal(stats::nobs(fit), n)
  expect_true(is_converged(fit))
  expect_equal(stats::fitted(fit)$mu1, seq_len(n))
  expect_equal(stats::fitted(fit)$mu2, seq_len(n) + 0.5)
  expect_equal(stats::residuals(fit)$mu1, rep(0.1, n))
  expect_equal(stats::sigma(fit)$sigma1, rep(0.8, n))
  expect_equal(stats::sigma(fit)$sigma2, rep(0.9, n))
  expect_equal(rho12(fit), rep(tanh(0.2), n))
})

test_that("Julia phylo bridge keeps structured scales out of fixed effects", {
  tree <- structure(
    list(
      edge = matrix(
        c(7, 5, 7, 6, 5, 1, 5, 2, 6, 3, 6, 4),
        ncol = 2,
        byrow = TRUE
      ),
      edge.length = rep(1, 6),
      tip.label = paste0("sp_", 1:4),
      Nnode = 3L
    ),
    class = "phylo"
  )
  result <- list(
    coef_names = c(
      "mu_(Intercept)",
      "mu_x",
      "sigma_(Intercept)",
      "resd_species"
    ),
    coefficients = c(0.1, 0.4, -0.2, log(1.7)),
    vcov = matrix(NaN, nrow = 4L, ncol = 4L),
    loglik = -12.5,
    aic = 33,
    bic = 35,
    df = 4L,
    nobs = 6L,
    converged = TRUE,
    fitted = seq_len(6),
    residuals = rep(0.1, 6),
    sigma = rep(0.8, 6),
    corpairs = list()
  )
  form <- bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)

  fit <- drmTMB:::new_drmTMB_julia(
    result = result,
    call = quote(drmTMB(form, data = dat, engine = "julia")),
    formula = form,
    family = gaussian(),
    data = data.frame(
      y = seq_len(6),
      x = seq_len(6),
      species = paste0("sp_", c(1, 1, 2, 3, 3, 4))
    ),
    family_type = "gaussian",
    structured_sd_scales = c("phylo(1 | species)" = sqrt(2)),
    bridge_payload = list(
      formula = list(
        mu = "y ~ x + phylo(1 | species)",
        sigma = "sigma ~ 1"
      ),
      data = data.frame(
        y = seq_len(6),
        x = seq_len(6),
        species = paste0("sp_", c(1, 1, 2, 3, 3, 4))
      ),
      tree = "((sp_1:1,sp_2:1):1,(sp_3:1,sp_4:1):1);",
      options = list(g_tol = 1e-4),
      structured_sd_scales = c("phylo(1 | species)" = sqrt(2))
    )
  )

  expect_equal(names(coef(fit)), c("mu", "sigma"))
  expect_equal(coef(fit, "mu"), c("(Intercept)" = 0.1, x = 0.4))
  expect_equal(coef(fit, "sigma"), c("(Intercept)" = -0.2))
  expect_equal(
    fit$sdpars$mu,
    c("phylo(1 | species)" = 1.7 * sqrt(2)),
    tolerance = 1e-12
  )
  expect_equal(dim(stats::vcov(fit)), c(3L, 3L))
  expect_named(
    fit$coef_vector,
    c("mu_(Intercept)", "mu_x", "sigma_(Intercept)")
  )
  expect_equal(fit$uncertainty$status, "unavailable")
  expect_equal(fit$uncertainty$se, FALSE)

  targets <- profile_targets(fit)
  # #1156: discovery lists the union the engine accepts -- fixed effects, the
  # response-scale sigma alias, and the phylogenetic SD -- not the SD alone.
  expect_equal(
    targets$parm,
    c(
      "fixef:mu:(Intercept)", "fixef:mu:x", "fixef:sigma:(Intercept)",
      "sigma", "sd:mu:phylo(1 | species)"
    )
  )
  targets <- targets[targets$parm == "sd:mu:phylo(1 | species)", , drop = FALSE]
  expect_equal(targets$tmb_parameter, "resd")
  expect_equal(targets$estimate, 1.7 * sqrt(2), tolerance = 1e-12)
  expect_equal(targets$link_estimate, log(1.7), tolerance = 1e-12)
  expect_equal(targets$profile_ready, TRUE)

  ci <- drmTMB:::drm_julia_inference_confint_row(
    target = targets,
    result = list(
      lower = log(1.1),
      upper = log(2.1),
      status = "profile",
      message = "profile_result completed",
      threaded = FALSE,
      worker_threads = 1L,
      julia_threads = 1L,
      blas_threads = 1L,
      elapsed = 0.25
    ),
    level = 0.80,
    method = "profile"
  )
  expect_equal(ci$lower, 1.1 * sqrt(2), tolerance = 1e-12)
  expect_equal(ci$upper, 2.1 * sqrt(2), tolerance = 1e-12)
  expect_equal(ci$profile.engine, "julia_profile_result")
  expect_equal(ci$julia.workers, 1L)
  testthat::local_mocked_bindings(
    drm_julia_call_inference = function(
      object,
      target,
      method,
      level,
      R,
      seed,
      threads
    ) {
      expect_s3_class(object, "drmTMB_julia")
      expect_equal(target$dpar[[1L]], "mu")
      expect_equal(method, "profile")
      expect_equal(level, 0.80)
      expect_equal(R, 1L)
      expect_null(seed)
      expect_false(threads)
      list(
        lower = log(1.1),
        upper = log(2.1),
        status = "profile",
        message = "profile_result completed",
        threaded = FALSE,
        worker_threads = 1L,
        julia_threads = 1L,
        blas_threads = 1L,
        elapsed = 0.25
      )
    },
    .package = "drmTMB"
  )
  ci_public <- stats::confint(
    fit,
    parm = "sd:mu:phylo(1 | species)",
    level = 0.80,
    method = "profile"
  )
  expect_equal(ci_public$lower, 1.1 * sqrt(2), tolerance = 1e-12)
  expect_equal(ci_public$upper, 2.1 * sqrt(2), tolerance = 1e-12)
  expect_equal(ci_public$conf.status, "profile")

  result_partial <- result
  result_partial$vcov <- matrix(NaN, nrow = 4L, ncol = 4L)
  result_partial$vcov[1:2, 1:2] <- diag(c(0.01, 0.02))
  fit_partial <- drmTMB:::new_drmTMB_julia(
    result = result_partial,
    call = quote(drmTMB(form, data = dat, engine = "julia")),
    formula = form,
    family = gaussian(),
    data = data.frame(
      y = seq_len(6),
      x = seq_len(6),
      species = paste0("sp_", c(1, 1, 2, 3, 3, 4))
    ),
    family_type = "gaussian",
    structured_sd_scales = c("phylo(1 | species)" = sqrt(2))
  )
  expect_equal(fit_partial$uncertainty$status, "partial")
  expect_equal(fit_partial$uncertainty$se, FALSE)
  expect_equal(fit_partial$uncertainty$finite_dpars, "mu")
  expect_true(all(is.finite(stats::vcov(fit_partial)[1:2, 1:2])))
  expect_true(is.nan(stats::vcov(fit_partial)[3, 3]))
})

test_that("engine = 'julia' guardrails fail before JuliaCall setup", {
  dat <- data.frame(y = 1:4, x = c(-1, 0, 1, 2))

  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      data = dat,
      weights = rep(1, 4),
      engine = "julia"
    ),
    "weights"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      data = dat,
      control = list(eval.max = 10),
      engine = "julia"
    ),
    "does not support .*control"
  )
  # beta_binomial() was admitted to the Workflow G FE route 2026-09-05 (A4,
  # one registry row); the former refusal assertion here moved to
  # tests/testthat/test-julia-family-beta_binomial.R as an admission receipt.
})

# Night question 14: DRM.jl refuses these two ordinary-GLMM route limits only
# AFTER the engine boots, with its own error forwarded through callr (verified
# live at DRM.jl 77513aa0, `src/gaussian_core.jl:611-698`). drmTMB now refuses
# them itself, before Julia is even started -- these tests run with
# `DRM_JL_PATH` unset (see the ledger CHECK for this file) to prove no engine
# is needed for the refusal.
test_that("engine = 'julia' route limit: REML with a sigma-side random intercept refuses before Julia starts", {
  dat <- data.frame(
    y = rnorm(30),
    x = rnorm(30),
    g = factor(rep(1:5, each = 6))
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ (1 | g)),
      data = dat,
      engine = "julia",
      REML = TRUE
    ),
    "does not support .*method = \"REML\".*random intercept on .*sigma"
  )
  # ML (the default) for the SAME formula is not this route limit -- it
  # reaches the ordinary sparse-Laplace GLMM route unimpeded (a DIFFERENT
  # already-live test, `test-julia-bridge.R:734`, covers that route with
  # DRM_JL_PATH set).
})

test_that("engine = 'julia' route limit: a random intercept on sigma together with one on mu refuses before Julia starts", {
  dat <- data.frame(
    y = rnorm(30),
    x = rnorm(30),
    g = factor(rep(1:5, each = 6)),
    h = factor(rep(1:6, times = 5))
  )
  # Same group on mu and sigma.
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | g), sigma ~ (1 | g)),
      data = dat,
      engine = "julia"
    ),
    "does not support a random intercept on .*sigma.*together with a random effect on .*mu"
  )
  # Different groups on mu and sigma -- the SAME DRM.jl limitation (a random
  # effect on sigma must be the only random structure), not a group-matching
  # rule.
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | g), sigma ~ (1 | h)),
      data = dat,
      engine = "julia"
    ),
    "does not support a random intercept on .*sigma.*together with a random effect on .*mu"
  )
  # This refusal fires independent of REML too (DRM.jl's "only random
  # structure" check applies regardless of method).
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | g), sigma ~ (1 | g)),
      data = dat,
      engine = "julia",
      REML = TRUE
    ),
    "does not support"
  )
})

test_that("Julia bridge marshals the q4 PLSM bivariate phylo route", {
  tree <- structure(
    list(
      edge = matrix(
        c(7, 5, 7, 6, 5, 1, 5, 2, 6, 3, 6, 4),
        ncol = 2,
        byrow = TRUE
      ),
      edge.length = rep(1, 6),
      tip.label = paste0("sp_", 1:4),
      Nnode = 3L
    ),
    class = "phylo"
  )
  form <- bf(
    mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
    mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
    sigma1 = ~ 1 + phylo(1 | p | species, tree = tree),
    sigma2 = ~ 1 + phylo(1 | p | species, tree = tree),
    rho12 = ~1
  )

  # The labelled covariance block phylo(1 | p | species) collapses to DRM.jl's
  # plain phylo(1 | species) on every axis (DRM.jl implies the 4x4 Sigma_a).
  spec <- drmTMB:::drm_julia_formula_spec(form)
  expect_equal(spec$mu1, "y1 ~ x + phylo(1 | species)")
  expect_equal(spec$mu2, "y2 ~ x + phylo(1 | species)")
  expect_equal(spec$sigma1, "sigma1 ~ 1 + phylo(1 | species)")
  expect_equal(spec$sigma2, "sigma2 ~ 1 + phylo(1 | species)")
  expect_equal(spec$rho12, "rho12 ~ 1")

  dat <- data.frame(
    y1 = seq_len(8),
    y2 = seq_len(8) + 0.5,
    x = seq(-1, 1, length.out = 8),
    species = paste0("sp_", c(1, 1, 2, 2, 3, 3, 4, 4))
  )
  cache <- get("drm_julia_phylo_payload_cache", asNamespace("drmTMB"))
  rm(list = ls(cache, all.names = TRUE), envir = cache)
  on.exit(rm(list = ls(cache, all.names = TRUE), envir = cache), add = TRUE)

  payload <- drmTMB:::drm_julia_bridge_payload(
    formula = form,
    family_type = "biv_gaussian",
    data = dat,
    env = environment()
  )
  # q4 route: DRM.jl defaults (no g_tol override, no `q4_vcov` -- D-213 #2,
  # owner steer 2026-09-03: `q4_vcov` is OPT-IN, not sent unless requested via
  # `drm_control(optimizer = list(q4_vcov = TRUE))`, so the default payload is
  # byte-identical to pre-D-213 #2); the block label "p" is NOT a data
  # column; the tree is marshalled as Newick; markers preserved per axis.
  expect_equal(drm_test_options_sans_labels(payload$options), list())
  expect_true(is.list(payload$options$coef_labels))
  expect_equal(payload$formula$sigma1, "sigma1 ~ 1 + phylo(1 | species)")
  expect_false("p" %in% names(payload$data))
  expect_true(all(c("y1", "y2", "x", "species") %in% names(payload$data)))
  expect_match(payload$tree, "^\\(\\(sp_1:1")

  reml_payload <- drmTMB:::drm_julia_bridge_payload(
    formula = form,
    family_type = "biv_gaussian",
    data = dat,
    env = environment(),
    method = "REML"
  )
  expect_equal(
    drm_test_options_sans_labels(reml_payload$options),
    list(method = "REML")
  )
  expect_true(is.list(reml_payload$options$coef_labels))
  expect_true(drmTMB:::drm_julia_reml_supported(form, "biv_gaussian"))

  # D-213 #2 plumbing, opt-in: `q4_vcov` reaches the payload options ONLY
  # when explicitly requested via `control_overrides` (what
  # `drm_julia_translate_control(drm_control(optimizer = list(q4_vcov =
  # TRUE)))` produces) -- the same mechanism `g_tol`/`algorithm` already use.
  q4_vcov_overrides <- drmTMB:::drm_julia_translate_control(
    drm_control(optimizer = list(q4_vcov = TRUE))
  )
  expect_equal(q4_vcov_overrides, list(q4_vcov = TRUE))
  q4_vcov_payload <- drmTMB:::drm_julia_bridge_payload(
    formula = form,
    family_type = "biv_gaussian",
    data = dat,
    env = environment(),
    method = "REML",
    control_overrides = q4_vcov_overrides
  )
  expect_equal(
    drm_test_options_sans_labels(q4_vcov_payload$options),
    list(method = "REML", q4_vcov = TRUE)
  )
  # ...and requesting `q4_vcov = FALSE` explicitly is a no-op relative to the
  # default (still absent from what DRM.jl actually reads as `false`, but
  # sent explicitly rather than omitted) -- confirms the FALSE branch of the
  # validator, not just TRUE.
  q4_vcov_false_overrides <- drmTMB:::drm_julia_translate_control(
    drm_control(optimizer = list(q4_vcov = FALSE))
  )
  expect_equal(q4_vcov_false_overrides, list(q4_vcov = FALSE))

  q2_form <- bf(
    mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
    mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1
  )
  q2_payload <- drmTMB:::drm_julia_bridge_payload(
    formula = q2_form,
    family_type = "biv_gaussian",
    data = dat,
    env = environment()
  )
  expect_equal(q2_payload$formula$mu1, "y1 ~ x + phylo(1 | species)")
  expect_equal(q2_payload$formula$mu2, "y2 ~ x + phylo(1 | species)")
  expect_equal(q2_payload$formula$sigma1, "sigma1 ~ 1")
  expect_equal(q2_payload$formula$sigma2, "sigma2 ~ 1")
  expect_equal(q2_payload$bivariate_dimension, "q2")
  expect_equal(drm_test_options_sans_labels(q2_payload$options), list(g_tol = 1e-4))
  expect_true(is.list(q2_payload$options$coef_labels))
  expect_false(drmTMB:::drm_julia_reml_supported(q2_form, "biv_gaussian"))

  expect_error(
    drmTMB:::drm_julia_phylo_payload(
      formula = bf(
        mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
        mu2 = y2 ~ x,
        sigma1 = ~1,
        sigma2 = ~1,
        rho12 = ~1
      ),
      family_type = "biv_gaussian",
      data = dat,
      env = environment()
    ),
    "q2.*mu1/mu2|q4 all-four-axis"
  )

  # rho12 may not carry phylo on the bridge route.
  expect_error(
    drmTMB:::drm_julia_phylo_payload(
      formula = bf(
        mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
        mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
        sigma1 = ~ 1 + phylo(1 | p | species, tree = tree),
        sigma2 = ~ 1 + phylo(1 | p | species, tree = tree),
        rho12 = ~ 1 + phylo(1 | p | species, tree = tree)
      ),
      family_type = "biv_gaussian",
      data = dat,
      env = environment()
    )
  )
})

test_that("Julia q4 bridge admits bivariate response masks without R-side dropping", {
  tree <- structure(
    list(
      edge = matrix(
        c(7, 5, 7, 6, 5, 1, 5, 2, 6, 3, 6, 4),
        ncol = 2,
        byrow = TRUE
      ),
      edge.length = rep(1, 6),
      tip.label = paste0("sp_", 1:4),
      Nnode = 3L
    ),
    class = "phylo"
  )
  form <- bf(
    mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
    mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
    sigma1 = ~ 1 + phylo(1 | p | species, tree = tree),
    sigma2 = ~ 1 + phylo(1 | p | species, tree = tree),
    rho12 = ~1
  )
  dat <- data.frame(
    y1 = c(NA, 2, 3, 4, 5, 6, 7, 8),
    y2 = c(1.5, 2.5, NA, 4.5, 5.5, 6.5, 7.5, 8.5),
    x = seq(-1, 1, length.out = 8),
    species = paste0("sp_", c(1, 1, 2, 2, 3, 3, 4, 4))
  )
  captured <- new.env(parent = emptyenv())
  fake_result <- list(
    coef_names = c(
      "mu1_(Intercept)",
      "mu1_x",
      "mu2_(Intercept)",
      "mu2_x",
      "sigma1_(Intercept)",
      "sigma2_(Intercept)",
      "rho12_(Intercept)"
    ),
    coefficients = rep(0, 7),
    vcov = diag(7),
    loglik = -10,
    aic = 34,
    bic = 36,
    df = 7L,
    nobs = 8L,
    converged = TRUE,
    fitted = list(mu1 = rep(0, 8), mu2 = rep(0, 8)),
    residuals = list(mu1 = rep(0, 8), mu2 = rep(0, 8)),
    sigma = list(sigma1 = rep(1, 8), sigma2 = rep(1, 8)),
    corpairs = list()
  )
  testthat::local_mocked_bindings(
    drm_julia_call_bridge = function(formula, family, data, tree, options) {
      captured$formula <- formula
      captured$family <- family
      captured$data <- data
      captured$tree <- tree
      captured$options <- options
      fake_result
    },
    .package = "drmTMB"
  )

  fit <- drmTMB:::drmTMB_julia_bridge(
    formula = form,
    family = biv_gaussian(),
    data = dat,
    env = environment(),
    weights_missing = TRUE,
    control = NULL,
    impute = NULL,
    missing = miss_control(response = "include"),
    REML = TRUE,
    call = quote(drmTMB())
  )

  expect_equal(captured$family, "biv_gaussian")
  expect_equal(nrow(captured$data), nrow(dat))
  expect_true(anyNA(captured$data$y1))
  expect_true(anyNA(captured$data$y2))
  expect_equal(
    drm_test_options_sans_labels(captured$options),
    list(method = "REML")
  )
  expect_true(is.list(captured$options$coef_labels))
  expect_equal(fit$estimator, "REML")
  expect_true(fit$requested_REML)
  expect_true(fit$effective_REML)
})

test_that("drm_julia_translate_control() rejects a supplied start list", {
  ctrl <- drm_control(start = list(`fixef:mu:(Intercept)` = 0.5))
  expect_error(
    drmTMB:::drm_julia_translate_control(ctrl),
    "start"
  )
})

test_that("drm_julia_translate_control() rejects multi_start > 1", {
  ctrl <- drm_control(multi_start = 3L)
  expect_error(
    drmTMB:::drm_julia_translate_control(ctrl),
    "multi_start"
  )
})

test_that("drm_julia_translate_control() still accepts plain drm_control() defaults", {
  expect_equal(drmTMB:::drm_julia_translate_control(drm_control()), list())
})

test_that("sigma random intercept: a live Julia fit of sigma ~ (1 | g) reports base-R public names matching the TMB engine", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  jl_path <- Sys.getenv("DRM_JL_PATH", "")
  skip_if_not(nzchar(jl_path) && dir.exists(jl_path), "DRM_JL_PATH not available")

  set.seed(1)
  n <- 120
  g <- factor(rep(1:12, each = 10))
  x <- rnorm(n)
  y <- 1 + 0.5 * x + rnorm(12, sd = 0.7)[g] + rnorm(n, sd = exp(0.2 * rnorm(12)[g]))
  dat <- data.frame(y = y, x = x, g = g)

  form <- bf(y ~ x, sigma ~ (1 | g))
  fj <- drmTMB(form, data = dat, engine = "julia")
  ft <- drmTMB(form, data = dat)

  expect_identical(names(coef(fj, "mu")), names(coef(ft, "mu")))
  expect_identical(names(coef(fj, "sigma")), names(coef(ft, "sigma")))
})

test_that("sdpars, sigma random intercept: the sigma-side random-effect SD is filed under sdpars$sigma, matching the TMB engine (live)", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  jl_path <- Sys.getenv("DRM_JL_PATH", "")
  skip_if_not(nzchar(jl_path) && dir.exists(jl_path), "DRM_JL_PATH not available")

  set.seed(1)
  n <- 120
  g <- factor(rep(1:12, each = 10))
  x <- rnorm(n)
  y <- 1 + 0.5 * x + rnorm(12, sd = 0.7)[g] + rnorm(n, sd = exp(0.2 * rnorm(12)[g]))
  dat <- data.frame(y = y, x = x, g = g)

  form <- bf(y ~ x, sigma ~ (1 | g))
  fj <- drmTMB(form, data = dat, engine = "julia")
  ft <- drmTMB(form, data = dat)

  # TMB's own `split_tmb_sdpars()` (R/drmTMB.R) only adds a dpar's entry to
  # `sdpars` when that dpar has a random effect at all -- `ft$sdpars` has no
  # `mu` entry (this formula's mean is fixed-effects-only), while the Julia
  # bridge always returns both slots from a fixed `empty_sdpars` template
  # (possibly empty). Accessing the missing key on either object gives
  # length 0 either way, so the comparison is on VALUES, not on which keys
  # are literally present.
  expect_identical(names(fj$sdpars$sigma), names(ft$sdpars$sigma))
  expect_length(fj$sdpars$mu, 0L)
  expect_length(ft$sdpars$mu, 0L)
  expect_true("sigma" %in% names(fj$sdpars))
  expect_true("sigma" %in% names(ft$sdpars))
})

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
  expect_equal(payload$options, list(g_tol = 1e-4))
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

  expect_error(
    drmTMB:::drm_julia_bridge_payload(
      formula = bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ x),
      family_type = "gaussian",
      data = dat,
      env = environment()
    ),
    "sparse all-node"
  )
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
  expect_equal(predict(fit, dpar = "mu"), seq_len(6))
  expect_equal(predict(fit, dpar = "sigma"), rep(0.8, 6))
  expect_true(is_converged(fit))
  expect_error(rho12(fit), "no residual")
  # newdata mu prediction is population-level (RE = 0); identity link here, so
  # the response equals the fixed-effect linear predictor 0.1 + 0.4 * x.
  expect_equal(predict(fit, newdata = data.frame(x = 1)), 0.5)
  expect_equal(
    predict(fit, newdata = data.frame(x = 1), type = "link"),
    0.5
  )
  # sigma on fresh newdata remains unsupported on the Julia route.
  expect_error(
    predict(fit, newdata = data.frame(x = 1), dpar = "sigma"),
    "location parameter"
  )
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
  expect_equal(targets$parm, "sd:mu:phylo(1 | species)")
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
      method,
      level,
      R,
      seed,
      threads
    ) {
      expect_s3_class(object, "drmTMB_julia")
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
    "default .*control"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = student(),
      data = dat,
      engine = "julia"
    ),
    "Gaussian one-/two-response"
  )
  # NB2 without a phylo term stays TMB-only: the Julia route is the large-p
  # phylogenetic count speed edge, not a general count GLM path.
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = nbinom2(),
      data = dat,
      engine = "julia"
    ),
    "only with a .*phylo.* random intercept"
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
  # q4 route: DRM.jl defaults (no g_tol override); the block label "p" is NOT a
  # data column; the tree is marshalled as Newick; markers preserved per axis.
  expect_equal(payload$options, list())
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
  expect_equal(reml_payload$options, list(method = "REML"))

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

# Regression tests for user input that used to be silently dropped:
# #1495 factor contrasts, #1482 Gaussian links, #1458 bootstrap failures.

test_that("user-set factor contrasts survive droplevels when every level is used (#1495)", {
  set.seed(1)
  d <- data.frame(
    y = stats::rnorm(30),
    g = factor(rep(c("a", "b", "c"), 10))
  )
  stats::contrasts(d$g) <- stats::contr.sum(3)
  form <- bf(y ~ g, sigma ~ 1)

  out <- drmTMB:::drm_droplevels_fixed_predictors(d, form)
  expect_equal(stats::contrasts(out$g), stats::contr.sum(3), ignore_attr = TRUE)
  expect_equal(
    colnames(stats::model.matrix(y ~ g, out)),
    c("(Intercept)", "g1", "g2")
  )

  fit <- drmTMB(form, data = d, family = gaussian())
  expect_equal(names(coef(fit, "mu")), c("(Intercept)", "g1", "g2"))
  expect_equal(
    unname(coef(fit, "mu")),
    unname(stats::coef(stats::lm(y ~ g, d))),
    tolerance = 1e-6
  )
})

test_that("predict(newdata) keeps user-set contrasts and matches lm (#1495)", {
  set.seed(3)
  d <- data.frame(
    y = stats::rnorm(30),
    g = factor(rep(c("a", "b", "c"), 10))
  )
  stats::contrasts(d$g) <- stats::contr.sum(3)
  fit <- drmTMB(bf(y ~ g, sigma ~ 1), data = d, family = gaussian())
  nd <- data.frame(g = factor(c("a", "b", "c"), levels = levels(d$g)))

  expect_equal(
    as.numeric(predict(fit, newdata = nd)),
    as.numeric(stats::predict(stats::lm(y ~ g, d), newdata = nd)),
    tolerance = 1e-6
  )
  expect_equal(names(coef(fit, "mu")), c("(Intercept)", "g1", "g2"))
})

test_that("unused levels still drop, and user-set contrasts warn instead of vanishing (#1495)", {
  set.seed(2)
  d <- data.frame(
    y = stats::rnorm(20),
    g = factor(rep(c("a", "b"), 10), levels = c("a", "b", "c"))
  )
  stats::contrasts(d$g) <- stats::contr.sum(3)
  form <- bf(y ~ g, sigma ~ 1)

  expect_warning(
    out <- drmTMB:::drm_droplevels_fixed_predictors(d, form),
    class = "drmTMB_contrasts_unused_levels"
  )
  expect_equal(levels(out$g), c("a", "b"))
  expect_null(attr(out$g, "contrasts"))

  fit <- NULL
  expect_warning(
    fit <- drmTMB(form, data = d, family = gaussian()),
    class = "drmTMB_contrasts_unused_levels"
  )
  expect_false("gc" %in% names(coef(fit, "mu")))
  expect_true(all(is.finite(summary(fit)$coefficients$std_error)))
})

test_that("gaussian(link = 'log') and gaussian(link = 'inverse') error instead of fitting identity (#1482)", {
  dat <- data.frame(y = stats::rnorm(12, 10), x = stats::rnorm(12))

  expect_equal(drmTMB:::drm_family_type(gaussian()), "gaussian")
  expect_equal(drmTMB:::drm_family_type(gaussian(link = "identity")), "gaussian")
  expect_error(
    drmTMB:::drm_family_type(gaussian(link = "log")),
    "identity link"
  )
  expect_error(
    drmTMB:::drm_family_type(gaussian(link = "log")),
    "Gamma"
  )
  expect_error(
    drmTMB:::drm_julia_xfam_family_tag(gaussian(link = "log")),
    "identity link"
  )
  expect_error(
    drmTMB:::drm_julia_is_cross_family(c(poisson(), gaussian(link = "log"))),
    "identity link"
  )
  expect_error(
    drmTMB:::drm_julia_is_cross_family(c(poisson(), gaussian(link = "log"))),
    "Gamma"
  )
  expect_error(
    drmTMB:::drm_family_type(gaussian(link = "inverse")),
    "identity link"
  )
  expect_error(
    drmTMB:::drm_family_type(c(gaussian(link = "log"), gaussian())),
    "identity link"
  )
  expect_error(
    drmTMB:::drm_impute_family_type(gaussian(link = "log")),
    "identity link"
  )

  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(link = "log"), data = dat),
    "identity link"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = gaussian(link = "inverse"),
      data = dat
    ),
    "identity link"
  )

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(link = "identity"),
    data = dat
  )
  expect_equal(fit$opt$convergence, 0)
})

test_that("bootstrap_conf_status is not plain bootstrap after failed refits (#1458)", {
  expect_equal(drmTMB:::bootstrap_conf_status(100L, 0L), "bootstrap")
  expect_equal(drmTMB:::bootstrap_conf_status(1L, 99L), "bootstrap_unavailable")
  expect_equal(drmTMB:::bootstrap_conf_status(0L, 10L), "bootstrap_unavailable")
  expect_equal(drmTMB:::bootstrap_conf_status(2L, 1L), "bootstrap_incomplete")
  expect_equal(drmTMB:::bootstrap_conf_status(40L, 60L), "bootstrap_incomplete")

  reconciled <- drmTMB:::bootstrap_reconcile_status(
    data.frame(
      parm = "fixef:mu:x",
      conf.status = "bootstrap",
      bootstrap.n = 48L,
      bootstrap.failed = 1L,
      stringsAsFactors = FALSE
    ),
    warn = FALSE
  )
  expect_equal(reconciled$conf.status, "bootstrap_incomplete")
})

test_that("confint(method = 'bootstrap') warns and flags dropped refits (#1458)", {
  set.seed(20261007)
  dat <- data.frame(y = stats::rnorm(24), x = stats::rnorm(24))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  testthat::local_mocked_bindings(
    bootstrap_refit_one = function(
      object,
      simulations,
      index,
      target_names,
      refit_control
    ) {
      out <- drmTMB:::bootstrap_empty_draws(index, target_names)
      if (identical(index, 1L)) {
        out$refit_status <- "refit_nonconverged"
        out$refit_message <- "mocked failure"
        return(out)
      }
      out$refit_ok <- TRUE
      out$refit_converged <- TRUE
      out$target_available <- TRUE
      out$estimate <- 0.1 * index
      out$link_estimate <- 0.1 * index
      out$estimate_finite <- TRUE
      out$link_estimate_finite <- TRUE
      out$refit_status <- "ok"
      out$refit_message <- "ok"
      out$refit_convergence <- 0L
      out
    },
    .package = "drmTMB"
  )

  ci <- NULL
  expect_warning(
    ci <- stats::confint(
      fit,
      parm = "fixef:mu:x",
      method = "bootstrap",
      R = 5L,
      seed = 20261007
    ),
    class = "drmTMB_bootstrap_incomplete_warning"
  )
  expect_equal(ci$conf.status, "bootstrap_incomplete")
  expect_equal(ci$bootstrap.n, 4L)
  expect_equal(ci$bootstrap.failed, 1L)
  expect_true(is.finite(ci$lower) && is.finite(ci$upper))
})

test_that("at-boundary bootstrap still warns about dropped refits (#1458)", {
  at_boundary <- data.frame(
    parm = "sd(group)",
    conf.status = "bootstrap_at_boundary",
    bootstrap.n = 39L,
    bootstrap.failed = 1L,
    stringsAsFactors = FALSE
  )
  expect_warning(
    drmTMB:::warn_bootstrap_incomplete(at_boundary),
    regexp = "bootstrap_at_boundary",
    class = "drmTMB_bootstrap_incomplete_warning"
  )

  clean_boundary <- at_boundary
  clean_boundary$bootstrap.failed <- 0L
  expect_no_warning(
    drmTMB:::warn_bootstrap_incomplete(clean_boundary),
    class = "drmTMB_bootstrap_incomplete_warning"
  )

  set.seed(20261007)
  dat <- data.frame(y = stats::rnorm(24), x = stats::rnorm(24))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  testthat::local_mocked_bindings(
    bootstrap_refit_one = function(
      object,
      simulations,
      index,
      target_names,
      refit_control
    ) {
      out <- drmTMB:::bootstrap_empty_draws(index, target_names)
      if (identical(index, 1L)) {
        out$refit_status <- "refit_nonconverged"
        out$refit_message <- "mocked failure"
        return(out)
      }
      out$refit_ok <- TRUE
      out$refit_converged <- TRUE
      out$target_available <- TRUE
      out$estimate <- 0.1 * index
      out$link_estimate <- 0.1 * index
      out$estimate_finite <- TRUE
      out$link_estimate_finite <- TRUE
      out$refit_status <- "ok"
      out$refit_message <- "ok"
      out$refit_convergence <- 0L
      out
    },
    bootstrap_boundary_share_at = function(...) 1,
    .package = "drmTMB"
  )

  ci <- NULL
  expect_warning(
    expect_warning(
      ci <- stats::confint(
        fit,
        parm = "fixef:mu:x",
        method = "bootstrap",
        R = 5L,
        seed = 20261007
      ),
      class = "drmTMB_bootstrap_boundary_warning"
    ),
    regexp = "bootstrap_at_boundary",
    class = "drmTMB_bootstrap_incomplete_warning"
  )
  expect_equal(ci$conf.status, "bootstrap_at_boundary")
  expect_equal(ci$bootstrap.n, 4L)
  expect_equal(ci$bootstrap.failed, 1L)
})

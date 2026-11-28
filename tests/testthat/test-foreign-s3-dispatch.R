# drmTMB re-exports `nlme`'s `fixef()` and `ranef()` (R/drmTMB-package.R), matching
# `lme4` and `glmmTMB`. NAMESPACE registration alone does not attach
# `fixef.drmTMB` / `ranef.drmTMB` to `nlme`'s generic, so `R/zzz.R` registers them
# at load time. These tests call `nlme::ranef()` / `nlme::fixef()` directly so they
# do not depend on attach order or on attaching comparator packages in the suite.
#
# These tests exercise nlme's generic directly. That is the generic that was
# broken, and calling it explicitly reproduces the failure without attaching
# anything -- attaching a comparator inside the suite is what caused the original
# incident, so it is deliberately not done here.

fit_with_random_effect <- function() {
  set.seed(20260815)
  n_group <- 8L
  per_group <- 5L
  id <- factor(rep(seq_len(n_group), each = per_group))
  x <- stats::rnorm(n_group * per_group)
  u <- stats::rnorm(n_group, sd = 0.7)[as.integer(id)]
  y <- 1 + 0.5 * x + u + stats::rnorm(n_group * per_group, sd = 0.5)
  drmTMB(
    bf(mu = y ~ x + (1 | id), sigma = ~1),
    data = data.frame(y = y, x = x, id = id),
    family = gaussian()
  )
}

test_that("nlme's ranef generic dispatches to drmTMB's method", {
  fit <- fit_with_random_effect()

  # The regression: this errored with "no applicable method for 'ranef' applied
  # to an object of class \"drmTMB\"" whenever nlme's generic was the one in scope.
  via_nlme <- nlme::ranef(fit, "mu")
  via_drmtmb <- drmTMB::ranef(fit, "mu")

  expect_identical(via_nlme, via_drmtmb)
  expect_true("(1 | id)" %in% names(via_nlme$terms))
  expect_true(all(is.finite(via_nlme$terms[["(1 | id)"]])))
})

test_that("nlme's fixef generic dispatches to drmTMB's method", {
  fit <- fit_with_random_effect()

  expect_identical(nlme::fixef(fit), drmTMB::fixef(fit))
  expect_true(all(is.finite(unlist(nlme::fixef(fit)))))
})

julia_fixef_fixture <- function() {
  result <- list(
    coef_names = c("mu_(Intercept)", "mu_x"),
    coefficients = c(0.1, 0.4),
    vcov = diag(c(0.01, 0.01)),
    loglik = -5,
    aic = 14,
    bic = 15,
    df = 2L,
    nobs = 10L,
    converged = TRUE,
    fitted = rep(0, 10L),
    residuals = rep(0, 10L),
    sigma = 1,
    corpairs = list()
  )
  form <- drmTMB::bf(y ~ x)
  drmTMB:::new_drmTMB_julia(
    result = result,
    call = quote(drmTMB(form, data = dat, engine = "julia")),
    formula = form,
    family = stats::gaussian(),
    data = data.frame(y = rnorm(10), x = rnorm(10)),
    family_type = "gaussian"
  )
}

test_that("nlme's fixef generic dispatches for drmTMB_julia fits (#1660)", {
  fit <- julia_fixef_fixture()
  expect_identical(nlme::fixef(fit), drmTMB::fixef(fit))
  expect_true(all(is.finite(unlist(nlme::fixef(fit)))))
})

test_that("drmTMB_julia fixef works after pkgload::load_all in a callr subprocess (#1660)", {
  skip_if_not_installed("callr")
  pkgdir <- testthat::test_path("..", "..")
  out <- callr::r(
    function(pkgdir) {
      pkgload::load_all(pkgdir, quiet = TRUE)
      dat <- data.frame(y = rnorm(10), x = rnorm(10))
      result <- list(
        coef_names = c("mu_(Intercept)", "mu_x"),
        coefficients = c(0.1, 0.4),
        vcov = diag(c(0.01, 0.01)),
        loglik = -5,
        aic = 14,
        bic = 15,
        df = 2L,
        nobs = 10L,
        converged = TRUE,
        fitted = rep(0, 10L),
        residuals = rep(0, 10L),
        sigma = 1,
        corpairs = list()
      )
      form <- drmTMB::bf(y ~ x)
      fit <- drmTMB:::new_drmTMB_julia(
        result = result,
        call = quote(drmTMB(form, data = dat, engine = "julia")),
        formula = form,
        family = stats::gaussian(),
        data = dat,
        family_type = "gaussian"
      )
      drmTMB::fixef(fit)
    },
    args = list(pkgdir = pkgdir),
    show = TRUE,
    timeout = 60
  )
  expect_true(all(is.finite(unlist(out$mu))))
})

test_that("the methods are registered against nlme, not merely present", {
  # Registration is the whole fix, so assert it structurally rather than
  # inferring it from a call that happened to work. If a future refactor drops
  # the .onLoad hook, this fails even if drmTMB's own generic still works.
  drmtmb_ns <- asNamespace("drmTMB")
  nlme_ns <- asNamespace("nlme")
  for (class in c("drmTMB", "drmTMB_julia", "drmTMB_julia_xfam")) {
    registered <- utils::getS3method(
      "fixef", class,
      optional = TRUE, envir = nlme_ns
    )
    expect_false(
      is.null(registered),
      info = paste0("fixef.", class, " is not registered on nlme's generic")
    )
    expect_identical(
      registered,
      get(paste0("fixef.", class), envir = drmtmb_ns)
    )
  }
  for (generic in "ranef") {
    registered <- utils::getS3method(
      generic, "drmTMB",
      optional = TRUE, envir = nlme_ns
    )
    expect_false(
      is.null(registered),
      info = paste0(generic, ".drmTMB is not registered on nlme's generic")
    )
    expect_identical(
      registered,
      get(paste0(generic, ".drmTMB"), envir = drmtmb_ns)
    )
  }
})

test_that("sigma needs no registration because it already shares the stats generic", {
  fit <- fit_with_random_effect()

  # Recorded so a later reader does not "fix" sigma the same way by reflex:
  # drmTMB registers sigma against stats::sigma, which lme4 and glmmTMB also use,
  # so no attach order can mask it. Note drmTMB exports no `sigma` function of its
  # own -- `drmTMB::sigma` does not exist, and that is the correct design here.
  registered <- utils::getS3method("sigma", "drmTMB", optional = TRUE, envir = asNamespace("stats"))
  expect_false(is.null(registered))
  expect_identical(stats::sigma(fit), registered(fit))
  expect_true(is.finite(as.numeric(stats::sigma(fit))[1L]))
})

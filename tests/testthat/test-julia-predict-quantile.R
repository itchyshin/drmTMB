# predict(type = "quantile") through engine = "julia" (drmTMB#1198, parity leaf
# `leaf-quantile-bridge`, 2026-09-05).
#
# BEFORE: predict.drmTMB_julia() accepted type = c("response", "link") only, so
# predict(fit, type = "quantile") on ANY engine = "julia" fit died in
# match.arg() with 'arg' should be one of "response", "link" -- for every
# family, while the native predict.drmTMB() has accepted it since DO-T2.
#
# AFTER: the bridge method accepts type = "quantile" and hands the fit to the
# SAME native drm_predict_quantile() (R/distributional-outputs.R). No new
# statistics: the {d,p,q} registry (R/family-dpq.R), the prob validation, the
# percentage column labels and the calibrated/prob/label attributes all keep
# one source of truth, and only the per-row distributional parameters come
# from the bridge's own reconstruction.
#
# COVERED: all 14 families the bridge admits on its fixed-effect route
# (R/julia-family-registry.R, fe = TRUE) -- every one of them is also a
# registered drm_family_dpq() model type, so the native and bridge quantile
# targets are identical by construction.
# NOT COVERED, on purpose: meta_V() gaussian fits (fenced below with a measured
# reason), phylo / structured / random-effect routes (the bridge's own
# prediction scope, not this leaf's), and any interval-COVERAGE claim --
# attr(., "calibrated") is FALSE on both engines.

# ---- offline (no Julia): the R-side assembly on hand-built stubs -----------

make_quantile_julia_fit <- function(formula, family, model_type, data, coefs,
                                    extra = list()) {
  structure(
    c(
      list(
        formula = formula,
        family = family,
        model = list(model_type = model_type),
        data = data,
        coefficients = coefs,
        engine = "julia"
      ),
      extra
    ),
    class = "drmTMB_julia"
  )
}

quantile_stub_data <- function() {
  data.frame(
    x = seq(-1, 1, length.out = 8L),
    y = c(-0.9, -0.4, -0.2, 0.1, 0.3, 0.6, 0.8, 1.2),
    successes = c(3, 4, 5, 6, 7, 8, 9, 10),
    failures = c(7, 6, 5, 4, 3, 2, 1, 1)
  )
}

quantile_gaussian_stub <- function() {
  make_quantile_julia_fit(
    formula = drmTMB::bf(y ~ x, sigma ~ x),
    family = stats::gaussian(),
    model_type = "gaussian",
    data = quantile_stub_data(),
    coefs = list(
      mu = c("(Intercept)" = 0.3, x = 0.4),
      sigma = c("(Intercept)" = -0.2, x = 0.5)
    )
  )
}

test_that("the bridge quantile of a hand-built Gaussian stub is the closed-form qnorm", {
  fit <- quantile_gaussian_stub()
  dat <- quantile_stub_data()
  prob <- c(0.025, 0.5, 0.975)

  out <- predict(fit, type = "quantile", prob = prob)

  mu <- 0.3 + 0.4 * dat$x
  sigma <- exp(-0.2 + 0.5 * dat$x)
  expected <- vapply(prob, function(p) stats::qnorm(p, mu, sigma), numeric(nrow(dat)))

  # Shape and labels are the native contract (drm_quantile_prob_labels()).
  expect_true(is.matrix(out))
  expect_identical(dim(out), c(nrow(dat), length(prob)))
  expect_identical(colnames(out), c("2.5%", "50%", "97.5%"))
  expect_null(rownames(out))
  expect_false(attr(out, "calibrated"))
  expect_identical(attr(out, "prob"), prob)
  expect_identical(attr(out, "label"), "distributional (plug-in) interval")
  expect_equal(unname(out[, ]), unname(expected))

  # Column ORDER follows prob, not a sort: a reversed prob reverses the columns.
  rev_out <- predict(fit, type = "quantile", prob = rev(prob))
  expect_identical(colnames(rev_out), c("97.5%", "50%", "2.5%"))
  expect_equal(unname(rev_out[, 1L]), unname(out[, 3L]))
  expect_equal(unname(rev_out[, 3L]), unname(out[, 1L]))

  # newdata is the population-level fixed-effect quantile for those rows.
  nd <- data.frame(x = c(-0.5, 0, 0.5))
  nd_out <- predict(fit, newdata = nd, type = "quantile", prob = 0.5)
  expect_identical(dim(nd_out), c(nrow(nd), 1L))
  expect_equal(unname(nd_out[, 1L]), 0.3 + 0.4 * nd$x)
})

test_that("PLANT: a wrong column ORDER in the bridge assembly is caught", {
  fit <- quantile_gaussian_stub()
  dat <- quantile_stub_data()
  prob <- c(0.025, 0.5, 0.975)
  good <- predict(fit, type = "quantile", prob = prob)
  mu <- 0.3 + 0.4 * dat$x
  sigma <- exp(-0.2 + 0.5 * dat$x)

  # Plant the classic assembly bug: the columns are computed in REVERSED prob
  # order while the labels still read 2.5% / 50% / 97.5%, so nothing about the
  # result's shape or names gives it away.
  local_mocked_bindings(
    drm_julia_predict_quantile = function(object, newdata, dpar, prob) {
      class(object) <- c(class(object), "drmTMB")
      out <- drmTMB:::drm_predict_quantile(
        object, newdata = newdata, dpar = dpar, prob = rev(prob)
      )
      colnames(out) <- drmTMB:::drm_quantile_prob_labels(prob)
      out
    },
    .package = "drmTMB"
  )
  planted <- predict(fit, type = "quantile", prob = prob)

  # The bug is INVISIBLE in shape and labels ...
  expect_identical(dim(planted), dim(good))
  expect_identical(colnames(planted), colnames(good))
  # ... and visible only in the values, which the offline block above checks.
  expect_gt(max(abs(planted - good)), 1)
  expect_false(isTRUE(all.equal(
    unname(planted[, 1L]), stats::qnorm(0.025, mu, sigma)
  )))
  expect_equal(unname(planted[, 1L]), stats::qnorm(0.975, mu, sigma))
})

test_that("the bridge quantile reaches every family-specific payload the registry needs", {
  dat <- quantile_stub_data()

  # binomial: `trials` is NOT on a bridge fit object; it is rebuilt from the
  # retained cbind() response and training data with the native rule.
  binom <- make_quantile_julia_fit(
    drmTMB::bf(cbind(successes, failures) ~ x), stats::binomial(), "binomial",
    dat, list(mu = c("(Intercept)" = 0.1, x = 0.2))
  )
  q_binom <- predict(binom, type = "quantile", prob = c(0.1, 0.9))
  trials <- dat$successes + dat$failures
  expect_equal(
    unname(q_binom[, 1L]),
    stats::qbinom(0.1, size = trials, prob = stats::plogis(0.1 + 0.2 * dat$x))
  )
  # The caller's object is never mutated by the reuse shim.
  expect_identical(class(binom), "drmTMB_julia")
  expect_null(binom$model$trials)

  # binomial newdata keeps the NATIVE contract: a trials column is required.
  expect_error(
    predict(binom, newdata = data.frame(x = 0), type = "quantile"),
    "needs the number of trials"
  )
  q_nd <- predict(
    binom,
    newdata = data.frame(x = c(-1, 1), trials = c(10, 20)),
    type = "quantile", prob = 0.5
  )
  expect_equal(
    unname(q_nd[, 1L]),
    stats::qbinom(0.5, size = c(10, 20), prob = stats::plogis(0.1 + 0.2 * c(-1, 1)))
  )

  # cumulative_logit: the cutpoints come from the fit's `ordinal` slot.
  cutpoints <- c("a|b" = -0.5, "b|c" = 0.8)
  ord <- make_quantile_julia_fit(
    drmTMB::bf(y ~ x), drmTMB::cumulative_logit(), "cumulative_logit",
    dat, list(mu = c(x = 0.5)),
    extra = list(ordinal = list(cutpoints = cutpoints))
  )
  q_ord <- predict(ord, type = "quantile", prob = 0.5)
  cdf1 <- stats::plogis(cutpoints[[1L]] - 0.5 * dat$x)
  cdf2 <- stats::plogis(cutpoints[[2L]] - 0.5 * dat$x)
  expect_equal(
    unname(q_ord[, 1L]),
    as.numeric(ifelse(cdf1 >= 0.5, 1L, ifelse(cdf2 >= 0.5, 2L, 3L)))
  )
})

test_that("the bridge quantile keeps the native prob and biv_gaussian dpar contracts", {
  fit <- quantile_gaussian_stub()
  expect_error(predict(fit, type = "quantile", prob = 1.5), "strictly between 0 and 1")
  expect_error(predict(fit, type = "quantile", prob = 0), "strictly between 0 and 1")
  expect_error(predict(fit, type = "quantile", prob = numeric(0)), "strictly between 0 and 1")

  biv_dat <- data.frame(
    y1 = c(-0.4, 0.1, 0.6), y2 = c(0.2, -0.3, 0.9), x = c(-1, 0, 1)
  )
  biv <- make_quantile_julia_fit(
    drmTMB::bf(
      mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1
    ),
    drmTMB::biv_gaussian(), "biv_gaussian", biv_dat,
    list(
      mu1 = c("(Intercept)" = 0.1, x = 0.2), mu2 = c("(Intercept)" = 0.3, x = -0.2),
      sigma1 = c("(Intercept)" = -0.3), sigma2 = c("(Intercept)" = -0.1),
      rho12 = c("(Intercept)" = 0.2)
    )
  )
  # Marginal, response-selected by dpar -- exactly the native rule.
  expect_equal(
    unname(predict(biv, dpar = "mu1", type = "quantile", prob = 0.5)[, 1L]),
    0.1 + 0.2 * biv_dat$x
  )
  expect_equal(
    unname(predict(biv, dpar = "sigma2", type = "quantile", prob = 0.5)[, 1L]),
    0.3 - 0.2 * biv_dat$x
  )
  expect_error(
    predict(biv, dpar = "rho12", type = "quantile"),
    "needs .*dpar.* to identify a response"
  )
})

test_that("a meta_V bridge fit REFUSES type = 'quantile' rather than dropping V", {
  dat <- data.frame(x = c(-1, 0, 1), y = c(-0.2, 0.3, 0.9), v = c(0.1, 0.2, 0.3))
  fit <- make_quantile_julia_fit(
    drmTMB::bf(y ~ x + meta_V(V = v), sigma ~ 1), stats::gaussian(), "gaussian",
    dat, list(mu = c("(Intercept)" = 0.3, x = 0.4), sigma = c("(Intercept)" = -0.2))
  )
  expect_error(
    predict(fit, type = "quantile"),
    "not available for a .*meta_V.* fit"
  )
  # The other two types are untouched by the fence.
  expect_equal(predict(fit, type = "link"), 0.3 + 0.4 * dat$x)
  expect_equal(predict(fit, type = "response"), 0.3 + 0.4 * dat$x)
})

# ---- live same-target receipt (opt-in; skips only when the engine is absent)

drm_quantile_bridge_prob <- function() c(0.1, 0.5, 0.9)

drm_quantile_bridge_specs <- function() {
  nd_x <- data.frame(x = c(-1, 0, 1))
  list(
    gaussian = list(
      build = function() {
        set.seed(20260905)
        n <- 300
        d <- data.frame(x = stats::rnorm(n))
        d$y <- 0.4 + 0.7 * d$x + stats::rnorm(n, sd = exp(-0.3 + 0.2 * d$x))
        d
      },
      fml = quote(drmTMB::bf(y ~ x, sigma ~ x)),
      fam = quote(stats::gaussian()), newdata = nd_x
    ),
    student = list(
      build = function() {
        set.seed(20260906)
        n <- 400
        d <- data.frame(x = stats::rnorm(n))
        d$y <- 0.3 + 0.6 * d$x + 0.8 * stats::rt(n, df = 6)
        d
      },
      fml = quote(drmTMB::bf(y ~ x, sigma ~ 1, nu ~ 1)),
      fam = quote(drmTMB::student()), newdata = nd_x
    ),
    lognormal = list(
      build = function() {
        set.seed(20260907)
        n <- 300
        d <- data.frame(x = stats::rnorm(n))
        d$y <- exp(0.2 + 0.5 * d$x + stats::rnorm(n, sd = 0.4))
        d
      },
      fml = quote(drmTMB::bf(y ~ x, sigma ~ 1)),
      fam = quote(drmTMB::lognormal()), newdata = nd_x
    ),
    poisson = list(
      build = function() {
        set.seed(20260908)
        n <- 300
        d <- data.frame(x = stats::rnorm(n))
        d$y <- stats::rpois(n, exp(0.8 + 0.4 * d$x))
        d
      },
      fml = quote(drmTMB::bf(y ~ x)),
      fam = quote(stats::poisson()), newdata = nd_x
    ),
    nbinom2 = list(
      build = function() {
        set.seed(20260909)
        n <- 400
        d <- data.frame(x = stats::rnorm(n))
        d$y <- stats::rnbinom(n, size = 1 / 0.6^2, mu = exp(0.7 + 0.35 * d$x))
        d
      },
      fml = quote(drmTMB::bf(y ~ x, sigma ~ 1)),
      fam = quote(drmTMB::nbinom2()), newdata = nd_x
    ),
    gamma = list(
      build = function() {
        set.seed(20260910)
        n <- 300
        d <- data.frame(x = stats::rnorm(n))
        mu <- exp(0.9 + 0.3 * d$x)
        shape <- 1 / 0.5^2
        d$y <- stats::rgamma(n, shape = shape, rate = shape / mu)
        d
      },
      fml = quote(drmTMB::bf(y ~ x, sigma ~ 1)),
      fam = quote(stats::Gamma(link = "log")), newdata = nd_x
    ),
    beta = list(
      build = function() {
        set.seed(20260911)
        n <- 400
        d <- data.frame(x = stats::rnorm(n))
        mu <- stats::plogis(-0.2 + 0.6 * d$x)
        phi <- 1 / 0.35^2
        d$y <- stats::rbeta(n, mu * phi, (1 - mu) * phi)
        d
      },
      fml = quote(drmTMB::bf(y ~ x, sigma ~ 1)),
      fam = quote(drmTMB::beta()), newdata = nd_x
    ),
    binomial = list(
      build = function() {
        set.seed(20260912)
        n <- 400
        d <- data.frame(x = stats::rnorm(n), trials = sample(6:20, n, TRUE))
        d$successes <- stats::rbinom(n, d$trials, stats::plogis(-0.1 + 0.7 * d$x))
        d$failures <- d$trials - d$successes
        d
      },
      fml = quote(drmTMB::bf(cbind(successes, failures) ~ x)),
      fam = quote(stats::binomial()),
      newdata = data.frame(x = c(-1, 0, 1), trials = c(8, 12, 20))
    ),
    truncated_nbinom2 = list(
      build = function() {
        set.seed(20260729)
        n <- 300
        x <- stats::rnorm(n)
        mu <- exp(0.5 + 0.25 * x)
        sigma <- 0.6
        p0 <- stats::dnbinom(0, size = 1 / sigma^2, mu = mu)
        u <- p0 + pmax(stats::runif(n), 1e-10) * (1 - p0)
        data.frame(y = stats::qnbinom(u, size = 1 / sigma^2, mu = mu), x = x)
      },
      fml = quote(drmTMB::bf(y ~ x, sigma ~ 1)),
      fam = quote(drmTMB::truncated_nbinom2()), newdata = nd_x
    ),
    zero_one_beta = list(
      build = function() {
        set.seed(20260620)
        n <- 800
        d <- data.frame(
          x = stats::rnorm(n), z = stats::rnorm(n),
          w = stats::rnorm(n), v = stats::rnorm(n)
        )
        mu <- stats::plogis(-0.20 + 0.65 * d$x)
        sigma <- exp(-0.85 + 0.22 * d$z)
        zoi <- stats::plogis(-1.00 + 0.45 * d$w)
        coi <- stats::plogis(0.15 - 0.55 * d$v)
        y <- stats::rbeta(n, mu / sigma^2, (1 - mu) / sigma^2)
        boundary <- stats::runif(n) < zoi
        y[boundary] <- as.numeric(stats::runif(sum(boundary)) < coi[boundary])
        d$prop <- y
        d
      },
      fml = quote(drmTMB::bf(prop ~ x, sigma ~ z, zoi ~ w, coi ~ v)),
      fam = quote(drmTMB::zero_one_beta()),
      newdata = data.frame(
        x = c(-1, 0, 1), z = c(-0.5, 0, 0.5),
        w = c(0, 0.3, -0.3), v = c(0.2, -0.2, 0)
      )
    ),
    tweedie = list(
      build = function() {
        set.seed(20260701)
        n <- 500L
        d <- data.frame(x = stats::runif(n, -1, 1), z = stats::rnorm(n))
        mu <- exp(0.2 + 0.45 * d$x)
        sigma <- exp(-0.55 + 0.20 * d$z)
        d$y <- drmTMB:::rtweedie_compound(n, mu = mu, phi = sigma^2, power = 1.35)
        d
      },
      fml = quote(drmTMB::bf(y ~ x, sigma ~ z, nu ~ 1)),
      fam = quote(drmTMB::tweedie()),
      newdata = data.frame(x = c(-0.5, 0, 0.5), z = c(-0.5, 0, 0.5))
    ),
    beta_binomial = list(
      build = function() {
        set.seed(20260510)
        n <- 600
        d <- data.frame(
          x = stats::rnorm(n), z = stats::rnorm(n),
          trials = sample(8:24, n, TRUE)
        )
        mu <- stats::plogis(-0.20 + 0.70 * d$x)
        phi <- 1 / exp(-1.10 + 0.25 * d$z)^2
        p <- stats::rbeta(n, mu * phi, (1 - mu) * phi)
        d$success <- stats::rbinom(n, d$trials, p)
        d$failure <- d$trials - d$success
        d
      },
      fml = quote(drmTMB::bf(cbind(success, failure) ~ x, sigma ~ z)),
      fam = quote(drmTMB::beta_binomial()),
      newdata = data.frame(x = c(-1, 0, 1), z = c(-0.5, 0, 0.5), trials = c(10, 16, 24))
    ),
    cumulative_logit = list(
      build = function() {
        set.seed(20260509)
        n <- 600
        d <- data.frame(x = stats::rnorm(n))
        cutpoints <- c(-0.90, 0.75)
        eta <- 0.85 * d$x
        p_low <- stats::plogis(cutpoints[[1L]] - eta)
        p_medium <- stats::plogis(cutpoints[[2L]] - eta) - p_low
        prob <- cbind(p_low, p_medium, 1 - stats::plogis(cutpoints[[2L]] - eta))
        draw <- vapply(
          seq_len(n), function(i) sample.int(3L, 1L, prob = prob[i, ]), integer(1)
        )
        d$score <- ordered(
          c("low", "medium", "high")[draw], levels = c("low", "medium", "high")
        )
        d
      },
      fml = quote(drmTMB::bf(score ~ x)),
      fam = quote(drmTMB::cumulative_logit()), newdata = nd_x
    ),
    biv_gaussian = list(
      build = function() {
        set.seed(20260913)
        n <- 300
        d <- data.frame(x = stats::rnorm(n))
        d$y1 <- 0.3 + 0.5 * d$x + stats::rnorm(n, sd = 0.7)
        d$y2 <- -0.2 + 0.4 * d$x + stats::rnorm(n, sd = 0.9)
        d
      },
      fml = quote(drmTMB::bf(
        mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      )),
      fam = quote(drmTMB::biv_gaussian()), newdata = nd_x,
      dpar = c("mu1", "mu2")
    )
  )
}

drm_quantile_bridge_roundtrip <- function() {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_test_drmjl_path()
  callr::r(
    function(pkg, jl_path, specs, prob) {
      julia_home <- Sys.getenv("DRM_JL_JULIA_HOME", Sys.getenv("JULIA_HOME", ""))
      if (nzchar(julia_home)) Sys.setenv(JULIA_HOME = julia_home)
      options(drmTMB.DRM.jl.path = jl_path)
      Sys.setenv(DRM_JL_PATH = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))
      lapply(specs, function(spec) {
        dat <- spec$build()
        fml <- eval(spec$fml)
        fam <- eval(spec$fam)
        ft <- drmTMB::drmTMB(fml, family = fam, data = dat, engine = "tmb")
        fj <- drmTMB::drmTMB(fml, family = fam, data = dat, engine = "julia")
        dpars <- if (is.null(spec$dpar)) list(NULL) else as.list(spec$dpar)
        list(
          converged = drmTMB::is_converged(fj),
          nobs = stats::nobs(fj),
          per_dpar = lapply(dpars, function(dp) {
            qt <- predict(ft, dpar = dp, type = "quantile", prob = prob)
            qj <- predict(fj, dpar = dp, type = "quantile", prob = prob)
            nt <- predict(ft, newdata = spec$newdata, dpar = dp,
                          type = "quantile", prob = prob)
            nj <- predict(fj, newdata = spec$newdata, dpar = dp,
                          type = "quantile", prob = prob)
            list(
              dpar = if (is.null(dp)) "<default>" else dp,
              dim_tmb = dim(qt), dim_julia = dim(qj),
              colnames_tmb = colnames(qt), colnames_julia = colnames(qj),
              calibrated_julia = attr(qj, "calibrated"),
              prob_julia = attr(qj, "prob"),
              label_julia = attr(qj, "label"),
              max_abs_stored = max(abs(qj - qt)),
              max_abs_newdata = max(abs(nj - nt)),
              dim_newdata_tmb = dim(nt), dim_newdata_julia = dim(nj)
            )
          })
        )
      })
    },
    args = list(
      pkg = pkg, jl_path = jl_path,
      specs = drm_quantile_bridge_specs(), prob = drm_quantile_bridge_prob()
    ),
    error = "stack"
  )
}

test_that("predict(type = 'quantile') on live engine = 'julia' fits matches engine = 'tmb' for every admitted family", {
  drm_skip_live_julia()
  testthat::skip_if_not_installed("JuliaCall")
  testthat::skip_if_not_installed("callr")
  testthat::skip_if_not_installed("pkgload")

  specs <- drm_quantile_bridge_specs()
  prob <- drm_quantile_bridge_prob()
  labels <- vapply(
    prob, function(p) paste0(format(100 * p, trim = TRUE, drop0trailing = TRUE), "%"),
    character(1)
  )

  # Fence: the cells below are exactly the bridge's fixed-effect family list,
  # so a family added to the registry without a quantile receipt fails here.
  expect_setequal(names(specs), drmTMB:::drm_julia_registry_families("fe"))

  out <- drm_quantile_bridge_roundtrip()
  expect_setequal(names(out), names(specs))

  for (family in names(out)) {
    cell <- out[[family]]
    expect_true(isTRUE(cell$converged), info = family)
    for (p in cell$per_dpar) {
      info <- paste(family, p$dpar)
      # Same SHAPE as the native result.
      expect_identical(p$dim_julia, p$dim_tmb, info = info)
      expect_identical(p$dim_julia, c(cell$nobs, length(prob)), info = info)
      expect_identical(p$dim_newdata_julia, p$dim_newdata_tmb, info = info)
      # Same LABELS and attributes.
      expect_identical(p$colnames_julia, p$colnames_tmb, info = info)
      expect_identical(p$colnames_julia, labels, info = info)
      expect_false(p$calibrated_julia, info = info)
      expect_identical(p$prob_julia, prob, info = info)
      expect_identical(p$label_julia, "distributional (plug-in) interval", info = info)
      # Same VALUES: this is a deterministic computation off the fitted
      # parameters, so the bar is 1e-6 on both stored and fresh rows.
      expect_lt(p$max_abs_stored, 1e-6)
      expect_lt(p$max_abs_newdata, 1e-6)
    }
  }
})

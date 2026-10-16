# anova.drmTMB() wired to drm_lrtest() (#1240, owner decision 2026-10-11):
# an LRT table with the REML/MAP guards, a boundary warning, and the
# chi-bar-square p-value from lrt_boundary() when exactly one or two variance
# components are added.

anova_fixed_data <- function() {
  set.seed(1)
  n <- 80
  d <- data.frame(x = stats::rnorm(n), z = stats::rnorm(n))
  d$y <- 0.2 + 0.6 * d$x + stats::rnorm(n)
  d
}

anova_ri_data <- function() {
  set.seed(2)
  G <- 30
  m <- 8
  g <- factor(rep(seq_len(G), each = m))
  b <- stats::rnorm(G, sd = 0.6)
  d <- data.frame(g = g, x = stats::rnorm(G * m), z = stats::rnorm(G * m))
  d$y <- 0.5 + 0.4 * d$x + b[g] + stats::rnorm(G * m, sd = 0.7)
  d
}

anova_fit <- function(form, dat, ...) {
  drmTMB(form, family = gaussian(), data = dat, ...)
}

test_that("anova() returns an LRT table that equals drm_lrtest() (#1240)", {
  d <- anova_fixed_data()
  m0 <- anova_fit(bf(y ~ 1, sigma ~ 1), d)
  m1 <- anova_fit(bf(y ~ x, sigma ~ 1), d)
  a <- anova(m0, m1)
  expect_s3_class(a, c("anova", "data.frame"))
  expect_identical(rownames(a), c("m0", "m1"))
  expect_identical(
    names(a),
    c("npar", "logLik", "deviance", "Chisq", "Df", "Pr(>Chisq)")
  )
  ref <- drmTMB:::drm_lrtest(m0, m1)
  expect_equal(a$Chisq[[2L]], ref$statistic, tolerance = 1e-12)
  expect_equal(a$Df[[2L]], ref$df)
  expect_equal(a$`Pr(>Chisq)`[[2L]], ref$p.value, tolerance = 1e-12)
  expect_equal(a$`Pr(>Chisq)`[[2L]], stats::pchisq(a$Chisq[[2L]], 1, lower.tail = FALSE))
  expect_equal(a$deviance, -2 * a$logLik)
  expect_equal(a$npar, c(m0$df, m1$df))
  expect_true(all(is.na(unlist(a[1L, c("Chisq", "Df", "Pr(>Chisq)")]))))
  expect_identical(attr(a, "p.method"), c(NA_character_, "chisq"))
  # No boundary warning when no variance component is added.
  expect_no_warning(anova(m0, m1))
  # The order of the arguments does not matter: fits are sorted by size.
  b <- anova(m1, m0)
  expect_identical(rownames(b), c("m0", "m1"))
  expect_equal(b$Chisq, a$Chisq)
  expect_equal(anova(m0, m1, test = "LRT")$Chisq, a$Chisq)
})

test_that("anova() compares more than two fits sequentially (#1240)", {
  d <- anova_fixed_data()
  m0 <- anova_fit(bf(y ~ 1, sigma ~ 1), d)
  m1 <- anova_fit(bf(y ~ x, sigma ~ 1), d)
  m2 <- anova_fit(bf(y ~ x + z, sigma ~ 1), d)
  a <- anova(m0, m1, m2)
  expect_identical(rownames(a), c("m0", "m1", "m2"))
  expect_equal(a$Chisq[[3L]], drmTMB:::drm_lrtest(m1, m2)$statistic, tolerance = 1e-12)
  expect_equal(a$Df, c(NA, 1, 1))
  named <- anova(m0, full = m1)
  expect_identical(rownames(named), c("m0", "full"))
})

test_that("anova() uses the chi-bar-square p-value when one SD is added (#1240)", {
  d <- anova_ri_data()
  r0 <- anova_fit(bf(y ~ x, sigma ~ 1), d)
  r1 <- anova_fit(bf(y ~ x + (1 | g), sigma ~ 1), d)
  expect_warning(
    a <- anova(r0, r1),
    class = "drmTMB_anova_boundary_warning"
  )
  lb <- lrt_boundary(r1, r0, q = 1)
  expect_equal(a$`Pr(>Chisq)`[[2L]], lb$pvalue, tolerance = 1e-12)
  expect_equal(a$`Pr(>Chisq)`[[2L]], 0.5 * lb$pvalue_naive, tolerance = 1e-12)
  expect_lt(a$`Pr(>Chisq)`[[2L]], lb$pvalue_naive)
  expect_identical(attr(a, "p.method"), c(NA_character_, "chibar"))
  # The pairwise helper's own conservative warning is not duplicated.
  w <- testthat::capture_warnings(anova(r0, r1))
  expect_length(w, 1L)
  expect_match(w, "chi-bar-square")
})

test_that("anova() keeps the naive p-value and says so when the mixture does not apply (#1240)", {
  d <- anova_ri_data()
  r0 <- anova_fit(bf(y ~ 1, sigma ~ 1), d)
  # One added SD plus an added fixed effect: df difference 2 != q = 1.
  r1 <- anova_fit(bf(y ~ x + (1 | g), sigma ~ 1), d)
  expect_warning(
    a <- anova(r0, r1),
    regexp = "does not apply",
    class = "drmTMB_anova_boundary_warning"
  )
  expect_identical(attr(a, "p.method"), c(NA_character_, "chisq"))
  expect_equal(
    a$`Pr(>Chisq)`[[2L]],
    stats::pchisq(a$Chisq[[2L]], a$Df[[2L]], lower.tail = FALSE),
    tolerance = 1e-12
  )
})

test_that("anova() refuses unsafe comparisons with a message that says what to do (#1240)", {
  d <- anova_fixed_data()
  m0 <- anova_fit(bf(y ~ 1, sigma ~ 1), d)
  m1 <- anova_fit(bf(y ~ x, sigma ~ 1), d)
  # One fit, or fits of equal size.
  expect_error(anova(m0), "at least two nested")
  expect_error(anova(m0, m0), "strictly increasing")
  expect_error(anova(m0, m1, test = "F"), "must be")
  # Different observations.
  m1_small <- anova_fit(bf(y ~ x, sigma ~ 1), d[-1L, ])
  expect_error(anova(m0, m1_small), "different numbers of observations")
  # REML: never mixed with ML, and REML fits need the same mean structure.
  r_null <- anova_fit(bf(y ~ 1, sigma ~ 1), d, REML = TRUE)
  r_full <- anova_fit(bf(y ~ x, sigma ~ 1), d, REML = TRUE)
  expect_error(anova(m0, r_full), class = "drmTMB_anova_estimator_error")
  expect_error(anova(r_null, r_full), class = "drmTMB_lrtest_reml_error")
  # Penalized (MAP) fits.
  map0 <- m0
  map1 <- m1
  map0$estimator <- map1$estimator <- "MAP"
  expect_error(anova(map0, map1), class = "drmTMB_lrtest_map_error")
  # engine = "julia" fits are not mixed in.
  stub <- structure(list(nobs = nrow(d), df = 4L), class = "drmTMB_julia")
  expect_error(anova(m0, stub), "engine")
})

test_that("anova() on an engine = 'julia' fit still refuses (#1240)", {
  stub <- structure(list(nobs = 7L, df = 3L), class = "drmTMB_julia")
  expect_error(stats::anova(stub), "not implemented for <drmTMB_julia> fits")
})

# ---------------------------------------------------------------------------
# Family-dispersion boundary: Poisson ⊂ NB2 tests sigma at 0 (#1557).
# The extra NB2 scale is not an RE SD, so the #1240 detector missed it and
# anova() reported a naive chi-square with no warning. This is the t10
# red-proof: it fails on ca3ddef (p.method = "chisq", no warning) and passes
# once anova() applies the same chi-bar path it already uses for (1 | g).
# ---------------------------------------------------------------------------

anova_nb2_null_data <- function() {
  # Official campaign seed 20261017000 overflows set.seed; same map as #1557.
  set.seed(as.integer(20261017000 - 1.9e10))
  n <- 80L
  d <- data.frame(x = stats::rnorm(n))
  d$y <- stats::rpois(n, lambda = exp(0.4 + 0.3 * d$x))
  d
}

test_that("anova() uses chi-bar for Poisson vs NB2 and warns (#1557)", {
  d <- anova_nb2_null_data()
  ctrl <- drm_control(se = FALSE)
  pois <- drmTMB(bf(y ~ x), family = stats::poisson(), data = d, control = ctrl)
  nb <- drmTMB(bf(y ~ x, sigma ~ 1), family = nbinom2(), data = d, control = ctrl)
  expect_warning(
    a <- anova(pois, nb),
    class = "drmTMB_anova_boundary_warning"
  )
  lb <- lrt_boundary(nb, pois, q = 1)
  expect_equal(a$`Pr(>Chisq)`[[2L]], lb$pvalue, tolerance = 1e-12)
  expect_equal(a$`Pr(>Chisq)`[[2L]], 0.5 * lb$pvalue_naive, tolerance = 1e-12)
  expect_identical(attr(a, "p.method"), c(NA_character_, "chibar"))
  w <- testthat::capture_warnings(anova(pois, nb))
  expect_length(w, 1L)
  expect_match(w, "sigma")
  expect_match(w, "chi-bar-square")
})

test_that("drm_lrtest() warns on Poisson vs NB2 but keeps the naive p (#1557)", {
  d <- anova_nb2_null_data()
  ctrl <- drm_control(se = FALSE)
  pois <- drmTMB(bf(y ~ x), family = stats::poisson(), data = d, control = ctrl)
  nb <- drmTMB(bf(y ~ x, sigma ~ 1), family = nbinom2(), data = d, control = ctrl)
  expect_warning(
    t <- drmTMB:::drm_lrtest(pois, nb),
    class = "drmTMB_lrtest_boundary_warning"
  )
  lb <- lrt_boundary(nb, pois, q = 1)
  expect_equal(t$p.value, lb$pvalue_naive, tolerance = 1e-12)
  expect_gt(t$p.value, lb$pvalue)
})

test_that("anova() keeps naive chi-square when Poisson vs NB2 adds more than sigma (#1557)", {
  d <- anova_nb2_null_data()
  ctrl <- drm_control(se = FALSE)
  pois <- drmTMB(bf(y ~ 1), family = stats::poisson(), data = d, control = ctrl)
  # Extra sigma plus an extra mean coefficient: df = 2 != q = 1.
  nb <- drmTMB(bf(y ~ x, sigma ~ 1), family = nbinom2(), data = d, control = ctrl)
  expect_warning(
    a <- anova(pois, nb),
    regexp = "does not apply",
    class = "drmTMB_anova_boundary_warning"
  )
  expect_identical(attr(a, "p.method"), c(NA_character_, "chisq"))
  expect_equal(
    a$`Pr(>Chisq)`[[2L]],
    stats::pchisq(a$Chisq[[2L]], a$Df[[2L]], lower.tail = FALSE),
    tolerance = 1e-12
  )
})

test_that("family-boundary detector is Poisson to NB2 only; siblings stay off (#1557)", {
  stub <- function(type, df) {
    structure(
      list(
        model = list(model_type = type),
        df = df,
        sdpars = NULL,
        corpars = NULL
      ),
      class = "drmTMB"
    )
  }
  pois <- stub("poisson", 2)
  nb <- stub("nbinom2", 3)
  zip <- stub("zi_poisson", 3)
  bb <- stub("beta_binomial", 3)
  bin <- stub("binomial", 2)
  fam <- drmTMB:::drm_anova_family_boundary(pois, nb)
  expect_identical(fam$added_dpar, "sigma")
  expect_true(fam$applies)
  expect_false(drmTMB:::drm_anova_family_boundary(pois, zip)$applies)
  expect_false(drmTMB:::drm_anova_family_boundary(bin, bb)$applies)
  expect_false(drmTMB:::drm_anova_family_boundary(nb, pois)$applies)
})

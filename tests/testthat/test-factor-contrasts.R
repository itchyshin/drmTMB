# User-set factor contrasts must reach the fixed-effect design (#1495).
# `drmTMB()` drops unused levels of fixed-effect factors up front (Dinnage
# audit Md-E). `base::droplevels()` rebuilds the factor and drops its
# `contrasts` attribute, so `contr.sum` silently became treatment coding.

test_that("#1495 repro: contr.sum columns and estimates match lm()", {
  skip_on_cran()
  set.seed(1)
  d <- data.frame(y = stats::rnorm(30), g = factor(rep(c("a", "b", "c"), 10)))
  stats::contrasts(d$g) <- stats::contr.sum(3)

  ref <- stats::lm(y ~ g, d)
  expect_identical(
    colnames(stats::model.matrix(y ~ g, d)),
    c("(Intercept)", "g1", "g2")
  )

  fit <- drmTMB(bf(y ~ g, sigma ~ 1), data = d, family = gaussian())
  est <- coef(fit, "mu")
  expect_identical(names(est), names(stats::coef(ref)))
  expect_false(any(c("gb", "gc") %in% names(est)))
  # Gaussian ML for the location equals OLS.
  expect_equal(unname(est), unname(stats::coef(ref)), tolerance = 1e-6)
})

test_that("an ordered factor keeps a stored contrast matrix when a level is dropped", {
  o <- ordered(c("a", "b", "c", "a", "b", "c"), levels = c("a", "b", "c", "d"))
  stats::contrasts(o) <- stats::contr.treatment(4)
  new <- drmTMB:::drm_droplevels_keep_contrasts_factor(o)
  expect_identical(levels(new), c("a", "b", "c"))
  expect_true(is.ordered(new))
  ctr <- attr(new, "contrasts")
  expect_true(is.matrix(ctr))
  expect_identical(colnames(ctr), c("2", "3"))
  expect_identical(
    colnames(stats::model.matrix(~o, data.frame(o = new))),
    c("(Intercept)", "o2", "o3")
  )
})

test_that("a contrast function name survives dropping an unused level", {
  f <- factor(c("a", "b", "c", "a", "b", "c"), levels = c("a", "b", "c", "d"))
  stats::contrasts(f) <- "contr.helmert"
  new <- drmTMB:::drm_droplevels_keep_contrasts_factor(f)
  expect_identical(levels(new), c("a", "b", "c"))
  expect_identical(attr(new, "contrasts"), "contr.helmert")
  expect_equal(
    unname(stats::contrasts(new)),
    unname(stats::contr.helmert(3))
  )
})

test_that("a contrast matrix that cannot be kept warns instead of switching silently", {
  # contr.sum(4) restricted to three levels is not a contrast basis.
  f <- factor(c("a", "b", "c", "a", "b", "c"), levels = c("a", "b", "c", "d"))
  stats::contrasts(f) <- stats::contr.sum(4)
  expect_warning(
    new <- drmTMB:::drm_droplevels_keep_contrasts_factor(f, name = "f"),
    class = "drmTMB_contrasts_dropped"
  )
  expect_identical(levels(new), c("a", "b", "c"))
  expect_null(attr(new, "contrasts"))
})

test_that("drmTMB() keeps a contrast function name on a factor with an unused level", {
  skip_on_cran()
  # A stored name ("contr.sum") is rebuilt on the levels that remain, so the
  # unused level d does not turn g1, g2 into treatment columns gb, gc.
  set.seed(1)
  g <- factor(rep(c("a", "b", "c"), 10), levels = c("a", "b", "c", "d"))
  stats::contrasts(g) <- "contr.sum"
  d <- data.frame(y = stats::rnorm(30), g = g)
  ref_data <- d
  ref_data$g <- droplevels(ref_data$g)
  stats::contrasts(ref_data$g) <- stats::contr.sum(3)
  ref <- stats::lm(y ~ g, ref_data)

  fit <- drmTMB(bf(y ~ g, sigma ~ 1), data = d, family = gaussian())
  est <- coef(fit, "mu")
  expect_identical(names(est), c("(Intercept)", "g1", "g2"))
  expect_equal(unname(est), unname(stats::coef(ref)), tolerance = 1e-6)
})

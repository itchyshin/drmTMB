# #1240: anova.drmTMB() runs the likelihood-ratio test through drm_lrtest().

anova_fixture <- function() {
  set.seed(1)
  g <- rep(seq_len(15), each = 8)
  x <- rnorm(length(g))
  y <- 0.5 * x + rnorm(15, sd = 0.8)[g] + rnorm(length(g))
  data.frame(y = y, x = x, g = factor(g))
}
anova_fit <- function(form, dat, ...) {
  suppressWarnings(drmTMB(form, family = gaussian(), data = dat, ...))
}

test_that("anova(m0, m1) returns an LRT table equal to drm_lrtest()", {
  dat <- anova_fixture()
  m0 <- anova_fit(bf(y ~ 1, sigma ~ 1), dat)
  m1 <- anova_fit(bf(y ~ x, sigma ~ 1), dat)
  a <- anova(m0, m1)
  l <- drmTMB:::drm_lrtest(m0, m1)
  expect_s3_class(a, "anova")
  expect_equal(nrow(a), 2L)
  expect_equal(a$Chisq[2], l$statistic)
  expect_equal(a$`Chi Df`[2], l$df)
  expect_equal(a$`Pr(>Chisq)`[2], l$p.value)
  expect_true(is.na(a$`Pr(>Chisq)`[1]))
})

test_that("anova() guards: one fit, wrong order, bad test, foreign fit", {
  dat <- anova_fixture()
  m0 <- anova_fit(bf(y ~ 1, sigma ~ 1), dat)
  m1 <- anova_fit(bf(y ~ x, sigma ~ 1), dat)
  expect_error(anova(m0), "at least two")
  expect_error(anova(m1, m0), "more parameters")
  expect_error(anova(m0, m1, test = "F"), "Chisq")
  expect_error(anova(m0, stats::lm(y ~ x, dat)), "drmTMB")
})

test_that("anova() refuses REML fits with different mean structures", {
  dat <- anova_fixture()
  r0 <- anova_fit(bf(y ~ 1, sigma ~ 1), dat, REML = TRUE)
  r1 <- anova_fit(bf(y ~ x, sigma ~ 1), dat, REML = TRUE)
  expect_error(anova(r0, r1), class = "drmTMB_lrtest_reml_error")
})

test_that("a boundary random-intercept SD gets the chi-bar-square p-value", {
  dat <- anova_fixture()
  m0 <- anova_fit(bf(y ~ x, sigma ~ 1), dat)
  m1 <- anova_fit(bf(y ~ x + (1 | g), sigma ~ 1), dat)
  expect_warning(a <- anova(m0, m1), class = "drmTMB_anova_boundary_warning")
  b <- lrt_boundary(m1, m0, q = 1)
  expect_equal(a$`Pr(>Chisq)`[2], b$pvalue)
  expect_lte(a$`Pr(>Chisq)`[2], b$pvalue_naive)
})

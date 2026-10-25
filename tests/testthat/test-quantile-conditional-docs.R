# On fitted rows of a random-effect fit, predict(type = "quantile"), exceedance()
# and residuals(type = "quantile") are conditional on the random-effect modes
# (owner decision on #1568: keep that behaviour and say so in the help pages).
# The behaviour half pins the code; the Rd half pins the wording and reads the
# committed man/*.Rd, which test-man-roxygen-sync.R keeps equal to the roxygen
# blocks in R/.
new_conditional_quantile_fit <- function() {
  set.seed(20261025)
  g <- factor(rep(seq_len(20), each = 8))
  x <- stats::rnorm(160)
  b <- stats::rnorm(20, sd = 0.8)
  d <- data.frame(g = g, x = x, y = 0.3 + 0.5 * x + b[g] + stats::rnorm(160, sd = 0.6))
  list(
    d = d,
    fit = drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(), data = d)
  )
}

test_that("fitted-row quantile, exceedance and quantile residuals are conditional on the modes (#1568)", {
  skip_on_cran()
  z <- new_conditional_quantile_fit()
  fit <- z$fit
  d <- z$d
  mu_pop <- predict(fit, newdata = d, dpar = "mu")
  mu_cond <- predict(fit, dpar = "mu")
  sig <- predict(fit, dpar = "sigma")
  expect_gt(max(abs(mu_cond - mu_pop)), 0.1)

  q50 <- predict(fit, type = "quantile", prob = 0.5)[, 1]
  expect_equal(unname(q50), unname(mu_cond), tolerance = 1e-8)
  expect_gt(max(abs(q50 - mu_pop)), 0.1)

  ex <- exceedance(fit, threshold = 1)
  expect_equal(
    as.numeric(ex),
    as.numeric(stats::pnorm(1, mu_cond, sig, lower.tail = FALSE)),
    tolerance = 1e-8
  )

  rq <- residuals(fit, type = "quantile")
  expect_equal(unname(rq), unname((d$y - mu_cond) / sig), tolerance = 1e-8)

  # With newdata the same functions are population-level, as documented.
  q50_new <- predict(fit, newdata = d, type = "quantile", prob = 0.5)[, 1]
  expect_equal(unname(q50_new), unname(mu_pop), tolerance = 1e-8)
})

test_that("?predict.drmTMB, ?exceedance and ?residuals.drmTMB say fitted rows are conditional on the modes (#1568)", {
  for (nm in c("predict.drmTMB", "exceedance", "residuals.drmTMB")) {
    rd <- test_path("..", "..", "man", paste0(nm, ".Rd"))
    skip_if_not(file.exists(rd), "man/ is unavailable in an installed-package check.")
    text <- gsub("\\s+", " ", paste(readLines(rd, warn = FALSE), collapse = " "))
    expect_true(grepl("conditional on the random-effect modes", text, fixed = TRUE), info = nm)
    expect_false(grepl("fixed-effect, population-level parameter estimates", text, fixed = TRUE), info = nm)
    expect_false(grepl("at the fitted, fixed-effect distributional parameters", text, fixed = TRUE), info = nm)
  }
})

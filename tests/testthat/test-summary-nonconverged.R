test_that("summary() flags a non-converged fit like print() does (#1545)", {
  set.seed(1545)
  d <- data.frame(x = rnorm(60))
  d$y <- 1 + 0.5 * d$x + rnorm(60)
  fit <- drmTMB(bf(mu = y ~ x, sigma = ~ 1), data = d, family = gaussian())

  ok <- summary(fit)
  expect_no_warning(out_ok <- cli::cli_fmt(print(ok)))
  expect_false(any(grepl("not converged", out_ok)))

  fit$opt$convergence <- 1L
  fit$opt$message <- "iteration limit reached without convergence (10)"
  s <- summary(fit)
  expect_identical(s$convergence_message, fit$opt$message)
  expect_warning(
    out <- cli::cli_fmt(print(s)),
    "did not converge"
  )
  expect_true(any(grepl("not converged", out)))
  expect_true(any(grepl("iteration limit reached", out)))
})

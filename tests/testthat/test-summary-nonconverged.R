test_that("summary() flags a non-converged fit like print() does (#1545)", {
  skip_on_cran()
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
    "did not converge",
    class = "drmTMB_convergence_warning"
  )
  expect_true(any(grepl("not converged", out)))
  expect_true(any(grepl("iteration limit reached", out)))
})

test_that("summary() flags a real non-converged Student t fit (#1545)", {
  skip_on_cran()
  # The #1545 false-convergence fits came from the large-nu density drift that
  # #1504 fixed, and they no longer reproduce. Capping the nlminb evaluation
  # budget gives a real, unmocked non-convergence on every platform.
  set.seed(1545)
  d <- data.frame(y = 1 + 1.3 * rt(50, df = 30))
  ctl <- drm_control(optimizer = list(iter.max = 2L, eval.max = 4L))
  expect_warning(
    fit <- drmTMB(
      bf(y ~ 1, sigma ~ 1, nu ~ 1),
      data = d,
      family = student(),
      control = ctl
    ),
    class = "drmTMB_convergence_warning"
  )
  expect_false(identical(fit$opt$convergence, 0L))

  s <- summary(fit)
  expect_identical(s$convergence_message, fit$opt$message)
  expect_warning(
    out <- cli::cli_fmt(print(s)),
    "did not converge",
    class = "drmTMB_convergence_warning"
  )
  expect_true(any(grepl("not converged", out)))
})

test_that("print(summary) warns when convergence_status is not converged at code 0 (#1951)", {
  skip_on_cran()
  set.seed(1)
  d <- data.frame(y = rnorm(60), x = rnorm(60))
  d$x2 <- d$x
  fit <- suppressWarnings(drmTMB(bf(y ~ x + x2, sigma ~ 1), data = d, family = gaussian()))
  expect_false(is_converged(fit))
  expect_identical(convergence_status(fit), "degenerate")
  expect_identical(fit$opt$convergence, 0L)

  s <- summary(fit)
  expect_identical(s$convergence_status, "degenerate")
  expect_warning(
    out <- cli::cli_fmt(print(s)),
    "did not converge",
    class = "drmTMB_convergence_warning"
  )
  expect_true(any(grepl("convergence_status is degenerate", out)))
})

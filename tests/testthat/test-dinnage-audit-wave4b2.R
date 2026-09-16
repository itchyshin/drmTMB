# Wave B2 (Dinnage audit arc 3): surfaces (#1332 A-2, #1360 UX-5, #1353 Mi-15,
# #1355 Mi-bundle, #1316 S7 docs-light).

wave4b2_gaussian_with_na_predictor <- function(n = 40L, n_na = 4L, seed = 1332L) {
  set.seed(seed)
  x <- stats::rnorm(n)
  x[seq_len(n_na)] <- NA_real_
  data.frame(y = stats::rnorm(n), x = x)
}

wave4b2_repo_r_drmtmb <- function() {
  drm_pkg_path("R/drmTMB.R")
}

wave4b2_drm_control_rd <- function() {
  drm_pkg_path("man/drm_control.Rd")
}

test_that("A-2: miss_control(predictor = fail) errors on NA predictors (Dinnage audit)", {
  dat <- wave4b2_gaussian_with_na_predictor()
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = gaussian(),
      data = dat,
      missing = miss_control(predictor = "fail")
    ),
    "predictor|missing|NA",
    ignore.case = TRUE
  )
})

test_that("UX-5: bf() accepts a formula held in a variable (Dinnage audit)", {
  f_mu <- y ~ x
  f_sigma <- ~ 1
  parsed <- bf(mu = f_mu, sigma = f_sigma)
  expect_s3_class(parsed, "drm_formula")
  expect_equal(parsed$names, c("mu", "sigma"))
})

test_that("Mi-15: as.matrix() on confint gives a 2-column stats-style matrix (Dinnage audit)", {
  dat <- data.frame(y = stats::rnorm(30), x = stats::rnorm(30))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  ci <- confint(fit, parm = "fixef:mu:x")
  expect_s3_class(ci, "data.frame")
  expect_gt(ncol(ci), 2L)
  m <- as.matrix(ci)
  expect_true(is.matrix(m))
  expect_equal(ncol(m), 2L)
  expect_equal(nrow(m), 1L)
  expect_true(all(is.finite(m)))
})

test_that("Mi-bundle: unsupported-parameter aborts include an i hint (Dinnage audit)", {
  dat_count <- data.frame(y = stats::rpois(25, lambda = 4), x = stats::rnorm(25))
  dat_pos <- data.frame(y = exp(stats::rnorm(25)), x = stats::rnorm(25))

  err_poisson <- tryCatch(
    drmTMB(bf(y ~ x, sigma ~ 1), family = poisson(), data = dat_count),
    error = function(e) e
  )
  expect_s3_class(err_poisson, "error")
  expect_match(conditionMessage(err_poisson), "Unsupported parameter")
  expect_match(conditionMessage(err_poisson), "i")

  err_lognormal <- tryCatch(
    drmTMB(bf(y ~ x, nu ~ 1), family = lognormal(), data = dat_pos),
    error = function(e) e
  )
  expect_s3_class(err_lognormal, "error")
  expect_match(conditionMessage(err_lognormal), "Unsupported parameter")
  expect_match(conditionMessage(err_lognormal), "i")
})

test_that("Mi-bundle: all drmTMB unsupported-parameter branches carry an i hint (Dinnage audit)", {
  lines <- readLines(wave4b2_repo_r_drmtmb(), warn = FALSE)
  hits <- grep('"x" = "Unsupported parameter', lines, fixed = FALSE)
  expect_length(hits, 17L)
  for (line_no in hits) {
    block <- paste(lines[line_no:min(line_no + 4L, length(lines))], collapse = "\n")
    expect_match(
      block,
      '"i" =',
      fixed = TRUE,
      info = sprintf("missing hint near R/drmTMB.R:%d", line_no)
    )
  }
})

test_that("Mi-bundle: mistyped data columns get a guided error (Dinnage audit)", {
  dat <- data.frame(y = stats::rnorm(15), x = stats::rnorm(15))
  err <- tryCatch(
    drmTMB(bf(y ~ typo_col), family = gaussian(), data = dat),
    error = function(e) e
  )
  expect_s3_class(err, "error")
  msg <- conditionMessage(err)
  expect_false(identical(msg, "undefined columns selected"))
  expect_match(msg, "typo_col|column|variable", ignore.case = TRUE)
})

test_that("Mi-bundle: singular missing weight uses correct grammar (Dinnage audit)", {
  dat <- data.frame(
    y = stats::rnorm(5),
    x = stats::rnorm(5),
    w = c(1, 1, 1, NA_real_, 1)
  )
  err <- tryCatch(
    drmTMB(bf(y ~ x), family = gaussian(), data = dat, weights = dat$w),
    error = function(e) e
  )
  expect_s3_class(err, "error")
  msg <- conditionMessage(err)
  expect_match(msg, "1 weight value")
  expect_match(msg, "is missing", fixed = TRUE)
  expect_false(grepl("1 weight value are", msg, fixed = TRUE))
})

test_that("Mi-bundle: AIC across identical REML fits does not warn (Dinnage audit)", {
  set.seed(1360)
  dat <- data.frame(
    y = stats::rnorm(40),
    x = stats::rnorm(40),
    id = factor(rep(seq_len(10L), each = 4L))
  )
  fit_a <- drmTMB(bf(y ~ x + (1 | id)), family = gaussian(), data = dat, REML = TRUE)
  fit_b <- drmTMB(bf(y ~ x + (1 | id)), family = gaussian(), data = dat, REML = TRUE)
  expect_warning(AIC(fit_a, fit_b), NA)
})

test_that("Mi-bundle: Tweedie d/p/q guard invalid power before calling tweedie (Dinnage audit)", {
  skip_if_not_installed("tweedie")
  set.seed(1355)
  dat <- data.frame(
    y = abs(stats::rnorm(40)) + stats::rpois(40, 0.2),
    x = stats::rnorm(40)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ 1),
    family = tweedie(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  dpq <- drm_family_dpq(fit)
  bad <- tryCatch(
    dpq$d(c(0.5, 1), params = list(mu = 1, sigma = 1, nu = c(2.5, 3))),
    error = function(e) e
  )
  expect_s3_class(bad, "error")
  expect_match(conditionMessage(bad), "power|nu|Tweedie", ignore.case = TRUE)
})

test_that("S7: drm_control documents joint sigma+zi local optima and multi_start (Dinnage audit)", {
  rd <- paste(readLines(wave4b2_drm_control_rd(), warn = FALSE), collapse = "\n")
  expect_match(rd, "multi_start", fixed = TRUE)
  expect_match(rd, "sigma", fixed = TRUE)
  expect_match(rd, "zi", fixed = TRUE)
  expect_match(rd, "local|optimum|basin", ignore.case = TRUE)
})

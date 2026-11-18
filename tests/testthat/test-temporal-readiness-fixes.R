temporal_readiness_data <- function(occasions = c(0L, 1L, 3L, 4L, 6L, 7L), seed = 7L) {
  set.seed(seed)
  dat <- expand.grid(
    occasion = occasions,
    id = sprintf("id_%02d", seq_len(30L)),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  dat$x <- stats::rnorm(nrow(dat))
  dat$y <- 0.3 * dat$x + rep(stats::rnorm(30L, sd = 0.5), each = length(occasions)) +
    stats::rnorm(nrow(dat))
  dat
}

test_that("non-temporal fits carry no temporal start bookkeeping", {
  dat <- temporal_readiness_data()
  fit_a <- drmTMB(bf(y ~ x + (1 | id)), data = dat)
  fit_b <- drmTMB(bf(y ~ x + (1 | id)), data = dat)
  expect_false("temporal_start_attempts" %in% names(fit_a))
  expect_null(attr(fit_a$opt, "drm_start_attempts"))
  # The optimizer result is again reproducible bit for bit: no wall-clock
  # timings ride along on `opt`.
  expect_identical(fit_a$opt, fit_b$opt)

  multi <- drmTMB(bf(y ~ x + (1 | id)), data = dat, control = drm_control(multi_start = 2L))
  expect_false("temporal_start_attempts" %in% names(multi))
  expect_null(attr(multi$opt, "drm_start_attempts"))
})

test_that("temporal fits warn that multi_start is not used and keep their start table", {
  dat <- temporal_readiness_data()
  expect_warning(
    fit <- drmTMB(
      bf(y ~ x + temporal(1 | id, time = occasion, structure = "ar1")),
      data = dat,
      control = drm_control(multi_start = 3L)
    ),
    "multi_start = 3"
  )
  expect_s3_class(fit$temporal_start_attempts, "data.frame")
  expect_identical(nrow(fit$temporal_start_attempts), 2L)
  expect_identical(sum(fit$temporal_start_attempts$selected), 1L)

  warnings <- character()
  withCallingHandlers(
    drmTMB(
      bf(y ~ x + temporal(1 | id, time = occasion, structure = "ar1")),
      data = dat
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  expect_false(any(grepl("multi_start", warnings, fixed = TRUE)))
})

test_that("print() counts the temporal term among mu random-effect terms", {
  dat <- temporal_readiness_data()
  ar1_only <- drmTMB(
    bf(y ~ x + temporal(1 | id, time = occasion, structure = "ar1")),
    data = dat
  )
  combined <- drmTMB(
    bf(y ~ x + (1 | id) + temporal(1 | id, time = occasion, structure = "ar1")),
    data = dat
  )
  expect_message(print(ar1_only), "mu random-effect terms: 1", fixed = TRUE)
  expect_message(print(combined), "mu random-effect terms: 2", fixed = TRUE)
})

test_that("temporal slopes get the temporal-specific intercept-only message", {
  dat <- temporal_readiness_data()
  error <- tryCatch(
    drmTMB(bf(y ~ temporal(x | id, time = occasion, structure = "ar1")), data = dat),
    error = function(e) e
  )
  expect_s3_class(error, "error")
  message <- conditionMessage(error)
  expect_match(message, "intercept-only", fixed = TRUE)
  expect_no_match(message, "1 + x", fixed = TRUE)
})

test_that("even-lag AR1 designs are told to rescale time by the common gap", {
  biennial <- temporal_readiness_data(occasions = c(0L, 2L, 4L, 6L))
  expect_error(
    drmTMB(
      bf(y ~ x + temporal(1 | id, time = occasion, structure = "ar1")),
      data = biennial
    ),
    "divide\\s+.?occasion.?\\s+by\\s+2"
  )
  sparse <- temporal_readiness_data(occasions = c(0L, 2L))
  expect_error(
    drmTMB(
      bf(y ~ x + temporal(1 | id, time = occasion, structure = "ar1")),
      data = sparse
    ),
    "collect\\s+more\\s+distinct\\s+within-series\\s+occasions"
  )
  expect_identical(drmTMB:::temporal_integer_gcd(12L, 18L), 6L)
  expect_identical(Reduce(drmTMB:::temporal_integer_gcd, c(2L, 4L, 6L), 0L), 2L)
})

test_that("OU fits with elapsed gaps beyond the integer range do not warn", {
  set.seed(11)
  seconds <- c(0, 1, 3, 6) * 1e9
  dat <- do.call(rbind, lapply(seq_len(20L), function(i) {
    data.frame(id = sprintf("s%02d", i), t = seconds, x = stats::rnorm(4L))
  }))
  dat$y <- 0.3 * dat$x + rep(stats::rnorm(20L), each = 4L) + stats::rnorm(nrow(dat))
  warnings <- character()
  fit <- withCallingHandlers(
    drmTMB(
      bf(y ~ x + temporal(1 | id, time = t, structure = "ou")),
      data = dat
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  expect_false(any(grepl("coercion to integer", warnings, fixed = TRUE)))
  expect_true(all(drmTMB:::temporal_mu_tmb_data(fit$model)$temporal_mu_gap == 0L))
  expect_true(is.finite(as.numeric(logLik(fit))))
})

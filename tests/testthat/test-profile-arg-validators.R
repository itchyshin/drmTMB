# Fit-free characterisation tests for the argument validators in R/profile.R.
# No model is fitted; each helper is called directly.

test_that("validate_interval_method() rejects malformed method values", {
  f <- drmTMB:::validate_interval_method
  ch <- c("wald", "profile")
  expect_error(f(1, ch, "confint"), "non-missing character")
  expect_error(f(NULL, ch, "confint"), "non-missing character")
  expect_error(f(character(0), ch, "confint"), "non-missing character")
  expect_error(f(NA_character_, ch, "confint"), "non-missing character")
  expect_error(f(c("wald", NA), ch, "confint"), "non-missing character")
  expect_error(f("", ch, "confint"), "non-missing character")
  expect_error(f(c("wald", ""), ch, "confint"), "non-missing character")
})

test_that("validate_interval_method() handles vectors of length > 1", {
  f <- drmTMB:::validate_interval_method
  ch <- c("wald", "profile")
  # A vector entirely inside `choices` (e.g. the unevaluated default) takes
  # the first choice.
  expect_identical(f(ch, ch, "confint"), "wald")
  expect_identical(f(rev(ch), ch, "confint"), "wald")
  expect_error(
    f(c("wald", "other"), ch, "confint"),
    "must be a single character value"
  )
})

test_that("validate_interval_method() resolves, partially matches, and refuses", {
  f <- drmTMB:::validate_interval_method
  ch <- c("wald", "profile")
  expect_identical(f("profile", ch, "confint"), "profile")
  expect_identical(f("prof", ch, "confint"), "profile")
  expect_identical(f("w", ch, "confint"), "wald")
  expect_error(f("nonsense", ch, "confint"), "must be one of")
  # Ambiguous partial match: pmatch() returns NA.
  expect_error(f("p", c("profile", "parametric"), "confint"), "must be one of")
})

test_that("validate_interval_method() gives a dedicated bootstrap message", {
  f <- drmTMB:::validate_interval_method
  ch <- c("wald", "profile")
  expect_error(f("bootstrap", ch, "confint"), "not implemented")
  expect_error(f("parametric_bootstrap", ch, "confint"), "not implemented")
  # The caller name is interpolated into the message.
  expect_error(f("bootstrap", ch, "my_caller"), "my_caller")
  # The bootstrap values pass through when they are valid choices.
  ch_boot <- c("wald", "bootstrap")
  expect_identical(f("bootstrap", ch_boot, "confint"), "bootstrap")
  expect_identical(f("boot", ch_boot, "confint"), "bootstrap")
  # Not exact: "parametric_bootstrap" is only special-cased by exact string.
  expect_error(f("param", ch, "confint"), "must be one of")
})

test_that("resolve_profile_precision() defaults, matches, and errors", {
  f <- drmTMB:::resolve_profile_precision
  expect_identical(f("fast", missing_arg = TRUE), "default")
  expect_identical(f(c("default", "fast"), missing_arg = TRUE), "default")
  expect_identical(f("default"), "default")
  expect_identical(f("fast"), "fast")
  expect_identical(f("fa"), "fast")
  expect_identical(f(c("default", "fast")), "default")
  expect_error(f("slow"), "should be one of")
  expect_error(f(1), "must be NULL or a character vector")
})

test_that("resolve_bootstrap_parallel() defaults, matches, and errors", {
  f <- drmTMB:::resolve_bootstrap_parallel
  expect_identical(f("cluster", missing_arg = TRUE), "none")
  expect_identical(f("none"), "none")
  expect_identical(f("multicore"), "multicore")
  expect_identical(f("clu"), "cluster")
  expect_identical(f(c("none", "multicore", "cluster")), "none")
  expect_error(f("snow"), "should be one of")
})

test_that("validate_profile_maxit() passes NULL and whole numbers", {
  f <- drmTMB:::validate_profile_maxit
  expect_null(f(NULL))
  expect_identical(f(5), 5L)
  expect_identical(f(5.0), 5L)
  expect_identical(f(5L), 5L)
  expect_identical(f(1), 1L)
})

test_that("validate_profile_maxit() rejects everything else", {
  f <- drmTMB:::validate_profile_maxit
  for (bad in list(0, -1, 2.5, NA, NA_real_, Inf, -Inf, c(1, 2), "a", TRUE, numeric(0))) {
    expect_error(f(bad), "positive whole number")
  }
})

test_that("validate_profile_plot_flag() accepts one logical and names the argument", {
  f <- drmTMB:::validate_profile_plot_flag
  expect_true(f(TRUE, "show_ci"))
  expect_false(f(FALSE, "show_ci"))
  for (bad in list(NA, NA_integer_, NULL, c(TRUE, FALSE), "yes", 1, logical(0))) {
    expect_error(f(bad, "show_ci"), "show_ci")
    expect_error(f(bad, "other_flag"), "other_flag")
  }
  expect_error(f(NA, "show_ci"), "single")
})

test_that("profile_first_pass_args() validates ystep and ytol", {
  f <- drmTMB:::profile_first_pass_args
  args <- list(ystep = 0.1, ytol = 3)
  bad_values <- list(0, -1, NA_real_, Inf, -Inf, NaN, "a", TRUE, c(1, 2), numeric(0), NULL)
  for (bad in bad_values) {
    expect_error(f(args, bad, 1), "first_pass_ystep")
    expect_error(f(args, 1, bad), "first_pass_ytol")
  }
  # ystep is checked first.
  expect_error(f(args, 0, 0), "first_pass_ystep")
})

test_that("profile_first_pass_args() overrides ystep/ytol and drops maxit", {
  f <- drmTMB:::profile_first_pass_args
  args <- list(ystep = 0.1, ytol = 0.5, maxit = 7L, trace = FALSE, parm = "a")
  out <- f(args, ystep = 0.4, ytol = 2)
  expect_identical(out$ystep, 0.4)
  expect_identical(out$ytol, 2)
  # maxit is removed (the first pass uses the TMB default); this is the one
  # deliberate difference from "all other elements unchanged".
  expect_false("maxit" %in% names(out))
  expect_identical(out$trace, FALSE)
  expect_identical(out$parm, "a")
  expect_setequal(names(out), c("ystep", "ytol", "trace", "parm"))
  # Elements absent from the input stay absent; integer inputs are accepted.
  out2 <- f(list(), 1L, 2L)
  expect_identical(out2, list(ystep = 1L, ytol = 2L))
})

test_that("validate_profile_plot_data() rejects non-profile objects", {
  f <- drmTMB:::validate_profile_plot_data
  expect_error(f(data.frame(a = 1)), "profile.drmTMB")
  expect_error(f(list()), "profile.drmTMB")
  expect_error(f(NULL), "profile.drmTMB")
  # Class set but not a data frame.
  expect_error(f(structure(list(), class = "profile.drmTMB")), "profile.drmTMB")
})

make_profile_frame <- function() {
  structure(
    data.frame(
      parm = "mu:(Intercept)",
      level = 0.95,
      profile_value = 1,
      delta_deviance = 0,
      estimate = 1,
      conf.low = 0.5,
      conf.high = 1.5,
      conf.status = "ok",
      stringsAsFactors = FALSE
    ),
    class = c("profile.drmTMB", "data.frame")
  )
}

test_that("validate_profile_plot_data() lists missing and non-numeric columns", {
  f <- drmTMB:::validate_profile_plot_data
  ok <- make_profile_frame()
  expect_identical(f(ok), ok)

  miss <- ok
  miss$conf.low <- NULL
  miss$estimate <- NULL
  expect_error(f(miss), "missing profile column")
  expect_error(f(miss), "conf.low")
  expect_error(f(miss), "estimate")

  bad <- ok
  bad$level <- "0.95"
  expect_error(f(bad), "must be numeric")
  expect_error(f(bad), "level")
})

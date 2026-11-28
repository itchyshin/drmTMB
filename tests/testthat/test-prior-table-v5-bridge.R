v5_mock_result <- function(expected, n = 4L) {
  list(
    prior_contract = "parameter_priors_v5",
    resolved_priors_v5 = expected,
    data_nll = 10, data_logLik = -10,
    fixed_prior_penalty = 0.1, residual_sd_prior_penalty = 0.2,
    random_effect_sd_prior_penalty = 0.3, correlation_prior_penalty = 0.4,
    penalized_objective = 11, data_gradient = rep(1, n),
    fixed_prior_gradient = rep(0.1, n), residual_sd_prior_gradient = rep(0.2, n),
    random_effect_sd_prior_gradient = rep(0.3, n), correlation_prior_gradient = rep(0.4, n),
    prior_penalty = 1, prior_gradient = rep(1, n), penalized_gradient = rep(2, n),
    penalised = TRUE, objective = -11, logLik = -10, log_prior = -1,
    pd_hessian_unpenalised = FALSE, prior_held_params = list(),
    se_type = "penalised", estim_method = "MAP", infocrit_basis = "unavailable"
  )
}

test_that("v5 serializer emits residual-SD natural-scale semantics", {
  residual <- drm_residual_sd_prior_gamma(shape = 2, rate = 3)
  resolved <- data.frame(class = "residual_sd", dpar = "sigma", group = NA_character_,
    block = "residual", coefficient = "(Intercept)", scale = "natural_sd",
    kind = "gamma", shape = 2, rate = 3)
  options <- drm_julia_prior_v5_options(list(residual), resolved,
    list(mu = c("(Intercept)", "x"), sigma = "(Intercept)"))
  expect_identical(options$prior_contract, "parameter_priors_v5")
  expect_identical(options$priors_v5[[1]], list(kind = "residual_sd_gamma", dpar = "sigma",
    coef = "(Intercept)", shape = 2, rate = 3, measure = "natural_sd"))
  expect_equal(options$prior_expected_v5[[1]]$index, 3L)
  expect_equal(options$prior_expected_v5[[1]]$log_normalizer, -2 * log(3) + lgamma(2))
  expect_false("jacobian" %in% names(options$prior_expected_v5[[1]]))

  student <- drm_prior_student_t(dpar = "mu", coef = "x", mean = 0.1,
    scale = 1.2, df = 4)
  full_resolved <- resolved
  full_resolved$reason <- full_resolved$precision <- full_resolved$mean <-
    full_resolved$sd <- full_resolved$df <- full_resolved$from_coef <-
    full_resolved$to_coef <- full_resolved$eta <- full_resolved$support_guard <-
    full_resolved$log_normalizer <- NA_real_
  fixed <- full_resolved[1, , drop = FALSE]
  fixed[] <- NA
  fixed$class <- "fixed"; fixed$dpar <- "mu"; fixed$coefficient <- "x"
  fixed$scale <- "link"; fixed$kind <- "student_t"; fixed$reason <- "exact column"
  fixed$precision <- 1 / 1.2^2; fixed$mean <- 0.1; fixed$sd <- 1.2; fixed$df <- 4
  student_options <- drm_julia_prior_v5_options(list(student, residual),
    rbind(fixed, full_resolved), list(mu = c("(Intercept)", "x"), sigma = "(Intercept)"))
  expect_identical(student_options$priors_v5[[1]]$kind, "fixed_student_t")
  expect_equal(student_options$prior_expected_v5[[1]][c("location", "scale", "df")],
    list(location = 0.1, scale = 1.2, df = 4))
  expect_equal(student_options$prior_expected_v5[[2]]$spec_index, 2L)

  all_coef <- drm_prior_normal(dpar = "mu", coef = "all", mean = 0, sd = 2,
    intercept = "include")
  expect_error(drm_julia_prior_v5_options(list(all_coef, residual), resolved,
    list(mu = c("(Intercept)", "x"), sigma = "(Intercept)")),
    "exact fixed-effect coefficient targets")
})

test_that("v5 composes Student-t coefficients with a random-intercept SD prior", {
  student <- drm_prior_student_t(dpar = "mu", coef = "x", mean = 0.25,
    scale = 1.4, df = 4)
  sd_prior <- drm_prior_sd_gamma(dpar = "mu", group = "site", shape = 2, rate = 3)
  priors <- list(student, sd_prior)
  resolved <- data.frame(
    class = c("fixed", "sd_gamma"), dpar = c("mu", "mu"),
    group = c(NA_character_, "site"), block = c(NA_character_, "mu:site"),
    coefficient = c("x", "(Intercept)"), scale = c("link", "natural_sd"),
    kind = c("student_t", "gamma"), shape = c(NA_real_, 2),
    rate = c(NA_real_, 3), from_coef = NA_character_, to_coef = NA_character_,
    eta = NA_real_, support_guard = NA_real_, log_normalizer = NA_real_,
    reason = c("exact column", NA_character_), precision = c(1 / 1.4^2, NA_real_),
    mean = c(0.25, NA_real_), sd = c(1.4, NA_real_), df = c(4, NA_real_),
    stringsAsFactors = FALSE
  )

  expect_true(drm_julia_has_student_t_with_sd_prior(priors))
  expect_false(drm_prior_uses_native_only_targets(priors))
  expect_false(drm_julia_has_student_t_with_sd_prior(list(student)))
  expect_false(drm_julia_has_student_t_with_sd_prior(list(sd_prior)))
  expect_false(drm_prior_uses_native_only_targets(list(student),
    formula = bf(mu = y ~ x, sigma = ~1)))
  expect_true(drm_prior_uses_native_only_targets(list(student),
    formula = bf(mu = y ~ x + (1 | site), sigma = ~1)))
  expect_true(drm_prior_uses_native_only_targets(list(student, sd_prior,
    drm_correlation_prior_lkj(dpar = "mu", group = "site",
      from_coef = "(Intercept)", to_coef = "x", eta = 2))))
  options <- drm_julia_prior_v5_options(priors, resolved,
    list(mu = c("(Intercept)", "x"), sigma = "(Intercept)"), "site")
  expect_identical(options$prior_contract, "parameter_priors_v5")
  expect_identical(vapply(options$priors_v5, `[[`, character(1), "kind"),
    c("fixed_student_t", "ranef_sd_gamma"))
  expect_equal(vapply(options$prior_expected_v5, `[[`, character(1), "class"),
    c("fixed", "ranef_sd"))
  expect_equal(options$prior_expected_v5[[1L]][c("location", "scale", "df")],
    list(location = 0.25, scale = 1.4, df = 4))
  expect_identical(options$prior_expected_v5[[1L]][c("index", "matrix_column")],
    list(index = 2L, matrix_column = 2L))
  expect_identical(options$prior_expected_v5[[2L]]$index, 4L)
  expect_false("jacobian" %in% names(options$prior_expected_v5[[2L]]))

  result <- v5_mock_result(options$prior_expected_v5)
  expect_no_error(drm_julia_validate_prior_v5_result(result, options$prior_expected_v5))
  result$resolved_priors_v5[[1L]]$index <- 1L
  expect_error(drm_julia_validate_prior_v5_result(result, options$prior_expected_v5),
    "resolved prior records differ")
  result <- v5_mock_result(options$prior_expected_v5)
  result$resolved_priors_v5[[2L]]$index <- NULL
  expect_error(drm_julia_validate_prior_v5_result(result, options$prior_expected_v5),
    "invalid resolved prior record fields")

  two_sd <- list(student,
    drm_prior_sd_gamma(dpar = "mu", group = "site", shape = 2, rate = 3),
    drm_prior_sd_gamma(dpar = "mu", group = "observer", shape = 3, rate = 4))
  two_resolved <- rbind(resolved, transform(resolved[2L, , drop = FALSE],
    group = "observer", block = "mu:observer", shape = 3, rate = 4))
  two_options <- drm_julia_prior_v5_options(two_sd, two_resolved,
    list(mu = c("(Intercept)", "x"), sigma = "(Intercept)"),
    c("site", "observer"))
  expect_equal(vapply(two_options$prior_expected_v5[-1L], `[[`, integer(1), "index"),
    c(4L, 5L))
  result <- v5_mock_result(two_options$prior_expected_v5, n = 5L)
  result$resolved_priors_v5[[2L]]$index <- 5L
  result$resolved_priors_v5[[3L]]$index <- 4L
  expect_error(drm_julia_validate_prior_v5_result(result, two_options$prior_expected_v5),
    "resolved prior records differ")
  result <- v5_mock_result(two_options$prior_expected_v5, n = 5L)
  result$resolved_priors_v5[[2L]]$group <- "observer"
  expect_error(drm_julia_validate_prior_v5_result(result, two_options$prior_expected_v5),
    "resolved prior records differ")
})

test_that("v5 composes fixed, residual-SD, random-SD and q2 correlation targets", {
  priors <- list(
    drm_prior_normal(dpar = "mu", coef = "x", mean = 0.25, sd = 1.5),
    drm_residual_sd_prior_gamma(shape = 2, rate = 3),
    drm_prior_sd_gamma(group = "site", shape = 2, rate = 3),
    drm_correlation_prior_lkj(dpar = "mu", group = "site",
      from_coef = "(Intercept)", to_coef = "x", eta = 2)
  )
  resolved <- data.frame(
    class = c("fixed", "residual_sd", "sd_gamma", "correlation"),
    dpar = c("mu", "sigma", "mu", "mu"),
    group = c(NA, NA, "site", "site"),
    block = c(NA, "residual", "mu:site", "cor(mu:(Intercept),mu:x | site)"),
    coefficient = c("x", "(Intercept)", "(Intercept)", NA),
    scale = c("link", "natural_sd", "SD", "natural_correlation"),
    kind = c("normal", "gamma", "gamma", "lkj"),
    shape = c(NA, 2, 2, NA), rate = c(NA, 3, 3, NA),
    from_coef = c(NA, NA, NA, "(Intercept)"),
    to_coef = c(NA, NA, NA, "x"),
    eta = c(NA, NA, NA, 2), reason = c("explicit", NA, NA, NA),
    precision = c(1 / 1.5^2, NA, NA, NA), mean = c(0.25, NA, NA, NA),
    sd = c(1.5, NA, NA, NA), df = NA_real_
  )
  options <- drm_julia_prior_v5_options(priors, resolved,
    list(mu = c("(Intercept)", "x"), sigma = "(Intercept)"), "site")
  expect_identical(options$prior_contract, "parameter_priors_v5")
  expect_equal(vapply(options$prior_expected_v5, `[[`, integer(1), "spec_index"), 1:4)
  expect_equal(vapply(options$prior_expected_v5, `[[`, character(1), "class"),
    c("fixed", "residual_sd", "ranef_sd", "random_effect_correlation"))
  expect_equal(options$prior_expected_v5[[2]]$index, 3L)
  expect_equal(options$prior_expected_v5[[3]]$index, 4L)
  expect_equal(options$prior_expected_v5[[4]]$index, 4L)

  result <- v5_mock_result(options$prior_expected_v5)
  result$resolved_priors_v5[[3]]$index <- 4L
  result$resolved_priors_v5[[4]]$support_guard <- result$resolved_priors_v5[[4]]$guard
  expect_no_error(drm_julia_validate_prior_v5_result(result, options$prior_expected_v5))
  result$resolved_priors_v5[[3]]$index <- 5L
  expect_error(drm_julia_validate_prior_v5_result(result, options$prior_expected_v5),
    "resolved prior records differ")
  result <- v5_mock_result(options$prior_expected_v5)
  result$resolved_priors_v5[[2]]$log_normalizer <- result$resolved_priors_v5[[2]]$log_normalizer + 0.1
  expect_error(drm_julia_validate_prior_v5_result(result, options$prior_expected_v5),
    "resolved prior records differ")
})

test_that("v5 refuses unsupported residual-plus-rho12 correlation and checks decompositions", {
  residual <- drm_residual_sd_prior_gamma(shape = 2, rate = 3)
  rho12 <- drm_correlation_prior_lkj(dpar = "rho12", eta = 2)
  expect_true(drm_prior_uses_native_only_targets(list(residual, rho12)))
  result <- v5_mock_result(list(list(spec_index = 1L, kind = "residual_sd_gamma",
    class = "residual_sd", dpar = "sigma", coef = "(Intercept)",
    block = "gaussian_residual", measure = "natural_sd", shape = 2, rate = 3,
    log_normalizer = -2 * log(3) + lgamma(2), index = 2L)))
  result$penalized_objective <- 12
  expect_error(drm_julia_validate_prior_v5_result(result,
    result$resolved_priors_v5), "objective decomposition")
})

test_that("v5 serializes mixed bivariate fixed priors with rho12 LKJ", {
  priors <- list(
    drm_prior_normal(dpar = "mu1", coef = "x", mean = 0.2, sd = 1.3),
    drm_prior_student_t(dpar = "mu2", coef = "(Intercept)", mean = -0.1,
      scale = 0.8, df = 5),
    drm_correlation_prior_lkj(dpar = "rho12", eta = 2)
  )
  resolved <- data.frame(
    class = c("fixed", "fixed", "correlation"),
    dpar = c("mu1", "mu2", "rho12"),
    group = NA_character_, block = c(NA, NA, "bivariate_residual"),
    coefficient = c("x", "(Intercept)", "(Intercept)"),
    scale = c("link", "link", "natural_correlation"),
    kind = c("normal", "student_t", "lkj"), shape = NA_real_, rate = NA_real_,
    from_coef = NA_character_, to_coef = NA_character_, eta = c(NA, NA, 2),
    reason = c("exact", "exact", NA), precision = c(1 / 1.3^2, 1 / 0.8^2, NA),
    mean = c(0.2, -0.1, NA), sd = c(1.3, 0.8, NA), df = c(NA, 5, NA)
  )
  options <- drm_julia_prior_v5_options(priors, resolved,
    list(mu1 = c("(Intercept)", "x"), mu2 = c("(Intercept)", "x")))
  expect_identical(options$prior_contract, "parameter_priors_v5")
  expect_identical(vapply(options$priors_v5, `[[`, character(1), "kind"),
    c("fixed_normal", "fixed_student_t", "lkj_residual_correlation"))
  expect_equal(options$prior_expected_v5[[1L]]$dpar, "mu1")
  expect_equal(options$prior_expected_v5[[2L]]$dpar, "mu2")
  expect_equal(options$prior_expected_v5[[3L]][c("class", "block", "scale", "eta")],
    list(class = "residual_correlation", block = "bivariate_residual",
      scale = "natural_correlation", eta = 2))

  result <- v5_mock_result(options$prior_expected_v5)
  result$resolved_priors_v5[[1L]]$index <- 2L
  result$resolved_priors_v5[[1L]]$matrix_column <- 2L
  result$resolved_priors_v5[[2L]]$index <- 3L
  result$resolved_priors_v5[[2L]]$matrix_column <- 1L
  result$resolved_priors_v5[[3L]]$guard <- 0.999999
  result$resolved_priors_v5[[3L]]$index <- 5L
  expect_no_error(drm_julia_validate_prior_v5_result(result, options$prior_expected_v5))
  result$resolved_priors_v5[[3L]]$dpar <- "mu"
  expect_error(drm_julia_validate_prior_v5_result(result, options$prior_expected_v5),
    "resolved prior records differ")
})

test_that("live v5 residual and mixed q2 fixtures agree through the Julia bridge", {
  skip_if_not(identical(Sys.getenv("DRMTMB_JULIA_BRIDGE_V5"), "1"),
    "Set DRMTMB_JULIA_BRIDGE_V5=1 after the embedded Julia process is clear.")
  skip_if_not_installed("JuliaCall")
  expected_sha <- Sys.getenv("DRMTMB_JULIA_V5_SOURCE_SHA")
  skip_if_not(nzchar(expected_sha),
    "Set DRMTMB_JULIA_V5_SOURCE_SHA to the reviewed DRModels.jl source commit.")
  expect_match(expected_sha, "^[0-9a-f]{40}$")
  active_pid <- system2("ps", c("-p", "21585", "-o", "pid="), stdout = TRUE,
    stderr = FALSE)
  skip_if(nzchar(trimws(paste(active_pid, collapse = ""))),
    "A separately owned embedded Julia process (PID 21585) is still active.")
  julia_path <- drm_julia_path()
  actual_sha <- system2("git", c("-C", shQuote(julia_path), "rev-parse", "HEAD"),
    stdout = TRUE, stderr = FALSE)
  expect_identical(trimws(actual_sha[[1L]]), expected_sha)
  source_status <- system2("git", c("-C", shQuote(julia_path), "status",
    "--porcelain", "--untracked-files=normal"), stdout = TRUE, stderr = FALSE)
  expect_identical(trimws(paste(source_status, collapse = "")), "")

  set.seed(27051)
  data <- data.frame(x = rep(c(-1, 0, 1), 16),
    site = factor(rep(rep(letters[1:8], each = 3), 2)))
  data$y <- 0.2 + 0.45 * data$x + rnorm(nrow(data)) +
    rnorm(8, sd = 0.35)[as.integer(data$site)]
  residual <- data.frame(prior = "gamma(2,3)", class = "residual_sd",
    dpar = "sigma", coef = "(Intercept)", scale = "natural_sd")
  residual_fit <- suppressWarnings(drmTMB(
    bf(mu = y ~ x, sigma = ~1), data = data, priors = residual,
    engine = "julia"
  ))
  expect_identical(residual_fit$bridge_payload$options$prior_contract,
    "parameter_priors_v5")
  expect_true(is.finite(residual_fit$residual_sd_prior_penalty))
  expect_equal(residual_fit$bridge_payload$options$prior_expected_v5[[1L]]$index, 3L)

  mixed_sd <- drm_priors(
    drm_prior_student_t(dpar = "mu", coef = "x", mean = 0, scale = 1.5, df = 4),
    drm_prior_sd_gamma(dpar = "mu", group = "site", shape = 2, rate = 3)
  )
  mixed_sd_fit <- suppressWarnings(drmTMB(
    bf(mu = y ~ x + (1 | site), sigma = ~1), data = data,
    priors = mixed_sd, engine = "julia"
  ))
  expect_identical(mixed_sd_fit$bridge_payload$options$prior_contract,
    "parameter_priors_v5")
  expect_true(is.finite(mixed_sd_fit$fixed_prior_penalty))
  expect_true(is.finite(mixed_sd_fit$random_effect_sd_prior_penalty))
  expect_equal(mixed_sd_fit$penalized_objective,
    -mixed_sd_fit$logLik + mixed_sd_fit$prior_penalty, tolerance = 1e-8)

  mixed <- data.frame(
    prior = c("normal(0.25,1.5)", "gamma(2,3)", "lkj(2)"),
    class = c("fixef", "residual_sd", "correlation"),
    dpar = c("mu", "sigma", "mu"),
    coef = c("x", "(Intercept)", ""),
    group = c("", "", "site"),
    from_coef = c("", "", "(Intercept)"),
    to_coef = c("", "", "x"),
    scale = c("link", "natural_sd", "natural_correlation")
  )
  mixed_fit <- suppressWarnings(drmTMB(
    bf(mu = y ~ x + (1 + x | site), sigma = ~1), data = data,
    priors = mixed, engine = "julia"
  ))
  expect_identical(mixed_fit$bridge_payload$options$prior_contract,
    "parameter_priors_v5")
  expect_equal(nrow(mixed_fit$resolved_correlation_prior), 1L)
  expect_true(is.finite(mixed_fit$fixed_prior_penalty))
  expect_true(is.finite(mixed_fit$residual_sd_prior_penalty))
  expect_true(is.finite(mixed_fit$correlation_prior_penalty))

  biv_data <- data.frame(x = rep(c(-1, 0, 1), 24))
  biv_data$y1 <- 0.2 + 0.4 * biv_data$x + rnorm(nrow(biv_data))
  biv_data$y2 <- -0.1 + 0.3 * biv_data$x + 0.35 * (biv_data$y1 - 0.2) +
    rnorm(nrow(biv_data))
  biv_priors <- data.frame(
    prior = c("normal(0.2,1.3)", "student_t(-0.1,0.8,5)", "lkj(2)"),
    class = c("fixef", "fixef", "correlation"),
    dpar = c("mu1", "mu2", "rho12"),
    coef = c("x", "(Intercept)", "(Intercept)"),
    scale = c("link", "link", "natural_correlation")
  )
  expect_error(drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~1),
    family = biv_gaussian(), data = biv_data,
    priors = biv_priors, engine = "julia"
  ), "does not support this combination of prior targets")
})

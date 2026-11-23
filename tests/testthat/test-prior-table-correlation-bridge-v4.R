mock_prior_v4_result <- function(expected) {
  n <- 2L
  list(
    prior_contract = "parameter_priors_v4",
    resolved_priors_v4 = lapply(expected, function(x) c(x, list(index = 4L))),
    working_coordinates = c("mu_(Intercept)", "mu_x"),
    working_values = c(0, 0),
    data_nll = 10,
    data_logLik = -10,
    data_logLik = -10,
    fixed_prior_penalty = 0,
    correlation_prior_penalty = 0.2,
    penalized_objective = 10.2,
    data_gradient = c(1, 2),
    fixed_prior_gradient = c(0, 0),
    correlation_prior_gradient = c(0.1, 0.2),
    penalized_gradient = c(1.1, 2.2),
    logLik = -10,
    log_prior = -0.2,
    penalised = TRUE,
    objective = -10.2,
    pd_hessian_unpenalised = FALSE,
    prior_held_params = list(list(name = "rho12", kind = "correlation")),
    se_type = "penalised",
    estim_method = "MAP",
    infocrit_basis = "unavailable",
    n = n
  )
}

test_that("v4 correlation handshakes carry semantic support and normalization", {
  rho <- drm_correlation_prior_lkj(dpar = "rho12", eta = 2)
  q2 <- drm_correlation_prior_lkj(
    dpar = "mu", group = "site", from_coef = "(Intercept)",
    to_coef = "x", eta = 2
  )
  fixed <- drm_prior_normal(dpar = "mu", coef = "x", mean = 0.25, sd = 1.5)
  ridge <- drm_prior_ridge(dpar = "mu", coef = "(Intercept)", lambda = 0.4)

  rho_resolved <- data.frame(
    class = "correlation", dpar = "rho12", group = NA_character_,
    block = "bivariate_residual", coefficient = "(Intercept)",
    from_coef = NA_character_, to_coef = NA_character_,
    scale = "natural_correlation", kind = "lkj", eta = 2
  )
  q2_resolved <- data.frame(
    class = c("correlation", "fixed", "fixed"), dpar = rep("mu", 3),
    group = c("site", NA_character_, NA_character_),
    block = c("cor(mu:(Intercept),mu:x | site)", NA_character_, NA_character_),
    coefficient = c(NA_character_, "x", "(Intercept)"),
    from_coef = c("(Intercept)", NA_character_, NA_character_),
    to_coef = c("x", NA_character_, NA_character_),
    scale = c("natural_correlation", "link", "link"),
    kind = c("lkj", "normal", "ridge"), eta = c(2, NA_real_, NA_real_),
    reason = c(NA_character_, "explicit", "explicit"),
    precision = c(NA_real_, 1 / 1.5^2, 0.4),
    mean = c(NA_real_, 0.25, NA_real_), sd = c(NA_real_, 1.5, NA_real_),
    df = rep(NA_real_, 3)
  )

  rho_options <- drm_julia_prior_v4_options(list(rho), rho_resolved)
  expect_identical(rho_options$prior_contract, "parameter_priors_v4")
  expect_equal(length(rho_options$priors_v4), 1L)
  expect_equal(length(rho_options$prior_expected_v4), 1L)
  expect_equal(rho_options$prior_expected_v4[[1]]$support_guard, 0.999999)
  expect_equal(
    rho_options$prior_expected_v4[[1]]$log_normalizer,
    lbeta(0.5, 2) + log(pbeta(0.999999^2, 0.5, 2)),
    tolerance = 1e-14
  )
  expect_false("index" %in% names(rho_options$prior_expected_v4[[1]]))

  mixed_options <- drm_julia_prior_v4_options(list(q2, fixed, ridge), q2_resolved)
  expect_identical(mixed_options$prior_contract, "parameter_priors_v4")
  expect_equal(vapply(mixed_options$priors_v4, `[[`, character(1), "kind"),
    c("lkj_random_effect_correlation", "fixed_normal", "fixed_ridge"))
  expect_equal(vapply(mixed_options$prior_expected_v4, `[[`, integer(1), "spec_index"),
    c(1L, 2L, 3L))
  expect_equal(mixed_options$prior_expected_v4[[1]]$support_guard, 0.99999999)
  expect_equal(mixed_options$prior_expected_v4[[2]]$coef, "x")
  expect_equal(mixed_options$prior_expected_v4[[3]]$coef, "(Intercept)")
  expect_false(any(vapply(mixed_options$prior_expected_v4, function(x) "index" %in% names(x), logical(1))))
  mock_mixed <- mock_prior_v4_result(mixed_options$prior_expected_v4)
  mock_mixed$resolved_priors_v4[[2]]$matrix_column <- 2L
  mock_mixed$resolved_priors_v4[[3]]$matrix_column <- 1L
  expect_no_error(drm_julia_validate_prior_v4_result(
    mock_mixed, mixed_options$prior_expected_v4
  ))

  student <- drm_prior_student_t(dpar = "mu", coef = "x", mean = 0,
    scale = 1.2, df = 4)
  student_row <- q2_resolved[2, , drop = FALSE]
  student_row$coefficient <- "x"
  student_row$kind <- "student_t"
  student_row$reason <- "exact column"
  student_row$precision <- 1 / 1.2^2
  student_row$mean <- 0
  student_row$sd <- 1.2
  student_row$df <- 4
  student_resolved <- rbind(q2_resolved[1, , drop = FALSE], student_row)
  student_options <- drm_julia_prior_v4_options(list(q2, student), student_resolved)
  expect_equal(student_options$priors_v4[[2]]$kind, "fixed_student_t")
  expect_equal(student_options$prior_expected_v4[[2]][c("location", "scale", "df")],
    list(location = 0, scale = 1.2, df = 4))
  student_result <- mock_prior_v4_result(student_options$prior_expected_v4)
  student_result$resolved_priors_v4[[2]]$matrix_column <- 2L
  expect_no_error(drm_julia_validate_prior_v4_result(
    student_result, student_options$prior_expected_v4
  ))
  student_result$resolved_priors_v4[[2]]$scale <- 0.8
  expect_error(drm_julia_validate_prior_v4_result(
    student_result, student_options$prior_expected_v4
  ), "resolved prior records differ")
})

test_that("v4 correlation target and normalization mismatches fail closed", {
  rho <- drm_correlation_prior_lkj(dpar = "rho12", eta = 2)
  q2 <- drm_correlation_prior_lkj(
    dpar = "mu", group = "site", from_coef = "(Intercept)",
    to_coef = "x", eta = 2
  )
  sd <- drm_prior_sd_gamma(group = "site", shape = 2, rate = 3)
  rho_resolved <- data.frame(
    class = "correlation", dpar = "rho12", group = NA_character_,
    block = "bivariate_residual", coefficient = "(Intercept)",
    from_coef = NA_character_, to_coef = NA_character_,
    scale = "natural_correlation", kind = "lkj", eta = 2
  )
  q2_resolved <- data.frame(
    class = "correlation", dpar = "mu", group = "site",
    block = "cor(mu:(Intercept),mu:x | site)", coefficient = NA_character_,
    from_coef = "(Intercept)", to_coef = "x", scale = "natural_correlation",
    kind = "lkj", eta = 2
  )
  expect_error(drm_julia_prior_v4_options(list(rho, rho), rbind(rho_resolved, rho_resolved)),
    "exactly one")
  expect_error(drm_julia_prior_v4_options(list(rho, sd), rho_resolved),
    "SD.*correlation|correlation.*SD")
  expect_error(drm_julia_prior_v4_options(list(rho, drm_prior_normal("mu", "x", sd = 1)), rho_resolved),
    "rho12.*fixed|fixed.*rho12")

  options <- drm_julia_prior_v4_options(list(q2), q2_resolved)
  wrong_guard <- options$prior_expected_v4
  wrong_guard[[1]]$support_guard <- 0.999999
  expect_error(drm_julia_validate_prior_v4_result(
    mock_prior_v4_result(wrong_guard), options$prior_expected_v4
  ), "resolved prior records differ")
  wrong_norm <- options$prior_expected_v4
  wrong_norm[[1]]$log_normalizer <- wrong_norm[[1]]$log_normalizer + 0.1
  expect_error(drm_julia_validate_prior_v4_result(
    mock_prior_v4_result(wrong_norm), options$prior_expected_v4
  ), "resolved prior records differ")
})

test_that("v4 response validation accepts Julia-derived packed indices", {
  q2 <- drm_correlation_prior_lkj(
    dpar = "mu", group = "site", from_coef = "(Intercept)",
    to_coef = "x", eta = 2
  )
  resolved <- data.frame(
    class = "correlation", dpar = "mu", group = "site",
    block = "cor(mu:(Intercept),mu:x | site)", coefficient = NA_character_,
    from_coef = "(Intercept)", to_coef = "x", scale = "natural_correlation",
    kind = "lkj", eta = 2
  )
  options <- drm_julia_prior_v4_options(list(q2), resolved)
  result <- mock_prior_v4_result(options$prior_expected_v4)
  result$resolved_priors_v4[[1]]$index <- 4L
  expect_no_error(drm_julia_validate_prior_v4_result(result, options$prior_expected_v4))
  result$resolved_priors_v4[[1]]$support_guard <- 1
  expect_error(drm_julia_validate_prior_v4_result(result, options$prior_expected_v4),
    "resolved prior records differ")
  result <- mock_prior_v4_result(options$prior_expected_v4)
  result$resolved_priors_v4[[1]]$unreviewed_field <- TRUE
  expect_error(drm_julia_validate_prior_v4_result(result, options$prior_expected_v4),
    "invalid resolved prior record")
})

test_that("live R-to-Julia v4 fixtures remain explicitly opt-in", {
  skip_if_not(identical(Sys.getenv("DRMTMB_JULIA_BRIDGE_V4"), "1"),
    "Set DRMTMB_JULIA_BRIDGE_V4=1 after the embedded Julia process is clear.")
  skip_if_not_installed("JuliaCall")
  expected_sha <- Sys.getenv("DRMTMB_JULIA_V4_SOURCE_SHA")
  skip_if_not(nzchar(expected_sha),
    "Set DRMTMB_JULIA_V4_SOURCE_SHA to the reviewed DRModels.jl commit before live validation.")
  expect_match(expected_sha, "^[0-9a-f]{40}$")
  active_pid <- system2("ps", c("-p", "21585", "-o", "pid="), stdout = TRUE,
    stderr = FALSE)
  skip_if(nzchar(trimws(paste(active_pid, collapse = ""))),
    "A separately owned embedded Julia process (PID 21585) is still active.")
  julia_path <- drm_julia_path()
  actual_sha <- system2("git", c("-C", shQuote(julia_path), "rev-parse", "HEAD"),
    stdout = TRUE, stderr = FALSE)
  expect_identical(trimws(actual_sha[[1L]]), expected_sha)

  # Live cases deliberately cover the residual target and the mixed q2
  # correlation/fixed-coefficient route. No local live run is permitted while
  # another embedded Julia process is active.
  set.seed(7135)
  rho_data <- data.frame(
    y1 = rnorm(48), y2 = rnorm(48), x = rep(seq(-1, 1, length.out = 12), 4)
  )
  rho_data$y1 <- 0.2 + 0.4 * rho_data$x + rho_data$y1
  rho_data$y2 <- -0.1 - 0.2 * rho_data$x + rho_data$y2
  rho_table <- data.frame(prior = "lkj(2)", class = "correlation",
    dpar = "rho12", coef = "(Intercept)", scale = "natural_correlation")
  rho_fit <- suppressWarnings(drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
    data = rho_data, priors = rho_table, engine = "julia"
  ))
  expect_equal(nrow(rho_fit$resolved_correlation_prior), 1L)
  expect_identical(rho_fit$resolved_correlation_prior$dpar, "rho12")
  expect_true(is.finite(rho_fit$correlation_prior_penalty))
  expect_equal(rho_fit$bridge_payload$options$prior_expected_v4[[1L]]$support_guard,
    0.999999)

  q2_data <- data.frame(
    x = rep(c(-1, 0, 1), 16),
    g = factor(rep(rep(letters[1:8], each = 3), 2))
  )
  q2_data$y <- 0.3 + 0.5 * q2_data$x + stats::rnorm(nrow(q2_data)) +
    stats::rnorm(8, sd = 0.4)[as.integer(q2_data$g)]
  q2_table <- data.frame(
    prior = c("lkj(2)", "normal(0,2)"),
    class = c("correlation", "fixef"),
    dpar = c("mu", "mu"), coef = c("", "x"),
    group = c("g", ""), from_coef = c("(Intercept)", ""),
    to_coef = c("x", ""), scale = c("natural_correlation", "link")
  )
  q2_fit <- suppressWarnings(drmTMB(
    bf(mu = y ~ x + (1 + x | g), sigma = ~1),
    data = q2_data, priors = q2_table, engine = "julia"
  ))
  expect_equal(nrow(q2_fit$resolved_correlation_prior), 1L)
  expect_identical(q2_fit$resolved_correlation_prior$group, "g")
  expect_true(is.finite(q2_fit$fixed_prior_penalty))
  expect_true(is.finite(q2_fit$correlation_prior_penalty))
  expect_equal(q2_fit$bridge_payload$options$prior_expected_v4[[1L]]$support_guard,
    0.99999999)
})

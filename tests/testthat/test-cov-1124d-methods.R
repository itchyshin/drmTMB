# Print and summary branches, plus the summary-table formatters.
# One small Gaussian fit supplies the object; family banners are labels only.

cov_1124d_gaussian_fit <- function() {
  set.seed(1124)
  dat <- data.frame(y = stats::rnorm(12), x = stats::rnorm(12))
  drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = drm_control(se = FALSE)
  )
}

print_text <- function(object) {
  paste(capture.output(print(object), type = "message"), collapse = "\n")
}

test_that("print.drmTMB names the distribution and the withheld standard errors", {
  fit <- cov_1124d_gaussian_fit()
  text <- print_text(fit)
  expect_match(text, "Gaussian location-scale", fixed = TRUE)
  expect_match(text, "standard errors: unavailable", fixed = TRUE)
  expect_match(text, "observations: 12", fixed = TRUE)

  banners <- c(
    lognormal = "Lognormal location-scale",
    gamma = "Gamma mean-CV",
    beta = "Beta mean-scale",
    zero_one_beta = "zero-one beta mean-scale-boundary",
    beta_binomial = "Beta-binomial mean-overdispersion",
    cumulative_logit = "cumulative-logit ordinal",
    poisson = "Poisson mean",
    zi_poisson = "zero-inflated Poisson mean",
    nbinom2 = "negative binomial 2 mean-dispersion",
    truncated_nbinom2 = "zero-truncated negative binomial 2 mean-dispersion",
    hurdle_nbinom2 = "hurdle negative binomial 2 mean-dispersion",
    zi_nbinom2 = "zero-inflated negative binomial 2 mean-dispersion"
  )
  for (model_type in names(banners)) {
    labelled <- fit
    labelled$model$model_type <- model_type
    expect_match(print_text(labelled), banners[[model_type]], fixed = TRUE)
  }

  binomial_fit <- fit
  binomial_fit$model$model_type <- "binomial"
  binomial_fit$model$link <- "probit"
  expect_match(print_text(binomial_fit), "probit link", fixed = TRUE)

  prior_fit <- fit
  prior_fit$resolved_priors <- data.frame(precision = 1)
  expect_match(print_text(prior_fit), "penalized/MAP", fixed = TRUE)

  penalized <- fit
  penalized$penalty <- list(kind = "pc")
  expect_match(print_text(penalized), "phylogenetic PC-prior", fixed = TRUE)

  random_fit <- fit
  random_fit$random_effects$mu$values <- 0
  random_fit$model$random$mu$labels <- "(1 | id)"
  expect_match(print_text(random_fit), "mu random-effect terms:", fixed = TRUE)

  unconverged <- fit
  unconverged$opt$convergence <- 1L
  unconverged$opt$message <- "false convergence"
  expect_match(
    print_text(unconverged),
    "not converged",
    fixed = TRUE
  )
})

test_that("structured_effects refuses a non-fit and an empty marker list", {
  expect_error(
    structured_effects(data.frame(y = 1)),
    "implemented for"
  )
  fit <- cov_1124d_gaussian_fit()
  fit$model$structured <- list()
  empty <- structured_effects(fit)
  expect_s3_class(empty, "data.frame")
  expect_identical(nrow(empty), 0L)
})

test_that("summary tables keep finite intervals and drop empty bounds", {
  parameters <- data.frame(
    component = "sigma",
    dpar = "sigma",
    term = "(Intercept)",
    estimate = 0.5,
    std_error = NA_real_,
    minimum = 0,
    maximum = 0,
    scale = "response",
    conf.low = 0.2,
    conf.high = 0.8,
    conf.status = "wald",
    profile.message = "not-ok",
    stringsAsFactors = FALSE
  )
  formatted <- drmTMB:::drm_summary_print_parameters(parameters)
  expect_false("std_error" %in% names(formatted))
  expect_false("minimum" %in% names(formatted))
  expect_equal(formatted$conf.low, 0.2)
  expect_equal(formatted$conf.high, 0.8)
  expect_identical(formatted$conf.status, "wald")
  expect_identical(formatted$profile.message, "not-ok")
  expect_identical(formatted$estimate, 0.5)

  covariance <- data.frame(
    level = "group",
    group = "id",
    block = NA_character_,
    from_dpar = "mu1",
    to_dpar = "mu2",
    class = "correlation",
    correlation = 0.3,
    from_sd = 1,
    to_sd = 2,
    covariance = 0.6,
    correlation_conf.low = 0.1,
    correlation_conf.high = 0.4,
    covariance_conf.status = "derived_interval_unavailable",
    stringsAsFactors = FALSE
  )
  printed_covariance <- drmTMB:::drm_summary_print_covariance(covariance)
  expect_equal(printed_covariance$correlation, 0.3)
  expect_equal(printed_covariance$covariance, 0.6)
  expect_equal(printed_covariance$correlation_conf.low, 0.1)
  expect_identical(
    printed_covariance$covariance_conf.status,
    "derived_interval_unavailable"
  )

  derived <- data.frame(
    quantity = "residual_variance",
    level = NA_character_,
    group = NA_character_,
    term = "sigma",
    estimate = 0.25,
    random_effect_variance = 0,
    residual_variance = 0.25,
    conf.status = "derived_interval_unavailable",
    stringsAsFactors = FALSE
  )
  printed_derived <- drmTMB:::drm_summary_print_derived(derived)
  expect_equal(printed_derived$estimate, 0.25)
  expect_identical(
    printed_derived$conf.status,
    "derived_interval_unavailable"
  )
})

test_that("print.summary.drmTMB reports intervals, OU point estimates, and non-convergence", {
  summary_object <- function(convergence = 0L, message = NULL) {
    coefficients <- data.frame(
      estimate = 0.2,
      std_error.status = "temporal_wald_unqualified",
      stringsAsFactors = FALSE
    )
    structure(
      list(
        estimator = "ML",
        conf.int = TRUE,
        conf.method = "wald",
        conf.level = 0.95,
        uncertainty = list(status = "failed", message = "TMB::sdreport() failed."),
        coefficients = coefficients,
        parameters = data.frame(
          component = "sigma",
          dpar = "sigma",
          term = "(Intercept)",
          estimate = 0.5,
          std_error = NA_real_,
          minimum = NA_real_,
          maximum = NA_real_,
          scale = "response"
        ),
        temporal_parameters_point_only = TRUE,
        covariance = data.frame(),
        derived = structure(
          data.frame(
            quantity = character(),
            level = character(),
            group = character(),
            term = character(),
            estimate = numeric(),
            random_effect_variance = numeric(),
            residual_variance = numeric()
          ),
          residual_variance.message = "sigma is not a single residual SD"
        ),
        ordinal = list(cutpoints = data.frame(cut = 0)),
        logLik = -12.5,
        convergence_status = "degenerate",
        convergence = convergence,
        convergence_message = message
      ),
      class = "summary.drmTMB"
    )
  }

  quiet <- print_text(summary_object())
  expect_match(quiet, "confidence intervals: wald", fixed = TRUE)
  expect_match(quiet, "OU coefficient table is point estimates only", fixed = TRUE)
  expect_match(quiet, "point estimates only", fixed = TRUE)
  expect_match(quiet, "Ordinal cutpoints", fixed = TRUE)
  expect_match(quiet, "logLik:", fixed = TRUE)
  expect_match(quiet, "convergence: 0", fixed = TRUE)

  expect_warning(
    unconverged <- print_text(summary_object(1L, "false convergence")),
    class = "drmTMB_convergence_warning"
  )
  expect_match(unconverged, "not converged", fixed = TRUE)
})

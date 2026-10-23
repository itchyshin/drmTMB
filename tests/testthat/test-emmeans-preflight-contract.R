# Characterisation tests for the helpers in R/emmeans-preflight.R that decide
# whether emmeans may run on a drmTMB fit. test-emmeans-preflight.R and
# test-emmeans-recover-data.R cover the happy path and the common refusals; this
# file pins the helpers by name and reaches every remaining cli_abort() branch.
# Real fits are used where cheap; fabricated drmTMB-classed lists stand in where
# the branch cannot be reached from a fit.

emmeans_contract_control <- function() {
  drm_control(
    keep_model_frame = TRUE,
    optimizer = list(eval.max = 120L, iter.max = 120L)
  )
}

emmeans_contract_data <- function(n = 120L) {
  d <- data.frame(
    x = stats::rnorm(n),
    f = factor(sample(c("a", "b", "c"), n, replace = TRUE)),
    size = exp(stats::rnorm(n, sd = 0.4)),
    id = factor(rep(seq_len(12L), length.out = n))
  )
  # Group-level covariate for sd(id) ~ gx: constant within id.
  d$gx <- as.numeric(d$id) / 12
  d$y <- 1 + 0.5 * d$x + 0.3 * (d$f == "b") + stats::rnorm(n, sd = 0.3)
  d
}

# A minimal drmTMB-classed object: only the slots the preflight reads.
emmeans_contract_fake <- function(
  model_type = "gaussian",
  response = "y",
  coefficients = list(mu = c("(Intercept)" = 0)),
  model_frame = NULL,
  terms = stats::terms(y ~ x),
  data = NULL
) {
  structure(
    list(
      model = list(
        model_type = model_type,
        response_names = list(mu = response),
        terms = list(mu = terms),
        model_frame = model_frame
      ),
      coefficients = coefficients,
      random_effects = list(),
      data = data
    ),
    class = "drmTMB"
  )
}

test_that("drm_emmeans_has_transformed_response classifies response spellings", {
  has_transformed <- drmTMB:::drm_emmeans_has_transformed_response
  fake <- function(response) {
    emmeans_contract_fake(response = response)
  }

  expect_false(has_transformed(fake("y"), "mu"))
  expect_true(has_transformed(fake("log(y)"), "mu"))
  expect_true(has_transformed(fake("I(y/2)"), "mu"))
  # cbind() binomial-style responses are not transformations.
  expect_false(has_transformed(fake("cbind(succ, fail)"), "mu"))
  # Missing, non-character, vector, NA and unparseable responses are not
  # flagged (the other guards decide those fits).
  expect_false(has_transformed(fake(NULL), "mu"))
  expect_false(has_transformed(fake(1), "mu"))
  expect_false(has_transformed(fake(c("y", "z")), "mu"))
  expect_false(has_transformed(fake(NA_character_), "mu"))
  expect_false(has_transformed(fake("log(y"), "mu"))
  # An unknown dpar has no response name.
  expect_false(has_transformed(fake("log(y)"), "sigma"))
})

test_that("drm_emmeans_has_transformed_response reads real fits", {
  testthat::skip_if_not_installed("emmeans")
  testthat::skip_on_cran()
  set.seed(20261001)
  dat <- emmeans_contract_data()
  plain <- drmTMB(
    bf(y ~ x + f, sigma ~ x),
    data = dat,
    control = emmeans_contract_control()
  )
  logged <- drmTMB(
    bf(log(size) ~ x + f, sigma ~ x),
    data = dat,
    control = emmeans_contract_control()
  )
  halved <- drmTMB(
    bf(I(y / 2) ~ x + f, sigma ~ x),
    data = dat,
    control = emmeans_contract_control()
  )

  expect_false(drmTMB:::drm_emmeans_has_transformed_response(plain, "mu"))
  expect_true(drmTMB:::drm_emmeans_has_transformed_response(logged, "mu"))
  expect_true(drmTMB:::drm_emmeans_has_transformed_response(halved, "mu"))
})

test_that("drm_has_random_scale_models is TRUE only with a scale model", {
  testthat::skip_if_not_installed("emmeans")
  testthat::skip_on_cran()
  set.seed(20261002)
  dat <- emmeans_contract_data()
  fixed <- drmTMB(
    bf(y ~ x + f, sigma ~ x),
    data = dat,
    control = emmeans_contract_control()
  )
  ordinary <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1),
    data = dat,
    control = emmeans_contract_control()
  )
  scaled <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ gx),
    data = dat,
    control = emmeans_contract_control()
  )

  expect_false(drmTMB:::drm_has_random_scale_models(fixed))
  # An ordinary random intercept has no scale model.
  expect_false(drmTMB:::drm_has_random_scale_models(ordinary))
  expect_true(drmTMB:::drm_has_random_scale_models(scaled))
  expect_true(
    "random-effect scale models" %in% drmTMB:::drm_emmeans_blocked_features(scaled)
  )
})

test_that("drm_has_random_scale_models handles both slots on fabricated fits", {
  has_scale <- drmTMB:::drm_has_random_scale_models
  fake <- function(mu = NULL, phylo = NULL) {
    out <- emmeans_contract_fake()
    out$model$random_scale <- list(mu = mu, phylo = phylo)
    out
  }

  expect_false(has_scale(emmeans_contract_fake()))
  expect_false(has_scale(fake(list(n_models = 0L), list(n_models = 0L))))
  expect_true(has_scale(fake(list(n_models = 1L), list(n_models = 0L))))
  expect_true(has_scale(fake(list(n_models = 0L), list(n_models = 2L))))
  expect_true(has_scale(fake(NULL, list(n_models = 1L))))
})

test_that("drm_validate_emmeans_mu_target accepts mu on a supported fit", {
  testthat::skip_if_not_installed("emmeans")
  testthat::skip_on_cran()
  set.seed(20261003)
  dat <- emmeans_contract_data()
  fit <- drmTMB(
    bf(y ~ x + f, sigma ~ x),
    data = dat,
    control = emmeans_contract_control()
  )

  expect_invisible(drmTMB:::drm_validate_emmeans_mu_target(fit, "mu"))
  expect_true(drmTMB:::drm_validate_emmeans_mu_target(fit, "mu"))
  expect_true(
    drmTMB:::drm_validate_emmeans_mu_target(emmeans_contract_fake(), "mu")
  )

  sigma_error <- expect_error(
    drmTMB:::drm_validate_emmeans_mu_target(fit, "sigma"),
    "limited to"
  )
  expect_match(conditionMessage(sigma_error), "dpar = \"mu\"", fixed = TRUE)
  expect_match(conditionMessage(sigma_error), "prediction_grid", fixed = TRUE)
  expect_match(conditionMessage(sigma_error), "predict_parameters", fixed = TRUE)
  expect_error(
    drmTMB:::drm_validate_emmeans_mu_target(fit, "rho12"),
    "limited to"
  )
  expect_error(
    drmTMB:::drm_validate_emmeans_mu_target(fit, "Mu"),
    "limited to"
  )
})

test_that("drm_validate_emmeans_mu_target rejects malformed dpar", {
  fake <- emmeans_contract_fake()
  validate <- drmTMB:::drm_validate_emmeans_mu_target

  expect_error(validate(fake, c("mu", "sigma")), "one distributional-parameter name")
  expect_error(validate(fake, NA_character_), "one distributional-parameter name")
  expect_error(validate(fake, character()), "one distributional-parameter name")
  expect_error(validate(fake, 1L), "one distributional-parameter name")
  expect_error(validate(fake, NULL), "one distributional-parameter name")
})

test_that("drm_validate_emmeans_mu_target refuses unsupported model types", {
  validate <- drmTMB:::drm_validate_emmeans_mu_target

  for (type in c("lognormal", "truncated_nbinom2", "zi_poisson", "biv_gaussian")) {
    err <- expect_error(
      validate(emmeans_contract_fake(model_type = type), "mu"),
      "not implemented"
    )
    expect_match(conditionMessage(err), type, fixed = TRUE)
    expect_match(conditionMessage(err), "Supported model types", fixed = TRUE)
  }
  for (type in c("gaussian", "student", "gamma", "beta", "beta_binomial", "poisson", "nbinom2")) {
    expect_true(validate(emmeans_contract_fake(model_type = type), "mu"))
  }
})

test_that("drm_validate_emmeans_mu_target refuses transformed responses", {
  err <- expect_error(
    drmTMB:::drm_emmeans_mu_basis(
      emmeans_contract_fake(response = "log(y)"),
      newdata = data.frame(x = 0)
    ),
    "transformed responses"
  )
  expect_match(conditionMessage(err), "log(y)", fixed = TRUE)
})

test_that("drm_validate_emmeans_mu_target refuses a fit without mu coefficients", {
  expect_error(
    drmTMB:::drm_validate_emmeans_mu_target(
      emmeans_contract_fake(coefficients = list(sigma = c("(Intercept)" = 0))),
      "mu"
    ),
    "does not contain a fitted"
  )
  expect_error(
    drmTMB:::drm_validate_emmeans_mu_target(
      emmeans_contract_fake(coefficients = list()),
      "mu"
    ),
    "does not contain a fitted"
  )
})

test_that("drm_validate_emmeans_mu_target names each blocked feature", {
  validate <- drmTMB:::drm_validate_emmeans_mu_target
  blocked_message <- function(object) {
    conditionMessage(expect_error(validate(object, "mu"), "fixed-effect models"))
  }

  mu_re <- emmeans_contract_fake()
  mu_re$random_effects$mu <- list(values = list(a = 1))
  expect_match(blocked_message(mu_re), "mu random effects", fixed = TRUE)

  sigma_re <- emmeans_contract_fake()
  sigma_re$random_effects$sigma <- list(values = list(a = 1))
  expect_match(blocked_message(sigma_re), "sigma random effects", fixed = TRUE)

  structured <- emmeans_contract_fake()
  structured$model$structured <- list(phylo_mu = list(has = TRUE))
  expect_match(blocked_message(structured), "structured mu effects", fixed = TRUE)

  cov_block <- emmeans_contract_fake()
  cov_block$random_effects$covariance_blocks <- list(
    contribution = matrix(0, nrow = 2L, ncol = 1L)
  )
  expect_match(
    blocked_message(cov_block),
    "covariance-block random effects",
    fixed = TRUE
  )

  scale <- emmeans_contract_fake()
  scale$model$random_scale <- list(mu = list(n_models = 1L))
  expect_match(blocked_message(scale), "random-effect scale models", fixed = TRUE)

  both <- mu_re
  both$model$random_scale <- list(phylo = list(n_models = 1L))
  msg <- blocked_message(both)
  expect_match(msg, "mu random effects", fixed = TRUE)
  expect_match(msg, "random-effect scale models", fixed = TRUE)
})

test_that("drm_emmeans_model_frame refuses missing retained frames", {
  model_frame <- drmTMB:::drm_emmeans_model_frame

  no_list <- emmeans_contract_fake(model_frame = NULL)
  err <- expect_error(model_frame(no_list, "mu"), "retained model frames")
  expect_match(conditionMessage(err), "keep_model_frame = TRUE", fixed = TRUE)

  no_dpar <- emmeans_contract_fake(model_frame = list(sigma = data.frame(x = 1)))
  err <- expect_error(model_frame(no_dpar, "mu"), "retained model frame for")
  expect_match(conditionMessage(err), "dpar = \"mu\"", fixed = TRUE)
  expect_match(conditionMessage(err), "keep_model_frame = TRUE", fixed = TRUE)

  not_df <- emmeans_contract_fake(model_frame = list(mu = matrix(1)))
  expect_error(model_frame(not_df, "mu"), "retained model frame for")

  ok <- emmeans_contract_fake(model_frame = list(mu = data.frame(y = 1, x = 2)))
  expect_identical(model_frame(ok, "mu"), data.frame(y = 1, x = 2))
})

test_that("drm_emmeans_model_frame returns the retained frame of a real fit", {
  testthat::skip_if_not_installed("emmeans")
  testthat::skip_on_cran()
  set.seed(20261004)
  dat <- emmeans_contract_data()
  fit <- drmTMB(
    bf(y ~ x + f, sigma ~ x),
    data = dat,
    control = emmeans_contract_control()
  )
  expect_identical(
    drmTMB:::drm_emmeans_model_frame(fit, "mu"),
    fit$model$model_frame$mu
  )

  lean <- drmTMB(
    bf(y ~ x + f, sigma ~ x),
    data = dat,
    control = drm_control(
      keep_model_frame = FALSE,
      optimizer = list(eval.max = 120L, iter.max = 120L)
    )
  )
  expect_error(
    drmTMB:::drm_emmeans_model_frame(lean, "mu"),
    "keep_model_frame = TRUE"
  )
})

test_that("drm_emmeans_complete_model_frame drops incomplete rows, keeps levels", {
  testthat::skip_if_not_installed("emmeans")
  testthat::skip_on_cran()
  set.seed(20261005)
  dat <- emmeans_contract_data()
  dat$x[c(3L, 40L)] <- NA_real_
  dat$y[7L] <- NA_real_
  dat$size[c(9L, 50L)] <- NA_real_
  fit <- drmTMB(
    bf(y ~ x + f + log(size), sigma ~ x),
    data = dat,
    control = emmeans_contract_control()
  )
  retained <- fit$model$model_frame$mu
  terms <- fit$model$terms$mu

  completed <- drmTMB:::drm_emmeans_complete_model_frame(fit, retained, terms)

  expect_equal(nrow(completed), nobs(fit))
  expect_lt(nrow(completed), nrow(dat))
  expect_identical(row.names(completed), row.names(retained))
  expect_false(any(c(3L, 40L, 7L, 9L, 50L) %in% as.integer(row.names(completed))))
  expect_true(all(c("x", "f", "size") %in% names(completed)))
  expect_false(anyNA(completed[c("x", "f", "size")]))
  expect_identical(levels(completed$f), levels(dat$f))
  expect_identical(levels(completed$f), levels(retained$f))
  expect_equal(
    completed$size,
    dat$size[match(row.names(completed), row.names(dat))]
  )
  expect_equal(
    drmTMB:::drm_emmeans_recover_data(fit)$xlevels$f,
    levels(dat$f)
  )
})

test_that("drm_emmeans_complete_model_frame returns a complete frame unchanged", {
  frame <- data.frame(y = 1:3, x = c(0.1, 0.2, 0.3))
  fake <- emmeans_contract_fake(model_frame = list(mu = frame))
  expect_identical(
    drmTMB:::drm_emmeans_complete_model_frame(fake, frame, stats::terms(y ~ x)),
    frame
  )
})

test_that("drm_emmeans_complete_model_frame refuses unrecoverable variables", {
  complete <- drmTMB:::drm_emmeans_complete_model_frame
  terms <- stats::terms(y ~ x + log(z))
  frame <- data.frame(y = 1:3, x = c(0.1, 0.2, 0.3), row.names = c("1", "2", "3"))

  # No stored data.
  err <- expect_error(
    complete(emmeans_contract_fake(data = NULL), frame, terms),
    "could not recover all model variables"
  )
  expect_match(conditionMessage(err), "z", fixed = TRUE)

  # Stored data lacks the variable.
  expect_error(
    complete(
      emmeans_contract_fake(data = data.frame(y = 1:3, x = 1:3)),
      frame,
      terms
    ),
    "could not recover all model variables"
  )

  # Stored data is not a data frame.
  expect_error(
    complete(emmeans_contract_fake(data = list(z = 1:3)), frame, terms),
    "could not recover all model variables"
  )
})

test_that("drm_emmeans_complete_model_frame restores or refuses by row alignment", {
  complete <- drmTMB:::drm_emmeans_complete_model_frame
  terms <- stats::terms(y ~ x + log(z))
  source <- data.frame(
    y = 1:4,
    x = c(0.1, 0.2, 0.3, 0.4),
    z = c(10, 20, 30, 40),
    row.names = c("a", "b", "c", "d")
  )

  # Row names match: z is restored by name, in frame order.
  by_name <- data.frame(y = c(4L, 2L), x = c(0.4, 0.2), row.names = c("d", "b"))
  out <- complete(emmeans_contract_fake(data = source), by_name, terms)
  expect_equal(out$z, c(40, 20))

  # Row names do not match but the row counts agree: positional fallback.
  positional <- data.frame(y = 1:4, x = c(0.1, 0.2, 0.3, 0.4))
  out <- complete(emmeans_contract_fake(data = source), positional, terms)
  expect_equal(out$z, c(10, 20, 30, 40))

  # Row names do not match and the counts differ: refuse.
  misaligned <- data.frame(y = 1:2, x = c(0.1, 0.2), row.names = c("p", "q"))
  err <- expect_error(
    complete(emmeans_contract_fake(data = source), misaligned, terms),
    "could not align retained model rows"
  )
  expect_match(conditionMessage(err), "Refit with", fixed = TRUE)
})

test_that("drm_emmeans_recover_data refuses a fit without retained terms", {
  fake <- emmeans_contract_fake(
    model_frame = list(mu = data.frame(y = 1:3, x = c(0.1, 0.2, 0.3)))
  )
  fake$model$terms <- list(mu = NULL)
  err <- expect_error(
    drmTMB:::drm_emmeans_recover_data(fake),
    "does not retain terms"
  )
  expect_match(conditionMessage(err), "dpar = \"mu\"", fixed = TRUE)
})

test_that("drm_emmeans_misc returns the documented list", {
  misc <- drmTMB:::drm_emmeans_misc

  # Identity link: only the dpar tag, no back-transformation.
  expect_identical(misc("identity", "mu"), list(dpar = "mu"))

  # Any other link adds the emmeans response-scale fields.
  for (link in c("log", "logit", "probit", "cloglog")) {
    out <- misc(link, "mu")
    expect_named(out, c("dpar", "tran", "inv.lbl", "sigma"))
    expect_identical(out$dpar, "mu")
    expect_identical(out$tran, link)
    expect_identical(out$inv.lbl, "response")
    expect_true(is.na(out$sigma))
  }
  expect_identical(misc("identity", "sigma")$dpar, "sigma")
})

test_that("emm_basis.drmTMB feeds drm_emmeans_misc the fitted mu link", {
  testthat::skip_if_not_installed("emmeans")
  testthat::skip_on_cran()
  set.seed(20261006)
  dat <- emmeans_contract_data()
  dat$count <- stats::rpois(nrow(dat), lambda = exp(0.3 + 0.4 * dat$x))
  gauss <- drmTMB(
    bf(y ~ x + f, sigma ~ x),
    data = dat,
    control = emmeans_contract_control()
  )
  pois <- drmTMB(
    bf(count ~ x + f),
    family = stats::poisson(link = "log"),
    data = dat,
    control = emmeans_contract_control()
  )
  grid <- data.frame(x = 0, f = factor("a", levels = levels(dat$f)))

  gauss_basis <- drmTMB:::emm_basis.drmTMB(gauss, NULL, NULL, grid)
  expect_identical(gauss_basis$misc, list(dpar = "mu"))
  pois_basis <- drmTMB:::emm_basis.drmTMB(pois, NULL, NULL, grid)
  expect_identical(pois_basis$misc$tran, "log")
  expect_identical(pois_basis$misc$inv.lbl, "response")
  expect_error(
    drmTMB:::emm_basis.drmTMB(gauss, NULL, NULL, grid, dpar = "sigma"),
    "limited to"
  )
})

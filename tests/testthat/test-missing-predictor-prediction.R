mi_prediction_object <- function(
  predictor = c("gaussian", "bernoulli"),
  sparse = FALSE
) {
  predictor <- match.arg(predictor)
  X <- matrix(
    c(1, -0.5, 0.1,
      1,  0.0, 0.2,
      1,  0.5, 0.3,
      1,  1.0, 0.4),
    ncol = 3L,
    byrow = TRUE,
    dimnames = list(NULL, c("(Intercept)", "z", "mi(x)"))
  )
  if (isTRUE(sparse)) {
    X <- Matrix::Matrix(X, sparse = TRUE)
  }
  observed <- c(TRUE, FALSE, TRUE, FALSE)
  values <- c(0.1, 0.8, 0.3, 0.6)
  list(
    model = list(
      model_type = "gaussian",
      X = list(mu = X),
      terms = list(mu = stats::terms(~z + mi(x))),
      model_frame = list(mu = data.frame(z = c(-.5, 0, .5, 1), `mi(x)` = values))
    ),
    data = data.frame(
      x = if (identical(predictor, "bernoulli")) {
        factor(c("no", NA, "yes", NA), levels = c("no", "yes"))
      } else {
        c(.1, NA, .3, NA)
      },
      z = c(-.5, 0, .5, 1)
    ),
    missing_data = list(
      original_row = c(11L, 12L, 13L, 14L),
      model_row = seq_len(4L),
      predictors = list(x = list(
        variable = "x",
        family = predictor,
        levels = if (identical(predictor, "bernoulli")) c("no", "yes") else character(),
        observed = observed,
        value = values,
        model_row = c(2L, 4L),
        original_row = c(12L, 14L),
        summary = if (identical(predictor, "bernoulli")) {
          "conditional_probability"
        } else {
          "conditional_mode"
        }
      ))
    )
  )
}

test_that("Gaussian training mu design uses finalized missing-predictor means", {
  object <- mi_prediction_object("gaussian")
  X <- drmTMB:::drm_prediction_matrix(object, NULL, "mu")
  expect_equal(X[, "mi(x)"], c(.1, .8, .3, .6))
  expect_equal(X[c(1L, 3L), "mi(x)"], c(.1, .3))

  sparse_object <- mi_prediction_object("gaussian", sparse = TRUE)
  sparse_X <- drmTMB:::drm_prediction_matrix(sparse_object, NULL, "mu")
  expect_s4_class(sparse_X, "sparseMatrix")
  expect_equal(as.numeric(sparse_X[, "mi(x)"]), c(.1, .8, .3, .6))
})

test_that("Bernoulli mi newdata maps fitted labels without changing numeric coding", {
  object <- mi_prediction_object("bernoulli")
  factor_data <- data.frame(
    x = factor(c("yes", "no"), levels = c("yes", "no")),
    z = c(-.25, .75)
  )
  character_data <- transform(factor_data, x = as.character(x))
  numeric_data <- transform(factor_data, x = c(1, 0))

  factor_X <- drmTMB:::drm_prediction_matrix(
    object, drmTMB:::drm_prepare_prediction_newdata(object, factor_data, "mu"), "mu"
  )
  character_X <- drmTMB:::drm_prediction_matrix(
    object, drmTMB:::drm_prepare_prediction_newdata(object, character_data, "mu"), "mu"
  )
  numeric_X <- drmTMB:::drm_prediction_matrix(
    object, drmTMB:::drm_prepare_prediction_newdata(object, numeric_data, "mu"), "mu"
  )
  expect_identical(colnames(factor_X), c("(Intercept)", "z", "mi(x)"))
  expect_equal(factor_X, numeric_X)
  expect_equal(character_X, numeric_X)
  expect_equal(unname(factor_X[, "mi(x)"]), c(1, 0))

  expect_error(
    drmTMB:::drm_prepare_prediction_newdata(
      object, data.frame(x = c("no", "other"), z = c(0, 1)), "mu"
    ),
    "unknown binary predictor level"
  )
  expect_error(
    drmTMB:::drm_prepare_prediction_newdata(
      object, data.frame(x = c(0, Inf), z = c(0, 1)), "mu"
    ),
    "must be finite"
  )
})

test_that("missing-predictor prediction refuses inconsistent stored metadata", {
  object <- mi_prediction_object("gaussian")
  object$missing_data$predictors$x$model_row <- c(1L, 4L)
  expect_error(
    drmTMB:::drm_prediction_matrix(object, NULL, "mu"),
    "model-row metadata"
  )
})

mi_state_prediction_object <- function() {
  levels <- c("a", "b", "c")
  z <- c(-.5, 0, .5, 1)
  state_X <- do.call(rbind, lapply(seq_along(z), function(row) {
    cbind(
      "(Intercept)" = rep(1, length(levels)),
      z = rep(z[[row]], length(levels)),
      "mi(x)b" = as.numeric(levels == "b"),
      "mi(x)c" = as.numeric(levels == "c")
    )
  }))
  X <- state_X[c(1L, 6L, 8L, 10L), , drop = FALSE]
  probability <- matrix(
    c(.2, .3, .5,
      .6, .2, .2),
    nrow = 2L,
    byrow = TRUE,
    dimnames = list(NULL, levels)
  )
  list(
    model = list(
      model_type = "gaussian",
      X = list(mu = X, sigma = cbind("(Intercept)" = 1, z = z)),
      terms = list(mu = stats::terms(~z + mi(x)), sigma = stats::terms(~z)),
      model_frame = list(mu = data.frame(z = z, `mi(x)` = factor(c("a", "c", "b", "a"), levels = levels)), sigma = data.frame(z = z)),
      missing_predictor = list(
        enabled = TRUE,
        variable = "x",
        family = "categorical",
        n_state = 3L,
        levels = levels,
        X_mu_state = state_X
      ),
      missing_predictor2 = list(enabled = FALSE)
    ),
    missing_data = list(
      original_row = c(21L, 22L, 23L, 24L),
      model_row = seq_len(4L),
      predictors = list(x = list(
        variable = "x",
        family = "categorical",
        levels = levels,
        n_state = 3L,
        observed = c(TRUE, FALSE, TRUE, FALSE),
        model_row = c(2L, 4L),
        original_row = c(22L, 24L),
        conditional_probabilities = probability,
        summary = "conditional_modal_category"
      ))
    )
  )
}

test_that("finite-state missing predictors weight observation-major designs", {
  object <- mi_state_prediction_object()
  before <- unserialize(serialize(object, NULL))
  X <- drmTMB:::drm_prediction_matrix(object, NULL, "mu")

  expect_equal(unname(X[1L, ]), unname(before$model$X$mu[1L, ]))
  expect_equal(unname(X[3L, ]), unname(before$model$X$mu[3L, ]))
  expect_equal(unname(X[2L, ]), c(1, 0, .3, .5))
  expect_equal(unname(X[4L, ]), c(1, 1, .2, .2))
  expect_identical(object$model$X, before$model$X)

  bad_probability <- mi_state_prediction_object()
  colnames(bad_probability$missing_data$predictors$x$conditional_probabilities) <- c("a", "b", "wrong")
  expect_error(
    drmTMB:::drm_prediction_matrix(bad_probability, NULL, "mu"),
    "named by fitted states"
  )
  bad_state_rows <- mi_state_prediction_object()
  bad_state_rows$model$missing_predictor$X_mu_state <- bad_state_rows$model$missing_predictor$X_mu_state[-1L, , drop = FALSE]
  expect_error(
    drmTMB:::drm_prediction_matrix(bad_state_rows, NULL, "mu"),
    "observation-major"
  )
})

test_that("multiple numeric missing predictors update only their missing rows", {
  object <- mi_prediction_object("gaussian")
  object$model$X$mu <- cbind(
    object$model$X$mu,
    "mi(w)" = c(.4, .5, .6, .7)
  )
  object$missing_data$predictors$w <- list(
    variable = "w",
    family = "gaussian",
    levels = character(),
    observed = c(FALSE, FALSE, TRUE, TRUE),
    value = c(1.1, 1.2, 1.3, 1.4),
    model_row = c(1L, 2L),
    original_row = c(11L, 12L),
    summary = "conditional_mode"
  )
  before <- unserialize(serialize(object, NULL))
  X <- drmTMB:::drm_prediction_matrix(object, NULL, "mu")

  expect_equal(unname(X[, "mi(x)"]), c(.1, .8, .3, .6))
  expect_equal(unname(X[, "mi(w)"]), c(1.1, 1.2, .6, .7))
  expect_equal(unname(X[, "z"]), unname(before$model$X$mu[, "z"]))
  expect_identical(object$model$X, before$model$X)
})

test_that("Bernoulli prediction validates fitted levels and leaves sigma exogenous", {
  object <- mi_prediction_object("bernoulli")
  object$model$X$sigma <- cbind("(Intercept)" = 1, z = c(-.5, 0, .5, 1))
  object$model$terms$sigma <- stats::terms(~z)
  object$model$model_frame$sigma <- data.frame(z = c(-.5, 0, .5, 1))

  sigma_data <- data.frame(z = c(-.25, .75))
  sigma_X <- drmTMB:::drm_prediction_matrix(
    object,
    drmTMB:::drm_prepare_prediction_newdata(object, sigma_data, "sigma"),
    "sigma"
  )
  expect_equal(as.numeric(sigma_X), c(1, 1, -.25, .75))

  single_level <- data.frame(x = factor("yes", levels = "yes"), z = .25)
  prepared <- drmTMB:::drm_prepare_prediction_newdata(object, single_level, "mu")
  expect_equal(prepared$x, 1)

  corrupt <- mi_prediction_object("bernoulli")
  corrupt$missing_data$predictors$x$levels <- "yes"
  expect_error(
    drmTMB:::drm_prepare_prediction_newdata(corrupt, single_level, "mu"),
    "metadata or values are incomplete"
  )
})

test_that("numeric Bernoulli labels take deterministic raw-level precedence", {
  raw_levels <- function(levels) {
    object <- mi_prediction_object("bernoulli")
    object$missing_data$predictors$x$levels <- as.character(levels)
    object
  }
  object_12 <- raw_levels(c(1, 2))
  expect_equal(
    drmTMB:::drm_prepare_prediction_newdata(
      object_12, data.frame(x = c(1, 2), z = c(0, 1)), "mu"
    )$x,
    c(0, 1)
  )
  expect_equal(
    drmTMB:::drm_prepare_prediction_newdata(
      object_12, data.frame(x = 1, z = 0), "mu"
    )$x,
    0
  )
  expect_error(
    drmTMB:::drm_prepare_prediction_newdata(
      object_12, data.frame(x = 0, z = 0), "mu"
    ),
    "fitted numeric levels"
  )

  object_23 <- raw_levels(c(2, 3))
  expect_equal(
    drmTMB:::drm_prepare_prediction_newdata(
      object_23, data.frame(x = c(2, 3), z = c(0, 1)), "mu"
    )$x,
    c(0, 1)
  )
  expect_error(
    drmTMB:::drm_prepare_prediction_newdata(
      object_23, data.frame(x = 1, z = 0), "mu"
    ),
    "fitted numeric levels"
  )
})

test_that("finite-state reconciliation accepts a sparse stored state design", {
  object <- mi_state_prediction_object()
  object$model$X$mu <- Matrix::Matrix(object$model$X$mu, sparse = TRUE)
  object$model$missing_predictor$X_mu_state <- Matrix::Matrix(
    object$model$missing_predictor$X_mu_state,
    sparse = TRUE
  )
  X <- drmTMB:::drm_prediction_matrix(object, NULL, "mu")
  expect_s4_class(X, "sparseMatrix")
  expect_equal(as.numeric(X[2L, ]), c(1, 0, .3, .5))
})

joint_prediction_fixture <- function() {
  path <- testthat::test_path(
    "..", "..", "docs", "dev-log", "evidence", "julia-r-parity",
    "joint-bridge", "joint-public-003.rds"
  )
  if (!file.exists(path)) {
    skip("The committed missing-predictor prediction fixture is unavailable.")
  }
  readRDS(path)$bernoulli$native
}

test_that("Bernoulli newdata survives missing stored templates", {
  fit <- joint_prediction_fixture()
  factor_data <- data.frame(
    x = factor(c("1", "0"), levels = c("1", "0")),
    z = c(-.25, .75)
  )
  numeric_data <- data.frame(x = c(1, 0), z = c(-.25, .75))

  fit$model$model_frame <- NULL
  expect_equal(
    predict(fit, newdata = factor_data, dpar = "mu"),
    predict(fit, newdata = numeric_data, dpar = "mu")
  )

  fit$data <- NULL
  fit$model$data <- NULL
  expect_equal(
    predict(fit, newdata = factor_data, dpar = "mu"),
    predict(fit, newdata = numeric_data, dpar = "mu")
  )
})

test_that("ambiguous parsed numeric Bernoulli labels reject numeric newdata", {
  for (levels in list(c("01", "1"), c("1", "1.0"))) {
    object <- mi_prediction_object("bernoulli")
    object$missing_data$predictors$x$levels <- levels
    expect_error(
      drmTMB:::drm_prepare_prediction_newdata(
        object, data.frame(x = 1, z = 0), "mu"
      ),
      "ambiguous fitted numeric levels"
    )
    expect_equal(
      drmTMB:::drm_prepare_prediction_newdata(
        object, data.frame(x = levels[[2L]], z = 0), "mu"
      )$x,
      1
    )
  }
})

test_that("decoded Bernoulli fallback leaves other factor validation intact", {
  object <- mi_prediction_object("bernoulli")
  object$model$model_frame <- NULL
  object$data$group <- factor(c("a", "a", "b", "b"), levels = c("a", "b"))
  object$model$terms$mu <- stats::terms(~z + group + mi(x))
  expect_error(
    drmTMB:::drm_prepare_prediction_newdata(
      object, data.frame(x = "yes", z = 0, group = "unknown"), "mu"
    ),
    "unknown factor level"
  )
  expect_s3_class(object$data$x, "factor")
})

joint_punctuated_prediction_fixture <- function() {
  dat <- data.frame(
    y = c(0.2, 0.5, NA, 1.1, 1.4, 1.8, 2.1, NA, 2.6),
    x = c(-.5, NA, .1, .4, NA, .9, 1.2, 1.4, .7),
    z = c(-1, -.7, -.3, 0, .2, .5, .8, 1, 1.3),
    g = factor(
      c("plain", "a: b", "a & b", "plain", "a: b", "a & b", "plain", "a: b", "a & b"),
      levels = c("plain", "a: b", "a & b")
    )
  )
  formula <- bf(
    y ~ mi(x) + g + z:g,
    sigma ~ g + z:g
  )
  prepared <- drmTMB:::drm_julia_joint_prepare(
    formula = formula,
    family = gaussian(),
    data = dat,
    env = environment(),
    weights_missing = TRUE,
    control = drm_control(),
    impute = list(x = x ~ z),
    missing = miss_control(response = "include", predictor = "model")
  )
  payload <- prepared$payload
  blocks <- c(
    rep("mu", length(payload$mu_names)),
    rep("sigma", length(payload$sigma_names)),
    rep("mi_x", length(payload$predictor_names)),
    "logsd_mi_x"
  )
  terms <- c(payload$mu_names, payload$sigma_names, payload$predictor_names, "log_sd")
  theta <- seq_along(blocks) / 10
  theta[[length(theta)]] <- log(1.2)
  names <- paste0(blocks, "_", terms)
  n <- length(payload$y)
  result <- list(
    schema = "joint_missing_result_v1",
    coef_names = names,
    coefficients = theta,
    vcov = diag(length(theta)) / 10,
    vcov_names = names,
    coefficient_blocks = blocks,
    coefficient_terms = terms,
    loglik = -12.3,
    aic = 34.6,
    bic = 39.1,
    df = length(theta),
    nobs = sum(payload$observed_y),
    converged = TRUE,
    iterations = 7L,
    fitted = rep(0, n),
    residuals = ifelse(payload$observed_y, 0, NA_real_),
    sigma = rep(1, n),
    corpairs = list(),
    dpars = list(),
    optimizer_status = "converged",
    covariance_status = "observed_information_inverse",
    original_row = payload$original_row,
    observed_y = payload$observed_y,
    observed_x = payload$observed_x,
    imputation = list(
      variable = rep("x", n),
      original_row = payload$original_row,
      model_row = seq_len(n),
      observed = payload$observed_x,
      estimate = ifelse(payload$observed_x, payload$x, 0),
      std_error = ifelse(payload$observed_x, NaN, .2),
      source = ifelse(payload$observed_x, "observed", "conditional_mode"),
      uncertainty_status = rep("ok", n),
      se_available = !payload$observed_x
    )
  )
  fit <- drmTMB:::drm_julia_joint_result(
    result, prepared, quote(joint_fit), formula, gaussian()
  )
  list(data = dat, prepared = prepared, fit = fit)
}

joint_punctuated_oracle <- function(fit, newdata, dpar) {
  rhs <- if (identical(dpar, "mu")) {
    ~x + g + z:g
  } else {
    ~g + z:g
  }
  X <- stats::model.matrix(rhs, newdata)
  if (identical(dpar, "mu")) {
    colnames(X)[colnames(X) == "x"] <- "mi(x)"
  }
  beta <- fit$coefficients[[dpar]]
  expect_identical(colnames(X), names(beta))
  drop(X %*% beta)
}

test_that("joint Julia newdata preserves punctuated factor and interaction labels", {
  fixture <- joint_punctuated_prediction_fixture()
  newdata <- data.frame(
    x = c(-.2, .3, .8),
    z = c(-.4, .1, .9),
    g = factor(c("a: b", "a & b", "plain"), levels = levels(fixture$data$g))
  )

  expect_true(is.null(fixture$fit$bridge_public_coef_labels))
  expect_true(any(grepl(": ", names(fixture$fit$coefficients$mu), fixed = TRUE)))
  expect_true(any(grepl(" & ", names(fixture$fit$coefficients$mu), fixed = TRUE)))
  expect_equal(
    predict(fixture$fit, newdata = newdata, dpar = "mu", type = "link"),
    unname(joint_punctuated_oracle(fixture$fit, newdata, "mu")),
    tolerance = 1e-12
  )
  expect_equal(
    predict(fixture$fit, newdata = newdata, dpar = "sigma", type = "link"),
    unname(joint_punctuated_oracle(fixture$fit, newdata, "sigma")),
    tolerance = 1e-12
  )
  unseen <- newdata
  unseen$g <- factor("unseen", levels = c(levels(fixture$data$g), "unseen"))
  expect_error(
    predict(fixture$fit, newdata = unseen, dpar = "mu", type = "link"),
    "new level"
  )
})

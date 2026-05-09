#' @export
print.drmTMB <- function(x, ...) {
  label <- switch(
    x$model$model_type,
    gaussian = "Gaussian location-scale",
    student = "Student-t location-scale-shape",
    lognormal = "Lognormal location-scale",
    gamma = "Gamma mean-CV",
    beta = "Beta mean-scale",
    poisson = "Poisson mean",
    zi_poisson = "zero-inflated Poisson mean",
    nbinom2 = "negative binomial 2 mean-dispersion",
    zi_nbinom2 = "zero-inflated negative binomial 2 mean-dispersion",
    biv_gaussian = "bivariate Gaussian location-scale-coscale",
    "distributional"
  )
  cli::cli_text("<drmTMB {label} fit>")
  cli::cli_text("  observations: {x$nobs}")
  if (has_mu_random_effects(x)) {
    cli::cli_text("  mu random-effect terms: {n_mu_random_effect_terms(x)}")
  }
  if (has_sigma_random_effects(x)) {
    cli::cli_text("  sigma random-effect terms: {length(x$sdpars$sigma)}")
  }
  cli::cli_text("  logLik: {format(x$logLik, digits = 4)}")
  cli::cli_text("  convergence: {x$opt$convergence}")
  invisible(x)
}

#' Extract fixed-effect coefficients
#'
#' `fixef()` returns the fixed-effect coefficients for one distributional
#' parameter, or all fixed-effect coefficient blocks when `dpar = NULL`.
#' It is a mixed-model-friendly alias for `coef()`.
#'
#' @param object A `drmTMB` fit.
#' @param dpar Optional distributional parameter name, such as `"mu"`,
#'   `"sigma"`, `"rho12"`, or `"sd(id)"`.
#' @param ... Reserved for future extractor options.
#'
#' @return A named numeric vector when `dpar` is supplied, otherwise a named
#'   list of coefficient vectors.
#' @export
fixef <- function(object, ...) {
  UseMethod("fixef")
}

#' @rdname fixef
#' @export
fixef.drmTMB <- function(object, dpar = NULL, ...) {
  coef.drmTMB(object, dpar = dpar, ...)
}

#' Extract conditional random-effect estimates
#'
#' `ranef()` returns conditional random-effect estimates for one fitted random
#' effect block, or all fitted random-effect blocks when `dpar = NULL`.
#'
#' The returned blocks use the internal `drmTMB` structure: `values` are on the
#' model scale, `latent` are the corresponding standard-normal latent effects,
#' and `terms` split model-scale values by random-effect term.
#'
#' @param object A `drmTMB` fit.
#' @param dpar Optional random-effect block name, such as `"mu"`, `"sigma"`,
#'   or `"phylo_mu"`.
#' @param ... Reserved for future extractor options.
#'
#' @return A named list of random-effect blocks when `dpar = NULL`, otherwise
#'   one random-effect block.
#' @export
ranef <- function(object, ...) {
  UseMethod("ranef")
}

#' @rdname ranef
#' @export
ranef.drmTMB <- function(object, dpar = NULL, ...) {
  blocks <- object$random_effects
  if (is.null(dpar)) {
    return(blocks)
  }
  if (!length(blocks)) {
    cli::cli_abort("This {.cls drmTMB} fit does not contain random effects.")
  }
  if (!dpar %in% names(blocks)) {
    cli::cli_abort(c(
      "Unknown random-effect block {.val {dpar}}.",
      i = "Available blocks: {.val {names(blocks)}}."
    ))
  }
  blocks[[dpar]]
}

#' Extract residual correlation rho12
#'
#' `rho12()` returns the residual response-response correlation from a
#' bivariate Gaussian `drmTMB` fit. By default it returns the response-scale
#' correlation. Use `type = "link"` for the Fisher-z-like linear predictor
#' whose response transform is `0.99999999 * tanh(eta)`.
#'
#' @param object A `drmTMB` fit.
#' @param newdata Optional data frame for prediction.
#' @param type Scale of returned values: `"response"` for correlation values or
#'   `"link"` for Fisher-z-like linear predictors.
#' @param ... Reserved for future extractor options.
#'
#' @return A numeric vector of residual correlations, or Fisher-z-like linear
#'   predictors when `type = "link"`.
#' @export
rho12 <- function(object, ...) {
  UseMethod("rho12")
}

#' @rdname rho12
#' @export
rho12.drmTMB <- function(object, newdata = NULL,
                         type = c("response", "link"), ...) {
  type <- match.arg(type)
  if (!"rho12" %in% names(object$coefficients)) {
    cli::cli_abort(
      "This {.cls drmTMB} fit does not contain residual correlation {.code rho12}."
    )
  }
  predict.drmTMB(object, newdata = newdata, dpar = "rho12", type = type, ...)
}

#' Extract fitted response values
#'
#' `fitted()` returns fitted response values from a `drmTMB` model. For
#' univariate Gaussian, Student-t, Gamma, beta, ordinary Poisson, and
#' negative-binomial fits this is the fitted `mu` vector. For zero-inflated
#' Poisson and zero-inflated negative-binomial 2 fits this is the unconditional
#' response mean `(1 - zi) * mu`, where `mu` is the conditional count mean. For
#' bivariate Gaussian fits this is a
#' two-column matrix with `mu1` and `mu2`. For lognormal fits this is the
#' arithmetic response mean, `exp(mu + sigma^2 / 2)`.
#'
#' Fitted values are returned for the original fitted rows. Use [predict()] for
#' new data or for non-location distributional parameters such as `sigma` or
#' `rho12`.
#'
#' @param object A `drmTMB` fit.
#' @param ... Reserved for future fitted-value options.
#'
#' @return A numeric vector for univariate fits, or a two-column matrix for
#'   bivariate Gaussian fits.
#' @export
fitted.drmTMB <- function(object, ...) {
  drm_fitted_response(object)
}

#' @export
coef.drmTMB <- function(object, dpar = NULL, ...) {
  if (is.null(dpar)) {
    return(object$coefficients)
  }
  dpar <- match.arg(dpar, names(object$coefficients))
  object$coefficients[[dpar]]
}

#' @export
vcov.drmTMB <- function(object, ...) {
  n_coef <- length(unlist(object$coefficients, use.names = FALSE))
  out <- object$sdr$cov.fixed[seq_len(n_coef), seq_len(n_coef), drop = FALSE]
  labels <- coefficient_labels(object)
  if (length(labels) == nrow(out)) {
    dimnames(out) <- list(labels, labels)
  }
  out
}

#' @export
logLik.drmTMB <- function(object, ...) {
  out <- object$logLik
  attr(out, "df") <- object$df
  attr(out, "nobs") <- object$nobs
  class(out) <- "logLik"
  out
}

#' Extract standard model-fit quantities
#'
#' These methods expose `drmTMB` fits to standard base-R model summary and
#' comparison helpers.
#'
#' `nobs()` returns the number of fitted rows after complete-case filtering.
#' `df.residual()` returns `nobs - df`, where `df` is the number of optimized
#' top-level parameters recorded in `logLik()`. `deviance()` returns
#' `-2 * logLik`; for these likelihood-based distributional models this is an
#' absolute negative twice log-likelihood value, not a saturated-model GLM
#' deviance.
#'
#' @param object A `drmTMB` fit.
#' @param ... Reserved for future extractor options.
#'
#' @return Numeric scalar.
#' @name model-fit-extractors
NULL

#' @rdname model-fit-extractors
#' @export
nobs.drmTMB <- function(object, ...) {
  object$nobs
}

#' @rdname model-fit-extractors
#' @export
df.residual.drmTMB <- function(object, ...) {
  object$nobs - object$df
}

#' @rdname model-fit-extractors
#' @export
deviance.drmTMB <- function(object, ...) {
  -2 * as.numeric(stats::logLik(object))
}

#' Predict distributional parameters
#'
#' `predict()` returns fitted or predicted values for one distributional
#' parameter of a `drmTMB` fit.
#'
#' By default, predictions are returned on the distributional parameter's
#' response scale. For positive scale parameters such as `sigma`, this means
#' the exponentiated value. For bivariate residual correlation `rho12`, this
#' means the correlation scale. Use `type = "link"` to return the linear
#' predictor instead.
#'
#' When `newdata = NULL`, predictions are for the fitted rows and include
#' currently implemented conditional random-effect contributions for `mu`,
#' phylogenetic `mu`, and residual-scale `sigma`. When `newdata` is supplied,
#' predictions are fixed-effect, population-level predictions for the supplied
#' rows.
#'
#' @param object A `drmTMB` fit.
#' @param newdata Optional data frame for prediction. If omitted, fitted rows
#'   are used.
#' @param dpar Distributional parameter to predict. If `NULL`, the first
#'   fitted distributional parameter is used.
#' @param type Prediction scale: `"response"` or `"link"`.
#' @param ... Reserved for future prediction options.
#'
#' @return A numeric vector.
#' @seealso [fitted.drmTMB()], [rho12()], [stats::sigma()]
#'
#' @examples
#' dat <- data.frame(
#'   y = c(0.2, 0.5, 1.1, 1.4, 1.8, 2.2),
#'   x = c(-1, -0.5, 0, 0.5, 1, 1.5)
#' )
#' fit <- drmTMB(bf(y ~ x, sigma = ~ x), data = dat)
#' predict(fit, dpar = "mu")
#' predict(fit, dpar = "sigma")
#' predict(fit, dpar = "sigma", type = "link")
#' predict(fit, newdata = data.frame(x = c(0, 1)), dpar = "mu")
#' @export
predict.drmTMB <- function(object, newdata = NULL, dpar = NULL,
                           type = c("response", "link"), ...) {
  if (is.null(dpar)) {
    dpar <- object$model$dpars[[1L]]
  }
  dpar <- match.arg(dpar, names(object$coefficients))
  type <- match.arg(type)
  if (is_random_scale_dpar(object, dpar)) {
    return(predict_random_scale_dpar(object, dpar, newdata = newdata, type = type))
  }
  X <- drm_prediction_matrix(object, newdata, dpar)
  eta <- as.vector(X %*% object$coefficients[[dpar]])
  if (is.null(newdata) && dpar == "mu" && has_ordinary_mu_random_effects(object)) {
    eta <- eta + mu_random_effect_contribution(object)
  }
  if (is.null(newdata) && dpar == "mu" && has_phylo_mu_effect(object)) {
    eta <- eta + phylo_mu_contribution(object)
  }
  if (is.null(newdata) && dpar == "sigma" && has_sigma_random_effects(object)) {
    eta <- eta + sigma_random_effect_contribution(object)
  }

  if (type == "link") {
    return(eta)
  }
  drm_inverse_link(object, dpar, eta)
}

#' Simulate from a fitted model
#'
#' `simulate()` draws new response values from the fitted `drmTMB` model. For
#' univariate Gaussian models with known sampling covariance, simulation uses
#' the total observation covariance implied by the known sampling covariance
#' plus the fitted residual scale. For Student-t models, simulation uses fitted
#' `mu`, `sigma`, and `nu`. For lognormal models, simulation uses fitted
#' log-scale `mu` and `sigma`. For Gamma models, simulation uses fitted mean
#' `mu` and coefficient of variation `sigma`. For beta models, simulation uses
#' fitted mean `mu` and public scale `sigma` with internal
#' `phi = 1 / sigma^2`. For Poisson models, simulation uses the fitted mean
#' `mu`. For zero-inflated Poisson models, simulation uses
#' fitted conditional mean `mu` and structural-zero probability `zi`. For
#' negative-binomial 2 models, simulation uses fitted `mu` and overdispersion
#' scale `sigma`, with `Var(y) = mu + sigma^2 * mu^2`; the zero-inflated NB2
#' path adds structural-zero probability `zi`. For bivariate Gaussian models without known
#' sampling covariance, simulation uses the fitted `mu1`, `mu2`, `sigma1`,
#' `sigma2`, and residual `rho12`. If a dense bivariate known `V` was supplied,
#' simulation uses the full row-paired observation covariance `V + Omega`.
#'
#' @param object A `drmTMB` fit.
#' @param nsim Number of simulated data sets.
#' @param seed Optional random-number seed. The previous `.Random.seed` state
#'   is restored after simulation.
#' @param ... Reserved for future simulation options.
#'
#' @return A data frame. Univariate models return one column per simulation.
#'   Bivariate models return paired columns named `sim_<j>_y1` and
#'   `sim_<j>_y2`.
#'
#' @examples
#' dat <- data.frame(y = c(0.2, 0.5, 1.1, 1.4), x = c(-1, 0, 1, 2))
#' fit <- drmTMB(bf(y ~ x, sigma = ~ 1), data = dat)
#' simulate(fit, nsim = 2, seed = 1)
#' @export
simulate.drmTMB <- function(object, nsim = 1, seed = NULL, ...) {
  if (!is.null(seed)) {
    had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    old_seed <- if (had_seed) {
      get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    } else {
      NULL
    }
    on.exit({
      if (had_seed) {
        assign(".Random.seed", old_seed, envir = .GlobalEnv)
      } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
        rm(".Random.seed", envir = .GlobalEnv)
      }
    }, add = TRUE)
    set.seed(seed)
  }

  if (identical(object$model$model_type, "student")) {
    mu <- predict(object, dpar = "mu")
    sigma <- predict(object, dpar = "sigma")
    nu <- predict(object, dpar = "nu")
    sims <- replicate(nsim, mu + sigma * stats::rt(length(mu), df = nu))
    sims <- as.data.frame(sims)
    names(sims) <- paste0("sim_", seq_len(nsim))
    return(sims)
  }

  if (identical(object$model$model_type, "lognormal")) {
    mu <- predict(object, dpar = "mu")
    sigma <- predict(object, dpar = "sigma")
    sims <- replicate(nsim, stats::rlnorm(length(mu), meanlog = mu, sdlog = sigma))
    sims <- as.data.frame(sims)
    names(sims) <- paste0("sim_", seq_len(nsim))
    return(sims)
  }

  if (identical(object$model$model_type, "gamma")) {
    mu <- predict(object, dpar = "mu")
    sigma <- predict(object, dpar = "sigma")
    shape <- 1 / sigma^2
    scale <- mu * sigma^2
    sims <- replicate(nsim, stats::rgamma(length(mu), shape = shape, scale = scale))
    sims <- as.data.frame(sims)
    names(sims) <- paste0("sim_", seq_len(nsim))
    return(sims)
  }

  if (identical(object$model$model_type, "beta")) {
    mu <- predict(object, dpar = "mu")
    sigma <- predict(object, dpar = "sigma")
    phi <- 1 / sigma^2
    sims <- replicate(nsim, stats::rbeta(
      length(mu),
      shape1 = mu * phi,
      shape2 = (1 - mu) * phi
    ))
    sims <- as.data.frame(sims)
    names(sims) <- paste0("sim_", seq_len(nsim))
    return(sims)
  }

  if (identical(object$model$model_type, "poisson")) {
    mu <- predict(object, dpar = "mu")
    sims <- replicate(nsim, stats::rpois(length(mu), lambda = mu))
    sims <- as.data.frame(sims)
    names(sims) <- paste0("sim_", seq_len(nsim))
    return(sims)
  }

  if (identical(object$model$model_type, "zi_poisson")) {
    mu <- predict(object, dpar = "mu")
    zi <- predict(object, dpar = "zi")
    sims <- replicate(nsim, {
      structural_zero <- stats::runif(length(mu)) < zi
      ifelse(structural_zero, 0L, stats::rpois(length(mu), lambda = mu))
    })
    sims <- as.data.frame(sims)
    names(sims) <- paste0("sim_", seq_len(nsim))
    return(sims)
  }

  if (identical(object$model$model_type, "nbinom2")) {
    mu <- predict(object, dpar = "mu")
    sigma <- predict(object, dpar = "sigma")
    sims <- replicate(nsim, stats::rnbinom(length(mu), size = 1 / sigma^2, mu = mu))
    sims <- as.data.frame(sims)
    names(sims) <- paste0("sim_", seq_len(nsim))
    return(sims)
  }

  if (identical(object$model$model_type, "zi_nbinom2")) {
    mu <- predict(object, dpar = "mu")
    sigma <- predict(object, dpar = "sigma")
    zi <- predict(object, dpar = "zi")
    sims <- replicate(nsim, {
      structural_zero <- stats::runif(length(mu)) < zi
      ifelse(
        structural_zero,
        0L,
        stats::rnbinom(length(mu), size = 1 / sigma^2, mu = mu)
      )
    })
    sims <- as.data.frame(sims)
    names(sims) <- paste0("sim_", seq_len(nsim))
    return(sims)
  }

  if (identical(object$model$model_type, "gaussian")) {
    mu <- predict(object, dpar = "mu")
    if (identical(object$model$V_known_type, "matrix")) {
      Sigma <- observation_covariance(object)
      chol_Sigma <- chol(Sigma)
      sims <- replicate(nsim, as.vector(mu + t(chol_Sigma) %*% stats::rnorm(length(mu))))
    } else {
      sigma <- observation_sigma(object)
      sims <- replicate(nsim, stats::rnorm(length(mu), mean = mu, sd = sigma))
    }
    sims <- as.data.frame(sims)
    names(sims) <- paste0("sim_", seq_len(nsim))
    return(sims)
  }

  mu1 <- predict(object, dpar = "mu1")
  mu2 <- predict(object, dpar = "mu2")
  sigma1 <- predict(object, dpar = "sigma1")
  sigma2 <- predict(object, dpar = "sigma2")
  rho12 <- predict(object, dpar = "rho12")
  if (identical(object$model$V_known_type, "matrix")) {
    mu_stack <- stack_biv_response(mu1, mu2)
    Sigma <- bivariate_observation_covariance(object)
    chol_Sigma <- chol(Sigma)
    sims_stack <- replicate(
      nsim,
      as.vector(mu_stack + t(chol_Sigma) %*% stats::rnorm(length(mu_stack)))
    )
    out <- vector("list", nsim * 2L)
    names(out) <- as.vector(rbind(
      paste0("sim_", seq_len(nsim), "_y1"),
      paste0("sim_", seq_len(nsim), "_y2")
    ))
    for (j in seq_len(nsim)) {
      sim_j <- unstack_biv_response(sims_stack[, j])
      out[[paste0("sim_", j, "_y1")]] <- sim_j[, "y1"]
      out[[paste0("sim_", j, "_y2")]] <- sim_j[, "y2"]
    }
    return(as.data.frame(out))
  }
  out <- vector("list", nsim * 2L)
  names(out) <- as.vector(rbind(
    paste0("sim_", seq_len(nsim), "_y1"),
    paste0("sim_", seq_len(nsim), "_y2")
  ))
  for (j in seq_len(nsim)) {
    z1 <- stats::rnorm(length(mu1))
    z2_ind <- stats::rnorm(length(mu1))
    z2 <- rho12 * z1 + sqrt(1 - rho12^2) * z2_ind
    out[[paste0("sim_", j, "_y1")]] <- mu1 + sigma1 * z1
    out[[paste0("sim_", j, "_y2")]] <- mu2 + sigma2 * z2
  }
  as.data.frame(out)
}

#' Extract model residuals
#'
#' `residuals()` returns response residuals or Pearson-style residuals from a
#' `drmTMB` fit.
#'
#' For univariate Gaussian models, response residuals are `y - mu`. Pearson
#' residuals divide by the fitted observation standard deviation. If a dense
#' known sampling covariance was used, Pearson residuals are whitened by the
#' fitted total observation covariance.
#'
#' For lognormal models, response residuals are `y - fitted_mean`. Pearson
#' residuals are computed on the log-response scale as `(log(y) - mu) / sigma`.
#' For Gamma models, response residuals are `y - mu` and Pearson residuals
#' divide by the fitted Gamma standard deviation `mu * sigma`, where `sigma` is
#' the coefficient of variation. For Poisson models, response residuals are
#' `y - mu` and Pearson residuals divide by `sqrt(mu)`. For zero-inflated
#' Poisson models, response residuals are `y - (1 - zi) * mu`, and Pearson
#' residuals divide by `sqrt((1 - zi) * mu * (1 + zi * mu))`. For
#' negative-binomial 2 models, Pearson residuals divide by
#' `sqrt(mu + sigma^2 * mu^2)`. For zero-inflated NB2 models, response
#' residuals are `y - (1 - zi) * mu`, and Pearson residuals divide by the
#' unconditional standard deviation implied by the structural-zero mixture.
#'
#' For bivariate Gaussian models, response residuals are returned as a
#' two-column matrix. Pearson residuals are standardized and whitened using the
#' fitted residual `sigma1`, `sigma2`, and `rho12`, or using the full row-paired
#' observation covariance when a dense bivariate known `V` was supplied.
#'
#' @param object A `drmTMB` fit.
#' @param type Residual type: `"response"` or `"pearson"`.
#' @param ... Reserved for future residual options.
#'
#' @return A numeric vector for univariate models, or a two-column matrix for
#'   bivariate Gaussian models.
#'
#' @examples
#' dat <- data.frame(y = c(0.2, 0.5, 1.1, 1.4), x = c(-1, 0, 1, 2))
#' fit <- drmTMB(bf(y ~ x, sigma = ~ 1), data = dat)
#' residuals(fit)
#' residuals(fit, type = "pearson")
#' @export
residuals.drmTMB <- function(object, type = c("response", "pearson"), ...) {
  type <- match.arg(type)
  if (identical(object$model$model_type, "lognormal")) {
    if (type == "response") {
      return(object$model$y - stats::fitted(object))
    }
    return((log(object$model$y) - predict(object, dpar = "mu")) /
      predict(object, dpar = "sigma"))
  }
  if (identical(object$model$model_type, "gamma")) {
    response <- object$model$y - predict(object, dpar = "mu")
    if (type == "response") {
      return(response)
    }
    return(response / (predict(object, dpar = "mu") * predict(object, dpar = "sigma")))
  }
  if (identical(object$model$model_type, "beta")) {
    mu <- predict(object, dpar = "mu")
    sigma <- predict(object, dpar = "sigma")
    response <- object$model$y - mu
    if (type == "response") {
      return(response)
    }
    return(response / sqrt(mu * (1 - mu) * sigma^2 / (1 + sigma^2)))
  }
  if (identical(object$model$model_type, "poisson")) {
    mu <- predict(object, dpar = "mu")
    response <- object$model$y - mu
    if (type == "response") {
      return(response)
    }
    return(response / sqrt(mu))
  }
  if (identical(object$model$model_type, "zi_poisson")) {
    mu <- predict(object, dpar = "mu")
    zi <- predict(object, dpar = "zi")
    fitted_mean <- (1 - zi) * mu
    response <- object$model$y - fitted_mean
    if (type == "response") {
      return(response)
    }
    return(response / sqrt((1 - zi) * mu * (1 + zi * mu)))
  }
  if (identical(object$model$model_type, "nbinom2")) {
    mu <- predict(object, dpar = "mu")
    sigma <- predict(object, dpar = "sigma")
    response <- object$model$y - mu
    if (type == "response") {
      return(response)
    }
    return(response / sqrt(mu + sigma^2 * mu^2))
  }
  if (identical(object$model$model_type, "zi_nbinom2")) {
    mu <- predict(object, dpar = "mu")
    sigma <- predict(object, dpar = "sigma")
    zi <- predict(object, dpar = "zi")
    fitted_mean <- (1 - zi) * mu
    response <- object$model$y - fitted_mean
    if (type == "response") {
      return(response)
    }
    component_var <- mu + sigma^2 * mu^2
    unconditional_var <- (1 - zi) * component_var + zi * (1 - zi) * mu^2
    return(response / sqrt(unconditional_var))
  }
  if (identical(object$model$model_type, "gaussian") ||
      identical(object$model$model_type, "student")) {
    response <- object$model$y - predict(object, dpar = "mu")
    if (type == "response") {
      return(response)
    }
    if (identical(object$model$V_known_type, "matrix")) {
      return(as.vector(forwardsolve(t(chol(observation_covariance(object))), response)))
    }
    return(response / observation_sigma(object))
  }

  response <- cbind(
    y1 = object$model$y1 - predict(object, dpar = "mu1"),
    y2 = object$model$y2 - predict(object, dpar = "mu2")
  )
  if (type == "response") {
    return(response)
  }
  if (identical(object$model$V_known_type, "matrix")) {
    response_stack <- stack_biv_response(response[, "y1"], response[, "y2"])
    white <- as.vector(forwardsolve(
      t(chol(bivariate_observation_covariance(object))),
      response_stack
    ))
    return(unstack_biv_response(white))
  }
  sigma1 <- predict(object, dpar = "sigma1")
  sigma2 <- predict(object, dpar = "sigma2")
  rho12 <- predict(object, dpar = "rho12")
  e1 <- response[, "y1"] / sigma1
  e2_raw <- response[, "y2"] / sigma2
  e2 <- (e2_raw - rho12 * e1) / sqrt(1 - rho12^2)
  cbind(y1 = e1, y2 = e2)
}

#' Extract fitted scale or dispersion
#'
#' `sigma()` returns the fitted scale-like parameter from a `drmTMB` model. For
#' univariate Gaussian location-scale models this is the fitted residual
#' `sigma_i` vector on the response scale. For Student-t models this is the
#' Student-t scale parameter; when `nu > 2`, the residual standard deviation is
#' `sigma * sqrt(nu / (nu - 2))`. For lognormal models this is the fitted
#' standard deviation of `log(y)`. For Gamma models this is the fitted
#' coefficient of variation. For beta models this is the public scale parameter
#' where internal precision is `phi = 1 / sigma^2`. Poisson and zero-inflated
#' Poisson models have no fitted residual scale parameter and return a fixed
#' unit dispersion vector for consistency with base-R `sigma()` conventions. For
#' negative-binomial 2 and
#' zero-inflated negative-binomial 2 models this is the fitted overdispersion
#' scale in `Var(y | nonstructural) = mu + sigma^2 * mu^2`. For bivariate
#' Gaussian models it returns a list with fitted `sigma1` and
#' `sigma2` vectors.
#'
#' In meta-analytic models fitted with `meta_known_V(V = V)`, this is the
#' modelled residual heterogeneity scale, not the square root of the known
#' sampling variance plus residual variance. Simulation and Pearson residuals
#' combine known sampling covariance with residual scale internally.
#'
#' @param object A `drmTMB` fit.
#' @param ... Reserved for future scale-extractor options.
#'
#' @return A numeric vector for univariate models, or a named list of numeric
#'   vectors for bivariate Gaussian models.
#'
#' @examples
#' dat <- data.frame(y = c(0.2, 0.5, 1.1, 1.4), x = c(-1, 0, 1, 2))
#' fit <- drmTMB(bf(y ~ x, sigma = ~ x), data = dat)
#' sigma(fit)
#' @export
sigma.drmTMB <- function(object, ...) {
  if (identical(object$model$model_type, "gaussian") ||
      identical(object$model$model_type, "student") ||
      identical(object$model$model_type, "lognormal") ||
      identical(object$model$model_type, "gamma") ||
      identical(object$model$model_type, "beta") ||
      identical(object$model$model_type, "nbinom2") ||
      identical(object$model$model_type, "zi_nbinom2")) {
    return(predict(object, dpar = "sigma"))
  }
  if (identical(object$model$model_type, "poisson") ||
      identical(object$model$model_type, "zi_poisson")) {
    return(rep(1, object$nobs))
  }
  list(
    sigma1 = predict(object, dpar = "sigma1"),
    sigma2 = predict(object, dpar = "sigma2")
  )
}

#' Summarize a fitted model
#'
#' `summary()` returns a compact summary of fixed-effect estimates, fitted
#' random-effect standard deviations and correlations, log-likelihood, and
#' optimizer convergence code.
#'
#' @param object A `drmTMB` fit.
#' @param ... Reserved for future summary options.
#'
#' @return An object of class `summary.drmTMB`.
#'
#' @examples
#' dat <- data.frame(y = c(0.2, 0.5, 1.1, 1.4), x = c(-1, 0, 1, 2))
#' fit <- drmTMB(bf(y ~ x, sigma = ~ 1), data = dat)
#' summary(fit)
#' @export
summary.drmTMB <- function(object, ...) {
  se <- sqrt(diag(stats::vcov(object)))
  est <- unlist(object$coefficients, use.names = FALSE)

  out <- list(
    call = object$call,
    coefficients = data.frame(
      estimate = est,
      std_error = se,
      row.names = coefficient_labels(object),
      check.names = FALSE
    ),
    sdpars = object$sdpars,
    corpars = object$corpars,
    logLik = stats::logLik(object),
    convergence = object$opt$convergence
  )
  class(out) <- "summary.drmTMB"
  out
}

#' @export
print.summary.drmTMB <- function(x, ...) {
  cli::cli_text("<summary.drmTMB>")
  print(x$coefficients)
  if (length(x$sdpars) > 0L) {
    cli::cli_text("Random-effect SDs:")
    print(x$sdpars)
  }
  if (length(x$corpars) > 0L) {
    cli::cli_text("Random-effect correlations:")
    print(x$corpars)
  }
  cli::cli_text("logLik: {format(as.numeric(x$logLik), digits = 4)}")
  cli::cli_text("convergence: {x$convergence}")
  invisible(x)
}

drm_prediction_matrix <- function(object, newdata, dpar) {
  if (is.null(newdata)) {
    return(object$model$X[[dpar]])
  }
  if (!is.data.frame(newdata)) {
    cli::cli_abort("{.arg newdata} must be a data frame.")
  }
  stats::model.matrix(object$model$terms[[dpar]], data = newdata)
}

observation_sigma <- function(object) {
  sqrt(known_v_diag(object) + predict(object, dpar = "sigma")^2)
}

observation_covariance <- function(object) {
  sigma2 <- predict(object, dpar = "sigma")^2
  if (identical(object$model$V_known_type, "matrix")) {
    out <- object$model$V_known
    diag(out) <- diag(out) + sigma2
    return(out)
  }
  diag(known_v_diag(object) + sigma2, nrow = length(sigma2))
}

bivariate_observation_covariance <- function(object) {
  n <- length(object$model$y1)
  out <- if (identical(object$model$V_known_type, "matrix")) {
    object$model$V_known
  } else {
    matrix(0, nrow = 2L * n, ncol = 2L * n)
  }
  sigma1 <- predict(object, dpar = "sigma1")
  sigma2 <- predict(object, dpar = "sigma2")
  rho12 <- predict(object, dpar = "rho12")
  i1 <- seq.int(1L, by = 2L, length.out = n)
  i2 <- i1 + 1L
  cov12 <- rho12 * sigma1 * sigma2
  out[cbind(i1, i1)] <- out[cbind(i1, i1)] + sigma1^2
  out[cbind(i2, i2)] <- out[cbind(i2, i2)] + sigma2^2
  out[cbind(i1, i2)] <- out[cbind(i1, i2)] + cov12
  out[cbind(i2, i1)] <- out[cbind(i2, i1)] + cov12
  out
}

stack_biv_response <- function(y1, y2) {
  as.vector(rbind(y1, y2))
}

unstack_biv_response <- function(y) {
  n <- length(y) / 2L
  cbind(
    y1 = y[seq.int(1L, by = 2L, length.out = n)],
    y2 = y[seq.int(2L, by = 2L, length.out = n)]
  )
}

known_v_diag <- function(object) {
  if (!is.null(object$model$V_known_diag)) {
    return(object$model$V_known_diag)
  }
  if (is.matrix(object$model$V_known)) {
    return(diag(object$model$V_known))
  }
  object$model$V_known
}

lognormal_mean <- function(object) {
  mu <- predict(object, dpar = "mu")
  sigma <- predict(object, dpar = "sigma")
  exp(mu + 0.5 * sigma^2)
}

drm_fitted_response <- function(object) {
  if (identical(object$model$model_type, "biv_gaussian")) {
    return(cbind(
      mu1 = predict.drmTMB(object, dpar = "mu1"),
      mu2 = predict.drmTMB(object, dpar = "mu2")
    ))
  }
  if (identical(object$model$model_type, "lognormal")) {
    return(lognormal_mean(object))
  }
  if (identical(object$model$model_type, "gamma")) {
    return(predict.drmTMB(object, dpar = "mu"))
  }
  if (identical(object$model$model_type, "beta")) {
    return(predict.drmTMB(object, dpar = "mu"))
  }
  if (identical(object$model$model_type, "poisson")) {
    return(predict.drmTMB(object, dpar = "mu"))
  }
  if (identical(object$model$model_type, "zi_poisson")) {
    mu <- predict.drmTMB(object, dpar = "mu")
    zi <- predict.drmTMB(object, dpar = "zi")
    return((1 - zi) * mu)
  }
  if (identical(object$model$model_type, "nbinom2")) {
    return(predict.drmTMB(object, dpar = "mu"))
  }
  if (identical(object$model$model_type, "zi_nbinom2")) {
    mu <- predict.drmTMB(object, dpar = "mu")
    zi <- predict.drmTMB(object, dpar = "zi")
    return((1 - zi) * mu)
  }
  if (identical(object$model$model_type, "gaussian") ||
      identical(object$model$model_type, "student")) {
    return(predict.drmTMB(object, dpar = "mu"))
  }
  cli::cli_abort(
    "Internal error: no fitted-response rule for model type {.val {object$model$model_type}}."
  )
}

drm_inverse_link <- function(object, dpar, eta) {
  link <- drm_dpar_link(object, dpar)
  switch(
    link,
    identity = eta,
    log = exp(eta),
    logit = stats::plogis(eta),
    logm2 = 2 + exp(eta),
    atanh_guarded = rho_response(eta),
    cli::cli_abort("Internal error: unknown inverse link {.val {link}}.")
  )
}

drm_dpar_link <- function(object, dpar) {
  links <- switch(
    object$model$model_type,
    gaussian = c(mu = "identity", sigma = "log"),
    student = c(mu = "identity", sigma = "log", nu = "logm2"),
    lognormal = c(mu = "identity", sigma = "log"),
    gamma = c(mu = "log", sigma = "log"),
    beta = c(mu = "logit", sigma = "log"),
    poisson = c(mu = "log"),
    zi_poisson = c(mu = "log", zi = "logit"),
    nbinom2 = c(mu = "log", sigma = "log"),
    zi_nbinom2 = c(mu = "log", sigma = "log", zi = "logit"),
    biv_gaussian = c(
      mu1 = "identity",
      mu2 = "identity",
      sigma1 = "log",
      sigma2 = "log",
      rho12 = "atanh_guarded"
    ),
    NULL
  )
  if (is.null(links)) {
    cli::cli_abort(
      "Internal error: no link table for model type {.val {object$model$model_type}}."
    )
  }
  if (!dpar %in% names(links)) {
    cli::cli_abort(
      "Internal error: no link entry for distributional parameter {.val {dpar}}."
    )
  }
  unname(links[[dpar]])
}

rho_response <- function(eta) {
  0.99999999 * tanh(eta)
}

coefficient_labels <- function(object) {
  unlist(lapply(names(object$coefficients), function(dpar) {
    paste0(dpar, ":", names(object$coefficients[[dpar]]))
  }), use.names = FALSE)
}

has_mu_random_effects <- function(object) {
  has_ordinary_mu_random_effects(object) || has_phylo_mu_effect(object)
}

has_ordinary_mu_random_effects <- function(object) {
  identical(object$model$model_type, "gaussian") &&
    length(object$random_effects$mu$values) > 0L
}

has_mu_random_intercepts <- has_mu_random_effects

has_phylo_mu_effect <- function(object) {
  identical(object$model$model_type, "gaussian") &&
    isTRUE(object$model$structured$phylo_mu$has)
}

n_mu_random_effect_terms <- function(object) {
  length(object$model$random$mu$labels) + as.integer(has_phylo_mu_effect(object))
}

has_sigma_random_effects <- function(object) {
  identical(object$model$model_type, "gaussian") &&
    length(object$random_effects$sigma$values) > 0L
}

is_random_scale_dpar <- function(object, dpar) {
  identical(object$model$model_type, "gaussian") &&
    object$model$random_scale$mu$n_models > 0L &&
    dpar %in% object$model$random_scale$mu$dpars
}

predict_random_scale_dpar <- function(object, dpar, newdata = NULL,
                                      type = c("response", "link")) {
  type <- match.arg(type)
  sd_mu <- object$model$random_scale$mu
  if (!dpar %in% sd_mu$dpars) {
    cli::cli_abort("Unknown random-effect scale parameter {.val {dpar}}.")
  }
  if (is.null(newdata)) {
    X <- sd_mu$X_list[[dpar]]
    names_out <- sd_mu$group_levels_list[[dpar]]
  } else {
    if (!is.data.frame(newdata)) {
      cli::cli_abort("{.arg newdata} must be a data frame.")
    }
    X <- stats::model.matrix(sd_mu$terms_list[[dpar]], data = newdata)
    names_out <- rownames(newdata)
  }
  eta <- as.vector(X %*% object$coefficients[[dpar]])
  if (type == "link") {
    stats::setNames(eta, names_out)
  } else {
    stats::setNames(exp(eta), names_out)
  }
}

mu_random_effect_contribution <- function(object) {
  values <- object$random_effects$mu$values
  index <- object$model$random$mu$index
  design_value <- object$model$random$mu$value
  rowSums(matrix(values[index], nrow = nrow(index)) * design_value)
}

mu_random_intercept_contribution <- mu_random_effect_contribution

phylo_mu_contribution <- function(object) {
  values <- object$random_effects$phylo_mu$values
  index <- object$model$structured$phylo_mu$observation_node_index
  unname(values[index])
}

sigma_random_effect_contribution <- function(object) {
  values <- object$random_effects$sigma$values
  index <- object$model$random$sigma$index
  design_value <- object$model$random$sigma$value
  rowSums(matrix(values[index], nrow = nrow(index)) * design_value)
}

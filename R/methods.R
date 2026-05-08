#' @export
print.drmTMB <- function(x, ...) {
  label <- switch(
    x$model$model_type,
    gaussian = "Gaussian location-scale",
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

  if (type == "link" || dpar %in% c("mu", "mu1", "mu2")) {
    return(eta)
  }
  if (dpar == "rho12") {
    return(rho_response(eta))
  }
  exp(eta)
}

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

#' @export
residuals.drmTMB <- function(object, type = c("response", "pearson"), ...) {
  type <- match.arg(type)
  if (identical(object$model$model_type, "gaussian")) {
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
  sigma1 <- predict(object, dpar = "sigma1")
  sigma2 <- predict(object, dpar = "sigma2")
  rho12 <- predict(object, dpar = "rho12")
  e1 <- response[, "y1"] / sigma1
  e2_raw <- response[, "y2"] / sigma2
  e2 <- (e2_raw - rho12 * e1) / sqrt(1 - rho12^2)
  cbind(y1 = e1, y2 = e2)
}

#' @export
sigma.drmTMB <- function(object, ...) {
  if (identical(object$model$model_type, "gaussian")) {
    return(predict(object, dpar = "sigma"))
  }
  list(
    sigma1 = predict(object, dpar = "sigma1"),
    sigma2 = predict(object, dpar = "sigma2")
  )
}

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

known_v_diag <- function(object) {
  if (!is.null(object$model$V_known_diag)) {
    return(object$model$V_known_diag)
  }
  if (is.matrix(object$model$V_known)) {
    return(diag(object$model$V_known))
  }
  object$model$V_known
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

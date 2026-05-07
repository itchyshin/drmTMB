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
  cli::cli_text("  logLik: {format(x$logLik, digits = 4)}")
  cli::cli_text("  convergence: {x$opt$convergence}")
  invisible(x)
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
  out <- object$sdr$cov.fixed
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
  X <- drm_prediction_matrix(object, newdata, dpar)
  eta <- as.vector(X %*% object$coefficients[[dpar]])

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
    sigma <- observation_sigma(object)
    sims <- replicate(nsim, stats::rnorm(length(mu), mean = mu, sd = sigma))
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
  sqrt(object$model$V_known + predict(object, dpar = "sigma")^2)
}

rho_response <- function(eta) {
  0.99999999 * tanh(eta)
}

coefficient_labels <- function(object) {
  unlist(lapply(names(object$coefficients), function(dpar) {
    paste0(dpar, ":", names(object$coefficients[[dpar]]))
  }), use.names = FALSE)
}

#' Construct a latent-normal association kernel
#'
#' `latent_normal()` declares the Gaussian-copula kernel used by
#' [associate_pairs()]. It is not a Gaussian residual-correlation model and
#' does not use [rho12()].
#'
#' @return A latent-normal kernel specification.
#' @export
latent_normal <- function() {
  structure(
    list(name = "latent_normal", version = 1L),
    class = "drm_pair_kernel"
  )
}

#' Associate two frozen marginal drmTMB fits
#'
#' `associate_pairs()` estimates a named within-row association after fitting
#' two marginal models. It never refits, updates, profiles, or otherwise alters
#' either margin. Arc 6 implements fixed-effect Gaussian margins paired with
#' literal Bernoulli `binomial(link = "logit")` or ordinary `nbinom2()` margins,
#' plus the literal Bernoulli × Bernoulli rectangle route, on the same complete
#' analysis rows.
#'
#' The fitted parameter `eta` is a Gaussian-copula latent-normal association.
#' It is neither [rho12()], an observed-scale correlation, nor [corpairs()].
#' The [corpair()] formula marker is a distinct interface.
#' The stage-2 Hessian treats the margins as fixed, so no standard error,
#' confidence interval, profile, or coverage claim is available.
#'
#' @param fit_1,fit_2 Two fitted `drmTMB` marginal models. They must use the
#'   identical complete analysis data, in the same order.
#' @param kernel A named association kernel. Arc 6 accepts only
#'   `latent_normal()`.
#' @param association Association formula. Arc 6.2 accepts only `~ 1`.
#'
#' @return An object of class `drm_pair_association`.
#' @export
#'
#' @examples
#' set.seed(20260723)
#' dat <- data.frame(x = rnorm(80))
#' z_g <- rnorm(80)
#' z_b <- 0.35 * z_g + sqrt(1 - 0.35^2) * rnorm(80)
#' dat$trait_continuous <- 0.2 + 0.5 * dat$x + z_g
#' dat$trait_binary <- as.integer(z_b > qnorm(0.6))
#'
#' gaussian_fit <- drmTMB(
#'   bf(mu = trait_continuous ~ x, sigma = ~ 1),
#'   family = gaussian(), data = dat
#' )
#' binary_fit <- drmTMB(
#'   bf(mu = trait_binary ~ x), family = binomial(), data = dat
#' )
#' assoc <- associate_pairs(
#'   gaussian_fit, binary_fit,
#'   kernel = latent_normal(), association = ~ 1
#' )
#' association(assoc)
associate_pairs <- function(
  fit_1,
  fit_2,
  kernel,
  association
) {
  if (missing(kernel)) {
    cli::cli_abort(
      "Supply an explicit {.code kernel = latent_normal()} declaration."
    )
  }
  if (missing(association)) {
    cli::cli_abort(
      "Supply {.code association = ~ 1}; Arc 6 has no implicit association model."
    )
  }
  drm_pair_validate_kernel(kernel)
  drm_pair_validate_intercept_only(association)
  drm_pair_validate_fit(fit_1, "fit_1")
  drm_pair_validate_fit(fit_2, "fit_2")
  drm_pair_validate_shared_data(fit_1, fit_2)
  if (identical(drm_pair_response_name(fit_1), drm_pair_response_name(fit_2))) {
    cli::cli_abort("Arc 6 requires two distinct response variables.")
  }

  model_types <- c(fit_1$model$model_type, fit_2$model$model_type)
  pair_class <- if (setequal(model_types, c("gaussian", "binomial"))) {
    "gaussian_bernoulli"
  } else if (setequal(model_types, c("gaussian", "nbinom2"))) {
    "gaussian_nbinom2"
  } else if (setequal(model_types, c("binomial", "nbinom2"))) {
    "bernoulli_nbinom2"
  } else if (identical(model_types, c("binomial", "binomial"))) {
    "bernoulli_bernoulli"
  } else {
    NULL
  }
  if (is.null(pair_class)) {
    cli::cli_abort(c(
      "Arc 6 requires one reviewed pair class, including ordinary {.code nbinom2()} where applicable, or two literal {.code binomial()} fits.",
      i = "Other pair classes require their own Arc 6 review."
    ))
  }

  fits <- list(fit_1, fit_2)
  descriptor <- if (identical(pair_class, "bernoulli_bernoulli")) NULL else {
    drm_pair_descriptor(pair_class)
  }
  components <- if (identical(pair_class, "bernoulli_bernoulli")) {
    binary_components <- lapply(fits, drm_pair_bernoulli_components)
    list(
      pair_class = pair_class,
      binary_1_y = binary_components[[1L]]$y,
      binary_1_p = binary_components[[1L]]$p,
      binary_2_y = binary_components[[2L]]$y,
      binary_2_p = binary_components[[2L]]$p
    )
  } else if (identical(pair_class, "bernoulli_nbinom2")) {
    binary_fit <- fits[[which(model_types == "binomial")]]
    nbinom2_fit <- fits[[which(model_types == "nbinom2")]]
    drm_pair_validate_bernoulli(binary_fit)
    drm_pair_validate_nbinom2(nbinom2_fit)
    binary_p <- stats::predict(binary_fit, dpar = "mu", type = "response")
    nbinom2_mu <- stats::predict(nbinom2_fit, dpar = "mu", type = "response")
    nbinom2_sigma <- stats::predict(nbinom2_fit, dpar = "sigma", type = "response")
    if (any(!is.finite(binary_p)) || any(binary_p <= 0 | binary_p >= 1)) {
      cli::cli_abort("Frozen Bernoulli probabilities must be finite and strictly interior.")
    }
    drm_pair_validate_nbinom2_components(nbinom2_fit$model$y, nbinom2_mu, nbinom2_sigma)
    list(pair_class = pair_class, descriptor = descriptor, binary_y = binary_fit$model$y,
      binary_p = binary_p, nbinom2_y = nbinom2_fit$model$y,
      nbinom2_mu = nbinom2_mu, nbinom2_sigma = nbinom2_sigma)
  } else {
    gaussian_pos <- which(model_types == "gaussian")
    gaussian_fit <- fits[[gaussian_pos]]
    drm_pair_validate_gaussian(gaussian_fit)
    gaussian_mu <- stats::predict(gaussian_fit, dpar = "mu", type = "response")
    gaussian_sigma <- stats::predict(gaussian_fit, dpar = "sigma", type = "response")
    gaussian_y <- gaussian_fit$model$y
    if (any(!is.finite(gaussian_mu)) || any(!is.finite(gaussian_sigma)) || any(gaussian_sigma <= 0)) {
      cli::cli_abort("Frozen marginal predictions must be finite and strictly interior.")
    }
    pair_fit <- fits[[which(model_types != "gaussian")]]
    if (identical(pair_class, "gaussian_bernoulli")) {
    drm_pair_validate_bernoulli(pair_fit)
    binary_p <- stats::predict(pair_fit, dpar = "mu", type = "response")
    if (any(!is.finite(binary_p)) || any(binary_p <= 0 | binary_p >= 1)) {
      cli::cli_abort("Frozen Bernoulli probabilities must be finite and strictly interior.")
    }
    list(
      pair_class = pair_class, descriptor = descriptor,
      gaussian_y = gaussian_y,
      binary_y = pair_fit$model$y,
      gaussian_mu = gaussian_mu,
      gaussian_sigma = gaussian_sigma,
      binary_p = binary_p
    )
    } else {
    drm_pair_validate_nbinom2(pair_fit)
    nbinom2_mu <- stats::predict(pair_fit, dpar = "mu", type = "response")
    nbinom2_sigma <- stats::predict(pair_fit, dpar = "sigma", type = "response")
    drm_pair_validate_nbinom2_components(
      pair_fit$model$y, nbinom2_mu, nbinom2_sigma
    )
    list(
      pair_class = pair_class, descriptor = descriptor,
      gaussian_y = gaussian_y,
      nbinom2_y = pair_fit$model$y,
      gaussian_mu = gaussian_mu,
      gaussian_sigma = gaussian_sigma,
      nbinom2_mu = nbinom2_mu,
      nbinom2_sigma = nbinom2_sigma
    )
    }
  }
  fit_result <- drm_pair_fit_eta(components)
  snapshot_1 <- drm_pair_margin_snapshot(fit_1)
  snapshot_2 <- drm_pair_margin_snapshot(fit_2)

  response_names <- c(
    fit_1 = drm_pair_response_name(fit_1),
    fit_2 = drm_pair_response_name(fit_2)
  )
  margin_order <- if (identical(pair_class, "bernoulli_bernoulli")) {
    c(fit_1 = "bernoulli_1", fit_2 = "bernoulli_2")
  } else if (identical(pair_class, "bernoulli_nbinom2")) {
    c(fit_1 = if (model_types[[1L]] == "binomial") "bernoulli" else "nbinom2",
      fit_2 = if (model_types[[2L]] == "binomial") "bernoulli" else "nbinom2")
  } else {
    pair_role <- if (identical(pair_class, "gaussian_bernoulli")) "bernoulli" else "nbinom2"
    c(fit_1 = if (model_types[[1L]] == "gaussian") "gaussian" else pair_role,
      fit_2 = if (model_types[[2L]] == "gaussian") "gaussian" else pair_role)
  }

  structure(
    list(
      call = match.call(),
      kernel = kernel,
      association = association,
      status = fit_result$status,
      eta = fit_result$eta,
      eta_internal = fit_result$eta_internal,
      alpha = fit_result$alpha,
      logLik = fit_result$logLik,
      diagnostics = fit_result$diagnostics,
      components = components,
      pair_descriptor = descriptor,
      response_names = response_names,
      margin_order = margin_order,
      margins = list(fit_1 = snapshot_1, fit_2 = snapshot_2),
      provenance = list(
        row_id = seq_len(nrow(fit_1$data)),
        original_row = drm_pair_analysis_rows(fit_1),
        data_hash = drm_pair_fingerprint(fit_1$data),
        fit_hashes = c(
          fit_1 = drm_pair_fingerprint(snapshot_1),
          fit_2 = drm_pair_fingerprint(snapshot_2)
        ),
        package_version = as.character(utils::packageVersion("drmTMB"))
      )
    ),
    class = "drm_pair_association"
  )
}

#' Extract a pair association estimate
#'
#' @param object A `drm_pair_association` object.
#' @param ... Reserved for future extractor options.
#'
#' @return A one-row data frame with the latent-normal association and its
#'   diagnostic status. No standard error or interval is supplied.
#' @export
association <- function(object, ...) {
  UseMethod("association")
}

#' @rdname association
#' @export
association.drm_pair_association <- function(object, ...) {
  if (identical(object$status, "boundary_unresolved")) {
    cli::cli_abort(c(
      "The association maximum is boundary-unresolved.",
      i = "Inspect {.code object$diagnostics}; Arc 6 does not return a public point estimate for this case."
    ))
  }
  data.frame(
    kernel = object$kernel$name,
    estimand = "latent-normal association",
    eta = object$eta,
    status = object$status,
    boundary = object$diagnostics$near_boundary,
    stringsAsFactors = FALSE
  )
}

#' @export
print.drm_pair_association <- function(x, ...) {
  cli::cli_text("<drmTMB frozen-margin pair association>")
  cli::cli_text("  kernel: {x$kernel$name}")
  cli::cli_text("  status: {x$status}")
  if (!identical(x$status, "boundary_unresolved")) {
    cli::cli_text("  eta: {format(x$eta, digits = 4)}")
  }
  cli::cli_text(
    "  standard errors: unavailable; frozen-margin point estimate only"
  )
  invisible(x)
}

#' @export
summary.drm_pair_association <- function(object, ...) {
  structure(
    list(
      association = if (identical(object$status, "boundary_unresolved")) {
        NULL
      } else {
        association(object)
      },
      diagnostics = object$diagnostics,
      provenance = object$provenance
    ),
    class = "summary.drm_pair_association"
  )
}

#' @export
print.summary.drm_pair_association <- function(x, ...) {
  cli::cli_text("<summary.drm_pair_association>")
  if (is.null(x$association)) {
    cli::cli_text("  association: boundary-unresolved")
  } else {
    cli::cli_text("  eta: {format(x$association$eta, digits = 4)}")
    cli::cli_text("  status: {x$association$status}")
  }
  cli::cli_text("  standard errors and intervals: unavailable")
  invisible(x)
}

#' @export
fitted.drm_pair_association <- function(object, ...) {
  if (identical(object$components$pair_class, "bernoulli_bernoulli")) {
    out <- data.frame(
      object$components$binary_1_p,
      object$components$binary_2_p,
      check.names = FALSE
    )
    names(out) <- unname(object$response_names)
    return(out)
  }
  by_role <- list()
  if ("gaussian" %in% object$components$descriptor$roles) {
    by_role$gaussian <- object$components$gaussian_mu
  }
  if ("bernoulli" %in% object$components$descriptor$roles) {
    by_role$bernoulli <- object$components$binary_p
  }
  if ("nbinom2" %in% object$components$descriptor$roles) {
    by_role$nbinom2 <- object$components$nbinom2_mu
  }
  out <- data.frame(
    by_role[[object$margin_order[["fit_1"]]]],
    by_role[[object$margin_order[["fit_2"]]]],
    check.names = FALSE
  )
  names(out) <- unname(object$response_names)
  out
}

#' @export
#' @importFrom stats fitted
predict.drm_pair_association <- function(object, newdata = NULL, ...) {
  if (!is.null(newdata)) {
    cli::cli_abort(c(
      "Arc 6 association predictions are defined only for frozen analysis rows.",
      i = "New-data association prediction needs a separate validated Arc."
    ))
  }
  fitted(object)
}

#' @export
simulate.drm_pair_association <- function(object, nsim = 1, seed = NULL, ...) {
  if (
    !identical(object$status, "interior") &&
      !identical(object$status, "near_boundary")
  ) {
    cli::cli_abort("Cannot simulate a boundary-unresolved association fit.")
  }
  if (!is.null(seed)) {
    set.seed(seed)
  }
  if (
    !is.numeric(nsim) ||
      length(nsim) != 1L ||
      is.na(nsim) ||
      nsim < 1L ||
      nsim != as.integer(nsim)
  ) {
    cli::cli_abort("{.arg nsim} must be one positive integer.")
  }

  eta <- object$eta_internal
  draws <- lapply(seq_len(as.integer(nsim)), function(i) {
    if (identical(object$components$pair_class, "bernoulli_bernoulli")) {
      n <- length(object$components$binary_1_p)
      z_1 <- stats::rnorm(n)
      z_2 <- eta * z_1 + sqrt(1 - eta^2) * stats::rnorm(n)
      out <- data.frame(
        as.integer(z_1 > stats::qnorm(object$components$binary_1_p, lower.tail = FALSE)),
        as.integer(z_2 > stats::qnorm(object$components$binary_2_p, lower.tail = FALSE)),
        check.names = FALSE
      )
      names(out) <- unname(object$response_names)
      return(out)
    }
    n <- if (!is.null(object$components$binary_y)) {
      length(object$components$binary_y)
    } else {
      length(object$components$gaussian_y)
    }
    z_1 <- stats::rnorm(n)
    z_2 <- eta * z_1 + sqrt(1 - eta^2) * stats::rnorm(n)
    by_role <- list()
    if ("gaussian" %in% object$components$descriptor$roles) {
      by_role$gaussian <- object$components$gaussian_mu + object$components$gaussian_sigma * z_1
    }
    if (identical(object$components$pair_class, "gaussian_bernoulli")) {
      threshold <- stats::qnorm(1 - object$components$binary_p)
      by_role$bernoulli <- as.integer(z_2 > threshold)
    } else if (identical(object$components$pair_class, "gaussian_nbinom2")) {
      by_role$nbinom2 <- drm_pair_nbinom2_quantile_from_normal(z_2,
        object$components$nbinom2_mu,
        object$components$nbinom2_sigma
      )
    } else {
      threshold <- stats::qnorm(
        object$components$binary_p,
        lower.tail = FALSE
      )
      by_role$bernoulli <- as.integer(z_1 > threshold)
      by_role$nbinom2 <- drm_pair_nbinom2_quantile_from_normal(z_2,
        object$components$nbinom2_mu, object$components$nbinom2_sigma)
    }
    data.frame(
      by_role[[object$margin_order[["fit_1"]]]],
      by_role[[object$margin_order[["fit_2"]]]],
      check.names = FALSE
    )
  })
  for (i in seq_along(draws)) {
    names(draws[[i]]) <- unname(object$response_names)
  }
  if (length(draws) == 1L) {
    return(draws[[1L]])
  }
  draws
}

#' @export
rho12.drm_pair_association <- function(object, ...) {
  cli::cli_abort(c(
    "{.fn rho12} is defined for {.fn biv_gaussian} fits, not mixed pair associations.",
    i = "Use {.fn association} for the Arc 6 latent-normal estimand."
  ))
}

#' @export
corpairs.drm_pair_association <- function(object, ...) {
  cli::cli_abort(c(
    "{.fn corpairs} requires a compatible Gaussian random-effect block.",
    i = "Arc 6 has fixed margins and no random-effect correlation."
  ))
}

#' @export
sigma.drm_pair_association <- function(object, ...) {
  cli::cli_abort(
    "{.fn sigma} has no single meaning for a mixed frozen-margin association."
  )
}

#' @export
residuals.drm_pair_association <- function(object, ...) {
  cli::cli_abort(
    "Residual diagnostics for frozen-margin pair associations are not implemented."
  )
}

#' @export
vcov.drm_pair_association <- function(object, ...) {
  cli::cli_abort(c(
    "{.fn vcov} is unavailable for Arc 6 frozen-margin association estimates.",
    i = "A later Arc must validate two-stage sandwich or bootstrap uncertainty."
  ))
}

#' @export
profile.drm_pair_association <- function(fitted, ...) {
  cli::cli_abort(
    "Profile inference is unavailable for Arc 6 frozen-margin association estimates."
  )
}

#' @export
confint.drm_pair_association <- function(object, ...) {
  cli::cli_abort(c(
    "Confidence intervals are unavailable for Arc 6 frozen-margin association estimates.",
    i = "A later Arc must validate two-stage uncertainty before {.fn confint} is available."
  ))
}

#' @export
#' @importFrom stats quantile
quantile.drm_pair_association <- function(x, ...) {
  cli::cli_abort(
    "Quantiles are unavailable for Arc 6 frozen-margin association estimates."
  )
}

#' @export
update.drm_pair_association <- function(object, ...) {
  cli::cli_abort(c(
    "Frozen-margin association objects cannot be updated.",
    i = "Refit declared margins separately, then construct a new {.fn associate_pairs} object."
  ))
}

#' @exportS3Method emmeans::recover_data
recover_data.drm_pair_association <- function(object, ...) {
  cli::cli_abort(
    "{.pkg emmeans} is unavailable for Arc 6 frozen-margin association estimates."
  )
}

#' @exportS3Method emmeans::emm_basis
emm_basis.drm_pair_association <- function(object, ...) {
  cli::cli_abort(
    "{.pkg emmeans} is unavailable for Arc 6 frozen-margin association estimates."
  )
}

drm_pair_validate_kernel <- function(kernel) {
  if (
    !inherits(kernel, "drm_pair_kernel") ||
      !identical(kernel$name, "latent_normal")
  ) {
    cli::cli_abort(
      "Arc 6 requires {.code kernel = latent_normal()}."
    )
  }
}

# Internal pair contract. The versioned descriptor is deliberately private: it
# records the two margin roles used by adapters without widening the public S3
# object API.
drm_pair_descriptor <- function(pair_class) {
  roles <- switch(pair_class,
    gaussian_bernoulli = c("gaussian", "bernoulli"),
    gaussian_nbinom2 = c("gaussian", "nbinom2"),
    bernoulli_nbinom2 = c("bernoulli", "nbinom2"),
    NULL
  )
  if (is.null(roles)) {
    cli::cli_abort("Unsupported frozen-margin pair descriptor.")
  }
  structure(list(version = 1L, pair_class = pair_class, roles = roles),
    class = "drm_pair_descriptor")
}

drm_pair_validate_intercept_only <- function(association) {
  if (!inherits(association, "formula")) {
    cli::cli_abort("{.arg association} must be a formula.")
  }
  association_terms <- stats::terms(association)
  if (
    attr(association_terms, "intercept") != 1L ||
      length(attr(association_terms, "term.labels")) != 0L
  ) {
    cli::cli_abort(c(
      "Arc 6 supports only {.code association = ~ 1}.",
      i = "Association slopes require a later Arc and separate identification review."
    ))
  }
}

drm_pair_validate_fit <- function(fit, name) {
  if (!inherits(fit, "drmTMB")) {
    cli::cli_abort("{.arg {name}} must be a fitted {.cls drmTMB} model.")
  }
  if (isTRUE(fit$REML) || !identical(fit$estimator, "ML")) {
    cli::cli_abort("{.arg {name}} must be a fixed-effect ML marginal fit.")
  }
  if (
    (!is.null(fit$missing_data$response_policy) &&
      !identical(fit$missing_data$response_policy, "drop")) ||
      !all(fit$model$keep) ||
      nrow(fit$data) != fit$nobs
  ) {
    cli::cli_abort(c(
      "{.arg {name}} must retain one complete analysis data set without dropped rows.",
      i = "Construct the complete-pair data before fitting either margin."
    ))
  }
  random_terms <- vapply(
    fit$model$random,
    function(x) if (is.null(x$n_terms)) 0L else x$n_terms,
    integer(1L)
  )
  if (
    !is.null(fit$model$random_names) ||
      length(fit$random_effects) ||
      length(fit$sdpars) ||
      any(random_terms > 0L) ||
      isTRUE(fit$model$structured$phylo_mu$has)
  ) {
    cli::cli_abort(
      "{.arg {name}} must not contain random or structured effects."
    )
  }
  if (any(fit$model$weights != 1) || isTRUE(fit$model$has_known_v)) {
    cli::cli_abort(
      "{.arg {name}} must use unit weights and no known covariance."
    )
  }
  offsets <- fit$model$offset
  if (!is.null(offsets) && any(unlist(offsets, use.names = FALSE) != 0)) {
    cli::cli_abort("{.arg {name}} must not contain an offset.")
  }
}

drm_pair_validate_shared_data <- function(fit_1, fit_2) {
  if (
    !identical(fit_1$data, fit_2$data) ||
      !identical(drm_pair_analysis_rows(fit_1), drm_pair_analysis_rows(fit_2))
  ) {
    cli::cli_abort(c(
      "The two margins must be fitted on identical complete analysis data in identical row order.",
      i = "Refit both margins after constructing one complete-pair analysis data set."
    ))
  }
  variables <- unique(c(fit_1$model$variables, fit_2$model$variables))
  if (!all(stats::complete.cases(fit_1$data[, variables, drop = FALSE]))) {
    cli::cli_abort(
      "The shared analysis data contain missing response or predictor values."
    )
  }
}

drm_pair_analysis_rows <- function(fit) {
  rows <- fit$missing_data$original_row
  if (is.null(rows)) seq_len(nrow(fit$data)) else rows
}

drm_pair_validate_gaussian <- function(fit) {
  if (
    !identical(fit$family$link, "identity") ||
      !identical(fit$model$dpars, c("mu", "sigma"))
  ) {
    cli::cli_abort("Arc 6 requires the standard Gaussian mu/sigma margin.")
  }
}

drm_pair_validate_bernoulli <- function(fit) {
  if (
    !identical(fit$family$link, "logit") ||
      !identical(fit$model$dpars, "mu") ||
      any(fit$model$trials != 1) ||
      any(!fit$model$y %in% c(0, 1))
  ) {
    cli::cli_abort(c(
      "Arc 6.1 requires literal 0/1 Bernoulli data fitted with {.code binomial(link = \"logit\")}.",
      i = "Binomial trials and weights-as-trials require a later pair contract."
    ))
  }
}

drm_pair_bernoulli_components <- function(fit) {
  drm_pair_validate_bernoulli(fit)
  p <- stats::predict(fit, dpar = "mu", type = "response")
  if (any(!is.finite(p)) || any(p <= 0 | p >= 1)) {
    cli::cli_abort(
      "Frozen Bernoulli probabilities must be finite and strictly interior."
    )
  }
  list(y = fit$model$y, p = p)
}

drm_pair_validate_nbinom2 <- function(fit) {
  if (
    !identical(unname(fit$family$link[c("mu", "sigma")]), c("log", "log")) ||
      !identical(fit$model$dpars, c("mu", "sigma"))
  ) {
    cli::cli_abort(c(
      "Arc 6.2 requires ordinary {.code nbinom2()} with log {.code mu} and {.code sigma} margins.",
      i = "Zero-inflated, hurdle, and truncated NB2 require separate pair contracts."
    ))
  }
}

drm_pair_validate_nbinom2_components <- function(y, mu, sigma) {
  size <- drm_nbinom2_size(sigma)
  if (
    any(!is.finite(y)) || any(y < 0) || any(y != floor(y)) ||
      any(!is.finite(mu)) || any(mu <= 0) ||
      any(!is.finite(sigma)) || any(sigma <= 0) ||
      any(!is.finite(size)) || any(size <= 0)
  ) {
    cli::cli_abort(c(
      "Frozen ordinary NB2 margins require finite non-negative integer counts and finite positive {.code mu} and {.code sigma}.",
      i = "Use a complete ordinary {.code nbinom2()} fit; altered count supports require a later Arc."
    ))
  }
}

drm_pair_response_name <- function(fit) {
  fit$model$response_names$mu
}

drm_pair_margin_snapshot <- function(fit) {
  list(
    call = fit$call,
    formula = fit$formula$calls,
    family = fit$family[c("family", "link")],
    coefficients = fit$coefficients,
    response_name = drm_pair_response_name(fit),
    response = fit$model$y,
    fitted = list(
      mu = stats::predict(fit, dpar = "mu", type = "response"),
      sigma = if ("sigma" %in% fit$model$dpars) {
        stats::predict(fit, dpar = "sigma", type = "response")
      } else {
        NULL
      }
    ),
    original_row = drm_pair_analysis_rows(fit),
    data_hash = drm_pair_fingerprint(fit$data),
    package_version = as.character(utils::packageVersion("drmTMB"))
  )
}

drm_pair_fingerprint <- function(x) {
  path <- tempfile("drmtmb-pair-fingerprint-", fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(x, path, version = 3)
  unname(tools::md5sum(path))
}

drm_pair_fit_eta <- function(components) {
  loglik <- drm_pair_loglikelihood_function(components)
  objective <- function(alpha) {
    value <- loglik(alpha, components)
    if (!is.finite(value)) {
      return(.Machine$double.xmax)
    }
    -value
  }
  starts <- c(-1, 0, 1)
  fits <- lapply(starts, function(start) {
    stats::nlminb(start = start, objective = objective, lower = -8, upper = 8)
  })
  objectives <- vapply(fits, `[[`, numeric(1L), "objective")
  multistart_alpha <- vapply(
    fits,
    function(fit) unname(fit$par[[1L]]),
    numeric(1L)
  )
  best <- fits[[which.min(objectives)]]
  alpha <- unname(best$par[[1L]])
  eta_internal <- 0.999999 * tanh(alpha)
  logLik <- loglik(alpha, components)
  h <- 1e-4
  curvature <- if (alpha > -8 + h && alpha < 8 - h) {
    (loglik(alpha + h, components) -
      2 * logLik +
      loglik(alpha - h, components)) /
      h^2
  } else {
    NA_real_
  }
  score <- if (alpha > -8 + h && alpha < 8 - h) {
    (loglik(alpha + h, components) -
      loglik(alpha - h, components)) /
      (2 * h)
  } else {
    NA_real_
  }
  near_boundary <- abs(eta_internal) >= 0.995
  objective_tolerance <- 1e-7 * (1 + abs(min(objectives)))
  multistart_disagreement <- any(
    !is.finite(objectives) |
      (objectives - min(objectives)) > objective_tolerance
  ) || (max(multistart_alpha) - min(multistart_alpha) > 1e-3)
  convergence_failure <- !identical(best$convergence, 0L)
  weak_curvature <- !is.finite(curvature) || curvature >= -1e-6
  score_failure <- !is.finite(score) || abs(score) > 1e-3
  unresolved <- abs(alpha) >= 7.99 ||
    !is.finite(logLik) ||
    convergence_failure ||
    multistart_disagreement ||
    weak_curvature ||
    score_failure
  status <- if (unresolved) {
    "boundary_unresolved"
  } else if (near_boundary) {
    "near_boundary"
  } else {
    "interior"
  }
  interval_diagnostics <- drm_pair_interval_diagnostics(components, alpha)
  list(
    status = status,
    eta = if (identical(status, "boundary_unresolved")) {
      NA_real_
    } else {
      eta_internal
    },
    eta_internal = eta_internal,
    alpha = alpha,
    logLik = logLik,
    diagnostics = list(
      alpha = alpha,
      eta_internal = eta_internal,
      near_boundary = near_boundary,
      boundary_unresolved = unresolved,
      optimizer_convergence = best$convergence,
      optimizer_message = best$message,
      multistart_objectives = objectives,
      multistart_alpha = multistart_alpha,
      multistart_disagreement = multistart_disagreement,
      convergence_failure = convergence_failure,
      weak_curvature = weak_curvature,
      score_failure = score_failure,
      score = score,
      curvature = curvature,
      response_patterns = drm_pair_response_diagnostics(components, alpha),
      count_interval = interval_diagnostics
    )
  )
}

drm_pair_response_diagnostics <- function(components, alpha) {
  pair_class <- components$pair_class
  if (identical(pair_class, "bernoulli_bernoulli")) {
    eta <- 0.999999 * tanh(alpha)
    evaluations <- drm_pair_bernoulli_bernoulli_evaluations(eta, components)
    probabilities <- vapply(evaluations, `[[`, numeric(1L), "value")
    abs_errors <- vapply(evaluations, `[[`, numeric(1L), "abs_error")
    messages <- vapply(evaluations, `[[`, character(1L), "message")
    return(list(
      table = table(components$binary_1_y, components$binary_2_y),
      minority_count_1 = min(sum(components$binary_1_y == 0), sum(components$binary_1_y == 1)),
      minority_count_2 = min(sum(components$binary_2_y == 0), sum(components$binary_2_y == 1)),
      prevalence_range_1 = range(components$binary_1_p),
      prevalence_range_2 = range(components$binary_2_p),
      min_rectangle_mass = min(probabilities),
      nonfinite_rectangle_count = sum(!is.finite(probabilities)),
      max_rectangle_abs_error = if (all(is.na(abs_errors))) NA_real_ else max(abs_errors, na.rm = TRUE),
      rectangle_messages = table(messages)
    ))
  }
  if (
    identical(pair_class, "gaussian_bernoulli") ||
      (is.null(pair_class) && !is.null(components$binary_y))
  ) {
    return(table(components$binary_y))
  }
  c(
    n = length(components$nbinom2_y),
    zeros = sum(components$nbinom2_y == 0),
    min_count = min(components$nbinom2_y),
    max_count = max(components$nbinom2_y)
  )
}

drm_pair_loglikelihood_function <- function(components) {
  pair_class <- components$pair_class
  if (is.null(pair_class) && !is.null(components$binary_y)) {
    pair_class <- "gaussian_bernoulli"
  }
  switch(
    pair_class,
    gaussian_bernoulli = drm_pair_gaussian_bernoulli_loglik,
    gaussian_nbinom2 = drm_pair_gaussian_nbinom2_loglik,
    bernoulli_bernoulli = drm_pair_bernoulli_bernoulli_loglik,
    bernoulli_nbinom2 = drm_pair_bernoulli_nbinom2_loglik,
    cli::cli_abort("Unsupported frozen-margin pair class.")
  )
}

drm_pair_interval_diagnostics <- function(components, alpha = NULL) {
  if (is.null(components$pair_class) ||
      !components$pair_class %in% c("gaussian_nbinom2", "bernoulli_nbinom2")) {
    return(NULL)
  }
  endpoints <- drm_pair_nbinom2_endpoints(
    components$nbinom2_y,
    components$nbinom2_mu,
    components$nbinom2_sigma
  )
  interval <- if (is.null(alpha)) NULL else if (identical(components$pair_class, "gaussian_nbinom2")) {
    drm_pair_nbinom2_interval_log_prob(alpha, components)
  } else {
    drm_pair_bernoulli_nbinom2_probabilities(alpha, components)
  }
  list(
    nbinom2_size_range = range(drm_nbinom2_size(components$nbinom2_sigma)),
    nbinom2_mu_range = range(components$nbinom2_mu),
    nbinom2_sigma_range = range(components$nbinom2_sigma),
    lower_tail_endpoints = sum(endpoints$upper_representation == "lower"),
    survival_tail_endpoints = sum(endpoints$upper_representation == "upper"),
    finite_endpoint_count = sum(is.finite(endpoints$upper)),
    strict_order = all(endpoints$lower < endpoints$upper),
    conditional_interval_branches = if (is.null(interval) || is.null(interval$branch)) NULL else table(interval$branch),
    conditional_log_interval_range = if (is.null(interval) || is.null(interval$log_probability)) NULL else range(interval$log_probability),
    nonfinite_conditional_intervals = if (is.null(interval)) NULL else sum(!is.finite(interval$log_probability)),
    endpoint_complement_error_max = endpoints$complement_error_max
  )
}

drm_pair_gaussian_bernoulli_loglik <- function(alpha, components) {
  eta <- 0.999999 * tanh(alpha)
  z <- (components$gaussian_y - components$gaussian_mu) /
    components$gaussian_sigma
  threshold <- stats::qnorm(components$binary_p, lower.tail = FALSE)
  conditional_z <- (threshold - eta * z) / sqrt(1 - eta^2)
  log_binary <- ifelse(
    components$binary_y == 1,
    stats::pnorm(conditional_z, lower.tail = FALSE, log.p = TRUE),
    stats::pnorm(conditional_z, log.p = TRUE)
  )
  sum(
    stats::dnorm(
      components$gaussian_y,
      mean = components$gaussian_mu,
      sd = components$gaussian_sigma,
      log = TRUE
    ) +
      log_binary
  )
}

drm_pair_gaussian_bernoulli_conditional_prob <- function(
  z,
  p,
  eta,
  binary_y
) {
  threshold <- stats::qnorm(p, lower.tail = FALSE)
  conditional_z <- (threshold - eta * z) / sqrt(1 - eta^2)
  if (length(binary_y) == 1L) {
    if (binary_y == 1) {
      return(stats::pnorm(conditional_z, lower.tail = FALSE))
    }
    return(stats::pnorm(conditional_z))
  }
  ifelse(
    binary_y == 1,
    stats::pnorm(conditional_z, lower.tail = FALSE),
    stats::pnorm(conditional_z)
  )
}

drm_pair_bernoulli_bernoulli_loglik <- function(alpha, components) {
  probabilities <- drm_pair_bernoulli_bernoulli_probabilities(alpha, components)
  if (any(!is.finite(probabilities)) || any(probabilities <= 0)) {
    return(-Inf)
  }
  sum(log(probabilities))
}

drm_pair_bernoulli_bernoulli_probabilities <- function(alpha, components) {
  eta <- 0.999999 * tanh(alpha)
  vapply(drm_pair_bernoulli_bernoulli_evaluations(eta, components), `[[`, numeric(1L), "value")
}

drm_pair_bernoulli_bernoulli_evaluations <- function(eta, components) {
  lapply(seq_along(components$binary_1_y), function(i) {
    drm_pair_bernoulli_rectangle_evaluation(
      y_1 = components$binary_1_y[[i]],
      p_1 = components$binary_1_p[[i]],
      y_2 = components$binary_2_y[[i]],
      p_2 = components$binary_2_p[[i]],
      eta = eta
    )
  })
}

drm_pair_bernoulli_rectangle_probability <- function(y_1, p_1, y_2, p_2, eta) {
  drm_pair_bernoulli_rectangle_evaluation(y_1, p_1, y_2, p_2, eta)$value
}

drm_pair_bernoulli_rectangle_evaluation <- function(y_1, p_1, y_2, p_2, eta) {
  threshold_1 <- stats::qnorm(p_1, lower.tail = FALSE)
  threshold_2 <- stats::qnorm(p_2, lower.tail = FALSE)
  limits_1 <- if (y_1 == 1L) c(threshold_1, Inf) else c(-Inf, threshold_1)
  sd_2 <- sqrt(1 - eta^2)
  integrand <- function(z_1) {
    z_2 <- (threshold_2 - eta * z_1) / sd_2
    probability_2 <- if (y_2 == 1L) {
      stats::pnorm(z_2, lower.tail = FALSE)
    } else {
      stats::pnorm(z_2)
    }
    stats::dnorm(z_1) * probability_2
  }
  result <- tryCatch(
    stats::integrate(integrand, lower = limits_1[[1L]], upper = limits_1[[2L]],
      rel.tol = 1e-10, subdivisions = 200L
    ),
    error = function(e) list(
      value = NA_real_, abs.error = NA_real_, message = conditionMessage(e)
    )
  )
  resolved <- !is.null(result) &&
    identical(result$message, "OK") &&
    is.finite(result$value) && result$value > 0 &&
    is.finite(result$abs.error) &&
    result$abs.error <= max(1e-10, 1e-7 * result$value)
  if (!resolved) {
    return(list(
      value = NA_real_,
      abs_error = if (is.null(result)) NA_real_ else result$abs.error,
      message = if (is.null(result)) "integration error" else result$message
    ))
  }
  list(value = result$value, abs_error = result$abs.error, message = result$message)
}

drm_pair_nbinom2_endpoints <- function(y, mu, sigma) {
  size <- drm_nbinom2_size(sigma)
  upper_log_cdf <- stats::pnbinom(y, size = size, mu = mu, log.p = TRUE)
  upper_log_survival <- stats::pnbinom(
    y, size = size, mu = mu, lower.tail = FALSE, log.p = TRUE
  )
  lower_y <- y - 1L
  lower_log_cdf <- rep.int(-Inf, length(y))
  lower_log_survival <- rep.int(0, length(y))
  positive <- y > 0
  lower_log_cdf[positive] <- stats::pnbinom(
    lower_y[positive], size = size[positive], mu = mu[positive], log.p = TRUE
  )
  lower_log_survival[positive] <- stats::pnbinom(
    lower_y[positive], size = size[positive], mu = mu[positive],
    lower.tail = FALSE, log.p = TRUE
  )
  upper <- drm_pair_normal_quantile_from_log_tails(
    upper_log_cdf, upper_log_survival
  )
  lower <- rep.int(-Inf, length(y))
  lower[positive] <- drm_pair_normal_quantile_from_log_tails(
    lower_log_cdf[positive], lower_log_survival[positive]
  )
  if (
    any(!is.finite(upper)) || any(!is.finite(lower[positive])) ||
      any(lower >= upper)
  ) {
    cli::cli_abort(c(
      "NB2 CDF interval endpoints are numerically unresolved for these frozen margins.",
      i = "Do not clip tail probabilities; refit or simplify the marginal model before association fitting."
    ))
  }
  list(
    lower = lower,
    upper = upper,
    upper_representation = ifelse(upper_log_cdf <= log(0.5), "lower", "upper"),
    lower_representation = ifelse(lower_log_cdf <= log(0.5), "lower", "upper"),
    complement_error_max = max(abs(
      exp(upper_log_cdf) + exp(upper_log_survival) - 1
    ))
  )
}

drm_pair_normal_quantile_from_log_tails <- function(log_cdf, log_survival) {
  use_lower <- log_cdf <= log(0.5)
  out <- numeric(length(log_cdf))
  out[use_lower] <- stats::qnorm(log_cdf[use_lower], log.p = TRUE)
  out[!use_lower] <- stats::qnorm(
    log_survival[!use_lower], lower.tail = FALSE, log.p = TRUE
  )
  out
}

drm_pair_nbinom2_quantile_from_normal <- function(z, mu, sigma) {
  mu <- rep_len(mu, length(z))
  sigma <- rep_len(sigma, length(z))
  log_cdf <- stats::pnorm(z, log.p = TRUE)
  log_survival <- stats::pnorm(z, lower.tail = FALSE, log.p = TRUE)
  use_lower <- log_cdf <= log(0.5)
  size <- drm_nbinom2_size(sigma)
  out <- numeric(length(z))
  out[use_lower] <- stats::qnbinom(
    log_cdf[use_lower], size = size[use_lower], mu = mu[use_lower], log.p = TRUE
  )
  out[!use_lower] <- stats::qnbinom(
    log_survival[!use_lower], size = size[!use_lower], mu = mu[!use_lower],
    lower.tail = FALSE, log.p = TRUE
  )
  if (any(!is.finite(out))) {
    cli::cli_abort("Latent-normal NB2 simulation produced a non-finite quantile.")
  }
  out
}

drm_pair_logdiffexp <- function(x, y) {
  ifelse(x > y, x + log1p(-exp(y - x)), -Inf)
}

drm_pair_nbinom2_interval_log_prob <- function(alpha, components) {
  endpoints <- drm_pair_nbinom2_endpoints(
    components$nbinom2_y,
    components$nbinom2_mu,
    components$nbinom2_sigma
  )
  eta <- 0.999999 * tanh(alpha)
  z <- (components$gaussian_y - components$gaussian_mu) /
    components$gaussian_sigma
  s <- sqrt(1 - eta^2)
  lower <- (endpoints$lower - eta * z) / s
  upper <- (endpoints$upper - eta * z) / s
  branch <- ifelse(upper <= 0, "lower", ifelse(lower >= 0, "upper", "straddle"))
  log_probability <- ifelse(
    branch == "upper",
    drm_pair_logdiffexp(
      stats::pnorm(lower, lower.tail = FALSE, log.p = TRUE),
      stats::pnorm(upper, lower.tail = FALSE, log.p = TRUE)
    ),
    drm_pair_logdiffexp(
      stats::pnorm(upper, log.p = TRUE),
      stats::pnorm(lower, log.p = TRUE)
    )
  )
  list(log_probability = log_probability, branch = branch, endpoints = endpoints)
}

drm_pair_gaussian_nbinom2_loglik <- function(alpha, components) {
  interval <- tryCatch(
    drm_pair_nbinom2_interval_log_prob(alpha, components),
    error = function(...) NULL
  )
  if (is.null(interval) || any(!is.finite(interval$log_probability))) {
    return(-Inf)
  }
  sum(
    stats::dnorm(
      components$gaussian_y,
      mean = components$gaussian_mu,
      sd = components$gaussian_sigma,
      log = TRUE
    ) + interval$log_probability
  )
}

drm_pair_gaussian_nbinom2_conditional_prob <- function(
  z,
  y,
  mu,
  sigma,
  eta
) {
  components <- list(
    gaussian_y = z,
    gaussian_mu = rep.int(0, length(z)),
    gaussian_sigma = rep.int(1, length(z)),
    nbinom2_y = y,
    nbinom2_mu = mu,
    nbinom2_sigma = sigma
  )
  exp(drm_pair_nbinom2_interval_log_prob(atanh(eta / 0.999999), components)$log_probability)
}

drm_pair_bernoulli_nbinom2_rectangle_probability <- function(
  binary_y, binary_p, nbinom2_y, nbinom2_mu, nbinom2_sigma, eta,
  integration_rel_tol = 5e-3, integration_abs_tol = 1e-12
) {
  fail <- function(reason, message = NA_character_, integration_error = NA_real_,
                   relative_integration_error = NA_real_) {
    list(probability = NA_real_, log_probability = NA_real_, status = reason,
      message = message, integration_error = integration_error,
      relative_integration_error = relative_integration_error,
      integration_rel_tol = integration_rel_tol,
      integration_abs_tol = integration_abs_tol, branch = NA_character_)
  }
  if (length(binary_y) != 1L || !binary_y %in% c(0, 1) ||
      !is.finite(binary_p) || binary_p <= 0 || binary_p >= 1 ||
      !is.finite(eta) || abs(eta) >= 1 ||
      !is.finite(integration_rel_tol) || integration_rel_tol <= 0 ||
      !is.finite(integration_abs_tol) || integration_abs_tol <= 0) {
    return(fail("invalid_input"))
  }
  endpoints <- tryCatch(
    drm_pair_nbinom2_endpoints(nbinom2_y, nbinom2_mu, nbinom2_sigma),
    error = function(e) e
  )
  if (inherits(endpoints, "error")) {
    return(fail("endpoint_failure", conditionMessage(endpoints)))
  }
  if (identical(eta, 0)) {
    probability <- stats::dbinom(binary_y, 1, binary_p) * stats::dnbinom(
      nbinom2_y, size = drm_nbinom2_size(nbinom2_sigma), mu = nbinom2_mu
    )
    return(list(probability = probability, log_probability = log(probability),
      status = "ok", message = NA_character_, integration_error = 0,
      relative_integration_error = 0, integration_rel_tol = integration_rel_tol,
      integration_abs_tol = integration_abs_tol,
      branch = "factorized", endpoints = endpoints))
  }
  threshold <- stats::qnorm(binary_p, lower.tail = FALSE)
  limits <- if (binary_y == 0) c(-Inf, threshold) else c(threshold, Inf)
  s <- sqrt(1 - eta^2)
  integrand <- function(z) {
    lower <- (endpoints$lower - eta * z) / s
    upper <- (endpoints$upper - eta * z) / s
    branch <- ifelse(upper <= 0, "lower", ifelse(lower >= 0, "upper", "straddle"))
    log_mass <- ifelse(branch == "upper",
      drm_pair_logdiffexp(stats::pnorm(lower, lower.tail = FALSE, log.p = TRUE),
        stats::pnorm(upper, lower.tail = FALSE, log.p = TRUE)),
      drm_pair_logdiffexp(stats::pnorm(upper, log.p = TRUE),
        stats::pnorm(lower, log.p = TRUE)))
    exp(stats::dnorm(z, log = TRUE) + log_mass)
  }
  integral <- tryCatch(stats::integrate(integrand, lower = limits[[1L]],
    upper = limits[[2L]], subdivisions = 200L, rel.tol = 1e-9),
    error = function(e) e)
  if (inherits(integral, "error") || !is.finite(integral$value) ||
      !is.finite(integral$abs.error) || integral$value <= 0) {
    return(fail("integration_failure", if (inherits(integral, "error")) conditionMessage(integral) else NA_character_))
  }
  if (integral$abs.error > max(
    integration_abs_tol,
    integration_rel_tol * integral$value
  )) {
    return(fail("integration_error_exceeds_tolerance",
      integration_error = integral$abs.error,
      relative_integration_error = integral$abs.error / integral$value))
  }
  midpoint <- (endpoints$lower + endpoints$upper) / 2
  branch <- if (midpoint <= 0) "lower" else if (midpoint >= 0) "upper" else "straddle"
  list(probability = integral$value, log_probability = log(integral$value),
    status = "ok", message = integral$message, integration_error = integral$abs.error,
    relative_integration_error = integral$abs.error / integral$value,
    integration_rel_tol = integration_rel_tol, integration_abs_tol = integration_abs_tol,
    branch = branch, endpoints = endpoints)
}

drm_pair_bernoulli_nbinom2_probabilities <- function(alpha, components) {
  eta <- 0.999999 * tanh(alpha)
  results <- lapply(seq_along(components$binary_y), function(i) {
    drm_pair_bernoulli_nbinom2_rectangle_probability(
      components$binary_y[[i]], components$binary_p[[i]],
      components$nbinom2_y[[i]], components$nbinom2_mu[[i]],
      components$nbinom2_sigma[[i]], eta
    )
  })
  list(
    log_probability = vapply(results, `[[`, numeric(1L), "log_probability"),
    status = vapply(results, `[[`, character(1L), "status"),
    integration_error = vapply(results, `[[`, numeric(1L), "integration_error"),
    branch = vapply(results, `[[`, character(1L), "branch"),
    results = results
  )
}

drm_pair_bernoulli_nbinom2_loglik <- function(alpha, components) {
  probabilities <- drm_pair_bernoulli_nbinom2_probabilities(alpha, components)
  if (any(probabilities$status != "ok") || any(!is.finite(probabilities$log_probability))) {
    return(-Inf)
  }
  sum(probabilities$log_probability)
}

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
#' either margin. The reviewed Arc 6 slices implement fixed-effect Gaussian
#' margins paired with literal Bernoulli `binomial(link = "logit")` or ordinary
#' `nbinom2()` margins, literal Bernoulli paired with ordinary `nbinom2()`,
#' two literal Bernoulli margins, and two ordinary `nbinom2()` margins, on the
#' same complete analysis rows.
#'
#' The fitted parameter `eta` is a Gaussian-copula latent-normal association.
#' It is neither [rho12()], an observed-scale correlation, nor [corpairs()].
#' The [corpair()] formula marker is a distinct interface.
#' The stage-2 Hessian treats the margins as fixed and is not used for
#' uncertainty. For every admitted pair route, [vcov()] and [confint()] instead
#' use a two-stage Godambe covariance that propagates fitted-margin uncertainty
#' when the fit-specific calculation succeeds. These alpha-scale routes are
#' interval-feasible. The retained Bernoulli x ordinary-NB2 intercept campaign
#' supports the stronger inference-ready-with-caveats tier. Intercept-only
#' associations also expose bounded eta intervals through
#' `confint(object, type = "eta")`; [predict.drm_pair_association()] supplies
#' delta-method eta standard errors and pointwise transformed intervals.
#' Profiles remain unavailable.
#'
#' @param fit_1,fit_2 Two fitted `drmTMB` marginal models. They must use the
#'   identical complete analysis data, in the same order.
#' @param kernel A named association kernel. Arc 6 accepts only
#'   `latent_normal()`.
#' @param association Association formula. Most Arc 6 pair classes accept only
#'   `~ 1`. The beta Bernoulli x ordinary-NB2 route accepts an intercept-bearing
#'   fixed-effect formula, including multiple predictors, factors,
#'   interactions, and explicit transformations. Random effects, offsets,
#'   missing values, aliased columns, and `.` expansion are not supported.
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
#' sqrt(diag(vcov(assoc)))
#' confint(assoc)
#' confint(assoc, type = "eta")
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
  } else if (identical(model_types, c("nbinom2", "nbinom2"))) {
    "nbinom2_nbinom2"
  } else {
    NULL
  }
  if (is.null(pair_class)) {
    cli::cli_abort(c(
      "Arc 6 requires one reviewed pair class, including ordinary {.code nbinom2()} where applicable, or two literal {.code binomial()} fits.",
      i = "Other pair classes require their own Arc 6 review."
    ))
  }
  association_design <- drm_pair_association_design(
    association, fit_1$data, pair_class
  )

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
  } else if (identical(pair_class, "nbinom2_nbinom2")) {
    drm_pair_validate_nbinom2(fit_1)
    drm_pair_validate_nbinom2(fit_2)
    nbinom2_mu_1 <- stats::predict(fit_1, dpar = "mu", type = "response")
    nbinom2_sigma_1 <- stats::predict(fit_1, dpar = "sigma", type = "response")
    nbinom2_mu_2 <- stats::predict(fit_2, dpar = "mu", type = "response")
    nbinom2_sigma_2 <- stats::predict(fit_2, dpar = "sigma", type = "response")
    drm_pair_validate_nbinom2_components(fit_1$model$y, nbinom2_mu_1, nbinom2_sigma_1)
    drm_pair_validate_nbinom2_components(fit_2$model$y, nbinom2_mu_2, nbinom2_sigma_2)
    list(pair_class = pair_class, descriptor = descriptor,
      nbinom2_y_1 = fit_1$model$y, nbinom2_mu_1 = nbinom2_mu_1,
      nbinom2_sigma_1 = nbinom2_sigma_1,
      nbinom2_y_2 = fit_2$model$y, nbinom2_mu_2 = nbinom2_mu_2,
      nbinom2_sigma_2 = nbinom2_sigma_2)
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
  fit_result <- drm_pair_fit_eta(components, association_design)
  snapshot_1 <- drm_pair_margin_snapshot(fit_1)
  snapshot_2 <- drm_pair_margin_snapshot(fit_2)

  response_names <- c(
    fit_1 = drm_pair_response_name(fit_1),
    fit_2 = drm_pair_response_name(fit_2)
  )
  margin_order <- if (identical(pair_class, "bernoulli_bernoulli")) {
    c(fit_1 = "bernoulli_1", fit_2 = "bernoulli_2")
  } else if (identical(pair_class, "nbinom2_nbinom2")) {
    c(fit_1 = "nbinom2_1", fit_2 = "nbinom2_2")
  } else if (identical(pair_class, "bernoulli_nbinom2")) {
    c(fit_1 = if (model_types[[1L]] == "binomial") "bernoulli" else "nbinom2",
      fit_2 = if (model_types[[2L]] == "binomial") "bernoulli" else "nbinom2")
  } else {
    pair_role <- if (identical(pair_class, "gaussian_bernoulli")) "bernoulli" else "nbinom2"
    c(fit_1 = if (model_types[[1L]] == "gaussian") "gaussian" else pair_role,
      fit_2 = if (model_types[[2L]] == "gaussian") "gaussian" else pair_role)
  }

  out <- structure(
    list(
      call = match.call(),
      kernel = kernel,
      association = association,
      status = fit_result$status,
      eta = fit_result$eta,
      eta_internal = fit_result$eta_internal,
      alpha = fit_result$alpha,
      association_coefficients = fit_result$coefficients,
      association_design = association_design,
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
  out$alpha_inference <- drm_pair_prepare_alpha_inference(
    fit_1 = fit_1,
    fit_2 = fit_2,
    association_fit = out
  )
  out
}

#' Fit two margins and construct a frozen-margin association in one call
#'
#' `biv_associate()` is the convenience front end for the reviewed Arc 6
#' frozen-margin route. It fits two univariate margins to the supplied data and
#' then calls [associate_pairs()] without refitting either margin. It is one R
#' call, but it is not a jointly fitted bivariate model: stage 2 treats the fitted
#' marginal parameters as fixed and estimates only the latent-normal
#' association `eta`.
#'
#' The two formulas must be univariate [bf()] or [drm_formula()] objects, and
#' `family` must be a two-element list. The supplied `data` must already be the
#' same complete paired analysis data for both margins. If the two marginal fits
#' retain different rows, the constructor fails rather than silently comparing
#' different individuals.
#'
#' @param formula_1,formula_2 Univariate `drm_formula` objects for the first
#'   and second response margins.
#' @param family A two-element list of marginal family objects.
#' @param data A data frame containing both responses and every predictor used
#'   by either margin.
#' @param kernel Association kernel. Arc 6 accepts only [latent_normal()].
#' @param association Association formula. Most Arc 6 pair classes accept only
#'   `~ 1`, which estimates one constant association parameter. The beta
#'   Bernoulli x ordinary-NB2 route accepts an intercept-bearing fixed-effect
#'   model-matrix formula, including multiple predictors, factors,
#'   interactions, and explicit transformations. Alpha-scale standard errors
#'   and Wald intervals are available for every admitted association formula
#'   when its fit-specific Godambe covariance diagnostics pass.
#' @param control_1,control_2 Optional control lists passed to the corresponding
#'   marginal [drmTMB()] fits.
#'
#' @return A `drm_pair_association` object that retains frozen snapshots of both
#'   fitted margins. [association()] returns the point estimate unless the
#'   numerical diagnostic is boundary-unresolved; a near-boundary status remains
#'   flagged. Admitted routes have alpha-scale [vcov()] and [confint()] methods
#'   when the fit-specific Godambe covariance succeeds. Intercept-only routes
#'   also have bounded eta intervals; [predict.drm_pair_association()] returns
#'   eta-scale standard errors and pointwise confidence intervals. No profile
#'   is available.
#' @export
#'
#' @examples
#' set.seed(20260725)
#' dat <- data.frame(x = rnorm(80))
#' z_continuous <- rnorm(80)
#' z_binary <- 0.35 * z_continuous + sqrt(1 - 0.35^2) * rnorm(80)
#' dat$trait_continuous <- 0.2 + 0.5 * dat$x + z_continuous
#' dat$trait_binary <- as.integer(z_binary > qnorm(0.4))
#'
#' assoc <- biv_associate(
#'   bf(mu = trait_continuous ~ x, sigma = ~ 1),
#'   bf(mu = trait_binary ~ x),
#'   family = list(gaussian(), binomial()), data = dat
#' )
#' association(assoc)
#' sqrt(diag(vcov(assoc)))
#' confint(assoc)
#' confint(assoc, type = "eta")
biv_associate <- function(
  formula_1,
  formula_2,
  family,
  data,
  kernel = latent_normal(),
  association = ~1,
  control_1 = list(),
  control_2 = list()
) {
  if (!inherits(formula_1, "drm_formula") || !inherits(formula_2, "drm_formula")) {
    cli::cli_abort(
      "{.arg formula_1} and {.arg formula_2} must be created with {.fn bf} or {.fn drm_formula}."
    )
  }
  if (!is.list(family) || length(family) != 2L) {
    cli::cli_abort(
      "{.arg family} must be a two-element list, for example {.code list(gaussian(), binomial())}."
    )
  }
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame.")
  }

  fit_1 <- drmTMB(
    formula = formula_1, family = family[[1L]], data = data,
    control = control_1
  )
  fit_2 <- drmTMB(
    formula = formula_2, family = family[[2L]], data = data,
    control = control_2
  )
  out <- associate_pairs(
    fit_1, fit_2, kernel = kernel, association = association
  )
  out$call <- match.call()
  out$stage <- "two-stage frozen margins"
  out
}

#' Extract a pair association estimate
#'
#' @param object A `drm_pair_association` object.
#' @param type For a constant association, the default `"coefficient"` returns
#'   the usual single `eta`. For a covariate-varying beta association,
#'   `"coefficient"` returns the association-link coefficients and `"fitted"`
#'   returns the frozen-row latent-normal associations.
#' @param ... Reserved for future extractor options.
#'
#' @return For a constant association, a one-row data frame with the
#'   latent-normal association and diagnostic status. For a beta association
#'   formula, a coefficient table or a frozen-row `eta` table according to
#'   `type`. The separate [vcov()] and [confint()] methods supply alpha-scale
#'   uncertainty for admitted association routes whose fit-specific Godambe
#'   covariance diagnostics pass; `confint(object, type = "eta")` supplies the
#'   transformed interval for a constant association.
#' @export
association <- function(object, ...) {
  UseMethod("association")
}

#' @rdname association
#' @export
association.drm_pair_association <- function(object, type = c("coefficient", "fitted"), ...) {
  type <- match.arg(type)
  if (identical(object$status, "boundary_unresolved")) {
    cli::cli_abort(c(
      "The association maximum is boundary-unresolved.",
      i = "Inspect {.code object$diagnostics}; Arc 6 does not return a public point estimate for this case."
    ))
  }
  if (identical(type, "fitted")) {
    return(data.frame(
      row = seq_along(object$eta_internal),
      association_link = object$alpha,
      eta = object$eta_internal,
      status = object$status,
      stringsAsFactors = FALSE
    ))
  }
  if (length(object$association_coefficients) > 1L) {
    return(data.frame(
      term = names(object$association_coefficients),
      association_link = unname(object$association_coefficients),
      status = object$status,
      boundary = object$diagnostics$near_boundary,
      stringsAsFactors = FALSE
    ))
  }
  data.frame(kernel = object$kernel$name, estimand = "latent-normal association",
    eta = object$eta, status = object$status,
    boundary = object$diagnostics$near_boundary, stringsAsFactors = FALSE)
}

#' @export
print.drm_pair_association <- function(x, ...) {
  cli::cli_text("<drmTMB frozen-margin pair association>")
  cli::cli_text("  kernel: {x$kernel$name}")
  cli::cli_text("  status: {x$status}")
  if (!identical(x$status, "boundary_unresolved")) {
    if (length(x$association_coefficients) == 1L) {
      cli::cli_text("  eta: {format(x$eta, digits = 4)}")
    } else {
      cli::cli_text("  association coefficients: {length(x$association_coefficients)}; fitted eta range: {format(range(x$eta_internal), digits = 4)}")
    }
  }
  if (identical(x$alpha_inference$status, "available")) {
    cli::cli_text("  uncertainty: alpha via vcov()/confint(); eta via confint(type = \"eta\")/predict()")
  } else {
    cli::cli_text("  alpha uncertainty: unavailable for this route or fit")
  }
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
  } else if ("eta" %in% names(x$association)) {
    cli::cli_text("  eta: {format(x$association$eta, digits = 4)}")
  } else {
    cli::cli_text("  association coefficients: {nrow(x$association)}")
  }
  status <- if (is.null(x$association)) {
    "boundary_unresolved"
  } else {
    x$association$status[[1L]]
  }
  cli::cli_text("  status: {status}")
  cli::cli_text("  use vcov() / confint() for an admitted alpha interval")
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
  if ("nbinom2_1" %in% object$components$descriptor$roles) {
    by_role$nbinom2_1 <- object$components$nbinom2_mu_1
  }
  if ("nbinom2_2" %in% object$components$descriptor$roles) {
    by_role$nbinom2_2 <- object$components$nbinom2_mu_2
  }
  out <- data.frame(
    by_role[[object$margin_order[["fit_1"]]]],
    by_role[[object$margin_order[["fit_2"]]]],
    check.names = FALSE
  )
  names(out) <- unname(object$response_names)
  out
}

#' Predict a frozen-margin pair association
#'
#' With no `newdata` or `type`, this method preserves the historical
#' `fitted()`-style output of the two frozen margins. `type = "link"` returns
#' the association linear predictor and `type = "eta"` returns its bounded
#' latent-normal association transform; `type = "response"` is a compatibility
#' alias for `"eta"`. The beta Bernoulli x ordinary-NB2 route also admits
#' new-data prediction from its fixed-effect association formula.
#'
#' @param object A `drm_pair_association` object.
#' @param newdata Optional data frame for beta Bernoulli x ordinary-NB2
#'   association prediction. Its terms, factor levels, contrasts, and columns
#'   must match the fitted association formula.
#' @param type Prediction scale: `"link"` for `X_A %*% alpha` or `"eta"` for
#'   `0.999999 * tanh(X_A %*% alpha)`. `"response"` is an alias for `"eta"`.
#'   Omit `type` together with `newdata` to retain the historical frozen-margin
#'   fitted output.
#' @param se.fit Logical; return pointwise standard errors on the requested
#'   scale. Eta-scale standard errors use the delta method.
#' @param interval `"none"` or `"confidence"`. Confidence limits are
#'   pointwise link-scale Wald limits transformed monotonically to eta when
#'   `type = "eta"`.
#' @param level Confidence level in `(0, 1)`.
#' @param ... Must be empty.
#' @return With omitted `type` and `newdata`, the frozen marginal fitted values.
#'   Without uncertainty, a numeric association prediction on the requested
#'   scale. With `interval = "confidence"`, a matrix with `fit`, `lwr`, and
#'   `upr` columns. With `se.fit = TRUE`, a list containing `fit` and `se.fit`;
#'   `fit` is the three-column matrix when an interval is requested.
#' @seealso [vcov.drm_pair_association()], [confint.drm_pair_association()]
#' @export
#' @importFrom stats fitted
#' @examples
#' \dontrun{
#' set.seed(20260801)
#' n <- 160
#' dat <- data.frame(
#'   x1 = seq(-1.2, 1.2, length.out = n),
#'   x2 = rep(c(-0.5, 0.5), length.out = n)
#' )
#' z_binary <- rnorm(n)
#' eta <- 0.999999 * tanh(-0.1 + 0.4 * dat$x1 - 0.2 * dat$x2)
#' z_count <- eta * z_binary + sqrt(1 - eta^2) * rnorm(n)
#' dat$binary <- as.integer(
#'   z_binary > qnorm(plogis(-0.2 + 0.3 * dat$x1), lower.tail = FALSE)
#' )
#' dat$count <- qnbinom(
#'   pnorm(z_count), mu = exp(0.5 + 0.2 * dat$x2), size = 4
#' )
#' binary_fit <- drmTMB(bf(mu = binary ~ x1), binomial(), dat)
#' count_fit <- drmTMB(
#'   bf(mu = count ~ x2, sigma = ~ 1), nbinom2(), dat
#' )
#' assoc <- associate_pairs(
#'   binary_fit, count_fit,
#'   kernel = latent_normal(), association = ~ x1 + x2
#' )
#' new_dat <- data.frame(x1 = c(-1, 0, 1), x2 = 0)
#' eta_prediction <- predict(
#'   assoc,
#'   newdata = new_dat,
#'   type = "eta",
#'   se.fit = TRUE,
#'   interval = "confidence"
#' )
#' eta_prediction$fit
#' eta_prediction$se.fit
#' }
predict.drm_pair_association <- function(
  object,
  newdata = NULL,
  type = NULL,
  se.fit = FALSE,
  interval = c("none", "confidence"),
  level = 0.95,
  ...
) {
  dots <- list(...)
  if (length(dots)) {
    cli::cli_abort("Unused prediction argument{?s}: {.arg {names(dots)}}.")
  }
  if (length(se.fit) != 1L || is.na(se.fit) || !is.logical(se.fit)) {
    cli::cli_abort("{.arg se.fit} must be one non-missing logical value.")
  }
  interval <- match.arg(interval)
  if (length(level) != 1L || !is.finite(level) || level <= 0 || level >= 1) {
    cli::cli_abort("{.arg level} must be one finite number strictly between zero and one.")
  }
  uncertainty_requested <- isTRUE(se.fit) || identical(interval, "confidence")
  if (is.null(type) && is.null(newdata) && !uncertainty_requested) {
    return(fitted(object))
  }
  if (is.null(type) && is.null(newdata)) {
    cli::cli_abort(c(
      "Choose an association scale before requesting prediction uncertainty.",
      i = "Use {.code type = \"eta\"} for bounded latent-association estimates."
    ))
  }
  if (is.null(type)) type <- "eta"
  type <- match.arg(type, c("link", "eta", "response"))
  if (identical(object$status, "boundary_unresolved")) {
    cli::cli_abort("Cannot predict from a boundary-unresolved association fit.")
  }
  if (!is.null(newdata) &&
      !identical(object$components$pair_class, "bernoulli_nbinom2")) {
    cli::cli_abort(c(
      "Arc 6 association predictions are defined only for frozen analysis rows.",
      i = "New-data association prediction needs a separate validated Arc."
    ))
  }
  design <- if (is.null(newdata)) object$association_design$matrix else
    drm_pair_association_newdata_design(object, newdata)
  coefficients <- object$association_coefficients
  if (length(coefficients) != ncol(design)) {
    cli::cli_abort("Association prediction design does not match the fitted coefficients.")
  }
  link <- as.vector(design %*% coefficients)
  eta_scale <- type %in% c("eta", "response")
  estimate <- if (eta_scale) 0.999999 * tanh(link) else link
  if (!uncertainty_requested) return(estimate)

  inference <- drm_pair_public_alpha_inference(object)
  covariance <- inference$covariance
  if (!identical(dim(covariance), c(ncol(design), ncol(design)))) {
    cli::cli_abort("Association prediction design does not match the stored alpha covariance.")
  }
  link_variance <- rowSums((design %*% covariance) * design)
  if (any(!is.finite(link_variance)) || any(link_variance <= 0)) {
    cli::cli_abort(c(
      "The derived association prediction variance is invalid.",
      i = "No standard error or placeholder interval is returned.",
      i = "Inspect {.code object$diagnostics}; verify predictor variation and design rank, then simplify or refit the association model."
    ))
  }
  link_se <- sqrt(link_variance)
  estimate_se <- if (eta_scale) {
    0.999999 * (1 - tanh(link)^2) * link_se
  } else {
    link_se
  }
  if (any(!is.finite(estimate_se)) || any(estimate_se <= 0)) {
    cli::cli_abort(c(
      "The derived association prediction standard error is invalid.",
      i = "No placeholder uncertainty is returned.",
      i = "Inspect {.code object$diagnostics}, then simplify or refit the association model."
    ))
  }
  drm_pair_warn_alpha_inference(object)

  fit <- estimate
  if (identical(interval, "confidence")) {
    critical <- stats::qnorm(1 - (1 - level) / 2)
    link_lwr <- link - critical * link_se
    link_upr <- link + critical * link_se
    limits <- if (eta_scale) {
      cbind(
        lwr = 0.999999 * tanh(link_lwr),
        upr = 0.999999 * tanh(link_upr)
      )
    } else {
      cbind(lwr = link_lwr, upr = link_upr)
    }
    fit <- cbind(fit = estimate, limits)
  }
  if (isTRUE(se.fit)) {
    return(list(fit = fit, se.fit = estimate_se))
  }
  fit
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
    n <- if (identical(object$components$pair_class, "nbinom2_nbinom2")) {
      length(object$components$nbinom2_y_1)
    } else if (!is.null(object$components$binary_y)) {
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
    } else if (identical(object$components$pair_class, "nbinom2_nbinom2")) {
      by_role$nbinom2_1 <- drm_pair_nbinom2_quantile_from_normal(z_1,
        object$components$nbinom2_mu_1, object$components$nbinom2_sigma_1)
      by_role$nbinom2_2 <- drm_pair_nbinom2_quantile_from_normal(z_2,
        object$components$nbinom2_mu_2, object$components$nbinom2_sigma_2)
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

#' Alpha-scale covariance for a frozen-margin association
#'
#' Returns the association-coefficient block of the two-stage Godambe
#' covariance for an admitted fixed-effect complete-pair association. Standard
#' errors are `sqrt(diag(vcov(object)))`. The covariance and standard errors are
#' on the unbounded association-link (`alpha`) scale, not the bounded latent
#' association (`eta`) scale. The method warns when coverage is uncalibrated or
#' the fit lies outside the retained coverage domain, and errors rather than
#' manufacturing a covariance when fit-specific diagnostics fail.
#'
#' @param object A fitted `drm_pair_association` object.
#' @param ... Reserved for future options.
#' @return A named symmetric covariance matrix for the alpha coefficients.
#' @seealso [confint.drm_pair_association()]
#' @export
vcov.drm_pair_association <- function(object, ...) {
  inference <- drm_pair_public_alpha_inference(object)
  drm_pair_warn_alpha_inference(object)
  inference$covariance
}

#' @export
profile.drm_pair_association <- function(fitted, ...) {
  cli::cli_abort(
    "Profile inference is unavailable for Arc 6 frozen-margin association estimates."
  )
}

#' Confidence intervals for a frozen-margin association
#'
#' For admitted fixed-effect complete-pair association routes, [vcov()] returns
#' the association-coefficient block of the two-stage Godambe sandwich and this
#' method returns corresponding Wald intervals. `type = "alpha"` returns the
#' coefficient-scale intervals. For an intercept-only association,
#' `type = "eta"` monotonically transforms its link-scale limits to the bounded
#' latent-association scale. A covariate-varying association has no single eta;
#' use [predict.drm_pair_association()] with `newdata` for row-specific eta
#' uncertainty. Every route is interval-feasible when its fit-specific
#' covariance diagnostics pass. Coverage evidence currently promotes only the
#' retained Bernoulli x ordinary-NB2 intercept domain to inference-ready with
#' caveats; other routes receive an experimental-coverage warning.
#'
#' @param object A fitted `drm_pair_association` object.
#' @param parm Association coefficients to include. `NULL` (the default) or
#'   `"alpha"` selects all association coefficients; a numeric or character
#'   subset may also be supplied.
#' @param level Confidence level in `(0, 1)`.
#' @param type `"alpha"` for coefficient-scale intervals or `"eta"` for the
#'   bounded latent association of an intercept-only model.
#' @param ... Reserved for future options.
#' @return A matrix with Wald confidence limits on the requested scale.
#' @seealso [vcov()], [predict.drm_pair_association()]
#' @export
#' @examples
#' \dontrun{
#' set.seed(20260801)
#' dat <- data.frame(x = rnorm(100))
#' z_1 <- rnorm(100)
#' z_2 <- 0.35 * z_1 + sqrt(1 - 0.35^2) * rnorm(100)
#' dat$continuous <- 0.2 + 0.4 * dat$x + z_1
#' dat$binary <- as.integer(z_2 > qnorm(0.55))
#' assoc <- biv_associate(
#'   bf(mu = continuous ~ x, sigma = ~ 1),
#'   bf(mu = binary ~ x),
#'   family = list(gaussian(), binomial()), data = dat
#' )
#' confint(assoc, type = "eta")
#' }
confint.drm_pair_association <- function(
  object,
  parm = NULL,
  level = 0.95,
  type = c("alpha", "eta"),
  ...
) {
  type <- match.arg(type)
  if (length(level) != 1L || !is.finite(level) || level <= 0 || level >= 1) {
    cli::cli_abort("{.arg level} must be one finite number strictly between zero and one.")
  }
  if (identical(type, "eta")) {
    if (isTRUE(object$association_design$varying)) {
      cli::cli_abort(c(
        "A covariate-varying association has no single eta confidence interval.",
        i = "Use {.code predict(object, newdata = ..., type = \"eta\", se.fit = TRUE, interval = \"confidence\")} for row-specific estimates."
      ))
    }
    if (!is.null(parm) &&
        !identical(parm, "eta") &&
        !(is.numeric(parm) && length(parm) == 1L && isTRUE(parm == 1))) {
      cli::cli_abort("For {.code type = \"eta\"}, {.arg parm} must be NULL, {.val eta}, or 1.")
    }
    prediction <- predict(
      object,
      type = "eta",
      se.fit = FALSE,
      interval = "confidence",
      level = level
    )
    limits <- matrix(
      prediction[1L, c("lwr", "upr")],
      nrow = 1L,
      dimnames = list(
        "eta",
        paste0(format(100 * c((1 - level) / 2, 1 - (1 - level) / 2), trim = TRUE), " %")
      )
    )
    return(limits)
  }
  inference <- drm_pair_public_alpha_inference(object)
  coefficient_names <- rownames(inference$covariance)
  if (is.null(parm) || identical(parm, "alpha")) {
    index <- seq_along(coefficient_names)
  } else if (is.numeric(parm)) {
    index <- as.integer(parm)
    if (any(!is.finite(parm)) || any(index != parm) || any(index < 1L) ||
        any(index > length(coefficient_names))) {
      cli::cli_abort("Numeric {.arg parm} values must index the available alpha coefficients.")
    }
  } else if (is.character(parm)) {
    raw_terms <- names(object$association_coefficients)
    index <- match(parm, coefficient_names)
    missing <- is.na(index)
    if (any(missing) && !is.null(raw_terms)) {
      index[missing] <- match(parm[missing], raw_terms)
    }
    if (anyNA(index)) {
      cli::cli_abort(c(
        "Unknown association coefficient in {.arg parm}.",
        i = "Available alpha coefficients: {.val {coefficient_names}}.",
        i = "For a constant bounded association interval, use {.code confint(object, type = \"eta\")} without an alpha {.arg parm}."
      ))
    }
  } else {
    cli::cli_abort("{.arg parm} must be NULL, numeric, or character.")
  }
  drm_pair_warn_alpha_inference(object)
  alpha <- unname(object$association_coefficients[index])
  se <- inference$se[index]
  tail <- (1 - level) / 2
  probabilities <- c(tail, 1 - tail)
  limits <- cbind(
    alpha + stats::qnorm(probabilities[[1L]]) * se,
    alpha + stats::qnorm(probabilities[[2L]]) * se
  )
  dimnames(limits) <- list(
    coefficient_names[index],
    paste0(format(100 * probabilities, trim = TRUE), " %")
  )
  limits
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
    nbinom2_nbinom2 = c("nbinom2_1", "nbinom2_2"),
    NULL
  )
  if (is.null(roles)) {
    cli::cli_abort("Unsupported frozen-margin pair descriptor.")
  }
  structure(list(version = 1L, pair_class = pair_class, roles = roles),
    class = "drm_pair_descriptor")
}

drm_pair_association_design <- function(association, data, pair_class) {
  if (!inherits(association, "formula")) {
    cli::cli_abort("{.arg association} must be a formula.")
  }
  if (length(association) != 2L) {
    cli::cli_abort("{.arg association} must be a one-sided formula.")
  }
  if ("." %in% all.names(association, functions = TRUE)) {
    cli::cli_abort(c(
      "The beta Bernoulli x ordinary-NB2 association model accepts fixed-effect model-matrix terms only.",
      i = "Do not use {.code .}, offsets, random-effect bars, or {.code mi()} in {.arg association}."
    ))
  }
  missing_variables <- setdiff(all.vars(association), names(data))
  if (length(missing_variables)) {
    cli::cli_abort(c(
      "Association predictors must be columns of the frozen analysis data.",
      i = "Missing column{?s}: {missing_variables}."
    ))
  }
  association_terms <- stats::terms(association)
  if (attr(association_terms, "intercept") != 1L) {
    cli::cli_abort("{.arg association} must include an intercept.")
  }
  labels <- attr(association_terms, "term.labels")
  if (!length(labels)) {
    matrix <- matrix(1, nrow(data), 1L, dimnames = list(NULL, "(Intercept)"))
    return(list(
      matrix = matrix, terms = association_terms, varying = FALSE,
      contrasts = NULL, xlevels = list(), column_names = colnames(matrix),
      fingerprint = drm_pair_fingerprint(matrix)
    ))
  }
  if (!identical(pair_class, "bernoulli_nbinom2")) {
    cli::cli_abort(c(
      "This Arc 6 association regression is available only for literal Bernoulli x ordinary-NB2 pairs.",
      i = "Use {.code association = ~ 1} for the other reviewed pair classes."
    ))
  }
  if (!is.null(attr(association_terms, "offset")) ||
      any(grepl("\\|", labels)) ||
      any(grepl("(^|[^[:alnum:]_])mi\\s*\\(", labels))) {
    cli::cli_abort(c(
      "The beta Bernoulli x ordinary-NB2 association model accepts fixed-effect model-matrix terms only.",
      i = "Do not use {.code .}, offsets, random-effect bars, or {.code mi()} in {.arg association}."
    ))
  }
  model_frame <- tryCatch(
    stats::model.frame(
      association_terms, data = data, na.action = stats::na.fail,
      drop.unused.levels = FALSE
    ),
    error = function(error) cli::cli_abort(
      "Cannot construct the complete association model frame: {conditionMessage(error)}"
    )
  )
  association_terms <- stats::terms(model_frame)
  matrix <- tryCatch(stats::model.matrix(association_terms, data = model_frame),
    error = function(error) cli::cli_abort("Cannot construct the association design: {conditionMessage(error)}"))
  if (nrow(matrix) != nrow(data) || !is.numeric(matrix) ||
      any(!is.finite(matrix))) {
    cli::cli_abort(c(
      "The association design must retain every paired analysis row and contain finite numeric columns.",
      i = "Remove missing or non-finite association covariates before fitting."
    ))
  }
  if (qr(matrix)$rank != ncol(matrix)) {
    cli::cli_abort(
      "The association design is rank deficient; remove aliased association terms."
    )
  }
  list(
    matrix = matrix, terms = association_terms, varying = TRUE,
    contrasts = attr(matrix, "contrasts"),
    xlevels = stats::.getXlevels(association_terms, model_frame),
    column_names = colnames(matrix), fingerprint = drm_pair_fingerprint(matrix)
  )
}

drm_pair_association_newdata_design <- function(object, newdata) {
  if (!is.data.frame(newdata) || !nrow(newdata)) {
    cli::cli_abort("{.arg newdata} must be a non-empty data frame.")
  }
  design <- object$association_design
  if (is.null(design$terms) || is.null(design$column_names)) {
    cli::cli_abort("This association fit lacks the stored design needed for new-data prediction.")
  }
  model_frame <- tryCatch(
    stats::model.frame(
      design$terms, data = newdata, na.action = stats::na.fail,
      xlev = design$xlevels, drop.unused.levels = FALSE
    ),
    error = function(error) cli::cli_abort(
      "Cannot construct the new-data association model frame: {conditionMessage(error)}"
    )
  )
  matrix <- tryCatch(
    stats::model.matrix(
      design$terms, data = model_frame, contrasts.arg = design$contrasts
    ),
    error = function(error) cli::cli_abort(
      "Cannot construct the new-data association design: {conditionMessage(error)}"
    )
  )
  if (!is.numeric(matrix) || any(!is.finite(matrix)) ||
      !identical(colnames(matrix), design$column_names)) {
    cli::cli_abort(c(
      "The new-data association design does not match the fitted design.",
      i = "Supply every fitted predictor with the same factor levels and model-matrix columns."
    ))
  }
  matrix
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

# The logit-only restriction here is DELIBERATE (design 252 §6), not an
# oversight: it fails closed on its own fit$family$link check, independent of
# drm_family_type()'s now-wider logit/probit/cloglog admissibility guard.
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

drm_pair_fit_eta <- function(components, association_design = NULL) {
  if (is.null(association_design)) {
    association_design <- list(
      matrix = matrix(1, drm_pair_component_n(components), 1L,
        dimnames = list(NULL, "(Intercept)")),
      varying = FALSE
    )
  }
  x_association <- association_design$matrix
  loglik <- drm_pair_loglikelihood_function(components)
  linear_predictor <- function(coefficients) {
    as.vector(x_association %*% coefficients)
  }
  objective <- function(coefficients) {
    alpha <- linear_predictor(coefficients)
    if (!isTRUE(association_design$varying)) alpha <- alpha[[1L]]
    value <- loglik(alpha, components)
    if (!is.finite(value)) {
      return(.Machine$double.xmax)
    }
    -value
  }
  starts <- if (ncol(x_association) == 1L) {
    list(-1, 0, 1)
  } else {
    list(rep(0, ncol(x_association)),
      c(-0.25, rep(0, ncol(x_association) - 1L)),
      c(0.25, rep(0, ncol(x_association) - 1L)))
  }
  fits <- lapply(starts, function(start) {
    stats::nlminb(start = start, objective = objective,
      lower = rep(-8, length(start)), upper = rep(8, length(start)))
  })
  objectives <- vapply(fits, `[[`, numeric(1L), "objective")
  multistart_coefficients <- do.call(cbind, lapply(
    fits, function(fit) unname(fit$par)
  ))
  best <- fits[[which.min(objectives)]]
  coefficients <- unname(best$par)
  names(coefficients) <- colnames(x_association)
  alpha <- linear_predictor(coefficients)
  if (!isTRUE(association_design$varying)) alpha <- alpha[[1L]]
  eta_internal <- 0.999999 * tanh(alpha)
  logLik <- loglik(alpha, components)
  h <- 1e-4
  diagnostic_coordinate <- function(index) {
    lower <- coefficients
    upper <- coefficients
    lower[[index]] <- lower[[index]] - h
    upper[[index]] <- upper[[index]] + h
    if (lower[[index]] <= -8 || upper[[index]] >= 8) {
      return(c(score = NA_real_, curvature = NA_real_))
    }
    c(
      score = (objective(lower) - objective(upper)) / (2 * h),
      curvature = -(objective(upper) - 2 * objective(coefficients) + objective(lower)) / h^2
    )
  }
  score_and_curvature <- vapply(seq_along(coefficients), diagnostic_coordinate,
    numeric(2L)
  )
  if (is.null(dim(score_and_curvature))) {
    score_and_curvature <- matrix(score_and_curvature, nrow = 2L,
      dimnames = list(c("score", "curvature"), names(coefficients)))
  } else {
    colnames(score_and_curvature) <- names(coefficients)
  }
  score <- score_and_curvature["score", ]
  curvature <- score_and_curvature["curvature", ]
  near_boundary <- any(abs(eta_internal) >= 0.995)
  objective_tolerance <- 1e-7 * (1 + abs(min(objectives)))
  finite_starts <- is.finite(objectives) & objectives < .Machine$double.xmax
  multistart_disagreement <- if (isTRUE(association_design$varying)) {
    sum(finite_starts) < 2L ||
      any((objectives[finite_starts] - min(objectives[finite_starts])) > objective_tolerance) ||
      any(apply(multistart_coefficients[, finite_starts, drop = FALSE], 1L,
        function(x) max(x) - min(x) > 1e-3))
  } else {
    any(!finite_starts | (objectives - min(objectives)) > objective_tolerance) ||
      any(apply(multistart_coefficients, 1L, function(x) max(x) - min(x) > 1e-3))
  }
  convergence_failure <- !identical(best$convergence, 0L)
  weak_curvature <- any(!is.finite(curvature) | curvature >= -1e-6)
  score_failure <- any(!is.finite(score) | abs(score) > 1e-3)
  unresolved <- any(abs(coefficients) >= 7.99) ||
    !is.finite(logLik) ||
    convergence_failure ||
    multistart_disagreement ||
    weak_curvature ||
    score_failure
  interval_diagnostics <- drm_pair_interval_diagnostics(components, alpha)
  endpoint_failure <- isTRUE(interval_diagnostics$endpoint_failure)
  unresolved <- unresolved || endpoint_failure
  status <- if (unresolved) {
    "boundary_unresolved"
  } else if (near_boundary) {
    "near_boundary"
  } else {
    "interior"
  }
  list(
    status = status,
    eta = if (identical(status, "boundary_unresolved")) {
      NA_real_
    } else if (length(coefficients) == 1L) {
      eta_internal
    } else {
      NA_real_
    },
    eta_internal = eta_internal,
    alpha = alpha,
    coefficients = coefficients,
    logLik = logLik,
    diagnostics = list(
      alpha = alpha,
      eta_internal = eta_internal,
      near_boundary = near_boundary,
      boundary_unresolved = unresolved,
      optimizer_convergence = best$convergence,
      optimizer_message = best$message,
      multistart_objectives = objectives,
      multistart_alpha = multistart_coefficients,
      multistart_disagreement = multistart_disagreement,
      convergence_failure = convergence_failure,
      endpoint_failure = endpoint_failure,
      weak_curvature = weak_curvature,
      score_failure = score_failure,
      score = score,
      curvature = curvature,
      response_patterns = drm_pair_response_diagnostics(components, alpha),
      count_interval = interval_diagnostics
    )
  )
}

drm_pair_component_n <- function(components) {
  if (identical(components$pair_class, "bernoulli_bernoulli")) return(length(components$binary_1_y))
  if (identical(components$pair_class, "nbinom2_nbinom2")) return(length(components$nbinom2_y_1))
  if (!is.null(components$binary_y)) return(length(components$binary_y))
  length(components$gaussian_y)
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
  if (identical(pair_class, "nbinom2_nbinom2")) {
    return(c(
      n = length(components$nbinom2_y_1),
      zeros_1 = sum(components$nbinom2_y_1 == 0),
      zeros_2 = sum(components$nbinom2_y_2 == 0),
      min_count_1 = min(components$nbinom2_y_1),
      min_count_2 = min(components$nbinom2_y_2),
      max_count_1 = max(components$nbinom2_y_1),
      max_count_2 = max(components$nbinom2_y_2)
    ))
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
    nbinom2_nbinom2 = drm_pair_nbinom2_nbinom2_loglik,
    cli::cli_abort("Unsupported frozen-margin pair class.")
  )
}

drm_pair_interval_diagnostics <- function(components, alpha = NULL) {
  if (identical(components$pair_class, "nbinom2_nbinom2")) {
    endpoints_1 <- tryCatch(drm_pair_nbinom2_endpoints(components$nbinom2_y_1,
      components$nbinom2_mu_1, components$nbinom2_sigma_1), error = function(e) e)
    endpoints_2 <- tryCatch(drm_pair_nbinom2_endpoints(components$nbinom2_y_2,
      components$nbinom2_mu_2, components$nbinom2_sigma_2), error = function(e) e)
    if (inherits(endpoints_1, "error") || inherits(endpoints_2, "error")) {
      error <- if (inherits(endpoints_1, "error")) endpoints_1 else endpoints_2
      return(list(endpoint_failure = TRUE, endpoint_failure_message = conditionMessage(error),
        row_numerics = data.frame(row = seq_along(components$nbinom2_y_1),
          status = "endpoint_failure", integration_error = NA_real_,
          relative_integration_error = NA_real_, count_1_lower = NA_real_,
          count_1_upper = NA_real_, count_2_lower = NA_real_,
          count_2_upper = NA_real_, stringsAsFactors = FALSE)))
    }
    interval <- if (is.null(alpha)) NULL else drm_pair_nbinom2_nbinom2_probabilities(alpha, components)
    rows <- if (is.null(interval)) NULL else data.frame(row = seq_along(components$nbinom2_y_1),
      status = interval$status, integration_error = interval$integration_error,
      relative_integration_error = vapply(interval$results, `[[`, numeric(1L), "relative_integration_error"),
      count_1_lower = endpoints_1$lower, count_1_upper = endpoints_1$upper,
      count_2_lower = endpoints_2$lower, count_2_upper = endpoints_2$upper,
      stringsAsFactors = FALSE)
    return(list(endpoint_failure = FALSE, endpoint_failure_message = NA_character_,
      nbinom2_1_size_range = range(drm_nbinom2_size(components$nbinom2_sigma_1)),
      nbinom2_2_size_range = range(drm_nbinom2_size(components$nbinom2_sigma_2)),
      strict_order = all(endpoints_1$lower < endpoints_1$upper) && all(endpoints_2$lower < endpoints_2$upper),
      conditional_interval_branches = if (is.null(interval)) NULL else table(interval$branch),
      row_numerics = rows))
  }
  if (is.null(components$pair_class) ||
      !components$pair_class %in% c("gaussian_nbinom2", "bernoulli_nbinom2")) {
    return(NULL)
  }
  endpoints <- tryCatch(
    drm_pair_nbinom2_endpoints(
      components$nbinom2_y,
      components$nbinom2_mu,
      components$nbinom2_sigma
    ),
    error = function(e) e
  )
  if (inherits(endpoints, "error")) {
    n <- length(components$nbinom2_y)
    row_numerics <- if (identical(components$pair_class, "bernoulli_nbinom2")) {
      data.frame(
        row = seq_len(n), status = rep("endpoint_failure", n),
        integration_error = rep(NA_real_, n),
        relative_integration_error = rep(NA_real_, n),
        binary_threshold = stats::qnorm(
          components$binary_p, lower.tail = FALSE
        ),
        count_lower = rep(NA_real_, n), count_upper = rep(NA_real_, n),
        count_lower_tail = rep(NA_character_, n),
        count_upper_tail = rep(NA_character_, n),
        conditional_branch = rep(NA_character_, n),
        stringsAsFactors = FALSE
      )
    } else {
      NULL
    }
    return(list(
      endpoint_failure = TRUE,
      endpoint_failure_message = conditionMessage(endpoints),
      row_numerics = row_numerics
    ))
  }
  interval <- if (is.null(alpha)) NULL else if (identical(components$pair_class, "gaussian_nbinom2")) {
    drm_pair_nbinom2_interval_log_prob(alpha, components)
  } else {
    drm_pair_bernoulli_nbinom2_probabilities(alpha, components)
  }
  row_numerics <- if (identical(components$pair_class, "bernoulli_nbinom2") &&
      !is.null(interval)) {
    data.frame(
      row = seq_along(components$binary_y),
      status = interval$status,
      integration_error = interval$integration_error,
      relative_integration_error = vapply(
        interval$results, `[[`, numeric(1L), "relative_integration_error"
      ),
      binary_threshold = stats::qnorm(
        components$binary_p, lower.tail = FALSE
      ),
      count_lower = endpoints$lower,
      count_upper = endpoints$upper,
      count_lower_tail = endpoints$lower_representation,
      count_upper_tail = endpoints$upper_representation,
      conditional_branch = interval$branch,
      stringsAsFactors = FALSE
    )
  } else {
    NULL
  }
  list(
    endpoint_failure = FALSE,
    endpoint_failure_message = NA_character_,
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
    endpoint_complement_error_max = endpoints$complement_error_max,
    row_numerics = row_numerics
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
  # Integrate over the NB2 CDF interval instead of an unbounded Bernoulli
  # half-line.  If U = Phi(Z_N), then dU = phi(Z_N) dZ_N, so this is the
  # same rectangle probability while retaining a bounded integration domain
  # even for count zero (where the latent lower endpoint is -Inf).
  size <- drm_nbinom2_size(nbinom2_sigma)
  lower_u <- if (nbinom2_y == 0L) {
    0
  } else {
    stats::pnbinom(nbinom2_y - 1L, size = size, mu = nbinom2_mu)
  }
  upper_u <- stats::pnbinom(nbinom2_y, size = size, mu = nbinom2_mu)
  if (!is.finite(lower_u) || !is.finite(upper_u) || lower_u < 0 ||
      upper_u > 1 || lower_u >= upper_u) {
    return(fail("endpoint_failure", "NB2 CDF interval is numerically unresolved."))
  }
  threshold <- stats::qnorm(binary_p, lower.tail = FALSE)
  s <- sqrt(1 - eta^2)
  log_conditional_probability <- function(u) {
    z <- stats::qnorm(u)
    if (binary_y == 1L) {
      stats::pnorm((eta * z - threshold) / s, log.p = TRUE)
    } else {
      stats::pnorm((threshold - eta * z) / s, log.p = TRUE)
    }
  }
  # The conditional probability is monotone in U.  Rescaling by its endpoint
  # maximum keeps the adaptive quadrature on a probability scale even when
  # the final rectangle probability is far below the absolute-error floor.
  maximum_u <- if ((binary_y == 1L && eta > 0) ||
      (binary_y == 0L && eta < 0)) upper_u else lower_u
  log_scale <- log_conditional_probability(maximum_u)
  if (!is.finite(log_scale)) {
    return(fail("integration_failure", "Conditional Bernoulli probability is numerically unresolved."))
  }
  integrand <- function(u) {
    exp(log_conditional_probability(u) - log_scale)
  }
  probability_scale <- exp(log_scale)
  quadrature_abs_tol <- integration_abs_tol / probability_scale
  if (!is.finite(quadrature_abs_tol)) {
    quadrature_abs_tol <- .Machine$double.xmax
  }
  # Do not let a probability-scale absolute tolerance become a loose scaled
  # tolerance in a rare-event integral: relative accuracy remains load-bearing.
  quadrature_abs_tol <- max(
    .Machine$double.xmin,
    min(quadrature_abs_tol, 1e-12)
  )
  integral <- tryCatch(stats::integrate(integrand, lower = lower_u,
    upper = upper_u, subdivisions = 200L, rel.tol = 1e-9,
    abs.tol = quadrature_abs_tol),
    error = function(e) e)
  if (inherits(integral, "error") || !is.finite(integral$value) ||
      !is.finite(integral$abs.error) || integral$value <= 0) {
    return(fail("integration_failure", if (inherits(integral, "error")) conditionMessage(integral) else NA_character_))
  }
  relative_integration_error <- integral$abs.error / integral$value
  integration_error <- probability_scale * integral$abs.error
  if (!is.finite(relative_integration_error) ||
      relative_integration_error > integration_rel_tol) {
    return(fail("integration_error_exceeds_tolerance",
      integration_error = integration_error,
      relative_integration_error = relative_integration_error))
  }
  log_probability <- log_scale + log(integral$value)
  probability <- exp(log_probability)
  if (!is.finite(log_probability) || !is.finite(probability) || probability <= 0) {
    return(fail("integration_failure", "Rectangle probability is numerically unresolved."))
  }
  midpoint <- (endpoints$lower + endpoints$upper) / 2
  branch <- if (midpoint <= 0) "lower" else if (midpoint >= 0) "upper" else "straddle"
  list(probability = probability, log_probability = log_probability,
    status = "ok", message = integral$message, integration_error = integration_error,
    relative_integration_error = relative_integration_error,
    integration_rel_tol = integration_rel_tol, integration_abs_tol = integration_abs_tol,
    branch = branch, endpoints = endpoints)
}

drm_pair_bernoulli_nbinom2_probabilities <- function(alpha, components) {
  eta <- 0.999999 * tanh(alpha)
  if (length(eta) == 1L) eta <- rep(eta, length(components$binary_y))
  if (length(eta) != length(components$binary_y)) {
    cli::cli_abort("The Bernoulli x ordinary-NB2 association predictor has the wrong number of rows.")
  }
  results <- lapply(seq_along(components$binary_y), function(i) {
    drm_pair_bernoulli_nbinom2_rectangle_probability(
      components$binary_y[[i]], components$binary_p[[i]],
      components$nbinom2_y[[i]], components$nbinom2_mu[[i]],
      components$nbinom2_sigma[[i]], eta[[i]]
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

# Direct conditional-normal rectangle probability for two frozen ordinary NB2
# margins.  Both discrete CDF intervals are formed through log-tail endpoints;
# quadrature error is part of the contract and is never silently ignored.
drm_pair_nbinom2_nbinom2_rectangle_probability <- function(
  y_1, mu_1, sigma_1, y_2, mu_2, sigma_2, eta,
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
  if (length(y_1) != 1L || length(y_2) != 1L ||
      !is.finite(eta) || abs(eta) >= 1 ||
      !is.finite(integration_rel_tol) || integration_rel_tol <= 0 ||
      !is.finite(integration_abs_tol) || integration_abs_tol <= 0) {
    return(fail("invalid_input"))
  }
  endpoints_1 <- tryCatch(drm_pair_nbinom2_endpoints(y_1, mu_1, sigma_1), error = function(e) e)
  endpoints_2 <- tryCatch(drm_pair_nbinom2_endpoints(y_2, mu_2, sigma_2), error = function(e) e)
  if (inherits(endpoints_1, "error") || inherits(endpoints_2, "error")) {
    error <- if (inherits(endpoints_1, "error")) endpoints_1 else endpoints_2
    return(fail("endpoint_failure", conditionMessage(error)))
  }
  if (identical(eta, 0)) {
    probability <- stats::dnbinom(y_1, size = drm_nbinom2_size(sigma_1), mu = mu_1) *
      stats::dnbinom(y_2, size = drm_nbinom2_size(sigma_2), mu = mu_2)
    return(list(probability = probability, log_probability = log(probability),
      status = "ok", message = NA_character_, integration_error = 0,
      relative_integration_error = 0, integration_rel_tol = integration_rel_tol,
      integration_abs_tol = integration_abs_tol, branch = "factorized",
      endpoints_1 = endpoints_1, endpoints_2 = endpoints_2))
  }
  s <- sqrt(1 - eta^2)
  integrand <- function(z_1) {
    lower <- (endpoints_2$lower - eta * z_1) / s
    upper <- (endpoints_2$upper - eta * z_1) / s
    branch <- ifelse(upper <= 0, "lower", ifelse(lower >= 0, "upper", "straddle"))
    log_mass <- ifelse(branch == "upper",
      drm_pair_logdiffexp(stats::pnorm(lower, lower.tail = FALSE, log.p = TRUE),
        stats::pnorm(upper, lower.tail = FALSE, log.p = TRUE)),
      drm_pair_logdiffexp(stats::pnorm(upper, log.p = TRUE), stats::pnorm(lower, log.p = TRUE)))
    exp(stats::dnorm(z_1, log = TRUE) + log_mass)
  }
  integral <- tryCatch(stats::integrate(integrand, lower = endpoints_1$lower,
    upper = endpoints_1$upper, subdivisions = 200L, rel.tol = 1e-9), error = function(e) e)
  if (inherits(integral, "error") || !is.finite(integral$value) ||
      !is.finite(integral$abs.error) || integral$value <= 0) {
    return(fail("integration_failure", if (inherits(integral, "error")) conditionMessage(integral) else NA_character_))
  }
  if (integral$abs.error > max(integration_abs_tol, integration_rel_tol * integral$value)) {
    return(fail("integration_error_exceeds_tolerance", integration_error = integral$abs.error,
      relative_integration_error = integral$abs.error / integral$value))
  }
  list(probability = integral$value, log_probability = log(integral$value), status = "ok",
    message = integral$message, integration_error = integral$abs.error,
    relative_integration_error = integral$abs.error / integral$value,
    integration_rel_tol = integration_rel_tol, integration_abs_tol = integration_abs_tol,
    branch = "conditional_normal", endpoints_1 = endpoints_1, endpoints_2 = endpoints_2)
}

drm_pair_nbinom2_nbinom2_probabilities <- function(alpha, components) {
  eta <- 0.999999 * tanh(alpha)
  results <- lapply(seq_along(components$nbinom2_y_1), function(i) {
    drm_pair_nbinom2_nbinom2_rectangle_probability(
      components$nbinom2_y_1[[i]], components$nbinom2_mu_1[[i]], components$nbinom2_sigma_1[[i]],
      components$nbinom2_y_2[[i]], components$nbinom2_mu_2[[i]], components$nbinom2_sigma_2[[i]], eta)
  })
  list(log_probability = vapply(results, `[[`, numeric(1L), "log_probability"),
    status = vapply(results, `[[`, character(1L), "status"),
    integration_error = vapply(results, `[[`, numeric(1L), "integration_error"),
    branch = vapply(results, `[[`, character(1L), "branch"), results = results)
}

drm_pair_nbinom2_nbinom2_loglik <- function(alpha, components) {
  probabilities <- drm_pair_nbinom2_nbinom2_probabilities(alpha, components)
  if (any(probabilities$status != "ok") || any(!is.finite(probabilities$log_probability))) return(-Inf)
  sum(probabilities$log_probability)
}

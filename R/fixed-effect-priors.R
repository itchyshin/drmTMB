#' Prior specifications for fixed effects and random-effect SDs
#'
#' Specify independent normal priors or ridge penalties on fixed-effect
#' coefficients. Coefficient names refer to the final design matrix, so their
#' meaning depends on contrasts and predictor units. No automatic scaling is
#' applied. For `coef = "all"`, state whether the intercept is included.
#'
#' Gaussian identity models may include one independent random intercept in
#' the mean. `drm_prior_sd_gamma()` targets its named group standard deviation
#' on the natural SD scale, with density relative to SD and no log-scale
#' Jacobian. Shape must exceed one and rate must be positive. It may be combined
#' with fixed-effect priors. The objective is the marginal data negative
#' log-likelihood plus the prior or penalty. A normal prior includes its density
#' constant, whereas a ridge penalty has no normalizing constant. `logLik()`
#' reports the data likelihood at the penalized estimates. Confidence intervals
#' and information criteria are not provided for active prior fits; local
#' penalized-Hessian curvature is not a calibrated confidence interval.
#' The Julia bridge currently refuses factor predictors in Gaussian mean
#' formulas with ordinary random effects; the native TMB route supports them.
#'
#' @param ... Prior specifications returned by `drm_prior_normal()`,
#'   `drm_prior_ridge()`, or `drm_prior_sd_gamma()`.
#' @param dpar For fixed-effect priors, `"mu"` or `"sigma"`. The SD prior
#'   currently supports `"mu"` only.
#' @param coef For fixed-effect priors, one exact design-matrix column name or
#'   `"all"`. The SD prior currently supports `"(Intercept)"` only.
#' @param mean Normal prior mean, a finite scalar.
#' @param sd Normal prior standard deviation, a positive finite scalar.
#' @param intercept For `coef = "all"`, either `"include"` or `"exclude"`.
#' @param lambda Nonnegative finite ridge precision. The penalty is
#'   `0.5 * lambda * sum(beta^2)`; zero contributes no penalty.
#' @return `drm_priors()` returns a collection of prior specifications; the
#'   other constructors return one specification.
#' @export
#' @examples
#' drm_priors(drm_prior_normal("mu", "x", sd = 2))
#' drm_priors(drm_prior_sd_gamma(group = "site", shape = 2, rate = 3))
#' \donttest{
#' d <- data.frame(x = rep(c(-1, 0, 1), 6), group = factor(rep(1:6, each = 3)))
#' d$y <- 0.5 + 0.6 * d$x + rep(c(-0.5, 0.2, 0.7, -0.3, 0.4, -0.4), each = 3) +
#'   rep(c(0.1, -0.2, 0.1), 6)
#' p <- drm_priors(drm_prior_normal("mu", "x", mean = 0.2, sd = 0.8))
#' fit <- drmTMB(bf(y ~ x + (1 | group), sigma ~ 1), data = d, priors = p)
#' coef(fit, dpar = "mu")
#' logLik(fit)  # data likelihood at the penalized estimates
#' sd_prior <- drm_priors(drm_prior_sd_gamma(group = "group", shape = 2, rate = 3))
#' formula <- bf(mu = y ~ x + (1 | group), sigma = ~ 1)
#' drm_resolve_priors(formula, gaussian(), d, sd_prior)  # inspect the target
#' sd_fit <- drmTMB(formula, data = d, priors = sd_prior)
#' logLik(sd_fit)  # data likelihood at the penalized estimates
#' }
drm_priors <- function(...) {
  entries <- list(...)
  if (!length(entries) || !all(vapply(entries, function(x) inherits(x, "drm_fixed_prior") || inherits(x, "drm_sd_prior"), logical(1)))) {
    cli::cli_abort("Supply one or more prior specifications.")
  }
  structure(entries, class = "drm_priors")
}

#' @rdname drm_priors
#' @param group Exact random-effect grouping variable name.
#' @param shape Gamma shape, finite and greater than one.
#' @param rate Gamma rate, positive and finite.
#' @export
drm_prior_sd_gamma <- function(dpar = "mu", group, coef = "(Intercept)", shape, rate) {
  scalar <- function(x) is.numeric(x) && length(x) == 1L && isTRUE(is.finite(x))
  if (!identical(dpar, "mu") || !is.character(group) || length(group) != 1L ||
      is.na(group) || !nzchar(group) || !identical(coef, "(Intercept)"))
    cli::cli_abort("SD priors require dpar 'mu', an exact group name and coef '(Intercept)'.")
  if (!scalar(shape) || shape <= 1 || !scalar(rate) || rate <= 0)
    cli::cli_abort("Gamma SD prior requires finite shape > 1 and finite rate > 0.")
  structure(list(dpar = dpar, group = group, coef = coef, shape = shape, rate = rate),
            class = "drm_sd_prior")
}

#' @rdname drm_priors
#' @export
drm_prior_normal <- function(dpar, coef, mean = 0, sd, intercept = NULL) {
  drm_fixed_prior_new(dpar, coef, intercept, "normal", mean, sd, NULL)
}

#' @rdname drm_priors
#' @export
drm_prior_ridge <- function(dpar, coef, lambda, intercept = NULL) {
  drm_fixed_prior_new(dpar, coef, intercept, "ridge", 0, NULL, lambda)
}

drm_fixed_prior_new <- function(dpar, coef, intercept, kind, mean, sd, lambda) {
  scalar_string <- function(x) is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)
  scalar_number <- function(x) is.numeric(x) && length(x) == 1L && !is.na(x) && is.finite(x)
  if (!scalar_string(dpar) || !dpar %in% c("mu", "sigma")) {
    cli::cli_abort("{.arg dpar} must be either 'mu' or 'sigma'.")
  }
  if (!scalar_string(coef)) cli::cli_abort("{.arg coef} must be one column name or 'all'.")
  if (identical(coef, "all")) {
    if (!scalar_string(intercept) || !intercept %in% c("include", "exclude")) {
      cli::cli_abort("For {.code coef = 'all'}, set {.arg intercept} to 'include' or 'exclude'.")
    }
  } else if (!is.null(intercept)) {
    cli::cli_abort("Set {.arg intercept} only when {.code coef = 'all'}; explicit names are literal.")
  }
  if (!identical(kind, "normal") && !identical(kind, "ridge")) cli::cli_abort("Invalid prior kind.")
  if (!scalar_number(mean)) cli::cli_abort("{.arg mean} must be a finite scalar.")
  if (identical(kind, "normal")) {
    if (!scalar_number(sd) || sd <= 0 || !is.finite(1 / sd^2) || 1 / sd^2 == 0) {
      cli::cli_abort("{.arg sd} must be positive and finite with representable precision.")
    }
    precision <- 1 / sd^2
  } else {
    if (!scalar_number(lambda) || lambda < 0) cli::cli_abort("{.arg lambda} must be a nonnegative finite scalar.")
    precision <- lambda
    sd <- if (lambda == 0) Inf else 1 / sqrt(lambda)
  }
  structure(list(dpar = dpar, coef = coef, intercept = intercept, kind = kind,
                 mean = mean, sd = sd, precision = precision), class = "drm_fixed_prior")
}

drm_apply_fixed_priors_spec <- function(spec, priors) {
  if (!inherits(priors, "drm_priors") || !length(priors)) {
    cli::cli_abort("{.arg priors} must be created with {.fn drm_priors}.")
  }
  sd_priors <- Filter(function(p) inherits(p, "drm_sd_prior"), priors)
  fixed <- Filter(function(p) inherits(p, "drm_fixed_prior"), priors)
  if (length(sd_priors) + length(fixed) != length(priors))
    cli::cli_abort("Invalid prior specification.")
  if (length(sd_priors) > 1L) cli::cli_abort("Only one SD prior is supported; duplicate or multiple targets are not supported.")
  if (length(sd_priors)) {
    p <- sd_priors[[1L]]
    p <- drm_prior_sd_gamma(p$dpar, p$group, p$coef, p$shape, p$rate)
    re <- spec$random$mu
    if (!identical(re$n_terms, 1L) || !identical(re$group_names, p$group) ||
        !identical(re$coef_names, p$coef) || !is.na(re$covariance_labels[[1L]]))
      cli::cli_abort("SD prior target must match the unique unlabelled iid mean random intercept group.")
    spec$resolved_sd_prior <- data.frame(class = "sd_gamma", dpar = "mu", group = p$group,
      block = re$labels[[1L]], coefficient = p$coef, scale = "SD", shape = p$shape, rate = p$rate)
    spec$tmb_data$prior_sd_index <- 0L
    spec$tmb_data$prior_sd_shape <- p$shape
    spec$tmb_data$prior_sd_rate <- p$rate
    spec$tmb_data$prior_sd_lgamma <- lgamma(p$shape)
  }
  if (!length(fixed)) return(spec)
  rows <- list()
  for (p in fixed) {
    if (!inherits(p, "drm_fixed_prior")) cli::cli_abort("Invalid fixed-effect prior specification.")
    # Revalidate stored specifications: callers can mutate an R list after construction.
    p <- drm_fixed_prior_new(p$dpar, p$coef, p$intercept, p$kind, p$mean,
                             if (identical(p$kind, "normal")) p$sd else NULL,
                             if (identical(p$kind, "ridge")) p$precision else NULL)
    X <- spec$X[[p$dpar]]
    if (is.null(X) || is.null(colnames(X))) cli::cli_abort("Unknown or unavailable prior distributional parameter {.val {p$dpar}}.")
    if (qr(as.matrix(X))$rank < ncol(X)) cli::cli_abort("Prior design matrix for {.val {p$dpar}} is rank deficient; remove aliased columns.")
    assign <- attr(X, "assign")
    if (identical(p$coef, "all")) {
      if (is.null(assign) || length(assign) != ncol(X)) cli::cli_abort("Design matrix lacks intercept assignment metadata.")
      selected <- seq_len(ncol(X))
      if (identical(p$intercept, "exclude")) selected <- selected[assign != 0L]
      reason <- paste0("all; intercept ", p$intercept)
    } else {
      selected <- match(p$coef, colnames(X), nomatch = 0L)
      if (selected == 0L) cli::cli_abort("Unknown coefficient {.val {p$coef}} for {.val {p$dpar}}.")
      reason <- "exact column"
    }
    if (!length(selected)) cli::cli_abort("Prior selector has an empty selection.")
    rows[[length(rows) + 1L]] <- data.frame(
      dpar = p$dpar, coefficient = colnames(X)[selected], matrix_column = selected,
      mean = p$mean, sd = p$sd, precision = p$precision,
      reason = reason, kind = p$kind, stringsAsFactors = FALSE
    )
  }
  resolved <- do.call(rbind, rows)
  if (anyDuplicated(resolved[c("dpar", "matrix_column")])) cli::cli_abort("Prior selections overlap for the same coefficient.")
  active <- resolved$precision > 0
  spec$resolved_priors <- resolved
  spec$tmb_data$prior_beta_block <- as.integer(match(resolved$dpar[active], c("mu", "sigma")) - 1L)
  spec$tmb_data$prior_beta_index <- as.integer(resolved$matrix_column[active] - 1L)
  spec$tmb_data$prior_beta_mean <- as.numeric(resolved$mean[active])
  spec$tmb_data$prior_beta_sd <- as.numeric(resolved$sd[active])
  spec$tmb_data$prior_beta_normalized <- as.integer(resolved$kind[active] == "normal")
  spec
}

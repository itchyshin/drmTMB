# First-slice admission stays outside the engine so unsupported requests fail
# before Julia setup, missing-data integration, or optimizer construction.
drm_fixed_priors_active <- function(priors) {
  if (is.null(priors)) return(FALSE)
  any(vapply(priors, function(p) inherits(p, "drm_sd_prior") || identical(p$kind, "normal") ||
    isTRUE(p$precision > 0), logical(1)))
}

drm_prior_control <- function(control) {
  parsed <- drm_parse_control(control)
  if (!inherits(control, "drm_control")) parsed["logsigma_clamp"] <- list(NULL)
  parsed
}

drm_validate_fixed_prior_designs <- function(spec) {
  for (X in spec$X) {
    if (qr(as.matrix(X))$rank < ncol(X)) {
      cli::cli_abort("Fixed-effect prior designs must have full column rank; remove aliased columns.")
    }
  }
  invisible(NULL)
}

drm_validate_fixed_prior_request <- function(priors, formula, family, data,
                                             REML = FALSE, estimator = "ml",
                                             penalty = NULL, impute = NULL,
                                             weights = NULL, control = list()) {
  if (is.null(priors)) return(invisible(NULL))
  if (!inherits(priors, "drm_priors")) {
    cli::cli_abort("{.arg priors} must be created with {.fn drm_priors}.")
  }
  if (isTRUE(REML) || !identical(estimator, "ml") || !is.null(penalty)) {
    cli::cli_abort("Fixed-effect priors require ML mode (REML = FALSE), without MSPL or {.arg penalty}.")
  }
  ft <- drm_family_type(family)
  has_sd <- any(vapply(priors, inherits, logical(1), "drm_sd_prior"))
  if (has_sd && !identical(ft, "gaussian"))
    cli::cli_abort("SD priors currently require a Gaussian mean random intercept.")
  if (!ft %in% c("gaussian", "binomial") ||
      (ft == "gaussian" && !identical(family$link, "identity")) ||
      (ft == "binomial" && !identical(family$link, "logit"))) {
    cli::cli_abort("Fixed-effect priors currently support univariate Gaussian identity and binomial logit models only.")
  }
  allowed <- if (ft == "gaussian") c("mu", "sigma") else "mu"
  if (any(!vapply(formula$entries, function(e) e$dpar %in% allowed, logical(1)))) {
    cli::cli_abort("Fixed-effect priors do not support this distributional-parameter formula yet.")
  }
  calls <- unique(unlist(lapply(formula$calls, all.names), use.names = FALSE))
  excluded <- c("||", "phylo", "spatial", "animal", "relmat", "corpair",
                "mi", "meta_V", "meta_known_V", "sd", "sd1", "sd2", "sd_phylo",
                "ar1", "ou", "homtoep")
  random_ok <- TRUE
  if ("|" %in% calls) {
    random_ok <- FALSE
    mu_idx <- which(vapply(formula$entries, function(e)
      identical(e$dpar, "mu"), logical(1)))
    if (identical(ft, "gaussian") && length(mu_idx) == 1L) {
      mu <- formula$entries[[mu_idx]]
      random <- extract_random_mu_terms(mu$rhs, "mu")
      bars <- unlist(lapply(formula$calls, all.names), use.names = FALSE)
      random_ok <- length(random$terms) %in% 1:2 &&
        sum(bars == "|") == length(random$terms) &&
        all(vapply(random$terms, function(term)
          identical(term$type, "intercept") && is.null(term$covariance_label), logical(1))) &&
        !anyDuplicated(vapply(random$terms, `[[`, character(1), "group")) &&
        !"|" %in% all.names(random$rhs)
      if (random_ok && length(random$terms) == 2L) {
        groups <- vapply(random$terms, `[[`, character(1), "group")
        if (all(groups %in% names(data)) && !anyNA(data[groups])) {
          first <- data[[groups[[1L]]]]
          second <- data[[groups[[2L]]]]
          paired <- unique(data.frame(first = first, second = second))
          if (nrow(paired) == length(unique(first)) && nrow(paired) == length(unique(second)))
            cli::cli_abort("Prior-enabled random-intercept groups must define distinct partitions; identical partitions do not identify separate SDs.")
        }
      }
    }
  }
  if (!random_ok || any(calls %in% excluded) || !is.null(impute) ||
      any(vapply(formula$entries, function(e) length(e$structured) > 0L, logical(1)))) {
    cli::cli_abort("Fixed-effect priors support fixed-effect-only models or one or two distinct Gaussian mean random intercepts, without structured or missing-predictor terms.")
  }
  if (has_sd && !"|" %in% calls)
    cli::cli_abort("SD priors require one Gaussian mean random intercept.")
  variables <- intersect(unique(unlist(lapply(formula$calls, all.vars))), names(data))
  if (anyNA(data[variables])) {
    cli::cli_abort("Fixed-effect priors currently require complete model variables; remove incomplete rows explicitly.")
  }
  if ((!is.null(weights) && any(!is.finite(weights) | weights != 1)) ||
      isTRUE(control$sparse_fixed) || isTRUE(control$aggregate_gaussian) ||
      (drm_fixed_priors_active(priors) && !is.null(control$logsigma_clamp))) {
    cli::cli_abort(c(
      "Fixed-effect priors currently require unit weights, dense unaggregated designs, and no logsigma clamp.",
      i = "Use complete fixed-effect data and {.code control = drm_control(logsigma_clamp = NULL)}."
    ))
  }
  invisible(NULL)
}

#' Preview prior selections without fitting
#'
#' Resolve selectors against the same Gaussian or binomial design builders used
#' by [drmTMB()]. Models require complete data and unit weights. Gaussian
#' identity models can include one or two independent mean random intercepts with distinct grouping partitions; other
#' random effects and random-effect SD formulas are not supported with priors.
#' A Gamma SD prior identifies the exact group and intercept and reports shape
#' and rate on the natural SD scale. The native and Julia engines support this
#' prior for the Gaussian mean random-intercept model described above.
#' The Julia bridge does not yet accept factor predictors in this mixed model.
#' No automatic centring or scaling is performed.
#' @param formula A [drm_formula()] or [bf()] specification.
#' @param family Gaussian identity or binomial logit family.
#' @param data A data frame with complete model variables.
#' @param priors A collection created by [drm_priors()].
#' @return A data frame identifying the resolved targets. Fixed-effect rows
#'   report the distributional parameter, coefficient, matrix column, prior
#'   mean, SD, precision and selection reason. An SD-prior row reports the
#'   distributional parameter, group, random-effect block, coefficient,
#'   SD scale, shape and rate. Mixed results combine these fields, with
#'   unavailable fields recorded as `NA`.
#' @export
#' @examples
#' d <- data.frame(y = c(1, 2, 1, 3), x = c(0, 1, 2, 3))
#' p <- drm_priors(drm_prior_normal("mu", "x", sd = 2))
#' drm_resolve_priors(bf(mu = y ~ x, sigma = ~ 1), gaussian(), d, p)
#' d$group <- factor(c(1, 1, 2, 2))
#' drm_resolve_priors(bf(mu = y ~ x + (1 | group), sigma = ~ 1), gaussian(), d, p)
drm_resolve_priors <- function(formula, family = stats::gaussian(), data, priors) {
  family <- drm_eval_family_arg(substitute(family), parent.frame())
  if (!inherits(formula, "drm_formula") || !is.data.frame(data)) {
    cli::cli_abort("Supply a {.fn bf} formula and a data frame.")
  }
  data <- drm_droplevels_fixed_predictors(data, formula)
  drm_validate_fixed_prior_request(priors, formula, family, data)
  env <- drm_formula_env(formula, parent.frame())
  spec <- if (identical(drm_family_type(family), "gaussian")) {
    drm_build_gaussian_ls_spec(formula, data, env = env,
      control = drm_parse_control(drm_prior_control(list())), missing = drm_parse_missing_control(miss_control()))
  } else {
    drm_build_binomial_spec(formula, data, env = env,
      missing = drm_parse_missing_control(miss_control()), link = family$link)
  }
  drm_validate_fixed_prior_designs(spec)
  spec <- drm_apply_fixed_priors_spec(spec, priors)
  if (is.null(spec$resolved_sd_prior)) return(spec$resolved_priors)
  if (is.null(spec$resolved_priors)) return(spec$resolved_sd_prior)
  fixed <- spec$resolved_priors
  fixed$class <- "fixed"
  fixed$group <- fixed$block <- fixed$scale <- NA_character_
  fixed$shape <- fixed$rate <- NA_real_
  sd <- spec$resolved_sd_prior
  for (n in setdiff(names(fixed), names(sd))) sd[[n]] <- NA
  rbind(fixed, sd[names(fixed)])
}

drm_has_fixed_priors <- function(object) {
  p <- object$resolved_priors
  (is.data.frame(p) && nrow(p) > 0L && any(p$precision > 0)) ||
    (is.data.frame(object$resolved_sd_prior) && nrow(object$resolved_sd_prior) > 0L)
}

drm_abort_fixed_prior_inference <- function(object, method) {
  if (drm_has_fixed_priors(object)) {
    label <- if (is.null(object$resolved_sd_prior)) "fixed-effect prior" else "fixed-effect or SD prior"
    cli::cli_abort(c(
      "{method} is not implemented for {label} fits.",
      i = "Inspect point estimates and local penalized-Hessian curvature with summary() and vcov(); these are not calibrated confidence intervals."
    ))
  }
  invisible(NULL)
}

drm_fixed_prior_bridge_options <- function(priors, resolved) {
  rows <- lapply(priors, function(p) {
    row <- list(kind = p$kind, dpar = p$dpar, coef = p$coef)
    if (!is.null(p$intercept)) row$intercept <- p$intercept
    if (identical(p$kind, "normal")) {
      row$mean <- p$mean
      row$sd <- p$sd
    } else row$lambda <- p$precision
    row
  })
  list(priors = rows, prior_expected = lapply(seq_len(nrow(resolved)), function(i)
    list(dpar = resolved$dpar[[i]], coef = resolved$coefficient[[i]])))
}

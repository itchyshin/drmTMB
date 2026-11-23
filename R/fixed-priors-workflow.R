# First-slice admission stays outside the engine so unsupported requests fail
# before Julia setup, missing-data integration, or optimizer construction.
drm_fixed_priors_active <- function(priors) {
  if (is.null(priors)) return(FALSE)
  any(vapply(priors, function(p) {
    if (inherits(p, c("drm_sd_prior", "drm_residual_sd_prior", "drm_correlation_prior"))) {
      return(TRUE)
    }
    identical(p$kind, "normal") || identical(p$kind, "student_t") ||
      isTRUE(p$precision > 0)
  }, logical(1)))
}

drm_prior_uses_native_only_targets <- function(priors) {
  if (is.null(priors)) return(FALSE)
  # The bivariate fixed-effect + rho12 table is admitted natively first; keep
  # Julia fail-closed until its matching mixed bivariate bridge contract lands.
  if (any(vapply(priors, function(p) {
    inherits(p, "drm_fixed_prior") && p$dpar %in% c("mu1", "mu2")
  }, logical(1)))) return(TRUE)
  has_q2_correlation <- any(vapply(priors, function(p) {
    inherits(p, "drm_correlation_prior") && identical(p$dpar, "mu")
  }, logical(1)))
  has_residual_sd <- any(vapply(priors, inherits, logical(1), "drm_residual_sd_prior"))
  has_student_t <- any(vapply(priors, function(p) {
    inherits(p, "drm_fixed_prior") && identical(p$kind, "student_t")
  }, logical(1)))
  if (has_residual_sd) {
    supported <- all(vapply(priors, function(p) {
      inherits(p, c("drm_fixed_prior", "drm_sd_prior", "drm_residual_sd_prior",
        "drm_correlation_prior"))
    }, logical(1))) &&
      sum(vapply(priors, inherits, logical(1), "drm_residual_sd_prior")) == 1L &&
      sum(vapply(priors, inherits, logical(1), "drm_correlation_prior")) <= 1L &&
      !any(vapply(priors, function(p) {
        inherits(p, "drm_correlation_prior") && !identical(p$dpar, "mu")
      }, logical(1)))
    return(!supported)
  }
  has_student_t && !has_q2_correlation
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

# Narrow phylogenetic scale-regression shape for normal coefficient priors.
drm_fixed_prior_phylo_lss <- function(priors, formula, family_type) {
  fixed <- Filter(function(p) inherits(p, "drm_fixed_prior"), priors)
  coefficient_density <- vapply(fixed, function(p)
    p$kind %in% c("normal", "student_t"), logical(1))
  if (!identical(family_type, "gaussian") || !length(fixed) ||
      !all(coefficient_density)) {
    return(FALSE)
  }
  entries <- formula$entries
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  mu <- which(dpars == "mu")
  sigma <- which(dpars == "sigma")
  if (length(entries) != 3L || length(mu) != 1L || length(sigma) != 1L) {
    return(FALSE)
  }
  structured <- entries[[mu]]$structured
  if (length(structured) != 1L ||
        !identical(structured[[1L]]$type, "phylo") ||
        !identical(structured[[1L]]$coef_names, "(Intercept)") ||
        !is.null(structured[[1L]]$covariance_label)) {
    return(FALSE)
  }
  grp <- structured[[1L]]$group
  expected <- c("mu", "sigma", paste0("sd_phylo(", grp, ")"))
  if (!identical(sort(dpars), sort(expected))) {
    return(FALSE)
  }
  other_structured <- vapply(entries[-mu], function(e) {
    length(e$structured) > 0L
  }, logical(1))
  if (any(other_structured)) {
    return(FALSE)
  }
  calls <- unlist(lapply(formula$calls, all.names), use.names = FALSE)
  forbidden <- c(
    "||", "spatial", "animal", "relmat", "corpair", "mi",
    "meta_V", "meta_known_V", "sd1", "sd2", "ar1", "ou", "homtoep"
  )
  sum(calls == "|") == 1L && sum(calls == "phylo") == 1L &&
    !any(calls %in% forbidden)
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
  has_residual_sd <- any(vapply(priors, inherits, logical(1), "drm_residual_sd_prior"))
  correlations <- Filter(function(p) inherits(p, "drm_correlation_prior"), priors)
  has_rho12_prior <- any(vapply(correlations, function(p) identical(p$dpar, "rho12"), logical(1)))
  has_random_correlation <- any(vapply(correlations, function(p) identical(p$dpar, "mu"), logical(1)))
  is_biv_gaussian <- identical(ft, "biv_gaussian")
  if ((has_sd || has_residual_sd || has_random_correlation) && !identical(ft, "gaussian")) {
    cli::cli_abort("Random-SD, residual-SD, and random-slope correlation priors currently require a univariate Gaussian identity model.")
  }
  if (has_rho12_prior && !is_biv_gaussian) {
    cli::cli_abort("An LKJ prior on rho12 requires family = biv_gaussian().")
  }
  if (is_biv_gaussian) {
    correlation_count <- sum(vapply(priors, inherits, logical(1), "drm_correlation_prior"))
    fixed <- Filter(function(p) inherits(p, "drm_fixed_prior"), priors)
    if (!has_rho12_prior || correlation_count != 1L ||
        length(fixed) + correlation_count != length(priors)) {
      cli::cli_abort("Bivariate Gaussian priors require exactly one rho12 LKJ prior and optional fixed-effect priors on mu1 or mu2.")
    }
    if (any(vapply(fixed, function(p) {
      !p$dpar %in% c("mu1", "mu2") ||
        !p$kind %in% c("normal", "student_t") || identical(p$coef, "all")
    }, logical(1)))) {
      cli::cli_abort("Bivariate rho12 prior combinations support exact mu1/mu2 Normal or Student-t coefficient targets only.")
    }
  }
  if (!ft %in% c("gaussian", "binomial", "biv_gaussian") ||
      (ft == "gaussian" && !identical(family$link, "identity")) ||
      (ft == "binomial" && !identical(family$link, "logit"))) {
    cli::cli_abort("Fixed-effect priors support univariate Gaussian identity and binomial logit models, plus exact mu1/mu2 Normal or Student-t targets combined with rho12 LKJ in bivariate Gaussian models.")
  }
  phylo_lss <- drm_fixed_prior_phylo_lss(priors, formula, ft)
  allowed <- if (is_biv_gaussian) c("mu1", "mu2", "rho12") else if (ft == "gaussian") c("mu", "sigma") else "mu"
  if (phylo_lss) {
    allowed <- c(allowed, vapply(formula$entries, `[[`, character(1), "dpar"))
  }
  if (any(!vapply(formula$entries, function(e) e$dpar %in% allowed, logical(1)))) {
    cli::cli_abort("Fixed-effect priors do not support this distributional-parameter formula yet.")
  }
  calls <- unique(unlist(lapply(formula$calls, all.names), use.names = FALSE))
  excluded <- c("||", "phylo", "spatial", "animal", "relmat", "corpair",
                "mi", "meta_V", "meta_known_V", "sd", "sd1", "sd2", "sd_phylo",
                "ar1", "ou", "homtoep")
  random_ok <- if (is_biv_gaussian) !"|" %in% calls else TRUE
  if (!is_biv_gaussian && "|" %in% calls) {
    random_ok <- FALSE
    mu_idx <- which(vapply(formula$entries, function(e)
      identical(e$dpar, "mu"), logical(1)))
    if (identical(ft, "gaussian") && length(mu_idx) == 1L) {
      mu <- formula$entries[[mu_idx]]
      random <- extract_random_mu_terms(mu$rhs, "mu")
      bars <- unlist(lapply(formula$calls, all.names), use.names = FALSE)
      intercept_only <- length(random$terms) %in% 1:2 &&
        all(vapply(random$terms, function(term)
          identical(term$type, "intercept") && is.null(term$covariance_label), logical(1)))
      q2_correlation_only <- has_random_correlation && length(random$terms) == 1L &&
        all(vapply(random$terms, function(term)
          identical(term$type, "correlated_slope") && is.null(term$covariance_label) &&
            length(term$coef_names) == 2L && identical(term$coef_names[[1L]], "(Intercept)"), logical(1)))
      random_ok <- (intercept_only || q2_correlation_only) &&
        sum(bars == "|") == length(random$terms) &&
        !anyDuplicated(vapply(random$terms, `[[`, character(1), "group")) &&
        !"|" %in% all.names(random$rhs)
      if (random_ok && intercept_only && length(random$terms) == 2L) {
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
  if ((!phylo_lss && (!random_ok || any(calls %in% excluded) ||
      any(vapply(formula$entries, function(e) length(e$structured) > 0L, logical(1))))) ||
      !is.null(impute)) {
    cli::cli_abort("fixed-effect-only and target-specific prior fits support fixed-effect models, one or two distinct Gaussian mean random intercepts, one unlabelled Gaussian q=2 intercept-slope block for its LKJ target, or an intercept-only bivariate rho12 target; structured and missing-predictor terms are refused.")
  }
  if (has_sd && (!"|" %in% calls || has_random_correlation))
    cli::cli_abort("Random-effect SD priors require one or two independent Gaussian mean random intercepts.")
  if (has_residual_sd && (!identical(ft, "gaussian") || is_biv_gaussian))
    cli::cli_abort("Residual-SD Gamma priors currently require a univariate Gaussian identity model.")
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
#' identity models can include one or two independent mean random intercepts
#' with distinct grouping partitions. Normal coefficient priors also support
#' one phylogenetic mean intercept with a matching phylogenetic SD regression
#' and fixed residual-SD predictors. The prior targets `mu` or `sigma`
#' coefficients, not the phylogenetic SD-regression coefficients. The
#' R-to-Julia bridge is not yet qualified for this phylogenetic prior route.
#' Other structured combinations and random slopes are not supported with priors.
#' A Gamma SD prior identifies the exact group and intercept and reports shape
#' and rate on the natural SD scale. The native engine also supports a Gamma
#' prior for the residual SD and LKJ priors for `rho12` in an intercept-only
#' bivariate Gaussian model or for the correlation in one unlabelled Gaussian
#' mean random-intercept/random-slope block. No automatic centring or scaling
#' is performed. Student-t coefficient, residual-SD, and correlation table
#' rows are native-engine only; the Julia bridge refuses them until its
#' versioned contract supports those targets.
#' @param formula A [drm_formula()] or [bf()] specification.
#' @param family Gaussian identity, binomial logit, or bivariate Gaussian family
#'   for the documented target classes.
#' @param data A data frame with complete model variables.
#' @param priors A collection created by [drm_priors()], or a data frame with
#'   `prior`, `class`, and `coef` columns. `class = "fixef"` accepts
#'   `normal(mean, sd)`, `student_t(location, scale, df)`, or `ridge(lambda)`;
#'   `class = "ranef_sd"` accepts `gamma(mean, shape)` for a named independent
#'   Gaussian mean-intercept SD; `class = "residual_sd"` accepts that Gamma
#'   form for the residual SD with `dpar = "sigma"` and `coef = "(Intercept)"`;
#'   and `class = "correlation"` accepts `lkj(eta)`. Correlation targets use
#'   `dpar = "rho12"`, `coef = "(Intercept)"` for bivariate residual
#'   correlation, or `dpar = "mu"`, `group`, `from_coef`, and `to_coef` for
#'   the exact intercept/slope pair in one unlabelled Gaussian q=2 block.
#'   Optional `dpar` defaults to `"mu"`; optional `group` names a grouping
#'   factor. A blank fixed-effect coefficient selects non-intercept coefficients;
#'   a blank random-SD selector selects all supported mean-intercept SDs.
#'   Gamma table rows use mean and shape, so `rate = shape / mean`; the
#'   constructor uses shape and rate. Normal, Student-t, Gamma, and LKJ
#'   densities are normalized; natural-SD and natural-correlation priors add
#'   no transform Jacobian. Overlapping targets, unsupported models, and a
#'   coefficient literally named `"all"` are rejected. Fitted objects retain
#'   the input table and `update()` replays resolved targets.
#' @return A data frame identifying the resolved targets. Fixed-effect rows
#'   report the distributional parameter, coefficient, matrix column, prior
#'   mean, SD, precision and selection reason. An SD-prior row reports the
#'   distributional parameter, group, random-effect block, coefficient,
#'   SD scale, shape and rate. Residual-SD rows identify the natural SD target;
#'   correlation rows identify the exact pair and LKJ eta. Previews use the
#'   classes `fixef`, `ranef_sd`, `residual_sd`, and `correlation`,
#'   with scales `link`, `natural_sd`, or `natural_correlation`. Mixed results
#'   combine these fields, with unavailable fields recorded as `NA`.
#' @export
#' @examples
#' d <- data.frame(y = c(1, 2, 1, 3), x = c(0, 1, 2, 3))
#' p <- drm_priors(drm_prior_normal("mu", "x", sd = 2))
#' drm_resolve_priors(bf(mu = y ~ x, sigma = ~ 1), gaussian(), d, p)
#' table <- data.frame(prior = "normal(0,2)", class = "fixef", coef = "x")
#' drm_resolve_priors(bf(mu = y ~ x, sigma = ~ 1), gaussian(), d, table)
#' d$group <- factor(c(1, 1, 2, 2))
#' drm_resolve_priors(bf(mu = y ~ x + (1 | group), sigma = ~ 1), gaussian(), d, p)
#' sd_table <- data.frame(prior = "gamma(0.6666666666666666,2)",
#'                        class = "ranef_sd", coef = "group")
#' drm_resolve_priors(bf(mu = y ~ x + (1 | group), sigma = ~ 1), gaussian(), d, sd_table)
#' \dontrun{
#' d$group <- factor(rep(seq_len(12), each = 10))
#' d$x <- rep(seq(-1, 1, length.out = 10), 12)
#' d$y <- 0.4 + 0.6 * d$x + rnorm(nrow(d))
#' f <- bf(mu = y ~ x + (1 + x | group), sigma = ~ 1)
#' prior_table <- data.frame(
#'   prior = c("normal(0,2)", "student_t(0,1.5,4)", "gamma(0.8,2)", "lkj(2)"),
#'   class = c("fixef", "fixef", "residual_sd", "correlation"),
#'   dpar = c("mu", "mu", "sigma", "mu"),
#'   coef = c("(Intercept)", "x", "(Intercept)", ""),
#'   group = c("", "", "", "group"),
#'   from_coef = c("", "", "", "(Intercept)"),
#'   to_coef = c("", "", "", "x"),
#'   scale = c("link", "link", "natural_sd", "natural_correlation")
#' )
#' drm_resolve_priors(f, gaussian(), d, prior_table)
#' fit <- drmTMB(f, data = d, priors = prior_table)
#' c(logLik = as.numeric(logLik(fit)), penalized_objective = fit$penalized_objective)
#' }
#' \dontrun{
#' tree <- ape::read.tree(text = "((a:0.5,b:0.5):0.5,(c:0.5,d:0.5):0.5);")
#' dat <- data.frame(y = c(.2,.7,.35,1.1,.8,1.25,1.4,1.1,1.9,1.5,2.15,.5),
#'                   x = c(-1.2,-.8,-.7,-.2,.1,.15,.4,.6,.8,1,1.2,-.3),
#'                   sp = c("a","a","b","b","b","c","c","d","d","d","d","a"),
#'                   z = c(-1,-1,-.35,-.35,-.35,.4,.4,1,1,1,1,-1))
#' f <- bf(y ~ x + phylo(1 | sp, tree = tree), sigma ~ x,
#'         sd(sp, level = "phylogenetic") ~ z)
#' pri <- data.frame(prior = c("normal(.1,.7)", "normal(-.2,.5)"),
#'                   class = "fixef", coef = "x", dpar = c("mu", "sigma"))
#' drm_resolve_priors(f, gaussian(), dat, pri)
#' fit <- drmTMB(f, data = dat, priors = pri)
#' }
drm_resolve_priors <- function(formula, family = stats::gaussian(), data, priors) {
  drm_prior_table_preview(drm_resolve_priors_native(formula, family, data, priors))
}

drm_resolve_priors_native <- function(formula, family = stats::gaussian(), data, priors) {
  family <- drm_eval_family_arg(substitute(family), parent.frame())
  if (!inherits(formula, "drm_formula") || !is.data.frame(data)) {
    cli::cli_abort("Supply a {.fn bf} formula and a data frame.")
  }
  data <- drm_droplevels_fixed_predictors(data, formula)
  table_input <- is.data.frame(priors)
  if (table_input) priors <- drm_normalize_prior_table(priors, formula, family, data)
  drm_validate_fixed_prior_request(priors, formula, family, data)
  env <- drm_formula_env(formula, parent.frame())
  spec <- switch(drm_family_type(family),
    gaussian = drm_build_gaussian_ls_spec(formula, data, env = env,
      control = drm_parse_control(drm_prior_control(list())),
      missing = drm_parse_missing_control(miss_control())),
    biv_gaussian = drm_build_biv_gaussian_spec(formula, data, env = env,
      missing = drm_parse_missing_control(miss_control())),
    binomial = drm_build_binomial_spec(formula, data, env = env,
      missing = drm_parse_missing_control(miss_control()), link = family$link)
  )
  drm_validate_fixed_prior_designs(spec)
  spec <- drm_apply_fixed_priors_spec(spec, priors, formula = formula, family = family)
  if (table_input && !is.null(spec$resolved_priors) && any(spec$resolved_priors$coefficient == "all"))
    cli::cli_abort("Prior tables cannot select a coefficient literally named {.val all}.")
  fixed <- spec$resolved_priors
  other_pieces <- Filter(Negate(is.null), list(
    spec$resolved_sd_prior, spec$resolved_residual_sd_prior,
    spec$resolved_correlation_prior
  ))
  if (!length(other_pieces)) return(fixed)
  if (!is.null(fixed)) {
    fixed$class <- "fixed"
    fixed$group <- fixed$block <- fixed$scale <- NA_character_
    fixed$shape <- fixed$rate <- fixed$eta <- NA_real_
    fixed$from_coef <- fixed$to_coef <- NA_character_
  }
  pieces <- Filter(Negate(is.null), c(list(fixed), other_pieces))
  if (!length(pieces)) return(data.frame())
  columns <- unique(unlist(lapply(pieces, names), use.names = FALSE))
  pieces <- lapply(pieces, function(piece) {
    for (column in setdiff(columns, names(piece))) piece[[column]] <- NA
    piece[, columns, drop = FALSE]
  })
  resolved <- do.call(rbind, pieces)
  if (table_input) drm_prior_table_preview(resolved) else resolved
}

drm_has_fixed_priors <- function(object) {
  p <- object$resolved_priors
  (is.data.frame(p) && nrow(p) > 0L && any(p$precision > 0)) ||
    (is.data.frame(object$resolved_sd_prior) && nrow(object$resolved_sd_prior) > 0L) ||
    (is.data.frame(object$resolved_residual_sd_prior) && nrow(object$resolved_residual_sd_prior) > 0L) ||
    (is.data.frame(object$resolved_correlation_prior) && nrow(object$resolved_correlation_prior) > 0L)
}

drm_abort_fixed_prior_inference <- function(object, method) {
  if (drm_has_fixed_priors(object)) {
    label <- "fixed-effect prior, random-SD prior, residual-SD prior, or correlation prior/penalty"
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

#' Prior specifications for distributional regression parameters
#'
#' Specify coefficient priors or penalties and natural-scale priors for
#' supported positive scales and correlations. Coefficient names refer to the final design matrix, so their
#' meaning depends on contrasts and predictor units. No automatic scaling is
#' applied. For `coef = "all"`, state whether the intercept is included.
#'
#' The prior-table interface accepts normal, Student-t, and ridge coefficient
#' rows, Gamma priors on supported random-effect and residual standard
#' deviations, and LKJ(eta) priors on supported correlations. Pass a table
#' directly to `drmTMB(priors = ...)` or [drm_resolve_priors()];
#' `drm_priors()` collects constructor specifications.
#' Gamma priors are densities on natural SD and LKJ priors are densities on
#' natural correlation; optimizing transformed coordinates adds no Jacobian.
#' In bivariate Gaussian models, exact Normal or Student-t fixed-effect rows
#' for `mu1` and `mu2` may be combined with one intercept-only `rho12` LKJ row;
#' other bivariate prior combinations remain unsupported.
#' Shape must exceed one and rate must be positive. Normal, Student-t, Gamma,
#' and LKJ densities include their normalizing constants; ridge remains an
#' unnormalized penalty. `logLik()`
#' reports the data likelihood at the penalized estimates. Confidence intervals
#' and information criteria are not provided for active prior fits; local
#' penalized-Hessian curvature is not a calibrated confidence interval.
#' The Julia bridge currently refuses factor predictors in Gaussian mean
#' formulas with ordinary random effects; the native TMB route supports them.
#'
#' @param ... Prior specifications returned by `drm_prior_normal()`,
#'   `drm_prior_ridge()`, or `drm_prior_sd_gamma()`.
#' @param dpar For fixed-effect priors, `"mu"` or `"sigma"` in univariate
#'   models. In a bivariate Gaussian model, fixed Normal and Student-t priors
#'   may target `"mu1"` or `"mu2"` when combined with one `rho12` LKJ prior.
#'   The SD prior currently supports `"mu"` only.
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
#' d$observer <- rep(c("a", "b"), 9)
#' two_groups <- bf(mu = y ~ x + (1 | group) + (1 | observer), sigma = ~ 1)
#' two_priors <- drm_priors(drm_prior_sd_gamma(group = "group", shape = 2, rate = 3),
#'                          drm_prior_sd_gamma(group = "observer", shape = 3, rate = 2))
#' drm_resolve_priors(two_groups, gaussian(), d, two_priors)
#' two_fit <- drmTMB(two_groups, data = d, priors = two_priors)
#' }
drm_priors <- function(...) {
  entries <- list(...)
  allowed <- c("drm_fixed_prior", "drm_sd_prior", "drm_residual_sd_prior", "drm_correlation_prior")
  if (!length(entries) || !all(vapply(entries, function(x)
    any(vapply(allowed, function(class) inherits(x, class), logical(1))), logical(1)))) {
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

drm_prior_student_t <- function(dpar, coef, mean = 0, scale, df, intercept = NULL) {
  drm_fixed_prior_new(dpar, coef, intercept, "student_t", mean, scale, NULL, df = df)
}

drm_residual_sd_prior_gamma <- function(shape, rate) {
  scalar <- function(x) is.numeric(x) && length(x) == 1L && is.finite(x)
  if (!scalar(shape) || shape <= 1 || !scalar(rate) || rate <= 0) {
    cli::cli_abort("Gamma residual-SD prior requires finite shape > 1 and finite rate > 0.")
  }
  structure(list(dpar = "sigma", coef = "(Intercept)", shape = shape, rate = rate,
    scale = "natural_sd"), class = "drm_residual_sd_prior")
}

drm_correlation_prior_lkj <- function(dpar, group = NULL, from_coef = NULL,
                                     to_coef = NULL, eta) {
  scalar_string <- function(x) is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)
  if (!scalar_string(dpar) || !dpar %in% c("rho12", "mu") ||
      !is.numeric(eta) || length(eta) != 1L || !is.finite(eta) || eta <= 1) {
    cli::cli_abort("LKJ correlation prior requires dpar rho12 or mu and finite eta > 1.")
  }
  if (identical(dpar, "rho12")) {
    if (!is.null(group) || !is.null(from_coef) || !is.null(to_coef)) {
      cli::cli_abort("Residual rho12 LKJ prior does not accept group or coefficient-pair selectors.")
    }
  } else if (!scalar_string(group) || !scalar_string(from_coef) ||
      !scalar_string(to_coef) || identical(from_coef, to_coef) ||
      !("(Intercept)" %in% c(from_coef, to_coef))) {
    cli::cli_abort("Random-effect LKJ prior requires group and a distinct intercept/slope pair.")
  }
  structure(list(dpar = dpar, group = group, from_coef = from_coef,
    to_coef = to_coef, eta = eta, scale = "natural_correlation"),
    class = "drm_correlation_prior")
}

drm_fixed_prior_new <- function(dpar, coef, intercept, kind, mean, sd, lambda, df = NULL) {
  scalar_string <- function(x) is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)
  scalar_number <- function(x) is.numeric(x) && length(x) == 1L && !is.na(x) && is.finite(x)
  if (!scalar_string(dpar) || !dpar %in% c("mu", "sigma", "mu1", "mu2")) {
    cli::cli_abort("{.arg dpar} must be 'mu', 'sigma', 'mu1', or 'mu2'.")
  }
  if (!scalar_string(coef)) cli::cli_abort("{.arg coef} must be one column name or 'all'.")
  if (identical(coef, "all")) {
    if (!scalar_string(intercept) || !intercept %in% c("include", "exclude")) {
      cli::cli_abort("For {.code coef = 'all'}, set {.arg intercept} to 'include' or 'exclude'.")
    }
  } else if (!is.null(intercept)) {
    cli::cli_abort("Set {.arg intercept} only when {.code coef = 'all'}; explicit names are literal.")
  }
  if (!kind %in% c("normal", "student_t", "ridge")) cli::cli_abort("Invalid prior kind.")
  if (!scalar_number(mean)) cli::cli_abort("{.arg mean} must be a finite scalar.")
  if (kind %in% c("normal", "student_t")) {
    if (!scalar_number(sd) || sd <= 0 || !is.finite(1 / sd^2) || 1 / sd^2 == 0) {
      cli::cli_abort("{.arg sd} must be positive and finite with representable precision.")
    }
    precision <- 1 / sd^2
    if (identical(kind, "student_t") &&
        (!scalar_number(df) || df <= 0)) {
      cli::cli_abort("{.arg df} must be positive and finite for a Student-t prior.")
    }
  } else {
    if (!scalar_number(lambda) || lambda < 0) cli::cli_abort("{.arg lambda} must be a nonnegative finite scalar.")
    precision <- lambda
    sd <- if (lambda == 0) Inf else 1 / sqrt(lambda)
  }
  structure(list(dpar = dpar, coef = coef, intercept = intercept, kind = kind,
    mean = mean, sd = sd, precision = precision,
    df = if (identical(kind, "student_t")) as.double(df) else NULL),
    class = "drm_fixed_prior")
}

drm_apply_fixed_priors_spec <- function(spec, priors, formula = NULL, family = NULL) {
  if (!inherits(priors, "drm_priors") || !length(priors)) {
    cli::cli_abort("{.arg priors} must be created with {.fn drm_priors}.")
  }
  sd_priors <- Filter(function(p) inherits(p, "drm_sd_prior"), priors)
  residual_sd_priors <- Filter(function(p) inherits(p, "drm_residual_sd_prior"), priors)
  correlation_priors <- Filter(function(p) inherits(p, "drm_correlation_prior"), priors)
  fixed <- Filter(function(p) inherits(p, "drm_fixed_prior"), priors)
  if (length(sd_priors) + length(residual_sd_priors) +
      length(correlation_priors) + length(fixed) != length(priors)) {
    cli::cli_abort("Invalid prior specification.")
  }
  if (length(sd_priors) > 2L) cli::cli_abort("At most two SD priors are supported.")
  if (length(residual_sd_priors) > 1L) {
    cli::cli_abort("Only one residual-SD prior target is supported.")
  }

  prior_sd_index <- integer()
  prior_sd_dpar <- integer()
  prior_sd_shape <- numeric()
  prior_sd_rate <- numeric()
  prior_sd_lgamma <- numeric()
  if (length(sd_priors)) {
    sd_priors <- lapply(sd_priors, function(p)
      drm_prior_sd_gamma(p$dpar, p$group, p$coef, p$shape, p$rate))
    re <- spec$random$mu
    groups <- vapply(sd_priors, `[[`, character(1), "group")
    if (anyDuplicated(groups)) cli::cli_abort("Only one SD prior per target is allowed; duplicate SD prior target.")
    if (!re$n_terms %in% 1:2 || anyDuplicated(re$group_names) ||
        any(re$coef_names != "(Intercept)") || any(!is.na(re$covariance_labels)))
      cli::cli_abort("SD prior target must match a unique unlabelled iid mean random intercept group.")
    index <- match(groups, re$group_names)
    if (anyNA(index)) cli::cli_abort("SD prior target must match a unique unlabelled iid mean random intercept group.")
    shape <- vapply(sd_priors, `[[`, numeric(1), "shape")
    rate <- vapply(sd_priors, `[[`, numeric(1), "rate")
    spec$resolved_sd_prior <- data.frame(class = "sd_gamma", dpar = "mu", group = groups,
      block = re$labels[index], coefficient = "(Intercept)", scale = "SD",
      kind = "gamma", shape = shape, rate = rate)
    prior_sd_index <- c(prior_sd_index, as.integer(index - 1L))
    prior_sd_dpar <- c(prior_sd_dpar, rep.int(0L, length(index)))
    prior_sd_shape <- c(prior_sd_shape, shape)
    prior_sd_rate <- c(prior_sd_rate, rate)
    prior_sd_lgamma <- c(prior_sd_lgamma, lgamma(shape))
  }
  if (length(residual_sd_priors)) {
    p <- residual_sd_priors[[1L]]
    if (!identical(spec$model_type, "gaussian") ||
        !identical(family$link, "identity") ||
        ncol(spec$X$sigma) != 1L ||
        !identical(colnames(spec$X$sigma), "(Intercept)") ||
        (!is.null(spec$random$sigma) && isTRUE(spec$random$sigma$n_terms > 0L))) {
      cli::cli_abort("Residual-SD Gamma prior requires a univariate Gaussian identity model with a constant sigma intercept and no residual random effect or known variance.")
    }
    p <- drm_residual_sd_prior_gamma(p$shape, p$rate)
    spec$resolved_residual_sd_prior <- data.frame(
      class = "residual_sd", dpar = "sigma", group = NA_character_,
      block = "residual", coefficient = "(Intercept)", scale = "natural_sd",
      kind = "gamma", shape = p$shape, rate = p$rate,
      stringsAsFactors = FALSE
    )
    prior_sd_index <- c(prior_sd_index, 0L)
    prior_sd_dpar <- c(prior_sd_dpar, 1L)
    prior_sd_shape <- c(prior_sd_shape, p$shape)
    prior_sd_rate <- c(prior_sd_rate, p$rate)
    prior_sd_lgamma <- c(prior_sd_lgamma, lgamma(p$shape))
  }
  if (length(prior_sd_index)) {
    spec$tmb_data$prior_sd_index <- as.integer(prior_sd_index)
    spec$tmb_data$prior_sd_dpar <- as.integer(prior_sd_dpar)
    spec$tmb_data$prior_sd_shape <- as.numeric(prior_sd_shape)
    spec$tmb_data$prior_sd_rate <- as.numeric(prior_sd_rate)
    spec$tmb_data$prior_sd_lgamma <- as.numeric(prior_sd_lgamma)
  }

  if (length(correlation_priors)) {
    cor_specs <- lapply(correlation_priors, function(p) {
      drm_correlation_prior_lkj(p$dpar, p$group, p$from_coef, p$to_coef, p$eta)
    })
    target_keys <- vapply(cor_specs, function(p) {
      paste(p$dpar, if (is.null(p$group)) "" else p$group,
        if (is.null(p$from_coef)) "" else p$from_coef,
        if (is.null(p$to_coef)) "" else p$to_coef, sep = "|")
    }, character(1L))
    if (anyDuplicated(target_keys)) {
      cli::cli_abort("Only one correlation prior per exact target is allowed.")
    }
    correlation_rows <- lapply(cor_specs, function(p) {
      if (identical(p$dpar, "rho12")) {
        X <- spec$X$rho12
        if (!identical(spec$model_type, "biv_gaussian") || is.null(X) ||
            ncol(X) != 1L || !identical(colnames(X), "(Intercept)")) {
          cli::cli_abort("rho12 LKJ prior requires a bivariate Gaussian model with one residual-correlation intercept.")
        }
        guard <- 0.999999
        log_normalizer <- lbeta(0.5, p$eta) + log(pbeta(guard^2, 0.5, p$eta))
        return(list(parameter = 0L, index = 0L, guard = guard,
          log_normalizer = log_normalizer, row = data.frame(
          class = "correlation", dpar = "rho12", group = NA_character_,
          block = "bivariate_residual", coefficient = "(Intercept)",
          from_coef = NA_character_, to_coef = NA_character_,
          scale = "natural_correlation", kind = "lkj", eta = p$eta,
          support_guard = guard, log_normalizer = log_normalizer,
          stringsAsFactors = FALSE
        )))
      }
      if (!identical(spec$model_type, "gaussian") ||
          !identical(family$link, "identity")) {
        cli::cli_abort("Random-slope LKJ prior requires a univariate Gaussian identity model.")
      }
      mu_entry <- Filter(function(entry) identical(entry$dpar, "mu"), formula$entries)
      if (length(mu_entry) != 1L) {
        cli::cli_abort("Random-slope LKJ prior requires one unambiguous mean formula.")
      }
      terms <- extract_random_mu_terms(mu_entry[[1L]]$rhs, "mu")$terms
      selected <- Filter(function(term) identical(term$group, p$group), terms)
      if (length(selected) != 1L ||
          !identical(selected[[1L]]$type, "correlated_slope") ||
          !is.null(selected[[1L]]$covariance_label) ||
          !identical(selected[[1L]]$coef_names, c("(Intercept)", p$to_coef)) ||
          !identical(p$from_coef, "(Intercept)")) {
        cli::cli_abort("Correlation target must resolve to one exact unlabelled Gaussian intercept-slope block in the requested group.")
      }
      labels <- spec$random$mu$cor_labels
      label <- format_random_mu_cor_label(selected[[1L]]$coef_names, p$group, NULL)
      index <- match(label, labels)
      if (length(index) != 1L || is.na(index)) {
        cli::cli_abort("Correlation target did not resolve to one model correlation parameter.")
      }
      guard <- 0.99999999
      log_normalizer <- lbeta(0.5, p$eta) + log(pbeta(guard^2, 0.5, p$eta))
      list(parameter = 1L, index = as.integer(index - 1L), guard = guard,
        log_normalizer = log_normalizer, row = data.frame(
        class = "correlation", dpar = "mu", group = p$group,
        block = label, coefficient = NA_character_,
        from_coef = p$from_coef, to_coef = p$to_coef,
        scale = "natural_correlation", kind = "lkj", eta = p$eta,
        support_guard = guard, log_normalizer = log_normalizer,
        stringsAsFactors = FALSE
      ))
    })
    spec$resolved_correlation_prior <- do.call(rbind,
      lapply(correlation_rows, `[[`, "row"))
    spec$tmb_data$prior_cor_parameter <- as.integer(vapply(
      correlation_rows, `[[`, integer(1L), "parameter"))
    spec$tmb_data$prior_cor_index <- as.integer(vapply(
      correlation_rows, `[[`, integer(1L), "index"))
    spec$tmb_data$prior_cor_eta <- as.numeric(vapply(
      cor_specs, `[[`, numeric(1L), "eta"))
    spec$tmb_data$prior_cor_guard <- as.numeric(vapply(
      correlation_rows, `[[`, numeric(1L), "guard"))
    spec$tmb_data$prior_cor_log_normalizer <- as.numeric(vapply(
      correlation_rows, `[[`, numeric(1L), "log_normalizer"))
  }
  if (!length(fixed)) return(spec)
  rows <- list()
  for (p in fixed) {
    if (!inherits(p, "drm_fixed_prior")) cli::cli_abort("Invalid fixed-effect prior specification.")
    # Revalidate stored specifications: callers can mutate an R list after construction.
    p <- drm_fixed_prior_new(p$dpar, p$coef, p$intercept, p$kind, p$mean,
      if (p$kind %in% c("normal", "student_t")) p$sd else NULL,
      if (identical(p$kind, "ridge")) p$precision else NULL,
      df = p$df)
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
      df = if (identical(p$kind, "student_t")) p$df else NA_real_,
      reason = reason, kind = p$kind, stringsAsFactors = FALSE
    )
  }
  resolved <- do.call(rbind, rows)
  if (anyDuplicated(resolved[c("dpar", "matrix_column")])) cli::cli_abort("Prior selections overlap for the same coefficient.")
  active <- resolved$precision > 0
  spec$resolved_priors <- resolved
  beta_blocks <- c(mu = 0L, sigma = 1L, mu1 = 2L, mu2 = 3L)
  spec$tmb_data$prior_beta_block <- as.integer(beta_blocks[resolved$dpar[active]])
  spec$tmb_data$prior_beta_index <- as.integer(resolved$matrix_column[active] - 1L)
  spec$tmb_data$prior_beta_mean <- as.numeric(resolved$mean[active])
  spec$tmb_data$prior_beta_sd <- as.numeric(resolved$sd[active])
  spec$tmb_data$prior_beta_normalized <- ifelse(resolved$kind[active] == "normal", 1L,
    ifelse(resolved$kind[active] == "student_t", 2L, 0L))
  spec$tmb_data$prior_beta_df <- as.numeric(resolved$df[active])
  spec
}

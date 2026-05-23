#' @export
print.drmTMB <- function(x, ...) {
  label <- switch(
    x$model$model_type,
    gaussian = "Gaussian location-scale",
    student = "Student-t location-scale-shape",
    lognormal = "Lognormal location-scale",
    gamma = "Gamma mean-CV",
    beta = "Beta mean-scale",
    beta_binomial = "Beta-binomial mean-overdispersion",
    cumulative_logit = "cumulative-logit ordinal",
    poisson = "Poisson mean",
    zi_poisson = "zero-inflated Poisson mean",
    nbinom2 = "negative binomial 2 mean-dispersion",
    truncated_nbinom2 = "zero-truncated negative binomial 2 mean-dispersion",
    hurdle_nbinom2 = "hurdle negative binomial 2 mean-dispersion",
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
  uncertainty <- drm_uncertainty_status(x)
  if (!identical(uncertainty, "ok")) {
    cli::cli_text(
      "  standard errors: unavailable; point estimates only ({drm_uncertainty_message(x)})"
    )
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
#'   `"sigma"`, `"hu"`, `"rho12"`, `"sd(id)"`, or
#'   `"sd_phylo(species)"`.
#' @param ... Reserved for future extractor options.
#'
#' @return A named numeric vector when `dpar` is supplied, otherwise a named
#'   list of coefficient vectors.
#' @export
#'
#' @examples
#' set.seed(20260525)
#' dat <- data.frame(
#'   y = 0.2 + 0.6 * seq(-1, 1, length.out = 24) + rnorm(24, sd = 0.5),
#'   x = seq(-1, 1, length.out = 24)
#' )
#' fit <- drmTMB(bf(y ~ x, sigma ~ x), data = dat)
#' fixef(fit)
#' fixef(fit, "mu")
#' coef(fit, "sigma")
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
#'   `"phylo_mu"`, or `"spatial_mu"`.
#' @param ... Reserved for future extractor options.
#'
#' @return A named list of random-effect blocks when `dpar = NULL`, otherwise
#'   one random-effect block.
#' @export
#'
#' @examples
#' set.seed(20260525)
#' id <- factor(rep(letters[1:8], each = 8))
#' x <- rep(seq(-1, 1, length.out = 8), times = 8)
#' u <- rnorm(nlevels(id), sd = 0.9)
#' dat <- data.frame(
#'   y = 0.2 + 0.7 * x + u[id] + rnorm(length(x), sd = 0.3),
#'   x = x,
#'   id = id
#' )
#' fit <- drmTMB(bf(y ~ x + (1 | id), sigma ~ 1), data = dat)
#' names(ranef(fit))
#' head(ranef(fit, "mu")$terms[["(1 | id)"]])
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

#' Extract likelihood weights
#'
#' `weights()` returns the row likelihood multipliers used by a fitted
#' `drmTMB` model after model-row filtering. These weights multiply
#' log-likelihood contributions. They are not known sampling variances or known
#' sampling covariance; use [meta_V()] for that meta-analytic role.
#'
#' @param object A `drmTMB` fit.
#' @param ... Reserved for future extractor options.
#'
#' @return A numeric vector with one weight per modelled response row, or per
#'   complete response pair for bivariate Gaussian models.
#' @importFrom stats weights
#' @export
#'
#' @examples
#' dat <- data.frame(
#'   y = c(0.2, 0.5, 1.1, 1.4),
#'   x = c(-1, 0, 1, 2),
#'   w = c(1, 1, 0.5, 2)
#' )
#' fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat, weights = w)
#' weights(fit)
weights.drmTMB <- function(object, ...) {
  object$model$weights
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
#'
#' @examples
#' set.seed(20260525)
#' n <- 36
#' x <- seq(-1, 1, length.out = n)
#' e1 <- rnorm(n)
#' e2 <- 0.4 * e1 + sqrt(1 - 0.4^2) * rnorm(n)
#' dat <- data.frame(
#'   y1 = 0.2 + 0.5 * x + e1,
#'   y2 = -0.1 + 0.3 * x + e2,
#'   x = x
#' )
#' fit <- drmTMB(
#'   bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ x),
#'   family = biv_gaussian(),
#'   data = dat
#' )
#' head(rho12(fit))
#' rho12(fit, newdata = data.frame(x = c(-0.5, 0, 0.5)))
rho12 <- function(object, ...) {
  UseMethod("rho12")
}

#' @rdname rho12
#' @export
rho12.drmTMB <- function(
  object,
  newdata = NULL,
  type = c("response", "link"),
  ...
) {
  type <- match.arg(type)
  if (!"rho12" %in% names(object$coefficients)) {
    cli::cli_abort(
      "This {.cls drmTMB} fit does not contain residual correlation {.code rho12}."
    )
  }
  predict.drmTMB(object, newdata = newdata, dpar = "rho12", type = type, ...)
}

#' Extract fitted correlation pairs
#'
#' `corpairs()` returns a long table of fitted correlation pairs from a
#' `drmTMB` model. The current implementation reports correlations that are
#' already fitted elsewhere: residual bivariate `rho12`, ordinary univariate
#' group-level `mu` random-effect correlations, matched univariate and
#' same-response bivariate `mu`/`sigma` random-intercept covariance blocks, and
#' matched bivariate `mu1`/`mu2` and `sigma1`/`sigma2` random-intercept
#' covariance blocks from `corpars`, plus fitted bivariate phylogenetic,
#' coordinate-spatial, animal-model, and `relmat()` correlation rows. Full q4
#' phylogenetic, coordinate-spatial, animal-model, and `relmat()` blocks report
#' six derived endpoint correlations; block-diagonal q4 fallback fits report
#' the direct `mu1`/`mu2` and `sigma1`/`sigma2` block correlations.
#'
#' Use `corpairs()` when the question is about correlations among fitted
#' residual, ordinary group-level, phylogenetic, coordinate-spatial,
#' animal-model, or `relmat()` latent effects. Use [rho12()] when the only
#' target is the residual correlation curve of a bivariate model.
#'
#' The table is intentionally more explicit than `rho12()` or `corpars` because
#' double-hierarchical, phylogenetic, spatial, animal-model, and lower-level
#' relatedness models can contain several scientifically different
#' correlations. Profile intervals are opt-in and can be slow; filter with
#' `level`, `group`, `block`, or `class` before requesting `conf.int = TRUE` on
#' large models. Bootstrap intervals are not a `corpairs()` route.
#'
#' @param object A `drmTMB` fit.
#' @param level Optional character vector of correlation levels to keep, such
#'   as `"residual"`, `"group"`, `"phylogenetic"`, or `"spatial"`.
#' @param group Optional character vector of grouping factors to keep, such as
#'   `"id"`. Residual rows have no grouping factor and are removed by this
#'   filter.
#' @param block Optional character vector of covariance-block labels to keep,
#'   such as `"p"`. Residual rows have no block label and are removed by this
#'   filter.
#' @param class Optional character vector of pair classes to keep, such as
#'   `"residual"` or `"mean-slope"`. Location aliases such as
#'   `"location-location"` and `"location-scale"` are accepted as filters for
#'   the current `"mean-mean"` and `"mean-scale"` rows.
#' @param conf.int Logical; include profile-likelihood confidence intervals
#'   where the correlation target is currently profile-ready. Unsupported
#'   derived targets receive an explicit interval status instead of silent
#'   missing bounds.
#' @param conf.level Confidence level used when `conf.int = TRUE`. This is
#'   named separately from the `level` filter to avoid ambiguity with
#'   correlation levels such as `"phylogenetic"`.
#' @param method Interval method used when `conf.int = TRUE`. Only
#'   `"profile"` is currently supported for correlation-pair intervals.
#' @param trace Logical; passed to [TMB::tmbprofile()] when profile intervals
#'   are requested.
#' @param ... Additional arguments passed to [TMB::tmbprofile()] when
#'   `conf.int = TRUE`.
#'
#' @return A data frame with one row per fitted correlation pair or pair
#'   summary. Predictor-dependent `rho12` is summarized by its mean, minimum,
#'   and maximum over the fitted rows. Rows include `conf.status` and
#'   `interval_source` so point-only and interval-aware pair tables use the same
#'   provenance vocabulary as prediction tables.
#'
#' @examples
#' set.seed(1)
#' n <- 40
#' x <- rnorm(n)
#' z1 <- rnorm(n)
#' z2 <- rnorm(n)
#' mu1 <- 0.2 + 0.5 * x
#' mu2 <- -0.1 + 0.4 * x
#' sigma1 <- exp(-0.2 + 0.15 * z1)
#' sigma2 <- exp(0.1 - 0.1 * z2)
#' rho <- 0.35
#' e1 <- rnorm(n)
#' e2 <- rho * e1 + sqrt(1 - rho^2) * rnorm(n)
#' dat <- data.frame(
#'   y1 = mu1 + sigma1 * e1,
#'   y2 = mu2 + sigma2 * e2,
#'   x = x,
#'   z1 = z1,
#'   z2 = z2
#' )
#' fit <- drmTMB(
#'   bf(
#'     mu1 = y1 ~ x,
#'     mu2 = y2 ~ x,
#'     sigma1 = ~ z1,
#'     sigma2 = ~ z2,
#'     rho12 = ~ 1
#'   ),
#'   family = c(gaussian(), gaussian()),
#'   data = dat
#' )
#' pairs <- corpairs(fit)
#' pairs
#' corpairs(fit, level = "residual")
#'
#' # Profile intervals are opt-in and can be slow for large models.
#' # corpairs(fit, level = "residual", conf.int = TRUE)
#' @export
corpairs <- function(object, ...) {
  UseMethod("corpairs")
}

#' @rdname corpairs
#' @export
corpairs.drmTMB <- function(
  object,
  level = NULL,
  group = NULL,
  block = NULL,
  class = NULL,
  conf.int = FALSE,
  conf.level = 0.95,
  method = "profile",
  trace = FALSE,
  ...
) {
  validate_summary_conf_int(conf.int)
  method <- validate_interval_method(method, "profile", "corpairs()")
  if (!conf.int && length(list(...)) > 0L) {
    cli::cli_abort(
      "Additional arguments in {.arg ...} are only used when {.code conf.int = TRUE}."
    )
  }

  rows <- list()

  if ("rho12" %in% names(object$coefficients)) {
    rows[[length(rows) + 1L]] <- residual_rho12_corpair(object)
  }

  phylo_rows <- phylo_mu_corpairs(object)
  if (length(phylo_rows) > 0L) {
    rows <- c(rows, phylo_rows)
  }

  registry_rows <- random_effect_registry_corpairs(object)
  if (length(registry_rows) > 0L) {
    rows <- c(rows, registry_rows)
  }
  structured_exclude <- structured_mu_corpars_keys(object)
  label_rows <- random_effect_label_corpairs(
    object,
    exclude = c(
      covariance_block_corpars_keys(
        object$model$random$covariance_blocks
      ),
      structured_exclude
    )
  )
  if (length(label_rows) > 0L) {
    rows <- c(rows, label_rows)
  }

  out <- if (length(rows) == 0L) {
    empty_corpairs()
  } else {
    do.call(rbind, rows)
  }

  if (!is.null(level)) {
    out <- out[out$level %in% level, , drop = FALSE]
  }
  if (!is.null(group)) {
    out <- out[out$group %in% group, , drop = FALSE]
  }
  if (!is.null(block)) {
    out <- out[out$block %in% block, , drop = FALSE]
  }
  if (!is.null(class)) {
    class <- normalize_corpairs_class_filter(class)
    out <- out[out$class %in% class, , drop = FALSE]
  }
  row.names(out) <- NULL
  out <- corpairs_add_default_interval_provenance(out)
  if (conf.int) {
    out <- corpairs_add_confint(
      object,
      out,
      level = conf.level,
      trace = trace,
      ...
    )
  }
  out
}

corpairs_add_confint <- function(object, pairs, level, trace, ...) {
  validate_profile_level(level)
  if (nrow(pairs) == 0L) {
    pairs$profile_target <- character()
    pairs$conf.low <- numeric()
    pairs$conf.high <- numeric()
    pairs$conf.level <- numeric()
    pairs$conf.method <- character()
    pairs$conf.status <- character()
    pairs$interval_source <- character()
    return(pairs)
  }

  targets <- drm_profile_targets(object)
  target_index <- corpairs_match_profile_targets(pairs, targets)
  target_rows <- targets[target_index, , drop = FALSE]

  profile_targets <- rep(NA_character_, nrow(pairs))
  has_target <- !is.na(target_index)
  profile_targets[has_target] <- target_rows$parm[has_target]
  profile_ready <- rep(FALSE, nrow(pairs))
  profile_ready[has_target] <- target_rows$profile_ready[has_target]
  ready_parms <- unique(profile_targets[profile_ready])

  ci <- empty_summary_confint()
  if (length(ready_parms) > 0L) {
    ci <- drm_profile_confint(
      object,
      parm = ready_parms,
      level = level,
      trace = trace,
      ...
    )
  }

  pairs$profile_target <- profile_targets
  pairs$conf.low <- NA_real_
  pairs$conf.high <- NA_real_
  pairs$conf.level <- level
  pairs$conf.method <- NA_character_
  pairs$conf.status <- corpairs_conf_status(pairs, target_rows, target_index)
  pairs$interval_source <- rep("not_available", nrow(pairs))

  if (nrow(ci) > 0L) {
    matched <- match(pairs$profile_target, ci$parm)
    has_ci <- !is.na(matched)
    pairs$conf.low[has_ci] <- ci$lower[matched[has_ci]]
    pairs$conf.high[has_ci] <- ci$upper[matched[has_ci]]
    pairs$conf.method[has_ci] <- ci$method[matched[has_ci]]
    pairs$conf.status[has_ci] <- "profile"
    pairs$interval_source[has_ci] <- "profile"
  }

  pairs
}

corpairs_add_default_interval_provenance <- function(pairs) {
  if (!"conf.status" %in% names(pairs)) {
    pairs$conf.status <- rep("not_requested", nrow(pairs))
  }
  if (!"interval_source" %in% names(pairs)) {
    pairs$interval_source <- rep("not_available", nrow(pairs))
  }
  pairs
}

corpairs_match_profile_targets <- function(pairs, targets) {
  if (nrow(pairs) == 0L) {
    return(integer())
  }
  if (nrow(targets) == 0L) {
    return(rep(NA_integer_, nrow(pairs)))
  }

  vapply(
    seq_len(nrow(pairs)),
    function(i) {
      pair <- pairs[i, , drop = FALSE]
      if (
        identical(pair$level[[1L]], "residual") &&
          identical(pair$parameter[[1L]], "rho12") &&
          !isTRUE(pair$modelled[[1L]])
      ) {
        hit <- which(targets$parm == "rho12")
        return(if (length(hit) == 1L) hit[[1L]] else NA_integer_)
      }

      if (
        identical(pair$level[[1L]], "residual") &&
          identical(pair$parameter[[1L]], "rho12")
      ) {
        return(NA_integer_)
      }

      hit <- which(
        targets$target_class == "random-effect-correlation" &
          targets$term == pair$parameter[[1L]]
      )
      structured_prefixes <- c(
        phylogenetic = "cor:phylo:",
        spatial = "cor:spatial:",
        animal = "cor:animal:",
        relmat = "cor:relmat:"
      )
      if (pair$level[[1L]] %in% names(structured_prefixes)) {
        hit <- hit[startsWith(
          targets$parm[hit],
          structured_prefixes[[pair$level[[1L]]]]
        )]
      } else if (identical(pair$level[[1L]], "group")) {
        hit <- hit[
          !Reduce(
            `|`,
            lapply(
              unname(structured_prefixes),
              function(prefix) startsWith(targets$parm[hit], prefix)
            )
          )
        ]
      }
      if (length(hit) == 1L) {
        return(hit[[1L]])
      }
      NA_integer_
    },
    integer(1L)
  )
}

corpairs_conf_status <- function(pairs, target_rows, target_index) {
  vapply(
    seq_len(nrow(pairs)),
    function(i) {
      if (is.na(target_index[[i]])) {
        if (
          isTRUE(pairs$modelled[[i]]) &&
            (identical(pairs$level[[i]], "residual") ||
              identical(pairs$level[[i]], "group") ||
              identical(pairs$level[[i]], "phylogenetic"))
        ) {
          return("newdata_required")
        }
        return("target_unavailable")
      }
      target <- target_rows[i, , drop = FALSE]
      if (isTRUE(target$profile_ready[[1L]])) {
        return("profile_ready")
      }
      if (identical(target$target_type[[1L]], "derived")) {
        return("derived_interval_unavailable")
      }
      interval_status_from_profile_note(
        profile_ready = target$profile_ready[[1L]],
        profile_note = target$profile_note[[1L]]
      )
    },
    character(1L)
  )
}

normalize_corpairs_class_filter <- function(class) {
  aliases <- c(
    "location-location" = "mean-mean",
    "location-scale" = "mean-scale",
    "location-slope" = "mean-slope",
    "slope-location" = "mean-slope"
  )
  mapped <- unname(aliases[class])
  class[!is.na(mapped)] <- mapped[!is.na(mapped)]
  unique(class)
}

empty_corpairs <- function() {
  data.frame(
    level = character(),
    group = character(),
    block = character(),
    from_dpar = character(),
    to_dpar = character(),
    from_coef = character(),
    to_coef = character(),
    from_response = character(),
    to_response = character(),
    class = character(),
    parameter = character(),
    estimate = numeric(),
    min = numeric(),
    max = numeric(),
    n_values = integer(),
    link_estimate = numeric(),
    link_min = numeric(),
    link_max = numeric(),
    modelled = logical(),
    conf.status = character(),
    interval_source = character(),
    stringsAsFactors = FALSE
  )
}

residual_rho12_corpair <- function(object) {
  rho <- predict(object, dpar = "rho12", type = "response")
  eta <- predict(object, dpar = "rho12", type = "link")
  n_coef <- length(coef(object, dpar = "rho12"))
  response_names <- bivariate_response_names(object)
  new_corpair_row(
    level = "residual",
    group = NA_character_,
    block = NA_character_,
    from_dpar = "residual",
    to_dpar = "residual",
    from_coef = NA_character_,
    to_coef = NA_character_,
    from_response = response_names[[1L]],
    to_response = response_names[[2L]],
    class = "residual",
    parameter = "rho12",
    estimate = mean(rho),
    min = min(rho),
    max = max(rho),
    n_values = length(rho),
    link_estimate = mean(eta),
    link_min = min(eta),
    link_max = max(eta),
    modelled = n_coef > 1L
  )
}

phylo_mu_corpairs <- function(object) {
  if (
    !object$model$model_type %in% c("gaussian", "biv_gaussian") ||
      !isTRUE(object$model$structured$phylo_mu$has)
  ) {
    return(list())
  }

  phylo_mu <- object$model$structured$phylo_mu
  cor_key <- structured_mu_correlation_key(phylo_mu)
  corpars <- object$corpars[[cor_key]]
  if (is.null(corpars) || length(corpars) == 0L) {
    return(list())
  }
  level <- structured_mu_corpair_level(phylo_mu)
  pair_table <- phylo_mu_pair_table(phylo_mu)
  lapply(seq_along(corpars), function(i) {
    estimate <- unname(corpars[[i]])
    parameter <- phylo_mu_correlation_parameter(object, i)
    pair <- pair_table[i, , drop = FALSE]
    model_dpar <- random_effect_correlation_model_dpar(object, cor_key, i)
    if (!is.na(model_dpar)) {
      rho <- predict(object, dpar = model_dpar, type = "response")
      eta <- predict(object, dpar = model_dpar, type = "link")
      estimate <- mean(rho)
      min_value <- min(rho)
      max_value <- max(rho)
      n_values <- length(rho)
      link_estimate <- mean(eta)
      link_min <- min(eta)
      link_max <- max(eta)
      modelled <- TRUE
    } else {
      min_value <- estimate
      max_value <- estimate
      n_values <- 1L
      link_estimate <- guarded_correlation_link(estimate, guard = 0.999999)
      link_min <- guarded_correlation_link(estimate, guard = 0.999999)
      link_max <- guarded_correlation_link(estimate, guard = 0.999999)
      modelled <- FALSE
    }
    new_corpair_row(
      level = level,
      group = phylo_mu$group,
      block = pair$block[[1L]],
      from_dpar = pair$from_dpar[[1L]],
      to_dpar = pair$to_dpar[[1L]],
      from_coef = "(Intercept)",
      to_coef = "(Intercept)",
      from_response = random_effect_response_name(object, pair$from_dpar[[1L]]),
      to_response = random_effect_response_name(object, pair$to_dpar[[1L]]),
      class = random_correlation_class(
        pair$from_dpar[[1L]],
        "(Intercept)",
        "(Intercept)",
        to_dpar = pair$to_dpar[[1L]]
      ),
      parameter = parameter,
      estimate = estimate,
      min = min_value,
      max = max_value,
      n_values = n_values,
      link_estimate = link_estimate,
      link_min = link_min,
      link_max = link_max,
      modelled = modelled
    )
  })
}

phylo_mu_correlation_parameter <- function(object, i = 1L) {
  phylo_mu <- object$model$structured$phylo_mu
  cor_key <- structured_mu_correlation_key(phylo_mu)
  phylo_names <- names(object$corpars[[cor_key]])
  parameter <- if (is.null(phylo_names) || length(phylo_names) < i) {
    NA_character_
  } else {
    phylo_names[[i]]
  }
  if (is.null(parameter) || is.na(parameter) || !nzchar(parameter)) {
    pair_table <- phylo_mu_pair_table(phylo_mu)
    parameter <- pair_table$parameter[[i]]
  }
  parameter
}

random_effect_registry_corpairs <- function(object) {
  registry <- object$model$random$covariance_blocks
  if (
    !is.list(registry) ||
      is.null(registry$pairs) ||
      nrow(registry$pairs) == 0L
  ) {
    return(list())
  }

  pairs <- registry$pairs
  pair_is_fitted <- !is.na(pairs$tmb_parameter) & !is.na(pairs$tmb_index)
  pairs <- pairs[pair_is_fitted, , drop = FALSE]
  if (nrow(pairs) == 0L) {
    return(list())
  }

  lapply(seq_len(nrow(pairs)), function(i) {
    pair <- pairs[i, , drop = FALSE]
    block <- registry$blocks[
      registry$blocks$block_id0 == pair$block_id0[[1L]],
      ,
      drop = FALSE
    ]
    if (nrow(block) != 1L) {
      cli::cli_abort(
        "Internal error: covariance-block registry pair has no matching block."
      )
    }
    cor_key <- covariance_block_corpars_key(pair$tmb_parameter[[1L]])
    cor_values <- object$corpars[[cor_key]]
    cor_index <- pair$tmb_index[[1L]]
    if (
      is.null(cor_values) || cor_index < 1L || cor_index > length(cor_values)
    ) {
      cli::cli_abort(
        "Internal error: covariance-block registry pair has no fitted correlation."
      )
    }
    estimate <- unname(cor_values[[cor_index]])
    model_dpar <- random_effect_correlation_model_dpar(
      object,
      cor_key,
      cor_index
    )
    if (!is.na(model_dpar)) {
      rho <- predict(object, dpar = model_dpar, type = "response")
      eta <- predict(object, dpar = model_dpar, type = "link")
      estimate <- mean(rho)
      min_value <- min(rho)
      max_value <- max(rho)
      n_values <- length(rho)
      link_estimate <- mean(eta)
      link_min <- min(eta)
      link_max <- max(eta)
      modelled <- TRUE
    } else {
      min_value <- estimate
      max_value <- estimate
      n_values <- 1L
      link_estimate <- guarded_correlation_link(estimate, guard = 0.999999)
      link_min <- guarded_correlation_link(estimate, guard = 0.999999)
      link_max <- guarded_correlation_link(estimate, guard = 0.999999)
      modelled <- FALSE
    }
    new_corpair_row(
      level = block$level[[1L]],
      group = block$group[[1L]],
      block = block$block_label[[1L]],
      from_dpar = pair$from_dpar[[1L]],
      to_dpar = pair$to_dpar[[1L]],
      from_coef = pair$from_coef[[1L]],
      to_coef = pair$to_coef[[1L]],
      from_response = random_effect_response_name(object, pair$from_dpar[[1L]]),
      to_response = random_effect_response_name(object, pair$to_dpar[[1L]]),
      class = pair$class[[1L]],
      parameter = pair$parameter[[1L]],
      estimate = estimate,
      min = min_value,
      max = max_value,
      n_values = n_values,
      link_estimate = link_estimate,
      link_min = link_min,
      link_max = link_max,
      modelled = modelled
    )
  })
}

random_effect_covariance_summaries <- function(object, intervals = NULL) {
  rows <- list(
    phylo_mu_covariance_summaries(object, intervals = intervals),
    registry_random_effect_covariance_summaries(object, intervals = intervals)
  )
  rows <- rows[vapply(rows, nrow, integer(1L)) > 0L]
  if (length(rows) == 0L) {
    return(empty_random_effect_covariance_summaries())
  }

  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

phylo_mu_covariance_summaries <- function(object, intervals = NULL) {
  if (
    !object$model$model_type %in% c("gaussian", "biv_gaussian") ||
      !isTRUE(object$model$structured$phylo_mu$has)
  ) {
    return(empty_random_effect_covariance_summaries())
  }

  phylo_mu <- object$model$structured$phylo_mu
  cor_key <- structured_mu_correlation_key(phylo_mu)
  corpars <- object$corpars[[cor_key]]
  if (is.null(corpars) || length(corpars) == 0L) {
    return(empty_random_effect_covariance_summaries())
  }
  level <- structured_mu_corpair_level(phylo_mu)
  group <- phylo_mu$group
  pair_table <- phylo_mu_pair_table(phylo_mu)
  sd_parameters <- phylo_mu_sd_labels(phylo_mu, object$model$model_type)
  covariance_interval_status <- covariance_summary_interval_status(intervals)

  rows <- lapply(seq_len(nrow(pair_table)), function(i) {
    pair <- pair_table[i, , drop = FALSE]
    parameter <- phylo_mu_correlation_parameter(object, i)
    correlation_target <- paste0("cor:", cor_key, ":", parameter)
    from_sd_parameter <- sd_parameters[[pair$from_index[[1L]]]]
    to_sd_parameter <- sd_parameters[[pair$to_index[[1L]]]]
    from_sd_summary <- phylo_mu_sd_summary(
      object,
      endpoint_index = pair$from_index[[1L]],
      scalar_parameter = from_sd_parameter
    )
    to_sd_summary <- phylo_mu_sd_summary(
      object,
      endpoint_index = pair$to_index[[1L]],
      scalar_parameter = to_sd_parameter
    )
    from_sd_parameter <- from_sd_summary$parameter
    to_sd_parameter <- to_sd_summary$parameter
    from_sd_target <- from_sd_summary$target
    to_sd_target <- to_sd_summary$target
    from_sd <- from_sd_summary$value
    to_sd <- to_sd_summary$value
    correlation <- unname(corpars[[i]])
    correlation_interval <- covariance_summary_interval(
      intervals,
      correlation_target
    )
    from_sd_interval <- covariance_summary_interval(intervals, from_sd_target)
    to_sd_interval <- covariance_summary_interval(intervals, to_sd_target)
    data.frame(
      level = level,
      group = group,
      block = pair$block[[1L]],
      from_dpar = pair$from_dpar[[1L]],
      to_dpar = pair$to_dpar[[1L]],
      from_coef = "(Intercept)",
      to_coef = "(Intercept)",
      from_response = random_effect_response_name(object, pair$from_dpar[[1L]]),
      to_response = random_effect_response_name(object, pair$to_dpar[[1L]]),
      class = random_correlation_class(
        pair$from_dpar[[1L]],
        "(Intercept)",
        "(Intercept)",
        to_dpar = pair$to_dpar[[1L]]
      ),
      parameter = parameter,
      correlation_target = correlation_target,
      from_sd_target = from_sd_target,
      to_sd_target = to_sd_target,
      correlation = correlation,
      from_sd_parameter = from_sd_parameter,
      to_sd_parameter = to_sd_parameter,
      from_sd = from_sd,
      to_sd = to_sd,
      from_variance = from_sd^2,
      to_variance = to_sd^2,
      covariance = correlation * from_sd * to_sd,
      from_scale = covariance_registry_member_scale(data.frame(
        dpar = pair$from_dpar[[1L]]
      )),
      to_scale = covariance_registry_member_scale(data.frame(
        dpar = pair$to_dpar[[1L]]
      )),
      correlation_conf.low = correlation_interval$lower,
      correlation_conf.high = correlation_interval$upper,
      correlation_conf.method = correlation_interval$method,
      from_sd_conf.low = from_sd_interval$lower,
      from_sd_conf.high = from_sd_interval$upper,
      from_sd_conf.method = from_sd_interval$method,
      to_sd_conf.low = to_sd_interval$lower,
      to_sd_conf.high = to_sd_interval$upper,
      to_sd_conf.method = to_sd_interval$method,
      covariance_conf.low = NA_real_,
      covariance_conf.high = NA_real_,
      covariance_conf.method = NA_character_,
      covariance_conf.status = covariance_interval_status,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

phylo_mu_sd_parameter <- function(dpar, group) {
  paste0(dpar, ":phylo(1 | ", group, ")")
}

phylo_mu_sd_value <- function(object, parameter, dpar = "mu") {
  value <- object$sdpars[[dpar]][[parameter]]
  if (is.null(value) && !identical(dpar, "mu")) {
    value <- object$sdpars$mu[[parameter]]
  }
  if (is.null(value)) {
    return(NA_real_)
  }
  unname(value)
}

phylo_mu_sd_summary <- function(object, endpoint_index, scalar_parameter) {
  direct_dpar <- phylo_mu_direct_sd_dpar(object, endpoint_index)
  if (!is.na(direct_dpar)) {
    values <- unname(object$sdpars[[direct_dpar]])
    values <- values[is.finite(values)]
    value <- if (length(values) > 0L) stats::median(values) else NA_real_
    return(list(
      parameter = paste0(direct_dpar, ":median"),
      target = paste0("sd:", direct_dpar, ":(median)"),
      value = value
    ))
  }

  phylo_mu <- object$model$structured$phylo_mu
  endpoint_dpar <- phylo_mu_endpoint_dpars(phylo_mu)[[endpoint_index]]
  sd_dpar <- if (identical(object$model$model_type, "biv_gaussian")) {
    "mu"
  } else {
    endpoint_dpar
  }

  list(
    parameter = scalar_parameter,
    target = paste0("sd:", sd_dpar, ":", scalar_parameter),
    value = phylo_mu_sd_value(object, scalar_parameter, dpar = sd_dpar)
  )
}

phylo_mu_direct_sd_dpar <- function(object, endpoint_index) {
  sd_phylo <- object$model$random_scale$phylo
  if (
    !is.list(sd_phylo) ||
      is.null(sd_phylo$n_models) ||
      sd_phylo$n_models == 0L
  ) {
    return(NA_character_)
  }
  hit <- which(unname(sd_phylo$target_endpoint) == endpoint_index)
  if (length(hit) == 0L) {
    return(NA_character_)
  }
  sd_phylo$dpars[[hit[[1L]]]]
}

registry_random_effect_covariance_summaries <- function(
  object,
  intervals = NULL
) {
  registry <- object$model$random$covariance_blocks
  if (
    !is.list(registry) ||
      is.null(registry$pairs) ||
      is.null(registry$members) ||
      is.null(registry$blocks) ||
      nrow(registry$pairs) == 0L
  ) {
    return(empty_random_effect_covariance_summaries())
  }

  pairs <- registry$pairs
  pair_is_fitted <- !is.na(pairs$tmb_parameter) & !is.na(pairs$tmb_index)
  pairs <- pairs[pair_is_fitted, , drop = FALSE]
  if (nrow(pairs) == 0L) {
    return(empty_random_effect_covariance_summaries())
  }

  rows <- lapply(seq_len(nrow(pairs)), function(i) {
    pair <- pairs[i, , drop = FALSE]
    block <- registry$blocks[
      registry$blocks$block_id0 == pair$block_id0[[1L]],
      ,
      drop = FALSE
    ]
    from_member <- covariance_registry_member_by_id(
      registry,
      block_id0 = pair$block_id0[[1L]],
      member_id0 = pair$from_member_id0[[1L]]
    )
    to_member <- covariance_registry_member_by_id(
      registry,
      block_id0 = pair$block_id0[[1L]],
      member_id0 = pair$to_member_id0[[1L]]
    )
    if (
      nrow(block) != 1L ||
        nrow(from_member) != 1L ||
        nrow(to_member) != 1L
    ) {
      cli::cli_abort(
        "Internal error: covariance-block registry pair has incomplete summary metadata."
      )
    }

    cor_key <- covariance_block_corpars_key(pair$tmb_parameter[[1L]])
    correlation_target <- paste0("cor:", cor_key, ":", pair$parameter[[1L]])
    from_sd_target <- covariance_registry_member_sd_target(from_member)
    to_sd_target <- covariance_registry_member_sd_target(to_member)
    cor_values <- object$corpars[[cor_key]]
    cor_index <- pair$tmb_index[[1L]]
    correlation <- if (
      is.null(cor_values) || cor_index < 1L || cor_index > length(cor_values)
    ) {
      NA_real_
    } else {
      unname(cor_values[[cor_index]])
    }
    from_sd <- covariance_registry_member_sd(object, from_member)
    to_sd <- covariance_registry_member_sd(object, to_member)
    from_variance <- from_sd^2
    to_variance <- to_sd^2
    covariance <- correlation * from_sd * to_sd
    correlation_interval <- covariance_summary_interval(
      intervals,
      correlation_target
    )
    from_sd_interval <- covariance_summary_interval(intervals, from_sd_target)
    to_sd_interval <- covariance_summary_interval(intervals, to_sd_target)
    covariance_interval_status <- covariance_summary_interval_status(intervals)

    data.frame(
      level = block$level[[1L]],
      group = block$group[[1L]],
      block = block$block_label[[1L]],
      from_dpar = pair$from_dpar[[1L]],
      to_dpar = pair$to_dpar[[1L]],
      from_coef = pair$from_coef[[1L]],
      to_coef = pair$to_coef[[1L]],
      from_response = random_effect_response_name(object, pair$from_dpar[[1L]]),
      to_response = random_effect_response_name(object, pair$to_dpar[[1L]]),
      class = pair$class[[1L]],
      parameter = pair$parameter[[1L]],
      correlation_target = correlation_target,
      from_sd_target = from_sd_target,
      to_sd_target = to_sd_target,
      correlation = correlation,
      from_sd_parameter = from_member$label[[1L]],
      to_sd_parameter = to_member$label[[1L]],
      from_sd = from_sd,
      to_sd = to_sd,
      from_variance = from_variance,
      to_variance = to_variance,
      covariance = covariance,
      from_scale = covariance_registry_member_scale(from_member),
      to_scale = covariance_registry_member_scale(to_member),
      correlation_conf.low = correlation_interval$lower,
      correlation_conf.high = correlation_interval$upper,
      correlation_conf.method = correlation_interval$method,
      from_sd_conf.low = from_sd_interval$lower,
      from_sd_conf.high = from_sd_interval$upper,
      from_sd_conf.method = from_sd_interval$method,
      to_sd_conf.low = to_sd_interval$lower,
      to_sd_conf.high = to_sd_interval$upper,
      to_sd_conf.method = to_sd_interval$method,
      covariance_conf.low = NA_real_,
      covariance_conf.high = NA_real_,
      covariance_conf.method = NA_character_,
      covariance_conf.status = covariance_interval_status,
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

empty_random_effect_covariance_summaries <- function() {
  data.frame(
    level = character(),
    group = character(),
    block = character(),
    from_dpar = character(),
    to_dpar = character(),
    from_coef = character(),
    to_coef = character(),
    from_response = character(),
    to_response = character(),
    class = character(),
    parameter = character(),
    correlation_target = character(),
    from_sd_target = character(),
    to_sd_target = character(),
    correlation = numeric(),
    from_sd_parameter = character(),
    to_sd_parameter = character(),
    from_sd = numeric(),
    to_sd = numeric(),
    from_variance = numeric(),
    to_variance = numeric(),
    covariance = numeric(),
    from_scale = character(),
    to_scale = character(),
    correlation_conf.low = numeric(),
    correlation_conf.high = numeric(),
    correlation_conf.method = character(),
    from_sd_conf.low = numeric(),
    from_sd_conf.high = numeric(),
    from_sd_conf.method = character(),
    to_sd_conf.low = numeric(),
    to_sd_conf.high = numeric(),
    to_sd_conf.method = character(),
    covariance_conf.low = numeric(),
    covariance_conf.high = numeric(),
    covariance_conf.method = character(),
    covariance_conf.status = character(),
    stringsAsFactors = FALSE
  )
}

covariance_registry_member_by_id <- function(registry, block_id0, member_id0) {
  registry$members[
    registry$members$block_id0 == block_id0 &
      registry$members$member_id0 == member_id0,
    ,
    drop = FALSE
  ]
}

covariance_registry_member_sd <- function(object, member) {
  sd_key <- covariance_registry_member_sd_key(member)
  sd_values <- object$sdpars[[sd_key]]
  if (is.null(sd_values)) {
    return(NA_real_)
  }
  value <- sd_values[[member$label[[1L]]]]
  if (is.null(value)) {
    return(NA_real_)
  }
  unname(value)
}

covariance_registry_member_sd_target <- function(member) {
  paste0(
    "sd:",
    covariance_registry_member_sd_key(member),
    ":",
    member$label[[1L]]
  )
}

covariance_registry_member_sd_key <- function(member) {
  dpar_family <- sub("[0-9]+$", "", member$dpar[[1L]])
  switch(
    dpar_family,
    mu = "mu",
    sigma = "sigma",
    dpar_family
  )
}

covariance_summary_interval <- function(intervals, parm) {
  if (is.null(intervals)) {
    return(covariance_summary_empty_interval())
  }
  if (!is.data.frame(intervals) || !"parm" %in% names(intervals)) {
    cli::cli_abort(
      "Internal error: covariance summary intervals must be a profile interval table."
    )
  }
  if (nrow(intervals) == 0L) {
    return(covariance_summary_empty_interval())
  }
  row <- intervals[intervals$parm == parm, , drop = FALSE]
  if (nrow(row) == 0L) {
    return(covariance_summary_empty_interval())
  }
  if (nrow(row) > 1L) {
    cli::cli_abort(
      "Internal error: covariance summary intervals contain duplicate targets."
    )
  }
  list(
    lower = if ("lower" %in% names(row)) row$lower[[1L]] else NA_real_,
    upper = if ("upper" %in% names(row)) row$upper[[1L]] else NA_real_,
    method = if ("method" %in% names(row)) {
      as.character(row$method[[1L]])
    } else {
      NA_character_
    }
  )
}

covariance_summary_empty_interval <- function() {
  list(lower = NA_real_, upper = NA_real_, method = NA_character_)
}

covariance_summary_interval_status <- function(intervals) {
  if (is.null(intervals)) {
    return("not_requested")
  }
  "derived_interval_unavailable"
}

covariance_registry_member_scale <- function(member) {
  dpar_family <- sub("[0-9]+$", "", member$dpar[[1L]])
  switch(
    dpar_family,
    mu = "identity",
    sigma = "log",
    "link"
  )
}

covariance_block_corpars_key <- function(tmb_parameter) {
  key <- switch(
    tmb_parameter,
    eta_cor_mu = "mu",
    eta_cor_sigma = "sigma",
    eta_cor_mu_sigma = "mu_sigma",
    theta_re_cov = "re_cov",
    NA_character_
  )
  if (is.na(key)) {
    cli::cli_abort(
      "Internal error: covariance-block registry pair uses an unknown correlation parameter."
    )
  }
  key
}

covariance_block_corpars_keys <- function(registry) {
  if (
    !is.list(registry) ||
      is.null(registry$pairs) ||
      nrow(registry$pairs) == 0L
  ) {
    return(character())
  }

  pairs <- registry$pairs
  pair_is_fitted <- !is.na(pairs$tmb_parameter) & !is.na(pairs$tmb_index)
  pairs <- pairs[pair_is_fitted, , drop = FALSE]
  if (nrow(pairs) == 0L) {
    return(character())
  }

  cor_keys <- vapply(
    pairs$tmb_parameter,
    covariance_block_corpars_key,
    character(1L)
  )
  paste(cor_keys, pairs$tmb_index, sep = ":")
}

random_effect_label_corpairs <- function(object, exclude = character()) {
  rows <- list()
  for (dpar in names(object$corpars)) {
    if (identical(dpar, "phylo")) {
      next
    }
    cor_values <- object$corpars[[dpar]]
    for (i in seq_along(cor_values)) {
      if (paste(dpar, i, sep = ":") %in% exclude) {
        next
      }
      rows[[length(rows) + 1L]] <- random_effect_corpair(
        object = object,
        dpar = dpar,
        label = names(cor_values)[[i]],
        estimate = unname(cor_values[[i]]),
        index = i
      )
    }
  }
  rows
}

structured_mu_corpars_keys <- function(object) {
  if (
    !object$model$model_type %in% c("gaussian", "biv_gaussian") ||
      !isTRUE(object$model$structured$phylo_mu$has)
  ) {
    return(character())
  }
  cor_key <- structured_mu_correlation_key(object$model$structured$phylo_mu)
  cor_values <- object$corpars[[cor_key]]
  if (is.null(cor_values) || length(cor_values) == 0L) {
    return(character())
  }
  paste(cor_key, seq_along(cor_values), sep = ":")
}

random_effect_corpair <- function(
  object,
  dpar,
  label,
  estimate,
  index = NA_integer_
) {
  parsed <- parse_random_correlation_label(label)
  from <- parse_random_correlation_endpoint(parsed$from_coef, dpar)
  to <- parse_random_correlation_endpoint(parsed$to_coef, dpar)
  model_dpar <- random_effect_correlation_model_dpar(object, dpar, index)
  if (!is.na(model_dpar)) {
    rho <- predict(object, dpar = model_dpar, type = "response")
    eta <- predict(object, dpar = model_dpar, type = "link")
    estimate <- mean(rho)
    min_value <- min(rho)
    max_value <- max(rho)
    n_values <- length(rho)
    link_estimate <- mean(eta)
    link_min <- min(eta)
    link_max <- max(eta)
    modelled <- TRUE
  } else {
    min_value <- estimate
    max_value <- estimate
    n_values <- 1L
    link_estimate <- guarded_correlation_link(estimate, guard = 0.999999)
    link_min <- guarded_correlation_link(estimate, guard = 0.999999)
    link_max <- guarded_correlation_link(estimate, guard = 0.999999)
    modelled <- FALSE
  }
  new_corpair_row(
    level = "group",
    group = parsed$group,
    block = parsed$block,
    from_dpar = from$dpar,
    to_dpar = to$dpar,
    from_coef = from$coef,
    to_coef = to$coef,
    from_response = random_effect_response_name(object, from$dpar),
    to_response = random_effect_response_name(object, to$dpar),
    class = random_correlation_class(
      from$dpar,
      from$coef,
      to$coef,
      to_dpar = to$dpar
    ),
    parameter = label,
    estimate = estimate,
    min = min_value,
    max = max_value,
    n_values = n_values,
    link_estimate = link_estimate,
    link_min = link_min,
    link_max = link_max,
    modelled = modelled
  )
}

random_effect_correlation_model_dpar <- function(object, dpar, index) {
  if (is.na(index)) {
    return(NA_character_)
  }
  model <- object$model$random$mu$cor_model
  if (!is.list(model) || model$n_models == 0L) {
    return(NA_character_)
  }
  if (identical(dpar, "mu") && !corpair_model_is_group(model)) {
    return(NA_character_)
  }
  if (identical(dpar, "phylo") && !corpair_model_is_phylogenetic(model)) {
    return(NA_character_)
  }
  if (!dpar %in% c("mu", "phylo")) {
    return(NA_character_)
  }
  if (index %in% model$target_cor) {
    return(model$dpar)
  }
  NA_character_
}

random_effect_correlation_is_modelled <- function(object, dpar, index) {
  !is.na(random_effect_correlation_model_dpar(object, dpar, index))
}

parse_random_correlation_endpoint <- function(value, default_dpar) {
  parts <- strsplit(value, ":", fixed = TRUE)[[1L]]
  if (
    length(parts) >= 2L &&
      parts[[1L]] %in% c("mu", "mu1", "mu2", "sigma", "sigma1", "sigma2")
  ) {
    return(list(
      dpar = parts[[1L]],
      coef = paste(parts[-1L], collapse = ":")
    ))
  }
  list(dpar = default_dpar, coef = value)
}

new_corpair_row <- function(
  level,
  group,
  block,
  from_dpar,
  to_dpar,
  from_coef,
  to_coef,
  from_response,
  to_response,
  class,
  parameter,
  estimate,
  min,
  max,
  n_values,
  link_estimate,
  link_min,
  link_max,
  modelled
) {
  data.frame(
    level = level,
    group = group,
    block = block,
    from_dpar = from_dpar,
    to_dpar = to_dpar,
    from_coef = from_coef,
    to_coef = to_coef,
    from_response = from_response,
    to_response = to_response,
    class = class,
    parameter = parameter,
    estimate = estimate,
    min = min,
    max = max,
    n_values = n_values,
    link_estimate = link_estimate,
    link_min = link_min,
    link_max = link_max,
    modelled = modelled,
    stringsAsFactors = FALSE
  )
}

parse_random_correlation_label <- function(label) {
  if (!startsWith(label, "cor(") || !endsWith(label, ")")) {
    return(list(
      from_coef = NA_character_,
      to_coef = NA_character_,
      group = NA_character_,
      block = NA_character_
    ))
  }

  inner <- substring(label, 5L, nchar(label) - 1L)
  pair_and_group <- strsplit(inner, " \\| ", fixed = FALSE)[[1L]]
  if (length(pair_and_group) < 2L) {
    return(list(
      from_coef = NA_character_,
      to_coef = NA_character_,
      group = NA_character_,
      block = NA_character_
    ))
  }

  pair <- pair_and_group[[1L]]
  pair_parts <- strsplit(pair, ",", fixed = TRUE)[[1L]]
  if (length(pair_parts) != 2L) {
    return(list(
      from_coef = NA_character_,
      to_coef = NA_character_,
      group = NA_character_,
      block = NA_character_
    ))
  }

  group_parts <- pair_and_group[-1L]
  if (length(group_parts) == 2L) {
    block <- group_parts[[1L]]
    group <- group_parts[[2L]]
  } else {
    block <- NA_character_
    group <- paste(group_parts, collapse = " | ")
  }

  list(
    from_coef = trimws(pair_parts[[1L]]),
    to_coef = trimws(pair_parts[[2L]]),
    group = trimws(group),
    block = trimws(block)
  )
}

random_correlation_class <- function(dpar, from_coef, to_coef, to_dpar = dpar) {
  from_family <- sub("[0-9]+$", "", dpar)
  to_family <- sub("[0-9]+$", "", to_dpar)
  from_intercept <- identical(from_coef, "(Intercept)")
  to_intercept <- identical(to_coef, "(Intercept)")
  if (identical(from_family, "mu") && identical(to_family, "mu")) {
    if (from_intercept && to_intercept) {
      return("mean-mean")
    }
    if (!from_intercept && !to_intercept) {
      return("slope-slope")
    }
    return("mean-slope")
  }
  if (identical(from_family, "sigma") && identical(to_family, "sigma")) {
    if (from_intercept && to_intercept) {
      return("scale-scale")
    }
    if (!from_intercept && !to_intercept) {
      return("malleability")
    }
    return("scale-slope")
  }
  if (
    (identical(from_family, "mu") && identical(to_family, "sigma")) ||
      (identical(from_family, "sigma") && identical(to_family, "mu"))
  ) {
    if (from_intercept && to_intercept) {
      return("mean-scale")
    }
    if (identical(from_family, "mu") && !from_intercept && to_intercept) {
      return("slope-scale")
    }
    if (identical(from_family, "sigma") && from_intercept && !to_intercept) {
      return("slope-scale")
    }
    return("mean-scale-slope")
  }
  paste0(dpar, "-", dpar)
}

guarded_correlation_link <- function(x, guard) {
  atanh(pmax(pmin(x / guard, 1 - 1e-12), -1 + 1e-12))
}

bivariate_response_names <- function(object) {
  c(
    response_name_from_model_frame(object, "mu1", fallback = "y1"),
    response_name_from_model_frame(object, "mu2", fallback = "y2")
  )
}

univariate_response_name <- function(object, dpar) {
  response_name_from_model_frame(object, "mu", fallback = NA_character_)
}

random_effect_response_name <- function(object, dpar) {
  if (identical(object$model$model_type, "biv_gaussian")) {
    response_names <- bivariate_response_names(object)
    if (dpar %in% c("mu1", "sigma1")) {
      return(response_names[[1L]])
    }
    if (dpar %in% c("mu2", "sigma2")) {
      return(response_names[[2L]])
    }
  }
  univariate_response_name(object, dpar)
}

response_name_from_model_frame <- function(object, dpar, fallback) {
  response_name <- object$model$response_names[[dpar]]
  if (
    is.character(response_name) &&
      length(response_name) == 1L &&
      !is.na(response_name)
  ) {
    return(response_name)
  }
  mf <- object$model$model_frame[[dpar]]
  if (is.data.frame(mf) && ncol(mf) > 0L) {
    return(names(mf)[[1L]])
  }
  fallback
}

#' Extract fitted response values
#'
#' `fitted()` returns fitted response values from a `drmTMB` model. For
#' univariate Gaussian, Student-t, Gamma, beta, beta-binomial, ordinary Poisson,
#' ordinary negative-binomial, and cumulative-logit ordinal fits this is the
#' fitted response summary. For beta-binomial fits, that summary is the fitted
#' success probability `mu`. For ordinal fits, that summary is the expected
#' ordered category score, `sum_k k * Pr(y_i = k)`. For zero-truncated
#' negative-binomial 2 fits this is the positive-count mean
#' `mu / (1 - Pr_NB2(0))`, where `mu` is the untruncated NB2 component mean.
#' For hurdle negative-binomial 2 fits this is the unconditional response mean
#' `(1 - hu) * mu / (1 - Pr_NB2(0))`.
#' For zero-inflated Poisson and zero-inflated negative-binomial 2 fits this is
#' the unconditional response mean `(1 - zi) * mu`, where `mu` is the
#' conditional count mean. For bivariate Gaussian fits this is a
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
#'
#' @examples
#' dat <- data.frame(y = c(0.2, 0.5, 1.1, 1.4), x = c(-1, 0, 1, 2))
#' fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat)
#' fitted(fit)
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

#' @rdname model-fit-extractors
#' @export
vcov.drmTMB <- function(object, ...) {
  cov_fixed <- drm_sdreport_cov_fixed(object)
  labels <- coefficient_labels(object)
  targets <- drm_profile_targets(object)
  targets <- targets[targets$target_class == "fixed-effect", , drop = FALSE]
  matched <- match(paste0("fixef:", labels), targets$parm)
  positions <- rep(NA_integer_, length(labels))
  opt_names <- names(object$opt$par)
  for (i in seq_along(labels)) {
    row <- matched[[i]]
    if (is.na(row)) {
      next
    }
    hits <- which(opt_names == targets$tmb_parameter[[row]])
    index <- targets$index[[row]]
    if (!is.na(index) && index >= 1L && index <= length(hits)) {
      positions[[i]] <- hits[[index]]
    }
  }
  out <- matrix(NA_real_, nrow = length(labels), ncol = length(labels))
  ok <- !is.na(positions)
  out[ok, ok] <- cov_fixed[
    positions[ok],
    positions[ok],
    drop = FALSE
  ]
  dimnames(out) <- list(labels, labels)
  out
}

drm_sdreport_cov_fixed <- function(object) {
  if (!drm_has_sdreport_covariance(object)) {
    cli::cli_abort(c(
      drm_sdreport_unavailable_message(object),
      "i" = "Refit with {.code control = drm_control(se = TRUE)} for {.fn vcov}, Wald standard errors, or Wald confidence intervals."
    ))
  }
  object$sdr$cov.fixed
}

drm_has_sdreport_covariance <- function(object) {
  !is.null(object$sdr) &&
    !is.null(object$sdr$cov.fixed) &&
    is.matrix(object$sdr$cov.fixed)
}

drm_uncertainty_status <- function(object) {
  state <- object$uncertainty
  if (
    is.list(state) &&
      is.character(state$status) &&
      length(state$status) == 1L &&
      !is.na(state$status) &&
      nzchar(state$status)
  ) {
    return(state$status)
  }
  if (!is.null(object$sdr)) {
    return("ok")
  }
  "unavailable"
}

drm_uncertainty_message <- function(object) {
  state <- object$uncertainty
  if (
    is.list(state) &&
      is.character(state$message) &&
      length(state$message) == 1L &&
      !is.na(state$message) &&
      nzchar(state$message)
  ) {
    return(state$message)
  }
  switch(
    drm_uncertainty_status(object),
    ok = "TMB::sdreport() completed successfully.",
    skipped = paste(
      "TMB::sdreport() was skipped because",
      "drm_control(se = FALSE) was used."
    ),
    failed = "TMB::sdreport() failed.",
    "This fit does not contain a TMB::sdreport() object."
  )
}

drm_sdreport_unavailable_message <- function(object) {
  status <- drm_uncertainty_status(object)
  if (identical(status, "skipped")) {
    return(paste(
      "Fixed-effect covariance is unavailable because TMB::sdreport()",
      "was skipped by drm_control(se = FALSE)."
    ))
  }
  if (identical(status, "failed")) {
    return(paste(
      "Fixed-effect covariance is unavailable because",
      drm_uncertainty_message(object)
    ))
  }
  "Fixed-effect covariance is unavailable because this drmTMB fit does not contain a TMB::sdreport() object."
}

drm_uncertainty_check_status <- function(object) {
  if (identical(drm_uncertainty_status(object), "skipped")) {
    return("note")
  }
  "warning"
}

drm_standard_error_status <- function(object) {
  switch(
    drm_uncertainty_status(object),
    skipped = "sdreport_skipped",
    failed = "sdreport_failed",
    ok = "ok",
    "sdreport_unavailable"
  )
}

#' Extract standard model-fit quantities
#'
#' These methods expose `drmTMB` fits to standard base-R model summary and
#' comparison helpers.
#'
#' `logLik()` returns a `"logLik"` object with `df` and `nobs` attributes so
#' [stats::AIC()] and [stats::BIC()] use the fitted likelihood, optimized
#' top-level parameter count, and fitted-row count consistently.
#' `nobs()` returns the number of fitted rows after complete-case filtering.
#' `df.residual()` returns `nobs - df`, where `df` is the number of optimized
#' top-level parameters recorded in `logLik()`. `deviance()` returns
#' `-2 * logLik`; for these likelihood-based distributional models this is an
#' absolute negative twice log-likelihood value, not a saturated-model GLM
#' deviance. `vcov()` returns the fixed-effect covariance matrix from
#' `TMB::sdreport()` with rows and columns labelled by distributional
#' parameter and coefficient. It intentionally does not include random-effect
#' conditional modes or derived response-scale quantities.
#'
#' @param object A `drmTMB` fit.
#' @param ... Reserved for future extractor options.
#'
#' @return `logLik()` returns an object of class `"logLik"`. The other methods
#'   return numeric scalars.
#'
#' @examples
#' set.seed(20260524)
#' n <- 36
#' x <- seq(-1.5, 1.5, length.out = n)
#' dat <- data.frame(
#'   y = 0.3 + 0.6 * x + rnorm(n, sd = 0.7),
#'   x = x
#' )
#' fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat)
#'
#' logLik(fit)
#' nobs(fit)
#' df.residual(fit)
#' deviance(fit)
#' AIC(fit)
#' BIC(fit)
#' vcov(fit)
#' @name model-fit-extractors
NULL

#' @rdname model-fit-extractors
#' @export
logLik.drmTMB <- function(object, ...) {
  out <- object$logLik
  attr(out, "df") <- object$df
  attr(out, "nobs") <- object$nobs
  class(out) <- "logLik"
  out
}

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
#' the exponentiated value. For bivariate residual correlation `rho12` or a
#' fitted `corpair()` model, this means the correlation scale. Use
#' `type = "link"` to return the linear predictor instead.
#'
#' When `newdata = NULL`, predictions are for the fitted rows and include
#' currently implemented conditional random-effect contributions for `mu`,
#' including registry-backed q > 2 ordinary covariance blocks, bivariate
#' `mu1`/`mu2`, phylogenetic `mu`, and residual-scale `sigma` including
#' bivariate `sigma1`/`sigma2` blocks. When `newdata` is supplied, predictions
#' are fixed-effect, population-level
#' predictions for the supplied rows.
#'
#' @param object A `drmTMB` fit.
#' @param newdata Optional data frame for prediction. If omitted, fitted rows
#'   are used. When supplied, `newdata` must include the predictors used by the
#'   requested `dpar`; required predictor values must be complete, required
#'   numeric predictors must be finite, and factor predictors must use fitted
#'   levels. Transformed predictor terms, such as `log(size)`, must also
#'   evaluate to finite design-matrix values.
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
#' fit <- drmTMB(bf(y ~ x, sigma ~ x), data = dat)
#' predict(fit, dpar = "mu")
#' predict(fit, dpar = "sigma")
#' predict(fit, dpar = "sigma", type = "link")
#' predict(fit, newdata = data.frame(x = c(0, 1)), dpar = "mu")
#' @export
predict.drmTMB <- function(
  object,
  newdata = NULL,
  dpar = NULL,
  type = c("response", "link"),
  ...
) {
  if (is.null(dpar)) {
    dpar <- object$model$dpars[[1L]]
  }
  dpar <- match.arg(dpar, names(object$coefficients))
  type <- match.arg(type)
  if (is_random_scale_dpar(object, dpar)) {
    return(predict_random_scale_dpar(
      object,
      dpar,
      newdata = newdata,
      type = type
    ))
  }
  basis <- drm_fixed_effect_basis(object, newdata = newdata, dpar = dpar)
  eta <- basis$eta
  if (
    is.null(newdata) &&
      dpar %in% mu_random_effect_dpars(object) &&
      has_ordinary_mu_random_effects(object)
  ) {
    eta <- eta + mu_random_effect_contribution(object, dpar = dpar)
  }
  if (
    is.null(newdata) &&
      dpar %in% c("mu", "mu1", "mu2") &&
      has_covariance_block_random_effects(object)
  ) {
    eta <- eta +
      covariance_block_random_effect_contribution(
        object,
        dpar = dpar
      )
  }
  if (
    is.null(newdata) &&
      dpar %in% phylo_mu_dpars(object$model$structured$phylo_mu) &&
      has_structured_mu_effect(object)
  ) {
    eta <- eta + phylo_mu_contribution(object, dpar = dpar)
  }
  if (
    is.null(newdata) &&
      dpar %in% sigma_random_effect_dpars(object) &&
      has_sigma_random_effects(object)
  ) {
    eta <- eta + sigma_random_effect_contribution(object, dpar = dpar)
  }
  if (
    is.null(newdata) &&
      dpar %in% c("sigma", "sigma1", "sigma2") &&
      has_covariance_block_random_effects(object)
  ) {
    eta <- eta +
      covariance_block_random_effect_contribution(
        object,
        dpar = dpar
      )
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
#' `phi = 1 / sigma^2`. For beta-binomial models, simulation draws latent
#' success probabilities from the fitted beta distribution and then success
#' counts from the stored trial denominators. For cumulative-logit ordinal
#' models, simulation draws ordered categories from the fitted cumulative-logit
#' probabilities. For Poisson models, simulation uses the fitted mean `mu`. For
#' zero-inflated Poisson models, simulation uses
#' fitted conditional mean `mu` and structural-zero probability `zi`. For
#' negative-binomial 2 models, simulation uses fitted `mu` and overdispersion
#' scale `sigma`, with `Var(y) = mu + sigma^2 * mu^2`; zero-truncated NB2
#' models draw from this NB2 component conditional on positive counts. The
#' zero-inflated NB2 path adds structural-zero probability `zi`; the hurdle NB2
#' path adds hurdle-zero probability `hu` and draws nonzero counts from the
#' zero-truncated NB2 component. For bivariate
#' Gaussian models without known
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
#' fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat)
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
    on.exit(
      {
        if (had_seed) {
          assign(".Random.seed", old_seed, envir = .GlobalEnv)
        } else if (
          exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
        ) {
          rm(".Random.seed", envir = .GlobalEnv)
        }
      },
      add = TRUE
    )
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
    sims <- replicate(
      nsim,
      stats::rlnorm(length(mu), meanlog = mu, sdlog = sigma)
    )
    sims <- as.data.frame(sims)
    names(sims) <- paste0("sim_", seq_len(nsim))
    return(sims)
  }

  if (identical(object$model$model_type, "gamma")) {
    mu <- predict(object, dpar = "mu")
    sigma <- predict(object, dpar = "sigma")
    shape <- 1 / sigma^2
    scale <- mu * sigma^2
    sims <- replicate(
      nsim,
      stats::rgamma(length(mu), shape = shape, scale = scale)
    )
    sims <- as.data.frame(sims)
    names(sims) <- paste0("sim_", seq_len(nsim))
    return(sims)
  }

  if (identical(object$model$model_type, "beta")) {
    mu <- predict(object, dpar = "mu")
    sigma <- predict(object, dpar = "sigma")
    phi <- 1 / sigma^2
    sims <- replicate(
      nsim,
      stats::rbeta(
        length(mu),
        shape1 = mu * phi,
        shape2 = (1 - mu) * phi
      )
    )
    sims <- as.data.frame(sims)
    names(sims) <- paste0("sim_", seq_len(nsim))
    return(sims)
  }

  if (identical(object$model$model_type, "beta_binomial")) {
    mu <- predict(object, dpar = "mu")
    sigma <- predict(object, dpar = "sigma")
    phi <- 1 / sigma^2
    trials <- object$model$trials
    sims <- replicate(nsim, {
      p <- stats::rbeta(
        length(mu),
        shape1 = mu * phi,
        shape2 = (1 - mu) * phi
      )
      stats::rbinom(length(mu), size = trials, prob = p)
    })
    sims <- as.data.frame(sims)
    names(sims) <- paste0("sim_", seq_len(nsim))
    return(sims)
  }

  if (identical(object$model$model_type, "cumulative_logit")) {
    prob <- ordinal_category_probabilities(object)
    levels <- object$ordinal$levels
    sims <- lapply(seq_len(nsim), function(j) {
      draw <- vapply(
        seq_len(nrow(prob)),
        function(i) {
          sample.int(ncol(prob), size = 1L, prob = prob[i, ])
        },
        integer(1)
      )
      ordered(levels[draw], levels = levels)
    })
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
    sims <- replicate(
      nsim,
      stats::rnbinom(length(mu), size = 1 / sigma^2, mu = mu)
    )
    sims <- as.data.frame(sims)
    names(sims) <- paste0("sim_", seq_len(nsim))
    return(sims)
  }

  if (identical(object$model$model_type, "truncated_nbinom2")) {
    mu <- predict(object, dpar = "mu")
    sigma <- predict(object, dpar = "sigma")
    p0 <- truncated_nbinom2_p0(mu, sigma)
    sims <- replicate(nsim, {
      u <- p0 + stats::runif(length(mu)) * (1 - p0)
      stats::qnbinom(u, size = 1 / sigma^2, mu = mu)
    })
    sims <- as.data.frame(sims)
    names(sims) <- paste0("sim_", seq_len(nsim))
    return(sims)
  }

  if (identical(object$model$model_type, "hurdle_nbinom2")) {
    mu <- predict(object, dpar = "mu")
    sigma <- predict(object, dpar = "sigma")
    hu <- predict(object, dpar = "hu")
    p0 <- truncated_nbinom2_p0(mu, sigma)
    sims <- replicate(nsim, {
      hurdle_zero <- stats::runif(length(mu)) < hu
      u <- p0 + pmax(stats::runif(length(mu)), .Machine$double.eps) * (1 - p0)
      ifelse(
        hurdle_zero,
        0L,
        stats::qnbinom(u, size = 1 / sigma^2, mu = mu)
      )
    })
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
      sims <- replicate(
        nsim,
        as.vector(mu + t(chol_Sigma) %*% stats::rnorm(length(mu)))
      )
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
#' the coefficient of variation. For beta-binomial models, response residuals
#' are observed success proportions minus fitted `mu`, and Pearson residuals
#' divide by the fitted beta-binomial proportion standard deviation. For
#' cumulative-logit ordinal models, response residuals are the observed
#' ordered-category score minus the fitted expected score, and Pearson
#' residuals divide by the fitted category-score standard deviation. For
#' Poisson models, response residuals are `y - mu` and Pearson residuals divide
#' by `sqrt(mu)`. For zero-inflated
#' Poisson models, response residuals are `y - (1 - zi) * mu`, and Pearson
#' residuals divide by `sqrt((1 - zi) * mu * (1 + zi * mu))`. For
#' negative-binomial 2 models, Pearson residuals divide by
#' `sqrt(mu + sigma^2 * mu^2)`. For zero-truncated NB2 models, response
#' residuals are `y - mu / (1 - Pr_NB2(0))`, and Pearson residuals divide by
#' the conditional positive-count standard deviation. For hurdle NB2 models,
#' response residuals are `y - (1 - hu) * mu / (1 - Pr_NB2(0))`, and Pearson
#' residuals divide by the unconditional standard deviation implied by the
#' hurdle-zero mixture. For zero-inflated NB2 models, response residuals are
#' `y - (1 - zi) * mu`, and Pearson residuals divide by the unconditional
#' standard deviation implied by the structural-zero mixture.
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
#' fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat)
#' residuals(fit)
#' residuals(fit, type = "pearson")
#' @export
residuals.drmTMB <- function(object, type = c("response", "pearson"), ...) {
  type <- match.arg(type)
  if (identical(object$model$model_type, "lognormal")) {
    if (type == "response") {
      return(object$model$y - stats::fitted(object))
    }
    return(
      (log(object$model$y) - predict(object, dpar = "mu")) /
        predict(object, dpar = "sigma")
    )
  }
  if (identical(object$model$model_type, "gamma")) {
    response <- object$model$y - predict(object, dpar = "mu")
    if (type == "response") {
      return(response)
    }
    return(
      response /
        (predict(object, dpar = "mu") * predict(object, dpar = "sigma"))
    )
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
  if (identical(object$model$model_type, "beta_binomial")) {
    mu <- predict(object, dpar = "mu")
    sigma <- predict(object, dpar = "sigma")
    trials <- object$model$trials
    observed <- object$model$y / trials
    response <- observed - mu
    if (type == "response") {
      return(response)
    }
    return(
      response / sqrt(beta_binomial_proportion_variance(mu, sigma, trials))
    )
  }
  if (identical(object$model$model_type, "cumulative_logit")) {
    expected <- ordinal_expected_score(object)
    response <- object$model$y - expected
    if (type == "response") {
      return(response)
    }
    return(
      response / sqrt(pmax(ordinal_score_variance(object), .Machine$double.eps))
    )
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
  if (identical(object$model$model_type, "truncated_nbinom2")) {
    mu <- predict(object, dpar = "mu")
    sigma <- predict(object, dpar = "sigma")
    fitted_mean <- truncated_nbinom2_mean(mu, sigma)
    response <- object$model$y - fitted_mean
    if (type == "response") {
      return(response)
    }
    return(response / sqrt(truncated_nbinom2_variance(mu, sigma)))
  }
  if (identical(object$model$model_type, "hurdle_nbinom2")) {
    mu <- predict(object, dpar = "mu")
    sigma <- predict(object, dpar = "sigma")
    hu <- predict(object, dpar = "hu")
    fitted_mean <- hurdle_nbinom2_mean(mu, sigma, hu)
    response <- object$model$y - fitted_mean
    if (type == "response") {
      return(response)
    }
    return(response / sqrt(hurdle_nbinom2_variance(mu, sigma, hu)))
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
  if (
    identical(object$model$model_type, "gaussian") ||
      identical(object$model$model_type, "student")
  ) {
    response <- object$model$y - predict(object, dpar = "mu")
    if (type == "response") {
      return(response)
    }
    if (identical(object$model$V_known_type, "matrix")) {
      return(as.vector(forwardsolve(
        t(chol(observation_covariance(object))),
        response
      )))
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
#' coefficient of variation. For beta and beta-binomial models this is the
#' public scale parameter where internal precision is `phi = 1 / sigma^2`.
#' Cumulative-logit ordinal, Poisson, and zero-inflated Poisson models have no
#' fitted residual scale parameter and return a fixed unit dispersion vector
#' for consistency with base-R `sigma()` conventions. For
#' negative-binomial 2, zero-truncated negative-binomial 2, hurdle
#' negative-binomial 2, and zero-inflated negative-binomial 2 models this is
#' the fitted overdispersion scale in the untruncated NB2 component
#' `Var(y | component) = mu + sigma^2 * mu^2`. For bivariate Gaussian models
#' it returns a roundable list with fitted `sigma1` and `sigma2` vectors.
#'
#' In meta-analytic models fitted with `meta_V(V = V)`, this is the
#' modelled residual heterogeneity scale, not the square root of the known
#' sampling variance plus residual variance. Simulation and Pearson residuals
#' combine known sampling covariance with residual scale internally.
#'
#' @param object A `drmTMB` fit.
#' @param ... Reserved for future scale-extractor options.
#'
#' @return A numeric vector for univariate models, or a named, roundable list
#'   of numeric vectors for bivariate Gaussian models.
#'
#' @examples
#' dat <- data.frame(y = c(0.2, 0.5, 1.1, 1.4), x = c(-1, 0, 1, 2))
#' fit <- drmTMB(bf(y ~ x, sigma ~ x), data = dat)
#' sigma(fit)
#' @export
sigma.drmTMB <- function(object, ...) {
  if (
    identical(object$model$model_type, "gaussian") ||
      identical(object$model$model_type, "student") ||
      identical(object$model$model_type, "lognormal") ||
      identical(object$model$model_type, "gamma") ||
      identical(object$model$model_type, "beta") ||
      identical(object$model$model_type, "beta_binomial") ||
      identical(object$model$model_type, "nbinom2") ||
      identical(object$model$model_type, "truncated_nbinom2") ||
      identical(object$model$model_type, "hurdle_nbinom2") ||
      identical(object$model$model_type, "zi_nbinom2")
  ) {
    return(predict(object, dpar = "sigma"))
  }
  if (
    identical(object$model$model_type, "poisson") ||
      identical(object$model$model_type, "zi_poisson") ||
      identical(object$model$model_type, "cumulative_logit")
  ) {
    return(rep(1, object$nobs))
  }
  new_biv_sigma(
    sigma1 = predict(object, dpar = "sigma1"),
    sigma2 = predict(object, dpar = "sigma2")
  )
}

new_biv_sigma <- function(sigma1, sigma2) {
  structure(
    list(sigma1 = sigma1, sigma2 = sigma2),
    class = c("drmTMB_biv_sigma", "list")
  )
}

#' @export
round.drmTMB_biv_sigma <- function(x, digits = 0) {
  out <- lapply(unclass(x), round, digits = digits)
  structure(out, class = class(x))
}

#' Summarize a fitted model
#'
#' `summary()` returns a compact summary of fixed-effect estimates,
#' response-scale distributional, scale, shape, random-effect SD, correlation,
#' and fitted random-effect covariance quantities when they are present.
#' The covariance component reports currently fitted registry-backed rows and
#' fitted bivariate phylogenetic covariance rows, including q=2 mean-mean and
#' q=4 endpoint rows where present.
#' The derived component reports simple point-estimate variance ratios, such as
#' Gaussian random-intercept repeatability and phylogenetic signal, when the
#' ingredients are unambiguous. Derived confidence intervals are marked as
#' unavailable until a nonlinear interval method is implemented.
#' When `TMB::sdreport()` succeeds, direct response-scale parameter rows also
#' include delta-method standard errors; descriptive fitted ranges and derived
#' variance ratios do not.
#' Confidence intervals are opt-in: fast Wald intervals are available for fixed
#' effects and direct response-scale parameter rows, and slower
#' profile-likelihood intervals are available for selected direct profile
#' targets. Profile summaries keep Wald intervals for fixed effects unless
#' fixed-effect profile targets are selected. Interval-aware tables include
#' `conf.status` so rows without intervals can say whether an interval was not
#' requested, needs `newdata`, is ready but unselected, or is currently
#' unavailable. Use `summary(fit, conf.int = TRUE)` for fixed-effect and direct
#' parameter Wald confidence intervals, and use `method = "profile"` with
#' `ci_parm` for direct response-scale targets such as `sigma`, `rho12`, or a
#' random-effect SD. Correlation Wald intervals use the fitted TMB
#' correlation-link scale, equivalent to a guarded Fisher z/atanh transform,
#' before returning lower and upper bounds on the correlation scale.
#'
#' @param object A `drmTMB` fit.
#' @param conf.int Logical; include confidence intervals when `TRUE`.
#' @param level Confidence level for intervals.
#' @param method Interval method used when `conf.int = TRUE`: `"wald"` for
#'   fast direct intervals or `"profile"` for profile-likelihood intervals on
#'   selected direct targets. `summary()` does not run bootstrap intervals yet;
#'   use `confint(..., method = "bootstrap")` for the current direct-target
#'   bootstrap route.
#' @param ci_parm Optional character or integer vector selecting confidence
#'   interval targets. For `method = "wald"` and `method = "profile"`, targets
#'   use the [profile_targets()] namespace, such as `"sigma"`, `"rho12"`,
#'   `"sd:mu:(1 | id)"`, or `"cor:mu:cor((Intercept),x | id)"`. `NULL` selects
#'   all direct Wald-ready targets for Wald intervals and currently ready direct
#'   non-fixed targets for profile intervals. This keeps large profile runs
#'   focused on scale, variance-component, and correlation rows unless
#'   fixed-effect profile targets are requested explicitly.
#' @param trace Logical; passed to [TMB::tmbprofile()] for profile intervals.
#' @param profile_precision Profile-control shortcut used with
#'   `method = "profile"`. `"default"` leaves [TMB::tmbprofile()] controls
#'   unchanged, while `"fast"` supplies `ystep = 0.5` and `ytol = 2` unless the
#'   caller supplies those controls in `...`.
#' @param ... Additional arguments passed to [TMB::tmbprofile()] when
#'   `conf.int = TRUE` and `method = "profile"`.
#'
#' @return An object of class `summary.drmTMB`.
#'
#' @examples
#' dat <- data.frame(y = c(0.2, 0.5, 1.1, 1.4), x = c(-1, 0, 1, 2))
#' fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat)
#' summary(fit)
#' summary(fit, conf.int = TRUE)
#' summary(
#'   fit,
#'   conf.int = TRUE,
#'   method = "profile",
#'   ci_parm = "sigma",
#'   profile_precision = "fast"
#' )
#' @export
summary.drmTMB <- function(
  object,
  conf.int = FALSE,
  level = 0.95,
  method = c("wald", "profile"),
  ci_parm = NULL,
  trace = FALSE,
  profile_precision = c("default", "fast"),
  ...
) {
  profile_precision_missing <- missing(profile_precision)
  validate_summary_conf_int(conf.int)
  validate_summary_trace(trace)
  validate_profile_level(level)
  method <- validate_interval_method(method, c("wald", "profile"), "summary()")
  profile_precision <- resolve_profile_precision(
    profile_precision,
    missing_arg = profile_precision_missing
  )

  dots <- list(...)
  if (!conf.int && length(dots) > 0L) {
    cli::cli_abort(
      "Additional arguments in {.arg ...} are only used when {.arg conf.int = TRUE} and {.code method = \"profile\"}."
    )
  }
  if (!conf.int && !is.null(ci_parm)) {
    cli::cli_abort("{.arg ci_parm} is only used when {.arg conf.int = TRUE}.")
  }
  if (conf.int && !identical(method, "profile") && length(dots) > 0L) {
    cli::cli_abort(
      "Additional arguments in {.arg ...} are only used when {.code method = \"profile\"}."
    )
  }

  coefficients <- drm_summary_coefficients(object)
  parameters <- drm_summary_parameters(object)
  ci <- NULL
  coefficient_ci <- NULL
  parameter_ci <- NULL
  coefficient_ci_method <- method
  ci_unavailable_status <- "not_requested"
  if (conf.int) {
    if (identical(method, "wald")) {
      if (drm_has_sdreport_covariance(object)) {
        ci <- drm_wald_confint(object, parm = ci_parm, level = level)
      } else {
        ci_unavailable_status <- "wald_unavailable"
        ci <- empty_summary_confint()
      }
      coefficient_ci <- ci
      parameter_ci <- ci
    } else {
      parameter_ci <- drm_summary_profile_confint(
        object,
        ci_parm = ci_parm,
        level = level,
        trace = trace,
        profile_precision = profile_precision,
        ...
      )
      coefficient_ci <- summary_profile_coefficient_ci(
        object,
        parameter_ci,
        level = level
      )
      coefficient_ci_method <- if (
        is.null(coefficient_ci) ||
          nrow(coefficient_ci) == 0L ||
          all(coefficient_ci$method == "wald")
      ) {
        "wald"
      } else {
        "profile"
      }
      if (
        !drm_has_sdreport_covariance(object) &&
          (is.null(coefficient_ci) || nrow(coefficient_ci) == 0L)
      ) {
        ci_unavailable_status <- "wald_unavailable"
      }
      ci <- rbind(
        coefficient_ci,
        parameter_ci[
          !parameter_ci$parm %in% coefficient_ci$parm,
          ,
          drop = FALSE
        ]
      )
    }
    coefficients <- drm_summary_add_coefficient_ci(
      coefficients,
      coefficient_ci,
      level = level,
      method = coefficient_ci_method,
      unavailable_status = ci_unavailable_status
    )
    parameters <- drm_summary_add_parameter_ci(
      parameters,
      parameter_ci,
      level = level,
      method = method
    )
  }

  covariance <- random_effect_covariance_summaries(
    object,
    intervals = if (conf.int && identical(method, "profile")) {
      parameter_ci
    } else {
      NULL
    }
  )
  derived <- drm_summary_derived_parameters(
    object,
    interval_requested = conf.int
  )

  out <- list(
    call = object$call,
    coefficients = coefficients,
    parameters = parameters,
    covariance = covariance,
    derived = derived,
    sdpars = object$sdpars,
    corpars = object$corpars,
    ordinal = object$ordinal,
    uncertainty = object$uncertainty,
    logLik = stats::logLik(object),
    convergence = object$opt$convergence,
    conf.int = conf.int,
    conf.level = if (conf.int) level else NA_real_,
    conf.method = if (conf.int) method else NA_character_,
    confint = ci
  )
  class(out) <- "summary.drmTMB"
  out
}

#' @export
print.summary.drmTMB <- function(x, ...) {
  cli::cli_text("<summary.drmTMB>")
  if (isTRUE(x$conf.int)) {
    cli::cli_text(
      "confidence intervals: {x$conf.method}, level = {format(x$conf.level)}"
    )
  }
  uncertainty <- drm_uncertainty_status(x)
  if (!identical(uncertainty, "ok")) {
    cli::cli_text(
      "standard errors: unavailable; coefficient and parameter tables are point estimates only ({drm_uncertainty_message(x)})"
    )
  }
  print(x$coefficients)
  if (nrow(x$parameters) > 0L) {
    cli::cli_text(
      "Distributional, random-effect, scale, and correlation parameters:"
    )
    print(drm_summary_print_parameters(x$parameters))
  }
  if (is.data.frame(x$covariance) && nrow(x$covariance) > 0L) {
    cli::cli_text("Random-effect covariance summaries:")
    print(drm_summary_print_covariance(x$covariance))
  }
  if (is.data.frame(x$derived) && nrow(x$derived) > 0L) {
    cli::cli_text("Derived summaries:")
    print(drm_summary_print_derived(x$derived))
  }
  if (!is.null(x$ordinal)) {
    cli::cli_text("Ordinal cutpoints:")
    print(x$ordinal$cutpoints)
  }
  cli::cli_text("logLik: {format(as.numeric(x$logLik), digits = 4)}")
  cli::cli_text("convergence: {x$convergence}")
  invisible(x)
}

validate_summary_conf_int <- function(conf.int) {
  if (
    !is.logical(conf.int) ||
      length(conf.int) != 1L ||
      is.na(conf.int)
  ) {
    cli::cli_abort(
      "{.arg conf.int} must be a single {.code TRUE} or {.code FALSE}."
    )
  }
  invisible(conf.int)
}

validate_summary_trace <- function(trace) {
  if (
    !is.logical(trace) ||
      length(trace) != 1L ||
      is.na(trace)
  ) {
    cli::cli_abort(
      "{.arg trace} must be a single {.code TRUE} or {.code FALSE}."
    )
  }
  invisible(trace)
}

drm_summary_coefficients <- function(object) {
  labels <- coefficient_labels(object)
  est <- unlist(object$coefficients, use.names = FALSE)
  if (length(est) == 0L) {
    return(data.frame(
      estimate = numeric(),
      std_error = numeric(),
      row.names = character(),
      check.names = FALSE
    ))
  }
  vcov <- tryCatch(stats::vcov(object), error = function(e) e)
  if (inherits(vcov, "error")) {
    out <- data.frame(
      estimate = est,
      std_error = rep(NA_real_, length(est)),
      row.names = labels,
      check.names = FALSE
    )
    out$std_error.status <- drm_standard_error_status(object)
    attr(out, "std_error.message") <- conditionMessage(vcov)
    return(out)
  }
  variances <- diag(vcov)
  se <- rep(NA_real_, length(variances))
  ok <- is.finite(variances) & variances >= 0
  se[ok] <- sqrt(variances[ok])
  data.frame(
    estimate = est,
    std_error = se,
    row.names = labels,
    check.names = FALSE
  )
}

drm_summary_parameters <- function(object) {
  rows <- list(
    drm_summary_direct_parameters(object),
    drm_summary_fitted_range_parameters(object)
  )
  rows <- rows[vapply(rows, nrow, integer(1)) > 0L]
  if (!length(rows)) {
    return(empty_summary_parameters())
  }
  out <- do.call(rbind, rows)
  out <- drm_summary_add_parameter_standard_errors(object, out)
  row.names(out) <- out$parm
  out
}

drm_summary_derived_parameters <- function(
  object,
  interval_requested = FALSE
) {
  out <- drm_derived_summary_rows(object)
  if (nrow(out) == 0L) {
    return(out)
  }
  out$conf.low <- NA_real_
  out$conf.high <- NA_real_
  out$conf.method <- NA_character_
  out$conf.status <- if (isTRUE(interval_requested)) {
    "derived_interval_unavailable"
  } else {
    "not_requested"
  }
  row.names(out) <- out$parm
  out
}

drm_derived_summary_rows <- function(object) {
  if (!identical(object$model$model_type, "gaussian")) {
    return(empty_derived_summary_parameters())
  }
  sigma <- drm_constant_residual_sigma(object)
  if (!is.finite(sigma)) {
    return(empty_derived_summary_parameters())
  }
  sd_values <- object$sdpars$mu
  if (is.null(sd_values) || length(sd_values) == 0L) {
    return(empty_derived_summary_parameters())
  }

  rows <- lapply(seq_along(sd_values), function(i) {
    term <- names(sd_values)[[i]]
    sd_value <- unname(sd_values[[i]])
    if (!is.finite(sd_value) || sd_value < 0) {
      return(NULL)
    }
    kind <- derived_summary_random_effect_kind(term)
    if (is.null(kind)) {
      return(NULL)
    }
    re_variance <- sd_value^2
    residual_variance <- sigma^2
    denominator <- re_variance + residual_variance
    if (!is.finite(denominator) || denominator <= 0) {
      return(NULL)
    }
    data.frame(
      quantity = kind$quantity,
      level = kind$level,
      group = kind$group,
      dpar = "mu",
      term = term,
      estimate = re_variance / denominator,
      random_effect_sd = sd_value,
      random_effect_variance = re_variance,
      residual_sd = sigma,
      residual_variance = residual_variance,
      scale = "response",
      parm = kind$parm,
      target_type = "derived",
      profile_ready = FALSE,
      profile_note = "derived_target",
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) {
    return(empty_derived_summary_parameters())
  }
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

empty_derived_summary_parameters <- function() {
  data.frame(
    quantity = character(),
    level = character(),
    group = character(),
    dpar = character(),
    term = character(),
    estimate = numeric(),
    random_effect_sd = numeric(),
    random_effect_variance = numeric(),
    residual_sd = numeric(),
    residual_variance = numeric(),
    scale = character(),
    parm = character(),
    target_type = character(),
    profile_ready = logical(),
    profile_note = character(),
    conf.low = numeric(),
    conf.high = numeric(),
    conf.method = character(),
    conf.status = character(),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

drm_constant_residual_sigma <- function(object) {
  beta <- object$coefficients$sigma
  if (
    is.null(beta) ||
      length(beta) != 1L ||
      !identical(names(beta), "(Intercept)") ||
      !identical(drm_dpar_link(object, "sigma"), "log")
  ) {
    return(NA_real_)
  }
  known_v <- known_v_diag(object)
  if (
    length(known_v) > 0L &&
      any(is.finite(known_v) & abs(known_v) > sqrt(.Machine$double.eps))
  ) {
    return(NA_real_)
  }
  exp(unname(beta[[1L]]))
}

derived_summary_random_effect_kind <- function(term) {
  if (startsWith(term, "phylo(")) {
    group <- random_intercept_group_from_call(term, "phylo")
    if (is.na(group)) {
      return(NULL)
    }
    return(list(
      quantity = "phylogenetic_signal",
      level = "phylogenetic",
      group = group,
      parm = paste0("derived:phylogenetic_signal(", group, ")")
    ))
  }
  group <- random_intercept_group_from_term(term)
  if (is.na(group)) {
    return(NULL)
  }
  list(
    quantity = "repeatability",
    level = "group",
    group = group,
    parm = paste0("derived:repeatability(", group, ")")
  )
}

random_intercept_group_from_call <- function(term, fun) {
  prefix <- paste0(fun, "(")
  if (!startsWith(term, prefix) || !endsWith(term, ")")) {
    return(NA_character_)
  }
  inner <- substr(term, nchar(prefix) + 1L, nchar(term) - 1L)
  random_intercept_group_from_inner(inner)
}

random_intercept_group_from_term <- function(term) {
  if (!startsWith(term, "(") || !endsWith(term, ")")) {
    return(NA_character_)
  }
  inner <- substr(term, 2L, nchar(term) - 1L)
  random_intercept_group_from_inner(inner)
}

random_intercept_group_from_inner <- function(inner) {
  parts <- trimws(strsplit(inner, "\\|", fixed = FALSE)[[1L]])
  if (length(parts) < 2L || !identical(parts[[1L]], "1")) {
    return(NA_character_)
  }
  group <- parts[[length(parts)]]
  if (!nzchar(group)) {
    return(NA_character_)
  }
  group
}

drm_summary_direct_parameters <- function(object) {
  targets <- drm_profile_targets(object)
  keep <- targets$target_class %in%
    c(
      "distributional-scale",
      "residual-correlation",
      "random-effect-sd",
      "random-effect-correlation"
    )
  targets <- targets[keep, , drop = FALSE]
  if (nrow(targets) == 0L) {
    return(empty_summary_parameters())
  }
  out <- data.frame(
    component = targets$target_class,
    dpar = targets$dpar,
    term = targets$term,
    estimate = targets$estimate,
    minimum = NA_real_,
    maximum = NA_real_,
    scale = targets$scale,
    parm = targets$parm,
    profile_ready = targets$profile_ready,
    profile_note = targets$profile_note,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  row.names(out) <- NULL
  out
}

drm_summary_fitted_range_parameters <- function(object) {
  dpars <- setdiff(names(object$coefficients), c("mu", "mu1", "mu2"))
  if (!length(dpars)) {
    return(empty_summary_parameters())
  }
  direct_parms <- drm_summary_direct_parameters(object)$parm
  rows <- lapply(dpars, function(dpar) {
    if (dpar %in% direct_parms) {
      return(NULL)
    }
    values <- tryCatch(
      predict(object, dpar = dpar, type = "response"),
      error = function(e) NULL
    )
    if (is.null(values) || length(values) == 0L || !all(is.finite(values))) {
      return(NULL)
    }
    values <- as.numeric(values)
    data.frame(
      component = drm_dpar_component(dpar),
      dpar = dpar,
      term = "fitted range",
      estimate = mean(values),
      minimum = min(values),
      maximum = max(values),
      scale = "response",
      parm = paste0("fitted:", dpar),
      profile_ready = FALSE,
      profile_note = drm_summary_range_profile_note(dpar),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) {
    return(empty_summary_parameters())
  }
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

drm_summary_range_profile_note <- function(dpar) {
  if (
    dpar %in%
      c("sigma", "sigma1", "sigma2", "rho12") ||
      startsWith(dpar, "corpair(")
  ) {
    return("use_confint_newdata")
  }
  "fitted_range_only"
}

empty_summary_parameters <- function() {
  data.frame(
    component = character(),
    dpar = character(),
    term = character(),
    estimate = numeric(),
    std_error = numeric(),
    minimum = numeric(),
    maximum = numeric(),
    scale = character(),
    parm = character(),
    profile_ready = logical(),
    profile_note = character(),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

drm_summary_add_parameter_standard_errors <- function(object, parameters) {
  parameters$std_error <- NA_real_
  if (nrow(parameters) == 0L || !drm_has_sdreport_covariance(object)) {
    return(summary_parameter_order_columns(parameters))
  }

  targets <- drm_profile_targets(object)
  matched <- match(parameters$parm, targets$parm)
  cov_fixed <- object$sdr$cov.fixed

  for (i in seq_len(nrow(parameters))) {
    target_row <- matched[[i]]
    if (is.na(target_row)) {
      next
    }
    target <- targets[target_row, , drop = FALSE]
    if (!identical(target$target_type[[1L]], "direct")) {
      next
    }
    position <- summary_parameter_opt_position(object, target)
    if (is.na(position) || position > nrow(cov_fixed)) {
      next
    }
    variance <- cov_fixed[position, position]
    if (!is.finite(variance) || variance < 0) {
      next
    }
    derivative <- summary_parameter_delta_derivative(target)
    if (!is.finite(derivative)) {
      next
    }
    parameters$std_error[[i]] <- abs(derivative) * sqrt(variance)
  }
  parameters <- summary_parameter_order_columns(parameters)
  parameters
}

summary_parameter_order_columns <- function(parameters) {
  preferred <- c(
    "component",
    "dpar",
    "term",
    "estimate",
    "std_error",
    "minimum",
    "maximum",
    "scale",
    "parm",
    "profile_ready",
    "profile_note"
  )
  parameters[,
    c(
      intersect(preferred, names(parameters)),
      setdiff(names(parameters), preferred)
    ),
    drop = FALSE
  ]
}

summary_parameter_opt_position <- function(object, target) {
  internal <- target$tmb_parameter[[1L]]
  index <- target$index[[1L]]
  if (is.na(internal) || is.na(index)) {
    return(NA_integer_)
  }
  positions <- which(names(object$opt$par) == internal)
  if (length(positions) < index) {
    return(NA_integer_)
  }
  positions[[index]]
}

summary_parameter_delta_derivative <- function(target) {
  eta <- target$link_estimate[[1L]]
  if (!is.finite(eta)) {
    return(NA_real_)
  }
  switch(
    target$transformation[[1L]],
    linear_predictor = 1,
    exp = exp(eta),
    tanh = 0.999999 * (1 - tanh(eta)^2),
    rho12_tanh = 0.99999999 * (1 - tanh(eta)^2),
    NA_real_
  )
}

drm_summary_profile_confint <- function(
  object,
  ci_parm,
  level,
  trace,
  profile_precision = c("default", "fast"),
  ...
) {
  targets <- drm_profile_targets(object)
  if (is.null(ci_parm)) {
    targets <- targets[
      targets$target_type == "direct" &
        targets$profile_ready &
        targets$target_class != "fixed-effect",
      ,
      drop = FALSE
    ]
    if (nrow(targets) == 0L) {
      return(empty_summary_confint())
    }
    ci_parm <- targets$parm
  }
  profile_args <- profile_precision_args(profile_precision, list(...))
  do.call(
    drm_profile_confint,
    c(
      list(
        object = object,
        parm = ci_parm,
        level = level,
        trace = trace
      ),
      profile_args
    )
  )
}

summary_profile_coefficient_ci <- function(object, profile_ci, level) {
  if (!is.null(profile_ci) && nrow(profile_ci) > 0L) {
    fixed_profile <- startsWith(profile_ci$parm, "fixef:")
    if (any(fixed_profile)) {
      return(profile_ci[fixed_profile, , drop = FALSE])
    }
  }
  if (!drm_has_sdreport_covariance(object)) {
    return(empty_summary_confint())
  }
  drm_wald_confint(object, parm = NULL, level = level)
}

empty_summary_confint <- function() {
  data.frame(
    parm = character(),
    level = numeric(),
    lower = numeric(),
    upper = numeric(),
    scale = character(),
    transformation = character(),
    tmb_parameter = character(),
    index = integer(),
    method = character(),
    conf.status = character(),
    profile.boundary = logical(),
    profile.message = character(),
    stringsAsFactors = FALSE
  )
}

drm_summary_add_coefficient_ci <- function(
  coefficients,
  ci,
  level,
  method,
  unavailable_status = "not_requested"
) {
  n <- nrow(coefficients)
  coefficients$conf.low <- rep(NA_real_, n)
  coefficients$conf.high <- rep(NA_real_, n)
  coefficients$conf.level <- rep(level, n)
  coefficients$conf.method <- rep(method, n)
  coefficients$conf.status <- rep(unavailable_status, n)
  coefficients$profile.boundary <- rep(NA, n)
  coefficients$profile.message <- rep(NA_character_, n)
  if (is.null(ci) || nrow(ci) == 0L) {
    return(coefficients)
  }
  keys <- paste0("fixef:", row.names(coefficients))
  matched <- match(keys, ci$parm)
  has_ci <- !is.na(matched)
  coefficients$conf.low[has_ci] <- ci$lower[matched[has_ci]]
  coefficients$conf.high[has_ci] <- ci$upper[matched[has_ci]]
  coefficients$conf.status[has_ci] <- summary_ci_status(
    ci,
    matched[has_ci],
    method
  )
  coefficients$profile.boundary[has_ci] <- summary_ci_column(
    ci,
    matched[has_ci],
    column = "profile.boundary",
    default = NA
  )
  coefficients$profile.message[has_ci] <- summary_ci_column(
    ci,
    matched[has_ci],
    column = "profile.message",
    default = NA_character_
  )
  coefficients
}

drm_summary_add_parameter_ci <- function(parameters, ci, level, method) {
  n <- nrow(parameters)
  parameters$conf.low <- rep(NA_real_, n)
  parameters$conf.high <- rep(NA_real_, n)
  parameters$conf.level <- rep(level, n)
  parameters$conf.method <- rep(method, n)
  parameters$conf.status <- summary_parameter_conf_status(
    parameters,
    method = method
  )
  parameters$profile.boundary <- rep(NA, n)
  parameters$profile.message <- rep(NA_character_, n)
  if (nrow(parameters) == 0L || is.null(ci) || nrow(ci) == 0L) {
    return(parameters)
  }
  matched <- match(parameters$parm, ci$parm)
  has_ci <- !is.na(matched)
  parameters$conf.low[has_ci] <- ci$lower[matched[has_ci]]
  parameters$conf.high[has_ci] <- ci$upper[matched[has_ci]]
  parameters$conf.status[has_ci] <- summary_ci_status(
    ci,
    matched[has_ci],
    method
  )
  parameters$profile.boundary[has_ci] <- summary_ci_column(
    ci,
    matched[has_ci],
    column = "profile.boundary",
    default = NA
  )
  parameters$profile.message[has_ci] <- summary_ci_column(
    ci,
    matched[has_ci],
    column = "profile.message",
    default = NA_character_
  )
  parameters
}

summary_ci_status <- function(ci, matched, method) {
  if ("conf.status" %in% names(ci)) {
    return(ci$conf.status[matched])
  }
  rep(method, length(matched))
}

summary_ci_column <- function(ci, matched, column, default) {
  if (column %in% names(ci)) {
    return(ci[[column]][matched])
  }
  rep(default, length(matched))
}

summary_parameter_conf_status <- function(parameters, method) {
  if (nrow(parameters) == 0L) {
    return(character())
  }
  if (identical(method, "wald")) {
    return(rep("wald_unavailable", nrow(parameters)))
  }
  mapply(
    function(profile_ready, profile_note) {
      interval_status_from_profile_note(
        profile_ready = profile_ready,
        profile_note = profile_note
      )
    },
    parameters$profile_ready,
    parameters$profile_note,
    USE.NAMES = FALSE
  )
}

interval_status_from_profile_note <- function(profile_ready, profile_note) {
  if (isTRUE(profile_ready)) {
    return("profile_ready")
  }
  if (is.na(profile_note) || !nzchar(profile_note)) {
    return("profile_unavailable")
  }
  switch(
    profile_note,
    ready = "profile_ready",
    use_confint_newdata = "newdata_required",
    derived_target = "derived_interval_unavailable",
    derived_unstructured_correlation = "derived_interval_unavailable",
    fitted_range_only = "target_unavailable",
    profile_note
  )
}

drm_summary_print_parameters <- function(parameters) {
  keep <- c(
    "component",
    "dpar",
    "term",
    "estimate",
    "std_error",
    "minimum",
    "maximum",
    "scale"
  )
  if (
    "std_error" %in%
      names(parameters) &&
      !any(is.finite(parameters$std_error))
  ) {
    keep <- setdiff(keep, "std_error")
  }
  if (
    all(c("minimum", "maximum") %in% names(parameters)) &&
      !any(
        is.finite(parameters$minimum) &
          is.finite(parameters$maximum) &
          parameters$minimum != parameters$maximum
      )
  ) {
    keep <- setdiff(keep, c("minimum", "maximum"))
  }
  if ("conf.low" %in% names(parameters)) {
    has_interval <- any(is.finite(parameters$conf.low)) ||
      any(is.finite(parameters$conf.high))
    if (has_interval) {
      keep <- c(keep, "conf.low", "conf.high")
    }
  }
  if (
    "conf.status" %in%
      names(parameters) &&
      any(parameters$conf.status != "profile", na.rm = TRUE)
  ) {
    keep <- c(keep, "conf.status")
  }
  if (
    "profile.message" %in%
      names(parameters) &&
      any(
        !is.na(parameters$profile.message) & parameters$profile.message != "ok"
      )
  ) {
    keep <- c(keep, "profile.message")
  }
  out <- parameters[, keep, drop = FALSE]
  row.names(out) <- row.names(parameters)
  out
}

drm_summary_print_covariance <- function(covariance) {
  keep <- c(
    "level",
    "group",
    "block",
    "from_dpar",
    "to_dpar",
    "class",
    "correlation",
    "from_sd",
    "to_sd",
    "covariance"
  )
  out <- covariance[, keep, drop = FALSE]
  if (
    "correlation_conf.low" %in%
      names(covariance) &&
      any(is.finite(covariance$correlation_conf.low))
  ) {
    out$correlation_conf.low <- covariance$correlation_conf.low
    out$correlation_conf.high <- covariance$correlation_conf.high
  }
  if (
    "covariance_conf.status" %in%
      names(covariance) &&
      any(
        covariance$covariance_conf.status == "derived_interval_unavailable",
        na.rm = TRUE
      )
  ) {
    out$covariance_conf.status <- covariance$covariance_conf.status
  }
  out
}

drm_summary_print_derived <- function(derived) {
  keep <- c(
    "quantity",
    "level",
    "group",
    "term",
    "estimate",
    "random_effect_variance",
    "residual_variance"
  )
  out <- derived[, keep, drop = FALSE]
  if (
    "conf.status" %in%
      names(derived) &&
      any(
        derived$conf.status == "derived_interval_unavailable",
        na.rm = TRUE
      )
  ) {
    out$conf.status <- derived$conf.status
  }
  out
}

drm_prediction_matrix <- function(object, newdata, dpar) {
  if (is.null(newdata)) {
    return(object$model$X[[dpar]])
  }
  if (!is.data.frame(newdata)) {
    cli::cli_abort("{.arg newdata} must be a data frame.")
  }
  if (
    identical(object$model$model_type, "cumulative_logit") &&
      identical(dpar, "mu")
  ) {
    return(ordinal_mu_model_matrix(object$model$terms[[dpar]], newdata))
  }
  drm_fixed_effect_matrix(
    object$model$terms[[dpar]],
    newdata,
    sparse = drm_fixed_effect_is_sparse(object, dpar)
  )
}

drm_fixed_effect_basis <- function(
  object,
  newdata = NULL,
  dpar = NULL,
  covariance = FALSE
) {
  if (is.null(dpar)) {
    dpar <- object$model$dpars[[1L]]
  }
  dpar <- match.arg(dpar, names(object$coefficients))
  validate_fixed_effect_basis_covariance(covariance)
  if (is_random_scale_dpar(object, dpar)) {
    cli::cli_abort(c(
      "Fixed-effect basis matrices are not defined for random-effect scale parameter {.val {dpar}}.",
      i = "Use {.fn predict} for fitted random-effect scale predictions."
    ))
  }
  supplied_newdata <- !is.null(newdata)
  if (!is.null(newdata)) {
    newdata <- drm_prepare_prediction_newdata(object, newdata, dpar)
  }

  X <- drm_prediction_matrix(object, newdata, dpar)
  if (isTRUE(supplied_newdata)) {
    drm_validate_prediction_matrix_finite(X, dpar)
  }
  beta <- object$coefficients[[dpar]]
  if (!identical(colnames(X), names(beta))) {
    cli::cli_abort(c(
      "Could not align the {.val {dpar}} design matrix with fitted coefficients.",
      i = "Check that factor levels and predictor columns match the fitted model."
    ))
  }

  offset <- drm_prediction_offset(object, newdata, dpar)
  if (length(offset) != nrow(X)) {
    cli::cli_abort(
      "Internal error: fixed-effect basis offsets do not match design-matrix rows."
    )
  }

  V <- NULL
  if (isTRUE(covariance)) {
    V <- drm_fixed_effect_basis_covariance(object, dpar, names(beta))
  }

  list(
    dpar = dpar,
    X = X,
    bhat = beta,
    V = V,
    offset = offset,
    eta = as.vector(X %*% beta) + offset,
    link = drm_dpar_link(object, dpar),
    coefficient_labels = paste0(dpar, ":", names(beta))
  )
}

drm_prepare_prediction_newdata <- function(object, newdata, dpar) {
  if (!is.data.frame(newdata)) {
    return(newdata)
  }
  template <- drm_prediction_template_data(object, dpar)
  if (!is.data.frame(template)) {
    return(newdata)
  }

  drm_prepare_model_matrix_newdata(
    newdata = newdata,
    dpar = dpar,
    terms = object$model$terms[[dpar]],
    template = template
  )
}

drm_prepare_model_matrix_newdata <- function(newdata, dpar, terms, template) {
  needed <- all.vars(stats::delete.response(terms))
  missing <- setdiff(needed, names(newdata))
  if (length(missing) > 0L) {
    cli::cli_abort(c(
      "New prediction data is missing required predictor{?s} for {.code dpar = \"{dpar}\"}.",
      i = "Missing predictor{?s}: {.var {missing}}."
    ))
  }
  for (name in intersect(names(newdata), needed)) {
    if (anyNA(newdata[[name]])) {
      cli::cli_abort(c(
        "New prediction data contains missing value{?s} for required predictor {.var {name}}.",
        i = "Supply complete prediction rows before calling {.fn predict} or {.pkg emmeans}."
      ))
    }
    if (is.numeric(newdata[[name]]) && any(!is.finite(newdata[[name]]))) {
      cli::cli_abort(c(
        "New prediction data contains non-finite value{?s} for required predictor {.var {name}}.",
        i = "Supply finite prediction values before calling {.fn predict} or {.pkg emmeans}."
      ))
    }
  }
  for (name in intersect(intersect(names(newdata), names(template)), needed)) {
    source <- template[[name]]
    if (!is.factor(source)) {
      next
    }
    value <- as.character(newdata[[name]])
    unknown <- setdiff(unique(value), levels(source))
    if (length(unknown) > 0L) {
      cli::cli_abort(c(
        "New prediction data contains unknown factor level{?s} for {.var {name}}.",
        i = "Unknown level{?s}: {.val {unknown}}.",
        i = "Fitted level{?s}: {.val {levels(source)}}."
      ))
    }
    newdata[[name]] <- factor(
      value,
      levels = levels(source),
      ordered = is.ordered(source)
    )
  }
  newdata
}

drm_prepare_random_scale_newdata <- function(sd_target, newdata, dpar) {
  template <- sd_target$model_frame_list[[dpar]]
  if (!is.data.frame(template)) {
    return(newdata)
  }
  drm_prepare_model_matrix_newdata(
    newdata = newdata,
    dpar = dpar,
    terms = sd_target$terms_list[[dpar]],
    template = template
  )
}

drm_validate_prediction_matrix_finite <- function(X, dpar) {
  terms <- drm_nonfinite_prediction_matrix_terms(X)
  if (length(terms) == 0L) {
    return(invisible(X))
  }
  cli::cli_abort(c(
    "New prediction data produces non-finite design-matrix value{?s} for {.code dpar = \"{dpar}\"}.",
    i = "Affected model column{?s}: {.val {terms}}.",
    i = "Check transformed predictors such as {.code log(x)} or {.code sqrt(x)} before prediction or post-fit grid helpers."
  ))
}

drm_nonfinite_prediction_matrix_terms <- function(X) {
  if (inherits(X, "sparseMatrix")) {
    bad <- !is.finite(X@x)
    if (!any(bad)) {
      return(character())
    }
    columns <- unique(findInterval(which(bad) - 1L, X@p[-1L]) + 1L)
    return(drm_prediction_matrix_term_names(X, columns))
  }
  bad <- !is.finite(as.matrix(X))
  if (!any(bad)) {
    return(character())
  }
  drm_prediction_matrix_term_names(X, which(colSums(bad) > 0L))
}

drm_prediction_matrix_term_names <- function(X, columns) {
  names <- colnames(X)
  if (is.null(names)) {
    return(paste0("column ", columns))
  }
  names[columns]
}

drm_prediction_template_data <- function(object, dpar) {
  model_frames <- object$model$model_frame
  if (is.list(model_frames) && is.data.frame(model_frames[[dpar]])) {
    return(model_frames[[dpar]])
  }
  if (is.data.frame(object$data)) {
    return(object$data)
  }
  if (is.data.frame(object$model$data)) {
    return(object$model$data)
  }
  NULL
}

validate_fixed_effect_basis_covariance <- function(covariance) {
  if (
    !is.logical(covariance) ||
      length(covariance) != 1L ||
      is.na(covariance)
  ) {
    cli::cli_abort(
      "{.arg covariance} must be a single {.code TRUE} or {.code FALSE}."
    )
  }
  invisible(covariance)
}

drm_fixed_effect_basis_covariance <- function(object, dpar, terms) {
  labels <- paste0(dpar, ":", terms)
  V <- vcov(object)
  missing <- setdiff(labels, row.names(V))
  if (length(missing) > 0L) {
    cli::cli_abort(c(
      "Could not align the {.val {dpar}} covariance matrix with fitted coefficients.",
      i = "Missing coefficient label{?s}: {.val {missing}}."
    ))
  }
  out <- V[labels, labels, drop = FALSE]
  if (anyNA(out)) {
    cli::cli_abort(c(
      "Fixed-effect covariance for {.val {dpar}} contains unavailable entries.",
      i = "Refit with standard errors enabled and check the fitted coefficient map."
    ))
  }
  dimnames(out) <- list(terms, terms)
  out
}

drm_prediction_offset <- function(object, newdata, dpar) {
  offset <- object$model$offset[[dpar]]
  if (is.null(offset)) {
    if (is.null(newdata)) {
      return(rep(0, nrow(object$model$X[[dpar]])))
    }
    return(rep(0, nrow(newdata)))
  }
  if (is.null(newdata)) {
    return(offset)
  }
  mf <- stats::model.frame(
    object$model$terms[[dpar]],
    data = newdata,
    na.action = stats::na.pass
  )
  out <- stats::model.offset(mf)
  if (is.null(out)) {
    return(rep(0, nrow(newdata)))
  }
  out <- as.numeric(out)
  if (length(out) != nrow(newdata) || any(!is.finite(out))) {
    cli::cli_abort(c(
      "Offset terms in {.arg newdata} must evaluate to one finite value per row.",
      "i" = "For exposure prediction, supply positive finite exposure values used by {.code offset(log(exposure))}."
    ))
  }
  out
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

truncated_nbinom2_p0 <- function(mu, sigma) {
  stats::dnbinom(0, size = 1 / sigma^2, mu = mu)
}

truncated_nbinom2_prob_positive <- function(mu, sigma) {
  pmax(1 - truncated_nbinom2_p0(mu, sigma), .Machine$double.eps)
}

truncated_nbinom2_mean <- function(mu, sigma) {
  mu / truncated_nbinom2_prob_positive(mu, sigma)
}

truncated_nbinom2_variance <- function(mu, sigma) {
  q <- truncated_nbinom2_prob_positive(mu, sigma)
  second_moment <- (mu + (1 + sigma^2) * mu^2) / q
  pmax(second_moment - (mu / q)^2, .Machine$double.eps)
}

hurdle_nbinom2_mean <- function(mu, sigma, hu) {
  (1 - hu) * truncated_nbinom2_mean(mu, sigma)
}

hurdle_nbinom2_variance <- function(mu, sigma, hu) {
  positive_mean <- truncated_nbinom2_mean(mu, sigma)
  positive_var <- truncated_nbinom2_variance(mu, sigma)
  pmax(
    (1 - hu) * positive_var + hu * (1 - hu) * positive_mean^2,
    .Machine$double.eps
  )
}

beta_binomial_proportion_variance <- function(mu, sigma, trials) {
  pmax(
    mu * (1 - mu) * (1 + trials * sigma^2) / (trials * (1 + sigma^2)),
    .Machine$double.eps
  )
}

ordinal_category_probabilities <- function(object, newdata = NULL) {
  eta <- predict(object, newdata = newdata, dpar = "mu", type = "link")
  cutpoints <- unname(object$ordinal$cutpoints)
  n <- length(eta)
  n_categories <- length(cutpoints) + 1L
  z <- matrix(
    cutpoints,
    nrow = n,
    ncol = length(cutpoints),
    byrow = TRUE
  ) -
    eta
  log_cumulative <- stats::plogis(z, log.p = TRUE)
  log_prob <- matrix(NA_real_, nrow = n, ncol = n_categories)
  log_prob[, 1L] <- log_cumulative[, 1L]
  if (n_categories > 2L) {
    upper <- z[, 2L:(n_categories - 1L), drop = FALSE]
    lower <- z[, 1L:(n_categories - 2L), drop = FALSE]
    log_prob[, 2L:(n_categories - 1L)] <-
      ordinal_log_inv_logit_diff(upper, lower)
  }
  log_prob[, n_categories] <- stats::plogis(
    z[, n_categories - 1L],
    lower.tail = FALSE,
    log.p = TRUE
  )
  out <- exp(log_prob)
  out <- pmax(out, 0)
  out <- out / rowSums(out)
  colnames(out) <- object$ordinal$levels
  out
}

ordinal_log_inv_logit_diff <- function(upper, lower) {
  upper +
    ordinal_log1mexp(lower - upper) -
    ordinal_log1pexp(upper) -
    ordinal_log1pexp(lower)
}

ordinal_log1pexp <- function(x) {
  ifelse(x > 0, x + log1p(exp(-x)), log1p(exp(x)))
}

ordinal_log1mexp <- function(log_p) {
  ifelse(
    log_p < log(0.5),
    log1p(-exp(log_p)),
    log(-expm1(log_p))
  )
}

ordinal_expected_score <- function(object, newdata = NULL) {
  prob <- ordinal_category_probabilities(object, newdata = newdata)
  as.vector(prob %*% seq_len(ncol(prob)))
}

ordinal_score_variance <- function(object, newdata = NULL) {
  prob <- ordinal_category_probabilities(object, newdata = newdata)
  scores <- seq_len(ncol(prob))
  mean_score <- as.vector(prob %*% scores)
  second_moment <- as.vector(prob %*% (scores^2))
  second_moment - mean_score^2
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
  if (identical(object$model$model_type, "beta_binomial")) {
    return(predict.drmTMB(object, dpar = "mu"))
  }
  if (identical(object$model$model_type, "cumulative_logit")) {
    return(ordinal_expected_score(object))
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
  if (identical(object$model$model_type, "truncated_nbinom2")) {
    mu <- predict.drmTMB(object, dpar = "mu")
    sigma <- predict.drmTMB(object, dpar = "sigma")
    return(truncated_nbinom2_mean(mu, sigma))
  }
  if (identical(object$model$model_type, "hurdle_nbinom2")) {
    mu <- predict.drmTMB(object, dpar = "mu")
    sigma <- predict.drmTMB(object, dpar = "sigma")
    hu <- predict.drmTMB(object, dpar = "hu")
    return(hurdle_nbinom2_mean(mu, sigma, hu))
  }
  if (identical(object$model$model_type, "zi_nbinom2")) {
    mu <- predict.drmTMB(object, dpar = "mu")
    zi <- predict.drmTMB(object, dpar = "zi")
    return((1 - zi) * mu)
  }
  if (
    identical(object$model$model_type, "gaussian") ||
      identical(object$model$model_type, "student")
  ) {
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
    atanh_re_guarded = rho_response(eta, guard = 0.999999),
    cli::cli_abort("Internal error: unknown inverse link {.val {link}}.")
  )
}

drm_dpar_link <- function(object, dpar) {
  if (startsWith(dpar, "corpair(")) {
    return("atanh_re_guarded")
  }
  links <- switch(
    object$model$model_type,
    gaussian = c(mu = "identity", sigma = "log"),
    student = c(mu = "identity", sigma = "log", nu = "logm2"),
    lognormal = c(mu = "identity", sigma = "log"),
    gamma = c(mu = "log", sigma = "log"),
    beta = c(mu = "logit", sigma = "log"),
    beta_binomial = c(mu = "logit", sigma = "log"),
    cumulative_logit = c(mu = "identity"),
    poisson = c(mu = "log"),
    zi_poisson = c(mu = "log", zi = "logit"),
    nbinom2 = c(mu = "log", sigma = "log"),
    truncated_nbinom2 = c(mu = "log", sigma = "log"),
    hurdle_nbinom2 = c(mu = "log", sigma = "log", hu = "logit"),
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

rho_response <- function(eta, guard = 0.99999999) {
  guard * tanh(eta)
}

coefficient_labels <- function(object) {
  unlist(
    lapply(names(object$coefficients), function(dpar) {
      paste0(dpar, ":", names(object$coefficients[[dpar]]))
    }),
    use.names = FALSE
  )
}

has_mu_random_effects <- function(object) {
  has_ordinary_mu_random_effects(object) ||
    has_structured_mu_effect(object) ||
    has_mu_covariance_block_random_effects(object)
}

has_ordinary_mu_random_effects <- function(object) {
  object$model$model_type %in%
    c("gaussian", "biv_gaussian") &&
    length(object$random_effects$mu$values) > 0L
}

has_mu_random_intercepts <- has_mu_random_effects

has_phylo_mu_effect <- function(object) {
  object$model$model_type %in%
    c("gaussian", "biv_gaussian", "poisson") &&
    isTRUE(object$model$structured$phylo_mu$has) &&
    identical(structured_mu_type(object$model$structured$phylo_mu), "phylo")
}

has_spatial_mu_effect <- function(object) {
  object$model$model_type %in%
    c("gaussian", "biv_gaussian") &&
    isTRUE(object$model$structured$phylo_mu$has) &&
    identical(structured_mu_type(object$model$structured$phylo_mu), "spatial")
}

has_structured_mu_effect <- function(object) {
  object$model$model_type %in%
    c("gaussian", "biv_gaussian", "poisson") &&
    isTRUE(object$model$structured$phylo_mu$has)
}

n_mu_random_effect_terms <- function(object) {
  length(object$model$random$mu$labels) +
    n_mu_covariance_block_random_effect_terms(object) +
    if (has_structured_mu_effect(object)) {
      structured_mu_q(object$model$structured$phylo_mu)
    } else {
      0L
    }
}

has_sigma_random_effects <- function(object) {
  object$model$model_type %in%
    c("gaussian", "biv_gaussian") &&
    length(object$random_effects$sigma$values) > 0L
}

has_covariance_block_random_effects <- function(object) {
  is.list(object$random_effects$covariance_blocks) &&
    !is.null(object$random_effects$covariance_blocks$contribution) &&
    ncol(object$random_effects$covariance_blocks$contribution) > 0L
}

has_mu_covariance_block_random_effects <- function(object) {
  has_covariance_block_random_effects(object) &&
    n_mu_covariance_block_random_effect_terms(object) > 0L
}

n_mu_covariance_block_random_effect_terms <- function(object) {
  registry <- object$model$random$covariance_blocks
  if (!is.list(registry)) {
    return(0L)
  }
  members <- qgt2_covariance_members(registry)
  if (nrow(members) == 0L) {
    return(0L)
  }
  sum(grepl("^mu", members$dpar))
}

sigma_random_effect_dpars <- function(object) {
  dpars <- object$model$random$sigma$dpars
  if (length(dpars) == 0L) {
    character()
  } else {
    unique(dpars)
  }
}

mu_random_effect_dpars <- function(object) {
  dpars <- object$model$random$mu$dpars
  if (length(dpars) == 0L) {
    character()
  } else {
    unique(dpars)
  }
}

is_random_scale_dpar <- function(object, dpar) {
  if (!object$model$model_type %in% c("gaussian", "biv_gaussian")) {
    return(FALSE)
  }
  if (
    object$model$random_scale$mu$n_models > 0L &&
      dpar %in% object$model$random_scale$mu$dpars
  ) {
    return(TRUE)
  }
  is.list(object$model$random_scale$phylo) &&
    object$model$random_scale$phylo$n_models > 0L &&
    dpar %in% object$model$random_scale$phylo$dpars
}

predict_random_scale_dpar <- function(
  object,
  dpar,
  newdata = NULL,
  type = c("response", "link")
) {
  type <- match.arg(type)
  sd_target <- if (dpar %in% object$model$random_scale$mu$dpars) {
    object$model$random_scale$mu
  } else if (
    is.list(object$model$random_scale$phylo) &&
      dpar %in% object$model$random_scale$phylo$dpars
  ) {
    object$model$random_scale$phylo
  } else {
    NULL
  }
  if (is.null(sd_target)) {
    cli::cli_abort("Unknown random-effect scale parameter {.val {dpar}}.")
  }
  if (is.null(newdata)) {
    X <- sd_target$X_list[[dpar]]
    names_out <- sd_target$group_levels_list[[dpar]]
  } else {
    if (!is.data.frame(newdata)) {
      cli::cli_abort("{.arg newdata} must be a data frame.")
    }
    newdata <- drm_prepare_random_scale_newdata(sd_target, newdata, dpar)
    X <- stats::model.matrix(sd_target$terms_list[[dpar]], data = newdata)
    drm_validate_prediction_matrix_finite(X, dpar)
    names_out <- rownames(newdata)
  }
  eta <- as.vector(X %*% object$coefficients[[dpar]])
  if (type == "link") {
    stats::setNames(eta, names_out)
  } else {
    stats::setNames(exp(eta), names_out)
  }
}

mu_random_effect_contribution <- function(object, dpar = NULL) {
  values <- object$random_effects$mu$values
  index <- object$model$random$mu$index
  design_value <- object$model$random$mu$value
  if (!is.null(dpar)) {
    terms <- which(object$model$random$mu$dpars %in% dpar)
    index <- index[, terms, drop = FALSE]
    design_value <- design_value[, terms, drop = FALSE]
  }
  rowSums(matrix(values[index], nrow = nrow(index)) * design_value)
}

mu_random_intercept_contribution <- mu_random_effect_contribution

phylo_mu_contribution <- function(object, dpar = NULL) {
  phylo_mu <- object$model$structured$phylo_mu
  key <- structured_mu_random_effect_key(phylo_mu)
  values <- object$random_effects[[key]]$values
  index <- phylo_mu$observation_node_index
  if (identical(object$model$model_type, "biv_gaussian")) {
    dpars <- phylo_mu_dpars(phylo_mu)
    dpar <- match.arg(dpar, dpars)
    offset <- (match(dpar, dpars) - 1L) * phylo_mu$n_re
    index <- index + offset
    return(unname(values[index]))
  }
  q <- structured_mu_q(phylo_mu)
  if (q > 1L && is.matrix(phylo_mu$value)) {
    n_re <- phylo_mu$n_re
    endpoint <- seq_len(q)
    if (!is.null(dpar)) {
      endpoint_dpars <- phylo_mu_endpoint_dpars(phylo_mu)
      endpoint <- which(endpoint_dpars %in% dpar)
    }
    if (length(endpoint) == 0L) {
      return(rep(0, object$nobs))
    }
    value_matrix <- matrix(
      unname(values[seq_len(q * n_re)]),
      nrow = n_re,
      ncol = q
    )
    return(unname(rowSums(
      value_matrix[index, endpoint, drop = FALSE] *
        phylo_mu$value[, endpoint, drop = FALSE]
    )))
  }
  unname(values[index])
}

sigma_random_effect_contribution <- function(object, dpar = NULL) {
  values <- object$random_effects$sigma$values
  index <- object$model$random$sigma$index
  design_value <- object$model$random$sigma$value
  if (!is.null(dpar)) {
    terms <- which(object$model$random$sigma$dpars %in% dpar)
    index <- index[, terms, drop = FALSE]
    design_value <- design_value[, terms, drop = FALSE]
  }
  rowSums(matrix(values[index], nrow = nrow(index)) * design_value)
}

covariance_block_random_effect_contribution <- function(object, dpar) {
  block_re <- object$random_effects$covariance_blocks
  members <- block_re$members
  cols <- which(members$dpar == dpar)
  if (length(cols) == 0L) {
    return(rep(0, object$nobs))
  }
  rowSums(block_re$contribution[, cols, drop = FALSE])
}

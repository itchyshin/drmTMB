#' Fixed-decay phylogenetic OU sensitivity fits
#'
#' Fit a Brownian-motion (BM) phylogenetic baseline and a user-specified grid
#' of *fixed* location-side Ornstein--Uhlenbeck (OU) decay rates.  This is a
#' robustness analysis for assumptions about phylogenetic decay; it does not
#' estimate a decay rate, select a preferred process, or provide a confidence
#' interval for decay.
#'
#' The first public slice is deliberately narrow: one complete-response
#' univariate Gaussian model, one unlabelled phylogenetic intercept in the
#' location formula, and deterministic fixed-effect predictors in `mu` and
#' `sigma`.  `alpha` is dimensionless when `alpha_scale = "root_depth"`: its
#' native rate is `alpha / tree_height`.  The tree must then be ultrametric.
#' Use `alpha_scale = "raw"` when rates are already in the tree's branch-length
#' units.  The package's phylogenetic routes still require an ultrametric tree.
#'
#' @param formula A [bf()] formula containing exactly one
#'   `phylo(1 | group, tree = tree, model = "ou")` term in `mu`.
#' @param data A data frame with complete model variables.
#' @param alpha Positive, prespecified OU decay values.
#' @param alpha_scale Whether `alpha` is scaled by the ultrametric tree height
#'   (`"root_depth"`, the default) or supplied in native branch-length units
#'   (`"raw"`).
#' @param control A [drm_control()] list.
#'
#' @return An object of class `drmTMB_ou_sensitivity` containing `$fits` (the
#'   BM fit followed by fixed-OU fits), `$summary` (likelihood and diagnostic
#'   information), and `$coefficients` (fixed effects for every distributional
#'   parameter and grid value).
#' @export
#'
#' @examples
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   set.seed(1)
#'   tree <- ape::rcoal(5)
#'   dat <- data.frame(
#'     y = rnorm(20), x = rnorm(20),
#'     species = rep(tree$tip.label, each = 4)
#'   )
#'   ou_sensitivity(
#'     bf(y ~ x + phylo(1 | species, tree = tree, model = "ou"), sigma ~ x),
#'     data = dat, alpha = c(0.3, 0.7, 1.3)
#'   )
#' }
ou_sensitivity <- function(
  formula,
  data,
  alpha,
  alpha_scale = c("root_depth", "raw"),
  control = list()
) {
  if (!inherits(formula, "drm_formula")) {
    cli::cli_abort(
      "{.arg formula} must be created with {.fn bf} or {.fn drm_formula}."
    )
  }
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame.")
  }
  alpha_scale <- match.arg(alpha_scale)
  alpha <- as.numeric(alpha)
  if (!length(alpha) || any(!is.finite(alpha)) || any(alpha <= 0)) {
    cli::cli_abort(
      "{.arg alpha} must contain one or more finite positive values."
    )
  }
  if (anyDuplicated(alpha)) {
    cli::cli_abort("{.arg alpha} must not contain duplicate values.")
  }
  drm_validate_ou_sensitivity_formula(formula)

  control_parsed <- drm_parse_control(control)
  formula_env <- drm_formula_env(formula, parent.frame())
  spec <- drm_build_gaussian_ls_spec(
    formula,
    data,
    env = formula_env,
    weights = NULL,
    control = control_parsed,
    impute = NULL,
    missing = miss_control()
  )
  drm_validate_ou_sensitivity_spec(spec)
  tree <- evaluate_phylo_tree(spec$structured$phylo_mu$tree, formula_env)
  tree_height <- drm_ou_sensitivity_tree_height(tree, alpha_scale)
  alpha_native <- if (identical(alpha_scale, "root_depth")) {
    alpha / tree_height
  } else {
    alpha
  }

  bm_formula <- drm_ou_sensitivity_bm_formula(formula)
  bm <- drm_ou_sensitivity_capture(
    drmTMB(
      bm_formula,
      family = stats::gaussian(),
      data = data,
      control = control_parsed,
      REML = FALSE
    )
  )
  fits <- list(BM = bm$value)
  warnings <- list(BM = bm$warnings)
  for (i in seq_along(alpha_native)) {
    ou_spec <- spec
    ou_spec$start$log_decay_phylo <- log(alpha_native[[i]])
    ou_spec$map$log_decay_phylo <- factor(NA)
    fitted <- drm_ou_sensitivity_capture(
      drm_fit_spec(
        spec = ou_spec,
        formula = formula,
        family = stats::gaussian(),
        control = control_parsed,
        REML = FALSE,
        penalty = NULL,
        estimator = "ML",
        fit_call = match.call()
      )
    )
    key <- paste0("alpha_", format(alpha[[i]], trim = TRUE, scientific = FALSE))
    fits[[key]] <- fitted$value
    warnings[[key]] <- fitted$warnings
  }
  summary <- do.call(
    rbind,
    c(
      list(drm_ou_sensitivity_fit_row(
        fits[["BM"]],
        "BM",
        NA_real_,
        NA_real_,
        alpha_scale,
        warnings[["BM"]]
      )),
      lapply(seq_along(alpha), function(i) {
        key <- names(fits)[[i + 1L]]
        drm_ou_sensitivity_fit_row(
          fits[[key]],
          "OU",
          alpha[[i]],
          alpha_native[[i]],
          alpha_scale,
          warnings[[key]]
        )
      })
    )
  )
  coefficients <- do.call(
    rbind,
    Map(
      drm_ou_sensitivity_coefficients,
      fit = fits,
      fit_id = names(fits),
      alpha = c(NA_real_, alpha)
    )
  )
  out <- list(
    call = match.call(),
    formula = formula,
    alpha = alpha,
    alpha_native = alpha_native,
    alpha_scale = alpha_scale,
    tree_height = tree_height,
    fits = fits,
    summary = summary,
    coefficients = coefficients,
    limitations = paste(
      "Experimental fixed-alpha sensitivity only: alpha is not estimated;",
      "no process-selection, interval, newdata, or forecasting claim is supported."
    )
  )
  class(out) <- "drmTMB_ou_sensitivity"
  out
}

#' @export
print.drmTMB_ou_sensitivity <- function(x, ...) {
  cat("Fixed-alpha phylogenetic OU sensitivity\n")
  cat("  ", x$limitations, "\n", sep = "")
  print(x$summary, row.names = FALSE)
  invisible(x)
}

drm_validate_ou_sensitivity_formula <- function(formula) {
  entries <- formula$entries
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  if (
    !identical(
      sort(unique(dpars)),
      sort(c("mu", if ("sigma" %in% dpars) "sigma"))
    )
  ) {
    cli::cli_abort(
      "{.fn ou_sensitivity} supports only univariate Gaussian {.code mu} and optional {.code sigma} formulas."
    )
  }
  if (sum(dpars == "mu") != 1L || sum(dpars == "sigma") > 1L) {
    cli::cli_abort(
      "{.fn ou_sensitivity} requires exactly one {.code mu} formula and at most one {.code sigma} formula."
    )
  }
  structured <- unlist(lapply(entries, `[[`, "structured"), recursive = FALSE)
  phylo <- Filter(function(x) identical(x$type, "phylo"), structured)
  if (
    length(phylo) != 1L ||
      !identical(phylo[[1]]$dpar, "mu") ||
      !identical(phylo[[1]]$model, "ou") ||
      !identical(phylo[[1]]$coef_names, "(Intercept)") ||
      !is.null(phylo[[1]]$covariance_label)
  ) {
    cli::cli_abort(c(
      "{.fn ou_sensitivity} requires one unlabelled location-side OU intercept.",
      "i" = "Use {.code y ~ x + phylo(1 | species, tree = tree, model = \"ou\")} with optional fixed {.code sigma} predictors."
    ))
  }
  if (length(structured) != 1L) {
    cli::cli_abort(
      "{.fn ou_sensitivity} does not support additional structured effects."
    )
  }
  bare_rhs <- lapply(entries, function(entry) {
    terms <- flatten_plus_terms(entry$rhs)
    keep <- !vapply(
      terms,
      is_structured_marker_call,
      logical(1),
      name = "phylo"
    )
    rebuild_plus_terms(terms[keep])
  })
  has_random <- any(vapply(
    bare_rhs,
    function(rhs) {
      "|" %in% all.names(rhs, functions = TRUE, unique = TRUE)
    },
    logical(1)
  ))
  if (has_random) {
    cli::cli_abort(
      "{.fn ou_sensitivity} does not support ordinary random effects."
    )
  }
}

drm_validate_ou_sensitivity_spec <- function(spec) {
  phylo <- spec$structured$phylo_mu
  valid <- identical(spec$model_type, "gaussian") &&
    identical(phylo$dpars, "mu") &&
    identical(phylo$q, 1L) &&
    identical(phylo$coef_names, "(Intercept)") &&
    identical(spec$V_known_type, "none") &&
    isTRUE(all(spec$weights == 1)) &&
    isTRUE(all(spec$keep)) &&
    isTRUE(all(spec$missing_data$observed_y)) &&
    !isTRUE(spec$missing_predictor$enabled) &&
    !isTRUE(spec$missing_predictor2$enabled) &&
    spec$random$mu$n_terms == 0L &&
    spec$random$sigma$n_terms == 0L &&
    spec$random_scale$mu$n_models == 0L &&
    spec$random_scale$phylo$n_models == 0L &&
    !isTRUE(spec$structured$temporal_mu$has) &&
    !isTRUE(spec$structured$mesh_spatial_mu$has)
  if (!valid) {
    cli::cli_abort(c(
      "This {.fn ou_sensitivity} configuration is outside the experimental fixed-alpha scope.",
      "i" = "Use complete response and predictors, unit weights, fixed mu/sigma predictors, and one location-side OU phylogenetic intercept."
    ))
  }
  invisible(spec)
}

drm_ou_sensitivity_tree_height <- function(tree, alpha_scale) {
  if (identical(alpha_scale, "raw")) {
    return(NA_real_)
  }
  depth <- ape::node.depth.edgelength(tree)[seq_len(ape::Ntip(tree))]
  tolerance <- sqrt(.Machine$double.eps) * max(depth)
  if (diff(range(depth)) > tolerance) {
    cli::cli_abort(c(
      "{.arg alpha_scale = \"root_depth\"} requires an ultrametric tree.",
      "i" = "Use an ultrametric tree, then choose either root-depth-scaled or raw branch-length decay units."
    ))
  }
  unname(mean(depth))
}

drm_ou_sensitivity_bm_formula <- function(formula) {
  out <- formula
  out$calls <- lapply(out$calls, drm_ou_sensitivity_replace_model)
  out$entries <- parse_drm_formula_entries(out$calls, out$names)
  out$env <- formula$env
  class(out) <- "drm_formula"
  out
}

drm_ou_sensitivity_replace_model <- function(x) {
  if (!is.call(x)) {
    return(x)
  }
  if (identical(x[[1L]], as.name("phylo")) && "model" %in% names(x)) {
    x[["model"]] <- "bm"
    return(x)
  }
  as.call(lapply(x, drm_ou_sensitivity_replace_model))
}

drm_ou_sensitivity_capture <- function(expr) {
  warnings <- character()
  value <- withCallingHandlers(expr, warning = function(w) {
    warnings <<- c(warnings, conditionMessage(w))
    invokeRestart("muffleWarning")
  })
  list(value = value, warnings = unique(warnings))
}

drm_ou_sensitivity_fit_row <- function(
  fit,
  process,
  alpha,
  alpha_native,
  alpha_scale,
  warnings
) {
  data.frame(
    fit = if (identical(process, "BM")) {
      "BM"
    } else {
      paste0("OU(alpha=", format(alpha, trim = TRUE), ")")
    },
    process = process,
    alpha = alpha,
    alpha_native = alpha_native,
    alpha_scale = alpha_scale,
    logLik = as.numeric(stats::logLik(fit)),
    AIC = stats::AIC(fit),
    convergence = fit$opt$convergence,
    pdHess = isTRUE(fit$sdr$pdHess),
    max_gradient = max(abs(fit$gradient)),
    warning = if (length(warnings)) paste(warnings, collapse = " | ") else "",
    stringsAsFactors = FALSE
  )
}

drm_ou_sensitivity_coefficients <- function(fit, fit_id, alpha) {
  effects <- fixef(fit)
  do.call(
    rbind,
    lapply(names(effects), function(dpar) {
      value <- effects[[dpar]]
      data.frame(
        fit = fit_id,
        alpha = alpha,
        dpar = dpar,
        term = names(value),
        estimate = unname(value),
        row.names = NULL
      )
    })
  )
}

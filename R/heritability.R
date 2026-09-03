#' Heritability, ICC, and repeatability accessors
#'
#' `heritability()`, `icc()`, and `repeatability()` are derived-quantity
#' accessors for structured-Gaussian `drmTMB` fits, ported term-for-term from
#' `DRM.jl`'s `src/heritability.jl` (design doc
#' `docs/design/259-heritability-icc-repeatability.md`). All three report the
#' share of total variance carried by one structured random-effect component
#' relative to a denominator on the working (log-SD) scale:
#'
#' * `heritability()`: `sigma^2_focal / (sum of ALL structured mean-component
#'   variances + residual variance)` -- the comparative-biology "phylogenetic
#'   signal" definition.
#' * `icc()` / `repeatability()`: `sigma^2_focal / (sigma^2_focal + residual
#'   variance)` -- the classic focal-vs-residual intraclass correlation.
#'   `repeatability()` is an alias for `icc()`.
#'
#' `heritability()` and `icc()` return the same value only when the fit has a
#' single structured mean component (no other components to net out of the
#' denominator).
#'
#' Fits must be Gaussian, have a constant residual scale (`sigma ~ 1`), and
#' have at least one structured mean random-effect component (`(1 | group)`,
#' `phylo(...)`, `animal(...)`, `relmat(...)`, or `spatial(...)`); a
#' component modelled with `sd(group) ~ ...` (location-scale-scale) does not
#' define a single variance component and is refused. When a fit has more
#' than one structured component, `component` must name one of them (see
#' `object$sdpars$mu` for the available labels).
#'
#' Standard errors and confidence intervals use a delta method on the
#' working (log-SD) scale: a numeric gradient of the ratio in the log-SD
#' parameters, combined with the fixed-parameter covariance
#' (`object$sdr$cov.fixed`) via the quadratic form, then a Wald interval at
#' `level`, clamped to `[0, 1]`. This is a delta-method approximation; not a coverage claim.
#' See the design doc for the sanity-check evidence this slice carries.
#'
#' `method = "profile"` is accepted for call-site parity with `DRM.jl` but is
#' **not implemented** in this slice; it aborts naming `method = "delta"` as
#' the supported option.
#'
#' @param object A `drmTMB` fit.
#' @param component Optional character string naming the structured mean
#'   component (matching a name in `object$sdpars$mu`, e.g. `"(1 | id)"` or
#'   `"phylo(1 | species)"`; structured markers drop their non-grouping
#'   arguments such as `tree =`/`Ainv =`/`K =` from the label -- see the
#'   `@examples` phylo case below). Required when the fit has more than one
#'   structured component; ignored (and unnecessary) when the fit has exactly
#'   one.
#' @param level Confidence level for the Wald interval. Default `0.95`.
#' @param method Either `"delta"` (default) or `"profile"`. `"profile"` is
#'   accepted for signature parity only and always aborts in this slice.
#' @param ... Reserved for future extractor options.
#'
#' @return A one-row data frame (class `drm_heritability`) with columns
#'   `quantity`, `component`, `estimate`, `se`, `lower`, `upper`, `level`,
#'   and `method`.
#'
#' @examples
#' set.seed(20260525)
#' n_groups <- 20
#' n_per <- 8
#' grp <- factor(rep(seq_len(n_groups), each = n_per))
#' sd_g <- 1
#' sd_e <- 0.6
#' b_g <- rnorm(n_groups, sd = sd_g)
#' dat <- data.frame(y = 2 + b_g[grp] + rnorm(length(grp), sd = sd_e), grp = grp)
#' fit <- drmTMB(bf(y ~ 1 + (1 | grp), sigma ~ 1), data = dat)
#' icc(fit)
#' repeatability(fit)
#' heritability(fit)
#'
#' \donttest{
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   # A structured (phylo) component: its sdpars$mu / component label drops
#'   # the tree argument entirely and is just "phylo(1 | species)".
#'   set.seed(20260601)
#'   n_tip <- 20
#'   phy <- ape::rcoal(n_tip)
#'   phy$tip.label <- paste0("sp_", seq_len(n_tip))
#'   A <- ape::vcv(phy, corr = TRUE)
#'   u <- as.vector(t(chol(A)) %*% rnorm(n_tip)) * 0.9
#'   species <- factor(rep(phy$tip.label, each = 4), levels = phy$tip.label)
#'   phylo_dat <- data.frame(
#'     y = 2 + u[rep(seq_len(n_tip), each = 4)] +
#'       rnorm(length(species), sd = 0.6),
#'     species = species
#'   )
#'   phylo_fit <- drmTMB(
#'     bf(y ~ 1 + phylo(1 | species, tree = phy), sigma ~ 1),
#'     data = phylo_dat
#'   )
#'   icc(phylo_fit, component = "phylo(1 | species)")
#' }
#' }
#'
#' @name heritability
NULL

#' @rdname heritability
#' @export
heritability <- function(object, ...) {
  UseMethod("heritability")
}

#' @rdname heritability
#' @export
heritability.drmTMB <- function(
  object,
  component = NULL,
  level = 0.95,
  method = c("delta", "profile"),
  ...
) {
  method <- match.arg(method)
  drm_variance_ratio(
    object,
    quantity = "heritability",
    component = component,
    level = level,
    method = method
  )
}

#' @rdname heritability
#' @export
icc <- function(object, ...) {
  UseMethod("icc")
}

#' @rdname heritability
#' @export
icc.drmTMB <- function(
  object,
  component = NULL,
  level = 0.95,
  method = c("delta", "profile"),
  ...
) {
  method <- match.arg(method)
  drm_variance_ratio(
    object,
    quantity = "icc",
    component = component,
    level = level,
    method = method
  )
}

#' @rdname heritability
#' @export
repeatability <- function(object, ...) {
  UseMethod("repeatability")
}

#' @rdname heritability
#' @export
repeatability.drmTMB <- function(
  object,
  component = NULL,
  level = 0.95,
  method = c("delta", "profile"),
  ...
) {
  method <- match.arg(method)
  drm_variance_ratio(
    object,
    quantity = "repeatability",
    component = component,
    level = level,
    method = method
  )
}

#' @export
print.drm_heritability <- function(x, ...) {
  cli::cli_text(
    "<{x$quantity[[1L]]}> component = {.val {x$component[[1L]]}}"
  )
  cli::cli_text(
    "  estimate: {format(x$estimate[[1L]], digits = 4)}"
  )
  if (identical(x$method[[1L]], "delta") && is.finite(x$se[[1L]])) {
    cli::cli_text(
      "  se: {format(x$se[[1L]], digits = 4)}  {x$level[[1L]] * 100}% CI: [{format(x$lower[[1L]], digits = 4)}, {format(x$upper[[1L]], digits = 4)}]"
    )
  }
  invisible(x)
}

# ---------------------------------------------------------------------------
# Shared implementation.
# ---------------------------------------------------------------------------

# Build the gated variance-component ratio (heritability / icc / repeatability)
# and its delta-method SE + Wald CI. `quantity` is one of "heritability",
# "icc", "repeatability"; "icc" and "repeatability" share the focal-vs-residual
# denominator, "heritability" uses the total-variance denominator.
drm_variance_ratio <- function(
  object,
  quantity,
  component,
  level,
  method
) {
  if (method == "profile") {
    cli::cli_abort(
      "{.arg method} = {.val profile} is not implemented for {.fn {quantity}}; use {.code method = \"delta\"}."
    )
  }
  if (!identical(object$model$model_type, "gaussian")) {
    cli::cli_abort(c(
      "{.fn {quantity}} requires a Gaussian {.field model_type} fit.",
      "i" = "This fit has {.val {object$model$model_type}}."
    ))
  }
  drm_variance_ratio_reject_random_slopes(object, quantity)
  sigma <- drm_constant_residual_sigma(object)
  if (!is.finite(sigma)) {
    cli::cli_abort(c(
      "{.fn {quantity}} requires a constant residual scale ({.code sigma ~ 1}).",
      "i" = "This fit has a {.field sigma} predictor, a non-log link, or a known-dispersion override, so a single scalar residual variance is not defined."
    ))
  }
  sd_values <- object$sdpars$mu
  if (is.null(sd_values) || length(sd_values) == 0L) {
    cli::cli_abort(c(
      "{.fn {quantity}} requires at least one structured mean random-effect component.",
      "i" = "No {.code (1 | group)}, {.fn phylo}, {.fn animal}, {.fn relmat}, or {.fn spatial} term with a single scalar SD was found (a {.code sd(group) ~ ...} term does not define one)."
    ))
  }
  focal <- drm_variance_ratio_resolve_component(sd_values, component, quantity)
  positions <- drm_variance_ratio_positions(object, sd_values)
  if (anyNA(positions)) {
    cli::cli_abort(
      "{.fn {quantity}}: could not locate the working-scale parameter position for one or more structured components."
    )
  }
  resid_position <- which(names(object$opt$par) == "beta_sigma")
  if (length(resid_position) != 1L) {
    cli::cli_abort(
      "{.fn {quantity}}: could not locate a single residual scale parameter."
    )
  }

  if (quantity == "heritability") {
    denom_idx <- seq_along(sd_values)
  } else {
    denom_idx <- focal
  }
  denom_positions <- c(positions[denom_idx], resid_position)
  focal_position <- positions[[focal]]

  cov_fixed <- drm_sdreport_cov_fixed(object)

  fit <- drm_variance_ratio_delta(
    theta_hat = object$opt$par,
    cov_fixed = cov_fixed,
    denom_positions = denom_positions,
    focal_position = focal_position
  )

  crit <- stats::qnorm(1 - (1 - level) / 2)
  lower <- fit$estimate - crit * fit$se
  upper <- fit$estimate + crit * fit$se

  out <- data.frame(
    quantity = quantity,
    component = names(sd_values)[[focal]],
    estimate = fit$estimate,
    se = fit$se,
    lower = pmin(pmax(lower, 0), 1),
    upper = pmin(pmax(upper, 0), 1),
    level = level,
    method = "delta",
    stringsAsFactors = FALSE
  )
  class(out) <- c("drm_heritability", "data.frame")
  out
}

# Resolve `component` to an index into `sd_values`; default to the sole entry.
drm_variance_ratio_resolve_component <- function(sd_values, component, quantity) {
  if (is.null(component)) {
    if (length(sd_values) != 1L) {
      cli::cli_abort(c(
        "{.fn {quantity}}: this fit has {length(sd_values)} structured components.",
        "i" = "Pass {.arg component} naming one of: {.val {names(sd_values)}}."
      ))
    }
    return(1L)
  }
  match_idx <- match(component, names(sd_values))
  if (is.na(match_idx)) {
    cli::cli_abort(c(
      "{.fn {quantity}}: no structured component named {.val {component}}.",
      "i" = "Available components: {.val {names(sd_values)}}."
    ))
  }
  match_idx
}

# Refuse random slopes / correlated random effects on mu: they are not a
# variance share (an intercept-column SD and a per-unit-of-x slope-column SD
# are in different units, and DRM.jl's src/heritability.jl has no
# random-slope route to port here -- the correct behaviour is to refuse, not
# to silently sum incompatible variances or drop the intercept-slope
# correlation). Detected structurally from the fit's parameter structure, not
# by regexing the sdpars$mu label text:
#   (a) any `eta_cor_mu` entry in object$opt$par -- a correlated mu random
#       effect exists somewhere in the fit;
#   (b) object$model$random$mu$coef_names containing anything other than
#       "(Intercept)" -- a multi-column (slope) mu random-effect term, even
#       when uncorrelated (e.g. `(0 + x | g)`).
# See docs/design/259-heritability-icc-repeatability.md section 2 for the
# probe evidence behind (a)/(b) (object$model$random$mu$n_terms/coef_names/
# n_cors on a fitted `(1 + x | blk)` and `(0 + x | blk)` model).
drm_variance_ratio_reject_random_slopes <- function(object, quantity) {
  if ("eta_cor_mu" %in% names(object$opt$par)) {
    cli::cli_abort(c(
      "{.fn {quantity}} does not support correlated random effects on {.field mu}.",
      "i" = "Random slopes / correlated random effects are not a variance share; use scalar {.code (1 | g)} or structured intercepts."
    ))
  }
  random_mu <- object$model$random$mu
  if (is.list(random_mu) && isTRUE(random_mu$n_re > 0L)) {
    coef_names <- random_mu$coef_names
    slope_idx <- which(!is.na(coef_names) & coef_names != "(Intercept)")
    if (length(slope_idx) > 0L) {
      slope_terms <- unique(random_mu$labels[slope_idx])
      cli::cli_abort(c(
        "{.fn {quantity}} does not support random slopes on {.field mu}.",
        "x" = "This fit has a random-slope term: {.val {slope_terms}}.",
        "i" = "Random slopes / correlated random effects are not a variance share; use scalar {.code (1 | g)} or structured intercepts."
      ))
    }
  }
  invisible(NULL)
}

# Map each name in `sd_values` (== object$sdpars$mu) to its position in
# object$opt$par. Names matching a structured-marker prefix consume
# `log_sd_phylo` positions in order; every other name consumes `log_sd_mu`
# positions in order (see docs/design/259-heritability-icc-repeatability.md
# section 1 for why this reproduces split_tmb_sdpars()'s assignment order).
drm_variance_ratio_positions <- function(object, sd_values) {
  nm <- names(sd_values)
  structured_prefix <- "^(phylo|animal|relmat|spatial|phylo_interaction)\\("
  is_structured <- grepl(structured_prefix, nm)
  opt_names <- names(object$opt$par)
  mu_positions <- which(opt_names == "log_sd_mu")
  phylo_positions <- which(opt_names == "log_sd_phylo")
  positions <- rep(NA_integer_, length(nm))
  mu_rank <- 0L
  phylo_rank <- 0L
  for (i in seq_along(nm)) {
    if (is_structured[[i]]) {
      phylo_rank <- phylo_rank + 1L
      if (phylo_rank <= length(phylo_positions)) {
        positions[[i]] <- phylo_positions[[phylo_rank]]
      }
    } else {
      mu_rank <- mu_rank + 1L
      if (mu_rank <= length(mu_positions)) {
        positions[[i]] <- mu_positions[[mu_rank]]
      }
    }
  }
  positions
}

# Numeric-gradient delta method for the ratio
# g(theta) = exp(2*theta[focal]) / sum(exp(2*theta[denom])), evaluated at
# `theta_hat[denom_positions]`, with `focal_position` one entry of
# `denom_positions`. Returns list(estimate, se).
drm_variance_ratio_delta <- function(
  theta_hat,
  cov_fixed,
  denom_positions,
  focal_position
) {
  theta_denom <- unname(theta_hat[denom_positions])
  focal_slot <- which(denom_positions == focal_position)[[1L]]

  ratio_fun <- function(theta) {
    v <- exp(2 * theta)
    v[[focal_slot]] / sum(v)
  }
  estimate <- ratio_fun(theta_denom)

  h <- 1e-5
  grad <- vapply(seq_along(theta_denom), function(j) {
    plus <- theta_denom
    plus[[j]] <- plus[[j]] + h
    minus <- theta_denom
    minus[[j]] <- minus[[j]] - h
    (ratio_fun(plus) - ratio_fun(minus)) / (2 * h)
  }, numeric(1))

  cov_sub <- cov_fixed[denom_positions, denom_positions, drop = FALSE]
  variance <- as.numeric(t(grad) %*% cov_sub %*% grad)
  se <- if (is.finite(variance) && variance >= 0) sqrt(variance) else NA_real_

  list(estimate = estimate, se = se)
}

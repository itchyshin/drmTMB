# coevolution-accessors.R -- user-facing accessors for the q = 4 structured
# bivariate location-scale ("coevolution") fit, ported from DRM.jl's
# `src/coevo_accessors.jl` (pin 430ef64cc; #1118).
#
# The engine fits one shared structured random effect (phylogenetic, animal,
# relatedness, or spatial) on the four axes (mu1, mu2, sigma1, sigma2) with a
# 4 x 4 among-axis group-level covariance Sigma_a. drmTMB stores that
# covariance on the fit as the four axis SDs (`object$sdpars$mu`) and the six
# among-axis correlations (`object$corpars[[type]]`), which the C++ objective
# builds into `phylo_q4_covariance = D R D` (`src/drmTMB.cpp`, the dense
# `drm_qgt2_corr_matrix` branch). An `engine = "julia"` fit stores Sigma_a as
# DRM.jl's ten log-Cholesky entries in the `phylocov` slot instead.
#
# The accessors are deterministic maps of that stored covariance -- no
# re-optimisation, no uncertainty (DRM.jl's `coevo_accessors.jl` lines 19-22
# make the same restriction; bootstrap CIs on Sigma_a are a separate follow-up
# there too). Contract followed term-for-term:
#
#   * `coevolution_cor`     <- `coevo_accessors.jl` lines 85-95
#   * `coevolution_vc`      <- `coevo_accessors.jl` lines 120-126
#   * `coevolution_summary` <- `coevo_accessors.jl` lines 147-174
#   * the shared guard      <- `_coevo_sigma_a`, lines 32-43

#' Coevolution accessors for q = 4 structured bivariate location-scale fits
#'
#' `coevolution_cor()`, `coevolution_vc()`, and `coevolution_summary()` read
#' the among-axis structure of a q = 4 "coevolution" fit: a bivariate Gaussian
#' location-scale model whose four axes `mu1`, `mu2`, `sigma1`, `sigma2` share
#' one structured random effect (`phylo()`, `animal()`, `relmat()`, or
#' `spatial()`) with a dense 4 x 4 among-axis covariance `Sigma_a`. They are
#' ported term-for-term from `DRM.jl`'s `src/coevo_accessors.jl` (#1118) and
#' return the same quantities:
#'
#' * `coevolution_cor()`: the 4 x 4 among-axis **correlation** matrix
#'   `R = D^{-1/2} Sigma_a D^{-1/2}`. Its off-diagonals are the coevolutionary
#'   correlations -- `R["mu1", "mu2"]` is the among-species correlation of the
#'   two trait means, `R["sigma1", "sigma2"]` the correlation of the two
#'   log-scales, and the mean-scale entries the lability couplings.
#' * `coevolution_vc()`: the per-axis **variance components** `diag(Sigma_a)`,
#'   their square roots, and the full covariance.
#' * `coevolution_summary()`: both of the above in a tidy long form -- one
#'   entry per unordered axis pair (upper triangle, in `combn(4, 2)` order:
#'   `mu1:mu2`, `mu1:sigma1`, `mu1:sigma2`, `mu2:sigma1`, `mu2:sigma2`,
#'   `sigma1:sigma2`).
#'
#' Every value is a deterministic map of the covariance the fit already
#' stores; nothing is re-optimised and no uncertainty is reported (this
#' matches `DRM.jl`, which reports point estimates here and leaves interval
#' work to its bootstrap). For the residual between-response correlation see
#' [rho12()] and [corpairs()], which also lists these six correlations one
#' row each under `level = "phylogenetic"` (or the matching structured level).
#'
#' @section Which fits qualify:
#' The fit must be `family = biv_gaussian()` with one structured marker shared
#' by all four axes under a single covariance label, e.g.
#' `phylo(1 | p | species, tree = tree)` on `mu1`, `mu2`, `sigma1`, and
#' `sigma2`. Any other fit -- a residual-only bivariate model, a univariate
#' model, a q = 2 block on the two means only, an intercept-and-slope q = 4
#' block on one trait, or a block whose SD is itself modelled with
#' `sd_phylo(...) ~` -- stores no single 4 x 4 `Sigma_a` over the four
#' location-scale axes and is refused with an error, as in `DRM.jl`.
#'
#' Block-diagonal q = 4 blocks (two labelled 2 x 2 blocks) are accepted: the
#' cross-block correlations are exactly zero by construction and are reported
#' as such.
#'
#' @section Scale convention for `engine = "julia"` fits:
#' `DRM.jl` reports `Sigma_a` on the raw branch-length scale of the tree,
#' whereas native drmTMB standardises the phylogenetic covariance to unit
#' height (`ape::vcv(tree, corr = TRUE)`). For an `engine = "julia"` fit these
#' accessors rescale the stored covariance by the tree height (variances by
#' `height`, SDs by `sqrt(height)`) so that the same model reports the same
#' numbers under both engines -- the conversion [profile_targets()] and
#' [confint()] already apply to that fit's axis SDs. Correlations are
#' scale-free and are unaffected. On a unit-height tree the two conventions
#' coincide.
#'
#' @param object A `drmTMB` fit (native engine) or a `drmTMB_julia` fit
#'   (`engine = "julia"`) of a q = 4 structured bivariate location-scale
#'   model.
#'
#' @return All three return a plain list with the field names of the
#'   `DRM.jl` originals:
#'
#' * `coevolution_cor()`: `cor` (the 4 x 4 correlation matrix, symmetric,
#'   unit diagonal, dimnames = axes) and `axes` (the axis labels
#'   `c("mu1", "mu2", "sigma1", "sigma2")`, the row/column order).
#' * `coevolution_vc()`: `axes`, `variance` (named numeric, `diag(Sigma_a)`),
#'   `sd` (named numeric, its square root), and `cov` (the 4 x 4 `Sigma_a`).
#' * `coevolution_summary()`: `axes`, `variance`, `sd`, `pair` (a 6 x 2
#'   character matrix with columns `from` and `to`), `correlation` and
#'   `covariance` (numeric length 6, named `from:to`, in `pair` order),
#'   `cor`, and `cov`.
#'
#' @examples
#' \donttest{
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   set.seed(1)
#'   n_tip <- 16L
#'   tree <- ape::compute.brlen(ape::stree(n_tip, type = "balanced"), 1)
#'   tree$tip.label <- paste0("t", seq_len(n_tip))
#'   C <- ape::vcv(tree, corr = TRUE)
#'   Sigma_a <- diag(c(0.8, 0.7, 0.4, 0.4)) %*%
#'     matrix(c(1, 0.6, 0, 0, 0.6, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1), 4) %*%
#'     diag(c(0.8, 0.7, 0.4, 0.4))
#'   A <- t(chol(C)) %*% matrix(rnorm(n_tip * 4), n_tip, 4) %*% chol(Sigma_a)
#'   rows <- rep(seq_len(n_tip), each = 4)
#'   x <- rnorm(length(rows))
#'   dat <- data.frame(
#'     species = tree$tip.label[rows],
#'     x = x,
#'     y1 = rnorm(length(rows), 2 + 0.5 * x + A[rows, 1], exp(-0.7 + A[rows, 3])),
#'     y2 = rnorm(length(rows), -1 + 0.3 * x + A[rows, 2], exp(-0.5 + A[rows, 4]))
#'   )
#'   fit <- drmTMB(
#'     bf(
#'       mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
#'       mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
#'       sigma1 = ~ 1 + phylo(1 | p | species, tree = tree),
#'       sigma2 = ~ 1 + phylo(1 | p | species, tree = tree),
#'       rho12 = ~1
#'     ),
#'     family = biv_gaussian(),
#'     data = dat,
#'     control = drm_control(se = FALSE)
#'   )
#'   coevolution_cor(fit)$cor["mu1", "mu2"] # coevolution of the two trait means
#'   coevolution_vc(fit)$sd
#'   coevolution_summary(fit)$correlation
#' }
#' }
#'
#' @name coevolution-accessors
#' @rdname coevolution-accessors
NULL

#' @rdname coevolution-accessors
#' @export
coevolution_cor <- function(object) {
  state <- drm_coevolution_sigma_a(object)
  sd <- sqrt(diag(state$cov))
  d_inv <- diag(1 / sd, nrow = 4L)
  R <- d_inv %*% state$cov %*% d_inv
  R <- (R + t(R)) / 2 # exact symmetry (kill round-off)
  diag(R) <- 1 # exact unit diagonal
  dimnames(R) <- list(state$axes, state$axes)
  list(cor = R, axes = state$axes)
}

#' @rdname coevolution-accessors
#' @export
coevolution_vc <- function(object) {
  state <- drm_coevolution_sigma_a(object)
  variance <- stats::setNames(diag(state$cov), state$axes)
  list(
    axes = state$axes,
    variance = variance,
    sd = sqrt(variance),
    cov = state$cov
  )
}

#' @rdname coevolution-accessors
#' @export
coevolution_summary <- function(object) {
  vc <- coevolution_vc(object)
  rc <- coevolution_cor(object)
  axes <- vc$axes
  index <- utils::combn(4L, 2L) # upper triangle, row-major: (1,2) (1,3) ...
  pair <- cbind(from = axes[index[1L, ]], to = axes[index[2L, ]])
  pair_names <- paste(pair[, "from"], pair[, "to"], sep = ":")
  list(
    axes = axes,
    variance = vc$variance,
    sd = vc$sd,
    pair = pair,
    correlation = stats::setNames(rc$cor[t(index)], pair_names),
    covariance = stats::setNames(vc$cov[t(index)], pair_names),
    cor = rc$cor,
    cov = vc$cov
  )
}

# The four location-scale axes a coevolution fit couples, in the order
# DRM.jl's `fit.ranef.axes` reports them.
drm_coevolution_axes <- c("mu1", "mu2", "sigma1", "sigma2")

# Shared guard (DRM.jl `_coevo_sigma_a`): pull the stored 4 x 4 Sigma_a plus
# axis labels off a q = 4 coevolution fit, or refuse with one message. Returns
# list(cov = 4 x 4 covariance with dimnames, axes = character(4)).
drm_coevolution_sigma_a <- function(object) {
  if (inherits(object, "drmTMB_julia")) {
    return(drm_coevolution_sigma_a_julia(object))
  }
  if (!inherits(object, "drmTMB")) {
    cli::cli_abort(
      "{.arg object} must be a {.cls drmTMB} or {.cls drmTMB_julia} fit, not {.cls {class(object)}}."
    )
  }
  if (
    !identical(object$model$model_type, "biv_gaussian") ||
      !has_structured_mu_effect(object)
  ) {
    drm_coevolution_refuse()
  }
  phylo_mu <- object$model$structured$phylo_mu
  q <- structured_mu_q(phylo_mu)
  if (!identical(q, 4L)) {
    drm_coevolution_refuse(
      "This fit's structured block has q = {q} axes, not 4."
    )
  }
  axes <- drm_phylo_mu_axis_labels(phylo_mu)
  if (!identical(unname(axes), drm_coevolution_axes)) {
    drm_coevolution_refuse(
      "This fit's q = 4 block spans {.val {axes}}, not the four location-scale axes {.val {drm_coevolution_axes}}."
    )
  }
  if (isTRUE(object$model$random_scale$phylo$n_models > 0L)) {
    drm_coevolution_refuse(
      "This fit models the structured SD with {.code sd_phylo(...) ~}, so it has no single per-axis variance to report."
    )
  }

  sd_labels <- phylo_mu_sd_labels(phylo_mu, "biv_gaussian")
  sd <- unname(object$sdpars$mu[sd_labels])
  if (length(sd) != 4L || anyNA(sd) || any(!is.finite(sd)) || any(sd <= 0)) {
    cli::cli_abort(c(
      "Internal error: the four structured axis SDs could not be read from {.code object$sdpars$mu}.",
      i = "Expected finite positive entries named {.val {sd_labels}}."
    ))
  }

  cor_key <- structured_mu_correlation_key(phylo_mu)
  rho <- object$corpars[[cor_key]]
  pair_table <- phylo_mu_pair_table(phylo_mu)
  if (
    is.null(rho) ||
      length(rho) != nrow(pair_table) ||
      !identical(unname(names(rho)), pair_table$parameter) ||
      any(!is.finite(rho))
  ) {
    cli::cli_abort(c(
      "Internal error: the among-axis correlations in {.code object$corpars${cor_key}} do not match the fit's {nrow(pair_table)} axis pairs.",
      i = "Expected one finite entry per pair named {.val {pair_table$parameter}}."
    ))
  }
  R <- diag(4L)
  R[cbind(pair_table$from_index, pair_table$to_index)] <- unname(rho)
  R[cbind(pair_table$to_index, pair_table$from_index)] <- unname(rho)
  # Sigma_a = D R D, exactly the C++ `phylo_q4_covariance` construction
  # (src/drmTMB.cpp, `sd_phylo(a) * phylo_q4_corr(a, b) * sd_phylo(b)`).
  cov <- diag(sd, nrow = 4L) %*% R %*% diag(sd, nrow = 4L)
  cov <- (cov + t(cov)) / 2
  dimnames(cov) <- list(drm_coevolution_axes, drm_coevolution_axes)
  list(cov = cov, axes = drm_coevolution_axes)
}

# `engine = "julia"` fits: Sigma_a lives in the `phylocov` slot as DRM.jl's
# log-Cholesky entries (raw branch-length scale). Rescale to drmTMB's
# unit-height convention with the tree's `sd_scale = sqrt(height)`, the same
# factor `drm_julia_profile_targets_biv()` applies to the axis SDs (#693).
drm_coevolution_sigma_a_julia <- function(object) {
  if (!identical(object$model$model_type, "biv_gaussian")) {
    drm_coevolution_refuse()
  }
  cov <- drm_julia_phylocov_matrix(object)
  if (is.null(cov) || !identical(dim(cov), c(4L, 4L))) {
    drm_coevolution_refuse(
      "This {.code engine = \"julia\"} fit stores no 4 x 4 {.code phylocov} block."
    )
  }
  export_axes <- object$bridge$q4_point_export$axes
  axes <- if (is.character(export_axes) && length(export_axes) == 4L) {
    export_axes
  } else {
    drm_coevolution_axes
  }
  if (!identical(unname(axes), drm_coevolution_axes)) {
    drm_coevolution_refuse(
      "This fit's q = 4 block spans {.val {axes}}, not the four location-scale axes {.val {drm_coevolution_axes}}."
    )
  }
  scales <- object$structured_sd_scales
  if (is.null(scales)) {
    scales <- object$bridge_payload$structured_sd_scales
  }
  sd_scale <- 1
  if (!is.null(scales) && length(scales)) {
    finite_scale <- unname(scales[is.finite(scales) & scales > 0])
    if (length(finite_scale)) {
      sd_scale <- finite_scale[[1L]]
    }
  }
  cov <- cov * sd_scale^2
  cov <- (cov + t(cov)) / 2
  dimnames(cov) <- list(drm_coevolution_axes, drm_coevolution_axes)
  list(cov = cov, axes = drm_coevolution_axes)
}

drm_coevolution_refuse <- function(detail = NULL) {
  cli::cli_abort(
    c(
      "Coevolution accessors require a q = 4 structured bivariate location-scale fit (a shared {.fn phylo}/{.fn animal}/{.fn relmat}/{.fn spatial} block on {.code mu1}, {.code mu2}, {.code sigma1}, and {.code sigma2}); this fit stores no 4 x 4 among-axis covariance.",
      x = detail,
      i = "Fit, for example, {.code bf(mu1 = y1 ~ x + phylo(1 | p | species, tree = tree), mu2 = y2 ~ x + phylo(1 | p | species, tree = tree), sigma1 = ~ 1 + phylo(1 | p | species, tree = tree), sigma2 = ~ 1 + phylo(1 | p | species, tree = tree), rho12 = ~ 1)} with {.code family = biv_gaussian()}; for the residual correlation use {.fn rho12} or {.fn corpairs}."
    ),
    .envir = parent.frame()
  )
}

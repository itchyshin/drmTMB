#' Penalty / prior specification for a phylogenetic location-scale fit
#'
#' Builds an optional penalty (a weakly-informative prior) for the phylogenetic
#' standard deviations and, optionally, the phylogenetic cross-parameter
#' correlation of a [drmTMB()] fit. Passing the result to the `penalty` argument
#' of [drmTMB()] switches the estimator from plain maximum likelihood to a
#' penalized / maximum-a-posteriori (MAP) estimator.
#'
#' The standard-deviation penalty is a penalised-complexity (PC) prior (Simpson
#' et al. 2017): an exponential prior on the SD scale with mass at zero, which
#' regularises a weakly-identified phylogenetic SD (for example a scale-side
#' phylogenetic field at about one observation per tip) toward the simpler
#' "no phylogenetic variance" model. The rate is `lambda = -log(sd_alpha) / sd_u`
#' so that, a priori, `P(sd > sd_u) = sd_alpha`. The optional correlation
#' penalty is a mean-zero normal on the unconstrained phylogenetic correlation
#' parameter.
#'
#' A penalized fit is a MAP point estimate, not a maximum-likelihood fit: its
#' standard errors are credible-interval-shaped, and likelihood-ratio tests or
#' AIC across penalized fits are not standard. [logLik()] returns the
#' unpenalized data log-likelihood; the penalty contribution is stored
#' separately on the fit as `fit$phylo_penalty`.
#'
#' @param sd_u,sd_alpha Penalised-complexity prior scale and tail probability
#'   for each phylogenetic SD: a priori `P(sd > sd_u) = sd_alpha`. `sd_u` must
#'   be positive and `sd_alpha` must lie in `(0, 1)`.
#' @param cor_sd Optional standard deviation of a mean-zero normal penalty on
#'   the phylogenetic cross-parameter correlation parameter. `NULL` (the
#'   default) applies no correlation penalty.
#' @return An object of class `drm_phylo_penalty`.
#' @references
#' Simpson, D., Rue, H., Riebler, A., Martins, T. G., & Sorbye, S. H. (2017).
#' Penalising model component complexity: a principled, practical approach to
#' constructing priors. Statistical Science, 32(1), 1-28.
#'
#' Chung, Y., Rabe-Hesketh, S., Dorie, V., Gelman, A., & Liu, J. (2013). A
#' nondegenerate penalized likelihood estimator for variance parameters in
#' multilevel models. Psychometrika, 78(4), 685-709.
#' @export
drm_phylo_penalty <- function(sd_u = 1, sd_alpha = 0.05, cor_sd = NULL) {
  if (
    !is.numeric(sd_u) || length(sd_u) != 1L || !is.finite(sd_u) || sd_u <= 0
  ) {
    cli::cli_abort("{.arg sd_u} must be a single positive number.")
  }
  if (
    !is.numeric(sd_alpha) || length(sd_alpha) != 1L || !is.finite(sd_alpha) ||
      sd_alpha <= 0 || sd_alpha >= 1
  ) {
    cli::cli_abort("{.arg sd_alpha} must be a single number in (0, 1).")
  }
  if (!is.null(cor_sd)) {
    if (
      !is.numeric(cor_sd) || length(cor_sd) != 1L || !is.finite(cor_sd) ||
        cor_sd <= 0
    ) {
      cli::cli_abort("{.arg cor_sd} must be a single positive number or NULL.")
    }
  }
  structure(
    list(
      sd_u = sd_u,
      sd_alpha = sd_alpha,
      rate = -log(sd_alpha) / sd_u,
      cor_sd = cor_sd
    ),
    class = c("drm_phylo_penalty", "list")
  )
}

# Validate and normalise the `penalty` argument of drmTMB(). Returns NULL or a
# validated drm_phylo_penalty object.
drm_parse_phylo_penalty <- function(penalty) {
  if (is.null(penalty)) {
    return(NULL)
  }
  if (!inherits(penalty, "drm_phylo_penalty")) {
    cli::cli_abort(
      "{.arg penalty} must be created with {.fn drm_phylo_penalty} or be NULL."
    )
  }
  penalty
}

# Attach the penalty DATA fields to spec$tmb_data and, when penalizing, record
# the estimator and penalty on the spec. The DATA fields are ALWAYS added (with
# `penalize_phylo = 0L` and empty rate vectors when there is no penalty) so that
# TMB sees them for every model type and a plain-ML fit stays bit-identical.
drm_apply_phylo_penalty_spec <- function(spec, penalty) {
  spec$tmb_data$penalize_phylo <- 0L
  spec$tmb_data$phylo_sd_penalty_rate <- numeric(0)
  spec$tmb_data$phylo_cor_penalty_sd <- numeric(0)
  if (is.null(penalty)) {
    return(spec)
  }
  phylo_mu <- spec$structured$phylo_mu
  if (is.null(phylo_mu) || !isTRUE(phylo_mu$has)) {
    cli::cli_abort(c(
      "{.arg penalty} requires a phylogenetic term in the model.",
      "i" = "Add a {.code phylo(...)} term to a {.code mu}/{.code sigma} formula, or set {.code penalty = NULL}."
    ))
  }
  if (isTRUE(spec$tmb_data$has_sd_phylo_model == 1L)) {
    cli::cli_abort(c(
      "{.arg penalty} is not supported with direct {.code sd_phylo(...)} formulae yet.",
      "i" = "Use a {.code phylo(...)} random-effect term, or set {.code penalty = NULL}."
    ))
  }
  q_phylo <- length(spec$start$log_sd_phylo)
  if (q_phylo < 1L) {
    cli::cli_abort(
      "{.arg penalty} found no phylogenetic SD parameters to penalize."
    )
  }
  spec$tmb_data$penalize_phylo <- 1L
  spec$tmb_data$phylo_sd_penalty_rate <- rep(penalty$rate, q_phylo)
  spec$tmb_data$phylo_cor_penalty_sd <-
    if (is.null(penalty$cor_sd)) numeric(0) else penalty$cor_sd
  spec$estimator <- "MAP"
  spec$penalty <- penalty
  spec
}

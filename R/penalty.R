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
#'   default) applies no correlation penalty. A non-`NULL` `cor_sd` requires a
#'   coupled phylogenetic model with at least two phylogenetic SDs (for example
#'   a coupled location-scale or bivariate fit); a location-only phylogenetic
#'   model has a single phylogenetic SD and no correlation parameter to
#'   penalize, so [drmTMB()] errors rather than silently ignoring `cor_sd`.
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
#'
#' @examples
#' # Penalised-complexity prior: a priori P(phylogenetic SD > 1) = 0.05.
#' pen <- drm_phylo_penalty(sd_u = 1, sd_alpha = 0.05)
#' pen$rate
#'
#' # Also penalize the phylogenetic correlation in a coupled location-scale or
#' # bivariate phylogenetic model.
#' pen_cor <- drm_phylo_penalty(sd_u = 1, sd_alpha = 0.05, cor_sd = 0.5)
#' pen_cor$cor_sd
drm_phylo_penalty <- function(sd_u = 1, sd_alpha = 0.05, cor_sd = NULL) {
  if (
    !is.numeric(sd_u) || length(sd_u) != 1L || !is.finite(sd_u) || sd_u <= 0
  ) {
    cli::cli_abort("{.arg sd_u} must be a single positive number.")
  }
  if (
    !is.numeric(sd_alpha) ||
      length(sd_alpha) != 1L ||
      !is.finite(sd_alpha) ||
      sd_alpha <= 0 ||
      sd_alpha >= 1
  ) {
    cli::cli_abort("{.arg sd_alpha} must be a single number in (0, 1).")
  }
  if (!is.null(cor_sd)) {
    if (
      !is.numeric(cor_sd) ||
        length(cor_sd) != 1L ||
        !is.finite(cor_sd) ||
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
# validated drm_phylo_penalty / drm_boundary_penalty object.
drm_parse_penalty <- function(penalty) {
  if (is.null(penalty)) {
    return(NULL)
  }
  if (inherits(penalty, "drm_phylo_penalty") ||
      inherits(penalty, "drm_boundary_penalty")) {
    return(penalty)
  }
  cli::cli_abort(c(
    "{.arg penalty} must be created with {.fn drm_phylo_penalty}, {.fn drm_boundary_penalty}, or be NULL.",
    "i" = "Do not pass a raw list or an {.code estimator = \"mspl\"} token here; boundary soft-penalties use the {.arg penalty} vocabulary (design 256)."
  ))
}

# Compatibility alias — callers and older notes still name the phylo parser.
drm_parse_phylo_penalty <- drm_parse_penalty

#' Scale-equivariant boundary soft-penalty for ordinary RE SDs (experimental)
#'
#' Builds the Design-256 moving-anchor negative-Huber penalty for a univariate
#' Gaussian A1 cell: one ordinary iid `mu` random intercept `(1 | group)`. Pass
#' the result to [drmTMB()]'s `penalty` argument. The fit is labeled `MAP`;
#' intervals (`confint` / `profile`) are withheld on this experimental route.
#'
#' Softness rate `c_g = 2 * sqrt(q_v / g)` with `q_v = 1` for this cell. The
#' Huber argument is `log(sd_u) - mean(eta^sigma)`, so the penalty is exactly
#' scale-equivariant on the identity-link Gaussian location model (Theorem 1).
#' Defaults keep the shipped symmetric shape (`kappa_minus = kappa_plus = 1`).
#'
#' @param kappa_minus,kappa_plus Positive slope scales on the lower and upper
#'   sides of the negative Huber. Defaults `1` match the shipped MSPL shape.
#' @return An object of class `drm_boundary_penalty`.
#' @references
#' Sterzinger, W., Kosmidis, I., & Moustaki, I. (2026). Softly penalized
#' likelihood for factor models. Psychometrika.
#'
#' Chung, Y., Rabe-Hesketh, S., Dorie, V., Gelman, A., & Liu, J. (2013). A
#' nondegenerate penalized likelihood estimator for variance parameters in
#' multilevel models. Psychometrika, 78(4), 685-709.
#' @seealso [drm_phylo_penalty()], design
#'   `docs/design/256-mspl-boundary-penalty-derivation.md`
#' @export
#'
#' @examples
#' pen <- drm_boundary_penalty()
#' pen$c_g_formula
drm_boundary_penalty <- function(kappa_minus = 1, kappa_plus = 1) {
  validate_boundary_kappa <- function(x, name) {
    if (
      !is.numeric(x) || length(x) != 1L || !is.finite(x) || x <= 0
    ) {
      cli::cli_abort("{.arg {name}} must be a single positive number.")
    }
    as.numeric(x)
  }
  structure(
    list(
      kind = "boundary",
      kappa_minus = validate_boundary_kappa(kappa_minus, "kappa_minus"),
      kappa_plus = validate_boundary_kappa(kappa_plus, "kappa_plus"),
      q_v = 1L,
      c_g_formula = "2 * sqrt(q_v / g)",
      experimental = TRUE
    ),
    class = c("drm_boundary_penalty", "list")
  )
}

drm_boundary_c_g <- function(q_v, g) {
  if (
    !is.numeric(q_v) || length(q_v) != 1L || !is.finite(q_v) || q_v < 1 ||
      q_v != floor(q_v) ||
      !is.numeric(g) || length(g) != 1L || !is.finite(g) || g < 2
  ) {
    cli::cli_abort(
      "{.fn drm_boundary_c_g} requires integer q_v >= 1 and g >= 2."
    )
  }
  2 * sqrt(as.numeric(q_v) / as.numeric(g))
}

# Closed-form efficient information for log(sigma_u) on the balanced Gaussian
# A1 cell (design 256 eq. 5.1). Shipped as a unit-test oracle.
drm_boundary_I_g_log_sd <- function(g, m, sigma, sigma_u) {
  stopifnot(
    length(g) == 1L, length(m) == 1L, length(sigma) == 1L, length(sigma_u) == 1L
  )
  g <- as.numeric(g)
  m <- as.numeric(m)
  sigma <- as.numeric(sigma)
  sigma_u <- as.numeric(sigma_u)
  lambda1 <- sigma^2 + m * sigma_u^2
  2 * g * m^2 * (m - 1) * sigma_u^4 /
    (sigma^4 + (m - 1) * lambda1^2)
}

# Equivariance-weight table (design 256 §4.2). Fail loudly rather than default
# to s ≡ 1 for an unclassified family.
drm_boundary_equivariance_weight <- function(family_type, family = NULL) {
  link <- if (is.list(family) && !is.null(family$link)) {
    as.character(family$link)
  } else {
    NA_character_
  }
  if (identical(family_type, "gaussian")) {
    if (!is.na(link) && !identical(link, "identity")) {
      cli::cli_abort(c(
        "Boundary penalty equivariance weight is unclassified for {.code gaussian(link = {.val {link}})}.",
        "x" = "Design 256 §4.2 only classifies the identity-link Gaussian location RE.",
        "i" = "Do not silently default the residual-scale anchor to 1."
      ), class = "drm_boundary_equivariance_unclassified")
    }
    return(list(weight = 1L, anchor = "mean_eta_sigma", classified = TRUE))
  }
  cli::cli_abort(c(
    "Boundary penalty equivariance weight is unclassified for family {.val {family_type}}.",
    "x" = "S2 admits only the univariate Gaussian A1 identity-link location RE cell.",
    "i" = "Refuse rather than default the anchor to {.code s ≡ 1} (design 256 §4.2)."
  ), class = "drm_boundary_equivariance_unclassified")
}

drm_apply_boundary_penalty_spec <- function(spec, penalty) {
  # Inert defaults keep the shared TMB signature stable for every model type.
  spec$tmb_data$penalize_boundary <- 0L
  spec$tmb_data$boundary_c_g <- 0
  spec$tmb_data$boundary_kappa_minus <- 1
  spec$tmb_data$boundary_kappa_plus <- 1
  if (is.null(penalty) || !inherits(penalty, "drm_boundary_penalty")) {
    return(spec)
  }

  drm_boundary_equivariance_weight(spec$model_type, family = NULL)

  if (!identical(spec$model_type, "gaussian")) {
    cli::cli_abort(c(
      "Experimental {.fn drm_boundary_penalty} requires {.code family = gaussian()}.",
      "i" = "S2 is scoped to the A1 iid {.code sd(group)} cell only (design 256)."
    ))
  }

  re_mu <- spec$random$mu
  re_sigma <- spec$random$sigma
  if (is.null(re_mu) || !isTRUE(re_mu$n_terms == 1L)) {
    cli::cli_abort(c(
      "Experimental {.fn drm_boundary_penalty} requires exactly one ordinary {.code mu} random-intercept term.",
      "i" = "Use {.code bf(y ~ x + (1 | group), sigma ~ 1)}."
    ))
  }
  if (!identical(re_mu$coef_names, "(Intercept)")) {
    cli::cli_abort(c(
      "Experimental {.fn drm_boundary_penalty} admits only an intercept-only {.code (1 | group)} term.",
      "x" = "Found coefficient(s): {.val {re_mu$coef_names}}."
    ))
  }
  if (!isTRUE(re_mu$n_cors == 0L)) {
    cli::cli_abort(
      "Experimental {.fn drm_boundary_penalty} does not admit correlated random-effect blocks yet."
    )
  }
  if (!is.null(re_sigma) && isTRUE(re_sigma$n_terms > 0L)) {
    cli::cli_abort(
      "Experimental {.fn drm_boundary_penalty} does not admit sigma-side random effects yet."
    )
  }
  if (isTRUE(spec$tmb_data$has_sd_mu_model == 1L)) {
    cli::cli_abort(
      "Experimental {.fn drm_boundary_penalty} does not admit {.code sd(...)} regression formulae yet."
    )
  }

  phylo_mu <- if (is.list(spec$structured)) spec$structured$phylo_mu else NULL
  if (is.list(phylo_mu) && isTRUE(phylo_mu$has)) {
    cli::cli_abort(c(
      "Experimental {.fn drm_boundary_penalty} does not combine with {.fn phylo} terms.",
      "i" = "Use {.fn drm_phylo_penalty} for phylogenetic MAP, or drop the structured term."
    ))
  }
  if (isTRUE(spec$tmb_data$has_mesh_spatial_mu == 1L) ||
      isTRUE(spec$tmb_data$has_phylo_mu == 1L) ||
      isTRUE(spec$tmb_data$has_phylo_mu2 == 1L)) {
    cli::cli_abort(
      "Experimental {.fn drm_boundary_penalty} admits only ordinary iid grouping, not structured fields."
    )
  }

  group_levels <- re_mu$groups[[1L]]
  g <- length(group_levels)
  if (!is.finite(g) || g < 2L) {
    cli::cli_abort(
      "Experimental {.fn drm_boundary_penalty} needs at least two grouping levels."
    )
  }
  # Design 256 §4.3c: reject designs with any singleton group (m ≡ 1).
  group_name <- re_mu$group_names[[1L]]
  group_factor <- factor(spec$data[[group_name]], levels = group_levels)
  sizes <- tabulate(as.integer(group_factor), nbins = g)
  if (any(sizes < 2L)) {
    cli::cli_abort(c(
      "Experimental {.fn drm_boundary_penalty} rejects designs with singleton groups.",
      "x" = "At least one level of {.field {group_name}} has size 1, so sigma and sigma_u are not separately identified along the scale orbit.",
      "i" = "Require within-group replication (m >= 2) for every retained level (design 256 §4.3c)."
    ), class = "drm_boundary_singleton_group")
  }

  q_v <- as.integer(penalty$q_v)
  c_g <- drm_boundary_c_g(q_v, g)
  spec$tmb_data$penalize_boundary <- 1L
  spec$tmb_data$boundary_c_g <- c_g
  spec$tmb_data$boundary_kappa_minus <- penalty$kappa_minus
  spec$tmb_data$boundary_kappa_plus <- penalty$kappa_plus
  spec$estimator <- "MAP"
  spec$penalty <- penalty
  spec$boundary_penalty_meta <- list(
    g = as.integer(g),
    q_v = q_v,
    c_g = c_g,
    group = group_name
  )
  spec
}

# Attach penalty DATA fields. Phylo and boundary routes are mutually exclusive;
# inert zeros are always present so plain ML stays bit-identical.
drm_apply_phylo_penalty_spec <- function(spec, penalty) {
  spec$tmb_data$penalize_phylo <- 0L
  spec$tmb_data$phylo_sd_penalty_rate <- numeric(0)
  spec$tmb_data$phylo_cor_penalty_sd <- numeric(0)
  spec <- drm_apply_boundary_penalty_spec(spec, NULL)

  if (is.null(penalty)) {
    return(spec)
  }

  if (inherits(penalty, "drm_boundary_penalty")) {
    return(drm_apply_boundary_penalty_spec(spec, penalty))
  }

  if (!inherits(penalty, "drm_phylo_penalty")) {
    cli::cli_abort(
      "{.arg penalty} must be a {.fn drm_phylo_penalty} or {.fn drm_boundary_penalty} object."
    )
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
  if (!is.null(penalty$cor_sd) && q_phylo < 2L) {
    cli::cli_abort(
      c(
        "{.arg cor_sd} requires a coupled phylogenetic model with at least two phylogenetic SDs.",
        "x" = "This model has a single phylogenetic SD ({.val {q_phylo}}), so there is no phylogenetic correlation parameter to penalize and {.arg cor_sd} would be silently ignored.",
        "i" = "Set {.code cor_sd = NULL} for a location-only phylogenetic model, or add a second phylogenetic term (for example a coupled location-scale or bivariate fit) before penalizing the correlation."
      ),
      class = "drm_phylo_cor_penalty_needs_two_sd"
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

#' Prior-sensitivity sweep for the phylogenetic correlation penalty
#'
#' Refits a penalized (MAP) phylogenetic model across a range of `cor_sd` values
#' so you can see whether a weakly identified coupling is data-informed or
#' prior-shaped. There is no universal `cor_sd`: a coupling that is stable across
#' the sweep is data-informed, while one that tracks `cor_sd` is prior-shaped.
#' This is the sweep the penalized/MAP workflow asks you to run; it is most
#' informative for coupled location-scale or bivariate phylogenetic models that
#' actually estimate a phylogenetic correlation.
#'
#' @param formula,data,family,control Passed to [drmTMB()].
#' @param cor_sd Numeric vector of positive correlation-penalty SDs to sweep.
#' @param sd_u,sd_alpha Penalty SD-prior parameters; see [drm_phylo_penalty()].
#' @param ... Further arguments passed to [drmTMB()].
#'
#' @return A list with `$summary` -- a data frame with one row per `cor_sd`
#'   giving `convergence`, `pdHess`, `logLik`, and any fit `error` -- and `$fits`
#'   -- the fitted objects, named by `cor_sd`, for extracting `corpars()`,
#'   `coef()`, and other couplings.
#' @export
#'
#' @examples
#' \donttest{
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   set.seed(20260601)
#'   n_tip <- 10
#'   tree <- ape::rcoal(n_tip)
#'   tree$tip.label <- paste0("sp_", seq_len(n_tip))
#'   A <- ape::vcv(tree, corr = TRUE)
#'   u <- as.vector(t(chol(A)) %*% rnorm(n_tip)) * 0.6
#'   species <- factor(rep(tree$tip.label, each = 2), levels = tree$tip.label)
#'   x <- rnorm(length(species))
#'   dat <- data.frame(
#'     y = 0.3 + 0.5 * x + u[rep(seq_len(n_tip), each = 2)] +
#'       rnorm(length(species), sd = 0.5),
#'     x = x,
#'     species = species
#'   )
#'
#'   # A coupled location-scale phylo model has two phylogenetic SDs, so the
#'   # cor_sd sweep is informative (see drm_phylo_penalty()).
#'   out <- drm_phylo_penalty_sweep(
#'     bf(
#'       y ~ x + phylo(1 | species, tree = tree),
#'       sigma ~ phylo(1 | species, tree = tree)
#'     ),
#'     data = dat,
#'     family = gaussian(),
#'     cor_sd = c(0.5, 1)
#'   )
#'   out$summary
#' }
#' }
drm_phylo_penalty_sweep <- function(
  formula,
  data,
  family = gaussian(),
  cor_sd = c(0.25, 0.5, 1),
  sd_u = 1,
  sd_alpha = 0.05,
  control = drm_control(),
  ...
) {
  if (
    !is.numeric(cor_sd) ||
      length(cor_sd) == 0L ||
      any(!is.finite(cor_sd)) ||
      any(cor_sd <= 0)
  ) {
    cli::cli_abort("{.arg cor_sd} must be a vector of positive numbers.")
  }
  # A cor_sd sweep is only meaningful when the model actually estimates a
  # phylogenetic correlation (>= 2 phylogenetic SDs). For a single-SD phylo
  # model the correlation penalty is inert, so every row would be identical and
  # the sweep would look like a prior-sensitivity check while being a no-op.
  # Probe the first cor_sd and refuse the whole sweep if the model has no
  # correlation parameter to penalize.
  probe <- tryCatch(
    drmTMB(
      formula,
      data = data,
      family = family,
      penalty = drm_phylo_penalty(
        sd_u = sd_u,
        sd_alpha = sd_alpha,
        cor_sd = cor_sd[[1L]]
      ),
      control = control,
      ...
    ),
    drm_phylo_cor_penalty_needs_two_sd = function(e) e
  )
  if (inherits(probe, "drm_phylo_cor_penalty_needs_two_sd")) {
    cli::cli_abort(
      c(
        "A {.arg cor_sd} sweep requires a coupled phylogenetic model with at least two phylogenetic SDs.",
        "x" = "This model has a single phylogenetic SD, so the correlation penalty is inert and every row of the sweep would be identical.",
        "i" = "Sweep a coupled location-scale or bivariate phylogenetic model, or drop the {.arg cor_sd} sweep for this location-only model."
      ),
      class = "drm_phylo_cor_penalty_needs_two_sd"
    )
  }
  fits <- lapply(cor_sd, function(cs) {
    tryCatch(
      drmTMB(
        formula,
        data = data,
        family = family,
        penalty = drm_phylo_penalty(
          sd_u = sd_u,
          sd_alpha = sd_alpha,
          cor_sd = cs
        ),
        control = control,
        ...
      ),
      error = function(e) e
    )
  })
  summary <- do.call(
    rbind,
    Map(
      function(cs, fit) {
        if (inherits(fit, "error")) {
          data.frame(
            cor_sd = cs,
            convergence = NA_integer_,
            pdHess = NA,
            logLik = NA_real_,
            error = conditionMessage(fit),
            stringsAsFactors = FALSE
          )
        } else {
          data.frame(
            cor_sd = cs,
            convergence = fit$opt$convergence,
            pdHess = isTRUE(fit$sdr$pdHess),
            logLik = as.numeric(fit$logLik),
            error = NA_character_,
            stringsAsFactors = FALSE
          )
        }
      },
      cor_sd,
      fits
    )
  )
  row.names(summary) <- NULL
  names(fits) <- paste0("cor_sd=", cor_sd)
  list(summary = summary, fits = fits)
}

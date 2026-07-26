# B1 cell adapters.
#
# These are deliberately thin lifts of existing drmTMB recovery fixtures.  They
# standardise only the DGP/fit/truth interface used by the B1 worker; they do
# not alter a family likelihood, formula grammar, or interval method.

b1_adapter_stop <- function(...) stop(..., call. = FALSE)

b1_rung_size <- function(rung) {
  out <- c(low = 24L, medium = 48L, high = 96L)[[as.character(rung)]]
  if (is.null(out)) b1_adapter_stop("Unknown B1 information rung: ", rung)
  unname(out)
}

b1_require_drmTMB <- function() {
  if (!requireNamespace("drmTMB", quietly = TRUE)) {
    b1_adapter_stop("drmTMB must be installed or loaded before a B1 fit.")
  }
  invisible(TRUE)
}

b1_beta_mu_intercept <- function(seed, rung) {
  b1_require_drmTMB()
  set.seed(seed)
  n_id <- b1_rung_size(rung); n_each <- 10L
  id <- factor(rep(seq_len(n_id), each = n_each)); n <- length(id)
  x <- stats::rnorm(n); z <- stats::rnorm(n)
  truth_sd <- 0.55
  effect <- stats::rnorm(n_id, sd = truth_sd); names(effect) <- levels(id)
  eta <- -0.30 + 0.70 * x + effect[as.character(id)]
  sigma <- exp(-0.85 + 0.16 * z)
  phi <- sigma^(-2)
  list(
    data = data.frame(prop = stats::rbeta(n, stats::plogis(eta) * phi, (1 - stats::plogis(eta)) * phi), x, z, id),
    truth = list(sd = truth_sd, field = effect, target = "sd:mu:(1 | id)"),
    fit = function(dat) drmTMB::drmTMB(drmTMB::bf(prop ~ x + (1 | id), sigma ~ z), family = drmTMB::beta(), data = dat)
  )
}

b1_binomial_mu_intercept <- function(seed, rung) {
  b1_require_drmTMB()
  set.seed(seed)
  n_id <- b1_rung_size(rung); n_each <- 12L
  id <- factor(rep(seq_len(n_id), each = n_each)); n <- length(id)
  x <- stats::rnorm(n); truth_sd <- 0.80
  effect <- stats::rnorm(n_id, sd = truth_sd); names(effect) <- levels(id)
  trials <- stats::rpois(n, 8) + 3L
  p <- stats::plogis(-0.2 + 0.7 * x + effect[as.character(id)])
  success <- stats::rbinom(n, trials, p)
  list(
    data = data.frame(success, failure = trials - success, x, id),
    truth = list(sd = truth_sd, field = effect, target = "sd:mu:(1 | id)"),
    fit = function(dat) drmTMB::drmTMB(drmTMB::bf(cbind(success, failure) ~ x + (1 | id)), family = stats::binomial(), data = dat)
  )
}

b1_nongaussian_mu_slope <- function(seed, rung, family = c("beta_binomial", "truncated_nbinom2")) {
  b1_require_drmTMB()
  family <- match.arg(family)
  set.seed(seed)
  n_id <- b1_rung_size(rung); n_each <- 8L
  id <- factor(rep(seq_len(n_id), each = n_each)); n <- length(id)
  x <- rep(seq(-1.25, 1.25, length.out = n_each), times = n_id) + stats::rnorm(n, sd = 0.03)
  slope_raw <- stats::qnorm((seq_len(n_id) - 0.5) / n_id)
  slope <- 0.48 * as.numeric(scale(slope_raw)); names(slope) <- levels(id)
  eta <- 0.15 + 0.42 * x + slope[as.character(id)] * x
  if (identical(family, "beta_binomial")) {
    trials <- rep(18L, n); mu <- stats::plogis(eta); phi <- 36
    p <- stats::rbeta(n, shape1 = mu * phi, shape2 = (1 - mu) * phi)
    success <- stats::rbinom(n, trials, p)
    return(list(
      data = data.frame(success, failure = trials - success, x, id),
      truth = list(sd = 0.48, field = slope, target = "sd:mu:(0 + x | id)"),
      fit = function(dat) drmTMB::drmTMB(drmTMB::bf(cbind(success, failure) ~ x + (0 + x | id), sigma ~ 1), family = drmTMB::beta_binomial(), data = dat)
    ))
  }
  mu <- exp(eta); sigma <- 0.36
  y <- stats::rnbinom(n, mu = mu, size = sigma^(-2))
  while (any(y == 0L)) {
    zero <- y == 0L
    y[zero] <- stats::rnbinom(sum(zero), mu = mu[zero], size = sigma^(-2))
  }
  list(
    data = data.frame(y, x, id),
    truth = list(sd = 0.48, field = slope, target = "sd:mu:(0 + x | id)"),
    fit = function(dat) drmTMB::drmTMB(drmTMB::bf(y ~ x + (0 + x | id), sigma ~ 1), family = drmTMB::truncated_nbinom2(), data = dat)
  )
}

b1_hurdle_relmat <- function(seed, rung) {
  b1_require_drmTMB()
  set.seed(seed)
  # This fixture's established recovery design starts at 60 groups.  It is a
  # hurdle-side field, so borrowing the ordinary-RE 24-group low rung creates a
  # false weak-identification failure before the model is actually exercised.
  n_id <- c(low = 60L, medium = 90L, high = 120L)[[as.character(rung)]]
  n_each <- 20L
  levels_id <- paste0("th", seq_len(n_id)); id <- factor(rep(levels_id, each = n_each), levels = levels_id)
  x <- stats::rnorm(length(id)); truth_sd <- 1
  field <- stats::rnorm(n_id, sd = truth_sd); names(field) <- levels_id
  probability <- stats::plogis(-0.8 + field[as.character(id)])
  positive <- stats::rnbinom(length(id), mu = exp(0.5 + 0.2 * x), size = 12)
  positive[positive == 0L] <- 1L
  Q <- diag(n_id); dimnames(Q) <- list(levels_id, levels_id)
  list(
    data = data.frame(y = ifelse(stats::rbinom(length(id), 1L, probability) == 1L, 0L, positive), x, id),
    truth = list(sd = truth_sd, field = field, target = "sd:hu:relmat(1 | id)", Q = Q),
    fit = function(dat) drmTMB::drmTMB(drmTMB::bf(y ~ x, sigma ~ 1, hu ~ drmTMB::relmat(1 | id, Q = Q)), family = drmTMB::truncated_nbinom2(), data = dat, control = drmTMB::drm_control(se = FALSE))
  )
}

b1_star_tree <- function(levels) {
  if (!requireNamespace("ape", quietly = TRUE)) b1_adapter_stop("ape is required for a B1 phylogenetic adapter.")
  tree <- ape::stree(length(levels), type = "star")
  tree$tip.label <- levels
  tree$edge.length <- rep(1, nrow(tree$edge))
  tree
}

b1_cumulative_logit_phylo <- function(seed, rung) {
  b1_require_drmTMB()
  set.seed(seed)
  n_species <- c(low = 12L, medium = 24L, high = 48L)[[as.character(rung)]]
  species_levels <- paste0("sp", seq_len(n_species)); n_each <- 18L
  species <- factor(rep(species_levels, each = n_each), levels = species_levels)
  x <- stats::rnorm(length(species)); truth_sd <- 0.35
  field <- stats::rnorm(n_species, sd = truth_sd); names(field) <- species_levels
  eta <- 0.55 * x + field[as.character(species)]
  cutpoints <- c(-0.65, 0.75)
  p_low <- stats::plogis(cutpoints[[1L]] - eta)
  probability <- cbind(p_low, stats::plogis(cutpoints[[2L]] - eta) - p_low, 1 - stats::plogis(cutpoints[[2L]] - eta))
  draw <- vapply(seq_len(nrow(probability)), function(i) sample.int(3L, 1L, prob = probability[i, ]), integer(1L))
  tree <- b1_star_tree(species_levels)
  list(
    data = data.frame(score = ordered(c("low", "medium", "high")[draw], levels = c("low", "medium", "high")), x, species),
    truth = list(sd = truth_sd, field = field, target = "sd:mu:phylo(1 | species)", tree = tree),
    fit = function(dat) drmTMB::drmTMB(drmTMB::bf(score ~ x + drmTMB::phylo(1 | species, tree = tree)), family = drmTMB::cumulative_logit(), data = dat, control = drmTMB::drm_control(se = FALSE))
  )
}

b1_spatial_field <- function(levels, truth_sd, group = "site") {
  theta <- seq(0, 1.9 * pi, length.out = length(levels))
  coords <- data.frame(x = cos(theta), y = sin(theta), row.names = levels)
  precision <- drmTMB:::drm_spatial_coords_precision(coords, site = levels, group = group)
  covariance <- solve(as.matrix(precision$precision))
  field <- as.vector(t(chol(covariance)) %*% stats::rnorm(length(levels), sd = truth_sd))
  names(field) <- levels
  list(coords = coords, field = field)
}

b1_zi_spatial <- function(seed, rung, family = c("poisson", "nbinom2"), target_dpar = c("zi", "mu")) {
  b1_require_drmTMB()
  family <- match.arg(family); target_dpar <- match.arg(target_dpar)
  set.seed(seed)
  n_site <- c(low = 30L, medium = 60L, high = 90L)[[as.character(rung)]]
  levels_site <- paste0("s", seq_len(n_site)); n_each <- 15L
  site <- factor(rep(levels_site, each = n_each), levels = levels_site)
  x <- stats::rnorm(length(site)); spatial <- b1_spatial_field(levels_site, truth_sd = 0.8)
  mu_field <- if (identical(target_dpar, "mu")) spatial$field else stats::setNames(rep(0, n_site), levels_site)
  zi_field <- if (identical(target_dpar, "zi")) spatial$field else stats::setNames(rep(0, n_site), levels_site)
  mu <- exp(0.45 + 0.25 * x + mu_field[as.character(site)])
  observed <- if (identical(family, "poisson")) stats::rpois(length(site), mu) else stats::rnbinom(length(site), mu = mu, size = 8)
  probability_zero <- stats::plogis(-0.6 + zi_field[as.character(site)])
  y <- ifelse(stats::rbinom(length(site), 1L, probability_zero) == 1L, 0L, observed)
  coords <- spatial$coords
  target_group <- if (identical(family, "poisson") && identical(target_dpar, "zi")) "id" else "site"
  target <- paste0("sd:", target_dpar, ":spatial(1 | ", target_group, ")")
  list(
    data = data.frame(y, x, site, id = site),
    truth = list(sd = 0.8, field = spatial$field, target = target, coords = spatial$coords),
    fit = function(dat) {
      if (identical(family, "poisson") && identical(target_dpar, "zi")) {
        drmTMB::drmTMB(drmTMB::bf(y ~ x, zi ~ drmTMB::spatial(1 | id, coords = coords)), family = stats::poisson(link = "log"), data = dat, control = drmTMB::drm_control(se = FALSE))
      } else if (identical(family, "nbinom2") && identical(target_dpar, "mu")) {
        drmTMB::drmTMB(drmTMB::bf(y ~ x + drmTMB::spatial(1 | site, coords = coords), sigma ~ 1, zi ~ 1), family = drmTMB::nbinom2(), data = dat, control = drmTMB::drm_control(se = FALSE))
      } else {
        b1_adapter_stop("Unsupported B1 zero-inflated spatial route.")
      }
    }
  )
}

b1_student_nu_phylo <- function(seed, rung) {
  b1_require_drmTMB()
  set.seed(seed)
  n_id <- c(low = 12L, medium = 24L, high = 48L)[[as.character(rung)]]
  levels_id <- paste0("sn", seq_len(n_id)); n_each <- 30L
  id <- factor(rep(levels_id, each = n_each), levels = levels_id)
  x <- stats::rnorm(length(id)); truth_sd <- 0.10
  field <- stats::rnorm(n_id, sd = truth_sd); names(field) <- levels_id
  nu <- 2 + exp(log(5) + field[as.character(id)])
  y <- 0.1 + 0.35 * x + 0.25 * stats::rt(length(id), df = nu)
  tree <- b1_star_tree(levels_id)
  list(
    data = data.frame(y, x, id),
    truth = list(sd = truth_sd, field = field, target = "sd:nu:phylo(1 | id)", tree = tree),
    fit = function(dat) drmTMB::drmTMB(drmTMB::bf(y ~ x, sigma ~ 1, nu ~ drmTMB::phylo(1 | id, tree = tree)), family = drmTMB::student(), data = dat, control = drmTMB::drm_control(se = FALSE))
  )
}

b1_skew_normal_response <- function(mu, sigma, nu) {
  delta <- nu / sqrt(1 + nu^2)
  shift <- delta * sqrt(2 / pi)
  omega <- sigma / sqrt(1 - shift^2)
  xi <- mu - omega * shift
  xi + omega * (delta * abs(stats::rnorm(length(mu))) + sqrt(1 - delta^2) * stats::rnorm(length(mu)))
}

b1_skew_normal_nu <- function(seed, rung) {
  b1_require_drmTMB()
  set.seed(seed)
  n <- c(low = 360L, medium = 720L, high = 1440L)[[as.character(rung)]]
  x <- seq(-1.2, 1.2, length.out = n)
  z <- rep(seq(-1, 1, length.out = 24), length.out = n)
  truth_nu <- 1.2
  list(
    data = data.frame(y = b1_skew_normal_response(0.2 + 0.4 * x, exp(-0.3 + 0.15 * z), truth_nu), x, z),
    truth = list(nu = truth_nu, target = "fixef:nu:(Intercept)"),
    fit = function(dat) drmTMB::drmTMB(drmTMB::bf(y ~ x, sigma ~ z, nu ~ 1), family = drmTMB::skew_normal(), data = dat, control = drmTMB::drm_control(se = FALSE))
  )
}

b1_adapter_fixture <- function(cell_id, seed, rung) {
  switch(cell_id,
    "mc-0005" = b1_beta_mu_intercept(seed, rung),
    "mc-0031" = b1_nongaussian_mu_slope(seed, rung, "beta_binomial"),
    "mc-0059" = b1_binomial_mu_intercept(seed, rung),
    "mc-0229" = b1_cumulative_logit_phylo(seed, rung),
    "mc-0364" = b1_hurdle_relmat(seed, rung),
    "mc-0460" = b1_skew_normal_nu(seed, rung),
    "mc-0495" = b1_student_nu_phylo(seed, rung),
    "mc-0511" = b1_nongaussian_mu_slope(seed, rung, "truncated_nbinom2"),
    "mc-0641" = b1_zi_spatial(seed, rung, "nbinom2", "mu"),
    "mc-0667" = b1_zi_spatial(seed, rung, "poisson", "zi"),
    b1_adapter_stop("No fixture-lift adapter is registered for ", cell_id, ".")
  )
}

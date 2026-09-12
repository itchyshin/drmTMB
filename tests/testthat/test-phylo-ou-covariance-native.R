test_that("stationary phylogenetic OU covariance matches ape::corMartins", {
  skip_if_not_installed("ape")
  set.seed(2026091103)
  tree <- ape::rcoal(5)
  tree$tip.label <- paste0("sp", seq_len(5))
  decay <- 0.7

  expected <- nlme::corMatrix(
    ape::corMartins(decay, tree), covariate = tree$tip.label
  )
  actual <- drmTMB:::drm_phylo_ou_tip_covariance(tree, decay = decay)

  expect_equal(actual, expected, tolerance = 1e-12)
})

test_that("stationary phylogenetic OU layout retains the root and every tree edge", {
  skip_if_not_installed("ape")
  set.seed(2026091104)
  tree <- ape::rcoal(4)
  tree$tip.label <- paste0("sp", seq_len(4))
  layout <- drmTMB:::drm_phylo_ou_augmented_layout(
    tree, species = rep(tree$tip.label, each = 2)
  )

  expect_equal(layout$n_re, length(tree$tip.label) + tree$Nnode)
  expect_equal(length(layout$edge_parent_index0), nrow(tree$edge))
  expect_equal(length(layout$edge_child_index0), nrow(tree$edge))
  expect_equal(length(layout$edge_length), nrow(tree$edge))
  expect_equal(layout$observation_node_index0,
    rep(seq_along(tree$tip.label) - 1L, each = 2)
  )
  expect_true(layout$root_index0 %in% (seq_len(layout$n_re) - 1L))
})

test_that("Gaussian phylogenetic OU fits a native stationary tree provider", {
  skip_if_not_installed("ape")
  set.seed(2026091105)
  tree <- ape::rcoal(5)
  tree$tip.label <- paste0("sp", seq_len(5))
  species <- rep(tree$tip.label, each = 5)
  x <- rep(c(-0.5, 0.5), length.out = length(species))
  y <- 0.2 + 0.4 * x + stats::rnorm(length(species), sd = 0.35)
  fit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree, model = "ou"), sigma ~ 1),
    data = data.frame(y, x, species), family = gaussian()
  )

  expect_true(is.finite(as.numeric(logLik(fit))))
  expect_true("log_decay_phylo" %in% names(fit$tmb_state$opt.par))
  expect_true(is.finite(unname(fit$tmb_state$opt.par[["log_decay_phylo"]])))
  expect_identical(fit$model$structured$phylo_mu$provider$covariance, "ou")
  expect_identical(
    fit$model$structured$phylo_mu$provider$alpha_parameter,
    "log_decay_phylo"
  )
  expect_identical(fit$model$structured$phylo_mu$provider$alpha_index0, 0L)
  expect_identical(fit$model$structured$phylo_mu$provider$field_id, "phylo_mu")
  fields <- drmTMB:::phylo_ou_provider_fields(fit$model$structured$phylo_mu)
  expect_length(fields, 1L)
  expect_identical(fields[[1L]]$field_id, "phylo_mu")
  expect_identical(fields[[1L]]$latent_index0, 0L)
  expect_identical(fields[[1L]]$alpha_index0, 0L)
  expect_identical(fit$model$tmb_data$phylo_ou_latent_index, 0L)
  expect_identical(fit$model$tmb_data$phylo_ou_alpha_index, 0L)
})

test_that("phylogenetic OU provider registry allocates one rate per latent field", {
  phylo <- list(
    has = TRUE,
    model = "ou",
    dpars = c("mu", "sigma"),
    provider = list(fields = list(
      phylo_mu = list(
        field_id = "phylo_mu", dpar = "mu", latent_index0 = 0L,
        alpha_parameter = "log_decay_phylo", alpha_index0 = 0L
      ),
      phylo_sigma = list(
        field_id = "phylo_sigma", dpar = "sigma", latent_index0 = 1L,
        alpha_parameter = "log_decay_phylo", alpha_index0 = 1L
      )
    ))
  )
  spec <- list(structured = list(phylo_mu = phylo))
  fields <- drmTMB:::phylo_ou_provider_fields(phylo)
  expect_identical(unname(vapply(fields, `[[`, integer(1L), "alpha_index0")), c(0L, 1L))
  decay <- drmTMB:::split_tmb_decaypars(
    list(log_decay_phylo = log(c(0.4, 1.2))), spec
  )
  expect_equal(unname(decay$phylo), c(0.4, 1.2))
  expect_named(decay$phylo, c("decay_phylo", "decay_phylo:sigma"))

  phylo$provider$fields[[2L]]$alpha_index0 <- 0L
  expect_error(drmTMB:::phylo_ou_provider_fields(phylo), "non-contiguous")
})

test_that("native OU prior evaluates separate alpha slots for two latent fields", {
  skip_if_not_installed("ape")
  set.seed(2026091205)
  tree <- ape::rcoal(4)
  tree$tip.label <- paste0("sp", seq_len(4))
  dat <- data.frame(y = stats::rnorm(20), species = rep(tree$tip.label, each = 5))
  fit <- drmTMB(
    bf(y ~ phylo(1 | species, tree = tree, model = "ou"), sigma ~ 1),
    data = dat, family = gaussian()
  )
  data <- fit$model$tmb_data
  parameters <- fit$model$start
  n_node <- length(parameters$u_phylo)
  # This is deliberately a TMB-level provider test, not public sigma-side OU
  # admission. The second endpoint proves that the native prior consumes a
  # distinct field and alpha index before that grammar is made public.
  data$phylo_mu_value <- cbind(data$phylo_mu_value, rep(0.15, nrow(dat)))
  data$phylo_mu_dpar <- c(0L, 1L)
  data$phylo_ou_latent_index <- c(0L, 1L)
  data$phylo_ou_alpha_index <- c(0L, 1L)
  parameters$u_phylo <- rep(0, 2L * n_node)
  parameters$log_sd_phylo <- log(c(0.25, 0.12))
  parameters$log_decay_phylo <- log(c(0.4, 1.2))
  obj <- TMB::MakeADFun(
    data = data, parameters = parameters, map = fit$model$map,
    random = fit$model$tmb_random_names, DLL = "drmTMB", silent = TRUE
  )
  alpha <- which(names(obj$par) == "log_decay_phylo")
  expect_length(alpha, 2L)
  expect_true(is.finite(obj$fn(obj$par)))
  expect_true(all(is.finite(obj$gr(obj$par))))
  shifted <- obj$par
  shifted[alpha[[2L]]] <- shifted[alpha[[2L]]] + log(1.3)
  expect_false(isTRUE(all.equal(obj$fn(shifted), obj$fn(obj$par))))

  # A registry may be ordered for display rather than latent storage.  The
  # native provider must follow each recorded offset, not its list position.
  permuted_data <- data
  permuted_data$phylo_ou_latent_index <- c(1L, 0L)
  permuted_data$phylo_ou_alpha_index <- c(1L, 0L)
  permuted_obj <- TMB::MakeADFun(
    data = permuted_data, parameters = parameters, map = fit$model$map,
    random = fit$model$tmb_random_names, DLL = "drmTMB", silent = TRUE
  )
  expect_equal(permuted_obj$fn(permuted_obj$par), obj$fn(obj$par), tolerance = 1e-10)
})

test_that("phylogenetic OU admits fixed sigma and direct phylogenetic-SD regressions", {
  skip_if_not_installed("ape")
  set.seed(2026091201)
  tree <- ape::rcoal(6)
  species_levels <- tree$tip.label
  n_each <- 8L
  species <- rep(species_levels, each = n_each)
  temperature_species <- stats::setNames(
    as.numeric(scale(stats::rnorm(length(species_levels)))), species_levels
  )
  unit_covariance <- drmTMB:::drm_phylo_ou_tip_covariance(tree, decay = 0.8)
  unit_field <- stats::setNames(
    as.numeric(t(chol(unit_covariance)) %*% stats::rnorm(length(species_levels))),
    species_levels
  )
  temperature <- temperature_species[species]
  precipitation <- stats::rnorm(length(species))
  gamma <- exp(-1 + 0.25 * temperature)
  sigma <- exp(-1.1 + 0.12 * precipitation)
  dat <- data.frame(
    y = 0.3 + 0.35 * temperature + gamma * unit_field[species] +
      stats::rnorm(length(species), sd = sigma),
    temperature = unname(temperature),
    precipitation,
    species
  )

  fit <- drmTMB(
    bf(
      y ~ temperature + phylo(1 | species, tree = tree, model = "ou"),
      sigma ~ precipitation,
      sd(species, level = "phylogenetic") ~ temperature
    ),
    family = gaussian(),
    data = dat,
    control = drm_control(optimizer = list(eval.max = 1000, iter.max = 1000))
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_true(fit$sdr$pdHess)
  expect_identical(fit$model$structured$phylo_mu$model, "ou")
  expect_equal(fit$model$random_scale$phylo$n_models, 1L)
  expect_true(is.finite(fit$decaypars$phylo[["decay_phylo"]]))
  expect_true(all(is.finite(coef(fit, "sigma"))))
  expect_true(all(is.finite(coef(fit, "sd_phylo(species)"))))

  fit_reml <- drmTMB(
    bf(
      y ~ temperature + phylo(1 | species, tree = tree, model = "ou"),
      sigma ~ precipitation,
      sd(species, level = "phylogenetic") ~ temperature
    ),
    family = gaussian(),
    data = dat,
    REML = TRUE,
    control = drm_control(optimizer = list(eval.max = 1000, iter.max = 1000))
  )
  expect_true(isTRUE(fit_reml$REML))
  expect_true(is.finite(as.numeric(logLik(fit_reml))))
})

test_that("phylogenetic OU direct-SD keeps a no-intercept amplitude identifiable", {
  skip_if_not_installed("ape")
  set.seed(2026091203)
  tree <- ape::rcoal(7)
  species_levels <- tree$tip.label
  species <- rep(species_levels, each = 7L)
  climate_by_species <- stats::setNames(
    seq(-0.7, 0.7, length.out = length(species_levels)), species_levels
  )
  climate <- unname(climate_by_species[species])
  precipitation <- stats::rnorm(length(species))
  correlation <- drmTMB:::drm_phylo_ou_tip_covariance(tree, decay = 0.75)
  field <- as.vector(t(chol(correlation)) %*% stats::rnorm(length(species_levels)))
  gamma <- exp(0.35 * climate)
  y <- 0.2 + gamma * field[match(species, species_levels)] +
    stats::rnorm(length(species), sd = exp(-1 + 0.08 * precipitation))
  fit <- drmTMB(
    bf(
      y ~ phylo(1 | species, tree = tree, model = "ou"),
      sigma ~ precipitation,
      sd(species, level = "phylogenetic") ~ 0 + climate
    ),
    family = gaussian(), data = data.frame(y, climate, precipitation, species),
    control = drm_control(optimizer = list(eval.max = 1000, iter.max = 1000))
  )
  expect_equal(fit$opt$convergence, 0L)
  expect_true(is.finite(as.numeric(logLik(fit))))
  expect_equal(names(coef(fit, "sd_phylo(species)")), "climate")
})

test_that("native OU-tree marginal likelihood matches the independent dense covariance", {
  skip_if_not_installed("ape")
  set.seed(2026091106)
  tree <- ape::rcoal(5)
  tree$tip.label <- paste0("sp", seq_len(5))
  species <- rep(tree$tip.label, each = 5)
  x <- rep(c(-0.5, 0.5), length.out = length(species))
  y <- -0.1 + 0.5 * x + stats::rnorm(length(species), sd = 0.3)
  fit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree, model = "ou"), sigma ~ 1),
    data = data.frame(y, x, species), family = gaussian()
  )
  decay <- exp(unname(fit$tmb_state$opt.par[["log_decay_phylo"]]))
  sd_phylo <- unname(fit$sdpars$mu[["phylo(1 | species)"]])
  sigma <- exp(unname(fit$par$sigma[["(Intercept)"]]))
  tip_correlation <- drmTMB:::drm_phylo_ou_tip_covariance(
    tree, species = species, decay = decay
  )
  observation_correlation <- tip_correlation[
    match(species, rownames(tip_correlation)),
    match(species, colnames(tip_correlation))
  ]
  covariance <- sd_phylo^2 * observation_correlation +
    diag(sigma^2, length(y))
  residual <- y - as.vector(cbind(`(Intercept)` = 1, x = x) %*% fit$par$mu)
  dense_nll <- 0.5 * (
    length(y) * log(2 * pi) +
      as.numeric(determinant(covariance, logarithm = TRUE)$modulus) +
      drop(crossprod(residual, solve(covariance, residual)))
  )

  expect_equal(-as.numeric(logLik(fit)), dense_nll, tolerance = 1e-7)
})

phylo_ou_dense_nll_at <- function(fit, par, tree) {
  parameter_names <- names(par)
  beta <- unname(par[parameter_names == "beta_mu"])
  sigma <- exp(unname(par[match("beta_sigma", parameter_names)]))
  sd_phylo <- exp(unname(par[match("log_sd_phylo", parameter_names)]))
  decay <- exp(unname(par[match("log_decay_phylo", parameter_names)]))
  phylo <- fit$model$structured$phylo_mu
  species <- as.character(fit$data[[phylo$group]])
  tip_correlation <- drmTMB:::drm_phylo_ou_tip_covariance(
    tree, species = species, decay = decay
  )
  observation_correlation <- tip_correlation[
    match(species, rownames(tip_correlation)),
    match(species, colnames(tip_correlation))
  ]
  covariance <- sd_phylo^2 * observation_correlation +
    diag(sigma^2, length(species))
  root <- chol(covariance)
  residual <- fit$model$y - as.vector(fit$model$X$mu %*% beta)
  0.5 * (
    length(species) * log(2 * pi) +
      2 * sum(log(diag(root))) +
      sum(forwardsolve(t(root), residual)^2)
  )
}

# This oracle deliberately integrates the latent field out.  It is therefore
# independent of the sparse all-node Markov representation used by TMB, while
# retaining the fitted, predictor-dependent phylogenetic amplitude exactly as
# the user specifies it.
phylo_ou_direct_sd_dense_nll_at <- function(fit, par, tree) {
  parameter_names <- names(par)
  beta_mu <- unname(par[parameter_names == "beta_mu"])
  beta_sigma <- unname(par[parameter_names == "beta_sigma"])
  beta_sd <- unname(par[parameter_names == "beta_sd_mu"])
  decay <- exp(unname(par[match("log_decay_phylo", parameter_names)]))
  phylo <- fit$model$structured$phylo_mu
  species <- as.character(fit$data[[phylo$group]])
  tip_correlation <- drmTMB:::drm_phylo_ou_tip_covariance(
    tree, species = species, decay = decay
  )
  observation_correlation <- tip_correlation[
    match(species, rownames(tip_correlation)),
    match(species, colnames(tip_correlation))
  ]
  gamma_by_species <- exp(as.vector(fit$model$tmb_data$X_sd_phylo %*% beta_sd))
  gamma <- gamma_by_species[fit$model$random_scale$phylo$observation_sd_row0 + 1L]
  sigma <- exp(as.vector(fit$model$tmb_data$X_sigma %*% beta_sigma))
  covariance <- tcrossprod(gamma) * observation_correlation +
    diag(sigma^2, length(species))
  root <- chol(covariance)
  residual <- fit$model$y - as.vector(fit$model$X$mu %*% beta_mu)
  0.5 * (
    length(species) * log(2 * pi) +
      2 * sum(log(diag(root))) +
      sum(forwardsolve(t(root), residual)^2)
  )
}

test_that("direct phylogenetic-SD OU matches a dense predictor-aware oracle", {
  skip_if_not_installed("ape")
  skip_if_not_installed("numDeriv")
  set.seed(2026091202)
  tree <- ape::rcoal(5)
  species_levels <- tree$tip.label
  species <- rep(species_levels, each = 6L)
  temperature_by_species <- stats::setNames(
    as.numeric(scale(stats::rnorm(length(species_levels)))), species_levels
  )
  temperature <- unname(temperature_by_species[species])
  precipitation <- stats::rnorm(length(species))
  correlation <- drmTMB:::drm_phylo_ou_tip_covariance(tree, decay = 0.65)
  unit_field <- as.vector(t(chol(correlation)) %*%
    stats::rnorm(length(species_levels)))
  gamma <- exp(-0.9 + 0.2 * temperature)
  sigma <- exp(-1.2 + 0.1 * precipitation)
  y <- -0.15 + 0.3 * temperature + gamma * unit_field[match(species, species_levels)] +
    stats::rnorm(length(species), sd = sigma)
  fit <- drmTMB(
    bf(
      y ~ temperature + phylo(1 | species, tree = tree, model = "ou"),
      sigma ~ precipitation,
      sd(species, level = "phylogenetic") ~ temperature
    ),
    family = gaussian(), data = data.frame(y, temperature, precipitation, species),
    control = drm_control(optimizer = list(eval.max = 1000, iter.max = 1000))
  )
  expect_true(isTRUE(fit$sdr$pdHess))
  expect_true(is.na(fit$model$map$log_sd_phylo[[1L]]))

  objective <- function(par) phylo_ou_direct_sd_dense_nll_at(fit, par, tree)
  opt_par <- fit$opt$par
  score <- numDeriv::grad(objective, opt_par, method.args = list(eps = 1e-6))
  hessian <- numDeriv::hessian(objective, opt_par, method.args = list(eps = 1e-4))
  observed_hessian <- solve(fit$sdr$cov.fixed)

  expect_equal(-as.numeric(logLik(fit)), objective(opt_par), tolerance = 1e-6)
  expect_equal(unname(fit$obj$gr(opt_par)), score, tolerance = 2e-5)
  expect_equal(unname(observed_hessian), unname(hessian), tolerance = 3e-4)
})

test_that("OU-tree score and observed Hessian match the dense covariance oracle", {
  skip_if_not_installed("ape")
  skip_if_not_installed("numDeriv")
  set.seed(2026091107)
  tree <- ape::rcoal(15)
  tree$tip.label <- paste0("sp", seq_len(15))
  species <- rep(tree$tip.label, each = 8)
  x <- rep(c(-0.75, -0.25, 0.25, 0.75, 0, 0.5, -0.5, 0.1),
    length.out = length(species)
  )
  truth_correlation <- drmTMB:::drm_phylo_ou_tip_covariance(tree, decay = 0.8)
  phylo_effect <- as.vector(t(chol(truth_correlation)) %*%
    stats::rnorm(length(tree$tip.label))) * 0.8
  y <- 0.15 + 0.45 * x + phylo_effect[match(species, tree$tip.label)] +
    stats::rnorm(length(species), sd = 0.25)
  fit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree, model = "ou"), sigma ~ 1),
    data = data.frame(y, x, species), family = gaussian()
  )
  expect_true(isTRUE(fit$sdr$pdHess))
  objective <- function(par) phylo_ou_dense_nll_at(fit, par, tree)
  opt_par <- fit$opt$par
  score <- numDeriv::grad(objective, opt_par, method.args = list(eps = 1e-6))
  hessian_1 <- numDeriv::hessian(objective, opt_par, method.args = list(eps = 1e-4))
  hessian_2 <- numDeriv::hessian(objective, opt_par, method.args = list(eps = 1e-5))
  observed_hessian <- solve(fit$sdr$cov.fixed)

  expect_equal(unname(fit$obj$gr(opt_par)), score, tolerance = 1e-5)
  expect_equal(hessian_1, hessian_2, tolerance = 1e-4)
  expect_equal(unname(observed_hessian), unname(hessian_1), tolerance = 1e-4)
})

phylo_ou_markov_nll <- function(layout, state, sd, decay,
                                include_root = TRUE,
                                edge_length = layout$edge_length,
                                transition_variance = c("stationary", "wrong")) {
  transition_variance <- match.arg(transition_variance)
  out <- 0
  if (include_root) {
    out <- out - stats::dnorm(state[[layout$root_index0 + 1L]], 0, sd, log = TRUE)
  }
  for (edge_id in seq_along(edge_length)) {
    rho <- exp(-decay * edge_length[[edge_id]])
    variance_factor <- if (identical(transition_variance, "stationary")) {
      1 - rho^2
    } else {
      1 - rho
    }
    parent <- state[[layout$edge_parent_index0[[edge_id]] + 1L]]
    child <- state[[layout$edge_child_index0[[edge_id]] + 1L]]
    out <- out - stats::dnorm(child, rho * parent, sd * sqrt(variance_factor),
      log = TRUE
    )
  }
  out
}

phylo_ou_dense_all_node_nll <- function(layout, state, sd, decay) {
  n_node <- length(state)
  parent <- rep(NA_integer_, n_node)
  edge_length <- numeric(n_node)
  child <- layout$edge_child_index0 + 1L
  parent[child] <- layout$edge_parent_index0 + 1L
  edge_length[child] <- layout$edge_length
  root <- layout$root_index0 + 1L
  depth <- rep(NA_real_, n_node)
  depth[[root]] <- 0
  while (anyNA(depth)) {
    unresolved <- which(is.na(depth))
    progressed <- FALSE
    for (node in unresolved) {
      parent_node <- parent[[node]]
      if (!is.na(parent_node) && !is.na(depth[[parent_node]])) {
        depth[[node]] <- depth[[parent_node]] + edge_length[[node]]
        progressed <- TRUE
      }
    }
    if (!progressed) stop("Invalid OU tree layout for dense oracle.", call. = FALSE)
  }
  ancestors <- lapply(seq_len(n_node), function(node) {
    out <- node
    while (!is.na(parent[[node]])) {
      node <- parent[[node]]
      out <- c(out, node)
    }
    out
  })
  correlation <- matrix(0, n_node, n_node)
  for (i in seq_len(n_node)) for (j in seq_len(n_node)) {
    mrca <- intersect(ancestors[[i]], ancestors[[j]])
    mrca <- mrca[[which.max(depth[mrca])]]
    distance <- depth[[i]] + depth[[j]] - 2 * depth[[mrca]]
    correlation[i, j] <- exp(-decay * distance)
  }
  covariance <- sd^2 * correlation
  factor <- chol(covariance)
  0.5 * (n_node * log(2 * pi) + 2 * sum(log(diag(factor))) +
    sum(forwardsolve(t(factor), state)^2))
}

# Dense conditional oracle for the admitted joint OU surface. It intentionally
# reconstructs the observation density and the two stationary tree priors in R
# from TMB data rather than calling the native sparse evaluator.
phylo_ou_joint_conditional_nll <- function(
    obj, data, phylo, par,
    include_sigma_field = TRUE,
    alpha_index = NULL,
    include_root = TRUE,
    transition_variance = "stationary",
    prior_engine = c("dense", "markov")
) {
  prior_engine <- match.arg(prior_engine)
  p <- obj$env$parList(par)
  n_node <- data$phylo_ou_n_nodes
  fields <- drmTMB:::phylo_ou_provider_fields(phylo)
  layout <- list(
    root_index0 = data$phylo_ou_root_index,
    edge_parent_index0 = data$phylo_ou_edge_parent,
    edge_child_index0 = data$phylo_ou_edge_child,
    edge_length = data$phylo_ou_edge_length
  )
  mu <- as.vector(data$X_mu %*% p$beta_mu) + data$offset_mu
  log_sigma <- as.vector(data$X_sigma %*% p$beta_sigma)
  prior <- 0
  for (field_id in seq_along(fields)) {
    field <- fields[[field_id]]
    state_index <- seq_len(n_node) + field$latent_index0 * n_node
    state <- p$u_phylo[state_index]
    endpoint <- field$latent_index0 + 1L
    contribution <- data$phylo_mu_value[, endpoint] *
      state[data$phylo_mu_node_index + 1L]
    if (data$phylo_mu_dpar[[endpoint]] == 1L) {
      if (include_sigma_field) log_sigma <- log_sigma + contribution
    } else {
      mu <- mu + contribution
    }
    field_alpha <- if (is.null(alpha_index)) field$alpha_index0 else alpha_index[[field_id]]
    field_sd <- exp(p$log_sd_phylo[[field$latent_index0 + 1L]])
    field_decay <- exp(p$log_decay_phylo[[field_alpha + 1L]])
    prior <- prior + if (identical(prior_engine, "dense")) {
      phylo_ou_dense_all_node_nll(layout, state, field_sd, field_decay)
    } else {
      phylo_ou_markov_nll(
        layout = layout, state = state, sd = field_sd, decay = field_decay,
        include_root = include_root, transition_variance = transition_variance
      )
    }
  }
  log_sigma <- drmTMB:::drm_softclamp_log_sd(log_sigma, data)
  observation <- -sum(stats::dnorm(data$y, mean = mu, sd = exp(log_sigma), log = TRUE))
  prior + observation
}

test_that("joint OU conditional objective, score, and Hessian match an independent dense oracle", {
  skip_if_not_installed("ape")
  skip_if_not_installed("numDeriv")
  set.seed(2026091214)
  tree <- ape::rcoal(4)
  tree$tip.label <- paste0("sp", seq_len(4))
  species <- rep(tree$tip.label, each = 4)
  x <- rep(seq(-0.6, 0.6, length.out = 4), times = 4)
  dat <- data.frame(
    y = 0.2 + 0.3 * x + stats::rnorm(length(species), sd = exp(-0.8 + 0.15 * x)),
    x, species
  )
  fit <- suppressWarnings(drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree, model = "ou"),
      sigma ~ x + phylo(1 | species, tree = tree, model = "ou")
    ),
    data = dat, family = gaussian()
  ))
  obj <- TMB::MakeADFun(
    data = fit$model$tmb_data,
    parameters = fit$model$start,
    map = fit$model$map,
    random = NULL,
    DLL = "drmTMB",
    silent = TRUE
  )
  objective <- function(par) phylo_ou_joint_conditional_nll(
    obj, fit$model$tmb_data, fit$model$structured$phylo_mu, par
  )
  par <- obj$par
  score <- numDeriv::grad(objective, par, method.args = list(eps = 1e-6))
  hessian <- numDeriv::hessian(objective, par, method.args = list(eps = 1e-4))
  expect_equal(obj$fn(par), objective(par), tolerance = 1e-8)
  expect_equal(as.numeric(obj$gr(par)), score, tolerance = 2e-5)
  expect_equal(unname(obj$he(par)), unname(hessian), tolerance = 3e-4)

  # The oracle must also cover the configured nonlinear log-sigma clamp,
  # rather than matching native TMB only inside its identity band.
  clamped <- par
  beta_sigma <- grep("^beta_sigma", names(clamped))
  expect_true(length(beta_sigma) >= 1L)
  clamped[beta_sigma[[1L]]] <- 13
  clamped_score <- numDeriv::grad(objective, clamped, method.args = list(eps = 1e-6))
  clamped_hessian <- numDeriv::hessian(objective, clamped, method.args = list(eps = 1e-4))
  expect_equal(obj$fn(clamped), objective(clamped), tolerance = 1e-8)
  expect_equal(as.numeric(obj$gr(clamped)), clamped_score, tolerance = 2e-5)
  expect_equal(unname(obj$he(clamped)), unname(clamped_hessian), tolerance = 3e-4)
})

test_that("joint OU dense oracle rejects the named implementation mutations", {
  skip_if_not_installed("ape")
  set.seed(2026091215)
  tree <- ape::rcoal(4)
  tree$tip.label <- paste0("sp", seq_len(4))
  species <- rep(tree$tip.label, each = 4)
  x <- rep(seq(-0.5, 0.5, length.out = 4), times = 4)
  dat <- data.frame(y = 0.25 + stats::rnorm(length(species)), x, species)
  fit <- suppressWarnings(drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree, model = "ou"),
      sigma ~ x + phylo(1 | species, tree = tree, model = "ou")
    ),
    data = dat, family = gaussian()
  ))
  obj <- TMB::MakeADFun(
    data = fit$model$tmb_data,
    parameters = fit$model$start,
    map = fit$model$map,
    random = NULL,
    DLL = "drmTMB",
    silent = TRUE
  )
  p <- obj$par
  alpha <- which(names(p) == "log_decay_phylo")
  p[alpha[[1L]]] <- log(0.25)
  p[alpha[[2L]]] <- log(1.75)
  u <- which(names(p) == "u_phylo")
  p[u] <- seq(-0.2, 0.2, length.out = length(u))
  observed <- obj$fn(p)
  oracle <- phylo_ou_joint_conditional_nll(
    obj, fit$model$tmb_data, fit$model$structured$phylo_mu, p
  )
  swapped_rate <- phylo_ou_joint_conditional_nll(
    obj, fit$model$tmb_data, fit$model$structured$phylo_mu, p,
    alpha_index = c(1L, 0L)
  )
  missing_root <- phylo_ou_joint_conditional_nll(
    obj, fit$model$tmb_data, fit$model$structured$phylo_mu, p,
    include_root = FALSE, prior_engine = "markov"
  )
  wrong_transition <- phylo_ou_joint_conditional_nll(
    obj, fit$model$tmb_data, fit$model$structured$phylo_mu, p,
    transition_variance = "wrong", prior_engine = "markov"
  )
  missing_sigma <- phylo_ou_joint_conditional_nll(
    obj, fit$model$tmb_data, fit$model$structured$phylo_mu, p,
    include_sigma_field = FALSE
  )
  permuted_phylo <- fit$model$structured$phylo_mu
  permuted_phylo$provider$fields <- rev(permuted_phylo$provider$fields)
  permuted_registry <- phylo_ou_joint_conditional_nll(
    obj, fit$model$tmb_data, permuted_phylo, p
  )
  expect_equal(observed, oracle, tolerance = 1e-8)
  expect_equal(observed, permuted_registry, tolerance = 1e-8)
  expect_false(isTRUE(all.equal(observed, swapped_rate)))
  expect_false(isTRUE(all.equal(observed, missing_root)))
  expect_false(isTRUE(all.equal(observed, wrong_transition)))
  expect_false(isTRUE(all.equal(observed, missing_sigma)))
})

phylo_ou_all_node_correlation <- function(tree, decay) {
  info <- drmTMB:::validate_phylo_tree(tree)
  edge <- tree$edge
  n_node <- info$n_tip + info$n_node
  parent <- integer(n_node)
  parent[edge[, 2L]] <- edge[, 1L]
  ancestor <- lapply(seq_len(n_node), drmTMB:::phylo_node_ancestors,
    parent = parent
  )
  out <- matrix(0, n_node, n_node)
  for (i in seq_len(n_node)) for (j in seq_len(n_node)) {
    mrca_depth <- max(info$node_depth[intersect(ancestor[[i]], ancestor[[j]])])
    distance <- info$node_depth[[i]] + info$node_depth[[j]] - 2 * mrca_depth
    out[i, j] <- exp(-decay * distance)
  }
  out
}

test_that("OU-tree reductions and mutations expose the intended mechanisms", {
  skip_if_not_installed("ape")
  set.seed(2026091108)
  tree <- ape::rcoal(6)
  tree$tip.label <- paste0("sp", seq_len(6))
  layout <- drmTMB:::drm_phylo_ou_augmented_layout(tree)
  decay <- 0.7
  sd <- 0.65
  state <- stats::rnorm(layout$n_re)
  correlation <- phylo_ou_all_node_correlation(tree, decay)
  covariance <- sd^2 * correlation
  root <- chol(covariance)
  dense_nll <- 0.5 * (
    length(state) * log(2 * pi) + 2 * sum(log(diag(root))) +
      sum(forwardsolve(t(root), state)^2)
  )
  correct <- phylo_ou_markov_nll(layout, state, sd, decay)
  missing_root <- phylo_ou_markov_nll(layout, state, sd, decay,
    include_root = FALSE
  )
  wrong_variance <- phylo_ou_markov_nll(layout, state, sd, decay,
    transition_variance = "wrong"
  )
  compressed <- phylo_ou_markov_nll(layout, state, sd, decay,
    edge_length = rep(mean(layout$edge_length), length(layout$edge_length))
  )
  tip_ou <- drmTMB:::drm_phylo_ou_tip_covariance(tree, decay = decay)
  tip_bm <- drmTMB:::drm_phylo_tip_covariance(tree)
  large_decay <- drmTMB:::drm_phylo_ou_tip_covariance(tree, decay = 100)
  small_decay <- drmTMB:::drm_phylo_ou_tip_covariance(tree, decay = 1e-8)
  temporal_kernel <- exp(-decay * abs(outer(seq_len(nrow(tip_ou)),
    seq_len(nrow(tip_ou)), "-"
  )))
  independent_trees <- Matrix::bdiag(tip_ou, tip_ou)
  shared_tree_state <- rbind(cbind(tip_ou, tip_ou), cbind(tip_ou, tip_ou))

  expect_equal(correct, dense_nll, tolerance = 1e-10)
  expect_false(isTRUE(all.equal(missing_root, dense_nll)))
  expect_false(isTRUE(all.equal(wrong_variance, dense_nll)))
  expect_false(isTRUE(all.equal(compressed, dense_nll)))
  expect_false(isTRUE(all.equal(tip_ou, tip_bm)))
  expect_false(isTRUE(all.equal(tip_ou, temporal_kernel)))
  expect_false(isTRUE(all.equal(as.matrix(independent_trees), shared_tree_state)))
  expect_lt(max(large_decay[row(large_decay) != col(large_decay)]), 1e-6)
  expect_equal(unname(small_decay), matrix(1, nrow(small_decay), ncol(small_decay)),
    tolerance = 1e-7
  )
})

test_that("fresh phylogenetic OU draws use the stationary root and every branch", {
  skip_if_not_installed("ape")
  set.seed(2026091109)
  tree <- ape::rcoal(7)
  tree$tip.label <- paste0("sp", seq_len(7))
  layout <- drmTMB:::drm_phylo_ou_augmented_layout(tree)
  phylo_mu <- list(model = "ou", precision = layout)
  sd <- 0.7
  decay <- 0.6

  set.seed(2026091110)
  expected <- numeric(layout$n_re)
  expected[[layout$root_index0 + 1L]] <- stats::rnorm(1L, sd = sd)
  for (edge_id in layout$edge_order) {
    parent <- layout$edge_parent_index0[[edge_id]] + 1L
    child <- layout$edge_child_index0[[edge_id]] + 1L
    rho <- exp(-decay * layout$edge_length[[edge_id]])
    expected[[child]] <- stats::rnorm(
      1L,
      mean = rho * expected[[parent]],
      sd = sd * sqrt(-expm1(-2 * decay * layout$edge_length[[edge_id]]))
    )
  }
  set.seed(2026091110)
  actual <- drmTMB:::drm_phylo_ou_fresh_values(phylo_mu, sd, decay)
  set.seed(2026091110)
  wrong_independent_draw <- stats::rnorm(layout$n_re, sd = sd)

  expect_equal(actual, expected, tolerance = 1e-12)
  expect_false(isTRUE(all.equal(actual, wrong_independent_draw)))
})

phylo_ou_methods_fit <- function(seed = 2026091111) {
  skip_if_not_installed("ape")
  set.seed(seed)
  tree <- ape::rcoal(8)
  tree$tip.label <- paste0("sp", seq_len(8))
  species <- rep(tree$tip.label, each = 6)
  x <- rep(c(-0.75, -0.25, 0.25, 0.75, -0.4, 0.4), length.out = length(species))
  correlation <- drmTMB:::drm_phylo_ou_tip_covariance(tree, decay = 0.75)
  effect <- as.vector(t(chol(correlation)) %*% stats::rnorm(8, sd = 0.65))
  y <- 0.2 + 0.45 * x + effect[match(species, tree$tip.label)] +
    stats::rnorm(length(species), sd = 0.3)
  list(
    fit = drmTMB(
      bf(y ~ x + phylo(1 | species, tree = tree, model = "ou"), sigma ~ 1),
      data = data.frame(y, x, species), family = gaussian()
    ),
    tree = tree
  )
}

test_that("phylogenetic OU exposes a point decay estimate and no decay interval", {
  built <- phylo_ou_methods_fit()
  fit <- built$fit
  targets <- drmTMB:::profile_targets(fit)
  decay <- targets[targets$target_class == "phylogenetic-decay", , drop = FALSE]
  summary_rows <- drmTMB:::drm_summary_direct_parameters(fit)
  diagnostic <- check_drm(fit)

  expect_named(fit$decaypars$phylo, "decay_phylo")
  expect_true(is.finite(unname(fit$decaypars$phylo[["decay_phylo"]])))
  expect_gt(unname(fit$decaypars$phylo[["decay_phylo"]]), 0)
  expect_equal(nrow(decay), 1L)
  expect_match(decay$parm, "^decay:phylo:")
  expect_false(decay$profile_ready)
  expect_identical(decay$profile_note, "phylogenetic_ou_decay_intervals_deferred")
  expect_true(any(summary_rows$component == "phylogenetic-decay"))
  expect_true(any(diagnostic$check == "phylo_ou_decay"))
})

test_that("phylogenetic OU fitted values, residuals, and seeded simulations use OU draws", {
  built <- phylo_ou_methods_fit()
  fit <- built$fit
  fixed_mu <- as.vector(fit$model$X$mu %*% fit$coefficients$mu)
  conditional_mu <- fixed_mu + phylo_mu_contribution(fit, dpar = "mu")
  sigma <- exp(unname(fit$coefficients$sigma[["(Intercept)"]]))

  expect_equal(stats::fitted(fit), conditional_mu, tolerance = 1e-10)
  expect_equal(stats::residuals(fit), fit$model$y - conditional_mu, tolerance = 1e-10)

  set.seed(2026091112)
  expected_conditional <- conditional_mu + stats::rnorm(length(conditional_mu), sd = sigma)
  conditional <- stats::simulate(fit, nsim = 1L, seed = 2026091112, re.form = NA)
  expect_equal(unname(conditional[[1L]]), expected_conditional, tolerance = 1e-10)

  set.seed(2026091113)
  fresh_effect <- drmTMB:::drm_structured_mu_random_effect_draws(fit)$mu
  expected_fresh <- stats::rnorm(length(fixed_mu), mean = fixed_mu + fresh_effect, sd = sigma)
  fresh <- stats::simulate(fit, nsim = 1L, seed = 2026091113)
  expect_equal(unname(fresh[[1L]]), expected_fresh, tolerance = 1e-10)
  expect_false(isTRUE(all.equal(unname(fresh[[1L]]), unname(conditional[[1L]]))))
})

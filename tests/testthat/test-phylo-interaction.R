phylo_interaction_balanced_tree <- function(n_tip = 4L, prefix = "sp") {
  stopifnot(n_tip >= 2L, log2(n_tip) == floor(log2(n_tip)))
  edges <- matrix(integer(), ncol = 2L)
  edge_lengths <- numeric()
  next_node <- n_tip + 1L

  build <- function(tips) {
    if (length(tips) == 1L) {
      return(tips)
    }
    node <- next_node
    next_node <<- next_node + 1L
    mid <- length(tips) / 2L
    left <- build(tips[seq_len(mid)])
    right <- build(tips[seq.int(mid + 1L, length(tips))])
    edges <<- rbind(edges, c(node, left), c(node, right))
    edge_lengths <<- c(edge_lengths, 1, 1)
    node
  }

  build(seq_len(n_tip))
  structure(
    list(
      edge = edges,
      edge.length = edge_lengths,
      tip.label = paste0(prefix, "_", seq_len(n_tip)),
      Nnode = n_tip - 1L
    ),
    class = "phylo"
  )
}

new_phylo_interaction_count_data <- function(
  seed = 2026053101,
  n_plant = 4L,
  n_pollinator = 4L,
  n_each = 8L,
  sd_pair = 0.45,
  sigma_nb2 = 0.35
) {
  set.seed(seed)
  plant_tree <- phylo_interaction_balanced_tree(n_plant, "plant")
  pollinator_tree <- phylo_interaction_balanced_tree(n_pollinator, "poll")
  plant_cov <- drmTMB:::drm_phylo_tip_covariance(plant_tree)
  pollinator_cov <- drmTMB:::drm_phylo_tip_covariance(pollinator_tree)
  pair_cov <- kronecker(pollinator_cov, plant_cov)
  pair_grid <- expand.grid(
    plant = plant_tree$tip.label,
    pollinator = pollinator_tree$tip.label,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  pair_effect <- as.vector(
    t(chol(pair_cov)) %*% stats::rnorm(nrow(pair_grid), sd = sd_pair)
  )
  pair_name <- paste0(pair_grid$plant, ":", pair_grid$pollinator)
  names(pair_effect) <- pair_name

  row_id <- rep(seq_len(nrow(pair_grid)), each = n_each)
  dat <- pair_grid[row_id, , drop = FALSE]
  x <- stats::rnorm(nrow(dat))
  beta_mu <- c(`(Intercept)` = 0.45, x = -0.20)
  eta <- beta_mu[[1L]] +
    beta_mu[[2L]] * x +
    pair_effect[paste0(dat$plant, ":", dat$pollinator)]
  dat$x <- x
  dat$y <- eta + stats::rnorm(nrow(dat), sd = 0.35)
  dat$count <- stats::rpois(nrow(dat), lambda = exp(eta))
  dat$nb2 <- stats::rnbinom(
    nrow(dat),
    size = 1 / sigma_nb2^2,
    mu = exp(eta)
  )

  list(
    data = dat,
    plant_tree = plant_tree,
    pollinator_tree = pollinator_tree,
    beta_mu = beta_mu,
    sd_pair = sd_pair,
    sigma_nb2 = sigma_nb2
  )
}

new_phylo_interaction_sigma_nb2_data <- function(
  seed = 2026072901,
  n_plant = 4L,
  n_pollinator = 4L,
  n_each = 18L,
  sd_pair = 0.60,
  sigma_intercept = -0.20
) {
  set.seed(seed)
  plant_tree <- phylo_interaction_balanced_tree(n_plant, "plant")
  pollinator_tree <- phylo_interaction_balanced_tree(n_pollinator, "poll")
  plant_cov <- drmTMB:::drm_phylo_tip_covariance(plant_tree)
  pollinator_cov <- drmTMB:::drm_phylo_tip_covariance(pollinator_tree)
  pair_cov <- kronecker(pollinator_cov, plant_cov)
  pair_grid <- expand.grid(
    plant = plant_tree$tip.label,
    pollinator = pollinator_tree$tip.label,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  pair_effect <- as.vector(
    t(chol(pair_cov)) %*% stats::rnorm(nrow(pair_grid), sd = sd_pair)
  )
  names(pair_effect) <- paste0(pair_grid$plant, ":", pair_grid$pollinator)
  row_id <- rep(seq_len(nrow(pair_grid)), each = n_each)
  dat <- pair_grid[row_id, , drop = FALSE]
  dat$x <- stats::rnorm(nrow(dat))
  log_sigma <- sigma_intercept + pair_effect[
    paste0(dat$plant, ":", dat$pollinator)
  ]
  dat$nb2 <- stats::rnbinom(
    nrow(dat),
    mu = exp(1.4 + 0.3 * dat$x),
    size = exp(-2 * log_sigma)
  )
  list(
    data = dat,
    plant_tree = plant_tree,
    pollinator_tree = pollinator_tree,
    pair_effect = pair_effect,
    sd_pair = sd_pair
  )
}

new_zi_nbinom2_sigma_phylo_interaction_data <- function(
  seed = 2026073001,
  n_plant = 4L,
  n_pollinator = 4L,
  n_each = 18L,
  sd_pair = 0.60,
  sigma_intercept = -0.20,
  zi_probability = 0.20
) {
  set.seed(seed)
  plant_tree <- phylo_interaction_balanced_tree(n_plant, "plant")
  pollinator_tree <- phylo_interaction_balanced_tree(n_pollinator, "poll")
  plant_cov <- drmTMB:::drm_phylo_tip_covariance(plant_tree)
  pollinator_cov <- drmTMB:::drm_phylo_tip_covariance(pollinator_tree)
  pair_cov <- kronecker(pollinator_cov, plant_cov)
  pair_grid <- expand.grid(
    plant = plant_tree$tip.label,
    pollinator = pollinator_tree$tip.label,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  pair_effect <- as.vector(
    t(chol(pair_cov)) %*% stats::rnorm(nrow(pair_grid), sd = sd_pair)
  )
  names(pair_effect) <- paste0(pair_grid$plant, ":", pair_grid$pollinator)
  row_id <- rep(seq_len(nrow(pair_grid)), each = n_each)
  dat <- pair_grid[row_id, , drop = FALSE]
  dat$x <- as.vector(scale(stats::rnorm(nrow(dat)), scale = FALSE))
  log_sigma <- sigma_intercept + pair_effect[
    paste0(dat$plant, ":", dat$pollinator)
  ]
  structural_zero <- stats::runif(nrow(dat)) < zi_probability
  nb_count <- stats::rnbinom(
    nrow(dat),
    mu = exp(1.4 + 0.3 * dat$x),
    size = exp(-2 * log_sigma)
  )
  dat$count <- ifelse(structural_zero, 0L, nb_count)
  dat$structural_zero <- structural_zero
  list(
    data = dat,
    plant_tree = plant_tree,
    pollinator_tree = pollinator_tree,
    pair_effect = pair_effect,
    sd_pair = sd_pair,
    sigma_intercept = sigma_intercept,
    zi_probability = zi_probability
  )
}

dense_augmented_phylo_precision <- function(tree) {
  n_tip <- length(tree$tip.label)
  n_total <- n_tip + tree$Nnode
  root <- setdiff(tree$edge[, 1L], tree$edge[, 2L])
  stopifnot(length(root) == 1L)
  included <- setdiff(seq_len(n_total), root)
  index <- integer(n_total); index[included] <- seq_along(included)
  Q <- matrix(0, length(included), length(included))
  for (edge_id in seq_len(nrow(tree$edge))) {
    parent <- tree$edge[edge_id, 1L]; child <- tree$edge[edge_id, 2L]
    weight <- 1 / tree$edge.length[edge_id]
    child_index <- index[[child]]
    Q[child_index, child_index] <- Q[child_index, child_index] + weight
    if (parent != root) {
      parent_index <- index[[parent]]
      Q[parent_index, parent_index] <- Q[parent_index, parent_index] + weight
      Q[parent_index, child_index] <- Q[parent_index, child_index] - weight
      Q[child_index, parent_index] <- Q[child_index, parent_index] - weight
    }
  }
  height <- max(ape::node.depth.edgelength(tree)[seq_len(n_tip)])
  list(Q = height * Q, log_det = length(included) * log(height) - sum(log(tree$edge.length)),
       tip_index = index[seq_len(n_tip)])
}

nb2_sigma_phylo_interaction_nll <- function(fit, par, tree1, tree2, observation_data) {
  data <- fit$model$tmb_data
  u <- as.vector(par$u_phylo)
  precision1 <- dense_augmented_phylo_precision(tree1)
  precision2 <- dense_augmented_phylo_precision(tree2)
  Q <- kronecker(precision2$Q, precision1$Q)
  node1 <- precision1$tip_index[match(observation_data$plant, tree1$tip.label)]
  node2 <- precision2$tip_index[match(observation_data$pollinator, tree2$tip.label)]
  observation_node_index <- (node2 - 1L) * nrow(precision1$Q) + node1
  expect_equal(data$phylo_mu_node_index + 1L, unname(observation_node_index))
  eta_mu <- as.vector(data$offset_mu + data$X_mu %*% par$beta_mu)
  log_sigma <- as.vector(data$X_sigma %*% par$beta_sigma) +
    data$phylo_mu_value[, 1L] * u[observation_node_index]
  quadratic <- sum(u * as.vector(Q %*% u))
  n_u <- length(u)
  prior <- .5 * (
    n_u * log(2 * pi) + 2 * n_u * par$log_sd_phylo -
      (nrow(precision2$Q) * precision1$log_det + nrow(precision1$Q) * precision2$log_det) +
      exp(-2 * par$log_sd_phylo) * quadratic
  )
  prior - sum(data$weights * stats::dnbinom(
    data$y, size = exp(-2 * log_sigma), mu = exp(eta_mu), log = TRUE
  ))
}

zi_nbinom2_sigma_phylo_interaction_nll <- function(fit, par, tree1, tree2, observation_data) {
  data <- fit$model$tmb_data
  u <- as.vector(par$u_phylo)
  precision1 <- dense_augmented_phylo_precision(tree1)
  precision2 <- dense_augmented_phylo_precision(tree2)
  Q <- kronecker(precision2$Q, precision1$Q)
  node1 <- precision1$tip_index[match(observation_data$plant, tree1$tip.label)]
  node2 <- precision2$tip_index[match(observation_data$pollinator, tree2$tip.label)]
  observation_node_index <- (node2 - 1L) * nrow(precision1$Q) + node1
  expect_equal(data$phylo_mu_node_index + 1L, unname(observation_node_index))
  eta_mu <- as.vector(data$offset_mu + data$X_mu %*% par$beta_mu)
  eta_zi <- as.vector(data$X_zi %*% par$beta_zi)
  log_sigma <- as.vector(data$X_sigma %*% par$beta_sigma) +
    data$phylo_mu_value[, 1L] * u[observation_node_index]
  log_nb <- stats::dnbinom(
    data$y, size = exp(-2 * log_sigma), mu = exp(eta_mu), log = TRUE
  )
  log_zi <- -log1p(exp(-eta_zi))
  log_one_minus_zi <- -log1p(exp(eta_zi))
  log_mix_zero <- function(a, b) {
    high <- pmax(a, b)
    high + log(exp(a - high) + exp(b - high))
  }
  log_lik <- ifelse(
    data$y == 0,
    log_mix_zero(log_zi, log_one_minus_zi + log_nb),
    log_one_minus_zi + log_nb
  )
  quadratic <- sum(u * as.vector(Q %*% u))
  n_u <- length(u)
  prior <- .5 * (
    n_u * log(2 * pi) + 2 * n_u * par$log_sd_phylo -
      (nrow(precision2$Q) * precision1$log_det + nrow(precision1$Q) * precision2$log_det) +
      exp(-2 * par$log_sd_phylo) * quadratic
  )
  prior - sum(data$weights * log_lik)
}

zi_nbinom2_sigma_iid_nll <- function(fit, par) {
  data <- fit$model$tmb_data
  index <- data$sigma_re_index[, 1L] + 1L
  term <- data$sigma_re_term[index] + 1L
  eta_mu <- as.vector(data$offset_mu + data$X_mu %*% par$beta_mu)
  eta_zi <- as.vector(data$X_zi %*% par$beta_zi)
  log_sigma <- as.vector(data$X_sigma %*% par$beta_sigma) +
    data$sigma_re_value[, 1L] * exp(par$log_sd_sigma[term]) *
    par$u_sigma[index]
  log_nb <- stats::dnbinom(
    data$y, size = exp(-2 * log_sigma), mu = exp(eta_mu), log = TRUE
  )
  log_zi <- -log1p(exp(-eta_zi))
  log_one_minus_zi <- -log1p(exp(eta_zi))
  log_mix_zero <- function(a, b) {
    high <- pmax(a, b)
    high + log(exp(a - high) + exp(b - high))
  }
  log_lik <- ifelse(
    data$y == 0,
    log_mix_zero(log_zi, log_one_minus_zi + log_nb),
    log_one_minus_zi + log_nb
  )
  -sum(data$weights * log_lik) - sum(stats::dnorm(par$u_sigma, log = TRUE))
}

central_gradient <- function(fn, par) {
  vapply(seq_along(par), function(i) {
    step <- 1e-6 * max(1, abs(par[[i]]))
    plus <- minus <- par
    plus[[i]] <- plus[[i]] + step
    minus[[i]] <- minus[[i]] - step
    (fn(plus) - fn(minus)) / (2 * step)
  }, numeric(1L))
}

expect_phylo_interaction_fit <- function(fit, model_type) {
  sd_name <- "phylo_interaction(1 | plant:pollinator)"
  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, model_type)
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$structured$phylo_mu$type, "phylo_interaction")
  expect_equal(fit$model$structured$phylo_mu$group1, "plant")
  expect_equal(fit$model$structured$phylo_mu$group2, "pollinator")
  expect_equal(fit$model$structured$phylo_mu$q, 1L)
  expect_named(fit$sdpars$mu, sd_name)
  expect_gt(unname(fit$sdpars$mu[[sd_name]]), 0)

  pair_re <- ranef(fit, "phylo_interaction_mu")
  expect_equal(pair_re, fit$random_effects$phylo_interaction_mu)
  expect_named(pair_re$terms, sd_name)
  expect_length(pair_re$values, fit$model$structured$phylo_mu$n_re)

  targets <- profile_targets(fit)
  sd_target <- targets[
    targets$parm == paste0("sd:mu:", sd_name),
    ,
    drop = FALSE
  ]
  expect_equal(nrow(sd_target), 1L)
  expect_true(sd_target$profile_ready)
  expect_equal(sd_target$tmb_parameter, "log_sd_phylo")

  fixed_link <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  expect_equal(
    unname(predict(fit, dpar = "mu", type = "link")),
    fixed_link + drmTMB:::phylo_mu_contribution(fit),
    tolerance = 1e-7
  )
}

test_that("Gaussian mu supports a q1 bipartite phylogenetic interaction", {
  sim <- new_phylo_interaction_count_data()
  plant_tree <- sim$plant_tree
  pollinator_tree <- sim$pollinator_tree

  fit <- drmTMB(
    bf(
      y ~ x +
        phylo_interaction(
          1 | plant:pollinator,
          tree1 = plant_tree,
          tree2 = pollinator_tree
        ),
      sigma ~ 1
    ),
    family = gaussian(),
    data = sim$data
  )

  expect_phylo_interaction_fit(fit, "gaussian")
})

test_that("Poisson mu supports a q1 bipartite phylogenetic interaction", {
  sim <- new_phylo_interaction_count_data()
  plant_tree <- sim$plant_tree
  pollinator_tree <- sim$pollinator_tree

  fit <- drmTMB(
    bf(
      count ~ x +
        phylo_interaction(
          1 | plant:pollinator,
          tree1 = plant_tree,
          tree2 = pollinator_tree
        )
    ),
    family = stats::poisson(link = "log"),
    data = sim$data
  )

  expect_phylo_interaction_fit(fit, "poisson")
})

test_that("NB2 mu supports a q1 bipartite phylogenetic interaction", {
  sim <- new_phylo_interaction_count_data()
  plant_tree <- sim$plant_tree
  pollinator_tree <- sim$pollinator_tree

  fit <- drmTMB(
    bf(
      nb2 ~ x +
        phylo_interaction(
          1 | plant:pollinator,
          tree1 = plant_tree,
          tree2 = pollinator_tree
        ),
      sigma ~ 1
    ),
    family = nbinom2(),
    data = sim$data
  )

  expect_phylo_interaction_fit(fit, "nbinom2")
})

test_that("NB2 sigma supports only the point-fit q1 phylo-interaction gate", {
  skip_on_cran()
  sim <- new_phylo_interaction_sigma_nb2_data()
  plant_tree <- sim$plant_tree
  pollinator_tree <- sim$pollinator_tree
  fit <- drmTMB(
    bf(
      nb2 ~ x,
      sigma ~ phylo_interaction(
        1 | plant:pollinator,
        tree1 = plant_tree,
        tree2 = pollinator_tree
      )
    ),
    family = nbinom2(),
    data = sim$data,
    control = drm_control(se = FALSE)
  )

  term <- "phylo_interaction(1 | plant:pollinator)"
  expect_equal(fit$model$structured$phylo_mu$dpars, "sigma")
  expect_false(drmTMB:::has_mu_random_effects(fit))
  expect_true(drmTMB:::has_sigma_random_effects(fit))
  expect_named(fit$sdpars$sigma, term)
  expect_named(ranef(fit, "phylo_interaction_sigma")$terms, term)
  targets <- profile_targets(fit)
  target <- targets[targets$parm == paste0("sd:sigma:", term), , drop = FALSE]
  expect_equal(nrow(target), 1L)
  expect_identical(target$tmb_parameter, "log_sd_phylo")
  expect_identical(target$target_type, "direct")
  expect_identical(target$transformation, "exp")
  expect_true(target$profile_ready)
  expect_identical(target$profile_note, "ready")
  expect_true(target$parm %in% profile_targets(fit, ready_only = TRUE)$parm)
  # The fence that made this route point-fit-only is gone (profile.R); the
  # "not ready for direct profiling" negative control no longer applies. A
  # cheap mock-based check replaces it: the endpoint engine now reaches
  # drm_profile_target_endpoint_confint() instead of short-circuiting to
  # "unsupported", and the mock aborts immediately so this stays fast (no
  # real profile optimization runs here; see the dedicated se = TRUE
  # profile-interval test for a real fit).
  endpoint_called <- FALSE
  testthat::local_mocked_bindings(
    drm_profile_target_endpoint_confint = function(...) {
      endpoint_called <<- TRUE
      stop("endpoint profile must not start", call. = FALSE)
    },
    .package = "drmTMB"
  )
  endpoint <- confint(
    fit, parm = target$parm, method = "profile", profile_engine = "endpoint"
  )
  expect_true(endpoint_called)
  expect_identical(endpoint$conf.status, "profile_failed")
  expect_match(endpoint$profile.message, "endpoint profile must not start")

  expect_error(
    drmTMB(
      bf(
        nb2 ~ x + phylo_interaction(
          1 | plant:pollinator,
          tree1 = plant_tree,
          tree2 = pollinator_tree
        ),
        sigma ~ phylo_interaction(
          1 | plant:pollinator,
          tree1 = plant_tree,
          tree2 = pollinator_tree
        )
      ),
      family = nbinom2(), data = sim$data
    ),
    "cannot be combined with.*mu"
  )
  expect_error(
    drmTMB(
      bf(
        nb2 ~ x,
        sigma ~ phylo_interaction(
          1 + x | plant:pollinator,
          tree1 = plant_tree,
          tree2 = pollinator_tree
        )
      ),
      family = nbinom2(), data = sim$data
    ),
    "intercept-only"
  )
  expect_error(
    drmTMB(
      bf(
        nb2 ~ x,
        sigma ~ (1 | plant) + phylo_interaction(
          1 | plant:pollinator,
          tree1 = plant_tree,
          tree2 = pollinator_tree
        )
      ),
      family = nbinom2(), data = sim$data
    ),
    "cannot be combined with ordinary"
  )
})

test_that("NB2 sigma phylo-interaction computes a finite ordered profile interval", {
  # Happy-path smoke test, not a boundary probe: a single-seed se = TRUE fit
  # of the same structured-sigma phylo-interaction q1 route as the gate test
  # above, checked for a finite, correctly-ordered profile interval plus a
  # Wald cross-check on the same fit. This is not a coverage or recovery
  # claim -- a single seed carries no error bar for that, and R/profile.R
  # documents a low-ML-estimate bias risk for structured-sigma routes in
  # this family of count models.
  skip_on_cran()
  sim <- new_phylo_interaction_sigma_nb2_data()
  plant_tree <- sim$plant_tree
  pollinator_tree <- sim$pollinator_tree
  fit <- drmTMB(
    bf(
      nb2 ~ x,
      sigma ~ phylo_interaction(
        1 | plant:pollinator,
        tree1 = plant_tree,
        tree2 = pollinator_tree
      )
    ),
    family = nbinom2(),
    data = sim$data
  )
  expect_true(fit$sdr$pdHess)

  term <- "phylo_interaction(1 | plant:pollinator)"
  target <- profile_targets(fit)
  target <- target[target$parm == paste0("sd:sigma:", term), , drop = FALSE]
  expect_true(target$profile_ready)

  profile_ci <- stats::confint(
    fit, parm = target$parm, level = 0.70, method = "profile", trace = FALSE, ystep = 0.50
  )
  expect_true(is.finite(profile_ci$lower))
  expect_true(is.finite(profile_ci$upper))
  expect_lt(profile_ci$lower, target$estimate)
  expect_gt(profile_ci$upper, target$estimate)
  expect_identical(profile_ci$conf.status, "profile")

  # Wald cross-check on the same fit: catches a wrong-scale transform or a
  # mislabelled row using an already-computed comparator, not a coverage
  # claim.
  wald_ci <- stats::confint(fit, parm = target$parm, level = 0.70, method = "wald")
  expect_identical(wald_ci$conf.status, "wald")
  expect_true(is.finite(wald_ci$lower))
  expect_true(is.finite(wald_ci$upper))
  expect_lt(profile_ci$lower, wald_ci$upper)
  expect_gt(profile_ci$upper, wald_ci$lower)
})

test_that("zero-inflated NB2 sigma supports only the point-fit q1 phylo-interaction gate", {
  skip_on_cran()
  sim <- new_zi_nbinom2_sigma_phylo_interaction_data()
  plant_tree <- sim$plant_tree
  pollinator_tree <- sim$pollinator_tree
  fit <- drmTMB(
    bf(
      count ~ x,
      sigma ~ phylo_interaction(
        1 | plant:pollinator,
        tree1 = plant_tree,
        tree2 = pollinator_tree
      ),
      zi ~ 1
    ),
    family = nbinom2(), data = sim$data, control = drm_control(se = FALSE)
  )

  term <- "phylo_interaction(1 | plant:pollinator)"
  expect_identical(fit$model$model_type, "zi_nbinom2")
  expect_equal(fit$model$structured$phylo_mu$dpars, "sigma")
  expect_false(drmTMB:::has_mu_random_effects(fit))
  expect_true(drmTMB:::has_sigma_random_effects(fit))
  expect_named(fit$sdpars$sigma, term)
  expect_named(ranef(fit, "phylo_interaction_sigma")$terms, term)
  targets <- profile_targets(fit)
  target <- targets[targets$parm == paste0("sd:sigma:", term), , drop = FALSE]
  expect_equal(nrow(target), 1L)
  expect_identical(target$tmb_parameter, "log_sd_phylo")
  expect_identical(target$target_type, "direct")
  expect_identical(target$transformation, "exp")
  expect_true(target$profile_ready)
  expect_identical(target$profile_note, "ready")
  expect_true(target$parm %in% profile_targets(fit, ready_only = TRUE)$parm)
  # The fence that made this route point-fit-only is gone (profile.R); the
  # "not ready for direct profiling" negative control no longer applies. A
  # cheap mock-based check replaces it: the endpoint engine now reaches
  # drm_profile_target_endpoint_confint() instead of short-circuiting to
  # "unsupported", and the mock aborts immediately so this stays fast (no
  # real profile optimization runs here; see the dedicated se = TRUE
  # profile-interval test for a real fit).
  endpoint_called <- FALSE
  testthat::local_mocked_bindings(
    drm_profile_target_endpoint_confint = function(...) {
      endpoint_called <<- TRUE
      stop("endpoint profile must not start", call. = FALSE)
    },
    .package = "drmTMB"
  )
  endpoint <- confint(fit, parm = target$parm, method = "profile", profile_engine = "endpoint")
  expect_true(endpoint_called)
  expect_identical(endpoint$conf.status, "profile_failed")
  expect_match(endpoint$profile.message, "endpoint profile must not start")

  fixed_mu <- as.vector(fit$model$tmb_data$offset_mu + fit$model$tmb_data$X_mu %*% coef(fit, "mu"))
  fixed_sigma <- as.vector(fit$model$tmb_data$X_sigma %*% coef(fit, "sigma"))
  fixed_zi <- as.vector(fit$model$tmb_data$X_zi %*% coef(fit, "zi"))
  expect_equal(unname(predict(fit, dpar = "mu", type = "link")), fixed_mu, tolerance = 1e-8)
  expect_equal(
    unname(predict(fit, dpar = "sigma", type = "link")),
    fixed_sigma + drmTMB:::phylo_mu_contribution(fit, dpar = "sigma"),
    tolerance = 1e-5
  )
  expect_equal(unname(predict(fit, dpar = "zi", type = "link")), fixed_zi, tolerance = 1e-8)

  expect_error(
    drmTMB(
      bf(count ~ x, sigma ~ phylo_interaction(
        1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree
      ), zi ~ x),
      family = nbinom2(), data = sim$data
    ),
    "Only the exact"
  )
  expect_error(
    drmTMB(
      bf(count ~ x, sigma ~ phylo_interaction(
        1 + x | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree
      ), zi ~ 1),
      family = nbinom2(), data = sim$data
    ),
    "intercept-only"
  )
  expect_error(
    drmTMB(
      bf(count ~ x + phylo_interaction(
        1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree
      ), sigma ~ phylo_interaction(
        1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree
      ), zi ~ 1),
      family = nbinom2(), data = sim$data
    ),
    "implemented only for ordinary NB2 models"
  )
})

test_that("NB2 sigma phylo-interaction q1 matches an independent objective and gradient oracle", {
  sim <- new_phylo_interaction_sigma_nb2_data(n_plant = 4L, n_pollinator = 4L, n_each = 6L)
  plant_tree <- sim$plant_tree
  pollinator_tree <- sim$pollinator_tree
  fit <- drmTMB(
    bf(nb2 ~ x, sigma ~ phylo_interaction(
      1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree
    )),
    family = nbinom2(), data = sim$data, control = drm_control(se = FALSE)
  )
  full_obj <- TMB::MakeADFun(
    data = fit$model$tmb_data, parameters = fit$model$start, map = fit$model$map,
    DLL = "drmTMB", silent = TRUE
  )
  probe <- full_obj$par + seq(-.04, .04, length.out = length(full_obj$par))
  par <- full_obj$env$parList(probe)
  expect_equal(
    full_obj$fn(probe),
    nb2_sigma_phylo_interaction_nll(fit, par, plant_tree, pollinator_tree, sim$data),
    tolerance = 1e-8
  )
  expect_equal(as.numeric(full_obj$gr(probe)), central_gradient(full_obj$fn, probe), tolerance = 4e-5)
  sd_index <- which(names(probe) == "log_sd_phylo")
  expect_length(sd_index, 1L)
  perturbed <- probe
  perturbed[[sd_index]] <- perturbed[[sd_index]] + .25
  expect_gt(abs(full_obj$fn(perturbed) - full_obj$fn(probe)), 1e-5)
})

test_that("zero-inflated NB2 sigma phylo-interaction q1 matches an independent objective and gradient oracle", {
  sim <- new_zi_nbinom2_sigma_phylo_interaction_data(n_each = 6L)
  plant_tree <- sim$plant_tree
  pollinator_tree <- sim$pollinator_tree
  fit <- drmTMB(
    bf(count ~ x, sigma ~ phylo_interaction(
      1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree
    ), zi ~ 1),
    family = nbinom2(), data = sim$data, control = drm_control(se = FALSE)
  )
  full_obj <- TMB::MakeADFun(
    data = fit$model$tmb_data, parameters = fit$model$start, map = fit$model$map,
    DLL = "drmTMB", silent = TRUE
  )
  probe <- full_obj$par + seq(-.04, .04, length.out = length(full_obj$par))
  par <- full_obj$env$parList(probe)
  expect_equal(
    full_obj$fn(probe),
    zi_nbinom2_sigma_phylo_interaction_nll(fit, par, plant_tree, pollinator_tree, sim$data),
    tolerance = 1e-8
  )
  expect_equal(as.numeric(full_obj$gr(probe)), central_gradient(full_obj$fn, probe), tolerance = 4e-5)
  sd_index <- which(names(probe) == "log_sd_phylo")
  expect_length(sd_index, 1L)
  perturbed <- probe
  perturbed[[sd_index]] <- perturbed[[sd_index]] + .25
  expect_gt(abs(full_obj$fn(perturbed) - full_obj$fn(probe)), 1e-5)
})

test_that("zero-inflated NB2 sigma admits only the IID q1 control with a full oracle", {
  skip_on_cran()
  sim <- new_zi_nbinom2_sigma_phylo_interaction_data(n_each = 8L)
  dat <- sim$data
  dat$pair <- factor(paste(dat$plant, dat$pollinator, sep = ":"))
  plant_tree <- sim$plant_tree
  pollinator_tree <- sim$pollinator_tree
  fit <- drmTMB(
    bf(count ~ x, sigma ~ 1 + (1 | pair), zi ~ 1),
    family = nbinom2(), data = dat, control = drm_control(se = FALSE)
  )

  expect_identical(fit$model$model_type, "zi_nbinom2")
  expect_false(isTRUE(fit$model$structured$phylo_mu$has))
  expect_named(fit$sdpars$sigma, "(1 | pair)")
  expect_named(ranef(fit, "sigma")$terms, "(1 | pair)")
  target <- subset(profile_targets(fit), parm == "sd:sigma:(1 | pair)")
  expect_equal(nrow(target), 1L)
  expect_identical(target$tmb_parameter, "log_sd_sigma")
  expect_identical(target$target_type, "direct")
  expect_identical(target$transformation, "exp")
  expect_false(target$profile_ready)
  expect_identical(target$profile_note, "point_fit_only_zi_nbinom2_sigma_q1")
  expect_false(target$parm %in% profile_targets(fit, ready_only = TRUE)$parm)
  expect_error(confint(fit, parm = target$parm, method = "profile"), "not ready for direct profiling")
  endpoint_called <- FALSE
  testthat::local_mocked_bindings(
    drm_profile_target_endpoint_confint = function(...) {
      endpoint_called <<- TRUE
      stop("endpoint profile must not start", call. = FALSE)
    },
    .package = "drmTMB"
  )
  endpoint <- confint(fit, parm = target$parm, method = "profile", profile_engine = "endpoint")
  expect_false(endpoint_called)
  expect_identical(endpoint$conf.status, "profile_failed")

  fixed_sigma <- as.vector(fit$model$tmb_data$X_sigma %*% coef(fit, "sigma"))
  sigma_re <- ranef(fit, "sigma")$terms[["(1 | pair)"]]
  expect_equal(
    unname(predict(fit, dpar = "sigma", type = "link")),
    fixed_sigma + unname(sigma_re[as.character(dat$pair)]),
    tolerance = 1e-5
  )

  full_obj <- TMB::MakeADFun(
    data = fit$model$tmb_data, parameters = fit$model$start, map = fit$model$map,
    DLL = "drmTMB", silent = TRUE
  )
  probe <- full_obj$par + seq(-.04, .04, length.out = length(full_obj$par))
  par <- full_obj$env$parList(probe)
  expect_equal(full_obj$fn(probe), zi_nbinom2_sigma_iid_nll(fit, par), tolerance = 1e-8)
  expect_equal(as.numeric(full_obj$gr(probe)), central_gradient(full_obj$fn, probe), tolerance = 4e-5)
  sd_index <- which(names(probe) == "log_sd_sigma")
  expect_length(sd_index, 1L)
  perturbed <- probe; perturbed[[sd_index]] <- perturbed[[sd_index]] + .25
  expect_gt(abs(full_obj$fn(perturbed) - full_obj$fn(probe)), 1e-5)
  zi_index <- which(names(probe) == "beta_zi")
  expect_length(zi_index, 1L)
  for (zi_eta in c(-12, 12)) {
    zi_probe <- probe
    zi_probe[[zi_index]] <- zi_eta
    zi_par <- full_obj$env$parList(zi_probe)
    expect_true(is.finite(full_obj$fn(zi_probe)))
    expect_equal(full_obj$fn(zi_probe), zi_nbinom2_sigma_iid_nll(fit, zi_par), tolerance = 1e-8)
  }
  near_zero_sd <- probe
  near_zero_sd[[sd_index]] <- -12
  near_zero_sd_par <- full_obj$env$parList(near_zero_sd)
  expect_equal(full_obj$fn(near_zero_sd), zi_nbinom2_sigma_iid_nll(fit, near_zero_sd_par), tolerance = 1e-8)

  expect_error(
    drmTMB(bf(count ~ x, sigma ~ x + (1 | pair), zi ~ 1), family = nbinom2(), data = dat),
    "Only the exact zero-inflated NB2"
  )
  expect_error(
    drmTMB(bf(count ~ x, sigma ~ 1 + (1 + x | pair), zi ~ 1), family = nbinom2(), data = dat),
    "Only the exact zero-inflated NB2"
  )
  expect_error(
    drmTMB(bf(count ~ x + (1 | pair), sigma ~ 1 + (1 | pair), zi ~ 1), family = nbinom2(), data = dat),
    "implemented only for ordinary NB2 models"
  )
  expect_error(
    drmTMB(bf(count ~ x, sigma ~ 1 + (1 | pair), zi ~ x), family = nbinom2(), data = dat),
    "Only the exact zero-inflated NB2"
  )
  expect_error(
    drmTMB(bf(count ~ x, sigma ~ (1 | pair) + phylo_interaction(
      1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree
    ), zi ~ 1), family = nbinom2(), data = dat),
    "cannot be combined with ordinary"
  )
})

test_that("phylo_interaction uses sparse Kronecker augmented precision", {
  sim <- new_phylo_interaction_count_data(n_each = 2L)
  plant_tree <- sim$plant_tree
  pollinator_tree <- sim$pollinator_tree
  parsed <- drm_formula(
    count ~ x +
      phylo_interaction(
        1 | plant:pollinator,
        tree1 = plant_tree,
        tree2 = pollinator_tree
      )
  )
  term <- parsed$entries[[1L]]$structured[[1L]]
  built <- drmTMB:::build_structured_mu_structure(
    term,
    sim$data,
    environment()
  )

  n1 <- length(sim$plant_tree$tip.label) + sim$plant_tree$Nnode - 1L
  n2 <- length(sim$pollinator_tree$tip.label) + sim$pollinator_tree$Nnode - 1L
  expect_equal(built$n_re, n1 * n2)
  expect_s4_class(built$precision$precision, "sparseMatrix")
  expect_equal(length(built$observation_node_index), nrow(sim$data))
  expect_true(all(grepl(":", built$node_labels, fixed = TRUE)))
})

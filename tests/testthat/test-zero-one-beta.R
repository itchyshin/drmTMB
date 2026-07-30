new_zero_one_beta_data <- function(n = 1600, seed = 20260620) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n),
    w = stats::rnorm(n),
    v = stats::rnorm(n)
  )
  beta_mu <- c(`(Intercept)` = -0.20, x = 0.65)
  beta_sigma <- c(`(Intercept)` = -0.85, z = 0.22)
  beta_zoi <- c(`(Intercept)` = -1.00, w = 0.45)
  beta_coi <- c(`(Intercept)` = 0.15, v = -0.55)
  mu <- stats::plogis(beta_mu[[1L]] + beta_mu[[2L]] * dat$x)
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  zoi <- stats::plogis(beta_zoi[[1L]] + beta_zoi[[2L]] * dat$w)
  coi <- stats::plogis(beta_coi[[1L]] + beta_coi[[2L]] * dat$v)
  y <- stats::rbeta(n, shape1 = mu / sigma^2, shape2 = (1 - mu) / sigma^2)
  boundary <- stats::runif(n) < zoi
  y[boundary] <- as.numeric(stats::runif(sum(boundary)) < coi[boundary])
  dat$prop <- y
  list(
    data = dat,
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    beta_zoi = beta_zoi,
    beta_coi = beta_coi
  )
}

dzoibeta_drm <- function(y, mu, sigma, zoi, coi, log = FALSE) {
  phi <- 1 / sigma^2
  out <- numeric(length(y))
  is_zero <- y == 0
  is_one <- y == 1
  is_interior <- y > 0 & y < 1
  out[is_zero] <- log(zoi[is_zero]) + log1p(-coi[is_zero])
  out[is_one] <- log(zoi[is_one]) + log(coi[is_one])
  out[is_interior] <- log1p(-zoi[is_interior]) +
    stats::dbeta(
      y[is_interior],
      shape1 = mu[is_interior] * phi[is_interior],
      shape2 = (1 - mu[is_interior]) * phi[is_interior],
      log = TRUE
    )
  if (isTRUE(log)) out else exp(out)
}

new_zero_one_beta_phylo_data <- function(seed = 2026072901L, n_tip = 32L, n_each = 30L) {
  set.seed(seed)
  tree <- ape::stree(n_tip, type = "balanced")
  tree$edge.length <- rep(1, nrow(tree$edge)); tree$tip.label <- paste0("sp", seq_len(n_tip))
  V <- drmTMB:::drm_phylo_tip_covariance(tree)
  u <- as.numeric(t(chol(V)) %*% stats::rnorm(n_tip, sd = .55)); names(u) <- tree$tip.label
  data <- data.frame(species = rep(tree$tip.label, each = n_each), x = stats::rnorm(n_tip * n_each))
  mu <- stats::plogis(-.10 + .35 * data$x + u[data$species])
  boundary <- stats::rbinom(nrow(data), 1, .12)
  data$y <- ifelse(boundary == 1, stats::rbinom(nrow(data), 1, .45), stats::rbeta(nrow(data), mu / .45^2, (1 - mu) / .45^2))
  list(data = data, tree = tree)
}

new_zero_one_beta_animal_data <- function(seed = 2026073001L, n_group = 32L, n_each = 30L) {
  set.seed(seed)
  labels <- paste0("sp", seq_len(n_group))
  Q <- diag(2, n_group)
  Q[cbind(seq_len(n_group - 1L), seq.int(2L, n_group))] <- -.5
  Q[cbind(seq.int(2L, n_group), seq_len(n_group - 1L))] <- -.5
  rownames(Q) <- colnames(Q) <- rev(labels)
  u <- as.numeric(t(chol(solve(Q))) %*% stats::rnorm(n_group, sd = .55)); names(u) <- labels
  data <- data.frame(species = rep(labels, each = n_each), x = stats::rnorm(n_group * n_each))
  data$x <- data$x - ave(data$x, data$species, FUN = mean); data$x <- data$x / stats::sd(data$x)
  mu <- stats::plogis(-.10 + .35 * data$x + u[data$species])
  boundary <- stats::rbinom(nrow(data), 1, .12)
  data$y <- ifelse(boundary == 1, stats::rbinom(nrow(data), 1, .45), stats::rbeta(nrow(data), mu / .45^2, (1 - mu) / .45^2))
  list(data = data, Ainv = Q)
}

new_zero_one_beta_relmat_data <- function(seed = 2026073101L, n_group = 32L, n_each = 30L) {
  set.seed(seed)
  labels <- paste0("sp", seq_len(n_group))
  Q <- diag(2, n_group)
  Q[cbind(seq_len(n_group - 1L), seq.int(2L, n_group))] <- -.5
  Q[cbind(seq.int(2L, n_group), seq_len(n_group - 1L))] <- -.5
  rownames(Q) <- colnames(Q) <- rev(labels)
  K <- solve(Q)
  u <- as.numeric(t(chol(K)) %*% stats::rnorm(n_group, sd = .55)); names(u) <- rownames(K)
  data <- data.frame(species = rep(labels, each = n_each), x = stats::rnorm(n_group * n_each))
  data$x <- data$x - ave(data$x, data$species, FUN = mean); data$x <- data$x / stats::sd(data$x)
  mu <- stats::plogis(-.10 + .35 * data$x + u[data$species])
  boundary <- stats::rbinom(nrow(data), 1, .12)
  data$y <- ifelse(boundary == 1, stats::rbinom(nrow(data), 1, .45), stats::rbeta(nrow(data), mu / .45^2, (1 - mu) / .45^2))
  list(data = data, K = K)
}

new_zero_one_beta_spatial_data <- function(seed = 2026073201L, n_group = 24L, n_each = 35L) {
  set.seed(seed)
  labels <- paste0("site", seq_len(n_group))
  coords <- cbind(seq_len(n_group), (seq_len(n_group) %% 5L) / 3)
  rownames(coords) <- rev(labels)
  precision <- dense_zoib_spatial_precision(coords, labels)
  u <- as.numeric(t(chol(solve(precision$Q))) %*% stats::rnorm(n_group, sd = .55)); names(u) <- labels
  data <- data.frame(site = rep(labels, each = n_each), x = stats::rnorm(n_group * n_each))
  data$x <- data$x - ave(data$x, data$site, FUN = mean); data$x <- data$x / stats::sd(data$x)
  mu <- stats::plogis(-.10 + .35 * data$x + u[data$site])
  boundary <- stats::rbinom(nrow(data), 1, .12)
  data$y <- ifelse(boundary == 1, stats::rbinom(nrow(data), 1, .45), stats::rbeta(nrow(data), mu / .45^2, (1 - mu) / .45^2))
  list(data = data, coords = coords)
}

new_zero_one_beta_phylo_interaction_data <- function(seed = 2026073301L, n_each = 30L) {
  set.seed(seed)
  plant_tree <- ape::stree(4L, type = "balanced"); plant_tree$edge.length <- rep(1, nrow(plant_tree$edge)); plant_tree$tip.label <- paste0("plant", 1:4)
  pollinator_tree <- ape::stree(4L, type = "balanced"); pollinator_tree$edge.length <- rep(1, nrow(pollinator_tree$edge)); pollinator_tree$tip.label <- paste0("poll", 1:4)
  V <- kronecker(drmTMB:::drm_phylo_tip_covariance(pollinator_tree), drmTMB:::drm_phylo_tip_covariance(plant_tree))
  grid <- expand.grid(plant = plant_tree$tip.label, pollinator = pollinator_tree$tip.label, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  u <- as.numeric(t(chol(V)) %*% stats::rnorm(nrow(grid), sd = .55)); names(u) <- paste0(grid$plant, ":", grid$pollinator)
  data <- grid[rep(seq_len(nrow(grid)), each = n_each), , drop = FALSE]; data$x <- stats::rnorm(nrow(data)); data$x <- data$x - ave(data$x, interaction(data$plant, data$pollinator), FUN = mean); data$x <- data$x / stats::sd(data$x)
  mu <- stats::plogis(-.10 + .35 * data$x + u[paste0(data$plant, ":", data$pollinator)]); boundary <- stats::rbinom(nrow(data), 1, .12)
  data$y <- ifelse(boundary == 1, stats::rbinom(nrow(data), 1, .45), stats::rbeta(nrow(data), mu / .45^2, (1 - mu) / .45^2))
  list(data = data, plant_tree = plant_tree, pollinator_tree = pollinator_tree)
}

new_zero_one_beta_sigma_random_intercept_data <- function(
  seed = 2026073401L,
  n_id = 12L,
  n_each = 24L,
  sd_sigma = 0.45
) {
  set.seed(seed)
  id <- factor(rep(paste0("id", seq_len(n_id)), each = n_each))
  x <- stats::rnorm(length(id))
  u_sigma <- stats::rnorm(n_id)
  names(u_sigma) <- levels(id)
  mu <- stats::plogis(-0.15 + 0.40 * x)
  sigma <- exp(-1.05 + sd_sigma * u_sigma[as.character(id)])
  zoi <- stats::plogis(-2.0)
  coi <- stats::plogis(0.15)
  boundary <- stats::rbinom(length(id), 1L, zoi)
  y <- stats::rbeta(
    length(id),
    shape1 = mu / sigma^2,
    shape2 = (1 - mu) / sigma^2
  )
  y[boundary == 1L] <- stats::rbinom(sum(boundary == 1L), 1L, coi)
  list(
    data = data.frame(
      y = y, x = x, id = id,
      id2 = factor(rep(paste0("id2", seq_len(n_id)), each = n_each))
    ),
    truth = list(sd_sigma = sd_sigma, u_sigma = u_sigma)
  )
}

new_zero_one_beta_zoi_random_intercept_data <- function(
  seed = 2026073501L,
  n_id = 32L,
  n_each = 50L,
  sd_zoi = 0.45
) {
  set.seed(seed)
  id <- factor(rep(paste0("id", seq_len(n_id)), each = n_each))
  x <- stats::rnorm(length(id))
  u_zoi <- stats::rnorm(n_id)
  names(u_zoi) <- levels(id)
  mu <- stats::plogis(-0.15 + 0.35 * x)
  sigma <- exp(-1.0)
  zoi <- stats::plogis(-1.15 + sd_zoi * u_zoi[as.character(id)])
  coi <- stats::plogis(0.1)
  boundary <- stats::rbinom(length(id), 1L, zoi)
  y <- stats::rbeta(length(id), mu / sigma^2, (1 - mu) / sigma^2)
  y[boundary == 1L] <- stats::rbinom(sum(boundary), 1L, coi)
  list(
    data = data.frame(y = y, x = x, id = id, id2 = factor(rep(seq_len(n_id), each = n_each))),
    truth = list(sd_zoi = sd_zoi, u_zoi = u_zoi)
  )
}

dense_zoib_phylo_precision <- function(tree) {
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
  list(
    Q = height * Q,
    log_det = length(included) * log(height) - sum(log(tree$edge.length)),
    tip_index = index[seq_len(n_tip)]
  )
}

zoib_phylo_nll <- function(fit, par, tree, species) {
  d <- fit$model$tmb_data; u <- as.vector(par$u_phylo)
  precision <- dense_zoib_phylo_precision(tree)
  observation_node_index <- precision$tip_index[match(species, tree$tip.label)]
  expect_equal(d$phylo_mu_node_index + 1L, unname(observation_node_index))
  eta <- as.vector(d$X_mu %*% par$beta_mu) + d$phylo_mu_value[, 1] * u[observation_node_index]
  mu <- stats::plogis(eta); sigma <- exp(as.vector(d$X_sigma %*% par$beta_sigma))
  zoi <- stats::plogis(as.vector(d$X_zi %*% par$beta_zoi)); coi <- stats::plogis(as.vector(d$X_nu %*% par$beta_coi))
  prior <- .5 * (length(u) * log(2*pi) + 2 * length(u) * par$log_sd_phylo - precision$log_det + exp(-2 * par$log_sd_phylo) * sum(u * as.vector(precision$Q %*% u)))
  prior - sum(d$weights * dzoibeta_drm(d$y, mu, sigma, zoi, coi, log = TRUE))
}

zoib_sigma_phylo_nll <- function(fit, par, tree, species) {
  d <- fit$model$tmb_data; u <- as.vector(par$u_phylo)
  precision <- dense_zoib_phylo_precision(tree)
  observation_node_index <- precision$tip_index[match(species, tree$tip.label)]
  expect_equal(d$phylo_mu_node_index + 1L, unname(observation_node_index))
  eta_mu <- as.vector(d$X_mu %*% par$beta_mu)
  log_sigma <- as.vector(d$X_sigma %*% par$beta_sigma) + d$phylo_mu_value[, 1] * u[observation_node_index]
  mu <- 1e-12 + (1 - 2e-12) * stats::plogis(eta_mu)
  prior <- .5 * (length(u) * log(2 * pi) + 2 * length(u) * par$log_sd_phylo - precision$log_det + exp(-2 * par$log_sd_phylo) * sum(u * as.vector(precision$Q %*% u)))
  prior - sum(d$weights * dzoibeta_drm(d$y, mu, exp(log_sigma), stats::plogis(as.vector(d$X_zi %*% par$beta_zoi)), stats::plogis(as.vector(d$X_nu %*% par$beta_coi)), log = TRUE))
}

zoib_phylo_central_gradient <- function(fn, par) {
  vapply(seq_along(par), function(i) {
    step <- 1e-6 * max(1, abs(par[[i]]))
    plus <- minus <- par
    plus[[i]] <- plus[[i]] + step
    minus[[i]] <- minus[[i]] - step
    (fn(plus) - fn(minus)) / (2 * step)
  }, numeric(1L))
}

zoib_animal_nll <- function(fit, par, Ainv, species) {
  d <- fit$model$tmb_data; u <- as.vector(par$u_phylo)
  expected_node_index <- match(species, rownames(Ainv))
  expect_equal(d$phylo_mu_node_index + 1L, unname(expected_node_index))
  eta <- as.vector(d$X_mu %*% par$beta_mu) + d$phylo_mu_value[, 1] * u[expected_node_index]
  mu <- stats::plogis(eta); sigma <- exp(as.vector(d$X_sigma %*% par$beta_sigma))
  zoi <- stats::plogis(as.vector(d$X_zi %*% par$beta_zoi)); coi <- stats::plogis(as.vector(d$X_nu %*% par$beta_coi))
  prior <- .5 * (length(u) * log(2 * pi) + 2 * length(u) * par$log_sd_phylo -
    as.numeric(determinant(Ainv, logarithm = TRUE)$modulus) +
    exp(-2 * par$log_sd_phylo) * sum(u * as.vector(Ainv %*% u)))
  prior - sum(d$weights * dzoibeta_drm(d$y, mu, sigma, zoi, coi, log = TRUE))
}

zoib_relmat_nll <- function(fit, par, K, species) {
  d <- fit$model$tmb_data; u <- as.vector(par$u_phylo)
  Q <- solve(K)
  expected_node_index <- match(species, rownames(K))
  expect_equal(d$phylo_mu_node_index + 1L, unname(expected_node_index))
  eta <- as.vector(d$X_mu %*% par$beta_mu) + d$phylo_mu_value[, 1] * u[expected_node_index]
  mu <- stats::plogis(eta); sigma <- exp(as.vector(d$X_sigma %*% par$beta_sigma))
  zoi <- stats::plogis(as.vector(d$X_zi %*% par$beta_zoi)); coi <- stats::plogis(as.vector(d$X_nu %*% par$beta_coi))
  prior <- .5 * (length(u) * log(2 * pi) + 2 * length(u) * par$log_sd_phylo +
    as.numeric(determinant(K, logarithm = TRUE)$modulus) +
    exp(-2 * par$log_sd_phylo) * sum(u * as.vector(Q %*% u)))
  prior - sum(d$weights * dzoibeta_drm(d$y, mu, sigma, zoi, coi, log = TRUE))
}

dense_zoib_spatial_precision <- function(coords, site_levels, jitter = 1e-6) {
  coords <- as.matrix(coords)[site_levels, seq_len(2L), drop = FALSE]
  distances <- as.matrix(stats::dist(coords))
  positive <- distances[distances > 0]
  range <- stats::median(positive)
  if (!is.finite(range) || range <= 0) range <- max(positive)
  K <- exp(-distances / range); diag(K) <- diag(K) + jitter
  chol_K <- chol(K)
  list(Q = chol2inv(chol_K), log_det_Q = -2 * sum(log(diag(chol_K))), levels = site_levels)
}

zoib_spatial_nll <- function(fit, par, coords, site) {
  d <- fit$model$tmb_data; u <- as.vector(par$u_phylo)
  precision <- dense_zoib_spatial_precision(coords, unique(as.character(site)))
  expected_node_index <- match(site, precision$levels)
  expect_equal(d$phylo_mu_node_index + 1L, unname(expected_node_index))
  eta <- as.vector(d$X_mu %*% par$beta_mu) + d$phylo_mu_value[, 1] * u[expected_node_index]
  mu <- stats::plogis(eta); sigma <- exp(as.vector(d$X_sigma %*% par$beta_sigma))
  zoi <- stats::plogis(as.vector(d$X_zi %*% par$beta_zoi)); coi <- stats::plogis(as.vector(d$X_nu %*% par$beta_coi))
  prior <- .5 * (length(u) * log(2 * pi) + 2 * length(u) * par$log_sd_phylo - precision$log_det_Q + exp(-2 * par$log_sd_phylo) * sum(u * as.vector(precision$Q %*% u)))
  prior - sum(d$weights * dzoibeta_drm(d$y, mu, sigma, zoi, coi, log = TRUE))
}

zoib_phylo_interaction_nll <- function(fit, par, tree1, tree2, data_frame) {
  d <- fit$model$tmb_data; u <- as.vector(par$u_phylo)
  p1 <- dense_zoib_phylo_precision(tree1); p2 <- dense_zoib_phylo_precision(tree2)
  Q <- kronecker(p2$Q, p1$Q)
  node1 <- p1$tip_index[match(data_frame$plant, tree1$tip.label)]
  node2 <- p2$tip_index[match(data_frame$pollinator, tree2$tip.label)]
  index <- (node2 - 1L) * nrow(p1$Q) + node1
  expect_equal(d$phylo_mu_node_index + 1L, unname(index))
  eta <- as.vector(d$X_mu %*% par$beta_mu) + d$phylo_mu_value[, 1] * u[index]
  mu <- stats::plogis(eta); sigma <- exp(as.vector(d$X_sigma %*% par$beta_sigma)); zoi <- stats::plogis(as.vector(d$X_zi %*% par$beta_zoi)); coi <- stats::plogis(as.vector(d$X_nu %*% par$beta_coi))
  prior <- .5 * (length(u) * log(2*pi) + 2 * length(u) * par$log_sd_phylo - (nrow(p2$Q) * p1$log_det + nrow(p1$Q) * p2$log_det) + exp(-2 * par$log_sd_phylo) * sum(u * as.vector(Q %*% u)))
  prior - sum(d$weights * dzoibeta_drm(d$y, mu, sigma, zoi, coi, log = TRUE))
}

zoib_sigma_random_intercept_nll <- function(fit, par) {
  d <- fit$model$tmb_data
  u_sigma <- as.vector(par$u_sigma)
  index <- d$sigma_re_index[, 1L] + 1L
  term <- d$sigma_re_term[index] + 1L
  expect_equal(length(u_sigma), length(unique(index)))
  expect_equal(unique(term), 1L)
  eta_mu <- as.vector(d$X_mu %*% par$beta_mu)
  log_sigma <- as.vector(d$X_sigma %*% par$beta_sigma) +
    d$sigma_re_value[, 1L] * exp(par$log_sd_sigma[term]) * u_sigma[index]
  mu <- stats::plogis(eta_mu)
  sigma <- exp(log_sigma)
  zoi <- stats::plogis(as.vector(d$X_zi %*% par$beta_zoi))
  coi <- stats::plogis(as.vector(d$X_nu %*% par$beta_coi))
  -sum(stats::dnorm(u_sigma, log = TRUE)) -
    sum(d$weights * dzoibeta_drm(d$y, mu, sigma, zoi, coi, log = TRUE))
}

zoib_zoi_random_intercept_nll <- function(fit, par) {
  d <- fit$model$tmb_data
  u_zoi <- as.vector(par$u_zoi)
  index <- d$zoi_re_index[, 1L] + 1L
  term <- d$zoi_re_term[index] + 1L
  eta_mu <- as.vector(d$X_mu %*% par$beta_mu)
  log_sigma <- as.vector(d$X_sigma %*% par$beta_sigma)
  eta_zoi <- as.vector(d$X_zi %*% par$beta_zoi) +
    d$zoi_re_value[, 1L] * exp(par$log_sd_zoi[term]) * u_zoi[index]
  eta_coi <- as.vector(d$X_nu %*% par$beta_coi)
  mu <- 1e-12 + (1 - 2e-12) * stats::plogis(eta_mu)
  sigma <- exp(log_sigma)
  -sum(stats::dnorm(u_zoi, log = TRUE)) -
    sum(d$weights * dzoibeta_drm(
      d$y, mu, sigma, stats::plogis(eta_zoi), stats::plogis(eta_coi), log = TRUE
    ))
}

test_that("zero-one-beta admits the exact phylo q1 mu gate", {
  sim <- new_zero_one_beta_phylo_data(); tree <- sim$tree
  fit <- drmTMB(bf(y ~ x + phylo(1 | species, tree = tree)), family = zero_one_beta(), data = sim$data, control = drm_control(se = FALSE))
  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$model$structured$phylo_mu$dpars, "mu")
  expect_named(fit$sdpars$mu, "phylo(1 | species)")
  expect_true(all(is.finite(predict(fit, dpar = "mu", type = "link"))))
  target <- profile_targets(fit)
  target <- target[target$parm == "sd:mu:phylo(1 | species)", , drop = FALSE]
  expect_identical(target$profile_ready, FALSE)
  expect_identical(target$profile_note, "point_fit_only_zero_one_beta_phylo_q1")
  expect_false(target$parm %in% profile_targets(fit, ready_only = TRUE)$parm)
  expect_error(
    confint(fit, parm = target$parm, method = "profile"),
    "not ready for direct profiling"
  )
  expect_error(
    profile(fit, parm = target$parm),
    "not ready for direct profiling"
  )
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
  expect_false(endpoint_called)
  expect_identical(endpoint$conf.status, "profile_failed")
  expect_match(endpoint$profile.message, "endpoint engine unsupported")
  expect_error(drmTMB(bf(y ~ x + phylo(1 + x | species, tree = tree)), family = zero_one_beta(), data = sim$data), "only one unlabelled q1")
  coords <- matrix(0, 32, 2)
  expect_error(drmTMB(bf(y ~ x + spatial(1 + x | species, coords = coords)), family = zero_one_beta(), data = sim$data), "only one unlabelled q1")
  Q <- diag(32); rownames(Q) <- colnames(Q) <- tree$tip.label
  interaction_data <- transform(sim$data, plant = species, pollinator = species)
  expect_error(drmTMB(bf(y ~ x + animal(1 + x | species, Ainv = Q)), family = zero_one_beta(), data = sim$data), "only one unlabelled q1")
  expect_error(drmTMB(bf(y ~ x + relmat(1 + x | species, K = Q)), family = zero_one_beta(), data = sim$data), "only one unlabelled q1")
  expect_error(drmTMB(bf(y ~ x + phylo_interaction(1 + x | plant:pollinator, tree1 = tree, tree2 = tree)), family = zero_one_beta(), data = interaction_data), "intercept-only")
  expect_error(drmTMB(bf(y ~ x, zoi ~ phylo(1 | species, tree = tree)), family = zero_one_beta(), data = sim$data), "Structured-effect syntax")
  expect_error(drmTMB(bf(y ~ x, coi ~ phylo(1 | species, tree = tree)), family = zero_one_beta(), data = sim$data), "Structured-effect syntax")
})

test_that("zero-one-beta admits only the exact phylo q1 sigma gate", {
  set.seed(2026074001L)
  tree <- ape::stree(16L, type = "balanced"); tree$edge.length <- rep(1, nrow(tree$edge)); tree$tip.label <- paste0("sp", seq_len(16L))
  precision <- dense_zoib_phylo_precision(tree); u <- as.numeric(t(chol(solve(precision$Q))) %*% rnorm(nrow(precision$Q), sd = .45)); names(u) <- tree$tip.label
  species <- rep(tree$tip.label, each = 40L); x <- rnorm(length(species)); mu <- plogis(-.15 + .35 * x); sigma <- exp(-1 + u[species]); zoi <- plogis(-1.1); coi <- plogis(.1)
  boundary <- rbinom(length(x), 1L, zoi); y <- rbeta(length(x), mu / sigma^2, (1 - mu) / sigma^2); y[boundary == 1L] <- rbinom(sum(boundary), 1L, coi)
  d <- data.frame(y, x, species)
  fit <- drmTMB(bf(y ~ x, sigma ~ phylo(1 | species, tree = tree), zoi ~ 1, coi ~ 1), family = zero_one_beta(), data = d, control = drm_control(se = FALSE))
  expect_equal(fit$opt$convergence, 0); expect_named(fit$sdpars$sigma, "phylo(1 | species)")
  target <- subset(profile_targets(fit), parm == "sd:sigma:phylo(1 | species)")
  expect_identical(target$tmb_parameter, "log_sd_phylo"); expect_identical(target$target_type, "direct")
  expect_false(target$profile_ready); expect_identical(target$profile_note, "point_fit_only_zero_one_beta_phylo_q1")
  expect_false(target$parm %in% profile_targets(fit, ready_only = TRUE)$parm)
  expect_error(confint(fit, parm = target$parm, method = "profile"), "not ready for direct profiling")
  expect_error(profile(fit, parm = target$parm), "not ready for direct profiling")
  endpoint_called <- FALSE
  testthat::local_mocked_bindings(drm_profile_target_endpoint_confint = function(...) { endpoint_called <<- TRUE; stop("endpoint profile must not start", call. = FALSE) }, .package = "drmTMB")
  endpoint <- confint(fit, parm = target$parm, method = "profile", profile_engine = "endpoint")
  expect_false(endpoint_called); expect_identical(endpoint$conf.status, "profile_failed"); expect_match(endpoint$profile.message, "endpoint engine unsupported")
  expect_error(drmTMB(bf(y ~ x, sigma ~ phylo(1 + x | species, tree = tree), zoi ~ 1, coi ~ 1), family = zero_one_beta(), data = d), "currently supports")
  expect_error(drmTMB(bf(y ~ x, sigma ~ phylo(1 | species, tree = tree), zoi ~ 1 + (1 | species), coi ~ 1), family = zero_one_beta(), data = d), "requires")
  obj <- TMB::MakeADFun(data = fit$model$tmb_data, parameters = fit$model$start, map = fit$model$map, DLL = "drmTMB", silent = TRUE)
  probe <- obj$par + seq(-.025, .025, length.out = length(obj$par)); oracle_fn <- function(v) zoib_sigma_phylo_nll(fit, obj$env$parList(v), tree, d$species)
  expect_equal(obj$fn(probe), oracle_fn(probe), tolerance = 1e-8)
  expect_equal(as.numeric(obj$gr(probe)), zoib_phylo_central_gradient(oracle_fn, probe), tolerance = 2e-5)
  i <- which(names(probe) == "log_sd_phylo"); changed <- probe; changed[[i]] <- changed[[i]] + .2
  expect_gt(abs(obj$fn(changed) - obj$fn(probe)), 1e-5)
})

test_that("zero-one-beta phylo q1 objective depends on its latent SD", {
  sim <- new_zero_one_beta_phylo_data(); tree <- sim$tree
  fit <- drmTMB(bf(y ~ x + phylo(1 | species, tree = tree)), family = zero_one_beta(), data = sim$data, control = drm_control(se = FALSE))
  obj <- TMB::MakeADFun(data = fit$model$tmb_data, parameters = fit$model$start, map = fit$model$map, DLL = "drmTMB", silent = TRUE)
  probe <- obj$par + seq(-.03, .03, length.out = length(obj$par)); par <- obj$env$parList(probe)
  oracle_fn <- function(x) zoib_phylo_nll(
    fit, obj$env$parList(x), tree = tree, species = sim$data$species
  )
  expect_equal(obj$fn(probe), oracle_fn(probe), tolerance = 1e-8)
  expect_equal(
    as.numeric(obj$gr(probe)), zoib_phylo_central_gradient(oracle_fn, probe),
    tolerance = 2e-5
  )
  i <- which(names(probe) == "log_sd_phylo"); changed <- probe; changed[[i]] <- changed[[i]] + .2
  expect_gt(abs(obj$fn(changed) - obj$fn(probe)), 1e-5)
})

test_that("zero-one-beta admits only the exact animal Ainv q1 mu gate", {
  sim <- new_zero_one_beta_animal_data(); Ainv <- sim$Ainv
  fit <- drmTMB(bf(y ~ x + animal(1 | species, Ainv = Ainv)), family = zero_one_beta(), data = sim$data, control = drm_control(se = FALSE))
  expect_equal(fit$opt$convergence, 0)
  expect_identical(fit$model$structured$phylo_mu$type, "animal")
  expect_equal(fit$model$structured$phylo_mu$node_labels, rownames(Ainv))
  expect_named(fit$sdpars$mu, "animal(1 | species)")
  expect_named(ranef(fit, "animal_mu")$terms, "animal(1 | species)")
  target <- profile_targets(fit)
  target <- target[target$parm == "sd:mu:animal(1 | species)", , drop = FALSE]
  expect_identical(target$profile_ready, FALSE)
  expect_identical(target$profile_note, "point_fit_only_zero_one_beta_animal_q1")
  expect_error(confint(fit, parm = target$parm, method = "profile"), "not ready for direct profiling")
  obj <- TMB::MakeADFun(data = fit$model$tmb_data, parameters = fit$model$start, map = fit$model$map, DLL = "drmTMB", silent = TRUE)
  probe <- obj$par + seq(-.025, .025, length.out = length(obj$par))
  oracle_fn <- function(x) zoib_animal_nll(fit, obj$env$parList(x), Ainv, sim$data$species)
  expect_equal(obj$fn(probe), oracle_fn(probe), tolerance = 1e-8)
  expect_equal(as.numeric(obj$gr(probe)), zoib_phylo_central_gradient(oracle_fn, probe), tolerance = 2e-5)
  expect_error(drmTMB(bf(y ~ x + animal(1 + x | species, Ainv = Ainv)), family = zero_one_beta(), data = sim$data), "only one unlabelled q1")
  expect_error(drmTMB(bf(y ~ x + animal(1 | species, A = solve(Ainv))), family = zero_one_beta(), data = sim$data), "Ainv")
})

test_that("zero-one-beta admits only the exact relmat K q1 mu gate", {
  sim <- new_zero_one_beta_relmat_data(); K <- sim$K
  fit <- drmTMB(bf(y ~ x + relmat(1 | species, K = K)), family = zero_one_beta(), data = sim$data, control = drm_control(se = FALSE))
  expect_equal(fit$opt$convergence, 0)
  expect_identical(fit$model$structured$phylo_mu$type, "relmat")
  expect_equal(fit$model$structured$phylo_mu$node_labels, rownames(K))
  expect_named(fit$sdpars$mu, "relmat(1 | species)")
  expect_named(ranef(fit, "relmat_mu")$terms, "relmat(1 | species)")
  target <- profile_targets(fit)
  target <- target[target$parm == "sd:mu:relmat(1 | species)", , drop = FALSE]
  expect_identical(target$profile_ready, FALSE)
  expect_identical(target$profile_note, "point_fit_only_zero_one_beta_relmat_q1")
  expect_error(confint(fit, parm = target$parm, method = "profile"), "not ready for direct profiling")
  expect_error(profile(fit, parm = target$parm), "not ready for direct profiling")
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
  expect_false(endpoint_called)
  expect_identical(endpoint$conf.status, "profile_failed")
  expect_match(endpoint$profile.message, "endpoint engine unsupported")
  obj <- TMB::MakeADFun(data = fit$model$tmb_data, parameters = fit$model$start, map = fit$model$map, DLL = "drmTMB", silent = TRUE)
  probe <- obj$par + seq(-.025, .025, length.out = length(obj$par))
  oracle_fn <- function(x) zoib_relmat_nll(fit, obj$env$parList(x), K, sim$data$species)
  expect_equal(obj$fn(probe), oracle_fn(probe), tolerance = 1e-8)
  expect_equal(as.numeric(obj$gr(probe)), zoib_phylo_central_gradient(oracle_fn, probe), tolerance = 2e-5)
  expect_error(drmTMB(bf(y ~ x + relmat(1 + x | species, K = K)), family = zero_one_beta(), data = sim$data), "only one unlabelled q1")
  expect_error(drmTMB(bf(y ~ x + relmat(1 | species, Q = solve(K))), family = zero_one_beta(), data = sim$data), "K")
})

test_that("zero-one-beta admits only the exact spatial coords q1 mu gate", {
  sim <- new_zero_one_beta_spatial_data(); coords <- sim$coords
  fit <- drmTMB(bf(y ~ x + spatial(1 | site, coords = coords)), family = zero_one_beta(), data = sim$data, control = drm_control(se = FALSE))
  expect_equal(fit$opt$convergence, 0)
  expect_identical(fit$model$structured$phylo_mu$type, "spatial")
  expect_named(fit$sdpars$mu, "spatial(1 | site)")
  expect_named(ranef(fit, "spatial_mu")$terms, "spatial(1 | site)")
  target <- profile_targets(fit)
  target <- target[target$parm == "sd:mu:spatial(1 | site)", , drop = FALSE]
  expect_identical(target$profile_ready, FALSE)
  expect_identical(target$profile_note, "point_fit_only_zero_one_beta_spatial_q1")
  expect_false(target$parm %in% profile_targets(fit, ready_only = TRUE)$parm)
  expect_error(confint(fit, parm = target$parm, method = "profile"), "not ready for direct profiling")
  expect_error(profile(fit, parm = target$parm), "not ready for direct profiling")
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
  expect_match(endpoint$profile.message, "endpoint engine unsupported")
  obj <- TMB::MakeADFun(data = fit$model$tmb_data, parameters = fit$model$start, map = fit$model$map, DLL = "drmTMB", silent = TRUE)
  probe <- obj$par + seq(-.025, .025, length.out = length(obj$par))
  oracle_fn <- function(x) zoib_spatial_nll(fit, obj$env$parList(x), coords, sim$data$site)
  expect_equal(obj$fn(probe), oracle_fn(probe), tolerance = 1e-8)
  expect_equal(as.numeric(obj$gr(probe)), zoib_phylo_central_gradient(oracle_fn, probe), tolerance = 2e-5)
  expect_error(drmTMB(bf(y ~ x + spatial(1 + x | site, coords = coords)), family = zero_one_beta(), data = sim$data), "only one unlabelled q1")
  expect_error(drmTMB(bf(y ~ x + spatial(1 | site, mesh = coords)), family = zero_one_beta(), data = sim$data), "coords")
})

test_that("zero-one-beta admits only the exact phylo-interaction q1 mu gate", {
  sim <- new_zero_one_beta_phylo_interaction_data()
  plant_tree <- sim$plant_tree; pollinator_tree <- sim$pollinator_tree
  fit <- drmTMB(bf(y ~ x + phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree)), family = zero_one_beta(), data = sim$data, control = drm_control(se = FALSE))
  expect_equal(fit$opt$convergence, 0)
  expect_identical(fit$model$structured$phylo_mu$type, "phylo_interaction")
  expect_equal(fit$model$structured$phylo_mu$q, 1L)
  expect_named(fit$sdpars$mu, "phylo_interaction(1 | plant:pollinator)")
  expect_named(ranef(fit, "phylo_interaction_mu")$terms, "phylo_interaction(1 | plant:pollinator)")
  target <- profile_targets(fit); target <- target[target$parm == "sd:mu:phylo_interaction(1 | plant:pollinator)", , drop = FALSE]
  expect_identical(target$profile_ready, FALSE)
  expect_identical(target$profile_note, "point_fit_only_zero_one_beta_phylo_interaction_q1")
  expect_false(target$parm %in% profile_targets(fit, ready_only = TRUE)$parm)
  expect_error(confint(fit, parm = target$parm, method = "profile"), "not ready for direct profiling")
  expect_error(profile(fit, parm = target$parm), "not ready for direct profiling")
  expect_error(drmTMB(bf(y ~ x + phylo_interaction(1 + x | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree)), family = zero_one_beta(), data = sim$data), "intercept-only")
  obj <- TMB::MakeADFun(data = fit$model$tmb_data, parameters = fit$model$start, map = fit$model$map, DLL = "drmTMB", silent = TRUE)
  probe <- obj$par + seq(-.025, .025, length.out = length(obj$par))
  oracle_fn <- function(x) zoib_phylo_interaction_nll(fit, obj$env$parList(x), plant_tree, pollinator_tree, sim$data)
  expect_equal(obj$fn(probe), oracle_fn(probe), tolerance = 1e-8)
  expect_equal(as.numeric(obj$gr(probe)), zoib_phylo_central_gradient(oracle_fn, probe), tolerance = 2e-5)
})

test_that("zero-one-beta admits only the exact sigma random-intercept q1 gate", {
  sim <- new_zero_one_beta_sigma_random_intercept_data()
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1 + (1 | id), zoi ~ 1, coi ~ 1),
    family = zero_one_beta(), data = sim$data, control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$model$random$sigma$n_terms, 1L)
  expect_equal(fit$model$random$sigma$n_cors, 0L)
  expect_named(fit$sdpars$sigma, "(1 | id)")
  expect_named(ranef(fit, "sigma")$terms, "(1 | id)")

  target <- profile_targets(fit)
  target <- target[target$parm == "sd:sigma:(1 | id)", , drop = FALSE]
  expect_equal(nrow(target), 1L)
  expect_identical(target$tmb_parameter, "log_sd_sigma")
  expect_identical(target$target_type, "direct")
  expect_identical(target$profile_ready, FALSE)
  expect_identical(target$profile_note, "point_fit_only_zero_one_beta_sigma_q1")
  expect_false(target$parm %in% profile_targets(fit, ready_only = TRUE)$parm)
  expect_error(confint(fit, parm = target$parm, method = "profile"), "not ready for direct profiling")
  expect_error(profile(fit, parm = target$parm), "not ready for direct profiling")
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
  expect_match(endpoint$profile.message, "endpoint engine unsupported")

  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1 + (1 + x | id), zoi ~ 1, coi ~ 1), family = zero_one_beta(), data = sim$data),
    "Only one independent"
  )
  expect_error(
    drmTMB(bf(y ~ x + (1 | id), sigma ~ 1 + (1 | id), zoi ~ 1, coi ~ 1), family = zero_one_beta(), data = sim$data),
    "cannot be combined"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1 + (1 | p | id), zoi ~ 1, coi ~ 1), family = zero_one_beta(), data = sim$data),
    "Only one independent"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1 + (1 | id) + (1 | id2), zoi ~ 1, coi ~ 1), family = zero_one_beta(), data = sim$data),
    "Only one independent"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ x + (1 | id), zoi ~ 1, coi ~ 1), family = zero_one_beta(), data = sim$data),
    "requires fixed"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1 + (1 | id), zoi ~ x, coi ~ 1), family = zero_one_beta(), data = sim$data),
    "requires fixed"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1 + (1 | id), zoi ~ 1, coi ~ x), family = zero_one_beta(), data = sim$data),
    "requires fixed"
  )
  phylo_sim <- new_zero_one_beta_phylo_data()
  tree <- phylo_sim$tree
  expect_error(
    drmTMB(
      bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1 + (1 | id), zoi ~ 1, coi ~ 1),
      family = zero_one_beta(), data = phylo_sim$data
    ),
    "cannot be combined with a structured mu"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ phylo(1 | id, tree = ape::stree(12L)), zoi ~ 1, coi ~ 1), family = zero_one_beta(), data = sim$data),
    "tree.*phylogeny"
  )
})

test_that("zero-one-beta sigma random-intercept objective has independent oracle and gradient", {
  sim <- new_zero_one_beta_sigma_random_intercept_data()
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1 + (1 | id), zoi ~ 1, coi ~ 1),
    family = zero_one_beta(), data = sim$data, control = drm_control(se = FALSE)
  )
  obj <- TMB::MakeADFun(
    data = fit$model$tmb_data, parameters = fit$model$start,
    map = fit$model$map, DLL = "drmTMB", silent = TRUE
  )
  probe <- obj$par + seq(-0.025, 0.025, length.out = length(obj$par))
  oracle_fn <- function(x) zoib_sigma_random_intercept_nll(fit, obj$env$parList(x))
  expect_equal(obj$fn(probe), oracle_fn(probe), tolerance = 1e-8)
  expect_equal(
    as.numeric(obj$gr(probe)), zoib_phylo_central_gradient(oracle_fn, probe),
    tolerance = 2e-5
  )
  i <- which(names(probe) == "log_sd_sigma")
  expect_length(i, 1L)
  changed <- probe
  changed[[i]] <- changed[[i]] + 0.2
  expect_gt(abs(obj$fn(changed) - obj$fn(probe)), 1e-5)
})

test_that("zero-one-beta admits only the exact sigma random-slope q1 gate", {
  set.seed(2026073701L)
  id <- factor(rep(seq_len(12L), each = 30L)); x <- stats::rnorm(length(id)); u <- stats::rnorm(12L)
  mu <- stats::plogis(.2 * x); sigma <- exp(-1 + .35 * u[id] * x); zoi <- stats::plogis(-.7); coi <- stats::plogis(.1)
  boundary <- stats::rbinom(length(id), 1L, zoi); y <- stats::rbeta(length(id), mu / sigma^2, (1 - mu) / sigma^2)
  y[boundary == 1L] <- stats::rbinom(sum(boundary), 1L, coi)
  d <- data.frame(y, x, id)
  fit <- drmTMB(bf(y ~ x, sigma ~ x + (0 + x | id), zoi ~ 1, coi ~ 1), family = zero_one_beta(), data = d, control = drm_control(se = FALSE))
  expect_equal(fit$opt$convergence, 0); expect_named(fit$sdpars$sigma, "(0 + x | id)")
  target <- profile_targets(fit)
  target <- target[target$parm == "sd:sigma:(0 + x | id)", , drop = FALSE]
  expect_equal(nrow(target), 1L)
  expect_identical(target$tmb_parameter, "log_sd_sigma")
  expect_identical(target$target_type, "direct")
  expect_identical(target$profile_ready, FALSE)
  expect_identical(target$profile_note, "point_fit_only_zero_one_beta_sigma_q1")
  expect_false(target$parm %in% profile_targets(fit, ready_only = TRUE)$parm)
  expect_error(confint(fit, parm = target$parm, method = "profile"), "not ready for direct profiling")
  expect_error(profile(fit, parm = target$parm), "not ready for direct profiling")
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
  expect_match(endpoint$profile.message, "endpoint engine unsupported")
  expect_error(drmTMB(bf(y ~ x, sigma ~ x + z + (0 + x | id), zoi ~ 1, coi ~ 1), family = zero_one_beta(), data = transform(d, z = x)), "requires")
  expect_error(drmTMB(bf(y ~ x, sigma ~ z + (0 + x | id), zoi ~ 1, coi ~ 1), family = zero_one_beta(), data = transform(d, z = x)), "requires")
  expect_error(drmTMB(bf(y ~ x, sigma ~ I(x^2) + (0 + x | id), zoi ~ 1, coi ~ 1), family = zero_one_beta(), data = d), "requires")
  expect_error(drmTMB(bf(y ~ x, sigma ~ x + (1 | id), zoi ~ 1, coi ~ 1), family = zero_one_beta(), data = d), "requires")
  obj <- TMB::MakeADFun(data = fit$model$tmb_data, parameters = fit$model$start, map = fit$model$map, DLL = "drmTMB", silent = TRUE)
  probe <- obj$par + seq(-.025, .025, length.out = length(obj$par)); oracle_fn <- function(v) zoib_sigma_random_intercept_nll(fit, obj$env$parList(v))
  expect_equal(obj$fn(probe), oracle_fn(probe), tolerance = 1e-8)
  expect_equal(as.numeric(obj$gr(probe)), zoib_phylo_central_gradient(oracle_fn, probe), tolerance = 2e-5)
})

test_that("zero-one-beta admits only the exact zoi random-intercept q1 gate", {
  sim <- new_zero_one_beta_zoi_random_intercept_data(n_id = 12L, n_each = 24L)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, zoi ~ 1 + (1 | id), coi ~ 1),
    family = zero_one_beta(), data = sim$data, control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$model$random$zoi$n_terms, 1L)
  expect_equal(fit$model$random$zoi$n_cors, 0L)
  expect_named(fit$sdpars$zoi, "(1 | id)")
  expect_named(ranef(fit, "zoi")$terms, "(1 | id)")
  target <- profile_targets(fit)
  target <- target[target$parm == "sd:zoi:(1 | id)", , drop = FALSE]
  expect_equal(nrow(target), 1L)
  expect_identical(target$tmb_parameter, "log_sd_zoi")
  expect_identical(target$target_type, "direct")
  expect_identical(target$profile_ready, FALSE)
  expect_identical(target$profile_note, "point_fit_only_zero_one_beta_zoi_q1")
  expect_false(target$parm %in% profile_targets(fit, ready_only = TRUE)$parm)
  expect_error(confint(fit, parm = target$parm, method = "profile"), "not ready for direct profiling")
  expect_error(profile(fit, parm = target$parm), "not ready for direct profiling")
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
  expect_match(endpoint$profile.message, "endpoint engine unsupported")
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1, zoi ~ 1 + (0 + x | id), coi ~ 1), family = zero_one_beta(), data = sim$data),
    "Only one independent"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1, zoi ~ 1 + (1 | p | id), coi ~ 1), family = zero_one_beta(), data = sim$data),
    "Only one independent"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1, zoi ~ x + (1 | id), coi ~ 1), family = zero_one_beta(), data = sim$data),
    "requires fixed"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1, zoi ~ 1 + (1 | id), coi ~ x), family = zero_one_beta(), data = sim$data),
    "requires fixed"
  )
  expect_error(
    drmTMB(bf(y ~ x + (1 | id), sigma ~ 1, zoi ~ 1 + (1 | id), coi ~ 1), family = zero_one_beta(), data = sim$data),
    "cannot be combined"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1 + (1 | id), zoi ~ 1 + (1 | id), coi ~ 1), family = zero_one_beta(), data = sim$data),
    "cannot be combined"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1, zoi ~ 1 + (1 | id), coi ~ 1 + (1 | id)), family = zero_one_beta(), data = sim$data),
    "cannot be combined"
  )
  missing_data <- sim$data
  missing_data$y[[1L]] <- NA_real_
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, zoi ~ 1 + (1 | id), coi ~ 1),
      family = zero_one_beta(), data = missing_data,
      missing = miss_control(response = "include")
    ),
    "does not support missing responses"
  )
  tree <- ape::stree(12L, type = "star")
  tree$edge.length <- rep(1, nrow(tree$edge))
  tree$tip.label <- levels(sim$data$id)
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, zoi ~ phylo(1 | id, tree = tree), coi ~ 1),
      family = zero_one_beta(), data = sim$data
    ),
    "Structured-effect syntax"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + phylo(1 | id, tree = tree), sigma ~ 1, zoi ~ 1 + (1 | id), coi ~ 1),
      family = zero_one_beta(), data = sim$data
    ),
    "cannot be combined with a structured mu"
  )
})

test_that("zero-one-beta zoi random-intercept objective has independent oracle and gradient", {
  sim <- new_zero_one_beta_zoi_random_intercept_data(n_id = 12L, n_each = 24L)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, zoi ~ 1 + (1 | id), coi ~ 1),
    family = zero_one_beta(), data = sim$data, control = drm_control(se = FALSE)
  )
  obj <- TMB::MakeADFun(
    data = fit$model$tmb_data, parameters = fit$model$start,
    map = fit$model$map, DLL = "drmTMB", silent = TRUE
  )
  probe <- obj$par + seq(-0.025, 0.025, length.out = length(obj$par))
  oracle_fn <- function(x) zoib_zoi_random_intercept_nll(fit, obj$env$parList(x))
  expect_equal(obj$fn(probe), oracle_fn(probe), tolerance = 1e-8)
  expect_equal(
    as.numeric(obj$gr(probe)), zoib_phylo_central_gradient(oracle_fn, probe),
    tolerance = 2e-5
  )
  i <- which(names(probe) == "log_sd_zoi")
  expect_length(i, 1L)
  changed <- probe
  changed[[i]] <- changed[[i]] + 0.2
  expect_gt(abs(obj$fn(changed) - obj$fn(probe)), 1e-5)
})

test_that("zero-one-beta admits only the exact zoi random-slope q1 gate", {
  set.seed(2026073801L)
  id <- factor(rep(seq_len(16L), each = 40L)); x <- rnorm(length(id)); x <- x - ave(x, id, FUN = mean); x <- x / sd(x)
  u <- rnorm(16L); mu <- plogis(-.15 + .35 * x); sigma <- exp(-1); zoi <- plogis(-1.15 + .45 * u[id] * x); coi <- plogis(.1)
  boundary <- rbinom(length(id), 1L, zoi); y <- rbeta(length(id), mu / sigma^2, (1 - mu) / sigma^2); y[boundary == 1L] <- rbinom(sum(boundary), 1L, coi)
  d <- data.frame(y, x, id)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1, zoi ~ x + (0 + x | id), coi ~ 1), family = zero_one_beta(), data = d, control = drm_control(se = FALSE))
  expect_equal(fit$opt$convergence, 0); expect_named(fit$sdpars$zoi, "(0 + x | id)")
  target <- subset(profile_targets(fit), parm == "sd:zoi:(0 + x | id)")
  expect_identical(target$tmb_parameter, "log_sd_zoi"); expect_identical(target$target_type, "direct")
  expect_false(target$profile_ready); expect_identical(target$profile_note, "point_fit_only_zero_one_beta_zoi_q1")
  expect_false(target$parm %in% profile_targets(fit, ready_only = TRUE)$parm)
  expect_error(confint(fit, parm = target$parm, method = "profile"), "not ready for direct profiling")
  expect_error(profile(fit, parm = target$parm), "not ready for direct profiling")
  endpoint_called <- FALSE
  testthat::local_mocked_bindings(drm_profile_target_endpoint_confint = function(...) { endpoint_called <<- TRUE; stop("endpoint profile must not start", call. = FALSE) }, .package = "drmTMB")
  endpoint <- confint(fit, parm = target$parm, method = "profile", profile_engine = "endpoint")
  expect_false(endpoint_called); expect_identical(endpoint$conf.status, "profile_failed"); expect_match(endpoint$profile.message, "endpoint engine unsupported")
  expect_error(drmTMB(bf(y ~ x, sigma ~ 1, zoi ~ z + (0 + x | id), coi ~ 1), family = zero_one_beta(), data = transform(d, z = x)), "requires")
  expect_error(drmTMB(bf(y ~ x, sigma ~ 1, zoi ~ I(x^2) + (0 + x | id), coi ~ 1), family = zero_one_beta(), data = d), "requires")
  expect_error(drmTMB(bf(y ~ x, sigma ~ 1, zoi ~ x + (1 | id), coi ~ 1), family = zero_one_beta(), data = d), "requires")
  obj <- TMB::MakeADFun(data = fit$model$tmb_data, parameters = fit$model$start, map = fit$model$map, DLL = "drmTMB", silent = TRUE)
  probe <- obj$par + seq(-.025, .025, length.out = length(obj$par)); oracle_fn <- function(v) zoib_zoi_random_intercept_nll(fit, obj$env$parList(v))
  expect_equal(obj$fn(probe), oracle_fn(probe), tolerance = 1e-8)
  expect_equal(as.numeric(obj$gr(probe)), zoib_phylo_central_gradient(oracle_fn, probe), tolerance = 2e-5)
  i <- which(names(probe) == "log_sd_zoi"); changed <- probe; changed[[i]] <- changed[[i]] + .2
  expect_gt(abs(obj$fn(changed) - obj$fn(probe)), 1e-5)
})
test_that("drmTMB fits fixed-effect zero-one beta models", {
  sim <- new_zero_one_beta_data()

  fit <- drmTMB(
    bf(prop ~ x, sigma ~ z, zoi ~ w, coi ~ v),
    family = zero_one_beta(),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "zero_one_beta")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$df, length(unlist(coef(fit), use.names = FALSE)))
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.10)
  expect_lt(max(abs(coef(fit, "sigma") - sim$beta_sigma)), 0.12)
  expect_lt(max(abs(coef(fit, "zoi") - sim$beta_zoi)), 0.12)
  expect_lt(max(abs(coef(fit, "coi") - sim$beta_coi)), 0.22)
  expect_true(all(predict(fit, dpar = "mu") > 0))
  expect_true(all(predict(fit, dpar = "mu") < 1))
  expect_true(all(predict(fit, dpar = "zoi") > 0))
  expect_true(all(predict(fit, dpar = "zoi") < 1))
  expect_true(all(predict(fit, dpar = "coi") > 0))
  expect_true(all(predict(fit, dpar = "coi") < 1))
  expect_true(all(sigma(fit) > 0))

  fitted_mean <- (1 - predict(fit, dpar = "zoi")) *
    predict(fit, dpar = "mu") +
    predict(fit, dpar = "zoi") * predict(fit, dpar = "coi")
  expect_equal(fitted(fit), fitted_mean, tolerance = 1e-12)

  ci <- confint(fit)
  expect_equal(
    ci$parm,
    c(
      "fixef:mu:(Intercept)",
      "fixef:mu:x",
      "fixef:sigma:(Intercept)",
      "fixef:sigma:z",
      "fixef:zoi:(Intercept)",
      "fixef:zoi:w",
      "fixef:coi:(Intercept)",
      "fixef:coi:v"
    )
  )
  expect_equal(
    ci$tmb_parameter,
    c(
      "beta_mu",
      "beta_mu",
      "beta_sigma",
      "beta_sigma",
      "beta_zoi",
      "beta_zoi",
      "beta_coi",
      "beta_coi"
    )
  )
  expect_true(all(ci$conf.status == "wald"))
})

test_that("zero-one beta likelihood matches independent mixture calculation", {
  sim <- new_zero_one_beta_data(n = 420, seed = 20260621)

  fit <- drmTMB(
    bf(prop ~ x, sigma ~ z, zoi ~ w, coi ~ v),
    family = zero_one_beta(),
    data = sim$data
  )
  eta_mu <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  eta_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  eta_zoi <- as.vector(fit$model$X$zoi %*% coef(fit, "zoi"))
  eta_coi <- as.vector(fit$model$X$coi %*% coef(fit, "coi"))
  ll_independent <- sum(dzoibeta_drm(
    fit$model$y,
    mu = stats::plogis(eta_mu),
    sigma = exp(eta_sigma),
    zoi = stats::plogis(eta_zoi),
    coi = stats::plogis(eta_coi),
    log = TRUE
  ))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(as.numeric(logLik(fit)), ll_independent, tolerance = 1e-6)

  weights <- seq(0.5, 1.5, length.out = nrow(sim$data))
  fit_w <- drmTMB(
    bf(prop ~ x, sigma ~ z, zoi ~ w, coi ~ v),
    family = zero_one_beta(),
    data = sim$data,
    weights = weights
  )
  ll_weighted <- sum(
    weights *
      dzoibeta_drm(
        fit_w$model$y,
        mu = predict(fit_w, dpar = "mu"),
        sigma = predict(fit_w, dpar = "sigma"),
        zoi = predict(fit_w, dpar = "zoi"),
        coi = predict(fit_w, dpar = "coi"),
        log = TRUE
      )
  )

  expect_equal(fit_w$opt$convergence, 0)
  expect_equal(as.numeric(logLik(fit_w)), ll_weighted, tolerance = 1e-6)
})

test_that("zero-one beta methods use the unconditional response mean", {
  sim <- new_zero_one_beta_data(n = 360, seed = 20260622)
  fit <- drmTMB(
    bf(prop ~ x, sigma ~ z, zoi ~ w, coi ~ v),
    family = zero_one_beta(),
    data = sim$data
  )

  mu <- predict(fit, dpar = "mu")
  sigma <- predict(fit, dpar = "sigma")
  zoi <- predict(fit, dpar = "zoi")
  coi <- predict(fit, dpar = "coi")
  fitted_mean <- (1 - zoi) * mu + zoi * coi
  beta_var <- mu * (1 - mu) * sigma^2 / (1 + sigma^2)
  mixture_var <- (1 - zoi) * (beta_var + mu^2) + zoi * coi - fitted_mean^2

  expect_equal(residuals(fit), fit$model$y - fitted_mean, tolerance = 1e-12)
  expect_equal(
    residuals(fit, type = "pearson"),
    (fit$model$y - fitted_mean) / sqrt(mixture_var),
    tolerance = 1e-12
  )

  newdata <- data.frame(
    x = c(-1, 0, 1),
    z = c(-1, 0, 1),
    w = c(-1, 0, 1),
    v = c(-1, 0, 1)
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "zoi", type = "link"),
    as.vector(stats::model.matrix(~w, newdata) %*% coef(fit, "zoi")),
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "coi"),
    stats::plogis(predict(fit, newdata = newdata, dpar = "coi", type = "link")),
    tolerance = 1e-12
  )

  sims <- simulate(fit, nsim = 2, seed = 20260623)
  expect_equal(dim(sims), c(nrow(fit$data), 2L))
  expect_named(sims, c("sim_1", "sim_2"))
  expect_true(all(unlist(sims, use.names = FALSE) >= 0))
  expect_true(all(unlist(sims, use.names = FALSE) <= 1))
  expect_true(any(unlist(sims, use.names = FALSE) == 0))
  expect_true(any(unlist(sims, use.names = FALSE) == 1))
  expect_equal(
    simulate(fit, nsim = 2, seed = 20260623),
    simulate(fit, nsim = 2, seed = 20260623)
  )
})

test_that("zero-one beta handles pure interior and one-sided boundary cells", {
  n <- 500
  dat <- data.frame(x = stats::rnorm(n), z = stats::rnorm(n))
  mu <- stats::plogis(0.10 + 0.50 * dat$x)
  sigma <- exp(-0.80 + 0.20 * dat$z)
  dat$prop <- stats::rbeta(
    n,
    shape1 = mu / sigma^2,
    shape2 = (1 - mu) / sigma^2
  )

  pure_interior <- drmTMB(
    bf(prop ~ x, sigma ~ z, zoi ~ 1, coi ~ 1),
    family = zero_one_beta(),
    data = dat
  )
  expect_equal(pure_interior$opt$convergence, 0)
  expect_true(is.finite(as.numeric(logLik(pure_interior))))
  expect_lt(unique(predict(pure_interior, dpar = "zoi")), 1e-4)

  zero_only <- transform(dat, prop = replace(prop, seq(1, n, by = 4), 0))
  one_only <- transform(dat, prop = replace(prop, seq(1, n, by = 4), 1))
  fit_zero <- drmTMB(
    bf(prop ~ x, sigma ~ z, zoi ~ 1, coi ~ 1),
    family = zero_one_beta(),
    data = zero_only
  )
  fit_one <- drmTMB(
    bf(prop ~ x, sigma ~ z, zoi ~ 1, coi ~ 1),
    family = zero_one_beta(),
    data = one_only
  )

  expect_equal(fit_zero$opt$convergence, 0)
  expect_equal(fit_one$opt$convergence, 0)
  expect_true(fit_zero$sdr$pdHess)
  expect_true(fit_one$sdr$pdHess)
  expect_lt(coef(fit_zero, "coi")[[1L]], -10)
  expect_gt(coef(fit_one, "coi")[[1L]], 10)
})

test_that("zero-one beta validates malformed and neighbouring inputs", {
  dat <- data.frame(
    y = c(0, 1, seq(0.12, 0.88, length.out = 10)),
    x = rep(c(0, 1), 6),
    id = factor(rep(1:3, each = 4)),
    success = c(0, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2),
    failure = c(4, 0, 3, 2, 1, 0, 3, 2, 1, 0, 3, 2)
  )

  expect_no_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1),
      family = zero_one_beta(),
      data = dat
    )
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = beta(), data = dat),
    "strictly between 0 and 1"
  )
  expect_error(
    drmTMB(
      bf(cbind(success, failure) ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1),
      family = zero_one_beta(),
      data = dat
    ),
    "single continuous bounded response"
  )
  # A `mu` random intercept is covered by Arc 2a; Z3 additionally admits only
  # the ordinary sigma random intercept. Inflation random effects remain closed.
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, zoi ~ x + (1 | id), coi ~ 1),
      family = zero_one_beta(),
      data = dat
    ),
    "zoi random-intercept q1 gate"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ x + (0 + x | id)),
      family = zero_one_beta(),
      data = dat
    ),
    "One-inflation random effects"
  )
  expect_no_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1 + (1 | id), zoi ~ 1, coi ~ 1),
      family = zero_one_beta(),
      data = dat
    )
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1, sd(id) ~ 1),
      family = zero_one_beta(),
      data = dat
    ),
    "Random-effect scale"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + meta_V(V = rep(0.1, 4)), sigma ~ 1, zoi ~ 1, coi ~ 1),
      family = zero_one_beta(),
      data = dat
    ),
    "meta_V"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1),
      family = zero_one_beta(),
      data = transform(dat, y = replace(y, 1, -0.1))
    ),
    "closed interval"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1),
      family = zero_one_beta(),
      data = transform(dat, y = rep(c(0, 1), length.out = nrow(dat)))
    ),
    "at least one interior"
  )
  expect_error(
    drmTMB(
      bf(mvbind(y, y) ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1),
      family = zero_one_beta(),
      data = dat
    ),
    "mvbind"
  )
})

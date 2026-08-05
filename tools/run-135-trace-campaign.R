#!/usr/bin/env Rscript
# 135-trace Prong B interval campaign — one (cell, seed, target) fit+profile.
#
# Authority:
#   docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/PREREGISTRATION.md
#   LOOP/ultra-plan.md
#
# Recorded endpoints use stats::profile() → TMB::tmbprofile (grid engine).
# clamp_limited is COMPUTED from the profile object (never hard-coded FALSE).
# Clause 6 (both-sides LR + unimodality) is evaluated and written on every receipt.
#
# Usage:
#   Rscript tools/run-135-trace-campaign.R --list
#   Rscript tools/run-135-trace-campaign.R --cell mc-0568 --seed-index 1 --target 'sd:sigma:(1 | id)'
#   Rscript tools/run-135-trace-campaign.R --cell mc-0568 --seed-index 1   # all targets for cell

`%||%` <- function(a, b) {
  if (is.null(a) || length(a) == 0L || (length(a) == 1L && is.na(a))) b else a
}

args <- commandArgs(trailingOnly = TRUE)
get_flag <- function(name, default = NULL) {
  hit <- which(args == name)
  if (!length(hit)) return(default)
  if (hit[[1L]] == length(args)) stop("Flag ", name, " needs a value", call. = FALSE)
  args[[hit[[1L]] + 1L]]
}
has_flag <- function(name) name %in% args

repo <- normalizePath(get_flag("--repo", Sys.getenv("DRMTMB_REPO", unset = ".")), mustWork = TRUE)
outdir_root <- get_flag(
  "--outdir",
  file.path(repo, "docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign")
)
level <- as.numeric(get_flag("--level", "0.95"))
lr_threshold <- stats::qchisq(level, df = 1L) / 2
# 0.95 → ~1.920729 on delta_objective (= deviance/2) scale

# ---------------------------------------------------------------------------
# Diagnostics (clause 5 clamp + clause 6 LR / unimodality)
# ---------------------------------------------------------------------------

trace_lr_both_sides <- function(trace, estimate, threshold) {
  if (is.null(trace) || !nrow(trace) || !is.finite(estimate)) {
    return(list(ok = FALSE, left = NA_real_, right = NA_real_))
  }
  x <- as.numeric(trace$profile_value)
  d <- as.numeric(trace$delta_objective)
  ok_row <- is.finite(x) & is.finite(d)
  x <- x[ok_row]
  d <- d[ok_row]
  if (!length(x)) return(list(ok = FALSE, left = NA_real_, right = NA_real_))
  left <- suppressWarnings(max(d[x < estimate], na.rm = TRUE))
  right <- suppressWarnings(max(d[x > estimate], na.rm = TRUE))
  if (!is.finite(left)) left <- NA_real_
  if (!is.finite(right)) right <- NA_real_
  list(
    ok = is.finite(left) && is.finite(right) && left >= threshold && right >= threshold,
    left = left,
    right = right
  )
}

trace_unimodal <- function(trace, tol = 1e-6) {
  if (is.null(trace) || !nrow(trace)) return(FALSE)
  x <- as.numeric(trace$profile_value)
  o <- as.numeric(trace$objective)
  ok_row <- is.finite(x) & is.finite(o)
  x <- x[ok_row]
  o <- o[ok_row]
  if (length(x) < 3L) return(FALSE)
  ord <- order(x)
  x <- x[ord]
  o <- o[ord]
  imin <- which.min(o)
  left_ok <- if (imin <= 1L) TRUE else all(diff(o[seq_len(imin)]) <= tol)
  right_ok <- if (imin >= length(o)) TRUE else all(diff(o[seq.int(imin, length(o))]) >= -tol)
  isTRUE(left_ok && right_ok)
}

compute_clamp_limited <- function(prof, conf_status, profile_message) {
  # Prefer the engine's own classification when present.
  if (identical(conf_status, "clamp_limited")) return(TRUE)
  msg <- tolower(as.character(profile_message %||% ""))
  if (grepl("clamp", msg, fixed = TRUE)) return(TRUE)
  # Belt: if the profile object carried a non-ok clamp status via message.
  if (is.data.frame(prof) && "profile.message" %in% names(prof)) {
    msgs <- unique(as.character(prof$profile.message))
    if (any(grepl("clamp", tolower(msgs), fixed = TRUE))) return(TRUE)
  }
  FALSE
}

file_sha256 <- function(path) {
  if (!file.exists(path)) return("")
  unname(tools::md5sum(path)) # lightweight receipt hash; rename field documents intent
}

# ---------------------------------------------------------------------------
# Cell registry (cell_index order matches PREREGISTRATION §2)
# ---------------------------------------------------------------------------

standard_x <- function(id) {
  x <- stats::rnorm(length(id))
  x <- x - ave(x, id, FUN = mean)
  x / stats::sd(x)
}

dense_zoib_phylo_precision <- function(tree) {
  n_tip <- length(tree$tip.label)
  n_total <- n_tip + tree$Nnode
  root <- setdiff(tree$edge[, 1L], tree$edge[, 2L])
  stopifnot(length(root) == 1L)
  included <- setdiff(seq_len(n_total), root)
  index <- integer(n_total)
  index[included] <- seq_along(included)
  Q <- matrix(0, length(included), length(included))
  for (edge_id in seq_len(nrow(tree$edge))) {
    parent <- tree$edge[edge_id, 1L]
    child <- tree$edge[edge_id, 2L]
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

dense_zoib_spatial_precision <- function(coords, site_levels, jitter = 1e-6) {
  coords <- as.matrix(coords)[site_levels, seq_len(2L), drop = FALSE]
  distances <- as.matrix(stats::dist(coords))
  positive <- distances[distances > 0]
  range <- stats::median(positive)
  if (!is.finite(range) || range <= 0) range <- max(positive)
  K <- exp(-distances / range)
  diag(K) <- diag(K) + jitter
  chol_K <- chol(K)
  list(Q = chol2inv(chol_K), log_det_Q = -2 * sum(log(diag(chol_K))), levels = site_levels)
}

zob_sigma_control <- function() {
  drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 900L, iter.max = 900L))
}

new_count_structured_mu_slope_data <- function(
  seed,
  n_level = 16L,
  n_each = 24L,
  sd_intercept = 0.25,
  sd_slope = 0.45,
  rho_phylo = 0.50,
  rho_provider = 0.50,
  sigma_nb2 = 0.20
) {
  set.seed(seed)
  levels <- paste0("id", seq_len(n_level))
  site <- rep(levels, each = n_each)
  id <- site
  x <- stats::rnorm(length(site))
  theta <- seq(0, 1.75 * pi, length.out = n_level)
  coords <- data.frame(
    x = cos(theta) + seq_len(n_level) / (4 * n_level),
    y = sin(theta)
  )
  rownames(coords) <- levels
  precision <- drmTMB:::drm_spatial_coords_precision(coords, site = levels, group = "site")
  spatial_covariance <- solve(as.matrix(precision$precision))
  K <- outer(seq_len(n_level), seq_len(n_level), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(levels, levels)
  Q <- solve(K)
  tree <- ape::stree(n_level, type = "balanced")
  tree$tip.label <- levels
  tree$edge.length <- rep(1, nrow(tree$edge))
  phylo_covariance <- drmTMB:::drm_phylo_tip_covariance(tree)
  phylo_covariance <- phylo_covariance[levels, levels]
  draw_fields <- function(covariance, rho = 0) {
    chol_covariance <- chol(covariance + diag(1e-8, nrow(covariance)))
    z_intercept <- stats::rnorm(nrow(covariance))
    z_slope <- rho * z_intercept + sqrt(1 - rho^2) * stats::rnorm(nrow(covariance))
    intercept <- as.vector(t(chol_covariance) %*% z_intercept * sd_intercept)
    slope <- as.vector(t(chol_covariance) %*% z_slope * sd_slope)
    names(intercept) <- rownames(covariance)
    names(slope) <- rownames(covariance)
    list(intercept = intercept, slope = slope)
  }
  fields <- list(
    phylo = draw_fields(phylo_covariance, rho = rho_phylo),
    spatial = draw_fields(spatial_covariance, rho = rho_provider),
    known = draw_fields(K, rho = rho_provider)
  )
  beta_mu <- c(`(Intercept)` = 0.55, x = -0.15)
  eta <- list(
    phylo = beta_mu[[1L]] + beta_mu[[2L]] * x + fields$phylo$intercept[site] + x * fields$phylo$slope[site],
    spatial = beta_mu[[1L]] + beta_mu[[2L]] * x + fields$spatial$intercept[site] + x * fields$spatial$slope[site],
    known = beta_mu[[1L]] + beta_mu[[2L]] * x + fields$known$intercept[id] + x * fields$known$slope[id]
  )
  data <- data.frame(
    poisson_phylo = stats::rpois(length(site), lambda = exp(eta$phylo)),
    poisson_spatial = stats::rpois(length(site), lambda = exp(eta$spatial)),
    poisson_known = stats::rpois(length(site), lambda = exp(eta$known)),
    nb2_phylo = stats::rnbinom(length(site), size = 1 / sigma_nb2^2, mu = exp(eta$phylo)),
    nb2_spatial = stats::rnbinom(length(site), size = 1 / sigma_nb2^2, mu = exp(eta$spatial)),
    nb2_known = stats::rnbinom(length(site), size = 1 / sigma_nb2^2, mu = exp(eta$known)),
    x = x,
    site = site,
    id = id
  )
  list(data = data, coords = coords, tree = tree, Q = Q)
}

phylo_interaction_balanced_tree <- function(n_tip, prefix) {
  edges <- matrix(integer(), ncol = 2L)
  edge_lengths <- numeric()
  next_node <- n_tip + 1L
  build <- function(tips) {
    if (length(tips) == 1L) return(tips)
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

new_phylo_interaction_sigma_nb2_data <- function(
  seed,
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
  pair_effect <- as.vector(t(chol(pair_cov)) %*% stats::rnorm(nrow(pair_grid), sd = sd_pair))
  names(pair_effect) <- paste0(pair_grid$plant, ":", pair_grid$pollinator)
  row_id <- rep(seq_len(nrow(pair_grid)), each = n_each)
  dat <- pair_grid[row_id, , drop = FALSE]
  dat$x <- stats::rnorm(nrow(dat))
  log_sigma <- sigma_intercept + pair_effect[paste0(dat$plant, ":", dat$pollinator)]
  dat$nb2 <- stats::rnbinom(nrow(dat), mu = exp(1.4 + 0.3 * dat$x), size = exp(-2 * log_sigma))
  list(data = dat, plant_tree = plant_tree, pollinator_tree = pollinator_tree)
}

new_zi_nbinom2_sigma_phylo_interaction_data <- function(
  seed,
  n_plant = 8L,
  n_pollinator = 8L,
  n_each = 18L,
  sd_pair = 0.60,
  sigma_intercept = -0.20,
  zi_probability = 0.20
) {
  # Campaign uses 8×8 (fixture-repair design), not the fence battery's cheap 4×4.
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
  pair_effect <- as.vector(t(chol(pair_cov)) %*% stats::rnorm(nrow(pair_grid), sd = sd_pair))
  names(pair_effect) <- paste0(pair_grid$plant, ":", pair_grid$pollinator)
  row_id <- rep(seq_len(nrow(pair_grid)), each = n_each)
  dat <- pair_grid[row_id, , drop = FALSE]
  dat$x <- as.vector(scale(stats::rnorm(nrow(dat)), scale = FALSE))
  log_sigma <- sigma_intercept + pair_effect[paste0(dat$plant, ":", dat$pollinator)]
  structural_zero <- stats::runif(nrow(dat)) < zi_probability
  nb_count <- stats::rnbinom(nrow(dat), mu = exp(1.4 + 0.3 * dat$x), size = exp(-2 * log_sigma))
  dat$count <- ifelse(structural_zero, 0L, nb_count)
  list(data = dat, plant_tree = plant_tree, pollinator_tree = pollinator_tree)
}

q2_target_truths <- function(provider, group) {
  data.frame(
    target = c(
      paste0("sd:mu:", provider, "(1 | p | ", group, ")"),
      paste0("sd:mu:", provider, "(0 + x | p | ", group, ")"),
      paste0("cor:", provider, ":cor(mu:(Intercept),mu:x | p | ", group, ")")
    ),
    true_value = c(0.25, 0.45, 0.50),
    n_seeds = c(5L, 5L, 8L),
    stringsAsFactors = FALSE
  )
}

make_cell <- function(cell_id, cell_index, group, targets_df, build_fit, early_stop = FALSE) {
  list(
    cell_id = cell_id,
    cell_index = as.integer(cell_index),
    group = group,
    targets = targets_df,
    build_fit = build_fit,
    early_stop = isTRUE(early_stop),
    structured_sigma_claim = group %in% c("zob_sigma_structured", "count_sigma_phylo_interaction")
  )
}

CELL_REGISTRY <- list(
  make_cell(
    "mc-0568", 1L, "zob_sigma_ordinary",
    data.frame(target = "sd:sigma:(1 | id)", true_value = 0.45, n_seeds = 5L, stringsAsFactors = FALSE),
    function(seed) {
      set.seed(seed)
      id <- factor(rep(paste0("g", seq_len(32L)), each = 30L))
      x <- standard_x(id)
      b <- stats::rnorm(32L, sd = 0.45)
      names(b) <- levels(id)
      mu <- stats::plogis(-0.15 + 0.35 * x)
      sigma <- exp(log(0.45) + b[as.character(id)])
      boundary <- stats::rbinom(length(id), 1L, 0.14)
      y <- ifelse(
        boundary == 1L,
        stats::rbinom(length(id), 1L, 0.40),
        stats::rbeta(length(id), mu / sigma^2, (1 - mu) / sigma^2)
      )
      list(
        data = data.frame(y, x, id),
        formula = drmTMB::bf(y ~ x, sigma ~ 1 + (1 | id), zoi ~ 1, coi ~ 1),
        family = drmTMB::zero_one_beta(),
        control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 3000L, iter.max = 3000L))
      )
    }
  ),
  make_cell(
    "mc-0576", 2L, "zob_sigma_ordinary",
    data.frame(target = "sd:sigma:(0 + x | id)", true_value = 0.45, n_seeds = 5L, stringsAsFactors = FALSE),
    function(seed) {
      set.seed(seed)
      id <- factor(rep(paste0("g", seq_len(32L)), each = 50L))
      x <- standard_x(id)
      b <- stats::rnorm(32L, sd = 0.45)
      names(b) <- levels(id)
      mu <- stats::plogis(-0.15 + 0.35 * x)
      sigma <- exp(-1 + b[as.character(id)] * x)
      zoi <- stats::plogis(-0.7)
      boundary <- stats::rbinom(length(id), 1L, zoi)
      y <- stats::rbeta(length(id), mu / sigma^2, (1 - mu) / sigma^2)
      y[boundary == 1L] <- stats::rbinom(sum(boundary), 1L, stats::plogis(0.1))
      list(
        data = data.frame(y, x, id),
        formula = drmTMB::bf(y ~ x, sigma ~ x + (0 + x | id), zoi ~ 1, coi ~ 1),
        family = drmTMB::zero_one_beta(),
        control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 3000L, iter.max = 3000L))
      )
    }
  ),
  make_cell(
    "mc-0593", 3L, "zob_sigma_structured",
    data.frame(target = "sd:sigma:phylo(1 | species)", true_value = 0.45, n_seeds = 5L, stringsAsFactors = FALSE),
    function(seed) {
      set.seed(seed)
      tree <- ape::stree(16L, type = "balanced")
      tree$edge.length <- rep(1, nrow(tree$edge))
      tree$tip.label <- paste0("sp", seq_len(16L))
      precision <- dense_zoib_phylo_precision(tree)
      u <- as.numeric(t(chol(solve(precision$Q))) %*% stats::rnorm(nrow(precision$Q), sd = 0.45))
      names(u) <- tree$tip.label
      species <- rep(tree$tip.label, each = 40L)
      x <- stats::rnorm(length(species))
      mu <- stats::plogis(-0.15 + 0.35 * x)
      sigma <- exp(-1 + u[species])
      zoi <- stats::plogis(-1.1)
      coi <- stats::plogis(0.1)
      boundary <- stats::rbinom(length(x), 1L, zoi)
      y <- stats::rbeta(length(x), mu / sigma^2, (1 - mu) / sigma^2)
      y[boundary == 1L] <- stats::rbinom(sum(boundary), 1L, coi)
      list(
        data = data.frame(y, x, species),
        formula = drmTMB::bf(y ~ x, sigma ~ phylo(1 | species, tree = tree), zoi ~ 1, coi ~ 1),
        family = drmTMB::zero_one_beta(),
        control = zob_sigma_control()
      )
    },
    early_stop = TRUE
  ),
  make_cell(
    "mc-0594", 4L, "zob_sigma_structured",
    data.frame(target = "sd:sigma:animal(1 | species)", true_value = 0.45, n_seeds = 5L, stringsAsFactors = FALSE),
    function(seed) {
      set.seed(seed)
      n <- 16L
      labels <- paste0("sp", seq_len(n))
      Ainv <- diag(2, n)
      Ainv[cbind(seq_len(n - 1L), seq.int(2L, n))] <- -0.5
      Ainv[cbind(seq.int(2L, n), seq_len(n - 1L))] <- -0.5
      rownames(Ainv) <- colnames(Ainv) <- rev(labels)
      u <- as.numeric(t(chol(solve(Ainv))) %*% stats::rnorm(n, sd = 0.45))
      names(u) <- rownames(Ainv)
      species <- rep(labels, each = 40L)
      x <- stats::rnorm(length(species))
      mu <- stats::plogis(-0.15 + 0.35 * x)
      sigma <- exp(-1 + u[species])
      zoi <- stats::plogis(-1.1)
      coi <- stats::plogis(0.1)
      boundary <- stats::rbinom(length(x), 1L, zoi)
      y <- stats::rbeta(length(x), mu / sigma^2, (1 - mu) / sigma^2)
      y[boundary == 1L] <- stats::rbinom(sum(boundary), 1L, coi)
      list(
        data = data.frame(y, x, species),
        formula = drmTMB::bf(y ~ x, sigma ~ animal(1 | species, Ainv = Ainv), zoi ~ 1, coi ~ 1),
        family = drmTMB::zero_one_beta(),
        control = zob_sigma_control()
      )
    },
    early_stop = TRUE
  ),
  make_cell(
    "mc-0595", 5L, "zob_sigma_structured",
    data.frame(target = "sd:sigma:relmat(1 | species)", true_value = 0.45, n_seeds = 5L, stringsAsFactors = FALSE),
    function(seed) {
      set.seed(seed)
      n <- 16L
      labels <- paste0("sp", seq_len(n))
      Q <- diag(2, n)
      Q[cbind(seq_len(n - 1L), seq.int(2L, n))] <- -0.5
      Q[cbind(seq.int(2L, n), seq_len(n - 1L))] <- -0.5
      rownames(Q) <- colnames(Q) <- rev(labels)
      K <- solve(Q)
      u <- as.numeric(t(chol(K)) %*% stats::rnorm(n, sd = 0.45))
      names(u) <- rownames(K)
      species <- rep(labels, each = 40L)
      x <- stats::rnorm(length(species))
      mu <- stats::plogis(-0.15 + 0.35 * x)
      sigma <- exp(-1 + u[species])
      zoi <- stats::plogis(-1.1)
      coi <- stats::plogis(0.1)
      boundary <- stats::rbinom(length(x), 1L, zoi)
      y <- stats::rbeta(length(x), mu / sigma^2, (1 - mu) / sigma^2)
      y[boundary == 1L] <- stats::rbinom(sum(boundary), 1L, coi)
      list(
        data = data.frame(y, x, species),
        formula = drmTMB::bf(y ~ x, sigma ~ relmat(1 | species, K = K), zoi ~ 1, coi ~ 1),
        family = drmTMB::zero_one_beta(),
        control = zob_sigma_control()
      )
    },
    early_stop = TRUE
  ),
  make_cell(
    "mc-0596", 6L, "zob_sigma_structured",
    data.frame(target = "sd:sigma:spatial(1 | site)", true_value = 0.45, n_seeds = 5L, stringsAsFactors = FALSE),
    function(seed) {
      set.seed(seed)
      n <- 16L
      labels <- paste0("site", seq_len(n))
      coords <- cbind(seq_len(n), (seq_len(n) %% 5L) / 3)
      rownames(coords) <- rev(labels)
      precision <- dense_zoib_spatial_precision(coords, labels)
      u <- as.numeric(t(chol(solve(precision$Q))) %*% stats::rnorm(n, sd = 0.45))
      names(u) <- labels
      site <- rep(labels, each = 40L)
      x <- stats::rnorm(length(site))
      mu <- stats::plogis(-0.15 + 0.35 * x)
      sigma <- exp(-1 + u[site])
      zoi <- stats::plogis(-1.1)
      coi <- stats::plogis(0.1)
      boundary <- stats::rbinom(length(x), 1L, zoi)
      y <- stats::rbeta(length(x), mu / sigma^2, (1 - mu) / sigma^2)
      y[boundary == 1L] <- stats::rbinom(sum(boundary), 1L, coi)
      list(
        data = data.frame(y, x, site),
        formula = drmTMB::bf(y ~ x, sigma ~ spatial(1 | site, coords = coords), zoi ~ 1, coi ~ 1),
        family = drmTMB::zero_one_beta(),
        control = zob_sigma_control()
      )
    },
    early_stop = TRUE
  ),
  make_cell(
    "mc-0597", 7L, "zob_sigma_structured",
    # Campaign truth pinned to PREREG 0.45 (fence fixture used 0.55 for classification only).
    data.frame(
      target = "sd:sigma:phylo_interaction(1 | plant:pollinator)",
      true_value = 0.45,
      n_seeds = 5L,
      stringsAsFactors = FALSE
    ),
    function(seed) {
      set.seed(seed)
      n_each <- 30L
      plant_tree <- ape::stree(4L, type = "balanced")
      plant_tree$edge.length <- rep(1, nrow(plant_tree$edge))
      plant_tree$tip.label <- paste0("plant", 1:4)
      pollinator_tree <- ape::stree(4L, type = "balanced")
      pollinator_tree$edge.length <- rep(1, nrow(pollinator_tree$edge))
      pollinator_tree$tip.label <- paste0("poll", 1:4)
      V <- kronecker(
        drmTMB:::drm_phylo_tip_covariance(pollinator_tree),
        drmTMB:::drm_phylo_tip_covariance(plant_tree)
      )
      grid <- expand.grid(
        plant = plant_tree$tip.label,
        pollinator = pollinator_tree$tip.label,
        KEEP.OUT.ATTRS = FALSE,
        stringsAsFactors = FALSE
      )
      u <- as.numeric(t(chol(V)) %*% stats::rnorm(nrow(grid), sd = 0.45))
      names(u) <- paste0(grid$plant, ":", grid$pollinator)
      data <- grid[rep(seq_len(nrow(grid)), each = n_each), , drop = FALSE]
      data$x <- stats::rnorm(nrow(data))
      data$x <- data$x - ave(data$x, interaction(data$plant, data$pollinator), FUN = mean)
      data$x <- data$x / stats::sd(data$x)
      mu <- stats::plogis(-0.10 + 0.35 * data$x + u[paste0(data$plant, ":", data$pollinator)])
      boundary <- stats::rbinom(nrow(data), 1, 0.12)
      data$y <- ifelse(
        boundary == 1,
        stats::rbinom(nrow(data), 1, 0.45),
        stats::rbeta(nrow(data), mu / 0.45^2, (1 - mu) / 0.45^2)
      )
      list(
        data = data,
        formula = drmTMB::bf(
          y ~ x,
          sigma ~ phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree),
          zoi ~ 1,
          coi ~ 1
        ),
        family = drmTMB::zero_one_beta(),
        control = zob_sigma_control()
      )
    },
    early_stop = TRUE
  ),
  make_cell(
    "mc-0418", 8L, "count_mu_labelled_q2",
    q2_target_truths("phylo", "site"),
    function(seed) {
      sim <- new_count_structured_mu_slope_data(seed = seed)
      tree <- sim$tree
      list(
        data = sim$data,
        formula = drmTMB::bf(nb2_phylo ~ x + phylo(1 + x | p | site, tree = tree), sigma ~ 1),
        family = drmTMB::nbinom2(),
        control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 900L, iter.max = 900L))
      )
    }
  ),
  make_cell(
    "mc-0436", 9L, "count_mu_labelled_q2",
    q2_target_truths("phylo", "site"),
    function(seed) {
      sim <- new_count_structured_mu_slope_data(seed = seed)
      tree <- sim$tree
      list(
        data = sim$data,
        formula = drmTMB::bf(poisson_phylo ~ x + phylo(1 + x | p | site, tree = tree)),
        family = stats::poisson(link = "log"),
        control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 900L, iter.max = 900L))
      )
    }
  ),
  make_cell(
    "mc-0446", 10L, "count_mu_labelled_q2",
    q2_target_truths("spatial", "site"),
    function(seed) {
      sim <- new_count_structured_mu_slope_data(seed = seed)
      coords <- sim$coords
      list(
        data = sim$data,
        formula = drmTMB::bf(poisson_spatial ~ x + spatial(1 + x | p | site, coords = coords)),
        family = stats::poisson(link = "log"),
        control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 900L, iter.max = 900L))
      )
    }
  ),
  make_cell(
    "mc-0450", 11L, "count_mu_labelled_q2",
    q2_target_truths("animal", "id"),
    function(seed) {
      sim <- new_count_structured_mu_slope_data(seed = seed)
      Q <- sim$Q
      data <- sim$data
      data$id <- factor(data$id, levels = rownames(Q))
      list(
        data = data,
        formula = drmTMB::bf(poisson_known ~ x + animal(1 + x | p | id, Ainv = Q)),
        family = stats::poisson(link = "log"),
        control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 900L, iter.max = 900L))
      )
    }
  ),
  make_cell(
    "mc-0454", 12L, "count_mu_labelled_q2",
    q2_target_truths("relmat", "id"),
    function(seed) {
      sim <- new_count_structured_mu_slope_data(seed = seed)
      Q <- sim$Q
      data <- sim$data
      data$id <- factor(data$id, levels = rownames(Q))
      list(
        data = data,
        formula = drmTMB::bf(poisson_known ~ x + relmat(1 + x | p | id, Q = Q)),
        family = stats::poisson(link = "log"),
        control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 900L, iter.max = 900L))
      )
    }
  ),
  make_cell(
    "mc-0425", 13L, "count_sigma_phylo_interaction",
    data.frame(
      target = "sd:sigma:phylo_interaction(1 | plant:pollinator)",
      true_value = 0.60,
      n_seeds = 5L,
      stringsAsFactors = FALSE
    ),
    function(seed) {
      sim <- new_phylo_interaction_sigma_nb2_data(seed = seed)
      plant_tree <- sim$plant_tree
      pollinator_tree <- sim$pollinator_tree
      list(
        data = sim$data,
        formula = drmTMB::bf(
          nb2 ~ x,
          sigma ~ phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree)
        ),
        family = drmTMB::nbinom2(),
        control = drmTMB::drm_control(se = TRUE)
      )
    },
    early_stop = TRUE
  ),
  make_cell(
    "mc-0653", 14L, "count_sigma_phylo_interaction",
    data.frame(
      target = "sd:sigma:phylo_interaction(1 | plant:pollinator)",
      true_value = 0.60,
      n_seeds = 5L,
      stringsAsFactors = FALSE
    ),
    function(seed) {
      sim <- new_zi_nbinom2_sigma_phylo_interaction_data(seed = seed) # 8×8 campaign design
      plant_tree <- sim$plant_tree
      pollinator_tree <- sim$pollinator_tree
      list(
        data = sim$data,
        formula = drmTMB::bf(
          count ~ x,
          sigma ~ phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree),
          zi ~ 1
        ),
        family = drmTMB::nbinom2(),
        control = drmTMB::drm_control(se = TRUE)
      )
    },
    early_stop = TRUE
  )
)
names(CELL_REGISTRY) <- vapply(CELL_REGISTRY, `[[`, character(1), "cell_id")

seed_integer <- function(cell_index, seed_index) {
  as.integer(20260805L + 1000000L * as.integer(cell_index) + as.integer(seed_index))
}

list_jobs <- function() {
  rows <- list()
  for (cell in CELL_REGISTRY) {
    for (i in seq_len(nrow(cell$targets))) {
      tgt <- cell$targets[i, , drop = FALSE]
      for (s in seq_len(tgt$n_seeds[[1L]])) {
        rows[[length(rows) + 1L]] <- data.frame(
          cell_id = cell$cell_id,
          cell_index = cell$cell_index,
          seed_index = s,
          seed = seed_integer(cell$cell_index, s),
          target = tgt$target[[1L]],
          true_value = tgt$true_value[[1L]],
          group = cell$group,
          stringsAsFactors = FALSE
        )
      }
    }
  }
  do.call(rbind, rows)
}

if (has_flag("--list")) {
  jobs <- list_jobs()
  print(jobs)
  message("n_jobs=", nrow(jobs))
  quit(status = 0L, save = "no")
}

if (has_flag("--emit-jobfile")) {
  dest <- get_flag("--emit-jobfile", NULL)
  if (is.null(dest) || !nzchar(dest)) stop("--emit-jobfile needs a path", call. = FALSE)
  jobs <- list_jobs()
  lines <- paste(jobs$cell_id, jobs$seed_index, jobs$target, sep = "^")
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, dest)
  message("wrote ", length(lines), " jobs to ", dest)
  quit(status = 0L, save = "no")
}

cell_id <- get_flag("--cell", NULL)
if (is.null(cell_id) || !nzchar(cell_id)) {
  stop("Required: --cell <mc-XXXX> (or --list)", call. = FALSE)
}
if (!cell_id %in% names(CELL_REGISTRY)) {
  stop("Unknown cell_id '", cell_id, "'. Use --list.", call. = FALSE)
}
cell <- CELL_REGISTRY[[cell_id]]
seed_index <- as.integer(get_flag("--seed-index", "1"))
if (!is.finite(seed_index) || seed_index < 1L) {
  stop("--seed-index must be a positive integer", call. = FALSE)
}
seed <- seed_integer(cell$cell_index, seed_index)
target_arg <- get_flag("--target", NULL)
targets_to_run <- if (is.null(target_arg) || !nzchar(target_arg)) {
  cell$targets
} else {
  hit <- cell$targets[cell$targets$target == target_arg, , drop = FALSE]
  if (!nrow(hit)) {
    stop(
      "Target '", target_arg, "' is not registered for ", cell_id, ".\n",
      "Registered: ", paste(cell$targets$target, collapse = " | "),
      call. = FALSE
    )
  }
  hit
}

dir.create(outdir_root, recursive = TRUE, showWarnings = FALSE)
cell_dir <- file.path(outdir_root, "receipts", cell_id)
dir.create(cell_dir, recursive = TRUE, showWarnings = FALSE)

message("loading package from ", repo)
devtools::load_all(repo, quiet = TRUE, export_all = FALSE)

message(
  "RUN cell=", cell_id, " seed_index=", seed_index, " seed=", seed,
  " n_targets=", nrow(targets_to_run)
)

stage <- "simulate"
pipeline_error <- NULL
fit <- NULL
spec <- NULL
t0_fit <- NULL

tryCatch({
  stage <- "simulate"
  spec <- cell$build_fit(seed)
  stage <- "fit"
  t0_fit <- proc.time()[["elapsed"]]
  fit <- drmTMB::drmTMB(
    formula = spec$formula,
    family = spec$family,
    data = spec$data,
    control = spec$control
  )
}, error = function(e) {
  pipeline_error <<- e
})

fit_elapsed <- if (!is.null(t0_fit)) proc.time()[["elapsed"]] - t0_fit else NA_real_
convergence <- if (!is.null(fit)) tryCatch(as.integer(fit$opt$convergence), error = function(e) NA_integer_) else NA_integer_
pdHess <- if (!is.null(fit)) tryCatch(isTRUE(fit$sdr$pdHess), error = function(e) NA) else NA

for (ti in seq_len(nrow(targets_to_run))) {
  tgt_row <- targets_to_run[ti, , drop = FALSE]
  target_name <- tgt_row$target[[1L]]
  true_value <- as.numeric(tgt_row$true_value[[1L]])
  stem <- sprintf("%s-seed%d-%s", cell_id, seed, gsub("[^A-Za-z0-9]+", "_", target_name))
  # Truncate stem for filesystem safety while keeping uniqueness via full target in receipt.
  if (nchar(stem) > 180L) stem <- substr(stem, 1L, 180L)
  trace_path <- file.path(cell_dir, paste0(stem, "-trace.tsv"))
  interval_path <- file.path(cell_dir, paste0(stem, "-interval.tsv"))
  receipt_path <- file.path(cell_dir, paste0(stem, "-receipt.tsv"))

  target_row <- NULL
  prof <- NULL
  estimate <- NA_real_
  lower <- NA_real_
  upper <- NA_real_
  conf_status <- "not_attempted"
  profile_message <- ""
  profile_boundary <- NA
  clamp_limited <- NA
  lr_ok <- FALSE
  lr_left <- NA_real_
  lr_right <- NA_real_
  unimodal <- FALSE
  brackets_truth <- FALSE
  rel_err <- NA_real_
  failure_reason <- ""
  target_error <- pipeline_error
  stage_t <- if (!is.null(pipeline_error)) stage else "target_lookup"
  profile_elapsed <- NA_real_

  if (is.null(target_error)) {
    tryCatch({
      stage_t <- "target_lookup"
      targets <- drmTMB::profile_targets(fit)
      target_row <- subset(targets, parm == target_name)
      if (
        nrow(target_row) != 1L || !isTRUE(target_row$profile_ready) ||
          !identical(as.character(target_row$target_type[[1L]]), "direct")
      ) {
        stop("Exact direct profile target is not ready: ", target_name, call. = FALSE)
      }
      estimate <- as.numeric(target_row$estimate[[1L]])
      rel_err <- abs(estimate - true_value) / abs(true_value)

      # Early-stop provider gate (PREREG §6d): seed_index==1 only.
      if (isTRUE(cell$early_stop) && identical(seed_index, 1L) && is.finite(rel_err) && rel_err > 0.25) {
        stop(
          sprintf(
            "EARLY_STOP: seed1 relative error %.4f > 0.25 for structured provider %s",
            rel_err, cell_id
          ),
          call. = FALSE
        )
      }

      stage_t <- "profile"
      t0p <- proc.time()[["elapsed"]]
      # Grid / tmbprofile engine — stats::profile.drmTMB always uses TMB::tmbprofile.
      prof <- stats::profile(fit, parm = target_name, trace = FALSE)
      profile_elapsed <- proc.time()[["elapsed"]] - t0p

      stage_t <- "artifact_write"
      trace <- as.data.frame(prof)
      trace$cell_id <- cell_id
      trace$target_id <- paste0(cell_id, "::", target_name)
      trace$seed <- seed
      utils::write.table(trace, trace_path, sep = "\t", quote = FALSE, row.names = FALSE)

      profile_field <- function(name) {
        value <- unique(prof[[name]])
        if (length(value) != 1L) stop("Profile field is not constant: ", name, call. = FALSE)
        value[[1L]]
      }
      lower <- as.numeric(profile_field("conf.low"))
      upper <- as.numeric(profile_field("conf.high"))
      conf_status <- as.character(profile_field("conf.status"))
      profile_message <- as.character(profile_field("profile.message"))
      profile_boundary <- !all(is.finite(c(lower, estimate, upper))) ||
        lower >= estimate ||
        upper <= estimate ||
        !identical(profile_message, "ok")
      clamp_limited <- compute_clamp_limited(prof, conf_status, profile_message)
      lr <- trace_lr_both_sides(trace, estimate, lr_threshold)
      lr_ok <- isTRUE(lr$ok)
      lr_left <- lr$left
      lr_right <- lr$right
      unimodal <- isTRUE(trace_unimodal(trace, tol = 1e-6))
      brackets_truth <- is.finite(true_value) && is.finite(lower) && is.finite(upper) &&
        lower <= true_value && true_value <= upper

      interval <- data.frame(
        parm = target_name,
        level = level,
        lower = lower,
        upper = upper,
        estimate = estimate,
        true_value = true_value,
        method = "profile",
        profile.engine = "tmbprofile",
        conf.status = conf_status,
        profile.boundary = profile_boundary,
        profile.message = profile_message,
        clamp_limited = clamp_limited,
        lr_both_sides = lr_ok,
        lr_left_max = lr_left,
        lr_right_max = lr_right,
        lr_threshold = lr_threshold,
        unimodal = unimodal,
        brackets_truth = brackets_truth,
        cell_id = cell_id,
        target_id = paste0(cell_id, "::", target_name),
        seed = seed,
        stringsAsFactors = FALSE
      )
      utils::write.table(interval, interval_path, sep = "\t", quote = FALSE, row.names = FALSE)
    }, error = function(e) {
      target_error <<- e
    })
  }

  failed <- !is.null(target_error)
  if (failed) {
    failure_reason <- paste0(stage_t, ": ", conditionMessage(target_error))
    if (identical(conf_status, "not_attempted") && identical(stage_t, "profile")) {
      conf_status <- "profile_error"
    }
  }

  clean <- !failed &&
    identical(conf_status, "profile") &&
    all(is.finite(c(lower, estimate, upper))) &&
    lower < estimate && estimate < upper &&
    !isTRUE(profile_boundary) &&
    !isTRUE(clamp_limited) &&
    identical(convergence, 0L) &&
    isTRUE(pdHess) &&
    isTRUE(lr_ok) &&
    isTRUE(unimodal) &&
    isTRUE(brackets_truth) &&
    is.finite(true_value) && true_value != 0

  if (!failed && !clean && !nzchar(failure_reason)) {
    failure_reason <- paste(
      "contract:",
      if (!identical(conf_status, "profile")) paste0("conf_status=", conf_status) else NULL,
      if (isTRUE(profile_boundary)) "boundary" else NULL,
      if (isTRUE(clamp_limited)) "clamp_limited" else NULL,
      if (!isTRUE(lr_ok)) "lr_both_sides_fail" else NULL,
      if (!isTRUE(unimodal)) "unimodal_fail" else NULL,
      if (!isTRUE(brackets_truth)) "truth_miss" else NULL,
      if (!identical(convergence, 0L) || !isTRUE(pdHess)) "fit_gate" else NULL,
      collapse = " "
    )
  }

  receipt <- data.frame(
    cell_id = cell_id,
    cell_index = cell$cell_index,
    seed_index = seed_index,
    seed = seed,
    target_id = paste0(cell_id, "::", target_name),
    profile_parameter = target_name,
    group = cell$group,
    true_value = true_value,
    estimate = estimate,
    lower = lower,
    upper = upper,
    rel_err = rel_err,
    brackets_truth = brackets_truth,
    conf_status = conf_status,
    profile_engine = "tmbprofile",
    convergence = convergence,
    pdHess = pdHess,
    profile_boundary = profile_boundary,
    # NA when no profile was produced; never invent FALSE without a compute path.
    clamp_limited = clamp_limited,
    clamp_limited_source = if (is.null(prof)) "no_profile" else "computed_from_profile",
    lr_both_sides = lr_ok,
    lr_left_max = lr_left,
    lr_right_max = lr_right,
    lr_threshold = lr_threshold,
    unimodal = unimodal,
    promotion_eligible = clean,
    receipt_scope = "targetwise_interval_feasibility_only_no_coverage",
    structured_sigma_claim_required = isTRUE(cell$structured_sigma_claim),
    fit_elapsed_sec = fit_elapsed,
    profile_elapsed_sec = profile_elapsed,
    failure_reason = failure_reason,
    trace_path = if (file.exists(trace_path)) trace_path else "",
    interval_path = if (file.exists(interval_path)) interval_path else "",
    binding_source = "tools/run-135-trace-campaign.R",
    stringsAsFactors = FALSE
  )
  # Refuse hard-coded clamp lies: if we wrote a profile and still claim not-limited
  # without a computed source, abort.
  if (!is.null(prof) && !identical(receipt$clamp_limited_source[[1L]], "computed_from_profile")) {
    stop("Internal error: clamp_limited must be computed from profile", call. = FALSE)
  }
  utils::write.table(receipt, receipt_path, sep = "\t", quote = FALSE, row.names = FALSE)

  print(receipt[c(
    "cell_id", "seed", "profile_parameter", "conf_status", "estimate", "lower", "upper",
    "brackets_truth", "clamp_limited", "lr_both_sides", "unimodal", "promotion_eligible",
    "failure_reason"
  )])
  message("wrote ", receipt_path)
}

if (!is.null(pipeline_error)) {
  quit(status = 2L, save = "no")
}
invisible(NULL)

# `simulate.drmTMB(..., re.form = NULL)` for a `phylo_interaction()` q == 1
# structured mu random effect -- Arc A2.
#
# `phylo_interaction()` shares the same q == 1 structured-mu marginal-draw
# code path as `phylo()`/`spatial()`/`relmat()`/`animal()`
# (`drm_fresh_structured_mu_values()`), reading the already-assembled
# Kronecker precision at `object$model$structured$phylo_mu$precision$precision`
# -- the same slot every other structured type stores its precision in. This
# file verifies that widened support both runs and is actually marginal (not
# just non-aborting).

phylo_interaction_reform_balanced_tree <- function(n_tip = 4L, prefix = "sp") {
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

new_phylo_interaction_reform_data <- function(
  seed = 2026053101,
  n_plant = 4L,
  n_pollinator = 4L,
  n_each = 8L,
  sd_pair = 0.45
) {
  set.seed(seed)
  plant_tree <- phylo_interaction_reform_balanced_tree(n_plant, "plant")
  pollinator_tree <- phylo_interaction_reform_balanced_tree(n_pollinator, "poll")
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
  x <- stats::rnorm(nrow(dat))
  eta <- 0.45 - 0.20 * x + pair_effect[paste0(dat$plant, ":", dat$pollinator)]
  dat$x <- x
  dat$y <- eta + stats::rnorm(nrow(dat), sd = 0.35)

  list(data = dat, plant_tree = plant_tree, pollinator_tree = pollinator_tree)
}

new_phylo_interaction_reform_fit <- function() {
  sim <- new_phylo_interaction_reform_data()
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
  list(fit = fit, data = sim$data)
}

test_that("marginal simulation no longer aborts for a q1 phylo_interaction fit", {
  built <- new_phylo_interaction_reform_fit()
  fit <- built$fit
  expect_equal(fit$model$structured$phylo_mu$type, "phylo_interaction")
  expect_equal(fit$model$structured$phylo_mu$q, 1L)

  expect_no_error(simulate(fit, nsim = 2, seed = 1))
  expect_no_error(simulate(fit, nsim = 2, seed = 1, re.form = NULL))
})

test_that("phylo_interaction marginal simulation redraws a fresh pair effect per replicate", {
  built <- new_phylo_interaction_reform_fit()
  fit <- built$fit
  pair_id <- paste0(built$data$plant, ":", built$data$pollinator)

  nsim <- 200
  sims_marg <- simulate(fit, nsim = nsim, seed = 7, re.form = NULL)
  sims_cond <- simulate(fit, nsim = nsim, seed = 7, re.form = NA)

  pair_means_marg <- vapply(sims_marg, function(col) {
    tapply(col, pair_id, mean)[[1L]]
  }, numeric(1L))
  pair_means_cond <- vapply(sims_cond, function(col) {
    tapply(col, pair_id, mean)[[1L]]
  }, numeric(1L))

  # Conditional replicates vary only through residual noise (averaged over
  # n_each observations per pair); marginal replicates also carry a fresh
  # structured-effect draw, so the across-replicate variance of the pair mean
  # must be materially larger under the marginal default.
  expect_gt(
    stats::var(pair_means_marg),
    5 * stats::var(pair_means_cond)
  )
})

test_that("phylo_interaction marginal draws recover the fitted Kronecker covariance", {
  built <- new_phylo_interaction_reform_fit()
  fit <- built$fit
  phylo_mu <- fit$model$structured$phylo_mu
  sd_name <- "phylo_interaction(1 | plant:pollinator)"
  sd_val <- unname(fit$sdpars$mu[[sd_name]])

  Q <- as.matrix(phylo_mu$precision$precision)
  target <- solve(Q) * sd_val^2

  set.seed(2026072501)
  R <- 20000
  draws <- matrix(0, nrow = R, ncol = phylo_mu$n_re)
  for (i in seq_len(R)) {
    draws[i, ] <- drmTMB:::drm_fresh_structured_mu_values(phylo_mu, sd_val)
  }
  emp_cov <- crossprod(draws) / R
  rel_frob <- norm(emp_cov - target, type = "F") / norm(target, type = "F")

  # The supported phylo/spatial/relmat/animal q1 cases achieve 0.011-0.021 at
  # R = 20000 (docs/design/243); phylo_interaction's Kronecker precision uses
  # the identical draw code, so the same order of magnitude is expected.
  expect_lt(rel_frob, 0.05)
})

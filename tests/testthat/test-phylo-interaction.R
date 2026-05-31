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
    tolerance = 1e-8
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

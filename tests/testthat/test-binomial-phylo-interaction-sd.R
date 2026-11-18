test_phylo_interaction_sd_tree <- function(n_tip, prefix) {
  stopifnot(n_tip >= 2L, log2(n_tip) == floor(log2(n_tip)))
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
    list(edge = edges, edge.length = edge_lengths,
         tip.label = paste0(prefix, seq_len(n_tip)), Nnode = n_tip - 1L),
    class = "phylo"
  )
}

test_that("Bernoulli phylogenetic-interaction SD varies by observed pair", {
  skip_on_cran()
  set.seed(20261027)
  n_plant <- 8L
  n_pollinator <- 8L
  n_each <- 24L
  plant_tree <- test_phylo_interaction_sd_tree(n_plant, "plant_")
  pollinator_tree <- test_phylo_interaction_sd_tree(n_pollinator, "poll_")
  A1 <- drmTMB:::drm_phylo_tip_covariance(plant_tree)
  A2 <- drmTMB:::drm_phylo_tip_covariance(pollinator_tree)
  pair_cov <- kronecker(A2, A1)
  pair_grid <- expand.grid(
    plant = plant_tree$tip.label,
    pollinator = pollinator_tree$tip.label,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  pair_grid$pair <- paste(pair_grid$plant, pair_grid$pollinator, sep = ":")
  z_pair <- as.numeric(scale(stats::rnorm(nrow(pair_grid))))
  alpha <- c(`(Intercept)` = log(0.45), z_pair = 0.45)
  pair_sd <- exp(alpha[[1L]] + alpha[[2L]] * z_pair)
  unit_field <- as.vector(t(chol(pair_cov)) %*% stats::rnorm(nrow(pair_grid)))
  pair_effect <- pair_sd * unit_field
  row <- rep(seq_len(nrow(pair_grid)), each = n_each)
  dat <- pair_grid[row, , drop = FALSE]
  dat$z_pair <- z_pair[row]
  dat$x <- stats::rnorm(nrow(dat))
  eta <- 0.15 + 0.3 * dat$x + pair_effect[row]
  dat$y <- stats::rbinom(nrow(dat), size = 1L, prob = stats::plogis(eta))

  fit <- drmTMB(
    bf(
      y ~ x + phylo_interaction(
        1 | plant:pollinator,
        tree1 = plant_tree,
        tree2 = pollinator_tree
      ),
      sd(pair, level = "phylogenetic_interaction") ~ z_pair
    ),
    family = stats::binomial(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_identical(
    bf(sd(pair, level = "phylogenetic_interaction") ~ z_pair)$entries[[1L]]$dpar,
    "sd_phylo(pair)"
  )
  bad_pair_data <- dat
  bad_pair_data$pair[[1L]] <- "not-the-observed-pair"
  expect_error(
    drmTMB(
      bf(
        y ~ x + phylo_interaction(
          1 | plant:pollinator,
          tree1 = plant_tree,
          tree2 = pollinator_tree
        ),
        sd(pair, level = "phylogenetic_interaction") ~ z_pair
      ),
      family = stats::binomial(),
      data = bad_pair_data,
      control = drm_control(se = FALSE)
    ),
    "identify observed species pairs one-to-one"
  )
  varying_pair_data <- dat
  varying_pair_data$z_pair[[1L]] <- varying_pair_data$z_pair[[1L]] + 1
  expect_error(
    drmTMB(
      bf(
        y ~ x + phylo_interaction(
          1 | plant:pollinator,
          tree1 = plant_tree,
          tree2 = pollinator_tree
        ),
        sd(pair, level = "phylogenetic_interaction") ~ z_pair
      ),
      family = stats::binomial(),
      data = varying_pair_data,
      control = drm_control(se = FALSE)
    ),
    "varies within pair level"
  )

  pair_rows <- dat[!duplicated(dat$pair), , drop = FALSE]
  sd_coef <- coef(fit, "sd_phylo(pair)")
  sd_hat <- predict(fit, dpar = "sd_phylo(pair)")
  expected_sd <- exp(as.vector(stats::model.matrix(~ z_pair, pair_rows) %*% sd_coef))
  expect_equal(fit$opt$convergence, 0L)
  expect_equal(unname(sd_hat), expected_sd, tolerance = 1e-10)
  expect_equal(names(sd_hat), pair_rows$pair)
  expect_named(sd_coef, names(alpha))
  expect_gt(sd_coef[["z_pair"]], 0)
  expect_lt(abs(sd_coef[["z_pair"]] - alpha[["z_pair"]]), 0.35)
})

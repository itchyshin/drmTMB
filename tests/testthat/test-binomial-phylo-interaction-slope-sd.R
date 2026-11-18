test_phylo_interaction_slope_sd_tree <- function(n_tip, prefix) {
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
    list(
      edge = edges,
      edge.length = edge_lengths,
      tip.label = paste0(prefix, seq_len(n_tip)),
      Nnode = n_tip - 1L
    ),
    class = "phylo"
  )
}

test_that("Bernoulli phylogenetic-interaction slopes support predictor-dependent SDs", {
  skip_on_cran()
  set.seed(202610281L)
  n_plant <- 8L
  n_pollinator <- 8L
  n_each <- 24L
  plant_tree <- test_phylo_interaction_slope_sd_tree(n_plant, "plant_")
  pollinator_tree <- test_phylo_interaction_slope_sd_tree(n_pollinator, "poll_")
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
  alpha_sd <- c(`(Intercept)` = log(0.45), z_pair = 0.55)
  pair_sd <- exp(alpha_sd[[1L]] + alpha_sd[[2L]] * z_pair)
  unit_slope <- as.vector(t(chol(pair_cov)) %*% stats::rnorm(nrow(pair_grid)))
  pair_slope <- pair_sd * unit_slope

  pair_index <- rep(seq_len(nrow(pair_grid)), each = n_each)
  x_within_pair <- rep(seq(-1.5, 1.5, length.out = n_each), times = nrow(pair_grid))
  dat <- pair_grid[pair_index, , drop = FALSE]
  dat$pair <- pair_grid$pair[pair_index]
  dat$z_pair <- z_pair[pair_index]
  dat$x <- x_within_pair
  eta <- -0.1 + 0.45 * dat$x + dat$x * pair_slope[pair_index]
  dat$y <- stats::rbinom(nrow(dat), size = 1L, prob = stats::plogis(eta))

  fit <- drmTMB(
    bf(
      y ~ x + phylo_interaction(
        0 + x | plant:pollinator,
        tree1 = plant_tree,
        tree2 = pollinator_tree
      ),
      sd(pair, level = "phylogenetic_interaction") ~ z_pair
    ),
    family = stats::binomial(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  sd_coef <- coef(fit, "sd_phylo(pair)")
  sd_hat <- predict(fit, dpar = "sd_phylo(pair)")
  pair_rows <- dat[!duplicated(dat$pair), , drop = FALSE]
  expected_sd <- exp(as.vector(
    stats::model.matrix(~ z_pair, pair_rows) %*% sd_coef
  ))

  expect_s3_class(fit, "drmTMB")
  expect_true(is_converged(fit))
  expect_named(sd_coef, names(alpha_sd))
  expect_equal(unname(sd_hat), expected_sd, tolerance = 1e-10)
  expect_identical(names(sd_hat), pair_rows$pair)
  expect_gt(sd_coef[["z_pair"]], 0)
  expect_lt(abs(sd_coef[["z_pair"]] - alpha_sd[["z_pair"]]), 0.35)
  expect_identical(
    simulate(fit, nsim = 1L, seed = 202610282L)$sim_1,
    simulate(fit, nsim = 1L, seed = 202610282L)$sim_1
  )

  varying_sd <- dat
  varying_sd$z_pair[[1L]] <- varying_sd$z_pair[[1L]] + 0.5
  expect_error(
    drmTMB(
      bf(
        y ~ x + phylo_interaction(
          0 + x | plant:pollinator,
          tree1 = plant_tree,
          tree2 = pollinator_tree
        ),
        sd(pair, level = "phylogenetic_interaction") ~ z_pair
      ),
      family = stats::binomial(),
      data = varying_sd,
      control = drm_control(se = FALSE)
    ),
    "varies within pair level"
  )
})

test_that("non-logit Bernoulli phylogenetic-interaction slopes recover SDs", {
  skip_on_cran()
  n_plant <- 16L
  n_pollinator <- 16L
  n_each <- 24L
  plant_tree <- test_phylo_interaction_slope_sd_tree(n_plant, "plant_")
  pollinator_tree <- test_phylo_interaction_slope_sd_tree(n_pollinator, "poll_")
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

  for (link in c("probit", "cloglog")) {
    set.seed(if (link == "probit") 202610283L else 202610284L)
    z_pair <- as.numeric(scale(stats::rnorm(nrow(pair_grid))))
    alpha_sd <- c(`(Intercept)` = log(0.45), z_pair = 0.55)
    unit_slope <- as.vector(
      t(chol(pair_cov)) %*% stats::rnorm(nrow(pair_grid))
    )
    pair_slope <- exp(alpha_sd[[1L]] + alpha_sd[[2L]] * z_pair) *
      unit_slope

    pair_index <- rep(seq_len(nrow(pair_grid)), each = n_each)
    x_within_pair <- rep(
      seq(-1.5, 1.5, length.out = n_each), times = nrow(pair_grid)
    )
    dat <- pair_grid[pair_index, , drop = FALSE]
    dat$pair <- pair_grid$pair[pair_index]
    dat$z_pair <- z_pair[pair_index]
    dat$x <- x_within_pair
    eta <- -0.1 + 0.45 * dat$x + dat$x * pair_slope[pair_index]
    dat$y <- stats::rbinom(
      nrow(dat), size = 1L,
      prob = stats::make.link(link)$linkinv(eta)
    )

    fit <- drmTMB(
      bf(
        y ~ x + phylo_interaction(
          0 + x | plant:pollinator,
          tree1 = plant_tree,
          tree2 = pollinator_tree
        ),
        sd(pair, level = "phylogenetic_interaction") ~ z_pair
      ),
      family = stats::binomial(link = link),
      data = dat,
      control = drm_control(se = FALSE)
    )

    sd_coef <- coef(fit, "sd_phylo(pair)")
    sd_hat <- predict(fit, dpar = "sd_phylo(pair)")
    pair_rows <- dat[!duplicated(dat$pair), , drop = FALSE]
    expected_sd <- exp(as.vector(
      stats::model.matrix(~ z_pair, pair_rows) %*% sd_coef
    ))
    expect_true(is_converged(fit), info = link)
    expect_named(sd_coef, names(alpha_sd), info = link)
    expect_equal(unname(sd_hat), expected_sd, tolerance = 1e-10,
                 info = link)
    expect_identical(names(sd_hat), pair_rows$pair, info = link)
    expect_true(sd_coef[["z_pair"]] > 0, info = link)
    expect_true(
      abs(sd_coef[["z_pair"]] - alpha_sd[["z_pair"]]) < 0.35,
      info = paste(link, "estimated SD slope", sd_coef[["z_pair"]])
    )
    expect_identical(
      simulate(fit, nsim = 1L, seed = 202610285L)$sim_1,
      simulate(fit, nsim = 1L, seed = 202610285L)$sim_1,
      info = link
    )
  }
})

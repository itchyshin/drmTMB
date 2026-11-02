binomial_phylo_interaction_bridge_tree <- function(prefix) {
  structure(
    list(
      edge = matrix(c(7L, 5L, 7L, 6L, 5L, 1L, 5L, 2L, 6L, 3L, 6L, 4L),
                    ncol = 2L, byrow = TRUE),
      edge.length = rep(1, 6),
      tip.label = paste0(prefix, 1:4),
      Nnode = 3L
    ),
    class = "phylo"
  )
}

binomial_phylo_interaction_bridge_fixture <- function(
  seed = 20261033L, link = "logit"
) {
  set.seed(seed)
  tree1 <- binomial_phylo_interaction_bridge_tree("h")
  tree2 <- binomial_phylo_interaction_bridge_tree("p")
  pair_grid <- expand.grid(
    host = tree1$tip.label,
    pollinator = tree2$tip.label,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  pair_grid$pair <- paste(pair_grid$host, pair_grid$pollinator, sep = ":")
  pair_grid$z <- rep(c(-1, 1), length.out = nrow(pair_grid))
  n_each <- 12L
  rows <- rep(seq_len(nrow(pair_grid)), each = n_each)
  dat <- pair_grid[rows, , drop = FALSE]
  dat$x <- stats::rnorm(nrow(dat))
  covariance <- kronecker(
    drm_phylo_tip_covariance(tree2),
    drm_phylo_tip_covariance(tree1)
  )
  pair_sd <- exp(-0.2 + 0.5 * pair_grid$z)
  latent <- as.vector(t(chol(covariance)) %*% stats::rnorm(nrow(pair_grid)))
  eta <- -0.2 + 0.25 * dat$x + (pair_sd * latent)[rows]
  dat$y <- stats::rbinom(
    nrow(dat), 1L, stats::binomial(link = link)$linkinv(eta)
  )
  dat <- dat[sample.int(nrow(dat)), , drop = FALSE]
  list(data = dat, tree1 = tree1, tree2 = tree2)
}

binomial_phylo_interaction_bridge_formula <- function(tree1, tree2) {
  bf(
    y ~ x + phylo_interaction(
      1 | host:pollinator,
      tree1 = tree1,
      tree2 = tree2
    ),
    sd(pair, level = "phylogenetic_interaction") ~ z
  )
}

test_that("Julia admits only the matching Binomial interaction SD route", {
  skip_if_not_installed("ape")
  fixture <- binomial_phylo_interaction_bridge_fixture()
  tree1 <- fixture$tree1
  tree2 <- fixture$tree2
  formula <- binomial_phylo_interaction_bridge_formula(
    tree1, tree2
  )
  expect_true(drm_julia_binomial_phylo_interaction_sd_route_admitted(formula))
  expect_true(drm_julia_refuse_binomial_nonlogit_sd(
    formula, stats::binomial(link = "probit")
  ) |> is.null())

  payload <- drm_julia_binomial_phylo_interaction_sd_payload(
    formula, fixture$data, environment()
  )
  expect_identical(payload$kwarg, "K")
  pair_rows <- fixture$data[!duplicated(fixture$data$pair), ]
  tree1_cov <- drm_phylo_tip_covariance(fixture$tree1)
  tree2_cov <- drm_phylo_tip_covariance(fixture$tree2)
  i1 <- match(pair_rows$host, rownames(tree1_cov))
  i2 <- match(pair_rows$pollinator, rownames(tree2_cov))
  expected <- tree1_cov[i1, i1, drop = FALSE] *
    tree2_cov[i2, i2, drop = FALSE]
  dimnames(expected) <- list(pair_rows$pair, pair_rows$pair)
  expect_equal(unname(payload$matrix), unname(expected))
  expect_match(payload$formula[["mu"]], "relmat\\(1 \\| pair\\)")
  expect_identical(names(payload$formula)[[2L]], "sd(pair, relmat)")
  expect_match(payload$formula[[2L]], "sd\\(pair, relmat\\) ~ z")

  bad_pair <- fixture$data
  bad_pair$pair[[1L]] <- "split-pair"
  expect_false(drm_julia_binomial_phylo_interaction_sd_route_admitted(
    formula, data = bad_pair
  ))
  extra_effect <- bf(
    y ~ x + (1 | observer) + phylo_interaction(
      1 | host:pollinator, tree1 = tree1, tree2 = tree2
    ),
    sd(pair, level = "phylogenetic_interaction") ~ z
  )
  expect_false(drm_julia_binomial_phylo_interaction_sd_route_admitted(
    extra_effect
  ))
})

test_that("Julia bridge fits Binomial phylogenetic-interaction SD regression", {
  skip_on_cran()
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  for (link in c("logit", "probit", "cloglog")) {
    fixture <- binomial_phylo_interaction_bridge_fixture(
      seed = 20261033L, link = link
    )
    formula <- binomial_phylo_interaction_bridge_formula(
      fixture$tree1, fixture$tree2
    )
    family <- stats::binomial(link = link)
    fit_julia <- drmTMB(
      formula, family = family, data = fixture$data, engine = "julia"
    )
    fit_tmb <- drmTMB(
      formula, family = family, data = fixture$data, engine = "tmb",
      control = drm_control(se = FALSE)
    )

    expect_equal(fit_julia$opt$convergence, 0L, info = link)
    expect_equal(fit_tmb$opt$convergence, 0L, info = link)
    expect_equal(unname(coef(fit_julia, "sd_phylo(pair)")),
                 unname(coef(fit_tmb, "sd_phylo(pair)")),
                 tolerance = 0.15, info = link)
    expect_equal(as.numeric(logLik(fit_julia)), as.numeric(logLik(fit_tmb)),
                 tolerance = 0.2, info = link)
    pred_julia <- predict(fit_julia, dpar = "sd_phylo(pair)")
    pred_tmb <- predict(fit_tmb, dpar = "sd_phylo(pair)")
    pair_order <- as.vector(outer(
      fixture$tree1$tip.label,
      fixture$tree2$tip.label,
      function(host, pollinator) paste(host, pollinator, sep = ":")
    ))
    julia_pair_names <- sub(
      "^sd_phylo\\(pair\\):", "", names(pred_julia)
    )
    expect_equal(
      unname(pred_julia[match(pair_order, julia_pair_names)]),
      unname(pred_tmb), tolerance = 0.15, info = link
    )
    seed <- 20261034L
    expect_identical(
      simulate(fit_julia, nsim = 1L, seed = seed)$sim_1,
      simulate(fit_julia, nsim = 1L, seed = seed)$sim_1,
      info = link
    )
  }
})

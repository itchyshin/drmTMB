test_that("ou_sensitivity fits BM and a fixed location-side OU grid", {
  skip_if_not_installed("ape")
  set.seed(20260913)
  tree <- ape::rcoal(6)
  data <- data.frame(
    y = rnorm(30),
    x = rnorm(30),
    species = rep(tree$tip.label, each = 5)
  )
  out <- ou_sensitivity(
    bf(y ~ x + phylo(1 | species, tree = tree, model = "ou"), sigma ~ x),
    data = data,
    alpha = c(0.3, 0.7)
  )

  expect_s3_class(out, "drmTMB_ou_sensitivity")
  expect_named(out$fits, c("BM", "alpha_0.3", "alpha_0.7"))
  expect_equal(out$summary$process, c("BM", "OU", "OU"))
  expect_equal(out$summary$alpha, c(NA, 0.3, 0.7))
  expect_true(all(is.finite(out$summary$AIC)))
  expect_true(all(out$summary$convergence == 0))
  expect_true(all(out$summary$pdHess))
  expect_setequal(unique(out$coefficients$dpar), c("mu", "sigma"))
  expect_equal(
    out$fits$alpha_0.3$obj$env$parList()$log_decay_phylo,
    log(0.3 / out$tree_height)
  )
  expect_equal(
    out$fits$alpha_0.7$obj$env$parList()$log_decay_phylo,
    log(0.7 / out$tree_height)
  )
  raw <- ou_sensitivity(
    bf(y ~ x + phylo(1 | species, tree = tree, model = "ou"), sigma ~ x),
    data = data,
    alpha = 0.7,
    alpha_scale = "raw"
  )
  expect_true(is.na(raw$tree_height))
  expect_equal(raw$fits$alpha_0.7$obj$env$parList()$log_decay_phylo, log(0.7))
  expect_equal(raw$fits$BM$model$structured$phylo_mu$model, "bm")
})

test_that("ou_sensitivity refuses shapes outside its fixed-alpha contract", {
  skip_if_not_installed("ape")
  set.seed(20260914)
  tree <- ape::rcoal(5)
  data <- data.frame(
    y = rnorm(20),
    x = rnorm(20),
    z = rnorm(20),
    species = rep(tree$tip.label, each = 4)
  )
  expect_error(
    ou_sensitivity(
      bf(
        y ~ x + phylo(1 | species, tree = tree, model = "ou"),
        sigma ~ z + phylo(1 | species, tree = tree, model = "ou")
      ),
      data = data,
      alpha = 0.7
    ),
    "location-side OU intercept"
  )
  expect_error(
    ou_sensitivity(
      bf(y ~ x + phylo(1 + x | species, tree = tree, model = "ou")),
      data = data,
      alpha = 0.7
    ),
    "location-side OU intercept"
  )
  data_missing <- data
  data_missing$x[[1]] <- NA_real_
  expect_error(
    ou_sensitivity(
      bf(y ~ x + phylo(1 | species, tree = tree, model = "ou")),
      data = data_missing,
      alpha = 0.7
    ),
    "outside the experimental fixed-alpha scope"
  )
  expect_error(
    ou_sensitivity(
      bf(y ~ x + phylo(1 | species, tree = tree, model = "ou")),
      data = data,
      alpha = c(0.7, 0.7)
    ),
    "must not contain duplicate"
  )
})

test_that("root-depth alpha scaling rejects non-ultrametric trees", {
  skip_if_not_installed("ape")
  set.seed(20260915)
  tree <- ape::rtree(5)
  data <- data.frame(y = rnorm(20), species = rep(tree$tip.label, each = 4))
  expect_error(
    ou_sensitivity(
      bf(y ~ phylo(1 | species, tree = tree, model = "ou")),
      data = data,
      alpha = 0.7
    ),
    "ultrametric"
  )
})

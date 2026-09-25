# check_drm() phylo_sd_shared_shift row. See
# docs/design/277-sd-phylo-root-offset-identifiability.md.

shared_shift_tree <- function() {
  # Root children: tip "a" (length 1) and internal node (length 0.5) over b, c.
  ape::read.tree(text = "(a:1,(b:0.5,c:0.5):0.5);")
}

test_that("shared-shift statistic matches its closed form", {
  skip_if_not_installed("ape")
  tree <- shared_shift_tree()
  prec <- drm_phylo_augmented_precision(tree)
  Q <- prec$precision
  # Only the root-child rows of Q have non-zero sums, so 1'Q1 = sum(1 / l_c)
  # over the edges leaving the root: 1 / 1 + 1 / 0.5 = 3.
  expect_equal(sum(Q), 3)

  n <- nrow(Q)
  stat <- phylo_shared_shift_statistic(Q, rep(0.7, n))
  expect_equal(stat$shift, 0.7)
  expect_equal(stat$z, 0.7 * sqrt(3))
  expect_equal(stat$prior_cost, 0.7^2 * 3 / 2)

  # A field with no precision-weighted shared component has z = 0.
  u <- as.numeric(solve(as.matrix(Q), c(1, -1, rep(0, n - 2L))))
  u <- u - sum(Matrix::rowSums(Q) * u) / sum(Q)
  expect_equal(phylo_shared_shift_statistic(Q, u)$z, 0, tolerance = 1e-12)

  expect_null(phylo_shared_shift_statistic(Q, rep(1, n + 1L)))
  expect_null(phylo_shared_shift_statistic(Q, c(NA, rep(1, n - 1L))))
})

shared_shift_fit <- function(sd_formula) {
  set.seed(20260925)
  tree <- ape::rcoal(40)
  tree$tip.label <- paste0("s", seq_len(40))
  dat <- data.frame(
    species = factor(tree$tip.label, levels = tree$tip.label),
    x = stats::rnorm(40)
  )
  dat$y <- 0.4 * dat$x + stats::rnorm(40)
  form <- if (is.null(sd_formula)) {
    bf(y ~ x + phylo(1 | species, tree = tree), sigma = ~ 1)
  } else {
    bf(y ~ x + phylo(1 | species, tree = tree), sigma = ~ 1, sd_formula)
  }
  suppressWarnings(drmTMB(form, data = dat))
}

shifted_row <- function(fit, z_target) {
  Q <- fit$model$structured$phylo_mu$precision$precision
  u <- fit$random_effects$phylo_mu$latent
  base <- phylo_shared_shift_statistic(Q, u)
  # Add the shared shift that moves z_shared to z_target.
  delta <- (z_target - base$z) / sqrt(sum(Q))
  fit$random_effects$phylo_mu$latent <- u + delta
  check <- check_drm(fit)
  list(row = check[check$check == "phylo_sd_shared_shift", ], ok = attr(check, "ok"))
}

test_that("covariate-dependent phylogenetic SD gets a shared-shift row", {
  skip_if_not_installed("ape")
  fit <- shared_shift_fit(sd(species, level = "phylogenetic") ~ x)
  check <- check_drm(fit)
  row <- check[check$check == "phylo_sd_shared_shift", ]
  expect_equal(nrow(row), 1L)
  expect_match(row$value, "z_shared=")
  expect_match(row$value, "mean_shift_range=")
  expect_true(row$status %in% c("ok", "note", "warning"))

  z_reported <- as.numeric(sub(".*z_shared=([^;]+);.*", "\\1", row$value))
  Q <- fit$model$structured$phylo_mu$precision$precision
  z_direct <- phylo_shared_shift_statistic(Q, fit$random_effects$phylo_mu$latent)$z
  expect_equal(z_reported, z_direct, tolerance = 1e-3)
})

test_that("shared-shift thresholds map to ok, note, and warning", {
  skip_if_not_installed("ape")
  fit <- shared_shift_fit(sd(species, level = "phylogenetic") ~ x)

  low <- shifted_row(fit, 0.5)
  expect_identical(low$row$status, "ok")

  mid <- shifted_row(fit, 2.5)
  expect_identical(mid$row$status, "note")
  expect_match(mid$row$message, "277-sd-phylo-root-offset-identifiability")

  high <- shifted_row(fit, -3.5)
  expect_identical(high$row$status, "warning")
  expect_false(high$ok)
})

test_that("bivariate direct-SD models get one row per phylogenetic endpoint", {
  skip_if_not_installed("ape")
  set.seed(20260925)
  tree <- ape::rcoal(40)
  tree$tip.label <- paste0("s", seq_len(40))
  dat <- data.frame(
    species = factor(tree$tip.label, levels = tree$tip.label),
    x = stats::rnorm(40)
  )
  dat$y1 <- 0.4 * dat$x + stats::rnorm(40)
  dat$y2 <- -0.3 * dat$x + stats::rnorm(40)
  fit <- suppressWarnings(drmTMB(
    bf(
      mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
      mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
      sd1(species, level = "phylogenetic") ~ x,
      sd2(species, level = "phylogenetic") ~ x
    ),
    family = biv_gaussian(),
    data = dat
  ))
  rows <- check_drm(fit)
  rows <- rows[rows$check == "phylo_sd_shared_shift", ]
  expect_equal(nrow(rows), 2L)
  expect_match(rows$value[1], "target=mu1")
  expect_match(rows$value[2], "target=mu2")

  # Shift only the mu2 block of the stacked latent field: only its row moves.
  Q <- fit$model$structured$phylo_mu$precision$precision
  n <- nrow(Q)
  u <- fit$random_effects$phylo_mu$latent
  z2 <- phylo_shared_shift_statistic(Q, u[n + seq_len(n)])$z
  u[n + seq_len(n)] <- u[n + seq_len(n)] + (3.5 - z2) / sqrt(sum(Q))
  fit$random_effects$phylo_mu$latent <- u
  shifted <- check_drm(fit)
  shifted <- shifted[shifted$check == "phylo_sd_shared_shift", ]
  expect_identical(shifted$status[1], rows$status[1])
  expect_identical(shifted$status[2], "warning")
})

test_that("constant phylogenetic SD gets no shared-shift row", {
  skip_if_not_installed("ape")
  no_sd_model <- check_drm(shared_shift_fit(NULL))
  expect_false("phylo_sd_shared_shift" %in% no_sd_model$check)

  intercept_only <- check_drm(
    shared_shift_fit(sd(species, level = "phylogenetic") ~ 1)
  )
  expect_false("phylo_sd_shared_shift" %in% intercept_only$check)
})

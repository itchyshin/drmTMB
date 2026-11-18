# G1 review condition C1: group-level SD designs must be full rank and have at
# least as many groups as columns (docs/dev-log/general-sd-regression/
# g1-joint-contract-review-20261101.md section 2).

sd_rank_beta_fixture <- function(groups = 12L, repeats = 4L) {
  id <- factor(rep(seq_len(groups), each = repeats))
  z_group <- seq(-1, 1, length.out = groups)
  data.frame(
    y = stats::qbeta(stats::runif(length(id), 0.1, 0.9), 3, 4),
    id = id,
    x = rep(c(-0.5, 0.5), length.out = length(id)),
    z = z_group[as.integer(id)]
  )
}

sd_rank_phylo_fixture <- function(n_tip, n_each, seed = 20261101L) {
  set.seed(seed)
  tree <- ape::rcoal(n_tip)
  species <- rep(tree$tip.label, each = n_each)
  z_tip <- as.numeric(scale(stats::rnorm(n_tip)))
  names(z_tip) <- tree$tip.label
  data <- data.frame(
    y = stats::qbeta(stats::runif(length(species), 0.1, 0.9), 3, 4),
    x_mu = stats::rnorm(length(species)),
    x_sigma = stats::rnorm(length(species)),
    z_species = unname(z_tip[species]),
    species = species
  )
  list(data = data, tree = tree)
}

test_that("ordinary SD design with collinear predictors names the aliased column", {
  dat <- sd_rank_beta_fixture()
  dat$z2 <- 2 * dat$z
  err <- expect_error(
    drm_build_beta_ls_spec(
      bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ z + z2),
      dat
    ),
    "rank deficient"
  )
  expect_match(conditionMessage(err), "sd(id)", fixed = TRUE)
  expect_match(conditionMessage(err), "z2", fixed = TRUE)
})

test_that("ordinary SD design with more columns than groups is refused", {
  dat <- sd_rank_beta_fixture(groups = 3L, repeats = 6L)
  dat$w <- c(0, 1, 3)[as.integer(dat$id)]
  dat$v <- c(0, 2, 1)[as.integer(dat$id)]
  err <- expect_error(
    drm_build_beta_ls_spec(
      bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ z + w + v),
      dat
    ),
    "more columns than groups"
  )
  expect_match(conditionMessage(err), "sd(id)", fixed = TRUE)
})

test_that("ordinary SD design with as many columns as groups is still accepted", {
  dat <- sd_rank_beta_fixture(groups = 3L, repeats = 6L)
  dat$w <- c(0, 1, 3)[as.integer(dat$id)]
  expect_no_error(
    drm_build_beta_ls_spec(
      bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ z + w),
      dat
    )
  )
})

test_that("structured SD design with collinear predictors names the aliased column", {
  sim <- sd_rank_phylo_fixture(n_tip = 12L, n_each = 3L)
  tree <- sim$tree
  dat <- sim$data
  dat$z_dup <- 3 * dat$z_species
  err <- expect_error(
    drmTMB(
      bf(
        y ~ x_mu + phylo(1 | species, tree = tree),
        sigma ~ x_sigma,
        sd(species, level = "phylogenetic") ~ z_species + z_dup
      ),
      family = beta_family(), data = dat
    ),
    "rank deficient"
  )
  expect_match(conditionMessage(err), "z_dup", fixed = TRUE)
})

test_that("structured SD design with more columns than groups is refused", {
  sim <- sd_rank_phylo_fixture(n_tip = 3L, n_each = 6L)
  tree <- sim$tree
  dat <- sim$data
  sp <- match(dat$species, tree$tip.label)
  dat$w <- c(0, 1, 3)[sp]
  dat$v <- c(0, 2, 1)[sp]
  err <- expect_error(
    drmTMB(
      bf(
        y ~ x_mu + phylo(1 | species, tree = tree),
        sigma ~ x_sigma,
        sd(species, level = "phylogenetic") ~ z_species + w + v
      ),
      family = beta_family(), data = dat
    ),
    "more columns than groups"
  )
  expect_match(conditionMessage(err), "sd_phylo(species)", fixed = TRUE)
})

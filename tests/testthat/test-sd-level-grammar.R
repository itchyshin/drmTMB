# Slice S2: unified `sd(group, level = )` scale grammar.
#
# `sd(group, level = "phylogenetic")` / `sd1(...)` / `sd2(...)` are the
# generic spelling for the phylogenetic direct-SD targets that the legacy
# `sd_phylo()` / `sd_phylo1()` / `sd_phylo2()` spellings already implement.
# `level` must be consumed entirely at parse time: the emitted dpar string is
# byte-identical to the legacy spelling's dpar string, because every
# downstream branch in R/drmTMB.R keys off `startsWith(dpars, "sd_phylo(")`
# (and the `sd_phylo1(`/`sd_phylo2(` siblings).

# Reset the lifecycle per-session deprecation cache so `expect_deprecated()`
# checks below are hermetic regardless of test run order (other test files
# also call the legacy `sd_phylo*()` spellings, which would otherwise have
# already tripped lifecycle's default once-per-session throttle).
reset_lifecycle_deprecation_cache <- function() {
  env <- get("deprecation_env", envir = asNamespace("lifecycle"))
  rm(list = ls(env, all.names = TRUE), envir = env)
}

# A small ultrametric tree, independent of the fixtures in
# test-phylo-gaussian.R so this file can run standalone via test_file().
sdgrammar_balanced_tree <- function(n_tip = 8L) {
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
      tip.label = paste0("sp_", seq_len(n_tip)),
      Nnode = n_tip - 1L
    ),
    class = "phylo"
  )
}

sdgrammar_sd_phylo_fixture <- function(
  seed = 20260901,
  n_tip = 8L,
  n_each = 6L,
  alpha_sd_phylo = c(`(Intercept)` = log(0.55), z_species = 0.60),
  sigma = 0.22
) {
  set.seed(seed)
  tree <- sdgrammar_balanced_tree(n_tip)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_species <- seq(-1, 1, length.out = n_tip)
  tau <- exp(
    alpha_sd_phylo[["(Intercept)"]] +
      alpha_sd_phylo[["z_species"]] * z_species
  )
  names(tau) <- tree$tip.label
  base_phylo <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip))
  names(base_phylo) <- tree$tip.label
  phylo_effect <- tau * base_phylo

  species <- rep(tree$tip.label, each = n_each)
  x <- stats::rnorm(length(species))
  beta_mu <- c(`(Intercept)` = 0.4, x = -0.25)
  y <- beta_mu[[1L]] +
    beta_mu[[2L]] * x +
    phylo_effect[species] +
    stats::rnorm(length(species), sd = sigma)

  list(
    data = data.frame(
      y = unname(y),
      x = x,
      species = species,
      z_species = z_species[match(species, tree$tip.label)]
    ),
    tree = tree
  )
}

# --- Parser equivalence -----------------------------------------------------

test_that("sd(group, level = 'phylogenetic') parses to the sd_phylo() dpar string", {
  f_new <- bf(sd(sp, level = "phylogenetic") ~ z)
  f_old <- suppressWarnings(bf(sd_phylo(sp) ~ z))

  expect_equal(f_new$entries[[1L]]$dpar, "sd_phylo(sp)")
  expect_equal(f_new$entries[[1L]]$dpar, f_old$entries[[1L]]$dpar)
})

test_that("sd1()/sd2() with level = 'phylogenetic' map to sd_phylo1()/sd_phylo2()", {
  f1_new <- bf(sd1(sp, level = "phylogenetic") ~ z)
  f1_old <- suppressWarnings(bf(sd_phylo1(sp) ~ z))
  f2_new <- bf(sd2(sp, level = "phylogenetic") ~ z)
  f2_old <- suppressWarnings(bf(sd_phylo2(sp) ~ z))

  expect_equal(f1_new$entries[[1L]]$dpar, "sd_phylo1(sp)")
  expect_equal(f1_new$entries[[1L]]$dpar, f1_old$entries[[1L]]$dpar)
  expect_equal(f2_new$entries[[1L]]$dpar, "sd_phylo2(sp)")
  expect_equal(f2_new$entries[[1L]]$dpar, f2_old$entries[[1L]]$dpar)
})

test_that("sd(group) without level still parses to the ordinary sd() dpar string", {
  f <- bf(sd(id) ~ x_group)
  expect_equal(f$entries[[1L]]$dpar, "sd(id)")
})

# --- Error cases -------------------------------------------------------------

test_that("an unsupported level value aborts", {
  expect_error(bf(sd(id, level = "bogus") ~ x), "level")
})

test_that("level = on an already sd_phylo* spelling aborts as redundant", {
  expect_error(
    bf(sd_phylo(sp, level = "phylogenetic") ~ x),
    "cannot be combined"
  )
  expect_error(
    bf(sd_phylo1(sp, level = "phylogenetic") ~ x),
    "cannot be combined"
  )
  expect_error(
    bf(sd_phylo2(sp, level = "phylogenetic") ~ x),
    "cannot be combined"
  )
})

test_that("reserved levels abort as not-yet-implemented, not as unsupported values", {
  expect_error(
    bf(sd(id, level = "spatial") ~ x),
    "planned but not implemented"
  )
  expect_error(
    bf(sd(id, level = "animal") ~ x),
    "planned but not implemented"
  )
  expect_error(
    bf(sd(id, level = "relmat") ~ x),
    "planned but not implemented"
  )
})

# --- Deprecation --------------------------------------------------------------

test_that("the legacy sd_phylo() spelling fires a one-time deprecation warning", {
  reset_lifecycle_deprecation_cache()
  lifecycle::expect_deprecated(bf(sd_phylo(sp) ~ z), "sd_phylo")
  # Throttled: a second parse in the same session does not warn again.
  expect_no_warning(bf(sd_phylo(sp) ~ z))
})

test_that("the legacy sd_phylo1()/sd_phylo2() spellings fire a one-time deprecation warning", {
  reset_lifecycle_deprecation_cache()
  lifecycle::expect_deprecated(bf(sd_phylo1(sp) ~ z), "sd_phylo1")
  lifecycle::expect_deprecated(bf(sd_phylo2(sp) ~ z), "sd_phylo2")
})

test_that("the new sd(level = ) spelling never fires the legacy deprecation", {
  reset_lifecycle_deprecation_cache()
  expect_no_warning(bf(sd(sp, level = "phylogenetic") ~ z))
})

# --- End-to-end equivalence --------------------------------------------------

test_that("sd(species, level = 'phylogenetic') fits identically to sd_phylo(species)", {
  fx <- sdgrammar_sd_phylo_fixture()
  dat <- fx$data
  tree <- fx$tree

  fit_new <- drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree),
      sigma ~ 1,
      sd(species, level = "phylogenetic") ~ z_species
    ),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 1000, iter.max = 1000)
  )
  fit_old <- suppressWarnings(drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree),
      sigma ~ 1,
      sd_phylo(species) ~ z_species
    ),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 1000, iter.max = 1000)
  ))

  expect_equal(fit_new$opt$convergence, 0)
  expect_equal(fit_old$opt$convergence, 0)

  s_new <- summary(fit_new)
  s_old <- summary(fit_old)
  s_new$call <- NULL
  s_old$call <- NULL
  expect_equal(s_new, s_old)

  expect_equal(rownames(vcov(fit_new)), rownames(vcov(fit_old)))
  expect_equal(colnames(vcov(fit_new)), colnames(vcov(fit_old)))
  expect_equal(as.matrix(vcov(fit_new)), as.matrix(vcov(fit_old)))

  expect_equal(coef(fit_new, "mu"), coef(fit_old, "mu"))
  expect_equal(
    coef(fit_new, "sd_phylo(species)"),
    coef(fit_old, "sd_phylo(species)")
  )
})

test_that("REML admits sd(level = 'phylogenetic') identically to sd_phylo() (rung 2)", {
  # On this branch (drmtmb/biv-scale-side-reml) the phylogenetic direct-SD scale
  # `sd_phylo(...) ~ predictors` IS admitted under REML (rung 2, v0.2.0). The
  # regression tripwire: the new generic spelling reaches the REML path and fits
  # BYTE-IDENTICALLY to the legacy spelling -- canonicalization is transparent
  # through REML too, not just ML.
  fx <- sdgrammar_sd_phylo_fixture(seed = 20260902)
  dat <- fx$data
  tree <- fx$tree

  fit_new <- drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree),
      sigma ~ 1,
      sd(species, level = "phylogenetic") ~ z_species
    ),
    family = gaussian(),
    data = dat,
    REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  )
  fit_old <- suppressWarnings(drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree),
      sigma ~ 1,
      sd_phylo(species) ~ z_species
    ),
    family = gaussian(),
    data = dat,
    REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  ))

  expect_equal(fit_new$estimator, "REML")
  expect_equal(fit_new$opt$convergence, 0)
  expect_equal(fit_old$opt$convergence, 0)

  s_new <- summary(fit_new)
  s_old <- summary(fit_old)
  s_new$call <- NULL
  s_old$call <- NULL
  expect_equal(s_new, s_old)
  expect_equal(as.matrix(vcov(fit_new)), as.matrix(vcov(fit_old)))
})

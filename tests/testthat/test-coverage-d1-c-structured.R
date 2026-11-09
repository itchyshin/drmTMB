# Phylogenetic and two-provider group-SD ADREPORT bodies, plus the bivariate
# phylogenetic PC prior. The penalty check is the hand sum
# rate * sd - log(sd) - log(rate) over the phylogenetic SDs, with
# rate = -log(sd_alpha) / sd_u.

d1_group_sd_control <- function() {
  drm_control(
    se_group_sd = TRUE,
    se_report_covariance = FALSE,
    optimizer = list(eval.max = 400L, iter.max = 400L)
  )
}

d1_balanced_tree <- function(n_tip = 4L) {
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
      tip.label = paste0("sp", seq_len(n_tip)),
      Nnode = n_tip - 1L
    ),
    class = "phylo"
  )
}

d1_phylo_frame <- function(seed, n_each = 6L) {
  set.seed(seed)
  tree <- d1_balanced_tree()
  species <- rep(tree$tip.label, each = n_each)
  list(
    tree = tree,
    data = data.frame(
      species = species,
      x = seq(-1, 1, length.out = length(species)),
      z = rep(seq(-0.4, 0.4, length.out = 4L), each = n_each)
    )
  )
}

d1_expect_group_sd <- function(fit, log_name, sd_name, eta) {
  report <- fit$obj$report()
  log_eta <- as.numeric(report[[log_name]])
  sd_hat <- as.numeric(report[[sd_name]])
  transformed <- drmTMB:::drm_exp_sd_logscale_guarded(
    drmTMB:::drm_softclamp_log_sd(log_eta, fit$model$tmb_data)
  )
  expect_equal(fit$opt$convergence, 0L)
  expect_equal(log_eta, as.numeric(eta), tolerance = 1e-12)
  expect_equal(sd_hat, transformed, tolerance = 1e-12)
  expect_true(all(is.finite(sd_hat) & sd_hat > 0))

  nm <- names(fit$sdr$value)
  log_sdr <- as.numeric(fit$sdr$value[nm == log_name])
  sd_sdr <- as.numeric(fit$sdr$value[nm == sd_name])
  expect_equal(length(log_sdr), length(log_eta))
  expect_equal(length(sd_sdr), length(sd_hat))
  expect_equal(
    sd_sdr,
    drmTMB:::drm_exp_sd_logscale_guarded(
      drmTMB:::drm_softclamp_log_sd(log_sdr, fit$model$tmb_data)
    ),
    tolerance = 1e-12
  )
}

d1_expect_phylo <- function(fit) {
  eta <- drmTMB:::sd_phylo_group_log_values(
    list(beta_sd_mu = as.numeric(fit$obj$report()$beta_sd_mu)),
    fit$model
  )
  d1_expect_group_sd(fit, "log_sd_phylo_group", "sd_phylo_group", eta)
}

test_that("beta phylogenetic group-SD ADREPORT matches the R log-SD transform", {
  built <- d1_phylo_frame(21L)
  dat <- built$data
  tree <- built$tree
  dat$y <- plogis(0.2 + 0.3 * dat$x)
  fit <- drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree),
      sigma ~ 1,
      sd(species, level = "phylogenetic") ~ z
    ),
    family = beta_family(),
    data = dat,
    control = d1_group_sd_control()
  )
  d1_expect_phylo(fit)
})

test_that("gamma phylogenetic group-SD ADREPORT matches the R log-SD transform", {
  built <- d1_phylo_frame(22L)
  dat <- built$data
  tree <- built$tree
  dat$y <- rgamma(nrow(dat), shape = 3, scale = 1)
  fit <- drmTMB(
    bf(
      y ~ 1 + phylo(1 | species, tree = tree),
      sigma ~ 1,
      sd(species, level = "phylogenetic") ~ z
    ),
    family = Gamma(link = "log"),
    data = dat,
    control = d1_group_sd_control()
  )
  d1_expect_phylo(fit)
})

test_that("binomial phylogenetic group-SD ADREPORT matches the R log-SD transform", {
  built <- d1_phylo_frame(23L)
  dat <- built$data
  tree <- built$tree
  dat$y <- rbinom(nrow(dat), 1L, 0.5)
  fit <- drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree),
      sd(species, level = "phylogenetic") ~ z
    ),
    family = binomial(),
    data = dat,
    control = d1_group_sd_control()
  )
  d1_expect_phylo(fit)
})

test_that("binomial phylo-plus-spatial group SDs match the R log-SD transforms", {
  built <- d1_phylo_frame(24L, n_each = 4L)
  dat <- built$data
  tree <- built$tree
  dat$y <- rep(c(0L, 1L, 0L, 1L), times = 4L)
  coords <- data.frame(x = c(0, 1, 0, 1), y = c(0, 0, 1, 1))
  rownames(coords) <- tree$tip.label
  fit <- drmTMB(
    bf(
      y ~ 1 +
        phylo(1 | species, tree = tree) +
        spatial(1 | species, coords = coords),
      sd(species, level = "phylogenetic") ~ 1,
      sd(species, level = "spatial") ~ 1
    ),
    family = binomial(),
    data = dat,
    control = d1_group_sd_control()
  )
  d1_expect_phylo(fit)
  eta2 <- drmTMB:::sd_phylo2_group_log_values(
    list(beta_sd_mu = as.numeric(fit$obj$report()$beta_sd_mu)),
    fit$model
  )
  d1_expect_group_sd(fit, "log_sd_phylo2_group", "sd_phylo2_group", eta2)
})

test_that("bivariate phylogenetic PC penalty equals the hand sum of the SD prior", {
  built <- d1_phylo_frame(25L)
  dat <- built$data
  tree <- built$tree
  dat$y1 <- 0.2 * dat$x + rnorm(nrow(dat), sd = 0.3)
  dat$y2 <- -0.1 * dat$x + rnorm(nrow(dat), sd = 0.3)
  fit <- drmTMB(
    bf(
      mu1 = y1 ~ 1 + phylo(1 | species, tree = tree),
      mu2 = y2 ~ 1 + phylo(1 | species, tree = tree),
      sigma1 ~ 1,
      sigma2 ~ 1,
      rho12 ~ 1
    ),
    family = biv_gaussian(),
    data = dat,
    penalty = drm_phylo_penalty(sd_u = 1, sd_alpha = 0.05),
    control = d1_group_sd_control()
  )
  sd <- as.numeric(fit$obj$report()$sd_phylo)
  rate <- -log(0.05) / 1
  hand <- sum(rate * sd - log(sd) - log(rate))
  expect_equal(fit$opt$convergence, 0L)
  expect_equal(fit$estimator, "MAP")
  expect_equal(length(sd), 2L)
  expect_true(all(is.finite(sd) & sd > 0))
  expect_equal(as.numeric(fit$obj$report()$phylo_penalty), hand, tolerance = 1e-10)
})

test_that("bivariate phylogenetic group-SD ADREPORT matches the R log-SD transform", {
  built <- d1_phylo_frame(26L)
  dat <- built$data
  tree <- built$tree
  dat$y1 <- rnorm(nrow(dat))
  dat$y2 <- rnorm(nrow(dat))
  fit <- drmTMB(
    bf(
      mu1 = y1 ~ 1 + phylo(1 | species, tree = tree),
      mu2 = y2 ~ 1 + phylo(1 | species, tree = tree),
      sigma1 ~ 1,
      sigma2 ~ 1,
      rho12 ~ 1,
      sd1(species, level = "phylogenetic") ~ 1,
      sd2(species, level = "phylogenetic") ~ 1
    ),
    family = biv_gaussian(),
    data = dat,
    control = d1_group_sd_control()
  )
  log_eta <- as.numeric(fit$obj$report()$log_sd_phylo_group)
  # Intercept-only sd1() and sd2() formulas: one log SD per response, repeated
  # across the four tips. sd_phylo_group_log_values() does not index this
  # bivariate coefficient vector, so the design check is the repeated value.
  expect_equal(length(log_eta), 8L)
  expect_equal(log_eta[seq_len(4L)], rep(log_eta[[1L]], 4L), tolerance = 1e-12)
  expect_equal(log_eta[5:8], rep(log_eta[[5L]], 4L), tolerance = 1e-12)
  d1_expect_group_sd(fit, "log_sd_phylo_group", "sd_phylo_group", log_eta)
})

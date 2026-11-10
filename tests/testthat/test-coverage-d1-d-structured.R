# Tweedie phylogenetic SDs and the gamma sigma group-SD ADREPORT.
# A Tweedie model with `phylo()` and no `sd()` formula reports one constant
# phylogenetic SD as `exp(log_sd_phylo)`. A direct `sd()` formula reports the
# soft-clamped group transform instead.

d1_group_sd_control <- function() {
  drm_control(
    se_group_sd = TRUE,
    se_report_covariance = FALSE,
    optimizer = list(eval.max = 400L, iter.max = 400L)
  )
}

# Fixed 4-tip tree and counts. A random coalescent tree makes this Tweedie
# fit either singular or slow; this draw converges with both the constant
# phylogenetic SD and the direct sd() formula.
d1_tweedie_phylo <- function() {
  tree <- structure(
    list(
      edge = cbind(
        c(5L, 5L, 6L, 6L, 7L, 7L),
        c(1L, 6L, 2L, 7L, 3L, 4L)
      ),
      edge.length = c(
        0.665451291927552, 0.145706726703793, 0.51974456522376,
        0.393880926369035, 0.125863638854724, 0.125863638854724
      ),
      tip.label = c("sp2", "sp3", "sp1", "sp4"),
      Nnode = 3L
    ),
    class = "phylo"
  )
  list(
    tree = tree,
    data = data.frame(
      species = rep(tree$tip.label, each = 6L),
      y = c(
        4L, 7L, 5L, 6L, 11L, 4L, 7L, 9L, 3L, 6L, 3L, 4L,
        4L, 1L, 4L, 8L, 4L, 5L, 5L, 5L, 3L, 7L, 6L, 7L
      )
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

test_that("Tweedie constant phylogenetic SD is exp of its log SD", {
  built <- d1_tweedie_phylo()
  tree <- built$tree
  fit <- drmTMB(
    bf(y ~ 1 + phylo(1 | species, tree = tree)),
    family = tweedie(),
    data = built$data,
    control = d1_group_sd_control()
  )
  report <- fit$obj$report()
  log_eta <- as.numeric(report$log_sd_phylo)
  sd_hat <- as.numeric(report$sd_phylo)
  expect_equal(fit$opt$convergence, 0L)
  expect_equal(sd_hat, exp(log_eta), tolerance = 1e-12)
  expect_true(all(is.finite(sd_hat) & sd_hat > 0))
  nm <- names(fit$sdr$value)
  expect_equal(
    as.numeric(fit$sdr$value[nm == "sd_phylo"]),
    exp(as.numeric(fit$sdr$value[nm == "log_sd_phylo"])),
    tolerance = 1e-12
  )
})

test_that("Tweedie phylogenetic group-SD ADREPORT matches the R log-SD transform", {
  built <- d1_tweedie_phylo()
  tree <- built$tree
  fit <- drmTMB(
    bf(
      y ~ 1 + phylo(1 | species, tree = tree),
      sd(species, level = "phylogenetic") ~ 1
    ),
    family = tweedie(),
    data = built$data,
    control = d1_group_sd_control()
  )
  eta <- drmTMB:::sd_phylo_group_log_values(
    list(beta_sd_mu = as.numeric(fit$obj$report()$beta_sd_mu)),
    fit$model
  )
  d1_expect_group_sd(fit, "log_sd_phylo_group", "sd_phylo_group", eta)
})

test_that("gamma sigma group-SD ADREPORT matches the R log-SD transform", {
  set.seed(33L)
  id <- factor(rep(paste0("g", seq_len(4L)), each = 6L))
  dat <- data.frame(
    id = id,
    z = rep(seq(-0.4, 0.4, length.out = 4L), each = 6L),
    y = rgamma(length(id), shape = 3, scale = 1)
  )
  fit <- drmTMB(
    bf(y ~ 1, sigma ~ 1 + (1 | id), sd(id, dpar = "sigma") ~ z),
    family = Gamma(link = "log"),
    data = dat,
    control = d1_group_sd_control()
  )
  eta <- drmTMB:::sd_sigma_group_log_values(
    list(beta_sd_sigma = as.numeric(fit$obj$report()$beta_sd_sigma)),
    fit$model
  )
  d1_expect_group_sd(fit, "log_sd_sigma_group", "sd_sigma_group", eta)
})

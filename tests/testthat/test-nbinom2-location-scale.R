new_nbinom2_data <- function(n = 1200, seed = 20260602) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  beta_mu <- c(`(Intercept)` = 0.35, x = -0.40)
  beta_sigma <- c(`(Intercept)` = -0.65, z = 0.30)
  mu <- exp(beta_mu[[1L]] + beta_mu[[2L]] * dat$x)
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  dat$count <- stats::rnbinom(n, size = 1 / sigma^2, mu = mu)
  list(data = dat, beta_mu = beta_mu, beta_sigma = beta_sigma)
}

new_nbinom2_random_effect_data <- function(
  n_id = 44,
  n_each = 10,
  seed = 20260628,
  sd_id = 0.45,
  sd_x = 0.30
) {
  set.seed(seed)
  n <- n_id * n_each
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  beta_mu <- c(`(Intercept)` = 0.35, x = -0.25)
  beta_sigma <- c(`(Intercept)` = -0.70, z = 0.20)
  u_id <- stats::rnorm(n_id, sd = sd_id)
  u_x <- stats::rnorm(n_id, sd = sd_x)
  eta_mu <- beta_mu[[1L]] +
    beta_mu[[2L]] * dat$x +
    u_id[dat$id] +
    u_x[dat$id] * dat$x
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  dat$count <- stats::rnbinom(n, size = 1 / sigma^2, mu = exp(eta_mu))
  list(
    data = dat,
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    sd_id = sd_id,
    sd_x = sd_x,
    u_id = u_id,
    u_x = u_x
  )
}

new_nbinom2_sigma_random_intercept_data <- function(
  n_id = 42,
  n_each = 20,
  seed = 20260642,
  sd_sigma_id = 0.42
) {
  set.seed(seed)
  n <- n_id * n_each
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  beta_mu <- c(`(Intercept)` = 0.50, x = -0.18)
  beta_sigma <- c(`(Intercept)` = -0.85, z = 0.16)
  a_sigma <- stats::rnorm(n_id, sd = sd_sigma_id)
  eta_mu <- beta_mu[[1L]] + beta_mu[[2L]] * dat$x
  eta_sigma <- beta_sigma[[1L]] +
    beta_sigma[[2L]] * dat$z +
    a_sigma[dat$id]
  sigma <- exp(eta_sigma)
  dat$count <- stats::rnbinom(n, size = 1 / sigma^2, mu = exp(eta_mu))
  list(
    data = dat,
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    sd_sigma_id = sd_sigma_id,
    a_sigma = a_sigma
  )
}

nbinom2_balanced_ultrametric_tree <- function(n_tip = 8L) {
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

new_nbinom2_phylo_intercept_data <- function(
  n_tip = 8L,
  n_each = 24L,
  seed = 20260641,
  sd_phylo = 0.45
) {
  set.seed(seed)
  tree <- nbinom2_balanced_ultrametric_tree(n_tip)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  phylo_effect <- as.vector(
    t(chol(A)) %*% stats::rnorm(n_tip, sd = sd_phylo)
  )
  names(phylo_effect) <- tree$tip.label
  species <- rep(tree$tip.label, each = n_each)
  x <- stats::rnorm(length(species))
  z <- stats::rnorm(length(species))
  beta_mu <- c(`(Intercept)` = 0.55, x = -0.25)
  beta_sigma <- c(`(Intercept)` = -0.85, z = 0.15)
  eta_mu <- beta_mu[[1L]] + beta_mu[[2L]] * x + phylo_effect[species]
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * z)
  data <- data.frame(
    count = stats::rnbinom(
      length(species),
      size = 1 / sigma^2,
      mu = exp(eta_mu)
    ),
    x = x,
    z = z,
    species = species
  )
  list(
    data = data,
    tree = tree,
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    sd_phylo = sd_phylo,
    phylo_effect = phylo_effect
  )
}

test_that("drmTMB fits fixed-effect nbinom2 mean-dispersion models", {
  sim <- new_nbinom2_data()

  fit <- drmTMB(
    bf(count ~ x, sigma ~ z),
    family = nbinom2(),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "nbinom2")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$df, length(unlist(coef(fit), use.names = FALSE)))
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.12)
  expect_lt(max(abs(coef(fit, "sigma") - sim$beta_sigma)), 0.18)
  expect_true(all(predict(fit, dpar = "mu") > 0))
  expect_true(all(sigma(fit) > 0))
  expect_equal(
    predict(fit, dpar = "mu"),
    exp(predict(fit, dpar = "mu", type = "link")),
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, dpar = "sigma"),
    exp(predict(fit, dpar = "sigma", type = "link")),
    tolerance = 1e-12
  )
  expect_equal(fitted(fit), predict(fit, dpar = "mu"), tolerance = 1e-12)

  ci <- confint(fit)
  expect_equal(
    ci$parm,
    c(
      "fixef:mu:(Intercept)",
      "fixef:mu:x",
      "fixef:sigma:(Intercept)",
      "fixef:sigma:z"
    )
  )
  expect_equal(
    ci$tmb_parameter,
    c("beta_mu", "beta_mu", "beta_sigma", "beta_sigma")
  )
  expect_true(all(ci$conf.status == "wald"))
})

test_that("nbinom2 mu supports ordinary random intercepts and slopes", {
  sim <- new_nbinom2_random_effect_data()

  fit <- drmTMB(
    bf(count ~ x + (1 | id) + (0 + x | id), sigma ~ z),
    family = nbinom2(),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "nbinom2")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$random$mu$n_terms, 2L)
  expect_equal(fit$model$random$mu$labels, c("(1 | id)", "(0 + x | id)"))
  expect_named(fit$sdpars$mu, c("(1 | id)", "(0 + x | id)"))
  expect_gt(unname(fit$sdpars$mu[["(1 | id)"]]), 0.05)
  expect_gt(unname(fit$sdpars$mu[["(0 + x | id)"]]), 0.05)
  expect_lt(abs(unname(fit$sdpars$mu[["(1 | id)"]]) - sim$sd_id), 0.30)
  expect_lt(abs(unname(fit$sdpars$mu[["(0 + x | id)"]]) - sim$sd_x), 0.30)
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.25)
  expect_lt(max(abs(coef(fit, "sigma") - sim$beta_sigma)), 0.25)

  id_effects <- fit$random_effects$mu$terms[["(1 | id)"]]
  slope_effects <- fit$random_effects$mu$terms[["(0 + x | id)"]]
  expect_equal(length(id_effects), length(sim$u_id))
  expect_equal(length(slope_effects), length(sim$u_x))
  expect_gt(stats::cor(id_effects, sim$u_id), 0.35)
  expect_gt(stats::cor(slope_effects, sim$u_x), 0.25)
  expect_equal(
    predict(fit, dpar = "mu"),
    fit$obj$report()$mu,
    tolerance = 1e-3
  )
  fixed_mu <- exp(as.vector(fit$model$X$mu %*% coef(fit, "mu")))
  expect_gt(max(abs(predict(fit, dpar = "mu") - fixed_mu)), 0.05)
  expect_true(drmTMB:::has_ordinary_mu_random_effects(fit))
  expect_equal(drmTMB:::n_mu_random_effect_terms(fit), 2L)

  targets <- profile_targets(fit)
  sd_targets <- targets[
    targets$parm %in% c("sd:mu:(1 | id)", "sd:mu:(0 + x | id)"),
  ]
  sd_targets <- sd_targets[
    match(
      c("sd:mu:(1 | id)", "sd:mu:(0 + x | id)"),
      sd_targets$parm
    ),
  ]
  expect_equal(
    sd_targets$parm,
    c(
      "sd:mu:(1 | id)",
      "sd:mu:(0 + x | id)"
    )
  )
  expect_true(all(sd_targets$profile_ready))
  expect_equal(sd_targets$tmb_parameter, c("log_sd_mu", "log_sd_mu"))

  expect_true(all(predict(fit, dpar = "mu") > 0))
  expect_equal(fitted(fit), predict(fit, dpar = "mu"), tolerance = 1e-12)
})

test_that("nbinom2 sigma supports ordinary random intercepts", {
  sim <- new_nbinom2_sigma_random_intercept_data()
  dat <- sim$data

  fit <- drmTMB(
    bf(count ~ x, sigma ~ z + (1 | id)),
    family = nbinom2(),
    data = dat,
    control = list(eval.max = 600, iter.max = 600)
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "nbinom2")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$random$sigma$n_terms, 1L)
  expect_named(fit$sdpars$sigma, "(1 | id)")
  expect_gt(unname(fit$sdpars$sigma), 0.05)
  expect_lt(abs(unname(fit$sdpars$sigma) - sim$sd_sigma_id), 0.35)
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.25)
  expect_lt(max(abs(coef(fit, "sigma") - sim$beta_sigma)), 0.35)

  sigma_effects <- fit$random_effects$sigma$terms[["(1 | id)"]]
  expect_equal(length(sigma_effects), length(sim$a_sigma))
  expect_gt(stats::cor(sigma_effects, sim$a_sigma), 0.30)

  fixed_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  sigma_link <- predict(fit, dpar = "sigma", type = "link")
  contribution <- drmTMB:::sigma_random_effect_contribution(fit)
  expect_equal(sigma_link, fixed_sigma + contribution, tolerance = 1e-10)
  expect_equal(sigma(fit), exp(sigma_link), tolerance = 1e-10)
  expect_equal(predict(fit, dpar = "sigma"), fit$obj$report()$sigma,
    tolerance = 1e-3
  )

  targets <- profile_targets(fit)
  sd_target <- targets[targets$parm == "sd:sigma:(1 | id)", ]
  expect_equal(sd_target$tmb_parameter, "log_sd_sigma")
  expect_equal(sd_target$target_type, "direct")
  expect_true(sd_target$profile_ready)

  chk <- check_drm(fit)
  sigma_sd <- chk[chk$check == "sigma_random_effect_replication", ]
  expect_equal(sigma_sd$status, "ok")
  expect_true(attr(chk, "ok"))
})

test_that("nbinom2 sigma random intercepts keep planned neighbours closed", {
  sim <- new_nbinom2_sigma_random_intercept_data(n_id = 8, n_each = 4)
  dat <- sim$data

  expect_error(
    drmTMB(
      bf(count ~ x, sigma ~ z + (0 + z | id)),
      family = nbinom2(),
      data = dat
    ),
    "Only independent NB2.*sigma.*random intercepts"
  )
  expect_error(
    drmTMB(
      bf(count ~ x + (1 | id), sigma ~ z + (1 | id)),
      family = nbinom2(),
      data = dat
    ),
    "cannot be combined"
  )
  expect_error(
    drmTMB(
      bf(count ~ x, sigma ~ z + (1 | id), zi ~ 1),
      family = nbinom2(),
      data = dat
    ),
    "ordinary NB2"
  )
  expect_error(
    drmTMB(
      bf(count ~ x, sigma ~ z + (1 | p | id)),
      family = nbinom2(),
      data = dat
    ),
    "Only independent NB2.*sigma.*random intercepts"
  )
})

test_that("nbinom2 mu supports q1 phylogenetic random intercepts", {
  sim <- new_nbinom2_phylo_intercept_data()
  dat <- sim$data
  tree <- sim$tree

  fit <- drmTMB(
    bf(count ~ x + phylo(1 | species, tree = tree), sigma ~ z),
    family = nbinom2(),
    data = dat,
    control = list(eval.max = 600, iter.max = 600)
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "nbinom2")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$tmb_data$has_phylo_mu, 1L)
  expect_equal(fit$model$structured$phylo_mu$q, 1L)
  expect_named(fit$sdpars$mu, "phylo(1 | species)")
  expect_gt(unname(fit$sdpars$mu), 0.05)
  expect_lt(abs(unname(fit$sdpars$mu) - sim$sd_phylo), 0.40)
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.30)
  expect_lt(max(abs(coef(fit, "sigma") - sim$beta_sigma)), 0.35)

  phylo_effects <- ranef(fit, "phylo_mu")$terms[["phylo(1 | species)"]]
  expect_equal(length(phylo_effects), 2 * length(tree$tip.label) - 2L)
  expect_gt(
    stats::cor(
      phylo_effects[names(sim$phylo_effect)],
      sim$phylo_effect
    ),
    0.35
  )

  targets <- profile_targets(fit)
  sd_target <- targets[targets$parm == "sd:mu:phylo(1 | species)", ]
  expect_equal(sd_target$tmb_parameter, "log_sd_phylo")
  expect_equal(sd_target$target_type, "direct")
  expect_true(sd_target$profile_ready)

  chk <- check_drm(fit)
  phylo <- chk[chk$check == "phylo_mu_diagnostics", ]
  expect_equal(phylo$status, "ok")
  expect_match(phylo$value, "min_species_n=24")
  expect_true(attr(chk, "ok"))
  expect_true(all(predict(fit, dpar = "mu") > 0))
  expect_equal(
    predict(fit, dpar = "mu"),
    fit$obj$report()$mu,
    tolerance = 1e-3
  )
  fixed_mu <- exp(as.vector(fit$model$X$mu %*% coef(fit, "mu")))
  expect_gt(max(abs(predict(fit, dpar = "mu") - fixed_mu)), 0.05)
  expect_true(drmTMB:::has_structured_mu_effect(fit))
  expect_equal(drmTMB:::n_mu_random_effect_terms(fit), 1L)
  expect_true(all(sigma(fit) > 0))
})

test_that("nbinom2 phylogenetic mu keeps planned neighboring routes closed", {
  dat <- data.frame(
    count = c(0, 1, 2, 3, 4, 5, 6, 7),
    x = seq(-1, 1, length.out = 8L),
    z = seq(1, -1, length.out = 8L),
    species = rep(paste0("sp_", seq_len(4L)), each = 2L),
    id = rep(seq_len(4L), each = 2L)
  )
  tree <- nbinom2_balanced_ultrametric_tree(n_tip = 4L)

  expect_error(
    drmTMB(
      bf(count ~ x + phylo(1 + x | species, tree = tree), sigma ~ z),
      family = nbinom2(),
      data = dat
    ),
    "q=1 random intercepts"
  )
  expect_error(
    drmTMB(
      bf(count ~ x + phylo(1 | species, tree = tree) + (1 | id), sigma ~ z),
      family = nbinom2(),
      data = dat
    ),
    "cannot be combined"
  )
  expect_error(
    drmTMB(
      bf(count ~ x + phylo(1 | species, tree = tree), sigma ~ z, zi ~ 1),
      family = nbinom2(),
      data = dat
    ),
    "ordinary NB2 models"
  )
  expect_error(
    drmTMB(
      bf(count ~ x, sigma ~ phylo(1 | species, tree = tree)),
      family = nbinom2(),
      data = dat
    ),
    "Structured non-Gaussian paths"
  )
})

test_that("nbinom2 mu random intercepts tolerate weak-SD boundary cases", {
  sim <- new_nbinom2_random_effect_data(
    n_id = 50,
    n_each = 12,
    seed = 20260629,
    sd_id = 0.03,
    sd_x = 0
  )

  fit <- drmTMB(
    bf(count ~ x + (1 | id), sigma ~ z),
    family = nbinom2(),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "nbinom2")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_named(fit$sdpars$mu, "(1 | id)")
  expect_true(is.finite(unname(fit$sdpars$mu)))
  expect_gt(unname(fit$sdpars$mu), 0)
  expect_lt(unname(fit$sdpars$mu), 0.25)
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.25)
  expect_lt(max(abs(coef(fit, "sigma") - sim$beta_sigma)), 0.25)

  chk <- check_drm(fit, sd_boundary = 0.25)
  sd_boundary <- chk[chk$check == "random_effect_sd_boundary", ]
  expect_equal(sd_boundary$status, "warning")
  expect_match(sd_boundary$value, "boundary=0.2500")
  expect_match(sd_boundary$message, "lower boundary")
  expect_false(attr(chk, "ok"))
})

test_that("nbinom2 likelihood matches independent dnbinom calculation", {
  sim <- new_nbinom2_data(n = 320, seed = 20260603)

  fit <- drmTMB(
    bf(count ~ x, sigma ~ z),
    family = nbinom2(),
    data = sim$data
  )

  eta_mu <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  eta_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  mu <- exp(eta_mu)
  sigma <- exp(eta_sigma)
  ll_independent <- sum(stats::dnbinom(
    fit$model$y,
    size = 1 / sigma^2,
    mu = mu,
    log = TRUE
  ))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(as.numeric(logLik(fit)), ll_independent, tolerance = 1e-6)
})

test_that("nbinom2 supports exposure offsets in the mean formula", {
  sim <- new_nbinom2_data(n = 300, seed = 20260608)
  dat <- sim$data
  dat$effort <- exp(stats::rnorm(nrow(dat), mean = -0.1, sd = 0.35))
  eta_rate <- 0.20 - 0.25 * dat$x
  sigma <- exp(-0.55 + 0.20 * dat$z)
  dat$count <- stats::rnbinom(
    nrow(dat),
    size = 1 / sigma^2,
    mu = dat$effort * exp(eta_rate)
  )

  fit <- drmTMB(
    bf(count ~ x + offset(log(effort)), sigma ~ z),
    family = nbinom2(),
    data = dat
  )

  eta_mu <- log(dat$effort) + as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  eta_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  mu <- exp(eta_mu)
  sigma_hat <- exp(eta_sigma)
  ll_independent <- sum(stats::dnbinom(
    fit$model$y,
    size = 1 / sigma_hat^2,
    mu = mu,
    log = TRUE
  ))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(as.numeric(logLik(fit)), ll_independent, tolerance = 1e-6)
  expect_equal(fit$model$offset$mu, log(dat$effort), tolerance = 1e-12)
  newdata <- data.frame(
    x = c(-1, 0, 1),
    z = c(-1, 0, 1),
    effort = c(0.25, 1, 4)
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "mu"),
    newdata$effort *
      exp(as.vector(stats::model.matrix(~x, newdata) %*% coef(fit, "mu"))),
    tolerance = 1e-12
  )
})

test_that("nbinom2 likelihood weights scale rows and match row duplication", {
  sim <- new_nbinom2_data(n = 220, seed = 20260607)
  dat <- sim$data

  fit <- drmTMB(
    bf(count ~ x, sigma ~ z),
    family = nbinom2(),
    data = dat
  )
  fit_double <- drmTMB(
    bf(count ~ x, sigma ~ z),
    family = nbinom2(),
    data = dat,
    weights = rep(2, nrow(dat))
  )

  expect_equal(coef(fit_double, "mu"), coef(fit, "mu"), tolerance = 1e-6)
  expect_equal(coef(fit_double, "sigma"), coef(fit, "sigma"), tolerance = 1e-6)
  expect_equal(
    as.numeric(logLik(fit_double)),
    2 * as.numeric(logLik(fit)),
    tolerance = 1e-6
  )
  expect_equal(stats::weights(fit_double), rep(2, nrow(dat)))

  w <- rep(c(0, 1, 2, 3), length.out = nrow(dat))
  fit_weighted <- drmTMB(
    bf(count ~ x, sigma ~ z),
    family = nbinom2(),
    data = dat,
    weights = w
  )
  dat_expanded <- dat[rep(seq_len(nrow(dat)), w), , drop = FALSE]
  fit_expanded <- drmTMB(
    bf(count ~ x, sigma ~ z),
    family = nbinom2(),
    data = dat_expanded
  )

  expect_equal(stats::weights(fit_weighted), w)
  expect_equal(
    coef(fit_weighted, "mu"),
    coef(fit_expanded, "mu"),
    tolerance = 1e-4
  )
  expect_equal(
    coef(fit_weighted, "sigma"),
    coef(fit_expanded, "sigma"),
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(logLik(fit_weighted)),
    as.numeric(logLik(fit_expanded)),
    tolerance = 1e-4
  )
})

test_that("nbinom2 methods return mean and overdispersion scales", {
  sim <- new_nbinom2_data(n = 220, seed = 20260604)
  fit <- drmTMB(
    bf(count ~ x, sigma ~ z),
    family = nbinom2(),
    data = sim$data
  )

  mu <- fitted(fit)
  sigma <- sigma(fit)
  expect_equal(predict(fit, dpar = "mu"), mu, tolerance = 1e-12)
  expect_equal(predict(fit, dpar = "sigma", type = "response"), sigma)
  expect_equal(
    residuals(fit, type = "pearson"),
    (fit$model$y - mu) / sqrt(mu + sigma^2 * mu^2),
    tolerance = 1e-12
  )
  expect_equal(residuals(fit), fit$model$y - mu, tolerance = 1e-12)
  newdata <- data.frame(x = c(-1, 0, 1), z = c(-1, 0, 1))
  expect_equal(
    predict(fit, newdata = newdata, dpar = "mu"),
    exp(as.vector(stats::model.matrix(~x, newdata) %*% coef(fit, "mu"))),
    tolerance = 1e-12
  )
  expect_equal(
    predict(fit, newdata = newdata, dpar = "sigma"),
    exp(as.vector(stats::model.matrix(~z, newdata) %*% coef(fit, "sigma"))),
    tolerance = 1e-12
  )
  sims <- simulate(fit, nsim = 2, seed = 20260605)
  expect_equal(dim(sims), c(nrow(fit$data), 2L))
  expect_named(sims, c("sim_1", "sim_2"))
  expect_true(all(unlist(sims, use.names = FALSE) >= 0))
  expect_true(all(unlist(sims, use.names = FALSE) %% 1 == 0))
  expect_equal(
    simulate(fit, nsim = 2, seed = 20260605),
    simulate(fit, nsim = 2, seed = 20260605)
  )
})

test_that("nbinom2 supports default sigma and complete-case filtering", {
  sim <- new_nbinom2_data(n = 120, seed = 20260606)
  fit_default_sigma <- drmTMB(
    bf(count ~ x),
    family = nbinom2(),
    data = sim$data
  )

  expect_equal(fit_default_sigma$opt$convergence, 0)
  expect_length(coef(fit_default_sigma, "sigma"), 1)
  expect_equal(ncol(fit_default_sigma$model$X$sigma), 1)

  dat <- sim$data[seq_len(40), ]
  dat$count[[1L]] <- -1
  dat$x[[1L]] <- NA
  dat$count[[2L]] <- 1.5
  dat$z[[2L]] <- NA

  fit <- drmTMB(
    bf(count ~ x, sigma ~ z),
    family = nbinom2(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(nobs(fit), nrow(dat) - 2L)
  expect_equal(fit$model$keep[1:2], c(FALSE, FALSE))
  expect_true(all(fit$model$y >= 0))
  expect_true(all(fit$model$y %% 1 == 0))
})

test_that("nbinom2 approaches Poisson likelihood as sigma approaches zero", {
  dat <- data.frame(y = c(0, 1, 2, 4, 7))
  fit <- drmTMB(
    bf(y ~ 1, sigma ~ 1),
    family = nbinom2(),
    data = dat
  )

  par <- fit$obj$par
  par[["beta_mu"]] <- 0
  par[["beta_sigma"]] <- -20
  ll_nb <- -fit$obj$fn(par)
  ll_pois <- sum(stats::dpois(dat$y, lambda = 1, log = TRUE))

  expect_equal(ll_nb, ll_pois, tolerance = 1e-6)
  expect_true(is.finite(fit$obj$fn(par)))

  par[["beta_sigma"]] <- -400
  expect_equal(-fit$obj$fn(par), ll_pois, tolerance = 1e-6)
  expect_true(is.finite(fit$obj$fn(par)))
})

test_that("nbinom2 rejects unsupported or invalid inputs", {
  dat <- data.frame(
    y = c(0, 1, 2, 3),
    x = c(0, 1, 0, 1),
    id = factor(c(1, 1, 2, 2))
  )

  expect_error(
    drmTMB(bf(y ~ x, nu ~ 1), family = nbinom2(), data = dat),
    "only support"
  )
  expect_error(
    drmTMB(bf(mu = ~x, sigma ~ 1), family = nbinom2(), data = dat),
    "must include a response"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1, sigma ~ x), family = nbinom2(), data = dat),
    "at most one"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = nbinom2(),
      data = transform(dat, y = c(0, 1.5, 2, 3))
    ),
    "non-negative integer"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = nbinom2(),
      data = transform(dat, y = c(0, -1, 2, 3))
    ),
    "non-negative integer"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = nbinom2(),
      data = transform(dat, y = NA_real_)
    ),
    "No complete observations"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + offset(log(c(1, 0, 2, 3))), sigma ~ 1),
      family = nbinom2(),
      data = dat
    ),
    "Offset terms"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id), sigma ~ 1, zi ~ 1),
      family = nbinom2(),
      data = dat
    ),
    "Zero-inflated NB2 random effects"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 + x | id), sigma ~ 1),
      family = nbinom2(),
      data = dat
    ),
    "Only independent NB2"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + meta_V(V = rep(0.1, 4)), sigma ~ 1),
      family = nbinom2(),
      data = dat
    ),
    "meta_V"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1, sd(id) ~ 1), family = nbinom2(), data = dat),
    "Random-effect scale"
  )
  expect_error(
    drmTMB(bf(mvbind(y, y) ~ x, sigma ~ 1), family = nbinom2(), data = dat),
    "mvbind"
  )
})

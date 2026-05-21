new_poisson_data <- function(n = 900, seed = 20260596) {
  set.seed(seed)
  dat <- data.frame(x = stats::rnorm(n))
  beta_mu <- c(`(Intercept)` = 0.25, x = -0.45)
  lambda <- exp(beta_mu[[1L]] + beta_mu[[2L]] * dat$x)
  dat$count <- stats::rpois(n, lambda = lambda)
  list(data = dat, beta_mu = beta_mu)
}

new_poisson_random_intercept_data <- function(
  n_id = 36,
  n_each = 10,
  seed = 20260619,
  sd_id = 0.55
) {
  set.seed(seed)
  n <- n_id * n_each
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n)
  )
  beta_mu <- c(`(Intercept)` = 0.35, x = -0.30)
  u_id <- stats::rnorm(n_id, sd = sd_id)
  eta <- beta_mu[[1L]] + beta_mu[[2L]] * dat$x + u_id[dat$id]
  dat$count <- stats::rpois(n, lambda = exp(eta))
  list(data = dat, beta_mu = beta_mu, sd_id = sd_id, u_id = u_id)
}

new_poisson_factor_random_intercept_data <- function(
  n_id = 48,
  n_each = 9,
  seed = 20260623
) {
  set.seed(seed)
  n <- n_id * n_each
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each))
  )
  dat$habitat <- factor(
    sample(rep(c("forest", "open", "wet"), length.out = n)),
    levels = c("forest", "open", "wet")
  )
  beta_mu <- c(
    "(Intercept)" = 0.25,
    habitatopen = 0.45,
    habitatwet = -0.35
  )
  sd_id <- 0.45
  u_id <- stats::rnorm(n_id, sd = sd_id)
  eta <- as.vector(stats::model.matrix(~habitat, dat) %*% beta_mu) +
    u_id[dat$id]
  dat$count <- stats::rpois(n, lambda = exp(eta))
  list(data = dat, beta_mu = beta_mu, sd_id = sd_id, u_id = u_id)
}

new_poisson_random_slope_data <- function(
  n_id = 42,
  n_each = 11,
  seed = 20260621
) {
  set.seed(seed)
  n <- n_id * n_each
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n)
  )
  beta_mu <- c(`(Intercept)` = 0.30, x = -0.25)
  sd_x <- 0.45
  u_x <- stats::rnorm(n_id, sd = sd_x)
  eta <- beta_mu[[1L]] + beta_mu[[2L]] * dat$x + u_x[dat$id] * dat$x
  dat$count <- stats::rpois(n, lambda = exp(eta))
  list(data = dat, beta_mu = beta_mu, sd_x = sd_x, u_x = u_x)
}

poisson_balanced_ultrametric_tree <- function(n_tip = 16L) {
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

new_poisson_phylo_intercept_data <- function(
  n_tip = 16L,
  n_each = 18L,
  seed = 20260641,
  sd_phylo = 0.55
) {
  set.seed(seed)
  tree <- poisson_balanced_ultrametric_tree(n_tip)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  phylo_effect <- as.vector(
    t(chol(A)) %*% stats::rnorm(n_tip, sd = sd_phylo)
  )
  names(phylo_effect) <- tree$tip.label
  species <- rep(tree$tip.label, each = n_each)
  x <- stats::rnorm(length(species))
  beta_mu <- c(`(Intercept)` = 0.45, x = -0.25)
  eta <- beta_mu[[1L]] + beta_mu[[2L]] * x + phylo_effect[species]
  data <- data.frame(
    count = stats::rpois(length(species), lambda = exp(eta)),
    x = x,
    species = species
  )
  list(
    data = data,
    tree = tree,
    beta_mu = beta_mu,
    sd_phylo = sd_phylo,
    phylo_effect = phylo_effect
  )
}

test_that("drmTMB fits fixed-effect Poisson mean models", {
  sim <- new_poisson_data()

  fit <- drmTMB(
    bf(count ~ x),
    family = stats::poisson(link = "log"),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "poisson")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$df, length(coef(fit, "mu")))
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.12)
  expect_true(all(predict(fit, dpar = "mu") > 0))
  expect_equal(
    predict(fit, dpar = "mu"),
    exp(predict(fit, dpar = "mu", type = "link")),
    tolerance = 1e-12
  )
  expect_equal(fitted(fit), predict(fit, dpar = "mu"), tolerance = 1e-12)
  expect_equal(sigma(fit), rep(1, nobs(fit)))

  ci <- confint(fit)
  expect_equal(
    ci$parm,
    c("fixef:mu:(Intercept)", "fixef:mu:x")
  )
  expect_equal(ci$tmb_parameter, c("beta_mu", "beta_mu"))
  expect_true(all(ci$conf.status == "wald"))
})

test_that("Poisson likelihood matches independent dpois calculation", {
  sim <- new_poisson_data(n = 260, seed = 20260597)

  fit <- drmTMB(
    bf(count ~ x),
    family = stats::poisson(link = "log"),
    data = sim$data
  )

  eta_mu <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  mu <- exp(eta_mu)
  ll_independent <- sum(stats::dpois(fit$model$y, lambda = mu, log = TRUE))

  expect_equal(fit$opt$convergence, 0)
  expect_equal(as.numeric(logLik(fit)), ll_independent, tolerance = 1e-6)
})

test_that("Poisson likelihood weights scale rows and match row duplication", {
  sim <- new_poisson_data(n = 180, seed = 20260602)
  dat <- sim$data

  fit <- drmTMB(
    bf(count ~ x),
    family = stats::poisson(link = "log"),
    data = dat
  )
  fit_double <- drmTMB(
    bf(count ~ x),
    family = stats::poisson(link = "log"),
    data = dat,
    weights = rep(2, nrow(dat))
  )

  expect_equal(coef(fit_double, "mu"), coef(fit, "mu"), tolerance = 1e-6)
  expect_equal(
    as.numeric(logLik(fit_double)),
    2 * as.numeric(logLik(fit)),
    tolerance = 1e-6
  )
  expect_equal(stats::weights(fit_double), rep(2, nrow(dat)))

  w <- rep(c(0, 1, 2, 3), length.out = nrow(dat))
  fit_weighted <- drmTMB(
    bf(count ~ x),
    family = stats::poisson(link = "log"),
    data = dat,
    weights = w
  )
  dat_expanded <- dat[rep(seq_len(nrow(dat)), w), , drop = FALSE]
  fit_expanded <- drmTMB(
    bf(count ~ x),
    family = stats::poisson(link = "log"),
    data = dat_expanded
  )

  expect_equal(stats::weights(fit_weighted), w)
  expect_equal(
    coef(fit_weighted, "mu"),
    coef(fit_expanded, "mu"),
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(logLik(fit_weighted)),
    as.numeric(logLik(fit_expanded)),
    tolerance = 1e-5
  )
})

test_that("Poisson mean model agrees with base glm on an overlapping model", {
  sim <- new_poisson_data(n = 280, seed = 20260598)

  fit <- drmTMB(
    bf(count ~ x),
    family = stats::poisson(link = "log"),
    data = sim$data
  )
  fit_glm <- stats::glm(
    count ~ x,
    family = stats::poisson(link = "log"),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    unname(coef(fit, "mu")),
    unname(stats::coef(fit_glm)),
    tolerance = 1e-6
  )
  expect_equal(
    as.numeric(logLik(fit)),
    as.numeric(stats::logLik(fit_glm)),
    tolerance = 1e-6
  )
})

test_that("Poisson mu supports ordinary random intercepts", {
  sim <- new_poisson_random_intercept_data()

  fit <- drmTMB(
    bf(count ~ x + (1 | id)),
    family = stats::poisson(link = "log"),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "poisson")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$random$mu$n_terms, 1L)
  expect_equal(fit$model$random$mu$labels, "(1 | id)")
  expect_named(fit$sdpars$mu, "(1 | id)")
  expect_gt(unname(fit$sdpars$mu), 0.05)
  expect_lt(abs(unname(fit$sdpars$mu) - sim$sd_id), 0.25)
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.20)

  id_effects <- fit$random_effects$mu$terms[["(1 | id)"]]
  expect_equal(length(id_effects), length(sim$u_id))
  expect_gt(stats::cor(id_effects, sim$u_id), 0.45)

  targets <- profile_targets(fit)
  sd_target <- targets[targets$parm == "sd:mu:(1 | id)", , drop = FALSE]
  expect_equal(nrow(sd_target), 1L)
  expect_true(sd_target$profile_ready)
  expect_equal(sd_target$tmb_parameter, "log_sd_mu")

  expect_true(all(predict(fit, dpar = "mu") > 0))
  expect_equal(fitted(fit), predict(fit, dpar = "mu"), tolerance = 1e-12)
})

test_that("Poisson mu supports independent random slopes", {
  sim <- new_poisson_random_slope_data()

  fit <- drmTMB(
    bf(count ~ x + (0 + x | id)),
    family = stats::poisson(link = "log"),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "poisson")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$random$mu$n_terms, 1L)
  expect_equal(fit$model$random$mu$labels, "(0 + x | id)")
  expect_named(fit$sdpars$mu, "(0 + x | id)")
  expect_gt(unname(fit$sdpars$mu), 0.05)
  expect_lt(abs(unname(fit$sdpars$mu) - sim$sd_x), 0.25)
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.20)

  slope_effects <- fit$random_effects$mu$terms[["(0 + x | id)"]]
  expect_equal(length(slope_effects), length(sim$u_x))
  expect_gt(stats::cor(slope_effects, sim$u_x), 0.35)

  targets <- profile_targets(fit)
  sd_target <- targets[targets$parm == "sd:mu:(0 + x | id)", , drop = FALSE]
  expect_equal(nrow(sd_target), 1L)
  expect_true(sd_target$profile_ready)
  expect_equal(sd_target$tmb_parameter, "log_sd_mu")

  expect_true(all(predict(fit, dpar = "mu") > 0))
  expect_equal(fitted(fit), predict(fit, dpar = "mu"), tolerance = 1e-12)
})

test_that("Poisson mu supports a q1 phylogenetic structured intercept", {
  sim <- new_poisson_phylo_intercept_data()
  tree <- sim$tree

  fit <- drmTMB(
    bf(count ~ x + phylo(1 | species, tree = tree)),
    family = stats::poisson(link = "log"),
    data = sim$data
  )

  sd_name <- "phylo(1 | species)"
  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "poisson")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$structured$phylo_mu$type, "phylo")
  expect_equal(fit$model$structured$phylo_mu$q, 1L)
  expect_named(fit$sdpars$mu, sd_name)
  expect_gt(unname(fit$sdpars$mu[[sd_name]]), 0.02)
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.30)

  phylo_re <- ranef(fit, "phylo_mu")
  expect_equal(phylo_re, fit$random_effects$phylo_mu)
  expect_named(phylo_re$terms, sd_name)
  expect_length(phylo_re$values, fit$model$structured$phylo_mu$n_re)

  targets <- profile_targets(fit)
  sd_target <- targets[
    targets$parm == paste0("sd:mu:", sd_name),
    ,
    drop = FALSE
  ]
  expect_equal(nrow(sd_target), 1L)
  expect_true(sd_target$profile_ready)
  expect_equal(sd_target$tmb_parameter, "log_sd_phylo")
  expect_equal(sd_target$target_type, "direct")

  conditional_link <- predict(fit, dpar = "mu", type = "link")
  fixed_link <- as.vector(fit$model$X$mu %*% fit$coefficients$mu)
  expect_equal(
    unname(conditional_link),
    fixed_link + drmTMB:::phylo_mu_contribution(fit),
    tolerance = 1e-8
  )

  chk <- check_drm(fit)
  phylo_check <- chk[chk$check == "phylo_mu_diagnostics", ]
  expect_equal(nrow(phylo_check), 1L)
  expect_match(phylo_check$value, "n_species=", fixed = TRUE)
  expect_match(phylo_check$value, "phylo_sd=", fixed = TRUE)
})

test_that("Poisson q1 phylogenetic structured intercept rejects nearby planned routes", {
  sim <- new_poisson_phylo_intercept_data(n_tip = 8L, n_each = 5L)
  tree <- sim$tree
  dat <- sim$data
  dat$id <- factor(rep(seq_len(8L), each = 5L))

  expect_error(
    drmTMB(
      bf(count ~ x + phylo(1 + x | species, tree = tree)),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "q=1 random intercepts"
  )
  expect_error(
    drmTMB(
      bf(count ~ x + (1 | id) + phylo(1 | species, tree = tree)),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "cannot be combined"
  )
  expect_error(
    drmTMB(
      bf(count ~ x + phylo(1 | species, tree = tree), zi ~ 1),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "Zero-inflated Poisson phylogenetic random effects"
  )
})

test_that("Poisson mu random intercept recovery handles factor predictors", {
  sim <- new_poisson_factor_random_intercept_data()

  fit <- drmTMB(
    bf(count ~ habitat + (1 | id)),
    family = stats::poisson(link = "log"),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "poisson")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$random$mu$n_terms, 1L)
  expect_equal(fit$model$random$mu$labels, "(1 | id)")
  expect_named(fit$sdpars$mu, "(1 | id)")
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.25)
  expect_lt(abs(unname(fit$sdpars$mu) - sim$sd_id), 0.25)

  id_effects <- fit$random_effects$mu$terms[["(1 | id)"]]
  expect_equal(length(id_effects), length(sim$u_id))
  expect_gt(stats::cor(id_effects, sim$u_id), 0.45)
  expect_true(all(predict(fit, dpar = "mu") > 0))
})

test_that("Poisson mu random intercepts tolerate weak-SD boundary cases", {
  sim <- new_poisson_random_intercept_data(
    n_id = 42,
    n_each = 9,
    seed = 20260622,
    sd_id = 0.03
  )

  fit <- drmTMB(
    bf(count ~ x + (1 | id)),
    family = stats::poisson(link = "log"),
    data = sim$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, "poisson")
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_named(fit$sdpars$mu, "(1 | id)")
  expect_true(is.finite(unname(fit$sdpars$mu)))
  expect_gt(unname(fit$sdpars$mu), 0)
  expect_lt(unname(fit$sdpars$mu), 0.20)
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.20)

  chk <- check_drm(fit, sd_boundary = 0.20)
  sd_boundary <- chk[chk$check == "random_effect_sd_boundary", ]
  expect_equal(sd_boundary$status, "warning")
  expect_match(sd_boundary$value, "boundary=0.2000")
  expect_match(sd_boundary$message, "lower boundary")
  expect_false(attr(chk, "ok"))
})

test_that("Poisson supports exposure offsets in the mean formula", {
  sim <- new_poisson_data(n = 260, seed = 20260603)
  dat <- sim$data
  dat$effort <- exp(stats::rnorm(nrow(dat), mean = 0.1, sd = 0.45))
  eta_rate <- 0.15 - 0.30 * dat$x
  dat$count <- stats::rpois(nrow(dat), lambda = dat$effort * exp(eta_rate))

  fit <- drmTMB(
    bf(count ~ x + offset(log(effort))),
    family = stats::poisson(link = "log"),
    data = dat
  )
  fit_glm <- stats::glm(
    count ~ x + offset(log(effort)),
    family = stats::poisson(link = "log"),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(coef(fit, "mu"), stats::coef(fit_glm), tolerance = 1e-6)
  expect_equal(
    as.numeric(logLik(fit)),
    as.numeric(stats::logLik(fit_glm)),
    tolerance = 1e-6
  )
  expect_equal(fit$model$offset$mu, log(dat$effort), tolerance = 1e-12)
  expect_equal(
    predict(fit, dpar = "mu", type = "link"),
    log(dat$effort) +
      as.vector(stats::model.matrix(~x, dat) %*% coef(fit, "mu")),
    tolerance = 1e-12
  )

  newdata <- data.frame(x = c(-1, 0, 1), effort = c(0.5, 1, 3))
  expect_equal(
    predict(fit, newdata = newdata, dpar = "mu"),
    newdata$effort *
      exp(as.vector(stats::model.matrix(~x, newdata) %*% coef(fit, "mu"))),
    tolerance = 1e-12
  )
})

test_that("Poisson methods return count-scale summaries", {
  sim <- new_poisson_data(n = 180, seed = 20260599)
  fit <- drmTMB(
    bf(count ~ x),
    family = stats::poisson(link = "log"),
    data = sim$data
  )

  expect_equal(predict(fit, dpar = "mu"), fitted(fit), tolerance = 1e-12)
  expect_equal(
    residuals(fit, type = "pearson"),
    (fit$model$y - fitted(fit)) / sqrt(fitted(fit)),
    tolerance = 1e-12
  )
  expect_equal(residuals(fit), fit$model$y - fitted(fit), tolerance = 1e-12)
  newdata <- data.frame(x = c(-1, 0, 1))
  expect_equal(
    predict(fit, newdata = newdata, dpar = "mu"),
    exp(as.vector(stats::model.matrix(~x, newdata) %*% coef(fit, "mu"))),
    tolerance = 1e-12
  )
  sims <- simulate(fit, nsim = 2, seed = 20260600)
  expect_equal(dim(sims), c(nrow(fit$data), 2L))
  expect_named(sims, c("sim_1", "sim_2"))
  expect_true(all(unlist(sims, use.names = FALSE) >= 0))
  expect_true(all(unlist(sims, use.names = FALSE) %% 1 == 0))
  expect_equal(
    simulate(fit, nsim = 2, seed = 20260600),
    simulate(fit, nsim = 2, seed = 20260600)
  )
})

test_that("Poisson supports complete-case filtering", {
  sim <- new_poisson_data(n = 40, seed = 20260601)
  dat <- sim$data
  dat$count[[1L]] <- -1
  dat$x[[1L]] <- NA
  dat$count[[2L]] <- 1.5
  dat$x[[2L]] <- NA

  fit <- drmTMB(
    bf(count ~ x),
    family = stats::poisson(link = "log"),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(nobs(fit), nrow(dat) - 2L)
  expect_equal(fit$model$keep[1:2], c(FALSE, FALSE))
  expect_true(all(fit$model$y >= 0))
  expect_true(all(fit$model$y %% 1 == 0))
})

test_that("Poisson models reject unsupported or invalid inputs", {
  dat <- data.frame(
    y = c(0, 1, 2, 3),
    x = c(0, 1, 0, 1),
    id = factor(c(1, 1, 2, 2))
  )

  expect_error(
    drmTMB(bf(y ~ x), family = stats::poisson(link = "identity"), data = dat),
    "Poisson models currently require"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "only support"
  )
  expect_error(
    drmTMB(bf(mu = ~x), family = stats::poisson(link = "log"), data = dat),
    "must include a response"
  )
  expect_error(
    drmTMB(
      bf(y ~ x),
      family = stats::poisson(link = "log"),
      data = transform(dat, y = c(0, 1.5, 2, 3))
    ),
    "non-negative integer"
  )
  expect_error(
    drmTMB(
      bf(y ~ x),
      family = stats::poisson(link = "log"),
      data = transform(dat, y = c(0, -1, 2, 3))
    ),
    "non-negative integer"
  )
  expect_error(
    drmTMB(
      bf(y ~ x),
      family = stats::poisson(link = "log"),
      data = transform(dat, y = NA_real_)
    ),
    "No complete observations"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 + x | id)),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "Only independent Poisson"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | p | id)),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "Only independent Poisson"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + offset(log(c(1, 0, 2, 3)))),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "Offset terms"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + meta_known_V(V = rep(0.1, 4))),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "meta_known_V"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sd(id) ~ 1),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "Random-effect scale"
  )
  expect_error(
    drmTMB(
      bf(mvbind(y, y) ~ x),
      family = stats::poisson(link = "log"),
      data = dat
    ),
    "mvbind"
  )
})

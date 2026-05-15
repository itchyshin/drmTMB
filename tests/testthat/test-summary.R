new_summary_balanced_tree <- function(n_tip = 4L) {
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

new_summary_biv_phylo_data <- function(
  seed = 20260622,
  n_tip = 4L,
  n_each = 5L,
  rho_phylo = 0.30,
  rho12 = 0.15
) {
  set.seed(seed)
  tree <- new_summary_balanced_tree(n_tip)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  z1 <- stats::rnorm(n_tip)
  z2 <- rho_phylo * z1 + sqrt(1 - rho_phylo^2) * stats::rnorm(n_tip)
  phylo1 <- as.vector(t(chol(A)) %*% z1) * 0.45
  phylo2 <- as.vector(t(chol(A)) %*% z2) * 0.40
  names(phylo1) <- tree$tip.label
  names(phylo2) <- tree$tip.label

  species <- rep(tree$tip.label, each = n_each)
  x <- stats::rnorm(length(species))
  e1 <- stats::rnorm(length(species))
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(length(species))
  list(
    data = data.frame(
      y1 = 0.25 + 0.30 * x + phylo1[species] + 0.25 * e1,
      y2 = -0.15 - 0.25 * x + phylo2[species] + 0.30 * e2,
      x = x,
      species = species
    ),
    tree = tree
  )
}

test_that("summary() reports fitted response-scale parameter ranges", {
  set.seed(20260511)
  n <- 80
  dat <- data.frame(
    x = stats::rnorm(n)
  )
  dat$y <- 0.2 + 0.4 * dat$x + stats::rnorm(n, sd = exp(-0.4 + 0.3 * dat$x))

  fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = dat
  )
  smry <- summary(fit)

  expect_s3_class(smry, "summary.drmTMB")
  expect_named(smry$coefficients, c("estimate", "std_error"))
  expect_equal(nrow(smry$covariance), 0L)
  expect_true("fitted:sigma" %in% rownames(smry$parameters))
  sigma_row <- smry$parameters["fitted:sigma", ]
  expect_equal(sigma_row$component, "distributional-scale")
  expect_equal(sigma_row$profile_note, "use_confint_newdata")
  expect_lt(sigma_row$minimum, sigma_row$maximum)
  expect_equal(sigma_row$minimum, min(stats::sigma(fit)))
  expect_equal(sigma_row$maximum, max(stats::sigma(fit)))
})

test_that("summary() reports random-effect and correlation parameter tables", {
  set.seed(20260512)
  n_id <- 20
  n_each <- 6
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- rep(seq(-1, 1, length.out = n_each), times = n_id)
  u <- stats::rnorm(n_id, sd = 0.45)
  dat <- data.frame(id = id, x = x)
  dat$y <- 0.3 + 0.5 * dat$x + u[dat$id] + stats::rnorm(nrow(dat), sd = 0.35)

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1),
    family = gaussian(),
    data = dat
  )
  smry <- summary(fit)

  expect_true("sigma" %in% rownames(smry$parameters))
  expect_true("sd:mu:(1 | id)" %in% rownames(smry$parameters))
  expect_equal(
    smry$parameters["sd:mu:(1 | id)", "estimate"],
    unname(fit$sdpars$mu[["(1 | id)"]])
  )

  profiled <- summary(
    fit,
    conf.int = TRUE,
    method = "profile",
    ci_parm = "sd:mu:(1 | id)"
  )
  sd_row <- profiled$parameters["sd:mu:(1 | id)", ]
  expect_true(is.finite(sd_row$conf.low))
  expect_true(is.finite(sd_row$conf.high))
  expect_lt(sd_row$conf.low, sd_row$conf.high)
  expect_true(all(is.na(profiled$coefficients$conf.low)))
})

test_that("summary() reports derived repeatability and interval status", {
  set.seed(20260631)
  n_id <- 18
  n_each <- 5
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n_id * n_each)
  u <- stats::rnorm(n_id, sd = 0.45)
  dat <- data.frame(id = id, x = x)
  dat$y <- 0.2 + 0.35 * x + u[id] + stats::rnorm(nrow(dat), sd = 0.40)

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1),
    family = gaussian(),
    data = dat
  )
  smry <- summary(fit)
  derived <- smry$derived
  parm <- "derived:repeatability(id)"
  sd_mu <- unname(fit$sdpars$mu[["(1 | id)"]])
  sigma <- unique(stats::sigma(fit))
  expected <- sd_mu^2 / (sd_mu^2 + sigma^2)

  expect_true(parm %in% rownames(derived))
  expect_equal(derived[parm, "quantity"], "repeatability")
  expect_equal(derived[parm, "level"], "group")
  expect_equal(derived[parm, "group"], "id")
  expect_equal(derived[parm, "estimate"], expected, tolerance = 1e-12)
  expect_equal(derived[parm, "conf.status"], "not_requested")

  profiled <- summary(fit, conf.int = TRUE, method = "wald")
  expect_equal(
    profiled$derived[parm, "conf.status"],
    "derived_interval_unavailable"
  )
  expect_true(is.na(profiled$derived[parm, "conf.low"]))
})

test_that("summary() reports residual rho12 on the response scale", {
  set.seed(20260513)
  n <- 120
  y1 <- stats::rnorm(n)
  y2 <- 0.35 * y1 + sqrt(1 - 0.35^2) * stats::rnorm(n)
  dat <- data.frame(y1 = y1, y2 = y2, x = stats::rnorm(n))

  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~1),
    family = c(gaussian(), gaussian()),
    data = dat
  )
  smry <- summary(fit)

  expect_true("rho12" %in% rownames(smry$parameters))
  expect_equal(smry$parameters["rho12", "component"], "residual-correlation")
  expect_equal(smry$parameters["rho12", "estimate"], unique(rho12(fit)))
})

test_that("summary() reports univariate mu/sigma covariance separately", {
  set.seed(20260517)
  n_id <- 22
  n_each <- 6
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  z_mu <- stats::rnorm(n_id)
  z_sigma <- stats::rnorm(n_id)
  rho_group <- 0.35
  b_mu <- 0.5 * z_mu
  b_sigma <- 0.25 * (rho_group * z_mu + sqrt(1 - rho_group^2) * z_sigma)
  dat <- data.frame(id = id, x = x, z = z)
  dat$y <- stats::rnorm(
    n,
    mean = 0.2 + 0.45 * x + b_mu[id],
    sd = exp(log(0.55) + 0.18 * z + b_sigma[id])
  )

  fit <- drmTMB(
    bf(y ~ x + (1 | p | id), sigma ~ z + (1 | p | id)),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 250, iter.max = 250)
  )
  smry <- summary(fit)

  sd_mu <- "sd:mu:(1 | p | id)"
  sd_sigma <- "sd:sigma:(1 | p | id)"
  cor_mu_sigma <- "cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)"
  expect_true(all(
    c(sd_mu, sd_sigma, cor_mu_sigma) %in% rownames(smry$parameters)
  ))
  expect_false("rho12" %in% rownames(smry$parameters))
  expect_equal(smry$parameters[sd_mu, "component"], "random-effect-sd")
  expect_equal(smry$parameters[sd_sigma, "component"], "random-effect-sd")
  expect_equal(
    smry$parameters[cor_mu_sigma, "component"],
    "random-effect-correlation"
  )
  expect_equal(smry$parameters[sd_mu, "estimate"], unname(fit$sdpars$mu[[1L]]))
  expect_equal(
    smry$parameters[sd_sigma, "estimate"],
    unname(fit$sdpars$sigma[[1L]])
  )
  expect_equal(
    smry$parameters[cor_mu_sigma, "estimate"],
    unname(fit$corpars$mu_sigma[[1L]])
  )
  expect_equal(
    smry$parameters[cor_mu_sigma, "term"],
    names(fit$corpars$mu_sigma)[[1L]]
  )
  expect_equal(nrow(smry$covariance), 1L)
  expect_equal(smry$covariance$level, "group")
  expect_equal(smry$covariance$group, "id")
  expect_equal(smry$covariance$block, "p")
  expect_equal(smry$covariance$class, "mean-scale")
  expect_equal(smry$covariance$from_scale, "identity")
  expect_equal(smry$covariance$to_scale, "log")
  expect_equal(
    smry$covariance$correlation,
    unname(fit$corpars$mu_sigma[[1L]]),
    tolerance = 1e-12
  )
  expect_equal(
    smry$covariance$covariance,
    unname(fit$sdpars$mu[[1L]]) *
      unname(fit$sdpars$sigma[[1L]]) *
      unname(fit$corpars$mu_sigma[[1L]]),
    tolerance = 1e-12
  )
  expect_true(all(is.na(smry$covariance$covariance_conf.low)))
  expect_equal(smry$covariance$covariance_conf.status, "not_requested")
  expect_false(grepl(
    "rho12",
    smry$parameters[cor_mu_sigma, "term"],
    fixed = TRUE
  ))

  profiled <- summary(
    fit,
    conf.int = TRUE,
    method = "profile",
    ci_parm = cor_mu_sigma,
    ystep = 0.35
  )
  cor_row <- profiled$parameters[cor_mu_sigma, ]
  expect_equal(profiled$conf.method, "profile")
  expect_true(is.finite(cor_row$conf.low))
  expect_true(is.finite(cor_row$conf.high))
  expect_lt(cor_row$conf.low, smry$parameters[cor_mu_sigma, "estimate"])
  expect_gt(cor_row$conf.high, smry$parameters[cor_mu_sigma, "estimate"])
  expect_true(is.finite(profiled$covariance$correlation_conf.low))
  expect_true(is.finite(profiled$covariance$correlation_conf.high))
  expect_true(all(is.na(profiled$covariance$from_sd_conf.low)))
  expect_true(all(is.na(profiled$covariance$covariance_conf.low)))
  expect_equal(
    profiled$covariance$covariance_conf.status,
    "derived_interval_unavailable"
  )
})

test_that("summary() separates bivariate group covariance from residual rho12", {
  set.seed(20260516)
  n_id <- 16
  n_each <- 5
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  z1 <- stats::rnorm(n_id)
  z2 <- stats::rnorm(n_id)
  rho_group <- 0.35
  b1 <- 0.45 * z1
  b2 <- 0.50 * (rho_group * z1 + sqrt(1 - rho_group^2) * z2)
  e1 <- stats::rnorm(n)
  e2 <- 0.20 * e1 + sqrt(1 - 0.20^2) * stats::rnorm(n)
  dat <- data.frame(id = id, x = x)
  dat$y1 <- 0.2 + 0.45 * x + b1[id] + 0.35 * e1
  dat$y2 <- -0.1 - 0.30 * x + b2[id] + 0.45 * e2

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + (1 | p | id),
      mu2 = y2 ~ x + (1 | p | id),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat
  )
  smry <- summary(fit)

  sd_mu1 <- "sd:mu:mu1:(1 | p | id)"
  sd_mu2 <- "sd:mu:mu2:(1 | p | id)"
  cor_mu <- "cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)"
  expect_true(all(
    c(sd_mu1, sd_mu2, cor_mu, "rho12") %in% rownames(smry$parameters)
  ))
  expect_equal(smry$parameters[sd_mu1, "component"], "random-effect-sd")
  expect_equal(smry$parameters[sd_mu2, "component"], "random-effect-sd")
  expect_equal(
    smry$parameters[cor_mu, "component"],
    "random-effect-correlation"
  )
  expect_equal(smry$parameters["rho12", "component"], "residual-correlation")
  expect_equal(smry$parameters[sd_mu1, "estimate"], unname(fit$sdpars$mu[[1L]]))
  expect_equal(smry$parameters[sd_mu2, "estimate"], unname(fit$sdpars$mu[[2L]]))
  expect_equal(
    smry$parameters[cor_mu, "estimate"],
    unname(fit$corpars$mu[[1L]])
  )
  expect_equal(smry$parameters["rho12", "estimate"], unique(rho12(fit)))
  expect_equal(smry$parameters[cor_mu, "term"], names(fit$corpars$mu)[[1L]])
  expect_false(grepl("rho12", smry$parameters[cor_mu, "term"], fixed = TRUE))
  expect_equal(nrow(smry$covariance), 1L)
  expect_equal(smry$covariance$class, "mean-mean")
  expect_equal(smry$covariance$from_dpar, "mu1")
  expect_equal(smry$covariance$to_dpar, "mu2")
  expect_equal(smry$covariance$from_scale, "identity")
  expect_equal(smry$covariance$to_scale, "identity")
  expect_equal(smry$covariance$correlation, unname(fit$corpars$mu[[1L]]))
  expect_equal(
    smry$covariance$covariance,
    unname(fit$sdpars$mu[[1L]]) *
      unname(fit$sdpars$mu[[2L]]) *
      unname(fit$corpars$mu[[1L]]),
    tolerance = 1e-12
  )
  expect_equal(smry$covariance$covariance_conf.status, "not_requested")
  expect_false(any(grepl("rho12", smry$covariance$parameter, fixed = TRUE)))

  profiled <- summary(
    fit,
    conf.int = TRUE,
    method = "profile",
    ci_parm = cor_mu,
    ystep = 0.35
  )
  pair_ci <- corpairs(
    fit,
    level = "group",
    conf.int = TRUE,
    conf.level = 0.80,
    ystep = 0.35
  )
  cor_row <- profiled$parameters[cor_mu, ]
  expect_equal(profiled$conf.method, "profile")
  expect_true(is.finite(cor_row$conf.low))
  expect_true(is.finite(cor_row$conf.high))
  expect_lt(cor_row$conf.low, smry$parameters[cor_mu, "estimate"])
  expect_gt(cor_row$conf.high, smry$parameters[cor_mu, "estimate"])
  expect_equal(pair_ci$profile_target, cor_mu)
  expect_equal(pair_ci$conf.status, "profile")
  expect_true(is.finite(pair_ci$conf.low))
  expect_true(is.finite(pair_ci$conf.high))
  expect_equal(
    profiled$covariance$covariance_conf.status,
    "derived_interval_unavailable"
  )
})

test_that("summary() reports univariate phylogenetic signal as derived", {
  set.seed(20260632)
  tree <- new_summary_balanced_tree(n_tip = 4L)
  species <- rep(tree$tip.label, each = 5L)
  phylo_effect <- stats::rnorm(length(tree$tip.label), sd = 0.5)
  names(phylo_effect) <- tree$tip.label
  dat <- data.frame(
    y = 0.2 + phylo_effect[species] + stats::rnorm(length(species), sd = 0.3),
    species = species
  )

  fit <- drmTMB(
    bf(y ~ phylo(1 | species, tree = tree), sigma ~ 1),
    family = gaussian(),
    data = dat
  )
  profiled <- summary(fit, conf.int = TRUE, method = "wald")
  parm <- "derived:phylogenetic_signal(species)"
  sd_phylo <- unname(fit$sdpars$mu[["phylo(1 | species)"]])
  sigma <- unique(stats::sigma(fit))
  expected <- sd_phylo^2 / (sd_phylo^2 + sigma^2)

  expect_true(parm %in% rownames(profiled$derived))
  expect_equal(profiled$derived[parm, "quantity"], "phylogenetic_signal")
  expect_equal(profiled$derived[parm, "level"], "phylogenetic")
  expect_equal(profiled$derived[parm, "estimate"], expected, tolerance = 1e-12)
  expect_equal(
    profiled$derived[parm, "conf.status"],
    "derived_interval_unavailable"
  )
})

test_that("summary() reports bivariate phylogenetic covariance separately", {
  sim <- new_summary_biv_phylo_data(
    n_tip = 8L,
    n_each = 8L,
    rho_phylo = 0.35,
    rho12 = 0.05
  )
  dat <- sim$data
  tree <- sim$tree
  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + phylo(1 | species, tree = tree),
      mu2 = y2 ~ x + phylo(1 | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = list(eval.max = 300, iter.max = 300)
  )
  smry <- summary(fit)

  sd_mu1 <- "sd:mu:mu1:phylo(1 | species)"
  sd_mu2 <- "sd:mu:mu2:phylo(1 | species)"
  cor_phylo <- "cor:phylo:cor(mu1:(Intercept),mu2:(Intercept) | phylo | species)"
  expect_true(all(
    c(sd_mu1, sd_mu2, cor_phylo, "rho12") %in% rownames(smry$parameters)
  ))
  expect_equal(smry$parameters[sd_mu1, "component"], "random-effect-sd")
  expect_equal(smry$parameters[sd_mu2, "component"], "random-effect-sd")
  expect_equal(
    smry$parameters[cor_phylo, "component"],
    "random-effect-correlation"
  )
  expect_equal(smry$parameters["rho12", "component"], "residual-correlation")
  expect_equal(
    smry$parameters[sd_mu1, "estimate"],
    unname(fit$sdpars$mu[["mu1:phylo(1 | species)"]])
  )
  expect_equal(
    smry$parameters[sd_mu2, "estimate"],
    unname(fit$sdpars$mu[["mu2:phylo(1 | species)"]])
  )
  expect_equal(
    smry$parameters[cor_phylo, "estimate"],
    unname(fit$corpars$phylo[[1L]])
  )
  expect_equal(smry$parameters["rho12", "estimate"], unique(rho12(fit)))
  expect_equal(nrow(smry$covariance), 1L)
  expect_equal(smry$covariance$level, "phylogenetic")
  expect_equal(smry$covariance$group, "species")
  expect_equal(smry$covariance$block, "phylo")
  expect_equal(smry$covariance$class, "mean-mean")
  expect_equal(smry$covariance$from_dpar, "mu1")
  expect_equal(smry$covariance$to_dpar, "mu2")
  expect_equal(smry$covariance$from_coef, "(Intercept)")
  expect_equal(smry$covariance$to_coef, "(Intercept)")
  expect_equal(smry$covariance$from_response, "y1")
  expect_equal(smry$covariance$to_response, "y2")
  expect_equal(smry$covariance$parameter, names(fit$corpars$phylo))
  expect_equal(smry$covariance$correlation_target, cor_phylo)
  expect_equal(smry$covariance$from_sd_target, sd_mu1)
  expect_equal(smry$covariance$to_sd_target, sd_mu2)
  expect_equal(smry$covariance$from_sd_parameter, "mu1:phylo(1 | species)")
  expect_equal(smry$covariance$to_sd_parameter, "mu2:phylo(1 | species)")
  expect_equal(smry$covariance$from_scale, "identity")
  expect_equal(smry$covariance$to_scale, "identity")
  expect_equal(
    smry$covariance$correlation,
    unname(fit$corpars$phylo[[1L]]),
    tolerance = 1e-12
  )
  expect_equal(
    smry$covariance$covariance,
    unname(fit$sdpars$mu[["mu1:phylo(1 | species)"]]) *
      unname(fit$sdpars$mu[["mu2:phylo(1 | species)"]]) *
      unname(fit$corpars$phylo[[1L]]),
    tolerance = 1e-12
  )
  expect_equal(smry$covariance$covariance_conf.status, "not_requested")
  expect_false(any(grepl("rho12", smry$covariance$parameter, fixed = TRUE)))
  expect_false(any(grepl(
    "rho12",
    smry$covariance$correlation_target,
    fixed = TRUE
  )))

  profiled <- summary(
    fit,
    conf.int = TRUE,
    method = "profile",
    ci_parm = c(sd_mu1, cor_phylo),
    ystep = 0.45,
    level = 0.70
  )
  pair_ci <- corpairs(
    fit,
    level = "phylogenetic",
    conf.int = TRUE,
    conf.level = 0.70,
    ystep = 0.45
  )
  expect_true(is.finite(profiled$parameters[sd_mu1, "conf.low"]))
  expect_true(is.finite(profiled$parameters[sd_mu1, "conf.high"]))
  expect_true(is.finite(profiled$parameters[cor_phylo, "conf.low"]))
  expect_true(is.finite(profiled$parameters[cor_phylo, "conf.high"]))
  expect_true(is.finite(profiled$covariance$correlation_conf.low))
  expect_true(is.finite(profiled$covariance$correlation_conf.high))
  expect_true(is.finite(profiled$covariance$from_sd_conf.low))
  expect_true(is.finite(profiled$covariance$from_sd_conf.high))
  expect_true(all(is.na(profiled$covariance$to_sd_conf.low)))
  expect_equal(
    profiled$covariance$covariance_conf.status,
    "derived_interval_unavailable"
  )
  expect_equal(pair_ci$profile_target, cor_phylo)
  expect_equal(pair_ci$conf.status, "profile")
  expect_true(is.finite(pair_ci$conf.low))
  expect_true(is.finite(pair_ci$conf.high))
})

test_that("summary() reports fitted shape ranges", {
  set.seed(20260515)
  n <- 90
  x <- seq(-1, 1, length.out = n)
  dat <- data.frame(
    y = 0.1 + 0.4 * x + stats::rt(n, df = 8),
    x = x
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ x),
    family = student(),
    data = dat
  )
  smry <- summary(fit)

  expect_true("fitted:nu" %in% rownames(smry$parameters))
  expect_equal(smry$parameters["fitted:nu", "component"], "shape")
  expect_lt(
    smry$parameters["fitted:nu", "minimum"],
    smry$parameters["fitted:nu", "maximum"]
  )
})

test_that("summary() adds Wald intervals to fixed effects only", {
  set.seed(20260514)
  dat <- data.frame(y = stats::rnorm(60), x = stats::rnorm(60))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  smry <- summary(fit, conf.int = TRUE, level = 0.90)

  expect_true(all(c("conf.low", "conf.high") %in% names(smry$coefficients)))
  expect_true(all(is.finite(smry$coefficients$conf.low)))
  expect_true(all(is.finite(smry$coefficients$conf.high)))
  expect_true("conf.low" %in% names(smry$parameters))
  expect_true(all(is.na(smry$parameters$conf.low)))
  expect_equal(smry$conf.method, "wald")
})

test_that("summary() validates confidence interval arguments", {
  dat <- data.frame(y = stats::rnorm(20))
  fit <- drmTMB(bf(y ~ 1), family = gaussian(), data = dat)

  expect_error(summary(fit, conf.int = NA), "conf.int")
  expect_error(summary(fit, trace = NA), "trace")
  expect_error(summary(fit, level = 1), "level")
  expect_error(summary(fit, ci_parm = "sigma"), "ci_parm")
  expect_error(summary(fit, unknown = TRUE), "Additional arguments")
})

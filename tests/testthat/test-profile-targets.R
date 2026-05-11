new_profile_biv_data <- function(
  n = 180,
  beta_rho12 = c(0.15, 0.35),
  seed = 20260593
) {
  set.seed(seed)
  x <- stats::rnorm(n)
  w <- stats::rnorm(n)
  mu1 <- 0.25 + 0.5 * x
  mu2 <- -0.1 - 0.35 * x
  sigma1 <- exp(-0.2)
  sigma2 <- exp(0.05)
  eta_rho12 <- beta_rho12[[1L]] + beta_rho12[[2L]] * w
  rho12 <- 0.99999999 * tanh(eta_rho12)
  e1 <- stats::rnorm(n)
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  data.frame(
    y1 = mu1 + sigma1 * e1,
    y2 = mu2 + sigma2 * e2,
    x = x,
    w = w
  )
}

new_profile_group_data <- function(n_id = 18, n_each = 5, seed = 20260591) {
  set.seed(seed)
  n <- n_id * n_each
  ID <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n)
  z0 <- stats::rnorm(n_id)
  z1 <- stats::rnorm(n_id)
  sd0 <- 0.5
  sd1 <- 0.35
  rho <- 0.45
  u0 <- sd0 * z0
  u1 <- sd1 * (rho * z0 + sqrt(1 - rho^2) * z1)
  y <- 0.2 + 0.65 * x + u0[ID] + u1[ID] * x + stats::rnorm(n, sd = 0.45)
  data.frame(y = y, x = x, ID = ID)
}

new_profile_balanced_tree <- function(n_tip = 16L) {
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

new_profile_phylo_data <- function(
  seed = 20260603,
  n_tip = 16L,
  n_each = 6L,
  sd_phylo = 0.9,
  sigma = 0.25
) {
  set.seed(seed)
  tree <- new_profile_balanced_tree(n_tip)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  phylo_effect <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip, sd = sd_phylo))
  names(phylo_effect) <- tree$tip.label
  species <- rep(tree$tip.label, each = n_each)
  x <- stats::rnorm(length(species))
  y <- 0.25 +
    0.45 * x +
    phylo_effect[species] +
    stats::rnorm(length(species), sd = sigma)

  list(
    data = data.frame(y = unname(y), x = x, species = species),
    tree = tree
  )
}

new_profile_hurdle_data <- function(n = 360, seed = 20260594) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n),
    w = stats::rnorm(n)
  )
  beta_mu <- c(`(Intercept)` = 0.35, x = -0.2)
  beta_sigma <- c(`(Intercept)` = -0.7, z = 0.15)
  beta_hu <- c(`(Intercept)` = -0.8, w = 0.45)
  mu <- exp(as.vector(stats::model.matrix(~x, dat) %*% beta_mu))
  sigma <- exp(as.vector(stats::model.matrix(~z, dat) %*% beta_sigma))
  hu <- stats::plogis(as.vector(stats::model.matrix(~w, dat) %*% beta_hu))
  p0 <- stats::dnbinom(0, size = 1 / sigma^2, mu = mu)
  hurdle_zero <- stats::runif(n) < hu
  positive_u <- p0 + stats::runif(n) * (1 - p0)
  dat$count <- ifelse(
    hurdle_zero,
    0,
    stats::qnbinom(positive_u, size = 1 / sigma^2, mu = mu)
  )
  dat
}

test_that("profile target inventory lists fixed effects", {
  set.seed(20260590)
  n <- 80
  x <- stats::rnorm(n)
  sigma <- exp(-0.3 + 0.1 * x)
  dat <- data.frame(
    y = 0.2 + 0.5 * x + stats::rnorm(n, sd = sigma),
    x = x
  )
  fit <- drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = dat)

  targets <- drmTMB:::drm_profile_targets(fit)

  expect_s3_class(targets, "data.frame")
  expect_named(
    targets,
    c(
      "parm",
      "target_class",
      "dpar",
      "term",
      "tmb_parameter",
      "index",
      "estimate",
      "link_estimate",
      "scale",
      "transformation",
      "target_type",
      "profile_ready",
      "profile_note"
    )
  )
  expect_equal(
    targets$parm,
    c(
      "fixef:mu:(Intercept)",
      "fixef:mu:x",
      "fixef:sigma:(Intercept)",
      "fixef:sigma:x"
    )
  )
  expect_equal(
    targets$tmb_parameter,
    c("beta_mu", "beta_mu", "beta_sigma", "beta_sigma")
  )
  expect_equal(targets$index, c(1L, 2L, 1L, 2L))
  expect_true(all(targets$profile_ready))
  expect_equal(targets$profile_note, rep("ready", 4))
  expect_true(all(targets$target_type == "direct"))
})

test_that("profile_targets exposes available confidence-interval targets", {
  dat <- new_profile_group_data(n_id = 10, n_each = 4, seed = 20260599)
  fit <- drmTMB(
    bf(y ~ x + (1 + x | p | ID)),
    family = gaussian(),
    data = dat
  )

  targets <- profile_targets(fit)
  ready_targets <- profile_targets(fit, ready_only = TRUE)

  expect_s3_class(targets, "data.frame")
  expect_equal(targets, drmTMB:::drm_profile_targets(fit))
  expect_true("fixef:mu:x" %in% targets$parm)
  expect_true("sd:mu:(1 + x | p | ID):x" %in% targets$parm)
  expect_true("cor:mu:cor((Intercept),x | p | ID)" %in% targets$parm)
  expect_true(all(ready_targets$profile_ready))
  expect_equal(
    ready_targets$parm,
    targets$parm[targets$profile_ready]
  )
  expect_error(profile_targets(list()), "drmTMB")
  expect_error(profile_targets(fit, ready_only = c(TRUE, FALSE)), "single")
})

test_that("confint returns Wald fixed-effect intervals", {
  set.seed(20260597)
  n <- 70
  x <- stats::rnorm(n)
  dat <- data.frame(
    y = 0.2 + 0.5 * x + stats::rnorm(n, sd = exp(-0.3 + 0.1 * x)),
    x = x
  )
  fit <- drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = dat)

  ci <- stats::confint(fit, level = 0.90)
  selected <- stats::confint(fit, parm = c("mu:x", "fixef:sigma:(Intercept)"))

  se <- sqrt(diag(stats::vcov(fit)))
  estimate <- unlist(coef(fit), use.names = FALSE)
  z <- stats::qnorm(0.95)

  expect_named(
    ci,
    c(
      "parm",
      "level",
      "lower",
      "upper",
      "scale",
      "transformation",
      "tmb_parameter",
      "index",
      "method"
    )
  )
  expect_equal(
    ci$parm,
    c(
      "fixef:mu:(Intercept)",
      "fixef:mu:x",
      "fixef:sigma:(Intercept)",
      "fixef:sigma:x"
    )
  )
  expect_equal(ci$lower, unname(estimate - z * se), tolerance = 1e-12)
  expect_equal(ci$upper, unname(estimate + z * se), tolerance = 1e-12)
  expect_equal(ci$method, rep("wald", 4))
  expect_equal(
    selected$parm,
    c("fixef:mu:x", "fixef:sigma:(Intercept)")
  )
})

test_that("confint profile intervals wrap direct fixed-effect profiles", {
  set.seed(20260595)
  n <- 55
  x <- stats::rnorm(n)
  dat <- data.frame(
    y = 0.2 + 0.5 * x + stats::rnorm(n, sd = 0.7),
    x = x
  )
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  ci <- stats::confint(
    fit,
    parm = "mu:x",
    level = 0.90,
    method = "profile",
    trace = FALSE,
    ystep = 0.25
  )

  manual_lincomb <- rep(0, length(fit$opt$par))
  manual_lincomb[which(names(fit$opt$par) == "beta_mu")[[2L]]] <- 1
  manual_profile <- TMB::tmbprofile(
    fit$obj,
    name = "fixef:mu:x",
    lincomb = manual_lincomb,
    trace = FALSE,
    ystep = 0.25
  )
  manual_ci <- stats::confint(manual_profile, level = 0.90)

  expect_named(
    ci,
    c(
      "parm",
      "level",
      "lower",
      "upper",
      "scale",
      "transformation",
      "tmb_parameter",
      "index",
      "method"
    )
  )
  expect_equal(ci$parm, "fixef:mu:x")
  expect_equal(ci$level, 0.90)
  expect_equal(ci$lower, unname(manual_ci[1L, "lower"]), tolerance = 1e-12)
  expect_equal(ci$upper, unname(manual_ci[1L, "upper"]), tolerance = 1e-12)
  expect_equal(ci$tmb_parameter, "beta_mu")
  expect_equal(ci$index, 2L)
  expect_equal(ci$method, "profile")
  expect_lt(ci$lower, unname(coef(fit, "mu")[["x"]]))
  expect_gt(ci$upper, unname(coef(fit, "mu")[["x"]]))
})

test_that("confint profile intervals cover residual rho12 coefficients on link scale", {
  dat <- new_profile_biv_data(n = 120, seed = 20260600)
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~w),
    family = c(gaussian(), gaussian()),
    data = dat
  )

  ci <- stats::confint(
    fit,
    parm = "fixef:rho12:w",
    level = 0.80,
    method = "profile",
    trace = FALSE,
    ystep = 0.30
  )
  manual_lincomb <- rep(0, length(fit$opt$par))
  manual_lincomb[which(names(fit$opt$par) == "beta_rho12")[[2L]]] <- 1
  manual_profile <- TMB::tmbprofile(
    fit$obj,
    name = "fixef:rho12:w",
    lincomb = manual_lincomb,
    trace = FALSE,
    ystep = 0.30
  )
  manual_ci <- stats::confint(manual_profile, level = 0.80)

  expect_equal(ci$parm, "fixef:rho12:w")
  expect_equal(ci$scale, "link")
  expect_equal(ci$transformation, "linear_predictor")
  expect_equal(ci$tmb_parameter, "beta_rho12")
  expect_equal(ci$index, 2L)
  expect_equal(ci$lower, unname(manual_ci[1L, "lower"]), tolerance = 1e-12)
  expect_equal(ci$upper, unname(manual_ci[1L, "upper"]), tolerance = 1e-12)
  expect_lt(ci$lower, unname(coef(fit, "rho12")[["w"]]))
  expect_gt(ci$upper, unname(coef(fit, "rho12")[["w"]]))
})

test_that("confint profile intervals transform constant residual rho12 targets", {
  dat <- new_profile_biv_data(
    n = 130,
    beta_rho12 = c(0.35, 0),
    seed = 20260604
  )
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~1),
    family = c(gaussian(), gaussian()),
    data = dat
  )

  targets <- profile_targets(fit)
  rho_target <- targets[targets$parm == "rho12", , drop = FALSE]
  expect_equal(nrow(rho_target), 1L)
  expect_equal(rho_target$target_class, "residual-correlation")
  expect_equal(rho_target$scale, "response")
  expect_equal(rho_target$transformation, "rho12_tanh")
  expect_true(rho_target$profile_ready)
  expect_equal(
    rho_target$estimate,
    mean(rho12(fit)),
    tolerance = 1e-12
  )

  ci <- stats::confint(
    fit,
    parm = "rho12",
    level = 0.80,
    method = "profile",
    trace = FALSE,
    ystep = 0.30
  )
  manual_lincomb <- rep(0, length(fit$opt$par))
  manual_lincomb[which(names(fit$opt$par) == "beta_rho12")[[1L]]] <- 1
  manual_profile <- TMB::tmbprofile(
    fit$obj,
    name = "rho12",
    lincomb = manual_lincomb,
    trace = FALSE,
    ystep = 0.30
  )
  manual_ci <- stats::confint(manual_profile, level = 0.80)

  expect_equal(ci$parm, "rho12")
  expect_equal(ci$scale, "response")
  expect_equal(ci$transformation, "rho12_tanh")
  expect_equal(ci$tmb_parameter, "beta_rho12")
  expect_equal(ci$index, 1L)
  expect_equal(
    ci$lower,
    drmTMB:::rho_response(unname(manual_ci[1L, "lower"])),
    tolerance = 1e-12
  )
  expect_equal(
    ci$upper,
    drmTMB:::rho_response(unname(manual_ci[1L, "upper"])),
    tolerance = 1e-12
  )
  expect_true(abs(ci$lower) < 1)
  expect_true(abs(ci$upper) < 1)
  expect_lt(ci$lower, mean(rho12(fit)))
  expect_gt(ci$upper, mean(rho12(fit)))
})

test_that("confint profile intervals transform SD and correlation targets", {
  dat <- new_profile_group_data(n_id = 24, n_each = 6, seed = 20260598)
  fit <- drmTMB(
    bf(y ~ x + (1 + x | p | ID)),
    family = gaussian(),
    data = dat
  )

  sd_parm <- "sd:mu:(1 + x | p | ID):(Intercept)"
  sd_ci <- stats::confint(
    fit,
    parm = sd_parm,
    level = 0.80,
    method = "profile",
    trace = FALSE,
    ystep = 0.30
  )
  sd_lincomb <- rep(0, length(fit$opt$par))
  sd_lincomb[which(names(fit$opt$par) == "log_sd_mu")[[1L]]] <- 1
  manual_sd_profile <- TMB::tmbprofile(
    fit$obj,
    name = sd_parm,
    lincomb = sd_lincomb,
    trace = FALSE,
    ystep = 0.30
  )
  manual_sd_ci <- stats::confint(manual_sd_profile, level = 0.80)

  cor_parm <- "cor:mu:cor((Intercept),x | p | ID)"
  cor_ci <- stats::confint(
    fit,
    parm = cor_parm,
    level = 0.80,
    method = "profile",
    trace = FALSE,
    ystep = 0.30
  )
  cor_lincomb <- rep(0, length(fit$opt$par))
  cor_lincomb[which(names(fit$opt$par) == "eta_cor_mu")[[1L]]] <- 1
  manual_cor_profile <- TMB::tmbprofile(
    fit$obj,
    name = cor_parm,
    lincomb = cor_lincomb,
    trace = FALSE,
    ystep = 0.30
  )
  manual_cor_ci <- stats::confint(manual_cor_profile, level = 0.80)

  expect_equal(sd_ci$parm, sd_parm)
  expect_equal(sd_ci$scale, "response")
  expect_equal(sd_ci$transformation, "exp")
  expect_equal(
    sd_ci$lower,
    exp(unname(manual_sd_ci[1L, "lower"])),
    tolerance = 1e-12
  )
  expect_equal(
    sd_ci$upper,
    exp(unname(manual_sd_ci[1L, "upper"])),
    tolerance = 1e-12
  )
  expect_gt(sd_ci$lower, 0)

  expect_equal(cor_ci$parm, cor_parm)
  expect_equal(cor_ci$scale, "response")
  expect_equal(cor_ci$transformation, "tanh")
  expect_equal(
    cor_ci$lower,
    0.999999 * tanh(unname(manual_cor_ci[1L, "lower"])),
    tolerance = 1e-12
  )
  expect_equal(
    cor_ci$upper,
    0.999999 * tanh(unname(manual_cor_ci[1L, "upper"])),
    tolerance = 1e-12
  )
  expect_true(abs(cor_ci$lower) < 1)
  expect_true(abs(cor_ci$upper) < 1)
})

test_that("confint profile intervals transform phylogenetic SD targets", {
  sim <- new_profile_phylo_data()
  dat <- sim$data
  tree <- sim$tree
  fit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
    family = gaussian(),
    data = dat
  )

  phylo_parm <- "sd:mu:phylo(1 | species)"
  ci <- stats::confint(
    fit,
    parm = phylo_parm,
    level = 0.80,
    method = "profile",
    trace = FALSE,
    ystep = 0.30
  )
  manual_lincomb <- rep(0, length(fit$opt$par))
  manual_lincomb[which(names(fit$opt$par) == "log_sd_phylo")[[1L]]] <- 1
  manual_profile <- TMB::tmbprofile(
    fit$obj,
    name = phylo_parm,
    lincomb = manual_lincomb,
    trace = FALSE,
    ystep = 0.30
  )
  manual_ci <- stats::confint(manual_profile, level = 0.80)

  expect_equal(ci$parm, phylo_parm)
  expect_equal(ci$scale, "response")
  expect_equal(ci$transformation, "exp")
  expect_equal(ci$tmb_parameter, "log_sd_phylo")
  expect_equal(ci$index, 1L)
  expect_equal(ci$lower, exp(unname(manual_ci[1L, "lower"])), tolerance = 1e-12)
  expect_equal(ci$upper, exp(unname(manual_ci[1L, "upper"])), tolerance = 1e-12)
  expect_gt(ci$lower, 0)
})

test_that("profile confidence intervals reject unsupported targets clearly", {
  dat <- new_profile_group_data(n_id = 8, n_each = 4, seed = 20260596)
  fit <- drmTMB(
    bf(y ~ x + (1 + x | p | ID)),
    family = gaussian(),
    data = dat
  )

  ordinal_dat <- data.frame(
    y = ordered(rep(1:3, each = 15)),
    x = stats::rnorm(45)
  )
  fit_ord <- drmTMB(
    bf(y ~ x),
    family = cumulative_logit(),
    data = ordinal_dat
  )

  expect_error(
    stats::confint(
      fit_ord,
      parm = "ordinal:theta_ord:1|2",
      method = "profile",
      trace = FALSE
    ),
    "ordinal-cutpoint-internal"
  )
  expect_error(
    stats::confint(fit, method = "profile"),
    "explicit target names"
  )
  expect_error(
    stats::confint(fit, parm = "missing-target"),
    "Unknown confidence-interval target"
  )
  expect_error(
    stats::confint(fit, parm = "fixef:mu:x", level = 1),
    "between 0 and 1"
  )

  missing_obj <- fit
  missing_obj$obj <- NULL
  expect_error(
    stats::confint(
      missing_obj,
      parm = "fixef:mu:x",
      method = "profile",
      trace = FALSE
    ),
    "TMB object retained"
  )
})

test_that("profile target inventory maps hurdle probabilities to beta_zi", {
  dat <- new_profile_hurdle_data()
  fit <- drmTMB(
    bf(count ~ x, sigma ~ z, hu ~ w),
    family = truncated_nbinom2(),
    data = dat
  )

  targets <- drmTMB:::drm_profile_targets(fit)
  hu_targets <- targets[targets$dpar == "hu", ]

  expect_equal(hu_targets$parm, c("fixef:hu:(Intercept)", "fixef:hu:w"))
  expect_equal(hu_targets$tmb_parameter, c("beta_zi", "beta_zi"))
  expect_equal(hu_targets$index, c(1L, 2L))
  expect_true(all(hu_targets$profile_ready))
  expect_equal(hu_targets$profile_note, rep("ready", 2))
})

test_that("profile target inventory separates random-effect SDs and correlations", {
  dat <- new_profile_group_data()
  fit <- drmTMB(
    bf(y ~ x + (1 + x | p | ID)),
    family = gaussian(),
    data = dat
  )

  targets <- drmTMB:::drm_profile_targets(fit)

  expect_true("sd:mu:(1 + x | p | ID):(Intercept)" %in% targets$parm)
  expect_true("sd:mu:(1 + x | p | ID):x" %in% targets$parm)
  expect_true("cor:mu:cor((Intercept),x | p | ID)" %in% targets$parm)

  sd_targets <- targets[targets$target_class == "random-effect-sd", ]
  expect_equal(sd_targets$tmb_parameter, c("log_sd_mu", "log_sd_mu"))
  expect_equal(sd_targets$index, c(1L, 2L))
  expect_equal(sd_targets$transformation, c("exp", "exp"))
  expect_true(all(sd_targets$profile_ready))
  expect_equal(sd_targets$profile_note, rep("ready", 2))

  cor_target <- targets[targets$target_class == "random-effect-correlation", ]
  expect_equal(cor_target$tmb_parameter, "eta_cor_mu")
  expect_equal(cor_target$index, 1L)
  expect_equal(cor_target$transformation, "tanh")
  expect_true(cor_target$profile_ready)
  expect_equal(cor_target$profile_note, "ready")
  expect_equal(
    cor_target$link_estimate,
    drmTMB:::guarded_correlation_link(cor_target$estimate, guard = 0.999999),
    tolerance = 1e-12
  )
})

test_that("profile target inventory marks modelled group scales as derived", {
  set.seed(20260592)
  n_id <- 10
  n_each <- 4
  id <- factor(rep(seq_len(n_id), each = n_each))
  gx_id <- stats::rnorm(n_id)
  gx <- gx_id[id]
  x <- stats::rnorm(n_id * n_each)
  y <- 0.3 + 0.4 * x + stats::rnorm(n_id * n_each, sd = 0.5)
  dat <- data.frame(y = y, x = x, id = id, gx = gx)
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ gx),
    family = gaussian(),
    data = dat
  )

  targets <- drmTMB:::drm_profile_targets(fit)

  expect_true("fixef:sd(id):(Intercept)" %in% targets$parm)
  expect_true("fixef:sd(id):gx" %in% targets$parm)
  expect_true(any(
    targets$tmb_parameter == "beta_sd_mu" & targets$profile_ready
  ))

  derived_sd <- targets[targets$target_class == "random-effect-sd", ]
  expect_true(all(derived_sd$dpar == "sd(id)"))
  expect_true(all(derived_sd$target_type == "derived"))
  expect_false(any(derived_sd$profile_ready))
  expect_equal(derived_sd$transformation, rep("derived_group_scale", n_id))
  expect_equal(derived_sd$profile_note, rep("derived_target", n_id))
})

test_that("profile target inventory lists residual rho12 and ordinal internals", {
  dat <- new_profile_biv_data()
  fit_biv <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~w),
    family = c(gaussian(), gaussian()),
    data = dat
  )

  biv_targets <- drmTMB:::drm_profile_targets(fit_biv)

  rho_rows <- biv_targets[biv_targets$dpar == "rho12", ]
  expect_equal(rho_rows$parm, c("fixef:rho12:(Intercept)", "fixef:rho12:w"))
  expect_equal(rho_rows$tmb_parameter, c("beta_rho12", "beta_rho12"))
  expect_equal(rho_rows$index, c(1L, 2L))
  expect_true(all(rho_rows$profile_ready))
  expect_equal(rho_rows$profile_note, rep("ready", 2))
  expect_false("rho12" %in% biv_targets$parm)

  ordinal_dat <- data.frame(
    y = ordered(rep(1:3, each = 15)),
    x = stats::rnorm(45)
  )
  fit_ord <- drmTMB(
    bf(y ~ x),
    family = cumulative_logit(),
    data = ordinal_dat
  )

  ord_targets <- drmTMB:::drm_profile_targets(fit_ord)
  theta_rows <- ord_targets[
    ord_targets$target_class == "ordinal-cutpoint-internal",
  ]
  expect_equal(
    theta_rows$parm,
    c("ordinal:theta_ord:1|2", "ordinal:theta_ord:2|3")
  )
  expect_equal(theta_rows$tmb_parameter, c("theta_ord", "theta_ord"))
  expect_equal(theta_rows$index, c(1L, 2L))
  expect_equal(theta_rows$transformation, rep("ordered_cutpoint", 2))
  expect_true(all(theta_rows$profile_ready))
  expect_equal(theta_rows$profile_note, rep("ready", 2))
})

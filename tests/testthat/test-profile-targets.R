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

new_profile_q4_pair_registry <- function(
  parameter = paste0("scaffold:", c("12", "13", "14", "23", "24", "34")),
  tmb_parameter = rep(NA_character_, 6L),
  tmb_index = rep(NA_integer_, 6L)
) {
  list(
    pairs = data.frame(
      parameter = parameter,
      tmb_parameter = tmb_parameter,
      tmb_index = tmb_index,
      stringsAsFactors = FALSE
    )
  )
}

new_profile_biv_group_data <- function(
  n_id = 14L,
  n_each = 5L,
  rho_group = 0.35,
  seed = 20260611
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  z1 <- stats::rnorm(n_id)
  z2 <- stats::rnorm(n_id)
  b1 <- 0.4 * z1
  b2 <- 0.45 * (rho_group * z1 + sqrt(1 - rho_group^2) * z2)
  data.frame(
    y1 = 0.2 + 0.45 * x + b1[id] + stats::rnorm(n, sd = 0.35),
    y2 = -0.15 - 0.3 * x + b2[id] + stats::rnorm(n, sd = 0.45),
    x = x,
    id = id
  )
}

new_profile_mu_sigma_group_data <- function(
  n_id = 18L,
  n_each = 5L,
  rho_group = 0.4,
  seed = 20260612
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  z_mu <- stats::rnorm(n_id)
  z_sigma <- stats::rnorm(n_id)
  b_mu <- 0.45 * z_mu
  b_sigma <- 0.25 * (rho_group * z_mu + sqrt(1 - rho_group^2) * z_sigma)
  data.frame(
    y = stats::rnorm(
      n,
      mean = 0.2 + 0.5 * x + b_mu[id],
      sd = exp(log(0.55) + 0.18 * z + b_sigma[id])
    ),
    x = x,
    z = z,
    id = id
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

new_profile_biv_phylo_data <- function(
  seed = 20260621,
  n_tip = 4L,
  n_each = 5L,
  rho_phylo = 0.25,
  rho12 = -0.10,
  sd_phylo1 = 0.45,
  sd_phylo2 = 0.40,
  sigma1 = 0.25,
  sigma2 = 0.30
) {
  set.seed(seed)
  tree <- new_profile_balanced_tree(n_tip)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  z1 <- stats::rnorm(n_tip)
  z2 <- rho_phylo * z1 + sqrt(1 - rho_phylo^2) * stats::rnorm(n_tip)
  phylo1 <- as.vector(t(chol(A)) %*% z1) * sd_phylo1
  phylo2 <- as.vector(t(chol(A)) %*% z2) * sd_phylo2
  names(phylo1) <- tree$tip.label
  names(phylo2) <- tree$tip.label

  species <- rep(tree$tip.label, each = n_each)
  x <- stats::rnorm(length(species))
  e1 <- stats::rnorm(length(species))
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(length(species))
  list(
    data = data.frame(
      y1 = 0.25 + 0.30 * x + phylo1[species] + sigma1 * e1,
      y2 = -0.15 - 0.25 * x + phylo2[species] + sigma2 * e2,
      x = x,
      species = species
    ),
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

test_that("confint profile intervals transform constant sigma targets", {
  set.seed(20260605)
  n <- 80
  x <- stats::rnorm(n)
  dat <- data.frame(
    y = 0.2 + 0.5 * x + stats::rnorm(n, sd = 0.7),
    x = x
  )
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  targets <- profile_targets(fit)
  sigma_target <- targets[targets$parm == "sigma", , drop = FALSE]
  expect_equal(nrow(sigma_target), 1L)
  expect_equal(sigma_target$target_class, "distributional-scale")
  expect_equal(sigma_target$scale, "response")
  expect_equal(sigma_target$transformation, "exp")
  expect_true(sigma_target$profile_ready)
  expect_equal(
    sigma_target$estimate,
    mean(stats::sigma(fit)),
    tolerance = 1e-12
  )

  ci <- stats::confint(
    fit,
    parm = "sigma",
    level = 0.80,
    method = "profile",
    trace = FALSE,
    ystep = 0.30
  )
  manual_lincomb <- rep(0, length(fit$opt$par))
  manual_lincomb[which(names(fit$opt$par) == "beta_sigma")[[1L]]] <- 1
  manual_profile <- TMB::tmbprofile(
    fit$obj,
    name = "sigma",
    lincomb = manual_lincomb,
    trace = FALSE,
    ystep = 0.30
  )
  manual_ci <- stats::confint(manual_profile, level = 0.80)

  expect_equal(ci$parm, "sigma")
  expect_equal(ci$scale, "response")
  expect_equal(ci$transformation, "exp")
  expect_equal(ci$tmb_parameter, "beta_sigma")
  expect_equal(ci$index, 1L)
  expect_equal(ci$lower, exp(unname(manual_ci[1L, "lower"])), tolerance = 1e-12)
  expect_equal(ci$upper, exp(unname(manual_ci[1L, "upper"])), tolerance = 1e-12)
  expect_gt(ci$lower, 0)
  expect_lt(ci$lower, mean(stats::sigma(fit)))
  expect_gt(ci$upper, mean(stats::sigma(fit)))
})

test_that("confint profile intervals transform newdata sigma targets", {
  set.seed(20260606)
  n <- 90
  x <- stats::rnorm(n)
  dat <- data.frame(
    y = 0.2 + 0.5 * x + stats::rnorm(n, sd = exp(-0.4 + 0.25 * x)),
    x = x
  )
  fit <- drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = dat)
  newdata <- data.frame(x = 0.35)
  row.names(newdata) <- "at_x"

  ci <- stats::confint(
    fit,
    parm = "sigma",
    level = 0.80,
    newdata = newdata,
    trace = FALSE,
    ystep = 0.30
  )
  X <- stats::model.matrix(fit$model$terms$sigma, data = newdata)
  manual_lincomb <- rep(0, length(fit$opt$par))
  manual_lincomb[which(names(fit$opt$par) == "beta_sigma")] <- as.numeric(X)
  manual_profile <- TMB::tmbprofile(
    fit$obj,
    name = "sigma[at_x]",
    lincomb = manual_lincomb,
    trace = FALSE,
    ystep = 0.30
  )
  manual_ci <- stats::confint(manual_profile, level = 0.80)
  sigma_hat <- predict(fit, newdata = newdata, dpar = "sigma")

  expect_equal(ci$parm, "sigma[at_x]")
  expect_equal(ci$scale, "response")
  expect_equal(ci$transformation, "exp")
  expect_equal(ci$tmb_parameter, "beta_sigma")
  expect_true(is.na(ci$index))
  expect_equal(ci$lower, exp(unname(manual_ci[1L, "lower"])), tolerance = 1e-12)
  expect_equal(ci$upper, exp(unname(manual_ci[1L, "upper"])), tolerance = 1e-12)
  expect_lt(ci$lower, sigma_hat)
  expect_gt(ci$upper, sigma_hat)
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
  scale_targets <- targets[targets$parm %in% c("sigma1", "sigma2"), ]
  expect_equal(scale_targets$target_class, rep("distributional-scale", 2))
  expect_equal(scale_targets$tmb_parameter, c("beta_sigma1", "beta_sigma2"))
  expect_equal(scale_targets$transformation, c("exp", "exp"))
  expect_true(all(scale_targets$profile_ready))
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

test_that("confint profile intervals transform newdata rho12 targets", {
  dat <- new_profile_biv_data(n = 140, seed = 20260607)
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~w),
    family = c(gaussian(), gaussian()),
    data = dat
  )
  newdata <- data.frame(x = 0, w = 0.2)
  row.names(newdata) <- "warm"

  ci <- stats::confint(
    fit,
    parm = "rho12",
    level = 0.80,
    method = "profile",
    newdata = newdata,
    trace = FALSE,
    ystep = 0.30
  )
  X <- stats::model.matrix(fit$model$terms$rho12, data = newdata)
  manual_lincomb <- rep(0, length(fit$opt$par))
  manual_lincomb[which(names(fit$opt$par) == "beta_rho12")] <- as.numeric(X)
  manual_profile <- TMB::tmbprofile(
    fit$obj,
    name = "rho12[warm]",
    lincomb = manual_lincomb,
    trace = FALSE,
    ystep = 0.30
  )
  manual_ci <- stats::confint(manual_profile, level = 0.80)
  rho_hat <- rho12(fit, newdata = newdata)

  expect_equal(ci$parm, "rho12[warm]")
  expect_equal(ci$scale, "response")
  expect_equal(ci$transformation, "rho12_tanh")
  expect_equal(ci$tmb_parameter, "beta_rho12")
  expect_true(is.na(ci$index))
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
  expect_lt(ci$lower, rho_hat)
  expect_gt(ci$upper, rho_hat)
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

test_that("profile target inventory covers bivariate phylogenetic covariance labels", {
  sim <- new_profile_biv_phylo_data()
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

  targets <- profile_targets(fit)
  ready_targets <- profile_targets(fit, ready_only = TRUE)
  phylo_parms <- c(
    "sd:mu:mu1:phylo(1 | species)",
    "sd:mu:mu2:phylo(1 | species)",
    "cor:phylo:cor(mu1:(Intercept),mu2:(Intercept) | phylo | species)"
  )
  phylo_targets <- targets[match(phylo_parms, targets$parm), ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(phylo_targets$parm, phylo_parms)
  expect_equal(
    phylo_targets$target_class,
    c(
      "random-effect-sd",
      "random-effect-sd",
      "random-effect-correlation"
    )
  )
  expect_equal(phylo_targets$dpar, c("mu", "mu", "phylo"))
  expect_equal(
    phylo_targets$tmb_parameter,
    c("log_sd_phylo", "log_sd_phylo", "eta_cor_phylo")
  )
  expect_equal(phylo_targets$index, c(1L, 2L, 1L))
  expect_equal(phylo_targets$transformation, c("exp", "exp", "tanh"))
  expect_equal(phylo_targets$target_type, rep("direct", 3))
  expect_true(all(phylo_targets$profile_ready))
  expect_equal(phylo_targets$profile_note, rep("ready", 3))
  expect_true(all(phylo_parms %in% ready_targets$parm))

  rho12_targets <- targets[targets$dpar == "rho12", ]
  expect_true("rho12" %in% rho12_targets$parm)
  expect_false(any(rho12_targets$parm %in% phylo_parms))
})

test_that("profile target inventory covers bivariate sd_phylo coefficients", {
  sim <- new_profile_biv_phylo_data(n_tip = 8L, n_each = 5L)
  dat <- sim$data
  tree <- sim$tree
  z_species <- seq(-1, 1, length.out = length(tree$tip.label))
  names(z_species) <- tree$tip.label
  dat$z_species <- z_species[dat$species]
  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + phylo(1 | species, tree = tree),
      mu2 = y2 ~ x + phylo(1 | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1,
      sd_phylo1(species) ~ z_species,
      sd_phylo2(species) ~ z_species
    ),
    family = biv_gaussian(),
    data = dat,
    control = list(eval.max = 600, iter.max = 600)
  )

  targets <- profile_targets(fit)
  direct_parms <- c(
    "fixef:sd_phylo1(species):(Intercept)",
    "fixef:sd_phylo1(species):z_species",
    "fixef:sd_phylo2(species):(Intercept)",
    "fixef:sd_phylo2(species):z_species"
  )
  direct_targets <- targets[match(direct_parms, targets$parm), ]
  surface_targets <- targets[
    targets$dpar %in%
      c("sd_phylo1(species)", "sd_phylo2(species)") &
      targets$target_class == "random-effect-sd",
  ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(direct_targets$parm, direct_parms)
  expect_equal(direct_targets$tmb_parameter, rep("beta_sd_mu", 4L))
  expect_equal(direct_targets$index, seq_len(4L))
  expect_true(all(direct_targets$profile_ready))
  expect_equal(direct_targets$profile_note, rep("ready", 4L))
  expect_true(nrow(surface_targets) > 0L)
  expect_true(all(surface_targets$target_type == "derived"))
  expect_false(any(surface_targets$profile_ready))
  expect_equal(
    unique(surface_targets$transformation),
    "derived_group_scale"
  )
})

test_that("confint profile intervals transform bivariate phylogenetic correlations", {
  sim <- new_profile_biv_phylo_data(
    seed = 20260701,
    n_tip = 8L,
    n_each = 8L,
    rho_phylo = 0.35,
    rho12 = 0.05,
    sd_phylo1 = 0.80,
    sd_phylo2 = 0.75,
    sigma1 = 0.20,
    sigma2 = 0.22
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

  phylo_cor <- "cor:phylo:cor(mu1:(Intercept),mu2:(Intercept) | phylo | species)"
  ci <- stats::confint(
    fit,
    parm = phylo_cor,
    level = 0.80,
    method = "profile",
    trace = FALSE,
    ystep = 0.30
  )
  manual_lincomb <- rep(0, length(fit$opt$par))
  manual_lincomb[which(names(fit$opt$par) == "eta_cor_phylo")[[1L]]] <- 1
  manual_profile <- TMB::tmbprofile(
    fit$obj,
    name = phylo_cor,
    lincomb = manual_lincomb,
    trace = FALSE,
    ystep = 0.30
  )
  manual_ci <- stats::confint(manual_profile, level = 0.80)

  expect_equal(ci$parm, phylo_cor)
  expect_equal(ci$scale, "response")
  expect_equal(ci$transformation, "tanh")
  expect_equal(ci$tmb_parameter, "eta_cor_phylo")
  expect_equal(ci$index, 1L)
  expect_equal(
    ci$lower,
    0.999999 * tanh(unname(manual_ci[1L, "lower"])),
    tolerance = 1e-12
  )
  expect_equal(
    ci$upper,
    0.999999 * tanh(unname(manual_ci[1L, "upper"])),
    tolerance = 1e-12
  )
  expect_true(abs(ci$lower) < 1)
  expect_true(abs(ci$upper) < 1)
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
  expect_error(
    stats::confint(
      fit,
      parm = "sigma",
      method = "wald",
      newdata = data.frame(x = 0)
    ),
    "only used when"
  )
  expect_error(
    stats::confint(
      fit,
      parm = NULL,
      method = "profile",
      newdata = data.frame(x = 0),
      trace = FALSE
    ),
    "must name one distributional parameter"
  )
  expect_error(
    stats::confint(
      fit,
      parm = "mu",
      method = "profile",
      newdata = data.frame(x = 0),
      trace = FALSE
    ),
    "scale, residual-correlation, and ordinary q2"
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

  fit_registry <- fit
  names(fit_registry$corpars$mu) <- "cor(bad,bad | wrong | wrong)"
  registry_targets <- profile_targets(fit_registry)
  expect_true("cor:mu:cor((Intercept),x | p | ID)" %in% registry_targets$parm)

  fit_compat <- fit
  fit_compat$model$random$covariance_blocks <- NULL
  expect_equal(profile_targets(fit_compat), profile_targets(fit))
})

test_that("profile target inventory covers univariate mu/sigma covariance labels", {
  dat <- new_profile_mu_sigma_group_data()
  fit <- drmTMB(
    bf(y ~ x + (1 | p | id), sigma ~ z + (1 | p | id)),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 250, iter.max = 250)
  )

  targets <- profile_targets(fit)
  ready_targets <- profile_targets(fit, ready_only = TRUE)
  mu_sigma_parms <- c(
    "sd:mu:(1 | p | id)",
    "sd:sigma:(1 | p | id)",
    "cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)"
  )
  mu_sigma_targets <- targets[match(mu_sigma_parms, targets$parm), ]

  expect_equal(mu_sigma_targets$parm, mu_sigma_parms)
  expect_equal(
    mu_sigma_targets$target_class,
    c(
      "random-effect-sd",
      "random-effect-sd",
      "random-effect-correlation"
    )
  )
  expect_equal(mu_sigma_targets$dpar, c("mu", "sigma", "mu_sigma"))
  expect_equal(
    mu_sigma_targets$tmb_parameter,
    c("log_sd_mu", "log_sd_sigma", "eta_cor_mu_sigma")
  )
  expect_equal(mu_sigma_targets$index, c(1L, 1L, 1L))
  expect_equal(mu_sigma_targets$transformation, c("exp", "exp", "tanh"))
  expect_equal(mu_sigma_targets$target_type, rep("direct", 3))
  expect_true(all(mu_sigma_targets$profile_ready))
  expect_equal(mu_sigma_targets$profile_note, rep("ready", 3))
  expect_true(all(mu_sigma_parms %in% ready_targets$parm))
  expect_false(any(targets$dpar == "rho12"))

  fit_registry <- fit
  names(fit_registry$corpars$mu_sigma) <- "cor(bad,bad | wrong | wrong)"
  registry_targets <- profile_targets(fit_registry)
  expect_true(mu_sigma_parms[[3L]] %in% registry_targets$parm)
})

test_that("confint profile intervals transform mu/sigma covariance targets", {
  dat <- new_profile_mu_sigma_group_data(
    n_id = 24L,
    n_each = 8L,
    rho_group = 0.2
  )
  fit <- drmTMB(
    bf(y ~ x + (1 | p | id), sigma ~ z + (1 | p | id)),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 300, iter.max = 300)
  )

  cor_parm <- "cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)"
  ci <- stats::confint(
    fit,
    parm = cor_parm,
    level = 0.80,
    method = "profile",
    trace = FALSE,
    ystep = 0.35
  )
  cor_hat <- unname(fit$corpars$mu_sigma[[1L]])

  expect_equal(ci$parm, cor_parm)
  expect_equal(ci$scale, "response")
  expect_equal(ci$transformation, "tanh")
  expect_equal(ci$tmb_parameter, "eta_cor_mu_sigma")
  expect_equal(ci$index, 1L)
  expect_equal(ci$method, "profile")
  expect_true(all(is.finite(c(ci$lower, ci$upper))))
  expect_true(all(abs(c(ci$lower, ci$upper)) < 1))
  expect_lt(ci$lower, cor_hat)
  expect_gt(ci$upper, cor_hat)
})

test_that("profile target inventory covers bivariate mu covariance labels", {
  dat <- new_profile_biv_group_data()
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

  targets <- profile_targets(fit)
  ready_targets <- profile_targets(fit, ready_only = TRUE)
  biv_parms <- c(
    "sd:mu:mu1:(1 | p | id)",
    "sd:mu:mu2:(1 | p | id)",
    "cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)"
  )
  biv_targets <- targets[match(biv_parms, targets$parm), ]

  expect_equal(biv_targets$parm, biv_parms)
  expect_equal(
    biv_targets$target_class,
    c(
      "random-effect-sd",
      "random-effect-sd",
      "random-effect-correlation"
    )
  )
  expect_equal(biv_targets$dpar, rep("mu", 3))
  expect_equal(
    biv_targets$tmb_parameter,
    c("log_sd_mu", "log_sd_mu", "eta_cor_mu")
  )
  expect_equal(biv_targets$index, c(1L, 2L, 1L))
  expect_equal(biv_targets$transformation, c("exp", "exp", "tanh"))
  expect_equal(biv_targets$target_type, rep("direct", 3))
  expect_true(all(biv_targets$profile_ready))
  expect_equal(biv_targets$profile_note, rep("ready", 3))
  expect_true(all(biv_parms %in% ready_targets$parm))

  rho12_targets <- targets[targets$dpar == "rho12", ]
  expect_true("rho12" %in% rho12_targets$parm)
  expect_equal(
    targets[targets$parm == "rho12", "target_class"],
    "residual-correlation"
  )
  expect_false(any(rho12_targets$parm %in% biv_parms))

  fit_registry <- fit
  names(fit_registry$corpars$mu) <- "cor(bad,bad | wrong | wrong)"
  registry_targets <- profile_targets(fit_registry)
  expect_true(biv_parms[[3L]] %in% registry_targets$parm)
})

test_that("profile targets can format fitted-like q=4 endpoint registry rows", {
  dat <- data.frame(
    y1 = c(-0.3, 0.1, 0.4, 0.8, -0.1, 0.6),
    y2 = c(0.2, -0.2, 0.5, 0.7, 0.1, 0.4)
  )
  fit <- drmTMB(
    bf(
      mu1 = y1 ~ 1,
      mu2 = y2 ~ 1,
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat
  )
  pair_labels <- c(
    "cor(mu1:(Intercept),mu2:(Intercept) | p | id)",
    "cor(mu1:(Intercept),sigma1:(Intercept) | p | id)",
    "cor(mu1:(Intercept),sigma2:(Intercept) | p | id)",
    "cor(mu2:(Intercept),sigma1:(Intercept) | p | id)",
    "cor(mu2:(Intercept),sigma2:(Intercept) | p | id)",
    "cor(sigma1:(Intercept),sigma2:(Intercept) | p | id)"
  )
  estimates <- c(0.12, -0.21, 0.16, 0.08, -0.14, 0.27)
  tmb_parameters <- rep("theta_re_cov", 6L)
  registry <- new_profile_q4_pair_registry(
    parameter = pair_labels,
    tmb_parameter = tmb_parameters,
    tmb_index = seq_along(pair_labels)
  )
  fit_q4 <- fit
  fit_q4$model$random$covariance_blocks <- registry
  fit_q4$corpars <- list(
    re_cov = stats::setNames(estimates, pair_labels)
  )
  fit_q4$opt$par <- c(
    fit_q4$opt$par,
    stats::setNames(rep(0, length(tmb_parameters)), tmb_parameters)
  )
  q4_parms <- paste0("cor:re_cov:", pair_labels)

  targets <- profile_targets(fit_q4)
  ready_targets <- profile_targets(fit_q4, ready_only = TRUE)
  q4_targets <- targets[match(q4_parms, targets$parm), ]

  expect_false(anyNA(q4_targets$parm))
  expect_equal(q4_targets$parm, q4_parms)
  expect_equal(
    q4_targets$target_class,
    rep("random-effect-correlation", 6L)
  )
  expect_equal(q4_targets$dpar, rep("re_cov", 6L))
  expect_equal(q4_targets$term, pair_labels)
  expect_equal(q4_targets$tmb_parameter, tmb_parameters)
  expect_equal(q4_targets$index, seq_along(pair_labels))
  expect_equal(q4_targets$estimate, estimates, tolerance = 1e-12)
  expect_true(all(is.na(q4_targets$link_estimate)))
  expect_equal(q4_targets$transformation, rep("unstructured_corr", 6L))
  expect_equal(q4_targets$target_type, rep("derived", 6L))
  expect_false(any(q4_targets$profile_ready))
  expect_equal(
    q4_targets$profile_note,
    rep("derived_unstructured_correlation", 6L)
  )
  expect_false(any(q4_parms %in% ready_targets$parm))
  expect_error(
    stats::confint(
      fit_q4,
      parm = q4_parms[[1L]],
      method = "profile",
      trace = FALSE
    ),
    "not ready for direct profiling"
  )

  fit_dormant <- fit
  fit_dormant$model$random$covariance_blocks <-
    new_profile_q4_pair_registry()
  dormant_targets <- profile_targets(fit_dormant)
  expect_false(any(grepl("scaffold:", dormant_targets$parm, fixed = TRUE)))

  registry_mixed <- new_profile_q4_pair_registry()
  registry_mixed$pairs$parameter[[1L]] <- pair_labels[[1L]]
  registry_mixed$pairs$tmb_parameter[[1L]] <- "eta_cor_mu"
  registry_mixed$pairs$tmb_index[[1L]] <- 1L
  fit_mixed <- fit
  fit_mixed$model$random$covariance_blocks <- registry_mixed
  fit_mixed$corpars <- list(
    mu = stats::setNames(estimates[[1L]], pair_labels[[1L]])
  )
  fit_mixed$opt$par <- c(
    fit_mixed$opt$par,
    stats::setNames(0, "eta_cor_mu")
  )
  mixed_targets <- profile_targets(fit_mixed)
  mixed_parm <- paste0("cor:mu:", pair_labels[[1L]])
  expect_equal(sum(mixed_targets$parm == mixed_parm), 1L)
  expect_false(any(grepl("scaffold:", mixed_targets$parm, fixed = TRUE)))
})

test_that("confint profile intervals transform bivariate mu covariance targets", {
  dat <- new_profile_biv_group_data()
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

  cor_parm <- "cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)"
  ci <- stats::confint(
    fit,
    parm = cor_parm,
    level = 0.80,
    method = "profile",
    trace = FALSE,
    ystep = 0.35
  )
  cor_hat <- unname(fit$corpars$mu[[1L]])

  expect_equal(ci$parm, cor_parm)
  expect_equal(ci$scale, "response")
  expect_equal(ci$transformation, "tanh")
  expect_equal(ci$tmb_parameter, "eta_cor_mu")
  expect_equal(ci$index, 1L)
  expect_equal(ci$method, "profile")
  expect_true(all(is.finite(c(ci$lower, ci$upper))))
  expect_true(all(abs(c(ci$lower, ci$upper)) < 1))
  expect_lt(ci$lower, cor_hat)
  expect_gt(ci$upper, cor_hat)
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

# Native Binomial probit and cloglog evidence for structured provider pairs
# with separate SD regressions:
#   animal(A) + (1 | site)                      [animal + iid]
#   relmat(K or Q) + (1 | group)                [relmat + iid]
#   phylo_interaction(tree1, tree2) intercept   [phylo-interaction intercept]
#
# Oracle: a dense Laplace approximation written in plain R. For
#   eta = X beta + Z u,  u ~ N(0, Sigma),  Sigma = blockdiag(D_k C_k D_k),
# the Laplace marginal log-likelihood is
#   l(u*) - u*' Sigma^-1 u* / 2 - log|I + Sigma Z' W Z| / 2,
# with W = -d2 l / d eta2 (observed). It uses the fitted mean and SD
# coefficients, so it checks the fitted likelihood and the SD-scale algebra
# independently of the TMB template.
#
# Tolerances are fixed before the first run:
#   dense oracle logLik       abs < 1e-4
#   constant-SD equivalence   logLik abs < 1e-5, log SD abs < 1e-3,
#                             mean coefficients abs < 1e-3
#   SD-slope recovery         abs error < 0.5 (as in the sibling tests)
#   max |gradient|            < 2e-2

bpp_inverse_link <- list(
  probit = stats::pnorm,
  cloglog = function(eta) -expm1(-exp(eta))
)

# Observed first and second derivatives of the Bernoulli log-likelihood in eta.
bpp_loglik_derivatives <- function(y, eta, link) {
  if (identical(link, "probit")) {
    p <- stats::pnorm(eta)
    p1 <- stats::dnorm(eta)
    p2 <- -eta * p1
  } else {
    e <- exp(eta)
    p <- -expm1(-e)
    p1 <- e * exp(-e)
    p2 <- p1 * (1 - e)
  }
  list(
    l = y * log(p) + (1 - y) * log1p(-p),
    d1 = p1 * (y - p) / (p * (1 - p)),
    d2 = p2 * (y - p) / (p * (1 - p)) -
      p1^2 * (y / p^2 + (1 - y) / (1 - p)^2)
  )
}

# blocks: list of list(Z = n x m indicator matrix, Sigma = m x m covariance).
bpp_dense_laplace <- function(y, eta_fixed, blocks, link) {
  Z <- do.call(cbind, lapply(blocks, `[[`, "Z"))
  m <- ncol(Z)
  Sigma <- matrix(0, m, m)
  at <- 0L
  for (block in blocks) {
    k <- ncol(block$Z)
    Sigma[at + seq_len(k), at + seq_len(k)] <- block$Sigma
    at <- at + k
  }
  Sigma_inv <- solve(Sigma)
  penalised <- function(u) {
    sum(bpp_loglik_derivatives(y, eta_fixed + drop(Z %*% u), link)$l) -
      0.5 * drop(crossprod(u, Sigma_inv %*% u))
  }
  u <- numeric(m)
  for (iteration in seq_len(200L)) {
    d <- bpp_loglik_derivatives(y, eta_fixed + drop(Z %*% u), link)
    gradient <- drop(crossprod(Z, d$d1)) - drop(Sigma_inv %*% u)
    hessian <- crossprod(Z, Z * (-d$d2)) + Sigma_inv
    step <- drop(solve(hessian, gradient))
    scale <- 1
    while (penalised(u + scale * step) < penalised(u) - 1e-12 && scale > 1e-8) {
      scale <- scale / 2
    }
    u <- u + scale * step
    if (max(abs(gradient)) < 1e-10) break
  }
  d <- bpp_loglik_derivatives(y, eta_fixed + drop(Z %*% u), link)
  W <- -d$d2
  log_det <- as.numeric(determinant(
    diag(m) + Sigma %*% crossprod(Z, Z * W), logarithm = TRUE
  )$modulus)
  sum(d$l) - 0.5 * drop(crossprod(u, Sigma_inv %*% u)) - 0.5 * log_det
}

bpp_indicator <- function(index, n_level) {
  Z <- matrix(0, length(index), n_level)
  Z[cbind(seq_along(index), index)] <- 1
  Z
}

bpp_sd_curve <- function(coef, z) exp(coef[[1L]] + coef[[2L]] * z)

# --- animal + iid ---------------------------------------------------------

bpp_animal_iid_fixture <- function(link, seed) {
  set.seed(seed)
  n_id <- 96L
  n_site <- 48L
  n_each <- 16L
  id_levels <- paste0("id", seq_len(n_id))
  site_levels <- paste0("site", seq_len(n_site))
  site_by_id <- sample(rep(site_levels, each = n_id / n_site))
  z_animal <- stats::setNames(seq(-1, 1, length.out = n_id), id_levels)
  z_iid <- stats::setNames(seq(-0.8, 0.8, length.out = n_site), site_levels)
  kernel_order <- rev(seq_len(n_id))
  A <- outer(kernel_order, kernel_order, function(i, j) 0.2^abs(i - j))
  dimnames(A) <- list(id_levels[kernel_order], id_levels[kernel_order])
  animal_draw <- as.vector(t(chol(A)) %*% stats::rnorm(n_id))
  names(animal_draw) <- rownames(A)
  animal_draw <- (animal_draw *
                    exp(-0.7 + 0.75 * z_animal)[names(animal_draw)])[id_levels]
  iid_draw <- stats::setNames(
    stats::rnorm(n_site, sd = exp(-0.8 - 0.65 * z_iid)), site_levels
  )
  id_index <- rep(seq_len(n_id), each = n_each)
  site_index <- match(site_by_id[id_index], site_levels)
  id <- factor(id_levels[id_index], levels = id_levels)
  site <- factor(site_levels[site_index], levels = site_levels)
  x <- stats::rnorm(length(id))
  eta <- -0.2 + 0.3 * x + animal_draw[as.character(id)] +
    iid_draw[as.character(site)]
  data <- data.frame(
    y = stats::rbinom(length(id), 1L, bpp_inverse_link[[link]](eta)),
    x = x, id = id, site = site,
    z_animal = unname(z_animal[as.character(id)]),
    z_iid = unname(z_iid[as.character(site)])
  )
  list(data = data, A = A, z_animal = z_animal, z_iid = z_iid,
       id_levels = id_levels, site_levels = site_levels)
}

test_that("Binomial probit and cloglog animal plus IID fits match a dense Laplace oracle", {
  skip_on_cran()
  for (link in c("probit", "cloglog")) {
    fx <- bpp_animal_iid_fixture(
      link, if (link == "probit") 20261201L else 20261202L
    )
    A <- fx$A
    fit <- drmTMB(
      bf(y ~ x + animal(1 | id, A = A) + (1 | site),
         sd(id, level = "animal") ~ z_animal,
         sd(site) ~ z_iid),
      family = stats::binomial(link = link), data = fx$data,
      control = drm_control(se = FALSE)
    )
    expect_identical(fit$opt$convergence, 0L, info = link)
    expect_true(max(abs(fit$obj$gr(fit$opt$par))) < 2e-2, info = link)
    expect_setequal(names(coef(fit)),
                    c("mu", "sd_animal(id)", "sd(site)"))

    animal_coef <- coef(fit, "sd_animal(id)")
    iid_coef <- coef(fit, "sd(site)")
    expect_gt(animal_coef[["z_animal"]], 0)
    expect_lt(iid_coef[["z_iid"]], 0)
    expect_lt(abs(animal_coef[["z_animal"]] - 0.75), 0.5)
    expect_lt(abs(iid_coef[["z_iid"]] + 0.65), 0.5)

    animal_sd <- bpp_sd_curve(animal_coef, fx$z_animal)
    iid_sd <- bpp_sd_curve(iid_coef, fx$z_iid)
    expect_equal(predict(fit, dpar = "sd_animal(id)")[fx$id_levels],
                 animal_sd, tolerance = 1e-8, info = link)
    expect_equal(predict(fit, dpar = "sd(site)")[fx$site_levels],
                 iid_sd, tolerance = 1e-8, info = link)

    mu <- coef(fit, "mu")
    D_animal <- animal_sd[rownames(A)]
    blocks <- list(
      list(Z = bpp_indicator(match(fx$data$id, rownames(A)), nrow(A)),
           Sigma = outer(D_animal, D_animal) * A),
      list(Z = bpp_indicator(as.integer(fx$data$site),
                             length(fx$site_levels)),
           Sigma = diag(iid_sd[fx$site_levels]^2))
    )
    dense <- bpp_dense_laplace(
      fx$data$y, mu[[1L]] + mu[[2L]] * fx$data$x, blocks, link
    )
    expect_lt(abs(as.numeric(logLik(fit)) - dense), 1e-4, label = link)

    simulated <- simulate(fit, nsim = 1L, seed = 20261203L)
    expect_true(all(simulated[[1L]] %in% c(0, 1)), info = link)
  }
})

test_that("Binomial probit and cloglog animal plus IID constant SD matches the plain model", {
  skip_on_cran()
  for (link in c("probit", "cloglog")) {
    fx <- bpp_animal_iid_fixture(
      link, if (link == "probit") 20261204L else 20261205L
    )
    A <- fx$A
    plain <- drmTMB(
      bf(y ~ x + animal(1 | id, A = A) + (1 | site)),
      family = stats::binomial(link = link), data = fx$data,
      control = drm_control(se = FALSE)
    )
    constant <- drmTMB(
      bf(y ~ x + animal(1 | id, A = A) + (1 | site),
         sd(id, level = "animal") ~ 1,
         sd(site) ~ 1),
      family = stats::binomial(link = link), data = fx$data,
      control = drm_control(se = FALSE)
    )
    expect_identical(plain$opt$convergence, 0L, info = link)
    expect_identical(constant$opt$convergence, 0L, info = link)
    expect_lt(abs(as.numeric(logLik(constant)) - as.numeric(logLik(plain))),
              1e-5, label = link)
    expect_equal(coef(constant, "mu"), coef(plain, "mu"),
                 tolerance = 1e-3, info = link)
    plain_sd <- plain$sdpars$mu
    expect_equal(unname(coef(constant, "sd_animal(id)")[["(Intercept)"]]),
                 unname(log(plain_sd[grepl("animal", names(plain_sd))])),
                 tolerance = 1e-3, info = link)
    expect_equal(unname(coef(constant, "sd(site)")[["(Intercept)"]]),
                 unname(log(plain_sd[grepl("site", names(plain_sd))])),
                 tolerance = 1e-3, info = link)
  }
})

# --- relmat + iid ----------------------------------------------------------

bpp_relmat_iid_fixture <- function(link, seed) {
  set.seed(seed)
  n_group <- 40L
  n_population <- 40L
  n_replicate <- 2L
  group_levels <- paste0("group_", seq_len(n_group))
  population_levels <- paste0("population_", seq_len(n_population))
  z_group <- stats::setNames(stats::rnorm(n_group), group_levels)
  z_population <- stats::setNames(stats::rnorm(n_population), population_levels)
  group_sd <- exp(log(0.45) + 0.35 * z_group)
  population_sd <- exp(log(0.50) - 0.40 * z_population)
  population_order <- rev(seq_len(n_population))
  K <- outer(population_order, population_order,
             function(i, j) 0.55^abs(i - j))
  dimnames(K) <- list(population_levels[population_order],
                      population_levels[population_order])
  group_effect <- stats::rnorm(n_group) * group_sd
  population_field <- as.vector(t(chol(K)) %*% stats::rnorm(n_population))
  names(population_field) <- rownames(K)
  population_effect <- (population_field *
                          population_sd[rownames(K)])[population_levels]
  design <- expand.grid(
    replicate = seq_len(n_replicate),
    group_index = seq_len(n_group),
    population_index = seq_len(n_population)
  )
  x <- stats::rnorm(nrow(design))
  eta <- -0.15 + 0.25 * x +
    group_effect[design$group_index] +
    population_effect[design$population_index]
  data <- data.frame(
    y = stats::rbinom(nrow(design), 1L, bpp_inverse_link[[link]](eta)),
    x = x,
    group = factor(group_levels[design$group_index], levels = group_levels),
    population = factor(population_levels[design$population_index],
                        levels = population_levels),
    z_group = unname(z_group[design$group_index]),
    z_population = unname(z_population[design$population_index])
  )
  list(data = data, K = K, Q = solve(K), z_group = z_group,
       z_population = z_population, group_levels = group_levels,
       population_levels = population_levels)
}

test_that("Binomial probit and cloglog relmat plus IID fits match a dense Laplace oracle", {
  skip_on_cran()
  for (link in c("probit", "cloglog")) {
    fx <- bpp_relmat_iid_fixture(
      link, if (link == "probit") 20261206L else 20261207L
    )
    K <- fx$K
    Q <- fx$Q
    fit_k <- drmTMB(
      bf(y ~ x + (1 | group) + relmat(1 | population, K = K),
         sd(group) ~ z_group,
         sd(population, level = "relmat") ~ z_population),
      family = stats::binomial(link = link), data = fx$data,
      control = drm_control(se = FALSE)
    )
    fit_q <- drmTMB(
      bf(y ~ x + (1 | group) + relmat(1 | population, Q = Q),
         sd(group) ~ z_group,
         sd(population, level = "relmat") ~ z_population),
      family = stats::binomial(link = link), data = fx$data,
      control = drm_control(se = FALSE)
    )
    for (fit in list(fit_k, fit_q)) {
      expect_identical(fit$opt$convergence, 0L, info = link)
      expect_true(max(abs(fit$obj$gr(fit$opt$par))) < 2e-2, info = link)
    }
    expect_setequal(names(coef(fit_k)),
                    c("mu", "sd(group)", "sd_relmat(population)"))
    group_coef <- coef(fit_k, "sd(group)")
    relmat_coef <- coef(fit_k, "sd_relmat(population)")
    expect_lt(abs(group_coef[["z_group"]] - 0.35), 0.5)
    expect_lt(abs(relmat_coef[["z_population"]] + 0.40), 0.5)

    group_sd <- bpp_sd_curve(group_coef, fx$z_group)
    population_sd <- bpp_sd_curve(relmat_coef, fx$z_population)
    expect_equal(predict(fit_k, dpar = "sd(group)")[fx$group_levels],
                 group_sd, tolerance = 1e-8, info = link)
    expect_equal(
      predict(fit_k, dpar = "sd_relmat(population)")[fx$population_levels],
      population_sd, tolerance = 1e-8, info = link
    )

    mu <- coef(fit_k, "mu")
    D_population <- population_sd[rownames(K)]
    blocks <- list(
      list(Z = bpp_indicator(as.integer(fx$data$group),
                             length(fx$group_levels)),
           Sigma = diag(group_sd[fx$group_levels]^2)),
      list(Z = bpp_indicator(match(fx$data$population, rownames(K)),
                             nrow(K)),
           Sigma = outer(D_population, D_population) * K)
    )
    dense <- bpp_dense_laplace(
      fx$data$y, mu[[1L]] + mu[[2L]] * fx$data$x, blocks, link
    )
    expect_lt(abs(as.numeric(logLik(fit_k)) - dense), 1e-4,
              label = paste(link, "K"))
    # The precision input Q = K^-1 targets the same likelihood.
    mu_q <- coef(fit_q, "mu")
    blocks_q <- blocks
    blocks_q[[1L]]$Sigma <- diag(
      bpp_sd_curve(coef(fit_q, "sd(group)"), fx$z_group)[fx$group_levels]^2
    )
    q_population_sd <- bpp_sd_curve(
      coef(fit_q, "sd_relmat(population)"), fx$z_population
    )[rownames(K)]
    blocks_q[[2L]]$Sigma <- outer(q_population_sd, q_population_sd) * K
    dense_q <- bpp_dense_laplace(
      fx$data$y, mu_q[[1L]] + mu_q[[2L]] * fx$data$x, blocks_q, link
    )
    expect_lt(abs(as.numeric(logLik(fit_q)) - dense_q), 1e-4,
              label = paste(link, "Q"))
  }
})

test_that("Binomial probit and cloglog relmat plus IID constant SD matches the plain model", {
  skip_on_cran()
  for (link in c("probit", "cloglog")) {
    fx <- bpp_relmat_iid_fixture(
      link, if (link == "probit") 20261208L else 20261209L
    )
    K <- fx$K
    plain <- drmTMB(
      bf(y ~ x + (1 | group) + relmat(1 | population, K = K)),
      family = stats::binomial(link = link), data = fx$data,
      control = drm_control(se = FALSE)
    )
    constant <- drmTMB(
      bf(y ~ x + (1 | group) + relmat(1 | population, K = K),
         sd(group) ~ 1,
         sd(population, level = "relmat") ~ 1),
      family = stats::binomial(link = link), data = fx$data,
      control = drm_control(se = FALSE)
    )
    expect_identical(plain$opt$convergence, 0L, info = link)
    expect_identical(constant$opt$convergence, 0L, info = link)
    expect_lt(abs(as.numeric(logLik(constant)) - as.numeric(logLik(plain))),
              1e-5, label = link)
    expect_equal(coef(constant, "mu"), coef(plain, "mu"),
                 tolerance = 1e-3, info = link)
    plain_sd <- plain$sdpars$mu
    expect_equal(unname(coef(constant, "sd(group)")[["(Intercept)"]]),
                 unname(log(plain_sd[grepl("group", names(plain_sd))])),
                 tolerance = 1e-3, info = link)
    expect_equal(
      unname(coef(constant, "sd_relmat(population)")[["(Intercept)"]]),
      unname(log(plain_sd[grepl("relmat", names(plain_sd))])),
      tolerance = 1e-3, info = link
    )
  }
})

# --- phylo-interaction intercept ----------------------------------------------

bpp_phylo_tree <- function(n_tip, prefix) {
  stopifnot(n_tip >= 2L, log2(n_tip) == floor(log2(n_tip)))
  edges <- matrix(integer(), ncol = 2L)
  edge_lengths <- numeric()
  next_node <- n_tip + 1L
  build <- function(tips) {
    if (length(tips) == 1L) return(tips)
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
    list(edge = edges, edge.length = edge_lengths,
         tip.label = paste0(prefix, seq_len(n_tip)), Nnode = n_tip - 1L),
    class = "phylo"
  )
}

bpp_phylo_interaction_fixture <- function(link, seed) {
  set.seed(seed)
  n_each <- 24L
  plant_tree <- bpp_phylo_tree(8L, "plant_")
  pollinator_tree <- bpp_phylo_tree(8L, "poll_")
  A1 <- drmTMB:::drm_phylo_tip_covariance(plant_tree)
  A2 <- drmTMB:::drm_phylo_tip_covariance(pollinator_tree)
  pair_cov <- kronecker(A2, A1)
  pair_grid <- expand.grid(
    plant = plant_tree$tip.label, pollinator = pollinator_tree$tip.label,
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  pair_grid$pair <- paste(pair_grid$plant, pair_grid$pollinator, sep = ":")
  z_pair <- as.numeric(scale(stats::rnorm(nrow(pair_grid))))
  pair_sd <- exp(log(0.45) + 0.45 * z_pair)
  pair_effect <- pair_sd *
    as.vector(t(chol(pair_cov)) %*% stats::rnorm(nrow(pair_grid)))
  row <- rep(seq_len(nrow(pair_grid)), each = n_each)
  data <- pair_grid[row, , drop = FALSE]
  data$z_pair <- z_pair[row]
  data$x <- stats::rnorm(nrow(data))
  eta <- 0.15 + 0.3 * data$x + pair_effect[row]
  data$y <- stats::rbinom(nrow(data), 1L, bpp_inverse_link[[link]](eta))
  list(data = data, plant_tree = plant_tree, pollinator_tree = pollinator_tree,
       pair_cov = pair_cov, pair_grid = pair_grid, z_pair = z_pair, row = row)
}

test_that("Binomial probit and cloglog phylo-interaction intercept SD matches a dense Laplace oracle", {
  skip_on_cran()
  for (link in c("probit", "cloglog")) {
    fx <- bpp_phylo_interaction_fixture(
      link, if (link == "probit") 20261210L else 20261211L
    )
    plant_tree <- fx$plant_tree
    pollinator_tree <- fx$pollinator_tree
    fit <- drmTMB(
      bf(y ~ x + phylo_interaction(1 | plant:pollinator,
                                   tree1 = plant_tree,
                                   tree2 = pollinator_tree),
         sd(pair, level = "phylogenetic_interaction") ~ z_pair),
      family = stats::binomial(link = link), data = fx$data,
      control = drm_control(se = FALSE)
    )
    expect_identical(fit$opt$convergence, 0L, info = link)
    expect_true(max(abs(fit$obj$gr(fit$opt$par))) < 2e-2, info = link)
    sd_coef <- coef(fit, "sd_phylo(pair)")
    expect_gt(sd_coef[["z_pair"]], 0)
    expect_lt(abs(sd_coef[["z_pair"]] - 0.45), 0.5)

    pair_sd <- bpp_sd_curve(sd_coef, fx$z_pair)
    predicted <- predict(fit, dpar = "sd_phylo(pair)")
    expect_equal(names(predicted), fx$pair_grid$pair, info = link)
    expect_equal(unname(predicted), pair_sd, tolerance = 1e-8, info = link)

    mu <- coef(fit, "mu")
    blocks <- list(list(
      Z = bpp_indicator(fx$row, nrow(fx$pair_grid)),
      Sigma = outer(pair_sd, pair_sd) * fx$pair_cov
    ))
    dense <- bpp_dense_laplace(
      fx$data$y, mu[[1L]] + mu[[2L]] * fx$data$x, blocks, link
    )
    expect_lt(abs(as.numeric(logLik(fit)) - dense), 1e-4, label = link)

    simulated <- simulate(fit, nsim = 1L, seed = 20261212L)
    expect_true(all(simulated[[1L]] %in% c(0, 1)), info = link)
  }
})

test_that("Binomial probit and cloglog phylo-interaction constant SD matches the plain model", {
  skip_on_cran()
  for (link in c("probit", "cloglog")) {
    fx <- bpp_phylo_interaction_fixture(
      link, if (link == "probit") 20261213L else 20261214L
    )
    plant_tree <- fx$plant_tree
    pollinator_tree <- fx$pollinator_tree
    plain <- drmTMB(
      bf(y ~ x + phylo_interaction(1 | plant:pollinator,
                                   tree1 = plant_tree,
                                   tree2 = pollinator_tree)),
      family = stats::binomial(link = link), data = fx$data,
      control = drm_control(se = FALSE)
    )
    constant <- drmTMB(
      bf(y ~ x + phylo_interaction(1 | plant:pollinator,
                                   tree1 = plant_tree,
                                   tree2 = pollinator_tree),
         sd(pair, level = "phylogenetic_interaction") ~ 1),
      family = stats::binomial(link = link), data = fx$data,
      control = drm_control(se = FALSE)
    )
    expect_identical(plain$opt$convergence, 0L, info = link)
    expect_identical(constant$opt$convergence, 0L, info = link)
    expect_lt(abs(as.numeric(logLik(constant)) - as.numeric(logLik(plain))),
              1e-5, label = link)
    expect_equal(coef(constant, "mu"), coef(plain, "mu"),
                 tolerance = 1e-3, info = link)
    plain_sd <- plain$sdpars$mu
    expect_equal(unname(coef(constant, "sd_phylo(pair)")[["(Intercept)"]]),
                 unname(log(plain_sd[[1L]])), tolerance = 1e-3, info = link)
  }
})

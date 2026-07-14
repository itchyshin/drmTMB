# Arc 3a: positive-continuous q1 structured mu intercepts.
#
# These tests cover native-TMB univariate ML point fitting only. They do not
# provide interval, coverage, REML, q2+, multiple-provider, or Julia evidence.

arc3a_balanced_tree <- function(n_tip = 8L) {
  stopifnot(n_tip >= 2L, log2(n_tip) == floor(log2(n_tip)))
  edge <- matrix(integer(), ncol = 2L)
  edge_length <- numeric()
  next_node <- n_tip + 1L

  build <- function(tips) {
    if (length(tips) == 1L) {
      return(tips)
    }
    node <- next_node
    next_node <<- next_node + 1L
    half <- length(tips) / 2L
    left <- build(tips[seq_len(half)])
    right <- build(tips[seq.int(half + 1L, length(tips))])
    edge <<- rbind(edge, c(node, left), c(node, right))
    edge_length <<- c(edge_length, 1, 1)
    node
  }

  build(seq_len(n_tip))
  structure(
    list(
      edge = edge,
      edge.length = edge_length,
      tip.label = sprintf("g%03d", seq_len(n_tip)),
      Nnode = n_tip - 1L
    ),
    class = "phylo"
  )
}

arc3a_relatedness <- function(n_level = 8L, rho = 0.5) {
  labels <- sprintf("g%03d", seq_len(n_level))
  K <- outer(seq_len(n_level), seq_len(n_level), function(i, j) {
    rho^abs(i - j)
  })
  dimnames(K) <- list(labels, labels)
  K
}

arc3a_draw_field <- function(covariance, tau) {
  out <- as.vector(t(chol(covariance)) %*% stats::rnorm(nrow(covariance))) * tau
  names(out) <- rownames(covariance)
  out
}

new_arc3a_positive_data <- function(
  family = c("lognormal", "gamma"),
  provider = c("phylo", "relmat"),
  seed = 2026071403L,
  n_level = 8L,
  n_each = 16L,
  beta_mu = c(`(Intercept)` = 0.20, x = 0.35),
  beta_sigma = log(0.35),
  tau = 0.50
) {
  family <- match.arg(family)
  provider <- match.arg(provider)
  set.seed(seed)

  tree <- arc3a_balanced_tree(n_level)
  K <- arc3a_relatedness(n_level)
  Q <- solve(K)
  covariance <- if (identical(provider, "phylo")) {
    drmTMB:::drm_phylo_tip_covariance(tree)
  } else {
    K
  }
  field <- arc3a_draw_field(covariance, tau)
  level <- rep(names(field), each = n_each)
  x <- stats::rnorm(length(level))
  eta_mu <- beta_mu[["(Intercept)"]] + beta_mu[["x"]] * x + field[level]
  sigma <- exp(beta_sigma)
  y <- if (identical(family, "lognormal")) {
    stats::rlnorm(length(level), meanlog = eta_mu, sdlog = sigma)
  } else {
    stats::rgamma(
      length(level),
      shape = 1 / sigma^2,
      scale = exp(eta_mu) * sigma^2
    )
  }

  data <- data.frame(
    y = unname(y),
    x = x,
    species = factor(level, levels = names(field)),
    id = factor(level, levels = names(field)),
    site = factor(rep(sprintf("s%02d", seq_len(4L)), length.out = length(level)))
  )
  data$y2 <- data$y * exp(stats::rnorm(nrow(data), sd = 0.05))
  data$plant <- factor(rep(tree$tip.label[seq_len(4L)], length.out = nrow(data)))
  data$pollinator <- factor(
    rep(tree$tip.label[seq.int(5L, 8L)], length.out = nrow(data))
  )

  list(
    data = data,
    tree = tree,
    K = K,
    Q = Q,
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    tau = tau,
    field = field,
    eta_mu = eta_mu,
    sigma = sigma
  )
}

arc3a_family <- function(family) {
  if (identical(family, "lognormal")) {
    lognormal()
  } else {
    stats::Gamma(link = "log")
  }
}

fit_arc3a_positive <- function(
  sim,
  family,
  provider,
  representation = "K",
  se = FALSE
) {
  tree <- sim$tree
  K <- sim$K
  Q <- sim$Q
  formula <- if (identical(provider, "phylo")) {
    bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)
  } else if (identical(representation, "K")) {
    bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1)
  } else {
    bf(y ~ x + relmat(1 | id, Q = Q), sigma ~ 1)
  }
  drmTMB(
    formula,
    family = arc3a_family(family),
    data = sim$data,
    REML = FALSE,
    control = drm_control(
      se = se,
      optimizer = list(eval.max = 600, iter.max = 600)
    )
  )
}

arc3a_formula_from_text <- function(mu, sigma = "sigma ~ 1", env = parent.frame()) {
  calls <- list(str2lang(mu), str2lang(sigma))
  names <- c("", "")
  structure(
    list(
      calls = calls,
      names = names,
      entries = drmTMB:::parse_drm_formula_entries(calls, names),
      env = env
    ),
    class = "drm_formula"
  )
}

expect_arc3a_fit_contract <- function(fit, family, provider) {
  key <- paste0(provider, "_mu")
  group <- if (identical(provider, "phylo")) "species" else "id"
  sd_name <- sprintf("%s(1 | %s)", provider, group)

  expect_s3_class(fit, "drmTMB")
  expect_identical(fit$model$model_type, family)
  expect_equal(as.integer(fit$opt$convergence), 0L)
  expect_true(is.finite(as.numeric(stats::logLik(fit))))
  expect_identical(fit$model$structured$phylo_mu$type, provider)
  expect_equal(fit$model$structured$phylo_mu$q, 1L)
  expect_identical(fit$model$structured$phylo_mu$coef_names, "(Intercept)")
  expect_named(fit$sdpars$mu, sd_name)
  expect_length(fit$sdpars$mu, 1L)
  expect_true(is.finite(unname(fit$sdpars$mu[[sd_name]])))
  expect_gt(unname(fit$sdpars$mu[[sd_name]]), 0)
  expect_null(fit$sdpars$sigma)
  expect_length(fit$corpars, 0L)
  expect_named(fit$random_effects, key)

  structured_re <- ranef(fit, key)
  expect_identical(structured_re, fit$random_effects[[key]])
  expect_named(structured_re$terms, sd_name)
  expect_length(structured_re$terms, 1L)

  contribution <- drmTMB:::phylo_mu_contribution(fit, dpar = "mu")
  index <- fit$model$structured$phylo_mu$observation_node_index
  # u_phylo is already the scaled field b. This identity catches an accidental
  # second multiplication by the reported structured scale.
  expect_equal(
    unname(contribution),
    unname(structured_re$terms[[sd_name]][index]),
    tolerance = 1e-8
  )

  fixed_link <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  conditional_link <- predict(fit, dpar = "mu", type = "link")
  expect_equal(
    unname(conditional_link),
    fixed_link + contribution,
    tolerance = 1e-8
  )
  expect_identical(names(coef(fit, "mu")), c("(Intercept)", "x"))
  expect_identical(names(coef(fit, "sigma")), "(Intercept)")
}

test_that("Arc 3a cells fit known DGPs with the intended component labels", {
  testthat::skip_if_not_installed("ape")
  routes <- list(
    list(family = "gamma", provider = "phylo", representation = "tree"),
    list(family = "lognormal", provider = "phylo", representation = "tree"),
    list(family = "lognormal", provider = "relmat", representation = "K")
  )

  for (i in seq_along(routes)) {
    route <- routes[[i]]
    sim <- new_arc3a_positive_data(
      family = route$family,
      provider = route$provider,
      seed = 2026071410L + i
    )
    fit <- fit_arc3a_positive(
      sim,
      family = route$family,
      provider = route$provider,
      representation = route$representation
    )
    expect_arc3a_fit_contract(fit, route$family, route$provider)
    expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.80)
    expect_lt(abs(coef(fit, "sigma")[[1L]] - sim$beta_sigma), 0.80)
    expect_true(all(is.finite(ranef(fit)[[paste0(route$provider, "_mu")]]$values)))
  }
})

test_that("lognormal relmat K and Q routes are numerically equivalent", {
  sim <- new_arc3a_positive_data(
    family = "lognormal",
    provider = "relmat",
    seed = 2026071421L
  )
  fit_K <- fit_arc3a_positive(sim, "lognormal", "relmat", "K")
  fit_Q <- fit_arc3a_positive(sim, "lognormal", "relmat", "Q")

  for (fit in list(fit_K, fit_Q)) {
    expect_arc3a_fit_contract(fit, "lognormal", "relmat")
  }
  expect_equal(
    as.numeric(stats::logLik(fit_K)),
    as.numeric(stats::logLik(fit_Q)),
    tolerance = 1e-6
  )
  expect_equal(coef(fit_K, "mu"), coef(fit_Q, "mu"), tolerance = 1e-5)
  expect_equal(coef(fit_K, "sigma"), coef(fit_Q, "sigma"), tolerance = 1e-5)
  expect_equal(fit_K$sdpars$mu, fit_Q$sdpars$mu, tolerance = 1e-5)
  expect_equal(
    ranef(fit_K, "relmat_mu")$values,
    ranef(fit_Q, "relmat_mu")$values,
    tolerance = 1e-4
  )
})

test_that("lognormal structured likelihood matches transformed Gaussian likelihood", {
  sim <- new_arc3a_positive_data(
    family = "lognormal",
    provider = "relmat",
    seed = 2026071422L
  )
  K <- sim$K
  fit_lognormal <- fit_arc3a_positive(sim, "lognormal", "relmat", "K")
  dat_gaussian <- transform(sim$data, log_y = log(y))
  fit_gaussian <- drmTMB(
    bf(log_y ~ x + relmat(1 | id, K = K), sigma ~ 1),
    family = gaussian(),
    data = dat_gaussian,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 600, iter.max = 600)
    )
  )

  expect_equal(coef(fit_lognormal, "mu"), coef(fit_gaussian, "mu"), tolerance = 1e-5)
  expect_equal(
    coef(fit_lognormal, "sigma"),
    coef(fit_gaussian, "sigma"),
    tolerance = 1e-5
  )
  expect_equal(fit_lognormal$sdpars$mu, fit_gaussian$sdpars$mu, tolerance = 1e-5)
  expect_equal(
    ranef(fit_lognormal, "relmat_mu")$values,
    ranef(fit_gaussian, "relmat_mu")$values,
    tolerance = 1e-4
  )
  expect_equal(
    as.numeric(stats::logLik(fit_lognormal)),
    as.numeric(stats::logLik(fit_gaussian)) - sum(log(sim$data$y)),
    tolerance = 1e-5
  )
})

test_that("Gamma relmat comparator retains conditional prediction and one-slope support", {
  sim <- new_arc3a_positive_data(
    family = "gamma",
    provider = "relmat",
    seed = 2026071423L
  )
  fit <- fit_arc3a_positive(sim, "gamma", "relmat", "K")
  expect_arc3a_fit_contract(fit, "gamma", "relmat")

  K <- sim$K
  fit_slope <- drmTMB(
    bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1),
    family = stats::Gamma(link = "log"),
    data = sim$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(as.integer(fit_slope$opt$convergence), 0L)
  expect_named(
    fit_slope$sdpars$mu,
    c("relmat(1 | id)", "relmat(0 + x | id)")
  )
  expect_named(ranef(fit_slope, "relmat_mu")$terms, names(fit_slope$sdpars$mu))
})

test_that("Arc 3a new routes reject slopes, labels, and extra variance layers", {
  testthat::skip_if_not_installed("ape")
  cases <- list(
    list(family = "gamma", provider = "phylo"),
    list(family = "lognormal", provider = "phylo"),
    list(family = "lognormal", provider = "relmat")
  )

  for (i in seq_along(cases)) {
    case <- cases[[i]]
    sim <- new_arc3a_positive_data(case$family, case$provider, 2026071430L + i)
    tree <- sim$tree
    K <- sim$K
    marker <- if (identical(case$provider, "phylo")) {
      "phylo(%s | species, tree = tree)"
    } else {
      "relmat(%s | id, K = K)"
    }
    family <- arc3a_family(case$family)

    for (lhs in c("0 + x", "1 + x", "1 + x + site")) {
      expect_error(
        drmTMB(
          arc3a_formula_from_text(sprintf("y ~ x + %s", sprintf(marker, lhs))),
          family = family,
          data = sim$data
        ),
        "intercept-only|intercept and one-slope"
      )
    }
    labelled <- if (identical(case$provider, "phylo")) {
      "y ~ x + phylo(1 | p | species, tree = tree)"
    } else {
      "y ~ x + relmat(1 | p | id, K = K)"
    }
    expect_error(
      drmTMB(arc3a_formula_from_text(labelled), family = family, data = sim$data),
      "unlabelled q=1"
    )

    sigma_marker <- if (identical(case$provider, "phylo")) {
      "sigma ~ phylo(1 | species, tree = tree)"
    } else {
      "sigma ~ relmat(1 | id, K = K)"
    }
    expect_error(
      drmTMB(
        arc3a_formula_from_text("y ~ x", sigma_marker),
        family = family,
        data = sim$data
      ),
      "sigma|pure-mu|fixed-effect"
    )
    expect_error(
      drmTMB(
        arc3a_formula_from_text(
          sprintf("y ~ x + %s", sprintf(marker, "1")),
          sigma_marker
        ),
        family = family,
        data = sim$data
      ),
      "sigma|joint|pure-mu|fixed-effect"
    )
    expect_error(
      drmTMB(
        arc3a_formula_from_text(
          sprintf("y ~ x + (1 | site) + %s", sprintf(marker, "1"))
        ),
        family = family,
        data = sim$data
      ),
      "ordinary|structured|cannot be combined|pure-mu"
    )
    expect_error(
      drmTMB(
        arc3a_formula_from_text(
          sprintf("y ~ x + %s", sprintf(marker, "1")),
          "sigma ~ 1 + (1 | site)"
        ),
        family = family,
        data = sim$data
      ),
      "sigma|fixed-effect|pure-mu"
    )
  }
})

test_that("Arc 3a new routes reject multiple and deferred structured providers", {
  testthat::skip_if_not_installed("ape")
  sim <- new_arc3a_positive_data("lognormal", "relmat", 2026071440L)
  tree <- sim$tree
  K <- sim$K
  coords <- data.frame(
    x = seq_len(nrow(K)),
    y = rep(c(0, 1), length.out = nrow(K)),
    row.names = rownames(K)
  )
  pedigree <- data.frame(
    id = rownames(K),
    dam = NA_character_,
    sire = NA_character_
  )
  plant_tree <- tree
  pollinator_tree <- tree

  for (family in list(lognormal(), stats::Gamma(link = "log"))) {
    expect_error(
      drmTMB(
        arc3a_formula_from_text(
          "y ~ x + phylo(1 | species, tree = tree) + relmat(1 | id, K = K)"
        ),
        family = family,
        data = sim$data
      ),
      "one structured|one.*provider|phylo.*relmat|relmat.*phylo"
    )
    expect_error(
      drmTMB(
        arc3a_formula_from_text(
          "y ~ x + phylo(1 | species, tree = tree) + phylo(1 | id, tree = tree)"
        ),
        family = family,
        data = sim$data
      ),
      "one.*phylo|one structured"
    )
    expect_error(
      drmTMB(
        arc3a_formula_from_text("y ~ x + spatial(1 | id, coords = coords)"),
        family = family,
        data = sim$data
      ),
      "spatial|phylo|relmat|structured"
    )
    expect_error(
      drmTMB(
        arc3a_formula_from_text("y ~ x + animal(1 | id, pedigree = pedigree)"),
        family = family,
        data = sim$data
      ),
      "animal|phylo|relmat|structured"
    )
    expect_error(
      drmTMB(
        arc3a_formula_from_text(paste(
          "y ~ x + phylo_interaction(",
          "1 | plant:pollinator,",
          "tree1 = plant_tree, tree2 = pollinator_tree)"
        )),
        family = family,
        data = sim$data
      ),
      "phylo_interaction|bipartite|structured"
    )
  }
})

test_that("Arc 3a routes reject REML and bivariate positive responses", {
  testthat::skip_if_not_installed("ape")
  for (family_name in c("gamma", "lognormal")) {
    sim <- new_arc3a_positive_data(family_name, "phylo", 2026071450L)
    tree <- sim$tree
    family <- arc3a_family(family_name)
    accepted <- bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)
    expect_error(
      drmTMB(accepted, family = family, data = sim$data, REML = TRUE),
      "REML.*only.*Gaussian"
    )
    expect_error(
      drmTMB(
        bf(mvbind(y, y2) ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
        family = family,
        data = sim$data
      ),
      "one positive response|bivariate|one response"
    )
  }
})

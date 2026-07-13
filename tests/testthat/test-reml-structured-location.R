# Arc 1a: exact-Gaussian REML for pure mean-side spatial, animal, and
# relatedness structured effects. The public gate admits only unlabelled
# intercept-only and independent intercept-plus-one-slope terms.

arc1a_pedigree <- function(labels) {
  n <- length(labels)
  dam <- sire <- rep(NA_character_, n)
  if (n > 4L) {
    child <- 5:n
    dam[child] <- labels[rep(1:4, length.out = length(child))]
    sire[child] <- labels[rep(2:5, length.out = length(child))]
  }
  data.frame(id = labels, dam = dam, sire = sire, stringsAsFactors = FALSE)
}

arc1a_provider_fixture <- function(
  provider,
  shape = c("intercept", "one_slope"),
  g = 12L,
  n_each = 12L,
  seed = 20260714L,
  unobserved_level = FALSE
) {
  shape <- match.arg(shape)
  set.seed(seed)
  n_level <- g + as.integer(unobserved_level)
  labels <- paste0("id", seq_len(n_level))
  observed <- labels[seq_len(g)]

  if (identical(provider, "spatial")) {
    theta <- seq(0, 1.5 * pi, length.out = n_level)
    auxiliary <- data.frame(
      x = cos(theta) + seq_len(n_level) / (3 * n_level),
      y = sin(theta),
      row.names = labels
    )
    precision <- drmTMB:::drm_spatial_coords_precision(
      auxiliary,
      site = labels,
      group = "id"
    )$precision
    K <- solve(as.matrix(precision))
  } else if (identical(provider, "relmat")) {
    K <- outer(
      seq_len(n_level),
      seq_len(n_level),
      function(i, j) 0.35^abs(i - j)
    )
    diag(K) <- diag(K) + 0.15
    dimnames(K) <- list(labels, labels)
    auxiliary <- K
  } else if (identical(provider, "animal")) {
    pedigree <- arc1a_pedigree(labels)
    K <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
    auxiliary <- list(A = K, pedigree = pedigree)
  } else {
    stop("Unknown Arc 1a provider: ", provider, call. = FALSE)
  }

  node_labels <- rownames(K)
  L <- t(chol(K))
  b0 <- as.vector(L %*% stats::rnorm(n_level)) * 0.5
  b1 <- if (identical(shape, "one_slope")) {
    as.vector(L %*% stats::rnorm(n_level)) * 0.38
  } else {
    rep(0, n_level)
  }
  id <- rep(observed, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), times = g)
  index <- match(id, node_labels)
  y <- 0.4 + 0.25 * x + b0[index] + b1[index] * x +
    stats::rnorm(g * n_each, 0, 0.5)
  data <- data.frame(
    y = y,
    x = x,
    id = factor(id, levels = node_labels)
  )
  X <- stats::model.matrix(~x, data)
  Z <- matrix(0, nrow(data), n_level)
  Z[cbind(seq_len(nrow(data)), index)] <- 1

  list(
    provider = provider,
    shape = shape,
    data = data,
    K = K,
    auxiliary = auxiliary,
    X = X,
    Z = Z,
    designs = if (identical(shape, "one_slope")) {
      list(Z, Z * x)
    } else {
      list(Z)
    }
  )
}

arc1a_formula <- function(fixture, representation = "canonical") {
  provider <- fixture$provider
  slope <- identical(fixture$shape, "one_slope")

  if (identical(provider, "spatial")) {
    coords <- fixture$auxiliary
    if (slope) {
      return(bf(y ~ x + spatial(1 + x | id, coords = coords), sigma ~ 1))
    }
    return(bf(y ~ x + spatial(1 | id, coords = coords), sigma ~ 1))
  }
  if (identical(provider, "relmat")) {
    if (identical(representation, "Q")) {
      Q <- solve(fixture$K)
      if (slope) {
        return(bf(y ~ x + relmat(1 + x | id, Q = Q), sigma ~ 1))
      }
      return(bf(y ~ x + relmat(1 | id, Q = Q), sigma ~ 1))
    }
    K <- fixture$K
    if (slope) {
      return(bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1))
    }
    return(bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1))
  }
  if (identical(provider, "animal")) {
    if (identical(representation, "Ainv")) {
      Ainv <- solve(fixture$K)
      if (slope) {
        return(bf(y ~ x + animal(1 + x | id, Ainv = Ainv), sigma ~ 1))
      }
      return(bf(y ~ x + animal(1 | id, Ainv = Ainv), sigma ~ 1))
    }
    if (identical(representation, "pedigree")) {
      pedigree <- fixture$auxiliary$pedigree
      if (slope) {
        return(bf(
          y ~ x + animal(1 + x | id, pedigree = pedigree),
          sigma ~ 1
        ))
      }
      return(bf(y ~ x + animal(1 | id, pedigree = pedigree), sigma ~ 1))
    }
    A <- fixture$K
    if (slope) {
      return(bf(y ~ x + animal(1 + x | id, A = A), sigma ~ 1))
    }
    return(bf(y ~ x + animal(1 | id, A = A), sigma ~ 1))
  }
  stop("Unknown Arc 1a provider", call. = FALSE)
}

arc1a_fit <- function(fixture, representation = "canonical", REML = TRUE) {
  drmTMB(
    arc1a_formula(fixture, representation),
    family = gaussian(),
    data = fixture$data,
    REML = REML,
    control = drm_control(optimizer_preset = "robust")
  )
}

arc1a_reml_reference <- function(fixture) {
  y <- fixture$data$y
  X <- fixture$X
  n <- length(y)
  p <- ncol(X)
  covariance_terms <- lapply(
    fixture$designs,
    function(W) W %*% fixture$K %*% t(W)
  )
  objective <- function(par) {
    q <- length(covariance_terms)
    V <- exp(2 * par[[q + 1L]]) * diag(n)
    for (j in seq_len(q)) {
      V <- V + exp(2 * par[[j]]) * covariance_terms[[j]]
    }
    chol_V <- chol(V)
    Vi <- chol2inv(chol_V)
    XtViX <- crossprod(X, Vi %*% X)
    chol_X <- chol(XtViX)
    beta <- backsolve(chol_X, forwardsolve(t(chol_X), crossprod(X, Vi %*% y)))
    residual <- y - drop(X %*% beta)
    as.numeric(0.5 * (
      (n - p) * log(2 * pi) +
        2 * sum(log(diag(chol_V))) +
        2 * sum(log(diag(chol_X))) +
        drop(crossprod(residual, Vi %*% residual))
    ))
  }
  q <- length(covariance_terms)
  opt <- stats::optim(
    par = log(c(rep(0.4, q), 0.5)),
    fn = objective,
    method = "L-BFGS-B",
    lower = rep(log(1e-4), q + 1L),
    upper = rep(log(5), q + 1L),
    control = list(maxit = 3000L, factr = 1e5, pgtol = 1e-10)
  )
  par <- opt$par
  V <- exp(2 * par[[q + 1L]]) * diag(n)
  for (j in seq_len(q)) {
    V <- V + exp(2 * par[[j]]) * covariance_terms[[j]]
  }
  Vi <- chol2inv(chol(V))
  XtViX <- crossprod(X, Vi %*% X)
  beta <- solve(XtViX, crossprod(X, Vi %*% y))
  list(
    sd = exp(par[seq_len(q)]),
    sigma = exp(par[[q + 1L]]),
    beta = unname(drop(beta)),
    par = par,
    objective = objective,
    convergence = opt$convergence
  )
}

arc1a_tmb_to_reference_par <- function(par) {
  c(
    unname(par[grepl("^log_sd_phylo", names(par))]),
    unname(par[names(par) == "beta_sigma"])
  )
}

test_that("Arc 1a REML providers match an independent restricted likelihood", {
  skip_on_cran()
  skip_fragile_recovery()

  for (provider in c("spatial", "animal", "relmat")) {
    for (shape in c("intercept", "one_slope")) {
      fixture <- arc1a_provider_fixture(provider, shape)
      fit <- suppressWarnings(arc1a_fit(fixture))
      reference <- arc1a_reml_reference(fixture)
      info <- paste(provider, shape)

      expect_identical(fit$estimator, "REML", info = info)
      expect_equal(fit$opt$convergence, 0L, info = info)
      expect_true(is.finite(fit$opt$objective), info = info)
      expect_true(isTRUE(fit$sdr$pdHess), info = info)
      expect_true(all(c("u_phylo", "beta_mu") %in% fit$model$tmb_random_names))
      expect_false("beta_sigma" %in% fit$model$tmb_random_names)
      expect_equal(reference$convergence, 0L, info = info)
      expect_equal(
        as.numeric(fit$sdpars$mu),
        reference$sd,
        tolerance = 2e-2,
        info = info
      )
      expect_equal(
        exp(as.numeric(fit$par$sigma[[1L]])),
        reference$sigma,
        tolerance = 2e-2,
        info = info
      )
      expect_equal(
        as.numeric(fit$par$mu),
        reference$beta,
        tolerance = 2e-2,
        info = info
      )

      base <- fit$opt$par
      expect_equal(
        as.numeric(fit$obj$fn(base)),
        reference$objective(arc1a_tmb_to_reference_par(base)),
        tolerance = 1e-5,
        info = paste(info, "objective")
      )
      expected_targets <- paste0(
        "sd:mu:",
        provider,
        if (identical(shape, "one_slope")) {
          c("(1 | id)", "(0 + x | id)")
        } else {
          "(1 | id)"
        }
      )
      expect_true(
        all(expected_targets %in% summary(fit)$parameters$parm),
        info = paste(info, "profile target labels")
      )
      displacements <- list(
        rep(c(0.07, -0.04, 0.05), length.out = length(base)),
        rep(c(-0.05, 0.06, -0.03), length.out = length(base))
      )
      for (delta in displacements) {
        displaced <- base + delta
        tmb_delta <- as.numeric(fit$obj$fn(displaced) - fit$obj$fn(base))
        reference_delta <- reference$objective(
          arc1a_tmb_to_reference_par(displaced)
        ) - reference$objective(arc1a_tmb_to_reference_par(base))
        expect_equal(
          tmb_delta,
          reference_delta,
          tolerance = 1e-5,
          info = paste(info, "normalized objective")
        )
      }
    }
  }
})

test_that("Arc 1a equivalent covariance representations agree with an unobserved level", {
  skip_on_cran()
  skip_fragile_recovery()

  relmat_fixture <- arc1a_provider_fixture(
    "relmat",
    "one_slope",
    g = 8L,
    unobserved_level = TRUE
  )
  relmat_K <- suppressWarnings(arc1a_fit(relmat_fixture, "canonical"))
  relmat_Q <- suppressWarnings(arc1a_fit(relmat_fixture, "Q"))
  expect_equal(relmat_K$opt$objective, relmat_Q$opt$objective, tolerance = 1e-6)
  expect_equal(relmat_K$sdpars$mu, relmat_Q$sdpars$mu, tolerance = 1e-5)
  expect_equal(relmat_K$par$mu, relmat_Q$par$mu, tolerance = 1e-5)

  animal_fixture <- arc1a_provider_fixture(
    "animal",
    "one_slope",
    g = 8L,
    unobserved_level = TRUE
  )
  fits <- lapply(
    c("canonical", "Ainv", "pedigree"),
    function(representation) suppressWarnings(
      arc1a_fit(animal_fixture, representation)
    )
  )
  for (i in 2:length(fits)) {
    expect_equal(fits[[1L]]$opt$objective, fits[[i]]$opt$objective, tolerance = 1e-6)
    expect_equal(fits[[1L]]$sdpars$mu, fits[[i]]$sdpars$mu, tolerance = 1e-5)
    expect_equal(fits[[1L]]$par$mu, fits[[i]]$par$mu, tolerance = 1e-5)
  }
})

test_that("Arc 1a REML provider admission remains bounded", {
  skip_on_cran()
  for (provider in c("spatial", "animal", "relmat")) {
    fixture <- arc1a_provider_fixture(provider, "one_slope", g = 8L)
    dat <- fixture$data
    dat$z <- dat$x^2
    dat$batch <- rep(paste0("batch", seq_len(8L)), length.out = nrow(dat))
    forms <- switch(
      provider,
      spatial = {
        coords <- fixture$auxiliary
        expect_error(
          bf(
            y ~ x + z + spatial(1 + x + z | id, coords = coords),
            sigma ~ 1
          ),
          "reserves only intercept and one-slope",
          info = "spatial multiple_slope"
        )
        list(
          slope_only = bf(
            y ~ x + spatial(0 + x | id, coords = coords),
            sigma ~ 1
          ),
          labelled = bf(
            y ~ x + spatial(1 | p | id, coords = coords),
            sigma ~ 1
          ),
          heteroscedastic_sigma = bf(
            y ~ x + spatial(1 + x | id, coords = coords),
            sigma ~ x
          ),
          sigma_random_effect = bf(
            y ~ x + spatial(1 + x | id, coords = coords),
            sigma ~ 1 + (1 | batch)
          ),
          matched_mean_scale = bf(
            y ~ x + spatial(1 | p | id, coords = coords),
            sigma ~ spatial(1 | p | id, coords = coords)
          )
        )
      },
      animal = {
        A <- fixture$K
        expect_error(
          bf(
            y ~ x + z + animal(1 + x + z | id, A = A),
            sigma ~ 1
          ),
          "reserves only intercept and one-slope",
          info = "animal multiple_slope"
        )
        list(
          slope_only = bf(y ~ x + animal(0 + x | id, A = A), sigma ~ 1),
          labelled = bf(y ~ x + animal(1 | p | id, A = A), sigma ~ 1),
          heteroscedastic_sigma = bf(
            y ~ x + animal(1 + x | id, A = A),
            sigma ~ x
          ),
          sigma_random_effect = bf(
            y ~ x + animal(1 + x | id, A = A),
            sigma ~ 1 + (1 | batch)
          ),
          matched_mean_scale = bf(
            y ~ x + animal(1 | p | id, A = A),
            sigma ~ animal(1 | p | id, A = A)
          )
        )
      },
      relmat = {
        K <- fixture$K
        expect_error(
          bf(
            y ~ x + z + relmat(1 + x + z | id, K = K),
            sigma ~ 1
          ),
          "reserves only intercept and one-slope",
          info = "relmat multiple_slope"
        )
        list(
          slope_only = bf(y ~ x + relmat(0 + x | id, K = K), sigma ~ 1),
          labelled = bf(y ~ x + relmat(1 | p | id, K = K), sigma ~ 1),
          heteroscedastic_sigma = bf(
            y ~ x + relmat(1 + x | id, K = K),
            sigma ~ x
          ),
          sigma_random_effect = bf(
            y ~ x + relmat(1 + x | id, K = K),
            sigma ~ 1 + (1 | batch)
          ),
          matched_mean_scale = bf(
            y ~ x + relmat(1 | p | id, K = K),
            sigma ~ relmat(1 | p | id, K = K)
          )
        )
      }
    )
    for (shape in names(forms)) {
      expected_error <- switch(
        shape,
        heteroscedastic_sigma = "require.*sigma ~ 1",
        sigma_random_effect = "constant residual scale.*sigma ~ 1.*no sigma random effect",
        matched_mean_scale = "matched mean-scale",
        "slope-only, labelled, multiple-slope"
      )
      expect_error(
        drmTMB(forms[[shape]], data = dat, REML = TRUE),
        expected_error,
        info = paste(provider, shape)
      )
    }
  }

  fixture <- arc1a_provider_fixture("spatial", "one_slope", g = 8L)
  coords <- fixture$auxiliary
  dat <- fixture$data
  expect_error(
    drmTMB(
      bf(
        y ~ x + spatial(1 | p | id, coords = coords),
        sigma ~ spatial(1 | p | id, coords = coords)
      ),
      data = dat,
      REML = TRUE
    ),
    "matched mean-scale"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + spatial(1 | id, coords = coords), sigma ~ 1),
      family = poisson(),
      data = transform(dat, y = stats::rpois(nrow(dat), 2)),
      REML = TRUE
    ),
    "only for univariate and bivariate Gaussian"
  )
})

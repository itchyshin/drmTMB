# Generate one CSV per t6 cell. Both engines fit these files.
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[[1L]] else Sys.getenv("T6_ROOT", unset = "")
if (!nzchar(root)) root <- getwd()
source(file.path(root, "t6_config.R"))

t6_simulate_y <- function(family, mu, sigma, nu, zoi, coi, trials) {
  n <- length(mu)
  switch(family,
    gaussian = mu + sigma * stats::rnorm(n),
    student = mu + sigma * stats::rt(n, df = nu),
    lognormal = stats::rlnorm(n, meanlog = mu, sdlog = sigma),
    gamma = {
      shape <- 1 / sigma^2
      stats::rgamma(n, shape = shape, scale = mu / shape)
    },
    poisson = stats::rpois(n, lambda = pmax(mu, 1e-8)),
    nbinom2 = {
      size <- 1 / sigma^2
      stats::rnbinom(n, size = size, mu = mu)
    },
    binomial = stats::rbinom(n, size = 1L, prob = mu),
    beta = {
      phi <- 1 / sigma^2
      stats::rbeta(n, shape1 = mu * phi, shape2 = (1 - mu) * phi)
    },
    tweedie = {
      if (requireNamespace("tweedie", quietly = TRUE)) {
        tweedie::rtweedie(n, mu = mu, phi = sigma^2, power = nu)
      } else {
        y <- stats::rgamma(n, shape = 2, scale = mu / 2)
        y[seq_len(max(1L, as.integer(round(0.1 * n))))] <- 0
        y
      }
    },
    skew_normal = mu + sigma * stats::rnorm(n),
    beta_binomial = {
      phi <- 1 / sigma^2
      p <- stats::rbeta(n, shape1 = mu * phi, shape2 = (1 - mu) * phi)
      stats::rbinom(n, size = trials, prob = p)
    },
    zero_one_beta = {
      phi <- 1 / sigma^2
      interior <- stats::rbeta(n, shape1 = mu * phi, shape2 = (1 - mu) * phi)
      boundary <- stats::runif(n) < zoi
      one <- stats::runif(n) < coi
      ifelse(boundary, as.numeric(one), pmin(pmax(interior, 1e-4), 1 - 1e-4))
    },
    stop(family)
  )
}

t6_make_cell <- function(family, re) {
  seed <- t6_seed_r(family, re)
  n <- if (re) T6_N_RE else T6_N_FE
  set.seed(seed, kind = "Mersenne-Twister",
           normal.kind = "Inversion", sample.kind = "Rejection")
  x <- stats::rnorm(n)
  f <- rep(c("a", "b", "c"), length.out = n)
  g <- if (re) {
    rep(sprintf("g%02d", seq_len(T6_G)), length.out = n)
  } else {
    rep("g01", n)
  }
  eta <- 0.2 + 0.4 * x + (f == "b") * 0.3 + (f == "c") * (-0.2)
  if (re) {
    u <- stats::rnorm(T6_G, sd = 0.25)
    names(u) <- sprintf("g%02d", seq_len(T6_G))
    eta <- eta + u[g]
  }
  trials <- rep(12L, n)
  dpar <- list(mu = NA_real_, sigma = 0.35, nu = 6, zoi = 0.08, coi = 0.4)
  if (family %in% c("gaussian", "student", "skew_normal")) {
    dpar$mu <- eta
    dpar$sigma <- 0.6
  } else if (family == "lognormal") {
    dpar$mu <- eta * 0.4
    dpar$sigma <- 0.35
  } else if (family == "gamma") {
    dpar$mu <- exp(0.4 + 0.3 * x)
    dpar$sigma <- 0.4
  } else if (family == "poisson") {
    dpar$mu <- exp(0.6 + 0.35 * x)
  } else if (family == "nbinom2") {
    dpar$mu <- exp(0.8 + 0.3 * x)
    dpar$sigma <- 0.4
  } else if (family == "binomial") {
    dpar$mu <- stats::plogis(eta)
  } else if (family == "beta") {
    dpar$mu <- stats::plogis(eta)
    dpar$sigma <- 0.25
  } else if (family == "tweedie") {
    dpar$mu <- exp(0.5 + 0.25 * x)
    dpar$sigma <- 0.4
    dpar$nu <- 1.5
  } else if (family == "beta_binomial") {
    dpar$mu <- stats::plogis(eta)
    dpar$sigma <- 0.3
  } else if (family == "zero_one_beta") {
    dpar$mu <- stats::plogis(eta)
    dpar$sigma <- 0.25
  }
  y <- t6_simulate_y(
    family, dpar$mu, dpar$sigma, dpar$nu, dpar$zoi, dpar$coi, trials
  )
  out <- data.frame(
    y = y, x = x, f = f, g = g, trials = trials,
    stringsAsFactors = FALSE
  )
  if (family == "beta") {
    out$y <- pmin(pmax(out$y, 1e-4), 1 - 1e-4)
  }
  out
}

datadir <- file.path(root, "data")
dir.create(datadir, recursive = TRUE, showWarnings = FALSE)
cells <- rbind(
  expand.grid(family = T6_T1_FAMILIES, re = c(FALSE, TRUE),
              stringsAsFactors = FALSE),
  data.frame(family = T6_FE_ONLY, re = FALSE, stringsAsFactors = FALSE)
)
for (i in seq_len(nrow(cells))) {
  fam <- cells$family[[i]]
  re <- cells$re[[i]]
  d <- t6_make_cell(fam, re)
  path <- file.path(datadir, paste0(t6_cell(fam, re), ".csv"))
  utils::write.csv(d, path, row.names = FALSE)
  message("wrote ", path, " n=", nrow(d), " seed_r=", t6_seed_r(fam, re))
}

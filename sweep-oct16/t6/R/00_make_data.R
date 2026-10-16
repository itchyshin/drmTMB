# t6 (sweep-oct16): shared seeded datasets for the predict()/simulate() lane.
#
# One CSV per (family, re) cell, read by both the R harness (drmTMB) and the
# Julia harness (DRModels.jl), so the two engines fit identical data.
#
# Seeds: the lane brief assigns 20261016600 + k. R's set.seed() refuses
# integers above .Machine$integer.max (2147483647), so R uses
#   seed_R = seed - 20000000000  (= 261016600 + k),
# while Julia uses the literal seed. Cell k is listed in cells.csv.
#
# Base R only; no package needed. Run from the repository root:
#   Rscript sweep-oct16/t6/R/00_make_data.R

out_dir <- file.path("sweep-oct16", "t6", "data")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

seed_base <- 20261016600
seed_r <- function(seed) seed - 20000000000

families <- c(
  "gaussian", "student", "skew_normal", "lognormal", "gamma", "beta",
  "zero_one_beta", "beta_binomial", "binomial", "poisson", "nbinom2",
  "truncated_nbinom2", "tweedie", "cumulative_logit"
)
res <- c("fixed", "ri")

n_group <- 24L
per_group <- 10L
n <- n_group * per_group
sd_b <- 0.5
f_eff <- c(a = 0, b = 0.3, c = -0.4)

rskewnorm_moment <- function(mu, sigma, alpha) {
  delta <- alpha / sqrt(1 + alpha^2)
  omega <- sigma / sqrt(1 - 2 * delta^2 / pi)
  xi <- mu - omega * delta * sqrt(2 / pi)
  u0 <- abs(stats::rnorm(length(mu)))
  v <- stats::rnorm(length(mu))
  xi + omega * (delta * u0 + sqrt(1 - delta^2) * v)
}

rtweedie_cpg <- function(mu, phi, p) {
  lambda <- mu^(2 - p) / (phi * (2 - p))
  gam <- phi * (p - 1) * mu^(p - 1)
  shape <- (2 - p) / (p - 1)
  N <- stats::rpois(length(mu), lambda)
  y <- numeric(length(mu))
  pos <- N > 0
  y[pos] <- stats::rgamma(sum(pos), shape = N[pos] * shape, scale = gam[pos])
  y
}

rtrunc_nb2 <- function(mu, size) {
  y <- stats::rnbinom(length(mu), size = size, mu = mu)
  while (any(y == 0)) {
    z <- y == 0
    y[z] <- stats::rnbinom(sum(z), size = size[z], mu = mu[z])
  }
  y
}

plogis <- stats::plogis
cells <- list()
k <- 0L
for (fam in families) {
  for (re in res) {
    seed <- seed_base + k
    set.seed(seed_r(seed))
    x <- round(stats::rnorm(n), 4)
    f <- sample(c("a", "b", "c"), n, replace = TRUE)
    g <- sprintf("g%02d", rep(seq_len(n_group), each = per_group))
    b <- if (re == "ri") stats::rnorm(n_group, 0, sd_b) else rep(0, n_group)
    bg <- b[rep(seq_len(n_group), each = per_group)]
    lin <- 0.5 * x + unname(f_eff[f]) + bg
    dat <- data.frame(x = x, f = f, g = g, stringsAsFactors = FALSE)
    truth <- list()
    if (fam == "gaussian") {
      mu <- 1 + lin; sigma <- exp(log(0.8) + 0.3 * x)
      dat$y <- stats::rnorm(n, mu, sigma)
    } else if (fam == "student") {
      mu <- 1 + lin; sigma <- exp(log(0.8) + 0.3 * x); nu <- 6
      dat$y <- mu + sigma * stats::rt(n, df = nu)
    } else if (fam == "skew_normal") {
      mu <- 1 + lin; sigma <- exp(log(0.8) + 0.3 * x); alpha <- 2
      dat$y <- rskewnorm_moment(mu, sigma, rep(alpha, n))
    } else if (fam == "lognormal") {
      mu <- 1 + lin; sigma <- exp(log(0.5) + 0.3 * x)
      dat$y <- stats::rlnorm(n, meanlog = mu, sdlog = sigma)
    } else if (fam == "gamma") {
      mu <- exp(1 + lin); sigma <- exp(log(0.5) + 0.3 * x)
      dat$y <- stats::rgamma(n, shape = 1 / sigma^2, scale = mu * sigma^2)
    } else if (fam == "beta") {
      mu <- plogis(lin); sigma <- exp(log(0.3) + 0.3 * x); phi <- 1 / sigma^2
      dat$y <- stats::rbeta(n, mu * phi, (1 - mu) * phi)
    } else if (fam == "zero_one_beta") {
      mu <- plogis(lin); sigma <- exp(log(0.3) + 0.3 * x); phi <- 1 / sigma^2
      zoi <- 0.15; coi <- 0.4
      yb <- stats::rbeta(n, mu * phi, (1 - mu) * phi)
      atom <- stats::runif(n) < zoi
      one <- stats::runif(n) < coi
      dat$y <- ifelse(atom, ifelse(one, 1, 0), yb)
    } else if (fam == "beta_binomial") {
      mu <- plogis(lin); sigma <- exp(log(0.4) + 0.3 * x); phi <- 1 / sigma^2
      trials <- sample(5:20, n, replace = TRUE)
      p <- stats::rbeta(n, mu * phi, (1 - mu) * phi)
      dat$successes <- stats::rbinom(n, trials, p)
      dat$failures <- trials - dat$successes
      dat$trials <- trials
    } else if (fam == "binomial") {
      mu <- plogis(lin)
      trials <- sample(5:20, n, replace = TRUE)
      dat$successes <- stats::rbinom(n, trials, mu)
      dat$failures <- trials - dat$successes
      dat$trials <- trials
    } else if (fam == "poisson") {
      mu <- exp(1 + lin)
      dat$y <- stats::rpois(n, mu)
    } else if (fam == "nbinom2") {
      mu <- exp(1 + lin); sigma <- exp(log(0.7) + 0.3 * x)
      dat$y <- stats::rnbinom(n, size = 1 / sigma^2, mu = mu)
    } else if (fam == "truncated_nbinom2") {
      mu <- exp(1 + lin); sigma <- exp(log(0.7) + 0.3 * x)
      dat$y <- rtrunc_nb2(mu, 1 / sigma^2)
    } else if (fam == "tweedie") {
      mu <- exp(1 + lin); sigma <- exp(log(0.8) + 0.3 * x); power <- 1.5
      dat$y <- rtweedie_cpg(mu, sigma^2, power)
    } else if (fam == "cumulative_logit") {
      cuts <- c(-1, 0.5, 1.8)
      u <- stats::rlogis(n, location = lin)
      dat$y <- as.integer(findInterval(u, cuts) + 1L)
    }
    file <- sprintf("%s_%s.csv", fam, re)
    utils::write.csv(dat, file.path(out_dir, file), row.names = FALSE)
    cells[[length(cells) + 1L]] <- data.frame(
      k = k, family = fam, re = re, seed = format(seed, scientific = FALSE),
      seed_r = format(seed_r(seed), scientific = FALSE), file = file
    )
    k <- k + 1L
  }
}
utils::write.csv(do.call(rbind, cells), file.path(out_dir, "cells.csv"), row.names = FALSE)

# Shared newdata sets.
#  nd_main: every f level, three x values, one seen and one unseen group.
nd_main <- expand.grid(
  x = c(-1, 0, 1.5), f = c("a", "b", "c"), g = c("g01", "gNEW"),
  stringsAsFactors = FALSE
)
nd_main$trials <- 10L
utils::write.csv(nd_main, file.path(out_dir, "nd_main.csv"), row.names = FALSE)
#  nd_subset: a single f level (tests contrasts rebuilt from a level subset).
nd_subset <- nd_main[nd_main$f == "b", ]
utils::write.csv(nd_subset, file.path(out_dir, "nd_subset.csv"), row.names = FALSE)
#  nd_unseen_f: an f level the model never saw (must refuse, not mis-predict).
nd_unseen_f <- data.frame(x = c(0, 1), f = c("d", "a"), g = c("g01", "g01"), trials = 10L)
utils::write.csv(nd_unseen_f, file.path(out_dir, "nd_unseen_f.csv"), row.names = FALSE)
cat("wrote", length(cells), "cells to", out_dir, "\n")

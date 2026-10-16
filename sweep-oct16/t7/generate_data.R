# t7 simulated data. Campaign seed family is 20261016700+; R's set.seed()
# takes a 32-bit integer, so 20261016700 overflows. We use 202610167L as the
# representable campaign seed and increment per table.

campaign_seed <- 202610167L

sim_offset_table <- function(family, seed) {
  set.seed(seed)
  n_g <- 20L
  per <- 10L
  n <- n_g * per
  g <- factor(rep(sprintf("g%02d", seq_len(n_g)), each = per))
  x <- stats::rnorm(n)
  effort <- stats::runif(n, min = 0.5, max = 2.5)
  off <- log(effort)
  u <- stats::rnorm(n_g, 0, 0.35)
  eta <- 0.25 + 0.40 * x + u[as.integer(g)]
  y <- switch(
    family,
    poisson = stats::rpois(n, lambda = effort * exp(eta)),
    nbinom2 = stats::rnbinom(n, mu = effort * exp(eta), size = 4),
    gamma = stats::rgamma(n, shape = 5, scale = (effort * exp(eta)) / 5),
    stop("unknown family")
  )
  data.frame(y = y, x = x, off = off, g = g, effort = effort, stringsAsFactors = FALSE)
}

sim_contrast_table <- function(seed) {
  set.seed(seed)
  n <- 160L
  g <- ordered(rep(c("a", "b", "c", "d"), each = n / 4L))
  x <- stats::rnorm(n)
  cell <- c(a = 0, b = 0.45, c = -0.30, d = 0.70)
  yg <- 1.1 + 0.55 * x + cell[as.character(g)] + stats::rnorm(n, 0, 0.35)
  yp <- stats::rpois(n, lambda = exp(0.15 + 0.35 * x + cell[as.character(g)]))
  data.frame(yg = yg, yp = yp, x = x, g = g)
}

offset_poisson <- sim_offset_table("poisson", campaign_seed + 0L)
offset_nbinom2 <- sim_offset_table("nbinom2", campaign_seed + 1L)
offset_gamma <- sim_offset_table("gamma", campaign_seed + 2L)
contrast_dat <- sim_contrast_table(campaign_seed + 50L)

dir.create("sweep-oct16/t7", showWarnings = FALSE, recursive = TRUE)
utils::write.csv(offset_poisson, "sweep-oct16/t7/data_offset_poisson.csv", row.names = FALSE)
utils::write.csv(offset_nbinom2, "sweep-oct16/t7/data_offset_nbinom2.csv", row.names = FALSE)
utils::write.csv(offset_gamma, "sweep-oct16/t7/data_offset_gamma.csv", row.names = FALSE)
utils::write.csv(contrast_dat, "sweep-oct16/t7/data_contrasts.csv", row.names = FALSE)

dput(offset_poisson, "sweep-oct16/t7/data_offset_poisson.dput")
dput(offset_nbinom2, "sweep-oct16/t7/data_offset_nbinom2.dput")
dput(offset_gamma, "sweep-oct16/t7/data_offset_gamma.dput")
dput(contrast_dat, "sweep-oct16/t7/data_contrasts.dput")

cat("wrote t7 data tables, n =", nrow(offset_poisson), "offset /", nrow(contrast_dat), "contrasts\n")

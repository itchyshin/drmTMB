# t2 | Simulation recovery, Gaussian location-scale (sweep 2026-10-16)
#
# Shared constants for the data generator, the drmTMB fitter and the analysis.
# The DRModels.jl fitter reads the same datasets from disk, so it needs no copy
# of the data-generating constants; the truth table below is re-declared in
# t2_fit_DRModels.jl and checked against `truth.csv` at start-up.

T2_SEED_BASE <- 20261016100 # nominal seed for rep r is T2_SEED_BASE + r
T2_REPS <- 500L
T2_N <- c(50L, 200L, 1000L)
# re = "none": no grouping term; "G20"/"G50": mu gains a (1 | g) intercept.
T2_RE <- list(none = 0L, G20 = 20L, G50 = 50L)

T2_TRUTH <- c(
  mu_intercept = 1.0, # mu = 1 + 0.5 x
  mu_x = 0.5,
  sigma_intercept = -0.5, # log sigma = -0.5 + 0.4 z
  sigma_z = 0.4,
  sd_g = 0.5 # sd of the (1 | g) mean intercept (RE cells only)
)

# R's set.seed() accepts only 32-bit integers, and the nominal seeds
# (20261016101 .. 20261016600) exceed .Machine$integer.max, so
# set.seed(20261016100 + r) errors ("supplied seed is not a valid integer").
# We therefore seed R with the nominal seed reduced modulo 2^31, which is
# injective over the 500 reps used here (933663269 .. 933663768).
t2_seed_r <- function(rep) {
  as.integer((T2_SEED_BASE + rep) %% 2^31)
}

t2_cells <- function() {
  cells <- expand.grid(
    n = T2_N,
    re = names(T2_RE),
    stringsAsFactors = FALSE,
    KEEP.OUT.ATTRS = FALSE
  )
  cells$G <- unname(unlist(T2_RE[cells$re]))
  cells$cell <- sprintf("n%04d_%s", cells$n, cells$re)
  cells[order(cells$re, cells$n), c("cell", "n", "re", "G")]
}

# One dataset. Draw order is fixed (x, z, eps, then u) so that, within a rep,
# the no-RE and RE cells at the same n share x, z and eps (common random
# numbers): the RE cells differ only by the added group intercepts u[g].
t2_simulate <- function(n, G, rep) {
  set.seed(t2_seed_r(rep), kind = "Mersenne-Twister",
           normal.kind = "Inversion", sample.kind = "Rejection")
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  eps <- stats::rnorm(n)
  mu <- T2_TRUTH[["mu_intercept"]] + T2_TRUTH[["mu_x"]] * x
  sigma <- exp(T2_TRUTH[["sigma_intercept"]] + T2_TRUTH[["sigma_z"]] * z)
  if (G > 0L) {
    u <- stats::rnorm(G, mean = 0, sd = T2_TRUTH[["sd_g"]])
    g <- rep_len(seq_len(G), n) # balanced, deterministic group labels
    mu <- mu + u[g]
  } else {
    g <- rep(0L, n)
  }
  data.frame(rep = rep, i = seq_len(n), y = mu + sigma * eps, x = x, z = z, g = g)
}

# t6 | predict() and simulate() methods (sweep 2026-10-16)
#
# t1 families (shared univariate surface that both engines fit on the pins,
# with and without (1|g)): gaussian, student, lognormal, gamma, poisson,
# nbinom2, binomial, beta. FE-only extras (no (1|g) on the Julia pin):
# tweedie, skew_normal, beta_binomial, zero_one_beta.
#
# Pins: drmTMB ca3ddefa5ea11bbfd3b765615dfbb89305d2485a
#       DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7
# Seeds: nominal 20261016600 + 10 * family_index + re_flag
# R set.seed() cannot take these, so R is seeded with seed %% 2^31
# (same convention as t2 #1549 and t4).

T6_SEED_BASE <- 20261016600
T6_NSIM <- 1000L
T6_N_FE <- 80L
T6_N_RE <- 80L
T6_G <- 8L
T6_PASS_MCSE <- 3
T6_PASS_RJ <- 1e-8
T6_FIT_TIMEOUT_S <- 120

# t1 families. `re` = ordinary (1|g) is in-scope for the lane.
T6_T1_FAMILIES <- c(
  "gaussian", "student", "lognormal", "gamma",
  "poisson", "nbinom2", "binomial", "beta"
)
# Extra shared FE families, run without (1|g) only.
T6_FE_ONLY <- c("tweedie", "skew_normal", "beta_binomial", "zero_one_beta")

T6_ALL_FAMILIES <- c(T6_T1_FAMILIES, T6_FE_ONLY)

t6_family_index <- function(family) {
  match(family, T6_ALL_FAMILIES) - 1L
}

t6_seed_nominal <- function(family, re) {
  T6_SEED_BASE + 10L * t6_family_index(family) + if (isTRUE(re)) 1L else 0L
}

t6_seed_r <- function(family, re) {
  as.integer(t6_seed_nominal(family, re) %% 2^31)
}

t6_cell <- function(family, re) {
  sprintf("%s_%s", family, if (isTRUE(re)) "re" else "fe")
}

t6_dpars <- function(family) {
  switch(family,
    gaussian = c("mu", "sigma"),
    student = c("mu", "sigma", "nu"),
    lognormal = c("mu", "sigma"),
    gamma = c("mu", "sigma"),
    poisson = "mu",
    nbinom2 = c("mu", "sigma"),
    binomial = "mu",
    beta = c("mu", "sigma"),
    tweedie = c("mu", "sigma", "nu"),
    skew_normal = c("mu", "sigma", "nu"),
    beta_binomial = c("mu", "sigma"),
    zero_one_beta = c("mu", "sigma", "zoi", "coi"),
    stop("unknown family: ", family)
  )
}

t6_root <- function() {
  here <- Sys.getenv("T6_ROOT", unset = "")
  if (nzchar(here)) here else getwd()
}

# Independent-oracle companion for the Julia Poisson, NB2 and Gamma
# structured intercept SD routes admitted in batch 32 (relmat K and coordinate
# spatial). The batch 32 bridge file compares Julia with native drmTMB only;
# this file evaluates an independent base-R DENSE LAPLACE logLik
# (helper-b34-julia-oracles.R: hand log densities and eta-derivatives, joint
# Newton mode, no drmTMB code) at the live Julia estimates. Kernels are hand
# built: a relmat K with non-unit diagonal and the exponential coordinate
# kernel exp(-d / median) + 1e-6 I. Data rows are shuffled, levels are named,
# and the kernel (or the coordinates) is supplied in a different row order from
# the factor levels.
# NB2 uses size 1 / sigma^2 and Gamma shape 1 / sigma^2, with sigma the
# exponentiated sigma intercept.
# Agreement asserted before any live run: logLik within B34C_TOL absolute of
# the oracle. Every emulated bug (selectors swapped, reversed SD vector,
# cov2cor(K) (relmat) or a mean-distance range (spatial, unit-diagonal
# kernel), kernel read by position, SD intercept shifted by log 2) must move
# the oracle by more than 20 times that tolerance. A one-step profile check
# asserts the Julia estimates are at a maximum of the oracle (tolerance
# B34C_TOL).
# Claim scope: one fixture per route; no calibration, coverage or broad parity.

B34C_TOL <- 1e-5

b34c_run <- function(kind, family) {
  seed <- 20261310L + 7L * match(family, c("poisson", "nbinom2", "gamma")) +
    (kind == "spatial")
  fx <- b34_struct_fixture(kind, family, seed)
  given <- fx$given
  fam <- switch(family, poisson = poisson(), nbinom2 = nbinom2(),
                gamma = Gamma(link = "log"))
  form <- if (kind == "relmat") {
    bf(y ~ x + relmat(1 | id, K = given), sd(id, level = "relmat") ~ z)
  } else {
    bf(y ~ x + spatial(1 | id, coords = given), sd(id, level = "spatial") ~ z)
  }
  fit <- drmTMB(form, family = fam, data = fx$data, engine = "julia")
  expect_equal(fit$opt$convergence, 0L, info = paste(kind, family))
  expect_false(identical(unique(as.character(fx$data$id)), fx$levels))
  res <- b34_struct_run(fit, fx$data, family, paste0("sd_", kind, "(id)"),
                        fx$levels, fx$K, fx$K_given, fx$z_level,
                        fx$K_bugs)
  message(b34_check(res$ll, res$base, res$gaps, paste(family, kind),
                    agreement_tol = B34C_TOL))
  b34_check_optimum(res, tol = B34C_TOL)
  invisible(res)
}

for (b34c_family in c("poisson", "nbinom2", "gamma")) {
  local({
    family <- b34c_family
    test_that(paste("Julia", family, "relmat intercept SD matches a dense Laplace oracle (non-unit K)"), {
      b34_live_setup()
      fx <- b34_struct_fixture("relmat", family, 1L)
      expect_gt(max(diag(fx$K)) - min(diag(fx$K)), 0.5)
      b34c_run("relmat", family)
    })
    test_that(paste("Julia", family, "coordinate spatial intercept SD matches a dense Laplace oracle (hand kernel)"), {
      b34_live_setup()
      b34c_run("spatial", family)
    })
  })
}

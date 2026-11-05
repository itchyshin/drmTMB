# Independent-oracle companion for the Julia Gaussian structured intercept SD
# routes admitted in batch 32 (relmat, animal, coordinate spatial). The
# batch 32 bridge file compares Julia with native drmTMB only; this file
# evaluates an independent base-R EXACT Gaussian marginal logLik
# (helper-b34-julia-oracles.R, no drmTMB code) at the live Julia estimates.
# Kernels are hand built: a relmat K with non-unit diagonal, a Henderson A from
# an inbred pedigree (diagonal 1.25 for the full-sib offspring) and the
# exponential coordinate kernel exp(-d / median) + 1e-6 I. Data rows are
# shuffled, levels are named, and the kernel (or the coordinates) is supplied
# in a different row order from the factor levels.
# Agreement asserted before any live run: logLik within 1e-8 absolute of the
# oracle. Every emulated bug (selectors swapped, reversed SD vector,
# cov2cor(K) (relmat, animal) or a mean-distance range (spatial,
# whose kernel has unit diagonal), kernel read by position, SD intercept shifted by log 2) must move
# the oracle by more than 20 times that tolerance. A one-step profile check
# asserts the Julia estimates are at a maximum of the oracle.
# Claim scope: one fixture per route; no calibration, coverage or broad parity.

test_that("the hand pedigree A is symmetric, positive definite and inbred", {
  ped <- b34_inbred_pedigree()
  A <- ped$A
  expect_equal(A, t(A))
  expect_gt(min(eigen(A, symmetric = TRUE, only.values = TRUE)$values), 1e-8)
  expect_equal(unname(diag(A)[c(1L, 9L, 25L)]), c(1, 1, 1.25))
  # Full sibs share relationship 0.5; a founder pair is unrelated.
  expect_equal(unname(A[9L, 10L]), 0.5)
  expect_equal(unname(A[1L, 3L]), 0)
})

b34g_run <- function(kind) {
  seed <- c(relmat = 20261301L, animal = 20261302L, spatial = 20261303L)[[kind]]
  fx <- b34_struct_fixture(kind, "gaussian", seed)
  if (kind != "spatial") {
    expect_gt(max(diag(fx$K)) - min(diag(fx$K)), 0.2)  # non-unit diagonal
  }
  given <- fx$given
  form <- switch(
    kind,
    relmat = bf(y ~ x + relmat(1 | id, K = given),
                sd(id, level = "relmat") ~ z),
    animal = bf(y ~ x + animal(1 | id, A = given),
                sd(id, level = "animal") ~ z),
    spatial = bf(y ~ x + spatial(1 | id, coords = given),
                 sd(id, level = "spatial") ~ z)
  )
  fit <- drmTMB(form, family = gaussian(), data = fx$data, engine = "julia")
  expect_equal(fit$opt$convergence, 0L)
  expect_false(identical(unique(as.character(fx$data$id)), fx$levels))
  res <- b34_struct_run(fit, fx$data, "gaussian", paste0("sd_", kind, "(id)"),
                        fx$levels, fx$K, fx$K_given, fx$z_level,
                        fx$K_bugs)
  message(b34_check(res$ll, res$base, res$gaps, paste("gaussian", kind),
                    agreement_tol = 1e-8))
  b34_check_optimum(res, tol = 1e-8)
  invisible(res)
}

test_that("Julia Gaussian relmat intercept SD matches an exact marginal oracle (non-unit K)", {
  b34_live_setup()
  b34g_run("relmat")
})

test_that("Julia Gaussian animal intercept SD matches an exact marginal oracle (inbred pedigree A)", {
  b34_live_setup()
  ped <- b34_inbred_pedigree()
  expect_equal(unname(diag(ped$A)[c(1L, 9L, 25L)]), c(1, 1, 1.25))
  b34g_run("animal")
})

test_that("Julia Gaussian coordinate spatial intercept SD matches an exact marginal oracle (hand kernel)", {
  b34_live_setup()
  b34g_run("spatial")
})

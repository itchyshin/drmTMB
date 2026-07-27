adapter_path <- testthat::test_path("..", "..", "tools", "b1-breadth-adapters.R")

if (!file.exists(adapter_path)) {
  test_that("B1 adapters are available in a source checkout", {
    skip("Top-level tools are intentionally excluded from the source tarball")
  })
} else {
  source(adapter_path)

  test_that("B1 fixture lifts have deterministic, cell-specific known DGPs", {
    beta <- b1_beta_mu_intercept(101L, "low")
    expect_equal(nrow(beta$data), 24L * 10L)
    expect_equal(beta$truth$target, "sd:mu:(1 | id)")
    slope <- b1_nongaussian_mu_slope(102L, "medium", "beta_binomial")
    expect_equal(nrow(slope$data), 48L * 8L)
    expect_true(all(slope$data$success + slope$data$failure == 18L))
    hurdle <- b1_hurdle_relmat(103L, "low")
    expect_equal(dim(hurdle$truth$Q), c(60L, 60L))
    expect_true(all(hurdle$data$y >= 0L))
    ordinal <- b1_cumulative_logit_phylo(104L, "low")
    expect_true(is.ordered(ordinal$data$score))
    student <- b1_student_nu_phylo(105L, "low")
    expect_true(all(is.finite(student$data$y)))
    skew <- b1_skew_normal_nu(108L, "low")
    expect_equal(skew$truth$target, "fixef:nu:(Intercept)")
    zi_mu <- b1_zi_spatial(106L, "low", "nbinom2", "mu")
    expect_equal(zi_mu$truth$target, "sd:mu:spatial(1 | site)")
    zi <- b1_zi_spatial(107L, "low", "poisson", "zi")
    expect_equal(zi$truth$target, "sd:zi:spatial(1 | id)")
    gamma <- b1_gamma_phylo_mu(109L, "low")
    expect_true(all(gamma$data$y > 0))
    lognormal <- b1_lognormal_relmat_mu(110L, "low")
    expect_equal(dim(lognormal$truth$Q), c(30L, 30L))
    sigma_slope <- b1_gaussian_sigma_slope(111L, "low")
    expect_equal(sigma_slope$truth$target, "sd:sigma:(0 + w | id)")
    animal <- b1_nbinom2_sigma_animal(112L, "low")
    expect_equal(dim(animal$truth$Q), c(45L, 45L))
  })

  test_that("B1 fixture dispatcher covers the registered breadth panel", {
    biv <- b1_adapter_fixture("mc-0074", 1L, "low")
    expect_equal(biv$truth$target, "sd:sigma:sigma1:(0 + x | p | id)")
    interaction <- b1_adapter_fixture("mc-0438", 1L, "low")
    expect_equal(interaction$truth$target, "sd:mu:phylo_interaction(1 | plant:pollinator)")
    expect_error(b1_adapter_fixture("mc-9999", 1L, "low"), "No fixture")
  })
}

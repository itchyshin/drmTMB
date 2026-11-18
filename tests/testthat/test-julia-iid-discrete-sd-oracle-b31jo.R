# Batch 31 (group jo): live Julia ordinary iid-group predictor-dependent-SD routes
# for beta-binomial, cumulative logit, hurdle NB2 (intercept and slope), zero-
# truncated NB2 (slope), Tweedie (intercept) and zero-inflated Poisson, each
# compared with an independent base-R oracle at the Julia estimates (see
# test-julia-iid-continuous-sd-oracle-b31jo.R for the oracle and the claim scope).
# Densities for beta-binomial, cumulative logit, hurdle NB2, truncated NB2,
# Tweedie and ZIP are written by hand. The hand Tweedie series density is first
# checked against the CRAN `tweedie` package (independent series code) and by
# total probability mass.

test_that("hand-written Tweedie series density matches tweedie::dtweedie and integrates to one", {
  skip_if_not_installed("tweedie")
  for (pw in c(1.3, 1.55, 1.8)) {
    for (mu in c(0.7, 2.5)) {
      for (phi in c(0.4, 1.2)) {
        ys <- c(0.05, 0.4, 1, 3, 8)
        ours <- b31jo_dtweedie(ys, rep(mu, 5), phi, pw, n_terms = 400L)
        ref <- log(tweedie::dtweedie(ys, power = pw, mu = mu, phi = phi))
        expect_lt(max(abs(ours - ref)), 1e-6)
        lam <- mu^(2 - pw) / (phi * (2 - pw))
        mass <- exp(-lam) + stats::integrate(
          function(y) exp(b31jo_dtweedie(y, rep(mu, length(y)), phi, pw, n_terms = 400L)),
          0, Inf, rel.tol = 1e-8)$value
        expect_lt(abs(mass - 1), 1e-5)
      }
    }
  }
})

for (route in list(c("beta_binomial", "intercept"), c("beta_binomial", "slope"),
                   c("cumulative_logit", "intercept"), c("cumulative_logit", "slope"),
                   c("hurdle_nbinom2", "intercept"), c("hurdle_nbinom2", "slope"),
                   c("truncated_nbinom2", "slope"), c("tweedie", "intercept"),
                   c("zi_poisson", "intercept"), c("zi_poisson", "slope"))) {
  local({
    fam <- route[[1L]]; kind <- route[[2L]]
    test_that(paste("Julia", fam, "iid", kind, "SD matches the independent oracle"), {
      b31jo_skip_unless_live_julia()
      b31jo_expect_iid_route(fam, kind)
    })
  })
}

test_that("ZI-NB2 sigma SD bridge keeps the Julia zi endpoint fixed", {
  dat <- data.frame(
    y = 0:3, x = c(-1, 1, -0.5, 0.5), w = rep(c(-1, 1), each = 2),
    id = factor(rep(1:2, each = 2))
  )
  make_formula <- function(zi_formula) {
    eval(substitute(
      bf(
        y ~ 1 + x, sigma ~ 1 + (1 | id), ZI,
        sd(id, dpar = "sigma") ~ w
      ),
      list(ZI = zi_formula)
    ), envir = parent.frame())
  }
  fixed_zi <- make_formula(quote(zi ~ 1))
  varying_zi <- make_formula(quote(zi ~ w))
  random_zi <- make_formula(quote(zi ~ 1 + (1 | id)))

  expect_true(drm_julia_negbin2_sigma_sd_route_admitted(fixed_zi, dat))
  expect_false(drm_julia_negbin2_sigma_sd_route_admitted(varying_zi, dat))
  expect_false(drm_julia_negbin2_sigma_sd_route_admitted(random_zi, dat))
})

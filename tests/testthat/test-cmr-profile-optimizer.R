test_that("individual CJS profile refinement continues past a relative-stopping plateau", {
  set.seed(42)
  rotation <- qr.Q(qr(matrix(stats::rnorm(49), 7L, 7L)))
  hessian <- rotation %*% diag(c(1, 2, 5, 10, 30, 100, 1000)) %*% t(rotation)
  truth <- c(1, -1, 2, -2, 1.5, -0.5, 0.7) * 1e-5
  objective <- function(x) 3419 + 0.5 * drop((x - truth) %*% hessian %*% (x - truth))
  gradient <- function(x) drop(hessian %*% (x - truth))
  plateau <- stats::optim(rep(0, 7L), objective, gr = gradient, method = "BFGS",
    control = list(maxit = 2000L, reltol = 1e-12))
  expect_gt(max(abs(gradient(plateau$par)), 0), 1e-4)

  helper_name <- ".cmr_cjs_profile_bfgs_continuation"
  helper <- if (exists(helper_name, envir = asNamespace("drmTMB"), inherits = FALSE)) {
    getFromNamespace(helper_name, "drmTMB")
  } else {
    NULL
  }
  expect_true(is.function(helper))
  if (is.function(helper)) {
    refined <- helper(objective, gradient, plateau$par, plateau$value)
    expect_true(refined$usable)
    expect_lte(refined$gradient_norm, 1e-4)
    expect_lte(refined$value, plateau$value + 1e-8)
  }
})

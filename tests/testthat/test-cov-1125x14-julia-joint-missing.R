# R/julia-joint-missing.R adapter guards (complement open x6/x8 Julia joint PRs).

julia_bf <- function(mu = y ~ x + mi(z)) {
  bf(mu, sigma ~ 1)
}

test_that("drm_julia_joint_default_control() recognises defaults", {
  expect_true(drmTMB:::drm_julia_joint_default_control(drm_control()))
  expect_true(drmTMB:::drm_julia_joint_default_control(NULL))
  expect_true(drmTMB:::drm_julia_joint_default_control(list()))
  expect_false(drmTMB:::drm_julia_joint_default_control(drm_control(se = FALSE)))
})

test_that("drm_julia_joint_formula_entries() requires a drm_formula", {
  expect_error(
    drmTMB:::drm_julia_joint_formula_entries(list(entries = list())),
    "bf()"
  )
  parsed <- julia_bf()
  entries <- drmTMB:::drm_julia_joint_formula_entries(parsed)
  expect_type(entries, "list")
  expect_true(length(entries) >= 1L)
})

test_that("drm_julia_joint_reject_formula_markers() refuses extra distributional parameters", {
  parsed <- julia_bf()
  expect_invisible(drmTMB:::drm_julia_joint_reject_formula_markers(parsed$entries))

  bad <- parsed$entries
  bad[[length(bad) + 1L]] <- list(dpar = "nu", rhs = quote(1), response = NULL)
  expect_error(
    drmTMB:::drm_julia_joint_reject_formula_markers(bad),
    "mu and sigma"
  )

  bad2 <- julia_bf(y ~ x + phylo(1 | id, tree = tree))$entries
  expect_error(
    drmTMB:::drm_julia_joint_reject_formula_markers(bad2),
    "fixed effects only"
  )
})

test_that("drm_julia_joint_mi_setup() validates the mu mi() layout", {
  parsed <- julia_bf()
  setup <- drmTMB:::drm_julia_joint_mi_setup(parsed$entries)
  expect_equal(setup$variable, "z")
  expect_equal(setup$response, "y")

  two <- julia_bf(y ~ mi(x) + mi(z))
  setup2 <- drmTMB:::drm_julia_joint_mi_setup(two$entries)
  expect_equal(setup2$variable, c("x", "z"))

  expect_error(
    drmTMB:::drm_julia_joint_mi_setup(julia_bf(y ~ x)$entries),
    "one or two"
  )
})

test_that("drm_julia_joint_numeric_matrix() coerces atomic designs", {
  m <- drmTMB:::drm_julia_joint_numeric_matrix(matrix(1:6, 2), "X")
  expect_true(is.matrix(m))
  expect_equal(mode(m), "numeric")
  na_err <- tryCatch(
    drmTMB:::drm_julia_joint_numeric_matrix(matrix(NA_real_, 1, 1), "X"),
    error = function(e) conditionMessage(e)
  )
  expect_match(na_err, "finite numeric")
  char_err <- tryCatch(
    drmTMB:::drm_julia_joint_numeric_matrix(matrix("a", 1, 1), "X"),
    error = function(e) conditionMessage(e)
  )
  expect_match(char_err, "finite numeric")
})

test_that("drm_julia_joint_response_drop() respects the predictor policy", {
  dat <- data.frame(y = c(1, NA, 3), z = 1:3)
  drop_resp <- drmTMB:::drm_julia_joint_response_drop(
    dat, "y", miss_control(response = "drop")
  )
  expect_equal(nrow(drop_resp$data), 2L)
  expect_equal(drop_resp$original_row, c(1L, 3L))

  keep_all <- drmTMB:::drm_julia_joint_response_drop(
    dat, "y", miss_control(response = "include")
  )
  expect_equal(nrow(keep_all$data), 3L)
  expect_equal(keep_all$original_row, 1:3)
})

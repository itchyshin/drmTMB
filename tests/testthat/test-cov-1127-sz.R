# refs coverage — R/[s-z]*.R slice (utils, sparse-fixed, sha256-portable, zzz, temporal helpers)

test_that("drm_suggest_closest_name covers prefix, distance, and guard branches", {
  f <- drmTMB:::drm_suggest_closest_name
  expect_null(f(NULL, c("a")))
  expect_null(f(NA_character_, c("a")))
  expect_null(f("", c("a")))
  expect_null(f("a", character()))
  expect_null(f(1L, c("a")))
  expect_identical(f("ev", c("eval.max", "iter.max")), "eval.max")
  expect_identical(f("it", c("eval.max", "iter.max")), "iter.max")
  expect_identical(
    f("ab", c("abc", "abd", "zzz"), cutoff = 2L),
    c("abc", "abd")
  )
  expect_null(f("EVAL", c("eval.max", "iter.max"), cutoff = 2L))
  expect_null(f("zzzz", c("eval.max", "iter.max")))
})

test_that("drm_optimizer_julia_bridge_names lists Julia-only optimizer keys", {
  expect_equal(
    drmTMB:::drm_optimizer_julia_bridge_names(),
    c("g_tol", "algorithm", "q4_vcov")
  )
})

test_that("internal %||% matches the null-only base contract", {
  op <- drmTMB:::`%||%`
  expect_equal(op(NULL, "fallback"), "fallback")
  expect_equal(op(0L, 1L), 0L)
  expect_equal(op(NA, 1L), NA)
  expect_equal(op(integer(), 1L), integer())
})

test_that("drm_sparse_fixed_tmb_data switches sparse mu payload for TMB", {
  sparse_mu <- Matrix::Matrix(0, 2, 2, sparse = TRUE)
  spec_on <- list(sparse_fixed = list(mu = TRUE), X = list(mu = sparse_mu))
  on <- drmTMB:::drm_sparse_fixed_tmb_data(spec_on)
  expect_equal(on$use_sparse_X_mu, 1L)
  expect_identical(on$X_mu_sparse, sparse_mu)

  spec_off <- list(sparse_fixed = list(mu = FALSE), X = list(mu = matrix(1, 2, 1)))
  off <- drmTMB:::drm_sparse_fixed_tmb_data(spec_off)
  expect_equal(off$use_sparse_X_mu, 0L)
  expect_s4_class(off$X_mu_sparse, "sparseMatrix")
  expect_equal(dim(off$X_mu_sparse), c(1L, 1L))
})

test_that("drm_fixed_effect_is_sparse reads the fitted sparse_fixed flag", {
  dat <- data.frame(y = rnorm(8), x = rnorm(8))
  dense <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    family = gaussian(),
    control = drm_control(optimizer = list(eval.max = 80L, iter.max = 80L))
  )
  sparse <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    family = gaussian(),
    control = drm_control(
      sparse_fixed = TRUE,
      optimizer = list(eval.max = 80L, iter.max = 80L)
    )
  )
  expect_false(drmTMB:::drm_fixed_effect_is_sparse(dense, "mu"))
  expect_true(drmTMB:::drm_fixed_effect_is_sparse(sparse, "mu"))
  expect_false(drmTMB:::drm_fixed_effect_is_sparse(sparse, "sigma"))
})

test_that("sha256 forced backends error cleanly when a backend is unavailable", {
  art <- local({
    dir <- file.path(tempdir(), "drmTMB-cov-1127-sha256")
    dir.create(dir, showWarnings = FALSE, recursive = TRUE)
    path <- file.path(dir, "payload.txt")
    writeBin(charToRaw("abc"), path)
    list(path = path)
  })
  if (!exists("sha256sum", envir = asNamespace("tools"), inherits = FALSE)) {
    expect_error(
      drmTMB:::sha256_file_portable(art$path, backend = "tools"),
      "tools::sha256sum is not available",
      fixed = TRUE
    )
  }
  if (!requireNamespace("digest", quietly = TRUE)) {
    expect_error(
      drmTMB:::sha256_file_portable(art$path, backend = "digest"),
      "digest package is not installed",
      fixed = TRUE
    )
  }
  if (!requireNamespace("openssl", quietly = TRUE)) {
    expect_error(
      drmTMB:::sha256_file_portable(art$path, backend = "openssl"),
      "openssl package is not installed",
      fixed = TRUE
    )
  }
  withr::local_envvar(PATH = "")
  expect_error(
    drmTMB:::sha256_file_portable(art$path, backend = "sha256sum"),
    "sha256sum is not on PATH",
    fixed = TRUE
  )
})

test_that("register_foreign_s3_methods succeeds when nlme is available", {
  skip_if_not(requireNamespace("nlme", quietly = TRUE), "nlme is not installed")
  expect_true(isTRUE(drmTMB:::register_foreign_s3_methods()))
})

test_that("temporal formula helpers and empty structures are wired consistently", {
  expect_false(drmTMB:::empty_temporal_mu_structure()$has)
  expect_equal(
    drmTMB:::temporal_structure_name(list(structure = "ou")),
    "Temporal OU"
  )
  temporal_bf <- bf(
    y ~ temporal(1 | id, time = occasion, structure = "ar1"),
    sigma ~ 1
  )
  plain_bf <- bf(y ~ 1, sigma ~ 1)
  expect_true(drmTMB:::drm_formula_has_temporal(temporal_bf))
  expect_false(drmTMB:::drm_formula_has_temporal(plain_bf))
  expect_false(
    drmTMB:::validate_phylo_temporal_ou_pair(
      NULL,
      list(type = "phylo"),
      data.frame(),
      parent.frame()
    )
  )
})

test_that("validate_temporal_wald_parm rejects deferred OU mean intervals", {
  dat <- data.frame(
    id = rep(c("a", "b"), each = 4L),
    elapsed = rep(c(0, 0.5, 1.5, 3), 2L),
    x = stats::rnorm(8L),
    y = stats::rnorm(8L)
  )
  fit <- drmTMB(
    bf(y ~ x + temporal(1 | id, time = elapsed, structure = "ou"), sigma ~ 1),
    data = dat,
    family = gaussian(),
    control = drm_control(optimizer = list(eval.max = 120L, iter.max = 120L))
  )
  expect_error(
    drmTMB:::validate_temporal_wald_parm(fit, NULL),
    "OU mean-coefficient Wald intervals",
    fixed = TRUE
  )
})
# Coverage for R/[s-z]*.R: utils, sparse-fixed, sha256, temporal, zzz helpers.
# Fast unit tests; no new nocov and no relaxed tolerances.

test_that("drm_suggest_closest_name follows prefix then edit-distance rules", {
  suggest <- drmTMB:::drm_suggest_closest_name
  choices <- drmTMB:::drm_nlminb_control_names()

  expect_null(suggest(NULL, choices))
  expect_null(suggest(NA_character_, choices))
  expect_null(suggest("", choices))
  expect_null(suggest("eval", character()))
  expect_null(suggest(1L, choices))
  expect_null(suggest(c("a", "b"), choices))

  expect_equal(suggest("ev", choices), "eval.max")
  expect_equal(suggest("it", choices), "iter.max")

  far <- suggest("zzzzzz", choices, cutoff = 2L)
  expect_null(far)
  close <- suggest("eval.m", choices, cutoff = 3L)
  expect_equal(close, "eval.max")
})

test_that("drm_optimizer_julia_bridge_names lists Julia-only optimizer keys", {
  expect_equal(
    drmTMB:::drm_optimizer_julia_bridge_names(),
    c("g_tol", "algorithm", "q4_vcov")
  )
})

test_that("internal null coalesce keeps empty vectors and NA", {
  op <- drmTMB:::`%||%`
  expect_equal(NULL %||% 1L, 1L)
  expect_equal(0 %||% 1L, 0L)
  expect_equal(character() %||% "fallback", character())
  expect_equal(NA_integer_ %||% 2L, NA_integer_)
})

test_that("drm_sparse_fixed_tmb_data records dense mu designs", {
  dense_mu <- matrix(c(1, 1, 0, 1), nrow = 2L)
  spec_dense <- list(
    sparse_fixed = list(mu = FALSE),
    X = list(mu = dense_mu)
  )
  out_dense <- drmTMB:::drm_sparse_fixed_tmb_data(spec_dense)
  expect_equal(out_dense$use_sparse_X_mu, 0L)
  expect_s4_class(out_dense$X_mu_sparse, "sparseMatrix")
  expect_equal(unname(as.matrix(out_dense$X_mu_sparse)), matrix(0, 1L, 1L))

  sparse_mu <- Matrix::sparseMatrix(i = c(1, 2, 2), j = c(1, 1, 2), x = c(1, 1, 1))
  spec_sparse <- list(
    sparse_fixed = list(mu = TRUE),
    X = list(mu = sparse_mu)
  )
  out_sparse <- drmTMB:::drm_sparse_fixed_tmb_data(spec_sparse)
  expect_equal(out_sparse$use_sparse_X_mu, 1L)
  expect_identical(out_sparse$X_mu_sparse, sparse_mu)
})

test_that("drm_fixed_effect_is_sparse reads per-dpar flags", {
  object <- list(model = list(sparse_fixed = list(mu = TRUE, sigma = FALSE)))
  expect_true(drmTMB:::drm_fixed_effect_is_sparse(object, "mu"))
  expect_false(drmTMB:::drm_fixed_effect_is_sparse(object, "sigma"))
  expect_false(drmTMB:::drm_fixed_effect_is_sparse(list(model = list()), "mu"))
})

test_that("empty temporal mu structure is a well-formed placeholder", {
  empty <- drmTMB:::empty_temporal_mu_structure()
  expect_false(empty$has)
  expect_identical(empty$type, "temporal")
  expect_equal(empty$n_series, 0L)
  expect_equal(empty$n_re, 0L)
  expect_equal(empty$n_occasions, 0L)
})

test_that("temporal structure labels and formula detection stay aligned", {
  term <- list(structure = "homtoep")
  expect_equal(drmTMB:::temporal_structure_name(term), "Temporal HOMTOEP")
  with_temporal <- drmTMB::bf(
    y ~ temporal(1 | id, time = occasion, structure = "ar1"),
    sigma ~ 1
  )
  without_temporal <- drmTMB::bf(y ~ x, sigma ~ 1)
  expect_true(drmTMB:::drm_formula_has_temporal(with_temporal))
  expect_false(drmTMB:::drm_formula_has_temporal(without_temporal))
})

test_that("validate_temporal_raw_data accepts null terms and rejects bad metadata", {
  expect_invisible(drmTMB:::validate_temporal_raw_data(NULL, data.frame(y = 1)))

  term <- list(group = "id", time = "occasion", structure = "ar1")
  expect_error(
    drmTMB:::validate_temporal_raw_data(term, data.frame(y = 1)),
    "Missing temporal column"
  )
  expect_error(
    drmTMB:::validate_temporal_raw_data(
      term,
      data.frame(id = c("a", "b"), occasion = c(1L, NA_integer_))
    ),
    "missing value"
  )
  expect_error(
    drmTMB:::validate_temporal_raw_data(
      term,
      data.frame(id = c("a", "b"), occasion = c(1L, Inf))
    ),
    "finite numeric"
  )
  expect_error(
    drmTMB:::validate_temporal_raw_data(
      term,
      data.frame(
        id = c("a", "b"),
        occasion = structure(c(1, 2), class = "Date")
      )
    ),
    "finite numeric"
  )
})

test_that("validate_temporal_gaussian_terms guards sigma and intercept rules", {
  term <- list(
    group = "id",
    time = "occasion",
    structure = "ar1"
  )
  empty_re <- list(terms = list())
  expect_invisible(
    drmTMB:::validate_temporal_gaussian_terms(
      NULL,
      mu_re = empty_re,
      sigma_re = empty_re,
      sigma_rhs = quote(1),
      data = data.frame(id = "a", occasion = 1)
    )
  )
  expect_error(
    drmTMB:::validate_temporal_gaussian_terms(
      term,
      mu_re = empty_re,
      sigma_re = empty_re,
      sigma_rhs = quote(x),
      data = data.frame(id = c("a", "b"), occasion = c(1, 2), x = 1:2)
    ),
    "sigma ~ 1"
  )
})

test_that("validate_phylo_temporal_ou_pair is inert unless both terms are present", {
  data <- data.frame(species = "a", elapsed = 1)
  expect_false(
    drmTMB:::validate_phylo_temporal_ou_pair(NULL, NULL, data, environment())
  )
  phylo_term <- list(
    type = "phylo",
    coef_names = "(Intercept)",
    covariance_label = NULL,
    group = "species",
    tree = "tree"
  )
  ou <- list(structure = "ou", group = "id", time = "elapsed")
  expect_error(
    drmTMB:::validate_phylo_temporal_ou_pair(
      ou,
      phylo_term,
      data.frame(species = "a", id = "a", elapsed = c(0, 1)),
      environment()
    ),
    "same grouping ID"
  )
})

test_that("temporal label helpers distinguish paired phylo-stable OU fits", {
  plain <- list(paired_phylo_stable = FALSE, label = "temporal_cor:occasion")
  paired <- list(paired_phylo_stable = TRUE, label = "temporal_cor:occasion")
  expect_equal(drmTMB:::temporal_mu_sd_label(plain), "temporal_sd: temporal_cor:occasion")
  expect_equal(drmTMB:::temporal_mu_sd_label(paired), "sd_temporal")
  expect_equal(drmTMB:::temporal_mu_decay_label(plain), plain$label)
  expect_equal(drmTMB:::temporal_mu_decay_label(paired), "decay_temporal")
})

test_that("temporal_homtoep_correlations wraps the Levinson map", {
  theta <- c(0.2, -0.1)
  rho <- drmTMB:::temporal_homtoep_correlations(theta)
  expect_equal(rho, drmTMB:::temporal_homtoep_levinson(theta)$rho)
  expect_length(rho, length(theta) + 1L)
})

test_that("drm_has_temporal_mu reflects the fitted structured slot", {
  bare <- list(model = list())
  expect_false(drmTMB:::drm_has_temporal_mu(bare))
  with_temporal <- list(
    model = list(
      structured = list(
        temporal_mu = list(has = TRUE, structure = "ar1")
      )
    )
  )
  expect_true(drmTMB:::drm_has_temporal_mu(with_temporal))
})

test_that("sha256_file_portable surfaces missing-backend errors", {
  path <- tempfile("drm-sha256-missing-backend-")
  writeLines("cov-1127", path)
  on.exit(unlink(path), add = TRUE)
  ns <- asNamespace("drmTMB")
  local_mocked_bindings(
    requireNamespace = function(pkg, quietly = TRUE, ...) {
      if (identical(pkg, "openssl")) {
        return(FALSE)
      }
      base::requireNamespace(pkg, quietly = quietly, ...)
    },
    .package = "base",
    .env = ns
  )
  expect_error(
    drmTMB:::sha256_file_portable(path, backend = "openssl"),
    "openssl package is not installed"
  )
  local_mocked_bindings(
    requireNamespace = function(pkg, quietly = TRUE, ...) {
      if (identical(pkg, "digest")) {
        return(FALSE)
      }
      base::requireNamespace(pkg, quietly = quietly, ...)
    },
    .package = "base",
    .env = ns
  )
  expect_error(
    drmTMB:::sha256_file_portable(path, backend = "digest"),
    "digest package is not installed"
  )
})

test_that("temporal_mu_contribution is zero for homtoep marginal models", {
  object <- list(
    model = list(structured = list(temporal_mu = list(structure = "homtoep"))),
    data = data.frame(y = 1:4)
  )
  expect_equal(drmTMB:::temporal_mu_contribution(object), rep(0, 4L))
})

test_that("temporal_homtoep_fit_levinson refuses non-homtoep structures", {
  fake_fit <- list(
    model = list(structured = list(temporal_mu = list(structure = "ar1"))),
    opt = list(par = c(theta_temporal = 0.1)),
    sdr = list()
  )
  expect_error(
    drmTMB:::temporal_homtoep_fit_levinson(fake_fit),
    "different temporal structure"
  )
})
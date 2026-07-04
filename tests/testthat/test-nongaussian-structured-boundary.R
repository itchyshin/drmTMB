test_that("non-Gaussian structured effects have an explicit boundary", {
  dat_count <- data.frame(
    y = c(0, 1, 2, 3, 4, 5),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5),
    id = factor(rep(1:3, each = 2))
  )
  dat_beta <- transform(dat_count, y = c(0.1, 0.2, 0.35, 0.5, 0.7, 0.85))
  dat_ord <- transform(
    dat_count,
    y = ordered(
      c("low", "medium", "high", "low", "medium", "high"),
      levels = c("low", "medium", "high")
    )
  )
  dat_pos <- transform(dat_count, y = y + 1)
  testthat::skip_if_not_installed("ape")
  tree <- ape::stree(3L, type = "star")
  tree$tip.label <- levels(dat_count$id)
  tree$edge.length <- rep(1, nrow(tree$edge))

  expect_error(
    drmTMB(
      bf(y ~ x + phylo(0 + x | id, tree = tree)),
      family = stats::poisson(link = "log"),
      data = dat_count
    ),
    "intercept-only or one-slope"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + spatial(1 | id, coords = coords), sigma ~ 1),
      family = student(),
      data = dat_pos
    ),
    "Structured non-Gaussian paths"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1),
      family = beta(),
      data = dat_beta
    ),
    "Structured non-Gaussian paths"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1),
      family = stats::Gamma(link = "log"),
      data = dat_pos
    ),
    "Structured non-Gaussian paths"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + phylo(1 | id, tree = tree)),
      family = cumulative_logit(),
      data = dat_ord
    ),
    "Structured non-Gaussian paths"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ animal(1 | id, pedigree = ped)),
      family = beta(),
      data = dat_beta
    ),
    "Structured non-Gaussian paths"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, nu ~ phylo(1 | id, tree = tree)),
      family = student(),
      data = dat_pos
    ),
    "Structured non-Gaussian paths"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, zi ~ spatial(1 | id, coords = coords)),
      family = stats::poisson(link = "log"),
      data = dat_count
    ),
    "Structured non-Gaussian paths"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, hu ~ relmat(1 | id, Q = Q)),
      family = truncated_nbinom2(),
      data = dat_count
    ),
    "Structured non-Gaussian paths"
  )

  # Count NB2 sigma one-slope structured-scale routes are rejected at the
  # pre-optimization formula gate for every structured provider. These back the
  # count-slope sigma one-slope rejection contract: count mu one-slope support
  # does not imply count sigma one-slope support.
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ phylo(1 + x | id, tree = tree)),
      family = nbinom2(),
      data = dat_count
    ),
    "Structured non-Gaussian paths"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ spatial(1 + x | id, coords = coords)),
      family = nbinom2(),
      data = dat_count
    ),
    "Structured non-Gaussian paths"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ animal(1 + x | id, Ainv = Q)),
      family = nbinom2(),
      data = dat_count
    ),
    "Structured non-Gaussian paths"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ relmat(1 + x | id, Q = Q)),
      family = nbinom2(),
      data = dat_count
    ),
    "Structured non-Gaussian paths"
  )
})

test_that("q-series v1 first-four rejection smoke reproduces current gates", {
  testthat::skip_on_cran()
  rscript <- file.path(R.home("bin"), "Rscript")
  testthat::skip_if(!file.exists(rscript), "Rscript is not available")
  tool <- file.path(
    "tools",
    "qseries-v1-first-four-rejection-smoke.R"
  )
  if (!file.exists(tool)) {
    tool <- file.path(
      "..",
      "..",
      "tools",
      "qseries-v1-first-four-rejection-smoke.R"
    )
  }
  testthat::skip_if_not(file.exists(tool))
  output <- tempfile(fileext = ".tsv")
  smoke <- system2(
    rscript,
    c("--vanilla", tool, "--output", output),
    stdout = TRUE,
    stderr = TRUE
  )
  smoke_status <- attr(smoke, "status")
  if (is.null(smoke_status)) {
    smoke_status <- 0L
  }
  expect_equal(smoke_status, 0L, info = paste(smoke, collapse = "\n"))
  result <- utils::read.delim(
    output,
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  expect_named(
    result,
    c(
      "gate_id",
      "cell_id",
      "formula_cell",
      "family",
      "provider",
      "expected_error_pattern",
      "status",
      "observed_error",
      "claim_boundary"
    )
  )
  expect_equal(
    result$cell_id,
    c(
      "qseries_beta_mu_animal_rejected",
      "qseries_gamma_mu_relmat_rejected",
      "qseries_ordinal_mu_phylo_rejected",
      "qseries_student_mu_spatial_rejected"
    )
  )
  expect_equal(
    result$status,
    c("expected_fit", rep("expected_rejection", 3L))
  )
  expect_equal(
    result$expected_error_pattern,
    c("", rep("Structured non-Gaussian paths", 3L))
  )
  expect_true(all(grepl(
    "Structured non-Gaussian paths",
    result$observed_error[-1L],
    fixed = TRUE
  )))
  expect_true(all(grepl(
    "no denominator, coverage",
    result$claim_boundary,
    fixed = TRUE
  )))
})

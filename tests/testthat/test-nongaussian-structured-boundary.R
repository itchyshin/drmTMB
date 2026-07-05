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
  levels_id <- levels(dat_count$id)
  K <- diag(length(levels_id))
  dimnames(K) <- list(levels_id, levels_id)
  Q <- K
  coords <- data.frame(
    x = c(0, 1, 0),
    y = c(0, 0, 1),
    row.names = levels_id
  )
  ped <- data.frame(
    id = levels_id,
    dam = NA_character_,
    sire = NA_character_
  )
  set.seed(2026070402)
  gamma_levels <- paste0("g", seq_len(8L))
  gamma_id <- factor(rep(gamma_levels, each = 10L), levels = gamma_levels)
  gamma_x <- stats::rnorm(length(gamma_id))
  gamma_field <- stats::rnorm(length(gamma_levels), sd = 0.25)
  names(gamma_field) <- gamma_levels
  gamma_mu <- exp(0.4 + 0.25 * gamma_x + gamma_field[as.character(gamma_id)])
  dat_gamma_relmat <- data.frame(
    y = stats::rgamma(length(gamma_id), shape = 25, scale = gamma_mu / 25),
    x = gamma_x,
    id = gamma_id
  )
  K_gamma <- diag(length(gamma_levels))
  dimnames(K_gamma) <- list(gamma_levels, gamma_levels)
  set.seed(2026070403)
  student_levels <- paste0("s", seq_len(8L))
  student_id <- factor(rep(student_levels, each = 16L), levels = student_levels)
  student_x <- stats::rnorm(length(student_id))
  student_field <- stats::rnorm(length(student_levels), sd = 0.2)
  names(student_field) <- student_levels
  student_mu <- 0.2 + 0.5 * student_x + student_field[as.character(student_id)]
  dat_student_spatial <- data.frame(
    y = student_mu + 0.25 * stats::rt(length(student_id), df = 12),
    x = student_x,
    id = student_id
  )
  coords_student <- data.frame(
    x = rep(seq_len(4L), each = 2L),
    y = rep(seq_len(2L), times = 4L),
    row.names = student_levels
  )
  set.seed(2026070404)
  beta_sigma_levels <- paste0("bs", seq_len(8L))
  beta_sigma_id <- factor(
    rep(beta_sigma_levels, each = 16L),
    levels = beta_sigma_levels
  )
  beta_sigma_x <- stats::rnorm(length(beta_sigma_id))
  beta_sigma_field <- stats::rnorm(length(beta_sigma_levels), sd = 0.18)
  names(beta_sigma_field) <- beta_sigma_levels
  beta_sigma_mu <- stats::plogis(-0.2 + 0.45 * beta_sigma_x)
  beta_sigma_sigma <- exp(
    log(0.22) + beta_sigma_field[as.character(beta_sigma_id)]
  )
  beta_sigma_phi <- 1 / (beta_sigma_sigma^2)
  dat_beta_sigma_animal <- data.frame(
    y = stats::rbeta(
      length(beta_sigma_id),
      shape1 = beta_sigma_mu * beta_sigma_phi,
      shape2 = (1 - beta_sigma_mu) * beta_sigma_phi
    ),
    x = beta_sigma_x,
    id = beta_sigma_id
  )
  ped_beta_sigma <- data.frame(
    id = beta_sigma_levels,
    dam = NA_character_,
    sire = NA_character_
  )
  set.seed(2026070405)
  nb_sigma_levels <- paste0("nbs", seq_len(8L))
  nb_sigma_id <- factor(
    rep(nb_sigma_levels, each = 18L),
    levels = nb_sigma_levels
  )
  nb_sigma_x <- stats::rnorm(length(nb_sigma_id))
  nb_sigma_field0 <- stats::rnorm(length(nb_sigma_levels), sd = 0.20)
  nb_sigma_field1 <- stats::rnorm(length(nb_sigma_levels), sd = 0.10)
  names(nb_sigma_field0) <- nb_sigma_levels
  names(nb_sigma_field1) <- nb_sigma_levels
  nb_sigma_mu <- exp(1.0 + 0.35 * nb_sigma_x)
  nb_sigma_sigma <- exp(
    log(0.35) +
      nb_sigma_field0[as.character(nb_sigma_id)] +
      nb_sigma_field1[as.character(nb_sigma_id)] * nb_sigma_x
  )
  dat_nb_sigma <- data.frame(
    y = stats::rnbinom(
      length(nb_sigma_id),
      mu = nb_sigma_mu,
      size = 1 / (nb_sigma_sigma^2)
    ),
    x = nb_sigma_x,
    id = nb_sigma_id
  )
  K_nb_sigma <- diag(length(nb_sigma_levels))
  dimnames(K_nb_sigma) <- list(nb_sigma_levels, nb_sigma_levels)
  Q_nb_sigma <- K_nb_sigma
  coords_nb_sigma <- data.frame(
    x = rep(seq_len(4L), each = 2L),
    y = rep(seq_len(2L), times = 4L),
    row.names = nb_sigma_levels
  )
  tree_nb_sigma <- ape::stree(length(nb_sigma_levels), type = "star")
  tree_nb_sigma$tip.label <- nb_sigma_levels
  tree_nb_sigma$edge.length <- rep(1, nrow(tree_nb_sigma$edge))
  tree <- ape::stree(3L, type = "star")
  tree$tip.label <- levels_id
  tree$edge.length <- rep(1, nrow(tree$edge))

  expect_error(
    drmTMB(
      bf(y ~ x + phylo(0 + x | id, tree = tree)),
      family = stats::poisson(link = "log"),
      data = dat_count
    ),
    "intercept-only or one-slope"
  )
  fit_student_spatial <- drmTMB(
    bf(y ~ x + spatial(1 | id, coords = coords_student), sigma ~ 1),
    family = student(),
    data = dat_student_spatial,
    control = drm_control(se = FALSE)
  )
  expect_s3_class(fit_student_spatial, "drmTMB")
  expect_equal(as.integer(fit_student_spatial$opt$convergence), 0L)
  expect_true("spatial_mu" %in% names(fit_student_spatial$random_effects))
  expect_true(
    any(grepl("^spatial\\(", names(fit_student_spatial$sdpars$mu)))
  )
  expect_error(
    drmTMB(
      bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1),
      family = beta(),
      data = dat_beta
    ),
    "Structured non-Gaussian paths"
  )
  fit_gamma_relmat <- drmTMB(
    bf(y ~ x + relmat(1 | id, K = K_gamma), sigma ~ 1),
    family = stats::Gamma(link = "log"),
    data = dat_gamma_relmat,
    control = drm_control(se = FALSE)
  )
  expect_s3_class(fit_gamma_relmat, "drmTMB")
  expect_equal(as.integer(fit_gamma_relmat$opt$convergence), 0L)
  expect_true("relmat_mu" %in% names(fit_gamma_relmat$random_effects))
  expect_true(
    any(grepl("^relmat\\(", names(fit_gamma_relmat$sdpars$mu)))
  )
  fit_beta_sigma_animal <- drmTMB(
    bf(y ~ x, sigma ~ animal(1 | id, pedigree = ped_beta_sigma)),
    family = beta(),
    data = dat_beta_sigma_animal,
    control = drm_control(se = FALSE)
  )
  expect_s3_class(fit_beta_sigma_animal, "drmTMB")
  expect_equal(as.integer(fit_beta_sigma_animal$opt$convergence), 0L)
  expect_true("animal_sigma" %in% names(fit_beta_sigma_animal$random_effects))
  expect_true(
    any(grepl("^animal\\(", names(fit_beta_sigma_animal$sdpars$sigma)))
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
      bf(y ~ x, sigma ~ animal(1 + x | id, pedigree = ped)),
      family = beta(),
      data = dat_beta
    ),
    "intercept-only structured terms"
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

  # Count NB2 sigma one-slope structured-scale routes are local fit-only
  # recovery rows. This does not imply retained denominators, intervals,
  # coverage, labelled covariance, or count location-scale support.
  nb_sigma_fits <- list(
    phylo = drmTMB(
      bf(y ~ x, sigma ~ phylo(1 + x | id, tree = tree_nb_sigma)),
      family = nbinom2(),
      data = dat_nb_sigma,
      control = drm_control(se = FALSE)
    ),
    spatial = drmTMB(
      bf(y ~ x, sigma ~ spatial(1 + x | id, coords = coords_nb_sigma)),
      family = nbinom2(),
      data = dat_nb_sigma,
      control = drm_control(se = FALSE)
    ),
    animal = drmTMB(
      bf(y ~ x, sigma ~ animal(1 + x | id, Ainv = Q_nb_sigma)),
      family = nbinom2(),
      data = dat_nb_sigma,
      control = drm_control(se = FALSE)
    ),
    relmat = drmTMB(
      bf(y ~ x, sigma ~ relmat(1 + x | id, Q = Q_nb_sigma)),
      family = nbinom2(),
      data = dat_nb_sigma,
      control = drm_control(se = FALSE)
    )
  )
  for (provider in names(nb_sigma_fits)) {
    fit <- nb_sigma_fits[[provider]]
    expect_s3_class(fit, "drmTMB")
    expect_equal(as.integer(fit$opt$convergence), 0L)
    expect_true(paste0(provider, "_sigma") %in% names(fit$random_effects))
    expect_true(
      any(grepl(paste0("^", provider, "\\("), names(fit$sdpars$sigma)))
    )
  }
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ animal(1 + x | p | id, Ainv = Q_nb_sigma)),
      family = nbinom2(),
      data = dat_nb_sigma
    ),
    "unlabelled independent one-slope"
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
      "qseries_student_mu_spatial_rejected",
      "qseries_beta_sigma_animal_rejected",
      "qseries_phylo_nbinom2_q1_sigma_one_slope_rejected",
      "qseries_spatial_nbinom2_q1_sigma_one_slope_rejected",
      "qseries_animal_nbinom2_q1_sigma_one_slope_rejected",
      "qseries_relmat_nbinom2_q1_sigma_one_slope_rejected"
    )
  )
  expect_equal(
    result$status,
    c(
      "expected_fit",
      "expected_fit",
      "expected_rejection",
      "expected_fit",
      "expected_fit",
      "expected_fit",
      "expected_fit",
      "expected_fit",
      "expected_fit"
    )
  )
  expect_equal(
    result$expected_error_pattern,
    c("", "", "Structured non-Gaussian paths", "", "", "", "", "", "")
  )
  expect_true(all(grepl(
    "Structured non-Gaussian paths",
    result$observed_error[result$status == "expected_rejection"],
    fixed = TRUE
  )))
  expect_true(all(grepl(
    "no denominator, coverage",
    result$claim_boundary,
    fixed = TRUE
  )))
})

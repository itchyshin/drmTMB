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
  set.seed(2026070401)
  student_nu_levels <- paste0("sn", seq_len(6L))
  student_nu_id <- factor(
    rep(student_nu_levels, each = 30L),
    levels = student_nu_levels
  )
  student_nu_x <- stats::rnorm(length(student_nu_id))
  student_nu_field <- stats::rnorm(length(student_nu_levels), sd = 0.02)
  names(student_nu_field) <- student_nu_levels
  student_nu <- 2 + exp(
    log(5) + student_nu_field[as.character(student_nu_id)]
  )
  student_nu_mu <- 0.1 + 0.35 * student_nu_x
  dat_student_nu_phylo <- data.frame(
    y = student_nu_mu + 0.25 * stats::rt(length(student_nu_id), df = student_nu),
    x = student_nu_x,
    id = student_nu_id
  )
  tree_student_nu <- ape::stree(length(student_nu_levels), type = "star")
  tree_student_nu$tip.label <- student_nu_levels
  tree_student_nu$edge.length <- rep(1, nrow(tree_student_nu$edge))
  set.seed(2026070407)
  poisson_zi_levels <- paste0("pz", seq_len(8L))
  poisson_zi_id <- factor(
    rep(poisson_zi_levels, each = 24L),
    levels = poisson_zi_levels
  )
  poisson_zi_x <- stats::rnorm(length(poisson_zi_id))
  poisson_zi_field <- stats::rnorm(length(poisson_zi_levels), sd = 0.75)
  names(poisson_zi_field) <- poisson_zi_levels
  poisson_zi_mu <- exp(0.7 + 0.25 * poisson_zi_x)
  poisson_zi_prob <- stats::plogis(
    -0.8 + poisson_zi_field[as.character(poisson_zi_id)]
  )
  dat_poisson_zi_spatial <- data.frame(
    y = ifelse(
      stats::rbinom(length(poisson_zi_id), size = 1L, prob = poisson_zi_prob) == 1L,
      0L,
      stats::rpois(length(poisson_zi_id), lambda = poisson_zi_mu)
    ),
    x = poisson_zi_x,
    id = poisson_zi_id
  )
  coords_poisson_zi <- data.frame(
    x = rep(seq_len(4L), each = 2L),
    y = rep(seq_len(2L), times = 4L),
    row.names = poisson_zi_levels
  )
  set.seed(2026070412)
  poisson_plus_sites <- paste0("site", seq_len(8L))
  poisson_plus_ids <- paste0("id", seq_len(16L))
  poisson_plus_theta <- seq(0, 1.75 * pi, length.out = length(poisson_plus_sites))
  coords_poisson_plus <- data.frame(
    x = cos(poisson_plus_theta),
    y = sin(poisson_plus_theta),
    row.names = poisson_plus_sites
  )
  poisson_plus_precision <- drmTMB:::drm_spatial_coords_precision(
    coords_poisson_plus,
    site = poisson_plus_sites,
    group = "site"
  )
  poisson_plus_cov <- solve(as.matrix(poisson_plus_precision$precision))
  poisson_plus_spatial <- as.vector(
    t(chol(poisson_plus_cov)) %*%
      stats::rnorm(length(poisson_plus_sites), sd = 0.45)
  )
  names(poisson_plus_spatial) <- poisson_plus_sites
  poisson_plus_id <- rep(poisson_plus_ids, each = 16L)
  poisson_plus_site_for_id <- rep(poisson_plus_sites, length.out = length(poisson_plus_ids))
  names(poisson_plus_site_for_id) <- poisson_plus_ids
  poisson_plus_site <- unname(poisson_plus_site_for_id[poisson_plus_id])
  poisson_plus_x <- stats::rnorm(length(poisson_plus_id))
  poisson_plus_ordinary <- stats::rnorm(length(poisson_plus_ids), sd = 0.25)
  names(poisson_plus_ordinary) <- poisson_plus_ids
  poisson_plus_eta <- 0.55 -
    0.20 * poisson_plus_x +
    poisson_plus_spatial[poisson_plus_site] +
    poisson_plus_ordinary[poisson_plus_id]
  dat_poisson_plus_ordinary <- data.frame(
    y = stats::rpois(length(poisson_plus_id), lambda = exp(poisson_plus_eta)),
    x = poisson_plus_x,
    site = factor(poisson_plus_site, levels = poisson_plus_sites),
    id = factor(poisson_plus_id, levels = poisson_plus_ids)
  )
  set.seed(2026070502)
  poisson_slope_levels <- paste0("ps", seq_len(8L))
  poisson_slope_site <- factor(
    rep(poisson_slope_levels, each = 25L),
    levels = poisson_slope_levels
  )
  poisson_slope_x <- stats::rnorm(length(poisson_slope_site))
  poisson_slope_theta <- seq(
    0,
    1.75 * pi,
    length.out = length(poisson_slope_levels)
  )
  coords_poisson_slope <- data.frame(
    x = cos(poisson_slope_theta) +
      seq_along(poisson_slope_levels) / (4 * length(poisson_slope_levels)),
    y = sin(poisson_slope_theta),
    row.names = poisson_slope_levels
  )
  poisson_slope_precision <- drmTMB:::drm_spatial_coords_precision(
    coords_poisson_slope,
    site = poisson_slope_levels,
    group = "site"
  )
  poisson_slope_cov <- solve(as.matrix(poisson_slope_precision$precision))
  poisson_slope_field <- as.vector(
    t(chol(poisson_slope_cov)) %*%
      stats::rnorm(length(poisson_slope_levels), sd = 0.40)
  )
  names(poisson_slope_field) <- poisson_slope_levels
  poisson_slope_eta <- 0.45 -
    0.18 * poisson_slope_x +
    poisson_slope_x * poisson_slope_field[as.character(poisson_slope_site)]
  dat_poisson_slope_only <- data.frame(
    y = stats::rpois(length(poisson_slope_site), lambda = exp(poisson_slope_eta)),
    x = poisson_slope_x,
    site = poisson_slope_site
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
  fit_student_nu_phylo <- drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ phylo(1 | id, tree = tree_student_nu)),
    family = student(),
    data = dat_student_nu_phylo,
    control = drm_control(se = FALSE)
  )
  expect_s3_class(fit_student_nu_phylo, "drmTMB")
  expect_equal(as.integer(fit_student_nu_phylo$opt$convergence), 0L)
  expect_true("phylo_nu" %in% names(fit_student_nu_phylo$random_effects))
  expect_true(
    any(grepl("^phylo\\(", names(fit_student_nu_phylo$sdpars$nu)))
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, nu ~ phylo(1 + x | id, tree = tree_student_nu)),
      family = student(),
      data = dat_student_nu_phylo
    ),
    "intercept-only structured terms"
  )
  fit_poisson_zi_spatial <- drmTMB(
    bf(y ~ x, zi ~ spatial(1 | id, coords = coords_poisson_zi)),
    family = stats::poisson(link = "log"),
    data = dat_poisson_zi_spatial,
    control = drm_control(se = FALSE)
  )
  expect_s3_class(fit_poisson_zi_spatial, "drmTMB")
  expect_equal(as.integer(fit_poisson_zi_spatial$opt$convergence), 0L)
  expect_true("spatial_zi" %in% names(fit_poisson_zi_spatial$random_effects))
  expect_true(
    any(grepl("^spatial\\(", names(fit_poisson_zi_spatial$sdpars$zi)))
  )
  fit_poisson_zi_mu_spatial <- drmTMB(
    bf(y ~ x + spatial(1 | id, coords = coords_poisson_zi), zi ~ 1),
    family = stats::poisson(link = "log"),
    data = dat_poisson_zi_spatial,
    control = drm_control(se = FALSE)
  )
  expect_s3_class(fit_poisson_zi_mu_spatial, "drmTMB")
  expect_equal(as.integer(fit_poisson_zi_mu_spatial$opt$convergence), 0L)
  expect_true(
    "spatial_mu" %in% names(fit_poisson_zi_mu_spatial$random_effects)
  )
  expect_true(
    any(grepl("^spatial\\(", names(fit_poisson_zi_mu_spatial$sdpars$mu)))
  )
  fit_poisson_plus_ordinary <- drmTMB(
    bf(y ~ x + spatial(1 | site, coords = coords_poisson_plus) + (1 | id)),
    family = stats::poisson(link = "log"),
    data = dat_poisson_plus_ordinary
  )
  expect_s3_class(fit_poisson_plus_ordinary, "drmTMB")
  expect_equal(as.integer(fit_poisson_plus_ordinary$opt$convergence), 0L)
  expect_true(fit_poisson_plus_ordinary$sdr$pdHess)
  expect_setequal(
    names(fit_poisson_plus_ordinary$random_effects),
    c("mu", "spatial_mu")
  )
  expect_setequal(
    names(fit_poisson_plus_ordinary$sdpars$mu),
    c("(1 | id)", "spatial(1 | site)")
  )
  fit_poisson_slope_only <- drmTMB(
    bf(y ~ x + spatial(0 + x | site, coords = coords_poisson_slope)),
    family = stats::poisson(link = "log"),
    data = dat_poisson_slope_only,
    control = drm_control(se = FALSE)
  )
  expect_s3_class(fit_poisson_slope_only, "drmTMB")
  expect_equal(as.integer(fit_poisson_slope_only$opt$convergence), 0L)
  expect_true("spatial_mu" %in% names(fit_poisson_slope_only$random_effects))
  expect_named(fit_poisson_slope_only$sdpars$mu, "spatial(0 + x | site)")
  expect_error(
    drmTMB(
      bf(y ~ x, zi ~ spatial(1 + x | id, coords = coords_poisson_zi)),
      family = stats::poisson(link = "log"),
      data = dat_poisson_zi_spatial
    ),
    "intercept-only structured terms"
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
      "qseries_truncnbinom2_hu_relmat_rejected",
      "qseries_count_mu_labelled_q2_rejected",
      "qseries_count_mu_simultaneous_structured_types_rejected",
      "qseries_student_mu_spatial_rejected",
      "qseries_student_nu_phylo_rejected",
      "qseries_poisson_zi_spatial_rejected",
      "qseries_count_mu_zeroinflated_poisson_structured_rejected",
      "qseries_count_mu_structured_plus_ordinary_rejected",
      "qseries_count_mu_noncanonical_term_rejected",
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
      "expected_rejection",
      "expected_rejection",
      "expected_rejection",
      "expected_fit",
      "expected_fit",
      "expected_fit",
      "expected_fit",
      "expected_fit",
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
    c(
      "",
      "",
      "Structured non-Gaussian paths",
      "Structured non-Gaussian paths",
      "unlabelled q=1",
      "Only one structured",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      ""
    )
  )
  rejection_rows <- result[result$status == "expected_rejection", , drop = FALSE]
  expect_true(all(mapply(
    grepl,
    pattern = rejection_rows$expected_error_pattern,
    x = rejection_rows$observed_error,
    fixed = TRUE
  )))
  expect_true(all(grepl(
    "no denominator, coverage",
    result$claim_boundary,
    fixed = TRUE
  )))
})

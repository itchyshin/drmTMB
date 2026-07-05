#!/usr/bin/env Rscript

load_drmTMB_for_smoke <- function(root = ".") {
  if (requireNamespace("pkgload", quietly = TRUE)) {
    pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
    return(invisible(TRUE))
  }
  stop("The pkgload package is required for this source-tree smoke.", call. = FALSE)
}

qseries_v1_first_four_fixture <- function() {
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
  levels_id <- levels(dat_count$id)
  K <- diag(length(levels_id))
  dimnames(K) <- list(levels_id, levels_id)
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
  set.seed(2026070401)
  beta_levels <- paste0("a", seq_len(8L))
  beta_id <- factor(rep(beta_levels, each = 10L), levels = beta_levels)
  beta_x <- stats::rnorm(length(beta_id))
  beta_field <- stats::rnorm(length(beta_levels), sd = 0.35)
  names(beta_field) <- beta_levels
  beta_eta <- -0.25 + 0.45 * beta_x + beta_field[as.character(beta_id)]
  beta_mu <- stats::plogis(beta_eta)
  beta_phi <- 35
  dat_beta_animal <- data.frame(
    y = stats::rbeta(
      length(beta_id),
      shape1 = beta_mu * beta_phi,
      shape2 = (1 - beta_mu) * beta_phi
    ),
    x = beta_x,
    id = beta_id
  )
  ped_beta <- data.frame(
    id = beta_levels,
    dam = NA_character_,
    sire = NA_character_
  )
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
  tree_nb_sigma <- structure(
    list(
      edge = cbind(
        length(nb_sigma_levels) + 1L,
        seq_len(length(nb_sigma_levels))
      ),
      tip.label = nb_sigma_levels,
      Nnode = 1L,
      edge.length = rep(1, length(nb_sigma_levels))
    ),
    class = "phylo"
  )
  tree <- structure(
    list(
      edge = matrix(c(4, 1, 4, 2, 4, 3), ncol = 2, byrow = TRUE),
      tip.label = levels_id,
      Nnode = 1L,
      edge.length = c(1, 1, 1)
    ),
    class = "phylo"
  )

  list(
    list(
      gate_id = "nongaussian_struct_fit_beta_mu_animal",
      cell_id = "qseries_beta_mu_animal_rejected",
      formula_cell = "animal(1 | id, pedigree = ped) in mu",
      family = "beta()",
      provider = "animal",
      expected_status = "expected_fit",
      expr = quote(drmTMB::drmTMB(
        drmTMB::bf(y ~ x + animal(1 | id, pedigree = ped_beta), sigma ~ 1),
        family = drmTMB::beta(),
        data = dat_beta_animal,
        control = drmTMB::drm_control(se = FALSE)
      )),
      expected_random_effect = "animal_mu",
      expected_sd_pattern = "^animal\\(",
      env = environment()
    ),
    list(
      gate_id = "nongaussian_struct_fit_gamma_mu_relmat",
      cell_id = "qseries_gamma_mu_relmat_rejected",
      formula_cell = "relmat(1 | id, K = K) in mu",
      family = "Gamma()",
      provider = "relmat",
      expected_status = "expected_fit",
      expr = quote(drmTMB::drmTMB(
        drmTMB::bf(y ~ x + relmat(1 | id, K = K_gamma), sigma ~ 1),
        family = stats::Gamma(link = "log"),
        data = dat_gamma_relmat,
        control = drmTMB::drm_control(se = FALSE)
      )),
      expected_random_effect = "relmat_mu",
      expected_sd_pattern = "^relmat\\(",
      env = environment()
    ),
    list(
      gate_id = "nongaussian_struct_reject_ordinal_mu_phylo",
      cell_id = "qseries_ordinal_mu_phylo_rejected",
      formula_cell = "phylo(1 | id, tree = tree) in mu",
      family = "cumulative_logit()",
      provider = "phylo",
      expected_status = "expected_rejection",
      expr = quote(drmTMB::drmTMB(
        drmTMB::bf(y ~ x + phylo(1 | id, tree = tree)),
        family = drmTMB::cumulative_logit(),
        data = dat_ord
      )),
      env = environment()
    ),
    list(
      gate_id = "nongaussian_struct_fit_student_mu_spatial",
      cell_id = "qseries_student_mu_spatial_rejected",
      formula_cell = "spatial(1 | id, coords = coords) in mu",
      family = "student()",
      provider = "spatial",
      expected_status = "expected_fit",
      expr = quote(drmTMB::drmTMB(
        drmTMB::bf(y ~ x + spatial(1 | id, coords = coords_student), sigma ~ 1),
        family = drmTMB::student(),
        data = dat_student_spatial,
        control = drmTMB::drm_control(se = FALSE)
      )),
      expected_random_effect = "spatial_mu",
      expected_sd_pattern = "^spatial\\(",
      env = environment()
    ),
    list(
      gate_id = "nongaussian_struct_fit_beta_sigma_animal",
      cell_id = "qseries_beta_sigma_animal_rejected",
      formula_cell = "animal(1 | id, pedigree = ped) in sigma",
      family = "beta()",
      provider = "animal",
      expected_status = "expected_fit",
      expr = quote(drmTMB::drmTMB(
        drmTMB::bf(
          y ~ x,
          sigma ~ animal(1 | id, pedigree = ped_beta_sigma)
        ),
        family = drmTMB::beta(),
        data = dat_beta_sigma_animal,
        control = drmTMB::drm_control(se = FALSE)
      )),
      expected_random_effect = "animal_sigma",
      expected_sd_dpar = "sigma",
      expected_sd_pattern = "^animal\\(",
      env = environment()
    ),
    list(
      gate_id = "nongaussian_struct_fit_nbinom2_sigma_phylo_one_slope",
      cell_id = "qseries_phylo_nbinom2_q1_sigma_one_slope_rejected",
      formula_cell = "phylo(1 + x | id, tree = tree) in sigma",
      family = "nbinom2()",
      provider = "phylo",
      expected_status = "expected_fit",
      expr = quote(drmTMB::drmTMB(
        drmTMB::bf(y ~ x, sigma ~ phylo(1 + x | id, tree = tree_nb_sigma)),
        family = drmTMB::nbinom2(),
        data = dat_nb_sigma,
        control = drmTMB::drm_control(se = FALSE)
      )),
      expected_random_effect = "phylo_sigma",
      expected_sd_dpar = "sigma",
      expected_sd_pattern = "^phylo\\(",
      env = environment()
    ),
    list(
      gate_id = "nongaussian_struct_fit_nbinom2_sigma_spatial_one_slope",
      cell_id = "qseries_spatial_nbinom2_q1_sigma_one_slope_rejected",
      formula_cell = "spatial(1 + x | id, coords = coords) in sigma",
      family = "nbinom2()",
      provider = "spatial",
      expected_status = "expected_fit",
      expr = quote(drmTMB::drmTMB(
        drmTMB::bf(
          y ~ x,
          sigma ~ spatial(1 + x | id, coords = coords_nb_sigma)
        ),
        family = drmTMB::nbinom2(),
        data = dat_nb_sigma,
        control = drmTMB::drm_control(se = FALSE)
      )),
      expected_random_effect = "spatial_sigma",
      expected_sd_dpar = "sigma",
      expected_sd_pattern = "^spatial\\(",
      env = environment()
    ),
    list(
      gate_id = "nongaussian_struct_fit_nbinom2_sigma_animal_one_slope",
      cell_id = "qseries_animal_nbinom2_q1_sigma_one_slope_rejected",
      formula_cell = "animal(1 + x | id, Ainv = Q) in sigma",
      family = "nbinom2()",
      provider = "animal",
      expected_status = "expected_fit",
      expr = quote(drmTMB::drmTMB(
        drmTMB::bf(y ~ x, sigma ~ animal(1 + x | id, Ainv = Q_nb_sigma)),
        family = drmTMB::nbinom2(),
        data = dat_nb_sigma,
        control = drmTMB::drm_control(se = FALSE)
      )),
      expected_random_effect = "animal_sigma",
      expected_sd_dpar = "sigma",
      expected_sd_pattern = "^animal\\(",
      env = environment()
    ),
    list(
      gate_id = "nongaussian_struct_fit_nbinom2_sigma_relmat_one_slope",
      cell_id = "qseries_relmat_nbinom2_q1_sigma_one_slope_rejected",
      formula_cell = "relmat(1 + x | id, Q = Q) in sigma",
      family = "nbinom2()",
      provider = "relmat",
      expected_status = "expected_fit",
      expr = quote(drmTMB::drmTMB(
        drmTMB::bf(y ~ x, sigma ~ relmat(1 + x | id, Q = Q_nb_sigma)),
        family = drmTMB::nbinom2(),
        data = dat_nb_sigma,
        control = drmTMB::drm_control(se = FALSE)
      )),
      expected_random_effect = "relmat_sigma",
      expected_sd_dpar = "sigma",
      expected_sd_pattern = "^relmat\\(",
      env = environment()
    )
  )
}

qseries_v1_run_rejection_case <- function(case) {
  fit <- NULL
  err <- tryCatch(
    {
      fit <- eval(case$expr, envir = case$env)
      NULL
    },
    error = identity
  )
  expected <- "Structured non-Gaussian paths"
  expected_status <- case$expected_status
  expected_random_effect <- case$expected_random_effect
  if (is.null(expected_random_effect)) {
    expected_random_effect <- ""
  }
  expected_sd_pattern <- case$expected_sd_pattern
  if (is.null(expected_sd_pattern)) {
    expected_sd_pattern <- ""
  }
  expected_sd_dpar <- case$expected_sd_dpar
  if (is.null(expected_sd_dpar)) {
    expected_sd_dpar <- "mu"
  }
  sdpars <- if (!is.null(fit) && expected_sd_dpar %in% names(fit$sdpars)) {
    fit$sdpars[[expected_sd_dpar]]
  } else {
    numeric()
  }
  fit_ok <- !is.null(fit) &&
    inherits(fit, "drmTMB") &&
    is.finite(fit$opt$objective) &&
    identical(as.integer(fit$opt$convergence), 0L) &&
    nzchar(expected_random_effect) &&
    expected_random_effect %in% names(fit$random_effects) &&
    length(sdpars) > 0L &&
    nzchar(expected_sd_pattern) &&
    any(grepl(expected_sd_pattern, names(sdpars)))
  status <- if (is.null(err) && identical(expected_status, "expected_fit")) {
    if (fit_ok) "expected_fit" else "unexpected_fit_shape"
  } else if (is.null(err)) {
    "unexpected_success"
  } else if (grepl(expected, conditionMessage(err), fixed = TRUE)) {
    if (identical(expected_status, "expected_rejection")) {
      "expected_rejection"
    } else {
      "unexpected_rejection"
    }
  } else {
    "unexpected_error"
  }
  observed <- if (is.null(err)) {
    ""
  } else {
    gsub("[\r\n\t]+", " ", conditionMessage(err))
  }
  data.frame(
    gate_id = case$gate_id,
    cell_id = case$cell_id,
    formula_cell = case$formula_cell,
    family = case$family,
    provider = case$provider,
    expected_error_pattern = if (identical(expected_status, "expected_rejection")) {
      expected
    } else {
      ""
    },
    status = status,
    observed_error = observed,
    claim_boundary = paste(
      "local debug smoke only; beta/Gamma/Student structured mu rows,",
      "the beta structured sigma row, and NB2 structured sigma one-slope",
      "rows are fit-only recovery evidence;",
      "no denominator, coverage, inference_ready, supported, q4/q8,",
      "REML, AI-REML, bridge, or public-support claim"
    ),
    stringsAsFactors = FALSE
  )
}

qseries_v1_first_four_rejection_smoke <- function(root = ".") {
  load_drmTMB_for_smoke(root)
  rows <- lapply(
    qseries_v1_first_four_fixture(),
    qseries_v1_run_rejection_case
  )
  do.call(rbind, rows)
}

write_qseries_v1_rejection_smoke <- function(results, output = "") {
  con <- if (nzchar(output)) {
    file(output, open = "w", encoding = "UTF-8")
  } else {
    stdout()
  }
  on.exit({
    if (nzchar(output)) {
      close(con)
    }
  }, add = TRUE)
  utils::write.table(
    results,
    file = con,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = ""
  )
  invisible(results)
}

main <- function(args = commandArgs(trailingOnly = TRUE)) {
  output <- ""
  root <- "."
  i <- 1L
  while (i <= length(args)) {
    arg <- args[[i]]
    if (identical(arg, "--output")) {
      i <- i + 1L
      output <- args[[i]]
    } else if (identical(arg, "--root")) {
      i <- i + 1L
      root <- args[[i]]
    } else {
      stop("Unknown argument: ", arg, call. = FALSE)
    }
    i <- i + 1L
  }
  results <- qseries_v1_first_four_rejection_smoke(root = root)
  write_qseries_v1_rejection_smoke(results, output = output)
  if (!all(results$status %in% c("expected_fit", "expected_rejection"))) {
    quit(status = 1L, save = "no")
  }
  invisible(results)
}

if (identical(environment(), globalenv()) && !length(sys.calls())) {
  main()
}

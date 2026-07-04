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
      env = environment()
    ),
    list(
      gate_id = "nongaussian_struct_reject_gamma_mu_relmat",
      cell_id = "qseries_gamma_mu_relmat_rejected",
      formula_cell = "relmat(1 | id, K = K) in mu",
      family = "Gamma()",
      provider = "relmat",
      expected_status = "expected_rejection",
      expr = quote(drmTMB::drmTMB(
        drmTMB::bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1),
        family = stats::Gamma(link = "log"),
        data = dat_pos
      )),
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
      gate_id = "nongaussian_struct_reject_student_mu_spatial",
      cell_id = "qseries_student_mu_spatial_rejected",
      formula_cell = "spatial(1 | id, coords = coords) in mu",
      family = "student()",
      provider = "spatial",
      expected_status = "expected_rejection",
      expr = quote(drmTMB::drmTMB(
        drmTMB::bf(y ~ x + spatial(1 | id, coords = coords), sigma ~ 1),
        family = drmTMB::student(),
        data = dat_pos
      )),
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
  fit_ok <- !is.null(fit) &&
    inherits(fit, "drmTMB") &&
    is.finite(fit$opt$objective) &&
    identical(as.integer(fit$opt$convergence), 0L) &&
    "animal_mu" %in% names(fit$random_effects) &&
    length(fit$sdpars$mu) > 0L &&
    any(grepl("^animal\\(", names(fit$sdpars$mu)))
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
      "local debug smoke only; beta animal is fit-only recovery evidence;",
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

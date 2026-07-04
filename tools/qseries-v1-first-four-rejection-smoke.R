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
      rejection_id = "nongaussian_struct_reject_beta_mu_animal",
      cell_id = "qseries_beta_mu_animal_rejected",
      formula_cell = "animal(1 | id, pedigree = ped) in mu",
      family = "beta()",
      provider = "animal",
      expr = quote(drmTMB::drmTMB(
        drmTMB::bf(y ~ x + animal(1 | id, pedigree = ped), sigma ~ 1),
        family = drmTMB::beta(),
        data = dat_beta
      )),
      env = environment()
    ),
    list(
      rejection_id = "nongaussian_struct_reject_gamma_mu_relmat",
      cell_id = "qseries_gamma_mu_relmat_rejected",
      formula_cell = "relmat(1 | id, K = K) in mu",
      family = "Gamma()",
      provider = "relmat",
      expr = quote(drmTMB::drmTMB(
        drmTMB::bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1),
        family = stats::Gamma(link = "log"),
        data = dat_pos
      )),
      env = environment()
    ),
    list(
      rejection_id = "nongaussian_struct_reject_ordinal_mu_phylo",
      cell_id = "qseries_ordinal_mu_phylo_rejected",
      formula_cell = "phylo(1 | id, tree = tree) in mu",
      family = "cumulative_logit()",
      provider = "phylo",
      expr = quote(drmTMB::drmTMB(
        drmTMB::bf(y ~ x + phylo(1 | id, tree = tree)),
        family = drmTMB::cumulative_logit(),
        data = dat_ord
      )),
      env = environment()
    ),
    list(
      rejection_id = "nongaussian_struct_reject_student_mu_spatial",
      cell_id = "qseries_student_mu_spatial_rejected",
      formula_cell = "spatial(1 | id, coords = coords) in mu",
      family = "student()",
      provider = "spatial",
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
  err <- tryCatch(
    {
      eval(case$expr, envir = case$env)
      NULL
    },
    error = identity
  )
  expected <- "Structured non-Gaussian paths"
  status <- if (is.null(err)) {
    "unexpected_success"
  } else if (grepl(expected, conditionMessage(err), fixed = TRUE)) {
    "expected_rejection"
  } else {
    "unexpected_error"
  }
  observed <- if (is.null(err)) {
    ""
  } else {
    gsub("[\r\n\t]+", " ", conditionMessage(err))
  }
  data.frame(
    rejection_id = case$rejection_id,
    cell_id = case$cell_id,
    formula_cell = case$formula_cell,
    family = case$family,
    provider = case$provider,
    expected_error_pattern = expected,
    status = status,
    observed_error = observed,
    claim_boundary = paste(
      "local rejection smoke only; no fit, denominator, coverage,",
      "inference_ready, supported, q4/q8, REML, AI-REML, bridge, or public-support claim"
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
  if (!all(results$status == "expected_rejection")) {
    quit(status = 1L, save = "no")
  }
  invisible(results)
}

if (identical(environment(), globalenv()) && !length(sys.calls())) {
  main()
}

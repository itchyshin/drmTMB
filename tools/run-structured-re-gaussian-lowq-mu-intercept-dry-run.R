#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/run-structured-re-gaussian-lowq-mu-intercept-dry-run.R [options]",
      "",
      "Options:",
      "  --n-rep=N                 Number of replicate seeds per provider (default: 2).",
      "  --run-kind=dry_run|smoke|pregrid|topup",
      "                            Evidence mode. Top-up mode shards additional retained-denominator replicates after the reviewed SR150 pregrid (default: dry_run).",
      "  --seed-start=N            First replicate index (default: 1).",
      "  --seed-base=N             Seed base; seed = seed_base + replicate_index (default: 812000).",
      "  --providers=a,b,c         Providers to run (default: phylo,spatial,animal,relmat).",
      "  --host-class=CLASS        Host class label for smoke artifacts (default: local_rehearsal).",
      "  --host-name=NAME          Host name label for smoke artifacts (default: Sys.info()[['nodename']]).",
      "  --output-dir=PATH         Artifact directory.",
      "  --overwrite=true          Replace an existing artifact directory.",
      "  --write-dashboard=false   Do not overwrite the dashboard summary sidecar.",
      "",
      sep = "\n"
    )
  )
  quit(status = 0)
}

arg_value <- function(name, default = NULL) {
  prefix <- paste0("--", name, "=")
  hit <- grep(paste0("^", prefix), args, value = TRUE)
  if (length(hit) == 0L) {
    return(default)
  }
  sub(prefix, "", hit[[length(hit)]], fixed = TRUE)
}

arg_flag <- function(name, default = FALSE) {
  value <- arg_value(name, NULL)
  if (is.null(value)) {
    return(default)
  }
  tolower(value) %in% c("1", "true", "yes", "y")
}

script_file <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1L] %||% "tools"
)
repo_root <- normalizePath(file.path(dirname(script_file), ".."))
if (!file.exists(file.path(repo_root, "DESCRIPTION"))) {
  repo_root <- normalizePath(getwd())
}

n_rep <- as.integer(arg_value("n-rep", "2"))
if (!is.finite(n_rep) || n_rep < 1L) {
  stop("`--n-rep` must be a positive integer.", call. = FALSE)
}
seed_start <- as.integer(arg_value("seed-start", "1"))
if (!is.finite(seed_start) || seed_start < 1L) {
  stop("`--seed-start` must be a positive integer.", call. = FALSE)
}
seed_base <- as.integer(arg_value("seed-base", "812000"))
if (!is.finite(seed_base) || seed_base < 1L) {
  stop("`--seed-base` must be a positive integer.", call. = FALSE)
}
overwrite <- arg_flag("overwrite", FALSE)
write_dashboard <- arg_flag("write-dashboard", TRUE)
run_kind <- gsub("-", "_", arg_value("run-kind", "dry_run"), fixed = TRUE)
if (!run_kind %in% c("dry_run", "smoke", "pregrid", "topup")) {
  stop("`--run-kind` must be `dry_run`, `smoke`, `pregrid`, or `topup`.", call. = FALSE)
}
if (identical(run_kind, "smoke") && n_rep != 5L) {
  stop(
    "Smoke mode is the reviewed n=5 fixture smoke. Use --n-rep=5.",
    call. = FALSE
  )
}
if (identical(run_kind, "pregrid") && n_rep != 150L) {
  stop(
    "Pregrid mode is the reviewed SR150 retained-denominator design. Use --n-rep=150.",
    call. = FALSE
  )
}
if (identical(run_kind, "smoke") && write_dashboard) {
  stop(
    "Smoke mode is artifact-only. Use --write-dashboard=false, then import ",
    "reviewed artifacts through a validator-owned sidecar.",
    call. = FALSE
  )
}
if (identical(run_kind, "pregrid") && write_dashboard) {
  stop(
    "Pregrid mode is artifact-only. Use --write-dashboard=false, then import ",
    "reviewed artifacts through a validator-owned sidecar.",
    call. = FALSE
  )
}
if (identical(run_kind, "topup") && write_dashboard) {
  stop(
    "Top-up mode is artifact-only. Use --write-dashboard=false, then aggregate ",
    "and import reviewed artifacts through a validator-owned sidecar.",
    call. = FALSE
  )
}
host_name <- arg_value("host-name", unname(Sys.info()[["nodename"]]))
host_class <- arg_value("host-class", "local_rehearsal")
run_label <- switch(
  run_kind,
  smoke = "smoke-results",
  pregrid = "pregrid-results",
  topup = "topup-results",
  dry_run = "dry-run"
)
run_id_prefix <- switch(
  run_kind,
  smoke = "gaussian_lowq_mu_intercept_smoke",
  pregrid = "gaussian_lowq_mu_intercept_pregrid",
  topup = "gaussian_lowq_mu_intercept_topup",
  dry_run = "gaussian_lowq_mu_intercept_dry_run"
)
run_id_field <- switch(
  run_kind,
  smoke = "smoke_id",
  pregrid = "pregrid_id",
  topup = "topup_id",
  dry_run = "dry_run_id"
)

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
default_artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  paste0("2026-06-29-gaussian-lowq-mu-intercept-", run_label, "-local")
)
artifact_dir <- normalizePath(
  arg_value("output-dir", default_artifact_dir),
  mustWork = FALSE
)
if (dir.exists(artifact_dir) && !overwrite) {
  stop(
    "`output-dir` already exists. Use --overwrite=true to replace it: ",
    artifact_dir,
    call. = FALSE
  )
}
if (dir.exists(artifact_dir) && overwrite) {
  unlink(artifact_dir, recursive = TRUE)
}
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

row_selection_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-lowq-row-selection.tsv"
)
smoke_contract_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-lowq-mu-intercept-smoke-contract.tsv"
)
smoke_substitution_contract_path <- file.path(
  dashboard_dir,
  "structured-re-q-series-smoke-substitution-contract.tsv"
)
denominator_contract_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-lowq-mu-intercept-retained-denominator-contract.tsv"
)
dashboard_summary_path <- file.path(
  dashboard_dir,
  paste0("structured-re-gaussian-lowq-mu-intercept-", run_label, ".tsv")
)
replicate_path <- file.path(
  artifact_dir,
  paste0(
    "structured-re-gaussian-lowq-mu-intercept-",
    run_label,
    "-replicates.tsv"
  )
)
summary_path <- file.path(
  artifact_dir,
  paste0("structured-re-gaussian-lowq-mu-intercept-", run_label, ".tsv")
)
seed_manifest_path <- file.path(
  artifact_dir,
  paste0(
    "structured-re-gaussian-lowq-mu-intercept-",
    run_label,
    "-seed-manifest.tsv"
  )
)
session_info_path <- file.path(artifact_dir, "sessionInfo.txt")
git_sha_path <- file.path(artifact_dir, "git-sha.txt")

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

write_tsv <- function(x, path) {
  character_cols <- vapply(x, is.character, logical(1L))
  x[character_cols] <- lapply(x[character_cols], clean_text)
  utils::write.table(
    x,
    path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA"
  )
}

read_tsv <- function(path) {
  utils::read.delim(
    path,
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

rel_path <- function(path) {
  sub(paste0("^", gsub("([\\W])", "\\\\\\1", repo_root), "/?"), "", path)
}

mcse_proportion <- function(x) {
  if (!is.logical(x) || length(x) == 0L || anyNA(x)) {
    return(NA_real_)
  }
  p <- mean(x)
  sqrt(p * (1 - p) / length(x))
}

fmt4 <- function(x) {
  ifelse(is.na(x), "NA", sprintf("%.4f", x))
}
fmt6 <- function(x) {
  ifelse(is.na(x), "NA", sprintf("%.6f", x))
}

assert_positive_integer <- function(x, name) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < 1L) {
    stop("`", name, "` must be one positive integer.", call. = FALSE)
  }
  invisible(TRUE)
}

load_drmTMB_for_lowq <- function(path) {
  if (requireNamespace("devtools", quietly = TRUE)) {
    suppressPackageStartupMessages(devtools::load_all(path, quiet = TRUE))
    return(invisible("devtools_load_all"))
  }
  if (requireNamespace("drmTMB", quietly = TRUE)) {
    suppressPackageStartupMessages(library(drmTMB))
    return(invisible("library_drmTMB"))
  }
  stop(
    "Cannot load drmTMB: install the synced source with R CMD INSTALL or ",
    "provide devtools in R_LIBS.",
    call. = FALSE
  )
}

source_local <- function(path) {
  source(file.path(repo_root, path), local = .GlobalEnv)
}

load_drmTMB_for_lowq(repo_root)
source_local("inst/sim/R/sim_registry.R")
source_local("inst/sim/R/sim_utils.R")
source_local("inst/sim/dgp/sim_dgp_phylo_mu_slope.R")
source_local("inst/sim/dgp/sim_dgp_animal_mu_slope.R")

row_selection <- read_tsv(row_selection_path)
allowed_row_selection_status <- c(
  "ready_for_local_dry_run",
  "local_smoke_completed_review_pending",
  "nibi_rorqual_substitution_smoke_ready",
  "nibi_rorqual_substitution_smoke_reviewed"
)
smoke_rows <- row_selection[
  row_selection$row_selection_class ==
    "first_smoke_candidate_location_intercept" &
    row_selection$selection_status %in% allowed_row_selection_status,
  ,
  drop = FALSE
]
expected_cells <- c(
  "qseries_phylo_q1_mu_intercept",
  "qseries_spatial_q1_mu_intercept",
  "qseries_animal_q1_mu_intercept",
  "qseries_relmat_q1_mu_intercept"
)
if (!setequal(smoke_rows$cell_id, expected_cells) || nrow(smoke_rows) != 4L) {
  stop(
    "Row-selection sidecar must expose exactly the four q1 mu intercept dry-run/smoke rows.",
    call. = FALSE
  )
}

provider_arg <- arg_value("providers", "phylo,spatial,animal,relmat")
selected_providers <- trimws(strsplit(provider_arg, ",", fixed = TRUE)[[1L]])
selected_providers <- selected_providers[nzchar(selected_providers)]
unknown_providers <- setdiff(
  selected_providers,
  c("phylo", "spatial", "animal", "relmat")
)
if (length(selected_providers) == 0L || length(unknown_providers) > 0L) {
  stop(
    "`--providers` must be a comma-separated subset of: phylo, spatial, animal, relmat.",
    call. = FALSE
  )
}
smoke_rows <- smoke_rows[
  match(selected_providers, smoke_rows$structure_provider),
  ,
  drop = FALSE
]
if (anyNA(smoke_rows$cell_id)) {
  stop(
    "Selected provider is missing from the row-selection sidecar.",
    call. = FALSE
  )
}

smoke_contract_by_provider <- NULL
denominator_contract_by_provider <- NULL
substitution_contract_row <- NULL
if (identical(run_kind, "smoke")) {
  smoke_contract <- read_tsv(smoke_contract_path)
  required_contract_fields <- c(
    "contract_id",
    "cell_id",
    "provider",
    "contract_status",
    "smoke_n_rep",
    "allowed_hosts",
    "blocked_hosts",
    "promotion_decision"
  )
  missing_contract_fields <- setdiff(
    required_contract_fields,
    names(smoke_contract)
  )
  if (length(missing_contract_fields) > 0L) {
    stop(
      "Smoke contract sidecar is missing fields: ",
      paste(missing_contract_fields, collapse = ", "),
      call. = FALSE
    )
  }
  smoke_contract <- smoke_contract[
    match(selected_providers, smoke_contract$provider),
    ,
    drop = FALSE
  ]
  if (anyNA(smoke_contract$provider)) {
    stop(
      "Smoke contract sidecar does not cover all selected providers.",
      call. = FALSE
    )
  }
  if (!identical(smoke_contract$cell_id, smoke_rows$cell_id)) {
    stop(
      "Smoke contract rows must match the selected q1 mu intercept cells.",
      call. = FALSE
    )
  }
  if (!all(smoke_contract$contract_status == "totoro_fiia_smoke_ready")) {
    stop(
      "Smoke contract rows must be `totoro_fiia_smoke_ready`.",
      call. = FALSE
    )
  }
  if (!all(smoke_contract$smoke_n_rep == 5L)) {
    stop("Smoke contract rows must require `smoke_n_rep = 5`.", call. = FALSE)
  }
  if (!all(smoke_contract$allowed_hosts == "Totoro;FIIA")) {
    stop(
      "Smoke contract rows must keep `allowed_hosts = Totoro;FIIA`.",
      call. = FALSE
    )
  }
  if (!all(smoke_contract$blocked_hosts == "Nibi;Rorqual;DRAC")) {
    stop(
      "Smoke contract rows must keep `blocked_hosts = Nibi;Rorqual;DRAC`.",
      call. = FALSE
    )
  }
  if (!all(smoke_contract$promotion_decision == "do_not_promote")) {
    stop(
      "Smoke contract rows must keep `promotion_decision = do_not_promote`.",
      call. = FALSE
    )
  }

  host_gate_text <- tolower(paste(host_class, host_name, collapse = " "))
  is_substitute_host <- grepl("nibi|rorqual", host_gate_text)
  is_blocked_cluster_host <- grepl(
    "drac|cluster|slurm",
    host_gate_text
  ) &&
    !is_substitute_host
  if (is_blocked_cluster_host) {
    stop(
      "Cluster smoke is blocked unless the host is Nibi/Rorqual and the ",
      "smoke-substitution contract applies.",
      call. = FALSE
    )
  }
  if (is_substitute_host) {
    if (
      !setequal(
        selected_providers,
        c("phylo", "spatial", "animal", "relmat")
      ) ||
        length(selected_providers) != 4L
    ) {
      stop(
        "Nibi/Rorqual substitute smoke must run the exact four q1 mu intercept targets.",
        call. = FALSE
      )
    }

    substitution_contract <- read_tsv(smoke_substitution_contract_path)
    required_substitution_fields <- c(
      "contract_id",
      "target_cells",
      "allowed_hosts",
      "allowed_run_mode",
      "required_reviewers",
      "denominator_policy",
      "blocked_uses",
      "promotion_decision"
    )
    missing_substitution_fields <- setdiff(
      required_substitution_fields,
      names(substitution_contract)
    )
    if (length(missing_substitution_fields) > 0L) {
      stop(
        "Smoke-substitution contract is missing fields: ",
        paste(missing_substitution_fields, collapse = ", "),
        call. = FALSE
      )
    }
    substitution_contract_row <- substitution_contract[
      substitution_contract$contract_id ==
        "qseries_smoke_substitution_q1_mu_intercept",
      ,
      drop = FALSE
    ]
    if (nrow(substitution_contract_row) != 1L) {
      stop(
        "Smoke-substitution contract must expose qseries_smoke_substitution_q1_mu_intercept.",
        call. = FALSE
      )
    }
    substitution_targets <- strsplit(
      substitution_contract_row$target_cells[[1L]],
      ";",
      fixed = TRUE
    )[[1L]]
    if (!setequal(substitution_targets, smoke_rows$cell_id)) {
      stop(
        "Smoke-substitution contract targets must match the selected q1 mu intercept cells.",
        call. = FALSE
      )
    }
    for (phrase in c(
      "Nibi or Rorqual only",
      "contract_bounded_n5_smoke_only"
    )) {
      fields <- paste(
        substitution_contract_row$allowed_hosts,
        substitution_contract_row$allowed_run_mode
      )
      if (!grepl(phrase, fields, fixed = TRUE)) {
        stop(
          "Smoke-substitution contract must mention: ",
          phrase,
          call. = FALSE
        )
      }
    }
    for (phrase in c("Fisher", "Rose", "Grace")) {
      if (
        !grepl(
          phrase,
          substitution_contract_row$required_reviewers,
          fixed = TRUE
        )
      ) {
        stop(
          "Smoke-substitution contract reviewers must include ",
          phrase,
          ".",
          call. = FALSE
        )
      }
    }
    for (phrase in c(
      "All attempted rows retained",
      "n=5 is smoke evidence, not coverage evidence",
      "DRAC denominator grids",
      "supported or inference_ready claims"
    )) {
      fields <- paste(
        substitution_contract_row$denominator_policy,
        substitution_contract_row$blocked_uses
      )
      if (!grepl(phrase, fields, fixed = TRUE)) {
        stop(
          "Smoke-substitution contract must keep the boundary phrase: ",
          phrase,
          call. = FALSE
        )
      }
    }
    if (
      !identical(
        substitution_contract_row$promotion_decision,
        "do_not_promote"
      )
    ) {
      stop(
        "Smoke-substitution contract must keep promotion_decision = do_not_promote.",
        call. = FALSE
      )
    }
  }
  smoke_contract_by_provider <- split(smoke_contract, smoke_contract$provider)
}

if (run_kind %in% c("pregrid", "topup")) {
  pregrid_exact_provider_set <- setequal(
    selected_providers,
    c("phylo", "spatial", "animal", "relmat")
  ) &&
    length(selected_providers) == 4L
  if (identical(run_kind, "pregrid") && !pregrid_exact_provider_set) {
    stop(
      "SR150 pregrid mode must run the exact four q1 mu intercept targets.",
      call. = FALSE
    )
  }
  host_gate_text <- tolower(paste(host_class, host_name, collapse = " "))
  if (!grepl("nibi|rorqual", host_gate_text)) {
    stop(
      "SR150 pregrid/top-up mode is allowed only on Nibi/Rorqual under the ",
      "reviewed retained-denominator contract.",
      call. = FALSE
    )
  }

  denominator_contract <- read_tsv(denominator_contract_path)
  required_denominator_fields <- c(
    "contract_id",
    "cell_id",
    "provider",
    "target_kind",
    "endpoint_member",
    "estimand",
    "profile_target",
    "denominator_policy",
    "pregrid_n_rep",
    "mcse_threshold",
    "one_sided_miss_policy",
    "allowed_hosts",
    "blocked_hosts",
    "contract_status",
    "promotion_decision",
    "claim_boundary",
    "next_gate"
  )
  missing_denominator_fields <- setdiff(
    required_denominator_fields,
    names(denominator_contract)
  )
  if (length(missing_denominator_fields) > 0L) {
    stop(
      "Retained-denominator contract sidecar is missing fields: ",
      paste(missing_denominator_fields, collapse = ", "),
      call. = FALSE
    )
  }
  denominator_contract <- denominator_contract[
    match(selected_providers, denominator_contract$provider),
    ,
    drop = FALSE
  ]
  if (anyNA(denominator_contract$provider)) {
    stop(
      "Retained-denominator contract sidecar does not cover all selected providers.",
      call. = FALSE
    )
  }
  if (!identical(denominator_contract$cell_id, smoke_rows$cell_id)) {
    stop(
      "Retained-denominator contract rows must match the selected q1 mu intercept cells.",
      call. = FALSE
    )
  }
  if (!all(
    denominator_contract$contract_status ==
      "fisher_rose_grace_reviewed_sr150_pregrid_ready"
  )) {
    stop(
      "Retained-denominator contract rows must be reviewed and SR150 pregrid ready.",
      call. = FALSE
    )
  }
  if (!all(denominator_contract$pregrid_n_rep == 150L)) {
    stop(
      "Retained-denominator contract rows must require `pregrid_n_rep = 150`.",
      call. = FALSE
    )
  }
  if (!all(denominator_contract$promotion_decision == "do_not_promote")) {
    stop(
      "Retained-denominator contract rows must keep promotion_decision = do_not_promote.",
      call. = FALSE
    )
  }
  for (phrase in c(
    "all_attempted_replicates_retained",
    "finite_denominator_reported",
    "Fisher/Rose/Grace accepted this contract",
    "MCSE <= 0.01 is a top-up target",
    "not an SR150 pass claim",
    "no status promotion"
  )) {
    fields <- paste(
      denominator_contract$denominator_policy,
      denominator_contract$next_gate
    )
    if (!all(grepl(phrase, fields, fixed = TRUE))) {
      stop(
        "Retained-denominator contract must keep the boundary phrase: ",
        phrase,
        call. = FALSE
      )
    }
  }
  denominator_contract_by_provider <- split(
    denominator_contract,
    denominator_contract$provider
  )
}

provider_defaults <- list(
  phylo = list(
    n_group = 8L,
    n_each = 7L,
    beta_mu_intercept = 0.40,
    sigma = 0.22,
    sd_intercept = 0.55,
    group_var = "species",
    term = "phylo(1 | species)"
  ),
  spatial = list(
    n_group = 12L,
    n_each = 8L,
    beta_mu_intercept = 0.60,
    sigma = 0.16,
    sd_intercept = 0.45,
    group_var = "site",
    term = "spatial(1 | site)"
  ),
  animal = list(
    n_group = 8L,
    n_each = 7L,
    beta_mu_intercept = 0.25,
    sigma = 0.22,
    sd_intercept = 0.55,
    group_var = "id",
    term = "animal(1 | id)"
  ),
  relmat = list(
    n_group = 8L,
    n_each = 7L,
    beta_mu_intercept = 0.25,
    sigma = 0.22,
    sd_intercept = 0.55,
    group_var = "id",
    term = "relmat(1 | id)",
    matrix_decay = 0.35,
    matrix_nugget = 0.15
  )
)

make_phylo_intercept <- function(spec, seed, cell_id, replicate_index) {
  assert_positive_integer(spec$n_group, "n_group")
  assert_positive_integer(spec$n_each, "n_each")
  draw <- function() {
    tree <- phase18_phylo_mu_slope_tree(spec$n_group)
    A <- drmTMB:::drm_phylo_tip_covariance(tree)

    phylo_intercept <- as.vector(
      t(chol(A)) %*% stats::rnorm(spec$n_group, sd = spec$sd_intercept)
    )
    names(phylo_intercept) <- tree$tip.label

    species <- rep(tree$tip.label, each = spec$n_each)
    mu <- unname(spec$beta_mu_intercept + phylo_intercept[species])
    y <- stats::rnorm(length(species), mean = mu, sd = spec$sigma)

    dat <- data.frame(
      y = y,
      species = species,
      mu = mu,
      sigma = spec$sigma,
      cell_id = cell_id,
      replicate = replicate_index,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "phylo_mu_intercept",
      beta_mu = c("(Intercept)" = spec$beta_mu_intercept),
      sigma = spec$sigma,
      sd = stats::setNames(spec$sd_intercept, spec$term),
      phylo_intercept = phylo_intercept,
      tree = tree,
      A = A,
      n_tip = spec$n_group,
      n_each = spec$n_each
    )
    dat
  }
  phase18_with_seed(seed, draw)
}

make_spatial_intercept <- function(spec, seed, cell_id, replicate_index) {
  assert_positive_integer(spec$n_group, "n_group")
  assert_positive_integer(spec$n_each, "n_each")
  draw <- function() {
    site_levels <- paste0("site_", seq_len(spec$n_group))
    theta <- seq(0, 1.5 * pi, length.out = spec$n_group)
    coords <- data.frame(
      coord_x = cos(theta) + seq_len(spec$n_group) / (3 * spec$n_group),
      coord_y = sin(theta)
    )
    row.names(coords) <- site_levels
    precision <- drmTMB:::drm_spatial_coords_precision(
      coords,
      site = site_levels,
      group = "site"
    )
    covariance <- solve(as.matrix(precision$precision))
    effect <- as.vector(
      t(chol(covariance)) %*% stats::rnorm(spec$n_group, sd = spec$sd_intercept)
    )
    names(effect) <- site_levels
    site <- rep(site_levels, each = spec$n_each)
    mu <- spec$beta_mu_intercept + effect[site]
    y <- stats::rnorm(length(site), mean = mu, sd = spec$sigma)
    dat <- data.frame(
      y = y,
      site = site,
      mu = unname(mu),
      sigma = spec$sigma,
      cell_id = cell_id,
      replicate = replicate_index,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "spatial_mu_intercept",
      beta_mu = c("(Intercept)" = spec$beta_mu_intercept),
      sigma = spec$sigma,
      sd = stats::setNames(spec$sd_intercept, spec$term),
      coords = coords,
      n_group = spec$n_group,
      n_each = spec$n_each
    )
    dat
  }
  phase18_with_seed(seed, draw)
}

make_animal_intercept <- function(spec, seed, cell_id, replicate_index) {
  assert_positive_integer(spec$n_group, "n_group")
  assert_positive_integer(spec$n_each, "n_each")
  draw <- function() {
    id_levels <- paste0("id_", seq_len(spec$n_group))
    pedigree <- phase18_animal_mu_slope_pedigree(id_levels)
    A <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
    Ainv <- solve(A)

    animal_intercept <- as.vector(
      t(chol(A)) %*% stats::rnorm(spec$n_group, sd = spec$sd_intercept)
    )
    names(animal_intercept) <- id_levels

    id <- rep(id_levels, each = spec$n_each)
    mu <- unname(spec$beta_mu_intercept + animal_intercept[id])
    y <- stats::rnorm(length(id), mean = mu, sd = spec$sigma)

    dat <- data.frame(
      y = y,
      id = id,
      mu = mu,
      sigma = spec$sigma,
      cell_id = cell_id,
      replicate = replicate_index,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "animal_mu_intercept",
      beta_mu = c("(Intercept)" = spec$beta_mu_intercept),
      sigma = spec$sigma,
      sd = stats::setNames(spec$sd_intercept, spec$term),
      animal_intercept = animal_intercept,
      pedigree = pedigree,
      A = A,
      Ainv = Ainv,
      n_id = spec$n_group,
      n_each = spec$n_each
    )
    dat
  }
  phase18_with_seed(seed, draw)
}

make_relmat_intercept <- function(spec, seed, cell_id, replicate_index) {
  assert_positive_integer(spec$n_group, "n_group")
  assert_positive_integer(spec$n_each, "n_each")
  draw <- function() {
    id_levels <- paste0("id_", seq_len(spec$n_group))
    K <- outer(
      seq_len(spec$n_group),
      seq_len(spec$n_group),
      function(i, j) spec$matrix_decay^abs(i - j)
    )
    diag(K) <- diag(K) + spec$matrix_nugget
    dimnames(K) <- list(id_levels, id_levels)
    Q <- solve(K)
    effect <- as.vector(
      t(chol(K)) %*% stats::rnorm(spec$n_group, sd = spec$sd_intercept)
    )
    names(effect) <- id_levels
    id <- rep(id_levels, each = spec$n_each)
    mu <- spec$beta_mu_intercept + effect[id]
    y <- stats::rnorm(length(id), mean = mu, sd = spec$sigma)
    dat <- data.frame(
      y = y,
      id = id,
      mu = unname(mu),
      sigma = spec$sigma,
      cell_id = cell_id,
      replicate = replicate_index,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "relmat_mu_intercept",
      beta_mu = c("(Intercept)" = spec$beta_mu_intercept),
      sigma = spec$sigma,
      sd = stats::setNames(spec$sd_intercept, spec$term),
      K = K,
      Q = Q,
      n_group = spec$n_group,
      n_each = spec$n_each
    )
    dat
  }
  phase18_with_seed(seed, draw)
}

make_data <- function(provider, spec, seed, cell_id, replicate_index) {
  switch(
    provider,
    phylo = make_phylo_intercept(spec, seed, cell_id, replicate_index),
    spatial = make_spatial_intercept(spec, seed, cell_id, replicate_index),
    animal = make_animal_intercept(spec, seed, cell_id, replicate_index),
    relmat = make_relmat_intercept(spec, seed, cell_id, replicate_index),
    stop("Unknown provider: ", provider, call. = FALSE)
  )
}

fit_intercept <- function(provider, dat) {
  truth <- attr(dat, "truth", exact = TRUE)
  switch(
    provider,
    phylo = {
      tree <- truth$tree
      drmTMB(
        bf(y ~ phylo(1 | species, tree = tree), sigma ~ 1),
        family = gaussian(),
        data = dat
      )
    },
    spatial = {
      coords <- truth$coords
      drmTMB(
        bf(y ~ spatial(1 | site, coords = coords), sigma ~ 1),
        family = gaussian(),
        data = dat
      )
    },
    animal = {
      A <- truth$A
      drmTMB(
        bf(y ~ animal(1 | id, A = A), sigma ~ 1),
        family = gaussian(),
        data = dat
      )
    },
    relmat = {
      K <- truth$K
      drmTMB(
        bf(y ~ relmat(1 | id, K = K), sigma ~ 1),
        family = gaussian(),
        data = dat
      )
    },
    stop("Unknown provider: ", provider, call. = FALSE)
  )
}

find_interval_row <- function(ci, term) {
  parm <- paste0("sd:mu:", term)
  hit <- ci$parm == parm
  if (!any(hit)) {
    hit <- grepl(parm, ci$parm, fixed = TRUE)
  }
  if (!any(hit)) {
    return(NULL)
  }
  ci[which(hit)[[1L]], , drop = FALSE]
}

run_one <- function(selection_row, replicate_index, seed) {
  provider <- selection_row$structure_provider[[1L]]
  spec <- provider_defaults[[provider]]
  warnings <- character()
  fit_error <- NA_character_
  confint_error <- NA_character_
  started <- proc.time()[["elapsed"]]
  dat <- tryCatch(
    withCallingHandlers(
      make_data(
        provider,
        spec,
        seed = seed,
        cell_id = selection_row$cell_id[[1L]],
        replicate_index = replicate_index
      ),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) e
  )
  fit <- NULL
  ci <- NULL
  if (inherits(dat, "error")) {
    fit_error <- conditionMessage(dat)
  } else {
    fit <- tryCatch(
      withCallingHandlers(
        fit_intercept(provider, dat),
        warning = function(w) {
          warnings <<- c(warnings, conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      ),
      error = function(e) e
    )
    if (inherits(fit, "error")) {
      fit_error <- conditionMessage(fit)
      fit <- NULL
    }
  }
  if (!is.null(fit)) {
    ci <- tryCatch(
      withCallingHandlers(
        confint(fit),
        warning = function(w) {
          warnings <<- c(warnings, conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      ),
      error = function(e) e
    )
    if (inherits(ci, "error")) {
      confint_error <- conditionMessage(ci)
      ci <- NULL
    }
  }

  elapsed <- proc.time()[["elapsed"]] - started
  fit_ok <- !is.null(fit)
  converged <- fit_ok && isTRUE(fit$opt$convergence == 0)
  pdhess <- fit_ok && isTRUE(fit$sdr$pdHess)
  confint_ok <- !is.null(ci)
  truth <- if (inherits(dat, "data.frame")) {
    attr(dat, "truth", exact = TRUE)
  } else {
    NULL
  }
  interval_row <- if (!is.null(ci)) {
    find_interval_row(ci, spec$term)
  } else {
    NULL
  }
  conf_status <- if (is.null(interval_row)) {
    if (!fit_ok) {
      "fit_failed"
    } else if (!pdhess) {
      "not_run_pdhess_false"
    } else if (!confint_ok) {
      "confint_failed"
    } else {
      "interval_target_missing"
    }
  } else {
    interval_row$conf.status[[1L]]
  }
  lower <- if (is.null(interval_row)) NA_real_ else interval_row$lower[[1L]]
  upper <- if (is.null(interval_row)) NA_real_ else interval_row$upper[[1L]]
  estimate <- if (
    fit_ok &&
      !is.null(fit$sdpars$mu) &&
      spec$term %in% names(fit$sdpars$mu)
  ) {
    unname(fit$sdpars$mu[[spec$term]])
  } else {
    NA_real_
  }
  truth_value <- if (!is.null(truth)) {
    unname(truth$sd[[spec$term]])
  } else {
    NA_real_
  }
  usable_interval <- identical(conf_status, "wald") &&
    is.finite(lower) &&
    is.finite(upper)
  covered <- usable_interval && lower <= truth_value && truth_value <= upper

  out <- data.frame(
    run_id = paste0(
      run_id_prefix,
      "_",
      provider,
      "_rep",
      replicate_index
    ),
    cell_id = selection_row$cell_id[[1L]],
    provider = provider,
    formula_cell = selection_row$formula_cell[[1L]],
    replicate_index = replicate_index,
    seed = seed,
    n_group = spec$n_group,
    n_each = spec$n_each,
    beta_mu_intercept = spec$beta_mu_intercept,
    sigma = spec$sigma,
    truth_sd_mu_intercept = truth_value,
    target_parameter = paste0("sd:mu:", spec$term),
    fit_ok = fit_ok,
    converged = converged,
    pdHess = pdhess,
    confint_ok = confint_ok,
    conf_status = conf_status,
    usable_interval = usable_interval,
    estimate = estimate,
    conf.low = lower,
    conf.high = upper,
    covered = covered,
    lower_miss = usable_interval && truth_value < lower,
    upper_miss = usable_interval && truth_value > upper,
    nobs = if (fit_ok) stats::nobs(fit) else NA_integer_,
    elapsed = elapsed,
    warning_count = length(unique(warnings)),
    warnings = paste(unique(warnings), collapse = " | "),
    fit_error = fit_error,
    confint_error = confint_error,
    stringsAsFactors = FALSE
  )
  names(out)[[1L]] <- run_id_field
  if (identical(run_kind, "smoke")) {
    contract_row <- smoke_contract_by_provider[[provider]]
    out$source_contract_id <- contract_row$contract_id[[1L]]
    out$source_contract <- rel_path(smoke_contract_path)
    out$host_class <- host_class
    out$host_name <- host_name
  } else if (run_kind %in% c("pregrid", "topup")) {
    contract_row <- denominator_contract_by_provider[[provider]]
    out$source_contract_id <- contract_row$contract_id[[1L]]
    out$source_contract <- rel_path(denominator_contract_path)
    out$host_class <- host_class
    out$host_name <- host_name
  }
  out
}

seed_manifest <- expand.grid(
  provider = selected_providers,
  replicate_index = seq(from = seed_start, length.out = n_rep),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
seed_manifest$seed <- seed_base + seed_manifest$replicate_index
seed_manifest$seed_role <- run_id_prefix
seed_manifest$execution_status <- "executed"
if (identical(run_kind, "smoke")) {
  seed_manifest$source_contract <- rel_path(smoke_contract_path)
  seed_manifest$host_class <- host_class
  seed_manifest$host_name <- host_name
  if (!is.null(substitution_contract_row)) {
    seed_manifest$source_substitution_contract <- rel_path(
      smoke_substitution_contract_path
    )
    seed_manifest$source_substitution_contract_id <-
      substitution_contract_row$contract_id[[1L]]
  }
  } else if (run_kind %in% c("pregrid", "topup")) {
    seed_manifest$source_contract <- rel_path(denominator_contract_path)
    seed_manifest$contract_status <- "fisher_rose_grace_reviewed_sr150_pregrid_ready"
  seed_manifest$host_class <- host_class
  seed_manifest$host_name <- host_name
}
write_tsv(seed_manifest, seed_manifest_path)

replicate_rows <- list()
row_i <- 1L
for (provider in selected_providers) {
  selection_row <- smoke_rows[
    smoke_rows$structure_provider == provider,
    ,
    drop = FALSE
  ]
  for (replicate_index in seq(from = seed_start, length.out = n_rep)) {
    seed <- seed_base + replicate_index
    replicate_rows[[row_i]] <- run_one(selection_row, replicate_index, seed)
    row_i <- row_i + 1L
  }
}
replicates <- do.call(rbind, replicate_rows)
row.names(replicates) <- NULL

summaries <- lapply(selected_providers, function(provider) {
  x <- replicates[replicates$provider == provider, , drop = FALSE]
  selection_row <- smoke_rows[
    smoke_rows$structure_provider == provider,
    ,
    drop = FALSE
  ]
  all_gate_passed <- all(x$fit_ok) &&
    all(x$converged) &&
    all(x$pdHess) &&
    all(x$usable_interval) &&
    (!identical(run_kind, "smoke") ||
      all(x$warning_count == 0L))
  coverage <- mean(x$covered)
  status_value <- if (identical(run_kind, "smoke")) {
    if (all_gate_passed) "smoke_passed_fixture_only" else "smoke_failed"
  } else if (identical(run_kind, "pregrid")) {
    "sr150_pregrid_completed_review_pending"
  } else if (identical(run_kind, "topup")) {
    "sr_topup_shard_completed_review_pending"
  } else if (all_gate_passed) {
    "local_dry_run_passed_screen_only"
  } else {
    "local_dry_run_failed"
  }
  decision_value <- if (identical(run_kind, "smoke")) {
    if (all_gate_passed) {
      "fisher_rose_review_pending_no_promotion"
    } else {
      "do_not_promote_smoke_failed"
    }
  } else if (identical(run_kind, "pregrid")) {
    "fisher_rose_grace_evidence_review_required_no_promotion"
  } else if (identical(run_kind, "topup")) {
    "fisher_rose_grace_aggregate_review_required_no_promotion"
  } else if (all_gate_passed) {
    "totoro_fiia_smoke_accepted_fisher_rose"
  } else {
    "do_not_smoke_dry_run_failed"
  }
  evidence_url <- if (identical(run_kind, "smoke")) {
    rel_path(artifact_dir)
  } else if (run_kind %in% c("pregrid", "topup")) {
    rel_path(artifact_dir)
  } else {
    "docs/dev-log/after-task/2026-06-29-q-series-gaussian-lowq-mu-intercept-dry-run.md"
  }
  claim_boundary <- if (identical(run_kind, "smoke")) {
    paste(
      "Gaussian low-q q1 mu-intercept n=5 fixture smoke artifact only;",
      "this promotes exactly no Q-Series row; n=5 is smoke, not coverage evidence;",
      "no interval_status, coverage_status, inference_ready, supported, sigma,",
      "matched mu+sigma, q2, q4/q8, direct-SD, phylo_interaction, non-Gaussian,",
      "REML, AI-REML, Nibi/Rorqual/DRAC denominator, bridge support, or public support claim."
    )
  } else if (identical(run_kind, "pregrid")) {
    paste(
      "Gaussian low-q q1 mu-intercept SR150 retained-denominator pregrid artifact;",
      "this promotes exactly no Q-Series row; MCSE <= 0.01 is a top-up target,",
      "not an SR150 pass claim; review finite denominator, one-sided misses,",
      "and failure taxonomy before any status edit; no interval_status, coverage_status,",
      "inference_ready, supported, q1 sigma, matched mu+sigma, q2, q4/q8,",
      "non-Gaussian, REML, AI-REML, bridge support, or public support claim."
    )
  } else if (identical(run_kind, "topup")) {
    paste(
      "Gaussian low-q q1 mu-intercept retained-denominator top-up shard artifact;",
      "this promotes exactly no Q-Series row; aggregate with the reviewed SR150",
      "pregrid before any result import; MCSE <= 0.01 is a top-up target,",
      "not a shard-level pass claim; no interval_status, coverage_status,",
      "inference_ready, supported, q1 sigma, matched mu+sigma, q2, q4/q8,",
      "non-Gaussian, REML, AI-REML, bridge support, or public support claim."
    )
  } else {
    paste(
      "Gaussian low-q q1 mu-intercept local dry-run only;",
      "this promotes exactly no Q-Series row;",
      paste0("n=", nrow(x), " is not coverage evidence;"),
      "no interval_status, coverage_status, inference_ready, supported, sigma,",
      "q2, q4/q8, non-Gaussian, REML, AI-REML, DRAC, bridge support, or public support claim."
    )
  }
  next_gate <- if (identical(run_kind, "smoke")) {
    if (all_gate_passed) {
      paste(
        "Fisher/Rose must review the n=5 smoke artifacts before any",
        "Nibi/Rorqual/DRAC denominator work; linked support cells remain",
        "point_fit/planned/planned.",
        if (!is.null(substitution_contract_row)) {
          paste(
            "This was a Nibi/Rorqual substitute smoke under",
            "structured-re-q-series-smoke-substitution-contract.tsv."
          )
        } else {
          ""
        }
      )
    } else {
      paste(
        "Repair the row-specific smoke failure before Fisher/Rose review;",
        "Nibi/Rorqual/DRAC remain blocked."
      )
    }
  } else if (identical(run_kind, "pregrid")) {
    paste(
      "Fisher/Rose/Grace evidence review must inspect retained denominator,",
      "convergence, pdHess, finite intervals, warnings, lower/upper misses,",
      "miss rates, upper:lower ratio, and coverage MCSE before any top-up",
      "or status-table edit; linked support cells remain point_fit/planned/planned."
    )
  } else if (identical(run_kind, "topup")) {
    paste(
      "Aggregate this top-up shard with SR150 and any sibling shards before",
      "Fisher/Rose/Grace review; inspect retained denominator, convergence,",
      "pdHess, finite intervals, warnings, lower/upper misses, miss rates,",
      "upper:lower ratio, coverage MCSE, and failure taxonomy; linked support",
      "cells remain point_fit/planned/planned until an explicit reviewed import."
    )
  } else if (all_gate_passed) {
    paste(
      "Fisher/Rose accepted the dry-run contract for a Totoro/FIIA n=5 smoke,",
      "and the smoke-substitution contract in",
      "structured-re-q-series-smoke-substitution-contract.tsv now permits",
      "Nibi/Rorqual for the exact n=5 substitute smoke only; run only the four",
      "q1 mu-intercept targets with all attempted rows retained, store the",
      "substitute-host artifact, and keep Nibi/Rorqual/DRAC denominator work",
      "blocked until that smoke passes and Fisher/Rose review it."
    )
  } else {
    paste(
      "Repair the row-specific local dry-run failure before Totoro/FIIA;",
      "Nibi/Rorqual/DRAC remain blocked."
    )
  }
  row <- data.frame(
    run_id = paste0(run_id_prefix, "_", provider),
    cell_id = selection_row$cell_id[[1L]],
    provider = provider,
    source_row_selection = rel_path(row_selection_path),
    artifact_dir = rel_path(artifact_dir),
    n_rep = nrow(x),
    n_fit_ok = sum(x$fit_ok),
    n_converged = sum(x$converged),
    n_pdhess = sum(x$pdHess),
    n_confint_ok = sum(x$confint_ok),
    n_usable_intervals = sum(x$usable_interval),
    finite_interval_rate = fmt4(mean(x$usable_interval)),
    n_covered = sum(x$covered),
    coverage = fmt4(coverage),
    coverage_mcse = fmt6(mcse_proportion(x$covered)),
    lower_miss = sum(x$lower_miss),
    upper_miss = sum(x$upper_miss),
    lower_miss_rate = fmt4(mean(x$lower_miss)),
    upper_miss_rate = fmt4(mean(x$upper_miss)),
    upper_lower_miss_ratio = fmt4(
      if (sum(x$lower_miss) == 0L) NA_real_ else sum(x$upper_miss) / sum(x$lower_miss)
    ),
    run_status = status_value,
    next_decision = decision_value,
    promotion_decision = "do_not_promote",
    evidence_url = evidence_url,
    claim_boundary = claim_boundary,
    next_gate = next_gate,
    stringsAsFactors = FALSE
  )
  names(row)[names(row) == "run_id"] <- run_id_field
  names(row)[names(row) == "run_status"] <- if (identical(run_kind, "smoke")) {
    "smoke_status"
  } else if (identical(run_kind, "pregrid")) {
    "pregrid_status"
  } else if (identical(run_kind, "topup")) {
    "topup_status"
  } else {
    "dry_run_status"
  }
  names(row)[names(row) == "next_decision"] <- if (
    run_kind %in% c("smoke", "pregrid", "topup")
  ) {
    "review_decision"
  } else {
    "smoke_decision"
  }
  if (identical(run_kind, "smoke")) {
    contract_row <- smoke_contract_by_provider[[provider]]
    row$source_contract_id <- contract_row$contract_id[[1L]]
    row$source_contract <- rel_path(smoke_contract_path)
    row$host_class <- host_class
    row$host_name <- host_name
    row$n_warning_replicates <- sum(x$warning_count > 0L)
  } else if (run_kind %in% c("pregrid", "topup")) {
    contract_row <- denominator_contract_by_provider[[provider]]
    row$source_contract_id <- contract_row$contract_id[[1L]]
    row$source_contract <- rel_path(denominator_contract_path)
    row$host_class <- host_class
    row$host_name <- host_name
    row$n_warning_replicates <- sum(x$warning_count > 0L)
    row$n_retained_denominator <- nrow(x)
  }
  row
})
summary <- do.call(rbind, summaries)
row.names(summary) <- NULL

write_tsv(replicates, replicate_path)
write_tsv(summary, summary_path)
if (write_dashboard) {
  write_tsv(summary, dashboard_summary_path)
}
writeLines(capture.output(sessionInfo()), session_info_path)
git_sha <- tryCatch(
  system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE),
  error = function(e) paste("git-sha-unavailable:", conditionMessage(e))
)
writeLines(git_sha, git_sha_path)

message(
  "Wrote ",
  nrow(summary),
  " Gaussian low-q mu-intercept ",
  run_label,
  " summary rows to ",
  rel_path(summary_path)
)
if (write_dashboard) {
  message("Updated dashboard sidecar: ", rel_path(dashboard_summary_path))
}
message(
  "Wrote ",
  nrow(replicates),
  " replicate rows to ",
  rel_path(replicate_path)
)

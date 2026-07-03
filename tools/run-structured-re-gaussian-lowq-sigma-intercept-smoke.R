#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/run-structured-re-gaussian-lowq-sigma-intercept-smoke.R [options]",
      "",
      "Options:",
      "  --run-kind=smoke|pregrid|bootstrap_smoke  Run contract kind (default: smoke).",
      "  --n-rep=N                         Replicates per provider (default: 5).",
      "  --seed-start=N                    First replicate index (default: 1).",
      "  --seed-base=N                     Seed base; seed = seed_base + replicate_index (default: 914000).",
      "  --seed-list=A,B                   Exact seeds; required by bootstrap_smoke.",
      "  --bootstrap=N                     Bootstrap refits per retained seed (default: 0).",
      "  --bootstrap-seed=N                Bootstrap seed base (default: 540054).",
      "  --providers=a,b,c                 Providers to run (default: phylo,spatial,animal,relmat).",
      "  --host-class=CLASS                Host class label (default: local_rehearsal).",
      "  --host-name=NAME                  Host name label (default: Sys.info()[['nodename']]).",
      "  --profile=true                    Attempt endpoint profile diagnostics (default: true).",
      "  --profile-engine=ENGINE           Profile engine: endpoint or tmbprofile (default: endpoint).",
      "  --profile-endpoint-max-eval=N     Endpoint profile evaluation budget (default: 12).",
      "  --output-dir=PATH                 Artifact directory.",
      "  --overwrite=true                  Replace an existing artifact directory.",
      "  --write-dashboard=true            Write the dashboard summary sidecar.",
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

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

write_tsv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
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

fmt4 <- function(x) {
  ifelse(is.na(x), "NA", sprintf("%.4f", x))
}

fmt6 <- function(x) {
  ifelse(is.na(x), "NA", sprintf("%.6f", x))
}

mcse_proportion <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0L) {
    return(NA_real_)
  }
  p <- mean(x)
  sqrt(p * (1 - p) / length(x))
}

numeric_or_na <- function(x) {
  if (length(x) == 0L || is.null(x) || !is.finite(x)) {
    return(NA_real_)
  }
  unname(x[[1L]])
}

load_drmTMB_for_lowq_sigma <- function(path) {
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

n_rep <- as.integer(arg_value("n-rep", "5"))
if (!is.finite(n_rep) || n_rep < 1L) {
  stop("`--n-rep` must be a positive integer.", call. = FALSE)
}
seed_start <- as.integer(arg_value("seed-start", "1"))
if (!is.finite(seed_start) || seed_start < 1L) {
  stop("`--seed-start` must be a positive integer.", call. = FALSE)
}
seed_base <- as.integer(arg_value("seed-base", "914000"))
if (!is.finite(seed_base) || seed_base < 1L) {
  stop("`--seed-base` must be a positive integer.", call. = FALSE)
}
seed_list_arg <- arg_value("seed-list", NULL)
seed_values <- NULL
if (!is.null(seed_list_arg)) {
  seed_values <- as.integer(trimws(strsplit(seed_list_arg, ",", fixed = TRUE)[[1L]]))
  if (
    length(seed_values) == 0L ||
      any(!is.finite(seed_values)) ||
      any(seed_values < 1L) ||
      anyDuplicated(seed_values)
  ) {
    stop(
      "`--seed-list` must be a comma-separated list of unique positive integers.",
      call. = FALSE
    )
  }
  if (length(seed_values) != n_rep) {
    stop(
      "`--n-rep` must equal the number of seeds in `--seed-list`.",
      call. = FALSE
    )
  }
}
replicate_indices <- if (is.null(seed_values)) {
  seq(from = seed_start, length.out = n_rep)
} else {
  seed_values - seed_base
}
if (any(!is.finite(replicate_indices)) || any(replicate_indices < 1L)) {
  stop(
    "`--seed-list` seeds must be larger than `--seed-base` so retained replicate indices are positive.",
    call. = FALSE
  )
}
if (is.null(seed_values)) {
  seed_values <- seed_base + replicate_indices
}
bootstrap_R <- as.integer(arg_value("bootstrap", "0"))
if (!is.finite(bootstrap_R) || bootstrap_R < 0L) {
  stop("`--bootstrap` must be a non-negative integer.", call. = FALSE)
}
bootstrap_seed <- as.integer(arg_value("bootstrap-seed", "540054"))
if (!is.finite(bootstrap_seed) || bootstrap_seed < 1L) {
  stop("`--bootstrap-seed` must be a positive integer.", call. = FALSE)
}
profile_enabled <- arg_flag("profile", TRUE)
profile_engine <- arg_value("profile-engine", "endpoint")
if (!profile_engine %in% c("endpoint", "tmbprofile")) {
  stop(
    "`--profile-engine` must be either endpoint or tmbprofile.",
    call. = FALSE
  )
}
profile_endpoint_max_eval <- as.integer(arg_value(
  "profile-endpoint-max-eval",
  "12"
))
if (
  !is.finite(profile_endpoint_max_eval) ||
    profile_endpoint_max_eval < 1L
) {
  stop(
    "`--profile-endpoint-max-eval` must be a positive integer.",
    call. = FALSE
  )
}
overwrite <- arg_flag("overwrite", FALSE)
write_dashboard <- arg_flag("write-dashboard", TRUE)
run_kind <- gsub("-", "_", arg_value("run-kind", "smoke"), fixed = TRUE)
if (!run_kind %in% c("smoke", "pregrid", "bootstrap_smoke")) {
  stop(
    "`--run-kind` must be `smoke`, `pregrid`, or `bootstrap_smoke`.",
    call. = FALSE
  )
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
host_class <- arg_value("host-class", "local_rehearsal")
host_name <- arg_value("host-name", unname(Sys.info()[["nodename"]]))

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
route_contract_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-lowq-sigma-intercept-route-contract.tsv"
)
bootstrap_contract_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-lowq-tranche54-q1-sigma-bootstrap-smoke-contract.tsv"
)
row_selection_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-lowq-row-selection.tsv"
)
dashboard_summary_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-lowq-sigma-intercept-local-smoke.tsv"
)
default_artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-29-gaussian-lowq-sigma-intercept-smoke-local"
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

summary_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-lowq-sigma-intercept-local-smoke.tsv"
)
replicate_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-lowq-sigma-intercept-local-smoke-replicates.tsv"
)
seed_manifest_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-lowq-sigma-intercept-local-smoke-seed-manifest.tsv"
)
session_info_path <- file.path(artifact_dir, "sessionInfo.txt")
git_sha_path <- file.path(artifact_dir, "git-sha.txt")

load_drmTMB_for_lowq_sigma(repo_root)

route_contract <- read_tsv(route_contract_path)
row_selection <- read_tsv(row_selection_path)

expected_cells <- c(
  phylo = "qseries_phylo_q1_sigma_intercept",
  spatial = "qseries_spatial_q1_sigma_intercept",
  animal = "qseries_animal_q1_sigma_intercept",
  relmat = "qseries_relmat_q1_sigma_intercept"
)
selected_providers <- trimws(strsplit(
  arg_value("providers", paste(names(expected_cells), collapse = ",")),
  ",",
  fixed = TRUE
)[[1L]])
selected_providers <- selected_providers[nzchar(selected_providers)]
unknown_providers <- setdiff(selected_providers, names(expected_cells))
if (length(selected_providers) == 0L || length(unknown_providers) > 0L) {
  stop(
    "`--providers` must be a comma-separated subset of: phylo, spatial, animal, relmat.",
    call. = FALSE
  )
}
if (identical(run_kind, "bootstrap_smoke")) {
  if (
    length(selected_providers) != 2L ||
      !setequal(selected_providers, c("animal", "relmat"))
  ) {
    stop(
      "Bootstrap-smoke mode is limited to `--providers=animal,relmat`.",
      call. = FALSE
    )
  }
  if (
    n_rep != 2L ||
      !identical(as.integer(seed_values), c(914008L, 914011L)) ||
      !identical(as.integer(replicate_indices), c(8L, 11L))
  ) {
    stop(
      "Bootstrap-smoke mode is limited to retained seeds 914008 and 914011.",
      call. = FALSE
    )
  }
  if (bootstrap_R <= 0L) {
    stop(
      "Bootstrap-smoke mode requires --bootstrap to be a positive integer.",
      call. = FALSE
    )
  }
  if (profile_enabled) {
    stop(
      "Bootstrap-smoke mode keeps the blocked profile route off. Use --profile=false.",
      call. = FALSE
    )
  }
  if (write_dashboard) {
    stop(
      "Bootstrap-smoke mode is artifact-only. Use --write-dashboard=false, ",
      "then import reviewed artifacts through a validator-owned sidecar.",
      call. = FALSE
    )
  }
  if (
    !identical(
      Sys.getenv("DRMTMB_Q1_SIGMA_TRANCHE54_EXECUTION_APPROVED", unset = ""),
      "rose_fisher_gauss_noether_grace"
    )
  ) {
    stop(
      "Refusing to run Tranche 54 bootstrap smoke without ",
      "DRMTMB_Q1_SIGMA_TRANCHE54_EXECUTION_APPROVED=rose_fisher_gauss_noether_grace.",
      call. = FALSE
    )
  }
}

contract_rows <- route_contract[
  route_contract$cell_id %in% unname(expected_cells[selected_providers]),
  ,
  drop = FALSE
]
contract_rows <- contract_rows[
  match(unname(expected_cells[selected_providers]), contract_rows$cell_id),
  ,
  drop = FALSE
]
if (
  nrow(contract_rows) != length(selected_providers) ||
    anyNA(contract_rows$cell_id)
) {
  stop(
    "Route-contract sidecar must contain the selected q1 sigma intercept cells.",
    call. = FALSE
  )
}
if (
  !all(
    contract_rows$interval_channel ==
      "raw_log_sd_wald_z;small_sample_df_none;bias_correct_none"
  )
) {
  stop(
    "Route contract must pin raw Wald intervals with no correction.",
    call. = FALSE
  )
}

selection_rows <- row_selection[
  row_selection$cell_id %in% unname(expected_cells[selected_providers]),
  ,
  drop = FALSE
]
selection_rows <- selection_rows[
  match(unname(expected_cells[selected_providers]), selection_rows$cell_id),
  ,
  drop = FALSE
]
if (
  nrow(selection_rows) != length(selected_providers) ||
    anyNA(selection_rows$cell_id)
) {
  stop(
    "Row-selection sidecar must contain the selected q1 sigma intercept cells.",
    call. = FALSE
  )
}
if (!all(selection_rows$endpoint_set == "sigma")) {
  stop("Selected rows must be q1 sigma rows.", call. = FALSE)
}
if (!all(selection_rows$slope_class == "intercept_only")) {
  stop("Selected rows must be intercept-only rows.", call. = FALSE)
}
if (identical(run_kind, "bootstrap_smoke")) {
  bootstrap_contract <- read_tsv(bootstrap_contract_path)
  required_bootstrap_fields <- c(
    "contract_id",
    "contract_scope",
    "cell_ids",
    "providers",
    "source_tranche53_design",
    "source_tranche49_blocker",
    "source_profile_route_review",
    "source_pregrid_replicates",
    "source_runner",
    "source_helper",
    "selected_route",
    "target_component",
    "target_estimand",
    "bootstrap_R",
    "n_rep_per_provider",
    "selected_seeds",
    "seed_list_arg",
    "retained_replicate_indices",
    "host_plan",
    "command_status",
    "execution_decision",
    "coverage_decision",
    "promotion_decision",
    "support_cell_decision",
    "blocking_reviewers",
    "advisory_reviewers",
    "fisher_review",
    "rose_audit",
    "gauss_review",
    "noether_review",
    "grace_review",
    "curie_review",
    "exact_command",
    "artifact_root",
    "evidence_url",
    "claim_boundary",
    "next_gate"
  )
  missing_bootstrap_fields <- setdiff(
    required_bootstrap_fields,
    names(bootstrap_contract)
  )
  if (length(missing_bootstrap_fields) > 0L) {
    stop(
      "Tranche 54 bootstrap contract sidecar is missing fields: ",
      paste(missing_bootstrap_fields, collapse = ", "),
      call. = FALSE
    )
  }
  bootstrap_contract_row <- bootstrap_contract[
    bootstrap_contract$contract_id ==
      "tranche54_q1_sigma_bootstrap_smoke_command",
    ,
    drop = FALSE
  ]
  if (nrow(bootstrap_contract_row) != 1L) {
    stop(
      "Tranche 54 bootstrap contract must expose exactly one command row.",
      call. = FALSE
    )
  }
  if (!identical(
    bootstrap_contract_row$cell_ids,
    "qseries_animal_q1_sigma_intercept;qseries_relmat_q1_sigma_intercept"
  )) {
    stop("Tranche 54 bootstrap command must target animal/relmat q1 sigma only.", call. = FALSE)
  }
  if (!identical(bootstrap_contract_row$providers, "animal;relmat")) {
    stop("Tranche 54 bootstrap command must keep providers = animal;relmat.", call. = FALSE)
  }
  if (!identical(
    bootstrap_contract_row$selected_route,
    "parametric_bootstrap_direct_sigma_sd_boundary_seed_micro_smoke"
  )) {
    stop(
      "Tranche 54 bootstrap command must keep the selected Tranche 53 route.",
      call. = FALSE
    )
  }
  contract_bootstrap_R <- as.integer(bootstrap_contract_row$bootstrap_R[[1L]])
  contract_n_rep <- as.integer(bootstrap_contract_row$n_rep_per_provider[[1L]])
  contract_seed_values <- as.integer(strsplit(
    bootstrap_contract_row$seed_list_arg[[1L]],
    ",",
    fixed = TRUE
  )[[1L]])
  if (
    !identical(contract_bootstrap_R, bootstrap_R) ||
      !identical(contract_n_rep, n_rep) ||
      !identical(contract_seed_values, as.integer(seed_values))
  ) {
    stop(
      "Tranche 54 bootstrap command arguments must match the reviewed contract.",
      call. = FALSE
    )
  }
  for (phrase in c(
    "contract_banked_not_executed",
    "do_not_execute_until_rose_fisher_gauss_noether_grace_explicit_approval",
    "coverage_not_authorized",
    "do_not_promote"
  )) {
    fields <- paste(
      bootstrap_contract_row$command_status,
      bootstrap_contract_row$execution_decision,
      bootstrap_contract_row$coverage_decision,
      bootstrap_contract_row$promotion_decision
    )
    if (!grepl(phrase, fields, fixed = TRUE)) {
      stop(
        "Tranche 54 bootstrap contract must keep boundary phrase: ",
        phrase,
        call. = FALSE
      )
    }
  }
}

provider_defaults <- list(
  phylo = list(
    n_group = 10L,
    n_each = 10L,
    beta_mu_intercept = 0.30,
    beta_sigma_intercept = -1.00,
    sd_sigma_intercept = 0.20,
    group_var = "species",
    term = "phylo(1 | species)"
  ),
  spatial = list(
    n_group = 10L,
    n_each = 10L,
    beta_mu_intercept = 0.30,
    beta_sigma_intercept = -1.00,
    sd_sigma_intercept = 0.18,
    group_var = "site",
    term = "spatial(1 | site)"
  ),
  animal = list(
    n_group = 10L,
    n_each = 10L,
    beta_mu_intercept = 0.30,
    beta_sigma_intercept = -1.00,
    sd_sigma_intercept = 0.20,
    group_var = "id",
    term = "animal(1 | id)"
  ),
  relmat = list(
    n_group = 10L,
    n_each = 10L,
    beta_mu_intercept = 0.30,
    beta_sigma_intercept = -1.00,
    sd_sigma_intercept = 0.20,
    group_var = "id",
    term = "relmat(1 | id)"
  )
)

make_dense_covariance <- function(n_group, prefix) {
  levels <- paste0(prefix, "_", seq_len(n_group))
  K <- outer(
    seq_len(n_group),
    seq_len(n_group),
    function(i, j) 0.35^abs(i - j)
  )
  diag(K) <- diag(K) + 0.20
  dimnames(K) <- list(levels, levels)
  K
}

make_sigma_effect <- function(K, sd_sigma) {
  L <- t(chol(K))
  effect <- as.vector(L %*% (sd_sigma * stats::rnorm(nrow(K))))
  names(effect) <- rownames(K)
  effect
}

make_data <- function(provider, spec, seed, cell_id, replicate_index) {
  set.seed(seed)
  if (identical(provider, "phylo")) {
    tree <- ape::rcoal(spec$n_group)
    tree$tip.label <- paste0("sp_", seq_len(spec$n_group))
    storage.mode(tree$edge) <- "double"
    K <- drmTMB:::drm_phylo_tip_covariance(tree)
    levels <- rownames(K)
    matrix_payload <- list(tree = tree, K = K)
  } else if (identical(provider, "spatial")) {
    levels <- paste0("site_", seq_len(spec$n_group))
    theta <- seq(0, 1.5 * pi, length.out = spec$n_group)
    coords <- data.frame(
      coord_x = cos(theta) + seq_len(spec$n_group) / (4 * spec$n_group),
      coord_y = sin(theta)
    )
    row.names(coords) <- levels
    precision <- drmTMB:::drm_spatial_coords_precision(
      coords,
      site = levels,
      group = "site"
    )
    K <- solve(as.matrix(precision$precision))
    dimnames(K) <- list(levels, levels)
    matrix_payload <- list(coords = coords, K = K)
  } else if (identical(provider, "animal")) {
    K <- make_dense_covariance(spec$n_group, "id")
    levels <- rownames(K)
    matrix_payload <- list(A = K, K = K)
  } else if (identical(provider, "relmat")) {
    K <- make_dense_covariance(spec$n_group, "id")
    levels <- rownames(K)
    matrix_payload <- list(K = K)
  } else {
    stop("Unknown provider: ", provider, call. = FALSE)
  }

  effect_sigma <- make_sigma_effect(K, spec$sd_sigma_intercept)
  group <- rep(levels, each = spec$n_each)
  mu <- rep(spec$beta_mu_intercept, length(group))
  sigma <- exp(unname(spec$beta_sigma_intercept + effect_sigma[group]))
  y <- stats::rnorm(length(group), mean = mu, sd = sigma)

  dat <- data.frame(y = y, stringsAsFactors = FALSE)
  dat[[spec$group_var]] <- group
  attr(dat, "truth") <- c(
    list(
      provider = provider,
      cell_id = cell_id,
      replicate_index = replicate_index,
      beta_mu_intercept = spec$beta_mu_intercept,
      beta_sigma_intercept = spec$beta_sigma_intercept,
      sd_sigma_intercept = spec$sd_sigma_intercept,
      n_group = spec$n_group,
      n_each = spec$n_each
    ),
    matrix_payload
  )
  dat
}

fit_sigma <- function(provider, dat) {
  truth <- attr(dat, "truth", exact = TRUE)
  ctrl <- drm_control(
    keep_tmb_object = TRUE,
    optimizer = list(eval.max = 500, iter.max = 500)
  )
  switch(
    provider,
    phylo = {
      tree <- truth$tree
      drmTMB(
        bf(y ~ 1, sigma ~ phylo(1 | species, tree = tree)),
        family = gaussian(),
        data = dat,
        control = ctrl
      )
    },
    spatial = {
      coords <- truth$coords
      drmTMB(
        bf(y ~ 1, sigma ~ spatial(1 | site, coords = coords)),
        family = gaussian(),
        data = dat,
        control = ctrl
      )
    },
    animal = {
      A <- truth$A
      drmTMB(
        bf(y ~ 1, sigma ~ animal(1 | id, A = A)),
        family = gaussian(),
        data = dat,
        control = ctrl
      )
    },
    relmat = {
      K <- truth$K
      drmTMB(
        bf(y ~ 1, sigma ~ relmat(1 | id, K = K)),
        family = gaussian(),
        data = dat,
        control = ctrl
      )
    },
    stop("Unknown provider: ", provider, call. = FALSE)
  )
}

find_interval_row <- function(ci, target) {
  if (is.null(ci)) {
    return(NULL)
  }
  hit <- ci$parm == target
  if (!any(hit)) {
    hit <- grepl(target, ci$parm, fixed = TRUE)
  }
  if (!any(hit) && grepl("^sd:sigma:", target)) {
    target_with_dpar <- sub("^sd:sigma:", "sd:sigma:sigma:", target)
    hit <- ci$parm == target_with_dpar
    if (!any(hit)) {
      hit <- grepl(target_with_dpar, ci$parm, fixed = TRUE)
    }
  }
  if (!any(hit)) {
    return(NULL)
  }
  ci[which(hit)[[1L]], , drop = FALSE]
}

run_bootstrap <- function(fit, parm, replicate_index) {
  if (bootstrap_R <= 0L) {
    return(list(
      attempted = FALSE,
      lower = NA_real_,
      upper = NA_real_,
      status = "skipped",
      message = "bootstrap_off",
      warnings = NA_character_,
      seed = NA_integer_
    ))
  }
  boot_seed <- bootstrap_seed + replicate_index
  warnings <- character()
  result <- withCallingHandlers(
    tryCatch(
      stats::confint(
        fit,
        parm = parm,
        method = "bootstrap",
        level = 0.95,
        R = bootstrap_R,
        seed = boot_seed
      ),
      error = function(e) e
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  if (inherits(result, "error")) {
    return(list(
      attempted = TRUE,
      lower = NA_real_,
      upper = NA_real_,
      status = "error",
      message = clean_text(conditionMessage(result)),
      warnings = clean_text(paste(warnings, collapse = " | ")),
      seed = boot_seed
    ))
  }
  interval_row <- find_interval_row(result, parm)
  if (is.null(interval_row)) {
    return(list(
      attempted = TRUE,
      lower = NA_real_,
      upper = NA_real_,
      status = "parm_not_found",
      message = paste0("bootstrap: parm not found: ", parm),
      warnings = clean_text(paste(warnings, collapse = " | ")),
      seed = boot_seed
    ))
  }
  lower <- interval_row$lower[[1L]]
  upper <- interval_row$upper[[1L]]
  list(
    attempted = TRUE,
    lower = lower,
    upper = upper,
    status = if (is.finite(lower) && is.finite(upper)) {
      "finite"
    } else {
      "nonfinite"
    },
    message = NA_character_,
    warnings = clean_text(paste(warnings, collapse = " | ")),
    seed = boot_seed
  )
}

estimate_for_sigma <- function(fit, spec) {
  if (is.null(fit) || is.null(fit$sdpars$sigma)) {
    return(NA_real_)
  }
  if (spec$term %in% names(fit$sdpars$sigma)) {
    return(numeric_or_na(unname(fit$sdpars$sigma[[spec$term]])))
  }
  numeric_or_na(unname(fit$sdpars$sigma[[1L]]))
}

sdr_cov_available <- function(fit) {
  if (is.null(fit) || is.null(fit$sdr)) {
    return(FALSE)
  }
  cov_fixed <- tryCatch(fit$sdr$cov.fixed, error = function(e) NULL)
  !is.null(cov_fixed) && length(cov_fixed) > 0L && all(is.finite(cov_fixed))
}

run_one <- function(selection_row, contract_row, replicate_index, seed) {
  provider <- selection_row$structure_provider[[1L]]
  spec <- provider_defaults[[provider]]
  warnings <- character()
  fit_error <- NA_character_
  confint_error <- NA_character_
  profile_error <- NA_character_
  profile_message <- NA_character_
  started <- proc.time()[["elapsed"]]
  target <- contract_row$direct_sd_target[[1L]]

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
  profile_ci <- NULL
  if (inherits(dat, "error")) {
    fit_error <- conditionMessage(dat)
  } else {
    fit <- tryCatch(
      withCallingHandlers(
        fit_sigma(provider, dat),
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
        confint(
          fit,
          parm = target,
          method = "wald",
          small_sample_df = "none",
          bias_correct = "none"
        ),
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

  if (!is.null(fit) && profile_enabled) {
    profile_args <- list(
      fit,
      parm = target,
      method = "profile",
      profile_engine = profile_engine
    )
    if (identical(profile_engine, "endpoint")) {
      profile_args$profile_endpoint_max_eval <- profile_endpoint_max_eval
    }
    profile_ci <- tryCatch(
      withCallingHandlers(
        do.call(confint, profile_args),
        warning = function(w) {
          warnings <<- c(warnings, conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      ),
      error = function(e) e
    )
    if (inherits(profile_ci, "error")) {
      profile_error <- conditionMessage(profile_ci)
      profile_message <- profile_error
      profile_ci <- NULL
    }
  }

  elapsed <- proc.time()[["elapsed"]] - started
  fit_ok <- !is.null(fit)
  converged <- fit_ok && isTRUE(fit$opt$convergence == 0)
  pdhess <- fit_ok && isTRUE(fit$sdr$pdHess)
  sdreport_ok <- sdr_cov_available(fit)
  confint_ok <- !is.null(ci)
  interval_row <- find_interval_row(ci, target)
  profile_row <- find_interval_row(profile_ci, target)

  conf_status <- if (is.null(interval_row)) {
    if (!fit_ok) {
      "fit_failed"
    } else if (!pdhess) {
      "not_run_pdhess_false"
    } else if (!sdreport_ok) {
      "sdreport_cov_unavailable"
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
  target_parameter <- if (is.null(interval_row)) {
    target
  } else {
    interval_row$parm[[1L]]
  }
  usable_interval <- identical(conf_status, "wald") &&
    is.finite(lower) &&
    is.finite(upper)
  truth_value <- spec$sd_sigma_intercept
  covered <- if (usable_interval) {
    lower <= truth_value && truth_value <= upper
  } else {
    NA
  }
  lower_miss <- if (usable_interval) truth_value < lower else NA
  upper_miss <- if (usable_interval) truth_value > upper else NA
  bi <- if (!is.null(fit)) {
    run_bootstrap(fit, target, replicate_index)
  } else {
    list(
      attempted = FALSE,
      lower = NA_real_,
      upper = NA_real_,
      status = if (is.na(fit_error)) "skipped" else "fit_failed",
      message = fit_error,
      warnings = NA_character_,
      seed = NA_integer_
    )
  }
  bootstrap_covered <- if (
    is.finite(bi$lower) &&
      is.finite(bi$upper) &&
      is.finite(truth_value)
  ) {
    bi$lower <= truth_value && truth_value <= bi$upper
  } else {
    NA
  }

  profile_status <- if (!profile_enabled) {
    "profile_not_requested"
  } else if (is.null(profile_row)) {
    if (!fit_ok) {
      "fit_failed"
    } else if (is.na(profile_error)) {
      "profile_target_missing"
    } else {
      "profile_failed"
    }
  } else {
    profile_row$conf.status[[1L]]
  }
  profile_lower <- if (is.null(profile_row)) {
    NA_real_
  } else {
    profile_row$lower[[1L]]
  }
  profile_upper <- if (is.null(profile_row)) {
    NA_real_
  } else {
    profile_row$upper[[1L]]
  }
  profile_finite <- is.finite(profile_lower) && is.finite(profile_upper)
  profile_ok <- identical(profile_status, "profile") && profile_finite
  profile_parameter <- if (is.null(profile_row)) {
    target
  } else {
    profile_row$parm[[1L]]
  }
  profile_covered <- if (profile_ok) {
    profile_lower <= truth_value && truth_value <= profile_upper
  } else {
    NA
  }
  profile_lower_miss <- if (profile_ok) truth_value < profile_lower else NA
  profile_upper_miss <- if (profile_ok) truth_value > profile_upper else NA
  if (!is.null(profile_row) && "profile.message" %in% names(profile_row)) {
    profile_message <- profile_row$profile.message[[1L]]
  }
  profile_channel <- if (profile_enabled) {
    paste0(profile_engine, "_profile_diagnostic_only")
  } else {
    "profile_not_requested"
  }

  data.frame(
    smoke_id = paste0(
      "gaussian_lowq_sigma_intercept_smoke_",
      provider,
      "_rep",
      replicate_index
    ),
    cell_id = selection_row$cell_id[[1L]],
    provider = provider,
    formula_cell = selection_row$formula_cell[[1L]],
    replicate_index = replicate_index,
    seed = seed,
    target_kind = "direct_sd_sigma_intercept",
    endpoint_member = "sigma:(Intercept)",
    estimand = "structured SD for sigma intercept",
    interval_channel = "raw_log_sd_wald_z;small_sample_df_none;bias_correct_none",
    profile_channel = profile_channel,
    source_contract_id = contract_row$contract_id[[1L]],
    source_contract = rel_path(route_contract_path),
    contract_direct_sd_target = target,
    wald_parameter = target_parameter,
    profile_parameter = profile_parameter,
    truth_value = truth_value,
    n_group = spec$n_group,
    n_each = spec$n_each,
    beta_mu_intercept = spec$beta_mu_intercept,
    beta_sigma_intercept = spec$beta_sigma_intercept,
    truth_sd_sigma_intercept = spec$sd_sigma_intercept,
    fit_ok = fit_ok,
    converged = converged,
    pdHess = pdhess,
    sdreport_cov_available = sdreport_ok,
    confint_ok = confint_ok,
    small_sample_df = "none",
    bias_correct = "none",
    conf_status = conf_status,
    usable_interval = usable_interval,
    estimate = estimate_for_sigma(fit, spec),
    conf.low = lower,
    conf.high = upper,
    covered = covered,
    lower_miss = lower_miss,
    upper_miss = upper_miss,
    bootstrap_R = bootstrap_R,
    bootstrap_refit_attempts_requested = bootstrap_R,
    bootstrap_seed = bi$seed,
    bootstrap_attempted = bi$attempted,
    bootstrap_status = bi$status,
    bootstrap_conf.low = bi$lower,
    bootstrap_conf.high = bi$upper,
    bootstrap_covered = bootstrap_covered,
    bootstrap_lower_miss = isTRUE(
      is.finite(bi$lower) &&
        is.finite(truth_value) &&
        truth_value < bi$lower
    ),
    bootstrap_upper_miss = isTRUE(
      is.finite(bi$upper) &&
        is.finite(truth_value) &&
        truth_value > bi$upper
    ),
    bootstrap_message = bi$message,
    bootstrap_warnings = bi$warnings,
    profile_ok = profile_ok,
    profile_status = profile_status,
    profile_engine = if (profile_enabled) profile_engine else "not_requested",
    profile_endpoint_max_eval = if (
      profile_enabled && identical(profile_engine, "endpoint")
    ) {
      profile_endpoint_max_eval
    } else {
      NA_integer_
    },
    profile.low = profile_lower,
    profile.high = profile_upper,
    profile_finite = profile_finite,
    profile_covered = profile_covered,
    profile_lower_miss = profile_lower_miss,
    profile_upper_miss = profile_upper_miss,
    profile_message = profile_message,
    nobs = if (fit_ok) stats::nobs(fit) else NA_integer_,
    elapsed = elapsed,
    warning_count = length(unique(warnings)),
    warnings = paste(unique(warnings), collapse = " | "),
    fit_error = fit_error,
    confint_error = confint_error,
    profile_error = profile_error,
    host_class = host_class,
    host_name = host_name,
    stringsAsFactors = FALSE
  )
}

seed_manifest <- expand.grid(
  provider = selected_providers,
  seed_position = seq_along(seed_values),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
seed_manifest$replicate_index <- replicate_indices[seed_manifest$seed_position]
seed_manifest$seed <- seed_values[seed_manifest$seed_position]
seed_manifest$seed_position <- NULL
seed_manifest$seed_role <- "gaussian_lowq_sigma_intercept_smoke"
seed_manifest$execution_status <- "executed"
seed_manifest$source_contract <- rel_path(route_contract_path)
seed_manifest$host_class <- host_class
seed_manifest$host_name <- host_name
if (identical(run_kind, "bootstrap_smoke")) {
  seed_manifest$source_contract <- rel_path(bootstrap_contract_path)
  seed_manifest$source_contract_id <- bootstrap_contract_row$contract_id[[1L]]
  seed_manifest$contract_status <- "tranche54_bootstrap_smoke_contract_ready"
  seed_manifest$bootstrap_R <- bootstrap_R
  seed_manifest$bootstrap_seed_base <- bootstrap_seed
  seed_manifest$bootstrap_seed <- bootstrap_seed + seed_manifest$replicate_index
}
write_tsv(seed_manifest, seed_manifest_path)

replicate_rows <- list()
row_i <- 1L
for (provider in selected_providers) {
  selection_row <- selection_rows[
    selection_rows$structure_provider == provider,
    ,
    drop = FALSE
  ]
  contract_row <- contract_rows[
    contract_rows$provider == provider,
    ,
    drop = FALSE
  ]
  for (seed_position in seq_along(seed_values)) {
    replicate_index <- replicate_indices[[seed_position]]
    seed <- seed_values[[seed_position]]
    replicate_rows[[row_i]] <- run_one(
      selection_row,
      contract_row,
      replicate_index,
      seed
    )
    row_i <- row_i + 1L
  }
}
replicates <- do.call(rbind, replicate_rows)
row.names(replicates) <- NULL

summaries <- lapply(selected_providers, function(provider) {
  x <- replicates[replicates$provider == provider, , drop = FALSE]
  selection_row <- selection_rows[
    selection_rows$structure_provider == provider,
    ,
    drop = FALSE
  ]
  contract_row <- contract_rows[
    contract_rows$provider == provider,
    ,
    drop = FALSE
  ]
  support_clear <- all(x$fit_ok) &&
    all(x$converged) &&
    all(x$pdHess) &&
    all(x$sdreport_cov_available) &&
    all(x$usable_interval) &&
    (!identical(run_kind, "bootstrap_smoke") ||
      all(x$bootstrap_status == "finite"))
  n_usable <- sum(x$usable_interval)
  covered <- x$covered[x$usable_interval]
  coverage <- if (length(covered) == 0L) NA_real_ else mean(covered)
  bootstrap_covered <- x$bootstrap_covered[
    !is.na(x$bootstrap_covered)
  ]
  bootstrap_coverage <- if (length(bootstrap_covered) == 0L) {
    NA_real_
  } else {
    mean(bootstrap_covered)
  }
  profile_covered <- x$profile_covered[x$profile_ok]
  profile_coverage <- if (length(profile_covered) == 0L) {
    NA_real_
  } else {
    mean(profile_covered)
  }
  status <- if (identical(run_kind, "bootstrap_smoke")) {
    if (support_clear) {
      "bootstrap_smoke_completed_review_pending"
    } else {
      "bootstrap_smoke_failed_review_required"
    }
  } else if (support_clear) {
    "local_smoke_passed_route_only"
  } else {
    "local_smoke_diagnostic_blocked"
  }
  blockers <- unique(c(
    if (any(!x$fit_ok)) "fit_failed",
    if (any(!x$converged)) "nonconverged",
    if (any(!x$pdHess)) "pdhess_false",
    if (any(!x$sdreport_cov_available)) "sdreport_cov_unavailable",
    if (any(!x$usable_interval)) "nonusable_wald_interval",
    if (profile_enabled && any(!x$profile_finite)) "profile_nonfinite_or_failed",
    if (
      identical(run_kind, "bootstrap_smoke") &&
        any(x$bootstrap_status != "finite")
    ) "bootstrap_nonfinite_or_failed",
    if (any(x$warning_count > 0L)) "warnings_recorded"
  ))
  if (length(blockers) == 0L) {
    blockers <- "none"
  }
  profile_engines <- paste(sort(unique(x$profile_engine)), collapse = ",")
  data.frame(
    smoke_id = paste0("gaussian_lowq_sigma_intercept_smoke_", provider),
    cell_id = selection_row$cell_id[[1L]],
    provider = provider,
    source_contract_id = contract_row$contract_id[[1L]],
    source_contract = rel_path(route_contract_path),
    source_row_selection = rel_path(row_selection_path),
    artifact_dir = rel_path(artifact_dir),
    n_rep = length(unique(x$replicate_index)),
    n_targets = nrow(x),
    n_fit_ok = sum(x$fit_ok),
    n_converged = sum(x$converged),
    n_pdhess = sum(x$pdHess),
    n_sdreport_cov_available = sum(x$sdreport_cov_available),
    n_confint_ok = sum(x$confint_ok),
    n_usable_wald_intervals = n_usable,
    finite_wald_interval_rate = fmt4(mean(x$usable_interval)),
    n_covered = if (length(covered) == 0L) 0L else sum(covered),
    coverage = fmt4(coverage),
    coverage_mcse = fmt6(mcse_proportion(covered)),
    lower_miss = sum(x$lower_miss, na.rm = TRUE),
    upper_miss = sum(x$upper_miss, na.rm = TRUE),
    n_bootstrap_request_rows = sum(x$bootstrap_R > 0L),
    n_bootstrap_attempted = sum(x$bootstrap_attempted),
    n_bootstrap_finite = sum(x$bootstrap_status == "finite", na.rm = TRUE),
    bootstrap_coverage_smoke = fmt4(bootstrap_coverage),
    bootstrap_coverage_mcse = fmt6(mcse_proportion(bootstrap_covered)),
    bootstrap_lower_miss = sum(x$bootstrap_lower_miss),
    bootstrap_upper_miss = sum(x$bootstrap_upper_miss),
    n_profile_ok = sum(x$profile_ok),
    n_profile_finite = sum(x$profile_finite),
    n_profile_failed = sum(!x$profile_ok),
    n_profile_covered = if (length(profile_covered) == 0L) {
      0L
    } else {
      sum(profile_covered)
    },
    profile_coverage = fmt4(profile_coverage),
    profile_coverage_mcse = fmt6(mcse_proportion(profile_covered)),
    profile_lower_miss = sum(x$profile_lower_miss, na.rm = TRUE),
    profile_upper_miss = sum(x$profile_upper_miss, na.rm = TRUE),
    n_boundary_rows = sum(grepl("boundary", x$conf_status, fixed = TRUE)),
    n_warning_replicates = sum(x$warning_count > 0L),
    smoke_status = status,
    blocker_signal = paste(blockers, collapse = ";"),
    review_decision = if (identical(run_kind, "bootstrap_smoke")) {
      "rose_fisher_gauss_noether_grace_review_required_no_promotion"
    } else {
      "fisher_gauss_rose_review_required"
    },
    promotion_decision = "do_not_promote",
    evidence_url = rel_path(artifact_dir),
    claim_boundary = if (identical(run_kind, "bootstrap_smoke")) {
      paste(
        "Tranche 54 animal/relmat q1 sigma bootstrap micro-smoke artifact only;",
        "this records boundary-seed bootstrap plumbing and promotes exactly no",
        "Q-Series row; two retained seeds per provider are not coverage evidence;",
        "no bootstrap reliability claim; no interval_status, coverage_status,",
        "inference_ready, supported, q1 mu, matched mu+sigma, q2, q4/q8,",
        "non-Gaussian, REML, AI-REML, bridge support, public support, or",
        "pooled host denominator claim."
      )
    } else {
      paste(
        "Gaussian low-q q1 sigma-intercept local smoke only;",
        "this promotes exactly no Q-Series row;",
        paste0(
          "n=",
          length(unique(x$replicate_index)),
          " is not coverage evidence;"
        ),
        "raw Wald uses small_sample_df=none and bias_correct=none;",
        paste0(profile_engines, " profile rows are diagnostic only;"),
        "boundary, warning, failed-profile, and finite-subset rows are retained;",
        "no fit_status, interval_status, coverage_status, inference_ready,",
        "supported, location-axis bias+t correction, q1 mu, matched mu+sigma, q2,",
        "q4/q8, non-Gaussian, REML, AI-REML, bridge support, public support,",
        "Totoro/FIIA, Nibi/Rorqual, or DRAC denominator claim."
      )
    },
    next_gate = if (identical(run_kind, "bootstrap_smoke")) {
      paste(
        "Rose/Fisher/Gauss/Noether/Grace must review the retained boundary-seed",
        "bootstrap artifact before any route expansion, top-up, or status-table",
        "edit; linked support cells remain point_fit/extractor_ready/",
        "fixture_parity/planned/planned/source."
      )
    } else {
      paste(
        "Fisher/Gauss/Rose must review the retained n=5 rows before any host",
        "escalation; if accepted, Totoro/FIIA may repeat this exact smoke;",
        "Nibi/Rorqual denominator work remains blocked until the retained",
        "denominator design, one-sided miss rules, profile diagnostic policy,",
        "and stop rules are signed off; keep support cells point_fit/planned/planned."
      )
    },
    host_class = host_class,
    host_name = host_name,
    stringsAsFactors = FALSE
  )
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
  " Gaussian low-q sigma-intercept smoke summary rows to ",
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

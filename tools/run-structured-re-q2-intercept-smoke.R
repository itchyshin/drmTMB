#!/usr/bin/env Rscript
#
# q2-intercept interval smoke runner.
#
# This runner executes the local gate declared in
# structured-re-q2-intercept-interval-contract.tsv, or the exact Nibi/Rorqual
# n=5 substitute-host smoke declared in
# structured-re-q-series-smoke-substitution-contract.tsv. It is deliberately
# not a coverage grid: every attempted target is retained in the denominator,
# and the summary promotes no Q-Series row.

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/run-structured-re-q2-intercept-smoke.R [options]",
      "",
      "Options:",
      "  --n-rep=N                 Replicates per provider (default: 1).",
      "  --seed-start=N            First replicate index (default: 1).",
      "  --seed-base=N             Seed base; seed = seed_base + replicate_index (default: 823000).",
      "  --providers=a,b,c         Providers to run (default: phylo,spatial,animal,relmat).",
      "  --estimands=a,b,c         Estimands to run (default: all q2 intercept targets).",
      "  --bootstrap=N             Bootstrap refits per target (default: 0 = record skipped attempts).",
      "  --profile-max-eval=N      Endpoint-profile evaluation budget (default: 60).",
      "  --interval-repair-channel=CHANNEL",
      "                            Diagnostic repair sidecar: none or bounded_tmbprofile_direct_correlation_sidecar.",
      "  --host-class=CLASS        Host class stamped into substitute-smoke artifacts.",
      "  --host-name=NAME          Host name stamped into substitute-smoke artifacts.",
      "  --output-dir=PATH         Artifact directory.",
      "  --overwrite=true          Replace an existing artifact directory and dashboard sidecar.",
      "  --write-dashboard=false   Do not write the dashboard summary sidecar.",
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

split_csv <- function(x) {
  out <- trimws(strsplit(x, ",", fixed = TRUE)[[1L]])
  out[nzchar(out)]
}

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
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

write_tsv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  character_cols <- vapply(x, is.character, logical(1L))
  x[character_cols] <- lapply(x[character_cols], clean_text)
  utils::write.table(
    x,
    file = path,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = "NA"
  )
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

script_file <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1L] %||% "tools"
)
repo_root <- normalizePath(file.path(dirname(script_file), ".."))
if (!file.exists(file.path(repo_root, "DESCRIPTION"))) {
  repo_root <- normalizePath(getwd())
}

rel_path <- function(path) {
  sub(paste0("^", gsub("([\\W])", "\\\\\\1", repo_root), "/?"), "", path)
}

n_rep <- as.integer(arg_value("n-rep", "1"))
if (!is.finite(n_rep) || n_rep < 1L) {
  stop("`--n-rep` must be a positive integer.", call. = FALSE)
}
seed_start <- as.integer(arg_value("seed-start", "1"))
if (!is.finite(seed_start) || seed_start < 1L) {
  stop("`--seed-start` must be a positive integer.", call. = FALSE)
}
seed_base <- as.integer(arg_value("seed-base", "823000"))
if (!is.finite(seed_base) || seed_base < 1L) {
  stop("`--seed-base` must be a positive integer.", call. = FALSE)
}
bootstrap_R <- as.integer(arg_value("bootstrap", "0"))
if (!is.finite(bootstrap_R) || bootstrap_R < 0L) {
  stop("`--bootstrap` must be a non-negative integer.", call. = FALSE)
}
profile_max_eval <- as.integer(arg_value("profile-max-eval", "60"))
if (!is.finite(profile_max_eval) || profile_max_eval < 1L) {
  stop("`--profile-max-eval` must be a positive integer.", call. = FALSE)
}
interval_repair_channel <- arg_value("interval-repair-channel", "none")
allowed_repair_channels <- c("none", "bounded_tmbprofile_direct_correlation_sidecar")
if (!interval_repair_channel %in% allowed_repair_channels) {
  stop(
    "`--interval-repair-channel` must be one of: ",
    paste(allowed_repair_channels, collapse = ", "),
    call. = FALSE
  )
}
overwrite <- arg_flag("overwrite", FALSE)
write_dashboard <- arg_flag("write-dashboard", TRUE)
host_name <- arg_value("host-name", unname(Sys.info()[["nodename"]]))
host_class <- arg_value("host-class", "local_rehearsal")
runtime_host_name <- unname(Sys.info()[["nodename"]])
slurm_cluster_name <- Sys.getenv("SLURM_CLUSTER_NAME", "")
slurm_job_id <- Sys.getenv("SLURM_JOB_ID", "")
run_root <- Sys.getenv("DRMTMB_RUN_ROOT", "NA")
metadata_dir <- Sys.getenv("DRMTMB_META_DIR", "NA")
log_dir <- Sys.getenv("DRMTMB_LOG_DIR", "NA")
host_gate_text <- tolower(paste(host_class, host_name, collapse = " "))
is_substitute_host <- grepl("nibi|rorqual", host_gate_text)
actual_cluster <- tolower(trimws(slurm_cluster_name))
is_cluster_runtime <- nzchar(actual_cluster) || nzchar(slurm_job_id)
is_allowed_substitute_runtime <- actual_cluster %in% c("nibi", "rorqual") &&
  nzchar(slurm_job_id)
is_blocked_cluster_host <- (
  is_cluster_runtime || grepl("drac|cluster|slurm", host_gate_text)
) && !is_allowed_substitute_runtime
if (is_blocked_cluster_host) {
  stop(
    "Cluster smoke is blocked unless the host is Nibi/Rorqual and the ",
    "smoke-substitution contract applies.",
    call. = FALSE
  )
}
if (is_substitute_host && !is_allowed_substitute_runtime) {
  stop(
    "Nibi/Rorqual substitute smoke requires SLURM runtime evidence from ",
    "cluster 'nibi' or 'rorqual'. Saw SLURM_CLUSTER_NAME='",
    slurm_cluster_name,
    "' and SLURM_JOB_ID='",
    slurm_job_id,
    "'.",
    call. = FALSE
  )
}
if (is_substitute_host && n_rep != 5L) {
  stop(
    "Nibi/Rorqual q2-intercept substitute smoke must use the exact n=5 contract.",
    call. = FALSE
  )
}
if (is_substitute_host && write_dashboard) {
  stop(
    "Nibi/Rorqual substitute smoke is artifact-only. Use ",
    "--write-dashboard=false, then import reviewed artifacts through a ",
    "validator-owned sidecar.",
    call. = FALSE
  )
}

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
contract_path <- file.path(
  dashboard_dir,
  "structured-re-q2-intercept-interval-contract.tsv"
)
smoke_substitution_contract_path <- file.path(
  dashboard_dir,
  "structured-re-q-series-smoke-substitution-contract.tsv"
)
dashboard_summary_path <- file.path(
  dashboard_dir,
  "structured-re-q2-intercept-local-smoke.tsv"
)
default_artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-29-q2-intercept-local-smoke"
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

artifact_stem <- if (is_substitute_host) {
  "structured-re-q2-intercept-substitute-smoke"
} else {
  "structured-re-q2-intercept-local-smoke"
}
replicate_path <- file.path(
  artifact_dir,
  paste0(artifact_stem, "-replicates.tsv")
)
summary_path <- file.path(
  artifact_dir,
  paste0(artifact_stem, ".tsv")
)
seed_manifest_path <- file.path(
  artifact_dir,
  paste0(artifact_stem, "-seed-manifest.tsv")
)
session_info_path <- file.path(artifact_dir, "sessionInfo.txt")
git_sha_path <- file.path(artifact_dir, "git-sha.txt")

load_drmTMB_for_q2_intercept <- function(path) {
  prefer_installed <- tolower(Sys.getenv("DRMTMB_RUN_INSTALLED", "")) %in%
    c("1", "true", "yes", "y")
  if (!prefer_installed && requireNamespace("devtools", quietly = TRUE)) {
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

load_drmTMB_for_q2_intercept(repo_root)

contract <- read_tsv(contract_path)
required_contract <- c(
  "contract_id",
  "cell_id",
  "provider",
  "target_kind",
  "endpoint_member",
  "estimand",
  "contract_status",
  "promotion_decision"
)
missing_contract <- setdiff(required_contract, names(contract))
if (length(missing_contract) > 0L) {
  stop(
    "Contract sidecar is missing fields: ",
    paste(missing_contract, collapse = ", "),
    call. = FALSE
  )
}
if (
  !all(
    contract$contract_status %in%
      c(
        "ready_for_totoro_fiia_n5_smoke",
        "nibi_substitute_smoke_reviewed_design_required",
        "contract_ready_no_compute"
      )
  )
) {
  stop(
    "Contract rows must be contract-ready, reviewed smoke-ready, or ",
    "reviewed-design-ready for retained-denominator pregrid.",
    call. = FALSE
  )
}
if (!all(contract$promotion_decision == "do_not_promote")) {
  stop(
    "All contract rows must keep promotion_decision = do_not_promote.",
    call. = FALSE
  )
}

provider_arg <- arg_value("providers", "phylo,spatial,animal,relmat")
selected_providers <- split_csv(provider_arg)
allowed_providers <- c("phylo", "spatial", "animal", "relmat")
unknown_providers <- setdiff(selected_providers, allowed_providers)
if (length(selected_providers) == 0L || length(unknown_providers) > 0L) {
  stop(
    "`--providers` must be a comma-separated subset of: phylo,spatial,animal,relmat.",
    call. = FALSE
  )
}
contract <- contract[contract$provider %in% selected_providers, , drop = FALSE]
if (!identical(sort(unique(contract$provider)), sort(selected_providers))) {
  stop("Contract sidecar does not cover all selected providers.", call. = FALSE)
}

estimand_arg <- arg_value(
  "estimands",
  "sd_mu1_intercept,sd_mu2_intercept,cor_mu1_mu2_intercept"
)
selected_estimands <- split_csv(estimand_arg)
allowed_estimands <- c(
  "sd_mu1_intercept",
  "sd_mu2_intercept",
  "cor_mu1_mu2_intercept"
)
unknown_estimands <- setdiff(selected_estimands, allowed_estimands)
if (length(selected_estimands) == 0L || length(unknown_estimands) > 0L) {
  stop(
    "`--estimands` must be a comma-separated subset of: ",
    "sd_mu1_intercept,sd_mu2_intercept,cor_mu1_mu2_intercept.",
    call. = FALSE
  )
}
contract <- contract[contract$estimand %in% selected_estimands, , drop = FALSE]
selected_contract_keys <- paste(
  rep(selected_providers, each = length(selected_estimands)),
  rep(selected_estimands, times = length(selected_providers))
)
contract_keys <- paste(contract$provider, contract$estimand)
if (!all(selected_contract_keys %in% contract_keys)) {
  stop(
    "Contract sidecar does not cover all selected provider/estimand pairs.",
    call. = FALSE
  )
}

if (is_substitute_host) {
  substitution_contract <- read_tsv(smoke_substitution_contract_path)
  required_substitution_fields <- c(
    "contract_id",
    "target_cells",
    "target_count",
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
  substitution_row <- substitution_contract[
    substitution_contract$contract_id ==
      "qseries_smoke_substitution_q2_intercept",
    ,
    drop = FALSE
  ]
  if (nrow(substitution_row) != 1L) {
    stop(
      "Smoke-substitution contract must have exactly one q2-intercept row.",
      call. = FALSE
    )
  }
  expected_cells <- paste(
    c(
      "qseries_phylo_q2_mu1_mu2_intercept",
      "qseries_spatial_q2_mu1_mu2_intercept",
      "qseries_animal_q2_mu1_mu2_intercept",
      "qseries_relmat_q2_mu1_mu2_intercept"
    ),
    collapse = ";"
  )
  if (substitution_row$target_cells[[1L]] != expected_cells) {
    stop(
      "q2-intercept substitute smoke must target exactly the four q2 ",
      "mu1+mu2 intercept cells.",
      call. = FALSE
    )
  }
  if (substitution_row$target_count[[1L]] != "12") {
    stop("q2-intercept substitute smoke target_count must be 12.", call. = FALSE)
  }
  for (phrase in c(
    "Nibi or Rorqual only",
    "contract_bounded_n5_smoke_only",
    "Fisher",
    "Rose",
    "Grace",
    "All attempted rows retained",
    "n=5 is smoke evidence, not coverage evidence",
    "DRAC denominator grids",
    "q2 slopes",
    "supported or inference_ready claims"
  )) {
    if (
      !any(vapply(
        substitution_row,
        function(column) grepl(phrase, column, fixed = TRUE),
        logical(1L)
      ))
    ) {
      stop(
        "q2-intercept smoke-substitution contract must mention `",
        phrase,
        "`.",
        call. = FALSE
      )
    }
  }
  if (substitution_row$promotion_decision[[1L]] != "do_not_promote") {
    stop(
      "q2-intercept smoke-substitution contract must not promote rows.",
      call. = FALSE
    )
  }
}

TRUTH <- list(
  mu1_intercept = 0.30,
  mu2_intercept = -0.15,
  sigma1 = 0.20,
  sigma2 = 0.22,
  rho12 = 0.00,
  sd_mu1_intercept = 0.70,
  sd_mu2_intercept = 0.55,
  cor_mu1_mu2_intercept = 0.25
)

balanced_tree <- function(n_tip = 8L) {
  edges <- matrix(integer(), ncol = 2L)
  edge_lengths <- numeric()
  next_node <- n_tip + 1L

  build <- function(tips) {
    if (length(tips) == 1L) {
      return(tips)
    }
    node <- next_node
    next_node <<- next_node + 1L
    mid <- length(tips) / 2L
    left <- build(tips[seq_len(mid)])
    right <- build(tips[seq.int(mid + 1L, length(tips))])
    edges <<- rbind(edges, c(node, left), c(node, right))
    edge_lengths <<- c(edge_lengths, 1, 1)
    node
  }

  build(seq_len(n_tip))
  structure(
    list(
      edge = edges,
      edge.length = edge_lengths,
      tip.label = paste0("sp_", seq_len(n_tip)),
      Nnode = n_tip - 1L
    ),
    class = "phylo"
  )
}

spatial_coords_and_K <- function(n = 8L) {
  labels <- paste0("site_", seq_len(n))
  theta <- seq(0, 1.5 * pi, length.out = n)
  coords <- data.frame(
    x = cos(theta) + seq_len(n) / (3 * n),
    y = sin(theta)
  )
  row.names(coords) <- labels
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = labels,
    group = "site"
  )
  list(
    labels = labels,
    coords = coords,
    K = solve(as.matrix(precision$precision))
  )
}

animal_K <- function() {
  pedigree <- data.frame(
    id = paste0("id", seq_len(8L)),
    dam = c(NA, NA, NA, NA, "id1", "id3", "id5", "id1"),
    sire = c(NA, NA, NA, NA, "id2", "id4", "id6", "id3"),
    stringsAsFactors = FALSE
  )
  K <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  list(K = K, labels = row.names(K))
}

relmat_K <- function(n_level = 8L) {
  labels <- paste0("id", seq_len(n_level))
  K <- outer(seq_len(n_level), seq_len(n_level), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(labels, labels)
  K
}

correlated_intercept_effects <- function(K, sd1, sd2, cor12) {
  endpoint_cov <- matrix(
    c(sd1^2, cor12 * sd1 * sd2, cor12 * sd1 * sd2, sd2^2),
    nrow = 2L
  )
  base <- t(chol(K)) %*% matrix(stats::rnorm(nrow(K) * 2L), nrow(K), 2L)
  out <- base %*% chol(endpoint_cov)
  colnames(out) <- c("mu1_intercept", "mu2_intercept")
  out
}

make_q2_intercept_data <- function(provider, seed, n_each = 16L) {
  set.seed(seed)
  n_groups <- 8L
  if (identical(provider, "phylo")) {
    tree <- balanced_tree(n_groups)
    labels <- tree$tip.label
    K <- drmTMB:::drm_phylo_tip_covariance(tree)
    group <- "species"
    extra <- list(tree = tree)
  } else if (identical(provider, "spatial")) {
    sp <- spatial_coords_and_K(n_groups)
    labels <- sp$labels
    K <- sp$K
    group <- "site"
    extra <- list(coords = sp$coords)
  } else if (identical(provider, "animal")) {
    ak <- animal_K()
    K <- ak$K
    labels <- ak$labels
    group <- "id"
    extra <- list(A = K)
  } else if (identical(provider, "relmat")) {
    K <- relmat_K(n_groups)
    labels <- row.names(K)
    group <- "id"
    extra <- list(K = K)
  } else {
    stop("Unknown provider: ", provider, call. = FALSE)
  }

  effects <- correlated_intercept_effects(
    K,
    sd1 = TRUTH$sd_mu1_intercept,
    sd2 = TRUTH$sd_mu2_intercept,
    cor12 = TRUTH$cor_mu1_mu2_intercept
  )
  row.names(effects) <- labels
  endpoint <- rep(labels, each = n_each)
  eta1 <- TRUTH$mu1_intercept + effects[endpoint, "mu1_intercept"]
  eta2 <- TRUTH$mu2_intercept + effects[endpoint, "mu2_intercept"]
  res_cov <- matrix(
    c(
      TRUTH$sigma1^2,
      TRUTH$rho12 * TRUTH$sigma1 * TRUTH$sigma2,
      TRUTH$rho12 * TRUTH$sigma1 * TRUTH$sigma2,
      TRUTH$sigma2^2
    ),
    nrow = 2L
  )
  residual <- matrix(stats::rnorm(length(endpoint) * 2L), ncol = 2L) %*%
    chol(res_cov)
  dat <- data.frame(
    y1 = eta1 + residual[, 1L],
    y2 = eta2 + residual[, 2L],
    stringsAsFactors = FALSE
  )
  dat[[group]] <- endpoint
  c(list(data = dat, group = group, K = K, labels = labels), extra)
}

fit_q2_intercept <- function(provider, sim) {
  if (identical(provider, "phylo")) {
    tree <- sim$tree
    form <- bf(
      mu1 = y1 ~ phylo(1 | p | species, tree = tree),
      mu2 = y2 ~ phylo(1 | p | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    )
  } else if (identical(provider, "spatial")) {
    coords <- sim$coords
    form <- bf(
      mu1 = y1 ~ spatial(1 | p | site, coords = coords),
      mu2 = y2 ~ spatial(1 | p | site, coords = coords),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    )
  } else if (identical(provider, "animal")) {
    A <- sim$A
    form <- bf(
      mu1 = y1 ~ animal(1 | p | id, A = A),
      mu2 = y2 ~ animal(1 | p | id, A = A),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    )
  } else if (identical(provider, "relmat")) {
    K <- sim$K
    form <- bf(
      mu1 = y1 ~ relmat(1 | p | id, K = K),
      mu2 = y2 ~ relmat(1 | p | id, K = K),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    )
  }

  drmTMB(
    form,
    family = biv_gaussian(),
    data = sim$data,
    control = drm_control(optimizer = list(eval.max = 1600, iter.max = 1600))
  )
}

group_for <- function(provider) {
  switch(
    provider,
    phylo = "species",
    spatial = "site",
    animal = "id",
    relmat = "id"
  )
}

parm_name_for <- function(provider, endpoint_member) {
  grp <- group_for(provider)
  if (identical(endpoint_member, "mu1:(Intercept)")) {
    return(paste0("sd:mu:mu1:", provider, "(1 | p | ", grp, ")"))
  }
  if (identical(endpoint_member, "mu2:(Intercept)")) {
    return(paste0("sd:mu:mu2:", provider, "(1 | p | ", grp, ")"))
  }
  paste0(
    "cor:",
    provider,
    ":cor(mu1:(Intercept),mu2:(Intercept) | p | ",
    grp,
    ")"
  )
}

truth_for <- function(estimand) {
  switch(
    estimand,
    sd_mu1_intercept = TRUTH$sd_mu1_intercept,
    sd_mu2_intercept = TRUTH$sd_mu2_intercept,
    cor_mu1_mu2_intercept = TRUTH$cor_mu1_mu2_intercept,
    stop("Unknown estimand: ", estimand, call. = FALSE)
  )
}

extract_estimate <- function(fit, provider, endpoint_member) {
  grp <- group_for(provider)
  tryCatch(
    {
      if (identical(endpoint_member, "mu1:(Intercept)")) {
        key <- paste0("mu1:", provider, "(1 | p | ", grp, ")")
        return(unname(fit$sdpars$mu[[key]]))
      }
      if (identical(endpoint_member, "mu2:(Intercept)")) {
        key <- paste0("mu2:", provider, "(1 | p | ", grp, ")")
        return(unname(fit$sdpars$mu[[key]]))
      }
      cp <- fit$corpars[[provider]]
      if (!is.null(cp)) {
        key <- paste0("cor(mu1:(Intercept),mu2:(Intercept) | p | ", grp, ")")
        if (key %in% names(cp)) {
          return(unname(cp[[key]]))
        }
        if (length(cp) >= 1L) {
          return(unname(cp[[1L]]))
        }
      }
      NA_real_
    },
    error = function(e) NA_real_
  )
}

run_wald <- function(fit, parm_name) {
  warnings_cap <- character()
  result <- withCallingHandlers(
    tryCatch(
      stats::confint(fit, parm = parm_name, method = "wald", level = 0.95),
      error = function(e) e
    ),
    warning = function(w) {
      warnings_cap <<- c(warnings_cap, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  if (inherits(result, "error")) {
    return(list(
      lower = NA_real_,
      upper = NA_real_,
      status = "error",
      message = clean_text(conditionMessage(result)),
      warnings = clean_text(paste(warnings_cap, collapse = "; "))
    ))
  }
  if (is.data.frame(result) && nrow(result) == 0L) {
    return(list(
      lower = NA_real_,
      upper = NA_real_,
      status = "parm_not_found",
      message = paste0("wald: parm not found: ", parm_name),
      warnings = clean_text(paste(warnings_cap, collapse = "; "))
    ))
  }
  lower <- result$lower[[1L]]
  upper <- result$upper[[1L]]
  list(
    lower = lower,
    upper = upper,
    status = if (is.finite(lower) && is.finite(upper)) {
      "finite"
    } else {
      "nonfinite"
    },
    message = NA_character_,
    warnings = clean_text(paste(warnings_cap, collapse = "; "))
  )
}

run_profile <- function(fit, parm_name) {
  warnings_cap <- character()
  result <- withCallingHandlers(
    tryCatch(
      stats::confint(
        fit,
        parm = parm_name,
        method = "profile",
        level = 0.95,
        profile_engine = "endpoint",
        trace = FALSE,
        profile_endpoint_max_eval = profile_max_eval
      ),
      error = function(e) e
    ),
    warning = function(w) {
      warnings_cap <<- c(warnings_cap, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  if (inherits(result, "error")) {
    return(list(
      lower = NA_real_,
      upper = NA_real_,
      status = "error",
      conf_status = NA_character_,
      message = clean_text(conditionMessage(result)),
      warnings = clean_text(paste(warnings_cap, collapse = "; "))
    ))
  }
  if (is.data.frame(result) && nrow(result) == 0L) {
    return(list(
      lower = NA_real_,
      upper = NA_real_,
      status = "parm_not_found",
      conf_status = NA_character_,
      message = paste0("profile: parm not found: ", parm_name),
      warnings = clean_text(paste(warnings_cap, collapse = "; "))
    ))
  }
  lower <- result$lower[[1L]]
  upper <- result$upper[[1L]]
  finite <- is.finite(lower) && is.finite(upper)
  list(
    lower = lower,
    upper = upper,
    status = if (finite) "finite" else "nonfinite",
    conf_status = if ("conf.status" %in% names(result)) {
      clean_text(as.character(result$conf.status[[1L]]))
    } else {
      NA_character_
    },
    message = if ("profile.message" %in% names(result)) {
      clean_text(as.character(result$profile.message[[1L]]))
    } else {
      NA_character_
    },
    warnings = clean_text(paste(warnings_cap, collapse = "; "))
  )
}

run_interval_repair <- function(fit, parm_name, target_kind) {
  if (
    !identical(interval_repair_channel, "bounded_tmbprofile_direct_correlation_sidecar") ||
      !identical(target_kind, "direct_correlation")
  ) {
    return(list(
      lower = NA_real_,
      upper = NA_real_,
      status = "skipped",
      conf_status = NA_character_,
      message = "repair_channel_not_requested_for_target",
      warnings = NA_character_
    ))
  }
  warnings_cap <- character()
  result <- withCallingHandlers(
    tryCatch(
      stats::confint(
        fit,
        parm = parm_name,
        method = "profile",
        level = 0.95,
        profile_engine = "tmbprofile",
        profile_precision = "fast",
        trace = FALSE
      ),
      error = function(e) e
    ),
    warning = function(w) {
      warnings_cap <<- c(warnings_cap, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  if (inherits(result, "error")) {
    return(list(
      lower = NA_real_,
      upper = NA_real_,
      status = "error",
      conf_status = NA_character_,
      message = clean_text(conditionMessage(result)),
      warnings = clean_text(paste(warnings_cap, collapse = "; "))
    ))
  }
  if (is.data.frame(result) && nrow(result) == 0L) {
    return(list(
      lower = NA_real_,
      upper = NA_real_,
      status = "parm_not_found",
      conf_status = NA_character_,
      message = paste0("repair_tmbprofile: parm not found: ", parm_name),
      warnings = clean_text(paste(warnings_cap, collapse = "; "))
    ))
  }
  lower <- result$lower[[1L]]
  upper <- result$upper[[1L]]
  finite <- is.finite(lower) && is.finite(upper)
  list(
    lower = lower,
    upper = upper,
    status = if (finite) "finite" else "nonfinite",
    conf_status = if ("conf.status" %in% names(result)) {
      clean_text(as.character(result$conf.status[[1L]]))
    } else {
      "tmbprofile"
    },
    message = if ("profile.message" %in% names(result)) {
      clean_text(as.character(result$profile.message[[1L]]))
    } else {
      NA_character_
    },
    warnings = clean_text(paste(warnings_cap, collapse = "; "))
  )
}

profile_repair_channel_for <- function(target_kind) {
  if (identical(target_kind, "direct_sd")) {
    return("endpoint_zero_boundary_profile_channel")
  }
  "existing_endpoint_profile_channel"
}

profile_repair_candidate_for <- function(target_kind) {
  if (identical(target_kind, "direct_sd")) {
    return("q2_direct_sd_endpoint_zero_boundary_profile_smoke")
  }
  "q2_direct_correlation_existing_profile_smoke"
}

run_bootstrap <- function(fit, parm_name) {
  if (bootstrap_R <= 0L) {
    return(list(
      lower = NA_real_,
      upper = NA_real_,
      status = "skipped",
      message = "bootstrap_off",
      warnings = NA_character_
    ))
  }
  warnings_cap <- character()
  result <- withCallingHandlers(
    tryCatch(
      stats::confint(
        fit,
        parm = parm_name,
        method = "bootstrap",
        level = 0.95,
        R = bootstrap_R,
        seed = 42L
      ),
      error = function(e) e
    ),
    warning = function(w) {
      warnings_cap <<- c(warnings_cap, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  if (inherits(result, "error")) {
    return(list(
      lower = NA_real_,
      upper = NA_real_,
      status = "error",
      message = clean_text(conditionMessage(result)),
      warnings = clean_text(paste(warnings_cap, collapse = "; "))
    ))
  }
  if (is.data.frame(result) && nrow(result) == 0L) {
    return(list(
      lower = NA_real_,
      upper = NA_real_,
      status = "parm_not_found",
      message = paste0("bootstrap: parm not found: ", parm_name),
      warnings = clean_text(paste(warnings_cap, collapse = "; "))
    ))
  }
  lower <- result$lower[[1L]]
  upper <- result$upper[[1L]]
  list(
    lower = lower,
    upper = upper,
    status = if (is.finite(lower) && is.finite(upper)) {
      "finite"
    } else {
      "nonfinite"
    },
    message = NA_character_,
    warnings = clean_text(paste(warnings_cap, collapse = "; "))
  )
}

covers <- function(truth, lower, upper) {
  if (is.finite(lower) && is.finite(upper)) {
    truth >= lower && truth <= upper
  } else {
    NA
  }
}

empty_target_row <- function(
  contract_row,
  replicate_index,
  seed,
  attempt_status,
  message
) {
  truth <- truth_for(contract_row$estimand[[1L]])
  parm <- parm_name_for(
    contract_row$provider[[1L]],
    contract_row$endpoint_member[[1L]]
  )
  data.frame(
    smoke_id = paste0(contract_row$contract_id[[1L]], "_rep", replicate_index),
    contract_id = contract_row$contract_id[[1L]],
    cell_id = contract_row$cell_id[[1L]],
    provider = contract_row$provider[[1L]],
    target_kind = contract_row$target_kind[[1L]],
    endpoint_member = contract_row$endpoint_member[[1L]],
    estimand = contract_row$estimand[[1L]],
    replicate_index = replicate_index,
    seed = seed,
    target_parm = parm,
    truth_value = truth,
    attempt_status = attempt_status,
    message = clean_text(message),
    convergence = NA_integer_,
    pdHess = NA,
    estimate = NA_real_,
    profile_repair_candidate = profile_repair_candidate_for(
      contract_row$target_kind[[1L]]
    ),
    profile_channel = profile_repair_channel_for(contract_row$target_kind[[1L]]),
    profile_endpoint_max_eval = profile_max_eval,
    wald_lower = NA_real_,
    wald_upper = NA_real_,
    wald_status = NA_character_,
    wald_message = NA_character_,
    wald_warnings = NA_character_,
    wald_contains = NA,
    profile_lower = NA_real_,
    profile_upper = NA_real_,
    profile_status = NA_character_,
    profile_conf_status = NA_character_,
    profile_message = NA_character_,
    profile_warnings = NA_character_,
    profile_contains = NA,
    repair_channel = interval_repair_channel,
    repair_lower = NA_real_,
    repair_upper = NA_real_,
    repair_status = "skipped",
    repair_conf_status = NA_character_,
    repair_message = clean_text(message),
    repair_warnings = NA_character_,
    repair_contains = NA,
    bootstrap_lower = NA_real_,
    bootstrap_upper = NA_real_,
    bootstrap_status = NA_character_,
    bootstrap_message = NA_character_,
    bootstrap_warnings = NA_character_,
    bootstrap_contains = NA,
    elapsed_sec = NA_real_,
    stringsAsFactors = FALSE
  )
}

run_provider_replicate <- function(
  provider,
  provider_contract,
  replicate_index,
  seed
) {
  sim <- tryCatch(
    make_q2_intercept_data(provider, seed),
    error = function(e) e
  )
  if (inherits(sim, "error")) {
    return(do.call(
      rbind,
      lapply(
        seq_len(nrow(provider_contract)),
        function(i) {
          empty_target_row(
            provider_contract[i, , drop = FALSE],
            replicate_index,
            seed,
            "sim_error",
            conditionMessage(sim)
          )
        }
      )
    ))
  }

  warnings_fit <- character()
  t_elapsed <- system.time({
    fit <- withCallingHandlers(
      tryCatch(
        fit_q2_intercept(provider, sim),
        error = function(e) e
      ),
      warning = function(w) {
        warnings_fit <<- c(warnings_fit, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
  })
  if (inherits(fit, "error")) {
    return(do.call(
      rbind,
      lapply(
        seq_len(nrow(provider_contract)),
        function(i) {
          empty_target_row(
            provider_contract[i, , drop = FALSE],
            replicate_index,
            seed,
            "fit_error",
            conditionMessage(fit)
          )
        }
      )
    ))
  }

  conv <- fit$opt$convergence
  pd_hess <- isTRUE(fit$sdr$pdHess)
  do.call(
    rbind,
    lapply(seq_len(nrow(provider_contract)), function(i) {
      contract_row <- provider_contract[i, , drop = FALSE]
      truth <- truth_for(contract_row$estimand[[1L]])
      parm <- parm_name_for(provider, contract_row$endpoint_member[[1L]])
      est <- extract_estimate(fit, provider, contract_row$endpoint_member[[1L]])
      wi <- run_wald(fit, parm)
      pi <- run_profile(fit, parm)
      ri <- run_interval_repair(fit, parm, contract_row$target_kind[[1L]])
      bi <- run_bootstrap(fit, parm)
      data.frame(
        smoke_id = paste0(
          contract_row$contract_id[[1L]],
          "_rep",
          replicate_index
        ),
        contract_id = contract_row$contract_id[[1L]],
        cell_id = contract_row$cell_id[[1L]],
        provider = provider,
        target_kind = contract_row$target_kind[[1L]],
        endpoint_member = contract_row$endpoint_member[[1L]],
        estimand = contract_row$estimand[[1L]],
        replicate_index = replicate_index,
        seed = seed,
        target_parm = parm,
        truth_value = truth,
        attempt_status = "fit_ok",
        message = clean_text(paste(warnings_fit, collapse = "; ")),
        convergence = conv,
        pdHess = pd_hess,
        estimate = if (is.null(est) || length(est) == 0L) NA_real_ else est,
        profile_repair_candidate = profile_repair_candidate_for(
          contract_row$target_kind[[1L]]
        ),
        profile_channel = profile_repair_channel_for(
          contract_row$target_kind[[1L]]
        ),
        profile_endpoint_max_eval = profile_max_eval,
        wald_lower = wi$lower,
        wald_upper = wi$upper,
        wald_status = wi$status,
        wald_message = wi$message,
        wald_warnings = wi$warnings,
        wald_contains = covers(truth, wi$lower, wi$upper),
        profile_lower = pi$lower,
        profile_upper = pi$upper,
        profile_status = pi$status,
        profile_conf_status = pi$conf_status,
        profile_message = pi$message,
        profile_warnings = pi$warnings,
        profile_contains = covers(truth, pi$lower, pi$upper),
        repair_channel = interval_repair_channel,
        repair_lower = ri$lower,
        repair_upper = ri$upper,
        repair_status = ri$status,
        repair_conf_status = ri$conf_status,
        repair_message = ri$message,
        repair_warnings = ri$warnings,
        repair_contains = covers(truth, ri$lower, ri$upper),
        bootstrap_lower = bi$lower,
        bootstrap_upper = bi$upper,
        bootstrap_status = bi$status,
        bootstrap_message = bi$message,
        bootstrap_warnings = bi$warnings,
        bootstrap_contains = covers(truth, bi$lower, bi$upper),
        elapsed_sec = unname(t_elapsed[["elapsed"]]),
        stringsAsFactors = FALSE
      )
    })
  )
}

seed_manifest <- expand.grid(
  provider = selected_providers,
  replicate_index = seq(from = seed_start, length.out = n_rep),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
seed_manifest$seed <- seed_base + seed_manifest$replicate_index
seed_manifest$seed_role <- if (is_substitute_host) {
  "q2_intercept_substitute_smoke"
} else {
  "q2_intercept_local_smoke"
}
seed_manifest$execution_status <- "executed"
seed_manifest$host_class <- host_class
seed_manifest$host_name <- host_name
seed_manifest$runtime_host_name <- runtime_host_name
seed_manifest$slurm_cluster_name <- slurm_cluster_name
seed_manifest$slurm_job_id <- slurm_job_id
seed_manifest$selected_estimands <- paste(selected_estimands, collapse = ";")
seed_manifest$interval_repair_channel <- interval_repair_channel
if (is_substitute_host) {
  seed_manifest$source_substitution_contract <- rel_path(
    smoke_substitution_contract_path
  )
  seed_manifest$source_substitution_contract_id <-
    "qseries_smoke_substitution_q2_intercept"
}
write_tsv(seed_manifest, seed_manifest_path)

replicate_rows <- list()
row_i <- 1L
for (provider in selected_providers) {
  provider_contract <- contract[contract$provider == provider, , drop = FALSE]
  provider_contract <- provider_contract[
    match(selected_estimands, provider_contract$estimand),
    ,
    drop = FALSE
  ]
  for (replicate_index in seq(from = seed_start, length.out = n_rep)) {
    seed <- seed_base + replicate_index
    replicate_rows[[row_i]] <- run_provider_replicate(
      provider,
      provider_contract,
      replicate_index,
      seed
    )
    row_i <- row_i + 1L
  }
}
replicates <- do.call(rbind, replicate_rows)
row.names(replicates) <- NULL
replicates$host_class <- host_class
replicates$host_name <- host_name
replicates$runtime_host_name <- runtime_host_name
replicates$slurm_cluster_name <- slurm_cluster_name
replicates$slurm_job_id <- slurm_job_id
if (is_substitute_host) {
  replicates$source_substitution_contract <- rel_path(
    smoke_substitution_contract_path
  )
  replicates$source_substitution_contract_id <-
    "qseries_smoke_substitution_q2_intercept"
}

summaries <- lapply(split(replicates, replicates$contract_id), function(x) {
  contract_row <- contract[
    contract$contract_id == x$contract_id[[1L]],
    ,
    drop = FALSE
  ]
  fit_rows <- x[x$attempt_status == "fit_ok", , drop = FALSE]
  n_fit_ok <- nrow(fit_rows)
  n_converged <- sum(!is.na(fit_rows$convergence) & fit_rows$convergence == 0L)
  n_pdhess <- sum(!is.na(fit_rows$pdHess) & fit_rows$pdHess)
  n_wald_finite <- sum(fit_rows$wald_status == "finite", na.rm = TRUE)
  n_profile_finite <- sum(fit_rows$profile_status == "finite", na.rm = TRUE)
  n_repair_attempted <- sum(
    fit_rows$repair_status != "skipped",
    na.rm = TRUE
  )
  n_repair_finite <- sum(fit_rows$repair_status == "finite", na.rm = TRUE)
  n_bootstrap_attempted <- sum(
    fit_rows$bootstrap_status != "skipped",
    na.rm = TRUE
  )
    n_bootstrap_finite <- sum(fit_rows$bootstrap_status == "finite", na.rm = TRUE)
    profile_repair_candidate <- paste(
      unique(fit_rows$profile_repair_candidate),
      collapse = ";"
    )
    profile_channel <- paste(unique(fit_rows$profile_channel), collapse = ";")
    repair_channel <- paste(unique(fit_rows$repair_channel), collapse = ";")
    wald_contains <- fit_rows$wald_contains
  profile_contains <- fit_rows$profile_contains
  repair_contains <- fit_rows$repair_contains
  wald_lower_miss <- sum(
    !is.na(fit_rows$wald_lower) & fit_rows$truth_value < fit_rows$wald_lower
  )
  wald_upper_miss <- sum(
    !is.na(fit_rows$wald_upper) & fit_rows$truth_value > fit_rows$wald_upper
  )
  profile_lower_miss <- sum(
    !is.na(fit_rows$profile_lower) &
      fit_rows$truth_value < fit_rows$profile_lower
  )
  profile_upper_miss <- sum(
    !is.na(fit_rows$profile_upper) &
      fit_rows$truth_value > fit_rows$profile_upper
  )
  repair_lower_miss <- sum(
    !is.na(fit_rows$repair_lower) &
      fit_rows$truth_value < fit_rows$repair_lower
  )
  repair_upper_miss <- sum(
    !is.na(fit_rows$repair_upper) &
      fit_rows$truth_value > fit_rows$repair_upper
  )
  smoke_passed <- n_fit_ok == n_rep &&
    n_converged == n_rep &&
    n_pdhess == n_rep &&
    n_wald_finite == n_rep &&
    n_profile_finite == n_rep
  next_gate <- if (smoke_passed) {
    if (is_substitute_host) {
      paste(
        "Fisher/Rose must review the Nibi/Rorqual q2-intercept substitute-host",
        "smoke artifact before any denominator work; q2 slopes, q2-plus-q2,",
        "q4/q8, and non-Gaussian rows remain blocked."
      )
    } else {
      paste(
        "Fisher/Rose must review the local q2 intercept smoke before any",
        "Totoro/FIIA smoke; Nibi/Rorqual/DRAC remain blocked for denominator work."
      )
    }
  } else {
    if (is_substitute_host) {
      paste(
        "Repair or explain the Nibi/Rorqual q2-intercept substitute-host",
        "smoke failure before any denominator work; q2 slopes, q2-plus-q2,",
        "q4/q8, and non-Gaussian rows remain blocked."
      )
    } else {
      paste(
        "Repair or explain the local q2 intercept smoke failure before",
        "Totoro/FIIA; Nibi/Rorqual/DRAC remain blocked for denominator work."
      )
    }
  }
  data.frame(
    smoke_id = paste0(
      if (is_substitute_host) {
        "q2_intercept_substitute_smoke_"
      } else {
        "q2_intercept_local_smoke_"
      },
      x$contract_id[[1L]]
    ),
    contract_id = x$contract_id[[1L]],
    cell_id = x$cell_id[[1L]],
    provider = x$provider[[1L]],
    target_kind = x$target_kind[[1L]],
    endpoint_member = x$endpoint_member[[1L]],
    estimand = x$estimand[[1L]],
      target_parm = x$target_parm[[1L]],
      profile_repair_candidate = profile_repair_candidate,
      profile_channel = profile_channel,
      repair_channel = repair_channel,
      profile_endpoint_max_eval = profile_max_eval,
      artifact_dir = rel_path(artifact_dir),
    n_rep = nrow(x),
    n_fit_ok = n_fit_ok,
    n_fit_error = sum(x$attempt_status == "fit_error"),
    n_sim_error = sum(x$attempt_status == "sim_error"),
    n_converged = n_converged,
    n_pdhess = n_pdhess,
    n_wald_finite = n_wald_finite,
    n_profile_finite = n_profile_finite,
    n_repair_attempted = n_repair_attempted,
    n_repair_finite = n_repair_finite,
    n_bootstrap_attempted = n_bootstrap_attempted,
    n_bootstrap_finite = n_bootstrap_finite,
    wald_coverage_smoke = fmt4(mean(wald_contains, na.rm = TRUE)),
    wald_mcse_smoke = fmt6(mcse_proportion(wald_contains)),
    profile_coverage_smoke = fmt4(mean(profile_contains, na.rm = TRUE)),
    profile_mcse_smoke = fmt6(mcse_proportion(profile_contains)),
    repair_coverage_smoke = fmt4(mean(repair_contains, na.rm = TRUE)),
    repair_mcse_smoke = fmt6(mcse_proportion(repair_contains)),
    lower_miss = wald_lower_miss,
    upper_miss = wald_upper_miss,
    wald_lower_miss = wald_lower_miss,
    wald_upper_miss = wald_upper_miss,
    profile_lower_miss = profile_lower_miss,
    profile_upper_miss = profile_upper_miss,
    repair_lower_miss = repair_lower_miss,
    repair_upper_miss = repair_upper_miss,
    smoke_status = if (smoke_passed) {
      if (is_substitute_host) {
        "nibi_rorqual_substitute_smoke_passed"
      } else {
        "local_smoke_passed"
      }
    } else {
      if (is_substitute_host) {
        "nibi_rorqual_substitute_smoke_failed"
      } else {
        "local_smoke_failed"
      }
    },
    promotion_decision = "do_not_promote",
    source_contract = rel_path(contract_path),
    host_class = host_class,
    host_name = host_name,
    runtime_host_name = runtime_host_name,
    slurm_cluster_name = slurm_cluster_name,
    slurm_job_id = slurm_job_id,
    run_root = run_root,
    metadata_dir = metadata_dir,
    log_dir = log_dir,
    source_substitution_contract = if (is_substitute_host) {
      rel_path(smoke_substitution_contract_path)
    } else {
      "NA"
    },
    source_substitution_contract_id = if (is_substitute_host) {
      "qseries_smoke_substitution_q2_intercept"
    } else {
      "NA"
    },
    evidence_url = rel_path(artifact_dir),
    claim_boundary = if (is_substitute_host) {
      paste(
        "Q2 intercept Nibi/Rorqual substitute-host smoke only; this promotes",
        "exactly no Q-Series row; n=5 is smoke not coverage evidence; it does",
        "not change interval_status, coverage_status, inference_ready,",
        "supported, q2 slope, q2-plus-q2, q4/q8, non-Gaussian, REML, AI-REML,",
        "bridge support, DRAC denominator evidence, or public support."
      )
    } else {
      paste(
        "Q2 intercept local smoke only; this promotes exactly no Q-Series row;",
        "n is smoke not coverage evidence; it does not change interval_status,",
        "coverage_status, inference_ready, supported, q2 slope, q2-plus-q2,",
        "q4/q8, non-Gaussian, REML, AI-REML, bridge support, or public support."
      )
    },
    next_gate = next_gate,
    stringsAsFactors = FALSE
  )
})
summary <- do.call(rbind, summaries)
summary <- summary[
  match(contract$contract_id, summary$contract_id),
  ,
  drop = FALSE
]
row.names(summary) <- NULL

write_tsv(replicates, replicate_path)
write_tsv(summary, summary_path)
if (write_dashboard) {
  write_tsv(summary, dashboard_summary_path)
}
writeLines(capture.output(sessionInfo()), session_info_path)
git_sha <- Sys.getenv("DRMTMB_GIT_SHA", "")
if (!nzchar(git_sha)) {
  git_sha <- tryCatch(
    system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE),
    error = function(e) paste("git-sha-unavailable:", conditionMessage(e))
  )
}
writeLines(git_sha, git_sha_path)

message(
  "Wrote ",
  nrow(summary),
  if (is_substitute_host) {
    " q2 intercept substitute-smoke summary rows to "
  } else {
    " q2 intercept local-smoke summary rows to "
  },
  rel_path(summary_path)
)
if (write_dashboard) {
  message("Updated dashboard sidecar: ", rel_path(dashboard_summary_path))
}
message(
  "Wrote ",
  nrow(replicates),
  if (is_substitute_host) {
    " q2 intercept substitute-smoke replicate rows to "
  } else {
    " q2 intercept local-smoke replicate rows to "
  },
  rel_path(replicate_path)
)

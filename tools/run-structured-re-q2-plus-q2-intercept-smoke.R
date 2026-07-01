#!/usr/bin/env Rscript
#
# Local q2-plus-q2 intercept smoke runner.
#
# This runner executes the local-only gate for the phylo q2-plus-q2
# mu1+mu2;sigma1+sigma2 intercept row. It is deliberately not a coverage grid:
# every attempted target is retained, cross-block correlations stay blocked in
# the contract, and the summary promotes no Q-Series row.

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/run-structured-re-q2-plus-q2-intercept-smoke.R [options]",
      "",
      "Options:",
      "  --n-rep=N                 Replicates (default: 1).",
      "  --seed-start=N            First replicate index (default: 1).",
      "  --seed-base=N             Seed base; seed = seed_base + replicate_index (default: 823000).",
      "  --bootstrap=N             Bootstrap refits per target (default: 0 = record skipped attempts).",
      "  --profile-max-eval=N      Endpoint-profile evaluation budget (default: 80).",
      "  --interval-repair-channel=CHANNEL",
      "                            Diagnostic repair sidecar: none or bounded_tmbprofile_direct_correlation_sidecar.",
      "  --n-each=N                Observations per phylo tip (default: 50).",
      "  --contract-ids=a,b        Optional direct-target contract_id subset.",
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
  if (is.null(x) || !nzchar(x)) {
    return(character())
  }
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

positive_integer_arg <- function(name, default) {
  value <- as.integer(arg_value(name, default))
  if (!is.finite(value) || value < 1L) {
    stop("`--", name, "` must be a positive integer.", call. = FALSE)
  }
  value
}

n_rep <- positive_integer_arg("n-rep", "1")
seed_start <- positive_integer_arg("seed-start", "1")
seed_base <- positive_integer_arg("seed-base", "823000")
n_each <- positive_integer_arg("n-each", "50")
bootstrap_R <- as.integer(arg_value("bootstrap", "0"))
if (!is.finite(bootstrap_R) || bootstrap_R < 0L) {
  stop("`--bootstrap` must be a non-negative integer.", call. = FALSE)
}
profile_max_eval <- positive_integer_arg("profile-max-eval", "80")
interval_repair_channel <- arg_value("interval-repair-channel", "none")
allowed_repair_channels <- c("none", "bounded_tmbprofile_direct_correlation_sidecar")
if (!interval_repair_channel %in% allowed_repair_channels) {
  stop(
    "`--interval-repair-channel` must be one of: ",
    paste(allowed_repair_channels, collapse = ", "),
    call. = FALSE
  )
}
selected_contract_ids <- split_csv(arg_value("contract-ids", ""))
overwrite <- arg_flag("overwrite", FALSE)
write_dashboard <- arg_flag("write-dashboard", TRUE)
host_name <- arg_value("host-name", unname(Sys.info()[["nodename"]]))
host_class <- arg_value("host-class", "local_rehearsal")
host_gate_text <- tolower(paste(host_class, host_name, collapse = " "))
is_substitute_host <- grepl("nibi|rorqual", host_gate_text)
is_blocked_cluster_host <- grepl("drac|cluster|slurm", host_gate_text) &&
  !is_substitute_host
if (is_blocked_cluster_host) {
  stop(
    "Cluster smoke is blocked unless the host is Nibi/Rorqual and the ",
    "smoke-substitution contract applies.",
    call. = FALSE
  )
}
if (is_substitute_host && n_rep != 5L) {
  stop(
    "Nibi/Rorqual q2-plus-q2 substitute smoke must use the exact n=5 contract.",
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
  "structured-re-q2-plus-q2-intercept-contract.tsv"
)
smoke_substitution_contract_path <- file.path(
  dashboard_dir,
  "structured-re-q-series-smoke-substitution-contract.tsv"
)
dashboard_summary_path <- file.path(
  dashboard_dir,
  "structured-re-q2-plus-q2-intercept-local-smoke.tsv"
)
default_artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-29-q2-plus-q2-intercept-local-smoke"
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

replicate_path <- file.path(
  artifact_dir,
  "structured-re-q2-plus-q2-intercept-local-smoke-replicates.tsv"
)
summary_path <- file.path(
  artifact_dir,
  "structured-re-q2-plus-q2-intercept-local-smoke.tsv"
)
seed_manifest_path <- file.path(
  artifact_dir,
  "structured-re-q2-plus-q2-intercept-local-smoke-seed-manifest.tsv"
)
session_info_path <- file.path(artifact_dir, "sessionInfo.txt")
git_sha_path <- file.path(artifact_dir, "git-sha.txt")

load_drmTMB_for_q2_plus_q2 <- function(path) {
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

load_drmTMB_for_q2_plus_q2(repo_root)

contract <- read_tsv(contract_path)
required_contract <- c(
  "contract_id",
  "cell_id",
  "provider",
  "target_kind",
  "endpoint_member",
  "estimand",
  "profile_target",
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
        "nibi_substitute_smoke_reviewed_profile_hold",
        "contract_ready_no_compute",
        "blocked_not_interval_target"
      )
  )
) {
  stop("Contract rows must be contract-ready or blocked.", call. = FALSE)
}
if (!all(contract$promotion_decision == "do_not_promote")) {
  stop(
    "All contract rows must keep promotion_decision = do_not_promote.",
    call. = FALSE
  )
}
contract_direct <- contract[
  contract$target_kind %in% c("direct_sd", "direct_correlation"),
  ,
  drop = FALSE
]
if (nrow(contract_direct) != 6L) {
  stop(
    "q2-plus-q2 local smoke expects exactly six within-block targets.",
    call. = FALSE
  )
}
if (length(selected_contract_ids) > 0L) {
  unknown_contract_ids <- setdiff(
    selected_contract_ids,
    contract_direct$contract_id
  )
  if (length(unknown_contract_ids) > 0L) {
    stop(
      "`--contract-ids` contains unknown q2-plus-q2 contract ids: ",
      paste(unknown_contract_ids, collapse = ", "),
      call. = FALSE
    )
  }
  contract_direct <- contract_direct[
    match(selected_contract_ids, contract_direct$contract_id),
    ,
    drop = FALSE
  ]
}

if (is_substitute_host) {
  if (length(selected_contract_ids) > 0L) {
    stop(
      "Nibi/Rorqual substitute smoke must run the exact six-target contract; ",
      "target subsets are reserved for retained-denominator pregrid wrappers.",
      call. = FALSE
    )
  }
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
      "qseries_smoke_substitution_q2_plus_q2_intercept",
    ,
    drop = FALSE
  ]
  if (nrow(substitution_row) != 1L) {
    stop(
      "Smoke-substitution contract must have exactly one q2-plus-q2 row.",
      call. = FALSE
    )
  }
  if (
    substitution_row$target_cells[[1L]] != "qseries_phylo_q2_plus_q2_intercept"
  ) {
    stop(
      "q2-plus-q2 substitute smoke must target only qseries_phylo_q2_plus_q2_intercept.",
      call. = FALSE
    )
  }
  if (substitution_row$target_count[[1L]] != "6") {
    stop("q2-plus-q2 substitute smoke target_count must be 6.", call. = FALSE)
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
    "cross-block correlations",
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
        "q2-plus-q2 smoke-substitution contract must mention `",
        phrase,
        "`.",
        call. = FALSE
      )
    }
  }
  if (substitution_row$promotion_decision[[1L]] != "do_not_promote") {
    stop(
      "q2-plus-q2 smoke-substitution contract must not promote rows.",
      call. = FALSE
    )
  }
}

TRUTH <- list(
  mu1_intercept = 0.25,
  mu2_intercept = -0.10,
  sigma1_intercept = -1.00,
  sigma2_intercept = -0.90,
  rho12 = 0.00,
  sd_mu1_intercept = 0.55,
  sd_mu2_intercept = 0.45,
  cor_mu1_mu2_intercept = 0.20,
  sd_sigma1_intercept = 0.45,
  sd_sigma2_intercept = 0.40,
  cor_sigma1_sigma2_intercept = 0.15
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

correlated_intercept_effects <- function(K, sd1, sd2, cor12) {
  endpoint_cov <- matrix(
    c(sd1^2, cor12 * sd1 * sd2, cor12 * sd1 * sd2, sd2^2),
    nrow = 2L
  )
  base <- t(chol(K)) %*% matrix(stats::rnorm(nrow(K) * 2L), nrow(K), 2L)
  out <- base %*% chol(endpoint_cov)
  colnames(out) <- c("axis1", "axis2")
  out
}

make_q2_plus_q2_intercept_data <- function(seed) {
  set.seed(seed)
  tree <- balanced_tree(8L)
  labels <- tree$tip.label
  K <- drmTMB:::drm_phylo_tip_covariance(tree)

  location_effects <- correlated_intercept_effects(
    K,
    sd1 = TRUTH$sd_mu1_intercept,
    sd2 = TRUTH$sd_mu2_intercept,
    cor12 = TRUTH$cor_mu1_mu2_intercept
  )
  scale_effects <- correlated_intercept_effects(
    K,
    sd1 = TRUTH$sd_sigma1_intercept,
    sd2 = TRUTH$sd_sigma2_intercept,
    cor12 = TRUTH$cor_sigma1_sigma2_intercept
  )
  row.names(location_effects) <- labels
  row.names(scale_effects) <- labels

  species <- rep(labels, each = n_each)
  eta1 <- TRUTH$mu1_intercept + location_effects[species, "axis1"]
  eta2 <- TRUTH$mu2_intercept + location_effects[species, "axis2"]
  log_sigma1 <- TRUTH$sigma1_intercept + scale_effects[species, "axis1"]
  log_sigma2 <- TRUTH$sigma2_intercept + scale_effects[species, "axis2"]
  data <- data.frame(
    y1 = stats::rnorm(length(species), eta1, exp(log_sigma1)),
    y2 = stats::rnorm(length(species), eta2, exp(log_sigma2)),
    species = species,
    stringsAsFactors = FALSE
  )
  list(data = data, tree = tree)
}

fit_q2_plus_q2_intercept <- function(sim) {
  tree <- sim$tree
  drmTMB(
    bf(
      mu1 = y1 ~ phylo(1 | pl | species, tree = tree),
      mu2 = y2 ~ phylo(1 | pl | species, tree = tree),
      sigma1 = ~ phylo(1 | ps | species, tree = tree),
      sigma2 = ~ phylo(1 | ps | species, tree = tree),
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = sim$data,
    control = drm_control(optimizer = list(eval.max = 2500, iter.max = 2500))
  )
}

truth_for <- function(estimand) {
  value <- TRUTH[[estimand]]
  if (is.null(value)) {
    stop("Unknown estimand: ", estimand, call. = FALSE)
  }
  value
}

extract_estimate <- function(fit, parm_name) {
  targets <- tryCatch(profile_targets(fit), error = function(e) e)
  if (inherits(targets, "error")) {
    return(NA_real_)
  }
  matched <- match(parm_name, targets$parm)
  if (is.na(matched)) {
    return(NA_real_)
  }
  unname(targets$estimate[[matched]])
}

run_interval <- function(fit, parm_name, method) {
  warnings_cap <- character()
  args <- list(fit, parm = parm_name, method = method, level = 0.95)
  if (identical(method, "profile")) {
    args$profile_engine <- "endpoint"
    args$trace <- FALSE
    args$profile_endpoint_max_eval <- profile_max_eval
  }
  if (identical(method, "bootstrap")) {
    if (bootstrap_R <= 0L) {
      return(list(
        lower = NA_real_,
        upper = NA_real_,
        status = "skipped",
        conf_status = NA_character_,
        message = "bootstrap_off",
        warnings = NA_character_
      ))
    }
    args$R <- bootstrap_R
    args$seed <- 42L
  }
  result <- withCallingHandlers(
    tryCatch(do.call(stats::confint, args), error = function(e) e),
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
      message = paste0(method, ": parm not found: ", parm_name),
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
    conf_status = if ("conf.status" %in% names(result)) {
      clean_text(as.character(result$conf.status[[1L]]))
    } else {
      method
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
  parm <- contract_row$profile_target[[1L]]
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

run_replicate <- function(replicate_index, seed) {
  sim <- tryCatch(make_q2_plus_q2_intercept_data(seed), error = function(e) e)
  if (inherits(sim, "error")) {
    return(do.call(
      rbind,
      lapply(seq_len(nrow(contract_direct)), function(i) {
        empty_target_row(
          contract_direct[i, , drop = FALSE],
          replicate_index,
          seed,
          "sim_error",
          conditionMessage(sim)
        )
      })
    ))
  }

  warnings_fit <- character()
  t_elapsed <- system.time({
    fit <- withCallingHandlers(
      tryCatch(fit_q2_plus_q2_intercept(sim), error = function(e) e),
      warning = function(w) {
        warnings_fit <<- c(warnings_fit, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
  })
  if (inherits(fit, "error")) {
    return(do.call(
      rbind,
      lapply(seq_len(nrow(contract_direct)), function(i) {
        empty_target_row(
          contract_direct[i, , drop = FALSE],
          replicate_index,
          seed,
          "fit_error",
          conditionMessage(fit)
        )
      })
    ))
  }

  conv <- fit$opt$convergence
  pd_hess <- isTRUE(fit$sdr$pdHess)
  do.call(
    rbind,
    lapply(seq_len(nrow(contract_direct)), function(i) {
      contract_row <- contract_direct[i, , drop = FALSE]
      truth <- truth_for(contract_row$estimand[[1L]])
      parm <- contract_row$profile_target[[1L]]
      est <- extract_estimate(fit, parm)
      wi <- run_interval(fit, parm, "wald")
      pi <- run_interval(fit, parm, "profile")
      ri <- run_interval_repair(fit, parm, contract_row$target_kind[[1L]])
      bi <- run_interval(fit, parm, "bootstrap")
      data.frame(
        smoke_id = paste0(
          contract_row$contract_id[[1L]],
          "_rep",
          replicate_index
        ),
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
        attempt_status = "fit_ok",
        message = clean_text(paste(warnings_fit, collapse = "; ")),
        convergence = conv,
        pdHess = pd_hess,
        estimate = est,
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

seed_manifest <- data.frame(
  provider = "phylo",
  replicate_index = seq(from = seed_start, length.out = n_rep),
  stringsAsFactors = FALSE
)
seed_manifest$seed <- seed_base + seed_manifest$replicate_index
seed_manifest$seed_role <- if (is_substitute_host) {
  "q2_plus_q2_intercept_substitute_smoke"
} else {
  "q2_plus_q2_intercept_local_smoke"
}
seed_manifest$execution_status <- "executed"
seed_manifest$host_class <- host_class
seed_manifest$host_name <- host_name
seed_manifest$interval_repair_channel <- interval_repair_channel
if (is_substitute_host) {
  seed_manifest$source_substitution_contract <- rel_path(
    smoke_substitution_contract_path
  )
  seed_manifest$source_substitution_contract_id <-
    "qseries_smoke_substitution_q2_plus_q2_intercept"
}
write_tsv(seed_manifest, seed_manifest_path)

replicate_rows <- lapply(
  seq(from = seed_start, length.out = n_rep),
  function(replicate_index) {
    run_replicate(replicate_index, seed_base + replicate_index)
  }
)
replicates <- do.call(rbind, replicate_rows)
row.names(replicates) <- NULL
replicates$host_class <- host_class
replicates$host_name <- host_name
if (is_substitute_host) {
  replicates$source_substitution_contract <- rel_path(
    smoke_substitution_contract_path
  )
  replicates$source_substitution_contract_id <-
    "qseries_smoke_substitution_q2_plus_q2_intercept"
}

summaries <- lapply(split(replicates, replicates$contract_id), function(x) {
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
        "Fisher/Rose must review the Nibi/Rorqual q2-plus-q2 substitute-host",
        "smoke artifact before any denominator work; cross-block correlations",
        "remain blocked."
      )
    } else {
      paste(
        "Fisher/Rose must review the local q2-plus-q2 intercept smoke before",
        "any Totoro/FIIA smoke; Nibi/Rorqual/DRAC remain blocked for denominator work."
      )
    }
  } else {
    if (is_substitute_host) {
      paste(
        "Repair or explain the Nibi/Rorqual q2-plus-q2 substitute-host smoke",
        "failure before any denominator work; cross-block correlations remain blocked."
      )
    } else {
      paste(
        "Repair or explain the local q2-plus-q2 intercept smoke failure before",
        "Totoro/FIIA; Nibi/Rorqual/DRAC remain blocked for denominator work."
      )
    }
  }
  data.frame(
    smoke_id = paste0("q2_plus_q2_intercept_local_smoke_", x$contract_id[[1L]]),
    contract_id = x$contract_id[[1L]],
    cell_id = x$cell_id[[1L]],
    provider = x$provider[[1L]],
    target_kind = x$target_kind[[1L]],
    endpoint_member = x$endpoint_member[[1L]],
    estimand = x$estimand[[1L]],
    target_parm = x$target_parm[[1L]],
    repair_channel = paste(unique(fit_rows$repair_channel), collapse = ";"),
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
    source_substitution_contract = if (is_substitute_host) {
      rel_path(smoke_substitution_contract_path)
    } else {
      "NA"
    },
    source_substitution_contract_id = if (is_substitute_host) {
      "qseries_smoke_substitution_q2_plus_q2_intercept"
    } else {
      "NA"
    },
    evidence_url = rel_path(artifact_dir),
    claim_boundary = if (is_substitute_host) {
      paste(
        "Q2-plus-q2 intercept Nibi/Rorqual substitute-host smoke only; this",
        "promotes exactly no Q-Series row; n=5 is smoke not coverage evidence;",
        "it does not change interval_status, coverage_status, inference_ready,",
        "supported, q2-only location support, q4/q8, non-Gaussian, REML,",
        "AI-REML, bridge support, DRAC denominator evidence, or public support;",
        "cross-block correlations remain blocked."
      )
    } else {
      paste(
        "Q2-plus-q2 intercept local smoke only; this promotes exactly no",
        "Q-Series row; n is smoke not coverage evidence; it does not change",
        "interval_status, coverage_status, inference_ready, supported, q2-only",
        "location support, q4/q8, non-Gaussian, REML, AI-REML, bridge support,",
        "or public support; cross-block correlations remain blocked."
      )
    },
    next_gate = next_gate,
    stringsAsFactors = FALSE
  )
})
summary <- do.call(rbind, summaries)
summary <- summary[
  match(contract_direct$contract_id, summary$contract_id),
  ,
  drop = FALSE
]

write_tsv(replicates, replicate_path)
write_tsv(summary, summary_path)
if (write_dashboard) {
  write_tsv(summary, dashboard_summary_path)
}

session_text <- utils::capture.output(sessionInfo())
writeLines(session_text, session_info_path)
git_sha <- tryCatch(
  system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE),
  error = function(e) paste("git rev-parse failed:", conditionMessage(e))
)
writeLines(git_sha, git_sha_path)

message(
  "wrote q2-plus-q2 intercept local-smoke artifacts to ",
  rel_path(artifact_dir)
)

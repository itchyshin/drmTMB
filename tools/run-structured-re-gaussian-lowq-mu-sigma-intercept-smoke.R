#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/run-structured-re-gaussian-lowq-mu-sigma-intercept-smoke.R [options]",
      "",
      "Options:",
      "  --n-rep=N               Replicates per provider (default: 1).",
      "  --seed-start=N          First replicate index (default: 1).",
      "  --seed-base=N           Seed base; seed = seed_base + replicate_index (default: 913000).",
      "  --providers=a,b,c       Providers to run (default: phylo,spatial,animal,relmat).",
      "  --host-class=CLASS      Host class label (default: local_rehearsal).",
      "  --host-name=NAME        Host name label (default: Sys.info()[['nodename']]).",
      "  --output-dir=PATH       Artifact directory.",
      "  --overwrite=true        Replace an existing artifact directory.",
      "  --write-dashboard=true  Write the dashboard summary sidecar.",
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

n_rep <- as.integer(arg_value("n-rep", "1"))
if (!is.finite(n_rep) || n_rep < 1L) {
  stop("`--n-rep` must be a positive integer.", call. = FALSE)
}
seed_start <- as.integer(arg_value("seed-start", "1"))
if (!is.finite(seed_start) || seed_start < 1L) {
  stop("`--seed-start` must be a positive integer.", call. = FALSE)
}
seed_base <- as.integer(arg_value("seed-base", "913000"))
if (!is.finite(seed_base) || seed_base < 1L) {
  stop("`--seed-base` must be a positive integer.", call. = FALSE)
}
overwrite <- arg_flag("overwrite", FALSE)
write_dashboard <- arg_flag("write-dashboard", TRUE)
host_class <- arg_value("host-class", "local_rehearsal")
host_name <- arg_value("host-name", unname(Sys.info()[["nodename"]]))

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
row_selection_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-lowq-row-selection.tsv"
)
dashboard_summary_path <- file.path(
  dashboard_dir,
  "structured-re-gaussian-lowq-mu-sigma-intercept-local-smoke.tsv"
)
default_artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-29-gaussian-lowq-mu-sigma-intercept-smoke-local"
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
  "structured-re-gaussian-lowq-mu-sigma-intercept-local-smoke.tsv"
)
replicate_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-lowq-mu-sigma-intercept-local-smoke-replicates.tsv"
)
seed_manifest_path <- file.path(
  artifact_dir,
  "structured-re-gaussian-lowq-mu-sigma-intercept-local-smoke-seed-manifest.tsv"
)
session_info_path <- file.path(artifact_dir, "sessionInfo.txt")
git_sha_path <- file.path(artifact_dir, "git-sha.txt")

suppressPackageStartupMessages(devtools::load_all(repo_root, quiet = TRUE))

row_selection <- read_tsv(row_selection_path)
expected_cells <- c(
  phylo = "qseries_phylo_q1_mu_sigma_intercept",
  spatial = "qseries_spatial_q1_mu_sigma_intercept",
  animal = "qseries_animal_q1_mu_sigma_intercept",
  relmat = "qseries_relmat_q1_mu_sigma_intercept"
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
    "Row-selection sidecar must contain the selected q1 mu+sigma intercept cells.",
    call. = FALSE
  )
}
if (!all(selection_rows$endpoint_set == "mu+sigma")) {
  stop(
    "Selected rows must be the matched q1 mu+sigma intercept cells.",
    call. = FALSE
  )
}
if (!all(selection_rows$slope_class == "intercept_only")) {
  stop("Selected rows must be intercept-only rows.", call. = FALSE)
}

provider_defaults <- list(
  phylo = list(
    n_group = 10L,
    n_each = 10L,
    beta_mu_intercept = 0.30,
    beta_sigma_intercept = -1.00,
    sd_mu_intercept = 0.55,
    sd_sigma_intercept = 0.20,
    rho_mu_sigma = 0.00,
    group_var = "species",
    term = "phylo(1 | species)"
  ),
  spatial = list(
    n_group = 10L,
    n_each = 10L,
    beta_mu_intercept = 0.30,
    beta_sigma_intercept = -1.00,
    sd_mu_intercept = 0.45,
    sd_sigma_intercept = 0.18,
    rho_mu_sigma = 0.00,
    group_var = "site",
    term = "spatial(1 | site)"
  ),
  animal = list(
    n_group = 10L,
    n_each = 10L,
    beta_mu_intercept = 0.30,
    beta_sigma_intercept = -1.00,
    sd_mu_intercept = 0.55,
    sd_sigma_intercept = 0.20,
    rho_mu_sigma = 0.00,
    group_var = "id",
    term = "animal(1 | id)"
  ),
  relmat = list(
    n_group = 10L,
    n_each = 10L,
    beta_mu_intercept = 0.30,
    beta_sigma_intercept = -1.00,
    sd_mu_intercept = 0.55,
    sd_sigma_intercept = 0.20,
    rho_mu_sigma = 0.00,
    group_var = "id",
    term = "relmat(1 | id)"
  )
)

make_correlated_effects <- function(K, spec) {
  L <- t(chol(K))
  n_group <- nrow(K)
  z_mu <- stats::rnorm(n_group)
  z_sigma <- stats::rnorm(n_group)
  rho <- spec$rho_mu_sigma
  effect_mu <- as.vector(L %*% (spec$sd_mu_intercept * z_mu))
  effect_sigma <- as.vector(
    L %*%
      (spec$sd_sigma_intercept *
        (rho * z_mu + sqrt(1 - rho^2) * z_sigma))
  )
  names(effect_mu) <- rownames(K)
  names(effect_sigma) <- rownames(K)
  list(mu = effect_mu, sigma = effect_sigma)
}

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

  effects <- make_correlated_effects(K, spec)
  group <- rep(levels, each = spec$n_each)
  mu <- unname(spec$beta_mu_intercept + effects$mu[group])
  sigma <- exp(unname(spec$beta_sigma_intercept + effects$sigma[group]))
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
      sd_mu_intercept = spec$sd_mu_intercept,
      sd_sigma_intercept = spec$sd_sigma_intercept,
      rho_mu_sigma = spec$rho_mu_sigma,
      n_group = spec$n_group,
      n_each = spec$n_each
    ),
    matrix_payload
  )
  dat
}

fit_mu_sigma <- function(provider, dat) {
  truth <- attr(dat, "truth", exact = TRUE)
  switch(
    provider,
    phylo = {
      tree <- truth$tree
      drmTMB(
        bf(
          y ~ phylo(1 | species, tree = tree),
          sigma ~ phylo(1 | species, tree = tree)
        ),
        family = gaussian(),
        data = dat
      )
    },
    spatial = {
      coords <- truth$coords
      drmTMB(
        bf(
          y ~ spatial(1 | site, coords = coords),
          sigma ~ spatial(1 | site, coords = coords)
        ),
        family = gaussian(),
        data = dat
      )
    },
    animal = {
      A <- truth$A
      drmTMB(
        bf(
          y ~ animal(1 | id, A = A),
          sigma ~ animal(1 | id, A = A)
        ),
        family = gaussian(),
        data = dat
      )
    },
    relmat = {
      K <- truth$K
      drmTMB(
        bf(
          y ~ relmat(1 | id, K = K),
          sigma ~ relmat(1 | id, K = K)
        ),
        family = gaussian(),
        data = dat
      )
    },
    stop("Unknown provider: ", provider, call. = FALSE)
  )
}

find_interval_row <- function(ci, target_prefix) {
  hit <- startsWith(ci$parm, target_prefix)
  if (!any(hit)) {
    hit <- grepl(target_prefix, ci$parm, fixed = TRUE)
  }
  if (!any(hit)) {
    return(NULL)
  }
  ci[which(hit)[[1L]], , drop = FALSE]
}

target_specs <- function(provider, spec) {
  list(
    list(
      target_kind = "direct_sd_mu_intercept",
      endpoint_member = "mu:(Intercept)",
      estimand = "structured SD for mu intercept",
      interval_channel = "default_confint_wald_direct_sd_mu",
      target_prefix = paste0("sd:mu:mu:", spec$term),
      truth_value = spec$sd_mu_intercept
    ),
    list(
      target_kind = "direct_sd_sigma_intercept",
      endpoint_member = "sigma:(Intercept)",
      estimand = "structured SD for sigma intercept",
      interval_channel = "default_confint_wald_direct_sd_sigma",
      target_prefix = paste0("sd:sigma:sigma:", spec$term),
      truth_value = spec$sd_sigma_intercept
    ),
    list(
      target_kind = "mu_sigma_correlation_intercept",
      endpoint_member = "mu:(Intercept);sigma:(Intercept)",
      estimand = "same-group mu-sigma random-effect correlation",
      interval_channel = "default_confint_wald_mu_sigma_correlation",
      target_prefix = paste0("cor:", provider, ":"),
      truth_value = spec$rho_mu_sigma
    )
  )
}

estimate_for_target <- function(fit, provider, target_kind) {
  if (is.null(fit)) {
    return(NA_real_)
  }
  if (identical(target_kind, "direct_sd_mu_intercept")) {
    return(numeric_or_na(unname(fit$sdpars$mu[[1L]])))
  }
  if (identical(target_kind, "direct_sd_sigma_intercept")) {
    return(numeric_or_na(unname(fit$sdpars$sigma[[1L]])))
  }
  if (identical(target_kind, "mu_sigma_correlation_intercept")) {
    return(numeric_or_na(unname(fit$corpars[[provider]][[1L]])))
  }
  NA_real_
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
        fit_mu_sigma(provider, dat),
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
  specs <- target_specs(provider, spec)
  rows <- lapply(specs, function(target) {
    interval_row <- if (!is.null(ci)) {
      find_interval_row(ci, target$target_prefix)
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
    target_parameter <- if (is.null(interval_row)) {
      target$target_prefix
    } else {
      interval_row$parm[[1L]]
    }
    usable_interval <- identical(conf_status, "wald") &&
      is.finite(lower) &&
      is.finite(upper)
    covered <- if (usable_interval) {
      lower <= target$truth_value && target$truth_value <= upper
    } else {
      NA
    }
    lower_miss <- if (usable_interval) target$truth_value < lower else NA
    upper_miss <- if (usable_interval) target$truth_value > upper else NA

    data.frame(
      smoke_id = paste0(
        "gaussian_lowq_mu_sigma_intercept_smoke_",
        provider,
        "_rep",
        replicate_index,
        "_",
        target$target_kind
      ),
      cell_id = selection_row$cell_id[[1L]],
      provider = provider,
      formula_cell = selection_row$formula_cell[[1L]],
      replicate_index = replicate_index,
      seed = seed,
      target_kind = target$target_kind,
      endpoint_member = target$endpoint_member,
      estimand = target$estimand,
      interval_channel = target$interval_channel,
      target_parameter = target_parameter,
      truth_value = target$truth_value,
      n_group = spec$n_group,
      n_each = spec$n_each,
      beta_mu_intercept = spec$beta_mu_intercept,
      beta_sigma_intercept = spec$beta_sigma_intercept,
      truth_sd_mu_intercept = spec$sd_mu_intercept,
      truth_sd_sigma_intercept = spec$sd_sigma_intercept,
      truth_rho_mu_sigma = spec$rho_mu_sigma,
      fit_ok = fit_ok,
      converged = converged,
      pdHess = pdhess,
      confint_ok = confint_ok,
      conf_status = conf_status,
      usable_interval = usable_interval,
      estimate = estimate_for_target(fit, provider, target$target_kind),
      conf.low = lower,
      conf.high = upper,
      covered = covered,
      lower_miss = lower_miss,
      upper_miss = upper_miss,
      nobs = if (fit_ok) stats::nobs(fit) else NA_integer_,
      elapsed = elapsed,
      warning_count = length(unique(warnings)),
      warnings = paste(unique(warnings), collapse = " | "),
      fit_error = fit_error,
      confint_error = confint_error,
      host_class = host_class,
      host_name = host_name,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

seed_manifest <- expand.grid(
  provider = selected_providers,
  replicate_index = seq(from = seed_start, length.out = n_rep),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
seed_manifest$seed <- seed_base + seed_manifest$replicate_index
seed_manifest$seed_role <- "gaussian_lowq_mu_sigma_intercept_smoke"
seed_manifest$execution_status <- "executed"
seed_manifest$host_class <- host_class
seed_manifest$host_name <- host_name
write_tsv(seed_manifest, seed_manifest_path)

replicate_rows <- list()
row_i <- 1L
for (provider in selected_providers) {
  selection_row <- selection_rows[
    selection_rows$structure_provider == provider,
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
  selection_row <- selection_rows[
    selection_rows$structure_provider == provider,
    ,
    drop = FALSE
  ]
  support_clear <- all(x$fit_ok) &&
    all(x$converged) &&
    all(x$pdHess) &&
    all(x$usable_interval) &&
    all(x$warning_count == 0L)
  n_usable <- sum(x$usable_interval)
  covered <- x$covered[x$usable_interval]
  coverage <- if (length(covered) == 0L) NA_real_ else mean(covered)
  status <- if (support_clear) {
    "local_smoke_passed_fixture_only"
  } else {
    "local_smoke_diagnostic_blocked"
  }
  blockers <- unique(c(
    if (any(!x$fit_ok)) "fit_failed",
    if (any(!x$converged)) "nonconverged",
    if (any(!x$pdHess)) "pdhess_false",
    if (any(!x$usable_interval)) "nonusable_interval",
    if (any(x$warning_count > 0L)) "warnings_recorded"
  ))
  if (length(blockers) == 0L) {
    blockers <- "none"
  }
  data.frame(
    smoke_id = paste0("gaussian_lowq_mu_sigma_intercept_smoke_", provider),
    cell_id = selection_row$cell_id[[1L]],
    provider = provider,
    source_row_selection = rel_path(row_selection_path),
    artifact_dir = rel_path(artifact_dir),
    n_rep = length(unique(x$replicate_index)),
    n_targets = nrow(x),
    n_fit_ok = sum(x$fit_ok),
    n_converged = sum(x$converged),
    n_pdhess = sum(x$pdHess),
    n_confint_ok = sum(x$confint_ok),
    n_usable_intervals = n_usable,
    finite_interval_rate = fmt4(mean(x$usable_interval)),
    n_covered = if (length(covered) == 0L) 0L else sum(covered),
    coverage = fmt4(coverage),
    coverage_mcse = fmt6(mcse_proportion(covered)),
    lower_miss = sum(x$lower_miss, na.rm = TRUE),
    upper_miss = sum(x$upper_miss, na.rm = TRUE),
    smoke_status = status,
    blocker_signal = paste(blockers, collapse = ";"),
    review_decision = "do_not_promote_diagnostic_only",
    promotion_decision = "do_not_promote",
    evidence_url = rel_path(artifact_dir),
    claim_boundary = paste(
      "Gaussian low-q q1 mu+sigma intercept local smoke only;",
      "this promotes exactly no Q-Series row;",
      paste0(
        "n=",
        length(unique(x$replicate_index)),
        " is not coverage evidence;"
      ),
      "sd_mu, sd_sigma, and mu-sigma correlation targets are separate;",
      "no interval_status, coverage_status, inference_ready, supported, q2, q4/q8,",
      "non-Gaussian, REML, AI-REML, bridge support, public support, or DRAC claim."
    ),
    next_gate = paste(
      "Fisher/Rose must review this diagnostic before any Totoro/FIIA smoke;",
      "matched mu+sigma does not inherit q1 mu, q1 sigma, q2, q4/q8,",
      "or non-Gaussian evidence; keep support cells point_fit/planned/planned."
    ),
    host_class = host_class,
    host_name = host_name,
    n_warning_targets = sum(x$warning_count > 0L),
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
  " Gaussian low-q mu+sigma intercept smoke summary rows to ",
  rel_path(summary_path)
)
if (write_dashboard) {
  message("Updated dashboard sidecar: ", rel_path(dashboard_summary_path))
}
message(
  "Wrote ",
  nrow(replicates),
  " target rows to ",
  rel_path(replicate_path)
)

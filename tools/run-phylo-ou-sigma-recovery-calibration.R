#!/usr/bin/env Rscript

# Campaign-readiness calibration for the G13 independent phylogenetic OU
# intercept model. This script is deliberately not a retained recovery or
# coverage campaign: it selects and prices a candidate design only.

args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) args[[1L]] else "--smoke"
if (!mode %in% c("--smoke", "--preflight", "--calibration", "--contract")) {
  stop("Usage: Rscript tools/run-phylo-ou-sigma-recovery-calibration.R [--contract|--smoke|--preflight|--calibration]", call. = FALSE)
}

out_dir <- if (identical(mode, "--calibration")) {
  file.path("docs", "dev-log", "evidence", "ou-v1-g14")
} else {
  file.path("docs", "dev-log", "implementation-recovery", "2026-09-12-phylo-ou-sigma-r1")
}
if (identical(mode, "--contract")) {
  cat("PHYLO_OU_SIGMA_R1_CONTRACT_PASS\n")
  quit(status = 0L)
}
if (!requireNamespace("ape", quietly = TRUE) || !requireNamespace("pkgload", quietly = TRUE)) {
  stop("This calibration needs ape and pkgload.", call. = FALSE)
}

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
run_started <- Sys.time()
pkgload::load_all(".", compile = TRUE, quiet = TRUE)

tree_seed_for <- function(n_species) {
  switch(as.character(n_species), `12` = 2026091203L, `32` = 2026091201L, `64` = 2026091202L)
}

rate_key <- function(x) sub("\\.", "p", formatC(x, format = "f", digits = 1L))

tree_for <- function(n_species) {
  seed <- tree_seed_for(n_species)
  set.seed(seed)
  tree <- ape::rcoal(n_species)
  tree$tip.label <- sprintf("sp%03d", seq_len(n_species))
  # Rates are conditional on this documented height-one scale. Dividing by
  # total branch length would change the relationship between alpha and depth.
  raw_height <- max(ape::node.depth.edgelength(tree)[seq_len(length(tree$tip.label))])
  tree$edge.length <- tree$edge.length / raw_height
  attr(tree, "raw_height") <- raw_height
  tree
}

# This intentionally does not call drmTMB:::drm_phylo_ou_tip_covariance().
# For a stationary OU process, the tip correlation is exp(-alpha*d_ij).
independent_ou_correlation <- function(tree, alpha) {
  distance <- ape::cophenetic.phylo(tree)
  exp(-alpha * distance)
}

conditions <- function() {
  ordinary <- expand.grid(
    n_species = c(32L, 64L), n_each = c(6L, 12L),
    alpha_mu_truth = c(0.7, 1.3), stringsAsFactors = FALSE
  )
  ordinary$alpha_sigma_truth <- ifelse(ordinary$alpha_mu_truth == 0.7, 1.3, 0.7)
  ordinary$design_class <- "ordinary"
  ordinary$condition <- sprintf(
    "ordinary_s%03d_r%02d_mu%.1f_sigma%.1f",
    ordinary$n_species, ordinary$n_each,
    ordinary$alpha_mu_truth, ordinary$alpha_sigma_truth
  )
  ordinary <- ordinary[rep(seq_len(nrow(ordinary)), each = 2L), ]
  ordinary$tree_seed <- vapply(ordinary$n_species, tree_seed_for, integer(1L))
  ordinary$seed <- rep(c(2026091211L, 2026091212L), times = nrow(ordinary) / 2L)
  ordinary$task_id <- sprintf(
    "S1_n%d_m%d_amu%s_asigma%s_seed%d", ordinary$n_species, ordinary$n_each,
    rate_key(ordinary$alpha_mu_truth), rate_key(ordinary$alpha_sigma_truth), ordinary$seed
  )
  ordinary$tree_id <- sprintf("tree_n%d_v1", ordinary$n_species)

  weak <- data.frame(
    n_species = 12L, n_each = 1L,
    alpha_mu_truth = c(0.7, 1.3), alpha_sigma_truth = c(1.3, 0.7),
    design_class = "negative_control",
    condition = c("negative_control_mu0.7_sigma1.3", "negative_control_mu1.3_sigma0.7"),
    tree_id = rep("tree_n12_v1", 2L),
    tree_seed = rep(tree_seed_for(12L), 2L),
    seed = c(2026091213L, 2026091214L), stringsAsFactors = FALSE
  )
  weak$task_id <- sprintf(
    "S1_NEG_n12_m1_amu%s_asigma%s_seed%d",
    rate_key(weak$alpha_mu_truth), rate_key(weak$alpha_sigma_truth), weak$seed
  )
  out <- rbind(ordinary, weak)
  rownames(out) <- NULL
  out
}

starts <- list(
  low = list(alpha = c(0.4, 0.4), sd = c(0.25, 0.15)),
  middle = list(alpha = c(1, 1), sd = c(0.45, 0.25)),
  high = list(alpha = c(2, 2), sd = c(0.70, 0.40))
)

fit_one <- function(row, start_id, start_spec) {
  tree <- tree_for(row$n_species)
  c_mu <- independent_ou_correlation(tree, row$alpha_mu_truth)
  c_sigma <- independent_ou_correlation(tree, row$alpha_sigma_truth)
  set.seed(row$seed)
  u <- drop(t(chol(c_mu)) %*% stats::rnorm(row$n_species, sd = 0.45))
  set.seed(row$seed + 100000L)
  v <- drop(t(chol(c_sigma)) %*% stats::rnorm(row$n_species, sd = 0.25))
  species <- rep(tree$tip.label, each = row$n_each)
  index <- match(species, tree$tip.label)
  sigma <- exp(-1 + v[index])
  set.seed(row$seed + 200000L)
  dat <- data.frame(
    y = u[index] + stats::rnorm(length(species), sd = sigma),
    species = species
  )
  warnings <- character()
  started <- Sys.time()
  cpu_started <- proc.time()
  model_formula <- bf(
    y ~ phylo(1 | species, tree = tree, model = "ou"),
    sigma ~ phylo(1 | species, tree = tree, model = "ou")
  )
  control <- drmTMB:::drm_parse_control(drm_control(
    optimizer = list(eval.max = 1500, iter.max = 1500)
  ))
  missing <- drmTMB:::drm_parse_missing_control(miss_control())
  spec <- drmTMB:::drm_build_gaussian_ls_spec(
    model_formula, dat, env = environment(), weights = NULL,
    control = control, impute = NULL, missing = missing
  )
  # This is an internal calibration-only start injection: the public start
  # interface does not expose two labelled OU-rate start coordinates. The
  # provider registry, rather than an endpoint position, proves the native
  # allocation used later by drm_fit_spec(). Its preparer expands an absent
  # log_decay_phylo start to one coordinate per registered field.
  fields <- drmTMB:::phylo_ou_provider_fields(spec$structured$phylo_mu)
  field_dpars <- unname(vapply(fields, `[[`, character(1L), "dpar"))
  field_alpha_index <- unname(vapply(fields, `[[`, integer(1L), "alpha_index0"))
  field_latent_index <- unname(vapply(fields, `[[`, integer(1L), "latent_index0"))
  if (!isTRUE(all(field_dpars == c("mu", "sigma"))) ||
      !isTRUE(all(field_alpha_index == 0:1)) ||
      !isTRUE(all(field_latent_index == 0:1))) {
    stop(sprintf(
      "The joint OU provider registry did not allocate mu and sigma rate slots (dpar=%s; alpha_index0=%s).",
      paste(field_dpars, collapse = ","), paste(field_alpha_index, collapse = ",")
    ), call. = FALSE)
  }
  spec$start$beta_mu <- 0
  spec$start$beta_sigma <- -1
  spec$start$log_sd_phylo <- log(start_spec$sd)
  spec$start$log_decay_phylo <- log(start_spec$alpha)
  fit <- tryCatch(
    withCallingHandlers(
      drmTMB:::drm_fit_spec(
        spec = spec, formula = model_formula, family = gaussian(),
        control = control, REML = FALSE, penalty = NULL, estimator = "ml"
      ),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = identity
  )
  elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  cpu_elapsed <- proc.time() - cpu_started
  common <- data.frame(
    task_id = row$task_id, condition = row$condition, design_class = row$design_class, seed = row$seed,
    tree_id = row$tree_id,
    tree_seed = row$tree_seed, n_species = row$n_species, n_each = row$n_each,
    n = nrow(dat), tree_height_raw = attr(tree, "raw_height"),
    alpha_mu_truth = row$alpha_mu_truth,
    alpha_sigma_truth = row$alpha_sigma_truth,
    start_id = start_id,
    start_alpha_mu = start_spec$alpha[[1L]], start_alpha_sigma = start_spec$alpha[[2L]],
    start_sd_mu = start_spec$sd[[1L]], start_sd_sigma = start_spec$sd[[2L]],
    elapsed_seconds = elapsed, cpu_seconds = unname(cpu_elapsed[["user.self"]] + cpu_elapsed[["sys.self"]]),
    warnings = paste(warnings, collapse = " | "), selected_status = "NOT_APPLICABLE_READINESS",
    stringsAsFactors = FALSE
  )
  if (inherits(fit, "error")) {
    return(cbind(common, fit_ok = FALSE, convergence = NA_integer_, pdHess = NA,
      max_gradient = NA_real_, min_fixed_covariance_eigen = NA_real_, alpha_mu = NA_real_,
      alpha_sigma = NA_real_, sd_mu = NA_real_, sd_sigma = NA_real_,
      mu_intercept = NA_real_, logsigma_intercept = NA_real_, objective = NA_real_,
      convergence_message = NA_character_, fn_evals = NA_integer_, gr_evals = NA_integer_,
      internal_parameters = NA_character_, boundary_mu = NA, boundary_sigma = NA,
      logLik = NA_real_,
      boundary = NA, error = conditionMessage(fit)))
  }
  alpha_mu <- unname(fit$decaypars$phylo[["decay_phylo"]])
  alpha_sigma <- unname(fit$decaypars$phylo[["decay_phylo:sigma"]])
  fixed_covariance <- tryCatch(fit$sdr$cov.fixed, error = function(e) NULL)
  min_covariance_eigen <- if (is.null(fixed_covariance) || !length(fixed_covariance)) NA_real_ else {
    min(eigen(fixed_covariance, symmetric = TRUE, only.values = TRUE)$values)
  }
  evaluations <- fit$opt$evaluations
  fn_evals <- if (length(evaluations) >= 1L) unname(as.integer(evaluations[[1L]])) else NA_integer_
  gr_evals <- if (length(evaluations) >= 2L) unname(as.integer(evaluations[[2L]])) else NA_integer_
  convergence_message <- if (is.null(fit$opt$message)) "" else as.character(fit$opt$message)
  internal_parameters <- paste(sprintf("%s=%.17g", names(fit$opt$par), fit$opt$par), collapse = ";")
  boundary_mu <- alpha_mu < 0.02 || alpha_mu > 50
  boundary_sigma <- alpha_sigma < 0.02 || alpha_sigma > 50
  cbind(common,
    fit_ok = TRUE, convergence = fit$opt$convergence,
    pdHess = isTRUE(fit$sdr$pdHess),
    max_gradient = max(abs(fit$obj$gr(fit$opt$par))),
    min_fixed_covariance_eigen = min_covariance_eigen,
    alpha_mu = alpha_mu, alpha_sigma = alpha_sigma,
    sd_mu = unname(fit$sdpars$mu[[1L]]), sd_sigma = unname(fit$sdpars$sigma[[1L]]),
    mu_intercept = unname(fit$par$mu[[1L]]),
    logsigma_intercept = unname(fit$par$sigma[[1L]]),
    objective = fit$opt$objective, convergence_message = convergence_message,
    fn_evals = fn_evals, gr_evals = gr_evals, internal_parameters = internal_parameters,
    boundary_mu = boundary_mu, boundary_sigma = boundary_sigma,
    logLik = as.numeric(stats::logLik(fit)),
    boundary = boundary_mu || boundary_sigma,
    error = NA_character_
  )
}

sha256_file <- function(path) {
  line <- system2("shasum", c("-a", "256", path), stdout = TRUE, stderr = TRUE)
  if (length(line) != 1L || !grepl("^[[:xdigit:]]{64} ", line)) {
    stop(sprintf("Could not obtain SHA-256 for %s", path), call. = FALSE)
  }
  sub(" .*", "", line)
}

task_payload <- function(row) {
  tree <- tree_for(row$n_species)
  c_mu <- independent_ou_correlation(tree, row$alpha_mu_truth)
  c_sigma <- independent_ou_correlation(tree, row$alpha_sigma_truth)
  set.seed(row$seed)
  u <- drop(t(chol(c_mu)) %*% stats::rnorm(row$n_species, sd = 0.45))
  set.seed(row$seed + 100000L)
  v <- drop(t(chol(c_sigma)) %*% stats::rnorm(row$n_species, sd = 0.25))
  species <- rep(tree$tip.label, each = row$n_each)
  index <- match(species, tree$tip.label)
  sigma <- exp(-1 + v[index])
  set.seed(row$seed + 200000L)
  dat <- data.frame(y = u[index] + stats::rnorm(length(species), sd = sigma), species = species)
  list(tree = tree, u = u, v = v, data = dat)
}

write_calibration_artifacts <- function(all_conditions, attempts, run_started, elapsed_total) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  for (subdir in c("trees", "data", "fields")) dir.create(file.path(out_dir, subdir), showWarnings = FALSE)
  tree_rows <- do.call(rbind, lapply(unique(all_conditions$n_species), function(n_species) {
    tree <- tree_for(n_species)
    tree_id <- sprintf("tree_n%d_v1", n_species)
    tree_path <- file.path(out_dir, "trees", paste0(tree_id, ".nwk"))
    ape::write.tree(tree, file = tree_path)
    data.frame(
      tree_id = tree_id, n_species = n_species, tree_seed = tree_seed_for(n_species),
      root_to_tip_height = 1, root_retained = TRUE,
      tip_order_sha256 = sha256_file({ p <- tempfile(); writeLines(tree$tip.label, p); p }),
      newick_sha256 = sha256_file(tree_path), scaling_rule = "height_one",
      root_distribution = "stationary", stringsAsFactors = FALSE
    )
  }))
  utils::write.csv(tree_rows, file.path(out_dir, "trees.csv"), row.names = FALSE)
  manifest_rows <- lapply(seq_len(nrow(all_conditions)), function(i) {
    row <- all_conditions[i, , drop = FALSE]
    payload <- task_payload(row)
    data_path <- file.path(out_dir, "data", paste0(row$task_id, ".csv"))
    u_path <- file.path(out_dir, "fields", paste0(row$task_id, "-u.csv"))
    v_path <- file.path(out_dir, "fields", paste0(row$task_id, "-v.csv"))
    utils::write.csv(payload$data, data_path, row.names = FALSE)
    utils::write.csv(data.frame(species = payload$tree$tip.label, u = payload$u), u_path, row.names = FALSE)
    utils::write.csv(data.frame(species = payload$tree$tip.label, v = payload$v), v_path, row.names = FALSE)
    data.frame(
      task_id = row$task_id, design_class = row$design_class, cell_id = row$condition,
      replicate_seed = row$seed, tree_id = row$tree_id, n_species = row$n_species, n_each = row$n_each,
      alpha_mu_truth = row$alpha_mu_truth, alpha_sigma_truth = row$alpha_sigma_truth,
      sd_u_truth = 0.45, sd_v_truth = 0.25, mu_intercept_truth = 0,
      logsigma_intercept_truth = -1, data_sha256 = sha256_file(data_path),
      generator_sha256 = sha256_file("tools/run-phylo-ou-sigma-recovery-calibration.R"),
      stringsAsFactors = FALSE
    )
  })
  manifest <- do.call(rbind, manifest_rows)
  utils::write.csv(manifest, file.path(out_dir, "manifest.csv"), row.names = FALSE)
  starts_table <- do.call(rbind, lapply(seq_len(nrow(all_conditions)), function(i) {
    do.call(rbind, lapply(names(starts), function(start_id) {
      start <- starts[[start_id]]
      start_text <- paste(c(start$alpha, start$sd, 0, -1), collapse = ",")
      start_path <- tempfile(); writeLines(start_text, start_path)
      data.frame(task_id = all_conditions$task_id[[i]], start_id = start_id,
        alpha_mu_start = start$alpha[[1L]], alpha_sigma_start = start$alpha[[2L]],
        sd_u_start = start$sd[[1L]], sd_v_start = start$sd[[2L]],
        mu_intercept_start = 0, logsigma_intercept_start = -1,
        internal_start_sha256 = sha256_file(start_path), stringsAsFactors = FALSE)
    }))
  }))
  utils::write.csv(starts_table, file.path(out_dir, "starts.csv"), row.names = FALSE)
  attempts$attempt_status <- ifelse(attempts$fit_ok, "FIT", "ERROR")
  attempts$selection_status <- "NOT_SELECTED"
  selected <- do.call(rbind, lapply(split(attempts, attempts$task_id), function(x) {
    qualified <- x[x$fit_ok & x$convergence == 0L & x$pdHess & !x$boundary & is.finite(x$objective), , drop = FALSE]
    if (nrow(qualified)) {
      picked <- qualified[which.min(qualified$objective), , drop = FALSE]
      attempts[attempts$task_id == picked$task_id & attempts$start_id == picked$start_id, "selection_status"] <<- "SELECTED"
      data.frame(task_id = picked$task_id, selection_status = "QUALIFIED", selected_start_id = picked$start_id,
        selected_objective = picked$objective, selected_pdHess = picked$pdHess,
        selected_max_abs_gradient = picked$max_gradient, alpha_mu = picked$alpha_mu,
        alpha_sigma = picked$alpha_sigma, sd_mu = picked$sd_mu, sd_sigma = picked$sd_sigma,
        mu_intercept = picked$mu_intercept, logsigma_intercept = picked$logsigma_intercept,
        diagnostic_class = picked$design_class, stringsAsFactors = FALSE)
    } else {
      data.frame(task_id = x$task_id[[1L]], selection_status = "NO_QUALIFIED_START", selected_start_id = NA_character_,
        selected_objective = NA_real_, selected_pdHess = NA, selected_max_abs_gradient = NA_real_,
        alpha_mu = NA_real_, alpha_sigma = NA_real_, sd_mu = NA_real_, sd_sigma = NA_real_,
        mu_intercept = NA_real_, logsigma_intercept = NA_real_, diagnostic_class = x$design_class[[1L]], stringsAsFactors = FALSE)
    }
  }))
  utils::write.csv(attempts, file.path(out_dir, "attempts.csv"), row.names = FALSE)
  utils::write.csv(selected, file.path(out_dir, "selected-fits.csv"), row.names = FALSE)
  diagnostics <- do.call(rbind, lapply(split(attempts, attempts$task_id), function(x) data.frame(
    task_id = x$task_id[[1L]], design_class = x$design_class[[1L]],
    finite_objective_any = any(is.finite(x$objective)), converged_any = any(x$convergence == 0L, na.rm = TRUE),
    pdHess_any = any(x$pdHess, na.rm = TRUE), qualified_start_count = sum(x$selection_status == "SELECTED"),
    warning_count = sum(nzchar(x$warnings)), boundary_count = sum(x$boundary, na.rm = TRUE),
    attempt_count = nrow(x), negative_control_interpretation = ifelse(x$design_class[[1L]] == "negative_control", "weak_identification_expected", "not_applicable"), stringsAsFactors = FALSE)))
  utils::write.csv(diagnostics, file.path(out_dir, "diagnostics.csv"), row.names = FALSE)
  artifact_files <- list.files(out_dir, recursive = TRUE, full.names = TRUE)
  artifact_files <- artifact_files[!basename(artifact_files) %in% c("DATA-SHA256SUMS", "SOURCE-PROVENANCE.tsv", "RESULTS.md")]
  sums <- vapply(artifact_files, sha256_file, character(1L))
  writeLines(paste(sums, sub(paste0("^", out_dir, "/"), "", artifact_files)), file.path(out_dir, "DATA-SHA256SUMS"))
  provenance <- c(
    paste("source_commit", system2("git", c("rev-parse", "HEAD"), stdout = TRUE), sep = "\t"),
    paste("source_dirty", length(system2("git", c("status", "--porcelain"), stdout = TRUE)) > 0L, sep = "\t"),
    paste("runner_sha256", sha256_file("tools/run-phylo-ou-sigma-recovery-calibration.R"), sep = "\t"),
    paste("design_sha256", sha256_file("docs/design/263-phylo-ou-sigma-recovery-calibration.md"), sep = "\t"),
    paste("r_version", R.version.string, sep = "\t"), paste("platform", R.version$platform, sep = "\t"),
    paste("drmTMB_version", as.character(utils::packageVersion("drmTMB")), sep = "\t"),
    paste("drmTMB_dll_sha256", {
      dll <- getLoadedDLLs()[["drmTMB"]]
      if (is.null(dll) || !file.exists(dll[["path"]])) NA_character_ else sha256_file(dll[["path"]])
    }, sep = "\t"),
    paste("command", paste(commandArgs(), collapse = " "), sep = "\t"),
    paste("run_started_utc", format(run_started, tz = "UTC", usetz = TRUE), sep = "\t"),
    paste("elapsed_total_seconds", elapsed_total, sep = "\t"))
  writeLines(provenance, file.path(out_dir, "SOURCE-PROVENANCE.tsv"))
  ordinary_selected <- sum(selected$selection_status == "QUALIFIED" & selected$diagnostic_class == "ordinary")
  negative_selected <- sum(selected$selection_status == "QUALIFIED" & selected$diagnostic_class == "negative_control")
  writeLines(c(
    "# OU v1 G14 local calibration", "",
    "This is a deterministic 54-attempt local calibration, not a retained multi-seed recovery campaign or public capability claim.", "",
    sprintf("Ordinary tasks: %d; negative-control tasks: %d; attempts: %d.", sum(all_conditions$design_class == "ordinary"), sum(all_conditions$design_class == "negative_control"), nrow(attempts)),
    sprintf("Qualified selected fits: ordinary %d/%d; negative controls %d/%d.", ordinary_selected, sum(all_conditions$design_class == "ordinary"), negative_selected, sum(all_conditions$design_class == "negative_control")),
    "Warnings, boundary estimates, and failed starts remain in attempts.csv and are not discarded.",
    "The calibration selects no recovery, interval, model-selection, or public-capability conclusion."
  ), file.path(out_dir, "RESULTS.md"))
}

all_conditions <- conditions()
if (identical(mode, "--smoke")) {
  selected <- rbind(
    all_conditions[all_conditions$design_class == "ordinary", ][1L, ],
    all_conditions[all_conditions$design_class == "negative_control", ][1L, ]
  )
} else if (identical(mode, "--preflight")) {
  selected <- all_conditions[
    all_conditions$design_class == "ordinary" & all_conditions$n_species == 64L &
      all_conditions$n_each == 12L,
  ]
} else selected <- all_conditions

attempts <- do.call(rbind, lapply(seq_len(nrow(selected)), function(i) {
  do.call(rbind, lapply(names(starts), function(start_id) {
    fit_one(selected[i, ], start_id, starts[[start_id]])
  }))
}))
git_dirty <- length(system2("git", c("status", "--porcelain"), stdout = TRUE)) > 0L
manifest <- data.frame(
  source_commit = system2("git", c("rev-parse", "HEAD"), stdout = TRUE),
  source_dirty = git_dirty,
  runner_md5 = unname(tools::md5sum("tools/run-phylo-ou-sigma-recovery-calibration.R")),
  contract_md5 = unname(tools::md5sum("docs/design/263-phylo-ou-sigma-recovery-calibration.md")),
  command = paste(commandArgs(), collapse = " "),
  run_started_utc = format(run_started, tz = "UTC", usetz = TRUE),
  r_version = R.version.string,
  platform = R.version$platform,
  ape_version = as.character(utils::packageVersion("ape")),
  drmTMB_dll_md5 = {
    dll <- getLoadedDLLs()[["drmTMB"]]
    if (is.null(dll) || !file.exists(dll[["path"]])) NA_character_ else unname(tools::md5sum(dll[["path"]]))
  },
  mode = mode, tree_scaling = "height_one", root = "stationary",
  stringsAsFactors = FALSE
)
elapsed_total <- as.numeric(difftime(Sys.time(), run_started, units = "secs"))
overhead_seconds <- max(0, elapsed_total - sum(attempts$elapsed_seconds, na.rm = TRUE))
if (identical(mode, "--preflight")) {
  # Sixteen ordinary and two negative-control tasks, each with three starts.
  # The slower observed fit plus measured one-time overhead is conservative.
  projected_seconds <- 54 * max(attempts$elapsed_seconds, na.rm = TRUE) + overhead_seconds
  preflight <- data.frame(
    preflight_fits = nrow(attempts), calibration_fits = 54L,
    elapsed_total_seconds = elapsed_total, overhead_seconds = overhead_seconds,
    slowest_fit_seconds = max(attempts$elapsed_seconds, na.rm = TRUE),
    projected_calibration_seconds = projected_seconds,
    within_local_25_minutes = projected_seconds <= 25 * 60,
    campaign_launch = FALSE, stringsAsFactors = FALSE
  )
  utils::write.csv(preflight, file.path(out_dir, "preflight-summary.csv"), row.names = FALSE)
}
if (identical(mode, "--calibration")) write_calibration_artifacts(all_conditions, attempts, run_started, elapsed_total)
utils::write.csv(all_conditions, file.path(out_dir, "conditions.csv"), row.names = FALSE)
utils::write.csv(attempts, file.path(out_dir, paste0(sub("--", "", mode), "-attempts.csv")), row.names = FALSE)
utils::write.csv(manifest, file.path(out_dir, paste0(sub("--", "", mode), "-manifest.csv")), row.names = FALSE)
cat(sprintf("PHYLO_OU_SIGMA_R1_%s_PASS fits=%d output=%s\n",
  toupper(sub("--", "", mode)), nrow(attempts), normalizePath(out_dir)))

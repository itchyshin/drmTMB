#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) args[[1L]] else "--preflight"
if (!mode %in% c("--contract", "--preflight", "--local")) {
  stop("Usage: Rscript tools/run-phylo-ou-r2-information-preflight.R [--contract|--preflight|--local]", call. = FALSE)
}
if (identical(mode, "--contract")) {
  cat("OU_V1_R2_RUNNER_CONTRACT_PASS\n")
  quit(status = 0L)
}
if (!requireNamespace("ape", quietly = TRUE) || !requireNamespace("pkgload", quietly = TRUE)) {
  stop("R2 needs ape and pkgload.", call. = FALSE)
}

out_dir <- file.path("docs", "dev-log", "evidence", "ou-v1-r2")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
run_started <- Sys.time()
pkgload::load_all(".", compile = TRUE, quiet = TRUE)

starts <- list(
  low = list(alpha = c(0.4, 0.4), sd = c(0.25, 0.15)),
  middle = list(alpha = c(1, 1), sd = c(0.45, 0.25)),
  high = list(alpha = c(2, 2), sd = c(0.70, 0.40))
)
rate_key <- function(x) sub("\\.", "p", formatC(x, format = "f", digits = 1L))
sha256_file <- function(path) {
  line <- system2("shasum", c("-a", "256", path), stdout = TRUE, stderr = TRUE)
  if (length(line) != 1L || !grepl("^[[:xdigit:]]{64} ", line)) stop("SHA-256 failed.", call. = FALSE)
  sub(" .*", "", line)
}

conditions <- function() {
  truth <- data.frame(alpha_mu_truth = c(0.7, 1.3), alpha_sigma_truth = c(1.3, 0.7))
  out <- do.call(rbind, lapply(seq_len(nrow(truth)), function(rate_id) {
    data.frame(rate_id = rate_id, replicate_id = 1:5,
      alpha_mu_truth = truth$alpha_mu_truth[[rate_id]], alpha_sigma_truth = truth$alpha_sigma_truth[[rate_id]],
      tree_field_seed = 2026091300L + 100L * rate_id + 1:5, stringsAsFactors = FALSE)
  }))
  out$n_species <- 128L; out$n_each <- 12L
  out$tree_id <- sprintf("r2_tree_rate%d_rep%d", out$rate_id, out$replicate_id)
  out$task_id <- sprintf("R2_n128_m12_amu%s_asigma%s_rep%d", rate_key(out$alpha_mu_truth), rate_key(out$alpha_sigma_truth), out$replicate_id)
  out
}

payload <- function(row) {
  set.seed(row$tree_field_seed)
  tree <- ape::rcoal(row$n_species)
  tree$tip.label <- sprintf("sp%03d", seq_len(row$n_species))
  raw_height <- max(ape::node.depth.edgelength(tree)[seq_len(row$n_species)])
  tree$edge.length <- tree$edge.length / raw_height
  distance <- ape::cophenetic.phylo(tree)
  draw_field <- function(alpha, sd, seed) {
    set.seed(seed)
    drop(t(chol(exp(-alpha * distance))) %*% stats::rnorm(row$n_species, sd = sd))
  }
  u <- draw_field(row$alpha_mu_truth, 0.45, row$tree_field_seed + 100000L)
  v <- draw_field(row$alpha_sigma_truth, 0.25, row$tree_field_seed + 200000L)
  species <- rep(tree$tip.label, each = row$n_each)
  index <- match(species, tree$tip.label)
  set.seed(row$tree_field_seed + 300000L)
  dat <- data.frame(y = u[index] + stats::rnorm(length(index), sd = exp(-1 + v[index])), species = species)
  list(tree = tree, data = dat, u = u, v = v, raw_height = raw_height)
}

fit_one <- function(row, start_id) {
  p <- payload(row); warnings <- character(); begun <- Sys.time(); cpu <- proc.time()
  formula <- bf(y ~ phylo(1 | species, tree = p$tree, model = "ou"), sigma ~ phylo(1 | species, tree = p$tree, model = "ou"))
  control <- drmTMB:::drm_parse_control(drm_control(optimizer = list(eval.max = 1500, iter.max = 1500)))
  spec <- drmTMB:::drm_build_gaussian_ls_spec(formula, p$data, env = environment(), weights = NULL,
    control = control, impute = NULL, missing = drmTMB:::drm_parse_missing_control(miss_control()))
  fields <- drmTMB:::phylo_ou_provider_fields(spec$structured$phylo_mu)
  if (!identical(unname(vapply(fields, `[[`, character(1L), "dpar")), c("mu", "sigma")) ||
      !identical(unname(vapply(fields, `[[`, integer(1L), "alpha_index0")), 0:1)) stop("R2 field-rate registry mismatch.", call. = FALSE)
  start <- starts[[start_id]]
  spec$start$beta_mu <- 0; spec$start$beta_sigma <- -1
  spec$start$log_sd_phylo <- log(start$sd); spec$start$log_decay_phylo <- log(start$alpha)
  fit <- tryCatch(withCallingHandlers(drmTMB:::drm_fit_spec(spec, formula, gaussian(), control, REML = FALSE,
    penalty = NULL, estimator = "ml"), warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning") }), error = identity)
  elapsed <- as.numeric(difftime(Sys.time(), begun, units = "secs")); cpu_elapsed <- proc.time() - cpu
  common <- data.frame(task_id = row$task_id, rate_id = row$rate_id, replicate_id = row$replicate_id,
    tree_id = row$tree_id, tree_field_seed = row$tree_field_seed, n_species = row$n_species, n_each = row$n_each,
    alpha_mu_truth = row$alpha_mu_truth, alpha_sigma_truth = row$alpha_sigma_truth, start_id = start_id,
    start_alpha_mu = start$alpha[[1L]], start_alpha_sigma = start$alpha[[2L]], start_sd_mu = start$sd[[1L]], start_sd_sigma = start$sd[[2L]],
    elapsed_seconds = elapsed, cpu_seconds = unname(cpu_elapsed[["user.self"]] + cpu_elapsed[["sys.self"]]), warnings = paste(warnings, collapse = " | "), stringsAsFactors = FALSE)
  if (inherits(fit, "error")) return(cbind(common, attempt_status = "ERROR", convergence = NA_integer_, pdHess = NA,
    max_gradient = NA_real_, objective = NA_real_, alpha_mu = NA_real_, alpha_sigma = NA_real_, sd_mu = NA_real_, sd_sigma = NA_real_, boundary_mu = NA, boundary_sigma = NA, error = conditionMessage(fit)))
  alpha_mu <- unname(fit$decaypars$phylo[["decay_phylo"]]); alpha_sigma <- unname(fit$decaypars$phylo[["decay_phylo:sigma"]])
  boundary_mu <- alpha_mu < 0.02 || alpha_mu > 50; boundary_sigma <- alpha_sigma < 0.02 || alpha_sigma > 50
  cbind(common, attempt_status = "FIT", convergence = fit$opt$convergence, pdHess = isTRUE(fit$sdr$pdHess),
    max_gradient = max(abs(fit$obj$gr(fit$opt$par))), objective = fit$opt$objective, alpha_mu = alpha_mu, alpha_sigma = alpha_sigma,
    sd_mu = unname(fit$sdpars$mu[[1L]]), sd_sigma = unname(fit$sdpars$sigma[[1L]]), boundary_mu = boundary_mu, boundary_sigma = boundary_sigma, error = NA_character_)
}

write_artifacts <- function(all, attempts) {
  for (d in c("trees", "data", "fields")) dir.create(file.path(out_dir, d), showWarnings = FALSE)
  manifest <- do.call(rbind, lapply(seq_len(nrow(all)), function(i) {
    row <- all[i, , drop = FALSE]; p <- payload(row)
    tree_path <- file.path(out_dir, "trees", paste0(row$tree_id, ".nwk")); data_path <- file.path(out_dir, "data", paste0(row$task_id, ".csv"))
    ape::write.tree(p$tree, tree_path); utils::write.csv(p$data, data_path, row.names = FALSE)
    utils::write.csv(data.frame(species = p$tree$tip.label, u = p$u), file.path(out_dir, "fields", paste0(row$task_id, "-u.csv")), row.names = FALSE)
    utils::write.csv(data.frame(species = p$tree$tip.label, v = p$v), file.path(out_dir, "fields", paste0(row$task_id, "-v.csv")), row.names = FALSE)
    cbind(row, sd_mu_truth = 0.45, sd_sigma_truth = 0.25, data_sha256 = sha256_file(data_path), tree_sha256 = sha256_file(tree_path))
  }))
  starts_table <- do.call(rbind, lapply(all$task_id, function(task_id) do.call(rbind, lapply(names(starts), function(id) {
    s <- starts[[id]]; data.frame(task_id, start_id = id, alpha_mu_start = s$alpha[[1L]], alpha_sigma_start = s$alpha[[2L]], sd_mu_start = s$sd[[1L]], sd_sigma_start = s$sd[[2L]])
  }))))
  selected <- do.call(rbind, lapply(split(attempts, attempts$task_id), function(x) {
    ok <- x[x$attempt_status == "FIT" & x$convergence == 0L & x$pdHess & !x$boundary_mu & !x$boundary_sigma & is.finite(x$objective), , drop = FALSE]
    if (!nrow(ok)) return(data.frame(task_id = x$task_id[[1L]], selection_status = "NO_QUALIFIED_START", selected_start_id = NA_character_, alpha_mu = NA_real_, alpha_sigma = NA_real_, abs_log_error_mu = NA_real_, abs_log_error_sigma = NA_real_))
    z <- ok[which.min(ok$objective), , drop = FALSE]; data.frame(task_id = z$task_id, selection_status = "QUALIFIED", selected_start_id = z$start_id, alpha_mu = z$alpha_mu, alpha_sigma = z$alpha_sigma, abs_log_error_mu = abs(log(z$alpha_mu / z$alpha_mu_truth)), abs_log_error_sigma = abs(log(z$alpha_sigma / z$alpha_sigma_truth)))
  }))
  diagnostics <- do.call(rbind, lapply(split(attempts, attempts$task_id), function(x) data.frame(task_id = x$task_id[[1L]], attempt_count = nrow(x), qualified_count = sum(x$attempt_status == "FIT" & x$convergence == 0L & x$pdHess & !x$boundary_mu & !x$boundary_sigma, na.rm = TRUE), warning_count = sum(nzchar(x$warnings)), boundary_count = sum(x$boundary_mu | x$boundary_sigma, na.rm = TRUE))))
  utils::write.csv(manifest, file.path(out_dir, "manifest.csv"), row.names = FALSE); utils::write.csv(starts_table, file.path(out_dir, "starts.csv"), row.names = FALSE)
  utils::write.csv(attempts, file.path(out_dir, "attempts.csv"), row.names = FALSE); utils::write.csv(selected, file.path(out_dir, "selected-fits.csv"), row.names = FALSE); utils::write.csv(diagnostics, file.path(out_dir, "diagnostics.csv"), row.names = FALSE)
  files <- list.files(out_dir, recursive = TRUE, full.names = TRUE); files <- files[!basename(files) %in% c("DATA-SHA256SUMS", "SOURCE-PROVENANCE.tsv", "RESULTS.md")]
  writeLines(paste(vapply(files, sha256_file, character(1L)), sub(paste0("^", out_dir, "/"), "", files)), file.path(out_dir, "DATA-SHA256SUMS"))
  writeLines(c(paste("source_commit", system2("git", c("rev-parse", "HEAD"), stdout = TRUE), sep = "\t"), paste("source_dirty", length(system2("git", c("status", "--porcelain", "--untracked-files=no"), stdout = TRUE)) > 0L, sep = "\t"), paste("runner_sha256", sha256_file("tools/run-phylo-ou-r2-information-preflight.R"), sep = "\t"), paste("command", paste(commandArgs(), collapse = " "), sep = "\t"), paste("run_started_utc", format(run_started, tz = "UTC", usetz = TRUE), sep = "\t")), file.path(out_dir, "SOURCE-PROVENANCE.tsv"))
  qualified <- selected[selected$selection_status == "QUALIFIED", , drop = FALSE]
  writeLines(c("# OU v1 R2 information preflight", "", "This is an information screen, not a recovery or G15 promotion claim.", sprintf("Tasks: %d; attempts: %d; qualified tasks: %d.", nrow(all), nrow(attempts), nrow(qualified)), sprintf("Median absolute log-rate error: alpha_mu %.3f; alpha_sigma %.3f.", stats::median(qualified$abs_log_error_mu), stats::median(qualified$abs_log_error_sigma)), sprintf("Maximum absolute log-rate error: alpha_mu %.3f; alpha_sigma %.3f.", max(qualified$abs_log_error_mu), max(qualified$abs_log_error_sigma))), file.path(out_dir, "RESULTS.md"))
}

all <- conditions(); selected <- if (identical(mode, "--preflight")) all[1L, , drop = FALSE] else all
attempts <- do.call(rbind, lapply(seq_len(nrow(selected)), function(i) do.call(rbind, lapply(names(starts), function(id) fit_one(selected[i, ], id)))))
elapsed_total <- as.numeric(difftime(Sys.time(), run_started, units = "secs"))
if (identical(mode, "--preflight")) {
  estimate <- 30 * max(attempts$elapsed_seconds) + max(0, elapsed_total - sum(attempts$elapsed_seconds))
  utils::write.csv(data.frame(preflight_attempts = nrow(attempts), projected_r2_seconds = estimate, within_30_minutes = estimate <= 1800), file.path(out_dir, "preflight.csv"), row.names = FALSE)
  utils::write.csv(attempts, file.path(out_dir, "preflight-attempts.csv"), row.names = FALSE)
} else write_artifacts(all, attempts)
cat(sprintf("OU_V1_R2_%s_PASS attempts=%d output=%s\n", toupper(sub("--", "", mode)), nrow(attempts), normalizePath(out_dir)))

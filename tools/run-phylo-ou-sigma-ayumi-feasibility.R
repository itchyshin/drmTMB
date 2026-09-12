#!/usr/bin/env Rscript

# Bounded real-data feasibility receipt for the OU-sigma G13 model.  The
# all-species data have one observation per tip, so this is deliberately not
# an alpha-recovery or OU-selection analysis.

args <- commandArgs(trailingOnly = TRUE)
full <- "--full" %in% args
tip_arg <- grep("^--tips=", args, value = TRUE)
n_tip <- if (full) {
  NA_integer_
} else if (length(tip_arg) == 1L) {
  as.integer(sub("^--tips=", "", tip_arg))
} else {
  500L
}
if (!is.na(n_tip) && (!is.finite(n_tip) || n_tip < 4L)) {
  stop("--tips must be an integer of at least four.", call. = FALSE)
}

data_path <- "/private/tmp/LS_ecogeographical-rules/data/derived/ecogeo_species_traits_climate_v1.rds"
tree_path <- "/private/tmp/LS_ecogeographical-rules/data/derived/ecogeo_tree_main_v1.rds"
repo_path <- "/private/tmp/LS_ecogeographical-rules"
out <- "/private/tmp/phylo-ou-sigma-ayumi-receipt"
if (!file.exists(data_path) || !file.exists(tree_path)) {
  stop("Ayumi data/tree receipt inputs are unavailable at the recorded paths.", call. = FALSE)
}
if (!requireNamespace("ape", quietly = TRUE) || !requireNamespace("pkgload", quietly = TRUE)) {
  stop("This feasibility fit needs ape and pkgload.", call. = FALSE)
}

sha256 <- function(path) {
  output <- suppressWarnings(system2("shasum", c("-a", "256", path), stdout = TRUE))
  sub("[[:space:]].*$", "", output[[1L]])
}
repo_commit <- function(path) {
  output <- suppressWarnings(system2("git", c("-C", path, "rev-parse", "HEAD"), stdout = TRUE))
  output[[1L]]
}

pkgload::load_all(".", compile = TRUE, quiet = TRUE)
raw_data <- readRDS(data_path)
raw_tree <- readRDS(tree_path)
required <- c("tree_tip", "log_mass_z", "mean_tavg_combined_z", "mean_prec_combined_z")
if (!all(required %in% names(raw_data))) {
  stop("Ayumi data receipt lacks the required body-mass/climate columns.", call. = FALSE)
}
if (!inherits(raw_tree, "phylo")) stop("Ayumi tree receipt is not an ape phylo object.", call. = FALSE)

data <- raw_data[, required, drop = FALSE]
names(data) <- c("species", "y", "temperature", "precipitation")
keep <- stats::complete.cases(data) & data$species %in% raw_tree$tip.label
data <- data[keep, , drop = FALSE]
if (anyDuplicated(data$species)) stop("Expected one Ayumi record per species.", call. = FALSE)
data <- data[match(raw_tree$tip.label, data$species, nomatch = 0L), , drop = FALSE]
if (nrow(data) != length(raw_tree$tip.label)) {
  stop("Ayumi data/tree did not retain an identical observed-tip set.", call. = FALSE)
}
if (!is.na(n_tip)) {
  selected_tip <- raw_tree$tip.label[seq_len(min(n_tip, length(raw_tree$tip.label)))]
  tree <- ape::keep.tip(raw_tree, selected_tip)
  data <- data[match(tree$tip.label, data$species), , drop = FALSE]
} else {
  tree <- raw_tree
}
if (!identical(as.character(data$species), tree$tip.label)) {
  stop("Feasibility data rows are not in exact tree-tip order.", call. = FALSE)
}

dir.create(out, recursive = TRUE, showWarnings = FALSE)
label <- if (full) "all-species" else sprintf("preflight-%d-tip", nrow(data))
control_used <- list(eval.max = 1000L, iter.max = 1000L)
fit_warnings <- character()
fit_time <- system.time({
  fit <- withCallingHandlers(
    drmTMB(
      bf(
        y ~ temperature + I(temperature^2) + precipitation + I(precipitation^2) +
          phylo(1 | species, tree = tree, model = "ou"),
        sigma ~ temperature + precipitation +
          phylo(1 | species, tree = tree, model = "ou")
      ),
      data = data,
      family = gaussian(),
      REML = FALSE,
      control = drm_control(optimizer = control_used)
    ),
    warning = function(warning) {
      fit_warnings <<- c(fit_warnings, conditionMessage(warning))
      invokeRestart("muffleWarning")
    }
  )
})
max_gradient <- max(abs(fit$obj$gr(fit$opt$par)))

summary_row <- data.frame(
  label = label,
  scope = if (full) "all_species_one_row_per_tip_feasibility" else "deterministic_real_data_subtree_preflight",
  n_rows = nrow(data),
  n_tips = length(tree$tip.label),
  convergence = fit$opt$convergence,
  pdHess = isTRUE(fit$sdr$pdHess),
  logLik = as.numeric(stats::logLik(fit)),
  AIC = stats::AIC(fit),
  alpha_mu = unname(fit$decaypars$phylo[["decay_phylo"]]),
  alpha_sigma = unname(fit$decaypars$phylo[["decay_phylo:sigma"]]),
  max_gradient = max_gradient,
  REML = FALSE,
  optimizer_eval_max = control_used$eval.max,
  optimizer_iter_max = control_used$iter.max,
  warning_count = length(fit_warnings),
  elapsed_seconds = fit_time[["elapsed"]],
  data_sha256 = sha256(data_path),
  tree_sha256 = sha256(tree_path),
  source_commit = repo_commit(repo_path),
  drmTMB_commit = repo_commit("."),
  stringsAsFactors = FALSE
)
utils::write.csv(summary_row, file.path(out, paste0(label, ".csv")), row.names = FALSE)
saveRDS(list(
  receipt = summary_row,
  formula = "y ~ temperature + I(temperature^2) + precipitation + I(precipitation^2) + phylo(1 | species, tree = tree, model = 'ou'); sigma ~ temperature + precipitation + phylo(1 | species, tree = tree, model = 'ou')",
  source = list(data_path = data_path, tree_path = tree_path, repo_path = repo_path),
  controls = list(REML = FALSE, optimizer = control_used),
  warnings = fit_warnings
), file.path(out, paste0(label, ".rds")))
cat(sprintf(
  "PHYLO_OU_SIGMA_AYUMI_%s_PASS rows=%d tips=%d elapsed_seconds=%.3f convergence=%d pdHess=%s\\n",
  if (full) "FULL" else "PREFLIGHT", nrow(data), length(tree$tip.label),
  fit_time[["elapsed"]], fit$opt$convergence, isTRUE(fit$sdr$pdHess)
))

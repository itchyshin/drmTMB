#!/usr/bin/env Rscript

# Reproducible four-fit feasibility ladder for Ayumi's all-species body-mass
# inputs.  The script needs an explicit clone of
# Ayumi-495/LS_ecogeographical-rules and never treats an empirical fit as
# recovery or interval evidence.
#
# Usage:
#   Rscript tools/phylo-ou-ayumi-bodymass-ladder.R /path/to/LS_ecogeographical-rules /output/path

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop(
    "Usage: Rscript tools/phylo-ou-ayumi-bodymass-ladder.R <Ayumi-repo> <output-dir>",
    call. = FALSE
  )
}
source_repo <- normalizePath(args[[1L]], mustWork = TRUE)
output_dir <- args[[2L]]
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
source_commit <- tryCatch(
  system2("git", c("-C", source_repo, "rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE),
  error = function(e) NA_character_
)
source_commit <- if (length(source_commit) == 1L && grepl("^[0-9a-f]{40}$", source_commit)) {
  source_commit
} else {
  NA_character_
}

required <- c("ape", "digest", "pkgload")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Missing packages: ", paste(missing, collapse = ", "))
pkgload::load_all(".", compile = TRUE, quiet = TRUE)

data_file <- file.path(source_repo, "data", "derived", "ecogeo_species_traits_climate_v1.rds")
tree_file <- file.path(source_repo, "data", "derived", "ecogeo_tree_main_v1.rds")
if (!file.exists(data_file) || !file.exists(tree_file)) {
  stop("Ayumi all-species derived data/tree files are unavailable.", call. = FALSE)
}
dat <- readRDS(data_file)
tree <- readRDS(tree_file)
temp <- "mean_tavg_combined_z"
prec <- "mean_prec_combined_z"
y <- "log_mass_z"
needed <- c("tree_tip", y, temp, prec)
if (!all(needed %in% names(dat))) stop("Required body-mass fields are absent.", call. = FALSE)
dat <- dat[
  is.finite(dat[[y]]) & is.finite(dat[[temp]]) & is.finite(dat[[prec]]) &
    dat$tree_tip %in% tree$tip.label,
  , drop = FALSE
]
tree <- ape::keep.tip(tree, dat$tree_tip)
dat <- dat[match(tree$tip.label, dat$tree_tip), , drop = FALSE]
if (!identical(dat$tree_tip, tree$tip.label) || !ape::is.ultrametric(tree)) {
  stop("Rows and tree tips do not align on an ultrametric tree.", call. = FALSE)
}
dat$phylo_id <- factor(dat$tree_tip, levels = tree$tip.label)

fit_one <- function(model, residual_scale) {
  mu <- as.formula(sprintf(
    "%s ~ 1 + %s + I(%s^2) + %s + I(%s^2) + phylo(1 | phylo_id, tree = tree, model = '%s')",
    y, temp, temp, prec, prec, model
  ))
  direct_sd <- as.formula(sprintf("sd(phylo_id, level = 'phylogenetic') ~ %s + %s", temp, prec))
  sigma <- if (identical(residual_scale, "constant")) ~ 1 else {
    as.formula(sprintf("~ %s + %s", temp, prec))
  }
  form <- do.call(bf, list(mu, sigma = sigma, direct_sd))
  warnings <- character()
  started <- Sys.time()
  fit <- withCallingHandlers(
    tryCatch(
      drmTMB(
        form, family = gaussian(), data = dat, REML = TRUE,
        control = drm_control(optimizer_preset = "default", fallback_optimizer = "BFGS")
      ),
      error = identity
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  if (inherits(fit, "error")) {
    return(list(
      receipt = data.frame(model, residual_scale, elapsed_seconds = elapsed,
        fit_ok = FALSE, error = conditionMessage(fit), stringsAsFactors = FALSE),
      fit = NULL, warnings = warnings
    ))
  }
  diagnostics <- check_drm(fit)
  list(
    receipt = data.frame(
      model, residual_scale, elapsed_seconds = elapsed, fit_ok = TRUE,
      convergence = fit$opt$convergence, pdHess = isTRUE(fit$sdr$pdHess),
      max_gradient = max(abs(fit$obj$gr(fit$opt$par))),
      logLik = as.numeric(logLik(fit)),
      decay_phylo = if (identical(model, "ou")) fit$decaypars$phylo[["decay_phylo"]] else NA_real_,
      check_drm_warning_count = sum(diagnostics$status == "warning"),
      check_drm_error_count = sum(diagnostics$status == "error"),
      stringsAsFactors = FALSE
    ),
    fit = fit, warnings = warnings
  )
}

cells <- expand.grid(
  model = c("bm", "ou"), residual_scale = c("constant", "climate"),
  stringsAsFactors = FALSE
)
rows <- vector("list", nrow(cells))
for (i in seq_len(nrow(cells))) {
  id <- paste(cells$model[[i]], cells$residual_scale[[i]], sep = "_")
  ans <- fit_one(cells$model[[i]], cells$residual_scale[[i]])
  rows[[i]] <- ans$receipt
  saveRDS(ans, file.path(output_dir, paste0(id, ".rds")))
}
receipt <- list(
  source_repo = source_repo,
  source_commit = source_commit,
  data_file = data_file,
  tree_file = tree_file,
  data_sha256 = digest::digest(file = data_file, algo = "sha256"),
  tree_sha256 = digest::digest(file = tree_file, algo = "sha256"),
  rows = nrow(dat), tips = length(tree$tip.label), REML = TRUE,
  formula = "log_mass_z ~ temperature + temperature^2 + precipitation + precipitation^2 + phylo; sigma constant or climate; direct phylogenetic SD climate",
  receipt_schema_version = 1L,
  results = do.call(rbind, rows),
  claim_boundary = "Empirical feasibility only: no recovery, interval, or universal BM-versus-OU claim."
)
saveRDS(receipt, file.path(output_dir, "receipt.rds"))
write.csv(receipt$results, file.path(output_dir, "receipt.csv"), row.names = FALSE)
writeLines(capture.output(str(receipt, max.level = 3L)), file.path(output_dir, "receipt.txt"))
cat(sprintf("AYUMI_BODYMASS_PHYLO_OU_LADDER_PASS rows=%d tips=%d output=%s\n",
  receipt$rows, receipt$tips, normalizePath(output_dir)
))

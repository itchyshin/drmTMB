#!/usr/bin/env Rscript
## Summarise a coverage grid produced by run_grid.R into (a) a per-measure x per-
## parameter coverage summary and (b) a headline "how many tests" count. Joins each
## measure's Wald-coverage CSV to its DGP conditions (conditions-map.csv if present,
## else regenerated from the same presets used by run_grid.R).
## Usage: Rscript summarise_grid.R <grid_out_dir> [out_csv_dir]

suppressWarnings(suppressMessages(library(drmTMB)))
args <- commandArgs(trailingOnly = TRUE)
grid_dir <- if (length(args) >= 1) args[[1]] else stop("give the grid output dir")
out_dir  <- if (length(args) >= 2) args[[2]] else grid_dir

## presets must match run_grid.R (used only when conditions-map.csv is absent)
measures <- list(
  SMD    = list(beta_mu_intercept = 0.30, beta_mu_x = 0.40, sampling_sd = c(0.12, 0.22)),
  lnRR   = list(beta_mu_intercept = 0.15, beta_mu_x = 0.25, sampling_sd = c(0.08, 0.18)),
  logOR  = list(beta_mu_intercept = 0.50, beta_mu_x = 0.60, sampling_sd = c(0.20, 0.40)),
  logIRR = list(beta_mu_intercept = 0.20, beta_mu_x = 0.35, sampling_sd = c(0.15, 0.30))
)
this_file <- sub("^--file=", "", commandArgs(FALSE)[grep("^--file=", commandArgs(FALSE))])
here <- if (length(this_file)) normalizePath(dirname(this_file)) else normalizePath(".")
sim_root <- normalizePath(file.path(here, "..", "..", "sim"))
source(file.path(sim_root, "dgp/sim_dgp_meta_v.R"))

present <- intersect(names(measures), list.dirs(grid_dir, recursive = FALSE, full.names = FALSE))
rows <- list()
for (m in present) {
  cov_csv <- file.path(grid_dir, m, "tables", "meta-v-wald-coverage.csv")
  if (!file.exists(cov_csv)) next
  cov <- utils::read.csv(cov_csv, stringsAsFactors = FALSE)
  map_csv <- file.path(grid_dir, m, "conditions-map.csv")
  if (file.exists(map_csv)) {
    cond <- utils::read.csv(map_csv, stringsAsFactors = FALSE)
  } else {
    mp <- measures[[m]]
    ## regenerate the axes run_grid.R uses at whatever tier produced these cells:
    ## infer axes from the coverage file's own cell count is fragile, so regenerate
    ## the LOCAL-tier grid (the only tier run without a map) and trust row order.
    cond <- phase18_meta_v_conditions(
      n_study = c(20L, 40L, 80L), known_v_type = "vector",
      sigma = c(0.0, 0.25, 0.50), sampling_sd = mp$sampling_sd, sampling_rho = c(0, 0.25),
      beta_mu_intercept = mp$beta_mu_intercept, beta_mu_x = mp$beta_mu_x)
    cond$cell_id <- sprintf("meta_v_%03d", seq_len(nrow(cond)))
  }
  j <- merge(cov, cond[, c("cell_id", "n_study", "sigma", "sampling_sd")], by = "cell_id")
  j$measure <- m
  rows[[m]] <- j
}
all <- do.call(rbind, rows)
if (is.null(all) || !nrow(all)) stop("no coverage cells found under ", grid_dir)

## per measure x parameter: pool cells (weight by intervals), and the across-cell range
agg <- do.call(rbind, lapply(split(all, list(all$measure, all$parameter), drop = TRUE), function(x) {
  n_int <- sum(x$n_interval); n_cov <- sum(x$n_covered)
  p <- n_cov / n_int
  data.frame(measure = x$measure[1], parameter = x$parameter[1],
             cells = nrow(x), intervals = n_int,
             coverage = p, mcse = sqrt(p * (1 - p) / n_int),
             min_cell = min(x$coverage), max_cell = max(x$coverage),
             stringsAsFactors = FALSE)
}))
agg <- agg[order(agg$measure, agg$parameter), ]
utils::write.csv(agg, file.path(out_dir, "grid-coverage-summary.csv"), row.names = FALSE)
utils::write.csv(all, file.path(out_dir, "grid-coverage-bycell.csv"), row.names = FALSE)

cat(sprintf("Measures: %s\n", paste(present, collapse = ", ")))
cat(sprintf("Total intervals (tests): %s across %d cells x %d parameters\n",
            format(sum(agg$intervals), big.mark = ","), length(unique(all$cell_id)),
            length(unique(all$parameter))))
cat("\nPooled Wald 95% coverage by measure x parameter:\n")
print(format(agg[, c("measure","parameter","cells","intervals","coverage","mcse","min_cell","max_cell")],
             digits = 3), row.names = FALSE)

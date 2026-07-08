#!/usr/bin/env Rscript
# gate-inference-ready-driver.R -- run the binding inference-ready gate over EVERY
# cell the board marks (or proposes) `inference_ready`, and write one machine-
# readable results table. This is Fisher's G4 recommendation (2026-07-08): the
# board's `CERTIFIED_INFERENCE_READY_CELLS` allowlist in validate-mission-control.py
# must be replaced by a computation that reads each cell's actual replicate file.
#
# It exists because `evidence_url` in the support-cells TSV is NOT a uniform data
# pointer -- the three cell groups use three schemas, and the q2 cells' evidence_url
# points at a design DOC, not data. So the cell -> real-file -> schema mapping is
# hard-coded here (see CELLS below) and each source is normalized to the canonical
# {channel}_lower/_upper + truth_sd form before `gate_one()` (sourced from
# tools/gate-inference-ready.R) is applied.
#
# Output: docs/dev-log/dashboard/inference-gate-results.tsv, one row per
#   (cell_id, member, channel): the gate metrics + status. A cell whose file is
#   absent (e.g. a campaign not yet run) is emitted with status = "pending_campaign"
#   -- fail-safe, never silently PASS.
#
# Run: OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null \
#        Rscript --no-init-file tools/gate-inference-ready-driver.R
# (No package load, no compile -- reads TSVs only. Safe to run while a sim campaign
#  is in flight.)

here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L]))
if (is.na(here) || !nzchar(here)) here <- "tools"
source(file.path(here, "gate-inference-ready.R"))   # gate_one(), gate_data_frame()

ART <- "docs/dev-log/simulation-artifacts"
G2  <- file.path(ART, "2026-07-08-g2-sigma-oneslope-adjudication")
MU  <- file.path(ART, "2026-06-30-gaussian-lowq-mu-intercept-topup-nibi", "results")
Q2  <- file.path(ART, "2026-06-27-bias-corrected-engine-coverage-g8", "replicates.tsv")

# ---- normalizers: each returns a data frame with {chan}_lower/_upper, truth_sd,
#      estimate_sd, plus an attribute `members` naming the (member, subset) splits.
read_tsv <- function(p) utils::read.delim(p, stringsAsFactors = FALSE, check.names = FALSE)

# sigma one-slope: the coverage-grid runner already emits the canonical schema.
gate_sigma_file <- function(cell_id, member, file, min_miss) {
  if (!file.exists(file)) {
    return(pending(cell_id, member, c("wald", "profile"), file))
  }
  d <- read_tsv(file)
  truth <- if ("truth_sd" %in% names(d)) d$truth_sd[[1L]] else NA_real_
  g <- gate_data_frame(d, truth, members = c("wald", "profile"), min_miss = min_miss)
  finish(cell_id, member, g, file)
}

# mu-intercept: single member, CI in conf.low/conf.high, one provider per file.
gate_mu_intercept_file <- function(cell_id, file, min_miss) {
  if (!file.exists(file)) return(pending(cell_id, "mu:(Intercept)", "default", file))
  d <- read_tsv(file)
  truth <- d$truth_sd_mu_intercept[[1L]]
  nd <- data.frame(default_lower = d$conf.low, default_upper = d$conf.high,
                   estimate_sd = d$estimate)
  g <- gate_data_frame(nd, truth, members = "default", min_miss = min_miss)
  finish(cell_id, "mu:(Intercept)", g, file)
}

# q2 mu1+mu2: filter provider, split by `target`, channels wald + bc, per-row truth.
gate_q2_provider <- function(cell_id, provider, file, min_miss) {
  if (!file.exists(file)) return(pending(cell_id, "mu1:x/mu2:x", c("wald", "bc"), file))
  d <- read_tsv(file)
  d <- d[d$provider == provider, , drop = FALSE]
  out <- list()
  for (tg in sort(unique(d$target))) {
    s <- d[d$target == tg, , drop = FALSE]
    nd <- data.frame(wald_lower = s$wald_lower, wald_upper = s$wald_upper,
                     bc_lower = s$bc_lower, bc_upper = s$bc_upper)
    g <- gate_data_frame(nd, s$truth[[1L]], members = c("wald", "bc"), min_miss = min_miss)
    out[[tg]] <- finish(cell_id, tg, g, file)
  }
  do.call(rbind, out)
}

pending <- function(cell_id, member, channels, file) {
  data.frame(cell_id = cell_id, member = member, channel = channels,
             n_fit = NA_integer_, finite_rate = NA_real_, coverage = NA_real_,
             mcse = NA_real_, n_high = NA_integer_, n_low = NA_integer_,
             ratio = NA_real_, binom_p = NA_real_, status = "pending_campaign",
             source_file = file, stringsAsFactors = FALSE)
}
finish <- function(cell_id, member, g, file) {
  if (is.null(g)) return(pending(cell_id, member, "?", file))
  data.frame(cell_id = cell_id, member = member, channel = g$member,
             n_fit = g$n_fit, finite_rate = g$finite_rate, coverage = g$coverage,
             mcse = g$mcse, n_high = g$n_high, n_low = g$n_low, ratio = g$ratio,
             binom_p = g$binom_p, status = g$status, source_file = file,
             stringsAsFactors = FALSE)
}

MIN_MISS <- as.integer(Sys.getenv("MIN_MISS", "40"))
rows <- list(
  # --- sigma one-slope (3 cells x 2 members): G2 output ---
  gate_sigma_file("qseries_phylo_q1_sigma_one_slope",  "sigma:(Intercept)", file.path(G2, "01-phylo-sigma_intercept-replicates.tsv"),  MIN_MISS),
  gate_sigma_file("qseries_phylo_q1_sigma_one_slope",  "sigma:x",           file.path(G2, "02-phylo-sigma_x-replicates.tsv"),          MIN_MISS),
  gate_sigma_file("qseries_animal_q1_sigma_one_slope", "sigma:(Intercept)", file.path(G2, "05-animal-sigma_intercept-replicates.tsv"), MIN_MISS),
  gate_sigma_file("qseries_relmat_q1_sigma_one_slope", "sigma:(Intercept)", file.path(G2, "06-relmat-sigma_intercept-replicates.tsv"), MIN_MISS),
  gate_sigma_file("qseries_relmat_q1_sigma_one_slope", "sigma:x",           file.path(G2, "07-relmat-sigma_x-replicates.tsv"),         MIN_MISS),
  # --- mu-intercept (3 cells): 2026-06-30 topup shards (PRE-Fisher-fix; needs re-run) ---
  gate_mu_intercept_file("qseries_phylo_q1_mu_intercept",   file.path(MU, "shard_1_phylo",   "structured-re-gaussian-lowq-mu-intercept-topup-results-replicates.tsv"), MIN_MISS),
  gate_mu_intercept_file("qseries_spatial_q1_mu_intercept", file.path(MU, "shard_2_spatial", "structured-re-gaussian-lowq-mu-intercept-topup-results-replicates.tsv"), MIN_MISS),
  gate_mu_intercept_file("qseries_relmat_q1_mu_intercept",  file.path(MU, "shard_4_relmat",  "structured-re-gaussian-lowq-mu-intercept-topup-results-replicates.tsv"), MIN_MISS),
  # --- q2 mu1+mu2 (2 cells): 2026-06-27 bias-corrected engine coverage ---
  gate_q2_provider("qseries_phylo_q2_mu1_mu2_one_slope",  "phylo",  Q2, MIN_MISS),
  gate_q2_provider("qseries_relmat_q2_mu1_mu2_one_slope", "relmat", Q2, MIN_MISS)
)
res <- do.call(rbind, rows)

out_path <- "docs/dev-log/dashboard/inference-gate-results.tsv"
utils::write.table(res, out_path, sep = "\t", row.names = FALSE, quote = FALSE)
cat("# inference-gate-results (min_miss =", MIN_MISS, ")  wrote", out_path, "\n\n")
print(res[, c("cell_id", "member", "channel", "coverage", "ratio", "binom_p", "status")],
      row.names = FALSE)
cat("\n# summary by cell (a cell is inference_ready only if EVERY member passes on >=1 channel):\n")
for (cid in unique(res$cell_id)) {
  s <- res[res$cell_id == cid, ]
  per_member <- split(s, s$member)
  mstat <- function(m) {
    if (any(m$status == "pending_campaign")) "PENDING"
    else if (any(m$status == "PASS")) "PASS"
    else if (any(m$status == "FAIL")) "FAIL"            # a real calibration failure on some channel
    else "INSUFFICIENT"                                   # underpowered / not evaluable
  }
  ms <- vapply(per_member, mstat, character(1))
  verdict <- if (any(ms == "PENDING")) "PENDING (campaign incomplete)"
             else if (any(ms == "FAIL")) "FAIL (miss-asymmetry on a member)"
             else if (all(ms == "PASS")) "PASS"
             else "INSUFFICIENT (underpowered; needs more reps)"
  cat(sprintf("  %-42s %s\n", cid, verdict))
}

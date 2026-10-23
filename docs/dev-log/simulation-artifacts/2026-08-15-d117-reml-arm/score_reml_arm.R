# Scorer for the D-117 REML arm. Applies the PRE-REGISTERED decision rule from
# PREREGISTRATION.md and checks the harness falsifiers FIRST -- if the ML control
# arm does not reproduce the banked numbers, or REML did not actually engage, the
# script says so and refuses to report a REML verdict.
#
#   Rscript --no-init-file score_reml_arm.R --results=<dir>

args <- commandArgs(trailingOnly = TRUE)
arg_of <- function(k, d = NA_character_) {
  h <- grep(sprintf("^--%s=", k), args, value = TRUE)
  if (!length(h)) return(d)
  sub(sprintf("^--%s=", k), "", h[[1L]])
}
res_dir <- arg_of("results", "results")

CELLS <- c("g10_n10_sd05", "g10_n04_sd05", "g10_n04_sd10", "g10_n10_sd10")
# Banked ML per-cell coverage, read off results/SUMMARY.csv of the 2026-08-09
# 100k re-gate. NAMED, not positional: the D-93 packet lists these four numbers
# in SUMMARY.csv's alphabetical cell order, which is NOT the cell-index order
# used by CELLS, and pairing them positionally silently mislabels three of four.
BANKED_ML <- c(g10_n04_sd05 = 0.92290, g10_n04_sd10 = 0.92567,
               g10_n10_sd05 = 0.92553, g10_n10_sd10 = 0.92510)
# Banked boundary incidence (profile), same source, for a second harness check.
BANKED_BOUNDARY <- c(g10_n04_sd05 = 0.49696, g10_n04_sd10 = 0.03704,
                     g10_n10_sd05 = 0.07632, g10_n10_sd10 = 0.00089)
BANKED_POOLED <- 0.924800
SS_FLOOR_10 <- 0.918

files <- file.path(res_dir, paste0(CELLS, ".csv"))
if (!all(file.exists(files))) {
  stop("Missing result files:\n  ", paste(files[!file.exists(files)], collapse = "\n  "),
       call. = FALSE)
}
dat <- do.call(rbind, lapply(files, utils::read.csv, stringsAsFactors = FALSE))

covered <- function(x) !is.na(x) & x            # all-attempt: NA counts as a miss
exact_ci <- function(k, n) stats::binom.test(k, n)$conf.int

cat("=====================================================================\n")
cat("D-117 REML ARM -- scored against PREREGISTRATION.md\n")
cat("=====================================================================\n\n")
cat("rows:", nrow(dat), " cells:", length(unique(dat$cell_id)),
    " package:", unique(dat$package_version), "\n")
cat("host:", unique(dat$host), "\n\n")

## ---- HARNESS FALSIFIERS (checked before any REML claim) -------------------
cat("--- HARNESS FALSIFIERS -------------------------------------------\n")
harness_ok <- TRUE

flag <- unique(dat$reml_flag_reml)
flag_ml <- unique(dat$reml_flag_ml)
ok_flag <- length(flag) == 1L && isTRUE(as.logical(flag)) &&
  length(flag_ml) == 1L && !isTRUE(as.logical(flag_ml))
cat(sprintf("  [%s] reml_flag reads back TRUE on REML arm / FALSE on ML arm (got %s / %s)\n",
            if (ok_flag) "PASS" else "FAIL",
            paste(flag, collapse = ","), paste(flag_ml, collapse = ",")))
harness_ok <- harness_ok && ok_flag

both_fin <- is.finite(dat$estimate_sd_ml) & is.finite(dat$estimate_sd_reml)
identical_share <- mean(dat$estimate_sd_ml[both_fin] == dat$estimate_sd_reml[both_fin])
ok_distinct <- identical_share < 0.001
cat(sprintf("  [%s] REML and ML SD estimates differ (identical on %.4f%% of replicates)\n",
            if (ok_distinct) "PASS" else "FAIL", 100 * identical_share))
harness_ok <- harness_ok && ok_distinct

ml_pooled <- mean(covered(dat$profile_covers_ml))
ml_ci <- exact_ci(sum(covered(dat$profile_covers_ml)), nrow(dat))
se_banked <- 0.000417
dev_se <- abs(ml_pooled - BANKED_POOLED) / se_banked
ok_control <- dev_se <= 3
cat(sprintf("  [%s] ML control reproduces banked pooled %.6f: got %.6f  (%.2f SE away)\n",
            if (ok_control) "PASS" else "FAIL", BANKED_POOLED, ml_pooled, dev_se))
harness_ok <- harness_ok && ok_control

cat("\n  per-cell ML control vs banked (coverage, and boundary incidence):\n")
cell_dev <- numeric(0)
for (cl in CELLS) {
  d <- dat[dat$cell_id == cl, ]
  m <- mean(covered(d$profile_covers_ml))
  b <- mean(!is.na(d$profile_boundary_ml) & d$profile_boundary_ml)
  cell_dev <- c(cell_dev, abs(m - BANKED_ML[[cl]]))
  cat(sprintf("    %-14s cov banked %.5f measured %.5f (%+.5f) | boundary banked %.5f measured %.5f (%+.5f)\n",
              cl, BANKED_ML[[cl]], m, m - BANKED_ML[[cl]],
              BANKED_BOUNDARY[[cl]], b, b - BANKED_BOUNDARY[[cl]]))
}
# Per-cell MCSE is ~0.00083; 4 SE is a generous tolerance for an independent re-run.
ok_cells <- all(cell_dev <= 4 * 0.00083)
cat(sprintf("  [%s] every cell's ML control within 4 MCSE of banked (max dev %.5f)\n",
            if (ok_cells) "PASS" else "FAIL", max(cell_dev)))
harness_ok <- harness_ok && ok_cells

if (!harness_ok) {
  cat("\n*** HARNESS FALSIFIER FIRED -- NO REML CLAIM MAY BE MADE FROM THIS RUN ***\n")
  quit(status = 1)
}
cat("\n  harness: OK -- proceeding to the REML result\n\n")

## ---- PRIMARY --------------------------------------------------------------
k_reml <- sum(covered(dat$profile_covers_reml)); n <- nrow(dat)
reml_pooled <- k_reml / n
reml_ci <- exact_ci(k_reml, n)

d_paired <- as.integer(covered(dat$profile_covers_reml)) - as.integer(covered(dat$profile_covers_ml))
delta <- mean(d_paired)
delta_se <- sqrt(stats::var(d_paired) / length(d_paired))
delta_lo <- delta - 1.96 * delta_se; delta_hi <- delta + 1.96 * delta_se

cat("--- PRIMARY: pooled all-attempt profile coverage ------------------\n")
cat(sprintf("  ML   %.6f  [%.6f, %.6f]\n", ml_pooled, ml_ci[1], ml_ci[2]))
cat(sprintf("  REML %.6f  [%.6f, %.6f]   (nominal 0.95, floor %.3f)\n",
            reml_pooled, reml_ci[1], reml_ci[2], SS_FLOOR_10))
cat(sprintf("  paired delta %+.6f  SE %.6f  [%+.6f, %+.6f]  (%.1f SE)\n\n",
            delta, delta_se, delta_lo, delta_hi, delta / delta_se))

contains_nominal <- reml_ci[1] <= 0.95 && 0.95 <= reml_ci[2]
narrows <- (reml_pooled - ml_pooled) > 2 * delta_se
if (contains_nominal) {
  verdict <- "REML CLOSES THE GAP"
} else if (narrows) {
  verdict <- "REML NARROWS BUT DOES NOT CLOSE"
} else {
  verdict <- "REML DOES NOT HELP"
}
cat("  PRE-REGISTERED VERDICT: ", verdict, "\n\n", sep = "")

## ---- PER CELL -------------------------------------------------------------
cat("--- per cell ------------------------------------------------------\n")
cat(sprintf("  %-14s %8s %8s %9s %9s %8s\n", "cell", "ML", "REML", "delta", "delta_SE", "floor"))
for (cl in CELLS) {
  d <- dat[dat$cell_id == cl, ]
  m <- mean(covered(d$profile_covers_ml)); r <- mean(covered(d$profile_covers_reml))
  dd <- as.integer(covered(d$profile_covers_reml)) - as.integer(covered(d$profile_covers_ml))
  se <- sqrt(stats::var(dd) / length(dd))
  cat(sprintf("  %-14s %8.4f %8.4f %+9.4f %9.4f %8s\n", cl, m, r, mean(dd), se,
              if (r >= SS_FLOOR_10) "clears" else "BELOW"))
}

## ---- RECOVERY -------------------------------------------------------------
cat("\n--- recovery (SD point estimate vs truth) -------------------------\n")
for (cl in CELLS) {
  d <- dat[dat$cell_id == cl, ]
  tr <- d$truth_sd[1]
  bm <- 100 * (mean(d$estimate_sd_ml, na.rm = TRUE) / tr - 1)
  br <- 100 * (mean(d$estimate_sd_reml, na.rm = TRUE) / tr - 1)
  cat(sprintf("  %-14s truth %.2f   ML %+7.2f%%   REML %+7.2f%%\n", cl, tr, bm, br))
}
bm <- 100 * (mean(dat$estimate_sd_ml / dat$truth_sd, na.rm = TRUE) - 1)
br <- 100 * (mean(dat$estimate_sd_reml / dat$truth_sd, na.rm = TRUE) - 1)
cat(sprintf("  %-14s              ML %+7.2f%%   REML %+7.2f%%\n", "POOLED", bm, br))

## ---- BOUNDARY -------------------------------------------------------------
cat("\n--- boundary sub-population ---------------------------------------\n")
for (arm in c("ml", "reml")) {
  b <- dat[[paste0("profile_boundary_", arm)]]
  cv <- covered(dat[[paste0("profile_covers_", arm)]])
  onb <- !is.na(b) & b
  cat(sprintf("  %-4s boundary incidence %.4f   coverage | boundary %.4f   | interior %.4f\n",
              toupper(arm), mean(onb),
              if (any(onb)) mean(cv[onb]) else NA_real_,
              if (any(!onb)) mean(cv[!onb]) else NA_real_))
}

## ---- INTERVAL AVAILABILITY / WIDTH ---------------------------------------
cat("\n--- availability and width ----------------------------------------\n")
cat(sprintf("  finite intervals  ML %d / %d    REML %d / %d\n",
            sum(dat$profile_status_ml == "valid"), n,
            sum(dat$profile_status_reml == "valid"), n))
cat(sprintf("  median width      ML %.4f        REML %.4f\n",
            median(dat$profile_width_ml, na.rm = TRUE),
            median(dat$profile_width_reml, na.rm = TRUE)))
miss_dir <- function(arm) {
  md <- dat[[paste0("profile_miss_direction_", arm)]]
  c(lower = sum(md == "lower", na.rm = TRUE), upper = sum(md == "upper", na.rm = TRUE))
}
for (arm in c("ml", "reml")) {
  m <- miss_dir(arm)
  cat(sprintf("  misses %-4s       lower %6d  upper %6d   ratio %.2f:1\n",
              toupper(arm), m[["lower"]], m[["upper"]],
              if (m[["lower"]] > 0) m[["upper"]] / m[["lower"]] else NA_real_))
}
cat("\n=====================================================================\n")

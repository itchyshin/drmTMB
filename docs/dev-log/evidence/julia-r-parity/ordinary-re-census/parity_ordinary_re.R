# Native-vs-Julia same-target parity for the ordinary-RE cells the census
# verified (parity leaf A5, gate G2).
#
# Mirrors the comparators in DRM.jl's tools/parity_fixture.R (coefficients +
# logLik, atol 1e-4) and tools/parity_se.R (per-coefficient Wald SE, rtol 1e-3,
# atol 1e-8, plus a NEGATIVE CONTROL that perturbs one Julia SE by +10% and must
# read SE_FAIL). Those two scripts carry FIXED cell lists and `library(drmTMB)`
# (the installed build, not this worktree), so their comparator bodies are
# reproduced here and their contracts (`parity_numeric()`, `drmtmb_code_hash()`)
# are sourced VERBATIM from the pinned DRM.jl clone. Output columns are the
# pin's, with `reml` and `drmjl_ref` appended so every row names the estimator
# it compares and the DRM.jl commit it was measured against.
#
# Only cells the census (census.tsv) recorded as FITS with estim_method equal
# to the requested method are compared. A cell REFUSED there has no Julia fit
# to compare and gets no row here -- an empty comparison is not a pass.
#
# Usage (from the worktree root):
#   OPENBLAS_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true DRM_JL_PATH=<pin> \
#     Rscript docs/dev-log/evidence/julia-r-parity/ordinary-re-census/parity_ordinary_re.R <outdir>

suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
outdir <- if (length(args) >= 1L) args[[1]] else dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
drmjl_path <- Sys.getenv("DRM_JL_PATH", "")
stopifnot(nzchar(drmjl_path), dir.exists(drmjl_path))
source(file.path(drmjl_path, "tools", "parity_numeric.R"))
source(file.path(drmjl_path, "tools", "drmtmb_provenance_lib.R"))
drmjl_ref <- system2("git", c("-C", shQuote(drmjl_path), "rev-parse", "HEAD"), stdout = TRUE)

# Same draw as census.R, so the parity rows are about the SAME fits the census
# classified (one seed; a second draw is not a second cell).
source(file.path(outdir, "make_data.R"))

tol <- 1e-4
rtol_se <- 1e-3
atol_se <- 1e-8

se_of <- function(f) {
  V <- vcov(f)
  v <- diag(as.matrix(V))
  se <- ifelse(v > 0, sqrt(v), NA_real_)
  labels <- rownames(as.matrix(V))
  names(se) <- sub(":", "_", labels, fixed = TRUE)
  se
}
fmt_vec <- function(x) paste(sprintf("%s=%.6g", names(x), x), collapse = ";")

cells <- list(
  list(capability_id = "drmjl_only:gaussian_ranef", cell_id = "ordre_gaussian_random_intercept_ml",
       label = "Gaussian (1 | g) on mu, sigma ~ 1, ML", shape = "gaussian_random_intercept",
       formula = function() bf(y ~ x + (1 | g), sigma ~ 1), reml = FALSE),
  list(capability_id = "drmjl_only:gaussian_ranef", cell_id = "ordre_gaussian_random_intercept_reml",
       label = "Gaussian (1 | g) on mu, sigma ~ 1, REML", shape = "gaussian_random_intercept",
       formula = function() bf(y ~ x + (1 | g), sigma ~ 1), reml = TRUE),
  list(capability_id = "drmjl_only:gaussian_ranef_slope", cell_id = "ordre_gaussian_random_slope_ml",
       label = "Gaussian correlated (1 + x | g) on mu, sigma ~ 1, ML", shape = "gaussian_random_slope",
       formula = function() bf(y ~ x + (1 + x | g), sigma ~ 1), reml = FALSE),
  list(capability_id = "drmjl_only:gaussian_sigma_ranef", cell_id = "ordre_gaussian_sigma_random_intercept_ml",
       label = "Gaussian sigma ~ (1 | g), fixed mu, ML", shape = "gaussian_sigma_random_intercept",
       formula = function() bf(y ~ x, sigma ~ (1 | g)), reml = FALSE)
)

fit_pair <- function(cell) {
  d <- make_data(cell$shape)
  ft <- try(drmTMB(cell$formula(), family = gaussian(), data = d, engine = "tmb", REML = cell$reml), silent = TRUE)
  fj <- try(suppressWarnings(drmTMB(cell$formula(), family = gaussian(), data = d, engine = "julia", REML = cell$reml)), silent = TRUE)
  list(ft = ft, fj = fj)
}

fixture_row <- function(cell, pr) {
  res <- list(capability_id = cell$capability_id, label = cell$label, status = NA_character_,
              max_abs_coef_diff = NA_real_, loglik_tmb = NA_real_, loglik_julia = NA_real_,
              loglik_diff = NA_real_, tolerance = tol, note = "",
              sd_tmb = "", sd_julia = "", max_abs_sd_diff = NA_real_)
  ft <- pr$ft; fj <- pr$fj
  if (inherits(ft, "try-error")) {
    res$status <- "NATIVE_FAILED"; res$note <- conditionMessage(attr(ft, "condition"))
  } else if (inherits(fj, "try-error")) {
    res$status <- "JULIA_FAILED"; res$note <- conditionMessage(attr(fj, "condition"))
  } else {
    ct <- unlist(fixef(ft)); cj <- unlist(fixef(fj))
    comparison <- parity_numeric(ct, cj, tol)
    res$max_abs_coef_diff <- comparison$max_abs_diff
    res$loglik_tmb <- as.numeric(logLik(ft))
    res$loglik_julia <- as.numeric(logLik(fj))
    res$loglik_diff <- abs(res$loglik_tmb - res$loglik_julia)
    # The random-effect SD is the parameter these shapes exist for; compare it
    # too (by value, positionally: the two engines label sdpars differently).
    # Correlated (1 + x | g): drmTMB reports the intercept SD, the slope SD and
    # their correlation. The Julia fit's `sdpars`/`corpars` are EMPTY for this
    # shape (measured 2026-09-05, inspect_slope.log): the bridge returns the
    # block as raw log-Cholesky coefficients `recov_g:L11`, `recov_g:L22`,
    # `recov_g:L21`, and drm_julia_structured_parameters() only translates a
    # `recov_` block for the phylo mu+sigma pair. So for this shape the SD/cor
    # are DERIVED here from the raw bridge coefficients (sd_int = exp(L11),
    # sd_slope = sqrt(L21^2 + exp(L22)^2), cor = L21 / sd_slope -- the same
    # map the phylo branch of that function uses) and the accessor gap is
    # recorded in the note. Reporting gap, not a parity claim: values agree.
    st_sd <- c(unlist(ft$sdpars), unlist(ft$corpars)); sj_sd <- c(unlist(fj$sdpars), unlist(fj$corpars))
    sd_note <- ""
    if (length(sj_sd) == 0L) {
      cf <- stats::setNames(as.numeric(fj$bridge$coefficients), fj$bridge$coef_names)
      rec <- cf[startsWith(names(cf), "recov_")]
      if (length(rec) == 3L) {
        l11 <- exp(rec[[grep(":L11$", names(rec))]]); l22 <- exp(rec[[grep(":L22$", names(rec))]]); l21 <- rec[[grep(":L21$", names(rec))]]
        sj_sd <- c(sd_int = l11, sd_slope = sqrt(l21^2 + l22^2), cor = l21 / sqrt(l21^2 + l22^2))
        sd_note <- sprintf("; julia sdpars/corpars EMPTY for this shape (bridge reporting gap) -- SD/cor derived from raw recov_ coefficients [%s]", fmt_vec(rec))
      }
    }
    res$sd_tmb <- fmt_vec(st_sd); res$sd_julia <- fmt_vec(sj_sd)
    res$max_abs_sd_diff <- if (length(st_sd) == length(sj_sd) && length(st_sd) > 0L) max(abs(unname(st_sd) - unname(sj_sd))) else NA_real_
    agree <- comparison$pass && is.finite(res$loglik_diff) && res$loglik_diff < tol &&
      is.finite(res$max_abs_sd_diff) && res$max_abs_sd_diff < tol
    res$status <- if (agree) "PARITY_PASS" else "PARITY_FAIL"
    res$note <- sprintf("%s; %d coefficient(s) compared; %d RE sd/cor value(s) compared; julia estim_method=%s; tmb estimator=%s%s",
                        comparison$reason, length(ct), length(st_sd), fj$bridge$estim_method, ft$estimator, sd_note)
  }
  res$cell_id <- cell$cell_id
  res$reml <- cell$reml
  res$drmjl_ref <- drmjl_ref
  as.data.frame(res, stringsAsFactors = FALSE)
}

se_row <- function(cell, pr, perturb = 0) {
  res <- list(capability_id = cell$capability_id, cell_id = cell$cell_id, label = cell$label,
              status = NA_character_, max_abs_se_diff = NA_real_, max_rel_se_diff = NA_real_,
              se_tmb = "", se_julia = "", tolerance = rtol_se, note = "")
  finish <- function(res) { res$reml <- cell$reml; res$drmjl_ref <- drmjl_ref; as.data.frame(res, stringsAsFactors = FALSE) }
  ft <- pr$ft; fj <- pr$fj
  if (inherits(ft, "try-error")) { res$status <- "NATIVE_FAILED"; res$note <- conditionMessage(attr(ft, "condition")); return(finish(res)) }
  if (inherits(fj, "try-error")) { res$status <- "JULIA_FAILED"; res$note <- conditionMessage(attr(fj, "condition")); return(finish(res)) }
  st <- try(se_of(ft), silent = TRUE)
  sj <- try(se_of(fj), silent = TRUE)
  if (inherits(st, "try-error")) { res$status <- "NATIVE_SE_UNAVAILABLE"; res$note <- conditionMessage(attr(st, "condition")); return(finish(res)) }
  if (inherits(sj, "try-error")) { res$status <- "JULIA_SE_UNAVAILABLE"; res$note <- conditionMessage(attr(sj, "condition")); return(finish(res)) }
  if (perturb != 0) sj[1] <- sj[1] * (1 + perturb)
  common <- intersect(names(st), names(sj))
  if (length(common) == 0L) {
    res$status <- "SE_NAMES_DISJOINT"
    res$note <- sprintf("no shared names; tmb=[%s] julia=[%s]", paste(names(st), collapse = ","), paste(names(sj), collapse = ","))
    res$se_tmb <- fmt_vec(st); res$se_julia <- fmt_vec(sj)
    return(finish(res))
  }
  a <- st[common]; b <- sj[common]
  res$se_tmb <- fmt_vec(st); res$se_julia <- fmt_vec(sj)
  degenerate <- !is.finite(a) | !is.finite(b) | a <= 1e-6 | b <= 1e-6
  if (any(degenerate)) {
    res$status <- "BOUNDARY_NOT_COMPARABLE"
    res$note <- paste0("degenerate/boundary SE(s): ", paste(names(a)[degenerate], collapse = ","), "; comparison declined, not passed")
    a <- a[!degenerate]; b <- b[!degenerate]
    if (length(a)) { res$max_abs_se_diff <- max(abs(a - b)); res$max_rel_se_diff <- max(abs(a - b) / pmax(abs(a), abs(b))) }
    return(finish(res))
  }
  res$max_abs_se_diff <- max(abs(a - b))
  res$max_rel_se_diff <- max(abs(a - b) / pmax(abs(a), abs(b)))
  agree <- res$max_abs_se_diff <= atol_se || res$max_rel_se_diff <= rtol_se
  res$status <- if (agree) "SE_PASS" else "SE_FAIL"
  unmatched <- c(setdiff(names(st), common), setdiff(names(sj), common))
  res$note <- paste0(length(a), " SE(s) compared",
                     if (length(unmatched)) paste0("; unmatched names: ", paste(unmatched, collapse = ",")) else "",
                     if (perturb != 0) sprintf("; NEGATIVE CONTROL: se_julia[1] perturbed by %+.0f%%", 100 * perturb) else "")
  finish(res)
}

fix_rows <- list(); se_rows <- list(); pairs <- list()
for (cell in cells) {
  pr <- fit_pair(cell); pairs[[cell$cell_id]] <- pr
  fr <- fixture_row(cell, pr); fix_rows[[length(fix_rows) + 1L]] <- fr
  sr <- se_row(cell, pr); se_rows[[length(se_rows) + 1L]] <- sr
  cat(sprintf("%-42s %-14s coef_diff=%.3e  loglik_diff=%.3e  sd_diff=%.3e | %-22s se_abs=%.3e se_rel=%.3e\n",
              cell$cell_id, fr$status, fr$max_abs_coef_diff, fr$loglik_diff, fr$max_abs_sd_diff,
              sr$status, sr$max_abs_se_diff, sr$max_rel_se_diff))
  if (!is.na(fr$note) && grepl("FAILED|exceeded|differ", fr$note)) cat("   note: ", fr$note, "\n")
  if (!is.na(sr$note) && !grepl("^[0-9]+ SE\\(s\\) compared$", sr$note)) cat("   se note: ", sr$note, "\n")
}

# NEGATIVE CONTROL -- prove the SE comparator can fail (same contract as parity_se.R).
nc <- cells[[1]]; nc$cell_id <- "negative_control_perturbed"; nc$label <- "NEGATIVE CONTROL: cell 1 with se_julia[1] * 1.10"
ncr <- se_row(nc, pairs[[cells[[1]]$cell_id]], perturb = 0.10)
ncr$status <- if (ncr$status == "SE_FAIL") "NEGATIVE_CONTROL_OK" else "NEGATIVE_CONTROL_BROKEN"
se_rows[[length(se_rows) + 1L]] <- ncr
cat(sprintf("%-42s %-22s se_abs=%.3e se_rel=%.3e\n", ncr$cell_id, ncr$status, ncr$max_abs_se_diff, ncr$max_rel_se_diff))

fix_tab <- do.call(rbind, fix_rows)
se_tab <- do.call(rbind, se_rows)
stamp <- drmtmb_code_hash()
fix_tab$drmtmb_code_hash <- stamp
se_tab$drmtmb_code_hash <- stamp
fix_tab <- fix_tab[, c("capability_id", "cell_id", "label", "status", "max_abs_coef_diff", "loglik_tmb", "loglik_julia", "loglik_diff", "tolerance", "note", "sd_tmb", "sd_julia", "max_abs_sd_diff", "reml", "drmjl_ref", "drmtmb_code_hash")]
write.table(fix_tab, file.path(outdir, "parity-fixtures-ordinary-re.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
write.table(se_tab, file.path(outdir, "parity-se-ordinary-re.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
cat("\nwrote parity-fixtures-ordinary-re.tsv and parity-se-ordinary-re.tsv in ", outdir, "\n", sep = "")
cat("drmTMB code hash: ", stamp, "\nDRM.jl ref: ", drmjl_ref, "\n", sep = "")
main_ok <- all(fix_tab$status == "PARITY_PASS") &&
  all(se_tab$status[se_tab$cell_id != "negative_control_perturbed"] == "SE_PASS")
nc_ok <- identical(ncr$status, "NEGATIVE_CONTROL_OK")
cat("OVERALL: ", if (main_ok && nc_ok) "ALL CELLS PASS (+ negative control rejects)" else "SOME CELLS FAILED", "\n", sep = "")
if (!(main_ok && nc_ok)) quit(status = 1L)

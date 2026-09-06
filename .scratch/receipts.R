# G3 + G4 receipts for the biv_student admission.
#
# Comparator code is taken VERBATIM from the pin clone's own tools: the fixture
# axis sources tools/parity_numeric.R and replays tools/parity_fixture.R's
# fe_cells loop body; the SE axis evaluates ONLY the assignments of `rtol_se`,
# `atol_se`, `se_of`, `fmt_vec` and `compare_cell` out of tools/parity_se.R, so
# the numbers below come from that file's comparator and not a local rewrite.
PIN <- "/Users/z3437171/local-scratch/parity-joint/drmjl-430ef64cc"
WT  <- "/Users/z3437171/local-scratch/parity-joint/wt-fam-biv-student"
suppressMessages(devtools::load_all(WT, quiet = TRUE))
source(file.path(PIN, "tools", "parity_numeric.R"))

# --- lift the SE comparator out of tools/parity_se.R without running it ------
se_env <- new.env(parent = globalenv())
exprs <- parse(file.path(PIN, "tools", "parity_se.R"))
wanted <- c("rtol_se", "atol_se", "se_of", "fmt_vec", "compare_cell")
for (e in exprs) {
  if (is.call(e) && identical(as.character(e[[1]]), "<-") &&
      is.name(e[[2]]) && as.character(e[[2]]) %in% wanted) {
    eval(e, envir = se_env)
  }
}
stopifnot(all(wanted %in% ls(se_env)))
cat("LIFTED_FROM_parity_se.R:", paste(sort(ls(se_env)), collapse = ", "), "\n")
cat("rtol_se =", se_env$rtol_se, " atol_se =", se_env$atol_se, "\n\n")

# --- the cell ---------------------------------------------------------------
# The SAME draw the focused test uses: drmTMB's own biv_student simulator
# (tests/testthat/test-biv-student.R `simulate_biv_student_truth`), verbatim.
simulate_biv_student_truth <- function(n, beta1, beta2, sigma1, sigma2, nu, rho12) {
  x <- seq(-1, 1, length.out = n)
  z1 <- stats::rnorm(n)
  z2 <- rho12 * z1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  shared_scale <- sqrt(nu / stats::rchisq(n, df = nu))
  data.frame(x = x,
             y1 = beta1[[1L]] + beta1[[2L]] * x + sigma1 * z1 * shared_scale,
             y2 = beta2[[1L]] + beta2[[2L]] * x + sigma2 * z2 * shared_scale)
}
cell <- list(
  capability_id = "fe_biv_student",
  cell_id = "se_biv_student",
  id      = "fe_biv_student",
  label   = "Bivariate Student-t (shared nu), fixed effects",
  build   = function() {
    set.seed(6401)
    simulate_biv_student_truth(n = 400, beta1 = c(0.2, 0.45), beta2 = c(-0.3, -0.25),
                               sigma1 = 0.55, sigma2 = 0.85, nu = 7, rho12 = 0.35)
  },
  formula = function() bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1,
                          nu = ~1, rho12 = ~1),
  family  = function() biv_student()
)

# ===================== G3: coefficient + logLik axis =========================
# Loop body copied verbatim from tools/parity_fixture.R's `fe_cells` loop.
tol <- 1e-4
d <- cell$build()
res <- list(
  capability_id = cell$id, label = cell$label,
  status = NA_character_, max_abs_coef_diff = NA_real_,
  loglik_tmb = NA_real_, loglik_julia = NA_real_, loglik_diff = NA_real_,
  tolerance = tol,
  note = sprintf("R-via-Julia bridge parity (engine='julia'), drmTMB %s",
                 as.character(utils::packageVersion("drmTMB")))
)
fml <- cell$formula()
ft <- try(drmTMB(fml, family = cell$family(), data = d, engine = "tmb"), silent = TRUE)
jb <- try(drmTMB(fml, family = cell$family(), data = d, engine = "julia"), silent = TRUE)
if (inherits(ft, "try-error")) {
  res$status <- "NATIVE_FAILED"; res$note <- conditionMessage(attr(ft, "condition"))
} else if (inherits(jb, "try-error")) {
  res$status <- "JULIA_FAILED"; res$note <- conditionMessage(attr(jb, "condition"))
} else {
  ct <- unlist(fixef(ft)); cj <- unlist(fixef(jb))
  comparison <- parity_numeric(ct, cj, tol)
  res$max_abs_coef_diff <- comparison$max_abs_diff
  res$loglik_tmb <- as.numeric(logLik(ft)); res$loglik_julia <- as.numeric(logLik(jb))
  res$loglik_diff <- abs(res$loglik_tmb - res$loglik_julia)
  res$status <- if (comparison$pass && is.finite(res$loglik_diff) && res$loglik_diff < tol)
    "PARITY_PASS" else "PARITY_FAIL"
  res$note <- paste(res$note, comparison$reason, sep = "; ")
}
cat("=== G3 FIXTURE ROW ===\n")
cat(sprintf("%-32s %-14s coef_diff=%.6e  loglik_diff=%.6e\n",
            res$capability_id, res$status, res$max_abs_coef_diff, res$loglik_diff))
cat("loglik_tmb =", sprintf("%.12f", res$loglik_tmb),
    " loglik_julia =", sprintf("%.12f", res$loglik_julia), "\n")
cat("note:", res$note, "\n")
if (!inherits(ft, "try-error") && !inherits(jb, "try-error")) {
  cat("coef_tmb  : ", paste(sprintf("%s=%.10g", names(unlist(fixef(ft))), unlist(fixef(ft))), collapse = " "), "\n")
  cat("coef_julia: ", paste(sprintf("%s=%.10g", names(unlist(fixef(jb))), unlist(fixef(jb))), collapse = " "), "\n")
}
fixture_row <- as.data.frame(res, stringsAsFactors = FALSE)

# ===================== G4: SE axis + negative control ========================
cat("\n=== G4 SE ROWS ===\n")
se_cell <- list(capability_id = cell$capability_id, cell_id = cell$cell_id,
                label = cell$label, build = cell$build,
                formula = cell$formula, family = cell$family)
r1 <- se_env$compare_cell(se_cell)
cat(sprintf("%-28s %-22s abs_diff=%.6e  rel_diff=%.6e\n",
            r1$cell_id, r1$status, r1$max_abs_se_diff, r1$max_rel_se_diff))
cat("se_tmb   : ", r1$se_tmb, "\n")
cat("se_julia : ", r1$se_julia, "\n")
cat("note     : ", r1$note, "\n")

nc <- se_cell
nc$cell_id <- "negative_control_perturbed_biv_student"
nc$label <- "NEGATIVE CONTROL: biv_student cell with se_julia[1] * 1.10"
r2 <- se_env$compare_cell(nc, perturb = 0.10)
r2$status <- if (r2$status == "SE_FAIL") "NEGATIVE_CONTROL_OK" else "NEGATIVE_CONTROL_BROKEN"
cat(sprintf("%-28s %-22s abs_diff=%.6e  rel_diff=%.6e\n",
            r2$cell_id, r2$status, r2$max_abs_se_diff, r2$max_rel_se_diff))
cat("note     : ", r2$note, "\n")

# ===================== provenance stamp ======================================
source(file.path(PIN, "tools", "drmtmb_provenance_lib.R"))
stamp <- drmtmb_code_hash()
cat("\ndrmtmb_code_hash =", stamp, "\n")

# ===================== append rows to the pin clone's TSVs ===================
fx_path <- file.path(PIN, "docs/dev-log/evidence/parity-fixtures.tsv")
se_path <- file.path(PIN, "docs/dev-log/evidence/parity-se.tsv")
fx <- utils::read.delim(fx_path, stringsAsFactors = FALSE, check.names = FALSE)
se <- utils::read.delim(se_path, stringsAsFactors = FALSE, check.names = FALSE)
fixture_row <- fixture_row[, names(fx), drop = FALSE]
se_rows <- rbind(as.data.frame(r1, stringsAsFactors = FALSE),
                 as.data.frame(r2, stringsAsFactors = FALSE))
se_rows$drmtmb_code_hash <- stamp
se_rows <- se_rows[, names(se), drop = FALSE]
fx <- fx[fx$capability_id != "fe_biv_student", , drop = FALSE]
se <- se[!se$cell_id %in% se_rows$cell_id, , drop = FALSE]
utils::write.table(rbind(fx, fixture_row), fx_path, sep = "\t",
                   row.names = FALSE, quote = FALSE)
utils::write.table(rbind(se, se_rows), se_path, sep = "\t",
                   row.names = FALSE, quote = FALSE)
cat("APPENDED_ROWS_OK\n")

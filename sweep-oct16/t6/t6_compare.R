# Compare R and Julia predict tables to the 1e-8 bar.
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[[1L]] else Sys.getenv("T6_ROOT")
source(file.path(root, "t6_config.R"))
resdir <- file.path(root, "results")
out <- file.path(resdir, "r_vs_julia.csv")
if (file.exists(out)) file.remove(out)

cells <- gsub("^predict_R_", "", gsub("\\.csv$", "",
              list.files(resdir, pattern = "^predict_R_.*\\.csv$")))
for (cell in cells) {
  pr <- file.path(resdir, paste0("predict_R_", cell, ".csv"))
  pj <- file.path(resdir, paste0("predict_J_", cell, ".csv"))
  if (!file.exists(pj)) {
    rec <- data.frame(cell = cell, col = NA, max_abs = NA,
                      pass = FALSE, detail = "missing Julia predict table",
                      stringsAsFactors = FALSE)
    utils::write.table(rec, out, sep = ",", row.names = FALSE,
                       col.names = !file.exists(out), append = file.exists(out))
    next
  }
  R <- utils::read.csv(pr)
  J <- utils::read.csv(pj)
  common <- intersect(setdiff(names(R), "row"), setdiff(names(J), "row"))
  if (!length(common)) {
    rec <- data.frame(cell = cell, col = NA, max_abs = NA,
                      pass = FALSE, detail = "no shared columns",
                      stringsAsFactors = FALSE)
    utils::write.table(rec, out, sep = ",", row.names = FALSE,
                       col.names = !file.exists(out), append = file.exists(out))
    next
  }
  for (col in common) {
    d <- abs(as.numeric(R[[col]]) - as.numeric(J[[col]]))
    mx <- max(d, na.rm = TRUE)
    rec <- data.frame(
      cell = cell, col = col, max_abs = mx,
      pass = is.finite(mx) && mx <= T6_PASS_RJ,
      detail = sprintf("max_abs=%g bar=%g", mx, T6_PASS_RJ),
      stringsAsFactors = FALSE
    )
    utils::write.table(rec, out, sep = ",", row.names = FALSE,
                       col.names = !file.exists(out), append = file.exists(out))
  }
}
message("wrote ", out)

# sweep-oct16 / t5 -- supplementary (out-of-grid) probe: NA in the grouping
# variable g on rows 1, 9, ..., 73 of each *_y00_x00 dataset (10 rows, one in
# each of groups g01..g10). R side: native and engine = "julia".
`%||%` <- function(x, y) if (is.null(x)) y else x   # R < 4.4 only (drmTMB #1550)
# Usage: Rscript R/run_probe_g.R <datadir> <outfile>
args <- commandArgs(trailingOnly = TRUE)
suppressMessages(library(drmTMB))
rows <- list()
for (fam in c("gaussian", "poisson", "gamma")) {
  d <- read.csv(file.path(args[[1]], sprintf("%s_y00_x00.csv", fam)), stringsAsFactors = FALSE)
  d$g[seq(1, 80, by = 8)] <- NA
  FO <- switch(fam, gaussian = gaussian(), poisson = poisson(link = "log"), gamma = Gamma(link = "log"))
  F <- if (fam == "poisson") bf(y ~ x + (1 | g)) else bf(y ~ x + (1 | g), sigma ~ 1)
  for (eng in c("tmb", "julia")) {
    r <- tryCatch({
      f <- drmTMB(F, family = FO, data = d, engine = eng)
      data.frame(status = "ok", error = NA, logLik = as.numeric(logLik(f)), nobs = nobs(f),
                 b_mu1 = coef(f)$mu[[2]], n_groups = length(unique(f$data$g)))
    }, error = function(e) data.frame(status = "error", error = gsub("[\r\n]+", " | ", conditionMessage(e)),
                                      logLik = NA, nobs = NA, b_mu1 = NA, n_groups = NA))
    rows[[length(rows) + 1L]] <- cbind(id = sprintf("%s_y00_x00", fam), mode = "g_missing", engine = eng, r)
  }
}
out <- do.call(rbind, rows)
write.csv(out, args[[2]], row.names = FALSE)
print(out[, c("id", "engine", "status", "nobs", "n_groups", "logLik")])

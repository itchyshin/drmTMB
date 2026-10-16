# sweep-oct16 / t5 -- supplementary probe: Gaussian (1 | g) with
# missing = miss_control(response = "include"), on the t5 cells, native vs
# engine = "julia". Under "include" the bridge skips its R-side row drop.
`%||%` <- function(x, y) if (is.null(x)) y else x   # R < 4.4 only (drmTMB #1550)
# Usage: Rscript R/run_probe_include.R <datadir> <outfile>
args <- commandArgs(trailingOnly = TRUE)
suppressMessages(library(drmTMB))
rows <- list()
for (id in c("gaussian_y05_x00", "gaussian_y00_x05", "gaussian_y05_x05")) {
  d <- read.csv(file.path(args[[1]], paste0(id, ".csv")))
  for (eng in c("tmb", "julia")) {
    r <- tryCatch({
      f <- drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(), data = d,
                  missing = miss_control(response = "include"), engine = eng)
      data.frame(status = "ok", error = NA, logLik = as.numeric(logLik(f)), nobs = nobs(f))
    }, error = function(e) data.frame(status = "error", error = substr(gsub("[\r\n]+", " | ", conditionMessage(e)), 1, 300),
                                      logLik = NA, nobs = NA))
    rows[[length(rows) + 1L]] <- cbind(id = id, engine = eng, r)
  }
}
out <- do.call(rbind, rows); write.csv(out, args[[2]], row.names = FALSE)
for (i in seq_len(nrow(out))) cat(sprintf("%-17s %-6s %-5s nobs=%s logLik=%s %s\n", out$id[i], out$engine[i], out$status[i], out$nobs[i], format(out$logLik[i], digits = 12), ifelse(is.na(out$error[i]), "", out$error[i])))

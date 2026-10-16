# Runner: sources the bridge repros in ONE R session (Julia boots once).
# Rscript /home/user/drmTMB/sweep-oct16/t6/repro/br_run_all.R > /home/user/drmTMB/sweep-oct16/t6/logs/repro_br.log 2>&1
options(width = 200, warn = 1)
.br_files <- commandArgs(trailingOnly = TRUE)
if (!length(.br_files)) .br_files <- c("br_methods.R", "br_fitted.R", "br_ri_label.R", "br_docs.R", "br_1551ext.R", "br_p6_quantile.R")
cat("R:", R.version.string, "| drmTMB", as.character(packageVersion("drmTMB")),
    "| build SHA", read.dcf(system.file("build-provenance.dcf", package = "drmTMB"))[1, "GitSHA"], "\n")
for (.br_f in .br_files) {
  cat("\n\n########", .br_f, "| start", format(Sys.time(), "%H:%M:%S"), "########\n")
  .br_t0 <- Sys.time()
  tryCatch(source(file.path("/home/user/drmTMB/sweep-oct16/t6/repro", .br_f), local = new.env(), echo = TRUE,
                       max.deparse.length = Inf, spaced = FALSE),
                error = function(e) { cat("RUNNER: script error:", conditionMessage(e), "\n"); NULL })
  cat("######## ", .br_f, "| done in", round(as.numeric(difftime(Sys.time(), .br_t0, units = "secs")), 1), "s ########\n")
  flush(stdout())
}
if (requireNamespace("JuliaCall", quietly = TRUE)) try(cat("Julia", JuliaCall::julia_eval("string(VERSION)"), "| DRModels at",
  JuliaCall::julia_eval("pathof(drmTMB_backend)"), "\n"))

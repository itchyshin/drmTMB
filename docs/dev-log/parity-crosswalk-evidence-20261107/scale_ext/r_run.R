# Native R drmTMB fits for the scale-extension study (reads data/ written by julia_run.jl / make_data_nb2phylo.R).
# usage: SC_OUT=<out> DRMTMB_LIB=<lib> Rscript r_run.R <route> <seed_from> <seed_to>   (run from the scripts directory)
args <- commandArgs(TRUE); route <- args[1]; s_from <- as.integer(args[2]); s_to <- as.integer(args[3])
if (nzchar(Sys.getenv("DRMTMB_LIB"))) .libPaths(c(Sys.getenv("DRMTMB_LIB"), .libPaths()))
suppressPackageStartupMessages(library(drmTMB)); cat("drmTMB", as.character(packageVersion("drmTMB")), "\n")
source("routes.R")
O <- Sys.getenv("SC_OUT", "."); dir.create(file.path(O, "r"), showWarnings = FALSE, recursive = TRUE)
tree <- if (route == "nb2_phylo") ape::read.tree("tree.nwk") else NULL
for (s in s_from:s_to) {
  tag <- sprintf("%s_s%03d", route, s)
  ds <- read_dataset(O, tag, route); d <- ds$d; K <- ds$K
  m <- build_model(route, d, K, tree)
  t0 <- Sys.time()
  fit <- tryCatch(drmTMB(m$bf, family = m$family, data = d), error = function(e) e)
  el <- as.numeric(Sys.time() - t0, units = "secs")
  if (inherits(fit, "error")) {
    msg <- gsub("[\"\n,]+", " ", conditionMessage(fit)); cat(tag, "R ERROR:", msg, "\n")
    write.csv(data.frame(ll = NA, convergence = "error", pdHess = NA, seconds = el, msg = substr(msg, 1, 300)), file.path(O, "r", paste0(tag, "_ll.csv")), row.names = FALSE); next }
  par <- fit$opt$par; se <- tryCatch(sqrt(diag(fit$sdr$cov.fixed)), error = function(e) rep(NA_real_, length(par)))
  if (is.null(names(se)) || !identical(names(se), names(par))) se <- setNames(rep(NA_real_, length(par)), names(par))
  write.csv(data.frame(name = names(par), est = unname(par), se = unname(se)), file.path(O, "r", paste0(tag, ".csv")), row.names = FALSE)
  write.csv(data.frame(ll = sprintf("%.12f", as.numeric(logLik(fit))), convergence = fit$opt$convergence,
                       pdHess = isTRUE(fit$sdr$pdHess), seconds = el, msg = ""), file.path(O, "r", paste0(tag, "_ll.csv")), row.names = FALSE)
  cat(sprintf("%s ll=%.8f conv=%s pdHess=%s t=%.1fs\n", tag, as.numeric(logLik(fit)), fit$opt$convergence, isTRUE(fit$sdr$pdHess), el))
}

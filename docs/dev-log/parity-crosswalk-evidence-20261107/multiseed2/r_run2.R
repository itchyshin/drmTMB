# Native R drmTMB fits for the second multi-seed agreement study (reads data/ written by julia_run2.jl / make_data_struct.R).
# usage: DRMTMB_LIB=<lib> Rscript r_run2.R <route> [seed_from seed_to]   (run from this directory)
args <- commandArgs(TRUE); route <- args[1]
s_from <- if (length(args) >= 3) as.integer(args[2]) else 1L; s_to <- if (length(args) >= 3) as.integer(args[3]) else 10L
if (nzchar(Sys.getenv("DRMTMB_LIB"))) .libPaths(c(Sys.getenv("DRMTMB_LIB"), .libPaths()))
suppressPackageStartupMessages(library(drmTMB)); cat("drmTMB", as.character(packageVersion("drmTMB")), "\n")
dir.create("r", showWarnings = FALSE)
tree <- ape::read.tree("tree.nwk")
cc <- read.csv("coords.csv"); coords <- as.matrix(cc[, 2:3]); rownames(coords) <- cc$id
fam_of <- function(r) if (grepl("^gamma", r)) Gamma(link = "log") else if (grepl("^nb2", r)) nbinom2() else gaussian()
formula_of <- function(r) switch(r,
  gauss_q3 = bf(y ~ x + z + (1 + x + z | id), sigma ~ 1, sd(id, coef = "(Intercept)") ~ w, sd(id, coef = "x") ~ w, sd(id, coef = "z") ~ w),
  gauss_q4 = bf(y ~ x + z + (1 + x + z + u | id), sigma ~ 1, sd(id, coef = "(Intercept)") ~ w, sd(id, coef = "x") ~ w, sd(id, coef = "z") ~ w, sd(id, coef = "u") ~ w),
  gamma_same = , nb2_same = bf(y ~ x + (1 | g) + (0 + x | g), sigma ~ 1, sd(g, coef = "(Intercept)") ~ w1, sd(g, coef = "x") ~ w2),
  gamma_corr = , nb2_corr = bf(y ~ x + (1 + x | g), sigma ~ 1, sd(g, coef = "(Intercept)") ~ w1, sd(g, coef = "x") ~ w2),
  gauss_joint = , nb2_joint = bf(y ~ x + (1 | id), sigma ~ 1 + (1 | id), sd(id) ~ w, sd(id, dpar = "sigma") ~ z),
  nb2_jcross = bf(y ~ x + (1 | id), sigma ~ 1 + (1 | g), sd(id) ~ w, sd(g, dpar = "sigma") ~ z),
  gauss_phylo = bf(y ~ x + phylo(1 + x | id, tree = tree), sigma ~ 1, sd(id, level = "phylogenetic", dpar = "mu", coef = "(Intercept)") ~ z0, sd(id, level = "phylogenetic", dpar = "mu", coef = "x") ~ z1),
  gauss_lphylo = bf(y ~ x + phylo(1 + x | p | id, tree = tree), sigma ~ 1, sd(id, level = "phylogenetic", dpar = "mu", coef = "(Intercept)") ~ z0, sd(id, level = "phylogenetic", dpar = "mu", coef = "x") ~ z1),
  gauss_spatial = bf(y ~ x + spatial(1 + x | id, coords = coords), sigma ~ 1, sd(id, level = "spatial", dpar = "mu", coef = "(Intercept)") ~ z0, sd(id, level = "spatial", dpar = "mu", coef = "x") ~ z1),
  gauss_lspatial = bf(y ~ x + spatial(1 + x | p | id, coords = coords), sigma ~ 1, sd(id, level = "spatial", dpar = "mu", coef = "(Intercept)") ~ z0, sd(id, level = "spatial", dpar = "mu", coef = "x") ~ z1))
for (s in s_from:s_to) {
  tag <- sprintf("%s_s%02d", route, s)
  d <- read.csv(file.path("data", paste0(tag, ".csv")))
  for (v in c("id", "g")) if (!is.null(d[[v]])) d[[v]] <- factor(d[[v]], levels = unique(d[[v]]))
  fm <- formula_of(route)
  t0 <- Sys.time()
  fit <- tryCatch(drmTMB(fm, family = fam_of(route), data = d), error = function(e) e)
  el <- as.numeric(Sys.time() - t0, units = "secs")
  if (inherits(fit, "error")) {
    msg <- gsub("[\"\n,]+", " ", conditionMessage(fit)); cat(tag, "R ERROR:", msg, "\n")
    write.csv(data.frame(ll = NA, convergence = "error", pdHess = NA, seconds = el, msg = substr(msg, 1, 300)),
              file.path("r", paste0(tag, "_ll.csv")), row.names = FALSE); next }
  par <- fit$opt$par; se <- tryCatch(sqrt(diag(fit$sdr$cov.fixed)), error = function(e) rep(NA_real_, length(par)))
  if (is.null(names(se)) || !identical(names(se), names(par))) se <- setNames(rep(NA_real_, length(par)), names(par))
  write.csv(data.frame(name = names(par), est = unname(par), se = unname(se)), file.path("r", paste0(tag, ".csv")), row.names = FALSE)
  write.csv(data.frame(ll = sprintf("%.12f", as.numeric(logLik(fit))), convergence = fit$opt$convergence,
                       pdHess = isTRUE(fit$sdr$pdHess), seconds = el, msg = ""), file.path("r", paste0(tag, "_ll.csv")), row.names = FALSE)
  cat(sprintf("%s ll=%.8f conv=%s pdHess=%s t=%.1fs\n", tag, as.numeric(logLik(fit)), fit$opt$convergence, isTRUE(fit$sdr$pdHess), el))
}

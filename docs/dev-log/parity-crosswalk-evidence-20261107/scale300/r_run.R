# Native R drmTMB fits for the multi-seed agreement study (reads data/ written by julia_run.jl / make_data_ps.R).
# usage: SC_OUT=<out> DRMTMB_LIB=<lib> Rscript r_run.R <route> [seed_from seed_to]   (run from this directory)
args <- commandArgs(TRUE); route <- args[1]
s_from <- if (length(args) >= 3) as.integer(args[2]) else 1L; s_to <- if (length(args) >= 3) as.integer(args[3]) else 300L
if (nzchar(Sys.getenv("DRMTMB_LIB"))) .libPaths(c(Sys.getenv("DRMTMB_LIB"), .libPaths()))
suppressPackageStartupMessages(library(drmTMB)); cat("drmTMB", as.character(packageVersion("drmTMB")), "\n")
O <- Sys.getenv("SC_OUT", "."); dir.create(file.path(O, "r"), showWarnings = FALSE, recursive = TRUE)
tree <- if (grepl("phylo", route)) ape::read.tree("tree.nwk") else NULL
if (grepl("spatial", route)) { cc <- read.csv("coords.csv"); coords <- as.matrix(cc[, 2:3]); rownames(coords) <- cc$id }
sdform <- function(lev, coef, z) {
  f <- as.formula(if (route %in% c("lord_poisson", "lord_nb2")) sprintf('sd(id, dpar = "mu", coef = "%s") ~ %s', coef, z) else
    if (is.null(lev)) sprintf('sd(id, coef = "%s") ~ %s', coef, z) else
    sprintf('sd(id, level = "%s", coef = "%s") ~ %s', lev, coef, z)); f }
cfg <- list(  # route -> rhs term, SD level, sigma formula present, family
  poisson_animal = list("animal(1 + x | id, A = K)", "animal", FALSE, stats::poisson()),
  poisson_labelled = list("animal(1 + x | p | id, A = K)", "animal", FALSE, stats::poisson()),
  nb2_relmat = list("relmat(1 + x | id, K = K)", "relmat", TRUE, nbinom2()),
  gauss_animal = list("animal(1 + x | id, A = K)", "animal", TRUE, gaussian()),
  gauss_ord = list("(1 + x | id)", NULL, TRUE, gaussian()),
  lord_poisson = list("(1 + x | id)", NULL, FALSE, stats::poisson()),
  lord_nb2 = list("(1 + x | id)", NULL, TRUE, nbinom2()),
  poisson_phylo = list("phylo(1 + x | id, tree = tree)", "phylogenetic", FALSE, stats::poisson()),
  poisson_spatial = list("spatial(1 + x | id, coords = coords)", "spatial", FALSE, stats::poisson()))[[route]]
for (s in s_from:s_to) {
  tag <- sprintf("%s_s%03d", route, s)
  d <- read.csv(file.path(O, "data", paste0(tag, ".csv"))); ids <- unique(d$g)
  d$id <- factor(d$g, levels = ids)
  if (file.exists(file.path(O, "data", paste0(tag, "_K.csv")))) {
    K <- as.matrix(read.csv(file.path(O, "data", paste0(tag, "_K.csv")), header = FALSE))
    kid <- read.csv(file.path(O, "data", paste0(tag, "_ids.csv")))$id; dimnames(K) <- list(kid, kid)
  }
  if (route %in% c("poisson_phylo", "poisson_spatial")) d$id <- factor(d$g)
  f <- as.formula(paste("y ~ x +", cfg[[1]])); environment(f) <- environment()
  s0 <- sdform(cfg[[2]], "(Intercept)", "z0"); s1 <- sdform(cfg[[2]], "x", "z1")
  fm <- if (cfg[[3]]) bf(f, sigma ~ 1, s0, s1) else bf(f, s0, s1)
  fam <- cfg[[4]]
  t0 <- Sys.time()
  fit <- tryCatch(drmTMB(fm, family = fam, data = d), error = function(e) e)
  el <- as.numeric(Sys.time() - t0, units = "secs")
  if (inherits(fit, "error")) {
    cat(tag, "R ERROR:", conditionMessage(fit), "\n")
    write.csv(data.frame(ll = NA, convergence = "error", pdHess = NA, seconds = el, msg = substr(conditionMessage(fit), 1, 300)),
              file.path(O, "r", paste0(tag, "_ll.csv")), row.names = FALSE); next }
  par <- fit$opt$par; se <- tryCatch(sqrt(diag(fit$sdr$cov.fixed)), error = function(e) rep(NA_real_, length(par)))
  if (is.null(names(se)) || !identical(names(se), names(par))) se <- setNames(rep(NA_real_, length(par)), names(par))
  write.csv(data.frame(name = names(par), est = unname(par), se = unname(se)), file.path(O, "r", paste0(tag, ".csv")), row.names = FALSE)
  write.csv(data.frame(ll = sprintf("%.12f", as.numeric(logLik(fit))), convergence = fit$opt$convergence,
                       pdHess = isTRUE(fit$sdr$pdHess), seconds = el, msg = ""), file.path(O, "r", paste0(tag, "_ll.csv")), row.names = FALSE)
  cat(sprintf("%s ll=%.8f conv=%s pdHess=%s t=%.1fs\n", tag, as.numeric(logLik(fit)), fit$opt$convergence, isTRUE(fit$sdr$pdHess), el))
}

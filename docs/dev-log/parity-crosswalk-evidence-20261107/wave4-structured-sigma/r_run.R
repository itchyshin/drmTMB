# Native R drmTMB fit of NB2 structured sigma intercept + one slope (fixed SDs) -- the shape native
# drmTMB 0.8.1 DOES fit. Generates the data (seeded), writes it for the Julia run, and fits.
# usage: DRMTMB_LIB=<lib> Rscript r_run.R <route> [seed_from seed_to]   (run from this directory)
#   routes: animal relmat phylo spatial
args <- commandArgs(TRUE); route <- args[1]
s_from <- if (length(args) >= 3) as.integer(args[2]) else 1L; s_to <- if (length(args) >= 3) as.integer(args[3]) else 1L
if (nzchar(Sys.getenv("DRMTMB_LIB"))) .libPaths(c(Sys.getenv("DRMTMB_LIB"), .libPaths()))
suppressPackageStartupMessages({library(drmTMB); library(ape)}); cat("drmTMB", as.character(packageVersion("drmTMB")), "\n")
G <- 40; ne <- 12; ids <- sprintf("s%02d", 1:G)
rhs <- c(animal = "animal(1 + x | id, A = K)", relmat = "relmat(1 + x | id, K = K)",
         phylo = "phylo(1 + x | id, tree = tree)", spatial = "spatial(1 + x | id, coords = coords)")[[route]]
for (s in s_from:s_to) {
  tag <- sprintf("%s_s%02d", route, s); set.seed(910000 + 1000 * match(route, c("animal", "relmat", "phylo", "spatial")) + s)
  tree <- NULL; coords <- NULL; K <- NULL
  if (route == "phylo") { tree <- rcoal(G, tip.label = ids); write.tree(tree, file.path("data", paste0(tag, "_tree.nwk")))
                          Kg <- vcv(tree, corr = TRUE)[ids, ids] }
  else if (route == "spatial") { coords <- cbind(runif(G, 0, 8), runif(G, 0, 8)); rownames(coords) <- ids
                                 D <- as.matrix(dist(coords)); Kg <- exp(-D / median(D[D > 0])) + 1e-6 * diag(G)
                                 write.csv(data.frame(id = ids, lon = coords[, 1], lat = coords[, 2]), file.path("data", paste0(tag, "_coords.csv")), row.names = FALSE) }
  else if (route == "animal") { Kg <- 0.4^abs(outer(1:G, 1:G, "-")) }
  else { Kg <- vcv(rcoal(G, tip.label = ids), corr = TRUE)[ids, ids] * 1.7 }
  if (route %in% c("animal", "relmat")) { K <- Kg; dimnames(K) <- list(ids, ids)
      write.table(K, file.path("data", paste0(tag, "_K.csv")), sep = ",", row.names = FALSE, col.names = FALSE) }
  L <- t(chol(Kg)); u1 <- as.numeric(L %*% rnorm(G)); u2 <- as.numeric(L %*% rnorm(G))
  d <- data.frame(id = factor(rep(ids, each = ne), levels = ids)); gi <- as.integer(d$id)
  d$x <- rnorm(nrow(d)); sg <- exp(-0.3 + 0.45 * u1[gi] + 0.35 * u2[gi] * d$x)
  d$y <- rnbinom(nrow(d), size = 1 / sg^2, mu = exp(1 + 0.3 * d$x))
  write.csv(data.frame(y = d$y, x = d$x, id = as.character(d$id)), file.path("data", paste0(tag, ".csv")), row.names = FALSE)
  f <- y ~ x; fs <- as.formula(paste("~ 1 +", rhs)); environment(fs) <- environment()
  fm <- bf(f, sigma = fs)
  t0 <- Sys.time(); fit <- tryCatch(drmTMB(fm, family = nbinom2(), data = d), error = function(e) e)
  el <- as.numeric(Sys.time() - t0, units = "secs")
  if (inherits(fit, "error")) { cat(tag, "R ERROR:", conditionMessage(fit), "\n")
    write.csv(data.frame(ll = NA, convergence = "error", pdHess = NA, seconds = el, msg = substr(conditionMessage(fit), 1, 300)), file.path("r", paste0(tag, "_ll.csv")), row.names = FALSE); next }
  par <- fit$opt$par; se <- tryCatch(sqrt(diag(fit$sdr$cov.fixed)), error = function(e) rep(NA_real_, length(par)))
  if (is.null(names(se)) || !identical(names(se), names(par))) se <- setNames(rep(NA_real_, length(par)), names(par))
  write.csv(data.frame(name = names(par), est = unname(par), se = unname(se)), file.path("r", paste0(tag, ".csv")), row.names = FALSE)
  write.csv(data.frame(ll = sprintf("%.12f", as.numeric(logLik(fit))), convergence = fit$opt$convergence,
                       pdHess = isTRUE(fit$sdr$pdHess), seconds = el, msg = ""), file.path("r", paste0(tag, "_ll.csv")), row.names = FALSE)
  cat(sprintf("%s ll=%.8f conv=%s pdHess=%s t=%.1fs\n", tag, as.numeric(logLik(fit)), fit$opt$convergence, isTRUE(fit$sdr$pdHess), el))
}

# Native R drmTMB REML (and ML for reference) for the Gaussian structured q2 SD-regression cells:
#   y ~ x + KIND(1 + x | id), sd(id, level, coef = "(Intercept)") ~ z0, sd(id, level, coef = "x") ~ z1
# Generates seeded data (written for the Julia run) and fits. Run from this directory.
# usage: DRMTMB_LIB=<lib> Rscript r_run.R seed_from seed_to
args <- commandArgs(TRUE); s_from <- as.integer(args[1]); s_to <- as.integer(args[2])
if (nzchar(Sys.getenv("DRMTMB_LIB"))) .libPaths(c(Sys.getenv("DRMTMB_LIB"), .libPaths()))
suppressPackageStartupMessages({library(drmTMB); library(ape)}); cat("drmTMB", as.character(packageVersion("drmTMB")), "\n")
G <- 40; ne <- 12; ids <- sprintf("s%02d", 1:G)
# case = kind + variant: plain (unlabelled, sigma ~ 1), lab (phylo only, labelled), sx (phylo only, sigma ~ x)
cases <- list(animal = c("animal", "plain"), relmat = c("relmat", "plain"), phylo = c("phylo", "plain"),
              spatial = c("spatial", "plain"), phylo_lab = c("phylo", "lab"), phylo_sx = c("phylo", "sx"))
for (s in s_from:s_to) for (cn in names(cases)) {
  kind <- cases[[cn]][1]; variant <- cases[[cn]][2]; tag <- sprintf("%s_s%02d", cn, s)
  set.seed(420000 + 100 * s + match(cn, names(cases)))
  tree <- NULL; coords <- NULL; K <- NULL
  if (kind == "phylo") { tree <- rcoal(G, tip.label = ids); write.tree(tree, file.path("data", paste0(tag, "_tree.nwk")))
                         Kg <- vcv(tree, corr = TRUE)[ids, ids] }
  else if (kind == "spatial") { coords <- cbind(runif(G, 0, 8), runif(G, 0, 8)); rownames(coords) <- ids
                                D <- as.matrix(dist(coords)); Kg <- exp(-D / median(D[D > 0])) + 1e-6 * diag(G)
                                write.csv(data.frame(id = ids, lon = coords[, 1], lat = coords[, 2]), file.path("data", paste0(tag, "_coords.csv")), row.names = FALSE) }
  else if (kind == "animal") Kg <- 0.4^abs(outer(1:G, 1:G, "-"))
  else Kg <- vcv(rcoal(G, tip.label = ids), corr = TRUE)[ids, ids] * 1.7
  if (kind %in% c("animal", "relmat")) { K <- Kg; dimnames(K) <- list(ids, ids)
      write.table(K, file.path("data", paste0(tag, "_K.csv")), sep = ",", row.names = FALSE, col.names = FALSE) }
  L <- t(chol(Kg)); n0 <- rnorm(G); n1 <- rnorm(G); rho <- if (variant == "lab") 0.5 else 0
  d <- data.frame(id = factor(rep(ids, each = ne), levels = ids)); gi <- as.integer(d$id)
  d$x <- rnorm(nrow(d)); z0 <- rnorm(G); z1 <- rnorm(G); d$z0 <- z0[gi]; d$z1 <- z1[gi]
  u0 <- exp(-0.6 + 0.35 * z0) * as.numeric(L %*% n0); u1 <- exp(-0.9 + 0.3 * z1) * as.numeric(L %*% (rho * n0 + sqrt(1 - rho^2) * n1))
  sg <- exp(-0.7 + if (variant == "sx") 0.3 * d$x else 0)
  d$y <- 0.3 + 0.35 * d$x + u0[gi] + d$x * u1[gi] + sg * rnorm(nrow(d))
  write.csv(data.frame(y = d$y, x = d$x, z0 = d$z0, z1 = d$z1, id = as.character(d$id)), file.path("data", paste0(tag, ".csv")), row.names = FALSE)
  arg <- c(animal = "A = K", relmat = "K = K", phylo = "tree = tree", spatial = "coords = coords")[[kind]]
  lev <- c(animal = "animal", relmat = "relmat", phylo = "phylogenetic", spatial = "spatial")[[kind]]
  lab <- if (variant == "lab") "p | " else ""
  mu <- as.formula(sprintf("y ~ x + %s(1 + x | %sid, %s)", kind, lab, arg)); environment(mu) <- environment()
  f0 <- as.formula(sprintf('sd(id, level = "%s", coef = "(Intercept)") ~ z0', lev))
  f1 <- as.formula(sprintf('sd(id, level = "%s", coef = "x") ~ z1', lev))
  fs <- if (variant == "sx") sigma ~ x else sigma ~ 1
  fm <- bf(mu, fs, f0, f1)
  for (REML in c(TRUE, FALSE)) {
    est <- if (REML) "REML" else "ML"; t0 <- Sys.time()
    fit <- tryCatch(drmTMB(fm, family = gaussian(), data = d, REML = REML), error = function(e) e)
    el <- as.numeric(Sys.time() - t0, units = "secs")
    if (inherits(fit, "error")) { cat(tag, est, "R ERROR:", conditionMessage(fit), "\n"); next }
    ct <- summary(fit)$coefficients
    tab <- data.frame(name = rownames(ct), est = ct[, "estimate"], se = ct[, "std_error"])
    if ("eta_cor_phylo" %in% names(fit$opt$par)) {  # labelled block: the correlation parameter is not in the summary table
      cf <- fit$sdr$cov.fixed; i <- which(colnames(cf) == "eta_cor_phylo")
      tab <- rbind(tab, data.frame(name = "eta_cor_phylo", est = unname(fit$opt$par["eta_cor_phylo"]), se = sqrt(cf[i, i])))
    }
    write.csv(tab, file.path("r", sprintf("%s_%s.csv", tag, est)), row.names = FALSE)
    write.csv(data.frame(ll = sprintf("%.12f", as.numeric(logLik(fit))), convergence = fit$opt$convergence,
                         pdHess = isTRUE(fit$sdr$pdHess), seconds = el), file.path("r", sprintf("%s_%s_ll.csv", tag, est)), row.names = FALSE)
    cat(sprintf("%s %s ll=%.8f conv=%s pdHess=%s t=%.1fs\n", tag, est, as.numeric(logLik(fit)), fit$opt$convergence, isTRUE(fit$sdr$pdHess), el))
  }
}

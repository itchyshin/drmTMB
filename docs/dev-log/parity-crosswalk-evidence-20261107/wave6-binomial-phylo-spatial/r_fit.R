# Native drmTMB fits (ML) for the Binomial phylo/spatial q2 shapes. Usage: Rscript r_fit.R <seed> ...
here <- dirname(sub("--file=", "", grep("--file=", commandArgs(FALSE), value = TRUE)))
lib <- Sys.getenv("DRM_R_LIB", "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/lib")
.libPaths(c(lib, .libPaths())); suppressPackageStartupMessages(library(drmTMB))
cat("drmTMB", as.character(packageVersion("drmTMB")), "\n")
tree <- ape::read.tree(file.path(here, "tree.nwk"))
cc <- read.csv(file.path(here, "coords.csv")); coords <- as.matrix(cc[, 2:3]); rownames(coords) <- cc$id
for (seed in as.integer(commandArgs(TRUE))) for (kind in c("phylo", "spatial")) {
  d <- read.csv(file.path(here, "data", sprintf("%s_%d.csv", kind, seed))); d$id <- factor(d$id)
  lev <- if (kind == "phylo") "phylogenetic" else "spatial"
  mu <- if (kind == "phylo") y ~ x + phylo(1 + x | id, tree = tree) else y ~ x + spatial(1 + x | id, coords = coords)
  environment(mu) <- environment()
  f0 <- as.formula(sprintf('sd(id, level = "%s", coef = "(Intercept)") ~ z0', lev))
  f1 <- as.formula(sprintf('sd(id, level = "%s", coef = "x") ~ z1', lev))
  t0 <- Sys.time()
  fit <- tryCatch(drmTMB(bf(mu, f0, f1), family = binomial(), data = d), error = function(e) e)
  tag <- sprintf("%s_%d", kind, seed)
  if (inherits(fit, "error")) { cat(tag, "R ERROR:", conditionMessage(fit), "\n"); next }
  ct <- summary(fit)$coefficients
  out <- data.frame(term = c("mu_int", "mu_x", "sd0_int", "sd0_z0", "sd1_int", "sd1_z1"),
                    est = ct[, 1], se = ct[, 2])
  write.csv(out, file.path(here, "out", paste0("r_", tag, ".csv")), row.names = FALSE)
  writeLines(sprintf("%.10f %s %.2f", as.numeric(logLik(fit)), fit$opt$convergence, as.numeric(Sys.time() - t0, units = "secs")),
             file.path(here, "out", paste0("r_", tag, "_ll.txt")))
  cat(tag, sprintf("ll %.8f conv %s\n", as.numeric(logLik(fit)), fit$opt$convergence))
}

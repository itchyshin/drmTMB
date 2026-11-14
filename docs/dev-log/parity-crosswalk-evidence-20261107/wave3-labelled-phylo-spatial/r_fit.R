# Native R drmTMB labelled phylo/spatial q2 fits (run from this directory).
# Usage: DRMTMB_LIB=<lib> Rscript r_fit.R
if (nzchar(Sys.getenv("DRMTMB_LIB"))) .libPaths(c(Sys.getenv("DRMTMB_LIB"), .libPaths()))
suppressMessages(library(drmTMB))
cat("drmTMB", as.character(packageVersion("drmTMB")), "\n")
tree <- ape::read.tree("tree.nwk")
cc <- read.csv("coords.csv"); coords <- as.matrix(cc[, 2:3]); rownames(coords) <- cc$id
fams <- list(poisson = stats::poisson(), nb2 = nbinom2(), gaussian = gaussian())
resp <- c(poisson = "yp", nb2 = "yn", gaussian = "yg")
lls <- NULL
for (kind in c("phylo", "spatial")) {
  d <- read.csv(if (kind == "phylo") "data_phylo.csv" else "data_spatial.csv")
  d$id <- factor(d$id)
  lev <- if (kind == "phylo") "phylogenetic" else "spatial"
  term <- if (kind == "phylo") "phylo(1 + x | p | id, tree = tree)" else "spatial(1 + x | p | id, coords = coords)"
  for (fn in names(fams)) {
    f <- as.formula(paste(resp[[fn]], "~ x +", term)); environment(f) <- environment()
    s0 <- as.formula(sprintf('sd(id, level = "%s", dpar = "mu", coef = "(Intercept)") ~ z0', lev))
    s1 <- as.formula(sprintf('sd(id, level = "%s", dpar = "mu", coef = "x") ~ z1', lev))
    fm <- if (fn == "poisson") bf(f, s0, s1) else bf(f, sigma ~ 1, s0, s1)
    t0 <- Sys.time(); fit <- tryCatch(drmTMB(fm, family = fams[[fn]], data = d), error = function(e) e)
    if (inherits(fit, "error")) {
      msg <- gsub("\\s+", " ", conditionMessage(fit))
      cat(fn, kind, "R REFUSES:", msg, "\n")
      lls <- rbind(lls, data.frame(family = fn, kind = kind, ll = NA_character_, convergence = NA_integer_))
      next
    }
    el <- as.numeric(Sys.time() - t0, units = "secs")
    par <- fit$opt$par; se <- sqrt(diag(fit$sdr$cov.fixed))
    stopifnot(identical(names(par), names(se)))
    cat(fn, kind, sprintf("ll=%.10f conv=%d t=%.1fs rho=%.6f\n", as.numeric(logLik(fit)),
        fit$opt$convergence, el, 0.999999 * tanh(par[["eta_cor_phylo"]])))
    write.csv(data.frame(name = names(par), est = unname(par), se = unname(se)),
              sprintf("r_%s_%s.csv", fn, kind), row.names = FALSE)
    lls <- rbind(lls, data.frame(family = fn, kind = kind, ll = sprintf("%.12f", as.numeric(logLik(fit))),
                                 convergence = fit$opt$convergence))
  }
}
write.csv(lls, "r_ll.csv", row.names = FALSE)

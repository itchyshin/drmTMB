# Native R drmTMB fits of the six labelled q2 routes on the Julia-written data.
O <- "."  # run from this directory
if (nzchar(Sys.getenv("DRMTMB_LIB"))) .libPaths(c(Sys.getenv("DRMTMB_LIB"), .libPaths())); suppressMessages(library(drmTMB))
cat("drmTMB", as.character(packageVersion("drmTMB")), "\n")
d <- read.csv(file.path(O, "data.csv")); A <- as.matrix(read.csv(file.path(O, "A.csv"), header = FALSE))
ids <- read.csv(file.path(O, "A_ids.csv"))$id; dimnames(A) <- list(ids, ids); K <- A
d$g <- factor(d$g, levels = ids)
fams <- list(poisson = stats::poisson(), nb2 = nbinom2(), gaussian = gaussian())
resp <- c(poisson = "yp", nb2 = "yn", gaussian = "yg")
lls <- NULL
for (fn in names(fams)) for (kind in c("animal", "relmat")) {
  term <- if (kind == "animal") "animal(1 + x | p | g, A = A)" else "relmat(1 + x | p | g, K = K)"
  f <- as.formula(paste(resp[[fn]], "~ x +", term)); environment(f) <- environment()
  s0 <- eval(parse(text = sprintf('sd(g, level = "%s", dpar = "mu", coef = "(Intercept)") ~ z0', kind)))
  s1 <- eval(parse(text = sprintf('sd(g, level = "%s", dpar = "mu", coef = "x") ~ z1', kind)))
  fm <- if (fn == "poisson") bf(f, s0, s1) else bf(f, sigma ~ 1, s0, s1)
  t0 <- Sys.time(); fit <- drmTMB(fm, family = fams[[fn]], data = d)
  el <- as.numeric(Sys.time() - t0, units = "secs")
  par <- fit$opt$par
  se <- sqrt(diag(fit$sdr$cov.fixed))
  stopifnot(identical(names(par), names(se)))
  pl <- fit$obj$env$parList()
  cat(fn, kind, sprintf("ll=%.10f conv=%d t=%.1fs log_sd_phylo(mapped)=%s rho=%.6f\n", as.numeric(logLik(fit)), fit$opt$convergence, el,
      paste(format(pl$log_sd_phylo), collapse = ","), 0.999999 * tanh(par[["eta_cor_phylo"]])))
  write.csv(data.frame(name = names(par), est = unname(par), se = unname(se)),
            file.path(O, sprintf("r_%s_%s.csv", fn, kind)), row.names = FALSE)
  lls <- rbind(lls, data.frame(family = fn, kind = kind, ll = sprintf("%.12f", as.numeric(logLik(fit))), convergence = fit$opt$convergence))
}
write.csv(lls, file.path(O, "r_ll.csv"), row.names = FALSE)

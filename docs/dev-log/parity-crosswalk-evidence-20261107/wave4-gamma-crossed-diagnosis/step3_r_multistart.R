# (b),(c) R: native drmTMB 0.8.1 objective, nlminb from R's estimate, from Julia's, and 30 random starts
# (same start distribution as step2_julia_multistart.jl: base + N(0, s^2), s in {0.5, 1.0}).
SP <- "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad"
.libPaths(c(file.path(SP, "agree-poisson-q2/lib"), .libPaths())); suppressMessages(library(drmTMB))
O <- file.path(SP, "drmr/docs/dev-log/parity-crosswalk-evidence-20261107/wave2-joint-sigma")
d <- read.csv(file.path(O, "data_gamma_crossed.csv")); d$id <- factor(d$id); d$g <- factor(d$g)
fit <- drmTMB(bf(y ~ x + (1 | id), sigma ~ 1 + (1 | g), sd(id) ~ w, sd(g, dpar = "sigma") ~ z),
              family = Gamma(link = "log"), data = d)
ob <- fit$obj; r <- ob$env$random
j <- read.csv(file.path(O, "jcoef_gamma_crossed.csv"))$est
rest <- fit$opt$par
run <- function(st, zero_inner = TRUE) {
  if (zero_inner) ob$env$last.par.best[r] <- 0
  op <- try(nlminb(st, ob$fn, ob$gr, control = list(rel.tol = 1e-12, iter.max = 500)), silent = TRUE)
  if (inherits(op, "try-error")) return(list(ll = NA, conv = NA, par = rep(NA, 7), pd = NA, g = NA))
  ob$env$last.par.best[r] <- 0; v <- ob$fn(op$par)
  H <- try(optimHess(op$par, ob$fn, ob$gr), silent = TRUE)
  pd <- !inherits(H, "try-error") && all(is.finite(H)) && all(eigen(H, symmetric = TRUE)$values > 0)
  list(ll = -op$objective, conv = op$convergence, par = op$par, pd = pd, g = max(abs(ob$gr(op$par))))
}
base <- c(0.8, 0.4, log(0.5), log(0.5), 0, log(0.3), 0)
set.seed(20261108)
res <- list(R_default = run(rest), from_R_est = run(rest), from_J_est = run(j))
for (s in c(0.5, 1.0)) for (k in 1:15) res[[sprintf("rand_s%s_%d", s, k)]] <- run(base + s * rnorm(7))
df <- do.call(rbind, lapply(names(res), function(n) { x <- res[[n]]
  data.frame(label = n, ll = x$ll, conv = x$conv, pd = x$pd, maxgrad = x$g, t(setNames(x$par, paste0("th", 1:7)))) }))
write.csv(df, file.path(SP, "drmr/docs/dev-log/parity-crosswalk-evidence-20261107/wave4-gamma-crossed-diagnosis/r_multistart.csv"), row.names = FALSE)
options(width = 200); print(transform(df[, 1:5], ll = round(ll, 8), maxgrad = signif(maxgrad, 3)))
cat("\ndistinct optima (ll rounded to 1e-4):\n"); print(table(round(df$ll[df$conv == 0 & !is.na(df$ll)], 4), useNA = "ifany"))
cat("\nR_default start is the package's own start; here `from_R_est` is a restart of nlminb at the reported estimate\n")

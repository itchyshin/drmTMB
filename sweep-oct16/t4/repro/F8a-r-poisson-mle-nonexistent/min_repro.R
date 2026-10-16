## Minimal, self-contained repro for the issue body (data inlined).
## Rscript min_repro.R > min_repro.out 2>&1
library(drmTMB)
cat("drmTMB", format(packageVersion("drmTMB")), "\n"); print(sessionInfo())

## sweep-oct16/t4 cell pois_n8_lowmean: x ~ N(0,1), y ~ Poisson(exp(-1.5 + 0.5 x)), n = 8
## rep 3 (R seed 933664970): all y = 0
d3 <- read.csv(text = "y,x
0,-0.0292785730789077
0,-2.07527755306188
0,-1.26224739973712
0,-0.135456173606004
0,-1.05584042635037
0,0.218711141103825
0,0.915790979674801
0,0.0391185640938337")
## rep 25 (R seed 933664992): the only positive count sits at the largest x
d25 <- read.csv(text = "y,x
0,-0.0128456813234092
0,-0.999152075133934
0,-0.116986412764093
0,0.169752769029484
1,0.788578561846954
0,-1.2588784926485
0,-1.44608776644376
0,0.168992027341795")

for (d in list(d3, d25)) {
  fit <- drmTMB(bf(y ~ x), family = poisson(), data = d)   # no warning is emitted
  print(cbind(estimate = fit$opt$par, se = sqrt(diag(vcov(fit)))))
  cat("logLik", format(as.numeric(logLik(fit))), "| opt code", fit$opt$convergence, fit$opt$message,
      "| is_converged", is_converged(fit), "| status", convergence_status(fit),
      "| check_drm ok", attr(check_drm(fit), "ok"), "\n")
  chk <- check_drm(fit)
  rows <- as.data.frame(chk)[chk$check %in% c("standard_errors_inflated", "hessian_conditioning"), c("check", "status", "value")]
  print(rows, row.names = FALSE)
}
## Start dependence on rep 25: the reported slope is wherever the optimiser stopped.
for (s in list(c(0, 0), c(-40, 0), c(-10, 10))) {
  f <- drmTMB(bf(y ~ x), family = poisson(), data = d25,
              control = drm_control(start = list("fixef:mu:(Intercept)" = s[1], "fixef:mu:x" = s[2])))
  cat("start", s, "-> slope", round(f$opt$par[2], 3), "SE", signif(sqrt(diag(vcov(f)))[2], 3),
      "is_converged", is_converged(f), "\n")
}
## Base R for comparison
g3 <- glm(y ~ x, family = poisson(), data = d3)               # silent: converged = TRUE
cat("glm rep 3: converged", g3$converged, "iter", g3$iter, "coef", signif(coef(g3), 6), "\n")
g25 <- withCallingHandlers(glm(y ~ x, family = poisson(), data = d25),
  warning = function(w) { cat("glm rep 25 warning:", conditionMessage(w), "\n"); invokeRestart("muffleWarning") })

# From the isolated package root: Rscript docs/dev-log/cmr/examples/fixed-effects.R
devtools::load_all(".", quiet = TRUE)
y <- rbind(c(1,0,0,0),c(1,0,1,0),c(1,1,0,0),c(1,1,1,0),
           c(1,0,0,1),c(1,0,1,1),c(1,1,0,1),c(1,1,1,1))
d <- cmr_data(y, id=1:8, occasions=1:4, units="years", frequency=c(12,4,8,4,4,4,4,4))
fit <- drm_cjs(d, phi=~1, p=~1)
stopifnot(fit$convergence == 0L, abs(fit$logLik + 86.998737757672856) < 1e-6)
print(fit$coefficients)
cat("CMR_FIT_SMOKE_OK\n")

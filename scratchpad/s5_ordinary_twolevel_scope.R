# S5 scoping: does the ORDINARY two-level (between/within individual) DHGLM carry the
# q-ladder toward q12 under ML today? Shinichi's realization: q12's identifiable home
# is the replicated ordinary case (random slopes on location + scale + scale-of-scale).
# Probe a complexity ladder under ML (REML gate 1973 still blocks ordinary sigma RE).
suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))
set.seed(7)
n_id <- 150L; n_each <- 8L; n <- n_id * n_each     # replicated: 8 obs/individual
id <- rep(seq_len(n_id), each = n_each)
x <- rnorm(n)
# between-individual location (int, slope) and scale (int, slope) random effects
b_mu_int <- rnorm(n_id, 0, 0.6); b_mu_slp <- rnorm(n_id, 0, 0.3)
b_sg_int <- rnorm(n_id, 0, 0.4); b_sg_slp <- rnorm(n_id, 0, 0.2)
mu <- 0.3 + 0.5 * x + b_mu_int[id] + b_mu_slp[id] * x
lsig <- log(0.5) + 0.2 * x + b_sg_int[id] + b_sg_slp[id] * x
y <- rnorm(n, mu, exp(lsig))
d <- data.frame(y = y, x = x, id = factor(id))

ck <- function(lbl, form) {
  r <- tryCatch({
    f <- suppressWarnings(drmTMB(form, gaussian(), d, control = drm_control(optimizer_preset = "robust")))
    sprintf("FITS  conv %d  pdHess %s  npar %d", f$opt$convergence, isTRUE(f$sdr$pdHess), length(f$opt$par))
  }, error = function(e) paste("REJECTED/ERROR:", sub("\n.*", "", conditionMessage(e))))
  cat(sprintf("%-46s %s\n", lbl, r))
}
cat("=== ordinary two-level DHGLM complexity ladder (ML, n_id=150 x 8 obs) ===\n")
ck("loc int only:                y~x+(1|id)",              bf(y ~ x + (1 | id), sigma ~ 1))
ck("loc+scale int (indep):       +sigma~x+(1|id)",         bf(y ~ x + (1 | id), sigma ~ x + (1 | id)))
ck("loc+scale int CORRELATED:    (1|p|id) both",           bf(y ~ x + (1 | p | id), sigma ~ x + (1 | p | id)))
ck("loc slope corr:              (1+x|p|id) mu",           bf(y ~ x + (1 + x | p | id), sigma ~ x + (1 | p | id)))
ck("scale slope (indep):         sigma (0+x|id)",          bf(y ~ x + (1 | id), sigma ~ x + (1 | id) + (0 + x | id)))
ck("FULL q-ish: loc+scale slopes corr", bf(y ~ x + (1 + x | p | id), sigma ~ x + (1 + x | p | id)))
cat("\nS5 ORDINARY SCOPE DONE\n")

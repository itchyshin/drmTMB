# #1551 extension: nbinom2, beta_family and binomial with an ordinary (1 | g) are also admitted by
# engine = "julia", run the full Julia fit, then abort at the "resd" coef_labels echo.
# drmTMB ca3ddefa5ea11bbfd3b765615dfbb89305d2485a + DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7; R 4.3.3, Julia 1.12.7
# Data: sweep-oct16/t6/data/{nbinom2,beta,binomial}_ri.csv, committed at
#   https://github.com/itchyshin/drmTMB/tree/cd6d3da751bdec440996ca2168f68c4d31490ffa/sweep-oct16/t6/data
Sys.setenv(JULIA_DEPOT_PATH = "/opt/julia-depot", DRMODELS_JL_PATH = "/home/user/DRModels.jl",
           NOT_CRAN = "true", JULIA_HOME = "/opt/julia-env/bin")
library(drmTMB)
if (!exists("%||%", baseenv())) assign("%||%", function(x, y) if (is.null(x)) y else x, envir = globalenv())  # #1550 (R < 4.4)
D <- "/home/user/drmTMB/sweep-oct16/t6/data"
drmTMB:::drm_julia_fe_only_fence_families()   # the pre-Julia refusal list: none of the three below is in it
cells <- list(
  nbinom2  = list(file = "nbinom2_ri.csv",  seed = 20261016621, fam = nbinom2(),
                  f = bf(y ~ x + f + (1 | g), sigma ~ x)),
  beta     = list(file = "beta_ri.csv",     seed = 20261016611, fam = beta_family(),
                  f = bf(y ~ x + f + (1 | g), sigma ~ x)),
  binomial = list(file = "binomial_ri.csv", seed = 20261016617, fam = binomial(),
                  f = bf(cbind(successes, failures) ~ x + f + (1 | g))))
for (nm in names(cells)) {
  cl <- cells[[nm]]; d <- read.csv(file.path(D, cl$file))
  ft <- drmTMB(cl$f, family = cl$fam, data = d)            # native: fits
  t0 <- Sys.time()
  r <- tryCatch(drmTMB(cl$f, family = cl$fam, data = d, engine = "julia"), error = function(e) e)
  secs <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  msg <- if (inherits(r, "error")) strsplit(conditionMessage(r), "\n")[[1]] else "ADMITTED"
  cat(sprintf("%-8s seed %.0f | tmb logLik %.4f | julia: %.1f s to failure\n  %s\n  %s\n",
              nm, cl$seed, as.numeric(logLik(ft)), secs, msg[1], if (length(msg) > 1) msg[2] else ""))
  # expected: a drmTMB-worded refusal before Julia starts, or a fit; observed: Julia stack trace after the fit
}

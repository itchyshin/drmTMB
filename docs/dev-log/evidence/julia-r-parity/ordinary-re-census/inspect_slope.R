# Why the random-slope Julia fit carries no `sdpars` (parity leaf A5, G2
# follow-through). Fits bf(y ~ x + (1 + x | g), sigma ~ 1) on both engines and
# prints, verbatim, what each engine reports for the random-effect block.
# Usage: OPENBLAS_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true DRM_JL_PATH=<pin> Rscript inspect_slope.R <outdir>
suppressMessages(devtools::load_all(".", quiet = TRUE))
args <- commandArgs(trailingOnly = TRUE)
outdir <- if (length(args) >= 1L) args[[1]] else dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(outdir, "make_data.R"))
d <- make_data("gaussian_random_slope")
f <- bf(y ~ x + (1 + x | g), sigma ~ 1)
ft <- drmTMB(f, family = gaussian(), data = d, engine = "tmb", REML = FALSE)
fj <- suppressWarnings(drmTMB(f, family = gaussian(), data = d, engine = "julia", REML = FALSE))
cat("== native sdpars\n"); print(ft$sdpars); cat("== native corpars\n"); print(ft$corpars)
cat("== julia sdpars\n"); print(fj$sdpars); cat("== julia corpars\n"); print(fj$corpars)
cat("== julia bridge raw_coef_names\n"); print(fj$bridge$raw_coef_names)
cat("== julia bridge coef_names\n"); print(fj$bridge$coef_names)
cat("== julia bridge coefficients (all)\n"); print(fj$bridge$coefficients)
cat("== julia bridge coef_name_map\n"); print(fj$bridge$coef_name_map)
cat("== julia bridge dpars\n"); print(fj$bridge$dpars)
cat("== julia bridge corpairs\n"); print(fj$bridge$corpairs)
cat("== julia bridge vcov_names\n"); print(fj$bridge$vcov_names)
cat("== formula entries structured (mu)\n"); print(fj$formula$entries$mu$structured)

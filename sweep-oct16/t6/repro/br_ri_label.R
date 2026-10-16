# engine = "julia" refuses Gaussian (1 | g) whenever the mean has a factor fixed effect (label contract skipped
# on the conditional-components bridge entry).
# drmTMB ca3ddefa5ea11bbfd3b765615dfbb89305d2485a + DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7; R 4.3.3, Julia 1.12.7
# Data: sweep-oct16/t6/data/gaussian_ri.csv (seed 20261016601), committed at
#   https://github.com/itchyshin/drmTMB/tree/cd6d3da751bdec440996ca2168f68c4d31490ffa/sweep-oct16/t6/data
Sys.setenv(JULIA_DEPOT_PATH = "/opt/julia-depot", DRMODELS_JL_PATH = "/home/user/DRModels.jl",
           NOT_CRAN = "true", JULIA_HOME = "/opt/julia-env/bin")
library(drmTMB)
if (!exists("%||%", baseenv())) assign("%||%", function(x, y) if (is.null(x)) y else x, envir = globalenv())  # #1550 (R < 4.4)
d <- read.csv("/home/user/drmTMB/sweep-oct16/t6/data/gaussian_ri.csv")

ft <- drmTMB(bf(y ~ x + f + (1 | g), sigma ~ x), family = gaussian(), data = d)   # native: fits
logLik(ft)
# expected: admitted (vignettes/julia-engine.Rmd:356 lists a Gaussian "ordinary random-effect" route)
system.time(e1 <- try(drmTMB(bf(y ~ x + f + (1 | g), sigma ~ x), family = gaussian(), data = d, engine = "julia")))
d$f <- factor(d$f)
e2 <- try(drmTMB(bf(y ~ x + f + (1 | g), sigma ~ 1), family = gaussian(), data = d, engine = "julia"))  # same refusal
e3 <- try(drmTMB(bf(y ~ x + f), family = gaussian(), data = d, engine = "julia"))  # no (1 | g): admitted
class(e3)
fj <- drmTMB(bf(y ~ x + (1 | g), sigma ~ x), family = gaussian(), data = d, engine = "julia")  # no factor: admitted
class(fj); as.numeric(logLik(fj) - logLik(drmTMB(bf(y ~ x + (1 | g), sigma ~ x), family = gaussian(), data = d)))

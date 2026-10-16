# drmTMB_julia fits have no simulate() or predict_parameters() method: generic "no applicable method" errors.
# drmTMB ca3ddefa5ea11bbfd3b765615dfbb89305d2485a + DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7; R 4.3.3, Julia 1.12.7
# Data: sweep-oct16/t6/data/gaussian_fixed.csv (seed 20261016600) and nd_main.csv, committed at
#   https://github.com/itchyshin/drmTMB/tree/cd6d3da751bdec440996ca2168f68c4d31490ffa/sweep-oct16/t6/data
Sys.setenv(JULIA_DEPOT_PATH = "/opt/julia-depot", DRMODELS_JL_PATH = "/home/user/DRModels.jl",
           NOT_CRAN = "true", JULIA_HOME = "/opt/julia-env/bin")
library(drmTMB)
if (!exists("%||%", baseenv())) assign("%||%", function(x, y) if (is.null(x)) y else x, envir = globalenv())  # #1550 (R < 4.4)
d  <- read.csv("/home/user/drmTMB/sweep-oct16/t6/data/gaussian_fixed.csv")
nd <- read.csv("/home/user/drmTMB/sweep-oct16/t6/data/nd_main.csv")
fj <- drmTMB(bf(y ~ x + f, sigma ~ x), family = gaussian(), data = d, engine = "julia")
class(fj)
try(simulate(fj, nsim = 10, seed = 261016700))   # expected: draws, or a drmTMB refusal naming engine = "tmb"
try(predict_parameters(fj, newdata = nd))        # same expectation
try(heritability(fj))                            # for contrast: a drmTMB-worded bridge refusal exists here
grep("simulate|predict_parameters", as.character(methods(class = "drmTMB_julia")), value = TRUE)  # character(0)
ft <- drmTMB(bf(y ~ x + f, sigma ~ x), family = gaussian(), data = d)
dim(simulate(ft, nsim = 10, seed = 261016700)); dim(predict_parameters(ft, newdata = nd))   # native works

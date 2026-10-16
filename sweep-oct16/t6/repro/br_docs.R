# drmTMB docs disagree with engine = "julia" family admission.
# drmTMB ca3ddefa5ea11bbfd3b765615dfbb89305d2485a + DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7; R 4.3.3, Julia 1.12.7
# Data: sweep-oct16/t6/data/{skew_normal,binomial,cumulative_logit}_fixed.csv, committed at
#   https://github.com/itchyshin/drmTMB/tree/cd6d3da751bdec440996ca2168f68c4d31490ffa/sweep-oct16/t6/data
# Docs at ca3ddefa:
#   vignettes/julia-engine.Rmd:363            | `skew_normal()` or another family | not currently available through the Julia engine |
#   vignettes/distribution-families.Rmd:804-806  "... Factor responses, proportions with trial weights, structured effects,
#                                                 bivariate responses, and `engine = "julia"` remain unsupported."   (plain binomial)
#   vignettes/proportion-beta-binomial.Rmd:167-170 "It still rejects ... bivariate or mixed responses, and `engine = "julia"`." (plain binomial)
#   vignettes/model-map.Rmd:79 lists "binomial structured effects or Julia bridge" as unsupported
#   R/drmTMB.R:144-150 (@param engine) names Gaussian, bivariate Gaussian, Student-t, lognormal, Poisson, NB2, Gamma, Beta,
#     Binomial, truncated_nbinom2, zero_one_beta, tweedie, beta_binomial -- not skew_normal(), not cumulative_logit()
# Contradicted by: R/julia-family-registry.R:168 spec("skew_normal", ..., fe = TRUE), :146 spec("cumulative_logit", ...),
#   julia-engine.Rmd:361-362, and NEWS.md:1203 "## `engine = "julia"` admits `skew_normal()` on the fixed-effect route".
Sys.setenv(JULIA_DEPOT_PATH = "/opt/julia-depot", DRMODELS_JL_PATH = "/home/user/DRModels.jl",
           NOT_CRAN = "true", JULIA_HOME = "/opt/julia-env/bin")
library(drmTMB)
if (!exists("%||%", baseenv())) assign("%||%", function(x, y) if (is.null(x)) y else x, envir = globalenv())  # #1550 (R < 4.4)
D <- "/home/user/drmTMB/sweep-oct16/t6/data"
both <- function(f, fam, d) { fj <- drmTMB(f, family = fam, data = d, engine = "julia")
  ft <- drmTMB(f, family = fam, data = d); cj <- unlist(coef(fj)); ct <- unlist(coef(ft))
  c(class = class(fj)[1], coef_maxabs = signif(max(abs(cj - ct[names(cj)])), 3),
    logLik_diff = signif(as.numeric(logLik(fj) - logLik(ft)), 3)) }
both(bf(y ~ x + f, sigma ~ x, nu ~ 1), skew_normal(),               # seed 20261016604; docs: "not available"
     read.csv(file.path(D, "skew_normal_fixed.csv")))
both(bf(cbind(successes, failures) ~ x + f), binomial(),             # seed 20261016616; docs: "unsupported"
     read.csv(file.path(D, "binomial_fixed.csv")))
d <- read.csv(file.path(D, "cumulative_logit_fixed.csv")); d$y <- ordered(d$y)
both(bf(y ~ x + f), cumulative_logit(), d)                           # seed 20261016626; not in @param engine
# expected: each fit either refused, or listed as admitted in every doc above

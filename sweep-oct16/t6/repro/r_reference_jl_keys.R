# drmTMB ca3ddefa5ea11bbfd3b765615dfbb89305d2485a reference values for the DRModels.jl (f71b2923360e9e5d4591e0d6e15a9ef9db0356d7) repros.
# Data: sweep-oct16/t6/data at https://github.com/itchyshin/drmTMB/tree/cd6d3da751bdec440996ca2168f68c4d31490ffa/sweep-oct16/t6/data
suppressPackageStartupMessages(library(drmTMB))
D <- "/home/user/drmTMB/sweep-oct16/t6/data"
rd <- function(f) utils::read.csv(file.path(D, f), stringsAsFactors = FALSE)
nd <- rd("nd_main.csv")
cat("drmTMB", as.character(packageVersion("drmTMB")), "\n")
s <- drmTMB(bf(y ~ x + f, sigma ~ x, nu ~ 1), family = student(), data = rd("student_fixed.csv"))
cat("student_fixed nu response nd[1] =", format(predict(s, newdata = nd, dpar = "nu", type = "response")[1], digits = 15), "\n")
k <- drmTMB(bf(y ~ x + f, sigma ~ x, nu ~ 1), family = skew_normal(), data = rd("skew_normal_fixed.csv"))
cat("skew_normal_fixed nu response nd[1] =", format(predict(k, newdata = nd, dpar = "nu", type = "response")[1], digits = 15), "\n")
z <- drmTMB(bf(y ~ x + f, sigma ~ x, zoi ~ 1, coi ~ 1), family = zero_one_beta(), data = rd("zero_one_beta_fixed.csv"))
cat("zero_one_beta_fixed mu response nd[1] =", format(predict(z, newdata = nd, dpar = "mu", type = "response")[1], digits = 15),
    " fitted(z)[1:3] =", format(fitted(z)[1:3], digits = 10), "\n")
dc <- rd("cumulative_logit_fixed.csv"); dc$y <- ordered(dc$y)
cl <- drmTMB(bf(y ~ x + f), family = cumulative_logit(), data = dc)
cat("cumulative_logit_fixed mu link nd[1:3] =", format(predict(cl, newdata = nd, dpar = "mu", type = "link")[1:3], digits = 10), "\n")
ln <- drmTMB(bf(y ~ x + f, sigma ~ x), family = lognormal(), data = rd("lognormal_fixed.csv"))
cat("lognormal_fixed fitted[1] =", format(fitted(ln)[1], digits = 10), " predict(mu, response)[1] =",
    format(predict(ln, dpar = "mu", type = "response")[1], digits = 10), "\n")
tn <- drmTMB(bf(y ~ x + f, sigma ~ x), family = truncated_nbinom2(), data = rd("truncated_nbinom2_fixed.csv"))
cat("truncated_nbinom2_fixed fitted[1] =", format(fitted(tn)[1], digits = 10), " predict(mu, response)[1] =",
    format(predict(tn, dpar = "mu", type = "response")[1], digits = 10), "\n")
kr <- drmTMB(bf(y ~ x + f + (1 | g), sigma ~ x, nu ~ 1), family = skew_normal(), data = rd("skew_normal_ri.csv"))
cat("skew_normal_ri: logLik =", format(as.numeric(logLik(kr)), digits = 10), " pdHess =", kr$sdreport$pdHess, "\n")
tr <- drmTMB(bf(y ~ x + f + (1 | g), sigma ~ x), family = truncated_nbinom2(), data = rd("truncated_nbinom2_ri.csv"))
cat("truncated_nbinom2_ri: logLik =", format(as.numeric(logLik(tr)), digits = 10), " pdHess =", tr$sdreport$pdHess, "\n")
for (cc in c("student", "poisson", "binomial")) {
  dd <- rd(paste0(cc, "_ri.csv"))
  ff <- switch(cc, student = bf(y ~ x + f + (1 | g), sigma ~ x, nu ~ 1), poisson = bf(y ~ x + f + (1 | g)),
               binomial = bf(cbind(successes, failures) ~ x + f + (1 | g)))
  m <- drmTMB(ff, family = switch(cc, student = student(), poisson = poisson(), binomial = binomial()), data = dd)
  cat(cc, "_ri (TMB Laplace) logLik = ", format(as.numeric(logLik(m)), digits = 12), "\n", sep = "")
  if (cc == "poisson") {
    Y <- as.matrix(simulate(m, nsim = 1000, seed = 261016719))   # drmTMB default re.form = NA
    gm <- function(v) tapply(v, dd$g, mean)
    cat("poisson_ri drmTMB simulate default: mean =", mean(Y), " var of group means: data", var(gm(dd$y)),
        " draws (avg over 1000)", mean(apply(Y, 2, function(v) var(gm(v)))), "\n")
  }
}

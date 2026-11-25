if (nzchar(Sys.getenv("DRMTMB_LIB"))) .libPaths(c(Sys.getenv("DRMTMB_LIB"), .libPaths())); suppressMessages(library(drmTMB))
d <- read.csv("../step1-poisson-animal-q2-agreement/data.csv"); A <- as.matrix(read.csv("../step1-poisson-animal-q2-agreement/A.csv", header=FALSE))
ids <- read.csv("../step1-poisson-animal-q2-agreement/A_ids.csv")$id; dimnames(A) <- list(ids, ids)
d$id <- factor(d$g, levels = ids); K <- A
set.seed(1); d$yg <- 0.2 + 0.3*d$x + rnorm(nrow(d))
try_fit <- function(lab, f, fam, ...) {
  environment(f) <- environment()
  r <- tryCatch({fit <- drmTMB(f, family = fam, data = d, ...); sprintf("OK ll=%.4f conv=%s", as.numeric(logLik(fit)), fit$opt$convergence)}, error=function(e) paste("ERROR:", conditionMessage(e)))
  cat(lab, "->", substr(r,1,400), "\n")
}
sdf <- function(lvl) list(sd(id, level = lvl, dpar = "mu", coef = "(Intercept)") ~ z0, sd(id, level = lvl, dpar = "mu", coef = "x") ~ z1)
# Poisson labelled no SD
try_fit("pois animal lab noSD", bf(y ~ x + animal(1 + x | p | id, A = A)), poisson())
try_fit("pois animal lab +SD", bf(y ~ x + animal(1 + x | p | id, A = A), sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ z0, sd(id, level = "animal", dpar = "mu", coef = "x") ~ z1), poisson())
try_fit("pois relmat lab +SD", bf(y ~ x + relmat(1 + x | p | id, K = K), sd(id, level = "relmat", dpar = "mu", coef = "(Intercept)") ~ z0, sd(id, level = "relmat", dpar = "mu", coef = "x") ~ z1), poisson())
try_fit("pois animal lab +slopeSD", bf(y ~ x + animal(1 + x | p | id, A = A), sd(id, level = "animal", dpar = "mu", coef = "x") ~ z1), poisson())
try_fit("nb2 animal lab +SD", bf(y ~ x + animal(1 + x | p | id, A = A), sigma ~ 1, sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ z0, sd(id, level = "animal", dpar = "mu", coef = "x") ~ z1), nbinom2())
try_fit("nb2 animal lab noSD", bf(y ~ x + animal(1 + x | p | id, A = A), sigma ~ 1), nbinom2())
try_fit("gau animal lab noSD", bf(yg ~ x + animal(1 + x | p | id, A = A), sigma ~ 1), gaussian())
try_fit("gau animal lab +SD", bf(yg ~ x + animal(1 + x | p | id, A = A), sigma ~ 1, sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ z0, sd(id, level = "animal", dpar = "mu", coef = "x") ~ z1), gaussian())
try_fit("gau relmat lab +SD", bf(yg ~ x + relmat(1 + x | p | id, K = K), sigma ~ 1, sd(id, level = "relmat", dpar = "mu", coef = "(Intercept)") ~ z0, sd(id, level = "relmat", dpar = "mu", coef = "x") ~ z1), gaussian())
try_fit("gau animal unlab +SD", bf(yg ~ x + animal(1 + x | id, A = A), sigma ~ 1, sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ z0, sd(id, level = "animal", dpar = "mu", coef = "x") ~ z1), gaussian())

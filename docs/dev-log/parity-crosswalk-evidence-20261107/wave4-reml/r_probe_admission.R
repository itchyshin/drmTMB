.libPaths(c("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/lib", .libPaths()))
suppressPackageStartupMessages({library(drmTMB); library(ape)})
cat("drmTMB", as.character(packageVersion("drmTMB")), "\n")
set.seed(7); G <- 40; m <- 12; ids <- sprintf("s%02d", 1:G)
tree <- rcoal(G, tip.label=ids); Kp <- vcv(tree, corr=TRUE)[ids,ids]
A <- 0.35^abs(outer(1:G,1:G,"-")); dimnames(A) <- list(ids,ids)
coords <- cbind(runif(G,0,8), runif(G,0,8)); rownames(coords) <- ids
d <- data.frame(id=factor(rep(ids,each=m),levels=ids)); gi <- as.integer(d$id)
d$x <- rnorm(nrow(d)); d$z <- rnorm(nrow(d)); d$z0 <- rep(rnorm(G),each=m); d$z1 <- rep(rnorm(G),each=m)
u0<-rnorm(G);u1<-rnorm(G); d$y <- 0.2+0.3*d$x + exp(-0.9+0.3*d$z0)*u0[gi] + d$x*exp(-1+0.3*d$z1)*u1[gi] + rnorm(nrow(d),0,0.4)
d$h <- factor(rep(1:m, G))
try1 <- function(label, expr) { r <- tryCatch(expr, error=function(e) e)
  if (inherits(r,"error")) cat("REFUSE", label, ":", gsub("\\s+"," ",conditionMessage(r)), "\n")
  else cat("FITS  ", label, "ll=", as.numeric(logLik(r)), "conv=", r$opt$convergence, "estimator=", r$estimator, "\n") }
for (REML in c(FALSE,TRUE)) {
cat("=== REML =", REML, "\n")
try1("ordinary q2 coefSD", drmTMB(bf(y ~ x + (1 + x | id), sigma ~ 1, sd(id, coef="(Intercept)") ~ z0, sd(id, coef="x") ~ z1), family=gaussian(), data=d, REML=REML))
try1("ordinary q3 coefSD", drmTMB(bf(y ~ x + z + (1 + x + z | id), sigma ~ 1, sd(id, coef="(Intercept)") ~ z0, sd(id, coef="x") ~ z1, sd(id, coef="z") ~ z0), family=gaussian(), data=d, REML=REML))
try1("ordinary q4 coefSD", drmTMB(bf(y ~ x + z + z0 + (1 + x + z + z0| id), sigma ~ 1, sd(id, coef="(Intercept)") ~ z1, sd(id, coef="x") ~ z1, sd(id, coef="z") ~ z1, sd(id, coef="z0") ~ z1), family=gaussian(), data=d, REML=REML))
try1("ordinary iid sd(id) ~ z0", drmTMB(bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ z0), family=gaussian(), data=d, REML=REML))
for (k in c("animal","relmat","phylo","spatial")) {
  arg <- switch(k, animal="A = A", relmat="K = A", phylo="tree = tree", spatial="coords = coords")
  lev <- switch(k, animal="animal", relmat="relmat", phylo="phylogenetic", spatial="spatial")
  mu <- as.formula(sprintf("y ~ x + %s(1 + x | id, %s)", k, arg)); environment(mu) <- environment()
  f0 <- as.formula(sprintf('sd(id, level = "%s", coef = "(Intercept)") ~ z0', lev))
  f1 <- as.formula(sprintf('sd(id, level = "%s", coef = "x") ~ z1', lev))
  try1(paste(k,"q2 coefSD"), drmTMB(bf(mu, sigma ~ 1, f0, f1), family=gaussian(), data=d, REML=REML))
}
try1("joint mu+sigma ordinary", drmTMB(bf(y ~ x + (1 | id), sigma ~ 1 + (1 | id), sd(id) ~ z0, sd(id, dpar="sigma") ~ z0), family=gaussian(), data=d, REML=REML))
}

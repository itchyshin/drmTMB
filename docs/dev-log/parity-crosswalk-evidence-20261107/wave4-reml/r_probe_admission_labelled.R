.libPaths(c("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/lib", .libPaths()))
suppressPackageStartupMessages({library(drmTMB); library(ape)})
set.seed(7); G <- 40; m <- 12; ids <- sprintf("s%02d", 1:G)
tree <- rcoal(G, tip.label=ids); A <- 0.35^abs(outer(1:G,1:G,"-")); dimnames(A) <- list(ids,ids)
coords <- cbind(runif(G,0,8), runif(G,0,8)); rownames(coords) <- ids
d <- data.frame(id=factor(rep(ids,each=m),levels=ids)); gi <- as.integer(d$id)
d$x <- rnorm(nrow(d)); d$z0 <- rep(rnorm(G),each=m); d$z1 <- rep(rnorm(G),each=m)
d$y <- 0.2+0.3*d$x + rnorm(G)[gi] + d$x*rnorm(G)[gi]*0.5 + rnorm(nrow(d),0,0.4)
try1 <- function(label, expr) { r <- tryCatch(expr, error=function(e) e)
  if (inherits(r,"error")) cat("REFUSE", label, ":", gsub("\\s+"," ",conditionMessage(r)), "\n")
  else cat("FITS  ", label, "ll=", as.numeric(logLik(r)), "conv=", r$opt$convergence, "\n") }
for (k in c("animal","relmat","phylo","spatial")) {
  arg <- switch(k, animal="A = A", relmat="K = A", phylo="tree = tree", spatial="coords = coords")
  lev <- switch(k, animal="animal", relmat="relmat", phylo="phylogenetic", spatial="spatial")
  mu <- as.formula(sprintf("y ~ x + %s(1 + x | p | id, %s)", k, arg)); environment(mu) <- environment()
  f0 <- as.formula(sprintf('sd(id, level = "%s", coef = "(Intercept)") ~ z0', lev))
  f1 <- as.formula(sprintf('sd(id, level = "%s", coef = "x") ~ z1', lev))
  try1(paste(k,"labelled q2 coefSD REML"), drmTMB(bf(mu, sigma ~ 1, f0, f1), family=gaussian(), data=d, REML=TRUE))
  try1(paste(k,"labelled q2 coefSD ML"), drmTMB(bf(mu, sigma ~ 1, f0, f1), family=gaussian(), data=d, REML=FALSE))
  mu <- as.formula(sprintf("y ~ x + %s(1 + x | id, %s)", k, arg)); environment(mu) <- environment()
  try1(paste(k,"q2 coefSD, sigma ~ x REML"), drmTMB(bf(mu, sigma ~ x, f0, f1), family=gaussian(), data=d, REML=TRUE))
  try1(paste(k,"q2 coefSD, sigma ~ x ML"), drmTMB(bf(mu, sigma ~ x, f0, f1), family=gaussian(), data=d, REML=FALSE))
}

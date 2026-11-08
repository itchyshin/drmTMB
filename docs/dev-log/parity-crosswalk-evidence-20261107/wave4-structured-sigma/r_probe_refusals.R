.libPaths(c("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/lib", .libPaths())); suppressMessages(library(drmTMB)); library(ape)
set.seed(11); G <- 40; ne <- 12
ids <- sprintf("s%02d", 1:G)
tr <- rcoal(G, tip.label = ids); A <- vcv(tr, corr=TRUE)[ids, ids]
coords <- cbind(runif(G), runif(G)); rownames(coords) <- ids
d <- data.frame(id = factor(rep(ids, each = ne), levels = ids)); d$x <- rnorm(nrow(d))
gi <- as.integer(d$id); d$zc <- rnorm(G)[gi]
u <- as.numeric(t(chol(A)) %*% rnorm(G)); u2 <- as.numeric(t(chol(A)) %*% rnorm(G))
sg <- exp(-0.3 + 0.4 * u[gi] + 0.3*u2[gi]*d$x)
d$yg <- rgamma(nrow(d), shape = 1/sg^2, scale = exp(0.5+0.3*d$x)*sg^2)
d$yn <- rnbinom(nrow(d), size = 1/sg^2, mu = exp(1 + 0.3*d$x))
d$yd <- 0.2 + 0.5*d$x + sg*rnorm(nrow(d))

tf <- function(label, expr) { cat("\n=====", label, "\n"); tryCatch({ft <- suppressWarnings(expr); print(logLik(ft)); invisible(ft)}, error=function(e) cat("REFUSAL:", conditionMessage(e), "\n")) }
fa <- function(rhs) { f <- as.formula(rhs); environment(f) <- globalenv(); f }
run <- function(label, fam, mu, sg, sdf) { tf(label, { fm <- if (is.null(sdf)) bf(mu, sigma = sg) else bf(mu, sigma = sg, sdf); drmTMB(fm, family=fam, data=d) }) }
mu_d <- fa("yd ~ x"); 
s1 <- fa("~ 1 + phylo(1 | id, tree = tr)"); sd1 <- fa('sd(id, level="phylogenetic", dpar="sigma") ~ zc')
run("gauss phylo sigma(1) sd~zc", gaussian(), mu_d, s1, sd1)
s1 <- fa("~ 1 + animal(1 | id, A = A)"); sd1 <- fa('sd(id, level="animal", dpar="sigma") ~ zc')
run("gauss animal sigma(1) sd~zc", gaussian(), mu_d, s1, sd1)
for (nm in c("nb2","gamma")) { fam <- if (nm=="nb2") nbinom2() else Gamma(link="log"); y <- if (nm=="nb2") "yn" else "yg"
 mu <- fa(paste(y,"~ x"))
 for (p in c("phylo","animal","relmat","spatial")) {
  arg <- switch(p, phylo="tree = tr", animal="A = A", relmat="K = A", spatial="coords = coords")
  lev <- switch(p, phylo="phylogenetic", animal="animal", relmat="relmat", spatial="spatial")
  s2 <- fa(sprintf("~ 1 + %s(1 + x | id, %s)", p, arg)); s1 <- fa(sprintf("~ 1 + %s(1 | id, %s)", p, arg))
  run(paste(nm,p,"sigma 1+x|id no sd"), fam, mu, s2, NULL)
  run(paste(nm,p,"sigma 1+x|id sd int~zc"), fam, mu, s2, fa(sprintf('sd(id, level="%s", dpar="sigma", coef="(Intercept)") ~ zc', lev)))
  run(paste(nm,p,"sigma 1|id sd~zc"), fam, mu, s1, fa(sprintf('sd(id, level="%s", dpar="sigma") ~ zc', lev)))
 }
}

.libPaths(c("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/lib", .libPaths())); suppressMessages(library(drmTMB))
set.seed(1); G <- 30; m <- 12; n <- G*m
id <- factor(rep(sprintf("g%02d", 1:G), each = m)); gi <- as.integer(id)
h <- factor(sample(sprintf("h%02d", 1:25), n, TRUE))
x <- rnorm(n); w1 <- rnorm(G)[gi]; w2 <- rnorm(G)[gi]
hz <- rnorm(25)[as.integer(h)]
mu <- exp(0.3 + 0.2*x + rnorm(G, sd=.5)[gi] + rnorm(G, sd=.3)[gi]*x + rnorm(25, sd=.4)[as.integer(h)])
dg <- data.frame(y = rgamma(n, shape = 5, scale = mu/5), x, id, h, w1, w2, hz)
dn <- dg; dn$y <- rnbinom(n, size = 3, mu = mu)
K <- 0.3^abs(outer(1:25, 1:25, "-")); dimnames(K) <- list(levels(h), levels(h))
Kg <- 0.3^abs(outer(1:G, 1:G, "-")); dimnames(Kg) <- list(levels(id), levels(id))
try1 <- function(lab, expr) { r <- tryCatch({f <- expr; sprintf("OK conv=%d ll=%.4f", f$opt$convergence, as.numeric(logLik(f)))}, error = function(e) paste("ERROR:", conditionMessage(e))); cat(lab, "->", substr(r,1,250), "\n") }
ctl <- drm_control(se = FALSE)
for (fam in c("nb2","gamma")) {
  d <- if (fam=="nb2") dn else dg; F <- if (fam=="nb2") nbinom2() else Gamma(link="log")
  try1(paste(fam,"samegroup indep"), drmTMB(bf(y ~ x + (1|id) + (0+x|id), sigma ~ 1, sd(id, coef="(Intercept)") ~ w1, sd(id, coef="x") ~ w2), family=F, data=d, control=ctl))
  try1(paste(fam,"samegroup corr (1+x|id)"), drmTMB(bf(y ~ x + (1+x|id), sigma ~ 1, sd(id, coef="(Intercept)") ~ w1, sd(id, coef="x") ~ w2), family=F, data=d, control=ctl))
  try1(paste(fam,"crossed"), drmTMB(bf(y ~ x + (1|id) + (1|h), sigma ~ 1, sd(id) ~ w1, sd(h) ~ hz), family=F, data=d, control=ctl))
  try1(paste(fam,"ord+relmat"), drmTMB(bf(y ~ x + (1|id) + relmat(1|h, K=K), sigma ~ 1, sd(id) ~ w1, sd(h, level="relmat") ~ hz), family=F, data=d, control=ctl))
  try1(paste(fam,"ord+animal"), drmTMB(bf(y ~ x + (1|id) + animal(1|h, A=K), sigma ~ 1, sd(id) ~ w1, sd(h, level="animal") ~ hz), family=F, data=d, control=ctl))
  try1(paste(fam,"relmat q2"), drmTMB(bf(y ~ x + relmat(1+x|id, K=Kg), sigma ~ 1, sd(id, level="relmat", coef="(Intercept)") ~ w1, sd(id, level="relmat", coef="x") ~ w2), family=F, data=d, control=ctl))
  try1(paste(fam,"animal q2 labelled"), drmTMB(bf(y ~ x + animal(1+x|p|id, A=Kg), sigma ~ 1, sd(id, level="animal", coef="(Intercept)") ~ w1, sd(id, level="animal", coef="x") ~ w2), family=F, data=d, control=ctl))
  try1(paste(fam,"relmat q2 labelled"), drmTMB(bf(y ~ x + relmat(1+x|p|id, K=Kg), sigma ~ 1, sd(id, level="relmat", coef="(Intercept)") ~ w1, sd(id, level="relmat", coef="x") ~ w2), family=F, data=d, control=ctl))
}

SP <- "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad"
.libPaths(c(file.path(SP, "agree-poisson-q2/lib"), .libPaths())); suppressMessages(library(drmTMB))
cat("drmTMB", as.character(packageVersion("drmTMB")), "\n")
set.seed(1)
G <- 40; n <- 800
id <- factor(sample(rep_len(sprintf("g%02d", 1:G), n)))
wl <- rnorm(G); names(wl) <- levels(id)
a <- rnorm(G, sd = exp(-0.5 + 0.3 * wl)); b <- rnorm(G, sd = exp(-1 + 0.3 * wl))
x <- rnorm(n)
y <- 0.2 + 0.5 * x + a[id] + exp(-0.7 + b[id]) * rnorm(n)
d <- data.frame(y, x, id, w = wl[as.character(id)], z = wl[as.character(id)])
try_fit <- function(lab, expr) {
  r <- tryCatch({ f <- eval(expr); sprintf("OK ll=%.6f conv=%d", as.numeric(logLik(f)), f$opt$convergence) },
                error = function(e) paste("ERROR:", conditionMessage(e)))
  cat("##", lab, ":", r, "\n")
}
try_fit("gauss same-group joint SD", quote(drmTMB(bf(y ~ x + (1 | id), sigma ~ 1 + (1 | id), sd(id) ~ w, sd(id, dpar = "sigma") ~ z), family = gaussian(), data = d)))
try_fit("gauss same-group joint no SD", quote(drmTMB(bf(y ~ x + (1 | id), sigma ~ 1 + (1 | id)), family = gaussian(), data = d)))
try_fit("gauss same-group correlated (1|p|id)", quote(drmTMB(bf(y ~ x + (1 | p | id), sigma ~ 1 + (1 | p | id)), family = gaussian(), data = d)))
try_fit("gauss same-group correlated + SD", quote(drmTMB(bf(y ~ x + (1 | p | id), sigma ~ 1 + (1 | p | id), sd(id) ~ w, sd(id, dpar = "sigma") ~ z), family = gaussian(), data = d)))
# structured sigma with SD formula: phylo / spatial
suppressMessages(library(ape))
set.seed(2); tr <- rtree(G, tip.label = levels(id)); tr <- compute.brlen(tr)
try_fit("gauss phylo sigma + SD", quote(drmTMB(bf(y ~ x, sigma ~ 1 + phylo(1 | id, tree = tr), sd(id, level = "phylo", dpar = "sigma") ~ z), family = gaussian(), data = d)))
try_fit("gauss phylo sigma no SD", quote(drmTMB(bf(y ~ x, sigma ~ 1 + phylo(1 | id, tree = tr)), family = gaussian(), data = d)))
co <- cbind(runif(G), runif(G)); rownames(co) <- levels(id); d$cx <- co[as.character(d$id), 1]; d$cy <- co[as.character(d$id), 2]
try_fit("gauss spatial sigma + SD", quote(drmTMB(bf(y ~ x, sigma ~ 1 + spatial(1 | id, coords = co), sd(id, level = "spatial", dpar = "sigma") ~ z), family = gaussian(), data = d)))
try_fit("gauss spatial sigma no SD", quote(drmTMB(bf(y ~ x, sigma ~ 1 + spatial(1 | id, coords = co)), family = gaussian(), data = d)))
# NB2 / Gamma joint different group
d$yc <- rnbinom(n, size = 3, mu = exp(1 + 0.3 * x + a[id])); d$yg <- rgamma(n, shape = 4, scale = exp(0.3 + 0.3 * x + a[id]) / 4)
g2 <- factor(sample(rep_len(sprintf("s%02d", 1:30), n))); d$g <- g2; zl <- rnorm(30); names(zl) <- levels(g2); d$zg <- zl[as.character(g2)]
try_fit("nb2 joint diff group", quote(drmTMB(bf(yc ~ x + (1 | id), sigma ~ 1 + (1 | g), sd(id) ~ w, sd(g, dpar = "sigma") ~ zg), family = nbinom2(), data = d)))
try_fit("nb2 joint same group", quote(drmTMB(bf(yc ~ x + (1 | id), sigma ~ 1 + (1 | id), sd(id) ~ w, sd(id, dpar = "sigma") ~ z), family = nbinom2(), data = d)))
try_fit("gamma joint diff group", quote(drmTMB(bf(yg ~ x + (1 | id), sigma ~ 1 + (1 | g), sd(id) ~ w, sd(g, dpar = "sigma") ~ zg), family = Gamma(link = "log"), data = d)))
try_fit("gamma joint same group", quote(drmTMB(bf(yg ~ x + (1 | id), sigma ~ 1 + (1 | id), sd(id) ~ w, sd(id, dpar = "sigma") ~ z), family = Gamma(link = "log"), data = d)))
try_fit("nb2 joint no SD", quote(drmTMB(bf(yc ~ x + (1 | id), sigma ~ 1 + (1 | g)), family = nbinom2(), data = d)))
try_fit("gamma joint no SD", quote(drmTMB(bf(yg ~ x + (1 | id), sigma ~ 1 + (1 | g)), family = Gamma(link = "log"), data = d)))
try_fit("nb2 joint sigma slope", quote(drmTMB(bf(yc ~ x + (1 | id), sigma ~ 1 + (0 + x | g), sd(id) ~ w, sd(g, dpar = "sigma", coef = "x") ~ zg), family = nbinom2(), data = d)))

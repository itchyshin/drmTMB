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
suppressMessages(library(ape))
set.seed(2); tr <- rtree(G, tip.label = levels(id)); tr <- compute.brlen(tr)
try_fit("gauss phylo sigma + SD", quote(drmTMB(bf(y ~ x, sigma ~ 1 + phylo(1 | id, tree = tr), sd(id, level = "phylogenetic", dpar = "sigma") ~ z), family = gaussian(), data = d)))
co <- cbind(runif(G), runif(G)); rownames(co) <- levels(id)
f <- drmTMB(bf(y ~ x, sigma ~ 1 + spatial(1 | id, coords = co), sd(id, level = "spatial", dpar = "sigma") ~ z), family = gaussian(), data = d)
print(f$opt$par); print(summary(f))

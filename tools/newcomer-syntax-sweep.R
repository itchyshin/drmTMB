# Newcomer-syntax sweep: what happens when a user arrives from lme4 / glmmTMB /
# brms / gamlss and types what they already know?
# Classifies each attempt as FITS, CLEAN ERROR (names the issue + a way forward),
# or RAW ERROR (internal R error that helps nobody).
suppressMessages(library(drmTMB))
set.seed(7)

M <- 20; k <- 6
g1 <- factor(rep(seq_len(M), each = k))
g2 <- factor(rep(rep(1:2, each = k / 2), M))
x  <- rnorm(M * k); z <- rnorm(M * k); off <- runif(M * k, 0.5, 2)
b  <- rnorm(M, 0, 0.7)[as.integer(g1)]
y  <- 1 + b + 0.5 * x + rnorm(M * k, 0, 1)
cnt <- rpois(M * k, exp(0.5 + 0.3 * x))
succ <- rbinom(M * k, 10, plogis(0.2 + 0.4 * x)); fail <- 10 - succ
d <- data.frame(y, x, z, g1, g2, off, cnt, succ, fail)

run <- function(label, source_pkg, expr) {
  r <- tryCatch(list(ok = TRUE, v = force(expr)),
                error = function(e) list(ok = FALSE, msg = conditionMessage(e)))
  if (r$ok) {
    cat(sprintf("\n[FITS ]  %-34s (%s)\n", label, source_pkg))
  } else {
    msg <- gsub("[\r\n]+", " ", r$msg)
    msg <- gsub("\\s+", " ", msg)
    cat(sprintf("\n[ERROR]  %-34s (%s)\n         %s\n", label, source_pkg,
                substr(msg, 1, 300)))
  }
  invisible(NULL)
}

cat("=== A. random-effects grammar ===\n")
run("(1 | g)", "lme4", drmTMB(bf(y ~ x + (1 | g1)), gaussian(), d))
run("(1 + x | g)  correlated", "lme4", drmTMB(bf(y ~ x + (1 + x | g1)), gaussian(), d))
run("(1|g) + (0+x|g)  two-term", "drmTMB doc", drmTMB(bf(y ~ x + (1 | g1) + (0 + x | g1)), gaussian(), d))
run("(1 + x || g)  double bar", "lme4/brms", drmTMB(bf(y ~ x + (1 + x || g1)), gaussian(), d))
run("(x | g)  implicit intercept", "lme4", drmTMB(bf(y ~ x + (x | g1)), gaussian(), d))
run("(1 | g1/g2)  nested", "lme4", drmTMB(bf(y ~ x + (1 | g1/g2)), gaussian(), d))
run("(1 | g1:g2)  interaction", "lme4", drmTMB(bf(y ~ x + (1 | g1:g2)), gaussian(), d))
run("(0 + x | g)  slope only", "lme4", drmTMB(bf(y ~ x + (0 + x | g1)), gaussian(), d))

cat("\n=== B. cross-package argument names ===\n")
run("dispformula =", "glmmTMB", drmTMB(y ~ x, family = gaussian(), data = d, dispformula = ~x))
run("ziformula =", "glmmTMB", drmTMB(cnt ~ x, family = poisson(), data = d, ziformula = ~1))
run("sigma.formula in bf()", "gamlss", drmTMB(bf(y ~ x, sigma.formula = ~x), gaussian(), d))
run("bare formula, no bf()", "lme4/glmmTMB", drmTMB(y ~ x + (1 | g1), family = gaussian(), data = d))

cat("\n=== C. common formula idioms ===\n")
run("poly(x, 2)", "base", drmTMB(bf(y ~ poly(x, 2)), gaussian(), d))
run("offset(off)", "base/glm", drmTMB(bf(cnt ~ x + offset(log(off))), poisson(), d))
run("cbind(succ, fail)", "glm", drmTMB(bf(cbind(succ, fail) ~ x), binomial(), d))
run("s(x)  smooth", "mgcv/gamlss", drmTMB(bf(y ~ s(x)), gaussian(), d))
run("sigma ~ x  (brms style)", "brms", drmTMB(bf(y ~ x, sigma ~ x), gaussian(), d))

cat("\n=== done ===\n")

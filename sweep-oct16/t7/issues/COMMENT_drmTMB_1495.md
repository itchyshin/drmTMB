# Comment intended for https://github.com/itchyshin/drmTMB/issues/1495

GitHub write from this cloud task returned 403 (PAT/integration cannot `addComment`). Paste this if posting by hand. Refs #1495. Do not re-file.

t7 live-fit check at drmTMB `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a` (R 4.6.1, TMB 1.9.25). #1501 is still open; this pin does not carry that fix.

**Expected.** User-set contrasts on an ordered factor (`contr.treatment`, `contr.sum`, `contr.helmert`, `contr.poly`) are used in the design, so `coef()` matches `lm()` / `glm()` with the same coding. Fitted values stay invariant across those four encodings to 1e-8.

**Actual.** Fitted values are invariant (max |fitted_i − fitted_j| = 0) and match `lm`/`glm` fitted values (Gaussian 8e-15, Poisson 1.3e-10). Coefficients match `lm`/`glm` **only** for `contr.poly`. `drm_droplevels_fixed_predictors()` still calls `droplevels()`, which drops the `contrasts` attribute. On an **ordered** factor the rebuilt column then gets R's default `contr.poly` (`g.L`/`g.Q`/`g.C`), not treatment coding. Unordered `contr.sum` still becomes treatment coding (`gb`/`gc` vs `lm` `g1`/`g2`), as in the original report.

`engine = "julia"` refuses all four ordered-factor encodings before Julia starts (`g: an ordered factor (R codes it with contr.poly)`), including requested `contr.treatment`, because droplevels restored poly first.

**Source.** Simulated. Campaign seed family `20261016700+` overflows R's 32-bit `set.seed()` integer. Table seed: `set.seed(202610217L)` (`202610167L + 50L`). Package drmTMB 0.7.1 at the SHA above.

**Preparation.**
```r
set.seed(202610217L)
n <- 160L
g <- ordered(rep(c("a", "b", "c", "d"), each = n / 4L))
x <- rnorm(n)
cell <- c(a = 0, b = 0.45, c = -0.30, d = 0.70)
yg <- 1.1 + 0.55 * x + cell[as.character(g)] + rnorm(n, 0, 0.35)
yp <- rpois(n, lambda = exp(0.15 + 0.35 * x + cell[as.character(g)]))
d0 <- data.frame(yg = yg, yp = yp, x = x, g = g)
```

**Minimal repro.**
```r
library(drmTMB)
d <- d0; d$y <- d$yg
run <- function(cm) {
  contrasts(d$g) <- cm
  list(lm = names(coef(lm(y ~ x + g, d))),
       drm = names(coef(drmTMB(bf(y ~ x + g, sigma ~ 1), family = gaussian(), data = d), "mu")))
}
run(contr.treatment(4)); run(contr.sum(4)); run(contr.helmert(4)); run(contr.poly(4))
```

Prepared table: `sweep-oct16/t7/data_contrasts.dput` (160 rows, 7.5 KB).

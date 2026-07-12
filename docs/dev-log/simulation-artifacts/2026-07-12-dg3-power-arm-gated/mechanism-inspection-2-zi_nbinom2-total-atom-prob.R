# Follow-up (Curie): zi_nbinom2's raw zi-intercept comparison showed a bigger
# gap (0.35) than the other 3 cells. Check whether the TOTAL atom probability
# P(y=0) -- which is what a quantile-residual diagnostic actually sees, not
# the raw zi parameter in isolation -- is what's actually being matched
# (since P(y=0) = zi + (1-zi)*dnbinom(0|mu), so a correctly-fit mu ~ x can
# trade off against a mismatched constant zi).
if (!identical(Sys.getenv("NOT_CRAN"), "true")) stop("Set NOT_CRAN=true")
suppressMessages(devtools::load_all(".", quiet = TRUE))
source("inst/dg3-power-arm/harness.R")
source("inst/dg3-power-arm/families.R")

n <- 1000L
seed <- 1L
ms <- dg3_spec_zi_nbinom2$mis_specs[[2]]
dat <- ms$dgp(seed, n)
ft <- ms$fit_true(dat)
fw <- ms$fit_wrong(dat)

mu_t <- exp(coef(ft, dpar = "mu")[["(Intercept)"]] + coef(ft, dpar = "mu")[["x"]] * dat$x)
sig_t <- exp(coef(ft, dpar = "sigma")[["(Intercept)"]])
zi_t <- plogis(coef(ft, dpar = "zi")[["(Intercept)"]] + coef(ft, dpar = "zi")[["x"]] * dat$x)
p0_fit_true <- mean(zi_t + (1 - zi_t) * dnbinom(0, size = 1 / sig_t^2, mu = mu_t))

mu_w <- exp(coef(fw, dpar = "mu")[["(Intercept)"]] + coef(fw, dpar = "mu")[["x"]] * dat$x)
sig_w <- exp(coef(fw, dpar = "sigma")[["(Intercept)"]])
zi_w <- plogis(coef(fw, dpar = "zi")[["(Intercept)"]])
p0_fit_wrong <- mean(zi_w + (1 - zi_w) * dnbinom(0, size = 1 / sig_w^2, mu = mu_w))

mu_true <- exp(0.4 + 0.25 * dat$x)
sig_true <- 0.6
zi_true <- plogis(-0.5 + 1.2 * dat$x)
p0_true_dgp <- mean(zi_true + (1 - zi_true) * dnbinom(0, size = 1 / sig_true^2, mu = mu_true))
p0_observed <- mean(dat$y == 0)

cat(sprintf("mu coefs   fit_true: %s\n", paste(sprintf("%.4f", coef(ft, dpar = "mu")), collapse = ", ")))
cat(sprintf("mu coefs   fit_wrong: %s\n", paste(sprintf("%.4f", coef(fw, dpar = "mu")), collapse = ", ")))
cat(sprintf("sigma      fit_true: %.4f   fit_wrong: %.4f\n", sig_t, sig_w))
cat(sprintf("\nmean total P(y=0) implied by fit_true:  %.4f\n", p0_fit_true))
cat(sprintf("mean total P(y=0) implied by fit_wrong: %.4f\n", p0_fit_wrong))
cat(sprintf("mean total P(y=0) under TRUE DGP:        %.4f\n", p0_true_dgp))
cat(sprintf("observed proportion y==0 in this sample: %.4f\n", p0_observed))
cat(sprintf("|fit_wrong - TRUE DGP| = %.4f\n", abs(p0_fit_wrong - p0_true_dgp)))

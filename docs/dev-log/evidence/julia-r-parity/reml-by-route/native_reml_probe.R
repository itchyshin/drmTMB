## Native TMB (engine="tmb") REML probe for the A9f route table.
## No Julia needed. Reports FITS (with logLik) or REFUSES (with the quoted message)
## for each route, so the table's "native TMB" column is measured in THIS run.
suppressMessages(devtools::load_all("/Users/z3437171/local-scratch/parity-joint/wt-a9f-reml-table", quiet = TRUE))
suppressMessages(library(ape))

probe <- function(label, expr) {
  res <- tryCatch(
    {
      fit <- force(expr)
      list(label = label, outcome = "FITS", loglik = as.numeric(stats::logLik(fit)), message = NA_character_)
    },
    error = function(e) list(label = label, outcome = "REFUSES", loglik = NA_real_, message = conditionMessage(e))
  )
  cat(sprintf("== %s ==\n outcome=%s loglik=%s\n message=%s\n\n",
              res$label, res$outcome, res$loglik %||% "NA",
              gsub("\n", " | ", res$message %||% "")))
  res
}
`%||%` <- function(a, b) if (is.null(a) || (length(a) == 1 && is.na(a))) b else a

set.seed(1)
n <- 60
x <- rnorm(n)
y <- 0.5 + 0.8 * x + rnorm(n, sd = 0.6)
g <- factor(rep(1:12, length.out = n))
d_base <- data.frame(y = y, x = x, g = g)

## 1. base_gaussian_location_scale: fixed-effect only, no RE, no phylo.
r1 <- probe("base_gaussian_location_scale (fixed-effect Gaussian, REML=TRUE)",
  drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = d_base, REML = TRUE, engine = "tmb")
)

## 2. biv_gaussian_residual: fixed-effect bivariate, rho12, no RE, no structure.
y1 <- 0.4 + 0.6 * x + rnorm(n, sd = 0.5)
y2 <- -0.2 + 0.3 * x + 0.4 * y1 + rnorm(n, sd = 0.5)
d_biv <- data.frame(y1 = y1, y2 = y2, x = x)
r2 <- probe("biv_gaussian_residual (fixed-effect bivariate, REML=TRUE)",
  drmTMB(bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
         family = biv_gaussian(), data = d_biv, REML = TRUE, engine = "tmb")
)

## 3. Ordinary random effects (A5's three census shapes), native TMB side.
r3 <- probe("gaussian_random_intercept (1|g), REML=TRUE",
  drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(), data = d_base, REML = TRUE, engine = "tmb")
)
r4 <- probe("gaussian_random_slope (1+x|g), REML=TRUE",
  drmTMB(bf(y ~ x + (1 + x | g), sigma ~ 1), family = gaussian(), data = d_base, REML = TRUE, engine = "tmb")
)
r5 <- probe("gaussian_sigma_random_intercept sigma~(1|g), REML=TRUE",
  drmTMB(bf(y ~ x, sigma ~ (1 | g)), family = gaussian(), data = d_base, REML = TRUE, engine = "tmb")
)

## 4. Phylo mean-only Gaussian (gaussian_phylo_mean / gaussian_response_mask).
tree <- ape::rcoal(20); tree$tip.label <- paste0("sp_", seq_len(20))
Aphy <- ape::vcv(tree, corr = TRUE)
sp <- factor(tree$tip.label, levels = tree$tip.label)
u <- as.vector(t(chol(Aphy)) %*% rnorm(20)) * 0.5
xp <- rnorm(20)
yp <- 0.3 + 0.5 * xp + u + rnorm(20, sd = 0.4)
d_phylo <- data.frame(y = yp, x = xp, species = sp)
r6 <- probe("gaussian_phylo_mean (mean-only phylo, sigma~1), REML=TRUE",
  drmTMB(bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
         family = gaussian(), data = d_phylo, REML = TRUE, engine = "tmb")
)

## gaussian_response_mask: same model, response="include" with one NA response row.
d_phylo_mask <- d_phylo
d_phylo_mask$y[3] <- NA
r7 <- probe("gaussian_response_mask (phylo mean, response='include'), REML=TRUE",
  drmTMB(bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
         family = gaussian(), data = d_phylo_mask, REML = TRUE, engine = "tmb",
         missing = miss_control(response = "include"))
)

## 5. general_covariance_structured (relmat), Gaussian mean-only, sigma~1.
set.seed(2)
K <- diag(12) * 0.7 + 0.3
rownames(K) <- colnames(K) <- levels(g)
r8 <- probe("general_covariance_structured Gaussian relmat(1|g,K=K), sigma~1, REML=TRUE",
  drmTMB(bf(y ~ x + relmat(1 | g, K = K), sigma ~ 1),
         family = gaussian(), data = d_base, REML = TRUE, engine = "tmb")
)

## 6. phylo_count_large_p / phylo_gamma_beta_binomial: non-Gaussian + phylo, one representative
## (poisson) since the refusal branch (model_type not in {gaussian,binomial}) is shared code.
yc <- rpois(20, exp(0.3 + 0.2 * xp))
d_phylo_c <- data.frame(y = yc, x = xp, species = sp)
r9 <- probe("phylo_count_large_p: poisson + phylo(1|species), REML=TRUE",
  drmTMB(bf(y ~ x + phylo(1 | species, tree = tree)),
         family = poisson(), data = d_phylo_c, REML = TRUE, engine = "tmb")
)

## 7. plain_binomial_nonphylo: fixed-effect only, cbind trials, no RE.
succ <- rbinom(n, 10, plogis(0.2 + 0.3 * x)); fail <- 10 - succ
d_bin <- data.frame(succ = succ, fail = fail, x = x)
r10 <- probe("plain_binomial_nonphylo (fixed-effect only cbind trials), REML=TRUE",
  drmTMB(bf(cbind(succ, fail) ~ x), family = stats::binomial(), data = d_bin, REML = TRUE, engine = "tmb")
)

## 8. cross_family_latent: c(gaussian(), poisson()).
d_xfam <- data.frame(y1g = y1, y2c = rpois(n, exp(0.2 + 0.1 * x)), x = x)
r11 <- probe("cross_family_latent c(gaussian(),poisson()), REML=TRUE",
  drmTMB(bf(mu1 = y1g ~ x, mu2 = y2c ~ x), family = c(gaussian(), poisson()),
         data = d_xfam, REML = TRUE, engine = "tmb")
)

## 9. A3 fixed-effect-only non-Gaussian families (fe_student etc.), one representative (fe_gamma)
## since the refusal branch is the shared model_type check.
yg <- rgamma(n, shape = 2, rate = 2 / exp(0.3 + 0.1 * x))
d_gamma <- data.frame(y = yg, x = x)
r12 <- probe("fe_gamma (fixed-effect only Gamma), REML=TRUE",
  drmTMB(bf(y ~ x), family = Gamma(link = "log"), data = d_gamma, REML = TRUE, engine = "tmb")
)

## 10. fe_poisson native (fixed-effect only, zero RE) -- needed to interpret the bridge edge case.
ypo <- rpois(n, exp(0.2 + 0.1 * x))
d_pois <- data.frame(y = ypo, x = x)
r13 <- probe("fe_poisson (fixed-effect only Poisson, zero RE), REML=TRUE",
  drmTMB(bf(y ~ x), family = poisson(), data = d_pois, REML = TRUE, engine = "tmb")
)

cat("ALL NATIVE PROBES DONE\n")

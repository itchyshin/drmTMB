# Standalone synthetic example of two independent relatedness fields whose
# coefficient SDs vary by group. Run from the drmTMB worktree root.
set.seed(2026102819L)
ids <- sprintf("group%02d", seq_len(24L))
variance <- seq(0.8, 1.3, length.out = length(ids))
K_full <- 0.25^abs(outer(seq_along(ids), seq_along(ids), "-")) *
  outer(sqrt(variance), sqrt(variance))
dimnames(K_full) <- list(ids, ids)
z0 <- stats::setNames(rep(c(-1, 1), length.out = length(ids)), ids)
z1 <- stats::setNames(rep(c(-1, 1), each = length(ids) / 2L), ids)
u0 <- drop(t(chol(K_full)) %*% stats::rnorm(length(ids)))
u1 <- drop(t(chol(K_full)) %*% stats::rnorm(length(ids)))
b0 <- exp(log(0.8) + 0.6 * z0) * u0
b1 <- exp(log(0.6) - 0.5 * z1) * u1
ii <- rep(seq_along(ids), each = 12L)
x <- rep(seq(-1.2, 1.2, length.out = 12L), length(ids))
eta <- 0.2 + 0.3 * x + b0[ii] + x * b1[ii]
dat <- data.frame(
  y = stats::rbinom(length(ii), 1L, stats::plogis(eta)),
  x = x, id = factor(ids[ii], levels = rev(ids)),
  z0 = unname(z0[ii]), z1 = unname(z1[ii])
)
order <- c(seq(2L, length(ids), 2L), seq(1L, length(ids), 2L))
K <- K_full[order, order]

pkgload::load_all(".", quiet = TRUE)
fit <- drmTMB::drmTMB(
  drmTMB::bf(
    y ~ x + drmTMB::relmat(1 + x | id, K = K),
    drmTMB::sd(id, level = "relmat", coef = "(Intercept)") ~ z0,
    drmTMB::sd(id, level = "relmat", coef = "x") ~ z1
  ),
  family = stats::binomial(), data = dat,
  control = drmTMB::drm_control(se = FALSE)
)
stopifnot(fit$opt$convergence == 0L)
print(stats::coef(fit, "mu"))
print(stats::coef(fit, 'sd_relmat(id, dpar = "mu", coef = "(Intercept)")'))
print(stats::coef(fit, 'sd_relmat(id, dpar = "mu", coef = "x")'))
print(head(stats::predict(fit, type = "link", re.form = NULL)))

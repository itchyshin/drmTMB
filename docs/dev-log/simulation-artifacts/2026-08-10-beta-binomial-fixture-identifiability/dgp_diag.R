# Gate-zero DGP diagnostics for the beta-binomial mi() fixture.
# No package load, no TMB fit: these are properties of the DGP alone.
# Adjudicates Ada's proposal (permute+shrink u) against Fisher's (latent Beta).

n <- 86
z <- seq(-1.8, 1.8, length.out = n)
trials <- rep(8:16, length.out = n)

# --- candidate constructions -------------------------------------------------
make_current <- function() {
  p <- stats::plogis(-0.25 + 0.85 * z + 0.10 * sin(seq_len(n) / 5))
  stats::qbinom(ppoints(n), size = trials, prob = p)
}
make_ada <- function() {
  p <- stats::plogis(-0.25 + 0.85 * z + 0.10 * sin(seq_len(n) / 5))
  u <- ppoints(n)[order(order(sin(seq_len(n))))]
  u <- 0.05 + 0.90 * u
  stats::qbinom(u, size = trials, prob = p)
}
make_fisher <- function(sig_true = 0.35) {
  phi <- 1 / sig_true^2
  mu_i <- stats::plogis(-0.25 + 0.85 * z)
  v_lat <- ppoints(n)[order(order(cos(2 * seq_len(n))))]
  u_cnt <- ppoints(n)[order(order(sin(seq_len(n))))]
  p_lat <- stats::qbeta(v_lat, mu_i * phi, (1 - mu_i) * phi)
  stats::qbinom(u_cnt, size = trials, prob = p_lat)
}

# --- beta-binomial profile over sigma ---------------------------------------
bb_ll <- function(s, nt, mu, sigma) {
  phi <- 1 / sigma^2
  a <- mu * phi; b <- (1 - mu) * phi
  sum(lchoose(nt, s) + lbeta(s + a, nt - s + b) - lbeta(a, b))
}
prof_at <- function(s, nt, sigma) {
  nll <- function(par) {
    mu <- stats::plogis(par[1] + par[2] * z)
    mu <- pmin(pmax(mu, 1e-10), 1 - 1e-10)
    v <- -bb_ll(s, nt, mu, sigma)
    if (!is.finite(v)) 1e10 else v
  }
  stats::optim(c(-0.25, 0.85), nll, method = "BFGS",
               control = list(maxit = 500, reltol = 1e-12))$value
}

grid <- c(1e-3, 1e-2, 0.05, 0.10, 0.20, 0.35, 0.50)

report <- function(label, s) {
  stopifnot(all(s <= trials), all(s >= 0))          # success <= trials invariant
  cover <- s / trials
  fit <- suppressWarnings(stats::glm(cbind(s, trials - s) ~ z, family = binomial()))
  disp <- sum(residuals(fit, type = "pearson")^2) / fit$df.residual
  r2 <- summary(stats::lm(cover ~ z))$r.squared
  vif <- 1 / (1 - r2)
  pr <- vapply(grid, function(g) prof_at(s, trials, g), numeric(1))
  pr <- pr - min(pr)
  cat(sprintf("\n== %s ==\n", label))
  cat(sprintf("  success<=trials      : TRUE (checked)\n"))
  cat(sprintf("  Pearson dispersion   : %.3f      [gate > 1.5]\n", disp))
  cat(sprintf("  cor(cover, z)        : %.4f\n", stats::cor(cover, z)))
  cat(sprintf("  VIF(cover | z)       : %.2f      [gate < 10]\n", vif))
  cat(sprintf("  exact 0s / exact 1s  : %d / %d\n", sum(cover == 0), sum(cover == 1)))
  cat(sprintf("  argmin sigma_mi      : %s\n", format(grid[which.min(pr)])))
  cat(sprintf("  BOUNDARY prof dev    : %.3f      [gate > 1.92]\n", pr[1]))
  cat("  profile (nll-min) over sigma grid:\n")
  cat(sprintf("    %-8s %s\n", "sigma", paste(sprintf("%8s", format(grid)), collapse = "")))
  cat(sprintf("    %-8s %s\n", "dev",   paste(sprintf("%8.2f", pr), collapse = "")))
  invisible(NULL)
}

report("CURRENT (on main)", make_current())
report("ADA proposal (permute+shrink u)", make_ada())
report("FISHER proposal (latent Beta, sig=0.35)", make_fisher(0.35))
report("FISHER fallback (latent Beta, sig=0.50)", make_fisher(0.50))

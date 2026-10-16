# t6 SPEC P6 for tweedie_fixed and tweedie_ri (extra coverage, tweedie package now installed).
# drmTMB ca3ddefa5ea11bbfd3b765615dfbb89305d2485a; tweedie 3.1.0; data sweep-oct16/t6/data/tweedie_{fixed,ri}.csv,
# nd_main.csv (cells.csv seeds 20261016624 / 20261016625; R seeds 261016624 / 261016625).
# Reference: tweedie::qtweedie(p, mu, phi = sigma^2, power = nu), called ONE ELEMENT AT A TIME at parameters built by
# hand from the coefficients (mu = exp(X b_mu [+ b-hat[g] on fitted rows]), sigma = exp(b0 + b1 x), nu = 1 + plogis(b_nu)).
# Quantile convention at the zero atom: Q(p) = inf{y >= 0 : F(y) >= p}, so Q(p) = 0 when p <= P(Y = 0).
suppressPackageStartupMessages({ library(drmTMB); library(tweedie) })
dd <- "/home/user/drmTMB/sweep-oct16/t6/data"
nd <- read.csv(file.path(dd, "nd_main.csv"))
probs <- c(0.025, 0.5, 0.975)
for (re in c("fixed", "ri")) {
  d <- read.csv(file.path(dd, sprintf("tweedie_%s.csv", re)))
  f_mu <- if (re == "ri") y ~ x + f + (1 | g) else y ~ x + f
  fit <- drmTMB(bf(f_mu, sigma ~ x, nu ~ 1), family = tweedie(), data = d)
  cf <- fit$coefficients
  hand <- function(D, insample) {
    X <- cbind(1, D$x, D$f == "b", D$f == "c")
    eta <- drop(X %*% cf$mu[c("(Intercept)", "x", "fb", "fc")])
    if (insample && re == "ri") eta <- eta + fit$random_effects$mu$values[paste0("(1 | g):", D$g)]
    list(mu = exp(eta), sigma = exp(cf$sigma[[1]] + cf$sigma[[2]] * D$x), nu = 1 + plogis(cf$nu[[1]]))
  }
  for (where in c("insample", "nd_main")) {
    D <- if (where == "insample") d else nd
    nd_arg <- if (where == "insample") NULL else nd
    Q <- predict(fit, newdata = nd_arg, type = "quantile", prob = probs)
    h <- hand(D, where == "insample")
    par_gap <- max(abs(predict(fit, newdata = nd_arg, dpar = "mu") - h$mu) / h$mu,
                   abs(predict(fit, newdata = nd_arg, dpar = "sigma") - h$sigma) / h$sigma,
                   abs(predict(fit, newdata = nd_arg, dpar = "nu") - h$nu))
    ref <- sapply(probs, function(p) vapply(seq_len(nrow(D)), function(i)
      qtweedie(p, mu = h$mu[i], phi = h$sigma[i]^2, power = h$nu), numeric(1)))
    p0 <- vapply(seq_len(nrow(D)), function(i) dtweedie(0, mu = h$mu[i], phi = h$sigma[i]^2, power = h$nu), numeric(1))
    atom <- outer(p0, probs, ">=")                      # Q should be exactly 0 here
    Fq <- sapply(seq_along(probs), function(j) vapply(seq_len(nrow(D)), function(i)
      ptweedie(Q[i, j], mu = h$mu[i], phi = h$sigma[i]^2, power = h$nu), numeric(1)))
    cat(sprintf("tweedie_%-5s %-8s nu=%.4f | max rel param gap %.2e | max|Q - qtweedie| = %.3e (rel %.3e) -> %s | atom cells %d, max Q there %.1e, Q==0 but p>P0: %d | max|F(Q)-p| off-atom %.2e\n",
      re, where, h$nu, par_gap, max(abs(Q - ref)), max(abs(Q - ref) / pmax(abs(ref), 1)),
      if (max(abs(Q - ref)) <= 1e-8) "PASS" else "FAIL", sum(atom), if (any(atom)) max(Q[atom]) else NA,
      sum(Q == 0 & !atom), max(abs(Fq - matrix(probs, nrow(D), 3, byrow = TRUE))[!atom])))
  }
}

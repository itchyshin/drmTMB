sd_regression_generate <- function(sc) {
  set.seed(as.integer(sc$seed))
  groups <- as.integer(sc$groups); repeats <- as.integer(sc$repeats)
  group <- rep(seq_len(groups), each = repeats)
  w_group <- seq(-1, 1, length.out = groups)
  w <- w_group[group]
  x <- rnorm(length(group)); u <- rnorm(groups)
  sd_group <- exp(sc$alpha0 + sc$a * w_group)
  eta <- sc$beta0 + sc$beta1 * x + sd_group[group] * u[group]
  y <- rbinom(length(group), 1L, plogis(eta))
  list(data = data.frame(y, failure = 1L - y, x, w, id = factor(group)),
       w_group = w_group, sd_group = sd_group, group = group, u = u, eta = eta)
}

sd_regression_generator_self_test <- function() {
  w_group <- seq(-1, 1, length.out = 160L)
  for (a in c(-0.5, 0, 0.5)) {
    sc <- data.frame(seed=2026101703L, a=a, groups=160L, repeats=16L,
                     alpha0=log(0.8), beta0=-0.3, beta1=0.6)
    generated <- sd_regression_generate(sc)
    observed <- generated$sd_group
    expected <- exp(log(0.8) + a * seq(-1, 1, length.out = 160L))
    legacy_indexing <- exp(log(0.8) + a * generated$data$w[generated$group])
    if (a != 0) stopifnot(max(abs(legacy_indexing - expected[generated$group])) > 1e-4)
    stopifnot(length(observed) == 160L, identical(observed, expected),
              identical(generated$data$w, rep(w_group, each = 16L)),
              identical(generated$sd_group[generated$group],
                        exp(sc$alpha0 + sc$a * generated$data$w)),
              isTRUE(all.equal(generated$eta,
                sc$beta0 + sc$beta1 * generated$data$x +
                  generated$sd_group[generated$group] * generated$u[generated$group],
                tolerance=0)))
  }
  invisible(TRUE)
}

# Ordinary random-effect SD regression with missing responses kept in the
# data, miss_control(response = "include"), for NB2 (family nbinom2()) and
# Gamma(link = "log").
#
# Scope: one ordinary mu random intercept, (1 | id), or one independent random
# slope, (0 + x | id), with sd(id) ~ w and a fixed-effect sigma ~ 1. Missing
# responses are masked in the C++ likelihood (observed_y guard in the NB2 and
# Gamma branches), so the fit must equal the complete-case fit.
#
# The same slice found and fixed one real defect: the NB2 include branch built
# its start values without the sd() design, so the SD regression was fitted
# from a start vector of the wrong length. The "sd slope is used" checks below
# would see that as a log-likelihood that no longer matches the oracle.
#
# Tolerances, fixed before the first run:
#   * include vs complete-case log-likelihood: 1e-8 absolute;
#   * include vs complete-case coefficients and training-row predictions: 1e-6;
#   * dense Laplace oracle at the fitted parameters: 1e-4 absolute;
#   * constant-SD equivalence (sd ~ 1 vs plain random effect): 1e-6 absolute;
#   * emulated-bug and constant-SD sensitivity: oracle values differ by more
#     than 0.05 absolute.
# The oracle is a per-group scalar Laplace approximation written here, with no
# drmTMB code in it. It is evaluated at the fitted parameters, so it checks the
# likelihood surface, not the optimiser's maximum. No recovery, coverage,
# calibration or Julia parity claim is made. Structured providers (relmat,
# animal, phylo, spatial) stay refused under include and are pinned below; the
# non-unit-diagonal K and shuffled-level requirement therefore applies to the
# refusal fixtures only. Group levels and rows are shuffled in every fixture.

mg_log_density <- function(family, y, eta, sigma) {
  if (identical(family, "nb2")) {
    stats::dnbinom(y, size = 1 / sigma^2, mu = exp(eta), log = TRUE)
  } else {
    stats::dgamma(y, shape = 1 / sigma^2, scale = exp(eta) * sigma^2,
                  log = TRUE)
  }
}

# Observed information of the log-density in eta (log link).
mg_info <- function(family, y, eta, sigma) {
  mu <- exp(eta)
  if (identical(family, "nb2")) {
    size <- 1 / sigma^2
    (y + size) * size * mu / (size + mu)^2
  } else {
    (1 / sigma^2) * y / mu
  }
}

mg_fixture <- function(family, term, seed, groups = 36L, repeats = 14L,
                       n_random_na = 40L) {
  set.seed(seed)
  levs <- sample(paste0("g", seq_len(groups)))
  w_group <- stats::setNames(
    sample(seq(-1, 1, length.out = groups)), levs
  )
  id <- rep(levs, each = repeats)
  x <- stats::rnorm(groups * repeats)
  tau <- exp(-0.4 + 0.9 * w_group)
  u <- stats::rnorm(groups, sd = tau)
  loading <- if (identical(term, "intercept")) 1 else x
  eta <- 0.3 + 0.2 * x + loading * u[match(id, levs)]
  y <- if (identical(family, "nb2")) {
    stats::rnbinom(length(eta), size = 1 / 0.4^2, mu = exp(eta))
  } else {
    stats::rgamma(length(eta), shape = 1 / 0.35^2, scale = exp(eta) * 0.35^2)
  }
  dat <- data.frame(y = y, x = x, w = as.numeric(w_group[id]),
                    id = factor(id, levels = levs))
  dat <- dat[sample(nrow(dat)), , drop = FALSE]
  rownames(dat) <- NULL
  dead <- levs[[1L]]  # one group has no observed response at all
  dat$y[dat$id == dead] <- NA_real_
  alive <- which(dat$id != dead)
  dat$y[sample(alive, n_random_na)] <- NA_real_
  list(data = dat, dead = dead, levs = levs, family = family, term = term)
}

mg_family <- function(family) {
  if (identical(family, "nb2")) nbinom2() else Gamma(link = "log")
}

mg_formula <- function(term, sd_rhs = "w") {
  mu <- if (identical(term, "intercept")) {
    y ~ x + (1 | id)
  } else {
    y ~ x + (0 + x | id)
  }
  sd_f <- stats::as.formula(paste0("sd(id) ~ ", sd_rhs))
  bf(mu, sigma ~ 1, sd_f)
}

mg_fit <- function(fx, data = fx$data, include = TRUE, sd_rhs = "w") {
  args <- list(
    mg_formula(fx$term, sd_rhs), family = mg_family(fx$family), data = data,
    control = drm_control(se = FALSE)
  )
  if (include) args$missing <- miss_control(response = "include")
  do.call(drmTMB, args)
}

# Dense, drmTMB-independent marginal log-likelihood by group: scalar Laplace.
mg_oracle <- function(fx, beta, log_sigma, alpha, y = fx$data$y,
                      drop_na = TRUE) {
  dat <- fx$data
  dat$y <- y
  if (drop_na) dat <- dat[!is.na(dat$y), , drop = FALSE]
  sigma <- exp(log_sigma)
  rows <- split(seq_len(nrow(dat)), dat$id)
  total <- 0
  for (g in fx$levs) {
    i <- rows[[g]]
    if (length(i) == 0L) next  # no observed rows: the prior integrates to one
    w <- dat$w[i[[1L]]]
    tau <- exp(alpha[[1L]] + alpha[[2L]] * w)
    eta0 <- beta[["(Intercept)"]] + beta[["x"]] * dat$x[i]
    l <- if (identical(fx$term, "intercept")) rep(1, length(i)) else dat$x[i]
    nll <- function(b) {
      -sum(mg_log_density(fx$family, dat$y[i], eta0 + l * b, sigma)) -
        stats::dnorm(b, 0, tau, log = TRUE)
    }
    mode <- stats::optimize(nll, c(-12 * tau, 12 * tau), tol = 1e-12)$minimum
    curv <- 1 / tau^2 +
      sum(mg_info(fx$family, dat$y[i], eta0 + l * mode, sigma) * l^2)
    total <- total - nll(mode) - 0.5 * log(curv) + 0.5 * log(2 * pi)
  }
  total
}

mg_oracle_at_fit <- function(fit, fx, ...) {
  mg_oracle(
    fx,
    beta = stats::coef(fit, dpar = "mu"),
    log_sigma = stats::coef(fit, dpar = "sigma")[[1L]],
    alpha = stats::coef(fit, dpar = "sd(id)"),
    ...
  )
}

mg_cases <- list(
  list(family = "nb2", term = "intercept", seed = 20261102L),
  list(family = "nb2", term = "slope", seed = 20261103L),
  list(family = "gamma", term = "intercept", seed = 20261104L),
  list(family = "gamma", term = "slope", seed = 20261105L)
)

mg_label <- function(case) paste(case$family, case$term)

test_that("include fits equal complete-case fits and match a dense Laplace oracle", {
  skip_on_cran()
  for (case in mg_cases) {
    fx <- mg_fixture(case$family, case$term, case$seed)
    dat <- fx$data
    observed <- !is.na(dat$y)
    expect_gt(sum(!observed), 40L)  # random NAs plus one empty group
    fit <- mg_fit(fx)
    cc <- mg_fit(fx, data = dat[observed, , drop = FALSE], include = FALSE)

    info <- mg_label(case)
    expect_true(is_converged(fit), info = info)
    expect_identical(fit$missing_data$response_policy, "include", info = info)
    expect_equal(fit$missing_data$observed_y, observed, info = info)
    expect_equal(fit$nobs, sum(observed), info = info)

    expect_lt(abs(as.numeric(logLik(fit)) - as.numeric(logLik(cc))), 1e-8)
    for (dp in c("mu", "sigma", "sd(id)")) {
      expect_equal(stats::coef(fit, dpar = dp), stats::coef(cc, dpar = dp),
                   tolerance = 1e-6, info = paste(info, dp))
    }
    expect_identical(names(stats::coef(fit, dpar = "sd(id)")),
                     c("(Intercept)", "w"))

    ll_oracle <- mg_oracle_at_fit(fit, fx)
    expect_lt(abs(as.numeric(logLik(fit)) - ll_oracle), 1e-4)

    # Emulated bug 1: masked rows treated as observed placeholder responses
    # (the value the data builder writes into masked rows).
    placeholder <- if (identical(case$family, "nb2")) 0 else 1
    y_bug <- dat$y
    y_bug[!observed] <- placeholder
    ll_bug <- mg_oracle_at_fit(fit, fx, y = y_bug, drop_na = FALSE)
    expect_gt(abs(ll_bug - ll_oracle), 0.05)

    # Emulated bug 2: the SD slope on w silently dropped (constant SD).
    alpha_flat <- stats::coef(fit, dpar = "sd(id)")
    alpha_flat[["w"]] <- 0
    ll_flat <- mg_oracle(
      fx, stats::coef(fit, dpar = "mu"),
      stats::coef(fit, dpar = "sigma")[[1L]], alpha_flat
    )
    expect_gt(abs(ll_flat - ll_oracle), 0.05)
    expect_gt(abs(stats::coef(fit, dpar = "sd(id)")[["w"]]), 0.05)
  }
})

test_that("constant SD under include equals the plain random effect and complete-case", {
  skip_on_cran()
  for (case in mg_cases) {
    fx <- mg_fixture(case$family, case$term, case$seed)
    dat <- fx$data
    observed <- !is.na(dat$y)
    const <- mg_fit(fx, sd_rhs = "1")
    mu_f <- if (identical(case$term, "intercept")) {
      y ~ x + (1 | id)
    } else {
      y ~ x + (0 + x | id)
    }
    plain <- drmTMB(
      bf(mu_f, sigma ~ 1), family = mg_family(case$family), data = dat,
      missing = miss_control(response = "include"),
      control = drm_control(se = FALSE)
    )
    cc_const <- mg_fit(fx, data = dat[observed, , drop = FALSE],
                       include = FALSE, sd_rhs = "1")
    info <- mg_label(case)
    expect_lt(abs(as.numeric(logLik(const)) - as.numeric(logLik(plain))), 1e-6)
    expect_lt(abs(as.numeric(logLik(const)) - as.numeric(logLik(cc_const))),
              1e-8)
    expect_equal(
      unname(predict(const, dpar = "sd(id)")),
      rep(unname(plain$sdpars$mu)[[1L]], length(fx$levs)),
      tolerance = 1e-4, info = info
    )
  }
})

test_that("predictions exist for masked rows and for the empty group", {
  skip_on_cran()
  for (case in mg_cases) {
    fx <- mg_fixture(case$family, case$term, case$seed)
    dat <- fx$data
    observed <- !is.na(dat$y)
    fit <- mg_fit(fx)
    cc <- mg_fit(fx, data = dat[observed, , drop = FALSE], include = FALSE)
    info <- mg_label(case)
    beta <- stats::coef(fit, dpar = "mu")
    fixed_link <- beta[["(Intercept)"]] + beta[["x"]] * dat$x

    # Training rows: one finite prediction per input row, masked rows included.
    eta <- predict(fit, dpar = "mu", type = "link")
    expect_length(eta, nrow(dat))
    expect_true(all(is.finite(eta)), info = info)
    expect_true(all(predict(fit, dpar = "mu", type = "response") > 0),
                info = info)
    # Observed rows agree with the complete-case fit (same conditional modes).
    expect_equal(unname(eta[observed]),
                 unname(predict(cc, dpar = "mu", type = "link")),
                 tolerance = 1e-6, info = info)
    # The group with no observed response has a conditional mode of zero, so
    # its masked rows sit on the fixed-effect line.
    empty <- dat$id == fx$dead
    expect_equal(unname(eta[empty]), unname(fixed_link[empty]),
                 tolerance = 1e-6, info = info)

    # New rows with an NA response get population-level predictions.
    masked <- dat[!observed, , drop = FALSE]
    eta_new <- predict(fit, newdata = masked, dpar = "mu", type = "link")
    expect_length(eta_new, nrow(masked))
    expect_equal(unname(eta_new), unname(fixed_link[!observed]),
                 tolerance = 1e-8, info = info)

    # Group SD predictions: one per group, name-aligned, equal to exp(X alpha)
    # by hand for every group including the empty one.
    alpha <- stats::coef(fit, dpar = "sd(id)")
    sd_hat <- predict(fit, dpar = "sd(id)")
    expect_setequal(names(sd_hat), fx$levs)
    w_by_group <- stats::setNames(
      as.numeric(tapply(dat$w, dat$id, function(v) v[[1L]])), levels(dat$id)
    )
    expect_equal(
      unname(sd_hat[fx$levs]),
      unname(exp(alpha[["(Intercept)"]] + alpha[["w"]] * w_by_group[fx$levs])),
      tolerance = 1e-8, info = info
    )
    expect_true(fx$dead %in% names(sd_hat))
  }
})

test_that("sigma-target, joint, and structured SD regression stay refused under include", {
  skip_on_cran()
  inc <- miss_control(response = "include")
  ctl <- drm_control(se = FALSE)
  for (family in c("nb2", "gamma")) {
    fx <- mg_fixture(family, "intercept", 20261106L)
    dat <- fx$data
    fam <- mg_family(family)
    pattern <- if (identical(family, "nb2")) "complete data" else "complete responses"
    sigma_pattern <- if (identical(family, "nb2")) {
      "complete data|sigma-endpoint"
    } else {
      "complete responses"
    }

    # sigma-target ordinary SD regression.
    expect_error(
      drmTMB(
        bf(y ~ x, sigma ~ 1 + (1 | id), sd(id, dpar = "sigma") ~ w),
        family = fam, data = dat, missing = inc, control = ctl
      ),
      sigma_pattern
    )
    # Joint mu and sigma ordinary SD regression.
    expect_error(
      drmTMB(
        bf(y ~ x + (1 | id), sigma ~ 1 + (1 | id),
           sd(id, dpar = "mu") ~ w, sd(id, dpar = "sigma") ~ w),
        family = fam, data = dat, missing = inc, control = ctl
      ),
      "complete|include|sigma"
    )
    # Structured providers with a non-unit-diagonal K and shuffled levels.
    n_id <- length(fx$levs)
    ids <- fx$levs
    K <- 1.7 * 0.45^abs(outer(seq_len(n_id), seq_len(n_id), `-`))
    dimnames(K) <- list(ids, ids)
    K <- K[rev(ids), rev(ids)]
    # NB2 admits structured intercept, slope-only and ordinary-plus-structured
    # shapes with include (test-count-structured-sd-missing-include.R and
    # test-count-iid-slope-sd-missing-include.R); its structured pin uses the
    # still-refused q2 shape. Gamma admits only a structured intercept
    # (test-binomial-gamma-sd-missing-include.R), so its pin keeps the
    # slope-only shape.
    if (identical(family, "nb2")) {
      sd_a <- sd(id, level = "relmat", coef = "(Intercept)") ~ w
      sd_b <- sd(id, level = "relmat", coef = "x") ~ w
      expect_error(
        drmTMB(
          bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1, sd_a, sd_b),
          family = fam, data = dat, missing = inc, control = ctl
        ),
        pattern
      )
      next
    }
    expect_error(
      drmTMB(
        bf(y ~ x + relmat(0 + x | id, K = K), sigma ~ 1,
           sd(id, level = "relmat") ~ w),
        family = fam, data = dat, missing = inc, control = ctl
      ),
      pattern
    )
  }
})

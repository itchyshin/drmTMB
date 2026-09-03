# Public start contract (docs/design/35-optimizer-start-map-multistart.md,
# "Public Start Contract (DECIDED 2026-09-01; implementation in progress)").
#
# `drm_control(start = list(...))` does not exist yet: `drm_control()` has no
# `start` formal, so every call below currently errors with base R's "unused
# argument" error before the label surface is ever reached. These tests are
# written as though the contract were implemented; today they must fail or
# error because the feature is absent, not because of a mistake in the test
# code itself. Implementation lands on claude/rev-parity-a2-start.

start_contract_fixef_data <- function() {
  set.seed(20260901)
  x <- seq(-1.5, 1.5, length.out = 12)
  data.frame(
    x = x,
    y = 0.6 + 0.8 * x + c(
      -0.15, 0.12, -0.05, 0.22, -0.18, 0.08,
      0.16, -0.12, 0.04, -0.02, 0.10, -0.09
    )
  )
}

start_contract_sd_data <- function() {
  set.seed(20260902)
  id <- factor(rep(seq_len(8L), each = 5L))
  x <- stats::rnorm(40L)
  u <- stats::rnorm(8L, sd = 0.3)
  data.frame(
    id = id,
    x = x,
    y = 0.4 + 0.3 * x + u[id] + stats::rnorm(40L, sd = 0.2)
  )
}

start_contract_cor_data <- function() {
  set.seed(20260903)
  id <- factor(rep(seq_len(10L), each = 6L))
  x <- stats::rnorm(60L)
  data.frame(
    id = id,
    x = x,
    y = 0.4 + 0.3 * x + stats::rnorm(60L, sd = 0.4)
  )
}

start_contract_map_data <- function() {
  set.seed(20260904)
  id <- factor(rep(seq_len(8L), each = 3L))
  id2 <- factor(rep(seq_len(6L), length.out = 24L))
  w <- rep(seq(-0.8, 0.8, length.out = 8L), each = 3L)
  u <- stats::rnorm(8L, sd = 0.3)
  u2 <- stats::rnorm(6L, sd = 0.2)
  data.frame(
    id = id,
    id2 = id2,
    w = w,
    y = 0.4 + 0.2 * w + u[id] + u2[id2] + stats::rnorm(24L, sd = 0.2)
  )
}

test_that("a valid fixef: start is accepted and reaches spec$start", {
  dat <- start_contract_fixef_data()

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = drm_control(
      start = list("fixef:mu:(Intercept)" = 0.2, "fixef:sigma:(Intercept)" = log(0.4)),
      se = FALSE
    )
  )

  expect_equal(unname(fit$model$start$beta_mu[["(Intercept)"]]), 0.2)
  expect_equal(unname(fit$model$start$beta_sigma[["(Intercept)"]]), log(0.4))
})

test_that("a valid sd: start is accepted, transformed, and reaches spec$start", {
  dat <- start_contract_sd_data()

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(
      start = list("sd:mu:(1 | id)" = 0.5),
      se = FALSE
    )
  )

  # (b): starts are given on the response (natural) scale and must be
  # transformed to the internal unconstrained log-sd scale before TMB sees
  # them, not passed through verbatim.
  expect_equal(unname(fit$model$start$log_sd_mu), log(0.5))
})

test_that("a valid cor: start is accepted, transformed, and reaches spec$start", {
  dat <- start_contract_cor_data()

  fit <- drmTMB(
    bf(y ~ x + (1 + x | id), sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(
      start = list("cor:mu:cor((Intercept),x | id)" = 0.4),
      se = FALSE
    )
  )

  # (b): a natural-scale correlation start must be mapped through Fisher-z
  # (atanh) onto the internal eta_cor_mu scale, not passed through verbatim.
  expect_equal(unname(fit$model$start$eta_cor_mu), atanh(0.4), tolerance = 1e-10)
})

test_that("an unknown start label errors before optimization, not during the fit", {
  dat <- start_contract_fixef_data()

  err <- tryCatch(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      data = dat,
      control = drm_control(
        start = list("fixef:mu:not_a_real_column" = 1),
        se = FALSE
      )
    ),
    error = function(e) e
  )

  expect_s3_class(err, "error")
  msg <- conditionMessage(err)
  # A pre-optimization validation error names the unknown label/component; it
  # must not read like an ordinary nlminb() numerical-failure message, which
  # is the signature of "failed during the fit" rather than "failed
  # validation before optimization ever started".
  expect_match(msg, "nknown", ignore.case = FALSE)
  expect_false(grepl("NA/NaN|gradient|convergence|iteration limit", msg))
})

test_that("a partial start updates only the named target; the rest match the cold-fit start", {
  dat <- start_contract_fixef_data()

  cold <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat, control = drm_control(se = FALSE))
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = drm_control(
      start = list("fixef:mu:(Intercept)" = 0.9),
      se = FALSE
    )
  )

  expect_equal(unname(fit$model$start$beta_mu[["(Intercept)"]]), 0.9)
  # Untouched fixef:mu:x and the whole beta_sigma component must equal the
  # ordinary family-builder default, i.e. the cold fit's own start -- not
  # merely "some finite value".
  expect_equal(unname(fit$model$start$beta_mu[["x"]]), unname(cold$model$start$beta_mu[["x"]]))
  expect_equal(fit$model$start$beta_sigma, cold$model$start$beta_sigma)
})

test_that("a slot fixed by spec$map is preserved, not overwritten, when its sibling is targeted", {
  dat <- start_contract_map_data()

  # log_sd_mu has two elements here: index 1 (the "id" term) is fully driven
  # by the sd(id) ~ w regression and is map-fixed (factor(NA)); index 2 (the
  # "id2" term) is an ordinary free variance component, publicly labelled
  # "sd:mu:(1 | id2)". No public label can ever address index 1, so the
  # translation layer must build the full-length override vector using the
  # family default for the mapped slot, not touch it, and not error on the
  # length mismatch between the one named label and the two-element target.
  cold <- drmTMB(
    bf(y ~ w + (1 | id) + (1 | id2), sigma ~ 1, sd(id) ~ w),
    family = gaussian(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  fit <- drmTMB(
    bf(y ~ w + (1 | id) + (1 | id2), sigma ~ 1, sd(id) ~ w),
    family = gaussian(),
    data = dat,
    control = drm_control(
      start = list("sd:mu:(1 | id2)" = 0.25),
      se = FALSE
    )
  )

  expect_equal(unname(fit$model$start$log_sd_mu[[2L]]), log(0.25))
  expect_equal(
    unname(fit$model$start$log_sd_mu[[1L]]),
    unname(cold$model$start$log_sd_mu[[1L]])
  )
  expect_equal(fit$model$map$log_sd_mu, cold$model$map$log_sd_mu)
})

test_that("provenance for an applied public start is recorded in spec$start_override_applied", {
  dat <- start_contract_fixef_data()

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = drm_control(
      start = list("fixef:mu:(Intercept)" = 0.2),
      se = FALSE
    )
  )

  expect_named(
    fit$model$start_override_applied,
    c("parameter", "n_value", "n_applied", "n_mapped")
  )
  expect_true(nrow(fit$model$start_override_applied) > 0L)
  expect_true("beta_mu" %in% fit$model$start_override_applied$parameter)
})

test_that("a label addressing a latent random effect (u) is rejected", {
  dat <- start_contract_sd_data()

  err_namespaced <- tryCatch(
    drmTMB(
      bf(y ~ x + (1 | id), sigma ~ 1),
      family = gaussian(),
      data = dat,
      control = drm_control(
        start = list("u:mu:1" = 0.1),
        se = FALSE
      )
    ),
    error = function(e) e
  )
  err_raw <- tryCatch(
    drmTMB(
      bf(y ~ x + (1 | id), sigma ~ 1),
      family = gaussian(),
      data = dat,
      control = drm_control(
        start = list("u_mu" = 0.1),
        se = FALSE
      )
    ),
    error = function(e) e
  )

  # These must be rejected as *latent-target* starts specifically -- not
  # merely error for the unrelated reason that `drm_control()` has no
  # `start` formal yet (today's "unused argument" error, which says nothing
  # about latent effects and would equally reject a perfectly valid label).
  expect_s3_class(err_namespaced, "error")
  expect_false(grepl("unused argument", conditionMessage(err_namespaced), fixed = TRUE))
  expect_match(conditionMessage(err_namespaced), "u:|latent|random effect", ignore.case = TRUE)

  expect_s3_class(err_raw, "error")
  expect_false(grepl("unused argument", conditionMessage(err_raw), fixed = TRUE))
  expect_match(conditionMessage(err_raw), "nknown|latent|random effect", ignore.case = TRUE)
})

test_that("starting a fit at its own optimum does not move the optimum (round trip)", {
  dat <- start_contract_fixef_data()

  cold <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat, control = drm_control(se = FALSE))
  start_at_optimum <- list(
    "fixef:mu:(Intercept)" = unname(cold$coefficients$mu[["(Intercept)"]]),
    "fixef:mu:x" = unname(cold$coefficients$mu[["x"]]),
    "fixef:sigma:(Intercept)" = unname(cold$coefficients$sigma[["(Intercept)"]])
  )

  restarted <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = drm_control(start = start_at_optimum, se = FALSE)
  )

  expect_equal(unname(restarted$opt$par), unname(cold$opt$par), tolerance = 1e-6)
  expect_equal(as.numeric(logLik(restarted)), as.numeric(logLik(cold)), tolerance = 1e-8)
})

test_that("a deliberately displaced start returns to the same optimum (round trip)", {
  dat <- start_contract_fixef_data()

  cold <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat, control = drm_control(se = FALSE))
  displaced_start <- list(
    "fixef:mu:(Intercept)" = unname(cold$coefficients$mu[["(Intercept)"]]) + 5,
    "fixef:mu:x" = unname(cold$coefficients$mu[["x"]]) - 3,
    "fixef:sigma:(Intercept)" = unname(cold$coefficients$sigma[["(Intercept)"]]) + 2
  )

  restarted <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = drm_control(start = displaced_start, se = FALSE)
  )

  expect_equal(unname(restarted$opt$par), unname(cold$opt$par), tolerance = 1e-4)
  expect_equal(as.numeric(logLik(restarted)), as.numeric(logLik(cold)), tolerance = 1e-6)
})

# Adversarial-pass follow-up (2026-09-01): defects found in the landed
# implementation that A1's ten blocks above did not cover. See
# docs/dev-log/after-task/2026-09-01-a2-start-implementation.md for the
# root-cause diagnosis and fix rationale.

test_that("a fixef:sigma: start outside the log-sigma clamp band warns instead of silently reporting a clean convergence (defect A2-D1)", {
  dat <- start_contract_fixef_data()

  cold <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat, control = drm_control(se = FALSE))

  # The default logsigma_clamp band is c(-12, 12); an intercept-only sigma
  # start of 50 lies far outside it, in the clamp's fully saturated tail
  # where the softclamp derivative is ~0. The optimizer should not be able
  # to silently report a clean convergence from a start it never moved away
  # from -- this must warn, naming the clamp, before or during the fit that
  # produces the bad result.
  expect_warning(
    saturated <- drmTMB(
      bf(y ~ x, sigma ~ 1),
      data = dat,
      control = drm_control(
        start = list("fixef:sigma:(Intercept)" = 50),
        se = FALSE
      )
    ),
    class = "drmTMB_start_clamp_saturated_warning"
  )

  # The contract's own invariant still holds: the warning reports the
  # condition, it does not silently move the user's start.
  expect_equal(unname(saturated$model$start$beta_sigma[["(Intercept)"]]), 50)

  # And the fit really did land somewhere much worse than the true optimum --
  # this is not a cosmetic warning on an otherwise-fine fit.
  expect_true(
    abs(as.numeric(logLik(saturated)) - as.numeric(logLik(cold))) > 10
  )
})

test_that("a fixef:mu: start under REML errors instead of being silently accepted with no effect (defect A2-D2)", {
  set.seed(20260905)
  id <- factor(rep(seq_len(10L), each = 6L))
  x <- stats::rnorm(60L)
  dat <- data.frame(
    id = id,
    x = x,
    y = 0.4 + 0.3 * x + stats::rnorm(60L, sd = 0.4)
  )

  err <- tryCatch(
    drmTMB(
      bf(y ~ x + (1 | id), sigma ~ 1),
      family = gaussian(),
      data = dat,
      REML = TRUE,
      control = drm_control(
        start = list("fixef:mu:(Intercept)" = 99),
        se = FALSE
      )
    ),
    error = function(e) e
  )

  expect_s3_class(err, "error")
  expect_match(conditionMessage(err), "REML", ignore.case = FALSE)
})

# rho12 and phylo covariance block labels (design 35, "Phylo Covariance
# Block"; A5 gap, N3 2026-09-03): `fixef:rho12:<term>`, `phylo_sd:<axis>`, and
# `phylo_cor:<axis1>:<axis2>` now reach `biv_gaussian`'s `rho12` fixed effect
# and the q4 dense phylogenetic covariance block, closing the gap the A5
# cross-engine receipt worked around by addressing `beta_rho12`/
# `log_sd_phylo`/`theta_phylo` by internal TMB parameter name.
start_contract_biv_q4_phylo_fixture <- function() {
  set.seed(575)
  tree <- ape::rcoal(16L, tip.label = sprintf("sp%02d", seq_len(16L)))
  species <- factor(rep(tree$tip.label, each = 3L), levels = tree$tip.label)
  n <- length(species)
  dat <- data.frame(
    y1 = stats::rnorm(n),
    y2 = stats::rnorm(n),
    x = stats::rnorm(n),
    species = species
  )
  form <- bf(
    mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
    mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
    sigma1 = ~ 1 + phylo(1 | p | species, tree = tree),
    sigma2 = ~ 1 + phylo(1 | p | species, tree = tree),
    rho12 = ~1
  )
  list(data = dat, tree = tree, formula = form)
}

test_that("a start naming rho12 and the q4 phylo covariance block converges to the same optimum", {
  fx <- start_contract_biv_q4_phylo_fixture()

  cold <- suppressWarnings(drmTMB(
    fx$formula,
    family = biv_gaussian(),
    data = fx$data,
    engine = "tmb",
    REML = TRUE,
    control = drm_control(optimizer_preset = "robust", keep_tmb_object = TRUE)
  ))

  par <- cold$opt$par
  log_sd_phylo <- unname(par[names(par) == "log_sd_phylo"])
  theta_phylo <- unname(par[names(par) == "theta_phylo"])
  rho12_hat <- as.numeric(coef(cold)$rho12[["(Intercept)"]])
  axes <- c("mu1", "mu2", "sigma1", "sigma2")
  pairs <- list(
    c("mu1", "mu2"), c("mu1", "sigma1"), c("mu2", "sigma1"),
    c("mu1", "sigma2"), c("mu2", "sigma2"), c("sigma1", "sigma2")
  )
  start <- list("fixef:rho12:(Intercept)" = rho12_hat)
  for (i in seq_along(axes)) {
    start[[paste0("phylo_sd:", axes[[i]])]] <- exp(log_sd_phylo[[i]])
  }
  for (i in seq_along(pairs)) {
    start[[paste0("phylo_cor:", pairs[[i]][[1L]], ":", pairs[[i]][[2L]])]] <- theta_phylo[[i]]
  }

  warm <- suppressWarnings(drmTMB(
    fx$formula,
    family = biv_gaussian(),
    data = fx$data,
    engine = "tmb",
    REML = TRUE,
    control = drm_control(optimizer_preset = "robust", start = start)
  ))

  expect_equal(as.numeric(logLik(warm)), as.numeric(logLik(cold)), tolerance = 1e-6)
})

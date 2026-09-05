# chibar_pvalue() and lrt_boundary(): the chi-bar-square boundary-corrected
# likelihood-ratio test for variance components, ported from DRM.jl
# src/chibar.jl (pin 430ef64cc). The closed-form and fitted-model blocks mirror
# DRM.jl test/test_chibar.jl; the live-Julia block measures same-target
# agreement between this port and DRM.jl's own lrt_boundary on the same data.

naive_p <- function(stat, df) stats::pchisq(stat, df = df, lower.tail = FALSE)

random_intercept_data <- function(seed, G, m, sd_b, beta = c(0.5, -0.4), sd_e = 0.7) {
  set.seed(seed)
  n <- G * m
  g <- rep(seq_len(G), each = m)
  x <- stats::rnorm(n)
  # Under the true null (sd_b = 0) no group draw is consumed, matching DRM.jl
  # test_chibar.jl:94 (`yy = 0.4 .- 0.5 .* xx .+ 0.7 .* randn(nn)`, no b term).
  b <- if (sd_b > 0) sd_b * stats::rnorm(G) else numeric(G)
  data.frame(
    y = beta[[1L]] + beta[[2L]] * x + b[g] + sd_e * stats::rnorm(n),
    x = x,
    g = factor(g)
  )
}

crossed_intercept_data <- function(seed, G = 30, H = 25, n = 600, sd_b = 0.3) {
  set.seed(seed)
  g <- sample(seq_len(G), n, replace = TRUE)
  h <- sample(seq_len(H), n, replace = TRUE)
  x <- stats::rnorm(n)
  bg <- sd_b * stats::rnorm(G)
  bh <- sd_b * stats::rnorm(H)
  data.frame(
    y = 0.5 - 0.4 * x + bg[g] + bh[h] + 0.7 * stats::rnorm(n),
    x = x,
    g = factor(g),
    h = factor(h)
  )
}

fit_ri_pair <- function(dat, ...) {
  list(
    full = suppressWarnings(drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(), data = dat, ...)),
    reduced = drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat, ...)
  )
}

test_that("chibar_pvalue q = 1 is the closed form 0.5 * P(chisq_1 > stat) (DRM.jl test_chibar.jl:15-34)", {
  for (stat in c(0.25, 1.0, 2.71, 3.84, 6.63, 10.0)) {
    expect_identical(chibar_pvalue(stat, 1), 0.5 * naive_p(stat, 1))
  }
  # Boundary point mass: the chisq_0 atom adds nothing to the upper tail.
  expect_identical(chibar_pvalue(0, 1), 0.5)
  expect_equal(chibar_pvalue(1e-10, 1), 0.5, tolerance = 1e-4)
  # Default q is 1.
  expect_identical(chibar_pvalue(3.84), chibar_pvalue(3.84, 1))
  # Less conservative than the naive chisq_1 tail.
  expect_lt(chibar_pvalue(3.84, 1), naive_p(3.84, 1))
  # A negative statistic clamps to the boundary value.
  expect_identical(chibar_pvalue(-2, 1), 0.5)
  # Valid, monotone decreasing.
  expect_gte(chibar_pvalue(5, 1), 0)
  expect_lte(chibar_pvalue(5, 1), 1)
  expect_lt(chibar_pvalue(5, 1), chibar_pvalue(1, 1))
})

test_that("chibar_pvalue q = 2 is the 0.25/0.5/0.25 mixture (DRM.jl test_chibar.jl:36-50)", {
  for (stat in c(0.5, 2.0, 4.0, 5.99, 9.21)) {
    expect_identical(
      chibar_pvalue(stat, 2),
      0.5 * naive_p(stat, 1) + 0.25 * naive_p(stat, 2)
    )
  }
  expect_identical(chibar_pvalue(0, 2), 0.75)
  expect_lt(chibar_pvalue(5.99, 2), naive_p(5.99, 2))
  expect_error(chibar_pvalue(3, 3), "must be 1 or 2")
  expect_error(chibar_pvalue(3, 0), "must be 1 or 2")
  expect_error(chibar_pvalue(3, 1.5), "must be 1 or 2")
  expect_error(chibar_pvalue(3, c(1, 2)), "must be 1 or 2")
  expect_error(chibar_pvalue("3", 1), "must be numeric")
})

test_that("chibar_pvalue is vectorised and propagates NA", {
  stats_in <- c(-1, 0, 1, NA, 4)
  out <- chibar_pvalue(stats_in, 1)
  expect_length(out, 5L)
  expect_identical(out[1:2], c(0.5, 0.5))
  expect_true(is.na(out[[4L]]))
  expect_identical(out[[5L]], 0.5 * naive_p(4, 1))
})

test_that("lrt_boundary on a fitted random-intercept model (DRM.jl test_chibar.jl:52-77)", {
  dat <- random_intercept_data(seed = 20260610, G = 60, m = 20, sd_b = 0.8)
  fits <- fit_ri_pair(dat)
  t <- lrt_boundary(fits$full, fits$reduced, q = 1)

  expect_s3_class(t, "drm_lrt_boundary")
  expect_named(t, c("statistic", "q", "pvalue", "pvalue_naive", "df"))
  expect_equal(
    t$statistic,
    2 * (as.numeric(logLik(fits$full)) - as.numeric(logLik(fits$reduced)))
  )
  expect_identical(t$q, 1L)
  expect_identical(t$df, 1)
  expect_identical(t$pvalue, chibar_pvalue(t$statistic, 1))
  expect_identical(t$pvalue_naive, naive_p(max(t$statistic, 0), 1))
  # q = 1, stat > 0: the boundary p-value is exactly half the naive one.
  expect_gt(t$statistic, 0)
  expect_equal(t$pvalue, 0.5 * t$pvalue_naive)
  expect_lte(t$pvalue, t$pvalue_naive)
  # A real random effect: both reject.
  expect_lt(t$pvalue, 0.05)

  expect_output(print(t), "chi-bar-square")
  expect_output(print(t), "naive chisq_1")
})

test_that("a variance estimated at zero gives the boundary p-value (DRM.jl test_chibar.jl:79-121, one true-null draw)", {
  # TRUE NULL with the random-intercept SD driven to the boundary: the LR
  # statistic sits at the chisq_0 atom. The naive p-value is 1 (all mass
  # treated as continuous chisq_1), the chi-bar-square p-value is the point
  # mass 0.5. Seed 7001 is one of the DRM.jl null-calibration seeds (7000 + i).
  dat <- random_intercept_data(seed = 7001, G = 25, m = 12, sd_b = 0,
                               beta = c(0.4, -0.5))
  fits <- fit_ri_pair(dat)
  sd_b <- unname(fits$full$sdpars$mu[[1L]])
  expect_lt(sd_b, 1e-4)

  t <- lrt_boundary(fits$full, fits$reduced, q = 1)
  expect_lt(abs(t$statistic), 1e-6)
  expect_identical(t$pvalue, 0.5)
  expect_identical(t$pvalue_naive, 1)
  expect_identical(chibar_pvalue(t$statistic, 2), 0.75)
})

test_that("null calibration: chi-bar-square rejects at least as often as naive, and the atom is visible (DRM.jl test_chibar.jl:79-121)", {
  skip_on_cran()
  alpha <- 0.05
  nrep <- 30L
  p_corr <- p_naive <- numeric(nrep)
  for (i in seq_len(nrep)) {
    dat <- random_intercept_data(seed = 7000 + i, G = 25, m = 12, sd_b = 0,
                                 beta = c(0.4, -0.5))
    fits <- fit_ri_pair(dat, control = drm_control(se = FALSE))
    t <- lrt_boundary(fits$full, fits$reduced, q = 1)
    p_corr[[i]] <- t$pvalue
    p_naive[[i]] <- t$pvalue_naive
  }
  rej_corr <- mean(p_corr < alpha)
  rej_naive <- mean(p_naive < alpha)
  expect_gte(rej_corr, rej_naive)
  expect_lte(rej_naive, alpha)
  expect_lte(abs(rej_corr - alpha), abs(rej_naive - alpha))
  # The chisq_0 atom: a large share of statistics are ~0, i.e. p_naive ~ 1.
  expect_gte(mean(p_naive > 0.99), 0.30)
})

test_that("lrt_boundary refuses malformed comparisons", {
  dat <- random_intercept_data(seed = 20260610, G = 20, m = 6, sd_b = 0.8)
  fits <- fit_ri_pair(dat)
  expect_error(lrt_boundary(fits$reduced, fits$full), "must have more parameters")
  expect_error(lrt_boundary(fits$full, fits$reduced, q = 3), "must be 1 or 2")
  expect_error(lrt_boundary(fits$full, dat), "must be a")
  expect_error(lrt_boundary(dat, fits$reduced), "must be a")

  # Different observations: nested models are compared on one data set.
  reduced_subset <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat[-1L, ])
  expect_error(lrt_boundary(fits$full, reduced_subset), "same observations")

  # q must match the number of dropped parameters, else the mixture is suspect.
  expect_warning(
    t2 <- lrt_boundary(fits$full, fits$reduced, q = 2),
    class = "drmTMB_lrt_boundary_df_mismatch"
  )
  expect_identical(t2$q, 2L)
  expect_identical(t2$df, 1)
  expect_no_warning(lrt_boundary(fits$full, fits$reduced, q = 1))

  # Penalized (MAP) fits have no chi-square reference (DRM.jl
  # comparison.jl:151-158). Exercise the guard on the estimator label.
  map_fit <- fits$full
  map_fit$estimator <- "MAP"
  expect_error(lrt_boundary(map_fit, fits$reduced), "penalized")
})

test_that("lrt_boundary applies the REML guard (DRM.jl comparison.jl:133-142)", {
  dat <- random_intercept_data(seed = 20260610, G = 20, m = 6, sd_b = 0.8)
  ml <- fit_ri_pair(dat)
  reml <- fit_ri_pair(dat, REML = TRUE)
  expect_true(isTRUE(reml$full$REML))

  # Same mean structure, REML on both sides: valid.
  t <- lrt_boundary(reml$full, reml$reduced, q = 1)
  expect_equal(
    t$statistic,
    2 * (as.numeric(logLik(reml$full)) - as.numeric(logLik(reml$reduced)))
  )
  # ML against REML: refused.
  expect_error(lrt_boundary(reml$full, ml$reduced), "ML fit with a REML fit")
  # REML fits whose mean structures differ: refused.
  reml_reduced_mean <- drmTMB(bf(y ~ 1, sigma ~ 1), family = gaussian(), data = dat, REML = TRUE)
  expect_error(
    lrt_boundary(reml$full, reml_reduced_mean),
    "different fixed-effect"
  )
})

# ---- Same-target agreement with DRM.jl's native lrt_boundary (live Julia) ----

lrt_boundary_julia <- function(dat, full_rhs, reduced_rhs, q) {
  JuliaCall::julia_assign("lrtb_y", dat$y)
  JuliaCall::julia_assign("lrtb_x", dat$x)
  JuliaCall::julia_assign("lrtb_g", as.integer(dat$g))
  if (!is.null(dat$h)) JuliaCall::julia_assign("lrtb_h", as.integer(dat$h))
  JuliaCall::julia_command(
    if (is.null(dat$h)) "lrtb_d = (; y = lrtb_y, x = lrtb_x, g = lrtb_g);"
    else "lrtb_d = (; y = lrtb_y, x = lrtb_x, g = lrtb_g, h = lrtb_h);"
  )
  JuliaCall::julia_command(sprintf(
    "lrtb_full = DRM.drm(DRM.bf(DRM.@formula(y ~ %s), DRM.@formula(sigma ~ 1)), DRM.Gaussian(); data = lrtb_d);",
    full_rhs
  ))
  JuliaCall::julia_command(sprintf(
    "lrtb_reduced = DRM.drm(DRM.bf(DRM.@formula(y ~ %s), DRM.@formula(sigma ~ 1)), DRM.Gaussian(); data = lrtb_d);",
    reduced_rhs
  ))
  JuliaCall::julia_eval(sprintf(
    "let t = DRM.lrt_boundary(lrtb_full, lrtb_reduced; q = %d); Dict(\"statistic\" => t.statistic, \"q\" => t.q, \"pvalue\" => t.pvalue, \"pvalue_naive\" => t.pvalue_naive, \"loglik_full\" => DRM.loglik(lrtb_full), \"loglik_reduced\" => DRM.loglik(lrtb_reduced)) end",
    q
  ))
}

test_that("lrt_boundary matches DRM.jl's native lrt_boundary on committed fixtures", {
  drm_skip_live_julia()
  drmTMB:::drm_julia_setup()

  fixtures <- list(
    # DRM.jl test_chibar.jl:55-64 shape: strong random intercept, decisive test.
    list(id = "ri_strong", dat = random_intercept_data(seed = 20260610, G = 60, m = 20, sd_b = 0.8),
         full = "x + (1 | g)", reduced = "x", q = 1L, p_tol = 1e-8),
    # Moderate random intercept: an interior statistic (~2.2, p ~ 0.07) where
    # 1e-8 agreement of the p-value is informative.
    list(id = "ri_moderate", dat = random_intercept_data(seed = 4251, G = 40, m = 8, sd_b = 0.15),
         full = "x + (1 | g)", reduced = "x", q = 1L, p_tol = 1e-8),
    # Boundary edge: both engines drive the random-intercept SD to zero, so
    # the statistic is ~0 and the p-values sit at the chisq_0 atom (0.5 and
    # 1). The chisq_1 tail has infinite slope at 0, so a 1e-13 difference in
    # the statistic moves p by ~3e-7; p-values are held at 1e-6 here, and the
    # identical-statistic check below carries the 1e-12 agreement.
    list(id = "ri_boundary", dat = random_intercept_data(seed = 4242, G = 40, m = 8, sd_b = 0.15),
         full = "x + (1 | g)", reduced = "x", q = 1L, p_tol = 1e-6),
    # q = 2: two crossed random intercepts dropped together (two independent
    # boundary components, the 0.25/0.5/0.25 mixture).
    list(id = "crossed_q2", dat = crossed_intercept_data(seed = 31415),
         full = "x + (1 | g) + (1 | h)", reduced = "x", q = 2L, p_tol = 1e-8)
  )
  for (fx in fixtures) {
    r_full <- stats::as.formula(paste("y ~", fx$full))
    r_reduced <- stats::as.formula(paste("y ~", fx$reduced))
    fits <- list(
      full = suppressWarnings(drmTMB(do.call(bf, list(r_full, sigma ~ 1)), family = gaussian(), data = fx$dat)),
      reduced = drmTMB(do.call(bf, list(r_reduced, sigma ~ 1)), family = gaussian(), data = fx$dat)
    )
    r <- lrt_boundary(fits$full, fits$reduced, q = fx$q)
    j <- lrt_boundary_julia(fx$dat, fx$full, fx$reduced, fx$q)
    # Same target, two optimisers: the statistic agrees to 1e-8 absolute.
    expect_lt(abs(r$statistic - j$statistic), 1e-8, label = paste(fx$id, "statistic"))
    expect_identical(as.integer(j$q), r$q)
    expect_lt(abs(r$pvalue - j$pvalue), fx$p_tol, label = paste(fx$id, "pvalue"))
    expect_lt(abs(r$pvalue_naive - j$pvalue_naive), fx$p_tol, label = paste(fx$id, "pvalue_naive"))
    # On the log scale too: an absolute tolerance is vacuous when p ~ 1e-148
    # (ri_strong) or 1e-22 (crossed_q2), so a wrong mixture would pass the
    # line above there. |d log p| ~ 0.5 |d stat| for a chisq_1 tail.
    expect_lt(abs(log(r$pvalue) - log(j$pvalue)), fx$p_tol, label = paste(fx$id, "log pvalue"))
    expect_lt(abs(log(r$pvalue_naive) - log(j$pvalue_naive)), fx$p_tol, label = paste(fx$id, "log pvalue_naive"))
    # The p-value function itself, on an identical statistic: 1e-12 relative.
    j_at_r <- JuliaCall::julia_eval(sprintf(
      "(DRM.chibar_pvalue(%.17g, 1), DRM.chibar_pvalue(%.17g, 2))", r$statistic, r$statistic
    ))
    expect_equal(chibar_pvalue(r$statistic, 1), j_at_r[[1L]], tolerance = 1e-12, info = fx$id)
    expect_equal(chibar_pvalue(r$statistic, 2), j_at_r[[2L]], tolerance = 1e-12, info = fx$id)
    # `all.equal()` falls back to an absolute tolerance below 1e-12, so the
    # two lines above cannot see a wrong mixture at p ~ 1e-148; log scale can.
    expect_equal(log(chibar_pvalue(r$statistic, 1)), log(j_at_r[[1L]]), tolerance = 1e-10, info = fx$id)
    expect_equal(log(chibar_pvalue(r$statistic, 2)), log(j_at_r[[2L]]), tolerance = 1e-10, info = fx$id)
    if (identical(fx$id, "ri_boundary")) {
      expect_lt(abs(r$statistic), 1e-6)
      expect_identical(r$pvalue, 0.5)
    }
    cat(sprintf(
      "\n[lrt_boundary parity %s] R stat=%.10f p=%.12g naive=%.12g | Julia stat=%.10f p=%.12g naive=%.12g | |dstat|=%.2e |dp|=%.2e |dp_naive|=%.2e\n",
      fx$id, r$statistic, r$pvalue, r$pvalue_naive, j$statistic, j$pvalue, j$pvalue_naive,
      abs(r$statistic - j$statistic), abs(r$pvalue - j$pvalue), abs(r$pvalue_naive - j$pvalue_naive)
    ))
  }
})

test_that("Julia Binomial admits an exact related-matrix plus IID SD pair", {
  K <- matrix(c(1, 0.4, 0.4, 1), 2L)
  form <- bf(
    y ~ x + (1 | site) + relmat(1 | population, K = K),
    sd(site) ~ w,
    sd(population, level = "relmat") ~ z
  )
  missing_target <- bf(
    y ~ x + (1 | site) + relmat(1 | population, K = K),
    sd(population, level = "relmat") ~ z
  )
  wrong_group <- bf(
    y ~ x + (1 | site) + relmat(1 | population, K = K),
    sd(site) ~ w,
    sd(other, level = "relmat") ~ z
  )
  slope <- bf(
    y ~ x + (x | site) + relmat(1 | population, K = K),
    sd(site, coef = "x") ~ w,
    sd(population, level = "relmat") ~ z
  )

  expect_true(drm_julia_binomial_relmat_iid_sd_route_admitted(form))
  expect_false(drm_julia_binomial_relmat_iid_sd_route_admitted(missing_target))
  expect_false(drm_julia_binomial_relmat_iid_sd_route_admitted(wrong_group))
  expect_false(drm_julia_binomial_relmat_iid_sd_route_admitted(slope))
  for (link in c("logit", "probit", "cloglog")) {
    expect_no_error(drm_julia_refuse_binomial_nonlogit_sd(
      form, stats::binomial(link = link)
    ))
  }
})

test_that("Julia Binomial related-matrix plus IID bridge fits all links", {
  skip_on_cran()
  drm_skip_live_julia()

  set.seed(202610291L)
  n_rel <- 20L
  n_iid <- 18L
  n_rep <- 4L
  K <- outer(seq_len(n_rel), seq_len(n_rel), function(i, j) 0.45^abs(i - j))
  dimnames(K) <- list(paste0("rel_", seq_len(n_rel)), paste0("rel_", seq_len(n_rel)))
  rel_idx <- rep(seq_len(n_rel), each = n_iid * n_rep)
  iid_idx <- rep(rep(seq_len(n_iid), each = n_rep), times = n_rel)
  rel_group <- factor(rownames(K)[rel_idx], levels = rownames(K))
  iid_group <- factor(paste0("iid_", iid_idx), levels = paste0("iid_", seq_len(n_iid)))
  z_group <- sample(rep(c(-1, 1), length.out = n_rel))
  w_group <- sample(rep(c(-1, 1), length.out = n_iid))
  z <- z_group[rel_idx]
  w <- w_group[iid_idx]
  x <- stats::rnorm(length(rel_idx))
  rel_sd <- exp(-0.65 + 0.35 * z_group)
  iid_sd <- exp(-0.8 - 0.3 * w_group)
  rel_effect <- as.vector(t(chol(K)) %*% stats::rnorm(n_rel)) * rel_sd
  iid_effect <- stats::rnorm(n_iid) * iid_sd
  eta <- -0.1 + 0.25 * x + rel_effect[rel_idx] + iid_effect[iid_idx]
  dat <- data.frame(x, z, w, rel_group, iid_group)
  form <- bf(
    y ~ x + (1 | iid_group) + relmat(1 | rel_group, K = K),
    sd(iid_group) ~ w,
    sd(rel_group, level = "relmat") ~ z
  )

  for (link in c("logit", "probit", "cloglog")) {
    dat$y <- stats::rbinom(
      nrow(dat), 1L, stats::binomial(link = link)$linkinv(eta)
    )
    native <- drmTMB(
      form, family = stats::binomial(link), data = dat, engine = "tmb",
      control = drm_control(se = FALSE)
    )
    julia <- drmTMB(
      form, family = stats::binomial(link), data = dat, engine = "julia"
    )
    expect_true(is_converged(native), info = paste(link, "TMB"))
    expect_true(is_converged(julia), info = paste(link, "Julia"))
    expect_equal(as.numeric(logLik(julia)), as.numeric(logLik(native)),
                 tolerance = 0.2, info = link)
    for (target in c("sd(iid_group)", "sd_relmat(rel_group)")) {
      expect_named(coef(julia, dpar = target), names(coef(native, dpar = target)))
      expect_equal(coef(julia, dpar = target), coef(native, dpar = target),
                   tolerance = 0.5, info = paste(link, target))
      expect_equal(predict(julia, dpar = target), predict(native, dpar = target),
                   tolerance = 0.3, info = paste(link, target))
    }
    simulated <- simulate(julia, nsim = 1L, seed = 202610292L)
    expect_length(simulated, 1L)
    expect_true(all(simulated[[1L]] %in% c(0L, 1L)))
  }
})

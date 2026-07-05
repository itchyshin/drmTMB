test_that("structured q2 scale-only blocks fit as scale-only point routes", {
  set.seed(60622128)
  n_id <- 6L
  n_each <- 10L
  id_levels <- paste0("id", seq_len(n_id))
  site_levels <- paste0("site", seq_len(n_id))
  n <- n_id * n_each
  id <- rep(id_levels, each = n_each)
  site <- rep(site_levels, each = n_each)
  site_scale <- stats::setNames(seq(-0.4, 0.4, length.out = n_id), site_levels)
  dat <- data.frame(
    y1 = 0.2 + stats::rnorm(n, sd = exp(-0.35 + site_scale[site])),
    y2 = -0.1 + stats::rnorm(n, sd = exp(-0.15 - 0.5 * site_scale[site])),
    x = stats::rnorm(n),
    z = stats::rnorm(n),
    id = id,
    site = site
  )
  K <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.2^abs(i - j))
  diag(K) <- diag(K) + 0.5
  dimnames(K) <- list(id_levels, id_levels)
  Q <- solve(K)
  coords <- data.frame(x = seq_len(n_id), y = c(0, 1, 1, 2, 3, 5))
  rownames(coords) <- site_levels
  ctrl <- drm_control(
    se = FALSE,
    optimizer = list(eval.max = 300, iter.max = 300)
  )

  fits <- list(
    spatial = drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ z + spatial(1 | ps | site, coords = coords),
        sigma2 = ~ z + spatial(1 | ps | site, coords = coords),
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat,
      control = ctrl
    ),
    animal = drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ z + animal(1 | ps | id, Ainv = Q),
        sigma2 = ~ z + animal(1 | ps | id, Ainv = Q),
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat,
      control = ctrl
    ),
    relmat = drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ z + relmat(1 | ps | id, Q = Q),
        sigma2 = ~ z + relmat(1 | ps | id, Q = Q),
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat,
      control = ctrl
    )
  )

  for (provider in names(fits)) {
    fit <- fits[[provider]]
    group <- if (identical(provider, "spatial")) "site" else "id"
    expect_equal(fit$opt$convergence, 0)
    expect_equal(fit$model$structured$phylo_mu$dpars, c("sigma1", "sigma2"))
    expect_equal(fit$model$structured$phylo_mu$q, 2L)
    expect_equal(fit$model$random$mu$n_re, 0L)
    expect_equal(fit$model$random$sigma$n_re, 0L)
    expect_equal(fit$model$structured$phylo_mu$covariance_mode, "scalar")
    expect_equal(fit$model$structured$phylo_mu$block_labels, "ps")
    expect_true("u_phylo" %in% fit$model$random_names)
    expect_named(fit$sdpars, c("sigma1", "sigma2"))
    expect_true(all(is.finite(unlist(fit$sdpars, use.names = FALSE))))
    expect_true(is.numeric(fit$corpars[[provider]]))
    expect_equal(length(fit$corpars[[provider]]), 1L)
    expect_true(is.finite(unlist(fit$corpars[[provider]], use.names = FALSE)))

    pairs <- corpairs(fit, level = provider)
    expect_equal(nrow(pairs), 1L)
    expect_equal(pairs$class, "scale-scale")
    expect_equal(pairs$from_dpar, "sigma1")
    expect_equal(pairs$to_dpar, "sigma2")
    expect_equal(pairs$block, "ps")
    expect_equal(
      pairs$parameter,
      paste0(
        "cor(sigma1:(Intercept),sigma2:(Intercept) | ps | ",
        group,
        ")"
      )
    )

    covariance <- drmTMB:::random_effect_covariance_summaries(fit)
    expect_equal(nrow(covariance), 1L)
    expect_equal(covariance$level, provider)
    expect_equal(covariance$class, "scale-scale")
    expect_equal(covariance$from_dpar, "sigma1")
    expect_equal(covariance$to_dpar, "sigma2")
    expect_equal(
      covariance$from_sd_target,
      paste0(
        "sd:sigma1:sigma1:",
        provider,
        "(1 | ps | ",
        group,
        ")"
      )
    )
    expect_equal(
      covariance$to_sd_target,
      paste0(
        "sd:sigma2:sigma2:",
        provider,
        "(1 | ps | ",
        group,
        ")"
      )
    )
    expect_true(is.finite(covariance$from_sd))
    expect_true(is.finite(covariance$to_sd))
  }
})

test_that("structured q2 scale-only blocks retain guarded layouts", {
  set.seed(60622126)
  n_id <- 4L
  n_each <- 2L
  id_levels <- paste0("id", seq_len(n_id))
  site_levels <- paste0("site", seq_len(n_id))
  n <- n_id * n_each
  dat <- data.frame(
    y1 = stats::rnorm(n),
    y2 = stats::rnorm(n),
    x = stats::rnorm(n),
    z = stats::rnorm(n),
    id = rep(id_levels, each = n_each),
    site = rep(site_levels, each = n_each)
  )
  coords <- data.frame(x = seq_len(n_id), y = c(0, 1, 1, 2))
  rownames(coords) <- site_levels

  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ z + spatial(1 | ps | site, coords = coords),
        sigma2 = ~ z,
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "Partial spatial location-scale blocks"
  )

  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ z + spatial(1 | site, coords = coords),
        sigma2 = ~ z + spatial(1 | site, coords = coords),
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "scale-side q=2 blocks require an explicit covariance-block label"
  )

  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ z + spatial(1 + z | ps | site, coords = coords),
        sigma2 = ~ z + spatial(1 + z | ps | site, coords = coords),
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "scale-side q=2 blocks need matching intercept-only terms"
  )
})

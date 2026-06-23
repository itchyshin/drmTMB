test_that("structured q2 scale-only blocks reject before optimization", {
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
  K <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(id_levels, id_levels)
  Q <- solve(K)
  coords <- data.frame(x = seq_len(n_id), y = c(0, 1, 1, 2))
  rownames(coords) <- site_levels

  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ z + spatial(1 | p | site, coords = coords),
        sigma2 = ~ z + spatial(1 | p | site, coords = coords),
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
        sigma1 = ~ z + animal(1 | p | id, Ainv = Q),
        sigma2 = ~ z + animal(1 | p | id, Ainv = Q),
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "Partial animal-model location-scale blocks"
  )

  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ z + relmat(1 | p | id, Q = Q),
        sigma2 = ~ z + relmat(1 | p | id, Q = Q),
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "Partial relmat location-scale blocks"
  )
})

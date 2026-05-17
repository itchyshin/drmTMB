test_that("non-Gaussian structured effects have an explicit boundary", {
  dat_count <- data.frame(
    y = c(0, 1, 2, 3, 4, 5),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5),
    id = factor(rep(1:3, each = 2))
  )
  dat_beta <- transform(dat_count, y = c(0.1, 0.2, 0.35, 0.5, 0.7, 0.85))
  dat_ord <- transform(
    dat_count,
    y = ordered(
      c("low", "medium", "high", "low", "medium", "high"),
      levels = c("low", "medium", "high")
    )
  )
  dat_pos <- transform(dat_count, y = y + 1)

  expect_error(
    drmTMB(
      bf(y ~ x + phylo(1 | id, tree = tree)),
      family = stats::poisson(link = "log"),
      data = dat_count
    ),
    "Structured non-Gaussian paths"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + spatial(1 | id, coords = coords), sigma ~ 1),
      family = nbinom2(),
      data = dat_count
    ),
    "Structured non-Gaussian paths"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + animal(1 | id, pedigree = ped), sigma ~ 1),
      family = beta(),
      data = dat_beta
    ),
    "Structured non-Gaussian paths"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1),
      family = stats::Gamma(link = "log"),
      data = dat_pos
    ),
    "Structured non-Gaussian paths"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + phylo(1 | id, tree = tree)),
      family = cumulative_logit(),
      data = dat_ord
    ),
    "Structured non-Gaussian paths"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ animal(1 | id, pedigree = ped)),
      family = beta(),
      data = dat_beta
    ),
    "Structured non-Gaussian paths"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, nu ~ phylo(1 | id, tree = tree)),
      family = student(),
      data = dat_pos
    ),
    "Structured non-Gaussian paths"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, zi ~ spatial(1 | id, coords = coords)),
      family = stats::poisson(link = "log"),
      data = dat_count
    ),
    "Structured non-Gaussian paths"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1, hu ~ relmat(1 | id, Q = Q)),
      family = truncated_nbinom2(),
      data = dat_count
    ),
    "Structured non-Gaussian paths"
  )
})

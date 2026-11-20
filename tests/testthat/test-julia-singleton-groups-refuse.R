# #1776: engine = "julia" refuses a random-effect grouping variable whose groups
# are all singletons, with the same message native engine = "tmb" gives.

singleton_data <- function(n = 25L) {
  set.seed(3)
  x <- rnorm(n)
  data.frame(
    x = x, g = factor(seq_len(n)),
    y = .2 + .5 * x + rnorm(n),
    cnt = rpois(n, 2)
  )
}

test_that("pre-check refuses all-singleton groups and passes repeated groups (pure R)", {
  d <- singleton_data()
  f <- drmTMB::bf(y ~ x + (1 | g))
  expect_error(
    drmTMB:::drm_julia_refuse_all_singleton_groups(f, d),
    "only singleton groups"
  )
  f_sd <- drmTMB::bf(y ~ x + (1 | g), sd(g, coef = "(Intercept)") ~ 1)
  expect_error(
    drmTMB:::drm_julia_refuse_all_singleton_groups(f_sd, d),
    "only singleton groups"
  )
  d$g2 <- factor(rep(1:5, each = 5))
  expect_null(drmTMB:::drm_julia_refuse_all_singleton_groups(
    drmTMB::bf(y ~ x + (1 | g2)), d
  ))
  # one repeated group is enough (matches the native rule)
  d$g3 <- factor(c(1, 1, seq_len(23) + 1L))
  expect_null(drmTMB:::drm_julia_refuse_all_singleton_groups(
    drmTMB::bf(y ~ x + (1 | g3)), d
  ))
  expect_null(drmTMB:::drm_julia_refuse_all_singleton_groups(
    drmTMB::bf(y ~ x), d
  ))
})

test_that("Julia and TMB refuse with the same message before Julia starts (pure R)", {
  d <- singleton_data()
  fams <- list(
    gaussian = list(stats::gaussian(), drmTMB::bf(y ~ x + (1 | g))),
    poisson = list(stats::poisson(), drmTMB::bf(cnt ~ x + (1 | g)))
  )
  for (nm in names(fams)) {
    f <- fams[[nm]][[2]]
    msg_tmb <- tryCatch(
      drmTMB::drmTMB(f, family = fams[[nm]][[1]], data = d, engine = "tmb"),
      error = conditionMessage
    )
    msg_jl <- tryCatch(
      drmTMB::drmTMB(f, family = fams[[nm]][[1]], data = d, engine = "julia"),
      error = conditionMessage
    )
    expect_match(msg_tmb, "only singleton groups", info = nm)
    expect_equal(msg_jl, msg_tmb, info = nm)
  }
})

test_that("live Julia route also refuses all-singleton groups", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  d <- singleton_data()
  expect_error(
    drmTMB::drmTMB(drmTMB::bf(y ~ x + (1 | g)), family = stats::gaussian(),
                   data = d, engine = "julia"),
    "only singleton groups"
  )
})

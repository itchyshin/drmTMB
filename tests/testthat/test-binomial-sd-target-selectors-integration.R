test_that("explicit binomial intercept selectors preserve the fitted public target", {
  dat <- binomial_sd_fixture(groups = 48L, repeats = 10L,
                             seed = 2026101714L)$data
  plain <- drmTMB(bf(y ~ x + (1 | id), sd(id) ~ w), binomial(), dat)
  key <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
  selected <- drmTMB(bf(
    y ~ x + (1 | id),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w
  ), binomial(), dat)

  expect_equal(as.numeric(logLik(selected)), as.numeric(logLik(plain)),
               tolerance = 1e-5)
  expect_equal(unname(coef(selected, key)), unname(coef(plain, "sd(id)")),
               tolerance = 1e-4)
  expect_equal(unname(predict(selected, dpar = key)),
               unname(predict(plain, dpar = "sd(id)")), tolerance = 1e-4)
  expect_equal(unname(predict(selected, dpar = key,
                              newdata = data.frame(w = c(-0.5, 0, 0.5)))),
               unname(predict(plain, dpar = "sd(id)",
                              newdata = data.frame(w = c(-0.5, 0, 0.5)))),
               tolerance = 1e-4)
  expect_true(all(paste0(key, c(":(Intercept)", ":w")) %in%
                  rownames(stats::vcov(selected))))
  expect_named(selected$sdpars, key)
  expect_identical(selected$model$random_scale$mu$target_identity[[key]]$coef,
                   "(Intercept)")
  expect_equal(dim(stats::simulate(selected, nsim = 1L,
                                   seed = 2026101715L)),
               c(nrow(dat), 1L))
})

test_that("a labelled scalar intercept maps selected SD through count likelihood", {
  dat <- binomial_sd_fixture(groups = 48L, repeats = 10L,
                             seed = 2026101716L, trials = 5L)$data
  key <- 'sd(id, block = "p")'
  selected <- drmTMB(bf(
    cbind(y, failure) ~ x + (1 | p | id),
    sd(id, block = "p") ~ w
  ), binomial(), dat)
  ordinary <- drmTMB(bf(
    cbind(y, failure) ~ x + (1 | p | id)
  ), binomial(), dat)
  constant <- drmTMB(bf(
    cbind(y, failure) ~ x + (1 | p | id),
    sd(id, block = "p") ~ 1
  ), binomial(), dat)

  expect_named(coef(selected, key), c("(Intercept)", "w"))
  expect_equal(length(predict(selected, dpar = key)), nlevels(dat$id))
  expect_equal(unname(predict(selected, dpar = key)),
               unname(selected$sdpars[[key]]), tolerance = 1e-7)
  expect_true(all(paste0(key, c(":(Intercept)", ":w")) %in%
                  rownames(stats::vcov(selected))))
  expect_identical(selected$model$random_scale$mu$target_identity[[key]]$block,
                   "p")
  expect_equal(as.numeric(logLik(constant)), as.numeric(logLik(ordinary)),
               tolerance = 1e-5)
  expect_equal(unname(predict(constant, dpar = key)),
               rep(unname(ordinary$sdpars$mu[[1L]]), nlevels(dat$id)),
               tolerance = 1e-4)
})

test_that("two ordinary q1 groups retain separate selected predictions and draws", {
  set.seed(2026101717L)
  grid <- expand.grid(id = seq_len(24L), site = seq_len(8L),
                      replicate = seq_len(3L))
  grid$id <- factor(grid$id)
  grid$site <- factor(grid$site)
  grid$x <- rnorm(nrow(grid))
  grid$w <- seq(-1, 1, length.out = 24L)[as.integer(grid$id)]
  grid$v <- seq(-1, 1, length.out = 8L)[as.integer(grid$site)]
  u_id <- rnorm(24L); u_site <- rnorm(8L)
  eta <- -0.3 + 0.6 * grid$x +
    exp(log(0.8) + 0.35 * grid$w) * u_id[as.integer(grid$id)] +
    exp(log(0.5) - 0.3 * grid$v) * u_site[as.integer(grid$site)]
  grid$y <- rbinom(nrow(grid), 1L, plogis(eta))
  key <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
  fit <- drmTMB(bf(
    y ~ x + (1 | id) + (1 | site),
    sd(id, dpar = "mu", coef = "(Intercept)") ~ w,
    sd(site) ~ v
  ), binomial(), grid)

  expect_named(coef(fit), c("mu", key, "sd(site)"))
  expect_named(coef(fit, key), c("(Intercept)", "w"))
  expect_named(coef(fit, "sd(site)"), c("(Intercept)", "v"))
  expect_equal(unname(predict(fit, dpar = key)),
               unname(fit$sdpars[[key]]), tolerance = 1e-7)
  expect_equal(unname(predict(fit, dpar = "sd(site)")),
               unname(fit$sdpars[["sd(site)"]]), tolerance = 1e-7)
  expect_equal(dim(stats::simulate(fit, nsim = 1L, seed = 2026101718L)),
               c(nrow(grid), 1L))
  expect_true(all(c(paste0(key, ":w"), "sd(site):v") %in%
                  rownames(stats::vcov(fit))))
})

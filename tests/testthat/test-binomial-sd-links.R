test_that("SD regression retains each admitted binomial response link", {
  for (link in c("logit", "probit", "cloglog")) {
    sim <- binomial_sd_fixture(groups = 70L, repeats = 14L,
                               trials = 4L, link = link)
    family <- stats::binomial(link)
    fit <- drmTMB(bf(cbind(y, failure) ~ x + (1 | id), sd(id) ~ w),
                  family, sim$data)
    expect_equal(fit$opt$convergence, 0L, info = link)
    expect_true(fit$sdr$pdHess, info = link)
    expect_equal(fit$family$link, link)
    grid <- data.frame(w = c(-0.5, 0.5))
    alpha <- coef(fit, "sd(id)")
    expect_equal(unname(predict(fit, dpar = "sd(id)", newdata = grid)),
                 exp(alpha[[1L]] + alpha[[2L]] * grid$w),
                 tolerance = 1e-7, info = link)
    ordinary <- drmTMB(bf(cbind(y, failure) ~ x + (1 | id)),
                       family, sim$data)
    constant <- drmTMB(bf(cbind(y, failure) ~ x + (1 | id), sd(id) ~ 1),
                       family, sim$data)
    expect_equal(as.numeric(logLik(constant)), as.numeric(logLik(ordinary)),
                 tolerance = 1e-6, info = link)
  }
})

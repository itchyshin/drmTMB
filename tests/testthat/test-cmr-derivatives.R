test_that("CJS objective gradients agree with step-checked finite differences", {
  y <- rbind(c(1, 0, 1, 0), c(1, 1, 0, 1), c(0, 1, NA, 0), c(1, NA, 0, 1))
  observed <- !is.na(y)
  observed[4, 2] <- FALSE
  d <- cmr_data(y, id = paste0("id", 1:4), observed = observed,
                occasions = c(1, 2, 4, 5), intervals = c(1, 2.5, 1.5),
                frequency = c(1, 2, 1, 1))
  p_rows <- expand.grid(t = 1:4, i = 1:4)
  p_data <- data.frame(id = d$id[p_rows$i], occasion = d$occasions[p_rows$t],
                       x = (p_rows$i - 2.5) / 2 + p_rows$t / 10,
                       off = (p_rows$t - 2) / 20)
  p_active <- p_rows$t > d$first[p_rows$i] & p_rows$t <= d$end[p_rows$i] &
    d$observed[cbind(p_rows$i, p_rows$t)]
  p_data <- p_data[p_active, , drop = FALSE]
  f_rows <- expand.grid(t = 1:3, i = 1:4)
  phi_data <- data.frame(id = d$id[f_rows$i],
                         interval_start = d$occasions[f_rows$t],
                         interval_end = d$occasions[f_rows$t + 1L],
                         x = (f_rows$i - 2.5) / 3 + f_rows$t / 8,
                         off = (f_rows$t - 1) / 30)
  f_active <- f_rows$t >= d$first[f_rows$i] & f_rows$t < d$end[f_rows$i]
  phi_data <- phi_data[f_active, , drop = FALSE]
  fit <- drm_cjs(d, phi = ~ x + offset(off), p = ~ x + offset(off),
                 phi_data = phi_data, p_data = p_data,
                 terminal_constraint = list(phi = .75),
                 control = list(eval.max = 30, iter.max = 20))
  b <- c(.3, -.7, .2, -.4)
  ad <- fit$obj$gr(b)
  fd <- function(h) vapply(seq_along(b), function(j) {
    up <- dn <- b; up[j] <- up[j] + h; dn[j] <- dn[j] - h
    (fit$obj$fn(up) - fit$obj$fn(dn)) / (2 * h)
  }, numeric(1))
  fd1 <- fd(1e-4); fd2 <- fd(5e-5)
  expect_true(all(is.finite(ad)))
  expect_gt(max(abs(ad)), .05)
  expect_lt(max(abs(ad - fd2)), 1e-6)
  expect_lt(max(abs(fd1 - fd2)), 1e-6)

  extreme <- TMB::MakeADFun(
    data = list(model_type = 1000L, cmr_N = 1L, cmr_T = 3L,
                cmr_y = c(1L, 0L, 1L), cmr_observed = c(1L, 1L, 1L),
                cmr_first = 0L, cmr_end = 2L, cmr_delta = c(1, 2),
                cmr_frequency = 1L,
                cmr_X_phi = matrix(1, 2L, 1L), cmr_X_p = matrix(1, 3L, 1L),
                cmr_offset_phi = c(1000, -1000),
                cmr_offset_p = c(0, -1000, 1000)),
    parameters = list(beta_phi = 0, beta_p = 0), DLL = "drmTMB", silent = TRUE)
  expect_true(is.finite(extreme$fn(c(0, 0))))
  expect_true(all(is.finite(extreme$gr(c(0, 0)))))
})

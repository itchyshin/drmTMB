test_that("CJS detection SD predictors are fitted and used for integrated prediction", {
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
  on.exit(if (had_seed) {
    assign(".Random.seed", old_seed, envir = .GlobalEnv)
  } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
    rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)

  set.seed(8106)
  n <- 240L
  nt <- 5L
  id <- sprintf("bird-%03d", seq_len(n))
  z <- rep(c(-1, 1), length.out = n)
  detection_sd <- exp(-0.35 + 0.25 * z)
  detection_effect <- stats::rnorm(n, sd = detection_sd)
  p_i <- stats::plogis(stats::qlogis(0.58) + detection_effect)
  y <- matrix(0L, n, nt)
  y[, 1L] <- 1L
  for (i in seq_len(n)) {
    alive <- TRUE
    for (t in 2:nt) {
      survival <- if (t == nt) 0.82 else 0.84
      alive <- alive && stats::rbinom(1L, 1L, survival) == 1L
      y[i, t] <- if (alive) stats::rbinom(1L, 1L, p_i[[i]]) else 0L
    }
  }
  d <- cmr_data(y, id = id, occasions = seq_len(nt), units = "years")
  p_data <- data.frame(id = rep(id, each = nt),
                       occasion = rep(seq_len(nt), times = n),
                       z = rep(z, each = nt))

  fit <- drm_cjs(d, phi = ~1, p = ~1 + (1 | id), p_data = p_data,
                 sd_p = ~z, terminal_constraint = list(phi = 0.82))
  sd_coefficients <- coef(fit, process = "sd_p")
  expect_named(sd_coefficients, c("sd_p:(Intercept)", "sd_p:z"))
  expect_true(all(is.finite(sd_coefficients)))

  integrated <- predict(fit, target = "integrated")
  expect_equal(attr(integrated, "prediction")$target, "integrated")
  expect_true(all(is.finite(integrated$p$p)))
})

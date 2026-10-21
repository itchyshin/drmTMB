make_shared_year_output_case <- function(n = 240L) {
  occasions <- c(1, 2, 4, 5, 6, 7, 8)
  delta <- diff(occasions)
  nt <- length(occasions)
  ids <- paste0("year-bird", seq_len(n))
  year_levels <- paste0("year", occasions)
  phi_effect <- c(-0.95, -0.55, 0.25, 0.8, 1.05, -0.2)
  p_effect <- c(-0.8, 0.45, 0.9, -0.45, 0.65, -0.1, 0.3)
  phi_effect <- stats::setNames(phi_effect, year_levels[-nt])
  p_effect <- stats::setNames(p_effect, year_levels)

  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
  on.exit(if (had_seed) {
    assign(".Random.seed", old_seed, envir = .GlobalEnv)
  } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
    rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(20261021L)

  end <- rep.int(nt, n)
  end[seq_len(12L)] <- nt - 1L
  observed <- matrix(TRUE, n, nt)
  observed[seq(3L, n, by = 11L), 4L] <- FALSE
  y <- matrix(0L, n, nt)
  y[, 1L] <- 1L
  for (i in seq_len(n)) {
    alive <- TRUE
    for (t in 2:nt) {
      if (t > end[[i]]) next
      survival <- if (t == nt) 0.82 else
        stats::plogis(stats::qlogis(0.82) + phi_effect[[year_levels[[t - 1L]]]]) ^ delta[[t - 1L]]
      alive <- alive && stats::rbinom(1L, 1L, survival) == 1L
      detection <- if (t == nt) 0.58 else
        stats::plogis(stats::qlogis(0.58) + p_effect[[year_levels[[t]]]])
      y[i, t] <- if (alive) stats::rbinom(1L, 1L, detection) else 0L
    }
  }
  y[!observed] <- 0L

  data <- cmr_data(y, id = ids, observed = observed, occasions = occasions,
                   intervals = delta, end = end, units = "years")
  phi_rows <- expand.grid(i = seq_len(n), t = seq_len(nt - 1L))
  p_rows <- expand.grid(i = seq_len(n), t = seq_len(nt))
  phi_data <- data.frame(
    id = ids[phi_rows$i],
    interval_start = occasions[phi_rows$t],
    interval_end = occasions[phi_rows$t + 1L],
    year = factor(year_levels[phi_rows$t], levels = year_levels)
  )
  p_data <- data.frame(
    id = ids[p_rows$i], occasion = occasions[p_rows$t],
    year = factor(year_levels[p_rows$t], levels = year_levels)
  )
  list(data = data, phi_data = phi_data, p_data = p_data, occasions = occasions)
}

shared_year_logistic_moment <- function(eta, sd, power = 1) {
  stats::integrate(
    function(z) stats::plogis(eta + sd * z)^power * stats::dnorm(z),
    lower = -Inf, upper = Inf, rel.tol = 1e-11
  )$value
}

test_that("shared-year CJS prediction and simulation retain year integration", {
  case <- make_shared_year_output_case()
  fit <- drm_cjs(
    case$data, phi = ~ 1 + (1 | year), p = ~ 1 + (1 | year),
    phi_data = case$phi_data, p_data = case$p_data,
    terminal_constraint = list(p = 0.58)
  )
  testthat::expect_identical(fit$random_effects$route, "year_vector")
  testthat::expect_identical(fit$convergence, 0L)

  prediction <- predict(fit, target = "integrated")
  testthat::expect_identical(attr(prediction, "prediction")$target, "integrated")
  interval_row <- which(prediction$phi$interval_length == 2)[[1L]]
  phi_eta <- unname(fit$coefficients$phi[[1L]])
  phi_sd <- unname(fit$random_effects$sd[["phi"]])
  expected_unit <- shared_year_logistic_moment(phi_eta, phi_sd)
  expected_interval <- shared_year_logistic_moment(phi_eta, phi_sd, power = 2)
  testthat::expect_gt(phi_sd, 0.1)
  testthat::expect_equal(prediction$phi$phi_unit[[interval_row]], expected_unit,
                         tolerance = 1e-5)
  testthat::expect_equal(prediction$phi$phi_interval[[interval_row]], expected_interval,
                         tolerance = 1e-5)
  testthat::expect_gt(abs(expected_interval - expected_unit^2), 1e-4)
  occasion_row <- which(prediction$p$occasion == 2)[[1L]]
  p_eta <- unname(fit$coefficients$p[[1L]])
  p_sd <- unname(fit$random_effects$sd[["p"]])
  expected_detection <- shared_year_logistic_moment(p_eta, p_sd)
  testthat::expect_equal(prediction$p$p[[occasion_row]], expected_detection,
                         tolerance = 1e-5)

  simulations <- simulate(fit, nsim = 400L, seed = 20261022L)
  first <- simulations[[1L]]
  testthat::expect_s3_class(first, "cmr_simulation")
  testthat::expect_identical(attr(first, "simulation")$target,
                             "conditional_first_capture_marked_cohort")
  testthat::expect_identical(attr(first, "simulation")$group_draws,
                             "one_per_contributing_level_and_process_per_replicate")
  testthat::expect_identical(first$data$y[, 1L], rep.int(1L, nrow(case$data$y)))
  testthat::expect_identical(first$data$observed, case$data$observed)
  testthat::expect_identical(first$data$end, case$data$end)
  testthat::expect_true(all(first$data$y[c(1:12), ncol(first$data$y)] == 0L))

  at_second <- vapply(simulations, function(x) x$data$y[, 2L], integer(nrow(case$data$y)))
  pair_products <- vapply(seq_len(ncol(at_second)), function(j) {
    captures <- sum(at_second[, j])
    captures * (captures - 1) / (nrow(at_second) * (nrow(at_second) - 1))
  }, numeric(1))
  marginal <- mean(at_second)
  empirical_covariance <- mean(pair_products) - marginal^2
  phi_second_mean <- shared_year_logistic_moment(phi_eta, phi_sd)
  phi_second_second <- shared_year_logistic_moment(phi_eta, phi_sd, power = 2)
  p_mean <- shared_year_logistic_moment(p_eta, p_sd)
  p_second <- shared_year_logistic_moment(p_eta, p_sd, power = 2)
  expected_covariance <- phi_second_second * p_second -
    (phi_second_mean * p_mean)^2
  testthat::expect_gt(expected_covariance, 0.005)
  testthat::expect_gt(empirical_covariance, expected_covariance / 2)
})

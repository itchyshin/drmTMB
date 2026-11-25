test_that("reference-selected CJS outputs integrate both fitted process SD predictors", {
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
  on.exit(if (had_seed) {
    assign(".Random.seed", old_seed, envir = .GlobalEnv)
  } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
    rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)

  set.seed(20261017L)
  n <- 144L
  nt <- 5L
  id <- sprintf("selected-%03d", seq_len(n))
  z <- rep(c(-1, 1), length.out = n)
  sigma_phi <- exp(-0.25 + 0.28 * z)
  sigma_p <- exp(-0.50 + 0.22 * z)
  end <- sample(4:5, n, replace = TRUE)
  y <- matrix(0L, n, nt)
  first <- integer(n)
  for (i in seq_len(n)) {
    repeat {
      z_phi <- stats::rnorm(1L)
      z_p <- stats::rnorm(1L)
      candidate <- integer(nt)
      alive <- TRUE
      for (t in seq_len(end[[i]])) {
        if (t > 1L) alive <- alive && stats::rbinom(
          1L, 1L, stats::plogis(stats::qlogis(0.82) + sigma_phi[[i]] * z_phi)
        ) == 1L
        if (alive) candidate[[t]] <- stats::rbinom(
          1L, 1L, stats::plogis(stats::qlogis(0.56) + sigma_p[[i]] * z_p)
        )
      }
      captures <- which(candidate == 1L)
      if (length(captures)) {
        y[i, ] <- candidate
        first[[i]] <- captures[[1L]]
        break
      }
    }
  }

  observed <- matrix(TRUE, n, nt)
  for (i in seq_len(n)) {
    # Retain both a masked pre-capture survey and a masked post-capture zero
    # where those occasions exist. Captures themselves remain observed.
    if (first[[i]] > 2L && y[i, 2L] == 0L) observed[i, 2L] <- FALSE
    post_mask <- first[[i]] + 2L
    if (post_mask <= end[[i]] && y[i, post_mask] == 0L)
      observed[i, post_mask] <- FALSE
  }
  y[!observed] <- NA_integer_
  d <- cmr_data(y, id = id, observed = observed, occasions = seq_len(nt),
                end = end, units = "years")
  testthat::expect_identical(d$first, first)
  testthat::expect_true(any(!d$observed))
  testthat::expect_true(any(d$end < nt))

  p_rows <- expand.grid(i = seq_len(n), t = seq_len(nt))
  phi_rows <- expand.grid(i = seq_len(n), t = seq_len(nt - 1L))
  p_data <- data.frame(id = id[p_rows$i], occasion = p_rows$t,
                       z = z[p_rows$i])
  phi_data <- data.frame(id = id[phi_rows$i], interval_start = phi_rows$t,
                         interval_end = phi_rows$t + 1L, z = z[phi_rows$i])
  fit <- drm_cjs(
    d, phi = ~1 + (1 | id), p = ~1 + (1 | id),
    phi_data = phi_data, p_data = p_data,
    sd_phi = ~z, sd_p = ~z,
    selection = list(eligibility = rep(1L, n), assumption = "alive_available"),
    terminal_constraint = list(phi = 0.82)
  )

  phi_sd_coef <- coef(fit, process = "sd_phi")
  p_sd_coef <- coef(fit, process = "sd_p")
  testthat::expect_named(phi_sd_coef, c("sd_phi:(Intercept)", "sd_phi:z"))
  testthat::expect_named(p_sd_coef, c("sd_p:(Intercept)", "sd_p:z"))
  testthat::expect_true(all(is.finite(c(phi_sd_coef, p_sd_coef))))

  prediction <- predict(fit, target = "integrated")
  testthat::expect_identical(
    attr(prediction, "prediction")$target,
    "reference_selection_integrated"
  )
  target_i <- which(d$first <= 3L)[[1L]]
  target_id <- as.character(d$id[[target_i]])
  first_i <- d$first[[target_i]]
  sigma_phi_i <- exp(unname(phi_sd_coef[["sd_phi:(Intercept)"]] +
                              phi_sd_coef[["sd_phi:z"]] * z[[target_i]]))
  sigma_p_i <- exp(unname(p_sd_coef[["sd_p:(Intercept)"]] +
                            p_sd_coef[["sd_p:z"]] * z[[target_i]]))

  phi_eta <- as.numeric(fit$phi$X %*% fit$coefficients$phi + fit$phi$offset)
  p_eta <- as.numeric(fit$p$X %*% fit$coefficients$p + fit$p$offset)
  phi_hist <- which(as.character(fit$training_phi_data$id) == target_id &
                      fit$training_phi_data$interval_start < first_i)
  p_hist <- which(as.character(fit$training_p_data$id) == target_id &
                    fit$training_p_data$occasion <= first_i)
  phi_post <- which(as.character(fit$training_phi_data$id) == target_id &
                      fit$training_phi_data$interval_start == first_i)
  p_post <- which(as.character(fit$training_p_data$id) == target_id &
                    fit$training_p_data$occasion == first_i + 1L)
  testthat::expect_length(phi_post, 1L)
  testthat::expect_length(p_post, 1L)
  testthat::expect_true(d$observed[target_i, first_i + 1L])

  # Independent adaptive integration of the two factorized process laws:
  # g(u) times the pre-capture survival/detection likelihood, normalized by
  # the same process-specific selection probability.
  phi_log_selection <- function(u) sum(
    d$delta[target_i, fit$training_phi_data$interval_start[phi_hist]] *
      stats::plogis(phi_eta[phi_hist] + sigma_phi_i * u, log.p = TRUE)
  )
  p_observed <- d$observed[target_i, fit$training_p_data$occasion[p_hist]]
  p_capture <- d$y[target_i, fit$training_p_data$occasion[p_hist]]
  p_use <- which(p_observed)
  p_log_selection <- function(u) {
    eta <- p_eta[p_hist[p_use]] + sigma_p_i * u
    capture <- p_capture[p_use]
    sum(ifelse(capture == 1L, stats::plogis(eta, log.p = TRUE),
               stats::plogis(-eta, log.p = TRUE)))
  }
  weighted_mean <- function(log_selection, eta, sigma, power) {
    denominator <- stats::integrate(function(u) {
      vapply(u, function(value) exp(log_selection(value)), numeric(1)) *
        stats::dnorm(u)
    }, -9, 9, rel.tol = 1e-10, subdivisions = 500L)$value
    numerator <- stats::integrate(function(u) {
      vapply(u, function(value) exp(log_selection(value)), numeric(1)) *
        stats::dnorm(u) *
        stats::plogis(rep_len(eta, length(u)) + sigma * u)^
          rep_len(power, length(u))
    }, -9, 9, rel.tol = 1e-10, subdivisions = 500L)$value
    numerator / denominator
  }
  phi_oracle <- weighted_mean(
    phi_log_selection, phi_eta[phi_post], sigma_phi_i,
    d$delta[target_i, first_i]
  )
  p_oracle <- weighted_mean(p_log_selection, p_eta[p_post], sigma_p_i, 1)
  predicted_phi <- prediction$phi$phi_interval[
    as.character(prediction$phi$id) == target_id &
      prediction$phi$interval_start == first_i
  ]
  predicted_p <- prediction$p$p[
    as.character(prediction$p$id) == target_id &
      prediction$p$occasion == first_i + 1L
  ]
  testthat::expect_length(predicted_phi, 1L)
  testthat::expect_length(predicted_p, 1L)
  testthat::expect_equal(predicted_phi, phi_oracle, tolerance = 2e-7)
  testthat::expect_equal(predicted_p, p_oracle, tolerance = 2e-7)

  simulated <- simulate(fit, nsim = 1L, seed = 90210L,
                        max_selection_attempts = 100000L)[[1L]]
  metadata <- attr(simulated, "simulation")
  testthat::expect_s3_class(simulated, "cmr_simulation")
  testthat::expect_identical(metadata$target,
                             "reference_selection_marked_cohort")
  testthat::expect_identical(
    metadata$effects,
    "persistent_reference_normal_effects_forward_rejection_selected"
  )
  testthat::expect_identical(simulated$data$first, d$first)
  testthat::expect_identical(simulated$data$observed, d$observed)
  testthat::expect_identical(simulated$data$end, d$end)
  testthat::expect_identical(metadata$selection$eligibility, rep(1L, n))
  testthat::expect_identical(metadata$selection$assumption, "alive_available")
  for (i in seq_len(n)) {
    f <- simulated$data$first[[i]]
    testthat::expect_true(simulated$data$observed[i, f])
    testthat::expect_identical(simulated$data$y[i, f], 1L)
    if (f > 1L) {
      before <- seq_len(f - 1L)
      testthat::expect_true(all(simulated$data$y[i, before][
        simulated$data$observed[i, before]
      ] == 0L))
    }
    if (simulated$data$end[[i]] < nt) {
      after_end <- seq.int(simulated$data$end[[i]] + 1L, nt)
      testthat::expect_true(all(simulated$data$y[i, after_end] == 0L))
    }
  }
})

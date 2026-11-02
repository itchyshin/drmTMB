make_cmr_profile_endpoint_case <- function(route = c("shared", "shared_pair", "individual", "sd_predictor", "selected"),
                                           n = 160L) {
  route <- match.arg(route)
  nt <- 5L
  n_group <- 8L
  if (n %% n_group != 0L) stop("n must be divisible by eight")

  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
  on.exit(if (had_seed) {
    assign(".Random.seed", old_seed, envir = .GlobalEnv)
  } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
    rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(switch(route, shared = 8101L, shared_pair = 8105L, individual = 8102L,
                  sd_predictor = 8103L, selected = 8104L))

  id <- paste0("bird", seq_len(n))
  group <- factor(rep(seq_len(n_group), each = n / n_group))
  z <- rep(c(-1, 1), length.out = n)
  if (route == "shared") {
    phi_re <- rep(stats::rnorm(n_group, sd = 0.65), each = n / n_group)
    phi_sd <- rep(0, n)
  } else if (route == "shared_pair") {
    phi_re <- rep(stats::rnorm(n_group, sd = 0.65), each = n / n_group)
    p_re <- rep(stats::rnorm(n_group, sd = 0.38), each = n / n_group)
    phi_sd <- rep(0, n)
  } else if (route == "sd_predictor") {
    phi_sd <- exp(-0.25 + 0.5 * z)
    phi_re <- stats::rnorm(n, sd = phi_sd)
  } else if (route == "individual") {
    phi_sd <- rep(0.55, n)
    phi_re <- stats::rnorm(n, sd = phi_sd)
  } else if (route == "selected") {
    phi_sd <- rep(0.55, n)
    phi_re <- numeric(n)
  } else {
    phi_sd <- rep(0, n)
    phi_re <- rep(0, n)
  }
  phi_i <- stats::plogis(stats::qlogis(0.82) + phi_re)
  p_i <- if (route == "shared_pair") {
    stats::plogis(stats::qlogis(0.58) + p_re)
  } else rep(0.58, n)

  y <- matrix(0L, n, nt)
  if (route == "selected") {
    retained <- 0L
    while (retained < n) {
      candidate_phi <- stats::plogis(stats::qlogis(0.82) +
                                       stats::rnorm(1L, sd = 0.55))
      candidate_p <- stats::plogis(stats::qlogis(0.58) +
                                     stats::rnorm(1L, sd = 0.4))
      history <- integer(nt)
      alive <- TRUE
      for (t in seq_len(nt)) {
        if (t > 1L) {
          survival <- if (t == nt) 0.82 else candidate_phi
          alive <- alive && stats::rbinom(1L, 1L, survival) == 1L
        }
        if (alive) history[[t]] <- stats::rbinom(1L, 1L, candidate_p)
      }
      if (any(history == 1L)) {
        retained <- retained + 1L
        y[retained, ] <- history
        phi_i[[retained]] <- candidate_phi
        p_i[[retained]] <- candidate_p
      }
    }
  } else {
    y[, 1L] <- 1L
    for (i in seq_len(n)) {
      alive <- TRUE
      for (t in 2:nt) {
        survival <- if (t == nt) 0.82 else phi_i[[i]]
        alive <- alive && stats::rbinom(1L, 1L, survival) == 1L
        y[i, t] <- if (alive) stats::rbinom(1L, 1L, p_i[[i]]) else 0L
      }
    }
  }
  data <- cmr_data(y, id = id, occasions = seq_len(nt))
  p_rows <- expand.grid(t = seq_len(nt), i = seq_len(n))
  phi_rows <- expand.grid(t = seq_len(nt - 1L), i = seq_len(n))
  p_data <- data.frame(id = data$id[p_rows$i], occasion = data$occasions[p_rows$t],
                       z = z[p_rows$i], group = group[p_rows$i])
  phi_data <- data.frame(id = data$id[phi_rows$i],
                         interval_start = data$occasions[phi_rows$t],
                         interval_end = data$occasions[phi_rows$t + 1L],
                         z = z[phi_rows$i], group = group[phi_rows$i])
  list(data = data, p_data = p_data, phi_data = phi_data,
       group = group, z = z, route = route)
}

expect_cmr_profile_endpoints <- function(interval, targets) {
  testthat::expect_identical(attr(interval, "method"), "profile")
  testthat::expect_identical(rownames(interval), targets)
  for (target in targets) {
    endpoint_status <- attr(interval, "endpoint_status")[target, ]
    target_status <- attr(interval, "target_status")[[target]]
    diagnostic <- paste0(
      "target=", target,
      "; interval=", paste(interval[target, ], collapse = ","),
      "; endpoint_status=", paste(endpoint_status, collapse = ","),
      "; target_status=", target_status
    )
    testthat::expect_true(all(is.finite(interval[target, ])), info = diagnostic)
    testthat::expect_true(interval[target, "lower"] < interval[target, "upper"],
                          info = diagnostic)
    testthat::expect_true(all(unname(attr(interval, "endpoint_status")[target, ]) %in%
                                c("ok", "boundary_included")), info = target)
    testthat::expect_identical(unname(attr(interval, "target_status")[[target]]),
                               "ok", info = target)
  }
}

test_that("shared paired coefficient profiles tolerate near-root relative convergence", {
  case <- make_cmr_profile_endpoint_case("shared_pair")
  fit <- drm_cjs(case$data, phi = ~ 1 + (1 | group), p = ~ 1 + (1 | group),
                 phi_data = case$phi_data, p_data = case$p_data,
                 terminal_constraint = list(phi = 0.82))
  interval <- stats::confint(fit, parm = "p:(Intercept)", level = 0.95,
                             method = "profile")
  expect_cmr_profile_endpoints(interval, "p:(Intercept)")
})

test_that("public CJS profile endpoints are available for eligible shared effects", {
  case <- make_cmr_profile_endpoint_case("shared")
  fit <- drm_cjs(case$data, phi = ~ 1 + (1 | group), p = ~ 1,
                 phi_data = case$phi_data, terminal_constraint = list(phi = 0.82))
  pred <- predict(fit, target = "integrated")
  testthat::expect_true(all(is.finite(pred$phi$phi_unit)))
  row <- which(fit$phi_active)[[1L]]
  eta <- sum(fit$phi$X[row, ] * fit$coefficients$phi) + fit$phi$offset[[row]]
  sigma <- unname(getFromNamespace(".cmr_shared_process_sd", "drmTMB")(
    fit, "phi")[[1L]])
  oracle <- stats::integrate(function(z) stats::plogis(eta + sigma * z) *
    stats::dnorm(z), -Inf, Inf, rel.tol = 1e-10)$value
  testthat::expect_equal(pred$phi$phi_unit[[1L]], oracle, tolerance = 1e-8)
  testthat::expect_identical(attr(pred, "prediction")$target, "integrated")
  sim <- simulate(fit, nsim = 1L, seed = 8101L)[[1L]]
  testthat::expect_s3_class(sim, "cmr_simulation")
  testthat::expect_identical(attr(sim, "simulation")$effects,
                             "fresh_independent_shared_group_effects")
  testthat::expect_equal(nrow(sim$data$y), sum(case$data$frequency))
  targets <- c("phi:(Intercept)", "sd:phi")
  testthat::expect_true(targets[[1L]] %in% names(coef(fit)))
  interval <- stats::confint(fit, parm = targets, level = 0.8, method = "profile")
  expect_cmr_profile_endpoints(interval, targets)
  # At the zero-variance boundary, the profile likelihood ratio is just
  # below the prespecified 80% chi-square cutoff for this seeded cohort.
  # Represent the lower SD endpoint as the boundary, not as missing.
  testthat::expect_identical(
    unname(attr(interval, "endpoint_status")["sd:phi", "lower"]),
    "boundary_included"
  )
  testthat::expect_identical(unname(interval["sd:phi", "lower"]), 0)
  sd_diagnostic <- attr(interval, "variance_profile")[["sd:phi"]]
  testthat::expect_identical(sd_diagnostic$interval_scale, "sd")
  testthat::expect_identical(sd_diagnostic$zero_model, "not_evaluated")

  testthat::expect_error(
    stats::confint(fit, parm = "sd:phi", method = "bootstrap", nsim = 2L,
                   min_usable = 1L),
    "only with `method = \"profile\"`"
  )
})

test_that("public CJS profile endpoints retain individual integration diagnostics", {
  case <- make_cmr_profile_endpoint_case("individual")
  fit <- drm_cjs(case$data, phi = ~ 1 + (1 | id), p = ~ 1,
                 terminal_constraint = list(phi = 0.82))
  targets <- c("p:(Intercept)", "sd:phi")
  testthat::expect_identical(fit$random_effects$route, "individual_phi")
  pred <- predict(fit, target = "integrated")
  testthat::expect_true(all(is.finite(pred$phi$phi_interval)))
  testthat::expect_identical(attr(pred, "prediction")$target, "integrated")
  sim <- simulate(fit, nsim = 1L, seed = 8102L)[[1L]]
  testthat::expect_s3_class(sim, "cmr_simulation")
  testthat::expect_identical(attr(sim, "simulation")$target,
                             "conditional_first_capture_marked_cohort")
  interval <- stats::confint(fit, parm = targets, level = 0.8, method = "profile")
  expect_cmr_profile_endpoints(interval, targets)
  diagnostic <- attr(interval, "coefficient_profile")[[targets[[1L]]]]
  testthat::expect_identical(diagnostic$baseline_status, "refined")
  testthat::expect_true(length(diagnostic$attempts$baseline) > 0L)
  testthat::expect_gte(diagnostic$order_cap, 97L)
  sd_diagnostic <- attr(interval, "variance_profile")[["sd:phi"]]
  testthat::expect_identical(sd_diagnostic$zero_model, "exact_reduced_model")
  testthat::expect_identical(sd_diagnostic$quadrature_status, "exact_no_remaining_effect")
  testthat::expect_gte(sd_diagnostic$profile_max_order, 257L)
})

test_that("public CJS profile endpoints cover SD predictor coefficients", {
  case <- make_cmr_profile_endpoint_case("sd_predictor", n = 240L)
  fit <- drm_cjs(case$data, phi = ~ 1 + (1 | id), p = ~ 1,
                 phi_data = case$phi_data, sd_phi = ~ z,
                 terminal_constraint = list(phi = 0.82))
  targets <- c("phi:(Intercept)", "sd_phi:z")
  coefficient_labels <- c(names(coef(fit)), names(coef(fit, process = "sd_phi")))
  testthat::expect_true(
    all(targets %in% coefficient_labels),
    info = paste("coefficient labels:", paste(coefficient_labels, collapse = ", "))
  )
  pred <- predict(fit, target = "integrated")
  testthat::expect_true(all(is.finite(pred$phi$phi_interval)))
  sim <- simulate(fit, nsim = 1L, seed = 8103L)
  testthat::expect_s3_class(sim[[1L]], "cmr_simulation")
  testthat::expect_identical(
    attr(sim[[1L]], "simulation")$target,
    "conditional_first_capture_marked_cohort"
  )
  interval <- stats::confint(fit, parm = targets[[1L]], level = 0.8,
                             method = "profile")
  expect_cmr_profile_endpoints(interval, targets[[1L]])
  slope_interval <- stats::confint(fit, parm = targets[[2L]], level = 0.8,
                                   method = "profile")
  testthat::expect_true(all(is.na(slope_interval[targets[[2L]], ])))
  testthat::expect_identical(
    unname(attr(slope_interval, "endpoint_status")[targets[[2L]], ]),
    c("integration_unrefined", "integration_unrefined")
  )
  testthat::expect_identical(
    unname(attr(slope_interval, "target_status")[[targets[[2L]]]]),
    "unavailable"
  )
  diagnostic <- attr(slope_interval, "sd_formula_profile")[[targets[[2L]]]]
  testthat::expect_identical(diagnostic$profile_scale, "log_sd_coefficient")
  testthat::expect_identical(diagnostic$integration, "individual_gauss_hermite")
  testthat::expect_true(diagnostic$profile_evaluations >= 3L)
  testthat::expect_identical(diagnostic$profile_quadrature_status,
                             "unrefined_at_order_cap")
})

test_that("public selected CJS profile endpoints preserve selection normalization", {
  case <- make_cmr_profile_endpoint_case("selected", n = 96L)
  fit <- drm_cjs(case$data, phi = ~ 1 + (1 | id), p = ~ 1 + (1 | id),
                 selection = list(eligibility = rep(1L, nrow(case$data$y)),
                                  assumption = "alive_available"),
                 terminal_constraint = list(phi = 0.82))
  targets <- c("p:(Intercept)", "sd:phi")
  pred <- predict(fit, target = "integrated")
  testthat::expect_true(all(is.finite(pred$p$p)))
  testthat::expect_identical(attr(pred, "prediction")$target,
                             "reference_selection_integrated")
  sim <- simulate(fit, nsim = 1L, seed = 8104L,
                  max_selection_attempts = 10000L)[[1L]]
  testthat::expect_s3_class(sim, "cmr_simulation")
  testthat::expect_identical(attr(sim, "simulation")$target,
                             "reference_selection_marked_cohort")
  testthat::expect_equal(sim$data$first, case$data$first)
  interval <- stats::confint(fit, parm = targets, level = 0.8, method = "profile")
  testthat::expect_true(is.finite(interval[targets[[1L]], "lower"]))
  testthat::expect_true(is.finite(interval[targets[[1L]], "upper"]))
  testthat::expect_identical(
    unname(attr(interval, "endpoint_status")[targets[[1L]], ]),
    c("ok", "ok")
  )
  testthat::expect_identical(
    unname(attr(interval, "target_status")[[targets[[1L]]]]), "ok"
  )
  diagnostic <- attr(interval, "selection_profile")[[targets[[1L]]]]
  testthat::expect_identical(diagnostic$baseline$status, "refined")
  refined_points <- Filter(function(point) identical(point$status, "refined"),
                           diagnostic$points)
  testthat::expect_gt(length(refined_points), 0L)
  testthat::expect_true(all(vapply(refined_points, function(point) {
    isTRUE(point$selection_normalization_retained)
  }, logical(1))))
  testthat::expect_identical(diagnostic$lower$status, "available")
  testthat::expect_identical(diagnostic$upper$status, "available")
  sd_diagnostic <- attr(interval, "variance_profile")[["sd:phi"]]
  testthat::expect_true(sd_diagnostic$selection_normalization_retained)
  testthat::expect_true(sd_diagnostic$other_process_effect_retained)
  testthat::expect_true(all(is.finite(interval["sd:phi", ])))
  testthat::expect_identical(
    unname(attr(interval, "target_status")[["sd:phi"]]), "ok"
  )
  testthat::expect_true(all(
    unname(attr(interval, "endpoint_status")["sd:phi", ]) %in%
      c("ok", "boundary_included")
  ))
})

test_that("CJS profile endpoints reject unsupported shared selection", {
  case <- make_cmr_profile_endpoint_case("shared", n = 80L)
  testthat::expect_error(
    drm_cjs(case$data, phi = ~ 1 + (1 | group), p = ~ 1,
            phi_data = case$phi_data,
            selection = list(eligibility = rep(1L, nrow(case$data$y)),
                             assumption = "alive_available"),
            terminal_constraint = list(phi = 0.82)),
    "every random-effect process must use"
  )
})

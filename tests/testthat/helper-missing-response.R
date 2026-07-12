missing_response_retaped_object <- function(fit, tmb_data) {
  TMB::MakeADFun(
    data = tmb_data,
    parameters = fit$model$start,
    map = fit$model$map,
    random = fit$model$tmb_random_names,
    DLL = "drmTMB",
    silent = TRUE
  )
}

expect_missing_response_sentinel_invariant <- function(
  fit,
  response = "y",
  observed = NULL,
  sentinels
) {
  if (is.null(observed)) {
    observed_name <- paste0("observed_", response)
    observed <- fit$model$tmb_data[[observed_name]]
  }
  missing <- as.integer(observed) == 0L
  testthat::expect_true(any(missing))
  testthat::expect_length(sentinels, 2L)
  testthat::expect_false(identical(sentinels[[1L]], sentinels[[2L]]))

  data_a <- fit$model$tmb_data
  data_b <- fit$model$tmb_data
  data_a[[response]][missing] <- sentinels[[1L]]
  data_b[[response]][missing] <- sentinels[[2L]]
  testthat::expect_false(identical(
    data_a[[response]][missing],
    data_b[[response]][missing]
  ))

  obj_a <- missing_response_retaped_object(fit, data_a)
  obj_b <- missing_response_retaped_object(fit, data_b)
  par <- fit$opt$par
  testthat::expect_equal(obj_a$fn(par), obj_b$fn(par), tolerance = 1e-8)
  testthat::expect_equal(
    obj_a$gr(par),
    obj_b$gr(par),
    tolerance = 1e-8,
    ignore_attr = TRUE
  )
  opt_a <- stats::nlminb(par, obj_a$fn, obj_a$gr)
  opt_b <- stats::nlminb(par, obj_b$fn, obj_b$gr)
  testthat::expect_equal(opt_a$convergence, 0L)
  testthat::expect_equal(opt_b$convergence, 0L)
  testthat::expect_equal(
    unname(opt_a$par),
    unname(opt_b$par),
    tolerance = 1e-6
  )
  testthat::expect_equal(
    -opt_a$objective,
    -opt_b$objective,
    tolerance = 1e-6
  )
  invisible(fit)
}

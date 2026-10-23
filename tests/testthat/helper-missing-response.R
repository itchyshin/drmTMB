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

missing_response_mask_mcar_within_group <- function(
  data,
  response,
  group,
  seed,
  fraction = 0.25
) {
  set.seed(seed)
  rows <- split(seq_len(nrow(data)), data[[group]])
  missing <- unlist(lapply(rows, function(idx) {
    n_missing <- length(idx) * fraction
    if (n_missing != as.integer(n_missing)) {
      stop("Each group size must permit the requested exact missing fraction.")
    }
    sample(idx, size = as.integer(n_missing))
  }), use.names = FALSE)
  data[[response]][missing] <- NA
  data
}

missing_response_mask_mcar <- function(
  data,
  response,
  seed,
  fraction = 0.25
) {
  n_missing <- nrow(data) * fraction
  if (n_missing != as.integer(n_missing)) {
    stop("The sample size must permit the requested exact missing fraction.")
  }
  set.seed(seed)
  missing <- sample(seq_len(nrow(data)), size = as.integer(n_missing))
  data[[response]][missing] <- NA
  data
}

expect_missing_response_sentinel_invariant <- function(
  fit,
  response = "y",
  observed = NULL,
  sentinels,
  control = NULL
) {
  if (is.null(observed)) {
    observed_name <- paste0("observed_", response)
    observed <- fit$model$tmb_data[[observed_name]]
  }
  missing <- as.integer(observed) == 0L
  testthat::expect_true(any(missing))
  testthat::expect_true(length(sentinels) >= 2L)

  # Check every consecutive pair (s1,s2), (s2,s3), ... rather than only the
  # first two. By the triangle inequality, two passing consecutive-pair
  # checks at tolerance 1e-8 bound the (s1,s3) comparison to ~2e-8, so full
  # pairwise invariance follows without a combinatorial check.
  for (i in seq_len(length(sentinels) - 1L)) {
    sentinel_a <- sentinels[[i]]
    sentinel_b <- sentinels[[i + 1L]]
    testthat::expect_false(identical(sentinel_a, sentinel_b))

    data_a <- fit$model$tmb_data
    data_b <- fit$model$tmb_data
    data_a[[response]][missing] <- sentinel_a
    data_b[[response]][missing] <- sentinel_b
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
    # `control` is passed through to nlminb() so callers whose DGP class
    # needs a bigger optimizer budget than the raw nlminb defaults (e.g.
    # zero-one-beta sigma phylo/animal, see zob_sigma_control() in
    # tools/profile-fence-fixtures.R) are not starved into a spurious
    # convergence == 1. Leaving control = NULL keeps today's behaviour
    # (raw nlminb defaults) unchanged for existing callers.
    if (is.null(control)) {
      opt_a <- stats::nlminb(par, obj_a$fn, obj_a$gr)
      opt_b <- stats::nlminb(par, obj_b$fn, obj_b$gr)
    } else {
      opt_a <- stats::nlminb(par, obj_a$fn, obj_a$gr, control = control)
      opt_b <- stats::nlminb(par, obj_b$fn, obj_b$gr, control = control)
    }
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
  }
  invisible(fit)
}

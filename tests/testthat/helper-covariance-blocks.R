expect_covariance_block_tmb_data_exported <- function(fit) {
  cov_tmb <- fit$model$random$covariance_blocks$tmb_data
  cov_names <- names(cov_tmb)

  expect_true(all(cov_names %in% names(fit$model$tmb_data)))
  expect_equal(fit$model$tmb_data[cov_names], cov_tmb)
}

expect_covariance_block_tmb_data_noop <- function(fit) {
  cov_names <- names(fit$model$random$covariance_blocks$tmb_data)
  scrambled <- fit$model$tmb_data

  for (nm in setdiff(cov_names, "n_re_cov_blocks")) {
    scrambled[[nm]] <- scramble_covariance_block_tmb_value(scrambled[[nm]])
  }

  obj <- TMB::MakeADFun(
    data = scrambled,
    parameters = fit$model$start,
    map = fit$model$map,
    random = fit$model$random_names,
    DLL = "drmTMB",
    silent = TRUE
  )

  expect_equal(obj$fn(fit$opt$par), fit$obj$fn(fit$opt$par), tolerance = 1e-10)
  expect_equal(obj$gr(fit$opt$par), fit$obj$gr(fit$opt$par), tolerance = 1e-8)
}

scramble_covariance_block_tmb_value <- function(x) {
  if (is.matrix(x)) {
    out <- x
    out[] <- if (is.integer(x)) 0L else 0
    return(out)
  }
  if (is.integer(x)) {
    return(rev(x))
  }
  if (is.numeric(x)) {
    return(rev(x) * 0)
  }
  x
}

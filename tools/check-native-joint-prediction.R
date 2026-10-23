#!/usr/bin/env Rscript
# Independent mathematical replay: no fitting, no use of imputed() as oracle.
args <- commandArgs(TRUE)
if (length(args) < 1L || length(args) > 2L) stop('usage: check-native-joint-prediction.R FIT_RDS [NEW_JSON]')
if (length(args) == 2L && file.exists(args[[2L]])) stop('refusing stale receipt')
pkgload::load_all(quiet = TRUE, recompile = FALSE)
sha <- function(path) digest::digest(file = path, algo = 'sha256')
paths <- sort(list.files('R', pattern = '[.]R$', full.names = TRUE))
before <- as.list(setNames(vapply(paths, sha, ''), paths))
objects <- readRDS(args[[1L]])
stopifnot(identical(sort(names(objects)), c('bernoulli', 'gaussian')))
out <- list(scope = 'Independent conditional-mean and binary newdata replay on retained native fits; no refit or optimizer-parity claim',
  fixture_sha256 = sha(args[[1L]]), runner_sha256 = sha('tools/check-native-joint-prediction.R'),
  tolerance = 4e-6, source_before = before, cases = list())
for (kind in c('gaussian', 'bernoulli')) {
  fit <- objects[[kind]]$native
  data <- fit$data
  beta <- coef(fit, 'mu'); alpha <- coef(fit, 'mi_x')
  stopifnot(identical(names(beta), c('(Intercept)', 'z', 'mi(x)')),
    identical(names(alpha), c('(Intercept)', 'z')), nrow(data) == 160L)
  x <- if (kind == 'gaussian') data$x else as.numeric(as.character(data$x))
  eta <- unname(alpha[[1L]] + alpha[[2L]] * data$z)
  base <- unname(beta[[1L]] + beta[[2L]] * data$z)
  slope <- unname(beta[[3L]])
  sigma <- exp(coef(fit, 'sigma')[[1L]])
  missing_x <- is.na(x); observed_y <- !is.na(data$y)
  latent <- missing_x & observed_y
  if (kind == 'gaussian') {
    tau <- coef(fit, 'sigma_mi_x')[[1L]]
    conditional_x <- eta
    conditional_x[latent] <- eta[latent] + tau^2 * slope /
      (sigma^2 + slope^2 * tau^2) *
      (data$y[latent] - base[latent] - slope * eta[latent])
  } else {
    posterior_logit <- eta
    posterior_logit[latent] <- eta[latent] +
      dnorm(data$y[latent], base[latent] + slope, sigma, log = TRUE) -
      dnorm(data$y[latent], base[latent], sigma, log = TRUE)
    conditional_x <- plogis(posterior_logit)
  }
  conditional_x[!missing_x] <- x[!missing_x]
  expected <- base + slope * conditional_x
  checks <- list()
  compare <- function(label, expression, expected) {
    checks[[label]] <<- tryCatch({
      value <- force(expression)
      stopifnot(is.numeric(value), length(value) == length(expected), all(is.finite(value)))
      delta <- max(abs(value - expected), 0)
      list(status = if (delta <= out$tolerance) 'PASS' else 'FAIL', max_abs_error = delta)
    }, error = function(e) list(status = 'ERROR', message = conditionMessage(e)))
  }
  compare('training_response', predict(fit), expected)
  compare('training_link', predict(fit, type = 'link'), expected)
  compare('training_sigma', predict(fit, dpar = 'sigma'), rep(sigma, 160L))
  ids <- which(!missing_x & observed_y)[1:6]
  fresh <- data[ids, , drop = FALSE]
  compare('newdata_original', predict(fit, newdata = fresh), base[ids] + slope*x[ids])
  if (kind == 'bernoulli') {
    numeric_data <- fresh; numeric_data$x <- x[ids]
    character_data <- fresh; character_data$x <- as.character(x[ids])
    reverse_data <- fresh; reverse_data$x <- factor(x[ids], levels = c(1, 0))
    compare('newdata_numeric', predict(fit, newdata = numeric_data), base[ids] + slope*x[ids])
    compare('newdata_character', predict(fit, newdata = character_data), base[ids] + slope*x[ids])
    compare('newdata_reversed_levels', predict(fit, newdata = reverse_data), base[ids] + slope*x[ids])
  }
  out$cases[[kind]] <- list(status = if (all(vapply(checks, function(x) identical(x$status, 'PASS'), TRUE))) 'PASS' else 'FAIL',
    checks = checks, rows = 160L, observed_rows = sum(observed_y), missing_predictor_rows = which(missing_x))
}
out$source_after <- as.list(setNames(vapply(paths, sha, ''), paths))
out$source_unchanged <- identical(out$source_before, out$source_after)
out$status <- if (out$source_unchanged && all(vapply(out$cases, function(x) identical(x$status, 'PASS'), TRUE))) 'PASS' else 'FAIL'
if (length(args) == 2L) jsonlite::write_json(out, args[[2L]], pretty = TRUE, auto_unbox = TRUE, digits = 17)
for (kind in names(out$cases)) {
  cat(kind, out$cases[[kind]]$status, '\n')
  print(out$cases[[kind]]$checks)
}
cat('NATIVE_JOINT_PREDICTION_ORACLE_', out$status, '\n', sep = '')
if (out$status != 'PASS') quit(status = 1L)

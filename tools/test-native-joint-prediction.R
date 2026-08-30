#!/usr/bin/env Rscript
# Damage retained model state, not the oracle, to establish sensitivity.
args <- commandArgs(TRUE)
if (length(args) != 1L) stop('usage: test-native-joint-prediction.R FIT_RDS')
for (e in parse('tools/check-native-joint-prediction-neighbours.R')) {
  if (is.call(e) && identical(e[[1L]], as.name('<-')) && identical(e[[2L]], as.name('native_prediction_delta'))) eval(e)
}
stopifnot(native_prediction_delta(c(1, 2), c(1, 2)) == 0)
output_damages <- list(
  list(NULL, c(1, 2)), list(1, c(1, 2)), list(c(1, 2, 3), c(1, 2)),
  list(c(1, NA_real_), c(1, 2)), list(c(1, Inf), c(1, 2)),
  list(c('1','2'), c(1, 2)), list(numeric(0), numeric(0)),
  list(c(1, 2), c(1, NA_real_)), list(matrix(c(1, 2)), c(1, 2)),
  list(c(1, 2), matrix(c(1, 2)))
)
for (values in output_damages) stopifnot(inherits(try(do.call(native_prediction_delta, values), silent = TRUE), 'try-error'))
fixture <- normalizePath(args[[1L]], mustWork = TRUE)
runner <- normalizePath('tools/check-native-joint-prediction.R', mustWork = TRUE)
work <- tempfile('joint-prediction-damage-'); dir.create(work)
original <- readRDS(fixture)
run <- function(path, name) {
  logfile <- file.path(work, paste0(name, '.log'))
  code <- system2(file.path(R.home('bin'), 'Rscript'), c(shQuote(runner), shQuote(path)), stdout = logfile, stderr = logfile)
  output <- readLines(logfile, warn = FALSE)
  list(code = code, output = output)
}
base <- run(fixture, 'baseline')
stopifnot(base$code == 0L, any(grepl('^NATIVE_JOINT_PREDICTION_ORACLE_PASS$', base$output)))
damages <- list(
  gaussian_training_design = function(x) {
    x$gaussian$native$model$X$mu[, 'z'] <- x$gaussian$native$model$X$mu[, 'z'] + 1
    x
  },
  gaussian_conditional_value = function(x) {
    x$gaussian$native$missing_data$predictors$x$value[[2L]] <- x$gaussian$native$missing_data$predictors$x$value[[2L]] + 1
    x
  },
  bernoulli_conditional_value = function(x) {
    x$bernoulli$native$missing_data$predictors$x$value[[2L]] <- 0
    x
  },
  bernoulli_level_mapping = function(x) {
    x$bernoulli$native$missing_data$predictors$x$levels <- rev(x$bernoulli$native$missing_data$predictors$x$levels)
    x$bernoulli$native$model$missing_predictor$levels <- rev(x$bernoulli$native$model$missing_predictor$levels)
    x
  }
)
for (name in names(damages)) {
  path <- file.path(work, paste0(name, '.rds'))
  saveRDS(damages[[name]](original), path)
  answer <- run(path, name)
  if (answer$code == 0L || !any(grepl('^NATIVE_JOINT_PREDICTION_ORACLE_FAIL$', answer$output))) {
    stop('Damage was not rejected by the prediction oracle: ', name, '; log=', work)
  }
}
cat('NATIVE_JOINT_PREDICTION_DAMAGES_PASS mutations=', length(damages) + length(output_damages), '\n', sep = '')
cat('Temporary damage evidence: ', work, '\n', sep = '')

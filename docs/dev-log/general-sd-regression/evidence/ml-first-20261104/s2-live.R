library(testthat)
pkgload::load_all(compile=FALSE, quiet=TRUE)
exprs <- parse('tests/testthat/test-julia-b34-structured-fitted-bridge.R')
for (e in exprs) if (is.call(e) && identical(e[[1]], as.name('<-')) && as.character(e[[2]]) %in% c('b34_fixture','b34_formula','b34_family')) eval(e)
for (fam in c('gaussian','poisson','nbinom2','gamma','binomial')) {
  cat('START', fam, format(Sys.time()), '\n'); flush.console()
  fx <- b34_fixture(fam, 'relmat', FALSE, 20261340L)
  K <- fx$K
  form <- b34_formula('relmat', FALSE, K, NULL, NULL)
  fit <- drmTMB(form, family=b34_family(fam), data=fx$dat, engine='julia')
  eta <- as.numeric(model.matrix(~x, fx$dat) %*% coef(fit)$mu) + fit$conditional_structured$eta_re
  expect_equal(as.numeric(predict(fit, dpar='mu', type='link')), eta, tolerance=1e-8)
  expect_equal(as.numeric(predict(fit, dpar='mu')), as.numeric(fitted(fit)), tolerance=1e-8)
  expect_gt(max(abs(fitted(fit)-fit$fitted)), 1e-2)
  cat('PASS', fam, format(Sys.time()), '\n'); flush.console()
}
cat('S2_LIVE_PASS\n')

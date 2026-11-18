devtools::load_all('.',quiet=TRUE)
exprs <- parse('tests/testthat/test-beta-animal-q2-sd-regression.R')
for (expr in exprs) if (is.call(expr) && identical(expr[[1L]],as.name('<-'))) eval(expr,.GlobalEnv)
fx <- beta_animal_q2_sd_fixture(groups=12L,repeats=8L)
(function() {
 testthat::local_mocked_bindings(
  drm_julia_setup=function(...)stop('UNEXPECTED_JULIA_SETUP'),.package='drmTMB')
 message <- tryCatch({drmTMB(beta_animal_q2_sd_form(fx$A),family=beta_family(),
  data=fx$data,engine='julia');'UNEXPECTED_FIT'},error=function(e)conditionMessage(e))
 cat(message,'\n')
 stopifnot(!grepl('UNEXPECTED',message),grepl('slope',message,ignore.case=TRUE))
 cat('JULIA_REFUSAL_BEFORE_SETUP_PASS\n')
})()

.libPaths(c('/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b/r-final-lib',.libPaths()))
library(drmTMB,lib.loc='/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b/r-final-lib')
root<-'/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b/r-final-src'
for (f in c('test-fixed-effect-priors.R','test-fixed-priors-workflow.R')) {
 cat('TEST_FILE ',f,'\n')
 testthat::test_file(file.path(root,'tests','testthat',f),reporter='summary',stop_on_failure=TRUE,env=new.env(parent=asNamespace('drmTMB')))
}
cat('R_PRIOR_ORACLES_PASS\n')

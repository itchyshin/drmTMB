.libPaths(c('/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b/r-final-lib',.libPaths()))
library(drmTMB,lib.loc='/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b/r-final-lib')
root<-'/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b/r-final-src'
cat('SOURCE ',root,'\nLOADED ',find.package('drmTMB'),'\n')
t<-system.time(r<-testthat::test_local(root,load_package='installed',reporter='summary',stop_on_failure=TRUE))
saveRDS(r,'/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b/evidence/r-final-full-results.rds')
cat('ELAPSED_SECONDS ',t[['elapsed']],'\nR_FULL_SUITE_PASS\n')

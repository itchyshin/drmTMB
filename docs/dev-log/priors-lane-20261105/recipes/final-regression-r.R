.libPaths(c('/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b/r-final-lib',.libPaths()))
library(drmTMB,lib.loc='/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b/r-final-lib')
root<-'/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b/r-final-src'
filter<-'^(fixed-effect-priors|fixed-priors-workflow|gaussian-location-scale|binomial-response|binomial-links|objective-at|model-comparison|phylo-penalty-spec|optimizer-contract|predict-parameters)$'
t<-system.time(r<-testthat::test_local(root,filter=filter,load_package='installed',reporter='summary',stop_on_failure=TRUE))
cat('ELAPSED_SECONDS ',t[['elapsed']],'\nR_AFFECTED_REGRESSIONS_PASS\n')

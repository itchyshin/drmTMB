.libPaths(c('/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b/r-final-lib',.libPaths()))
library(drmTMB,lib.loc='/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b/r-final-lib')
knitr::knit('/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b/r-final-src/vignettes/articles/fixed-effect-priors.Rmd',output='/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b/evidence/fixed-effect-priors.md',quiet=TRUE)
cat('PRIOR_ARTICLE_EXECUTION_PASS\n')

started <- proc.time()[['elapsed']]
r <- devtools::test(filter='beta-relmat-q2-sd-regression|beta-animal-q2-sd-regression|beta-animal-pedigree-q2-sd-regression|beta-animal-pedigree-sd-regression|^beta-sd-regression$|gamma-relmat-q2-sd-regression|nongaussian-structured-mu-slope',reporter='summary',stop_on_failure=FALSE)
d <- as.data.frame(r)
cat('TOTAL_PASSED',sum(d$passed),'FAILED',sum(d$failed),'ERRORS',sum(d$error),'WARNINGS',sum(d$warning),'SKIPPED',sum(d$skipped),'SECONDS',proc.time()[['elapsed']]-started,'\n')
if(any(d$failed>0|d$error)) quit(status=1)

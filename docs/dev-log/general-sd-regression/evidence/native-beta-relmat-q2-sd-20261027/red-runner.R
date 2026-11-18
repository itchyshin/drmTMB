started <- proc.time()[['elapsed']]
r <- devtools::test(filter='^beta-relmat-q2-sd-regression$', reporter='summary', stop_on_failure=FALSE)
d <- as.data.frame(r)
cat('PASSED',sum(d$passed),'FAILED',sum(d$failed),'ERRORS',sum(d$error),'SECONDS',proc.time()[['elapsed']]-started,'\n')

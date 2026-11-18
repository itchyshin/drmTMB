started <- proc.time()[['elapsed']]
r <- devtools::test(filter = 'beta-animal-q2-sd-regression|beta-animal-pedigree-sd-regression|^beta-sd-regression$|nongaussian-structured-mu-slope|gamma-relmat-q2-sd-regression',
  reporter = 'summary', stop_on_failure = TRUE)
d <- as.data.frame(r)
cat('FINAL_TOTAL_PASSED',sum(d$passed),'FAILED',sum(d$failed),'ERRORS',sum(d$error),
 'WARNINGS',sum(d$warning),'SKIPPED',sum(d$skipped),
 'ELAPSED_SECONDS',proc.time()[['elapsed']]-started,'\n')

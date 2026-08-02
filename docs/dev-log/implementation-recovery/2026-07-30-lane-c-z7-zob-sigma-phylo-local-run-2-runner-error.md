# Lane C Z7 runner-error record — second invocation

The second invocation corrected the missing `tree` scope but stopped while
assembling the first record: it attempted `abs(fit$report$log_sigma)`, whereas
this fitted object exposes reports through `fit$obj$report()`. It produced no
`raw-attempts.tsv`; therefore it is not recovery evidence and no result is
inferred from it.

Run 3 changed only that report access and reran the entire predeclared seed set
from scratch. This is a runner-repair record, not a DGP, threshold, or model
change.

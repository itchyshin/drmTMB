# Z3 local runner history

This directory's retained recovery evidence is the run made after the runner
was committed. The two earlier invocations did not reach a fitted candidate and
are retained here solely as runner provenance.

| Attempt | Runner defect | Result | Evidence role |
|---|---|---|---|
| 1 | Passed optimizer controls directly to `drm_control()` | All four calls aborted before a fit | Not a recovery attempt |
| 2 | Passed `se` in the optimizer control list | All four calls aborted before a fit | Not a recovery attempt |
| 3 | Looked for `ranef` in the fitted object instead of via the method | First successful fit stopped while recording its mode correlation | Not a recovery attempt |

The corrected runner uses `drm_control(optimizer = ...)`, `ranef(fit, "sigma")`,
and `fit$obj$report()`. Its final all-attempt output is regenerated after the
implementation commit so source SHA and runner checksum authenticate the tested
code.

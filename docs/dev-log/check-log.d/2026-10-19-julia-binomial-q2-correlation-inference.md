## Julia Bernoulli q2 correlation inference plumbing

Added a public response-scale profile target for the ordinary Bernoulli
intercept-slope working correlation, mapped to the existing Julia `recov`
coordinate. The R bridge now dispatches profile and bootstrap intervals through
the existing generic Julia inference selector and transforms the limits back to
the guarded correlation scale. The target remains outside the fixed-effect
`coef()` and `vcov()` contract; Wald intervals remain unavailable.

`Rscript --vanilla -e 'devtools::test(filter = "julia-binomial-sd", reporter = "summary")'`
passed the mocked/source-level tests (the five Julia live tests were skipped in
this invocation because the engine paths were not set).

The live cross-engine test was run with the paired candidate Julia project,
`DRMTMB_JULIA_TESTS=true`, one Julia thread and BLAS/OpenMP caps of one. The
focused `correlated Bernoulli q2 SD point and outputs compare across engines`
test passed, including profile target discovery, one profile interval and a
five-refit bootstrap interval. This checks route plumbing only; five bootstrap
refits do not establish interval calibration. A first run exposed that the
target helper read the Julia-ready bridge formula instead of the fitted R
formula; after correcting that and fixing a test assertion that passed a data
frame to `is.finite()`, the live test passed.

No Julia source change was needed. No issue or PR was changed. The separate
DRM.jl CMR lane was sent a coordination update; it remains active and has not
yet replied about overlap. The larger general-SD goal remains active, with
calibration and the full capability inventory still open.

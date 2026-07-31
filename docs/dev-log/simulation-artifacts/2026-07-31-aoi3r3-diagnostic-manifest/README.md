# AOI-3R3 fresh diagnostic-smoke manifest

Status: **FROZEN FOR THE OWNER-AUTHORIZED LOCAL R3 SMOKE ONLY.**

This manifest replaces neither AOI-3R1's invalid retained output nor AOI-3R2's
incomplete retained directory.  It allocates 15 outer and 45 scheduled inner
attempts across the five fixed-effect Bernoulli x ordinary-NB2 formula classes
at `n = 720`.  Its 60 seeds are unique and disjoint from both earlier AOI-3R
manifests.

The computational source is commit
`f787599a705e8f2653391adda148155d888bc956`; the runner SHA-256 at that commit is
`9ccdc56baa4698d1fbc3110d481aef179eb805c066b344cb72f47dc15690cdea`.
That repair retains `run-startup.csv`, durable `runner-events.csv`, and atomic
outer/inner/covariance checkpoints after every outer attempt.  An absent
`run_complete` event therefore records an incomplete run rather than an
unclassifiable empty directory.

Before invocation, verify the frozen code surface:

```sh
git diff --quiet f787599a705e8f2653391adda148155d888bc956 -- \
  R src DESCRIPTION NAMESPACE tools/run-aoi3-bernoulli-nb2-full-refit.R
```

Use a fresh immutable result root and set
`AOI3_SOURCE_SHA=f787599a705e8f2653391adda148155d888bc956`.  This authorization
does not permit a DRAC submission, covariance/coverage calibration, public
uncertainty API, `vcov()`, `confint()`, standard errors, or capability claim.

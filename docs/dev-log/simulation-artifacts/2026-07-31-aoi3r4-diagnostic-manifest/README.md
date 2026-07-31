# AOI-3R4 fresh diagnostic-smoke manifest

Status: **FROZEN FOR THE OWNER-AUTHORIZED SUPERVISED LOCAL R4 SMOKE ONLY.**

This manifest allocates 15 outer and 45 scheduled inner attempts across the
five fixed-effect Bernoulli x ordinary-NB2 formula classes at `n = 720`.  Its
60 seeds are unique and disjoint from R1, R2, and R3.  The computational source
is `f787599a705e8f2653391adda148155d888bc956` (runner SHA-256
`9ccdc56baa4698d1fbc3110d481aef179eb805c066b344cb72f47dc15690cdea`).

The R4 command must run in a live interactive terminal session and be polled
through that session until it emits all five formula-complete lines and creates
the top-level `COMPLETE` marker.  The per-shard runner retains startup, event,
and atomic outer checkpoints, so termination before `run_complete` remains
operationally explicit.

Before invocation, require:

```sh
git diff --quiet f787599a705e8f2653391adda148155d888bc956 -- \
  R src DESCRIPTION NAMESPACE tools/run-aoi3-bernoulli-nb2-full-refit.R
```

Use a fresh immutable result root and set the matching `AOI3_SOURCE_SHA`.  This
authorization does not permit DRAC, uncertainty calibration, `vcov()`,
`confint()`, standard errors, capability promotion, or public inference.

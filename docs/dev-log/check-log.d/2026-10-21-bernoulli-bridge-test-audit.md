# Check log: Bernoulli bridge test audit (2026-10-21)

- Broad `binomial.*sd` sweep reached testthat’s 10-failure stop: 9 live bridge calls could not locate Julia on PATH and 1 stale expected-error message failed. Native tests displayed no failures before the bridge errors; the run has no complete denominator.
- Retried Julia 1.10.0 with juliaup on PATH. JuliaCall setup exceeded the three-minute estimate with stale RCall pidfile warnings; only this task's R process was terminated, status 143, before tests began.
- Corrected the negative test to assert the current `structured combinations` guidance for unsupported Student structured terms.
- Focused animal bridge test with live Julia disabled: 14 checks passed, 0 failed, 1 live fit skipped.
- Full detail: `docs/dev-log/after-task/2026-10-21-bernoulli-bridge-test-audit.md`.

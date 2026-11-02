## Bernoulli 97.5% profile-range repair

The current-source Totoro timing capsule completed 45 timing-only fits but
returned 0 valid 97.5% intervals. Its retained one-seed curve stopped at a
2.029 negative-log-likelihood rise, below the 2.512 cutoff. TMB 1.9.25's
default `ytol = 2` caused the truncation. The native R/TMB profile path now
sets `ytol` to `max(2, cutoff + 0.5)` when it is omitted, for
both `confint()` and `profile()`. This gives the search more room to reach the
cutoff; optimizer or iteration failures can still prevent endpoint finding.
Explicit values remain in force.

The Bernoulli profile test fails at 97.5% before the change and passes after it:
20 expectations passed, including finite interval endpoints, explicit `ytol =
2` behavior and its `nonfinite_interval` message, and a full curve that reaches the requested deviance cutoff. `devtools::test(filter =
"profile-targets")` passed 1,034 expectations with 0 failures, 2 expected
Julia-engine skips, and 6 existing deprecation warnings. `devtools::document()`
updated `confint.drmTMB.Rd` and `profile.drmTMB.Rd`.

A post-fix Totoro smoke reused the same frozen synthetic seed and the already
source-pinned 0.7.1/TMB 1.9.25 installation, loading only the patched R profile
functions. It returned the finite 97.5% interval [-1.078105, -0.2688165], with
profile status `profile`, `ytol = 3.011943`, and maximum deviance 6.12987 above
the 5.023886 cutoff. Fit convergence was 0 and `pdHess` was true. The smoke took
0.510 seconds to fit, 8.607 seconds for the interval, and 8.571 seconds for the
full curve. This validates one profile route on one seed; it is not recovery or
interval-calibration evidence.

The pre-fix and post-fix 45-row timing receipts and one-seed raw pre-fix trace are retained under
`docs/dev-log/general-sd-regression/evidence/calibration-20261017/profile-range-debug-0975-current-source-v2/`.
The post-fix capsule records 45 valid intervals, no failures or boundaries, and
no warnings or launch errors. Its registry digest is
`674a924c2e86d134eecdbaf8f55883a0be14e3be15f334719c130d2dfcfefaf4`. The
pinned worker hash matches the archived worker with the overlay activation
sequence, and the pinned `R/profile.R` hash matches current source. The
supervisor verifies registry integrity; each worker rechecks source hashes,
loads the pinned profile definitions, replaces the namespace bindings, and
registers the S3 method before fitting. Independent inference review confirmed
this chain with no material activation gap. At 16 workers, the supervisor took
31.357 seconds, supporting a preliminary 34.8-minute projection for 3,000
comparable fits. This is timing evidence, not calibration evidence. All 234
files copied from the earlier capsule matched a fresh Totoro SHA-256 manifest. The prior 98 to
127 minute projection came from an older 95% worker/source and cannot estimate
the corrected 97.5% route.

Consistency search run:

```sh
rg -n "ytol|97\\.5%|profile range|profile cutoff" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/18-random-effect-scale-models.md vignettes/formula-grammar.Rmd _pkgdown.yml
```

The development NEWS and both profile help pages describe the level-aware
default and explicit-control behavior. Formula grammar, family support,
roadmap, and pkgdown navigation need no change. GitHub search for
`repo:itchyshin/drmTMB profile interval ytol` found no open issue; none was
created or changed. The D-93 coverage hold and programme gates G2/G5 remain
open. A whole-package `R CMD build` attempt was interrupted after its source
copy stalled in the shared dirty worktree; no package check or calibration run
was claimed from that attempt.

Report: `docs/dev-log/after-task/2026-10-19-bernoulli-profile-range-0975.md`.

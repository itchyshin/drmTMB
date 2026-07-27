# After Task: Arc D Design 1 fail-closed SD overflow guard

## 1. Goal

Implement Shinichi's approved Design 1 only: an internal overflow-only guard
for the nine C++ and two R regression-predicted `sd()` log-scale evaluations,
without allowing a guard boundary to become a finite profile endpoint.

## 2. Implemented

Added `drm_exp_sd_logscale_guarded()` in C++ and R. It is identical to `exp()`
through `eta <= 700`; above that, the C++ objective is made non-finite after
the safe evaluation, so the pre-existing profile failure route returns missing
endpoints. A private report field records guard contact for tests. No public
control, status value, or output contract was added.

## 3a. Decisions and Rejected Alternatives

Implemented approved Design 1 with Fisher's fail-closed refinement. Reusing the
residual `logsigma_clamp` is still rejected because it manufactured a finite
K=12 endpoint. Design 2 (`clamp_limited`) remains deferred because its endpoint
tracing and status-consumer contract are wider work. Design 3 remains rejected:
the fitted and profiled objectives would differ.

## 4. Files Touched

- `src/drmTMB.cpp`
- `R/drmTMB.R`
- `tests/testthat/test-arc-d-sd-overflow-guard.R`
- `docs/design/247-arc-d-clamp-profile-contract-d1.md`
- `docs/dev-log/after-task/2026-07-26-arc-d-design1-overflow-guard.md`

## 5. Checks Run

- `R CMD INSTALL --preclean .` completed successfully (compiler warnings were
  pre-existing unused `sigma_i` locals).
- `devtools::test(filter = "^(arc-d-sd-overflow-guard|phase18-meta-v-lss-runner|gaussian-random-effect-scale|gradient-conformance)$")` passed: 182 expectations, 0 failures, 0 warnings, 0 skips.
- `R CMD check --no-manual --as-cran .` stopped before package tests because this
  local R 4.6 check requires legacy `Author` and `Maintainer` DESCRIPTION fields;
  it reported that metadata error before testing this change.

## 6. Tests of the Tests

The new regression test directly sets a modelled-SD slope high enough for one
group predictor to exceed 700. It observes a non-finite C++ objective, positive
guard-contact report, and the existing `profile_failed` interpretation for a
non-finite interval. It also checks ordinary C++/R agreement. The retained K=12
test independently proves the original false-precision failure remains visible.

## 7a. Issue Ledger

No issue was opened, closed, or commented on. The existing Arc D decision
record, design 247, is the authoritative internal ledger; B1 PR #855 and the
association PR #854 were intentionally not touched.

## 8. Consistency Audit

Searched `README.md`, `ROADMAP.md`, `NEWS.md`,
`docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`,
`vignettes/formula-grammar.Rmd`, and `_pkgdown.yml` with
`rg -n -i 'sd\\(|log.?sd|overflow|clamp|interval_status|profile_failed'`.
No public wording changed because this is a private numerical safety repair.
The nine C++ sites and both R re-derivation surfaces were enumerated before
editing. The TMB likelihood review confirmed the positive log-scale transform,
ordinary AD/FD gradients, and boundary path were covered.

## 9. What Did Not Go Smoothly

The initial focused test passed `obj$par` to `obj$report()`, which is invalid
for a Laplace model because `report()` needs the full parameter state. The test
now supplies the stored full state with fixed parameters replaced. The local
`R CMD check` metadata gate also prevents a package-check verdict in this R
installation.

## 10. Known Residuals

This establishes no empirical reachability of `eta > 700`, no stability gain,
and no inference calibration. The guard uses an internal report field only; it
does not add user-facing diagnostics. Design 2's endpoint-specific
`clamp_limited` contract remains unimplemented. The full `R CMD check` result
is unavailable until the local DESCRIPTION metadata environment is resolved.

## 11. Team Learning

Recall and routing shaped this task: the Lane B handover, D0/D1 design record,
and prior F5 false-precision result were read before implementation; the
cross-repo sweep found no reusable counterpart. The TMB likelihood-review and
after-task-audit skills made the fail-closed objective and retained K=12
sentinel explicit. No LOAD-FIRST manifest existed for this worktree, and no
new hub guard is proposed. The Golden Set was not applicable: this is a narrow
internal numerical repair, not a memory-regression campaign.

## 12. Cross-Product Coverage

The overflow guard covers ✓ the nine C++ direct-SD exponentiation sites and the
two R group-SD re-derivations, including ordinary Gaussian SD regression,
gradient conformance, and the K=12 profile sentinel. It does NOT cover residual
`log(sigma)` clamps, Design 2 status plumbing, bootstrap, association,
missing-response, capability-ledger transitions, coverage/recovery campaigns,
public documentation, or a claim that overflow occurs in a realistic fit.

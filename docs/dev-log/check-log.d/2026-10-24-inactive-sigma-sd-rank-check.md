# Check Log: Inactive sigma SD design in fixed-effect rank checks

## Source state

- Repository candidate: `codex/general-sd-regression`.
- `R/check.R` SHA-256: `0c4acbf8c48c5f03b8d869140dd428d4d56670a24097b7610b4558eeae12e1cf`.
- `tests/testthat/test-check-fixed-effect-rank.R` SHA-256: `c1f2456deeccaa5483749e7d1d13dbb4be779b14f51d48cacdb6ee1557f7b7ac`.

## Command and result

```sh
Rscript -e 'devtools::test(filter = "check-fixed-effect-rank", reporter = "summary", stop_on_failure = TRUE)'
```

Exit code 0. Testthat reported six expectations, no failures, warnings, or
skips.

## Other checks

- `git diff --check -- R/check.R tests/testthat/test-check-fixed-effect-rank.R R/julia-bridge.R tests/testthat/test-julia-binomial-animal-iid-sd-parity.R`: passed.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-10-24-inactive-sigma-sd-rank-check.md`: report structure passed. The checker found 13 acceptance-ledger files but could not run the ledger because its node or gate-check was missing; gate state is unknown.
- `python3 /Users/z3437171/shinichi-brain/tools/slop_check.py <absolute report path>`: zero findings.
- The focused test first failed on the inactive sigma design before the implementation change; the final test uses the actual beta-binomial spec builder and retains an active-design rank-deficiency assertion.
- GitHub search found the related but distinct open issue #1470; no issue action was taken.
- No likelihood, public API, formula grammar, examples, or pkgdown navigation changed.

Both rank-check call sites now use the shared internal `drm_twin_rank_tol`
constant, preserving the `1e-8` threshold after review of active temporal-rank
refs.

Scope: fixes rank diagnostics for an inactive random-effect scale endpoint only.
This is not evidence of broad SD-regression support or calibrated intervals.

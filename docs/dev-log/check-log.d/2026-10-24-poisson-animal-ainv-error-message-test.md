# Check Log: Poisson animal Ainv bridge expectation

## Source state

- Repository: `drmTMB` candidate worktree, branch `codex/general-sd-regression`.
- Updated test SHA-256: `2359553fdfbe39340562ae5feaab9fb45f55a590ad1122a521c9ffcaaf7328c2`.
- Bridge source SHA-256: `25551cecd5cde337627bb2fff466a905cf565b0443294a9d0bc1b1fcd6c7e03c`.

## Command and result

```sh
PATH='/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin:/Users/z3437171/.juliaup/bin:'"$PATH" \
JULIA_HOME='/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin' \
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' \
Rscript -e 'devtools::test(filter = "julia-poisson-animal-ainv-sd-parity", reporter = "summary", stop_on_failure = TRUE)'
```

Exit code: 0. One live Julia bridge test ran and passed. Julia 1.10.0 was
loaded through JuliaCall.

## Other checks

- `git diff --check -- tests/testthat/test-julia-poisson-animal-ainv-sd-parity.R`: passed.
- `rg -n "only for a Poisson animal-intercept SD model" tests R docs`: no matches.
- `gh issue list --state open --search 'Poisson animal Ainv SD regression' --json number,title,url --limit 10`: no matching open issues.
- `tools/check-after-task.R`: after-task structure passed; wider acceptance
  ledger was reported as not runnable, so gate state is unknown.
- `tools/slop_check.py` on the after-task report: 0 findings.

Scope: synchronized one stale expected message with the existing bridge guard.
No runtime implementation changed; this does not close a general-SD gate.

# After Task: Q-Series q1 Sigma Endpoint Zero-Boundary Profile Review

## Goal

Harden and review the animal and relmat q1 `sigma` intercept profile route
after the SR150 raw-Wald pregrid showed finite-interval censoring and
warning-heavy replicates.

## Implemented

This promotes exactly no Q-Series row. It adds a route-review sidecar showing
the full progression: endpoint profiles with budget 48 partially rescued the
selected failures, the endpoint zero-boundary patch rescued the remaining hard
seed, and local SR1000 profile-channel evidence reached 1000/1000 finite
profiles for both rows. The SR1000 profile coverage is 0.9430 with MCSE
0.007332, but misses remain upper-tail heavy (lower=12, upper=45), so the
route is now blocked for promotion and top-up by Fisher/Gauss/Rose.

## Mathematical Contract

The reviewed estimand remains the direct structured SD target on the `sigma`
axis for `animal(1 | id, A = A)` and `relmat(1 | id, K = K)`. The current raw
log-SD Wald route uses `small_sample_df = "none"` and `bias_correct = "none"`;
the profile-channel evidence uses endpoint likelihood profiles. For positive
SD targets, the hardened endpoint rule treats the lower side as the
response-scale zero boundary once the profiled log-SD value has reached
numerical zero and the likelihood-ratio distance is still below the cutoff.
This avoids chasing a spurious finite lower root below an already near-zero SD
estimate. The `tmbprofile` replay remains diagnostic only and negative for this
slice.

## Files Changed

- `tools/run-structured-re-gaussian-lowq-sigma-intercept-smoke.R` now accepts
  `--profile-engine=endpoint|tmbprofile` and records the actual profile
  channel, profile coverage, profile MCSE inputs, and one-sided misses in
  replay artifacts.
- `R/profile.R` now has the endpoint zero-boundary lower-side guard for
  positive SD targets.
- `tools/summarize-structured-re-gaussian-lowq-sigma-profile-route-review.R`
  creates `structured-re-gaussian-lowq-sigma-profile-route-review.tsv` from
  the original SR150 pregrid, selected endpoint/tmbprofile replays, patched
  SR150 replay, and patched SR1000 shards. It synchronizes the 104-row board,
  low-q audit, row-selection gate, queue, closure triage, row-selection
  artifact mirror, and dashboard version.
- `tools/validate-mission-control.py` validates the new two-row sidecar and
  the updated q1 `sigma` animal/relmat blocker state.
- `docs/dev-log/dashboard/index.html`, `README.md`, dashboard TSVs, and the
  focused conversion-contract test now expose the route review.

## Checks Run

- Endpoint replay, no dashboard write:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-gaussian-lowq-sigma-intercept-smoke.R --providers=animal,relmat --n-rep=5 --seed-start=8 --seed-base=914000 --profile=true --profile-engine=endpoint --profile-endpoint-max-eval=48 --host-class=local_adaptive_profile_replay --host-name=local --output-dir=docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-adaptive-profile-smoke-local --write-dashboard=false --overwrite=true`.
- `tmbprofile` replay, no dashboard write:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-gaussian-lowq-sigma-intercept-smoke.R --providers=animal,relmat --n-rep=5 --seed-start=8 --seed-base=914000 --profile=true --profile-engine=tmbprofile --host-class=local_tmbprofile_replay --host-name=local --output-dir=docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-tmbprofile-smoke-local --write-dashboard=false --overwrite=true`.
- Endpoint zero-boundary hard-seed replay, no dashboard write:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-gaussian-lowq-sigma-intercept-smoke.R --providers=animal,relmat --n-rep=1 --seed-start=11 --seed-base=914000 --profile=true --profile-engine=endpoint --profile-endpoint-max-eval=48 --host-class=local_endpoint_boundary_patch_hard_seed --host-name=local --output-dir=docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-hardseed-local --write-dashboard=false --overwrite=true`.
- Endpoint zero-boundary hard-seed replay after lower-side error-branch
  hardening, no dashboard write:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-gaussian-lowq-sigma-intercept-smoke.R --providers=animal,relmat --n-rep=1 --seed-start=11 --seed-base=914000 --profile=true --profile-engine=endpoint --profile-endpoint-max-eval=48 --host-class=local_endpoint_boundary_patch_error_branch_recheck --host-name=local --output-dir=docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-error-branch-hardseed-local --write-dashboard=false --overwrite=true`.
  Seed 914011 still returned finite profile intervals `[0, 0.272805]` for
  animal and relmat, with `profile_error = NA`.
- Production-path hard-seed regression for seed 914011:
  `tests/testthat/test-profile-targets.R` now checks both animal and relmat
  `confint(..., method = "profile", profile_engine = "endpoint")` results and
  requires `[0, 0.272805]`-class finite intervals with
  `profile.message = near_sd_boundary`.
- Endpoint zero-boundary selected replay, no dashboard write:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-gaussian-lowq-sigma-intercept-smoke.R --providers=animal,relmat --n-rep=5 --seed-start=8 --seed-base=914000 --profile=true --profile-engine=endpoint --profile-endpoint-max-eval=48 --host-class=local_endpoint_boundary_patch_replay --host-name=local --output-dir=docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-sigma-boundary-patch-replay-local --write-dashboard=false --overwrite=true`.
- Endpoint zero-boundary SR150 replay and SR1000 local top-up shards: passed
  with single-threaded workers and no dashboard write. The SR1000 aggregate is
  1000/1000 finite profiles, coverage 0.9430, MCSE 0.007332, lower=12 and
  upper=45 misses for each provider.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file tools/summarize-structured-re-gaussian-lowq-sigma-profile-route-review.R --overwrite=true --sync-dashboard=true`: passed.
- `/opt/homebrew/bin/air format ...`: passed for the touched R files.
- Quiet parse check for the touched R/test files: passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 104 Q-Series cells and 2 sigma profile-route review rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "profile-targets")'`: 816 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`: 10206 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `git diff --check`: passed.
- Totoro source snapshot: synced to `/home/snakagaw/codex/drmTMB` excluding
  `.git` and simulation artifacts; remote `const BUILD = "r186"` and touched
  R files parse with `R_PROFILE_USER=/dev/null Rscript --no-init-file`.
- Trillium source snapshot: synced to
  `/project/def-snakagaw/snakagaw/drmtmb-qseries/source/drmTMB` excluding
  `.git` and simulation artifacts; after loading `StdEnv/2023 gcc/12.3 r/4.4.0`,
  remote `const BUILD = "r186"` and touched R files parse with
  `R_PROFILE_USER=/dev/null Rscript --no-init-file`.
- Final touched-file resync after the production hard-seed regression: Totoro
  `/home/snakagaw/codex/drmTMB` and Trillium
  `/project/def-snakagaw/snakagaw/drmtmb-qseries/source/drmTMB` both parse
  `R/profile.R` and `tests/testthat/test-profile-targets.R`.

## Tests Of The Tests

The focused test initially failed because it still expected animal/relmat q1
`sigma` rows to point at the SR150 pregrid results. Updating the test forced
the current source of truth to be the profile-route review sidecar. After the
patch, the test now checks both the historical blocker values and the patched
route values: 5/5 selected replay profiles finite, SR150 profile coverage
0.9533 with MCSE 0.017222, SR1000 profile coverage 0.9430 with MCSE 0.007332,
misses lower=12/upper=45, and 0/5 `tmbprofile` finite intervals.

## Member Review

Fisher, Gauss, and Rose all recommended no promotion. Fisher treated the
12/45 lower/upper miss imbalance and the one-scenario DGP as blockers for
`inference_ready`. Gauss accepted the zero-boundary convention as numerically
plausible, but found that the lower-side error branch could overclassify a
profile evaluation failure as a valid zero-boundary interval. That branch is now
tightened: only a finite below-cutoff evaluation at or below the numerical-zero
floor can return `theta = -Inf`. Rose found no status overclaim, but flagged
stale Trillium source-readiness wording; the host-access sidecar and dashboard
README now record the parse-ready source snapshot while preserving the
denominator/status block.

## Consistency Audit

Mission control, dashboard TSVs, the row-selection artifact mirror, dashboard
README, widget build/version, and the 104-row support-cell table now agree that
animal and relmat q1 `sigma` intercept rows remain
`point_fit/planned/planned`. The route review is SR1000 profile-channel
blocker evidence only and does not claim `interval_status`,
`coverage_status`, `inference_ready`, `supported`, q1 `mu`, matched
`mu+sigma`, q2, q4/q8, non-Gaussian intervals, REML, AI-REML, bridge support,
denominator evidence, or public support.

## GitHub Issue Maintenance

No GitHub issues or PR comments were changed in this slice. The work only
updated local mission-control evidence and tests.

## What Did Not Go Smoothly

The first replay artifacts carried stale `endpoint_profile_diagnostic_only`
metadata even for the `tmbprofile` run. The hard seed then showed that the
upper endpoint was valid but the lower side was chasing a numerically
meaningless finite root below an already near-zero SD estimate. After the
zero-boundary patch, the statistical blocker moved from profile execution to
upper-tail miss imbalance.

## Team Learning

For route repairs, add the review sidecar before host escalation and keep old
failure evidence beside the patched-route evidence. The summarizer now also
syncs the row-selection artifact mirror so Rose does not have to rediscover
dashboard-vs-artifact drift later.

## Known Limitations

The endpoint zero-boundary profile route has not been accepted as an
`inference_ready` interval channel. Totoro is reachable through the existing SSH
control socket, and Trillium is reachable with R 4.4.0 after modules load. Both
now have parse-ready source snapshots for fast follow-on shards, but neither
should be mixed into the local SR1000 denominator without an explicit
confirmation design and host-separated provenance. The next interval-route
repair must also keep production evaluation errors distinct from legitimate
zero-boundary intervals.

## Next Actions

Implement the next q1 `sigma` diagnostic slice before any status edit: persist
endpoint diagnostics per replicate, compare endpoint profiles with dense manual
log-SD profile curves for boundary and non-boundary cases, and rerun any
confirmation shards with host-separated provenance. Keep the support cells
`point_fit/planned/planned` until Fisher/Gauss/Rose authorize a status edit.

# After Task: Q-Series q2 intercept local smoke

## 1. Goal

Run and register the first local q2 intercept smoke for the 12-row
interval-denominator contract before spending Totoro/FIIA, Nibi/Rorqual, or
DRAC compute.

## 2. Implemented

This promotes exactly no Q-Series row. The task added
`tools/run-structured-re-q2-intercept-smoke.R`, ran a local n=1 smoke for
phylo, spatial, animal, and relmat q2 intercept targets, and wrote
`docs/dev-log/dashboard/structured-re-q2-intercept-local-smoke.tsv`.

The smoke sidecar mirrors the artifact summary under
`docs/dev-log/simulation-artifacts/2026-06-29-q2-intercept-local-smoke/` and is
backed by raw replicate rows, a seed manifest, `sessionInfo.txt`, and
`git-sha.txt`. All 12 targets had fit success, convergence code 0, `pdHess =
TRUE`, finite default-Wald intervals, finite endpoint-profile intervals, and
bootstrap-off accounting. The summary keeps Wald and endpoint-profile
lower/upper miss fields separate; the legacy `lower_miss`/`upper_miss` fields
remain as Wald aliases for continuity.

Mission control now validates the sidecar, its raw artifacts, its seed
manifest, and the linked q2 intercept contract. The focused
structured-RE conversion-contract test now checks the same row-level contract
without running model fits during the test suite.

## 3a. Decisions and Rejected Alternatives

The smoke stayed local and n=1 because its purpose is runner/schema
verification, not coverage. Totoro/FIIA smoke and DRAC top-ups remain blocked
until Fisher/Rose review the local artifact and confirm the next denominator
contract.

The runner records bootstrap as skipped by default instead of silently omitting
bootstrap fields. That keeps later denominator accounting explicit without
spending bootstrap compute in the first local smoke.

The q2 intercept direct-correlation target is retained as its own target. It is
not inherited from the two direct-SD endpoint passes.

## 4. Files Touched

- `tools/run-structured-re-q2-intercept-smoke.R`
- `tools/start-mission-control.sh`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-q2-intercept-local-smoke.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/simulation-artifacts/2026-06-29-q2-intercept-local-smoke/structured-re-q2-intercept-local-smoke.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q2-intercept-local-smoke/structured-re-q2-intercept-local-smoke-replicates.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q2-intercept-local-smoke/structured-re-q2-intercept-local-smoke-seed-manifest.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q2-intercept-local-smoke/sessionInfo.txt`
- `docs/dev-log/simulation-artifacts/2026-06-29-q2-intercept-local-smoke/git-sha.txt`
- `docs/dev-log/after-task/2026-06-29-q-series-q2-intercept-local-smoke.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q2-intercept-smoke.R --n-rep=1 --profile-max-eval=25 --bootstrap=0 --overwrite=true`: passed; wrote 12 summary rows and 12 replicate rows.
- `python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 12 structured RE q2 intercept local-smoke rows.
- `/opt/homebrew/bin/air format tests/testthat/test-structured-re-conversion-contracts.R tools/run-structured-re-q2-intercept-smoke.R`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'parse("tools/run-structured-re-q2-intercept-smoke.R"); cat("parse_ok\n")'`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`: passed with 8,002 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q2-intercept-local-smoke.md')"`: passed with `after-task structure check passed`.
- `git diff --check`: passed.
- `sh -n tools/start-mission-control.sh`: passed.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`: passed after replacing `cp -R` artifact-directory copying with content-only Python mirroring; the dashboard was already listening at `http://127.0.0.1:8765/`.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/codex-checkpoint.R --goal "Q-Series q2 intercept local smoke closed; Totoro/FIIA remote smoke blocked by SSH alias/auth" --next "Prime non-interactive Totoro or FIIA access, then run tools/run-structured-re-q2-intercept-smoke.R --n-rep=5 --profile-max-eval=25 --bootstrap=0 --write-dashboard=false in a separate artifact directory; do not use Nibi/Rorqual for this q2 intercept smoke without Fisher/Rose approval"`: wrote local ignored checkpoint `docs/dev-log/recovery-checkpoints/2026-06-29-171621-codex-checkpoint.md`.

## 6. Tests of the Tests

The first mission-control validator run failed because I assumed the raw
replicate `convergence` field was Boolean. The runner stores the optimizer
convergence code (`0`) and stores `pdHess` separately as Boolean. Updating the
validator to the actual schema proved the new guard is reading raw artifacts
rather than only checking row counts.

The focused test compares the dashboard summary to the artifact summary,
checks all 12 raw replicate rows, and checks the four-provider seed manifest.
Changing a contract id, source-contract path, promotion decision, bootstrap
status, or linked support-cell status should now fail the test.

## 7a. Issue Ledger

No GitHub issue was opened or closed. This is a local Q-Series evidence slice
under the current mission-control arc.

## 8. Consistency Audit

I checked the q2 intercept interval contract, the new local-smoke dashboard
sidecar, the mirrored artifact summary, raw replicate rows, and seed manifest.
The linked q2 intercept support cells still read `point_fit/planned/planned`.

I also updated the dashboard README and check-log so the human-facing story
matches the validator: this is smoke evidence only, not interval coverage, not
`inference_ready`, not `supported`, not q2 slope, not q2-plus-q2, not q4/q8,
not non-Gaussian, not REML, not AI-REML, not bridge support, and not public
support.

## 9. What Did Not Go Smoothly

The raw replicate schema used optimizer convergence code `0`, while I first
wrote the validator as though it were Boolean `TRUE`. The validator caught the
mistake immediately.

The R parse check printed the parsed expression before `parse_ok`; that was
noisy but not a failure.

The first dashboard refresh attempt failed while `cp -R` tried to replay
setgid permissions from an older Rorqual artifact tree into `/tmp/drm-dashboard`.
I updated `tools/start-mission-control.sh` to mirror comparator and simulation
artifact files by content, without preserving cluster-side permissions, then
reran the dashboard refresh successfully.

## 10. Known Residuals

The n=1 local smoke is not coverage evidence and cannot justify any row-level
promotion. At the time of this smoke report, Fisher/Rose review was still
required before a Totoro/FIIA smoke. That review was later recorded in
`docs/dev-log/after-task/2026-06-29-q-series-q2-intercept-fisher-rose-signoff.md`;
the current gate is a reviewed but host-held Totoro/FIIA `n=5` smoke, and
Nibi/Rorqual/DRAC remain blocked for this row set.

The next real evidence gate needs more replicates, denominator retention,
replicated one-sided miss balance, and a clear decision about whether direct
correlation targets use profile, delta, bootstrap, or another interval channel.

Post-review host probe: `ssh -o BatchMode=yes totoro` resolved but required
interactive authentication, `fiia`/`FIIA` did not resolve as SSH aliases in
this shell, and Nibi/Rorqual responded but remain blocked by the q2 intercept
smoke gate. Do not run the q2 intercept n=5 smoke on Nibi/Rorqual just because
those hosts are reachable.

## 11. Team Learning

For smoke runners, validate raw artifact schemas before interpreting pass/fail
summaries. Numeric optimizer convergence and Boolean `pdHess` should stay
separate in both validators and tests.

Wald and endpoint-profile one-sided miss fields should also stay separate, even
in smoke artifacts, so a later coverage summary cannot silently borrow the wrong
interval channel.

For dashboard refreshes, copy artifact content rather than cluster permissions.
DRAC and Rorqual artifact trees can carry group bits that are valid on the
cluster but fragile in the local `/tmp` dashboard mirror.

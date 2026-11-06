# After Task: Bernoulli corrected first look and runner validation

> **Superseded interpretation (2026-10-19):** This report records an earlier confusion between fitted-profile and Monte Carlo interval levels. The approved contract uses 95% fitted profile intervals and 97.5% exact Monte Carlo confidence intervals. The 3,000-fit 97.5%-profile run below is historical exploratory evidence only; its `look2_required` result cannot authorize another look. The archived 95%-profile first look has the approved nominal level but remains ineligible for replay because required profile metadata and current-source hashes do not match. A fresh source-bound 95% first look is still required. See `../general-sd-regression/staged-calibration-contract.md` and `2026-10-19-bernoulli-calibration-contract-reconciliation.md`.

## 1. Goal

Read back the corrected native Bernoulli first-look campaign and repair the
versioned runner so a rejected subset design does not leave an output directory.

## 2. Implemented

The runner now verifies the prepared source, external registry digest, full
manifest design, worker script, and required test-library configuration before
creating a subset directory. After copying, it verifies the subset registry and
manifest against the source before launching workers. Regression tests require
invalid seeds and missing worker configuration to leave no subset directory.
This runner repair was made after the production campaign; the campaign used the
earlier runner, and its full production path did not create a subset directory.

The historical 97.5%-profile campaign evidence was copied from Totoro. The 3,000 planned
fits completed; all 3,000 fits were healthy, all 3,000 profile intervals were
valid, and all 3,000 independent Laplace-oracle checks passed. The staged helper
returned `look2_required`; overall qualification is `FALSE`. The campaign used
97.5% fitted intervals, while the approved contract uses 95% fitted profiles
and 97.5% Monte Carlo uncertainty intervals. The earlier interpretation that
the acceptance bands implied a 97.5% fitted target was incorrect; the run and
its results remain historical exploratory evidence.

## 3a. Decisions and Rejected Alternatives

The frozen bands were not changed after observing the results. The decision
helper's `look2_required` output is retained as the mechanical result, but it
does not qualify the approved 95% fitted-profile target. No second-look fits
were launched. The analysis script was not part of the production source
registry, so its separate SHA-256 receipt remains attached to the results.

Assumptions made without asking: the evidence copy should remain a separate
folder from the historical 95% archive. If that naming distinction is wrong,
only the evidence path and links need to change.

## 4. Files Touched

- `tools/general-sd-regression/native-calibration/run-0975.py`
- `tools/general-sd-regression/native-calibration/test-timing-0975.py`
- `.unlazy/general-sd-regression/GATES.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/general-sd-regression/calibration-0975-band-audit.md`
- `docs/dev-log/general-sd-regression/staged-calibration-contract.md`
- `docs/dev-log/general-sd-regression/evidence/calibration-20261017/first-look-postfix-20261019-v2/` (15,016 campaign files and 3 source snapshots)
- `docs/dev-log/general-sd-regression/evidence/calibration-20261017/first-look-postfix-20261019-v2/source-snapshot/native-calibration/prepare-0975.R`
- `docs/dev-log/general-sd-regression/evidence/calibration-20261017/first-look-postfix-20261019-v2/source-snapshot/native-calibration/run-0975.py`
- `docs/dev-log/general-sd-regression/evidence/calibration-20261017/first-look-postfix-20261019-v2/source-snapshot/native-calibration/summarize-0975.R`
- `docs/dev-log/after-task/2026-10-19-bernoulli-corrected-first-look.md`

## 5. Checks Run

- `python3 -m unittest tools/general-sd-regression/native-calibration/test-timing-0975.py -v`: 9 tests passed.
- `python3 -m py_compile .../run-0975.py .../test-timing-0975.py`: passed.
- `git diff --check`: passed.
- The structural after-task checker passed for all required headings and the `does NOT cover` section.
- Totoro supervisor readback: 3,000 planned cases, 3,000 completed, campaign complete, not interrupted.
- Campaign output counts: 3,000 results, 3,000 health records, 3,000 interval records; 15,016 files total. Three source snapshots were added separately.
- Key local hashes match the remote receipts: manifest `3a16ee05…`, source registry `cd1418d2…`, supervisor `5232aa7f…`, summary-tool receipt `b4e6938f…`, summary CSV `fd90417a…`, and summary Markdown `503f59ee…`.
- `lane_preflight.sh` found no other lane working on `run-0975.py`. `route.py` found no LOAD-FIRST manifest for either the worktree or repository path.
- The brain `closeout.py new` helper resolved its output under the Shinichi brain rather than this worktree and failed with a permission error. No file was written there; this report was created in the repository and is checked with the available structural validator.
- The full `closeout.py check` path was stopped because it re-runs the brain repository's acceptance ledgers from the wrong root; this programme's own ledgers remain open by design.
- Focused regression follow-up: `devtools::test(filter = "binomial-sd")` passed 562 assertions, with 5 live-Julia tests skipped because the DRM.jl engine path was not configured; `devtools::test(filter = "binomial-correlated-sd")` passed 60 assertions; `devtools::test(filter = "julia-binomial-sd")` passed 23 R-side assertions, with 4 live-Julia tests skipped for the same reason. Total: 645 passed, 9 skipped, 0 failed or warned across the three commands. This verifies native tests and Julia bridge/output handling only; it does not exercise the Julia engine or establish interval calibration.

## 6. Tests of the Tests

Before the runner change, the invalid-seed regression failed because the subset
directory existed after validation rejected the design. After the change, the
test passes and confirms that workers are not called and no output directory is
created. A second regression failed before the fix when the required test-library
environment variable was missing; it now confirms that this setup error also
leaves no directory.

## 7a. Issue Ledger

- Open: a fresh source-bound first look at the approved 95% fitted-profile
  target is required. The archived 95% rows lack required profile-level
  metadata and do not match the current package-source hashes.
- Historical: the completed 97.5%-profile first look and its `look2_required`
  decision do not qualify the approved target or authorize look two.
- Open: `summarize-0975.R` was not registered in the production source registry.
  Its content hash and output hashes are recorded separately.
- Open: the per-file checksum walk over all 15,016 Dropbox-backed files was
  stopped because it was too slow. Counts and key hashes were checked; full
  byte-by-byte transfer verification is not claimed.
- Fixed: invalid qualification designs no longer create a subset output folder.
- Fixed: missing `DRMTMB_SD_TEST_LIBRARY` is rejected before subset creation.

## 8. Consistency Audit

The later contract reconciliation established that fitted profile intervals
target 95%, while 97.5% applies to Monte Carlo uncertainty. The 97.5%-profile
run in this report is exploratory; the older 95%-profile archive has the
correct nominal level but remains ineligible for replay because its rows lack
explicit profile-level metadata and its package source hashes differ from the
current candidate. The DRM.jl lane was told the Totoro campaign had ended and
the machine was free; no source overlap was identified. The original email
remains unsent.

## 9. What Did Not Go Smoothly

The earlier review conflated fitted-profile level with Monte Carlo confidence
level and treated 97.5% fitted intervals as the frozen target. A later
source-backed reconciliation corrected that interpretation. The full
file-by-file checksum walk was too slow on the Dropbox-backed copy. The shared
closeout helper also assumes the brain repository is the target root, so it
could not create this project report directly. One command briefly created
empty directories in the main checkout because its worktree path was omitted;
I removed them before copying files there.

## 10. Known Residuals

The Bernoulli first-look campaign does not complete the Bernoulli inference
gate. A fresh current-source 95% first look and the second look have not run,
and Julia uncertainty calibration remains open. The historical 97.5%-profile
campaign summary script was not source-registry pinned. The overall family,
random-effect, and engine parity programme remains active; G0-G8 remain open.

## 11. Team Learning

Keep the fitted profile interval level separate from the Monte Carlo confidence
level for coverage and false-positive estimates. The approved contract uses
95% fitted intervals and 97.5% Monte Carlo intervals. Review both fields
together before launching calibration, then preserve their separate roles in
the result schema and acceptance checks.

Memory receipt: read the brain index, working-style note, relevant campaign
guard, and reusable-work note. The frozen-rule guard shaped the decision to
retain the mechanical output without changing the band after results were seen.
The repo route script found no LOAD-FIRST manifest. Golden Set: not in scope.

## 12. Cross-Product Coverage

Covers: native R/TMB Bernoulli first-look evidence and the versioned calibration
runner's validation ordering.

Does NOT cover: Julia calibration, other response families, other random-effect
forms, a corrected acceptance-band protocol, second-look results, full family
parity, or programme completion.

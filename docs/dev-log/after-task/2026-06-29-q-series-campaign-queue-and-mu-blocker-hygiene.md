# After Task: Q-Series campaign queue and mu-blocker hygiene

## 1. Goal

Make the 104-row Q-Series board actionable without overclaiming: add a
compute/hold queue for the connected local, Totoro, FIIA, Nibi, Rorqual, and
DRAC resources, and propagate the Gaussian q1 `mu` one-slope interval-shape
blockers into the support-cell and low-q audit ledgers.

## 2. Implemented

This promotes exactly no Q-Series row under the campaign-queue and q1 `mu`
blocker-propagation channel, with the existing support-cell denominator policy,
and does not claim `supported`, new `inference_ready` rows, q4/q8 readiness,
non-Gaussian interval readiness, REML, AI-REML, bridge support, or public
support.

Added `structured-re-q-series-next-campaign-queue.tsv`, a ten-row queue whose
row counts sum to the 104 support cells. The queue separates no-compute
reference rows, baseline comparator holds, non-Gaussian recovery-only rows,
intentional rejection holds, Gaussian low-q row-selection work, q1 `mu`
interval-rule design, spatial/animal q2 blockers, high-q geometry/stability
work, and non-Gaussian future family design. Each compute-bearing row names the
allowed host class and blocks broad DRAC denominator campaigns until the exact
row contract is reviewed.

Updated the mission-control widget to render the new queue near the top of the
Q-Series section and bumped the dashboard build to `r114`. The queue is a
cluster-use guard only; it does not change any support-cell fit, interval, or
coverage status.

Propagated the Gaussian q1 `mu` one-slope blocker evidence into both
`structured-re-q-series-support-cells.tsv` and
`structured-re-gaussian-lowq-status-audit.tsv`. Phylo, relmat, and spatial now
point at the SR475 interval-shape diagnostic and explicitly require Fisher/Rose
approval before any DRAC top-up, TSV promotion, or public wording change.
Animal points at the hybrid boundary audit and remains hard-blocked until the
interval channel is repaired.

Mission control and focused tests now enforce the propagation: the four linked
support cells must stay `planned/planned`, must not be `supported`, must point
at the expected blocker sidecars, and must mention the Fisher/Rose DRAC and TSV
promotion stop rule.

## 3a. Decisions and Rejected Alternatives

Decision: treat connected DRAC machines and Totoro as capacity behind explicit
row gates, not as a reason to launch broad denominator campaigns.

Decision: separate stability, recovery, interval feasibility, coverage, and
`inference_ready` status in the widget. A tried or fit-stable row is not
automatically inference-ready.

Decision: keep the q1 `mu` upper-tail and boundary-profile evidence as blocker
evidence. MCSE-qualified retained denominators do not override one-sided miss
imbalance or hard-negative interval geometry.

Rejected alternatives:

- Do not spend DRAC time on evidence-complete, baseline-comparator,
  intentionally rejected, diagnostic-only, or family-design-hold rows.
- Do not promote phylo, relmat, spatial, or animal q1 `mu` one-slope rows from
  point/fixture stability or smoke evidence.
- Do not use q1 `mu` evidence to promote sigma, q2, q4/q8, non-Gaussian, REML,
  AI-REML, bridge, `supported`, or public-support claims.
- Do not let stale support-cell or low-q audit text point future work back to a
  top-up path before Fisher/Rose accept a replacement interval rule.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-campaign-queue-and-mu-blocker-hygiene.md`

## 5. Checks Run

- `/opt/homebrew/bin/air format tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R`:
  passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`: passed
  with `mission_control_ok`, including 104 Q-Series support cells, 16
  closure-triage rows, 10 next-campaign queue rows, and 6 Gaussian q1 `mu`
  interval-shape diagnostic rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  7271 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `git diff --check`: passed.
- `node - <<'NODE' ... NODE`: passed with `dashboard_js_parse_ok` after
  extracting and parsing the dashboard script block.
- `find . -type d -name '__pycache__' -print`: returned no paths after
  removing `tools/__pycache__`.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-campaign-queue-and-mu-blocker-hygiene.md')"`:
  passed.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`:
  passed; the dashboard was already listening at `http://127.0.0.1:8765/`.
- Served widget checks: `version.txt` returned `r114`, the next-campaign queue
  TSV served 11 lines including the header, and `/` contained both
  `Campaign queue` and the queue TSV fetch path.

## 6. Tests of the Tests

The new mission-control queue guard is row-count and row-id exact: it requires
the ten queue rows to sum to the 104 support cells and rejects non-local compute
rows that omit DRAC host wording, stop rules, primary evidence, or no-claim
language. The new focused test also checks the exact q1 `mu` blocker support
cells and low-q audit rows. If a future edit changes any of those rows back to
a generic top-up or fixture-parity gate, the focused contract test fails before
the widget can present stale work instructions.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This was local
mission-control hygiene inside the active Q-Series evidence board. The queue
does not replace future issue or PR triage for a specific compute campaign.

## 8. Consistency Audit

Checked the support-cell, closure-triage, next-campaign queue, Gaussian low-q
audit, q1 `mu` interval-shape diagnostic, q1 `mu` hybrid-boundary audit,
dashboard README, widget renderer, validator, and focused tests as neighbours
of the change.

The board remains 104 rows with five interval-and-coverage `inference_ready`
rows and no structured `supported` row. The new queue counts also sum to 104,
so it is an overlay on the same board rather than a parallel inventory.

The connected-host policy is now explicit: Totoro/FIIA are smoke hosts, Nibi
and Rorqual are prespecified denominator/admission hosts, and DRAC-wide work is
blocked for hold/no-compute rows or before a row-specific Fisher/Rose contract.

## 9. What Did Not Go Smoothly

One mechanical edit to the queue TSV was made with a short Python script before
the editing discipline was noticed. The file was then covered by mission
control and the focused R contract test; future manual edits should use
`apply_patch`.

## 10. Known Residuals

Q-Series is not complete. Gaussian q4/q6/q8 rows remain geometry,
admission, or stability work; q8 is not inference-ready. Non-Gaussian rows
remain recovery-only, rejected, or planned-family design, with no interval or
coverage readiness. q1 `mu` one-slope rows remain blocked until a replacement
interval-shape or calibration rule is written and reviewed. q2 spatial/animal
and spatial sigma retain row-specific blockers.

## 11. Team Learning

When all compute hosts are reachable, the board needs a host-use contract even
more than it needs another run. Put the stop rule beside the row count, and
make the validator enforce that a future top-up cannot silently become a
promotion.

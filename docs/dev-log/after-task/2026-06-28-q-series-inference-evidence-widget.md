# After-task: Q-Series inference-evidence widget summaries

Meta: 2026-06-28 · Codex · branch `codex/qseries-sigma-inference-ready`;
dashboard build `r65`.

## 1. Goal

Make the top Q-Series widget more useful for the four rows already promoted to
`inference_ready` by showing their interval channel, denominator summary,
coverage summary, and miss-balance caveat next to the 104-row support-cell
table. This was a status-discipline patch, not a new inference promotion.

## 2. Implemented

- Added
  `docs/dev-log/dashboard/structured-re-q-series-inference-evidence-summary.tsv`
  with exactly four rows: phylo/relmat q1 sigma one-slope and phylo/relmat q2
  `mu1+mu2` one-slope.
- Updated `docs/dev-log/dashboard/index.html` so promoted rows join to that
  sidecar and display reader-facing evidence denominators while non-promoted
  rows keep showing the support-cell denominator policy.
- Registered the new sidecar in `tools/validate-mission-control.py`.
- Updated `docs/dev-log/dashboard/README.md`, `status.json`, and `version.txt`
  for dashboard build `r65`.
- Added this check-log and after-task closeout.

## 3a. Decisions and Rejected Alternatives

The 104-row support-cell TSV remains the row-level source of truth. Its
`denominator_policy` field is still the route/status contract; the new
four-row sidecar is the reader-facing evidence summary for rows already at
`inference_ready`.

Rejected alternatives:

- Do not change the four promoted support-cell rows just to improve display
  wording.
- Do not create summaries for planned, diagnostic, blocked, or unsupported rows.
- Do not treat pooled all-provider q2 evidence as a claim that all providers are
  independently `inference_ready`.
- Do not use the sigma evidence summary to imply bias+t, profile-channel
  reliability, or `supported`.

## 4. Files Touched

- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/structured-re-q-series-inference-evidence-summary.tsv`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-28-q-series-inference-evidence-widget.md`

## 5. Checks Run

- `sed -n '/<script>/,/<\\/script>/p' docs/dev-log/dashboard/index.html | sed
  '1d;$d' | node --check -`: passed.
- `python3 tools/validate-mission-control.py`: passed with
  `mission_control_ok`, 104 Q-Series support cells, and 4 Q-Series
  inference-evidence summary rows.
- `git diff --check`: passed.
- `tools/start-mission-control.sh --background`: passed; dashboard already
  listening at `http://127.0.0.1:8765/`.
- `curl -fsS http://127.0.0.1:8765/version.txt`: returned `r65`.
- `curl -fsS
  http://127.0.0.1:8765/structured-re-q-series-inference-evidence-summary.tsv |
  wc -l`: returned 5 lines.

## 6. Tests of the Tests

The validator now checks that
`structured-re-q-series-inference-evidence-summary.tsv` has exactly four rows,
that each row points to one of the four current `inference_ready` support cells,
that the linked cells still have both interval and coverage status set to
`inference_ready`, and that none of those linked rows is marked `supported`.

The live server check separately confirmed that the served dashboard is build
`r65` and that the new sidecar is reachable over the local widget server.

## 7a. Issue Ledger

No GitHub issue or PR comment was added. This patch supports the active Q-Series
widget/PR stack and does not alter the public claim boundary.

## 8. Consistency Audit

The Q-Series status count remains 104 rows with exactly four
`inference_ready` rows. The widget now makes those four rows easier to audit:
q1 sigma rows show raw uncorrected log-SD Wald-z evidence, while q2 location
rows show the default location-axis bias+t evidence. Both summaries retain the
`inference_ready_with_caveats` status and explicitly withhold `supported`.

## 9. What Did Not Go Smoothly

The first validator patch attempt used an overly specific context line in the
long mission-control summary print and did not apply. I split the validator edit
into smaller patches before rerunning validation.

## 10. Known Residuals

- The widget still has no filters, search, sticky header, or column sorting.
- The q2 corrected evidence is summarized from design/report artifacts rather
  than a per-replicate dashboard sidecar. A later compute/reporting slice could
  add a fuller q2 corrected-coverage evidence TSV.
- No new row was promoted.

## 11. Team Learning

The support-cell row and the evidence denominator are related but not identical.
Keeping the status contract in the 104-row TSV and the promoted-row evidence
summary in a tiny sidecar makes the widget clearer without weakening the
validator's anti-overclaiming guards.

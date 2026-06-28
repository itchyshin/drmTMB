# Q-Series spatial/animal q2 admission widget

## 1. Goal

Surface the remaining evidence gates for the spatial and animal q2 `mu1+mu2`
one-slope support cells without promoting either cell to `inference_ready`.

## 2. Implemented

Added `structured-re-q2-slope-spatial-animal-admission-audit.tsv`, a two-row
dashboard sidecar for `qseries_spatial_q2_mu1_mu2_one_slope` and
`qseries_animal_q2_mu1_mu2_one_slope`. The Q-Series widget now merges sigma and
q2 admission audits and displays `calibration_required` for spatial q2 and
`admission_blocked` for animal q2. The validator reads and enforces the q2
sidecar, including raw SR475 under-coverage, missing animal correlation coverage,
and the planned interval/coverage status boundary.

## 3a. Decisions and Rejected Alternatives

I rejected promoting spatial q2 by analogy with phylo/relmat. The spatial raw
SR475 coverage rows under-cover, and the default bias+t correction has not been
banked as a row-specific spatial promotion with Fisher/Rose sign-off.

I rejected promoting animal q2 because the two SD endpoints have raw
under-coverage and the `mu1:x+mu2:x` correlation endpoint is absent from the
coverage grid while remaining a replicated-denominator holdout.

I kept both as widget display states rather than TSV scientific status changes:
both support cells retain `interval_status = planned` and
`coverage_status = planned`.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-slope-spatial-animal-admission-audit.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-28-q-series-spatial-animal-q2-admission-widget.md`

## 5. Checks Run

- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `sed -n '/<script>/,/<\\/script>/p' docs/dev-log/dashboard/index.html | sed '1d;$d' | node --check -`: passed.
- `python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 104 Q-Series support cells and 2 q2 slope spatial/animal admission-audit rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e "devtools::test(filter = 'structured-re-conversion-contracts')"`: passed, `6225 PASS / 0 FAIL / 0 WARN / 0 SKIP`.
- `tools/start-mission-control.sh --background`: dashboard already listening at `http://127.0.0.1:8765/`.
- `curl -fsS http://127.0.0.1:8765/version.txt`: returned `r68`.
- `curl -fsS http://127.0.0.1:8765/structured-re-q2-slope-spatial-animal-admission-audit.tsv | wc -l`: returned 3 lines, meaning header plus two audit rows.
- System-Chrome Playwright smoke against `http://127.0.0.1:8765/`: Q-Series board rendered `calibration required`, `admission blocked`, `qseries_spatial_q2_mu1_mu2_one_slope`, and `qseries_animal_q2_mu1_mu2_one_slope`.
- `git diff --check`: no whitespace errors.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-28-q-series-spatial-animal-q2-admission-widget.md')"`: after-task structure check passed.

## 6. Tests of the Tests

The validator now fails if the q2 audit sidecar drops either row, changes the
raw SR475 coverage metrics, adds an animal correlation coverage row before the
denominator holdout is reconciled, marks either linked support cell as anything
other than planned for interval/coverage, or weakens the no-promotion language.

## 7a. Issue Ledger

- Spatial q2 one-slope: raw coverage is negative; next step is row-specific
  default bias+t corrected coverage with retained denominators and Fisher/Rose
  sign-off.
- Animal q2 one-slope: the correlation endpoint remains a denominator holdout;
  next step is endpoint-profile admission repair before any full-row coverage
  claim.

## 8. Consistency Audit

Checked the q2 support-cell rows, raw slope coverage results, q2 denominator
admission, q2 replicated-denominator rule, default bias-correction design note,
widget JavaScript, dashboard README, and mission-control validator. The only
q2 support cells that remain `inference_ready` are phylo and relmat.

## 9. What Did Not Go Smoothly

The q2 evidence has two layers that are easy to conflate: older raw
Wald/profile coverage is negative for all providers, while the later default
bias+t correction promoted only exact phylo/relmat cells. The new audit keeps
those layers separate.

## 10. Known Residuals

Spatial q2 still needs row-specific default bias+t coverage evidence and
g-stress comparison before promotion. Animal q2 still needs the correlation
endpoint denominator holdout reconciled before full-row coverage can be
evaluated.

## 11. Team Learning

When a correction is accepted for a subset of providers, the widget needs an
explicit neighbour-audit row for the non-promoted providers. Otherwise "all
four providers contributed evidence" can be misread as "all four providers are
inference-ready."

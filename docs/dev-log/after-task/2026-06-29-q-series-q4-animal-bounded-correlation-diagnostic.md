# After Task: Q-Series q4 animal bounded-correlation diagnostic

## 1. Goal

Test the smallest q4 animal all-four continuation experiment after the
start/map diagnostic localized the hard-seed blocker to the free q4 correlation
block, without launching DRAC coverage or promoting any Q-Series row.

## 2. Implemented

This promotes exactly no Q-Series row under the animal q4 bounded-correlation
diagnostic channel, with three hard seeds and optimizer-layer
`theta = cap * tanh(eta)` accounting, and does not claim q4 interval
reliability, q4 coverage, `inference_ready`, `supported`, q8 support, REML,
AI-REML, broad bridge support, a production parameterization change, derived
correlation intervals, or public support.

Added `tools/run-structured-re-q4-animal-bounded-correlation-diagnostic.R`.
The runner reuses the same animal q4 all-four DGP and internal TMB object path
as the admission, optimizer-route, and start/map probes. It runs seeds
`910101`, `910102`, and `910110` across five strategies: the zero-correlation
map control, the current unbounded staged fit, and bounded continuations at
caps `0.50`, `0.80`, and `0.95`.

The bounded continuation does not change the package likelihood or formula
grammar. It wraps the optimizer so that free outer `eta` values are transformed
to the current TMB `theta_phylo` scale by `theta = cap * tanh(eta)` before the
existing objective and gradient are evaluated.

## 3a. Decisions and Rejected Alternatives

Decision: do not use Nibi, Rorqual, Totoro, or FIIA for q4 coverage from this
result. All bounded rows reached `pdHess = TRUE`, but all nine bounded rows hit
their cap and retained a large fixed-gradient signal. That is boundary-seeking
geometry evidence, not admission evidence.

Rejected alternatives:

- Do not call cap-saturated `pdHess = TRUE` rows a q4 rescue.
- Do not launch a 16-replicate DRAC admission rerun until a bounded or
  penalized route passes without cap saturation.
- Do not promote animal q4 all-four, q8-shaped rows, derived correlations,
  REML, AI-REML, bridge parity, or public support.

## 3b. Mathematical Contract

No likelihood, estimator, formula grammar, or interval channel changed. The
runner uses the current q4 all-four animal syntax:

- `mu1 = y1 ~ x + animal(1 + x | p | id, A = A)`
- `mu2 = y2 ~ x + animal(1 + x | p | id, A = A)`
- `sigma1 = ~ z + animal(1 + x | p | id, A = A)`
- `sigma2 = ~ z + animal(1 + x | p | id, A = A)`
- `rho12 = ~ 1`

The diagnostic only asks whether a bounded optimizer-layer continuation can
find an interior q4 correlation solution on the hard seeds. Because every cap
was saturated, the comparison supports a deeper bounded/penalized design
question rather than all-free q4 admission.

## 4. Files Touched

- `tools/run-structured-re-q4-animal-bounded-correlation-diagnostic.R`
- `docs/dev-log/dashboard/structured-re-q4-animal-bounded-correlation-diagnostic.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-bounded-correlation-local/`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q4-animal-bounded-correlation-diagnostic.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'invisible(parse("tools/run-structured-re-q4-animal-bounded-correlation-diagnostic.R")); cat("bounded_runner_parse_ok\n")'`: passed.
- `/opt/homebrew/bin/air format tools/run-structured-re-q4-animal-bounded-correlation-diagnostic.R`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q4-animal-bounded-correlation-diagnostic.R --overwrite=true --write-dashboard=true`: passed, writing 15 bounded-correlation rows.
- `/opt/homebrew/bin/air format tools/run-structured-re-q4-animal-bounded-correlation-diagnostic.R tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R`: passed.
- Dashboard JavaScript parse check via `node`: `dashboard_js_ok`.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 15 structured RE q4 animal bounded-correlation diagnostic rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`: 7199 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q4-animal-bounded-correlation-diagnostic.md')"`: passed.
- `git diff --check`: passed.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`: passed after a fresh `mission_control_ok`; the dashboard was already listening at `http://127.0.0.1:8765/`.
- Served dashboard verification: `curl -fsS http://127.0.0.1:8765/version.txt` returned `r112`; `index.html` contained the `q4AnimalBoundedCorrelationDiagnostic`, `Animal q4 bounded`, `q4 bounded`, `structured-re-q4-animal-bounded-correlation-diagnostic`, and `bounded-correlation diagnostic` markers; the bounded-correlation TSV served 16 lines including the header.

## 6. Tests of the Tests

The focused structured-RE conversion test now requires the exact 15-row
bounded-correlation matrix: three hard seeds crossed with five strategies,
three zero-correlation control passes, three current unbounded staged
gradient/Hessian blockers, and nine cap-saturated bounded rows.

The test also requires diagnostic-only claim boundaries, `coverage_status =
not_evaluable`, and the artifact copy to match the dashboard sidecar exactly.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This was a local
diagnostic/dashboard banking slice inside the Q-Series high-q arc.

## 8. Consistency Audit

The linked Q-Series animal q4 all-four one-slope cell remains
`interval_status = diagnostic_only` and `coverage_status = planned`. The new
bounded-correlation sidecar records `interval_claim_status = diagnostic_only`
and `coverage_status = not_evaluable`.

The evidence separates optimizer-layer bounded geometry from production q4
support. Cap-saturated `pdHess = TRUE` rows do not become interval readiness,
coverage evidence, support, q8 evidence, REML, AI-REML, bridge support, or a
user-facing parameterization claim.

## 9. What Did Not Go Smoothly

The bounded optimizer wrapper needed to report both the outer bounded gradient
and the ordinary TMB fixed gradient. The outer gradients were small, but the
ordinary fixed gradients stayed large because the optima sat on the cap. That
distinction is the main diagnostic result.

## 10. Known Residuals

Animal q4 all-four correlation admission remains blocked. This diagnostic does
not validate an interior bounded transform, a penalized likelihood, a q4
coverage denominator, q4 derived-correlation intervals, q8, REML, AI-REML, or
bridge support.

## 11. Team Learning

When zero-correlation maps and cap-bounded continuations both produce positive
Hessians, but the capped solutions saturate, the model is asking for boundary
correlations rather than merely better starts. DRAC should stay reserved until
the next design can produce interior solutions on the hard seeds.

## 12. Next Actions

- Ask Gauss/Noether whether the next experiment should be a penalized q4
  correlation route, a reduced block design, or a different q4 correlation
  parameterization.
- Keep q4 coverage-grid design paused until hard-seed q4 correlation admission
  passes without cap saturation.
- Ask Fisher/Rose to review any future denominator-policy change before a
  Q-Series status edit.

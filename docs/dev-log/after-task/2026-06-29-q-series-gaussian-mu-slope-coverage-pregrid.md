# After Task: Q-Series Gaussian Mu-Slope Coverage Pregrid

## 1. Goal

Execute the retained-outcome SR150 pregrid for the Gaussian q1 `mu` one-slope
rows that passed the local interval-probe rung, then rerun it after fixing the
structured SD group-count matcher for decomposed q1 slope targets, while keeping
all support-cell interval, coverage, `inference_ready`, `supported`, REML,
AI-REML, bridge, q2/q4/q8, sigma, non-Gaussian, and public-support claims
unpromoted.

## 2. Implemented

This promotes exactly no support cell. The support-cell rows for
`qseries_phylo_q1_mu_one_slope`, `qseries_spatial_q1_mu_one_slope`,
`qseries_animal_q1_mu_one_slope`, and
`qseries_relmat_q1_mu_one_slope` remain `fit_status = point_fit`,
`interval_status = planned`, and `coverage_status = planned`.

I added `tools/run-structured-re-gaussian-mu-slope-coverage-pregrid.R` and ran
the full local SR150 retained-outcome pregrid. The runner fits once per
provider/seed and evaluates the exact target endpoints from
`structured-re-gaussian-mu-slope-coverage-pregrid-dry-run.tsv`. Failed fits,
`!pdHess`, failed `confint()`, non-finite intervals, and boundary/non-Wald
statuses stay in the retained denominator rather than being dropped.

The current artifact was rerun after `R/profile.R` learned that component rows
such as `phylo(1 | species)` and `phylo(0 + x | species)` belong to the
structured block labelled `phylo(1 + x | species)`. That restored the documented
location-axis t-width and `log(g/(g-1))` centre shift for q1 structured `mu`
slope SD targets.

The executed pregrid is negative admission evidence for all four rows. The
widget now displays each as `mu_slope_pregrid_blocked`.

## 3a. Decisions and Rejected Alternatives

The retained-denominator coverage numerator is deliberately strict: an unusable
interval is counted as not covered for the all-replicate coverage rate. This
prevents survivor coverage from hiding boundary and Hessian problems.

Rejected alternatives: I did not top up to SR500/SR1000 after the SR150 result,
because the pregrid found finite-interval, boundary, low retained-coverage, and
right-tail miss issues before the MCSE gate could be the limiting problem. I
also did not promote spatial from its cleaner retained coverage by analogy; the
spatial slope target still had boundary/non-Wald statuses and upper misses.

## 4. Files Touched

- `tools/run-structured-re-gaussian-mu-slope-coverage-pregrid.R`
- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-coverage-pregrid-results.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-coverage-pregrid-local/`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-coverage-pregrid.md`

## 5. Checks Run

```sh
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-gaussian-mu-slope-coverage-pregrid.R --n-rep=2 --output-dir=/tmp/drmtmb-gaussian-mu-slope-pregrid-smoke --overwrite=true
Rscript --no-init-file -e 'parse("tools/run-structured-re-gaussian-mu-slope-coverage-pregrid.R")'
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-gaussian-mu-slope-coverage-pregrid.R --n-rep=150 --overwrite=true
python3 -m py_compile tools/validate-mission-control.py
sed -n '/<script>/,/<\/script>/p' docs/dev-log/dashboard/index.html | sed '1d;$d' | node --check -
R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py
git diff --check
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'
R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-coverage-pregrid.md')"
DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background
curl -fsS http://127.0.0.1:8765/version.txt
```

Results: the SR150 run wrote four dashboard result rows, eight target summary
rows, 600 fit-status rows, 1200 retained target-replicate rows, `sessionInfo`,
`git-sha`, and a run log. Dashboard JavaScript syntax passed and
`tools/validate-mission-control.py` reported `mission_control_ok`. The focused
structured-RE conversion test passed with 6353 PASS / 0 FAIL / 0 WARN / 0 SKIP,
`git diff --check` passed, the after-task structure check passed, and the served
dashboard reported build `r91`.

## 6. Tests of the Tests

The mission-control validator now checks the four executed SR150 result rows,
the exact linked Gaussian q1 `mu` support cells, the 600 fit rows, 1200
retained target-replicate rows, eight target summary rows, four provider
summary rows, the artifact directory, the `mu_slope_pregrid_blocked` widget
state, the `planned` interval/coverage support-cell status, and the
no-promotion claim boundary.

The runner was first exercised with `--n-rep=2` into `/tmp`, which caught
script integration issues without overwriting the final artifact directory.

## 7a. Issue Ledger

No GitHub issue action was taken in this slice. The work updates local
mission-control evidence on the current Q-Series branch and does not open or
close a public capability claim.

## 8. Consistency Audit

The SR150 target summaries are:

- animal: one eligible target and one visible holdout; the eligible slope SD
  had 122/150 usable intervals, retained coverage 0.813, 27 boundary/non-Wald
  statuses, and one `!pdHess` fit.
- phylo: 291/300 usable intervals across two targets, retained coverage
  0.940-0.947, three lower misses, and five upper misses.
- relmat: 297/300 usable intervals, retained coverage 0.953-0.973, two lower
  misses, and six upper misses.
- spatial: 297/300 usable intervals, retained coverage 0.947-0.960, six lower
  misses, and five upper misses.

All four widget rows are therefore `mu_slope_pregrid_blocked`; none are
`inference_ready`, `supported`, or top-up-ready.

## 9. What Did Not Go Smoothly

The first `--n-rep=2` rehearsal wrote a temporary dashboard result sidecar with
two-replicate values. The full SR150 run immediately overwrote it. I also
tightened the target-gate logic after inspecting the first SR150 output,
because low retained coverage in phylo and relmat intercept targets should not
be described as a simple top-up problem.

## 10. Known Residuals

Gaussian q1 `mu` one-slope intervals are not admission-ready. The default
small-sample correction now applies to the intended component targets, and
phylo/relmat/spatial retained coverage is close to nominal at SR150. The main
residuals are boundary/non-Wald statuses in slope targets, the visible animal
intercept holdout, and SR150 MCSE above the inference gate. The next work should
separate boundary-profile geometry from a possible retained-denominator top-up
for phylo/relmat/spatial.

## Next Actions

Add a diagnostic follow-up that separates boundary/non-Wald interval failures
from retained-coverage calibration failures for the q1 `mu` slope targets. Do
not launch SR1000 as a promotion run until the SR150 blockers are understood.

## 11. Team Learning

A pregrid can legitimately be negative evidence. A failed admission rung can
also expose implementation coverage: the q1 `mu` slope pregrid showed that the
documented default correction was not reaching decomposed slope components until
the group-count matcher was fixed.

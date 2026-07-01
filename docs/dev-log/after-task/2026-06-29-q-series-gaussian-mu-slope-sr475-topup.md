# After Task: Q-Series Gaussian Mu-Slope SR475 Top-Up

## 1. Goal

Run the retained-denominator top-up for the Gaussian q1 `mu` one-slope phylo,
relmat, and spatial rows, then combine it with the repaired SR150
boundary-profile evidence without promoting any support-cell status.

## 2. Implemented

This promotes exactly no support cell. The linked Q-Series rows remain
`fit_status = point_fit`, `interval_status = planned`, and
`coverage_status = planned`.

I ran the generated-seed top-up for phylo, relmat, and spatial over replicate
indices 151-475. The top-up artifact under
`docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-topup-sr475-local/`
has 325 generated seeds, 975 fit-status rows, 1950 retained target-replicate
rows, six target summaries, and three provider summaries. All 975 fits
converged with `pdHess = TRUE`.

I then ran the endpoint-profile boundary diagnostic on the 27 top-up
boundary/non-Wald rows. The boundary artifact under
`docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-topup-boundary-profile-local/`
has 27 detail rows and three provider summaries.

Finally, I added `tools/summarize-structured-re-gaussian-mu-slope-hybrid-sr475.R`.
It overlays the original SR150 boundary-profile repairs and the top-up
boundary-profile repairs, then writes
`docs/dev-log/dashboard/structured-re-gaussian-mu-slope-hybrid-sr475-audit.tsv`
and a six-row target summary. The widget now displays phylo, relmat, and
spatial as `mcse_met_upper_tail_blocked`, not `inference_ready`.

## 3a. Decisions and Rejected Alternatives

Animal was deliberately excluded from the top-up because the SR150 hybrid audit
already showed a hard negative: 132/150 covered, coverage 0.880, and 15 upper
misses.

Rejected alternatives: I did not edit
`docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`, because the
combined SR475 evidence still has upper-tail miss imbalance and one
profile-failed row per provider. I also did not call the MCSE-qualified
denominator `inference_ready`; MCSE is necessary evidence, not sufficient
evidence.

## 4. Files Touched

- `tools/run-structured-re-gaussian-mu-slope-coverage-pregrid.R`
- `tools/run-structured-re-gaussian-mu-slope-boundary-profile-diagnostic.R`
- `tools/summarize-structured-re-gaussian-mu-slope-hybrid-sr475.R`
- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-hybrid-sr475-audit.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-sr475-topup.md`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-topup-sr475-local/`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-topup-boundary-profile-local/`

## 5. Checks Run

```sh
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-gaussian-mu-slope-coverage-pregrid.R --n-rep=325 --seed-start=151 --providers=phylo,relmat,spatial --output-dir=docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-topup-sr475-local --write-dashboard=false --overwrite=true
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-gaussian-mu-slope-boundary-profile-diagnostic.R --source-replicates=docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-topup-sr475-local/structured-re-gaussian-mu-slope-coverage-pregrid-replicates.tsv --output-dir=docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-topup-boundary-profile-local --write-dashboard=false --overwrite=true
air format tools/summarize-structured-re-gaussian-mu-slope-hybrid-sr475.R
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'invisible(parse("tools/summarize-structured-re-gaussian-mu-slope-hybrid-sr475.R"))'
R_PROFILE_USER=/dev/null Rscript --no-init-file tools/summarize-structured-re-gaussian-mu-slope-hybrid-sr475.R --overwrite=true
python3 -m py_compile tools/validate-mission-control.py
R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py
sed -n '/<script>/,/<\/script>/p' docs/dev-log/dashboard/index.html | sed '1d;$d' | node --check -
```

Results: mission control reported `mission_control_ok` with three Gaussian
mu-slope hybrid-SR475 audit rows. Dashboard JavaScript syntax passed.

## 6. Tests of the Tests

The mission-control validator now checks the SR475 audit schema, the exact
three row ids, the combined denominator counts, source artifact paths,
support-cell links, no-promotion status, claim-boundary phrases, and the six
target-summary rows. It fails if any SR475 target summary drops below
`target_signal = mcse_met` or changes the target denominator away from 475.

## 7a. Issue Ledger

No GitHub issue action was taken. This is local evidence and widget routing
work inside the Q-Series completion arc.

## 8. Consistency Audit

The combined SR475 hybrid audit is:

- phylo: 913/950 covered, 949/950 usable intervals, coverage 0.9611, MCSE
  0.006277, lower/upper misses 5/31, one profile failure. Worst target is
  `mu:x`: coverage 0.9537, MCSE 0.009643, lower/upper misses 1/20.
- relmat: 926/950 covered, 949/950 usable intervals, coverage 0.9747, MCSE
  0.005091, lower/upper misses 3/20, one profile failure. Worst target is
  `mu:(Intercept)`: coverage 0.9621, MCSE 0.008761, lower/upper misses 2/16.
- spatial: 912/950 covered, 949/950 usable intervals, coverage 0.9600, MCSE
  0.006358, lower/upper misses 15/22, one profile failure. Worst target is
  `mu:(Intercept)`: coverage 0.9600, MCSE 0.008991, lower/upper misses 8/11.

All six target-level MCSE values are `<= 0.01`. That is stronger evidence than
SR150, but the upper-tail miss imbalance and profile failures still block
`inference_ready` without Fisher and Rose review.

## 9. What Did Not Go Smoothly

The stronger denominator did not cleanly resolve the interval question. It
reduced MCSE as intended, but it confirmed that the remaining blocker is not
just sample size: the boundary-profile rows continue to miss on the upper side.

## 10. Known Residuals

Phylo, relmat, and spatial q1 `mu` one-slope rows need Fisher/Rose review of
one-sided misses and profile failures before any status edit. A skew-aware or
boundary-aware interval path may be needed before promotion. Animal remains
blocked by the SR150 hard negative and was not top-up eligible.

## Next Actions

Have Fisher and Rose audit the SR475 sidecar. If they block promotion, open the
next interval-channel arc around the near-boundary upper-tail misses rather
than adding more plain top-up replicates.

## 11. Team Learning

Top-up denominators can change the uncertainty question from “not enough
replicates” to “wrong tail shape.” The widget should show that distinction
explicitly so the team does not keep buying more replicates when the interval
channel is the real blocker.

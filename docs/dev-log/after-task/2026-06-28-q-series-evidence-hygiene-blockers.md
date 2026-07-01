# Q-Series evidence hygiene blockers

## 1. Goal

Make the Q-Series widget and validator more useful for the 104-row board
without changing any tier/status claim. This tranche separates recovery,
stability, admission, interval readiness, and coverage readiness for two
drift-prone areas:

- count q1 `mu` one-slope recovery rows;
- spatial/animal q2 `mu1+mu2` one-slope bias+t endpoint evidence.

## 2. Implemented

This promotes exactly no support cell under no interval channel with no
denominator-policy change and does not claim q2 correlation-target coverage,
range-estimating spatial support, pedigree/Ainv bridge marshalling, q4/q8,
non-Gaussian intervals, REML, AI-REML, bridge support, `supported`, or public
support.

Added `structured-re-q2-slope-bias-t-coverage-evidence.tsv`, a four-row
sidecar for spatial/animal q2 SD endpoints after the default bias+t
revalidation. Each row has `promotion_status = block_row_promotion`.

Updated `structured-re-q2-slope-spatial-animal-admission-audit.tsv` so the
widget now cites the measured q2 bias+t endpoint evidence:

- spatial stays `calibration_required`;
- animal stays `admission_blocked`.

Fixed the count recovery sidecar for `recov_spatial_nbinom2_q1_mu_one_slope`.
The row still has 80/80 fit_ok and 80/80 finite estimates, but it now records
that 2/80 fits have `pdHess = FALSE`; it carries a Hessian caveat instead of a
`pdHess clean` claim.

Updated `tools/validate-mission-control.py` and
`tests/testthat/test-structured-re-conversion-contracts.R` so these claim
boundaries are executable:

- positive `pdhess_false` rows cannot say `pdHess clean`;
- q2 bias+t endpoint rows must keep linked support cells at planned interval
  and coverage status;
- the new sidecar must keep the exact SR475 coverage, MCSE, and miss counts.

Updated dashboard and design prose, revised the stale spatial/animal q2 runner
header, and bumped the mission-control widget build to `r79`.

## 3a. Decisions and Rejected Alternatives

I kept the support-cell `evidence_url` fields pointing at the original parity
fixtures where the validator requires them. The blocker evidence now flows
through admission sidecars, which the widget already joins into the 104-row
table. This keeps downstream fixture ledgers stable while still surfacing the
current blockers near the top of the widget.

I did not promote spatial q2. The spatial `mu2:x` endpoint is below nominal
after bias+t at 0.9411 with MCSE 0.0108 and 24 upper-tail misses. The
endpoint-only sidecar also does not settle the q2 correlation target.

I did not promote animal q2. The animal `mu2:x` endpoint is borderline at
0.9474 with MCSE 0.0102, and the correlation target still has no coverage-grid
row after the denominator holdout.

I did not change any q4/q8 wording into an inference claim. The design map now
says the g-sweep diagnostics show some walls relax at larger g, but q4 remains
diagnostic-only and q8 remains stability-first.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-slope-bias-t-coverage-evidence.tsv`
- `docs/dev-log/dashboard/structured-re-q2-slope-spatial-animal-admission-audit.tsv`
- `docs/dev-log/dashboard/structured-re-count-slope-recovery-results.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-bias-corrected-coverage-g8-spatial-animal.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-28-q-series-evidence-hygiene-blockers.md`

## 5. Checks Run

- Ada audit: close evidence hygiene before additional tier work.
- Fisher audit: no new inference-ready row is justified; spatial/animal q2 and
  spatial sigma remain blocked.
- Rose audit: count recovery `pdHess` caveat and q2 blocker wording needed
  validator guards before more status work.
- `python3 tools/validate-mission-control.py`: passed with
  `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e
  'devtools::test(filter = "structured-re-conversion-contracts")'`: 6278 PASS /
  0 FAIL.
- `git diff --check`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e
  'devtools::test()'`: 19657 PASS / 0 FAIL / 17 warnings / 43 skips.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e
  'devtools::check()'`: 0 errors / 0 warnings / 0 notes.

## 6. Tests of the Tests

The mission-control validator now reads and validates the new q2 bias+t
coverage-evidence sidecar. It checks exact row ids, linked support cells,
provider/endpoint identity, seed range, attempted reps, bias+t coverage, MCSE,
one-sided misses, raw Wald coverage, blocker status, and claim-boundary
phrases.

The focused R contract test checks the same sidecar and the count recovery
Hessian caveat. The first focused run failed because I briefly pointed
support-cell evidence URLs at admission/blocker ledgers instead of the original
fixture ledgers. That failure was useful: it preserved the support-cell table as
the stable fixture source of truth while the admission sidecars carry blocker
evidence.

## 7a. Issue Ledger

- `qseries_spatial_q2_mu1_mu2_one_slope`: still planned; needs row-specific
  retained-denominator bias+t/top-up plus correlation-target handling and
  Fisher/Rose sign-off.
- `qseries_animal_q2_mu1_mu2_one_slope`: still planned; correlation endpoint
  denominator holdout must be repaired before coverage wording.
- `qseries_spatial_q1_sigma_one_slope`: still blocked; SR1000 finite-Wald rate
  for `sigma:(Intercept)` is 0.9360, below the 0.95 gate.
- `recov_spatial_nbinom2_q1_mu_one_slope`: recovery-only with a Hessian caveat,
  not a clean-Hessian recovery row.

No GitHub issue was opened. This is a PR #685 evidence-hygiene tranche.

## 8. Consistency Audit

The Q-Series board still has exactly 104 rows and exactly five
interval+coverage `inference_ready` rows:

- `qseries_phylo_q1_sigma_one_slope`;
- `qseries_animal_q1_sigma_one_slope`;
- `qseries_relmat_q1_sigma_one_slope`;
- `qseries_phylo_q2_mu1_mu2_one_slope`;
- `qseries_relmat_q2_mu1_mu2_one_slope`.

No structured row is `supported`. The q2 bias+t evidence is explicitly
endpoint-only; count rows are explicitly recovery-only; q4/q8 remain
diagnostic/stability work.

## 9. What Did Not Go Smoothly

The first mission-control run rejected my attempt to move support-cell
`denominator_policy` and `evidence_url` fields toward blocker ledgers. Those
fields are fixture contracts used by many downstream ledgers, so I restored
them and carried the blocker evidence through admission sidecars instead.

The first focused R test also caught case-sensitive wording: the support-cell
claim boundary needed the exact lowercase phrase `fixed-covariance`.

## 10. Known Residuals

Spatial/animal q2 still need real row-level follow-up before any promotion.
The next scientific tranche should either top up/rework spatial q2 and repair
animal q2 correlation denominator admission, or move to a recovery-only
non-Gaussian count tranche. q4/q8 remain out of inference promotion scope.

## 11. Team Learning

Keep the support-cell table as the stable row identity/fixture contract, and
put evolving blocker evidence into admission/evidence sidecars that the widget
joins onto the row. It gives the table a single durable shape while still
letting evidence mature honestly.

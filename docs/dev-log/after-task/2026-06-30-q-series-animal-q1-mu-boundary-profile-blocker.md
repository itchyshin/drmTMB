# After Task: Q-Series Animal q1 Mu Boundary-Profile Blocker

## Goal

Make the animal q1 `mu:(Intercept)` retained-boundary evidence visible as a
route blocker, not as an unresolved top-up candidate.

## Implemented

This promotes exactly no Q-Series row. The animal q1 `mu:(Intercept)` support
cell now points at
`structured-re-gaussian-lowq-mu-intercept-animal-boundary-profile.tsv`, while
phylo, spatial, and relmat q1 `mu:(Intercept)` rows keep their SR475
inference-ready evidence. The dashboard, Gaussian low-q audit, row-selection
table, validator, and focused conversion-contract tests now agree on the
animal blocker.

## Mathematical Contract

The target is the direct structured SD on the `mu` axis for
`animal(1 | id, A = A)` under the Gaussian q1 intercept model. The SR475
aggregate retained all attempted fits; seeds `812407` and `812444` produced
Wald-at-boundary intervals. Local replay shows endpoint profiles finite 2/2
but upper-missing 2/2 against truth 0.55, while the full `tmbprofile` fallback
is finite 0/2. The blocker is interval route shape, not Monte Carlo precision.

## Files Changed

- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-30-q-series-animal-q1-mu-boundary-profile-blocker.md`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`

## Checks Run

Initial syntax gates passed:

- `python3 -m py_compile tools/validate-mission-control.py`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'invisible(parse("tools/summarize-structured-re-gaussian-lowq-mu-intercept-animal-boundary-profile.R")); invisible(parse("tests/testthat/test-structured-re-conversion-contracts.R"))'`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 104 Q-Series support cells and 1
  animal q1 `mu` boundary-profile blocker row.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  passed, 10226 tests / 0 failures / 0 warnings / 0 skips.

## Tests Of The Tests

The validator now requires exactly one animal boundary-profile sidecar row, the
two hard replay seeds, endpoint finite 2/2, endpoint coverage 0.0000, endpoint
misses lower=0/upper=2, `tmbprofile` finite 0/2, and
`fisher_gauss_rose_boundary_profile_blocked_no_topup`. The focused test now
expects the animal support cell and low-q audit to point at the blocker sidecar
while promoted phylo/spatial/relmat rows still point at the SR475 evidence.

## Member Review

Fisher blocks top-up because both repaired endpoint intervals miss high and the
fallback profile route is non-finite. Gauss treats this as a route-geometry
problem for the animal A-matrix direct-SD target, not a denominator-size
problem. Rose blocks any status promotion or host submission until a new animal
q1 `mu` interval route is designed or an explicit blocker decision is written.

## Consistency Audit

The 104-row support-cell table keeps animal q1 `mu:(Intercept)` at
`point_fit/planned/planned`. The Gaussian low-q audit, row-selection sidecar,
closure queue, and evidence URL all point at the boundary-profile blocker. The
dashboard build marker was advanced to `r190` to match `version.txt`.

## GitHub Issue Maintenance

No GitHub issue or PR comment was changed in this sync. This is local
mission-control and evidence-ledger consistency work.

## What Did Not Go Smoothly

The old SR475 aggregate, row-selection, and validator wording still treated
animal as a possible top-up route. The hard-seed replay changed the decision
boundary: more replicas on the same route would only measure the upper-miss
problem more precisely.

## Team Learning

When a retained-denominator aggregate has only a small number of boundary
rows, replay those hard seeds before scheduling more cluster work. If the hard
seeds show route-shape failure, stop and write a blocker instead of spending
Totoro or DRAC time on a larger denominator.

## Known Limitations

This does not solve animal q1 `mu` inference. It does not create a new profile,
skew-aware, REML, or bootstrap route and does not change q1 `sigma`, matched
`mu+sigma`, q2, q4/q8, non-Gaussian, bridge, or public support status.

## Next Actions

For Tranche 2, either design a new animal q1 `mu` interval route or move to the
next exact low-q candidate whose blocker is not already measured. Do not submit
animal q1 `mu` top-up jobs on Totoro, FIIA, Nibi, Rorqual, Trillium, or DRAC
from the current Wald/profile route.

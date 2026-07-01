# After Task: Q-Series q4 Animal Production-Transform Design Gate

## 1. Goal

Record the member consensus for the q4 animal all-four next gate before any
new local runner, Nibi/Rorqual admission rerun, or DRAC coverage grid. The
question was whether the connected compute should be used now. The answer is
no: this row needs lower-level TMB parameterization design first.

## 2. Implemented

Added `docs/design/220-structured-q4-animal-production-transform-gate.md`. The
design note states that the animal all-four one-slope row is q8-shaped in the
implementation, with eight structured endpoints and 28 `theta_phylo`
correlation coordinates under the current full q>2
`density::UNSTRUCTURED_CORR_t(theta_phylo)` route.

Updated the Q-Series queue, high-q audit, support-cell next gate, transform
contract, dashboard README, and mission-control validator/test expectations so
the next action is:

1. write and test a lower-level TMB parameterization design;
2. only then implement a production-transform admission experiment;
3. hold Nibi/Rorqual and DRAC until local hard-seed admission passes.

No support-cell status changed.

## 3a. Decisions and Rejected Alternatives

Gauss, Noether, and Fisher agreed that another optimizer-layer wrapper around
current `theta_phylo` is not a production-transform admission experiment. The
bounded, ridge, one-theta, and ridge-continuation routes remain diagnostic
blocker localization.

Rejected alternatives:

- Do not launch Nibi/Rorqual or DRAC from the current transform contract.
- Do not call a finite-cap `theta = cap * tanh(eta)` route production unless it
  is proven equivalent to the same full q>2 positive-definite correlation
  manifold.
- Do not use optimizer-layer ridge penalties, cap saturation, large-theta rows,
  convergence-watch rows, or Hessian-blocked rows as admission passes.

## 3b. Mathematical Contract

The current animal all-four route uses the full q>2 TMB unstructured
correlation transform. A candidate production transform must either preserve
that model space and likelihood target, or explicitly declare itself a
constrained diagnostic model. Objective-equivalence tests must compare C++ and
R reconstructions of `phylo_q4_corr`, `phylo_q4_covariance`, log determinant,
quadratic form, and objective value with penalties off.

## 4. Files Touched

- `docs/design/220-structured-q4-animal-production-transform-gate.md`
- `docs/design/03-likelihoods.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/dashboard/structured-re-q4-animal-transform-admission-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `docs/dev-log/dashboard/structured-re-high-q-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q4-animal-transform-admission-contract.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q4-animal-production-transform-design-gate.md`

## 5. Checks Run

- `python3 tools/validate-mission-control.py`: rerun after the design gate
  wiring.
- `awk '/<script>/{flag=1; next} /<\\/script>/{flag=0} flag {print}'
  docs/dev-log/dashboard/index.html > /tmp/drmtmb-dashboard-index.js &&
  node --check /tmp/drmtmb-dashboard-index.js`: dashboard JavaScript parse
  check.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: focused Q-Series contract test.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q4-animal-production-transform-design-gate.md')"`:
  after-task structure check.
- `git diff --check`: whitespace check.
- `curl -fsS http://127.0.0.1:8765/version.txt`: served dashboard build
  `r129`.
- System-Chrome Playwright smoke against `http://127.0.0.1:8765/`: rendered
  the Q-Series board with `Total rows = 104`, `Inference-ready = 5`, campaign
  queue `10`, `High-q = 24`, and `q8 = 9`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::check()'`: passed in 12m 48.6s with 0 errors,
  0 warnings, and 0 notes.

## 6. Tests of the Tests

The mission-control validator and focused conversion-contract test now require
every transform-admission row to mention `lower-level TMB parameterization
design` in its next gate. This makes stale cluster-first wording fail before a
DRAC or Nibi/Rorqual job can be justified by the widget.

## 7a. Issue Ledger

No GitHub issue was opened or closed in this slice. This is local
mission-control gating inside the Q-Series high-q arc.

## 8. Consistency Audit

The linked support cell remains `diagnostic_only` / `planned`. The dashboard
build is `r129`. The queue, support cell, high-q audit, transform contract,
README, design notes, validator, and focused test all point to design-first
work before any cluster admission.

## 9. What Did Not Go Smoothly

The first instinct was to implement a runner, but member review showed that
would only create another optimizer-layer diagnostic unless the TMB
parameterization itself is designed and tested first.

## 10. Known Residuals

No C++ parameterization has been implemented in this slice. Animal q4 all-four
admission remains blocked. The DRAC and Totoro/FIIA compute resources are
available campaign capacity, but they are intentionally held for this row until
the local TMB design and hard-seed admission gate pass.

## 11. Team Learning

Connected compute is useful only after the row contract is executable. For
q4 animal all-four, the next scarce resource is not DRAC time; it is a precise
TMB parameterization design with equivalence tests.

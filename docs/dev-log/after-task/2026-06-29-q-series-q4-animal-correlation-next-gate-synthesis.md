# After Task: Q-Series q4 animal correlation next-gate synthesis

## 1. Goal

Reconcile the q4 animal all-four one-slope widget state with Gauss and Noether
review after the bounded-correlation diagnostic localized the blocker to the
free q4 correlation block.

## 2. Implemented

This promotes exactly no Q-Series row. It updates source-of-truth status text
only: the animal q4 all-four one-slope row still has point/extractor and
fixture parity evidence, but interval status remains `diagnostic_only` and
coverage status remains `planned`.

The support-cell row now says the exact eight-member endpoint map is fixture
ready, while the active blocker is the free q4 correlation block: zero-
correlation controls pass, all-free staged fits fail, and cap-bounded
continuations saturate. The high-q audit now links the animal all-four
q8-shaped row to
`structured-re-q4-animal-bounded-correlation-diagnostic.tsv`, and the campaign
queue names the next local diagnostic: one-theta release from the
zero-correlation map on the hard seeds, before MAP/penalty sensitivity or any
DRAC coverage grid.

## 3a. Decisions and Rejected Alternatives

Decision: use Noether's one-theta release diagnostic as the first next gate.
It is the smallest diagnostic that can distinguish a few identifiable
problematic correlation coordinates from general 28-correlation
overparameterization.

Decision: keep Gauss's MAP/penalty sweep as sensitivity work after the
one-theta diagnostic, not as a direct admission or support route.

Rejected alternatives:

- Do not launch DRAC coverage from cap-saturated bounded fits.
- Do not treat zero-correlation map success as support for the unrestricted
  all-free q4 correlation model.
- Do not promote q4/q8 interval status, coverage, `inference_ready`,
  `supported`, REML, AI-REML, bridge support, or public support from this
  synthesis.

## 3b. Mathematical Contract

No likelihood, formula grammar, estimator, interval channel, or TMB
parameterization changed. The row remains the animal A-matrix all-four
one-slope model:

- `mu1 = y1 ~ x + animal(1 + x | p | id, A = A)`
- `mu2 = y2 ~ x + animal(1 + x | p | id, A = A)`
- `sigma1 = ~ z + animal(1 + x | p | id, A = A)`
- `sigma2 = ~ z + animal(1 + x | p | id, A = A)`
- `rho12 = ~ 1`

The next diagnostic target is identifiability of the 28 nuisance correlation
coordinates in the implied eight-axis animal covariance block. The direct
admission estimands remain the eight SDs:
`mu1:(Intercept)`, `mu1:x`, `mu2:(Intercept)`, `mu2:x`,
`sigma1:(Intercept)`, `sigma1:x`, `sigma2:(Intercept)`, and `sigma2:x`.
Derived correlations remain nuisance diagnostics, not interval targets.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-high-q-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q4-animal-correlation-next-gate-synthesis.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 104 structured RE q-series cells,
  24 structured RE high-q status-audit rows, 15 structured RE q4 animal
  bounded-correlation diagnostic rows, and 10 structured RE q-series
  next-campaign queue rows.
- `git diff --check`: passed.

## 6. Tests of the Tests

The mission-control validator caught two useful drift points before this report:
`version.txt` and `index.html` had mismatched build markers, and the support-cell
claim boundary had lost exact guard phrases required by the q4 parity-fixture
contract. Those failures were fixed by bumping the dashboard `BUILD` to `r123`
and restoring the required exact-eight-member and `pedigree/Ainv` wording.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This was an internal
mission-control status synchronization based on local Gauss/Noether review.

## 8. Consistency Audit

Checked the support-cell row, high-q audit row, campaign queue, dashboard
README, mission-control validator, and dashboard build marker. The current
board still has 104 rows, five interval-and-coverage `inference_ready` rows,
zero `supported` rows, 24 high-q rows, and nine q8 rows. No q4 or q8 row is
newly promoted.

## 9. What Did Not Go Smoothly

The first wording patch was directionally correct but too loose for existing
contracts: it lost the exact phrase `exact eight-member endpoint map`, changed
the case of `pedigree/Ainv`, and left the high-q stability signal without one
of the validator's stability/Hessian/pdHess guard words. Mission control caught
those problems before the widget was refreshed.

## 10. Known Residuals

This synthesis does not run the one-theta release diagnostic. It does not
validate MAP/penalty sensitivity, q4 admission, q4 coverage, q8 inference,
REML, AI-REML, bridge support, derived-correlation intervals, or public support.

## 11. Team Learning

For high-q rows, next-gate text is part of the scientific contract. It should
name the smallest diagnostic that answers the current blocker, not a generic
"more interval diagnostics" step.

## 12. Next Actions

Implement and run a local hard-seed one-theta release diagnostic for seeds
`910101`, `910102`, and `910110`. Record objective gain versus the
zero-correlation map, `pdHess`, fixed-gradient maximum, `theta` magnitude,
`sdr$cov.fixed` eigenvalues, and direct-SD shifts for each released coordinate.

# After Task: Gamma animal SD likelihood runtime check

## 1. Goal

Resolve a static audit concern about predictor-dependent structured SDs in the
native Gamma likelihood, and verify the existing animal intercept and
slope-only routes against the current candidate source.

## 2. Implemented

No production code changed. The current TMB `model_type == 5` branch computes
the group SD from `X_sd_phylo` and `beta_sd_mu`, applies it to the structured
field, and evaluates the latent field's Gaussian penalty using `Q_phylo`.
The earlier static claim that the branch ignored the SD design was incorrect.
The two focused native tests
pass on the current source: the animal intercept and provider-equivalence
fixture passed 14 assertions, and the slope-only fixture passed 15.

## 3a. Decisions and Rejected Alternatives

The verified estimands remain separate q1 routes. The intercept test does not
prove intercept-plus-slope support, and the slope test does not prove a
combined intercept and slope model. A correlated `animal(1 + x | id)` block
would differ from two independent fields and is not a substitute for that
capability row.

## 4. Files Touched

This report, `docs/dev-log/check-log.md`, and
`LOOP/lanes/general-sd-regression/checkpoint.md`.

## 5. Checks Run

- `Rscript -e 'devtools::test(filter = "gamma-animal-pedigree-sd-regression")'` exited 0: 14 passed, 0 failed, 0 warnings, 0 skips.
- `Rscript -e 'devtools::test(filter = "gamma-animal-slope-sd-regression")'` exited 0: 15 passed, 0 failed, 0 warnings, 0 skips.
- `python3 tools/general-sd-regression/reconcile_evidence.py` passed with 19,118 candidate rows, 32 receipt records, 26 linked rows, and 19,092 unlinked rows.
- `python3 tools/general-sd-regression/tests/test_reconcile_evidence.py` passed 11/11.
- The Julia Poisson animal test could not launch locally because the only installed Julia is 1.6 while the project targets 1.10. The existing Totoro ControlMaster socket was blocked by the sandbox. This is an environment limitation, not a test result.

## 6. Tests of the Tests

The two native fixtures use fixed seeds and fitted synthetic animal models. The
intercept test checks coefficient recovery, group-keyed SD predictions,
pedigree/A/Ainv likelihood agreement, and constant-SD equivalence. The
slope-only test checks coefficient recovery, group-keyed predictions,
simulation, reload, constant-SD equivalence, and a within-group-varying SD
predictor rejection. These checks do NOT test a combined animal intercept and
slope model.

## 7a. Issue Ledger

No GitHub issue was changed. The earlier issue search for this programme could
not reach GitHub's API; issue overlap remains unknown.

## 8. Consistency Audit

The source and runtime checks agree for the two q1 routes. The combined
intercept-plus-slope animal route remains unimplemented in both engines and
must stay open in the capability ledger. No support or calibration claim was
promoted.

## 9. What Did Not Go Smoothly

The initial static review mistook a different likelihood branch for Gamma's
current branch. Reading the exact `model_type == 5` code and running both
focused tests resolved that discrepancy. This Mac cannot execute the required
Julia 1.10 test environment, and the existing Totoro socket was inaccessible
from this sandbox.

## 10. Known Residuals

The combined structured intercept-plus-slope route remains open. Julia runtime
verification is still needed for any new Julia edits. Broader family/effect
coverage, output parity, interval calibration, package-wide checks, and the
remaining programme gates are unchanged.

## 11. Team Learning

For a likelihood concern, first bind the review to the exact family dispatch
and then run its narrowest existing fixture. A passing q1 test must not be
described as evidence for a combined q2 layout.

## 12. Cross-Product Coverage

This check covers only native Gamma animal q1 intercept and slope-only
fixtures. It does NOT cover a combined intercept-plus-slope animal effect,
Julia runtime behavior, other families, or interval calibration.

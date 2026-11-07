# After Task: Binomial Animal and IID Independent Laplace Oracle

## 1. Goal

Check the combined Binomial animal and IID-intercept SD fit against an
independent likelihood calculation on the same data used for the TMB/Julia
comparison.

## 2. Implemented

Added an R-side dense joint-Laplace oracle to the existing cross-engine test.
The oracle reconstructs the animal covariance and IID site precision, then
optimizes the latent mode and evaluates its Hessian without calling either
engine's likelihood implementation. Both engines' fitted log likelihoods
match the oracle within `2e-4`. The existing test also compares covariance
`A` with its equivalent precision `Ainv`.

The focused test passed 37 expectations with one live Julia bridge test.
Before/after hashes for the R test, bridge, TMB model, Julia fitter, bridge,
inference, and direct Julia test are identical. The evidence overlay now links
60 receipts to 49 of 19,118 candidate rows; 19,069 rows have no linked
receipt. No row was promoted and no programme gate closed.

## 3a. Decisions and Rejected Alternatives

I reused the existing same-data bridge fixture and added the missing
independent calculation there. The paired Julia test already had a dense
Laplace oracle on a separate Julia-generated dataset, so adding another Julia
fixture would not strengthen the same-data cross-engine check. The oracle
evaluates the Laplace approximation at each fitted parameter vector; it does
not claim exact marginal-likelihood integration or coverage calibration.

Assumption: both engines should optimize the same Laplace objective for this
specific q1 animal plus q1 IID model. A difference beyond `2e-4` would require
investigation of the kernel or integration semantics, not a wider tolerance.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-animal-iid-sd-parity.R`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/general-sd-regression/inventory.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/general-sd-regression/evidence/binomial-animal-iid-independent-oracle-20261024/`
- `docs/dev-log/after-task/2026-10-24-binomial-animal-iid-independent-laplace-oracle.md`

No model source changed. The frozen `required-rows.tsv` file was not changed.

## 5. Checks Run

- R parser check for the modified test: passed.
- Focused opt-in bridge filter: passed, 37 expectations and one live Julia
  test. Captured stdout is `evidence/binomial-animal-iid-independent-oracle-20261024/console.log`.
- Before/after SHA-256 manifests for nine R/TMB and Julia source/test files
  matched exactly; see `source-before.sha256` and `source-after.sha256`.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: passed with 60
  receipt records, 49 linked rows, and 19,069 unlinked rows.
- The evidence reconciliation unit tests passed 11 tests; the frozen-universe
  suite passed 17 tests earlier in this same execution arc.
- Scoped `git diff --check`, the closeout compiler, and the prose slop check
  passed. Full package checks and coverage simulations were not run.

## 6. Tests of the Tests

The new oracle rebuilds the random-effect design matrix, block precision, mode,
and Hessian independently from the fitted values. It checks both the TMB and
Julia likelihoods on the same observations. No deliberate wrong-index or
wrong-scale sabotage run was added; the check is scoped to this fixture and
does not prove all covariance paths are correct.

## 7a. Issue Ledger

No issue was searched, opened, edited, or closed in this slice.

## 8. Consistency Audit

The R oracle uses the supplied non-unit-diagonal animal `A` and separate IID
site effects, matching the documented fixture. The Julia-side dense oracle
uses the same covariance construction on its own synthetic dataset. The new
same-data oracle is an additional check and does not change existing
simulation, prediction, fitting, or kernel semantics.

## 9. What Did Not Go Smoothly

The saved checkpoint named this same-data comparison as outstanding, but the
worktree already contained it. Inspection showed that its missing piece was an
independent oracle on that exact fixture. The scope was reduced to that gap;
no duplicate bridge or second generator was added.

## 10. Known Residuals

This is one complete-data logit Binomial fixture with one animal intercept and
one IID site intercept. The oracle validates the implemented Laplace
approximation at fitted parameters; it is not an exact integral, a repeated
sample recovery study, or evidence that 95% intervals have correct coverage.
Other response families, provider combinations, and public workflows remain
unresolved in the required universe.

## 11. Team Learning

Before implementing a checkpoint item, check the current candidate tests and
receipts. A planned same-data comparison may already exist while a narrower
independent numerical check remains missing.

## 12. Cross-Product Coverage

**Covers:** native TMB and paired DRM.jl fitting for one Binomial logit model
with predictor-dependent SDs on an animal covariance intercept and an IID
site intercept; same-data likelihood checks against an independent R
joint-Laplace oracle; and `A`/`Ainv` equivalence checks.

**Does NOT cover:** other response distributions, random slopes, correlated
blocks, different structured providers, exact integration error, or interval
coverage calibration.

**Memory receipt:** queried the Shinichi brain for the random-effect SD
hierarchy and project decisions. `route.py` returned no LOAD-FIRST manifest
for this worktree, and the repository has no local `memory/00-INDEX.md`;
technical claims were checked against candidate source, tests, and receipts.

**Golden Set:** Not in scope for this one-fixture oracle addition; no model
source changed and no broader correctness claim is made.

**Prose assessment:** Style 3/10, medium confidence. Genre/coverage: internal
after-task report, reviewed in full. Evidence/repair: sections 2 and 10 state
the tested family, approximation, and limits concretely; no prose change
needed. Gates: science = pass for the stated Laplace formula and fitted-route
scope; facts = pass against the test output and source hashes; references =
not applicable because no literature is cited. Provenance: self-review of
this saved draft on 2026-10-24; prior project reports were already seen.

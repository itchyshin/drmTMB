# After Task: Clean-Current Adapter Probe Mapping

## 1. Goal

Give the clean-current Bernoulli look-two adapter a source-checked set of three
probe rows, one for each frozen log-SD truth, without reusing the legacy seed
stream.

## 2. Implemented

`clean_current_stage_two.adapter_qualification_cases()` validates the three
transformed batches against the frozen `look2.csv`, then returns the probe
identities at local indices 1, 1001, and 2001. The corresponding global rows
are 1, 4001, and 8001, with truth values -0.5, 0, and 0.5. Tests cover the
identities and reject a changed source index. The stage-two README now says
explicitly that the earlier v7 PASS is tied to the legacy manifest.

## 3a. Decisions and Rejected Alternatives

Keep the clean-current qualification mapping separate from the legacy mapping.
Both use the same three truth/replicate positions, but their frozen seed
manifests differ. The legacy v7 PASS therefore remains evidence for its own
source only. No likelihood or model equation changed; this slice provides no
identifiability or interval-calibration evidence.

## 4. Files Touched

- `tools/general-sd-regression/native-calibration-stage-two/clean_current_stage_two.py`
- `tools/general-sd-regression/native-calibration-stage-two/test_stage_two.py`
- `tools/general-sd-regression/native-calibration-stage-two/README.md`
- `docs/dev-log/check-log.d/2026-10-20-clean-current-adapter-case-map.md`

## 5. Checks Run

- `python3 -m unittest test_stage_two.py`: PASS, 45 tests.
- `python3 -m py_compile clean_current_stage_two.py test_stage_two.py`: PASS.
- `git diff --check`: PASS.
- Read-only Totoro check confirmed that the v7 adapter receipt pins the legacy
  source SHA `8fd627ccb8a7f8689c56e629a5ff12e53405be1a508167216632bcf445652e96`.
  The frozen clean-current `look2.csv` SHA is
  `7920b4d482d599828bffe4f6333661afcae6d6efea411758b03d2f0a263e1b98`.
  Therefore the v7 PASS does not qualify the clean-current route.
- Read-only Totoro hash checks matched the current v4 library artifacts in its
  source registry. No worker process was active.
- No fit, calibration campaign, GitHub mutation, email, or DRAC job ran.

## 6. Tests of the Tests

The two new tests initially failed because the clean-current case selector did
not exist. The first targeted run also exposed that the runner test class
depended on another test class having already initialized its attributes. The
runner now imports its adapter and manifest directly, so it can run alone. The
source-index mutation test then failed with the expected mapping error before
the helper was added; both tests pass in the final 45-test suite.

## 8. Consistency Audit

The legacy qualification scripts and their schema were not changed. The
new helper revalidates each batch against the existing frozen manifest
contract. This update changes only internal calibration tooling and its
developer README; formula grammar, likelihoods, package outputs, NEWS, public
vignettes, pkgdown navigation, and package capability claims were not changed.
The current-source adapter still lacks a fit-running preparation/runner path.

## 7a. Issue Ledger

Read-only searches for open random-effect SD and Bernoulli SD issues found no
issue matching this adapter work. #496 and #932 track the separate GVA/Laplace
workstream. No GitHub issue was changed.

## 9. What Did Not Go Smoothly

The test class originally relied on another class's `setUpClass()` side
effects. Running the new test by itself exposed that coupling, and the setup
was made independent before checking the intended missing-feature failure.
More importantly, the existing remote qualification is named as a current
stage-two job but its receipt is bound to the legacy manifest; the exact SHA
comparison made that boundary explicit.

## 11. Team Learning

Qualification receipts must identify the exact seed-manifest mode and SHA.
A PASS for a legacy route must not be inherited by a later clean-current
manifest, even when the probe indices and truth values match.

## 10. Known Residuals

This helper establishes only clean-current probe identity. It does not run the
three worker fits, validate a source-bound clean-current supervisor receipt,
or establish recovery or calibrated uncertainty. Programme gates G0-G8 remain
open.

## 12. Cross-Product Coverage

This change covers clean-current Bernoulli stage-two probe-row identity in the
Python manifest helper and its fit-free tests. This slice does NOT cover
likelihood families, R/TMB model code, Julia implementation, interval
estimation, recovery, prediction, output extraction, calibration, public
examples, or API. The current-source preparation and worker qualification
remain the next engineering step, followed by a bounded three-probe Totoro
qualification.

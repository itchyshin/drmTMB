# After Task: Clean-Current Stage-Two Receipt Adapter

## 1. Goal

Preserve the exact source identity of the clean-current Bernoulli look-two design through stage-two preparation and combination, without launching fits.

## 2. Implemented

The stage-two combiner now checks each clean-current conversion receipt against the prepared-root receipt, the batch manifest digest, and the GO-record digest. It verifies the batch number, source-row range, local indices, master seed, source and worker design modes, and prepared-only status. Existing legacy conversion validation remains on its original branch.

## 3a. Decisions and Rejected Alternatives

This tooling change does not alter a statistical model. It preserves the mapping from each of three 3,000-row batches to its frozen 9,000-row synthetic source. The pinned source remains `clean_current`, and the worker mode remains `clean_current_stage_two`.

The combiner reads the receipt directly because a hash-only registry seal would not show whether its declared mapping agrees with the root preparation and manifest. No modelling or public API alternative was involved.

## 4. Files Touched

- `tools/general-sd-regression/native-calibration-stage-two/stage-two-rules.R`
- `tools/general-sd-regression/native-calibration-stage-two/combine-stage-two.R`
- `tools/general-sd-regression/native-calibration-stage-two/test-combine-stage-two.R`

## 5. Checks Run

- `python3 tools/general-sd-regression/native-calibration-stage-two/test_stage_two.py`: PASS, 40 tests.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-stage-two-rules.R tools/general-sd-regression/native-calibration-stage-two`: PASS, `STAGE_TWO_R_RULES_PASS offsets=3 metrics_tolerance=1e-12`.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-combine-stage-two.R`: PASS, including the legacy replay rejection marker.
- `python3 -m py_compile tools/general-sd-regression/native-calibration-stage-two/stage_two.py tools/general-sd-regression/native-calibration-stage-two/prepare-stage-two.py`: PASS.
- `git diff --check`: PASS.

No model fits, calibration runs, Totoro jobs, or DRAC jobs were launched.

## 6. Tests of the Tests

The new tests accept an exact receipt bound by a synthetic prepared-root record, reject a changed source-row endpoint, and run the production combiner batch reader over all three sealed clean-current batches of terminal errors. The reader returns the expected 1–9,000 global source indices without fitting models. Before this change, the combiner did not consume the clean-current conversion receipt, so these checks exercise a missing validation path rather than mirror the implementation. The full Python suite also exercises source-row tampering and wrong-batch rejection.

## 7a. Issue Ledger

No GitHub issue was changed. This internal receipt-validation fix does not itself close or alter the broader random-effect SD regression work item. The issue tracker was not searched in this tooling-only slice.

## 8. Consistency Audit

The combiner validates the same frozen look-two source mapping already enforced by the Python preparation and runner adapters. Clean-current records retain their source identity; legacy records continue through the legacy validation branch. No public formula, likelihood, or fit output changed.

## 9. What Did Not Go Smoothly

The R test now exercises the clean-current identity mapper and production batch reader for all three batches, as well as the legacy replay rejection. It does not run the complete clean-current prepare-to-run-to-combine chain. That larger integration proof remains outstanding.

## 10. Known Residuals

The full prepare-to-run-to-combine clean-current path still lacks a fit-free integration test. Add that test before treating the adapter as campaign-ready. Even after that, the test will establish identity plumbing only; it will not qualify inference, coverage, or calibration.

NotebookLM authentication is now verified for `itchyshin@gmail.com`; all 14 notebook sources report ready. The methods synthesis found that the reviewed sources discuss constant covariance models and do not directly establish identifiability or interval calibration for continuous predictor-dependent latent SD coefficients. That gap remains open. Joe (2008) reports that Laplace bias depends strongly on response discreteness and generally decreases with larger clusters; Stringer (2023 preprint) reports that adaptive quadrature can improve variance-parameter inference for a single grouping factor when enough nodes are used. Neither result establishes calibration for heteroscedastic SD slopes. Primary-source checks: [Joe (2008)](https://doi.org/10.1016/j.csda.2008.05.002), [Stringer (2023)](https://arxiv.org/abs/2310.01589), and the [glmmTMB covariance-structure vignette](https://glmmtmb.github.io/glmmTMB/articles/covstruct.html).

## 11. Team Learning

The root preparation record should bind every conversion receipt and the combiner should read those receipts, not rely on their registry hashes alone. This improves tamper detection at the point where source identity enters combined results.

## 12. Cross-Product Coverage

This is an internal calibration-harness integrity change. It covers receipt checks in the R stage-two combiner and the matching synthetic negative test. It does NOT cover model fitting, the complete prepare-to-run-to-combine chain, R/Julia parity, inference, coverage, calibration, or public package behavior. The design remains unqualified until the clean-current chain and approved validation campaign are complete. No user-facing documentation or model design document changed; README, NEWS, roadmap, known-limitations, formula grammar, vignette, and pkgdown checks were not run because product behavior did not change.

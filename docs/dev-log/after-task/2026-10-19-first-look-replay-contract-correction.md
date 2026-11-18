# First-look replay contract correction

## 1. Goal

Correct the historical Bernoulli calibration readback so it agrees with the current approved interval contract and explains why the archived first look cannot authorize a second look.

## 2. Implemented

Replaced the obsolete claim that fitted profiles needed a 97.5% level. The note now says the current contract uses 95% fitted profile intervals and 97.5% Monte Carlo confidence intervals. It records why the old result remains ineligible for current replay: the archived result CSVs lack explicit profile-level metadata, and four core source files differ from the current candidate checkout.

## 3a. Decisions and Rejected Alternatives

Preserved the historical estimates, gate readout, and original interpretation as an as-assessed record. Did not relabel the old run as current calibration, infer new eligibility from the requested profile level alone, reuse it to authorize look two, or launch new fits.

## 4. Files Touched

Updated docs/dev-log/general-sd-regression/first-look-inference-review.md, docs/dev-log/general-sd-regression/inventory.md, and tools/general-sd-regression/native-calibration-stage-two/test-combine-stage-two.R. Added this after-task report and a short check-log fragment.

## 5. Checks Run

git diff --check passed for the corrected review. A read-only archive audit found 3,000 result CSVs and 3,000 interval RDS files; every result CSV header lacks profile_level. The archived source registry's hashes for R/drmTMB.R, R/methods.R, R/profile.R, and src/drmTMB.cpp differ from this candidate checkout. The archived worker.R hash matches the current worker.R, which explicitly requests a 0.95 profile interval. The first-look-v4 negative-control fixture also has 3,000 rows, all missing profile_level. Rscript tools/general-sd-regression/native-calibration-stage-two/test-combine-stage-two.R passed in about two minutes with STAGE_TWO_LEGACY_REPLAY_REJECT_PASS; its subprocess warning and status 1 are expected by the assertion that the legacy fixture is rejected before output creation. The project after-task validator passed. The prose checker returned FINDINGS: 0.

## 6. Tests of the Tests

The existing no-fit combiner test served as the negative control. It uses the retained 3,000-row fixture and asserts that replay stops on the raw-versus-standardized mismatch before creating an output directory or decision receipt. The run produced the expected rejection marker. No fit or calibration attempt was launched.

## 7a. Issue Ledger

No issue was created, edited, or closed. A prior read-only search for random-effect SD uncertainty identified issue #1558 as related under-coverage context; no issue specifically tracks this source-bound replay correction.

## 8. Consistency Audit

The correction agrees with docs/dev-log/general-sd-regression/staged-calibration-contract.md and the versioned worker-095.R contract: fitted profile level 0.95, Monte Carlo interval level 0.975, explicit per-result level required for replay. The candidate inventory now records that the 97.5%-profile experiment is historical and the archived 95%-profile result is not eligible for current-source replay. The test comment now states why the 95% fixture is rejected. The archive remains historical because it lacks that field and its core model source differs from the current candidate.

## 9. What Did Not Go Smoothly

The previous supersession note reversed the fitted-profile and Monte Carlo confidence levels. I checked the current frozen contract, archived result schema, archived worker source hash, and current model-source hashes before replacing the stale claim.

## 10. Known Residuals

The current-source 95% first look and complete replay have not run. The old estimates cannot be used as current-source calibration, and look two remains unauthorized. This correction does not establish interval calibration.

## 11. Team Learning

Record fitted confidence level separately from Monte Carlo confidence level, and require the level in each attempt row so later replay can authenticate it without relying only on worker defaults or narrative.

## 12. Cross-Product Coverage

This correction covers the native Bernoulli random-intercept SD-slope calibration record and its replay rationale. It does NOT cover a fresh current-source first look, look-two authorization, Julia parity, other families or random-effect types, or programme completion.

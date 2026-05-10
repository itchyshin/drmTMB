# Five-Task QA Batch

Date: 2026-05-10

Reader: Ada, Pat, Grace, and future contributors deciding whether the current
Phase 9 surface is stable enough to move toward release hardening.

## Goal

Complete five small quality-first tasks after the landing-page and comparator
work, without starting a new large likelihood feature.

## Completed Tasks

| Task | Phase | Files | Result |
| --- | --- | --- | --- |
| Beta-binomial newdata prediction coverage | Phase 9 | `tests/testthat/test-beta-binomial.R` | Added link- and response-scale `newdata` checks for `mu` and `sigma`. |
| Beta-binomial malformed-response coverage | Phase 9 | `tests/testthat/test-beta-binomial.R` | Added negative tests for negative counts, infinite counts, and one-column `cbind()` responses. |
| Cumulative-logit newdata probability coverage | Phase 9 | `tests/testthat/test-cumulative-logit.R` | Added `newdata` checks for category probabilities, expected ordinal score, and score variance. |
| Cumulative-logit malformed-response coverage | Phase 9 | `tests/testthat/test-cumulative-logit.R` | Added negative tests for character responses and two-category ordered responses. |
| Release/QA planning | Phase 17 | `docs/design/05-testing-strategy.md`, `ROADMAP.md` | Expanded the family testing checklist and added the `0.1.0` preview-release gate. |

## Validation

- `air format tests/testthat/test-beta-binomial.R tests/testthat/test-cumulative-logit.R`: passed.
- Focused beta-binomial and cumulative-logit tests: 127 passed, 0 failed, 0 warnings, 0 skips.
- `Rscript -e "devtools::test()"`: 1400 passed, 0 failed, 0 warnings, 0 skips.
- `Rscript -e "pkgdown::build_home()"`: passed and rendered the `0.1.0` gate in `pkgdown-site/ROADMAP.html`.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `git diff --check`: clean.

## Next Recommended Tasks

| Next task | Phase | Why next |
| --- | --- | --- |
| Add the local O'Dea/Nakagawa Gaussian replication harness | Phase 7/8 validation, feeding Phase 17 | It turns the paper-map into executable evidence while staying inside implemented Gaussian location-scale support. |
| Audit pkgdown mobile/desktop rendering of the new landing page | Phase 17 | Pat found the information architecture issue; visual QA is the next accessibility step before deployment. |
| Add beta-binomial denominator alias design note | Phase 9 | The implemented path is `cbind(successes, failures)`; a `successes/trials` alias needs a deliberate grammar decision before code. |
| Add ordinal-scale/discrimination naming decision note | Phase 9 | The next ordinal extension should not begin until the direction of `sigma` versus a native discrimination parameter is clear. |
| Prepare a `0.1.0` release checklist issue | Phase 17 | The roadmap now defines the gate; the checklist will make the preview-release work trackable. |

## Remaining Limitations

This batch did not implement new likelihoods. It tightened tests and planning
around already implemented Phase 9 families and the first public-preview gate.

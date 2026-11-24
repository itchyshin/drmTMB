# Student-t fixed effects with random-effect SD priors

Source base: drmTMB main `55c3160800ef574ee87034d723ea8af0e8a1050e`. The prior-table, model-comparison, article, and ANOVA-fix commits were reconciled into the isolated integration branch; the mixed Student-t/SD bridge change is still local.

The Julia bridge now selects the compositional v5 contract when a Student-t fixed-effect prior is combined with a mean random-intercept SD prior. The v5 serializer checks both target records and keeps the existing normalized Student-t and natural-SD Gamma conventions. A Student-t-only prior on a model with random terms remains refused before Julia starts unless that model uses another admitted contract.

`Rscript --vanilla -e 'devtools::test(filter="prior-table-v5-bridge")'` passed 34 assertions with zero failures and one expected live-Julia skip. The combined focused run `Rscript --vanilla -e 'devtools::test(filter="prior-table|prior-convergence-contract|model-comparison|lrt-boundary")'` passed 1,003 assertions with zero failures and seven expected skips. The skips cover live Julia routes and routes without a local DRModels.jl checkout. `git diff --check` passed.

The first combined run exposed a missing early refusal: a Student-t-only random-effects model reached Julia setup before the intended unsupported-combination error. The admission check now receives the formula and rejects that model before backend setup. The rerun passed. The tests exercise the v5 Student-t plus SD serializer and the formula-specific refusal, but no live Julia fit has run on this candidate. Full package tests and bridge parity remain open.

## Current-main rerun

A second combined focused run on the integrated branch at commit `c8afb3d7e49dc771bd705faa4307cf38b5b50966` completed in 95.5 seconds: 1,003 passed, 0 failed, and 7 expected skips. The tracked working-tree patch at launch had SHA-256 `170c7cd8bd81662020c9734eac07873581be6762f8438b15bf4bf5769cdfb3b2`. Four skips require an installed DRModels.jl checkout; three opt-in live-table bridge cases remained disabled. This rerun does not establish live Julia parity or a full-suite pass.

## Independent bridge review correction

Review found that the v5 receipt validator accepted omitted packed indices for fixed and random-effect SD targets. The serializer now derives fixed `index` and `matrix_column` values from the ordered bridge coefficient labels, and derives each SD `index` from the fixed-parameter count plus the formula's random-intercept order. The validator requires and compares those identities. Tests reject a wrong fixed index, a missing SD index, swapped indices for `site` and `observer`, and an echoed SD assigned to the wrong group. The opt-in live test also checks that the selected DRModels.jl checkout is clean at the expected commit. The bivariate rho12 route remains an explicit Julia refusal in the live test, consistent with current admission.

After this correction, the combined focused run passed 1,013 assertions in 28.5 seconds with zero failures and seven expected skips. A final v5-only rerun passed 47 assertions with zero failures and one expected live-Julia skip. These runs exercise mock marshalling and the independent prior-table oracle; they do not establish live Julia parity or a full-suite pass.

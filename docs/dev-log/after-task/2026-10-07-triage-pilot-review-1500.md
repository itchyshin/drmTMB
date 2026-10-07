# After Task: PR #1500 review — unnamed update() extras and #1484 hold

## Goal

Keep draft PR #1500 unmerged and respond to the code-review block: unnamed
`update()` extras must error, the C17/C14 capability receipt must be
re-certified after `R/methods.R` moved, and #1484 must not change
`miss_control(response = "include")` semantics until Shinichi decides
whether that call drops incomplete predictor rows or errors.

## Implemented

`update.drmTMB()` now refuses unnamed arguments in `...`. A call such as
`update(fit, bf(...), dd2)` errors instead of silently refitting the
original data.

The #1484 evaluated-control check is reverted to the A-2 / #1332
call-syntax helper. `miss_control(response = "include")` and
`miss_control(response = "drop")` again drop incomplete predictor rows.
Stored `miss_control(predictor = "fail")` objects and `predictor` values
held in a variable still bypass the early fail check; that is the open
#1484 question, not a silent semantic flip.

## #1484 failures confirmed on head `4932d9482`

Thirteen tests in eleven files failed on the previous head. The tests
were not edited. Exact failures:

| File | Line | Test | Failure |
| --- | --- | --- | --- |
| `test-missing-response-poisson.R` | 102 | drops missing-predictor rows | Error: `miss_control(predictor = "fail")` requires complete predictors (x). |
| `test-missing-response-nbinom2.R` | 109 | drops missing-predictor rows | same early abort |
| `test-missing-response-binomial.R` | 108 | drops missing-predictor rows | same early abort |
| `test-missing-response-beta.R` | 110 | drops missing-predictor rows | same early abort |
| `test-missing-response-continuous.R` | 300 | MR-T2 drop predictor-missing rows | same early abort |
| `test-missing-response-boundary.R` | 202 | MR-T3 drop predictor-missing rows | same early abort |
| `test-missing-response-encoded.R` | 193 | MR-T4 drop predictor-missing rows | same early abort |
| `test-missing-response-truncated-nbinom2.R` | 109 | MR-T5 drop predictor-missing rows | same early abort |
| `test-missing-response-count-mixtures.R` | 202 | MR-T6 ZIP neighbouring gates | same early abort |
| `test-missing-response-count-mixtures.R` | 311 | MR-T6 ZINB2 neighbouring gates | same early abort |
| `test-missing-response-count-mixtures.R` | 429 | MR-T6 hurdle neighbouring gates | same early abort |
| `test-missing-response-gaussian.R` | 174 | still fail under predictor = fail | message-only: expected `Missing predictors`, got the A-2 complete-predictors abort |
| `test-missing-response-biv-gaussian.R` | 219 | keep predictor and dense-V boundaries | message-only: expected `Missing predictors`, got the A-2 complete-predictors abort |

## Mathematical Contract

No likelihood or parameterization changed.

## Files Changed

- `R/methods.R`, `man/update.drmTMB.Rd`, `tests/testthat/test-update-drmTMB.R`
- `R/drmTMB.R`, `R/missing-data.R`, `man/miss_control.Rd` restored to A-2 call syntax
- removed `tests/testthat/test-miss-control-predictor-fail.R`
- `NEWS.md`, `docs/dev-log/check-log.md`, this report

## Next Actions

Re-run `tools/run-lane-c-c17c1-c14-model15-compatibility.R` (or
`tools/recertify-c17.py`), repoint the TSV receipt, then rerun the
update / heritability / missing-response files.

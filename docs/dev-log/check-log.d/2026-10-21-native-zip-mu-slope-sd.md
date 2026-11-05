# 2026-10-21: native complete-data ZIP `mu` slope SD regression

- Focused tests: `test-zi-poisson-sd-regression` and `test-zi-poisson-sd-integration` passed 25 assertions each. The latter includes seeded slope recovery, group-SD predictions, an independent groupwise integral, and a reversed-index control.
- Documentation: the SD-regression and formula-grammar vignettes, formula grammar, distribution roadmap, known-limitations page, and NEWS now describe the exact native complete-response ZIP slope route and its fixed-`zi` boundary. The current-source vignette render executed the ZIP chunks; its final prose-only equation was added during rendering and was not inspected in the HTML.
- Scope: one independent numeric `mu` slope with a matching coefficient-selected SD formula. This is point-fit and fixture-specific integration evidence only; calibration, missing responses, other ZIP effects, and Julia parity remain open.
- Full details: `docs/dev-log/after-task/2026-10-21-native-zip-mu-slope-sd.md`.

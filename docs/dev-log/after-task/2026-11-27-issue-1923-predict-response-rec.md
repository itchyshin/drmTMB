# After-task: issue #1923 — lognormal `predict(type = "response")` vs `fitted()`

## Task goal

Triage whether `predict(type = "response")` should match `fitted()` for `lognormal()` fits, per Cursor test issue #1923.

## Files created or changed

- `docs/dev-log/after-task/2026-11-27-issue-1923-predict-response-rec.md` (this report)

## Checks run and exact outcomes

- Read `?predict.drmTMB` (`R/methods.R` roxygen): `type = "response"` is the distributional parameter on its response scale, explicitly not `E[Y]` for lognormal (`mu` on the log scale).
- `NEWS.md` (#1320): `type = "mean"` returns `E[Y]`; `type = "response"` is unchanged as the component distributional parameter.
- `tests/testthat/test-predict-mean.R` asserts `type = "response"` stays log-scale `mu` and differs from `type = "mean"` / `fitted()`.
- No implementation change: aligning `type = "response"` with `fitted()` would require weakening or replacing those expectations.

## Recommendation (3 lines)

**A — Make `type = "response"` equal `E[Y]` on the natural scale for `lognormal()` (and default `dpar = "mu"`):** matches user intuition and `fitted()` on training rows, but breaks the #1320 contract, glm-like “inverse link of `eta`” reading, and every test that locks log-scale `mu` under `type = "response"`.

**B — Keep current values:** `fitted()` and `predict(type = "mean")` already expose the arithmetic mean `exp(mu + sigma^2/2)`; `type = "response"` with `dpar = "mu"` remains log-scale `mu` as documented in `?predict.drmTMB` and `NEWS.md`.

**Pick B** unless the project reopens #1320 for a breaking release: documentation and tests are already aligned; close #1923 as “use `type = \"mean\"` or `fitted()` for natural-scale means.”

## GitHub issue maintenance

Draft PR refs #1923 with this recommendation; no code change.
# After-task: issue #1924 — `truncated_nbinom2()` `fitted()` vs `predict(type = "response")`

## Task goal

Triage whether `predict(type = "response")` should match `fitted()` for plain `truncated_nbinom2()` fits, per Cursor test issue #1924.

## Files created or changed

- `docs/dev-log/after-task/2026-11-27-issue-1924-predict-response-rec.md` (this report)

## Checks run and exact outcomes

- Read `?predict.drmTMB` (`R/methods.R` roxygen): for count families, `type = "response"` with `dpar = "mu"` is the component count mean, not the unconditional or truncated response mean; `type = "mean"` is `E[Y]`.
- `NEWS.md` (#1320, #1566): `fitted()` for `truncated_nbinom2()` is the truncated mean; `type = "mean"` matches `fitted()`; `type = "response"` remains untruncated `mu`.
- `tests/testthat/test-predict-mean.R` covers hurdle means; changing plain truncated `response` to the truncated mean would shift the same semantic lane as #1320 and any contract tests that treat `dpar = "mu", type = "response"` as NB2 `mu`.
- No implementation change.

## Recommendation (3 lines)

**A — Make `type = "response"` return the truncated positive-count mean for `truncated_nbinom2()`:** aligns with `fitted()` on training rows, but breaks the documented #1320 split between component `mu` (`response`) and `E[Y]` (`mean` / `fitted()`).

**B — Keep current values:** use `predict(type = "mean")` or `fitted()` for the truncated mean; use `predict(dpar = "mu", type = "response")` for the latent NB2 mean `mu`, as `?predict.drmTMB` already states.

**Pick B** and close #1924 with a pointer to `type = "mean"` unless the package deliberately deprecates component-`mu` `response` predictions in a major release.

## GitHub issue maintenance

Draft PR refs #1924 with this recommendation; no code change.
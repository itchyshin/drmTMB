# Check log slice — 2026-11-27 — predict `response` vs `fitted` rec (#1923, #1924)

## Scope

Documentation-led triage only; no R or test edits.

## Overlap

- `gh pr list --state all --search "1923 in:body"`: empty
- `gh pr list --state all --search "1924 in:body"`: empty
- Open lanes #1912–#1922: no collision with `cursor/1127fx-1923` or `cursor/1127fx-1924` (noted #1915 covr, #1921 vcov only)

## Evidence

- `R/methods.R` `predict.drmTMB` @details: `type = "response"` ≠ `E[Y]` for lognormal and ZI/hurdle counts
- `NEWS.md` #1320: `type = "mean"` for `E[Y]`; `response` unchanged
- `tests/testthat/test-predict-mean.R`: lognormal `response` = log-scale `mu`

## Tests

```text
Rscript -e 'testthat::test_file("tests/testthat/test-predict-mean.R")'
```

Run on branch tip after doc-only commits (sanity: existing contract unchanged).
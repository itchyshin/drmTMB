TITLE: [Dinnage audit Mi-bundle] Six further minor papercuts bundled in §4 (report says ten; seven named, one already tracked as #1240)
LABELS: audit-dinnage, bug, minor
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4 Minor "Also:" bullet and Appendix A's
"Mi-rest" row; severity minor each). Full attribution in the report's own `code-review/CROSS-EXAMINATION.md`.

## What Russell found
The report calls this "ten further papercuts" but names only seven distinct items (confint's shape and
sigma()'s vector return are named there too but split out as Mi-15/Mi-16; the count gap is unresolved,
not guessed at):
1. `anova.drmTMB()` always errors -- tracked separately, see below.
2. AIC/BIC REML guard fires on the *estimator*, not the *comparison*.
3. Tweedie `d`/`p`/`q` have no support guard.
4. `print(fit)` shows no coefficients.
5. A mistyped column name gives a raw `Error: undefined columns selected`.
6. 12 parallel "unsupported parameter" branches, only 2 with the helpful `"i" =` hint.
7. `"1 weight value are missing"` -- wrong grammar for the singular case.

## Where (at 945da24f)
`R/methods.R` (anova, AIC/BIC guard, print), `R/family-dpq.R` (Tweedie), `R/parse-formula.R`/`R/drmTMB.R`
(undefined columns, unsupported-parameter branches, weight-value message).

## Since-audit status on main (4bfb9d721, 2026-09-13)
1. **anova errors** -- PRESENT. `R/methods.R:2708-2717` still ends `cli::cli_abort("... not implemented
   for {.cls drmTMB} fits.")` for every non-MSPL input. **Already open: #1240** ("anova.drmTMB always
   aborts") -- not restated here; see `anova-note.comment.md`.
2. **AIC/BIC guard** -- PRESENT. `R/methods.R:2649-2658` warns `if (any(estimators == "REML"))`
   unconditionally, no check of whether compared structures differ.
3. **Tweedie d/p/q** -- PRESENT. `drm_family_dpq_tweedie` calls `tweedie::dtweedie`/`ptweedie`/`qtweedie`
   directly (`R/family-dpq.R:199-201`), no upstream `power`/`nu` domain validation.
4. **print(fit)** -- PRESENT. `print.drmTMB()` prints label, RE term counts, SE status, logLik,
   convergence -- never the coefficient table.
5. **undefined columns** -- PRESENT. No `tryCatch` around `data[, vars, drop = FALSE]` access (e.g.
   `R/drmTMB.R:4097`, `:4739`, `:5064`) traps a mistyped column name.
6. **unsupported-parameter branches** -- PRESENT, count drifted: `grep -c "Unsupported parameter"
   R/drmTMB.R` = 17 now (was ~12), 5 with an `"i" =` hint (was 2) -- same pattern, different counts.
7. **weight grammar** -- PRESENT. `R/drmTMB.R:17621`: `"{sum(bad)} weight value{?s} are missing or
   non-finite."` -- `{?s}` pluralizes correctly but "are" is hardcoded, so n=1 still says "are."

`git log --oneline 945da24f..HEAD` touching these files shows no commit fixing items 2-7.

## Proposed fix (Russell's, if stated)
Each "trivial" per the report's own fix-size column. Item 7: use a `{?is/are}` cli glue conditional (or
`cli::qty()`), matching the existing "value{?s}" pluralization.

## Acceptance
- [ ] items 2-7 each get the minimal fix described above (item 1 tracked at #1240)
- [ ] `sum(bad) == 1` produces "1 weight value is missing or non-finite"
- [ ] NEWS.md entry crediting the report

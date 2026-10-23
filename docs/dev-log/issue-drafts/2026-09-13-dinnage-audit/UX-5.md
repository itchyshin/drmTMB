TITLE: [Dinnage audit UX-5] `bf()`/`drm_formula()` reject a formula held in a variable, asserting it "is not a formula" when it is
LABELS: audit-dinnage, bug, minor
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §7.2, Appendix A row UX-5; severity minor).
Supporting working: 6 of 19 first-contact runs hit this; cost one simulation arm its entire drmTMB side
(11 cells reported `convergence: 0.0000`, cause sat in a results column rather than on screen).

## What Russell found
`` `drm_formula()` inputs must be formulas; input 1 is not a formula `` fires on an object that **is** a
formula -- specifically, a formula assigned to a variable and passed by reference (`f <- y ~ x; bf(f)`).
The message asserts the opposite of the truth, and 6 of 19 documentation-only runs hit it. It blocks df-
selection sweeps, CV folds, and any `lapply` over specifications; `lm`, `gamlss` and `glmmTMB` all accept
the identical formula-in-a-variable pattern.

## Where (at 945da24f)
`R/parse-formula.R`.

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT, root cause confirmed by direct code inspection. `is_formula_call(expr)` (`R/parse-formula.R:
117-119`) is `is.call(expr) && identical(expr[[1L]], as.name("~"))` -- it inspects the **unevaluated call
expression** (captured via non-standard evaluation, e.g. `substitute()`/`match.call()` upstream), not the
evaluated value. When a formula is held in a variable and passed by name (`f <- y ~ x; bf(f)`), the
captured `expr` is the *symbol* `f`, not a call to `` `~` ``, so `is_formula_call()` returns FALSE even
though `f` evaluates to a genuine formula object -- `parse_drm_formula_entry()`
(`R/parse-formula.R:54-58`) then aborts with "input {position} is not a formula." `git log --oneline
945da24f..HEAD -- R/parse-formula.R` shows no commit changing `is_formula_call()` or adding an
evaluated-value fallback. No existing-issue match: `gh issue list --search "drm_formula formula"` returns
nothing on point.

## Proposed fix (Russell's, if stated)
"Accept, or reword." Either evaluate `expr` and check `is.formula()` on the result when the NSE structural
check fails (accepting the variable case), or reword the message to say the input must be a literal
formula expression (not evaluate-and-reject silently as a bug).

## Acceptance
- [ ] a test that fails on 945da24f-behaviour and passes after: `f <- y ~ x; bf(f)` either succeeds
      (accepting a formula held in a variable) or the error message accurately describes the actual
      restriction rather than asserting `f` is not a formula
- [ ] NEWS.md entry crediting the report

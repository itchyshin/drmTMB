# After Task: reject ignored Student phylogenetic SD formulas

## 1. Goal

Prevent a Student-t formula from silently accepting a phylogenetic random-effect SD predictor that the builder does not implement.

## 2. Implemented

The Student builder now rejects any `sd_phylo()` formula with an explicit unsupported-route message. An ordinary Student random intercept plus a phylogenetic SD selector is covered by a regression test.

## 3a. Decisions and Rejected Alternatives

Keep the route fenced until Student structured SDs are implemented end to end. Silently constructing an empty structure was misleading; implementing structured scaling was outside this bounded defect fix. Assumptions made without asking: none.

## 4. Files Touched

- `R/drmTMB.R`
- `tests/testthat/test-student-sd-regression.R`
- `docs/dev-log/check-log.d/2026-10-20-student-phylo-sd-selector-guard.md`
- `docs/dev-log/after-task/2026-10-20-student-phylo-sd-selector-guard.md`

## 5. Checks Run

- Before the code change, the focused regression suite failed because the builder did not error.
- After the change, `Rscript -e "devtools::test(filter = 'student-sd-regression', reporter = 'summary')"` passed.
- `Rscript -e "devtools::test(filter = 'student-sd-integration', reporter = 'summary')"` passed.
- `git diff --check -- R/drmTMB.R tests/testthat/test-student-sd-regression.R` passed.

## 6. Tests of the Tests

The new test failed before the guard because the formula was silently accepted. It passes after the guard and matches the unsupported Student phylogenetic SD selector.

## 7a. Issue Ledger

No issue was opened or changed. This guard does not complete the broader structured SD implementation requirement.

## 8. Consistency Audit

Reviewed the Student builder and nearby Student SD assembly/integration tests. The public formula guide lists Student ordinary SD regression and does not claim Student phylogenetic SD regression. The error now agrees with that documented boundary. The repository route script returned no LOAD-FIRST manifest for this worktree, so I used the supplied drmTMB AGENTS.md as the project instruction source. The Golden Set was not run; this narrow formula-admission check did not change statistical behavior.

## 9. What Did Not Go Smoothly

The first test used `phylo()` directly in the location formula and hit an earlier structured-effect fence. Reframing it with an ordinary location random intercept isolated the silent SD-selector acceptance. The report helper resolved the worktree to the neighboring Shinichi repository; its accidental new file was removed immediately.

## 10. Known Residuals

Student phylogenetic SD regression is still unimplemented. This guard does not address other family/backend gaps or interval calibration. The full predictor-dependent SD goal remains active.

## 11. Team Learning

When a family parser classifies a formula selector as supported, test that every classified selector is either consumed or rejected explicitly; do not allow a selector to disappear during assembly.

## 12. Cross-Product Coverage

The native Student formula guard is covered. This task does NOT cover Julia, other response families, or implementation of Student phylogenetic SD regression.

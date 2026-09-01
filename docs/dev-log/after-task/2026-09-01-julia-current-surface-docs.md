# After-task report — Julia current-route documentation surface

## Scope
Correct generic documentation that described the Julia bridge as future/deferred even though documented admitted cells are current.

## Changed
- Updated generic `summary.drmTMB_julia()` and `confint.drmTMB_julia()` help and generated Rd files.
- Updated the function cheatsheet source and checked-in function-map article.
- Preserved cross-family legacy/deferred wording where that limitation remains real.

## Evidence
`devtools::document(quiet = TRUE)` completed. The R source parses, the two generated help pages render through `tools::Rd2txt()`, and `git diff --check` passes.

## Scope boundary
This is a documentation truthfulness repair. It does not establish full Julia–R parity; profile and bootstrap calibration/performance, control symmetry, diagnostics, and broad family coverage remain separate evidence gates.

## Follow-up
Run the PR CI, inspect the rendered documentation, and use the retained scope boundary in the Ayumi reply draft.

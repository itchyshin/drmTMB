## 1. Goal

Correct stale Julia location-scale-scale capacity wording in the R bridge capability ledger and its published artifacts.

## 2. Implemented

The location-scale-scale row now states that DRM.jl automatically selects the sparse O(p) engine for one phylogenetic LSS component above 500 species. It separates that route from the forced-dense fallback and current multi-component route, which retain a 5,000-observation guard. The bridge comment, installed TSV, and dashboard TSV are synchronized with the source registry.

## 3a. Decisions and Rejected Alternatives

Keep the capability claim bounded to routing and documented guards. Do not turn the existing sparse implementation into a universal species-count, performance, or profile/bootstrap claim. Do not remove the dense/multi-component guard.

## 4. Files Touched

R/julia-bridge.R; inst/extdata/julia-capabilities.tsv; docs/dev-log/dashboard/julia-capabilities.tsv; tests/testthat/test-julia-gate-vs-engine.R; this report; and the matching check-log.

## 5. Checks Run

`Rscript -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-gate-vs-engine.R", reporter = "summary")'` passed in this worktree. A loaded-source registry check also confirmed that both TSV artifacts equal `drm_julia_capability_comparison()` exactly. `git diff --check` passed.

## 6. Tests of the Tests

The new row-specific assertions were written before the source change. Against the loaded pre-repair registry, they failed on the stale wording that said the sparse engine was “underway” and that the dense cap would “lift.” They pass after the source and artifacts were corrected.

## 7a. Issue Ledger

This is an accuracy repair supporting the Julia-R parity programme and Ayumi’s species-capacity question. It does not close the open engine-control issue drmTMB#1108, diagnostics issue DRM.jl#569, broad profile/bootstrap parity work, or performance gates.

## 8. Consistency Audit

Inspected the R registry, installed artifact, dashboard artifact, public Julia vignette PR #1107, and DRM.jl capacity guidance PR #568. All now use the same distinction: one phylogenetic component can use sparse routing; only forced-dense and current multi-component LSS paths retain the 5,000-observation guard.

## 9. What Did Not Go Smoothly

Running `test_file()` without loading this checkout used an older installed drmTMB namespace and produced unrelated registry/artifact differences. Loading the worktree with `devtools::load_all()` made the test exercise the edited source. The initial test regexp expected the word “implemented”; the accurate source says the engine is selected automatically, so the test was narrowed to that factual contract.

## 10. Known Residuals

No new timing, large-tree, interval-calibration, or universal-capacity evidence was generated. The sparse route’s practical limits still depend on data shape and requested inference. The engine-control and route-aware diagnostic contracts remain deliberately unimplemented.

## 11. Team Learning

Capability ledgers are public claims and must be synchronized with current router behavior, source comments, installed artifacts, and user-facing vignette wording. A row-specific regression assertion prevents a completed sparse route from being described as future work again.

## 12. Cross-Product Coverage

This covers only documentation/registry truth for the Gaussian phylogenetic LSS capacity boundary. It does not establish direct-Julia/native-R parity, bridge inference parity, bootstrap correctness, threaded safety, performance wins, all model families, missing predictors, safe worktree retirement, release readiness, or programme completion.

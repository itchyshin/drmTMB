# Julia article example validation

## 1. Goal

Verify the revised general Julia-engine article against the actual isolated R/Julia builds.
This is a bounded slice of the open full-parity programme, DRM.jl issue563.

## 2. Implemented

Added an executable article runner and retained exact-build results, including the failed
first harness attempt. Moved the noninteractive setup note under setup rather than above
the article introduction. The earlier draft removes the stale future-support menu label.

## 3a. Decisions and Rejected Alternatives

Built into a temporary R library without replacing the user's installed package. Literal R
fences must execute even when normal package builds mark them eval=FALSE. Installation
expressions use pre-provided dependencies. Retained raw logs in byte-preserving gzip files.

## 4. Files Touched

`vignettes/julia-engine.Rmd`, `tools/check-julia-engine-article.R`, this report, and
`docs/dev-log/evidence/julia-r-parity/`: article-execution.md, final004JSON, failed001JSON,
R-install.log.gz and article-execution-004.log.gz. Ignored unlazy leaf records the executable
check. The earlier menu edit is in local commit08db05ac1; no production R/Julia source changed.

## 5. Checks Run

Isolated `R CMD INSTALL` passed. Final run004: five converged fits, expected estimators,
finite coefficients, seven passing output/runtime/likelihood checks. Expressions took
30.417seconds; actual Julia/BLAS threads1/1. Unlazy reran the named one-gate leaf and reported
ALL MET(1met). This is not the programme acceptance ledger. Scoped diff check passed.

## 6. Tests of the Tests

The initial purl-based attempt failed because eval=FALSE omitted the fits; its receipt is
preserved. Collapsed, missing and failed-status interval negative controls reject invalid
results before execution. Rose required checks of returned values and estimator/target
identity rather than merely successful calls; all are implemented and exercised.

## 7a. Issue Ledger

DRM.jl#563 remains open; this slice does not close the full parity, performance or docs goals.

## 8. Consistency Audit

Rose independently verified the final receipt against current article, R DLL and Julia
source hashes, and approved the bounded evidence. Predictions, covariance and interval
targets are checked, not inferred from convergence alone. Setup wording covers ape and the
package's noninteractive opt-in while retaining Julia optionality for normal installation.

## 9. What Did Not Go Smoothly

purl initially extracted only setup. Successively stronger checks exposed what execution
alone cannot prove. The unlazy --leaf option is for claims, not running a gate; its documented
explicit-file target was used for the successful acceptance run. Raw compiler logs naturally
contain trailing spaces, so compressed copies preserve original bytes without source-lint noise.

## 10. Known Residuals

No fresh-machine installation test, full suite, full parity, coverage or performance claim.
Documenter pilot and full-site deployment remain separate open work. Protected Julia core
edits remain unapplied pending the explicit approval required by their tool denial.

## 11. Team Learning

Memory receipt: project ownership, optional-engine and exact-build rules shaped the checks;
the current repository and retained runs provide evidence. Golden Set: not run for this
bounded article slice. No Codex memory files changed. Keep literal example execution distinct
from package-build execution, since eval=FALSE intentionally skips the former in builds.

## 12. Cross-Product Coverage

Covers these five example fits and their requested ordinary-model prediction, covariance,
Wald and profile outputs. This does NOT cover all families, providers, formulas, missingness
patterns, REML inference, threaded correctness, interval coverage, large trees or live pages.

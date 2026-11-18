# Julia random-effect SD candidate availability correction

## 1. Goal

Correct current capability wording so development-candidate Julia SD-regression checks are not presented as support in shared or released DRM.jl, general engine parity, or calibrated uncertainty.

## 2. Implemented

The public and design wording now identifies the inspected non-Gaussian Julia SD routes as development-candidate-only, requiring paired local drmTMB and DRM.jl candidate sources. It distinguishes candidate workflow checks from current shared or released availability, same-data engine parity, and interval calibration. Two stale statements in the known-limitations inventory were corrected after a file-specific lane preflight.

## 3a. Decisions and Rejected Alternatives

Kept the existing formula and model claims scoped to the evidence already present. Candidate-source checks were not described as released Julia support. Recovery, output, profile, and bootstrap-routing checks were not upgraded into calibration evidence. No implementation claims or numerical results were added.

## 4. Files Touched

Updated README, NEWS, the formula grammar, likelihood and distribution-roadmap design notes, the random-effect SD design, internal roadmap, known limitations, Julia output contract, and the formula-grammar, Julia-engine, location-scale-scale, model-map, and predictor-dependent-SD vignettes. The public formula documentation source and generated Rd file were kept aligned. Added this after-task report and the matching check-log fragment.

## 5. Checks Run

git diff --check passed on the scoped paths. The prose checker returned FINDINGS: 0 across the scoped candidate-status documents and this report. R parsing of R/random-effect-scale-formulas.R and tools::parse_Rd() of man/random_effect_scale_formulas.Rd passed. The project after-task validator passed after the required section headings were added. No package tests or vignette rendering were run because this correction changed status wording; public examples were not executed in this pass.

## 6. Tests of the Tests

Not applicable. No test expectations were changed. Parsing checked the public formula documentation source and its Rd representation.

## 7a. Issue Ledger

A read-only search found no issue clearly matching this documentation correction. Issue #1558 records a related Wald-interval under-coverage concern for ordinary random-effect SDs and remains relevant to the broader calibration programme. No issue was created, edited, or closed.

## 8. Consistency Audit

The required status inventory was searched with rg -n -i 'julia.{0,80}(bernoulli|beta|gamma|student|nb2|sd-regress)|((bernoulli|beta|gamma|student|nb2).{0,80}julia)' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml. Candidate availability and inference wording was searched with rg -n -i 'current shared/released DRM\.jl|candidate.{0,50}(parity|calibration)|same-data (engine )?parity|interval calibration' across the scoped status, design, and user-facing documents. The sweep found two stale known-limitations statements, one calling the Julia Beta route complete and another grouping Gamma, Poisson, and NB2 slope routes under native TMB and Julia without qualifying candidate source. Both were corrected after a file-specific lane preflight. A whole-repository stale-claim audit remains outside this bounded documentation pass.

## 9. What Did Not Go Smoothly

The first prose-check command used relative paths and resolved them against the brain repository. Re-running with absolute paths produced the valid scoped result. The repository-local copies of the lane-preflight and after-task-validator commands were not present in this worktree; the available brain tools were run by absolute path.

## 10. Known Residuals

The Julia SD routes discussed here require matching local drmTMB and DRM.jl candidate checkouts and are absent from the inspected current shared or released companion. This documentation pass establishes no general same-data engine parity or interval calibration. Package tests and rendered-site verification remain outstanding. Required capability and inference rows in the larger implementation programme remain open.

## 11. Team Learning

When describing cross-repository development routes, state the exact source pair used, distinguish the candidate from shared or released availability, and say separately whether same-data parity and uncertainty calibration were tested. Candidate workflow checks alone do not establish either claim.

## 12. Cross-Product Coverage

README, NEWS, the formula and model-map vignettes, the Julia and location-scale vignettes, and the design and status documents now use candidate-only wording. The reference documentation source and Rd file remain aligned. No pkgdown navigation changed, so _pkgdown.yml was left untouched. The Julia candidate status is qualified separately from native TMB support; no new engine-parity claim was made. This documentation correction does NOT cover family implementation, all response families, structured or bivariate providers, missing-data paths, REML, full cross-engine parity, interval calibration, or rendered-site validation.

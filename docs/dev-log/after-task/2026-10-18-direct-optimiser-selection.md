# Direct optimiser selection

## 1. Goal

Let applied users compare native optimizers on the same model without editing drmTMB internals. Record missing public solver choices in the sibling packages.

## 2. Implemented

`drm_control(optimizer_method = ...)` selects nlminb, BFGS, L-BFGS-B, Nelder-Mead or CG. Direct optim methods use method-specific controls and maxit, reuse multistart, and record their actual method and evaluation counts. Existing nlminb defaults, preset retries and fallback behavior remain available.

Profile endpoint refits keep separate nlminb controls. Diagnostics, staged metrics, warning advice, selected-attempt records and retained-bootstrap headers now account for the chosen method. Newton polishing updates the selected attempt consistently with the returned optimum.

## 3a. Decisions and Rejected Alternatives

Append optimizer_method to preserve positional calls. Use exact stats method names and keep optimizer as the existing named control list. Reject incompatible controls, nonpositive fnscale, nlminb presets on direct methods, and misplaced bounds. Keep profile solvers unchanged. Preserve unavailable iteration counts rather than substituting function counts.

Assumptions made without asking: the request to make the alternatives selectable covers the four existing optim fallback methods. No new optimization library, stochastic solver or public box-bound API was added.

## 4. Files Touched

- R/control.R and R/drmTMB.R: selection, normalization, metadata and staged diagnostics.
- R/check.R, R/profile.R and R/bootstrap-shards.R: downstream diagnostics, endpoint controls and provenance.
- tests/testthat/test-optimizer-selection.R and test-optimizer-selection-downstream.R: pure and compiled integration tests.
- tests/testthat/test-julia-control-refusal-names.R and test-julia-optimizer-controls.R: new-field refusal probes.
- tests/testthat/test-check-drm.R: update the synthetic selected-budget record.
- man/drm_control.Rd, NEWS.md, vignettes/convergence.Rmd and docs/design/35-optimizer-start-map-multistart.md: public and design documentation.
- docs/dev-log/optimizer-selection/: plan, check log and retained receipts.
- docs/dev-log/dashboard/capability-ledger/2026-08-08-c17c2-c14-final-source-compatibility.tsv and a new dated implementation-recovery folder: required unchanged-surface compatibility receipt.
- This after-task report.

## 5. Checks Run

The unchanged C++ backend compiled and installed into a temporary library. Pure dispatch tests passed in both source and installed-package layouts: 14 tests, 234 assertions. The final wider affected suite passed 139 tests and 1165 assertions, with no failures or errors. Sixteen expected warnings came from existing diagnostic, deprecation and clamp fixtures.

All four direct methods recover a small Gaussian likelihood against independent lm coefficients and ML residual scale, with finite covariance and positive Hessians. BFGS also passes a replicated phylogenetic location-scale model comparison, labelled public starts, multistart, profile intervals, polishing metadata and memory-light storage checks.

pkgdown::check_pkgdown(), the control reference build and convergence article build completed. Final-source R CMD check with --no-manual --ignore-vignettes passed with zero errors, warnings or notes. Independent architecture review found no remaining blocking concern after fixes. git diff --check passed.

## 6. Tests of the Tests

Dispatch tests first failed on the missing argument and missing metadata. Downstream tests first failed on hardcoded optimizer diagnostics and profile-control forwarding. Separate red/green tests exposed duplicate fnscale handling, staged metrics, selected-attempt attribution and legacy R partial matching. Installed-layout testing proves the pure fixture works when package R sources are absent. The second CI run exposed another Julia-refusal probe table; its two failures were reproduced locally before adding the missing probe. The resulting control/selection suite passed 45 tests and 487 assertions.

Integration tests compare estimates with lm and the Gaussian ML residual scale, exercise all four algorithms with Newton polishing disabled, and combine BFGS with profiling, public starts and random effects. This checks likelihood behavior as well as dispatch instrumentation.

## 7a. Issue Ledger

Opened GLLVModels.jl #938 and gllvmTMB #1595; added explicit acceptance requirements to existing DRModels.jl #948 instead of duplicating it. All three posts were read back exactly. gllvmTMB native fitting already supports an optim selector; its new issue concerns VA fitting. Existing gllvmTMB #1347 tracks the Julia bridge separately.

Related drmTMB #570 remains open. The beak-data rescue it requests was not reproduced here, and this interface change does not establish that rescue. Ayumi's paper issue #61 will receive the tested public usage after the feature has a usable remote reference.

## 8. Consistency Audit

Checked control parsing, direct and fallback dispatch, selected-optimum synchronization, staged metrics, diagnostics, profile endpoints and retained-bootstrap compatibility. Updated the convergence guide's stale statement that public starts, fallback and multistart were unavailable.

Status inventory scan used `rg -n -i 'fallback optimizers|no.*start|only.*nlminb|optim.*fallback|optimizer' README.md docs/dev-log/known-limitations.md docs/dev-log/internal-roadmap.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml`. Older numbered roadmap entries describe historical slices; the current public contract and new NEWS entry record the supported API. No likelihood equation or formula grammar changed. Existing article and reference navigation remain valid.

Prose review covered the changed public paragraphs and this report for applied ecology users. No new reference or scientific claim was introduced. Self-assessment: perceived AI-like style 2/10, medium confidence, whole changed prose, 18 October 2026. Concrete method names and executable comparison code support readability; dated historical sections remain verbatim. Science gate: pass for bounded numerical claims backed by tests. Facts gate: pass within the recorded checks. Reference gate: source links in sibling issues were checked against the audited refs. Slop checker results are retained in the check log.

## 9. What Did Not Go Smoothly

The shared check-log path was leased by another lane, so this task uses a dedicated log. The GitHub connector lacked write access to the sibling repositories; the existing authenticated CLI completed the authorized posts. The documentation generator changed unrelated help files; those generated changes were removed. The first package check exposed three old fixture assertions that mutated requested controls without updating the recorded selected controls; that fixture was corrected. Its hunk is separate from the pending print-format tests in another lane.

Early integration fixtures assumed an arbitrary remote start would find a good optimum, treated attempt rows as individual multistart rows, and supplied a non-ultrametric test tree. Corrected those test assumptions without changing the optimizer's behavior. A later audit found partial matching could misread legacy optimizer_preset as an optimizer name; a failing regression test preceded the fix.

## 10. Known Residuals

This is numerical-method selection, not calibration evidence. No Ayumi real-data fit, full Bayesian family-level refit, performance campaign, new uncertainty guarantee or CRAN release was run. Optimizer agreement alone cannot establish identifiability. The Julia engine continues to reject unsupported native settings. Profile endpoint solvers remain nlminb. Initial CI required a fresh existing compatibility receipt; it has been refreshed. Full exact-head CI and remote delivery status belong in the check log and PR readback.

## 11. Team Learning

A new optimizer changes more than dispatch: inspect diagnostics, constrained profile controls, staged reports, selected-result metadata and bootstrap compatibility. Use exact list indexing for newly interpreted legacy metadata fields to avoid R partial matching. When a constructor gains a field, search every derived field registry before CI; both Julia refusal registries required probes here.

Memory receipt: the lane preflight, route manifest and project contract were applied; no Codex memory was modified. Golden Set: no capability claim was promoted. The existing three model-15 compatibility cells were rechecked, 12/12 attempts passed, and their source receipt was refreshed with the authenticated surface fingerprint unchanged. The focused regression suite supplies interface and small-likelihood evidence only.

## 12. Cross-Product Coverage

Covers: native Gaussian likelihood fits for every selectable method; BFGS with replicated phylogenetic location and ordinary scale random effects, public labelled starts, deterministic multistart, optional polishing, standard errors, profile intervals and light storage; pure parallel-plan forwarding, fallback metadata and Julia control refusal.

Does NOT cover: every family-by-estimator-by-provider combination, live Julia execution, true parallel direct-method numerical equivalence on every operating system, full-data beak rescue, family-level Bayesian comparison, box constraints or new simulation-based uncertainty calibration. Sibling packages received issue records rather than implementation changes.

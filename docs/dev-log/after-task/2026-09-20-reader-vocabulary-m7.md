# Reader vocabulary, milestone 7

## 1. Goal

Give biology PhD students and other scientists consistent first definitions of the model, the R package, and the optional Julia connection.

## 2. Implemented

Clarified the opening definition and optional companion wording in README.md and vignettes/julia-engine.Rmd. Template Model Builder is expanded at first mention in the new package-identity paragraph. The default R workflow needs no Julia installation. The optional bridge points to its existing limits. Corrected the README capability table to three headings matching its three-cell rows. Renamed the three legacy Julia companion references in the drmTMB() roxygen source and regenerated its help. All warnings, examples, equations, evidence and capability statuses are preserved.

## 3a. Decisions and Rejected Alternatives

Kept this a prose-only repair, including the parent-approved neighbouring table and help-name corrections. Reused existing setup and limits pages instead of creating a new guide or promising feature parity. No model, API, build workflow, CI policy, version, figure or Julia repository was changed.

## 4. Files Touched

- README.md
- vignettes/julia-engine.Rmd
- R/drmTMB.R (roxygen comments only)
- man/drmTMB.Rd (regenerated)
- docs/dev-log/after-task/2026-09-20-reader-vocabulary-m7.md
- docs/dev-log/check-log.d/2026-09-20-reader-vocabulary-m7.md

## 5. Checks Run

- Base: origin/main ac886734c; isolated worktree /private/tmp/drmtmb-vocabulary-m7, branch docs/reader-vocabulary-m7.
- `Rscript -e 'pkgdown::check_pkgdown()'`: no problems found.
- `Rscript tools/check-reader-contracts.R`: Reader vignette contract OK.
- Scoped pkgdown render using `p <- pkgdown::as_pkgdown(".", override=list(destination="/private/tmp/drmtmb-vocabulary-m7-review")); pkgdown::init_site(p); pkgdown::build_home_index(p); pkgdown::build_article("julia-engine", p)`: home and changed article built successfully.
- `Rscript /private/tmp/check-r-vocabulary-m7.R /private/tmp/drmtmb-vocabulary-m7 /private/tmp/drmtmb-vocabulary-m7-review`: PASS. Parsed both rendered main elements; checked definitions appear before the warning, optional Julia text and limits are present, new links have the intended targets, and all fenced code blocks equal HEAD.
- `git diff --check`: clean.
- `roxygen2::roxygenise(".", roclets="rd", load_code=roxygen2::load_installed)`: regenerated help without compilation; only the three intended name changes remain in man/drmTMB.Rd.
- `pkgdown::build_reference(p, topics="drmTMB", examples=FALSE, devel=FALSE)`: scoped help render with no fitted examples.
- Parsed rendered table: every header/data row has three cells. Parsed R expressions before/after are identical. Generated Rd and rendered help use DRModels.jl for all three renamed references.
- `tools::checkRd("man/drmTMB.Rd")` completed with the pre-existing non-ASCII encoding diagnostic for the unchanged `coef ± 1.96 * se` text at line 211; no new Rd content other than the names was introduced.
- `Rscript ~/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-09-20-reader-vocabulary-m7.md`: structure passed.
- No fits, compilation, Julia startup, full package suite or full-site build: this changes prose only. The scoped render is not a complete site or deployment certificate.

## 6. Tests of the Tests

No permanent tests added for this reversible prose edit. The one-off reader check examines generated HTML, not just source strings; its code-block equality check compares against the pre-edit commit. Existing reader checkers were run unchanged.

## 7a. Issue Ledger

No open issue exactly matched this first-definition repair. The vocabulary issue search also returned #1301, whose repeatability-scale audit is unrelated. No issue was closed or modified.

PR #1397 owns the count/family guides; PR #1111 owns the function-map article; neither is touched. PR #1304 edits a later README capability paragraph and the drmTMB() help source. Parent-lane approval covers the narrow introductory/table and companion-name repairs here; no #1304 model, evidence or API change is included.

## 8. Consistency Audit

Inventoried README, current navigation, first tutorial, limits, glossary or Julia guide, and open PR public-file paths before editing. Both R packages now expand TMB and explicitly describe Julia as optional for supported models. Source checks do not certify model accuracy. Package defaults and companion names were checked in the current bridge source/help.

Memory receipt: loaded route.py for both R repos, hub VOICE, memory's reader-first and optional-Julia boundaries, and project prose-style-review/after-task-audit skills. They kept the R workflow primary, retained evidence boundaries, and placed definitions before mechanics. Brain MCP tools were unavailable; repo docs were the fallback. Golden Set was not rerun: no model or estimator behaviour changed. No memory files were modified.

## 9. What Did Not Go Smoothly

The initial main worktrees were stale relative to origin/main. Used fresh isolated checkouts. A direct build_home attempt stopped on a sandboxed CRAN DNS lookup and generated private root pages in a disposable preview. The successful scoped render uses build_home_index and the changed article only in a fresh destination, avoiding private-root generation; no preview artifacts are committed. An initial low-level single-file roxygen call lacked package markdown settings and treated other help files as obsolete; a full standard rd-roclet run restored all generated files and left exactly the three intended name edits. Git diff confirms no other help changes.

## 10. Known Residuals

The table and three legacy help names found in the neighbourhood audit are repaired. Other internal tracking language in the long drmTMB() help was not changed by this bounded vocabulary pass. Full-site and deployed-site verification remain outside this PR's scoped checks.

## 11. Team Learning

Rose: inspect origin/main before treating a stale checkout's wording as a new regression. Match each public model definition with the package identity and an explicit optional-engine boundary. Scoped renders establish the changed reader experience without rerunning scientific examples.

## 12. Cross-Product Coverage

Covers the two edited public entry points, their rendered definitions, links, optional Julia wording, unchanged examples, the README table shape and the regenerated fitting-function help names. This does NOT cover full-site publication, numerical recovery, interval calibration, feature parity, tutorials owned by other PRs, or the Julia packages themselves. Separate review PR requested; do not merge in this lane.

# After Phase: General SD Discrete Checkpoint

Status: **ACTIVE CHECKPOINT. The programme remains open.** This report records the current evidence boundary. It authorizes no merge, release, email, or additional compute.

## 1. Goal

Establish a finite, auditable scope for random-effect SD regression across the existing response routes, latent endpoints, provider/input primitives, covariance-dimension classes, and both engine source pins. The required universe currently contains 18,996 rows, with 72 documented narrow mathematical exclusions. Missing base plumbing remains unresolved work, not an exclusion. G0 is open.

The implementation checkpoint is narrower: native ordinary Poisson scalar random-intercept SD regression and selector/output workflows. It does not imply that every cross-product cell is implemented.

## 2. Implemented

The native ordinary SD parameterization uses a positive group SD,
\[
  \mathrm{SD}_j = \exp\{\mathrm{clamp}(x_j^\top\alpha)\},
\]
multiplying a standard-normal latent effect. Target selectors resolve to registered identities and coefficient slices. The Poisson ordinary slice remains limited to scalar random intercepts. No NB, ZIP, slope, structured-target, or other unsupported extension is admitted by this checkpoint.

The Poisson coefficient extraction repair now routes through the shared registry-based splitter. Default long-format predictions now use registered group labels for random-scale targets; both source and fitted-model checks pass.

## 3a. Decisions and Rejected Alternatives

Keep the required scope as a finite source-derived union of response route × latent endpoint × mechanism/provider × existing covariance-dimension class × engine. Each row retains provenance and one of the current states: required, unresolved, blocked base plumbing, or structural inapplicability. No row is promoted to SD support by the inventory.

Reject silently dropping a cell because an engine lacks code, calling absent plumbing mathematically impossible, using one feasibility seed as calibration, or inferring programme completion from the current narrow native slice.

## 4. Files Touched

Work spans native R/TMB builders and methods, selector and prediction-label helpers, focused R tests, a private Julia numerical helper and tests, source-universe generator/TSV/contract, calibration and reference-pilot tooling, evidence receipts, and dev-log/design notes. These are grouped categories, not an exhaustive changed-file listing; the lane worktree is authoritative.

## 5. Checks Run

Recorded receipts:

- Selector path: 24 source assertions, 22 compiled assertions, and 12 workflow assertions. The native checkpoint records 117 compiled expectations; the selector receipt reports 392 distinct assertions across its suite family.
- Existing native regressions: Gaussian random-effect tests 89; clamp tests 26; binomial link tests 66; binomial response tests 60.
- Poisson extraction: four initial compiled test errors exposed missing coefficient extraction and were retained. After the registry-driven splitter repair, the final source assembly test passed 29 expectations. An earlier blanket Poisson rejection expectation in a Gaussian regression was narrowed only after the valid count-response route was checked.
- Prediction-label checks: 11 source assertions passed, including a public-method mock with distinct observation and group row counts. No model was fit in that source run.
- Final fresh Totoro output-label build: 305 compiled assertions passed, including 28 Poisson assertions, 11 prediction-label assertions, selector workflows and the six original Bernoulli files. One deliberate clamp warning was retained. The fitted R/C++ code remained unchanged when the Poisson labelled-base fence was clarified in reference prose and one source rejection assertion was added. The exact compiled source archive is `eaf3198f9a703c4d88e21b106dc0c9dbe16fa8adef1235be83da33aa7167c417`; its source manifest, binary hashes, environment and logs are in `evidence/poisson-20261017/output/`.
- Private Julia helper: 25 direct numerical assertions passed. Public Julia integration remains blocked on ownership of shared bridge files.
- Source universe: 18,996 rows with 72 valid narrow exclusions; G0 remains open.
- DRAC feasibility: one seed completed in about two minutes; one fit/profile took 13.715 seconds and agreed with the independent oracle to 7.5e-9. This supports feasibility and numerical agreement only, not calibration.
- Three qualification workers completed, but summary generation failed on a subset-manifest path. The producer repair passed independent pure checks. A new live qualification is pending. No 15-case stress run or production campaign was launched.

The qualification summary repair passed independent pure checks; a newly sealed live qualification and the two-stage inference analyzer remain pending. Full package checks, rendered-document review, and final cross-engine reconciliation are not receipts in this checkpoint.

## 6. Tests of the Tests

The focused suites exercise target identity, coefficient-index slices, malformed selectors, binomial regressions, count-response likelihood agreement, and negative controls. The Poisson scalar-group Laplace calculation is an implementation oracle; the DRAC comparison checks one fit against it. Neither establishes interval calibration or operating characteristics.

The Poisson extraction tests failed in four retained compiled attempts and exposed a real output defect. The final extraction source test passed. The separate prediction-label helper test passed without fits; the integrated fresh output build remains pending.

## 7a. Issue Ledger

No issue comments, opens, closures, PRs, or email are recorded for this checkpoint. A full overlapping-issue audit remains a closeout action; no external communication was authorized.

## 8. Consistency Audit

The universe is the finite union of source-derived response routes, endpoint kinds, provider/input primitives, and covariance-dimension classes across native and Julia source pins. It does not introduce new response families, more than two responses, random effects on SD-formula right-hand sides, or arbitrary provider/correlation combinations. Structured q1 and q>1 source shapes remain distinct rows; q domains are symbolic and bounded by existing source shapes.

A missing engine counterpart stays blocked as missing plumbing. No row disappears merely because the corresponding likelihood or SD builder is not yet wired. The native Poisson implementation reviewed here covers only the ordinary scalar-intercept slice and selected native scalar targets. The 18,996-row registry still needs independent G0 audit before its completeness can be claimed.

## 9. What Did Not Go Smoothly

The Poisson coefficient splitter initially omitted new SD coefficients, producing four retained compiled test errors before repair. One pre-existing test expected a blanket Poisson SD rejection and required narrowing after count-response validation. Qualification summary generation could not resolve its subset manifest path. The first source-count export failed on a list column after all tests passed. The corrected export retained 120 passing source assertions across 23 tests.

The advertised repository checker was absent. The canonical hub checker at `~/shinichi-brain/tools/check-after-task.R` was then used for this report.

## 10. Known Residuals

- No repeated-sampling calibration evidence is available. The one-seed DRAC run is only a feasibility/oracle check.
- The universe remains at G0 open; rows may not be excluded solely for missing engine plumbing.
- A new live qualification is required after the summary repair; production remains unlaunched.
- Julia's 25-assertion private module does not establish public fit/prediction parity; shared bridge ownership is pending.
- The final focused native build passes. Full package checks, cross-engine review, rendered-page inspection and programme closeout remain open.

## 11. Team Learning

Separate source assembly, compiled execution, fit health, independent numerical agreement, and calibrated uncertainty in both tests and receipts. Preserve every failed attempt and denominator. In a large finite family-by-mechanism universe, require the registry to fail closed on missing engine mirrors, lost candidate members, and missing provenance before implementation can advance.

## Design-Document Updates

Native formula and likelihood notes, formula vignette, NEWS, limitations, roadmap, selector/target documentation, and dev-log evidence were updated in the active worktree. The scope registry, block-dimension contract, and calibration design document the approved finite axes and unresolved rows. Full status-inventory reconciliation remains open.

## Pkgdown and Documentation Updates

Source documentation and formula-related notes are present in the active worktree. No pkgdown build, rendered-page inspection, or complete documentation status audit is recorded here. Target Rd validation, HTML conversion and `pkgdown::check_pkgdown()` passed; full rendered-page inspection remains open.

## 12. Cross-Product Coverage

The required matrix spans existing source routes × latent endpoints × provider/input mechanisms × covariance-dimension classes × both engines. It preserves source-admitted combinations even where implementation is absent, marking them blocked with provenance; only 72 rows currently carry narrow mathematical-exclusion status. This is a scope registry, not a claim of 18,996 implemented models.

The verified native work is the ordinary Poisson scalar-intercept slice plus selector/output paths and regression evidence listed above. It does NOT cover random slopes, correlated or structured SD targets, other family/endpoint routes, Julia public dispatch, the R bridge, missing-data combinations, REML/AI-REML, or interval calibration. The private Julia work remains numerical-only. No blanket family, provider, endpoint, q-dimension, engine-parity, or calibration support claim follows.

Prose self-assessment: 3/10 perceived AI-like style, medium confidence. The separate exact-draft record retains evidence and distinct scientific, factual and reference gates; this assessment is not programme closure.

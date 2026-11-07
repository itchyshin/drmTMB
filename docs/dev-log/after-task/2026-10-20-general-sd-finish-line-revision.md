# After Task: General SD implementation finish-line revision

## 1. Goal

Keep the full predictor-dependent random-effect SD scope across supported
families, effect types, providers, and both engines. Move interval-coverage
calibration out of the current completion gate while retaining light
correctness, equivalence, and fixed-seed recovery checks.

## 2. Implemented

The active goal, phased plan, execution arcs, unlazy ledger, and checkpoint now
agree that implementation and light checks define the current finish line.
Coverage calibration is a separate follow-on. The full support matrix remains
in scope; no family or effect row was removed. The Codex goal control exposes
status changes but no active-objective edit operation, so the durable goal file
and its linked plan are the revised scope record.

## 3. Mathematical Contract

No model equation, parameterization, formula grammar, or covariance convention
changed. The change is about the order and acceptance boundary for validation.

## 3a. Decisions and Rejected Alternatives

Coverage calibration is deferred, not removed from the research programme.
The implementation goal still requires all currently supported family, effect,
provider, layout, and engine rows wherever identifiable. Keeping 95% coverage as
a release gate now, or narrowing the capability scope to make the schedule look
shorter, was not selected.

## 4. Files Touched

- `LOOP/lanes/general-sd-regression/GOAL.md`
- `LOOP/lanes/general-sd-regression/ultra-plan.md`
- `LOOP/lanes/general-sd-regression/arcs.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `.unlazy/general-sd-regression/GATES.md`
- `docs/dev-log/general-sd-regression/deferred/native-calibration-GATES.md`
- `docs/dev-log/check-log.d/2026-10-20-general-sd-implementation-first-sequencing.md`
- `docs/dev-log/after-task/2026-10-20-general-sd-finish-line-revision.md`

## 5. Checks Run

- `Rscript -e 'devtools::test(filter = "lognormal-sd-assembly")'`: 24 passed,
  0 failed, 0 warnings, 0 skipped, 1.5 seconds. Assembly only; no model fit.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e
  'devtools::test(filter = "lognormal-sd-integration")'`: 24 passed, 0 failed,
  0 warnings, 0 skipped, 69 seconds. Native synthetic integration/recovery and
  oracle check; no live Julia and no interval-coverage validation.
- `git diff --check` passed for the revised goal, plan, arcs, checkpoint, and
  ledger.
- The naturalness checker reported zero findings for the revised goal and
  plan. The check-log note and this report are checked after drafting.
- `Rscript ~/shinichi-brain/tools/check-after-task.R` passed the report-structure
  check, then correctly returned the broader acceptance ledger as unmet. The
  active ledger has 8 parent gates and 10 child gates open. This report closes
  only the goal-rescope subtask, not the implementation programme.
- The required status inventory search was
  `rg -n -i 'calibrat(ed|ion)|coverage|profile interval|confidence interval' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd vignettes/predictor-dependent-random-sd.Rmd _pkgdown.yml`.
  It found existing statements that interval coverage is unvalidated and no
  conflicting claim that this goal's coverage calibration is complete.

## 6. Tests of the Tests

No test was added in this scope-update task. The existing lognormal assembly
test checks positive formula assembly, constant SD, selector metadata, and
rejection of within-group-varying predictors and unsupported combinations.
The integration test exercises recovery and an independent likelihood
comparison on its synthetic fixture. Neither establishes interval coverage.

## 7a. Issue Ledger

Open issue #1551 was inspected because it concerns the Julia Poisson/Gamma
ordinary-intercept bridge. It remains open; this internal goal update did not
change mainline code or provide a release fix. No issue was opened, closed, or
commented on.

## 8. Consistency Audit

The public status and formula documents already describe interval limitations.
The previously filed sequencing note contained an older finish-line statement
and estimate; a superseding note now marks those claims withdrawn. P8/G5 remains
available as a later validation phase. The candidate worktree is dirty and
shared source files have extensive work on other refs, so no model source was
changed in this task.

## 9. What Did Not Go Smoothly

The generic lane preflight reports many active lanes, and source-level
preflight found 63 refs with changes to `src/drmTMB.cpp` missing from this
checkout. The Julia candidate also has a separate owner and dirty inference
sources. I kept this update to leased planning and test-record paths, then sent
the DRM.jl task a narrow ownership question before attempting further Julia
work.

## 10. Known Residuals

The overall goal remains active. The full family/effect/provider/backend map
and implementation gates are not complete. The current candidate bridge
results do not establish universal Julia parity. Interval coverage is not
validated for the new routes. A provisional planning range of 60-120 calendar
days with two or three sustained contributors was communicated, but it is not
a measured schedule; the plan requires dependency-clustered re-estimation.

## 11. Team Learning

When validation scope changes, update the goal, plan, execution table,
acceptance ledger, and checkpoint together. Label coverage as deferred rather
than leaving it in a gate that silently blocks implementation completion.

## 12. Cross-Product Coverage

This task changed internal goal and validation documents only. No Julia source,
R package interface, release text, vignette, or pkgdown navigation changed.
The Julia bridge results cited in the checkpoint are prior candidate-worktree
evidence and were not rerun here. No compute campaign ran on Totoro or DRAC.
This report does NOT cover implementation completion, capability-row closure,
live Julia parity, interval calibration, or release readiness.

## Next Actions

Continue the core-family implementation and light checks on paths with clear
ownership. Confirm the Julia file owner before editing shared inference or
family files. Keep coverage campaigns deferred until the implementation waves
are complete and the follow-on is separately approved.

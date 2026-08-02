# Arc 6 F3R — plan versus actual

## Plan

F3R was scoped as a 2–2.5 hour private build: correct F1M provenance, freeze the F3 one-attempt contract, build a dedicated runner with pure tests, verify it, and retain a commit-ready approval target.  It explicitly excluded executing the runner.

## Actual

The planned documentation and runner surfaces were completed.  Independent review found and repaired four pre-execution contract issues: non-frozen split CLI syntax, an unreliable direct-execution guard, unvalidated terminal status combinations, and missing rectangle/fit-diagnostic evidence.  A final provenance alignment changed the dataset hash from CSV bytes to the serialized RDS object.

## Verification and scope

The dedicated runner test passed 47 expectations; both focused F1 suites and `git diff --check` passed.  No runner main call, dataset generation, fit, association, private sandwich calculation, remote task, or public surface occurred.

## Disposition

Adaptive repair, not scope drift.  The next task is a fresh, separately approved F3 execution at the final F3R runner SHA.

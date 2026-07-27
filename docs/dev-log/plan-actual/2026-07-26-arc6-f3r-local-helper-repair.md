# Arc 6 F3R — plan versus actual: local-helper lifecycle repair

## Plan

Repair the private-helper preflight contract only, preserve the one-attempt
design, add a regression test for local namespace ordering, and stop before F3.

## Actual

The helper check moved from `f3r_preflight()` to immediately after
`f3r_load_local_namespace()` in `f3r_main()`, before `f3r_layout()`. A pure
test verifies a synthetic local namespace and the source ordering. No runner
was invoked and no output directory was created.

## Reconciliation

**No scope drift:** the CLI, seed, output path, SHA/blob guards, and immutable
receipt design are unchanged. **Next decision owner:** Shinichi must approve
exactly one F3 invocation at the newly committed source SHA.

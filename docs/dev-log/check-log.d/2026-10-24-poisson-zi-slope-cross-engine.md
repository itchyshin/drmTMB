# ZIP selected mean-slope SD cross-engine evidence

- Command: `devtools::test(filter = "julia-poisson-zi-sd-regression", reporter = "summary", stop_on_failure = TRUE)` with the paired Julia candidate and one Julia/OpenBLAS thread.
- Result: exit 0; two live Julia bridge fits ran, with no failures or skips. The Julia focused ZIP suite passed 33 checks across intercept and selected-slope routes, including the scalar integration, seeded simulation, profile, and bootstrap smoke checks.
- Binding: before/after source manifests match for 169 files; the current bridge test SHA-256 is `ec0dd301a70f49c034a0389ba6c67b7eca31afc9b7c105bd603b25e4ed68b605`.
- Reconciliation: pass; 47 receipt records link to 38 of 19,118 required rows. The slope rows are unreviewed evidence only; no interval-coverage claim is made.
- Details: `docs/dev-log/after-task/2026-10-24-poisson-zi-slope-cross-engine.md`.

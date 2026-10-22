# Plot-data validator tests (#1607)

The exact PR head inspected before rebase was
`7294ed7fa3dead693a8f03de3e21b6dbadec3bf8`; GitHub `main` was
`f9bff01b5f3bbbc424402b73d67084dd446d9ff8`. Local focused tests below run on
the combined rebased tree. They do not represent remote exact-head CI. The
remote branch remains at the PR head until the refreshed branch is pushed.

The fit-free test file SHA-256 remains
`da2a0b562c846510ef1679f4c3e3252c0deafba3a2bd3a169c9534a8ec46ad68`.
The test file is retained unchanged by this closeout. The root chronological
`docs/dev-log/check-log.md` append conflicted with current main and was removed;
this per-slice record is retained.

Local combined-tree results will be recorded after the focused
`plot-data-validators` and `env-skip-census` test commands complete. No model
fit or live Julia bridge is exercised. The full test suite, `R CMD check`, and
rendered-plot behavior are outside this focused characterization.

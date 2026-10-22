# Plot-data validator tests (#1607)

The exact remote PR head inspected before rebase was
`7294ed7fa3dead693a8f03de3e21b6dbadec3bf8`; GitHub `main` was
`f9bff01b5f3bbbc424402b73d67084dd446d9ff8`. The PR was rebased locally; both
focused tests ran on local commit `245bb04cabc1fa16948c07e5dab3355e775aa6f3`.
They are evidence for that local combined tree, not remote exact-head CI. The
remote branch remains at the original PR head until the refreshed branch is
pushed.

The fit-free test file SHA-256 remains
`da2a0b562c846510ef1679f4c3e3252c0deafba3a2bd3a169c9534a8ec46ad68`.
The test file is retained unchanged by this closeout. The root chronological
`docs/dev-log/check-log.md` append conflicted with current main and was removed;
this per-slice record is retained.

- `Rscript -e 'devtools::test(filter="plot-data-validators", reporter="summary")'`:
  124 expectations; no failures, warnings, or skips.
- `Rscript -e 'devtools::test(filter="env-skip-census", reporter="summary")'`:
  five expectations; no failures.

No model fit or live Julia bridge is exercised. The full test suite, `R CMD
check`, and rendered-plot behavior are outside this focused characterization.
`git diff --check` passed. I manually compared the report sections with the
repository protocol; no automated structure checker is present in this clone.
The prose-style check found no issues.

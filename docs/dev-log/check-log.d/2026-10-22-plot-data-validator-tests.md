# Plot-data validator tests (#1607)

On PR head `f9eff0bc3a3c9e3d5ecdf0e30cb576bf5f99bbbd`, ran
`Rscript -e 'devtools::test(filter="plot-data-validators", reporter="summary")'`
with R 4.6.0. The focused fit-free test file completed successfully; no model
fit or Julia live bridge was exercised. The PR's earlier run records 124
passing expectations. Also ran
`Rscript -e 'devtools::test(filter="env-skip-census", reporter="summary")'`;
all five expectations passed, confirming this test-only addition does not alter
the census.

The PR is based on `aa33f1e93c8e3dbfdd4287742c9a8cf1954d2848`; current GitHub
`main` is `2cc6ee63ed1b32512346cfd79df4e256445bc61f`. GitHub reports the branch
nine commits behind `main`; the PR's two added paths do not overlap with the
paths changed on `main` or in the adjacent #1605/#1606 test-only slices. The
current `main` commit is absent from the shared local object database, so this
worktree was not rebased and this test was not rerun on updated `main`.

No full package suite, `R CMD check`, or current-main test result is claimed.

Follow-up on 2026-10-22: narrowed the eye-data test title to its actual
assertions (empty input, row count, bounds, group and colour); the assertions
were unchanged. Re-ran the focused command above successfully on R 4.6.0.
Updated test-file SHA-256:
`da2a0b562c846510ef1679f4c3e3252c0deafba3a2bd3a169c9534a8ec46ad68`.

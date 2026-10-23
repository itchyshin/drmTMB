# Current-main change impact — candidate `6b45164b…`

The source commit is merge commit
`5485ccb8aeca404412fd346a3a538d0e57808c79` from PR #1074. It contains the
reader-surface and release-governance repair requested by the rejected
`e9c5556d…` Gate 7 panel.

## Shipped impact

PR #1074 changed no R runtime implementation and no C/C++ likelihood code. It:

- aligned `DESCRIPTION`, `README.md`, `NEWS.md`, `_pkgdown.yml`, the introductory
  vignette, capability guide, formula guide, and neighbouring vignettes on the
  0.7.0 pre-CRAN identity;
- moved six heavy reader pages to pkgdown-only development articles, reducing
  installed documentation below the CRAN guideline without deleting their
  public documentation;
- removed the unverified generated cheatsheet PNG from the built package;
- documented original logo authorship and licence in `inst/COPYRIGHTS`; and
- added release-identity tests that compare the independent reader surfaces.

The resulting tarball has 945 entries, SHA-256 `6b45164b…`, and size 4,367,799
bytes. It is not byte-identical to either predecessor candidate, so all
artifact-dependent evidence was rerun.

## Build-excluded coordination impact

PR #1073 merged at `12a5cc5bcc36ed1b83d969e5147e29bc98aaadf6`. Its four
files are `AGENTS.md` plus three files under `docs/`; `.Rbuildignore` excludes
both paths. The PR is therefore part of source history but absent from the built
package. Its Ubuntu release job was green before merge.

The evidence and ledger files added after the freeze live under `docs/` and are
also build-excluded. They cannot change candidate bytes.

## Protected scope

PR #1033, `_julia_skip2_artifacts/`, `submit_cran()`, and the submission decision
remain outside this lane. The ledger can advance only to the rung supported by
the recorded evidence and independent panel.


# 2026-09-18 — D-269 selected-manifest runtime guard

PASS for the narrow #1381 compatibility diagnostic.  After JuliaCall starts
its actual runtime but before the selected checkout is activated or imported,
the bridge asks Julia to resolve that checkout's manifest using Julia's own
selection rules.  A format-2.1 manifest with Julia older than 1.13 now stops
with an actionable error rather than a downstream dependency/precompile
failure.  This does not say that DRModels itself requires Julia 1.13: its
`Project.toml` still declares Julia 1.10 compatibility, and only the known
format-2.1 incompatibility is rejected.

Verification: the new regression test was observed failing before the guard,
then `devtools::test(filter = "julia-module-compat")` PASSed (47 pass, one
expected live skip).  The adjacent Julia bridge contexts PASSed (204 pass, 3
expected live skips, 2 pre-existing beta deprecation warnings).  Fresh live
smokes proved both boundaries: Julia 1.10.0 named the selected `Manifest.toml`
and stopped before activation; Julia 1.13.0 activated the checkout and loaded
`drmTMB_backend` as `DRModels`.  `git diff --check` and R parsing PASSed.

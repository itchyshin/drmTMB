The R-to-Julia bridge now admits one complete-data Binomial `relmat()` location
intercept with the matching `sd(id, level = "relmat") ~ z` formula. A live
same-data synthetic fit on the paired development checkouts passed the focused
bridge test, including point-recovery and target-specific SD prediction
comparisons. The current-source formula-grammar, model-map, and Julia-engine
vignettes rendered,
and `pkgdown::check_pkgdown()` found no problems apart from existing Pandoc
MathML deprecation warnings. This is one candidate-source point-parity cell,
not interval calibration, broad Julia support, or support in shared/released
DRM.jl. A separately shuffled labelled covariance also passes live parity after
the bridge aligns labelled K/A by group first appearance. The overlapping-ref
review found and removed a duplicate `drm_julia_rhs_is_intercept_only()`
definition, protected by source-count and formula-semantics tests. Details:
`docs/dev-log/after-task/2026-10-21-julia-binomial-relmat-sd-parity.md`.

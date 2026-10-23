# 2026-09-18 — D-269 bridge review fixes

PASS for the non-overlapping corrective slice on PR #1381.  The live formula
probe now interrogates the selected backend binding rather than assuming a
legacy `DRM` module, and the isolated relmat child pins its selected checkout
through the canonical `drmTMB.DRModels.jl.path` setting.  The location-scale
vignette link now uses the public DRModels.jl Pages address.

Verification: package-loaded focused formula and structured test groups PASS
(live cells skip without a configured checkout); a canonical-precedence
assertion PASSed; a Julia 1.13 live setup loaded `DRModels`; `knitr::knit()` of
the vignette and `git diff --check` PASSed.  The local Julia 1.10 live attempt
failed before bridge assertions because its default JuliaCall dependency set is
incompatible with the checkout's Julia-1.13 manifest; this is recorded as a
follow-up compatibility risk, not hidden as a passing live check.

# 2026-09-18 — D-269 bridge reader wording

Documentation-only PASS. `NEWS.md` and the Julia-engine vignette now describe
the actual selected-checkout contract: read `Project.toml`'s declared package
name (`DRModels` or legacy `DRM`) and verify the resolved/loaded source path.
They no longer claim an inaccurate module-name fallback.

Verification: `git diff --check` PASS; `knitr::knit()` of
`vignettes/julia-engine.Rmd` to a temporary file PASS. No bridge code, API,
release, or Pages deployment changed.

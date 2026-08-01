# Phase 1.5 #5 Hopper finish-matrix — paired R ↔ Julia (2026-08-01)

**Lane:** Hopper / Shannon (twin inventory).  
**Bar (Q3):** admitted cells + result-shape for **Gaussian uni / bivariate / first phylo mean** + gate-ID rejections; stay **experimental**; no new families.  
**Rose fence:** this package’s `vignettes/julia-engine.Rmd` may keep Julia **deferred for CRAN readers**; twin DRM.jl docs keep **experimental**. Do **not** claim CRAN Depends on JuliaCall.

Canonical twin: `itchyshin/DRM.jl` → `docs/dev-log/plans/bridge-finish-matrix-2026-08-01.md`.

---

## 1. Admitted cells (Hopper #5 trio)

| Cell | capability_id | R evidence | Julia evidence | Status |
|---|---|---|---|---|
| Gaussian uni loc-scale | `base_gaussian_location_scale` | `test-julia-bridge.R` + Route C parity | DRM.jl `test/test_bridge.jl` | **EVIDENCED** (experimental) |
| Bivariate residual `rho12` | `biv_gaussian_residual` | Offline shape + Route B parity | DRM.jl `test/test_bridge.jl` | **EVIDENCED** (experimental) |
| First phylo mean | `gaussian_phylo_mean` | Offline shape + Route A parity | DRM.jl `test/test_bridge.jl` + inference | **EVIDENCED** (experimental) |

Helper: `drmTMB:::drm_julia_phase15_admitted_cells()`.

---

## 2. Gate IDs

`drm_julia_intentional_gates()` (15 IDs) + `test-julia-gate-vs-engine.R` + `julia-gates.tsv`. Pre-JuliaCall aborts; patterns listed in the registry. No new families opened in this slice.

---

## 3. Close DRM.jl #5?

Propose **yes after Rose PR pass** — matrix + offline result-shape + gate registry evidenced; live JuliaCall parity remains skip-guarded; public vignette stays deferred/experimental for CRAN.

---

*Worktree: `hopper/bridge-finish-phase15-5` off `origin/main`. Did not touch dirty `claude/handover-freshness-0718`.*

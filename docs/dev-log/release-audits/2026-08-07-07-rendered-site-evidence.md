# Rendered-site / claim-surface evidence — 0.7.0 readiness

**Date:** 2026-08-07  
**Commit base:** `8df6f2402` (+ docs `7bacb9e2c` + claim-freeze WIP)

## What was checked (source, not a full pkgdown rebuild)

1. README experimental banner + lifecycle badge present (D-41).
2. README states not on CRAN; CRAN target 0.7.0.
3. README preview-status line corrected from stale "0.5.0 development version"
   to **0.6.0 development cycle**.
4. NEWS records 135-trace promotions and D-117 boundary warning honestly.
5. `?confint.drmTMB` Boundary intervals section present on source.
6. No unqualified "CRAN ready" string on README / NEWS / cran-comments.

Full `pkgdown::build_site()` / article render is **not** re-run in this slice;
post-merge pkgdown Actions on #930 was green
(https://github.com/itchyshin/drmTMB/actions/runs/31047116604). Treat a fresh
local site build as owed before **submission-ready**, not before source-clean.

## Audit pointer

`docs/dev-log/release-audits/2026-08-07-07-cran-claim-audit.md`

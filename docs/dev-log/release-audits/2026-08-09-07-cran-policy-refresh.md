# CRAN policy refresh — 0.7.0 candidate (Gate -1)

**Read on:** 2026-08-09 · **Candidate:** `drmTMB_0.7.0.tar.gz`, SHA-256 `d35c0b9e…`
**Sources fetched today:** `https://cran.r-project.org/web/packages/policies.html` (HTTP 200),
`https://cran.r-project.org/web/packages/submission_checklist.html` (HTTP 200).

Each threshold below is labelled **current policy** (stated in the policy document),
**observed incoming behaviour** (seen from CRAN's machines, not written policy), or
**local margin** (our own conservative bound, not a CRAN concept).

## Verified: drmTMB is not on CRAN

`https://cran.r-project.org/package=drmTMB` → 303 → **404** at
`.../web/packages/drmTMB/index.html`. The `New submission` NOTE is therefore correct and
`release_type = first_submission` stands.

## ⚠ Finding: documentation size exceeds the stated policy maximum

**Label: current policy.** Quoted verbatim from today's read:

> As a general rule, neither data nor documentation should exceed 5MB (which covers several
> books). A CRAN package is not an appropriate way to distribute course notes, and **authors
> will be asked to trim their documentation to a maximum of 5MB.**

**Measured on the frozen candidate: `inst/doc` is 11.11 MB in the tarball** (11.4 Mb
installed). That is **2.2× the stated maximum**, and the wording is not advisory — it says
authors *will be asked* to trim.

The local check does **not** flag this. It reports only:

```
* checking installed package size ... INFO
  installed size is 31.2Mb
    R 3.1Mb · doc 11.4Mb · libs 13.6Mb · sim 1.9Mb
```

An `INFO`, not even a NOTE. This is exactly the failure class this protocol was written
for: substantive checks all pass while a different release surface is out of policy.

### What drives it

Self-contained vignette HTML with base64-embedded figures:

| File | Size |
| --- | ---: |
| `figure-gallery.html` | **2.90 MB** |
| `function-map-cheatsheet.html` | **1.52 MB** |
| `simulation-plot-grammar.html` | 0.73 MB |
| `model-workflow.html` | 0.63 MB |
| `distributional-outputs-and-adequacy.html` | 0.47 MB |
| remaining 32 vignettes | ~4.9 MB combined |

The top five alone are **6.25 MB** — more than the entire allowance.

### Options, none of them taken here

This is a **product decision about which vignettes ship**, not a packaging tweak, so Stage B
records it rather than acting on it.

1. **Move gallery-style articles to pkgdown-only.** `figure-gallery` is arguably a website
   artifact rather than package documentation, and `function-map-cheatsheet` exists mainly
   to display one 1.1 MB PNG. Dropping both from the package while keeping them on the site
   removes ~4.4 MB and takes `doc` to roughly 6.7 MB — still over, but close.
2. **Reduce figure resolution / switch to vector output** in the heaviest vignettes.
   Lower-DPI raster or SVG would cut the base64 payload substantially without losing any
   article.
3. **Set `build_vignettes = FALSE` for the heaviest few** so the source ships but the built
   HTML does not.
4. **Justify in `cran-comments.md`** and submit as-is. Weakest option given the policy
   wording, but it is a legitimate choice for a maintainer who judges the documentation
   proportionate.

`libs` at 13.6 MB is a separate matter and is **not** covered by the 5MB documentation rule
— it is compiled TMB object code, intrinsic to this class of package, and CRAN's own
`glmmTMB` carries the same pattern.

## Other thresholds carried

| Threshold | Label | Status on this candidate |
| --- | --- | --- |
| ~10-minute Windows incoming check time | **observed incoming behaviour**, not written policy | Vignette rebuild measured **96s wall**, total local check **15m29s**, on Apple-silicon macOS. Encouraging but **not evidence** — macOS timing is not Windows timing. win-builder in the platform matrix is the real measurement. |
| Installed size note | observed | 31.2 Mb, reported as INFO. Driven by `libs` 13.6 + `doc` 11.4. |
| 75-minute CI ceiling | **local margin**, measured 2026-08-04 | Not a CRAN concept; applies to our own Actions runs. |
| `_R_CHECK_FORCE_SUGGESTS_` must not be disabled for the claim-bearing check | current policy practice | Honoured — not set in the claim-bearing run. |

## Bearing on the rung

**None on `tarball-clean`.** That rung is about whether the exact built tarball passes
CRAN-shaped local checks, and it does: Status 1 NOTE, `New submission` only.

**Material to `submission-ready`.** Gate 8 should not be entered while a stated policy
maximum is exceeded by 2.2× without a deliberate owner decision recorded against it.

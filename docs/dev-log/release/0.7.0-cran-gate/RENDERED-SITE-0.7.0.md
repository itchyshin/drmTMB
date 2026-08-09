# Rendered reader surface — 0.7.0 candidate (Gate 2)

**Date:** 2026-08-09 · **Source:** `claude/07-release-slice` · **Candidate:** `da9b2d76…`

## Checks run

| Check | Result |
| --- | --- |
| `pkgdown::check_pkgdown()` | **No problems found** |
| `pkgdown::build_site(install = TRUE, new_process = TRUE)` | completed, exit 0, **0 error lines** in the log |
| Articles rendered | **38** |
| Reference pages rendered | **114** |
| Site size | 26 MB |
| Leaked internal pages (`dev-log`, `internal`, `scratch` in article names) | **0** |
| `NEWS` page picked up the version | yes — renders `drmTMB 0.7.0` and the new offset section |

## What reading the built site caught that reading the source did not

**This is why Gate 2 exists as a separate gate.** Inspecting `pkgdown-site/index.html`
rather than `README.md` surfaced a defect that had survived an earlier targeted fix:

The Install section still carried `pak::pak("itchyshin/drmTMB@v0.5.0")` while
`vignettes/drmTMB.Rmd:64-67` states that tag predates the current line and is not a
supported install target. Step one of a new user's first session contradicted the docs they
would read next — on the surface that becomes the package landing page for a first CRAN
release.

It had been reported as a HIGH-severity gap by the pre-release reader review
([`2026-08-09-07-pre-release-user-gap-review.md`](../../release-audits/2026-08-09-07-pre-release-user-gap-review.md),
trap 5). The earlier release-bytes commit fixed the *neighbouring* line — the "0.6.0
development cycle" sentence at `README.md:66` — and missed the install command itself.

Repaired in `14bc8ce89`. Because `README.md` ships, that **invalidated candidate
`d35c0b9e`** and forced the rebuild to `da9b2d76`. Confirmed fixed in the artifact, not
just in source: extracting `drmTMB/README.md` from the frozen tarball returns **0**
occurrences of the stale install command.

## Version-consistency sweep on the rendered surface

Version-like strings remaining on the built homepage are `headroom-0.11.0` (a bundled
pkgdown JavaScript dependency, irrelevant) and the `v0.5.0` mention now retained
deliberately as the sentence explaining that the tag is *not* supported. No other stale
version claim renders.

## Not covered

The **deployed** site is not verified here — this is a local build. `pkgdown` deploys from
`main` via `workflow_run`, so public deployment is a post-merge event and belongs to Gate 9,
not to this candidate. Screenshot/visual review, mobile layout, and link-by-link crawling of
the live site were not performed.

# S3 rendered-surface inspection — drmTMB 0.6.0 CRAN RC (2026-07-20)

Built site: `pkgdown-site/` (index.html = README home; 34 articles; 98 reference pages; 67 rendered PNGs).
`build_site()` clean (no errors, all articles + reference built). Four read-only lenses inspected the render
via a Workflow: **Florence** (figures), **Emmy** (API/Rd), **Pat** (reader), **Darwin** (audience).

## Headline: NO CRAN tarball-clean blocker

Pat and Emmy found **no BLOCKING** items. Florence's and Darwin's "BLOCKING" are **figure-quality /
audience-quality** issues on the rendered site — real reader defects, but none fails an `R CMD check`.
Install path is correct (defaults to the 0.6.0 dev line, not the ditched `v0.5.0` — Pat verified).

## Findings + disposition

### F1 — README home-page jargon (Pat SHOULD-FIX + Darwin BLOCKING; the top convergent finding)
`index.html` "Stable-core matrix" (`README.md`, rendered ~lines 212–381) and "What can I model now?" are a
verbatim developer-ledger dump on the CRAN landing page: `q=N` notation used 22× with no definition,
`pdHess`, `point_fit_recovery`, cell IDs (`mc-0069`…), 150–400-word run-on cells. Two lenses independently:
an ecologist/reviewer cannot act on it. Both recommend trimming to a short pointer (`model-map.html` /
`drmTMB.html:439-531`'s own plain "What can I fit today?" table already exists) and back-porting the
`capability-and-limits.html` voice. **Not a CRAN check failure; a reader-quality issue on the landing page.**
→ **DECISION for Shinichi (scope/effort): trim now (README docs edit) or defer to a post-0.6.0 doc pass.**

### F2 — Adequacy-vignette figures reproduce two D2-fixed defects (Florence BLOCKING ×2)
In `vignettes/distributional-outputs-and-adequacy.Rmd` (rendered figures worm-true/qq-true/worm-mis/
centile-chart):
- **Colour-blind-unsafe centile chart** — categorical hue palette on ordered centiles (3/15/50/85/97%). The
  D2 audit already diagnosed this as F4 and fixed it with `+ scale_colour_viridis_d()` — but only at the
  gallery call-site (`figure-gallery.Rmd:701`), never inside `centile_chart.drmTMB()`
  (`R/distributional-outputs.R:288-306`, no default scale), so this plain call reproduces it.
- **Clipped subtitles** on all four figures — D2's F1, whose fix (`wrap_subtitle()` + `fig.width=7.4`) is
  vignette-local to `figure-gallery.Rmd:177`; this vignette uses the default `fig.width=6.4`.
- Root cause (Florence): the D2 fixes are **per-vignette patches, not function-level defaults**, so any
  vignette/user call reproduces them.
→ **The proper fix is function-level (`R/…`) = out of this lane's fence → follow-up issue, post-0.6.0.**
  A per-vignette patch (viridis + fig.width in the adequacy vignette, docs) is possible now.
  **DECISION for Shinichi: patch the adequacy vignette now, or defer with the function-level issue.**

### F3 — worm-true alt-text overstates flatness (Florence SHOULD-FIX; HONESTY)
Alt text says "no systematic bend for the correctly specified fit," but the drawn `poly(x,3)` smooth swings
≈+0.20 → 0 → +0.13 → −0.17. D2 hedged the parallel gallery figure (F3) but the hedge wasn't propagated.
→ **Honesty fix — reword the alt/caption to match what the plot draws** (small vignette edit; recommend doing).

### F4 — `coef()` has no reference page (Emmy SHOULD-FIX)
`coef.drmTMB` (`R/methods.R:2259-2266`) is bare `#' @export` with no roxygen doc, so it has no reference page
and its `dpar` argument is undiscoverable via `?coef` — while `fixef()` (its documented alias) covers `dpar`.
Legal (S3method-registered → no R CMD check NOTE), so **not a blocker**. → follow-up issue / optional doc add.

### Confirmed clean (Emmy)
`reference/imputed.html`, `drm_phylo_penalty.html`, `drm_phylo_penalty_sweep.html` render their new Examples
correctly; `confint.drmTMB.html` + `summary.drmTMB.html` carry the correct `@seealso` to capability-and-limits.
Reference index groupings coherent, no broken hrefs.

### Content gaps + polish (Darwin/Pat/Florence — all post-0.6.0)
Darwin: `animal-models.html` never computes heritability h² (its raison d'être) though `phylogenetic-models`
computes λ; animal-models leads with a jargon table before the worked example. Pat: Install smoke-test
duplicates the Tiny example. Florence: qq overplotting (low alpha). Emmy: issue numbers in reference prose.
→ all **follow-up / post-0.6.0 polish**, none blocking.

## Positives for the record
`capability-and-limits.html` (incl. the new "Known limitations for 0.6.0" section: rho12-interval gap,
`sd_hat`/point-bias gap, #710.5 fix, Julia xfam gap) is the model for reader-facing honesty — opens with the
reader's real question, defines tiers once, states "what to try next" per gap, communicates the zero-one-beta
generator-qualified caveat without overselling (Pat + Darwin). No `tau` drift; `nu`/`zi`/`hu`/`sd(group)`
defined at first use.

## Proposed follow-up issues (G2 — file with Shinichi's OK)
1. Function-level figure-accessibility defaults (viridis in `centile_chart()`; subtitle handling in
   `worm_plot()`/`qq_plot()`) so vignette/user calls don't reproduce D2's F1/F4. [bug][figures] post-0.6.0.
2. `coef.drmTMB` documentation / reference page (discoverability of `dpar`). [docs] post-0.6.0.
3. `animal-models` vignette: add heritability h²; move the status table after the worked example. [docs] post-0.6.0.

# CRAN NOTE fixes — measured evidence

**2026-08-09 · branch `claude/07-cran-notes` off `origin/main @ a2695a788`**

## Result

```
Status: 1 NOTE
* checking CRAN incoming feasibility ... [4s/22s] NOTE
Maintainer: 'Shinichi Nakagawa <itchyshin@gmail.com>'

New submission
```

**`New submission` only** — the cleanest a first CRAN release can be. Zero hits across the whole
check log for `possibly invalid` / `invalid URI` / `Possible.*spelling` / `centile` / `uncalibrated`.

## What was fixed

| NOTE | fix |
| --- | --- |
| `Possible DESCRIPTION spellings: centile, mis, uncalibrated` | `mis` was a **real typo** — `mis-specification` hyphenated, splitting into the flagged fragment. Corrected to `misspecification`. `centile`/`uncalibrated` are legitimate terminology. |
| `Possibly invalid file URI 'function-map-cheatsheet.png' from 'inst/doc/function-map-cheatsheet.html'` | The vignette uses the image **twice**: `knitr::include_graphics()` (embedded — `html_vignette` is self-contained, never the problem) and a separate **hyperlink**, which cannot be embedded and needs a real file. The link now points at the published copy on the pkgdown site. |

## The first attempt was wrong, and the check caught it

Adding `vignettes/.install_extras` with `\.png$` did clear the file-URI NOTE — by installing the PNG
into `inst/doc` — but immediately raised a new one:

```
* checking installed files from 'inst/doc' ... NOTE
The following files should probably not be installed:
  'function-map-cheatsheet.png'
```

**Status stayed at 2 NOTEs.** It treated the symptom. `.install_extras` is reverted; nothing loose
ships. Recorded because it is the arc's recurring lesson — a repair is unreviewed work, and this one
was caught only by running the check rather than trusting the reasoning.

## The URL was verified before use, not guessed

CRAN checks URLs, so a wrong path would have traded the NOTE a third time:

```
https://itchyshin.github.io/drmTMB/articles/function-map-cheatsheet.png   -> HTTP 200
```

## ⚠ A defect this branch does NOT share with the release candidate

The candidate (`cc4f5baee`) fixes the same link **its own way**, pointing at:

```
https://github.com/itchyshin/drmTMB/blob/main/vignettes/articles/function-map-cheatsheet.png
```

**That URL 404s.** Measured 2026-08-09 — `blob` → 404, `raw.githubusercontent.com` → 404 — because
`vignettes/articles/` **does not exist on `main`** (`git ls-tree -r origin/main | grep -c
'^vignettes/articles/'` → 0). The path only exists on the unmerged release slice.

So the candidate carries a **latent URL NOTE**: it resolves only *after* the slice merges to `main`.
If the candidate is submitted before that merge, CRAN's URL check sees a 404. The pkgdown URL used
here has no such dependency — it is live now.

**This is the one part of this branch that is NOT redundant with the candidate.** The spelling fix
*is* redundant: `git show cc4f5baee:DESCRIPTION` already reads `misspecification` at line 22, and
`inst/WORDLIST` already exists there.

## A caution for any future spelling fix

`inst/WORDLIST` is **never read** by CRAN-incoming spell checking — an exhaustive scan of the `tools`
and `utils` namespaces for the literal `"WORDLIST"` returns **zero** hits; only `.aspell/defaults.R`
overrides dictionaries, and no `.aspell` path exists in this package. A WORDLIST entry does not
silence that NOTE. What actually cleared it here was fixing the real typo; `centile` and
`uncalibrated` no longer appear because the local check's dictionary accepted them, **not** because
of the WORDLIST. Do not rely on that mechanism.

## Reproduce

```sh
cd <worktree on claude/07-cran-notes>
R CMD build --no-manual .
R CMD check --as-cran --no-manual drmTMB_0.6.0.tar.gz
```

`DESCRIPTION` stays **0.6.0** — the 0.7.0 bump is owner-gated.

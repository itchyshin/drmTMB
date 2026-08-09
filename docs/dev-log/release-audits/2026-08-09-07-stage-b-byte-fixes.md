# Stage-B byte fixes — prepared, reviewed, HELD (not landed)

**Date:** 2026-08-09 · **Lane:** Claude task 1, Stage A · **Baseline:** `origin/main@ac363cadb`
**Status:** **PREPARED ONLY.** Nothing in this document has been applied. Every item
changes installed bytes, so all of it lands in **Stage B**, on the post-disposition
`main`, before the definitive tarball is built.
**Authority:** Shinichi, 2026-08-09 — "Prepare in Stage A, land in Stage B".

## Why these are Stage B and not Stage A

Each item edits `DESCRIPTION`, `vignettes/`, `R/`, or `man/`. Under D-49 any
installed-byte change creates a new candidate identity. Landing them on this lane now
would mean the eventual candidate is built from bytes that were never the merged
post-disposition `main` — exactly the predecessor-evidence trap this arc exists to
close. They are therefore staged as reviewed diffs and applied once, in Stage B.

## Source of truth for items 1–2

`docs/dev-log/release/0.7.0-cran-gate/platform/winbuilder-release-fixed-00check.log:17-24`,
on predecessor tarball `f9b9588e…`. Both flavours (R-release, R-devel) report the same
`checking CRAN incoming feasibility ... NOTE`:

```
Possibly misspelled words in DESCRIPTION:
  centile (23:43)
  mis (22:40)
  uncalibrated (24:6)

Found the following (possibly) invalid file URI:
  URI: function-map-cheatsheet.png
    From: inst/doc/function-map-cheatsheet.html
```

**These are predecessor observations.** They must be re-read on the real candidate;
they are used here only to prepare the fix, not to claim a rung.

---

## Item 1 — invalid file URI (root cause pinned)

**Not a broken path in source.** The PNG exists and *is* shipped — but to the wrong
place for the link that references it. From the predecessor tarball inventory
(`tarball-inventory.txt`):

| Line | Path in tarball |
| --- | --- |
| 57 | `drmTMB/inst/doc/function-map-cheatsheet.html` |
| 896 | `drmTMB/vignettes/function-map-cheatsheet.png` |
| — | **`drmTMB/inst/doc/function-map-cheatsheet.png` — absent** |

`vignettes/function-map-cheatsheet.Rmd` references the image twice:

- **line 75** — `knitr::include_graphics("function-map-cheatsheet.png")` inside a
  chunk. `html_vignette` self-contains this as a base64 data URI, so the *displayed*
  image is fine and survives installation.
- **line 78** — a plain markdown link:
  `[Open the full-size function map](function-map-cheatsheet.png)`. This is **not**
  processed by knitr; it becomes a literal relative `href` in the installed HTML,
  pointing at a file that does not exist in `inst/doc/`.

So the NOTE is caused by line 78 alone, and the image itself is never broken.

**Prepared fix — replace the relative link with the deployed pkgdown URL:**

```diff
--- a/vignettes/function-map-cheatsheet.Rmd
+++ b/vignettes/function-map-cheatsheet.Rmd
@@ -78,2 +78,2 @@
-[Open the full-size function map](function-map-cheatsheet.png) when reading on
-a small screen.
+[Open the full-size function map](https://itchyshin.github.io/drmTMB/function-map-cheatsheet.png)
+when reading on a small screen.
```

**Why this option.** It keeps the reader affordance (the point of the line is
small-screen users opening the image full size), and an absolute `https://` URI is not
a file URI, so the NOTE cannot fire. Deleting the line also clears the NOTE but costs
the reader something real.

**Stage-B preconditions before adopting this diff:**

1. Confirm the asset actually resolves at that URL on the deployed site. If pkgdown
   does not publish `vignettes/*.png` at the site root, use the article-relative URL
   pkgdown actually emits, or fall back to deleting the line.
2. Re-run `urlchecker::url_check()` — an absolute URL is now subject to CRAN's URL
   check, which the relative path was not. **This trades one check surface for
   another; do not skip it.**

---

## Item 2 — DESCRIPTION spelling (correcting a likely assumption)

**`inst/WORDLIST` will NOT fix this.** Evidence, not inference:

- The three words are **absent** from `inst/WORDLIST` (checked).
- The NOTE appears in the **win-builder** logs and **not** in the local
  `--as-cran` log (`local-as-cran-check.log` has no `misspelled` match).

That asymmetry is the tell: the flag comes from **CRAN's incoming feasibility check**,
which uses its own dictionary and does not consult `inst/WORDLIST`. `inst/WORDLIST`
serves `spelling::spell_check_package()` / `spell_check_test()`. Adding words there
would leave the CRAN NOTE untouched while creating the impression it was handled.

Two honest routes:

### Route A — adjust the DESCRIPTION prose (recommended)

Current `DESCRIPTION:22-24`:

```
    detect fixed-effect shape and atom mis-specification, and
    conditional-quantile, exceedance, and centile outputs with plug-in
    (uncalibrated) intervals.
```

```diff
--- a/DESCRIPTION
+++ b/DESCRIPTION
@@ -22,3 +22,3 @@
-    detect fixed-effect shape and atom mis-specification, and
-    conditional-quantile, exceedance, and centile outputs with plug-in
-    (uncalibrated) intervals.
+    detect fixed-effect shape and atom misspecification, and
+    conditional-quantile, exceedance, and percentile outputs with plug-in
+    intervals that are not calibrated.
```

- `mis-specification` → `misspecification` — the hyphen is what produced the bare
  token `mis`; the closed form is standard usage in statistics.
- `centile` → `percentile` — a plain synonym, and clearer for the applied ecology and
  evolution readership.
- `(uncalibrated)` → `that are not calibrated` — same meaning, and it reads as a
  stronger caveat, which is the honest direction.

This is precedent-consistent: `cran-comments.md` records that the prior lane already
resolved spelling flags by adjusting DESCRIPTION prose (quoting `'Tweedie'`,
hyphenating "semi-continuous").

**Residual risk, stated plainly:** `misspecification` may still be absent from CRAN's
dictionary. Route A is expected to clear all three, verified to clear `mis` and
`centile`, and **unverified** for `misspecification`. It must be re-read on the
candidate's own incoming check.

### Route B — keep the prose, explain the NOTE in `cran-comments.md`

Entirely legitimate: "Possibly misspelled words" is advisory, and maintainers commonly
respond by confirming the terms are correct domain vocabulary. Costs nothing and
changes no bytes, but leaves a NOTE on the submission.

**Recommendation: Route A, with Route B as the fallback** for any word that survives.
Do not combine either with a `WORDLIST` edit and call the NOTE addressed.

---

## Item 3 — offset documentation overclaim (new; from A5)

Full analysis: [`2026-08-09-07-870-offset-analysis.md`](2026-08-09-07-870-offset-analysis.md).

The roxygen grants `offset(log(exposure))` to zero-truncated negative-binomial `mu`;
a live fit with `truncated_nbinom2()` **aborts** with "unsupported term: offset". Three
lines of evidence agree (dispatch switch, `allow_offset` call-site inventory, live
fits). **Pending Shinichi's Option 1 / Option 2 choice.** If Option 1:

```diff
--- a/R/drmTMB.R
+++ b/R/drmTMB.R
@@ -22,3 +22,3 @@
 #' on the logit-event-probability scale. Poisson, ordinary negative-binomial,
-#' and zero-truncated negative-binomial `mu` formulas may include standard R
-#' `offset(log(exposure))` terms for exposure or effort,
+#' `mu` formulas may include standard R `offset(log(exposure))` terms for
+#' exposure or effort,
```

Then re-run `devtools::document()` to regenerate `man/drmTMB.Rd:169-171`. No other
surface repeats the claim — `README.md`, `NEWS.md`, and the vignettes are all correct.

---

## Stage-B application order

1. Land the separation disposition receipt (task 2) and refresh a clean worktree at
   the merged `main`.
2. Apply items 1–3 as **one reviewed release-bytes commit**, with `devtools::document()`
   after item 3.
3. Bump `DESCRIPTION` to `0.7.0` **in that same release slice** (D-86).
4. Only then: `R CMD build`, freeze, hash, and run the exact-artifact checks.
5. Re-read the incoming NOTE set on the candidate's **own** logs. Any of items 1–2 that
   persists gets a `cran-comments.md` explanation, not a silent pass.

## What this document does not do

Does not apply any change · does not bump `DESCRIPTION` · does not claim any release
rung · does not re-use predecessor check results as candidate evidence · does not close
#870.

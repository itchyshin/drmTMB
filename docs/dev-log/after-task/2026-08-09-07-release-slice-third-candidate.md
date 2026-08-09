# After-task — drmTMB 0.7.0, third candidate frozen (release slice)

**Date:** 2026-08-09 · **Platform:** Claude Code · **Branch:** `claude/07-release-slice` ·
**Lane:** main 0.7.0 release slice (explicitly *not* the MSPL lane)

## 1. Goal

Finish the OWED steps in the 2026-08-09 release-slice handover: merge boundary surfacing, then
rebuild → re-check → re-freeze → re-dispatch, and return a decision packet. Produce **one exact,
honest candidate** and stop at the owner gate.

## 2. Implemented

1. **Merged boundary surfacing** into the slice (PR [#961](https://github.com/itchyshin/drmTMB/pull/961),
   base `claude/07-release-slice`, **not** `main`).
2. **Closed the third D-117 documentation surface** — `bootstrap_at_boundary` now appears in the
   `conf.status` enumerations in `first-week-intervals` and `model-workflow`, alongside the
   `NEWS.md` and `man/` surfaces the branch already covered.
3. **Resolved the 5MB documentation risk** by moving the five heaviest vignettes to
   `vignettes/articles/` (pkgdown-only). `inst/doc` 11.105 MB → **4.605 MB**; tarball 9,853,648 →
   **4,190,432** bytes.
4. **Repaired the collateral**: `_pkgdown.yml` article paths, 15 cross-links, and three
   capability-ledger guards.
5. **Froze candidate `d04d0e88`** with a full evidence packet and re-ran the fail-closed gate.

## 3a. Decisions and rejected alternatives

- **Moved vignettes rather than deleting them.** Dropping the four largest reaches only 5.07 MB —
  still over — so five are required either way; moving keeps all five on the website. Owner
  decision after being shown the measured table and the cost.
- **Rejected lowering figure resolution.** 88–98% of the worst files is embedded base64 images, so
  dpi cuts would have worked numerically, but the largest file is the *figure gallery*, whose whole
  purpose is figure quality.
- **Rejected re-dispatching R-hub** at the final head: the delta is `_pkgdown.yml`, which does not
  ship, so it would burn R-hub minutes for zero information.
- **Rejected dispatching pkgdown** to prove the site builds: its `workflow_dispatch` path deploys
  to Pages, which would publish the candidate's site over the live one. Verified locally instead.
- **Rejected rebuilding** to make source-commit equal branch-head; recorded the provenance delta
  instead, with the tarball listing as proof that no installed byte differs.

## 4. Files touched

**Package (ships):** `R/profile.R`, `R/check.R`, `NEWS.md`, `man/confint.drmTMB.Rd`,
`tests/testthat/test-boundary-surfacing.R` (via the merge) · `vignettes/first-week-intervals.Rmd`
and 9 further staying vignettes (link rewrites) · five vignettes + `function-map-cheatsheet.png`
moved to `vignettes/articles/`.

**Repo only (does not ship):** `.Rbuildignore`, `_pkgdown.yml`,
`tools/tests/test_capability_ledger.py`,
`docs/dev-log/release/0.7.0-cran-gate/FREEZE-NOTES-0.7.0.md`,
`docs/dev-log/release-audits/2026-08-09-07-cran-release-ledger.json`, this report.

## 5. Checks run

| Check | Result |
| --- | --- |
| `R CMD check --as-cran --run-donttest` on the exact frozen tarball | **Status: 1 NOTE** (`New submission`), 0 errors, 0 warnings |
| `misspelled\|invalid.*URI` in that log | **0** |
| `testthat` (in-check) | 10m/11m **OK** |
| targeted `boundary-surfacing` + `offset-families` | **45 pass, 0 fail** |
| `python3 -m unittest discover -s tools/tests` | **122 tests OK** |
| `cran_release_gate.py --selftest` | **14/14 negative controls fail closed** |
| `cran_release_gate.py <ledger>` | **READY FOR CLAIMED RUNG** (`tarball-clean`) |
| `pkgdown::check_pkgdown()` | **no problems** |
| `pkgdown::as_pkgdown()` | **37** vignettes discovered; all five resolve to `articles/…` |
| forbidden-path scan on the built tarball | **0 hits** |
| independent mechanical re-verify (fresh context) | **20 claims, 20 match, 0 mismatch** |

## 6. Tests of the tests

The guard repairs are the interesting case, because "make the test pass" is exactly the wrong
move here. Evidence each repair preserves intent rather than hiding a regression:

- The C17 fingerprint was **not** re-pinned; it was never invalidated. Proven by running the guard
  and reading `C17 current-source compatibility PASS`, and by the fact that the merge touched
  `R/profile.R` / `R/check.R`, not `R/drmTMB.R` / `src/drmTMB.cpp`.
- The nav-entry regex change was checked to still *fail* correctly: it captures the stem whether or
  not an `articles/` prefix is present, so `assertNotIn`/`count()` assertions retain their force.
- The recursive-glob change keeps the contract at 37 = 37 = 37 across the learning path, design doc
  226, and the article index. Counting only shipped vignettes would have passed too — by silently
  redefining a *reader-coverage* contract as a *packaging* contract. That is the failure this
  repair deliberately avoids.

## 7a. Issue ledger

No issues opened or closed. PR #961 opened and merged into the slice. PRs #957, #958, #959, #960
untouched.

## 8. Consistency audit (the neighbourhood sweep)

Applying the Rose principle to the vignette move, every same-class surface was swept, not just the
one that broke:

- **All** `vignettes/<moved>.Rmd` path references across `*.py`, `*.R`, `*.yaml`, `*.Rmd` — exactly
  one (the guard), fixed.
- **All** relative `.html` links in shipped vignettes: a full resolver found **0 dead links**
  across 32 shipped vignettes.
- `vignette("…")` calls in `R/`, `man/`, `README.md` — none.
- `README.md` already used the absolute pkgdown URL, which is why the rewrite matched it.
- The overstatement "no reader loses access" was found in **both** the freeze notes and the ledger
  note, and corrected in both.

## 9. What did not go smoothly

- **I ran the capability-ledger guard before the vignette move and not after.** CI caught three
  failures I should have caught locally. The lesson is not "run the guard" — I did — it is that a
  guard result is only evidence for the tree it ran against.
- The permission classifier denied both `gh pr merge` and `git merge`; the merge needed a grant.
- The Haiku size-inventory returned two identical trim options and labelled a 5.072 MB result as
  meeting a 5.0 MB target. The measurements were sound, the arithmetic conclusion was not — caught
  by re-checking before putting it to the owner.
- Three CI runs show `conclusion: cancelled`; all three were concurrency cancels from my own next
  push, verified rather than assumed.

## 10. Known residuals

- **`platform-clean` is NOT claimed.** Runs are dispatched, not adjudicated.
- **The candidate's source commit is `6d1fb0562`, not branch head.** The delta is `_pkgdown.yml`
  only, `.Rbuildignore`d and absent from the tarball. Recorded, not resolved by rebuilding.
- **Publication remains blocked independently of this candidate** by D-117 (PASS withheld), and
  D-89 records that submission is far away by choice.
- `DESCRIPTION:19` still understates skewness support. Flagged, not changed — product copy.
- The frozen artifact lives under a session scratchpad path, inheriting the fragility of the
  predecessor's location.

## 11. Team learning

**A guard result is scoped to the tree it ran on.** Re-run every guard *after* the last change to
the tree, not after the change you thought was risky. The handover warned that editing `R/`
invalidates the C17 fingerprint; the actual break came from moving *vignettes*, a class nobody had
flagged.

**Corollary, worth promoting:** when a plan's stated trap does not fire, that is not evidence the
tree is clean — it is evidence that *that* trap did not fire.

## 12. Cross-product coverage — the negative space

- **Not covered:** `platform-clean`, `submission-ready`, D-43, tag, release, upload — all
  owner-gated and untouched.
- **Not covered:** the MSPL lane, PR #960, PRs #957/#958/#959, and every foreign `codex/*` branch,
  stash, and the dirty primary checkout. All PROTECTED and unmodified.
- **Not covered:** whether the five relocated vignettes *render correctly* on the live site. Their
  discovery and output paths are proved; their rendered output is not, because proving it would
  have required deploying to Pages.
- **Not covered:** Windows/macOS vignette timing — no win-builder submission was made.
- **Not tested:** that the absolute pkgdown URLs survive CRAN's URL check on a future
  `--as-cran` run against a live network; the local run reported 0 URI findings.

# After-Task Report: Reader Phrase Sweep

**Date:** 2026-09-21
**Repository:** drmTMB
**Branch:** `claude/reader-phrase-sweep-20260921`
**Base:** origin/main @ 54df129fe

## Goal

Remove three internal-sounding phrases from public reader pages, and check
whether the reader-contract test that already bans them on one page should
guard all public pages instead. The phrases:

- "Pedigree/Ainv bridge marshalling" -- worded as if pedigree input were
  unsupported; the real limit is that interval evidence checked with an `A`
  matrix does not carry over to pedigree or `Ainv` input.
- "recovery-grade NB2" -- an internal evidence-tier label; the site's own
  plain tier vocabulary lives in `vignettes/capability-and-limits.Rmd`.
- "fixed-kappa mesh intercept" -- an internal implementation detail; the
  reader-facing fact is that the mesh route uses a spatial range the user
  sets rather than one the model estimates.

This is a separate, self-contained repair. `vignettes/structural-dependence.Rmd`
(fixed on `codex/structural-reader-decisions-20260921`, PR #1418) and
`vignettes/convergence.Rmd` (PR #1417) are excluded and were not touched.

## Mathematical Contract

No public API, likelihood, formula-grammar, or family change. This task edits
prose only; every executable R chunk and display equation on every touched
page is unchanged.

## Files Created or Changed

**Six reader vignettes, the phrases named in the task:**

1. `vignettes/animal-models.Rmd` (line 162): "Pedigree/Ainv bridge marshalling"
   -> "Pedigree and `Ainv` inputs are fitted, but interval results checked
   with an `A` matrix do not yet carry over to pedigree or `Ainv` input for
   this one-slope `sigma` route."
2. `vignettes/model-map.Rmd` (lines 222, 262): the same bridge sentence, and
   "recovery-grade NB2" / "fixed-kappa mesh intercept" -> "point estimate
   only" / "fixed spatial range".
3. `vignettes/which-scale.Rmd` (line 870): "recovery-grade NB2" -> "point
   estimate only".
4. `vignettes/articles/phylogenetic-spatial.Rmd` (lines 286, 630, 1237): same
   three substitutions.
5. `vignettes/formula-grammar.Rmd`: the bridge sentence and "fixed-kappa" in
   context.

**Repair round (same day, after the Fable/Sonnet review): the same phrase
class, found on five more pages the task did not list.**

6. `vignettes/spatial-models.Rmd`: six "fixed-kappa" mentions (opening
   paragraph, status-table row, the section heading "Geographic coordinates
   and the fixed-kappa mesh route", the q2 calibrated-example paragraph, the
   Confidence Eye `fig.cap`, and the closing boundary sentence) -> "fixed
   spatial range" / "fixed-range mesh route", matching the wording already
   used on the model map and the phylogenetic-spatial article. One "recovery
   grade" (the spatial `sigma` route, line 352) -> "point estimate only". The
   heading rename changes the pkgdown anchor; grep confirms no page links to
   the old anchor.
7. `vignettes/formula-grammar.Rmd`: nine further "recovery grade" /
   "recovery/source-test grade" / "diagnostic grade" phrases (lines 66, 73,
   88, 130, 134, 225, 227, 270, 271, 273) -> "point estimate only" or
   "diagnostic only (fit/extractor feasibility, not point-estimate
   recovery)", the vocabulary the same page already uses for the
   cumulative-logit row.
8. `vignettes/adding-families.Rmd` line 208: "recovery-grade" /
   "diagnostic-grade" -> "point estimate only" / "diagnostic only".
9. `vignettes/articles/figure-gallery.Rmd` line 2562: the rendered label
   "(recovery-grade)" -> "(point estimate only)".
10. `vignettes/proportion-beta-binomial.Rmd` lines 168 and 583, and
    `vignettes/robust-student.Rmd` line 275: the same class ("at recovery
    grade", "recovery/diagnostic grade"), found by a whole-class grep and
    swept in the same round.

**Test suite:**

- `tools/tests/test_capability_ledger.py`: added
  `test_public_vignettes_are_free_of_internal_route_jargon()`, which reads
  every `vignettes/*.Rmd` and `vignettes/articles/*.Rmd` (whitespace-
  normalised, case-folded) and fails on the three named phrases or any
  spelling in the same class: "bridge marshalling", "bridge marshaling",
  "bridge claims", "recovery-grade", "recovery grade", "diagnostic-grade",
  "diagnostic grade", "fixed-kappa", "local-fit level". Also updated the two
  existing `assertIn` literals for `model-map.Rmd` (lines 1829 and 2160, was
  1813/2144 before the new test was inserted) to expect "(point estimate
  only)" instead of "recovery-grade NB2", so the required-presence check
  still finds a string that is actually on the page.
- `docs/dev-log/check-log.d/2026-09-21-reader-phrase-sweep.md` (new,
  per-lane entry; see Team Learning below for why this file and not the
  shared log).
- This report.

## Checks Run and Exact Outcomes

```
$ python3 -m unittest tools/tests/test_capability_ledger.py 2>&1 | tail -8
.................................................................................
----------------------------------------------------------------------
Ran 81 tests in 1.999s

OK
C14 receipt equivalence: OK (3 eligible, 7 source-different retained receipts; C17 current-source compatibility PASS)
capability-ledger: OK (1 generated outputs)
```

```
$ Rscript tools/check-reader-contracts.R 2>&1 | tail -2
Reader vignette contract: OK
```

```
$ git diff --check
(clean, exit 0)
```

```
$ grep -rln -i -E 'bridge marshal|recovery[- ]grade|fixed[- ]kappa|diagnostic[- ]grade|local-fit level|bridge claims' vignettes/*.Rmd vignettes/articles/*.Rmd
vignettes/structural-dependence.Rmd
```
Only the excluded file remains, and its fixed version on
`codex/structural-reader-decisions-20260921` is already clean of every phrase
in the widened list (checked with `git show`).

```
$ git diff -U0 -- vignettes tools/tests | grep -E '^\+' | grep -c '—'
0
```

```
$ git diff --stat
 tools/tests/test_capability_ledger.py       | 42 +++++++++++++++++++++++++++--
 vignettes/adding-families.Rmd               |  4 +--
 vignettes/animal-models.Rmd                 |  2 +-
 vignettes/articles/figure-gallery.Rmd       |  2 +-
 vignettes/articles/phylogenetic-spatial.Rmd | 30 +++++++++++----------
 vignettes/formula-grammar.Rmd               | 36 ++++++++++++-------------
 vignettes/model-map.Rmd                     | 41 +++++++++++++++-------------
 vignettes/proportion-beta-binomial.Rmd      |  8 +++---
 vignettes/robust-student.Rmd                |  6 ++---
 vignettes/spatial-models.Rmd                | 26 +++++++++---------
 vignettes/which-scale.Rmd                   |  2 +-
 11 files changed, 122 insertions(+), 77 deletions(-)
```
Only reader pages and the one test file changed; no unintended edits.

Four page renders (prose-only, no `timeout`/`gtimeout` binary on this Mac, so
`perl -e 'alarm 900; exec ...'` stood in for a 900s cap; none of the four came
close to it):

| Page | Result | Seconds |
| --- | --- | --- |
| `vignettes/model-map.Rmd` | rendered, exit 0; HTML free of all three phrases; "point estimate only" appears 5x | 1.97 |
| `vignettes/which-scale.Rmd` | rendered, exit 0; HTML free of the phrases; "point estimate only" appears 1x | 3.86 |
| `vignettes/animal-models.Rmd` | rendered, exit 0; HTML free of the phrases | 3.88 |
| `vignettes/formula-grammar.Rmd` | rendered, exit 0; HTML free of the phrases; "point estimate only" appears 1x | 1.96 |

`vignettes/articles/phylogenetic-spatial.Rmd` (site-only, heavy) was NOT
rendered, by instruction; verified at the source level only (all 11 edits
applied; grep finds no "bridge marshal", "recovery-grade", "fixed-kappa", or
"local-fit" left in the file). `devtools::test()`, `load_all()`, and
`R CMD check` were not run, per the task's remit.

## Consistency Audit

All six locations named in the task are fixed and confirmed by the whole-
class grep above:

1. `vignettes/animal-models.Rmd:162`
2. `vignettes/model-map.Rmd:222`
3. `vignettes/model-map.Rmd:262` (recovery-grade NB2)
4. `vignettes/which-scale.Rmd:870`
5. `vignettes/articles/phylogenetic-spatial.Rmd:286`
6. `vignettes/articles/phylogenetic-spatial.Rmd:630`

Repair round, same phrase class, all confirmed fixed by the same grep:
`spatial-models.Rmd` (7 spots), `formula-grammar.Rmd` (9),
`adding-families.Rmd` (1), `figure-gallery.Rmd` (1),
`proportion-beta-binomial.Rmd` (2), `robust-student.Rmd` (1).

Cross-references checked:

- `vignettes/capability-and-limits.Rmd`: plain tier vocabulary intact, used
  as the source for every replacement.
- `vignettes/structural-dependence.Rmd`: excluded, fixed separately (#1418).
- `vignettes/convergence.Rmd`: excluded, fixed separately (#1417).
- `NEWS.md`, `R/`, `inst/`, `src/`: untouched, per the task's exclusion list.
  `NEWS.md` still carries the historical phrases in its own dated entries;
  those are a changelog record of past releases, not a live reader claim,
  and rewriting history there was out of scope.

## Tests of the Tests

The original contract test (`test_reader_navigation_redirect_and_public_
language_contract`) checked only `structural-dependence.Rmd` for the three
exact phrases. The task asked whether that list should widen to all public
reader vignettes; the answer is yes, with one sequencing condition.

The new `test_public_vignettes_are_free_of_internal_route_jargon()` was shown
to fail before it was trusted: a probe file containing "recovery\ngrade"
across a line break (mimicking a hard-wrapped Rmd paragraph) tripped it with
`'recovery grade' found in vignettes/zz-probe.Rmd`; the probe was then
deleted.

The test was also shown to fail on the unmodified base. A scratch copy of
this branch with `vignettes/structural-dependence.Rmd` replaced by the
`origin/main` version (i.e. undoing the #1418 fix) reproduces the exact
failure this branch depends on #1418 for:
`AssertionError: True is not false : 'pedigree/ainv bridge marshalling' found
in vignettes/structural-dependence.Rmd`. Swapping in the
`codex/structural-reader-decisions-20260921` version of that one file instead
returns the suite to 81/81 OK. So the test is not vacuously green: it
distinguishes the fixed and unfixed page, and it is red on this branch only
because of the one file this lane may not touch.

The two existing `assertIn` literals for `model-map.Rmd` were updated in
lock-step with the page text they check (see Files Changed); without that
update, `test_reader_surfaces_do_not_erase_structured_sigma_slope_support`
fails to find its required string on the rewritten page. Left unweakened:
the literal still requires an exact evidence-tier fact (NB2 q=1 structured
`sigma` is point-estimate only), just phrased in the page's own words rather
than restated as "recovery-grade".

## What Did Not Go Smoothly

**The first pass was incomplete; a follow-up review caught it.** The first
sweep replaced the three exact phrases at the six named locations and left
six "fixed-kappa" mentions in the spatial guide (including a section
heading) and nine "recovery grade" / "diagnostic grade" mentions in
`formula-grammar.Rmd`, plus four more in three files nobody had listed. A
narrow three-phrase test was green while a reader would still meet the
internal vocabulary on the very next page. The fix was to grep for the whole
phrase class across every public vignette rather than trust the reported
line list, and to make the widened test check the class, not the three
literal strings.

**Merge-order dependency with PR #1418
(`codex/structural-reader-decisions-20260921`).** This branch's widened test
excludes `structural-dependence.Rmd` with a dated comment, because that file
is still unfixed on `origin/main` and is owned by #1418. Whoever lands
second should delete that one-line exclusion; the #1418 version of the page
already passes the widened list (checked with `git show`, see Tests of the
Tests). Separately, the `codex/structural-reader-decisions-20260921` copy of
`tools/tests/test_capability_ledger.py` still asserts the OLD `model-map.Rmd`
strings ("separate recovery-grade NB2 q=1 structured `sigma` routes" and
"recovery-grade NB2 q1 spatial `sigma`"). This branch changed `model-map.Rmd`
and both assertions to the "(point estimate only)" wording that matches the
page. Merging both without reconciling those two `assertIn` strings will
turn CI red on whichever branch lands second; this branch's versions are the
ones that match the live page text.

**A pre-existing inconsistency, noticed and left alone.**
`formula-grammar.Rmd` line 74 says the Gamma ordinary `sigma` random
intercept has an ML-Laplace profile interval that is "inference-ready with
caveats" at true SD 0.40, `n_each = 12`, `M >= 32`; line 271 on the same page
called that same route "recovery grade", now translated faithfully to "point
estimate only". The two sentences disagreed with each other before this
lane and still do after it; which tier is correct should be settled from the
capability ledger by whoever owns the Gamma family page, not guessed here.
Not fixed, because it is a factual disagreement about evidence tier, not a
jargon-wording problem this lane is scoped to repair.

## Team Learning by Roles

- **Rose** (this role) drafted the six named fixes, reused the reference
  sentence and tier vocabulary the task specified, and wrote this report.
- Three same-model reviewers, run as independent lenses over the diff,
  refuted a narrower reading of the task in round one (four of the proposed
  edits were contested and re-checked against the actual repo before being
  applied or dropped) and then, in a second pass, found the sweep's own
  incompleteness: "fixed-kappa" surviving on `spatial-models.Rmd` including a
  section heading, and unhyphenated "recovery grade" surviving on
  `formula-grammar.Rmd` and two other files the task never named.
- A Fable-style diff read caught that the widened test's failure on this
  branch was expected and traced it to the correct root cause
  (`structural-dependence.Rmd` is out of scope and unfixed on `main`), rather
  than treating the one red test as a defect to paper over.
- A final gate re-run confirmed all of the above by direct command
  execution rather than by re-reading the earlier claims (see Checks Run).

**Durable lesson:** a phrase-ban test that lists exact strings and a task
description that lists exact line numbers both invite the same failure mode
-- fixing precisely what was named and nothing else. A grep for the phrase
*class*, run before closing, is what actually finds the neighbouring
instances a reader would still meet.

## Design-Doc and Pkgdown Updates

None. This is a pure reader-page wording repair; no capability, grammar, or
navigation change. No `_pkgdown.yml` edit is needed because no page was
added, removed, or renamed at the pkgdown-article level (the one internal
anchor rename inside `spatial-models.Rmd` was checked for inbound links, see
Files Changed).

## Roadmap Tick

None. This task does not correspond to a roadmap milestone; it is a
documentation-honesty repair flagged by a review, not a capability
deliverable.

## GitHub Issue Ledger

Searched open issues for reader-documentation jargon leakage; none matched
this bounded wording repair. No issue was opened, closed, or commented on.
The PR itself records the scope and the merge-order dependency on #1418.

## Known Limitations and Next Actions

**Limitation:** `vignettes/structural-dependence.Rmd` still contains the
banned phrases on this branch, because this branch is based on
`origin/main` and that file's fix lives only on
`codex/structural-reader-decisions-20260921` (#1418). The widened test
excludes that one file, with a dated comment, until #1418 lands.

**Next actions:**

1. Land #1418 and this branch in either order; whichever lands second should
   delete the `structural-dependence.Rmd` exclusion in
   `test_public_vignettes_are_free_of_internal_route_jargon` and keep this
   branch's two "(point estimate only)" `assertIn` strings for
   `model-map.Rmd` rather than #1418's older "recovery-grade" strings.
2. Resolve the Gamma `sigma` random-intercept tier disagreement on
   `formula-grammar.Rmd` (lines 74 vs 271) from the capability ledger.
3. `vignettes/articles/phylogenetic-spatial.Rmd` was not re-rendered (site
   build only, out of this lane's remit); the source-level checks above are
   the only verification for that page's HTML output.
4. Contributor-facing pages (e.g. `implementation-map.Rmd`, `source-map.Rmd`)
   fall inside the widened glob and currently pass; if a future contributor
   note needs the internal tier words, it belongs in `docs/design/`, not in
   `vignettes/`.

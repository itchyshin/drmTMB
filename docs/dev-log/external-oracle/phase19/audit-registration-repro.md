# Phase 19 audit — registration checklist (plan §9) and reproducibility block (plan §12), as built

Auditor: Grace (reproducibility engineer). Adversarial; default verdict NOT-DONE unless every
claim below is independently verified against the live worktree.

Worktree: `.worktrees/phase19`, branch `claude/phase19-comparator-workflows`, rebased onto
`origin/main@7d756efc6`. HEAD at audit time: `8659319cc` ("chore: drop stray figure/ debris
from the package root").

Scope: the two surfaces the prior claims audits (`build-verify-claims.md`,
`build-verify-numeric.md`, `gate5-claims.md`) did **not** reach. `gate5-claims.md`'s own
check-log entry says so explicitly: *"§9 (registration, this entry's own subject), §12
(reproducibility), and the c04–c09 build specifications remain unaudited from the audit
side"* (`docs/dev-log/check-log.md`, 2026-08-15 entry "Phase 19: `comparing-with-other-
packages.Rmd`, its comparator tests, and their registration"). This report closes that gap.

All citations are by content (grep-verified against the live file at the time this report was
written), never by line number alone, per the task's standing rule.

---

## Verdict

**NOT-DONE.** Registration (plan §9) is correct on all five coupled edits, including the fifth
edit the plan's own §9 text never names. Reproducibility (plan §12) is **not built**: no
reproducibility harness was committed (plan §14 build-order step 2 explicitly mandates one),
no reproducibility metadata — package versions, platform, seed statement, threading — appears
anywhere a reader or a re-runner can find it, and the article's stated numeric precision
(e.g. "agreement to `1e-3`", "`1.63e-11`") is implicitly tied to specific comparator package
versions that are recorded only in this plan document, not in DESCRIPTION, not in the article,
and not in any committed script. One separate, unrelated finding: a genuine internal
inconsistency in `docs/design/226-reader-learning-path.md`, present before and unrelated to
this arc's edit, missed by both the arc's own hand-edit and the automated ledger test.

No blocking defect touches the receipt-pinned files or reintroduces build debris — both are
clean.

---

## Part A — Registration checklist (plan §9), as built

### A0. The plan documents four edits; there are five in the live contract

Plan §9.1 ("The four coupled edits") lists only: the vignette itself, `_pkgdown.yml`, the
manifest CSV row, and the hard-coded count in
`tests/testthat/test-reader-vignette-contracts.R`. It never mentions
`docs/design/226-reader-learning-path.md` anywhere in the document —

```
$ grep -n "226-reader-learning-path\|reader-learning-path" \
    docs/dev-log/external-oracle/phase19/PR2-build-plan.md
(no output)
```

— even though `docs/design/226-reader-learning-path.md`'s own §3 table is enforced against the
live vignette set by `tools/tests/test_capability_ledger.py`
(`test_reader_navigation_redirect_and_public_language_contract`, verified running below). This
is a plan omission, not a build omission: the builder did, in fact, make this fifth edit
correctly (§A5 below), so the checklist under-documents what the contract actually requires
rather than the build under-delivering it. Flagging it here because a future session reading
only plan §9 would not know a fifth coupled file exists.

### A1. `vignettes/comparing-with-other-packages.Rmd` — vignette tag

```
$ grep -n "VignetteIndexEntry\|VignetteEngine\|VignetteEncoding" \
    vignettes/comparing-with-other-packages.Rmd
6:  %\VignetteIndexEntry{Comparing drmTMB with other packages}
7:  %\VignetteEngine{knitr::rmarkdown}
8:  %\VignetteEncoding{UTF-8}
```

Correct, present. **VERIFIED.**

### A2. `_pkgdown.yml` — articles entry and the vignettes==articles invariant

```
$ awk '/^articles:/{f=1} f' _pkgdown.yml | grep -A2 "Comparison with Established"
  - title: Comparison with Established Packages
    contents:
      - comparing-with-other-packages
```

Placed exactly where plan §9.1 item 2 specifies: after "Applied Family Tutorials", before
"Model Checking and Practical Workflow".

Invariant check, recomputed independently rather than trusted from prose:

```
$ ls vignettes/*.Rmd | xargs -n1 basename | sed 's/\.Rmd$//' | sort > /tmp/vig.txt
$ wc -l < /tmp/vig.txt
38
$ awk '/^articles:/{f=1} f' _pkgdown.yml | grep -oP '^\s{6}- \K[a-zA-Z0-9_-]+' | sort > /tmp/art.txt
$ wc -l < /tmp/art.txt
38
$ diff /tmp/vig.txt /tmp/art.txt
(no output — identical sets)
```

38 vignettes, 38 article entries, identical membership. **VERIFIED.**

### A3. `inst/reader-contracts/vignette-manifest.csv` — row, audience, trailing fields

```
$ grep -n "comparing-with-other-packages" inst/reader-contracts/vignette-manifest.csv
8:comparing-with-other-packages.Rmd,reader,,
$ head -1 inst/reader-contracts/vignette-manifest.csv
vignette,audience,permitted_private_fields,rationale
$ wc -l < inst/reader-contracts/vignette-manifest.csv
39
```

`audience=reader`, `permitted_private_fields` empty, `rationale` empty — matches the
`structural-dependence.Rmd,reader,,` pattern the plan cites. 39 lines = 1 header + 38 rows,
consistent with the 38-vignette count. Row is placed alphabetically between
`capability-and-limits.Rmd` and `convergence.Rmd`, matching the file's existing sort order
(confirmed by reading the surrounding rows). **VERIFIED.**

### A4. `tests/testthat/test-reader-vignette-contracts.R` — hard-coded count

```
$ grep -n "nrow(manifest)" tests/testthat/test-reader-vignette-contracts.R
224:  expect_equal(nrow(manifest), 38L)
```

Bumped from `37L` to `38L` as required. Ran it live rather than trusting the source read:

```
$ R_PROFILE_USER=/dev/null Rscript --no-init-file -e \
    'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-reader-vignette-contracts.R")'
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 21 ]
```

**VERIFIED.**

### A5. `docs/design/226-reader-learning-path.md` — the fifth, undocumented-in-§9 edit

The task's brief said this edit is enforced against the live vignette count by
`tools/tests/test_capability_ledger.py` and needs a header count, an "N rows." statement, and
a table row set exactly equal to the vignette stems. All three checked independently:

```
$ grep -n "38 vignettes\|38 rows\|Total: 38" docs/design/226-reader-learning-path.md
1:# 226 — One canonical reader learning path across 38 vignettes
88:38 rows. Role legend: **tutorial** = worked biological example with fitted
136:Total: 38 placed. Stage counts **after the §9 corrections**: **1. First fit**
```

Table row 34 is present and correctly authored:

```
| 34 | `comparing-with-other-packages` | 5. Uncertainty & inference boundaries | guide |
Fits eight models drmTMB shares with `lme4`, `glmmTMB`, `metafor` and `ordinal`, and shows the
estimates agreeing on matched scales. Read when the question is "should I trust this package",
after the reader can already fit and interpret a model. States which comparisons are
independent engines and which share drmTMB's TMB stack. |
```

Table-stems-equal-vignette-set, recomputed independently:

```
$ awk '/^## 3\. The full placement table/,/^## 4\./' docs/design/226-reader-learning-path.md \
    | grep -E '^\| [0-9]+' | wc -l
38
$ awk '/^## 3\. The full placement table/,/^## 4\./' docs/design/226-reader-learning-path.md \
    | grep -E '^\| [0-9]+' \
    | sed -E 's/^\| [0-9a-z]+ \| `([a-zA-Z0-9_-]+)`.*/\1/' | sort > /tmp/doc226.txt
$ diff /tmp/doc226.txt /tmp/vig.txt
(no output — identical sets)
```

The mechanical enforcement was also run live, not assumed:

```
$ python3 -m unittest \
    tools.tests.test_capability_ledger.CapabilityLedgerTests.test_reader_navigation_redirect_and_public_language_contract \
    -v
test_reader_navigation_redirect_and_public_language_contract ... ok
Ran 1 test in 0.062s
OK
```

`git diff 7d756efc6..HEAD -- docs/design/226-reader-learning-path.md` confirms this session's
edit touched exactly the title (37→38), the §3 header ("37 rows."→"38 rows."), added table row
34, updated the "5. Uncertainty & inference boundaries" stage count (4→5), and corrected the
arithmetic line (`4+4+9+3+7+4+1+5=37` → `4+4+9+3+7+5+1+5=38`). All of that is internally
consistent and independently re-derivable from the table (recomputed the eight stage-group
tallies row-by-row from the live table: First fit 4, Reporting-boundary row 1, Choose your
family 4, Interpretation tutorials 9, Random & structured effects 7, Uncertainty & inference
boundaries 5, Developer track 5, Specialist branch 3 — sums to 38 and matches the doc's own
stated breakdown). **VERIFIED** as edited — but see the separate finding in Part C below: one
sentence in the same document, outside the diff this arc made, was left stale and now
disagrees with everything else in the file.

### A summary — registration

All five coupled edits are correct in the live worktree. The plan text itself is incomplete
(documents four, needs five); the build is not. This is worth fixing in the plan for the next
vignette addition, since a future session following plan §9.1 literally would ship a vignette
that fails `test_reader_navigation_redirect_and_public_language_contract` (doc 226 out of sync)
while believing the four-edit checklist was exhaustive.

---

## Part B — Reproducibility block (plan §12), as built

### B1. What plan §12 specifies

Plan §12 records an environment block (R version, platform, BLAS, core count, `drmTMB`
0.7.0-from-source, and pinned versions for `TMB`, `Matrix`, `glmmTMB`, `lme4`, `metafor`,
`metadat`, `ordinal`, `MASS`, `palmerpenguins`; `gamlss` absent, `betareg` installed-but-unused),
an explicit seed statement ("no stochastic component… no simulation, no resampling, no
bootstrap"), a threading pin (`OPENBLAS_NUM_THREADS=1`), and an explicit "no timing claim, and
why" statement. Plan §14 build-order step 2 is unambiguous about where this is supposed to
land: *"Write the reproducibility harness first, and commit it to the worktree at a path this
plan can cite. One script that fits the 8 article drmTMB models and their 8 comparators, runs
the 2 classification checks… and emits §12's environment block."*

### B2. No such script was committed

```
$ find . -iname "*reproduc*" -not -path "./.git/*" \
    -not -path "*/docs/dev-log/external-oracle/*"
./.claude/agents/reproducibility-engineer.md
./.codex/agents/reproducibility-engineer.toml
```

Neither is a Phase 19 artifact — both are the pre-existing agent role files. The full diff of
every file this arc touched or added, relative to the pre-arc merge base, contains no script of
any kind beyond the vignette and the test file:

```
$ git diff 7d756efc6..8659319cc --stat
DESCRIPTION                                                       |    1 +
_pkgdown.yml                                                      |    3 +
docs/design/226-reader-learning-path.md                           |   11 +-
docs/dev-log/after-task/2026-08-15-phase19-comparator-workflows.md|  293 +
docs/dev-log/check-log.md                                         |  244 +
docs/dev-log/external-oracle/phase19/*.md                         | (23 files)
inst/reader-contracts/vignette-manifest.csv                       |    1 +
tests/testthat/test-comparators-phase19.R                         |  596 +
tests/testthat/test-reader-vignette-contracts.R                   |    2 +-
vignettes/comparing-with-other-packages.Rmd                       |  612 +
31 files changed, 11154 insertions(+), 6 deletions(-)
```

No `tools/*.R`, no `docs/dev-log/*repro*` script, nothing under a "reproducibility harness"
name anywhere. **Plan §14 step 2 is not built.**

### B3. No reproducibility metadata appears anywhere a reader can find it

The article itself was read in full. Its only sentence resembling the plan's reproducibility
language is the evidence-class boilerplate, which is a statement about statistical evidence
class, not about re-run environment:

```
$ grep -n -i "reproducib\|sessionInfo\|R version\|seed\|platform\|BLAS\|package version" \
    vignettes/comparing-with-other-packages.Rmd
36:Every comparison here is single-seed and single-dataset. Each one shows that
```

That is the *evidence-class* claim ("single-seed" = one dataset, one deterministic fit — no
stochastic replication), not the *reproducibility* record §12 was written to produce. There is
no session-info block, no package-version table, no platform statement, no
`OPENBLAS_NUM_THREADS` note, and no explicit statement that these are exact real datasets with
no RNG involved (the closest the article gets is the sentence above, which a reader has to
infer the no-RNG claim from rather than being told directly, and even that inference conflates
"single-seed" language with "no seed needed" without saying so).

The test file's header comment block was checked too — no reproducibility content there
either; it documents the package-attachment discipline and the `metadat` declaration only, not
versions, platform, or seeds.

**Conclusion: plan §12's content exists nowhere in the built artifacts.** It exists only in the
plan document itself, which is explicitly *not* the reader's or the re-runner's surface (plan
line 40: "Reader: the session that builds PR 2. This is the plan only"). A reader of the
vignette, or a future session trying to re-run the eight comparisons and reproduce the stated
tolerances, has nothing in the repository to consult.

### B4. Comparator versions the article depends on but does not state

The article's precision claims are version-sensitive, and no version is pinned or recorded
anywhere in the shipped artifacts:

```
$ grep -n "^Suggests:" -A 30 DESCRIPTION
Suggests:
    ape, callr, detectseparation (>= 0.4.0), emmeans, extraDistr, fmesher,
    glmmTMB, ggplot2, JuliaCall, knitr, lme4, MASS, metadat, metafor,
    mvtnorm, nlme, numDeriv, ordinal, palmerpenguins, pkgload, rmarkdown,
    sf, spelling, statmod, testthat (>= 3.0.0), tweedie, withr
```

`glmmTMB`, `lme4`, `metafor`, `metadat`, and `ordinal` — every comparator this article calls —
are declared with **no version floor**. Plan §12 recorded the exact versions the tolerances in
the article were measured against (`glmmTMB 1.1.14`, `lme4 2.0.1`, `metafor 5.0.1`, `ordinal
2025.12.29`), but:

- Comparison 1's tolerance is explicitly the loosest in the set (`~1e-3`, attributed to a
  stable PIRLS-vs-AD-Laplace difference, not under-convergence) — a `lme4` optimizer-default
  change between versions is exactly the kind of thing that could move this number, and
  nothing pins `lme4`'s version.
- Comparisons 2/3 depend on `metafor::rma.uni(method = "ML")` reproducing a specific
  log-likelihood to `1e-12`/`3.4e-8`; `metafor` has no floor either.
- Comparisons 4/5 depend on `ordinal::clm`/`clmm` matching to `1e-5`–`1e-10`; `ordinal` (dated
  `2025.12.29` in the plan's own recording, an unusual date-as-version scheme) has no floor.

None of this is stated in the vignette, in `DESCRIPTION`, or in a script. A reader who installs
a materially different version of any of these four packages and reproduces a looser or
tighter number than the article states has no way to know from the shipped artifacts whether
that is expected drift or a real regression, because the article never says what was assumed.

### B5. What the article does get right, reproducibility-adjacent

Not a gap: every comparator block in the article is gated on
`requireNamespace("<pkg>", quietly = TRUE)` (verified: `has_lme4`, `has_metafor`, `has_metadat`,
`has_ordinal`, `has_glmmTMB`, `has_penguins` all set at the top of the file and used to gate
`eval=` on the relevant chunks), so a build without an optional comparator degrades rather than
errors. That is a real reproducibility property, just not the one plan §12 promised (versions,
platform, seeds).

### Verdict — Part B

**NOT-DONE.** Plan §12's content and plan §14 step 2's mandated harness script are both absent
from the built artifacts. This is not a wording nit: a reader or auditor cannot currently
determine, from anything in this repository, which package versions the article's stated
numeric tolerances were measured against, or get a one-command way to regenerate those numbers.
The check-log's own honest-audit note already flagged this section as unaudited; this report
confirms the gap is real, not just unexamined.

---

## Part C — doc 226 internal consistency (found while verifying A5)

The task asked me to recompute the stage-count paragraph and arithmetic line in doc 226's §3
footer from the table and check agreement. Done in §A5 above: **that footer is internally
consistent** (4+4+9+3+7+5+1+5=38, matches the recomputed per-stage tallies, matches the table's
38 rows).

A different, separate inconsistency exists in the same document, in §1 rather than §3, and
this arc's own diff shows it was never touched:

```
$ grep -n "37 vignettes\|38 vignettes" docs/design/226-reader-learning-path.md
1:# 226 — One canonical reader learning path across 38 vignettes
38:The synchronized placement table below now contains 37 vignettes after the
```

Line 1 (title) and line 88/136 (§3 header and footer, both edited by this arc — see the
`git diff` in §A5) all say **38**. Line 38, in §1's opening problem statement, still says
**37**. Confirmed this line was not part of this arc's edit:

```
$ git diff 7d756efc6..HEAD -- docs/design/226-reader-learning-path.md
[... shows edits to line 1, the §3 header, the added table row 34, the stage-count line, and
the arithmetic line — line 38 does not appear in the diff at all]
```

So this is a **pre-existing** staleness, not something Phase 19 introduced, but Phase 19's
hand-edit had the opportunity to catch it (it edited the same document, three other places,
for the same reason — the vignette count changing) and did not. The automated enforcement
(`test_reader_navigation_redirect_and_public_language_contract`) does not catch it either: it
checks `f"across {vignette_count} vignettes"` only against `design.splitlines()[0]` (the
title) and `f"{vignette_count} rows."` only as a substring anywhere in the file — line 38's
"contains 37 vignettes" sentence matches neither pattern, so the test is blind to it. Confirmed
by running the test live (Part A5) — it passes with line 38 still wrong.

This is a real, hand-verified defect: one sentence in a document that otherwise says "38"
consistently three other times still says "37". It is not blocking (the mechanical contract
this PR's registration depends on does not read that sentence), but it is exactly the kind of
stale hand-edited count this task asked me to hunt for, and it was sitting in a document this
arc edited without being fixed.

---

## Part D — Debris and receipt-pinned files

### D1. No committed build debris

```
$ git ls-files | grep -i "^figure/"
(no output, exit 1)
$ ls figure 2>&1
ls: figure: No such file or directory
```

A `figure/` directory of two stray PNGs *was* committed mid-arc (visible in
`8659319cc`'s parent) and was removed in the immediately following commit `8659319cc` ("chore:
drop stray figure/ debris from the package root"), confirmed by `git show 8659319cc --stat`
showing both PNGs deleted. At HEAD, no debris is tracked. **VERIFIED clean.**

### D2. Receipt-pinned files unchanged

```
$ git diff 7d756efc6..HEAD --stat -- R/methods.R R/drmTMB.R src/drmTMB.cpp \
    tests/testthat/test-zero-one-beta.R \
    tools/run-lane-c-c17c1-c14-model15-compatibility.R
(no output)
```

None of the five receipt-pinned files changed anywhere in this arc's commits. **VERIFIED
clean.**

---

## What I did not check

- I did not re-run `pkgdown::build_site()` or `devtools::check(args = "--as-cran")` myself;
  the check-log's 2026-08-15 entries record a completed `--as-cran` run (0 errors, 0 warnings,
  2 notes, the second note being the now-removed figure debris) and a `render()`-vs-`knit()`
  distinction that caught a search-path leak. I read that record rather than reproducing the
  full run, which is outside this task's registration/reproducibility scope and would be a
  >30-minute campaign of its own (D-139).
- I did not audit the numeric correctness of the eight comparisons or the c04–c09 build
  specifications — that is explicitly out of scope for this task (the claims auditor's lane)
  and is separately flagged as unaudited in the check-log.
- I did not verify every one of doc 226's 38 individual placement-reason cells for accuracy,
  only the mechanical invariants (row count, stem set, stage arithmetic) the task asked for.

---

## Recommendation

1. Add `docs/design/226-reader-learning-path.md` as a fifth item to plan §9.1's coupled-edit
   list (or, better, note in the plan that the checklist is stale and point to
   `test_reader_navigation_redirect_and_public_language_contract` as the actual authority) so
   the next vignette addition does not silently break that test.
2. Fix `docs/design/226-reader-learning-path.md` line 38 ("now contains 37 vignettes") to say
   38, for internal consistency. Small, mechanical, not gated on anything else in this arc.
3. Before this PR is represented as reproducibility-complete: either commit the harness script
   plan §14 step 2 mandates and cite it from the article, or explicitly amend the plan/PR body
   to say the harness was deliberately not built and why, and add a minimal statement to the
   vignette itself recording at least the comparator package versions the stated tolerances
   were measured against — the four unpinned comparator packages are exactly the ones the
   article's headline numeric agreements depend on.

# After Task: Phase 19 — `comparing-with-other-packages.Rmd`, its comparator tests, and their registration

**A note on this report's own history, because it matters for reading it.** The
first version covered only the four registration edits, and said the article
did not exist, that `tools/check-reader-contracts.R` failed, and that an
`expect_setequal()` would fail. All three were true when written and are false
now: the article and its tests landed in this same branch shortly afterwards.
Issue #60's Definition of Done names the article and the check log explicitly,
so a report that disclaimed the deliverable did not discharge it. This version
describes the branch as it actually stands. Every number below was re-run
against the current tree.

## 1. Goal

Land a reader-facing pkgdown article that answers one question in four
comparator packages' own vocabulary — on a dataset you may already know, does
`drmTMB` land on the same fit? — together with regression guards that keep the
answer true, the `DESCRIPTION` declaration the article's data needs, and the
four coupled registration edits that put the article on the site.

This task did not add a capability-ledger row, did not change any likelihood,
estimand, or formula grammar, and did not touch any of the five byte-pinned
files (`R/methods.R`, `R/drmTMB.R`, `src/drmTMB.cpp`,
`tests/testthat/test-zero-one-beta.R`,
`tools/run-lane-c-c17c1-c14-model15-compatibility.R`).

## 2. Implemented

1. `vignettes/comparing-with-other-packages.Rmd` — the article. Eight
   comparisons, each a real dataset with a real `drmTMB` fit and a real
   comparator fit beside it, grouped by how independent the comparator is:
   1–3 against `lme4`/`metafor` (STRONG), 4–5 against `ordinal`
   (unclassified), 6–8 against `glmmTMB` (WEAK — same TMB AD stack and outer
   optimizer).
2. `tests/testthat/test-comparators-phase19.R` — one `test_that()` per
   Comparison, 41 assertions, mirroring the same calls and the same
   matched-scale conversions the article shows.
3. `DESCRIPTION` — `metadat` added to `Suggests`, alphabetically between
   `MASS` and `metafor`.
4. `_pkgdown.yml` — new `articles:` section `Comparison with Established
   Packages`, inserted between `Applied Family Tutorials` and `Model Checking
   and Practical Workflow`.
5. `inst/reader-contracts/vignette-manifest.csv` — one new row,
   `comparing-with-other-packages.Rmd,reader,,`, placed alphabetically between
   `capability-and-limits.Rmd` and `convergence.Rmd`.
6. `tests/testthat/test-reader-vignette-contracts.R` — manifest row-count
   assertion bumped `37L` → `38L`.
7. `docs/dev-log/check-log.md` — dated entry covering all of the above.

## 3a. Decisions and Rejected Alternatives

**`metadat` is declared rather than designed around.** Comparisons 2 and 3 call
`metadat::dat.bcg` in both the article and the tests, and `R CMD check`'s
unstated-dependency scan reaches tangled vignette sources as well as test
files, so leaving it undeclared was a real check risk rather than a style
point. The alternative — moving both comparisons to a dataset reachable without
`metadat` — was rejected because `dat.bcg` is the dataset a `metafor` user
already knows, which is the whole point of the comparison.

Declaring it adds no new install burden: `metafor` 5.0.1's `Depends` field is
`R (>= 4.0.0), methods, Matrix, metadat, numDeriv`, so `metadat` is already
present wherever `metafor` is. That transitive route is not something this
package pins, though — `DESCRIPTION` declares a bare `metafor` with no version
floor — which is the second reason to declare `metadat` directly rather than
rely on the inheritance. A scan of every local and remote ref confirmed no
other branch already adds it, so this is not a duplicate of another lane's fix.

**No capability-ledger row**, per `PR2-build-plan.md` §10.1 and the explicit
instruction. The evidence class is `external_comparator`
(`docs/design/242-external-comparator-evidence-class.md`): point estimates and
`logLik` only, one dataset and one seed per cell. That does not reach any
ledger tier, and adding a row would misrepresent what a single-seed agreement
licenses.

**Tolerances are stated per assertion with the measured difference beside
them**, rather than set to one round number file-wide. Comparison 1 is
deliberately the loosest at `1e-3`, because both sides are `nAGQ = 1` Laplace
and the residual gap is a stable difference between TMB's AD inner solve and
`lme4`'s PIRLS solve — refitting `glmer` with tight `optCtrl` reproduces the
same loose agreement to six decimals, so tightening the tolerance would be
asserting a falsehood about what the comparison shows.

## 4. Files Touched

- `vignettes/comparing-with-other-packages.Rmd` (new)
- `tests/testthat/test-comparators-phase19.R` (new)
- `DESCRIPTION`
- `_pkgdown.yml`
- `inst/reader-contracts/vignette-manifest.csv`
- `tests/testthat/test-reader-vignette-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-08-15-phase19-comparator-workflows.md` (this file)

Not touched: any capability-ledger file, any of the five byte-pinned files,
`docs/design/226-reader-learning-path.md` (repaired separately by the
maintainer).

## 5. Checks Run

All re-run against the current tree, with the article present:

```
$ R_PROFILE_USER=/dev/null Rscript --no-init-file tools/check-reader-contracts.R
Reader vignette contract: OK
(exit code 0)
```

```
testthat::test_file("tests/testthat/test-comparators-phase19.R")
  8 test blocks, 41 assertions, 0 failed, 0 errors, 0 skipped
  per block (nb): C1 4 · C2 4 · C3 4 · C4 6 · C5 5 · C6 6 · C7 6 · C8 6
```

```
testthat::test_file("tests/testthat/test-reader-vignette-contracts.R")
  21 assertions, 0 failed, 0 errors, 0 skipped
```

```
$ python3 -m unittest tools/tests/test_capability_ledger.py
Ran 73 tests — OK
C14 receipt equivalence: OK (3 eligible, 7 source-different retained receipts;
C17 current-source compatibility PASS)
capability-ledger: OK (1 generated outputs)
```

```
knitr::knit("vignettes/comparing-with-other-packages.Rmd")
  73/73 chunks, no error
  (the two error = TRUE chunks fire as intended, printing drmTMB's own
   rejection messages)
```

Registration invariants, checked after editing:

```
$ awk '/^articles:/{f=1} f && /^      - /{c++} END{print c}' _pkgdown.yml
38
$ wc -l inst/reader-contracts/vignette-manifest.csv
39   (1 header + 38 rows)
```

Before editing, §9.1's five cited locations were re-verified against the live
worktree — this phase had stale line citations recur three times — and all five
were exactly where the plan said. No line-number correction was needed.

## 6. Tests of the Tests

The comparator guards were checked by mutation, not by inspection. Making a
wrong model pass is the failure mode that matters here, so it was attempted:

| Probe | Mutation | Result |
| --- | --- | --- |
| Comparison 6 | drmTMB refit with `(1 \| Subject)` instead of `(1 + Days \| Subject)` | `mu`, `sigma`, `logLik` all FAIL |
| Comparison 5 | drmTMB refit without `(1 \| judge)` | slopes and cutpoints FAIL |
| Comparison 2 | comparator switched to `rma.uni()` default REML — the estimator trap the test warns about | `mu`, `tau^2`, `logLik` all FAIL |
| Comparison 1 | drmTMB estimates scaled by `(1 + eps)` | passes at `1e-4`, fails at `1e-3` |

So the assertions bite at roughly 0.1% relative error and catch the three
model-shape regressions that would actually occur. One assertion is a
demonstration rather than a guard and should be read as such:
Comparison 8's `expect_true(all(abs(naive_diff) > 0.5))` asserts that the
*unconverted* comparison disagrees, and would also pass if `drmTMB` regressed
badly — it is paired with the converted equality assertion, so nothing rests on
it alone.

The manifest row-count assertion is a literal, not a computed count, so it
cannot silently pass against the wrong number; bumping it to `38L` and
confirming `wc -l` reports 39 is the direct check that count and file agree.

## 7a. Issue Ledger

No GitHub issue opened, commented on, or closed. Issue #60's Definition of Done
names the pkgdown article, the check log, the after-phase report, and CI
evidence; the first three are present as of this report. CI evidence is not
claimed here — no `R CMD check --as-cran` or `pkgdown::build_site()` was run in
this slice (see §10).

## 8. Consistency Audit

- Vignettes==articles invariant holds at 38 in `_pkgdown.yml`.
- Manifest row count (38) matches the test's updated expectation (38).
- Every non-base package the article calls — `glmmTMB`, `knitr`, `lme4`,
  `metadat`, `metafor`, `ordinal`, `palmerpenguins`, `rmarkdown` — is declared
  in `DESCRIPTION` `Suggests`. This was enumerated from the article's own
  `::`, `requireNamespace()`, `package =` and `library()` calls rather than
  assumed, because the article's closing paragraph asserts exactly this
  ("compared against packages listed in `drmTMB`'s `DESCRIPTION` under
  `Suggests`") and that sentence was false while `metadat` was undeclared. It
  is true as of this report.
- Terminology is stable against the house list: `sigma` (never `tau` as a
  drmTMB parameter — `tau`/`tau^2` appear only when reporting what `metafor`
  itself reports), `meta_V(V = V)`, `mu`, `sigma ~ x`. No `meta_gaussian()` or
  `tau ~` syntax appears.
- Both capability-ledger cells the article names were re-read from
  `docs/dev-log/dashboard/capability-ledger/cells.tsv` rather than trusted from
  the upstream plan: `mc-0225` is `cumulative_logit` / `mu` /
  `ordinary_re_intercept` / ML / `interval_feasible`; `mc-0227` is the same
  family and dpar but `ordinary_re_slope` / ML / `point_fit_recovery`.
- No byte-pinned file was touched; `git status` shows only the files in §4.

## 9. What Did Not Go Smoothly

**The records shipped stale, and that is the finding worth keeping.** This
report and the check-log entry were written at 06:25 against a tree where the
article did not exist; the article landed at 06:37. Three statements that were
accurate on writing became false twelve minutes later, and both documents were
ready to ship that way. Neither author was wrong at the time — the defect is
that a record written mid-flight was never re-read against the tree it
describes before being treated as done. `check-log.md` is append-only
institutional memory: a future session reading the original entry would have
concluded the vignette was missing and the linter red, in a tree where both
were fine.

The mechanism generalises beyond this phase: a "verification" step whose
result is a *predicted* failure ("this will fail until X lands") is not
verification, and it silently expires. The correction is to re-run the checks
at the moment the record is written, which is what §5 now contains.

**Two audits found attribution defects the builders' own checks would not
have.** Both `build-verify-claims.md` and `build-verify-numeric.md` independently
flagged the same wrong ledger cell in Comparison 5, and one flagged a false
"only" that ran in the *conservative* direction — it under-claimed `drmTMB`'s
position, which is exactly the kind of error a self-check has no incentive to
look for. Own-the-verifier held here: the builder did not get to be the only
judge.

## 10. Known Residuals

- **No `R CMD check --as-cran`, no `pkgdown::build_site()`, no full
  `devtools::test()` run in this slice.** The `metadat` declaration is
  specifically the fix for an unstated-dependency finding that only
  `--as-cran` would surface, and that check has not been run to confirm it
  closed. It should be run before the PR merges. This is the one Definition-of-
  Done item from issue #60 not discharged here.
- `docs/design/242-external-comparator-evidence-class.md` does not classify
  `ordinal`'s independence strength, which is why Comparisons 4 and 5 are
  reported without one. Classifying it is a separate, small doc task.
- The article adds 9 words absent from `inst/WORDLIST` under `en_GB`
  (`Adelie`, `PIRLS`, `pleuropneumonia`, `unmodelled`, `unsquared`, `level's`,
  `TMB's`, `lme`, `drmTMB`). `tests/spelling.R` sets `error = FALSE`
  deliberately, so this is report-only and not a CI risk.
- Comparison 7's `drmTMB`-only fit is gated on `has_glmmTMB`, so on a machine
  without `glmmTMB` the surrounding prose remains while the output it describes
  disappears. Standard for conditional vignettes, worth one hedging sentence
  given this article's subject is what the reader can see.
- `PR2-build-plan.md` §12 (reproducibility) and the c04–c09 build
  specifications remain unaudited from the audit side, per
  `gate5-claims.md`'s own closing section. This task does not close that.

## 11. Team Learning

**Record honestly: the restructured Phase 19 plan and its columned comparator
survey failed five consecutive claims audits on one recurring defect class —
unqualified absence claims of the shape "no comparator exists for capability
X".** Each of the first four repairs fixed the wording the audit named rather
than the class: round 2→3 added a 5-string blacklist, and a sixth phrasing plus
a whole per-family table survived it; round 3→4 added a required-clause phrase
search, and three bare-token rows, the term's own definition, and the
replacement heading survived that. **The recurring mechanism was string-shaped
sweeps substituting for enumeration** — grepping for a known-bad phrase rather
than reading every sentence against the rule.

Two maintainer decisions broke the cycle: drop the two frontier fits rather
than keep negotiating their wording; then, once the defect persisted in the
*taxonomy* rather than in sentences, cut the absence narrative out of the
article entirely and give the survey table explicit claim-class / searched /
run columns, so incompleteness shows as an empty cell rather than requiring a
sweep that knows what to look for.

**That worked, and the evidence is that it worked.** The claims audit over the
built article enumerated all 59 paragraphs, 13 headings and 8 table cells one
at a time and found **zero** A1 violations; `grep -i frontier` returns 0. The
class that regenerated five times did not regenerate in the artifact. The
lesson to carry forward is the specific one: **replace the surface the claim
needs, rather than chasing its wording** — and verify by enumeration, not by
grep, because a grep can only find the phrasing you already thought of.

The second lesson is §9's: a record whose verification step is a *prediction*
of failure expires silently. Re-run the checks when you write the record.

## 12. Cross-Product Coverage

Covered: the article, its eight comparator guards, the `metadat` declaration,
the four registration edits, and the check-log and after-task records.

NOT covered, and no claim is made about any of it: `R CMD check --as-cran`,
`pkgdown::build_site()`, a full `devtools::test()` run, interval calibration or
coverage for any model shown (the evidence class is point estimate and `logLik`
only, single dataset, single seed), any capability-ledger promotion, the
statistical adequacy of the eight models as science, `ordinal`'s independence
classification, and `PR2-build-plan.md` §12 / the c04–c09 build specifications.
No likelihood, estimand, formula grammar, or evidence tier changed.

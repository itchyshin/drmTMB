# Build-verify — claims audit of the BUILT Phase 19 artifacts

Auditor: Rose (systems auditor). 2026-08-15. Worktree `.worktrees/phase19`, branch
`claude/phase19-comparator-workflows` (`git status --short --branch`: no commits ahead of
`origin/main@82cd00560`; all Phase 19 artifacts are uncommitted working-tree changes).
drmTMB 0.7.0 via `devtools::load_all()`.

Artifacts read in full: `vignettes/comparing-with-other-packages.Rmd` (605 lines),
`tests/testthat/test-comparators-phase19.R` (587 lines), the check-log entry
(`git diff docs/dev-log/check-log.md`, 74 added lines), and
`docs/dev-log/after-task/2026-08-15-phase19-comparator-workflows.md` (230 lines).
Also read for adjudication: `PR2-build-plan.md` §1.3, §2.5, §6.2, §14; `gate5-claims.md`
Part B; `158-plan-of-record.md` §(c); `docs/design/242-external-comparator-evidence-class.md`;
`docs/dev-log/dashboard/capability-ledger/cells.tsv`; and
`docs/dev-log/external-oracle/phase19/build-verify-mechanical.md` (309 lines, which appeared
in the tree during this audit).

**Verdict: NOT-DONE. 2 blocking, 7 serious.**

**Say the important thing first: A1 is clean.** I enumerated all 59 prose paragraphs, 13
headings and 8 table cells of the article, one at a time, against §2.5's A1, and found **zero
violations**. The two sentences gate 5 blocked on (G5-B1) are repaired in the landed text, not
merely reworded around. The class that regenerated five times did not regenerate here. Both
blocking findings below are about things outside the article's prose: an undeclared package
dependency that will fail `R CMD check`, and a repo record that asserts, as current, a state
that is false in the very tree it describes.

I ran the test file, knit the vignette, ran four mutation probes, a perturbation sweep, two
comparator-advice fits, the reader-contract linter, the Python ledger unittest, and a spell
check. Every claim below cites the command or the file:line it came from.

---

## Answers to the five questions asked

### 1. A1 enumeration — every sentence, including a named package's incapacity. **PASS, 0 violations.**

Enumeration method (not a grep): the article was split mechanically into 13 headings, 8 table
rows and 59 paragraphs with code chunks removed, then each unit was read against A1
(`PR2-build-plan.md:306-309`). Chunk bodies were scanned separately for comments — there is
exactly one (`knitr::opts_chunk$set(...)` at `:12`), so there is no chunk-comment surface.
Rendered chunk *output* was also read, because knitr can introduce text the source does not
contain.

**G5-B1's two sentences are repaired, and repaired in the licensed direction.** Both now
predicate the limitation of a *model*, not of a *package*:

- Comparison 6 (`vignettes/comparing-with-other-packages.Rmd:433-435`):
  *"A mean-only model cannot show that, because it carries a single residual SD for every
  observation."* No package is named.
- Comparison 7 (`:494-496`): *"the `sigma ~ sex` submodel is what makes that second finding
  representable at all; a model with one residual SD has no parameter for it."* No package is
  named.

Neither `lmer` nor `lm` appears anywhere in the article as the subject of an incapacity.
`grep -c -i frontier` over the vignette returns **0** (§14 step 6's first mechanical aid).

**The four sentences closest to the line, and why each clears it.** I record these because a
sixth round should not have to re-derive the adjudication:

| # | Sentence | Why it clears A1 |
| --- | --- | --- |
| `:360-362` | *"no separate estimation engine checked a residual-scale submodel anywhere in this article"* | Absence-shaped, but scoped by "anywhere in this article". §2.5 draws the line at *what this article covered* (supportable) versus *what exists elsewhere* (forbidden); this is the former. It is also restated positively at `:594-596`. |
| `:300-305` | *"`cumulative_logit()` currently fits only a `mu` location formula … `ordinal::clm(scale = ~ ...)` is the tool that already has it."* | Absence of a **drmTMB** capability plus **presence** of a comparator. A1 governs comparator absence. §2.5 names this asymmetry as one of the two accepted compensations. Under §8.5(b) the presence half names the package **and** was run — `comparison4-scale-comparator` fits it and prints `logLik = -86.43946`. |
| `:31-34` | *"These eight models were chosen because a package this article already depends on fits them too; that set is small next to what `drmTMB` implements as a whole…"* | This is §1.3's mandated composition disclosure, near-verbatim (`PR2-build-plan.md:154-160`). It carries a weak inverse implicature (why were the others not chosen?), but the maintainer litigated and signed this exact form in round 5, and `:600-604` names the searched set explicitly (`DESCRIPTION` `Suggests`). Not reopened. |
| `:59-61` (table) | *"none / not compared here / nothing to classify"* | §5 rule 4 makes "not compared here" the complete permitted answer. `:61`'s cell appends "the design documents record what it contains", which §2.5 explicitly permits ("may point to the design documents for the rest"). |

**Rendered output introduces nothing.** The two `error = TRUE` chunks print drmTMB's own
rejection messages (`Unsupported parameter: "sigma"`; the supported-family list). Both are
statements about drmTMB, not about a comparator.

### 2. Independence strength per comparison; glmmTMB honestly WEAK; no percentages. **PASS.**

All eight comparisons carry a labelled independence line: `:130`, `:182-183`, `:240-243`,
`:307-308`, `:351-352`, `:437-438`, `:498`, `:583`. Three section openers carry the block-level
statement (`:77-80`, `:247-251`, `:356-362`), and the closing summary re-states the split
(`:587-598`). The article volunteers the uncomfortable part unprompted at `:360-362` and
`:594-598`: the residual-scale capability — drmTMB's differentiator — has no separate-engine
check anywhere in it. That is the honest direction, and it is stated twice.

**No percentages.** `grep -n "%"` over the vignette returns only the `%\Vignette*` YAML
directives. §1.3's 79%/21% AGENT-INFERRED figures did not leak.

`ordinal` is reported without a strength (`:247-251`, `:307-308`, `:351-352`), and the reason
given — that doc 242 has not classified it — is true: `grep -n ordinal
docs/design/242-external-comparator-evidence-class.md` returns **nothing**.

### 3. Are the tests non-vacuous? **YES — verified by mutation, not by inspection.**

`testthat::test_file("tests/testthat/test-comparators-phase19.R")` → **41 assertions, all
pass, 5.6 s**. I then tried to make assertions pass with wrong models:

| Probe | Mutation | Result |
| --- | --- | --- |
| Comparison 6 | drmTMB refit with `(1 \| Subject)` instead of `(1 + Days \| Subject)`, comparator unchanged | `mu` **FAIL**, `sigma` **FAIL**, `logLik` **FAIL**. Wrong-model sigma `(3.0347, 0.0832)` vs correct `(2.8118, 0.0846)`. |
| Comparison 5 | drmTMB refit **without** `(1 \| judge)`, `clmm` comparator unchanged | slopes **FAIL**, cutpoints **FAIL**. |
| Comparison 2 | comparator switched to `rma.uni()` default REML (the estimator trap the test warns about) | `mu` **FAIL**, `tau^2` **FAIL**, `logLik` **FAIL**. |
| Comparison 1 | drmTMB estimates multiplied by `(1 + eps)` | `1e-4` passes, **`1e-3` fails**, for both the `mu` vector and the herd SD. |

So the assertions bite at ~0.1 % relative error, and the three model-shape mutations a
regression would actually produce are all caught. `expect_error(..., "Unsupported parameter")`
matches for the right reason — the rendered vignette shows the same message coming from
`drm_build_cumulative_logit_spec()`.

One assertion is a demonstration rather than a guard, and should be read as such:
`expect_true(all(abs(naive_diff) > 0.5))` in Comparison 8 asserts that the *un*converted
comparison disagrees; it would also pass if drmTMB regressed badly. It is paired with the
converted equality assertion, so nothing rests on it alone.

### 4. Does the article imply every drmTMB model has a comparator (issue #60's first guardrail)? **NO.**

`158-plan-of-record.md:117` quotes the guardrail verbatim: *"Do not imply that every `drmTMB`
model has a one-to-one comparator."* The article states the opposite four times, each in the
form §2.5 permits: `:30-34` (composition disclosure), `:48-52` and the `:59-61` table rows
("none" / "not compared here"), `:63-65` (joint fits do not license either submodel alone),
and `:600-604` (the closing paragraph, which names `DESCRIPTION` `Suggests` as the searched
set and points to the design documents for the rest). There is one count in the article —
eight — and it counts *comparisons*, not agreements, so §6.2's "no sentence may count or total
agreements across strengths" is not engaged.

### 5. Does the after-task overstate against `build-verify-mechanical.md`? **NO — it understates, and it is stale.**

The only after-task report in the tree
(`docs/dev-log/after-task/2026-08-15-phase19-comparator-workflows.md`) covers the four
registration edits and explicitly disclaims the deliverable: *"This task did not write, read
for content, or edit the `.Rmd` article itself"* (§1). It claims nothing about the article or
the tests, so there is nothing in it to overstate; §11's account of the five-round audit
history is, if anything, harder on the phase than it needs to be. It does not contradict
`build-verify-mechanical.md` on any check both ran.

The defect is the opposite one — three of its statements are false in the tree as landed — and
it is recorded as **B2** below.

---

## Blocking

### B1 [BLOCKING] `metadat` is used by both new artifacts and is not a declared dependency; `R CMD check` will flag it, and the task's own constraints forbid the obvious fix

`metadat` is required by Comparisons 2 and 3 on both sides:

- `vignettes/comparing-with-other-packages.Rmd:15` — `has_metadat <- requireNamespace("metadat", quietly = TRUE)`, and `:139` — `data(dat.bcg, package = "metadat")`.
- `tests/testthat/test-comparators-phase19.R:88,93,148` — `skip_if_not_installed("metadat")` and `metadat::dat.bcg`.

`grep -rn metadat --include=*.R --include=*.Rmd --include=DESCRIPTION` shows these are the
**only** uses in the package, and `DESCRIPTION`'s `Suggests` (25 packages, lines 30-56) does
not contain it. This is the first undeclared package dependency in the repo's vignettes or
tests.

`R CMD check`'s "checking for unstated dependencies in vignettes / in tests" scans tangled
vignette sources and test files for `library`, `require`, **`requireNamespace`** and `::`
usage: `tools:::.check_packages_used_in_vignettes` ends in
`.check_packages_used_helper(db, Rfiles)` over `.package_vignettes_via_call_to_R(...,
source = TRUE)`. Both the vignette's `requireNamespace("metadat")` and the test's
`metadat::dat.bcg` are in scope. The check will fire.

The test file's header (`:24-32`) records this honestly and says the `DESCRIPTION` edit is
"out of scope for this test-only task under the 'no new package dependency' constraint". That
is the right disclosure in the wrong place: **the vignette does not mention it, the check-log
does not mention it, and no after-task report mentions it**, so the only record of a
CI-affecting decision sits in a comment in one of the two files that causes it.

Two supporting details:

1. The header's mitigation — *"metafor (>= 5.0-1, already a Suggests dependency) Depends on
   metadat"* — is half right. `packageDescription("metafor")$Depends` is
   `R (>= 4.0.0), methods, Matrix, metadat, numDeriv`, so the transitive claim holds **for the
   installed 5.0-1**. But `DESCRIPTION` lists a bare `metafor` with **no version floor**
   (`grep metafor DESCRIPTION` → `    metafor,`), so the "(>= 5.0-1)" in the comment describes
   a constraint the package does not declare. A user with an older `metafor` may not have
   `metadat`, and the `skip_if_not_installed()` guard covers the test but not the vignette's
   check-time tangle.
2. This is a maintainer decision, not a builder fix: either `metadat` joins `Suggests`
   (violating this slice's stated constraint, so it needs an explicit sign-off), or
   Comparisons 2 and 3 move to a dataset reachable without it. **Escalate rather than land.**

### B2 [BLOCKING] The landed check-log and after-task report assert, as current, three things that are false in the same tree — and no record covers the article or the tests at all

`docs/dev-log/check-log.md` (this branch's new 2026-08-15 entry) and
`docs/dev-log/after-task/2026-08-15-phase19-comparator-workflows.md` were written at 06:25
against a tree where the article did not exist; the article landed at 06:37 (`ls -la
vignettes/comparing-with-other-packages.Rmd`). Three statements are now false:

| Statement | Where | Truth today |
| --- | --- | --- |
| *"it does not exist in this worktree as of this entry"* (the article) | check-log entry, bullet 1; after-task §1 | It exists, 605 lines. |
| *"`Rscript tools/check-reader-contracts.R` **fails** with `Manifest references absent vignette(s)`"* | check-log entry, verification bullet; after-task §5 | I ran it: **`Reader vignette contract: OK`**, exit 0. |
| *"`vignettes/comparing-with-other-packages.Rmd` does not exist in this worktree; until it lands, `tools/check-reader-contracts.R` and `test-reader-vignette-contracts.R`'s `expect_setequal()` will fail"* | after-task §10 | Both pass. `test_file("tests/testthat/test-reader-vignette-contracts.R")` → 21 assertions, all pass. |

Each was accurate when written and neither author is at fault for the ordering. The defect is
that they ship this way: `check-log.md` is append-only institutional memory, and a future
session reading it will conclude the vignette is missing and the linter red. Two corrective
lines close it.

The larger half of this finding is what is *absent*. `AGENTS.md` rule 7 ("every meaningful
change should update `docs/dev-log/check-log.md`") and rule 8 (after-task report per
`docs/design/10-after-task-protocol.md`) are unmet for the two artifacts under audit: **there
is no check-log entry and no after-task report for `comparing-with-other-packages.Rmd` or
`test-comparators-phase19.R`.** Issue #60's Definition of Done names both explicitly
(`158-plan-of-record.md:113-115`: *"…pkgdown article or design note, check log, after-phase
report, and CI evidence are present"*). The mechanical report is evidence, not a record of
decisions: nothing in the repo yet states why eight cells, why these tolerances, why no ledger
row, or that B1 was knowingly accepted.

---

## Serious

### S1 [SERIOUS] *"the only comparison in this article that checks a `sigma` linear predictor against a separate estimation engine"* is false — Comparison 2 does it too, in this article, with the output printed

`vignettes/comparing-with-other-packages.Rmd:240-243`:

> **Independence: STRONG.** This is the only comparison in this article that checks a `sigma`
> linear predictor against a separate estimation engine…

Comparison 2 fits `sigma = ~ 1` and compares it to `metafor` ML. The rendered chunk
`comparison2-convert` prints:

```
c(drmTMB_tau2 = exp(2 * coef(fit2, "sigma")), metafor_tau2 = cmp2$tau2)
#> drmTMB_tau2.(Intercept)            metafor_tau2
#>               0.2800281               0.2800282
```

An intercept-only `sigma` formula is still a `sigma` linear predictor, and the test file
asserts it (`tests/testthat/test-comparators-phase19.R:123-129`, "tau^2 = exp(2*sigma)").
`:594-596` repeats the claim in an ambiguous form — *"The one separate-engine check on a
`sigma` linear predictor is the meta-analysis comparison"* — when there are two meta-analysis
comparisons and both check one. The `:58` table row ("Distributional (`sigma`) submodel, fixed
effects | 3, 6, 7, 8") makes the same omission.

In fairness the error runs in the conservative direction: counting Comparison 2 would *add* a
STRONG `sigma` check and slightly improve drmTMB's position. It is still a false "only" in the
one accounting paragraph the article's honesty rests on. Fix: qualify as "a `sigma` linear
predictor **with a covariate**", and either add Comparison 2 to the `:58` row or say in that
row why an intercept-only `sigma` is counted separately.

### S2 [SERIOUS] Comparison 5 asserts that cutpoints agree, and never shows drmTMB's cutpoints

`:336-337`: *"Every quantity here — slopes, cutpoints, the random-intercept SD, and the
log-likelihood — agrees closely between the two fits."*

The chunks display `summary(fit5)$coefficients` (two slopes only — the rendered output is
`mu:tempwarm 3.063001`, `mu:contactyes 1.834900`), `coef(cmp5)` (which *does* print `ordinal`'s
four cutpoints), the two SDs and the two log-likelihoods. **drmTMB's cutpoints are never
printed**, so the reader is asked to accept an agreement in a quantity only one side of which
is on the page. Comparison 4 shows both sides (`summary(fit4)$ordinal$cutpoints` at `:266`),
which makes the omission look like an oversight rather than a choice.

The test does check them (`:301-306`, `fit$ordinal$cutpoints` vs `fit_clmm$alpha`, measured
max abs diff ~1.5e-5), so the claim is true — it is the article's evidence that is missing.
One added line (`summary(fit5)$ordinal$cutpoints`) closes it.

### S3 [SERIOUS] Comparison 1's "what to try next" pointer fails when tried

`:127-128`: *"`beta_binomial()` or `nbinom2()` add a dispersion parameter if that matters for
your own data"* — written immediately after discussing `cbpp`'s extra-binomial variation, on a
two-column `cbind(incidence, size - incidence)` response.

Run against `lme4::cbpp` with the article's own formula:

```
--- beta_binomial on cbpp ---  "OK logLik -88.042"
--- nbinom2 on cbpp cbind response ---  "ERROR: Internal model-frame mismatch in nbinom2 model."
```

Half the advice works; the other half errors, and errors with an internal-sounding message
that gives the reader nothing to act on. `AGENTS.md`'s writing rules require telling the reader
what to try next when a model or syntax is unsupported — a pointer that dead-ends is worse
than none. Either drop `nbinom2()` from the sentence, or scope it explicitly to a single-column
count response ("…and `nbinom2()` if your response is a count rather than a two-column
binomial").

### S4 [SERIOUS] Comparison 5 cites the wrong ledger cell — `mc-0227` is the random-**slope** row; the fitted model is a random **intercept**

`:346-349`: *"The public `mc-0227` slope capability behind this family uses ML-Laplace and is
point-fit-recovery only…"*

The model shown is `mu = rating ~ temp + contact + (1 | judge)`. In
`docs/dev-log/dashboard/capability-ledger/cells.tsv`:

- `mc-0225` — `cumulative_logit`, `dpar mu`, `effect_type ordinary_re_intercept`,
  `evidence_tier interval_feasible`. **This is the cell the comparison fits.**
- `mc-0227` — `cumulative_logit`, `dpar mu`, `effect_type ordinary_re_slope`,
  `evidence_tier point_fit_recovery`. This is the cell the article names.

The sentence itself is grounded — it is a near-quote of
`docs/design/02-family-registry.md:97` — and it is *conservative*, since `mc-0227` sits a tier
below `mc-0225`. But calling it "the capability behind this family" attaches the wrong row to
the displayed model, and `mc-0225`'s own boundary is the one a reader of this comparison needs
(*"interval_feasible only for the named cell × direct intercept-SD target × frozen low-rung
fixture … does not establish inference readiness … or public interval guidance"*). Cite
`mc-0225` for the fitted model, and keep `mc-0227` only if the article means to speak about
slopes as well.

### S5 [SERIOUS] Comparison 6's test uses `lme4` but only skips on `glmmTMB` — it errors instead of skipping when `lme4` is absent

`tests/testthat/test-comparators-phase19.R`, the `test_that("Comparison 6 (c01) …")` block:
its only guard is `suppressWarnings(testthat::skip_if_not_installed("glmmTMB"))`, and the body
then calls `lme4::sleepstudy` five times — in the displayed drmTMB fit, the comparator fit, and
three times in the fixed-effect density sub-check. Both packages are `Suggests`, so a machine
with `glmmTMB` and without `lme4` is a legitimate check environment; there the test **errors**
rather than skipping. Comparison 1 guards `lme4` correctly and Comparison 7 guards both
`glmmTMB` and `palmerpenguins`, so this is an omission, not a policy. One added
`skip_if_not_installed("lme4")` closes it.

### S6 [SERIOUS] `build-verify-mechanical.md` §8's knit transcript does not correspond to the article it certifies

`docs/dev-log/external-oracle/phase19/build-verify-mechanical.md:252-286` pastes a knit
transcript and concludes *"PASS — Vignette knit completed successfully. All 73 chunks executed
without error."* The transcript cannot have come from the landed article:

- it lists a chunk named **`comparison8-loglik`**, which does not exist —
  `grep -o '^```{r [^,}]*'` over the vignette returns 34 labelled chunks and that is not one of
  them;
- it lists `comparison8-clash`, `comparison8-drmtmb`, `comparison8-comparator` and
  `comparison8-convert` **three times each**. knitr errors on duplicate chunk labels, so no
  single knit of any valid document produces that sequence.

My own run (`knitr::knit("vignettes/comparing-with-other-packages.Rmd", output = <scratch>)`)
completed 73/73 with each label once, ending at `comparison8-convert`. **The conclusion is
right and I have independently reproduced it** — that is why this is serious rather than
blocking — but the evidence offered for it is not evidence of this artifact, which is the one
thing a mechanical report exists to provide.

Same section, smaller: §7c states the manifest has *"38 rows (data rows; line 40 is blank)"*.
`wc -l inst/reader-contracts/vignette-manifest.csv` is **39** (1 header + 38 rows) and `od -c`
on the tail shows the file ends after row 38; there is no line 40.

### S7 [SERIOUS] The doc-226 repair bumped the numeral the unittest reads and left the document's own totals at 37

`build-verify-mechanical.md:145-171` reported the one FAIL:
`test_reader_navigation_redirect_and_public_language_contract`, because
`docs/design/226-reader-learning-path.md` line 1 said "37 vignettes". That has since been
edited (`git diff docs/design/226-reader-learning-path.md`) and the unittest now passes
73/73 — I re-ran it. But the diff changed line 1, changed "37 rows" to "38 rows", and added
row 34, while the paragraph immediately below the table still reads:

```
Total: 37 placed. Stage counts … **5. Uncertainty & inference boundaries** = 4 …
4 + 4 + 9 + 3 + 7 + 4 + 1 + 5 = 37.
```

The new row was placed in "5. Uncertainty & inference boundaries", so that count should be 5
and the total 38. The unittest asserts only on `design.splitlines()[0]`
(`tools/tests/test_capability_ledger.py:1206`), so a numeral bumped on line 1 turns it green
over a document whose own arithmetic now contradicts its heading. This is the same
string-shaped-fix-for-a-structural-problem pattern that `gate5-claims.md` Part D records four
times; it is worth naming because it recurred *inside this phase's own clean-up*. The edit is
also absent from the check-log and from every after-task report.

---

## Minor / notes (no action required, but record the adjudication)

1. **§14 step 7's mandated grep will hit the article twice, on negations.** §6.2 forbids
   "independent confirmation" and "cross-implementation" for WEAK comparisons. The article
   contains *"not an independent confirmation"* (`:437-438`) and *"not a cross-implementation
   check"* (`:359-360`). Both are honest — they deny the forbidden claim — but §6.2 as written
   has no negation exemption, so the next reviewer running that grep gets two hits and must
   re-derive this adjudication. Record it, or reword to "not an independent check".
2. **`:576-581` compares a sign to something that has no sign.** *"it is signed the opposite
   way for `nbinom2()` than it was for the identity rule in Comparison 6"* — Comparison 6's
   rule is the identity, which has no sign to be opposite of. The test comment states the real
   contrast correctly (`-2*` for `nbinom2`, `+2*` for `tweedie`). Related: the naive mismatch
   the sentence calls "large enough to notice" is never shown in the article; the test measures
   it (`> 0.5`).
3. **Two uncited factual claims in reader prose.** `:234-236` — *"drmTMB's own recorded
   evidence for this route says heterogeneity intervals are not usable at this few studies per
   level"* — is supported by `mc-0260m`'s claim boundary (*"The K=12 tau=0.10 [0, Inf]
   degeneracy remains a separate STOP for heterogeneity intervals"*), but the record is at
   K = 12 **total**, not per level, and the article names no source. `:257` cites "Randall
   (1989)" with no reference entry anywhere in the vignette.
4. **Degraded rendering when a Suggests package is missing is unhedged.** Comparison 7's
   drmTMB-only fit is gated on `has_glmmTMB` (`:445`), so on a machine without `glmmTMB` the
   prose at `:466-470`, `:482-485` and `:492-496` remains while the output it describes
   disappears. Standard for conditional vignettes; worth one sentence of hedging given this
   article's subject is what the reader can see.
5. **Spelling is report-only, so this is not a CI risk**, but the new vignette adds 9 words
   absent from `inst/WORDLIST` under `en_GB` (`Adelie`, `PIRLS`, `pleuropneumonia`,
   `unmodelled`, `unsquared`, `level's`, `TMB's`, `lme`, `drmTMB`). `tests/spelling.R` sets
   `error = FALSE` deliberately.
6. **Rendered error output embeds the worktree path** (`Error in
   \`drm_build_cumulative_logit_spec()\` at phase19/R/drmTMB.R:424:3`). Regenerated at build
   time, so harmless — noted only so nobody mistakes it for a stable citation.

---

## What I verified, exactly

| Check | Command | Result |
| --- | --- | --- |
| Comparator tests | `testthat::test_file("tests/testthat/test-comparators-phase19.R")` | 41 assertions pass, 5.6 s |
| Test non-vacuity | 3 wrong-model refits + relative-perturbation sweep | all mutations FAIL correctly; detection at ~1e-3 relative |
| Vignette executes | `knitr::knit("vignettes/comparing-with-other-packages.Rmd")` | 73/73 chunks, no error |
| Rendered numbers | read the knitted `.md` in full | Jacobian identity, `sd=exp(eta)` identity, `size=1/sigma^2` identity, all three reproduce `logLik()` as claimed |
| Reader contract | `Rscript tools/check-reader-contracts.R` | `Reader vignette contract: OK` |
| Manifest test | `testthat::test_file("tests/testthat/test-reader-vignette-contracts.R")` | 21 assertions pass |
| Ledger unittest | `python3 -m unittest tools/tests/test_capability_ledger.py` | 73 tests, OK (Grace's FAIL now fixed — see S7) |
| Comparator advice | `beta_binomial()` / `nbinom2()` refits on `cbpp` | see S3 |
| Dependency scan | `grep -rn metadat`; `DESCRIPTION`; `packageDescription("metafor")` | see B1 |
| Spelling | `spelling::spell_check_files(..., lang = "en_GB")` | 9 new words, report-only |

**What I did NOT check, and nobody should read this report as covering:** I did not run
`R CMD check --as-cran` (B1's consequence is derived from the check's own source, not
observed), did not build the pkgdown site, did not run the full `devtools::test()` suite, did
not audit `PR2-build-plan.md` §9/§12 or the c04–c09 build specifications (still unaudited from
the audit side per `gate5-claims.md`), and did not evaluate the statistical adequacy of the
eight models as science — only whether the article's claims match what the code produces.

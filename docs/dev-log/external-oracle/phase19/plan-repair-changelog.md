# PR 2 build-plan repair — changelog

Author: Ada (integrator), 2026-08-14.
Worktree: `.worktrees/external-oracle`, branch `claude/external-oracle-intervals`,
`4530fd71a`, drmTMB 0.7.0 (`DESCRIPTION:3`).
Target: `docs/dev-log/external-oracle/phase19/PR2-build-plan.md` (rewritten in place).

Inputs: `adversarial-claims.md` (Rose — overall NOT-DONE, 8 findings, A1 BLOCKING),
`adversarial-scales.md` (Noether — 9/10 conversions survive, N1 REFUTED, N2–N6 secondary),
`docs/design/242-external-comparator-evidence-class.md` including its 2026-08-15 amendment.

No R was run for this repair; every source fact below was re-read from the file it cites.
Nothing was re-fitted — all numeric results in the plan remain Gauss's and Noether's
measurements, cited as theirs.

---

## 1. Rose A1 [BLOCKING] — frontier leakage by adjacency

**Finding.** Each frontier model was paired with an agreeing overlap cell on the same
dataset (sleepstudy → sleepstudy, penguins → penguins), same narrative voice, escalating
reader question. Labelling does not undo adjacency; `docs/design/242-…:86-91` forbids
*blurring*, not merely mislabelling.

**Previous plan's answer.** A disclaimer sentence attached to each frontier cell, with the
concession "the dataset thread cannot be broken without losing the cells". That is the
weaker of Rose's two remedies and it puts a caveat next to an agreeing number.

**What changed.** The plan now answers A1 with article architecture. New §2 ("Article
architecture — this is the A1 fix") replaces the one-paragraph structural rule and
specifies:

- **§2.1 — a three-part shape.** Part 2 (comparisons) is *closed out* by its own scope
  summary before Part 3 (the frontier register) opens. The reader crosses a stated boundary,
  not a heading.
- **§2.2 — Part 2 is reordered by independence strength, not by dataset or by drama.** Three
  sub-headed blocks: STRONG (`lme4`, `metafor`) → `ordinal` (unclassified) → WEAK
  (`glmmTMB`). Article reading order becomes c08, c04, c05, c06, c07, c01, c09, c03. This
  simultaneously fixes A3 (below) and puts **`Owls` last** — so neither `sleepstudy` nor
  `penguins` is the last dataset before the register. Adjacency is broken by two intervening
  comparisons in each case.
- **§2.3 — eight build rules F1–F8 governing the register.** F1: the frontier models lose
  their article number and their `c0x` label, so the parallel enumeration that invites
  transfer is gone. F2: closed section between. F3: the register *opens* with the
  undemonstrated frontier list (`sd()` regression, bivariate LSS, phylogenetic/spatial
  structure), so the two illustrated models read as instances of a class rather than as
  cells 9 and 10. F4: no agreement arithmetic anywhere in the register — no abs-diff column,
  no tolerance, no digit copied from Part 2. F5: each subsection restarts its dataset,
  question and model, with explicit bans on "as in Comparison 6", "the same data as above",
  and the escalation pattern. F6: each subsection names its governing `cell_id` before
  showing any estimate. F7–F8 are the disclaimer layer, now *on top of* structure and
  repositioned **before** the numbers rather than after. F8 makes the article end on frontier
  framing, not on "glmmTMB failed and drmTMB did not".
- **§2.4 — alternatives considered, rejected, and the residual risk named.** Substituting a
  different dataset is forbidden (unfitted model). Dropping c01/c09 is clean but costs both
  location-scale reader stories and does not even fix A3. The escalation — drop the frontier
  fits entirely — is recorded as available and added to the maintainer sign-off list
  (§10.4.5). The residual risk (both datasets still appear twice in one document) is stated,
  with a **build gate**: if the drafted register cannot satisfy F4 while remaining readable,
  the frontier fits are dropped.

**Also changed:** §4 is now "Part 3 — the register", written to F1–F8 rather than as two more
cell specifications; §8.2's boundary paragraph now says "**eight** models compared", not
"these ten cells", so the opening does not fold the frontier into the total.

## 2. Rose A2 [SERIOUS] — coverage table merges overlap with frontier

**Finding.** `candidate-cells.md:48` puts four fixed-effect scale submodels and one
random-effect scale submodel under one "distributional submodel" row, making it read as one
validated thing with five supporting cells.

**What changed.** New §5 gives the article's coverage table in full, with the row split into
two bold rows:

- *Distributional (`sigma`/dispersion) submodel — **fixed effects*** → Comparisons 3, 6, 7, 8;
  comparator exists for all four.
- *Distributional (`sigma`) submodel — **ordinary random effect*** → **none** in Part 2; "no
  working comparator: `glmmTMB` accepts the syntax and returns a degenerate fit on the one
  dataset tested".

A third frontier row (`rho12` with a predictor) also reports "none", and a sixth row carries
the ~79% composition fact. Three binding rules were added: no total/count row (that averages
WEAK into STRONG), frontier rows must show "none" rather than cite a Part 3 subsection, and
the same split must be applied to `candidate-cells.md:48` before that file is cited (§11).

## 3. Rose A3 [SERIOUS] — WEAK independence carrying STRONG's weight

**Finding.** Every residual-scale agreement is against `glmmTMB`, which shares drmTMB's
TMB/AD stack and outer optimizer (`docs/design/242-…:110-111`) — and residual scale is
drmTMB's differentiator.

**What changed.** New §6, four mechanisms in decreasing structural weight:

- **§6.1 structural** — Part 2 is sectioned by strength (§2.2), so a WEAK number cannot be
  reached without first reading the block heading and its mandatory opening sentence. The
  STRONG block takes the opening position, which is the heaviest rhetorical slot.
- **§6.2 vocabulary rule**, grep-able at review: "independent implementation",
  "independently validated", "external validation", "independent confirmation" and
  "cross-implementation" are **forbidden** for `glmmTMB` rows; the permitted phrasing is doc
  242:111's own "a consistency check between related implementations". No sentence may count
  or total agreements across strengths.
- **§6.3** the mandatory closing sentence for Part 2, which states plainly that every
  residual-scale comparison in the article is in the `glmmTMB` group.
- **§6.4** inline per-cell tagging (retained from the previous revision) plus a strength
  column in the §5 table.

**One refinement, stated openly rather than applied silently.** Rose's A3 prose says "Every
residual-scale agreement in the set is weak-independence", while Rose's own A3 table lists
Comparison 3 (c05) as metafor/STRONG. Both are right at different resolutions: c05's `sigma`
enters as the between-study component of `sqrt(v_known + sigma^2)`
(`R/methods.R:5433-5435`, re-read in place), so it is a `sigma`-side linear predictor but not
a residual scale. The plan uses the precise form and says so in §6.3. This sharpens A3; it
does not contest it.

## 4. Noether N1 [REFUTED] — the `rho12` link

**Finding.** The link was stated as `atanh`/`tanh`; it is `0.999999 * tanh`.

**Verified independently before writing**, not taken from the audit:

```
src/drmTMB.cpp:670   vector<Type> rho12 = Type(0.999999) * tanh(eta_rho12);
src/drmTMB.cpp:4260  (identical, the other biv_gaussian branch)
R/family.R:34        rho12 = "atanh_guarded"
R/family.R:13-15     "...fitted response-scale correlations use rho12 = 0.999999 * tanh(eta_rho12)"
```

(`grep -rn "0.999999" src/*.cpp R/*.R` also shows the same guard on every other correlation
branch in the template, so this is the package's uniform convention, not a one-off.)

**What changed.** §4.2 states the guarded link with all three source citations and the
inverse `eta = atanh(rho12 / 0.999999)`; the sentence *"the link is `atanh` (Fisher z)" must
not appear in the article, in doc 158, or in any corrected source document*. A new doc 158
edit (§10.2 item 5) requires checking whether the plain-`tanh` error propagated into the
design doc. §11 carries the `feasibility-batch-4.md:111-115` correction.

## 5. Noether N2–N6 — the five secondary defects

**I dispute none of them.** All five are applied, and §11's corrections table now carries an
"audit id" column so each fix is traceable to its finding.

| id | Defect | Where it is applied |
| --- | --- | --- |
| N2 | Two of c10's three quoted `tanh` values misrounded (`0.3860`/`0.6536` vs `0.3858209`/`0.6535349`) — ~300× the guard effect the paragraph was demonstrating | §4.2 "Numbers to use" (six-decimal response-scale values, explicit "do not quote batch 4's"), §11 row |
| N3 | `feasibility-batch-1.md:35` `abs diff` `1e-6`, actual `1.1e-7` | §3 Comparison 6 build note, extended to also correct the table's "4-5 significant figures" (the `sigma` coefficients agree to 8); §11 row |
| N4 | Batch 3's "doc 158 L69/L30/L25" point at the phase19 extract, not the design doc (`:90`, `:47`, `:42`) | §11 row |
| N5 | Batch 4 cites `docs/design/242-…:82-84` for credibility-laundering; the passage is `:86-91` | §11 row, with the note that `:82-84` is about the withheld `lme4` point-agreement row |
| N6 | "the conversion table is being read correctly" over-claims: only **two** non-identity conversions were tested | §7 closing paragraph (verbatim scope limit) + new doc 158 edit §10.2 item 3 marking which rows are density-verified; §11 row |

## 6. Carried forward unchanged (per brief)

- **Only actually-fitted cells appear.** The eight comparisons are exactly the eight VIABLE
  fits; nothing was added. The two frontier models were fitted on the drmTMB side and are
  retained as frontier, not promoted.
- **Every rejected cell keeps its blocker** — §7's table is intact, with `beta_binomial`,
  `gamlss`, `betareg`, the `cumulative_logit` scale submodel, c05's rejected *claim*, and the
  speed claim all retained.
- **Reproducibility block** — §12, unchanged in substance, with one addition: the recorded
  versions are labelled "as recorded" and the building session must re-emit them.
- **Reader-article registration checklist** — §9, all five edits retained (four coupled +
  `DESCRIPTION`).
- **Runtime estimate with D-139 flags** — §13, unchanged: everything authoring-side is under
  the 30-minute line; `pkgdown::build_site()` and `--as-cran` remain flagged as requiring
  approval, with the stop-and-re-report rule.

## 7. Additional defects found while repairing (Rose principle)

None of these came from either audit; all were found by re-reading the sources the plan
cites, and all are fixed in place.

1. **`mc-0266`'s boundary does not cover the sleepstudy design.** Read from `cells.tsv`: its
   `interval_feasible` tier is scoped to "the current-source ML Gaussian residual-scale
   random-intercept DGP at **48 groups and 20 observations per group**", and its `next_gate`
   forbids inheriting the result to another group design. `sleepstudy` is 18 subjects × 10
   observations. The plan now forbids presenting that fit as interval-ready (§4.3, §15.4).
   Rose correctly said the frontier cell must be sourced to `mc-0266`; this is what `mc-0266`
   actually says.
2. **`c10` does have a governing ledger cell.** `mc-0181` (`biv_gaussian`, `dpar = rho12`,
   fixed, ML, implemented, `interval_feasible`) exists — the previous plan implied none. But
   its recorded boundary's worked example is `rho12~1`, an intercept-only correlation, and
   recovery is at n=900 within 0.12 abs error. Whether a predictor-dependent `rho12 ~ species`
   sits inside its tested domain is **not established**; flagged as an open item for the
   building session (§4.2, §15.3) rather than assumed either way.
3. **Five wrong line citations in the previous revision of the plan itself**, all
   re-verified in place and tabulated in §11: `tools/check-reader-contracts.R:6-8` → `:7-10`
   (the forbidden-field vector); `:106-109` → `:98-100` (`route_pattern`); `:210-215` →
   `:234-239` (the reader-row fail-closed branch); `:2-4` → `:3-5` (the "operates on source
   text" comment); `tools/capability_ledger.py:2329-2333` → `:2328-2333`.
4. **Three more wrong line citations in the ledger-enforcement block** (§8.4), found on a
   second pass: `test_capability_ledger.py:3016-3021` → `:3009-3014` (required tokens),
   `:3022-3025` → `:3023-3026` (`path_or_url`), `:3037-3040` → `:3037-3041` (`cell_id`).
   Also added the independence-token assertion at `:3018-3022`, which the previous revision
   attributed only to `capability_ledger.py`.
5. **Source facts re-verified in place** so the plan does not rest on the audits alone:
   `drm_nbinom2_size <- function(sigma) 1 / sigma^2` (`R/family-dpq.R:902-904`);
   `stats::dlnorm(y, meanlog = params$mu, sdlog = params$sigma)` (`R/family-dpq.R:427-434`);
   `drm_total_obs_sd <- function(v_known, sigma) sqrt(v_known + sigma^2)`
   (`R/methods.R:5433-5435`); `cumulative_logit()`'s `dpars = c("mu")` (`R/family.R:415-418`);
   `COMPARATOR_PACKAGES` and `ordinal`'s membership (`tools/capability_ledger.py:3875-3878`,
   `:3876`); `ev-mc-0260m-meta-v`'s small-K heterogeneity sentence (`evidence.tsv`);
   `expect_equal(nrow(manifest), 37L)` at `tests/testthat/test-reader-vignette-contracts.R:224`
   with the manifest at 1 header + 37 rows; `_pkgdown.yml:256-261` / `:262-268`; and
   `metadat` genuinely absent from `DESCRIPTION` `Suggests`.

## 8. Not fixed, and why

Recorded in the plan at §15 as well.

1. `sleepstudy` and `penguins` still each appear twice in the document — the residual A1
   risk, with the escalation and the build gate named (§2.4).
2. `ordinal`'s independence strength remains a doc 242 decision (§10.3); two of eight
   comparisons ship without a strength if it is unsigned.
3. `mc-0181`'s coverage of predictor-dependent `rho12` is unresolved (§4.2).
4. Timing remains dropped rather than measured (§12), pending maintainer sign-off.
5. No cell was re-fitted in this repair.

---

# Round 3 — repair after both re-audits returned NOT-DONE

Author: Ada (integrator), 2026-08-14.
Inputs: `regate-claims.md` (Rose — NOT-DONE, R1 BLOCKING, R2–R8 serious, five notes) and
`regate-scales.md` (Noether — R1 MATERIAL, R2/R3/R4 new, S1 self-correction).

**Round 3 ran R.** Rounds 1 and 2 re-fitted nothing. This round re-fitted four models —
c01 and c03 in both their displayed random-effect form and their fixed-effect variant —
plus the c02 `glmmTMB` comparator, because Noether R1 and the factual core of Rose R1 could
not be settled from documents. Script: `scratchpad/ada-round3-verify.R`. Raw output is in
the plan at §11.1. Everything else numeric remains Gauss's or Noether's, cited as theirs.

## 1. Rose R1 [BLOCKING] — the false non-existence claim returned in Part 3's frame

**Finding.** The A1 fix built a new Part 3 whose opening (`:533-537`) and closing
(`:659-665`) both asserted that no comparator exists — for a set including the one model
where one demonstrably fits. §8.3 item 3's frontier list omitted scale-side random effects,
so §4.3's model was not an instance of the class F3 opened with. The register's prose
contradicted its own coverage table at `:685-686`. Root cause upstream and uncorrected:
`expressible-vs-comparator.md:110-113`.

**Not argued down. Fixed structurally, in four places plus the source.**

- **New §8.5, "The three comparator-absence claims, never merged"** — the mechanism this
  document lacked. Class **A** *no comparator found* (a stated set, actually searched),
  class **B** *a comparator fits and fails / fits a different model*, class **C** *a
  comparator may fit and was not validated*. Each with its evidence requirement, permitted
  phrasing, and the instances in this article. Binding rule: no sentence anywhere may
  assert a blanket "no comparator exists" for a capability where one demonstrably fits, and
  a list mixing classes may not take a single class-A framing — which was the precise
  mechanism of the failure. Forbidden strings are listed for a grep at draft review, and
  §14 step 7 makes that grep mandatory. Downgrade direction stated: when uncertain between
  A and C, write C.
- **§4.1 rewritten.** The register's opening draft now carries the three-way split
  explicitly, names the class-B case before the reader meets it, and points forward to
  Comparison 4 for the reverse direction. The old sentence is quoted in place as what was
  wrong and why.
- **§4.4 rewritten.** The article no longer ends on "because there is no other package to
  agree with". The replacement paragraph states plainly that the two frontier models are
  *not in the same position as each other*, and names the weaker claim as weaker.
- **F3 (§2.3) re-sourced.** The list is now the complete four-class frontier of
  `expressible-vs-comparator.md:102-133` as corrected — scale-side random effects **first** —
  which is also doc 242's own sentence at `:86-88`. Both illustrated models are now genuine
  instances of the opening list. F3 explicitly may not claim the whole list has no
  comparator.
- **§8.3 retitled and completed** ("What has no *working* comparator"), with a §8.5 class on
  every item and item 3 expanded to all four classes, each classified.
- **§1.2, §5, §7 aligned** — the frontier table gains a claim-class column, the coverage
  table's three "none" rows are distinguished in words, and the rejected-cell table names
  c02 class B and c10 class A/C.
- **Upstream fixed, not just downstream.** `expressible-vs-comparator.md:110-113` is
  corrected in place: class 1 now reads as class B, quotes the refuted sentence in a
  superseded block so the record survives, and cites the re-run. Classes 2–4 are marked
  class C ("none known to this survey"), and the file gains a three-class preamble. This is
  the part that stops later documents re-importing the error.

**Where I state it more narrowly than Rose did.** Rose's fix (i) offered doc 242's frontier
*or* `expressible-vs-comparator.md`'s four classes. I used the latter and routed the choice
to maintainer sign-off as §10.4.6, because the corrected file is what the article cites as
its evidence trail while doc 242 is the governing design document — that is a maintainer's
call, not mine.

## 2. Noether R1 [MATERIAL] — fixed-effect log-likelihoods cited for random-effect models

**Finding.** §3 Comparisons 6 and 8 display random-effect models and cite `-938.7163657`
and `-1725.172156`, which are fixed-effect fits' values; the density identity provably fails
on the displayed models. Noether's own "fixed effects only, so no Laplace step" qualifier
did not survive into round 2's plan.

**Re-derived and verified by running the fits, not copied.** Measured this round:

```
c01 displayed (RE) logLik  drmTMB -870.000347731500  glmmTMB -870.000347731517  abs 1.63e-11
c01 fixed-effect variant   logLik -938.716365658989
   hand dnorm(sd = sigma)         -938.716365658985   accepted
   hand dnorm(sd = sqrt(sigma))  -4647.81685139013    rejected
c03 displayed (RE) logLik  drmTMB -1716.217678074193 glmmTMB -1716.217678074613 abs 4.20e-10
c03 fixed-effect variant   logLik -1725.1721564513
   hand dnbinom(size = 1/sigma^2) -1725.17215645118   accepted
   hand dnbinom(size = 1/sigma)   -1735.68990059604   rejected
   hand dnbinom(size = sigma)     -1822.90463179193   rejected
```

**What changed.** Both conversion bullets are restructured into two numbered pieces of
evidence on two named models: the density check on the fixed-effect variant, where the
likelihood is exact; and the shared *marginal* log-likelihood on the displayed model, which
Noether is right to call the stronger evidence and which round 2 left unused. Draft article
wording is supplied for both. The provenance line now points at §11.1 (this session), not at
`adversarial-scales.md:48-68`, whose numbers belong to the fixed-effect variant.

**One narrowing of Noether's own claim.** He reports the two packages' marginal
log-likelihoods as "identical". At full double precision they differ by `1.63e-11` and
`4.20e-10`. "Identical to printed precision" is accurate; "identical" is not, and the plan
now quotes the differences. Recorded in §11.1.

## 3. The serious findings

| Finding | Disposition | Where |
| --- | --- | --- |
| **R2** — "Eight of these ten models have a comparator" contradicts `:71` and `:761` | **Closed.** The true statement is "eight have a comparator **that produces a usable fit**"; nine have one at all. Fixed at §1.3 with the reason stated, and made consistent in §1.2, §7, §8.5. | §1.3 |
| **R3** — mandatory summary opens "Eight models, eight agreements", which §6.2 forbids | **Closed by deleting the clause**, not by amending the rule. The decomposition was always the substance. §6.2 stands unamended; the choice and its reason are recorded under §6.3. | §6.3 |
| **R4** — F4 "no agreement arithmetic" vs the 1e-5/1e-6 §4.2 permitted itself | **Closed by removing the carve-out.** The self-check is now reported qualitatively with no digits; if the builder wants the figure it goes in the reproducibility script's output. F4 is restated as having no exception, and §14's draft gate says a tolerance figure anywhere in Part 3 fails. | §2.3 F4, §4.3, §14 |
| **R5** — adjacency claim false for `penguins`; free fix available | **Closed by taking the free fix.** Part 3's subsections are swapped: scale-side `sigma` RE (`sleepstudy`) first, `rho12 ~ species` (`penguins`) second. The uniform "two in each case" claim is replaced by the separations the order actually delivers, traced per dataset — `sleepstudy` two comparisons, `penguins` one comparison plus one intervening frontier subsection. §4's order line, §14's build order and every §4.2/§4.3 cross-reference are updated together. | §2.2, §4, §14 |
| **R6** — §4.2 lacked §4.3's "not interval-ready" guard | **Closed.** The `rho12` subsection now carries an explicit no-interval/no-calibration guard with two independent reasons, and quotes `mc-0181`'s "stops short of 'supported'" clause that round 2 elided. It also enforces §15.3's domain question rather than only flagging it. | §4.3 |
| **R7** — §11's sweep misses two live instances in a cited document | **Closed, and one of them fixed in place.** `expressible-vs-comparator.md:110-113` (B2-class) and `:105` (N5-class stale `242:79-80`) are corrected in the source file itself, since it is the upstream import point. Both are added to §11 as rows, along with `candidate-cells.md:97-99`, which quotes the refuted sentence approvingly and was missed. While there I found and fixed a third instance of the same citation defect at `expressible-vs-comparator.md:92` (`242:82` → `:86-87`). | §11, `expressible-vs-comparator.md` |
| **R8** — "extend `ev-mc-0260m-meta-v`'s result" would badge a `mu` cell with a `sigma` result | **Closed, re-derived rather than trusted.** The extension is restricted to **Comparison 2 only** (c04 → `mc-0260m`, `mu`-side). Comparison 3's real-data provenance goes to the vignette and after-task report. Re-derivation: `result` is scanned by package detection (`tools/capability_ledger.py:2328-2333`; doc 242 states the same at `:100-101`), so it is not an inert notes field — which is the fact that makes the mis-attachment real. Rose flags this as inherited from her own D4/D3 pair; that is recorded in the plan rather than passed on silently. | §10.1 |
| **S1** — Noether's own N3 replacement was derived from rounded values | **Closed with this session's measurement.** `:434` and `:1032` now read `1.6e-7` (measured `1.5696e-07`), and "agree to 8 significant figures" is replaced by the two measured absolute differences `1.6e-7` / `3.8e-8` — because "8 figures" is false for `sigma:Days` (relative `4.5e-7`, ≈ 6 figures). c03's batch-1 values `1.1e-6` / `1e-6` are confirmed correct to the digit shown (measured `1.15e-6` / `1.32e-6`). | §3 Comparison 6, §11 |

## 4. Noether's three other re-gate findings, also applied

Not on the brief's list, but they are his findings against the round-2 repair and all three
were confirmed against source before applying.

- **R3 (citation).** `src/drmTMB.cpp:4260` is now the primary citation for the `rho12` guard.
  Verified: `:4260` sits in `} else if (model_type == 2 || 19 || 20)` (`:4254`) and
  `R/drmTMB.R:20456` maps `biv_gaussian = 2L`; `:670` sits in the `95 || 96 || 97` branch
  (`:618`) and `grep -n "95L" R/*.R` returns nothing, so round 2's primary citation pointed
  at unreachable code.
- **R2 (values).** §11's N2 row gave `0.3858209`/`0.6535349` as the "correct" values. Those
  are **plain-`tanh`** — the unguarded link the same table declares wrong. Replaced with the
  response-scale values from §4.3.
- **R4 (scope).** §0's "plain `atanh`/`tanh` … must not appear anywhere" is scoped to the
  `rho12` dpar, with the deliberately unguarded binomial `q = 2` block named
  (`src/drmTMB.cpp:3330`, `R/drmTMB.R:21581`, both verified in place). As written it would
  have invited a future contributor to "correct" a likelihood.

## 5. Rose's five notes, cleared

1. **`mc-0266` field misattribution** — the group-design exclusion is in `claim_boundary`,
   not `next_gate`; both fields are now quoted from `cells.tsv` and the misattribution is
   named as the citation class §11 exists to eliminate. (§4.2)
2. **Two D7 caveats dropped at point of use** — the c01-versus-`ev-mc-0260-external-comparator`
   duplication check and the c06/c07 §10.3 blocker are restored, with the reason the
   enforcement cannot catch a mis-minted c06 row (it checks only that a strength *token* is
   present). (§10.1)
3. **D2's "say it explicitly" had no home** — nominated: PR body and after-task report,
   explicitly *not* the article. (§10.1)
4. **§5's table decomposes joint fits** — footnote added: agreement obtained inside a joint
   fit does not license either submodel in isolation. (§5)
5. **§13's estimate built from disowned timings** — labelled order-of-magnitude, with the
   reason a 40× spread is harmless for a D-139 estimate and fatal for a speed claim. (§13)

## 6. Carried, with reasons

1. **`candidate-cells.md:97-99` is not corrected in this round.** The upstream instance in
   `expressible-vs-comparator.md` is, because that is the file every later document imports
   from; the quotation of it is scheduled in §11 for the build session, and §15.7 says not to
   cite `candidate-cells.md` until it is done.
2. **`sleepstudy` and `penguins` still each appear twice.** Unchanged from round 2; §2.4's
   escalation and build gate remain the answer, and it stays on the maintainer's sign-off
   list.
3. **Class A remains scoped to `DESCRIPTION` `Suggests`, not to CRAN.** Nobody searched
   further, and §8.5 is written so the article cannot imply otherwise. Recorded at §15.8.
4. **Rounds 1–2's untouched sections were not re-audited** — §9, §12, and the c04–c09
   specifications stand as round 2 left them beyond the specific corrections above (§15.9).
5. **Timing stays dropped**, pending §10.4.4.

---

# Round 4 — narrowing

Author: Ada (integrator), 2026-08-15.
Worktree: `.worktrees/phase19`, branch `claude/phase19-comparator-workflows`, off
`origin/main@82cd00560`, drmTMB 0.7.0 (`DESCRIPTION:3`).
Input: `gate3-claims.md` (Rose — NOT-DONE, G-B1/G-B2 blocking, G-S1…G-S6 serious, two notes,
and a Part D recommendation to stop repairing prose).
Decision: **the maintainer approved the auditor's preferred escalation.** The two frontier
demonstration fits are dropped from the article.

**No R was run in this round.** It is a scope narrowing plus prose and citation corrections.
Every number in the plan remains Gauss's, Noether's, or round 3's, cited as theirs — with
round 3's independently reproduced by Rose at gate 3 (`gate3-claims.md:256-269`), which is
now the provenance of record for §11.1 (see G-S2 below).

## 1. Why narrowing rather than a fourth repair round

Rose's Part D measured the pattern rather than the instance. Three rounds, one class of
error:

| Round | Where the false-absence claim was killed | Where it reappeared |
| --- | --- | --- |
| 1 → 2 | `candidate-cells.md:52`, §4.3's wording | Part 3's opening and closing prose, plus two uncorrected source lines |
| 2 → 3 | §4.1, §4.4, F3, §8.3; `expressible-vs-comparator.md`'s class 1 | F2's mandated heading, plus `expressible-vs-comparator.md`'s per-family table — the same file round 3 declared "fixed upstream" |

Each round fixed exactly what the audit named, and the audit named exactly what it found.
The mechanism is structural: **the claim class is open-ended and the enforcement was a
closed blacklist** — §8.5 forbade five strings and grepped the draft article only, so a sixth
string (a mandated section heading) and an instance in a cited source document both walked
through it. A blacklist cannot close an open class.

**What the narrowing does that a fourth repair could not.** The article kept *needing* an
absence claim because it kept showing a frontier model and then having to say what does and
does not exist about it. Remove the demonstrations and the frontier can be stated once,
classified once, and checked once. This is not a better hedge on the claim; it deletes the
surface the claim lives on.

Recorded in the plan at §2.4 as the escalation taken, and at §10.4.5 as signed.

## 2. What was deleted, and what each thing was for

Everything below existed to make two displayed frontier models safe to display.

| Deleted | What it guarded | Audit id |
| --- | --- | --- |
| §4.2 — the whole `sigma = ~ (1 \| Subject)` subsection on `sleepstudy` | — | escalation |
| §4.3 — the whole `rho12 ~ species` subsection on `penguins` | — | escalation |
| F2's mandated heading *"Where drmTMB has no comparator"* | naming Part 3 | **G-B2 (BLOCKING)** |
| F3's *"Two of these four are shown below"* | telling the reader which classes were illustrated | **G-S4** |
| F4's no-agreement-arithmetic rule, its risk surface and its conditional draft gate | keeping Part 2's tolerance figures out of Part 3 | **R4**, now subsumed |
| F5's restart rule and its banned back-references | stopping Part 3 leaning on Part 2's narrative | escalation |
| F6's per-subsection governing ledger cell | stopping an ungoverned drmTMB estimate | escalation |
| F7's per-model non-transfer sentences | stopping Part 2's agreements reading as support | escalation |
| Both interval guards (`mc-0266`, `mc-0181`) | stopping two `interval_feasible` tiers reading as calibrated intervals | **R6**, now moot |
| The `0.506` vs `1.233e-06` matched-scale pairing | a compliant-but-provocative comparison | Rose's note 2 |
| §2.2 consequence 3 and the whole dataset-adjacency calculation | measuring how far apart each frontier model sat from its overlap twin | **R5**, now moot |
| The residual A1 risk itself — `sleepstudy` and `penguins` each appearing twice | — | three rounds named it; none fixed it |

**The two frontier facts are not deleted, and this is the distinction the round turns on.**
The c02 and c10 *runs* survive as the warrant for two classification statements: without the
c02 run, Part 3 could only say scale-side random effects were "not tested" rather than "a
comparator accepts this and did not converge"; without the c10 run, `rho12 ~ x` would be an
untested absence rather than a searched one. §1.2 records them in that role, and §4's rule P3
forbids the article showing any model, dataset, call, warning text or digit from either.

**Also not deleted: the two ledger-cell constraints round 3 discovered.** `mc-0266`'s
`interval_feasible` tier covers 48 groups × 20 observations and not `sleepstudy`'s 18 × 10;
whether `mc-0181` covers a predictor-dependent `rho12 ~ x` is unestablished. Both are true
and will bind any future write-up, so they moved to §15 rather than being dropped with the
subsections they used to constrain.

## 3. The blocking findings

| Finding | Disposition | Where |
| --- | --- | --- |
| **G-B1** — the refuted claim survives unhedged in the file round 3 declared fixed, and four further table rows assert absence with no scope; one is already cited as authority | **Closed at source, and the scope statement is moved so no row can fall outside it again.** Rose offered two fixes; both were applied. (a) The two **false** parentheticals — Gamma's "glmmTMB has no formula for dispersion-as-random-effect" and nbinom2's "fixed dispersion in glmmTMB" — are deleted and marked as false, with `feasibility-batch-1.md:66-73` as the refutation. The four unscoped rows get an explicit class marker each. (b) The claim-class preamble is **moved out of the FRONTIER section to a new document-wide section above the per-family table**, and rescoped from "Nothing below" to the whole document. **Ten rows touched in total** — Rose named six; the same bare "no comparator fits …" phrasing was live in four more (skew_normal, beta, poisson, truncated_nbinom2) and was narrowed to "none known to this survey, and none was tried". | `expressible-vs-comparator.md`; plan §11 |
| **G-B2** — the plan mandates a Part 3 heading its own binding rule forbids | **Closed by retitling, and then by deletion.** Part 3's heading is now *"The frontier: what has no comparator, and what we did not check"* — it states the split rather than asserting one half over a mixed list. Rose noted the enforcement grep could not see this instance because it was a sixth string; that is exactly why the enforcement was replaced (§4 below) rather than extended by one entry. | §2.3, §4 |

## 4. The recurring-class remedy: from a blacklist to a required clause

Rose's structural move 2, adopted verbatim in substance. §8.5 no longer forbids five strings.
It states one rule:

> **No sentence may assert that a comparator is absent unless the same sentence names (a) the
> set that was searched and (b) whether a comparator was actually run against the
> capability.**

Four things changed with it:

1. **It binds every document the PR touches** — the vignette, the PR body, the after-task
   report, doc 158's edits, and every source document §11 corrects — not just the drafted
   article. Round 3's grep read one file; one of the two new instances lived in another.
2. **A heading, a table cell, a footnote, a bullet and a caption are each a sentence** for
   this rule. That closes G-B2's mechanism explicitly rather than by adding its string to a
   list.
3. **It is checked by reading, not by grepping** (§14 step 7). A grep for absence-shaped
   wording is named as a *finding aid* and explicitly not the test — round 3's enforcement
   institutionalised the opposite belief, and a blacklist that passes is what "fixed at the
   named site" felt like for two rounds.
4. **A sentence failing the rule is not re-worded** around a forbidden phrase. It is missing
   evidence, and must acquire it or be downgraded. The three classes (found-nothing /
   fits-and-fails / not-tested) are retained as the way a compliant sentence is built, with
   the standing downgrade direction: when uncertain between A and C, write C.

The same rule is now stated once at the top of `expressible-vs-comparator.md` and binds that
whole document, which is the upstream import point for every later Phase 19 file.

## 5. The remaining serious findings — all live defects the narrowing does not delete

| Finding | Disposition | Where |
| --- | --- | --- |
| **G-S1** — the citation carrying the R1 fix points at one of the four classes, not four | **Closed by changing citation style, not the range.** Round 3 cited `expressible-vs-comparator.md:102-133` four times as "the complete four-class list"; its own edit to that file had moved the classes, and round 4's edits move them again. All four citations now name the **section heading** ("FRONTIER region, summarized"). A line range into a document under active correction cannot be kept true by re-checking harder. | §4.1, §8.3 |
| **G-S2** — §11.1's provenance script does not resolve, and does not cover its own c02 block | **Closed by stating the provenance that actually exists.** `scratchpad/ada-round3-verify.R` is confirmed absent from this worktree and from the repository (`find … -name "ada-round3*"` returns nothing); it lived in an ephemeral session scratchpad and contained no c02 fit. The honest provenance is that **Rose re-fitted every value independently at gate 3 and all reproduced exactly**, output at `gate3-claims.md:256-269` — a committed artifact, unlike the script. §14 step 2 now requires the reproducibility harness to be **committed at a citable path** and to re-emit these values, including the c02 classification check. | §11.1, §14 |
| **G-S3** — §10.4.6 offers a sign-off that reintroduces the repaired claim | **Closed by stating the consequence before asking for the signature.** Doc 242's four-item sentence (`242:86-91`, re-read in place) is an unqualified absence assertion whose **first named item is the one capability where a comparator demonstrably fits**. §10.4.6 now says so, and permits option (b) only with the class split appended. The over-claim in the governing design document is a finding in its own right and is reported upward as new §10.5, plus a note beside the same quotation in `expressible-vs-comparator.md`. | §10.4.6, §10.5 |
| **G-S4** — "two of these four are shown below" is false for the second model | **Deleted with the demonstrations.** Rose's underlying classification point stands and is preserved: `rho12 ~ x` is in class 4's *neighbourhood*, not an instance of it. §8.3 item 3 keeps the distinction. | §4.1 |
| **G-S5** — doc 158's blanket sentence quoted approvingly and not scheduled for repair | **Closed on both halves.** The appeal to doc 158 is dropped from §8.3 item 2 — `feasibility-batch-4.md:52-73` is the real evidence and was already cited — and a **sixth doc 158 edit** is added scoping `docs/design/158-phase-19-comparator-matrix.md:79` (verified in place; quoted identically at `158-plan-of-record.md:58`) to the set actually searched and run. Until that edit lands, no Phase 19 document may cite doc 158 as corroboration for this claim. | §8.3, §10.2 |
| **G-S6** — §5's mandatory footnote names a Comparison 9, which F1 abolished | **Closed.** "Comparisons 6, 7 and 8." The footnote had transcribed build id `c09` as article number 9; `c09` is article number 7. §8.4 already had it right in build ids. | §5 |
| **Note 1** — §4.1 over-claims coverage | **Closed.** "make up most of the rest" → "recur across nearly every family in the rest of it", which is the source's own claim shape (`expressible-vs-comparator.md`: the four classes "recur across nearly every family row"). §1.3's 79% is AGENT-INFERRED and about a different quantity. | §4.1 |
| **Note 2** — the `0.506` vs `1.233e-06` pairing is the first thing a reviewer will challenge | **Deleted with the demonstrations.** | §4.2 (gone) |

## 6. Found while repairing (Rose principle)

Not in the audit; found by walking the neighbours of what the audit named.

1. **Two more instances of the stale-citation class in `expressible-vs-comparator.md`.**
   Round 3 corrected `242:79-80` → `:86-91` at the FRONTIER list head and found a third at
   `:92`. Two survived: the **document header** cited `242:82-84` for credibility-laundering,
   and **"Files consulted"** cited "the credibility-laundering warning at lines 79-84". Both
   ranges are inside the 2026-08-15 amendment about whether an `lme4` point-agreement block
   was withheld from the ledger — verified in place. Both repointed to `:86-91`, with the
   frontier example list at `:87-88` and the independence classifications at `:108-111`.
2. **The Gamma row carried the false claim twice, not once.** Rose named the parenthetical
   "glmmTMB has no formula for dispersion-as-random-effect". The same cell also said "sigma
   is a single fixed dispersion in glmmTMB, not a modelled/RE parameter" — false in exactly
   the same way, in the same sentence. Both deleted.
3. **`feasibility-batch-4.md:126-127` cites the biv_gaussian row by line number**, which
   round 4's edit moves. §11 now schedules repointing it **by row** and adding the scope
   clause; a note in the corrected row itself says the same, so whoever follows the citation
   arrives at the instruction.
4. **§9 and §12 are now two rounds stale.** They were left untouched by rounds 3 and 4, and
   §9's four coupled edits are all line-number-dependent. §14 step 8 now requires
   re-verifying them against the worktree before editing, rather than trusting round 2.
5. **A `Suggests` entry is the PR's only new dependency, and it is not new in substance.**
   `metadat` is required by Comparisons 2 and 3 and is already installed transitively via
   `metafor`'s `Depends`. Stated plainly in §9.3 so the sign-off in §10.4.3 is a small
   decision rather than an open-ended one.
6. **Comparison 4 now carries more weight than it did.** It is the article's only
   *demonstrated* asymmetry — `ordinal::clm(scale = ~ temp)` fits a model drmTMB cannot
   express — and round 3 had two frontier models sharing that job. Its build note says not to
   compress it.

## 7. What round 4 did not fix

Recorded in the plan at §15.

1. **`candidate-cells.md:97-99` is still uncorrected** — it quotes the refuted class-1
   sentence approvingly. Round 3 fixed the upstream file; round 4 fixed that file's table;
   this quotation remains scheduled in §11 for the build session. Do not cite
   `candidate-cells.md` until it is done.
2. **`ordinal`'s independence strength** remains a doc 242 decision (§10.3).
3. **Doc 242's own frontier sentence is over-strong for its first item** and round 4 did not
   amend it — a Phase 19 write-up may not amend a governing design document by side effect.
   Reported upward as §10.5 instead.
4. **Timing** stays dropped, pending §10.4.4.
5. **No cell was re-fitted.** The committed reproducibility harness (§14 step 2) is the build
   session's first task and is what finally replaces §11.1's lost-script provenance.
6. **§9, §12, and the c04–c09 specifications have not been re-audited since round 2.** A
   defect there would now be two rounds old and unfound by anyone.

---

# Round 5 — structural

Author: Ada (integrator), 2026-08-15.
Worktree: `.worktrees/phase19`, branch `claude/phase19-comparator-workflows`, off
`origin/main@82cd00560`, drmTMB 0.7.0 (`DESCRIPTION:3`).
Input: `gate4-claims.md` (Rose — NOT-DONE, G4-B1…G4-B4 blocking, G4-S1…G4-S5 serious, plus
one structural recommendation).
Decisions: **the maintainer took a second escalation** — the reader article makes presence
claims only, and the "what has no comparator" narrative is cut from it entirely.

**One measurement was run this round, and it is not a fit.** The installed status of the
eight non-`Suggests` packages this survey names, via `system.file(package = ...)`:

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e \
  'for (p in c("gamlss","sn","VGAM","cplm","brms","MCMCglmm","betareg","metadat"))
     cat(p, ifelse(nzchar(system.file(package = p)), "INSTALLED", "ABSENT"), "\n")'
```

Result: `gamlss` **ABSENT**, `sn` **ABSENT**, `cplm` **ABSENT**; `VGAM`, `brms`, `MCMCglmm`,
`betareg`, `metadat` installed. Recorded in full in `expressible-vs-comparator.md`. It is the
evidence for G4-S1 and it is the reason six presence claims in that file were wrong rather
than merely unscoped. No model was fitted; every number in the plan remains Gauss's,
Noether's or round 3's, cited as theirs.

Also verified mechanically, since the fix is structural and a structural fix has to be
checked structurally: the rewritten per-family table has **17 data rows, 8 cells each, and no
empty or dash-only cell** (parsed from the file with a short R script, not read by eye).

## 0. What "structural" means here, and why round 5 is not round 4 again

Rose's Part D is the finding that matters: four rounds, one class of defect, and the round
that finally held the *right rule* still executed the *wrong sweep*. Round 4 adopted a
required-clause rule that says a grep "is explicitly not the test", and then closed its own
sweep by searching for the phrase `"no comparator fits …"`. Ten rows matched. Three rows that
asserted absence with nothing but a bolded token did not match, because **a phrase search
cannot see a claim made without a phrase**. Neither did the definition of the token itself.

So round 5's test for every change below is: *does this change what a future careless sweep
would find, or does it change what is there to be found?* Only the second counts. Each entry
below states what changed structurally; where a string also changed, that is a consequence,
not the fix.

| Round | Enforcement in force | How the sweep ran | What survived |
| --- | --- | --- | --- |
| 1 → 2 | none | fix what the audit named | Part 3's prose; two source lines |
| 2 → 3 | 5-string blacklist, grepped over the article | fix what the audit named | a sixth string; a whole per-family table in a cited source |
| 3 → 4 | required-clause rule, all documents, "checked by reading" | searched for one phrase; ten rows touched | three rows carrying the bare token; the term's own definition; the replacement heading |
| 4 → 5 | **the rule, plus a table shape that makes incompleteness visible, plus removal of the claim class from the deliverable** | **enumerated all 17 rows and all article-facing sections; verified the table's shape with a script** | to be measured at gate 5 |

## 1. G4-B1 [BLOCKING] — the term was redefined, not its instances

**What was wrong.** `expressible-vs-comparator.md:5-7` defined FRONTIER as "the region where
none can [fit the same model]". That is an unqualified class-A assertion, and it is the first
definition a reader meets. All fifteen uses of the token in the per-family table, and the four
frontier classes below it, inherited it. Round 4 corrected ten instances and left the
definition untouched, 88 lines above the note meant to weaken it.

**The structural change.** The **term is redefined**, so every use is scoped at the point of
definition rather than rescued at the point of use:

> FRONTIER — the region where **this survey found no comparator in the set it searched
> (`DESCRIPTION` `Suggests`), having in most rows searched that set by reading package
> documentation rather than by running anything**.

Three properties, each load-bearing:

1. **It names the searched set inside the definition**, so a downstream use of the token
   carries the set with it and cannot be quoted into a stronger claim by omission.
2. **It names the run status**, which is the second required clause. The definition sentence
   therefore satisfies the rule stated 65 lines below it — round 4's did not, which was the
   finding.
3. **It never says CRAN**, because CRAN was never searched. The old definition implied a
   universal quantifier over implementations; the new one quantifies over 25 named packages.

OVERLAP is redefined in the same breath and for the same reason: it now says a package *in
that set* fits the model, and whether the fit was executed or inferred from documentation.

**What did not change.** No frontier verdict was withdrawn. The classification is the same;
what changed is what the word means, which is what fifteen cells were relying on.

## 2. G4-B2 [BLOCKING] + the structural recommendation — three columns, seventeen rows, filled by enumeration

**What was wrong.** Rows `:114` (`student()`), `:118` (`tweedie()`) and `:126`
(`cumulative_logit()`) asserted FRONTIER with a bare bolded token, no class marker, no
searched set, no run status. They were invisible to four consecutive phrase-searches because
they contain no phrase.

**The structural change, and it is the centre of this round.** The per-family table gains
three dedicated columns — **claim class (A/B/C)** · **set searched** · **actually run?** —
and every one of the **seventeen** rows was filled by **enumerating all seventeen**. Not by
searching for a phrase; not by fixing three exceptions. The three rows Rose named were filled
as rows 2, 6 and 14 of an enumeration, and nothing about them was treated as special.

**Why this closes the class rather than the instance.** The rule stops being something a
reader must remember to apply and becomes something the table's shape enforces:

- An **empty cell is a defect on sight**, to anyone, with no sweep. The check "does every row
  carry its clauses" becomes "is any cell blank", which a script can answer — and one did:
  17 rows × 8 cells, zero empty.
- The columns are **claim-shaped, not prose-shaped**, so a row cannot assert absence "without
  a phrase". There is no way to write the row that skips the question.
- **Incompleteness is visible before it is load-bearing.** The previous failure mode was a
  cell that read fine and said nothing; the new one cannot read fine while saying nothing.

**What the enumeration turned up that no sweep would have.** Filling "actually run?" honestly
required attributing all eleven Phase 19 comparator executions to family rows, which had never
been done in one place. The result: **eleven of seventeen rows had no comparator executed for
them at all**, six had one on their overlap half only, and **exactly one cell in the whole
table is class A** — and only within `Suggests`. That distribution is the document's real
epistemic state and it was previously reconstructible only by reading four feasibility batches
side by side. It is now a column.

## 3. G4-B3 [BLOCKING] — the blanket default is deleted, because the columns leave nothing for it to repair

**What was wrong.** `:95-97` instructed the reader to "read every FRONTIER verdict below that
carries no explicit class marker as class C". Two defects, and the second is the serious one:
it contradicted the rule 25 lines above it (which requires the clause *in the sentence*), and
it was **a prose caveat repairing table cells** — the precise pattern `PR2-build-plan.md:771`
forbids at source ("**No prose caveat elsewhere repairs a summary table**") and §5 rule 4
repeats for the article's own table.

**The structural change.** Deleted outright, and replaced by a **column contract**: every row
carries its own markers, all three columns must be non-empty in all seventeen rows, and an
empty cell is a visible defect. There is no default because there is nothing left for a
default to cover.

**Why deletion and not rewording.** The default's practical effect was to make unmarked rows
*feel safe*, which is why nobody went looking for unmarked rows — Rose's "the practical proof
is G4-B2". A rule of the form "anything I missed is class C" guarantees the next sweep is also
partial, because it converts an unknown into a benign default without anyone noticing the
unknown. Any replacement default would do the same. The columns are the alternative: they make
the unknown *look* unknown.

## 4. G4-S1 [SERIOUS] — the rule is now two-way, and the presence claims were measured

**What was wrong.** §8.5 constrained only sentences asserting a comparator is *absent*.
Sentences asserting one *exists* were ungoverned, and `expressible-vs-comparator.md` was full
of them: `:136-138` said `lme4`, `glmmTMB`, `ordinal`, `VGAM`, `sn` and `gamlss` "fit
statistically equivalent models and can serve as an oracle"; `:114` named `gamlss` and `brms`
for Student-t; `:115` said "`sn` fits fixed-effect only, no RE"; `:118` named `cplm`; `:119`
and `:121` named `gamlss` and `VGAM`.

**The structural change, in two parts.**

1. **§8.5 is made symmetric.** A sentence asserting a comparator *fits* must name the package
   and whether it was run, exactly as an absence claim must name the set and the run. The
   asymmetry was not an oversight in enforcement; it was a hole in the rule, and a rule with a
   hole gets swept along the side that is governed.
2. **The claim was replaced by a measurement.** Rather than hedge six sentences, the file now
   carries an **installed-status table with the command that produced it**. `gamlss`, `sn` and
   `cplm` are **not installed on this machine**; `VGAM`, `brms` and `MCMCglmm` are installed,
   outside `Suggests`, and were never run. One sentence had been telling readers that `gamlss`
   "can serve as an oracle" for a package that cannot be loaded here.

**Why this is the same defect and not a second one.** An unverified presence claim moves the
overlap/frontier boundary in the *other* direction: it advertises a check nobody performed and
**shrinks the apparent frontier**. Doc 242's concern is that the two regions not be blurred,
and a wrongly-placed boundary blurs them whichever way the error runs. The OVERLAP summary is
now split three ways — demonstrated by an executed fit, asserted from documentation, asserted
from documentation of a package that is not installed — which is the same A/B/C move applied
to presence.

## 5. G4-B4 [BLOCKING] + the maintainer's scope decision — Part 3 leaves the article

**What was wrong.** Round 4's mandated Part 3 heading, *"The frontier: what has no comparator,
and what we did not check"*, failed twice: it named no searched set (§8.5 says a heading is a
sentence), and its first conjunct had **no referent in the section it titled** — class 1 is B,
classes 2–4 and the tail are C, so no Part 3 item was class A. The heading was refuted by its
own contents. This was G-B2 recurring *inside its own fix*, one round later.

**The structural change, which is larger than the finding.** The finding asks for a retitle.
The maintainer's decision removes the section: **the article makes presence claims only, and
the frontier narrative is cut from it entirely** (`PR2-build-plan.md` §2.5). Both were done:

- **§4 is retitled** to "The frontier classification — what we checked, what we did not, and
  where it now lives", which asserts no absence and therefore needs no clause, and
  **repurposed** from an article specification into a plan record.
- **The article's Part 3 is deleted.** §2.1 is now a two-part shape ending on §6.3's scope
  summary. Round 4's P1–P5 are retired with the section they governed, each recorded with what
  it guarded, and replaced by a single rule, **A1**: *no sentence in the vignette may assert,
  imply, or classify the absence of a comparator for any capability.*

**Why removing the section is structural and retitling alone is not.** The recurring defect
needs a habitat: a sentence in a reader document that classifies the comparator landscape.
Rounds 2, 3 and 4 governed that sentence with a disclaimer, a blacklist, and a required-clause
rule. Each was an improvement; each was applied by a sweep that missed something; and the
fourth failed **in the replacement text produced by the third**. Removing the habitat from the
deliverable is the move that does not depend on the next sweep being better than the last
four. What remains governed by §8.5 is a bounded set of design and planning documents — which
now have a structural check of their own (§2 above).

**What it cost, recorded because it is real.** A reader of the vignette alone will not learn
from it that most of drmTMB's implemented surface has no comparator. Two partial
compensations, neither equivalent: §1.3's composition disclosure (these eight were *selected*
for comparability) and Comparison 4's demonstrated asymmetry in the comparator's favour
(`ordinal::clm(scale = ~ temp)` fits a model drmTMB rejects). Recorded in §2.5, in §10.4 item 5a as
a signed decision, in §15.10 as a live limitation, and required in the PR body — four places,
so a later session cannot read the omission as an oversight and restore Part 3 as a
"correction".

**The two claims that had to be re-homed, not deleted.** §1.3's *"most of drmTMB's implemented
surface cannot be [compared]"* and §8.2's closing clause were absence claims sitting in the two
paragraphs the article cannot drop. Both were **rewritten as claims about this article's
coverage** — what was compared here, against a named set — rather than about what exists
elsewhere. That distinction is what makes the opening and the boundary paragraph sayable at
all under A1.

## 6. G4-S2 … G4-S5 — the four serious findings

| Finding | What changed structurally | Where |
| --- | --- | --- |
| **G4-S2** — the "also frontier" tail's second conjunct is bare in the source and scoped in the plan | The source is brought up to the plan's standard rather than the plan down to the source's. Both conjuncts of `expressible-vs-comparator.md`'s tail now carry "`Suggests` read, nothing beyond it searched, nothing run". The general principle, stated so it is not re-litigated: **when a plan and its cited source disagree about scope, the source is the defect** — the plan cites it, so a reader following the citation lands on the weaker claim. | `expressible-vs-comparator.md`, "Also frontier"; `PR2-build-plan.md:734-736` unchanged |
| **G4-S3** — `feasibility-batch-4.md:126-127` scheduled for repair but not quarantined | Added to the do-not-cite list as **§15.9**, matching the treatment `candidate-cells.md` already had. The asymmetry was the finding: two files carry an uncorrected absence claim, one is quarantined, one is not, and the unquarantined one is an invitation. Nothing live cites it today (measured at gate 4: both references are inside §11's correction tables); the quarantine closes the gap before something does. | `PR2-build-plan.md` §15.9, §11 |
| **G4-S4** — §14 step 2 lets the classification checks' output into an article chunk | The sentence now reads "written from this script's **eight-comparison** output; the two classification checks are recorded in the script and quoted nowhere in the article". This is a genuine one-sentence fix and is labelled as such — it was an ambiguity in a build instruction, not an open claim class, and it sat exactly where a builder would read it. | `PR2-build-plan.md` §14 step 2 |
| **G4-S5** — §4.2's builder prohibitions were written for Part 3 and did not bind §5's coverage table in Part 1 | Two changes. (a) The coverage table's status column is **renamed from "Comparator status" to "Compared in this article?"**, and every cell answers only that; a row with no comparison says "not compared here", which asserts nothing about the world and needs no clause because it makes no claim requiring one. (b) **New §5 rule 5** binds the column to §4.2's prohibitions explicitly — no dataset name, no verbatim message, no variance, no number from an unshown run. Rule 4's requirement that the searched-set clause survive compression into a cell is superseded: round 5 removes the claim that needed the clause. | `PR2-build-plan.md` §5 |

## 7. Found while repairing (Rose principle)

Not in the audit; found by walking the neighbours of what the audit named.

1. **The eleven comparator executions had never been listed in one place.** Filling the
   "actually run?" column required it. Two of the eleven are *rejections* rather than
   agreements (`ordinal::clm(scale = ~ temp)` fitting a model drmTMB refuses;
   `glmmTMB(cbind(...))` refusing a two-column response), which is why "eleven executions" and
   "eight comparisons" are both correct and easy to confuse. The table states the difference.
2. **`gamlss` was cited as an oracle six ways from a package that will not load.** The audit
   named the `:136-138` instance; the installed-status measurement showed `sn` and `cplm` are
   in the same state, and that `VGAM`, `brms` and `MCMCglmm` are installed — so "not installed"
   was never the reason they went unrun, which weakens the excuse and strengthens the class-C
   marking.
3. **§4.3's deleted closing draft contained the defect it warned against.** Its own note said
   the failure mode is "a closing sentence that reaches for a clean line and merges the claims
   back together" — and the draft's second sentence read *"Most of them do not"*, an unscoped
   absence claim, immediately after. That is the strongest single argument for §2.5 that this
   round produced, and it came from re-reading text that was already scheduled for deletion.
   Recorded in §4.3 rather than dropped silently.
4. **The `student()` row failed in both directions at once.** Its frontier half had no clause
   (G4-B2) and its overlap half named two packages neither of which was run, one absent from
   this machine (G4-S1). A row can be wrong on both sides of a one-way rule, which is a
   compact argument for making the rule two-way.
5. **§14 step 5 is now a numbered gap, not a renumbering.** "There is no step 5. Part 3 is not
   drafted." A session working from an older copy of the plan will notice a missing step;
   silent renumbering would let it draft a section this plan deliberately dropped.
6. **§15 gained item 10**, recording that the frontier record now lives only in documents with
   no reader, and naming the condition under which it should return: a wider search that makes
   the claim supportable on evidence rather than assertion.

## 8. What round 5 did not fix

Recorded in the plan at §15, and repeated here in short.

1. **`candidate-cells.md:97-99`** still quotes the refuted class-1 sentence approvingly, and
   the file stays on the do-not-cite list. Four rounds have now scheduled this repair for the
   build session.
2. **`ordinal`'s independence strength** remains a doc 242 decision (§10.3).
3. **Doc 242's own frontier sentence over-claims for its first item** and round 5 did not amend
   it — a Phase 19 write-up may not amend a governing design document by side effect. Reported
   upward as §10.5, now with the note that the same "no established implementation exists"
   shape is exactly what G4-B1 found in `expressible-vs-comparator.md`'s definition. The
   governing document has the defect its dependents keep being audited for.
4. **`feasibility-batch-4.md:126-127`** is quarantined, not repaired (§15.9).
5. **No cell was re-fitted**, in this round or the last two. The committed reproducibility
   harness (§14 step 2) remains the build session's first task.
6. **§9, §12 and the c04–c09 specifications are now three rounds unaudited** (§15.7, §15.8).
   A defect there would be older than every finding this changelog records.

---

# Round 6 — serious closeout

Author: Ada (integrator), 2026-08-15.
Worktree: `.worktrees/phase19`, branch `claude/phase19-comparator-workflows`, off
`origin/main@82cd00560`, drmTMB 0.7.0.
Input: `gate5-claims.md` (Rose — NOT-DONE, one blocking G5-B1, five serious G5-S1…G5-S5).
Scope: **G5-B1 was closed before this round** (the two Reader's conclusions now describe a
*model's* limitation rather than a named package's incapacity, and §14 step 6 mandates
enumerating all eight conclusions). This round applies the five serious findings only. The
auditor stated they are one- or two-line fixes and that no sixth audit round should be held
for them.

**One measurement was run this round, and it is not a fit.** The `rho12` link, read directly
out of the C++ template:

```sh
sed -n '670p;4260p' src/drmTMB.cpp
#   vector<Type> rho12 = Type(0.999999) * tanh(eta_rho12);   (both lines, byte-identical)
```

That is the evidence for the second half of G5-S1. Verified structurally, since two of the
five fixes are structural: the per-family table still has **17 data rows, 8 cells each, no
empty or dash-only cell**, re-parsed with a script after the edits, and **15 of 17 claim-class
cells now carry an A/B/C letter** (was 13).

**One discipline governs every entry below: each target was located by its CONTENT, never by
the line number the audit quoted.** The plan had just been edited when `gate5-claims.md` was
written, so every line reference in it had already shifted. Citing a stale range is the defect
that has now recurred three times in this phase — and G5-S1 is that defect found *inside its
own fix*. Nothing below is recorded by line number as an identifier.

## 1. G5-S1 [SERIOUS] — the quarantine now names the claim, not a range; and a second `atanh` sentence is scheduled

**What I located.** The defective sentence in `feasibility-batch-4.md` is the
**`biv_gaussian()`/`rho12` FRONTIER verdict**, in its *"3/4. Matched scale + verdict"*
section, opening:

> **Verdict: UNCERTAIN**, unchanged from the pre-filled cell, and for the same reason:
> `expressible-vs-comparator.md:79` classes formula-capable `biv_gaussian()` `rho12` as
> FRONTIER — expressible by drmTMB but with no comparator to check it against

That sentence asserts an absence with no searched set and no run status, and cites a line
number that rounds 4 and 5 both moved. The range round 5 quarantined instead is innocuous:
it is prose about the fit converging and about the `Suggests` check being made rather than
assumed. A builder opening it finds nothing wrong and concludes the quarantine is spurious or
already discharged — which is exactly what the auditor predicted.

**What changed, in four places, all keyed to the claim:**

1. **§15.9 (the quarantine itself)** — rewritten to quarantine the verdict sentence, quoted by
   its opening words, with an explicit instruction to locate it by that quotation and never by
   line, and a note that round 5 named the wrong target.
2. **§11's correction row** — the row's subject column is now the claim (section + quoted
   opening) rather than a range, and records that round 5 named `:126-127` and what that range
   actually contains.
3. **§11's round-5 change table** — the row recording the quarantine's addition now names the
   verdict rather than the range.
4. **§11's `G-B1` row for the per-family table** — it said the `biv_gaussian()` row was
   "already cited as authority by `feasibility-batch-4.md:126-127`". The citing sentence is
   the verdict, not that range; corrected to name the claim.
5. **`expressible-vs-comparator.md`'s R11 citation note** — same substitution, plus the
   record of what round 5 got wrong and why the quarantine is now claim-shaped.

**The second half of the finding — the `rho12` link.** `feasibility-batch-4.md` states the
link as plain `atanh`/`tanh` in **two** sentences, and §11 had scheduled only the first. The
second is clause **(c)** of the same verdict paragraph — *"the internal `rho12` link is
`atanh`/`tanh`, so any reader comparing raw coefficients to a correlation must transform
first"*. The true link is **`rho12 = 0.999999 * tanh(eta_rho12)`**, verified above at
`src/drmTMB.cpp:670` and `:4260`. A new §11 row schedules it, identified by its "(c)" clause,
and requires both sentences to be repaired in the same edit — repairing only the first leaves
the file still asserting the wrong link.

**One thing I did not change, and why.** §15's round-5 provenance list records the source
ranges Rose *re-read in place* during rounds 4 and 5, `feasibility-batch-4.md:52-73` and
`:126-127` among them. That is a record of what an auditor read on a given date, not an
identifier of a defect or an appeal to authority. Rewriting it would misstate the round-5
record rather than repair it.

## 2. G5-S2 [SERIOUS] — three unclaused assertions of the sentence §1.3 removed from the article

**What I located.** Three instances of the sentence shape *"most of drmTMB's implemented
surface has no comparator"*, asserted with no searched set and no run status:

| Where (by content) | How it read |
| --- | --- |
| §2.5's **"What this costs, stated plainly"** paragraph | "A reader of the vignette alone will not learn from it that most of drmTMB's implemented surface has no comparator. **That fact is true**, it matters…" |
| §10.4 **item 5a**, the signed article-scope decision | "…a reader of the vignette alone will not learn from it that most of drmTMB's implemented surface has no comparator" |
| §15 **item 10**, "the frontier record now lives in documents with no reader" | "…the fact that most of drmTMB's implemented surface has no comparator is now reachable only by a reader who follows a pointer" |

This is the precise sentence §1.3 rewrote out of the article, for the precise reason that it
is an absence claim about drmTMB's whole surface with no search behind it. The plan asserted
it three times while removing it, and one instance called it established fact.

**What changed.** All three rescoped to the same replacement: *"…was not compared against any
package in `DESCRIPTION` `Suggests`, and nothing beyond that set was searched."* Each carries
a round-6 marker so a later session does not read the longer sentence as padding and revert
it.

**Checked and deliberately left alone:** §8.2 contains *"It does **not** say the rest of the
surface has no comparator, that nothing else fits it…"*. That is a prohibition on making the
claim, not the claim. Rescoping it would invert its meaning.

## 3. G5-S3 [SERIOUS] — §8.3's heading, and its stale item 3

**What I located.** The heading **"8.3 What has no *working* comparator — explicit
statement"**. §8.5 counts a section heading as a sentence; this one names no searched set and
no run status, and it is refuted by its own body — item 1 of the section says a comparator
exists and was run. It is the same defect §4's title was retitled for at round 5 (G4-B4), left
in place because the two sections were not read together.

Its **item 3** opened *"The wider frontier the article names without demonstrating"*. After
§2.5 the article names nothing; the lead-in described a Part 3 that no longer exists.

**What changed.** Retitled to **"8.3 Comparator status per capability — searched, run, and
what that supports"**, which asserts no absence and so needs no clause, with a short retitle
note in the §4 house style recording what the old title claimed and why it failed. Item 3
re-led as **"The wider frontier, recorded in this plan only"**, with the superseded lead-in
quoted so the change is visible rather than silent.

**Checked:** every cross-reference to this section elsewhere in the plan cites it as "§8.3",
by number, never by title — so the retitle breaks no inbound reference.

## 4. G5-S4 [SERIOUS] — two determinate claim classes written, and the letterless cell governed

**What I located.** In `expressible-vs-comparator.md`'s per-family table, four claim-class
cells carried no A/B/C letter although the column is titled "Claim class (A/B/C)". Two are
determinate **C** by the document's own definition — *"a comparator may fit; it was not
checked"*:

| Row | Cell read | Why C |
| --- | --- | --- |
| `beta_binomial()` | "No absence claim in this row… The presence half is **unrun documentation**" | The row does claim `glmmTMB(family=betabinomial)` fits, unrun |
| `biv_lognormal()` | "No absence claim in this row. The presence half is an **unrun inference**" | Same, and weaker than C's usual warrant — no package is even named |

**What changed.** **C** written in both, existing clauses kept and extended by the reason.
`binomial()` and `biv_student()` left letterless, as the auditor directed.

**The column contract gained one line**, so an empty cell stays visibly wrong: a letter is
required whenever the row makes a claim of either kind, and the one permitted letterless cell
is a row that makes **no claim of either kind** and says so — `biv_student()`. The line also
records that `binomial()` is letterless on a different, narrower ground the auditor examined
and passed: its presence claim is neither absent nor unverified but **demonstrated by an
executed, agreeing `lme4::glmer` fit**, the one status A/B/C was not built to letter. Naming
that second shape explicitly is the difference between a contract a future session can apply
and one it must interpret; leaving it implicit would have made the `binomial()` row read as a
violation of the rule I had just written.

**Verified after the edit:** 17 rows, 8 cells each, no empty or dash-only cell, and the two
repaired cells carry their letter in the claim-class column and not in a neighbour.

## 5. G5-S5 [SERIOUS] — the 79% / 21% figures are marked plan-side and barred from the article

**What I located.** §1.3, under the heading **"Composition disclosure, mandatory in the
article's opening"**: *"268 of 341 implemented cells (79%) sitting in or beside the frontier,
leaving at most ~21% comparator-eligible"*. "At most ~21% comparator-eligible" is an absence
claim about the other 79%, expressed as a number, in the section a builder reads while
drafting the article's opening. The compliant replacement below it is introduced with
"instead", which scopes it — but §5 got an **explicit** prohibition on smuggling a verdict
into a cell (rule 4) where §1.3 had only an implication.

**What changed.** One paragraph added directly after the figures: the 79% / 21% numbers are
this plan's own AGENT-INFERRED derivation, **no percentage appears in the article**, and the
article carries the bold sentence below and nothing else from that paragraph. §1.3 now has the
belt §5 already had.

## 6. What round 6 did not fix

Unchanged from round 5's list, and none of it is in scope for a serious-findings pass.

1. **`candidate-cells.md:97-99`** still quotes the refuted class-1 sentence approvingly and
   stays on the do-not-cite list. Five rounds have now scheduled this for the build session.
2. **`feasibility-batch-4.md` is quarantined, not repaired.** Round 6 corrected *what* the
   quarantine names; the source file itself is still the build session's edit, now with two
   `atanh` sentences scheduled instead of one.
3. **Doc 242's own frontier sentence over-claims** and remains reported upward (§10.5), not
   amended by side effect.
4. **No cell was re-fitted**, in this round or the previous three. The committed
   reproducibility harness (§14 step 2) remains the build session's first task.
5. **§9, §12 and the c04–c09 specifications are now four rounds unaudited.** `gate5-claims.md`
   names this as the oldest unfound thing in the phase, and this round did not touch it.

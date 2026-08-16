# Phase 19 re-gate — adversarial re-audit of the repaired PR 2 build plan

Author: Rose (`systems_auditor`), fresh re-review, 2026-08-14.
Worktree: `.worktrees/external-oracle`, branch `claude/external-oracle-intervals`,
HEAD `4530fd71a` (`git log --oneline -1`), drmTMB 0.7.0 (`DESCRIPTION:3`).
Reader: the maintainer deciding whether PR 2 may be built from
`docs/dev-log/external-oracle/phase19/PR2-build-plan.md`, and the session that would build it.

Audited in full: `PR2-build-plan.md` (1,189 lines), my own prior
`adversarial-claims.md`, `docs/design/242-external-comparator-evidence-class.md` (134
lines, including the 2026-08-15 amendment at `:53-84`), plus `plan-repair-changelog.md`,
`expressible-vs-comparator.md`, `candidate-cells.md`, and the four feasibility batches at
the lines the plan cites. Source facts re-verified in place, not taken from the plan:
`src/drmTMB.cpp:670`, `R/family.R:13-15,:34,:415-418`, `DESCRIPTION` `Suggests`,
`cells.tsv` rows `mc-0181`/`mc-0266`, `tools/check-reader-contracts.R`,
`tools/capability_ledger.py`, `tools/tests/test_capability_ledger.py`,
`tests/testthat/test-reader-vignette-contracts.R:224`.

---

## Overall verdict: NOT-DONE — one blocking finding, seven serious.

This is a substantially better document than the one I audited. Six of my eight blocking
findings are genuinely closed, several of them by structural remedies stronger than the
ones I proposed, and every line reference the plan re-verified checks out against the
files (§ "What the repair got right"). The verdict is NOT-DONE for a narrow reason: the
restructure that fixes A1 introduced a **new** home for the exact false claim B2 killed,
and it put it in the two most load-bearing sentences of the new Part 3 — its opening
framing and the article's final paragraph.

That is the Rose principle biting the repair itself. B2 was fixed at the site I named and
reappeared at two sites I had not, plus two uncorrected sites in the source documents the
article will cite.

---

## Part A — verdict on each of my eight prior BLOCKING findings

| Prior | Finding | Verdict now |
| --- | --- | --- |
| A1 | Frontier cell adjacent to an agreeing overlap cell on the same dataset | **CLOSED** (with a new arithmetic defect, R5) |
| B1 | Sample composition inverts the package (80% vs ≤21%) | **CLOSED** |
| B2 | False non-existence claim ("no comparator can fit this") | **STILL-OPEN** — fixed at the named site, reopened at four others |
| C1 | Single-run wall times are noise | **CLOSED** |
| C2 | Documents disagree with each other on the same fits | **CLOSED** |
| D1 | Cell 5's conclusion contradicts `mc-0260m`'s recorded boundary | **CLOSED** |
| D2 | Frontier models must carry no row and not be framed as "withheld" | **CLOSED** (one loose end, R-note 3) |
| D8 | `metadat` undeclared, and the "no new dependency" claim is false | **CLOSED** |

### A1 — CLOSED

I asked for *either* separation of the frontier cells *or* a per-cell non-transfer
sentence. The plan does both and adds four more layers. Evidence in the current file:

- Frontier models lose their number and their `c0x` label (`PR2-build-plan.md:149-151`,
  F1); Part 2 items are "Comparison 1"…"Comparison 8", Part 3's are named subsections.
- Part 2 is reordered by independence strength (`:119-123`), so the reading order is c08,
  c04, c05, c06, c07, c01, c09, c03 and the last dataset before the register is `Owls`.
- Part 2 is closed by an explicit scope summary before Part 3 opens (`:152-155`, F2;
  draft at `:730-738`).
- No agreement arithmetic in the register (`:159-161`, F4); each subsection restarts its
  dataset and question with named banned phrasings (`:162-165`, F5).
- The non-transfer sentence survives, moved *before* the numbers (`:169-171`, F7; drafts
  at `:556-559` and `:620-625`), and it names the capability rather than "Comparison 6",
  which is the stronger form.
- §2.4 (`:176-198`) records the two rejected alternatives, keeps "drop the frontier fits
  entirely" open as an escalation, names the residual risk, and sets a draft-review build
  gate. §15.1 (`:1173-1175`) repeats it. That is the honest disclosure I asked for.

The residual — `sleepstudy` and `penguins` each still appear twice — is stated by the
plan itself and escalated to the maintainer (`:1012-1014`). I accept that as closed. See
R5 for a defect *inside* this fix.

### B1 — CLOSED

`:76-86` makes the composition disclosure mandatory in the article's opening, carries the
268/341 (79%) figure with my AGENT-INFERRED marking preserved verbatim, and states the
required sentence: "these models were chosen because they can be compared, and most of
drmTMB's implemented surface cannot." `:687` carries the same fact as a coverage-table
row ("The rest of the implemented model surface (~79% …)"), and `:810` repeats it in the
boundary paragraph. `:812-813` explicitly fixes the count at **eight**, not ten. This is
more than I asked for.

### B2 — STILL-OPEN

Fixed where I pointed:

- `:1027` schedules the correction of `candidate-cells.md:52` ("No comparator can fit the
  same thing | 2, 10") — verified still uncorrected in the source at `candidate-cells.md:52`.
- `:626-632` mandates the exact supportable wording for §4.3 and bans "no package can
  express this" by name.
- `:685` gives the coverage table an honest frontier row: "no working comparator:
  `glmmTMB` accepts the syntax and returns a degenerate fit on the one dataset tested".

Reopened elsewhere — see **R1** (two new sites in the plan's own drafted article prose)
and **R7** (two uncorrected sites in documents the article cites). Because the new sites
are drafted article text rather than survey scaffolding, the claim is now closer to a
reader than it was when I first found it. STILL-OPEN.

### C1, C2 — CLOSED

Timing is dropped as a claim (`:38`, `:768`, `:1087-1104`). The reasons are recorded with
the numbers: the 40× spread on c09's five reps, the 18×/1.5× inter-document disagreement,
the falsified "<1 s" bound, the post-hoc timer scope, and the source-vs-installed build
asymmetry. `:1099-1104` states that this does **not** literally satisfy #60's "timing
summaries" and routes it to maintainer sign-off (§10.4.4) instead of quietly dropping it.
That is the right handling of a Definition-of-Done conflict. C3, C4, C5 fall with it —
C5's seed answer is given explicitly at `:1077-1082` rather than left silent, exactly as
asked.

### D1 — CLOSED

`:317-330` rewrites Comparison 3's reader conclusion, quotes `ev-mc-0260m-meta-v`'s
boundary, notes the `alternate` level's **two** studies against the recorded K=12 regime,
and ships a replacement sentence that keeps the point agreement and drops the comparative
heterogeneity finding. `:767` records the rejected claim in the rejected-cells table so
nobody re-derives it. `:1030` schedules the correction of `candidate-cells.md:172-174`.
This was the finding I flagged as "not a wording fix"; it was answered as one, correctly.

### D2 — CLOSED

`:945-948` carries the three-state distinction (licensable-and-recorded,
licensable-but-withheld, nothing-to-record) and states that these are the third. `:38` and
`:1007` recommend zero rows with maintainer sign-off. The drafted article never says "no
ledger row was added", so the inference I was worried about has no surface. One loose end
at R-note 3.

### D8 — CLOSED

`metadat` is confirmed absent from `Suggests` (re-verified: the list is `ape, callr,
detectseparation, emmeans, extraDistr, fmesher, glmmTMB, ggplot2, JuliaCall, knitr, lme4,
MASS, metafor, mvtnorm, numDeriv, ordinal, palmerpenguins, pkgload, rmarkdown, sf,
spelling, statmod, testthat, tweedie, withr` — no `metadat`, no `betareg`). `:926-935`
makes `DESCRIPTION` a fifth coupled edit, `:1028` schedules the correction of
`candidate-cells.md:15-17`, `:1071` records `metadat 1.6.0` in the environment block, and
`:1009` routes it to sign-off. Complete.

---

## Part B — the serious and note findings

| Prior | Verdict now | Evidence |
| --- | --- | --- |
| A2 (merged coverage row) | **CLOSED** | §5 (`:669-696`) splits the row into fixed-effect and random-effect halves, forbids a total row, and forbids a frontier row citing a Part 3 subsection. `:1029` schedules the same split in `candidate-cells.md:48`. |
| A3 (WEAK independence undisclosed) | **CLOSED, and sharpened** | §6 (`:700-751`): structural sectioning, a grep-enforceable vocabulary table, mandatory block-opening sentences, inline tagging. `:740-746` refines my own loose phrasing about c05 correctly — `sqrt(v_known + sigma^2)` makes it a `sigma`-side predictor that is not a residual scale. I accept the correction. |
| A4 (Cell 2 sourced to `mc-0266`) | **CLOSED** | F6 (`:166-168`) and §4.3 (`:608-619`). |
| B3 (keep Cell 6 prominent) | **CLOSED** | `:358-367` makes the `ordinal::clm(scale = ~ temp)` boundary a prominent feature and adds the repo's "tell the reader what to try instead" rule. `:830-832` names the reverse direction in §8.3. |
| C3, C4, C5 | **CLOSED** with C1/C2 | `:1087-1104`, `:1077-1085`. |
| D3 (Cell 5 has no cell to attach to) | **CLOSED**, then partly undone | `:955-958` states it. Contradicted by `:949-954` — see **R8**. |
| D4 (Cells 4/5 duplicate a banked row) | **CLOSED** | `:949-954`. |
| D5 (`ordinal` unclassified) | **CLOSED** | §10.3 (`:991-1003`) routes it to doc 242, marks the STRONG suggestion AGENT-INFERRED, and specifies the fallback wording if unsigned. Residual at R-note 2. |
| D6 (joint fit split across cells) | **CLOSED for ledger rows** | `:852-854`. Not applied to the article's own coverage table — R-note 4. |
| D7 (which cells are licensable) | **CARRIED**, two caveats dropped | `:962-966`. See R-note 2. |
| D9 (`nbinom2` masking) | **CLOSED** | `:494-497` makes the `drmTMB::` prefix mandatory and requires the article to say why once. |

---

## Part C — what the repair INTRODUCED

### R1 [BLOCKING] The register's own framing re-asserts the false-gap claim, at two sites

The A1 fix built a new Part 3 with new opening and closing prose. Both drafts state that
no comparator exists — for a set that includes the one model where a comparator
demonstrably does.

**Site 1 — the register's opening (`:533-537`).** The draft reads: *"The following have no
established frequentist implementation to compare against at all"* → the list from §8.3
item 3 → *"Two of them are shown below."*

Two defects compound here:

1. §8.3 item 3 (`:825-829`) lists **`sd(group)` regression, bivariate LSS with structured
   covariance, and phylogenetic/spatial/`animal()`/`relmat()` structure**. It does *not*
   list scale-side random effects — those are §8.3 item 1 (`:817-820`). So the model shown
   in §4.3 is **not an instance of the class the register opens with**, and F3's stated
   purpose ("the two illustrated models then read as two instances of a class", `:155-158`)
   fails for it. The source the plan cites for that list,
   `expressible-vs-comparator.md:103-133`, has **four** classes and scale-side `sigma`
   random effects are class 1 (`:109-113`); doc 242's own frontier sentence names them
   first (`docs/design/242-…:87-88`). The plan quoted a truncated list.
2. Applied to §4.3's model, "no established frequentist implementation to compare against
   at all" is **false** — `glmmTMB` accepts `dispformula = ~ (1|Subject)`, runs, and
   returns a degenerate fit (`feasibility-batch-1.md:77-90`). This is precisely the
   over-claimed gap of B2, in drafted article prose.

**Site 2 — the article's final sentence (`:659-665`).** The F8 closing paragraph ends:
*"…because there is no other package to agree with."* False for §4.3's model, and it is
the last thing the reader reads. F8's purpose (do not end on "glmmTMB failed and drmTMB
did not", `:172-174`) is served; its wording substitutes a stronger false claim for a
weaker true one.

**Why blocking.** I graded B2 BLOCKING because over-claiming a gap is the mirror-image
violation of issue #60, and the plan agrees (`:626-632`). The claim has moved from a
survey table into the drafted article's opening and closing frames, which is a worse
position, not a better one.

**Fix.** (i) F3's list must be doc 242's own four-part frontier — including scale-side
random effects — or `expressible-vs-comparator.md`'s four classes in full, not §8.3 item 3.
(ii) Both draft sentences must be split by case: *no comparator exists* for `rho12 ~ x`;
*a comparator exists and fails on this dataset* for scale-side `sigma` REs. §5's coverage
table already draws that distinction correctly at `:685-686`; the register's prose must
match its own table.

### R2 [SERIOUS] "Eight of these ten models have a comparator" contradicts §1.2 and §7

`:78` opens the mandatory composition disclosure with that sentence. `:71` says of c02:
"The comparator **exists, runs, and fails.**" `:761` says "Comparator exists but is
unusable on this dataset." Nine of ten have a comparator; eight have a *usable* one. The
sentence is B2's error in miniature, inside the section that fixes B1. **Fix:** "Eight of
these ten models have a comparator that produces a usable fit." The 79%/21% figure and the
mandated bold sentence at `:84-85` are unaffected and remain correct.

### R3 [SERIOUS] §6.3's mandated summary violates §6.2's own rule

`:724` states the rule: *"No sentence may count or total agreements across strengths."*
`:730` opens the mandatory Part 2 closing summary with: *"Eight models, eight agreements."*
That is a standalone sentence totalling agreements across three strengths. §5 rule 1
(`:690-691`) forbids the same thing in the coverage table for the stated reason that
totals "average WEAK into STRONG".

The decomposition follows immediately, so the intent is fine — but a build session facing
a flat prohibition and a mandatory draft that breaks it will resolve the conflict
arbitrarily. **Fix:** delete the opening clause (the summary reads perfectly starting at
"Three of them…"), or amend §6.2 to permit a total only when the strength decomposition
appears in the same sentence.

### R4 [SERIOUS] F4 is contradicted by the exception §4.2 grants itself

F4 (`:159-161`) is stated as non-negotiable: Part 3 carries "no absolute-difference column,
no tolerance, no 'agrees to N figures', and no digit copied from Part 2." §4.2 then
specifies (`:591-597`) that the per-species Pearson correlation "agrees to ~1e-5/1e-6",
labelled as a self-check rather than a comparator, and adds: "It is not an agreement number
for F4 purposes — but it is the one place F4 is at risk."

A tolerance figure of `1e-5` in Part 3, in the same order of magnitude as Part 2's `1e-3`
to `1e-7`, is the numeric parallel F4 exists to remove. The label sits in the same
sentence; my A1 finding was that a label is not a firewall, and that reasoning does not
stop applying because the plan invokes it. **Fix:** report the sanity check
qualitatively ("the fitted per-species correlations reproduce the raw per-species sample
correlations, as they must when every submodel is species-saturated") with no figure — or
move it into a build note and out of the article. Do not carry an exception inside a rule
labelled non-negotiable.

### R5 [SERIOUS] The A1 adjacency arithmetic is wrong for `penguins`, and Part 3's order makes it worse

`:132-136` claims: *"Adjacency between a frontier model and its dataset twin is broken by
two intervening comparisons in each case (c01 → c09, c03 → register → c10; c09 → c03 →
register → c10 → c02)."*

Article order is c08, c04, c05, c06, c07, **c01**, **c09**, c03, [register opening],
**c10**, **c02** (`:119-123` for Part 2; `:527-528` for Part 3).

- `sleepstudy`: c01 (6th) → c02 (last). Two comparisons intervene (c09, c03), plus the
  register opening and c10. Claim holds.
- `penguins`: c09 (7th) → c10. **One** comparison intervenes (c03), plus the register
  opening. The claim of "two … in each case" is false, and c10 sits in the **first
  demonstrated slot of Part 3** — the closest position to its twin that the architecture
  allows.

The parenthetical itself shows this and is internally garbled: its first chain ends at c10,
its second begins at c09 and ends at c02, so neither traces one dataset pair.

**Free fix:** swap Part 3's demonstration order to scale-side `sigma` RE (`sleepstudy`)
first, `rho12 ~ species` (`penguins`) second. Then `sleepstudy` is separated by c09, c03
and the opening (two comparisons) and `penguins` by c03, the opening and the `sleepstudy`
subsection (two comparisons). Both pairs reach the claimed separation and nothing else in
F1–F8 changes. §4's stated order and `:1153-1154`'s build order must be updated together.

### R6 [SERIOUS] §4.2 lacks the "not interval-ready" instruction that §4.3 carries

F6 requires each register subsection to name its governing `cell_id` and tier *before* any
estimate. Both do. Only one guards the consequence.

§4.3 (`:617-619`) is exemplary: it reads `mc-0266`'s design (48 groups × 20 obs) against
`sleepstudy`'s (18 × 10) and rules "The article must not present this fit as
interval-ready … Report the point estimate and its SE as output, not as a calibrated
interval."

§4.2 (`:545-555`) quotes `mc-0181`'s `evidence_tier = interval_feasible` and its boundary,
and flags only the *domain* question (is `rho12 ~ species` inside a cell tested on
`rho12~1`?). It gives no instruction about what the article may claim. Read directly from
`cells.tsv`, `mc-0181`'s boundary is narrower than the plan quotes: it also states "No
committed CI-coverage simulation found for biv_gaussian fixed effects specifically … so
this stops short of 'supported'", and its `next_gate` is "Preserve the existing
model-surface evidence tier." So the article would print `interval_feasible` beside a
predictor-dependent `rho12` model whose form is not established as in-domain, with no
counterpart to §4.3's guard. **Fix:** add the parallel sentence — no interval or
calibration claim for this fit, point estimates only — and require the builder to resolve
the domain question or state it in the article, which §15.3 (`:1177-1178`) already asks
for but §4.2 does not enforce.

### R7 [SERIOUS] The §11 correction sweep is incomplete — the same two error classes survive in cited sources

§11 (`:1018-1052`) is thorough and its self-correction table is the right instinct. It
misses two live instances of errors it corrects elsewhere, in a document §4.1 and §8.3
name as the article's evidence trail:

1. **B2-class false gap.** `expressible-vs-comparator.md:110-113`: "No comparator package
   models residual-scale as a random effect the way drmTMB does; `glmmTMB` treats
   dispersion as a fixed nuisance parameter, not a formula-driven random-effect target."
   Refuted by `feasibility-batch-1.md:77-90`. The same sentence is quoted approvingly at
   `candidate-cells.md:97-98` — a line §11 does not list, though it lists `:15-17`, `:48`,
   `:52`, `:172-174` and `:298-300` from the same file.
2. **N5-class stale citation.** `expressible-vs-comparator.md:105` cites
   `docs/design/242-…:79-80` for the frontier quote. Verified: `242:79-80` is inside the
   2026-08-15 amendment, about whether the `lme4` point-agreement block was withheld from
   the ledger. The frontier passage is at `242:86-91`. This is the identical defect §11
   corrects for `feasibility-batch-4.md:137-139` (N5).

**Fix:** add both rows to §11. The first is not cosmetic: it is the upstream source of R1.

### R8 [SERIOUS] §10.1's "extend the existing row" advice contradicts its own next bullet

`:949-954`: "**Comparisons 2 and 3 largely duplicate `ev-mc-0260m-meta-v`** … If the
provenance matters, extend that row's `result` field rather than opening a new one."
`:955-958`: "**Comparison 3 has no cell to attach to.** The only `route_modifier ==
'meta_V'` cell is `mc-0260m` (`dpar = mu`, fixed). There is no `meta_V` `sigma` cell, and
attaching it to `mc-0262` … would badge a non-meta cell with a result obtained under a
`meta_V` likelihood."

Extending `ev-mc-0260m-meta-v`'s `result` with Comparison 3's evidence badges a **`mu`-side**
cell with a **`sigma`-side** result — the same mis-attachment the second bullet refuses,
by a different route. And `result` is one of the two fields package detection scans
(`tools/capability_ledger.py:2328-2329`, re-verified), so it is not an inert notes field.

For candour: this is my own error, inherited. My D4 said "Cells 4 and 5"; my D3 said Cell 5
has nowhere to attach. The plan transcribed both faithfully. **Fix:** restrict any `result`
extension to **Comparison 2** (c04 → `mc-0260m`, `mu`-side, real-data provenance). Record
Comparison 3's real-data provenance in the vignette and the after-task report only.

### Notes (not blocking, fix while passing)

1. **`mc-0266` field misattribution (`:617-618`).** The plan says "the cell's own
   `next_gate` forbids inheriting the result to another group design". Read directly:
   `next_gate` is "Coverage or calibration requires a separate approved DRAC campaign; do
   not inherit this target-specific result to another random-effect block, information
   rung, estimator, or family" — no mention of group design. "other group designs … were
   not evaluated" is in `claim_boundary`. The conclusion is right; the field is wrong.
   This is the citation class §11 was built to eliminate.
2. **Two D7 caveats dropped at the point of use (`:962-966`).** The licensable-cell list
   loses (a) my instruction to check c01's overlap against the existing
   `ev-mc-0260-external-comparator`, and (b) the D5 blocker for c06/c07. On (b): the
   enforcement only checks that a strength *token* is present
   (`tools/capability_ledger.py:2334-2341`, `tools/tests/test_capability_ledger.py:3018-3022`),
   so a builder minting a c06 row would type "STRONG INDEPENDENCE" and amend doc 242 by
   side effect — exactly what §10.3 exists to prevent. Cross-reference §10.3 from §10.1.
3. **D2's "say it explicitly" has no named home (`:945-948`).** The three-state statement
   is required but no artifact is nominated. The article should not discuss ledger rows at
   all; nominate the PR body or the after-task report.
4. **§5's table decomposes joint fits (`:680-687`).** Row 1 assigns "Location (`mu`)
   submodel, fixed effects → 1–8 (all), comparator exists". Both frontier models are joint
   fits whose `mu` components fall in that row. §8.4 (`:852-854`) applies my D6 joint-fit
   caveat to hypothetical ledger rows but not to the article's own table. One footnote
   fixes it: agreement was obtained inside joint fits and does not license any submodel in
   isolation.
5. **§13's estimate is built from the timings §12 disowns (`:1114-1115`).** Acceptable for
   a D-139 estimate; label them order-of-magnitude so the numbers cannot be re-read later
   as measurements.

---

## Part D — the four checks asked for

**1. Can a frontier model borrow an overlap model's credibility — by dataset, section
order, or a shared summary row?**

- *Shared summary row:* **NO.** §5's table is split, frontier rows show "none" in the
  comparisons column, and a frontier row citing a Part 3 subsection is explicitly forbidden
  (`:692-694`). Residual: R-note 4 (joint fits decompose into a "comparator exists" row).
- *Section order:* **Largely no.** F1–F8 remove the enumeration, the narrative thread and
  the numeric parallel, and Part 2 is closed by a scope summary. Two leaks: R4 (a tolerance
  figure permitted in Part 3) and R5 (`penguins` separated by one comparison, with the
  frontier `penguins` model first in Part 3).
- *Dataset:* **Residual, disclosed.** Both datasets still appear twice. §2.4 and §15.1 name
  it, set a build gate, and keep "drop the frontier fits" available to the maintainer. I
  accept the disclosure as sufficient for a plan.

**2. Is independence strength per-cell and honest?**

**YES.** Every one of the eight comparisons carries its strength in the §1.1 table
(`:51-64`), at first mention in its own subsection (§3), and in the §5 coverage table.
Part 2 is *sectioned* by strength, so a WEAK number cannot be reached without its framing
sentence. The vocabulary table (`:717-722`) is grep-enforceable and forbids the exact
phrases that would launder WEAK as STRONG. `ordinal` is reported as unclassified rather
than assumed. `:740-746` sharpens my own A3 phrasing correctly. The single conflict is R3
(the mandated summary's opening clause breaks the no-totalling rule).

**3. Does the plan imply every drmTMB model has a comparator (issue #60)?**

**NO — with one contradictory sentence.** The disclosure is mandatory in the article's
opening (`:76-86`), repeated in the coverage table's last row (`:687`), repeated in the
boundary paragraph (`:810`), the count is pinned at eight not ten (`:812-813`), and §8.3
item 4 requires the *reverse* direction — `ordinal::clm(scale = ~ temp)` fits a model
drmTMB cannot (`:830-832`). This is a strong answer to #60. The defect is R2 ("Eight of
these ten models have a comparator"), which understates the comparator surface in the same
section — the mirror error, and the one R1 makes structural.

**4. Is any capability-ledger row proposed that doc 242 does not license?**

**NO.** §10.1 recommends **zero** rows and routes it to maintainer sign-off (`:38`,
`:941-960`, `:1007`). Its four reasons are all correct against the sources: the frontier
models have nothing to record (242's three-state amendment at `242:78-84`); Comparisons 2
and 3 duplicate `ev-mc-0260m-meta-v`; Comparison 3 has no `meta_V` `sigma` cell; the live
precedent is zero rows. §8.4's minting vocabulary (`:834-854`) matches the enforcement
exactly — I re-verified `tools/capability_ledger.py:2328-2341`, `:3875-3878`
(`COMPARATOR_PACKAGES` includes `ordinal`), and
`tools/tests/test_capability_ledger.py:3009-3014`, `:3018-3026`, `:3037-3041`. The
proposed doc 242 amendment (`ordinal` = STRONG) is a design-doc edit, correctly separated
from the write-up, marked AGENT-INFERRED, and given a fallback if unsigned (`:991-1003`).
Two loose ends: R8 (a `result` extension that would mis-attach a `sigma`-side result to a
`mu`-side cell) and R-note 2.

**5. Was any cell quietly dropped?**

**NO.** All ten build ids are accounted for: eight in §1.1, c02 and c10 in §1.2 with
verdicts and sources, and §7 (`:755-778`) records every rejection with its blocker,
including two rejections that are *claims* rather than cells (c05's comparative-
heterogeneity conclusion, and any speed claim). §7's closing paragraph adds Noether's N6
limit — five families never fitted, only two non-identity conversions verified — which
narrows a claim nobody asked it to narrow. That section is a model of the genre.

---

## What the repair got right

Recorded so the blocking finding is not read as a rejection of the document.

1. **Every line reference the plan says it re-verified, checks out.** I independently
   confirmed `src/drmTMB.cpp:670` (`Type(0.999999) * tanh(eta_rho12)`), `R/family.R:34`
   (`rho12 = "atanh_guarded"`) and `:13-15`, `R/family.R:415-418` (`dpars = c("mu")`),
   `DESCRIPTION` `Suggests` (no `metadat`, no `betareg`),
   `tests/testthat/test-reader-vignette-contracts.R:224` (`expect_equal(nrow(manifest),
   37L)`, manifest 38 lines = header + 37), `tools/check-reader-contracts.R:3-5`, `:7-10`,
   `:98-100`, `:132`, `:178`, `:234-239`, and all five ledger-enforcement locations. The
   §11 self-correction table (`:1043-1052`) is accurate in all eight rows. An author who
   re-checks their own citations after being told their sources had citation errors is
   doing the thing the Rose principle asks for.
2. **A1 was answered with architecture rather than a disclaimer**, and the changelog says
   plainly why the disclaimer was the weaker remedy (`plan-repair-changelog.md:26-31`).
   The demotion of F7/F8 to "the last of several layers" is the correct ordering.
3. **§2.4 names what was rejected, why, what remains available, and what risk survives** —
   including an escalation that would cost the author's own design. That is the disclosure
   discipline this phase has been short of.
4. **D1 was treated as a claim problem, not a wording problem.** The replacement sentence
   keeps the point agreement, drops the finding, and cites the ledger boundary that kills
   it.
5. **`:1183-1188` states that nothing was re-fitted** and enumerates exactly what was
   re-verified. §15 as a whole ("What this revision did not fix") pre-empts four of the
   findings a reviewer would otherwise have to discover, including one — `mc-0266`'s design
   mismatch — that none of the audits caught.

---

## Gate conditions before PR 2 is built

1. **R1 (BLOCKING).** Rewrite §4.1's and §4.4's drafts to distinguish *no comparator
   exists* from *a comparator exists and fails here*, and replace F3's list with doc 242's
   full frontier (or `expressible-vs-comparator.md`'s four classes), which includes
   scale-side random effects.
2. Fix R2 (`:78`), R3 (`:730`), R8 (`:949-954` → Comparison 2 only). All one-line edits.
3. Decide R4: drop the `1e-5/1e-6` figure from Part 3, or amend F4 to state its one
   exception explicitly. Do not leave a non-negotiable rule with an unstated carve-out.
4. Apply R5's free fix — swap Part 3's two subsections — and correct the adjacency
   sentence at `:132-136` to what the order actually delivers.
5. Add R6's interval guard to §4.2, matching §4.3.
6. Add R7's two rows to §11 before any source document is cited by the article.
7. Clear the five notes while passing.
8. Maintainer sign-offs already listed at §10.4 remain required, plus a sixth: whether
   F3's frontier list should be doc 242's (R1).

Nothing here requires re-fitting. Every item is a text or ordering change to the plan.

## Verification limits of this re-audit

I re-fitted nothing and re-ran no R. Every numeric result discussed remains Gauss's or
Noether's measurement, cited as theirs, and I did not re-verify any of them. What I read
directly: the four files named in the header, plus `cells.tsv` rows `mc-0181` and
`mc-0266` in full, `DESCRIPTION`, `src/drmTMB.cpp:668-672`, `R/family.R`,
`tools/check-reader-contracts.R`, `tools/capability_ledger.py`,
`tools/tests/test_capability_ledger.py`,
`tests/testthat/test-reader-vignette-contracts.R:222-228`, and the cited line ranges of
`expressible-vs-comparator.md`, `candidate-cells.md` and `feasibility-batch-1/2/3.md`. I
did **not** re-derive the 268/341 frontier proportion; it remains my own prior
AGENT-INFERRED classification and the plan carries that marking correctly. R8 corrects an
error in my own prior audit (D4 versus D3); the plan is not at fault for inheriting it.

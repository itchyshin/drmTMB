# Gate 5 — claims audit of the restructured plan and the columned survey

Auditor: Rose (systems auditor). 2026-08-15, round 5. FINAL gate.
Worktree: `.worktrees/phase19`, branch `claude/phase19-comparator-workflows`, off
`origin/main@82cd00560`, drmTMB 0.7.0.
Inputs read in full: `PR2-build-plan.md` (1833 lines), `expressible-vs-comparator.md`
(478 lines), plus targeted re-reads of `feasibility-batch-1.md` … `-4.md`,
`candidate-cells.md`, `DESCRIPTION`, and
`docs/design/242-external-comparator-evidence-class.md`.

**Verdict: NOT-DONE. 1 blocking, 5 serious.**

**Say the important thing first: round 5 closed the class.** Four rounds of audit chased one
defect — an unqualified assertion that no comparator exists — and each repair moved it rather
than killing it. Round 5 is the first that changed the shape of the problem instead of the
wording: the term is redefined at its definition, the survey table's incompleteness is now
visible without a sweep, and the article no longer has a place for the claim to live. All
four of my blocking findings and all five of my serious findings from gate 4 are closed, and
I verified each mechanically rather than on the changelog's say-so.

**The one blocking finding is not that class.** It is a different absence-claim shape —
"package X cannot do this" — sitting in two mandated article conclusions that predate §2.5
and were never re-read against it. It is true, narrow, and costs three lines to fix. I am not
asking for a sixth structural change, and I would not have opened a fifth round for it alone.

I ran two measurements this round (both below) and no model fits.

---

## Answers to the six questions asked

### 1. Is the FRONTIER definition clause-compliant, and does it name the searched set? **YES.**

`expressible-vs-comparator.md:22-27`:

> **FRONTIER** — the region where **this survey found no comparator in the set it searched
> (`DESCRIPTION` `Suggests`), having in most rows searched that set by reading package
> documentation rather than by running anything**. FRONTIER is a statement about what this
> survey found in that set. It is **never** a statement that no implementation exists, and it
> must not be read, quoted, or inherited as one.

Both clauses are inside the definition sentence: the set (`DESCRIPTION` `Suggests`) and the
run status ("by reading package documentation rather than by running anything"). The set is
named once for the whole document at `:15-18` and quoted in full at `:108-114`.

**The set is real, and I checked it.** The 25-package list quoted at `:110-113` matches
`DESCRIPTION`'s `Suggests` exactly — same 25 packages, differing only by the version
constraints on `detectseparation` and `testthat`, which the doc drops. "No CRAN search was
made" is stated at `:16` and again at `:116`, and every row's "Set searched" cell repeats it.

Residual uses of the old wording are all quotation-of-history: `:32`, `:269`, `:344`, `:466`
each quote the superseded phrasing inside a correction record. None is a live definition.

### 2. Are claim-class / searched / run filled for ALL seventeen rows? **YES — 17/17, verified mechanically.**

Parsed the table at `expressible-vs-comparator.md:209-225` with escaped pipes handled:

```
n data rows: 17   (all 8 columns each; no empty, dash-only, or n/a cell in columns 6, 7, 8)
209 gaussian          class[154 ch] set[172] run[377]     214 tweedie          class[20]  set[91]  run[73]
210 student           class[149]    set[176] run[94]      215 beta             class[20]  set[186] run[45]
211 skew_normal       class[20]     set[113] run[70]      216 zero_one_beta    class[97]  set[81]  run[99]
212 lognormal         class[197]    set[40]  run[188]     217 beta_binomial    class[125] set[75]  run[219]
213 Gamma             class[175]    set[40]  run[62]      218 binomial         class[32]  set[113] run[105]
219 poisson           class[20]     set[40]  run[52]      222 cumulative_logit class[121] set[40]  run[234]
220 nbinom2           class[169]    set[40]  run[186]     223 biv_gaussian     class[126] set[235] run[273]
221 truncated_nbinom2 class[20]     set[40]  run[43]      224 biv_lognormal    class[122] set[40]  run[49]
                                                          225 biv_student      class[27]  set[43]  run[23]
```

Seventeen rows is also the right count: it matches the fitted families in
`docs/design/02-family-registry.md:68-118`, and the three rows gate 4 named
(`student()` `:210`, `tweedie()` `:214`, `cumulative_logit()` `:222`) are filled.

**One qualification, filed as G5-S4:** four cells are non-empty but carry no A/B/C letter.
The column contract as written ("all three must be non-empty") is met; the column's own title
is not.

### 3. Is the `:95-97` blanket default gone? **YES.**

Deleted, and replaced by an explicit prohibition at `:192-197`: *"There is no blanket default,
and there must not be one."* The paragraph names the mechanism — a prose caveat repairing
table cells, which `PR2-build-plan.md:863` already ruled out at source — and closes with *"If
a cell is incomplete, the cell is wrong."* The five surviving occurrences of "unmarked"
(`:192`, `:196`, `:346`, `:472`, `:473`) are all descriptions of the deletion.

### 4. Are presence claims governed, and are the gamlss/sn/VGAM/cplm/brms claims marked? **YES to both.**

The rule is two-way at `expressible-vs-comparator.md:92-96` and `PR2-build-plan.md:1161-1164`:
no sentence may assert a comparator is absent **or** that one exists and fits without naming
(a) the set searched or the package, and (b) whether it was run.

**I re-ran the installed-status measurement** recorded at `expressible-vs-comparator.md:124-128`
and it reproduces exactly:

```
gamlss ABSENT · sn ABSENT · cplm ABSENT
VGAM INSTALLED · brms INSTALLED · MCMCglmm INSTALLED · betareg INSTALLED · metadat INSTALLED
```

Every one of the six claims gate 4 named is now marked in its own cell: `gamlss`/`brms`
(student, `:210`), `sn` (skew_normal, `:211`), `cplm` (tweedie, `:214`), `gamlss`/`betareg`
(beta, `:215`), `VGAM` (beta_binomial, `:217`). The sentence that said those packages *"can
serve as an oracle"* is gone; `:299-308` replaces it with a four-way split — demonstrated by
an executed fit / asserted from documentation / asserted and not installed / installed,
outside `Suggests`, never run.

The eleven-execution table at `:151-162` is accurate. I resolved all eleven cited ranges plus
four others; every one lands on the content claimed
(`feasibility-batch-1.md:40-43`, `:66-73`, `:142-149`; `-2.md:46-52`, `:118-129`, `:162-191`,
`:183-191`; `-3.md:60-68`, `:138-144`, `:208-213`; `-4.md:52-73`).

**This also fixes the reader-lands-on-a-lie problem I raised at gate 4.** The article's one
inbound citation into this file is Comparison 5's mandatory boundary
(`PR2-build-plan.md:533`), which points at the "OVERLAP region, summarized" section by
heading. A reader following it now lands on the demonstrated/asserted split, not on
"`gamlss` can serve as an oracle".

### 5. Is Part 3 removed from the ARTICLE spec? **YES.**

`PR2-build-plan.md:179` (*"Changed in round 5: there is no Part 3"*), the two-part shape at
`:181-187`, §2.5's rule A1 at `:306-309`, and §14 step 5 at `:1737-1739`, which keeps step 5
as a numbered gap so a session working from an older copy notices. §4 is retitled and
repurposed as a plan record (`:731-745`), and §4.1/§4.3 record the retired drafts.

I enumerated all 47 occurrences of "Part 3" in the plan. Every one is retrospective — a
retirement note, a disposition table, or a correction record. None mandates article text.

### 6. G4-B1..B4 and G4-S1..S5

| Finding | Status | Evidence I checked |
| --- | --- | --- |
| **G4-B1** FRONTIER defined as unqualified absence | **CLOSED** | Redefined at `expressible-vs-comparator.md:22-27` with both clauses in the definition sentence; old wording survives only inside quoted correction records (`:32`, `:344`, `:466`). This is the fix I asked for — the term, not its instances. |
| **G4-B2** three rows assert FRONTIER with no clause | **CLOSED** | Three columns added; 17 rows parsed mechanically, all three columns non-empty in every row (table above). `student()`, `tweedie()`, `cumulative_logit()` are filled and were filled *as part of the enumeration*, per `:281-285`, not as three exceptions. |
| **G4-B3** blanket class-C default at `:95-97` | **CLOSED** | Deleted; replaced by an explicit no-default rule at `:192-197` that cites the same source standard (`PR2-build-plan.md:863`) I did. |
| **G4-B4** Part 3 heading asserts absence, first conjunct has no referent | **CLOSED BY REMOVAL** | The heading is gone because the section is gone (§2.5). §4's plan-side title is now *"…what we checked, what we did not, and where it now lives"*, which asserts no absence. Removal is a stronger close than a retitle. **But see G5-S3: §8.3's heading is the same defect and was not retitled.** |
| **G4-S1** rule one-way; six unverified presence claims | **CLOSED** | Rule two-way at `:1161-1164`; installed-status table measured and **independently re-run by me this round with identical output**; all six claims marked in-cell. |
| **G4-S2** "also frontier" tail unscoped in the source | **CLOSED** | `expressible-vs-comparator.md:417-424` now carries both conjuncts scoped, matching `PR2-build-plan.md:818-823`. |
| **G4-S3** `feasibility-batch-4.md` not quarantined | **CLOSED, with a defect in the fix** | Quarantine added at §15 item 9 (`:1816-1825`), same treatment `candidate-cells.md` gets. **The line range it names is wrong — G5-S1.** |
| **G4-S4** §14 step 2 lets classification output into a chunk | **CLOSED** | `:1727-1731` now reads *"from this script's **eight-comparison** output; the two classification checks are recorded in the script and quoted nowhere in the article"* — the wording I proposed. |
| **G4-S5** §4.2's prohibitions written for Part 3, not for §5 | **CLOSED** | §5 rule 5 added at `:907-912`, and the status column is renamed *"Compared in this article?"* with rule 4 (`:901-906`) making "not compared here" the complete permitted answer. The rename is a better fix than the rule I asked for. |

---

## Part B — blocking

### G5-B1 [BLOCKING] Two mandated article conclusions assert that a named comparator cannot do something — §2.5 A1 forbids exactly that, and §14 step 6's checks cannot see them

`PR2-build-plan.md:597-599`, Comparison 6's Reader's conclusion (article text):

> The `sigma` slope on `Days` is positive: residual spread grows with each day of
> deprivation — **a claim `lmer()` cannot make at all, because it has one residual SD.**

`PR2-build-plan.md:657-659`, Comparison 7's Reader's conclusion (article text):

> **The sex-variance result is the part `lm()`/`lmer()` cannot deliver.**

§2.5's A1 (`:306-309`) is absolute and admits one exception, which is not this one:

> **No sentence in the vignette may assert, imply, or classify the absence of a comparator
> for any capability.** Not in a heading, a table cell, a footnote, a caption, a chunk
> comment, or a closing paragraph.

Both sentences classify the absence of a comparator for the residual-scale capability. `lme4`
is a comparator package in this very article — Comparison 1 is `lme4::glmer`. Under §8.5 they
fail the second clause as well: they name a package but no run status, and **no `lmer` or
`lm` fit was run anywhere in Phase 19** (the eleven executions are tabulated at
`expressible-vs-comparator.md:151-162`; `lme4::glmer` on `cbpp` is the only `lme4` entry).

**Three things make this blocking rather than serious.**

1. **The article inherits it by construction.** These are not planning notes; they are the
   specified reader conclusions for two of the eight comparisons. A builder drafting from §3
   writes these sentences.
2. **Round 5's own gate cannot catch them.** §14 step 6 (`:1740-1745`) offers two mechanical
   aids: the vignette should contain no occurrence of "frontier", and §5's status column
   should contain only a count or "not compared here". Neither sentence contains "frontier"
   and neither is in that column. This is the same failure mode as rounds 2–4 — *a claim made
   without the phrase the aid searches for* — one level down. The step-6 enumeration would
   catch them if executed as an enumeration; four rounds say that is exactly what does not
   happen when an aid is available.
3. **They survived unre-read.** Both predate A1 by two rounds. §2.3, §4.1 and §11's round-5
   table each enumerate what round 5 re-homed or retired; §3's eight Reader's-conclusion
   bullets were never enumerated against the new rule. The round-4 builder notes attached to
   these same two comparisons (`:621-625`, `:665-667`) *were* updated for round 5, so the
   subsections were touched — the conclusions just were not read as claims.

**In fairness, and it matters for how you fix it:** both sentences are *true*. `lmer` has one
residual SD by construction. The defect is rule erosion, not misinformation — which is why
the fix is cheap and why I am not asking for a structural change.

**Fix — three lines, no new evidence.** Restate both as statements about a *model*, not about
a *package's capability*, which is the same distinction §2.5 draws between "what this article
covered" and "what exists elsewhere":

- `:598-599` → *"…residual spread grows with each day of deprivation. A mean-only model
  cannot represent that, because it carries a single residual SD for every observation."*
- `:659` → *"The sex-variance result comes from the `sigma` submodel; a model with one
  residual SD has no parameter for it."*

Then add the Reader's-conclusion bullets to §14 step 6's enumeration explicitly, so the next
session reads §3's eight conclusions against A1 rather than assuming §3 is pre-round-5 and
therefore settled.

---

## Part C — serious

### G5-S1 [SERIOUS] The quarantine that closes G4-S3 names the wrong lines — third generation of the stale-line-citation defect, inside its own fix

`PR2-build-plan.md:1816-1825` (§15.9) and the §11 correction row at `:1511` both quarantine
**`feasibility-batch-4.md:126-127`**. Read in place today, the defective sentence is at
**`:122-124`**:

```
122 **Verdict: UNCERTAIN**, unchanged from the pre-filled cell, and for the same reason:
123 `expressible-vs-comparator.md:79` classes formula-capable `biv_gaussian()` `rho12` as
124 FRONTIER — expressible by drmTMB but with no comparator to check it against — so
125 "VIABLE" is not available (nothing to agree with) and "BLOCKED" is wrong (the fit
126 converges cleanly and the one sanity check available passes to 1e-5). What is newly
127 verified here, beyond the pre-filled draft: (a) the fit actually converges and returns
```

`:126-127` is innocuous prose about convergence. A builder who opens the quarantined range
finds nothing wrong there, and the most likely readings are "already repaired" or "spurious
quarantine". `expressible-vs-comparator.md:279-280` carries the same wrong range in R11's
citation note.

This is the defect class G-S1 was raised for and that §4 already ruled on
(`:756-760`: *"Cite `expressible-vs-comparator.md` by section heading, not by line range …
Heading citations do not go stale when lines shift"*). The rule was applied to one file and
not to the other. My gate-4 text is partly at fault — my body quoted `:124-127` and my Fix
line said `:126-127`; the plan took the narrower one.

**Fix.** Quarantine and cite by **claim**, not by line: *"the `biv_gaussian()`/`rho12`
FRONTIER verdict in `feasibility-batch-4.md`'s section 3 (Verdict: UNCERTAIN)"*. Same in
`expressible-vs-comparator.md`'s R11.

*Also noted while there:* `feasibility-batch-4.md:130` states the `rho12` link as plain
`atanh`/`tanh`, which §0 and §11 (`:1521`) both declare wrong. That correction is already
scheduled for `:111-115`; the same error at `:130` is outside the scheduled range. Add it.

### G5-S2 [SERIOUS] The sentence §1.3 removed from the article is asserted three times, unclaused, in the plan that removed it

§8.5 binds this plan explicitly (`:1166-1168`, and §0's decision row at `:73`). Three
instances:

| Line | Sentence |
| --- | --- |
| `:328` | "A reader of the vignette alone will not learn from it that **most of drmTMB's implemented surface has no comparator**. **That fact is true**, it matters…" |
| `:1446-1447` | "…a reader of the vignette alone will not learn from it that **most of drmTMB's implemented surface has no comparator**" |
| `:1829-1830` | "…the fact that **most of drmTMB's implemented surface has no comparator** is now reachable only by a reader who follows a pointer" |

None names a searched set; none names a run status; one asserts it as established fact. This
is the precise sentence §1.3 (`:142-152`) rewrote out of the article, for the precise reason
that it is an absence claim about drmTMB's whole surface with no search behind it — and
`DESCRIPTION` `Suggests` is the only set anyone searched.

Three instances of one sentence-shape is a class, not a slip. It is confined to the plan and
the article does not inherit it, which is why it is serious rather than blocking.

**Fix.** *"…will not learn from it that most of drmTMB's implemented surface was not compared
against any package in `DESCRIPTION` `Suggests`, and that nothing beyond that set was
searched."* Same substitution in all three.

### G5-S3 [SERIOUS] §8.3's heading is G4-B4's defect, unretitled — and its item 3 is stale after round 5

Two problems in one section.

**The heading.** `:1085`: **"### 8.3 What has no *working* comparator — explicit statement"**.
§8.5 says a section heading is a sentence for the rule (`:1168-1169`). This one names no
searched set and no run status. §4's heading was retitled for exactly this finding
(`:733-739`); §8.3's was not, though the two sections carry the same material. The section's
*contents* are compliant — items 1 and 2 both carry their clauses — so the heading is refuted
by its own body in the milder direction: the body says "a comparator exists and was run" and
the heading says "what has no working comparator".

**Item 3 is stale.** `:1109`: *"**The wider frontier the article names without demonstrating**"*.
After §2.5 the article names nothing. The lead-in describes a Part 3 that no longer exists.

**Fix.** Retitle to *"§8.3 Comparator status per capability — searched, run, and what that
supports"*. Re-lead item 3 as *"The wider frontier, recorded in this plan only"*.

### G5-S4 [SERIOUS] Four claim-class cells carry no A/B/C letter, and for two of them the class is determinate

The column is titled **"Claim class (A/B/C)"**. Four cells give no letter:

| Row | Cell reads | My read |
| --- | --- | --- |
| `:217` `beta_binomial()` | "No absence claim in this row… The presence half is **unrun documentation**" | The row *does* claim `glmmTMB(family=betabinomial)` fits, unrun. By the document's own definition at `:176-177` that is **class C**. |
| `:224` `biv_lognormal()` | "No absence claim in this row. The presence half is an **unrun inference**" | Same — **class C**, and weaker than C's usual warrant, since no package is even named. |
| `:218` `binomial()` | "No absence claim in this row" | Fair. The presence half is a run and agreeing fit; a letter would be the presence-side analogue of B. |
| `:225` `biv_student()` | "No claim of either kind" | Correct as written — the row makes no claim. |

The contract the document sets itself ("all three must be non-empty", `:182-189`) is met, and
every cell carries its clause in content, so no reader is misled. But the document also tells
itself *"When uncertain between A and C, write C"* (`:180`) and then declines to write C where
the class is not uncertain. A column whose title promises a letter and delivers a paragraph in
four of seventeen rows is one round from someone reintroducing a blank and calling it
consistent with `:217`.

**Fix.** Write **C** in `:217` and `:224`, keeping the existing clause after it. Leave `:218`
and `:225` as they are, and add one line to the column contract at `:182-189` saying a row
that makes no claim of either kind is the one permitted letterless cell.

### G5-S5 [SERIOUS] §1.3 puts an absence-shaped statistic inside the section headed "mandatory in the article's opening", without saying it stays out

`:132-140`, under the heading **"Composition disclosure, mandatory in the article's opening"**:

> …gives 268 of 341 implemented cells (79%) sitting **in or beside the frontier**, leaving at
> most **~21% comparator-eligible**

"At most ~21% comparator-eligible" is an absence claim about 79% of the surface, expressed as
a number, in the section a builder reads when drafting the article's opening. The compliant
replacement sentence is given at `:147-149` and is introduced with "instead", which scopes it
— but §5 got an explicit prohibition on smuggling a verdict into a cell (rule 4, `:901-906`),
and §1.3 got no equivalent sentence saying the percentage is a plan-side derivation that does
not appear in the article. §11's own round-4 note at `:1552` already records that this 79% is
AGENT-INFERRED and about a different quantity than the claim it was once used to support.

I am calling this serious rather than blocking because "instead" does scope it and the
mandated wording is compliant. But §5 got a belt where §1.3 has only braces, and the
difference is not principled.

**Fix.** One sentence after `:140`: *"The 79% / 21% figures are this plan's derivation and are
AGENT-INFERRED; no percentage appears in the article. The article carries only the sentence in
bold below."*

---

## Part D — the pattern, closed

| Round | Enforcement | How the sweep was executed | What survived |
| --- | --- | --- | --- |
| 1 → 2 | none | fix what the audit named | Part 3's prose; two source lines |
| 2 → 3 | 5-string blacklist, grepped over the article | fix what the audit named | a sixth string; a whole per-family table in a cited source |
| 3 → 4 | required-clause rule, all documents | phrase search for `"no comparator fits …"` | three bare-token rows; the term's definition; the replacement heading |
| 4 → 5 | **rule made two-way; term redefined; columns added; the article's absence surface deleted** | **enumeration over 17 rows, verified mechanically; article surface removed rather than governed** | **one different claim shape ("package X cannot"), in two pre-A1 draft conclusions** |

The four-round defect is closed, and the reason it is closed is that round 5 stopped trying to
enforce a rule over an open surface and made two structural moves instead: the survey table
now answers the question by its shape (an empty cell is the finding), and the article no longer
has the surface the claim needed. Both are the moves I recommended at gate 4, and both were
executed rather than paraphrased.

What survived is a *different* shape, and I want to be precise about that rather than claim
continuity for rhetorical weight. "No comparator exists for capability X" is an unbounded
claim about the world. "`lmer()` cannot model residual spread" is a bounded, true claim about
one package. They fail the same rule and they are not the same error. G5-B1 is a rule breach
in article text; it is not the fifth recurrence of a false claim.

---

## Is this safe to build?

**Not as it stands, and yes after G5-B1.**

Fix G5-B1 — three lines in §3, plus one line added to §14 step 6's enumeration — and the plan
is safe to build. Nothing in the blocking finding requires a fit, a measurement, a maintainer
decision, or a structural change. I would not hold a fifth round for the five serious
findings; they are all confined to planning documents, none reaches the vignette, and every
one has a one- or two-line fix that the build session can apply in §14 step 1's single
enumeration pass.

Three things I want on the record for the build session, because they are the reason I can
say "safe" at all and they will decay if unattended:

1. **§14 step 6 must be executed as an enumeration over every sentence of the drafted
   vignette, including the eight Reader's-conclusion bullets.** The two mechanical aids are
   aids. G5-B1 exists because §3's conclusions were never enumerated against a rule adopted
   two rounds after they were drafted.
2. **The quarantines are live.** `candidate-cells.md` (§15.1) and the `biv_gaussian()`
   FRONTIER verdict in `feasibility-batch-4.md` (§15.9, range to be corrected per G5-S1) may
   not be cited as authority for a comparator-absence claim until §11's repairs land.
3. **Three sections remain unaudited from the audit side, and that is now three to four rounds
   deep** — §9 (registration checklist), §12 (reproducibility), and the c04–c09 build
   specifications. `PR2-build-plan.md:1809-1815` declares this honestly and §14 step 8
   requires re-verifying §9's line numbers before editing. I did not audit them this round
   either. A defect there would be the oldest unfound thing in this phase.

---

## What I checked and did not find a problem with

Recorded so the next auditor does not redo it.

- **The 25-package `Suggests` list** quoted at `expressible-vs-comparator.md:110-113` matches
  `DESCRIPTION` exactly (25 packages; version constraints on `detectseparation` and `testthat`
  dropped, nothing added or missing).
- **The installed-status table** at `:130-139` reproduces exactly under the command it
  records. I re-ran it.
- **All eleven comparator executions** at `:151-162` resolve to the content claimed; I opened
  each cited range.
- **`docs/design/242-…:86-91`** is the credibility-laundering passage and `:87-88` is its
  example list — both citations correct, both previously wrong (`:79-84`) and now repointed in
  both files. `:108-111` is the strength classification, correct.
- **§10.5's upward report** of doc 242's over-claim survives round 5 intact (`:1473-1489`), and
  §10.4.6 still states the consequence before asking for the signature (`:1458-1468`).
- **`candidate-cells.md:97-99`** is still uncorrected and still quarantined — §15.1 is honest
  about it. Its own citation of `expressible-vs-comparator.md:109-113` is stale too, which the
  quarantine covers.
- **Block 2c's mandatory opening** (`:544-545`) — *"no separate estimation engine checked a
  residual-scale submodel anywhere in this article"* — is scoped to the article and is the
  permitted form under §2.5. It is also self-critical, in the article, before the numbers. It
  should stay.
- **§7's eight rejection rows and §7's five never-fitted conversion rows** are unchanged and
  still carry their blockers and sources.
- **§11.1's provenance** still reads as corrected at gate 4 (script absent, values reproduced
  by me at `gate3-claims.md:256-269`, harness required by §14 step 2).
- I could not verify the maintainer signatures at `:1437` and `:1441-1448` from the repository;
  the plan records them as taken. I accepted the same shape at gate 4 and note it here as a
  provenance limit of this audit, not as a finding.

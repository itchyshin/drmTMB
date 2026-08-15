# Gate 4 — claims audit of the narrowed plan

Auditor: Rose (systems auditor). 2026-08-15, round 4.
Worktree: `.worktrees/phase19`, branch `claude/phase19-comparator-workflows`, off
`origin/main@82cd00560`, drmTMB 0.7.0.
Inputs read in full: `PR2-build-plan.md` (1585 lines), `expressible-vs-comparator.md`
(269 lines), `feasibility-batch-1.md` … `-4.md`, `gate3-claims.md`,
`plan-repair-changelog.md` "Round 4 — narrowing".

**Verdict: NOT-DONE. 4 blocking, 5 serious.**

The narrowing worked where it was aimed. The two frontier fits are genuinely gone, no cell
was silently dropped, every rejection still carries its blocker, and all six of my G-S
findings are closed with evidence I can check. The required-clause rule is a real
improvement on the blacklist and I would keep it.

It did not close the class. Round 4's own changelog records how the sweep was executed:
*"the same bare `'no comparator fits …'` phrasing was live in four more (skew_normal, beta,
poisson, truncated_nbinom2)"* (`plan-repair-changelog.md`, §3, G-B1 row). That is a search
over a **string** — the fourth consecutive string-shaped sweep, run under a rule that was
adopted precisely because string-shaped sweeps cannot close an open class
(`PR2-build-plan.md:1004-1009`, `:1037-1041`). Three per-family rows assert FRONTIER with no
phrase at all, just the bolded token, and were not touched. The token itself is defined at
the top of the document as an unqualified absence.

I ran no fits this round. Every claim below is a read of the two target documents against
the four feasibility batches.

---

## Part A — what is closed

### A1. The two frontier fits are gone, and nothing reintroduces them by another name

| Check | Where | Result |
| --- | --- | --- |
| c02 and c10 declared out of the article | `PR2-build-plan.md:86-95` | Both rows read "**Not in the article.** No drmTMB fit, no comparator output, no number." |
| Escalation recorded as taken, not offered | `:236-237`, `:1258-1260` | Signed 2026-08-15; §10.4.5 records it as decided rather than asked |
| Part 3 contains no model/data/code/digit | `:197-201` (P3), `:697`, `:1522`, `:1525-1526` | Stated three times; §14 step 6 makes it a mechanical check ("any numeral in Part 3 that is not a class number fails it") |
| Round-3 machinery that only existed for the demonstrations is deleted, each with what it guarded | `:209-221` | Eight-row disposition table; nothing deleted silently |
| No frontier model survives under a different label | swept `:1-1585` | The only surviving traces are (a) §1.2's classification warrants, in words, (b) §7's rejected-cell rows, (c) §11.1's measurement block, all three outside the article and all three explicitly barred from it at `:1400-1403` |
| Dataset adjacency (the residual A1 risk) | `:79-84`, `:249-251` | `sleepstudy`, `penguins`, `Owls` each appear once; `dat.bcg` and `wine` twice, both inside Part 2 between agreeing comparisons |

One wording hole in this otherwise clean result — see **G4-S4**.

### A2. No cell silently dropped; every rejection records its blocker

All ten build ids exist in the batches and all ten are dispositioned:

- **Eight retained:** c08, c04, c05, c06, c07, c01, c09, c03 (`:64-73`), each with a source
  batch line range.
- **Two dropped as frontier:** c02, c10 (`:92-95`), both also carried in §7.
- `grep -oE "c0[0-9]|c10"` over the four batches returns exactly c01…c10, no eleventh id.

§7's rejection table (`:880-889`) has eight rows, each with a Blocker column and a Source
column: c02, c10, `cumulative_logit()` + `sigma ~ temp`, `beta_binomial()` + `sigma ~ period`,
any `gamlss` comparator, any `betareg` cell, c05's comparative-heterogeneity *conclusion*
(the fit is kept, the claim rejected), and any speed claim. I checked the upstream proposal
documents for rejected candidates not carried forward — `candidate-cells.md:322`
(beta-binomial), `reader-gap-audit.md:115-118` (betareg), `dataset-inventory.md:73`
(`cumulative_logit` scale) — all three are present in §7. Nothing was dropped without a
recorded blocker.

§7's closing paragraph (`:891-899`) additionally records the five never-fitted conversion
rows, which is the right shape: an absence of evidence stated as such.

### A3. G-S1 … G-S6 are closed

| Finding | Closed? | Evidence |
| --- | --- | --- |
| **G-S1** stale line-range citation of `expressible-vs-comparator.md` | **CLOSED** | All four uses now cite the section heading. `grep -n "expressible-vs-comparator.md:[0-9]"` over the plan returns four hits, all inside §11's correction tables describing the old citation (`:689`, `:1319`, `:1341`, `:1349`); the live citation at `:962` reads *"the 'FRONTIER region, summarized' section"*. The rationale at `:688-692` is the right one: line ranges into a file under active correction cannot be kept true by re-checking harder. |
| **G-S2** §11.1's provenance does not resolve | **CLOSED as a plan change** | `:1363-1369` states the honest provenance: script absent, values independently reproduced by me at `gate3-claims.md:256-269`. `:1509-1515` (§14 step 2) makes the committed harness the build session's first task and requires it to re-emit §11.1 including the c02 check. The defect I found was provenance, not accuracy, and the plan now says so in those words. |
| **G-S3** §10.4.6 offers a signature that reintroduces R1 | **CLOSED** | `:1266-1276` states the consequence before asking: doc 242's sentence *"is an unqualified absence assertion … and its first named item is the one capability where a comparator demonstrably fits"*, and option (b) is permitted only with the class split appended. The over-claim is escalated as a standalone finding at `:1281-1297`. |
| **G-S4** "Two of these four are shown below" | **CLOSED** | Deleted (`:214`, `:1352`). The classification point survives: §4.2 class 4 keeps the neighbour-versus-instance distinction explicitly (`:729-732`). |
| **G-S5** doc 158's unscoped `rho12` sentence quoted approvingly | **CLOSED on both halves** | Appeal dropped from §8.3 item 2 (`:952-960`); a sixth doc-158 edit added at `:1221-1229` scoping `docs/design/158-phase-19-comparator-matrix.md:79`, with a standing quarantine ("no Phase 19 document may cite doc 158 as corroboration for this claim" until it lands). |
| **G-S6** "Comparison 9" in §5's mandatory footnote | **CLOSED** | `:806-809` corrects to "Comparisons 6, 7 and 8" and explains the transcription error. `grep -n "Comparison 9"` returns only the two correction-note lines. |

---

## Part B — blocking

### G4-B1 [BLOCKING] `FRONTIER` is *defined* as an unqualified absence, and the definition governs every use of the token

`expressible-vs-comparator.md:5-7`, the document's scope statement:

> …separated into the region where an established package could fit the same model
> (OVERLAP) and **the region where none can (FRONTIER)**.

"Where none can" is a class-A assertion about every capability the document later marks
FRONTIER. It names no searched set and no run. It is the first definition a reader meets and
it is 88 lines above the note that tries to weaken it.

The document then states the governing rule at `:70-73` — *"no sentence may assert that a
comparator is absent unless the same sentence names the set that was searched and whether a
comparator was actually run. A table cell, a parenthetical and a heading each count as a
sentence"* — and its own definition sentence fails that rule.

This is not pedantry about a heading. The token `FRONTIER` appears fifteen times inside the
per-family table alone (`:111-129`), plus in the four frontier classes below it, and in every
one of them it carries whatever the definition says it carries. Round 4 corrected ten cells one at a time while leaving the word they all use
defined as "none can". Correcting instances of a term is not correcting the term.

**Fix.** Redefine at `:7`: FRONTIER is *the region where this survey found no comparator in
the set it searched, or did not search* — with the searched set (`DESCRIPTION` `Suggests`,
never CRAN) named in the definition, since that is where it binds every downstream use. Then
the per-row class markers refine a scoped term instead of rescuing an unscoped one.

### G4-B2 [BLOCKING] Three per-family rows still assert FRONTIER with neither a class marker nor a search/run clause

Measured mechanically over the table (`:111-129`), rows containing `FRONTIER` and containing
no `class A/B/C` marker:

| Line | Family | The surviving sentence | Searched set named? | Run status named? |
| --- | --- | --- | --- | --- |
| `:114` | `student()` | "**FRONTIER** for phylo/spatial-structured nu or mu" | no | no |
| `:118` | `tweedie()` | "**FRONTIER** for any structured/phylo/spatial route" | no | no |
| `:126` | `cumulative_logit()` | "**FRONTIER** for the `phylo()` mu intercept" | no | no |

(Rows `:121` and `:128` also contain the token but state the *absence of a frontier cell*
— "no FRONTIER cell to report", "no RE surface exists to be FRONTIER yet" — which is not a
comparator-absence claim. They are fine.)

**Why these three survived, which is the finding.** `plan-repair-changelog.md` §3 records the
round-4 sweep verbatim: the six rows I named, plus *"the same bare `'no comparator fits …'`
phrasing was live in four more (skew_normal, beta, poisson, truncated_nbinom2)"*. Ten rows,
selected by searching for a phrase. These three rows contain no phrase — they assert absence
with the bare bolded token and nothing else, so a phrase search cannot see them.

That is the fourth consecutive string-shaped sweep, and it was run in the same round that
adopted the required-clause rule specifically because *"a blacklist cannot close an open
class"* (`PR2-build-plan.md:1009`) and that *"a grep for absence-shaped wording is a **finding
aid** … and is explicitly **not** the test"* (`:1037-1041`). The rule was written correctly and
then not used to do the sweep. The correct sweep is: enumerate every row of the table, and
for each, ask whether the cell asserts absence and whether the cell carries both clauses.
Seventeen rows, one pass, no search string.

**Aggravating detail on `:114`.** The student row's OVERLAP half names `gamlss` and `brms` as
comparators. `gamlss` is **ABSENT from this machine** (`PR2-build-plan.md:1429`;
`:886` "not installed on this machine at all") and `brms` is not in `Suggests` and was never
run (`feasibility-batch-4.md:63-69`). So the one row that asserts frontier without scope also
asserts overlap without evidence — see **G4-S1**.

**Fix.** One pass over all seventeen rows. Each of the three gets `class C — not searched
beyond `Suggests`, not run`, matching `:123` (poisson), which is the same claim shape and is
already compliant.

### G4-B3 [BLOCKING] The document-wide default at `:95-97` is a prose caveat repairing table cells — the mechanism that let G4-B2 through

`expressible-vs-comparator.md:95-97`:

> **Read every FRONTIER verdict below that carries no explicit class marker as class C**:
> "none known to this survey", not "none exists".

This is a blanket exemption for exactly the rows that fail the rule, installed 25 lines below
the rule it exempts them from. Two things are wrong with it:

1. **It contradicts the rule as stated.** `:70-73` requires the clause in *the same sentence*
   and says a table cell is a sentence. `:95-97` says an unmarked cell is fine because a
   paragraph elsewhere reinterprets it. Both cannot be the document's standard.
2. **It is the pattern the plan already ruled out at source.** `PR2-build-plan.md:771`,
   carrying my own A2: *"**No prose caveat elsewhere repairs a summary table**, so the table
   is fixed at source."* §5 rule 4 (`:795-798`) repeats it for the article's coverage table:
   *"A cell that says only 'none' fails the rule no matter what the surrounding prose says."*
   The same standard has to apply to the source document the article cites as its evidence
   trail, or the rule is enforced only where it is convenient.

The practical proof is G4-B2: the default was written to make unmarked rows safe, and its
existence is why nobody went looking for unmarked rows.

**Fix.** Delete `:95-97`'s blanket reading. Replace with a statement that every FRONTIER cell
carries its own class marker, and mark the three that do not (G4-B2). A default that says
"anything I missed is class C" guarantees the next sweep is also partial.

### G4-B4 [BLOCKING] Part 3's replacement heading asserts absence with neither clause, and its first half has no referent in Part 3

`PR2-build-plan.md:656-657`, mandated as the article's Part 3 heading:

> **"The frontier: what has no comparator, and what we did not check"**

I raised G-B2 against round 3's *"Where drmTMB has no comparator"* because a heading is the
highest-salience sentence in a section and that one was a blanket class-A framing over a
mixed list. The replacement is milder and still fails, on two counts:

1. **It carries neither required clause.** §8.5 is explicit that *"a section heading … is a
   sentence for this rule"* (`:1019-1020`). This heading names no searched set. "what we did
   not check" carries a run status for its second conjunct only.
2. **Its first conjunct has no referent in the section it titles.** Part 3's four classes are
   classified at `:699-732`: class 1 is **B** (a comparator exists and was run), classes 2, 3
   and 4 are **C** (not searched, not run), and the "also frontier" tail at `:734-736` is C.
   **No item in Part 3 is class A.** The heading tells the reader the section contains things
   that have no comparator; the section then says, correctly, that it contains one thing with
   a comparator and three things nobody looked for. The heading is refuted by its own
   contents.

The single class-A claim in the whole article is `rho12 ~ x`, and it lives in §5's coverage
table in Part 1 (`:783`), not in Part 3.

This is G-B2 recurring inside its own fix — the same defect class, one round later, in the
replacement text. That is the pattern Part D of `gate3-claims.md` measured, and it is why I
cannot pass this document on the strength of the narrowing alone.

**Fix.** Title Part 3 for what it contains: *"The frontier: what we checked, what we did not,
and what that leaves"*, or *"The frontier: four kinds of model, and what we know about each"*.
Neither asserts absence, so neither needs a clause.

---

## Part C — serious

### G4-S1 [SERIOUS] The required-clause rule is one-way: absence is governed, presence is not — and the unverified presence claims are all in the same document

§8.5 constrains only sentences asserting a comparator is **absent**. Nothing constrains a
sentence asserting one **exists**. `expressible-vs-comparator.md` is full of the latter, and
they are unchecked:

| Line | Claim | Status of the named comparator |
| --- | --- | --- |
| `:136-138` | "For all of these, `lme4`, `glmmTMB`, or family-specific packages (`ordinal`, `VGAM`, `sn`, `gamlss`) **fit statistically equivalent models and can serve as an oracle**" | `gamlss` **absent from this machine** (`PR2-build-plan.md:1429`, `:886`); `VGAM` and `sn` not in `Suggests`, never run (`Suggests` list quoted at `PR2-build-plan.md:887`) |
| `:114` | `gamlss`, `brms` "overlap partially" for Student-t | `gamlss` absent; `brms` not in `Suggests`, never run |
| `:115` | "`sn` package fits fixed-effect only, no RE" | `sn` never installed, never run — and this is simultaneously an *absence* claim about `sn`'s capability with no clause |
| `:118` | `cplm` for Tweedie | not in `Suggests`, never run |
| `:119`, `:121` | `gamlss` for beta; `VGAM` for beta-binomial | absent / never run |

An unverified OVERLAP claim is the same credibility defect as an unverified FRONTIER claim,
pointed the other way: it tells the reader a check is available that nobody has performed,
and it *shrinks* the apparent frontier. Doc 242's concern is that the two regions not be
blurred; a wrongly-placed boundary blurs them regardless of which side the error falls on.

This one is serious rather than blocking because the article does not inherit these
claims — Part 2 shows eight fits that were actually run, and the coverage table's OVERLAP
rows are all backed by executed comparators. But `expressible-vs-comparator.md` is the file
the article cites as its evidence trail (`PR2-build-plan.md:962-963`), and a reader who
follows the citation lands on "gamlss can serve as an oracle" for a package that is not
installed.

**Fix.** Extend §8.5 to presence: a sentence asserting a comparator *fits* names whether it
was run, or says "not tried". Then mark the six rows above.

### G4-S2 [SERIOUS] The "Also frontier" tail is scoped in the plan and unscoped in the source

`expressible-vs-comparator.md:240-243`:

> Also frontier: `zero_one_beta()`'s zoi/coi random-effect cells (no package known to this
> survey shares the exact four-parameter … grammar), **and any zero-inflation/hurdle random
> effect beyond the two diagnostic-only `spatial()`/`relmat()` intercepts noted above.**

The first conjunct is scoped ("known to this survey") though it still gives no run status.
The second conjunct is bare. `PR2-build-plan.md:734-736` states the same fact correctly —
*"Not searched, not run"* — so the plan is right and its cited source is weaker. Since the
plan's own §11 exists to fix the source before it is cited, this belongs there.

**Fix.** Append "; neither was searched beyond `Suggests` and neither was run" to `:243`.

### G4-S3 [SERIOUS] `feasibility-batch-4.md:126-127` still asserts absence with no clause and is not quarantined

Read in place (`feasibility-batch-4.md:124-127`):

> `expressible-vs-comparator.md:79` classes formula-capable `biv_gaussian()` `rho12` as
> FRONTIER — expressible by drmTMB but **with no comparator to check it against**

No searched set, no run status, and the line number it cites is stale: read in place,
`expressible-vs-comparator.md:78-81` is now the "what was searched" bullet list (the
`glmmTMB`/`sleepstudy` run), not the `biv_gaussian()` row it claims to be quoting. §11
schedules the repair (`PR2-build-plan.md:1319`) and the corrected `biv_gaussian()` row
carries a matching note (`expressible-vs-comparator.md:127`, "*Citation note*"). Good.

What is missing is the quarantine. §15.1 forbids citing `candidate-cells.md` until its
`:97-99` is corrected (`PR2-build-plan.md:1549-1553`). There is no equivalent line for
`feasibility-batch-4.md:126-127`. Measured: the plan names that file twelve times, at ranges
`:24-29`, `:52-73` (×4), `:111-115`, `:113-115`, `:126-127` (×2), `:137-139` — and both
`:126-127` hits are inside §11's correction table (`:1318`, `:1319`), i.e. references to the
defect, not appeals to it as authority. So no live citation is contaminated today. But the
asymmetry is an invitation.

**Fix.** Add `feasibility-batch-4.md:126-127` to §15's do-not-cite list until §11's repair
lands, matching the treatment `candidate-cells.md` gets.

### G4-S4 [SERIOUS] §14 step 2's wording lets the classification checks' output into an article chunk

`PR2-build-plan.md:1509-1515` (§14 step 2):

> One script that fits the 8 article drmTMB models and their 8 comparators, **runs the 2
> classification checks from §1.2**, prints full-precision output … **The article's chunks
> are written from this script's output.**

Read literally, the script's output includes the c02 and c10 classification checks, and the
article's chunks are written from the script's output. A builder following the sentence has
permission to put `Variance = 1.521243e-12` into a chunk — which P3 forbids absolutely
(`:197-201`), §1.2 forbids by name (`:97-101`), and §4.2's builder-prohibition list forbids
item by item (`:738-742`). Everything else in the plan is unambiguous; this one sentence is
not, and it sits in the build order where a builder will actually read it.

**Fix.** "The article's chunks are written from this script's **eight-comparison** output;
the two classification checks are recorded in the script and quoted nowhere in the article."

### G4-S5 [SERIOUS] §5's coverage table carries the two frontier runs in words, under §8.5 only — the no-demonstration guard is stated for Part 3 and not for Part 1

`:782-783`, both in Part 1 of the article:

> **no *working* comparator: `glmmTMB` accepts the syntax, was run on one dataset, and did
> not converge; `gamlss` not installed, not tried**

> **none found in the packages this article depends on — the one that could take a
> two-response model was run and rejected it**

These are §8.5-compliant and I am not asking for them to be removed — §1.2 explicitly
permits a run to warrant a classification without the model being shown (`:97-101`). The gap
is that §4.2's concrete guard — *"do not name the dataset either run used, do not quote the
rejection message or the convergence warning verbatim, do not give a variance"* (`:738-741`)
— is written as governing Part 3 ("here"), and these two cells are in Part 1. The current
drafts obey it, but nothing in §5 says they must. §5's four rules (`:786-798`) cover totals,
"none" columns, `candidate-cells.md:48`, and §8.5 compression — not this.

**Fix.** Add §5 rule 5: the comparator-status column obeys §4.2's builder prohibitions —
classification in words, no dataset name, no verbatim message, no number.

---

## Part D — the pattern, measured again

Four rounds, one class, and this round is the informative one because the *rule* was finally
right and the *sweep* still was not.

| Round | Enforcement in force | How the sweep was executed | What survived |
| --- | --- | --- | --- |
| 1 → 2 | none | fix what the audit named | Part 3's prose; two source lines |
| 2 → 3 | 5-string blacklist, grepped over the article | fix what the audit named | a sixth string (a mandated heading); a whole per-family table in a cited source |
| 3 → 4 | **required-clause rule, all documents, checked by reading** | **searched for the phrase `"no comparator fits …"`; ten rows touched** | three rows carrying the bare token; the term's own definition; the replacement heading |

The rule adopted in round 4 is correct and I would not change it. What round 4 did not do is
apply it as a rule. `PR2-build-plan.md:1037-1041` says the test is *"locate every sentence in
the deliverable that says something is absent, and confirm both clauses are present in that
sentence"* — an enumeration over sentences, terminating, with a definite answer per sentence.
The changelog records an enumeration over *matches for a phrase*, which is the finding aid
the same paragraph says is not the test.

The four blocking findings above are what an enumeration finds and a phrase search cannot:
a definition (G4-B1), three cells with no phrase in them (G4-B2), a default that exempts
whatever the sweep missed (G4-B3), and a heading (G4-B4) — the same slot the last round's
blocking finding occupied.

**One structural recommendation, which is cheap.** The seventeen-row per-family table is the
whole surface. Add a column: **Claim class (A/B/C) · searched · run**. A row with an empty
cell in that column is visibly incomplete, to anyone, without a sweep. That converts the rule
from something a reader must apply into something the table's shape enforces. It is the same
move that made §5's coverage table auditable, applied one document upstream.

---

## What I checked and did not find a problem with

Recorded so the next auditor does not redo it.

- All eight retained cells trace to an executed fit with a batch line range (`:64-73`);
  spot-checked c08 → `feasibility-batch-3.md:138-144`, c05 → `feasibility-batch-2.md:118-129`,
  c09 → `feasibility-batch-3.md:208-213`. All resolve.
- The c08 tolerance is stated honestly at ~1e-3 with the non-convergence explanation
  (`:291-299`), not rounded down to match the tighter cells.
- c05's comparative-heterogeneity conclusion is still rejected and the replacement wording
  still cites `ev-mc-0260m-meta-v`'s recorded boundary (`:374-387`).
- The WEAK/STRONG vocabulary rule (`:830-837`) and the no-totalling rule survive, and §6.3's
  mandatory draft still obeys them (the R3 conflict is not back).
- The `-2 *` versus `+2 *` family-signed conversion trap (`:635-641`) and the "two conversion
  shapes verified, never 'the conversion table is verified'" limit (`:891-899`) are intact.
- §15's eight-item "what round 4 did not fix" list is honest and matches what I found
  independently, including the admission at `:1580-1585` that §9, §12 and the c04–c09
  specifications are two rounds unaudited. I did not audit them either; that limit still
  stands from the audit side.

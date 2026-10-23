# PR 2 build plan — Phase 19 reader-facing comparator article (issue #60)

Author: Ada (integrator). First issue 2026-08-14; repaired 2026-08-14 after Rose's claims
audit and Noether's scale audit; repaired again 2026-08-14 (round 3) after both re-audits
returned NOT-DONE; narrowed 2026-08-15 (round 4) on the maintainer's decision, after
`gate3-claims.md` returned NOT-DONE for the third consecutive round; **restructured
2026-08-15 (round 5) after `gate4-claims.md` returned NOT-DONE with four blocking findings,
and on a second maintainer decision that cuts the frontier narrative from the article
entirely.**
Worktree: `.worktrees/phase19`, branch `claude/phase19-comparator-workflows`, off
`origin/main@82cd00560`, drmTMB 0.7.0 (`DESCRIPTION:3`).

**What round 5 changed, in one sentence: the article now makes presence claims only.** Round
4 dropped the two frontier *fits* and kept a Part 3 that named and classified the frontier in
words. Round 5 drops Part 3 as well. The article is eight verified comparisons and the scope
statement that frames them; it asserts nothing about what has no comparator. The frontier
classification is not deleted — it lives in this plan (§4) and in
`expressible-vs-comparator.md`, which are design and planning documents, not reader-facing
ones.

**Why that is the right cut rather than a fifth repair.** Four consecutive rounds killed the
same defect — an unqualified assertion that no comparator exists — at every site the audit
named, and it reappeared elsewhere each time. Round 4's own sweep was a search over a phrase,
run in the round that adopted a rule saying a grep "is explicitly not the test"
(`gate4-claims.md` Part D). Two structural conclusions follow, and round 5 applies both:

1. **In the source documents, make incompleteness visible instead of sweeping for it.**
   `expressible-vs-comparator.md`'s seventeen-row table now carries three dedicated columns —
   claim class, set searched, actually run? — filled by enumerating all seventeen rows. An
   empty cell is a defect on sight. The term FRONTIER is itself redefined, since a corrected
   instance of a term is not a corrected term (`gate4-claims.md` G4-B1).
2. **In the article, remove the claim class rather than govern it.** A reader vignette that
   makes no absence claim cannot make a false one. This is the same move as round 4's, one
   level up: round 4 deleted the *demonstrations* the claim attached to; round 5 deletes the
   *narrative*.

Full reasoning: `gate3-claims.md` Part D and `gate4-claims.md` Part D. What changed
structurally, per finding: `plan-repair-changelog.md`, "Round 5 — structural".

Reader: the session that builds PR 2. This is the plan only — no vignette, no test, no
ledger row is written here.

Synthesised from, and superseding for build purposes:
`158-plan-of-record.md`, `dataset-inventory.md`, `expressible-vs-comparator.md`,
`reader-gap-audit.md`, `candidate-cells.md`, `feasibility-batch-1.md` …
`feasibility-batch-4.md`, `adversarial-scales.md`, `adversarial-claims.md`,
`regate-claims.md`, `regate-scales.md`, `gate3-claims.md`, `gate3-scales.md`
(all in `docs/dev-log/external-oracle/phase19/`).

Where those documents disagree, this plan states which one wins and why. Several of them
contain errors that must be fixed before they are cited (§11).

**The surviving deliverable, stated once so it cannot drift:** eight comparator cells
verified VIABLE by real fits on both sides, presented as eight comparisons, **with no
frontier fit displayed and no frontier narrative in the article at all.** The article's only
statement about its own scope is that it compared eight models against packages listed in
drmTMB's `DESCRIPTION` `Suggests`, and a pointer to the design documents for what else the
package implements.

---

## 0. Decision summary

| Question | Decision |
| --- | --- |
| Deliverable | One new reader vignette, `vignettes/comparing-with-other-packages.Rmd`, plus targeted edits to `docs/design/158-phase-19-comparator-matrix.md`. |
| Cells that survived feasibility | **8** VIABLE by an actual fit. Not 10. |
| Frontier fits included | **None.** Round 4 dropped both (§2.4). |
| Frontier *narrative* included | **None — new in round 5 (§2.5).** The article makes presence claims only. Part 3 is removed; the frontier classification stays in this plan (§4) and in `expressible-vs-comparator.md`. |
| What the article may say about its own scope | One sentence: it compared eight models against packages listed in `DESCRIPTION` `Suggests`, and the design docs record the rest of the implemented surface. It names the set searched and asserts nothing about what exists outside it. |
| Article ordering axis | **Independence strength first**, conversion shape second (§2.2). The three WEAK-independence agreements are grouped, labelled, and read last — not first. |
| Coverage table | The "distributional submodel" row is **split** into fixed-effect and random-effect halves (§5). |
| Comparator-absence claims | **A required-clause rule, not a banned-string list** (§8.5): no sentence may assert comparator absence unless the same sentence names the set searched and whether a comparator was actually run. Three claim classes (found-nothing / fits-and-fails / not-tested) are how a compliant sentence is built. **Round 5 makes the rule two-way** — a sentence asserting a comparator *exists and fits* must name the package and whether it was run. The article makes no absence claim at all, so the rule binds this plan and the source documents; §14 step 7 checks it. |
| `rho12` link | **`rho12 = 0.999999 * tanh(eta)`**, re-verified against source (§11). This now governs the **source-document corrections and doc 158 only** — the article no longer states any `rho12` link, because it no longer shows the `rho12` model. Plain `atanh`/`tanh` remains wrong **for the `rho12` dpar**; the admitted binomial `q = 2` random-effect correlation is deliberately **unguarded** (`src/drmTMB.cpp:3330`, `R/drmTMB.R:21581`, both verified in place in round 3) and no Phase 19 cell touches it. |
| New capability-ledger rows | **None.** Recommend zero rows; maintainer sign-off required (§10.4). |
| Timing / speed claims | **Dropped.** Reproducibility metadata recorded instead; reasons in §12. Needs maintainer sign-off against #60's "timing summaries" wording. |
| Runtime | Authoring + all fits: well under 30 min. `pkgdown::build_site()` and `--as-cran`: **flagged, likely >30 min, D-139 approval needed** (§13). |

---

## 1. The cell list

### 1.1 The eight comparison cells

Eight cells were verified VIABLE by an executed fit on both sides with a matched-scale
comparison. The **article number** column is the number the reader sees; it is assigned by
the ordering rule in §2.2, not by the internal build id.

| Article # | build id | Family / route | Dataset | Comparator | Independence | Verdict | Source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | c08 | `binomial()` + herd RE | `lme4::cbpp` | `lme4::glmer` | **STRONG** | VIABLE at ~1e-3 | `feasibility-batch-3.md:138-144` |
| 2 | c04 | gaussian + `meta_V(V = vi)` | `metadat::dat.bcg` | `metafor::rma.uni(method="ML")` | **STRONG** | VIABLE | `feasibility-batch-2.md:46-52` |
| 3 | c05 | `meta_V` with `sigma ~ alloc` | `metadat::dat.bcg` | `metafor::rma.mv(struct="DIAG")` | **STRONG** | VIABLE | `feasibility-batch-2.md:118-129`, upgraded by `adversarial-scales.md:186-214` |
| 4 | c06 | `cumulative_logit()`, fixed effects | `ordinal::wine` | `ordinal::clm` | **unclassified** (§10.3) | VIABLE | `feasibility-batch-2.md:183-191` |
| 5 | c07 | `cumulative_logit()` + judge RE | `ordinal::wine` | `ordinal::clmm` | **unclassified** (§10.3) | VIABLE | `feasibility-batch-3.md:60-68` |
| 6 | c01 | gaussian location-scale, `sigma ~ Days` | `lme4::sleepstudy` | `glmmTMB` `dispformula` | **WEAK** | VIABLE | `feasibility-batch-1.md:40-43` |
| 7 | c09 | `lognormal()`, `mu ~ species`, `sigma ~ sex` | `palmerpenguins::penguins` | `glmmTMB` gaussian on `log(y)` | **WEAK** | VIABLE | `feasibility-batch-3.md:208-213` |
| 8 | c03 | nbinom2, `sigma ~ FoodTreatment` | `glmmTMB::Owls` | `glmmTMB` `dispformula` | **WEAK** | VIABLE | `feasibility-batch-1.md:142-149` |

Strength classifications: `lme4` and `metafor` STRONG, `glmmTMB` WEAK, per
`docs/design/242-external-comparator-evidence-class.md:108-111` (re-read in place this
round). `ordinal` is undeclared there — §10.3.

**Each dataset now appears in the article exactly as often as Part 2 needs it.** `sleepstudy`
appears once (Comparison 6), `penguins` once (Comparison 7), `Owls` once (Comparison 8).
`dat.bcg` appears twice (Comparisons 2 and 3) and `wine` twice (Comparisons 4 and 5), but
both repeats are inside Part 2 between two *agreeing* comparisons, so neither creates the
overlap-next-to-frontier adjacency that Rose A1 objected to. That adjacency is gone from the
document entirely (§2.4).

### 1.2 The two frontier fits — dropped from the article, retained as classification evidence

**Changed in round 4, and again in round 5.** Round 3 kept these two models in a Part 3
"register". Round 4 took them out of the article and let their runs warrant two sentences in
Part 3's classification. **Round 5 removes Part 3 from the article too**, so these runs now
warrant nothing the reader ever sees. What they still warrant, and what this table is for, is
the claim class recorded in **this plan's §4** and in `expressible-vs-comparator.md`'s
per-family table — design and planning documents, where the classification belongs.

| build id | Model | Status in PR 2 | What its run still supports | Source |
| --- | --- | --- | --- | --- |
| c02 | `sigma = ~ (1 \| Subject)` on `lme4::sleepstudy` | **Not in the article, in any form.** No drmTMB fit, no comparator output, no number, and after round 5 no classification sentence either. | The single fact that class 1 of the frontier is a **class B** absence, not class A: `glmmTMB` accepts `dispformula = ~ (1 \| Subject)`, runs, and returns a dispersion variance component, degenerate on this one dataset. That fact is recorded in this plan (§4, §8.3) and in `expressible-vs-comparator.md`'s `gaussian()` row. Without this run, both would be entitled to say only "not tested". | `feasibility-batch-1.md:66-73` (re-read in place round 4); re-run in round 3 (§11.1) and independently reproduced by Rose (`gate3-claims.md:256-269`) |
| c10 | `rho12 ~ species` on `biv_gaussian()`, `palmerpenguins::penguins` | **Not in the article, in any form.** No drmTMB fit, no fitted correlations, no `rho12` link statement, no classification sentence. | The single fact that predictor-dependent `rho12` is a **class A** absence *within `DESCRIPTION` `Suggests`* rather than an untested one: the only `Suggests` package that could take a two-column response was run and rejected the call — `glmmTMB(cbind(bill_length_mm, bill_depth_mm) ~ species)` returns `"matrix-valued responses are not allowed"`. Recorded in §4 and in `expressible-vs-comparator.md`'s `biv_gaussian()` row. | `feasibility-batch-4.md:52-73` (re-read in place round 4) |

**The distinction the build session must hold, restated for round 5.** A run may be cited as
the *warrant for a classification* without the model being *shown* — but after round 5 the
only documents that carry such a classification are this plan and the design/survey files.
**The vignette carries neither the demonstration nor the classification.** The builder never
faces the question "how do I phrase this absence claim safely?", because the article contains
no absence claim to phrase. §2.5 states the rule; §14 step 6 checks it.

### 1.3 Composition disclosure, mandatory in the article's opening (Rose B1)

The article compares **eight** models. That is not a sample of drmTMB's implemented surface;
it is the part of it that another package can fit. Classifying
`docs/dev-log/dashboard/capability-ledger/cells.tsv` by `axis == "model_surface"` and
`capability_status == "implemented"` gives 268 of 341 implemented cells (79%) sitting in or
beside the frontier, leaving at most ~21% comparator-eligible
(`adversarial-claims.md:110-133`; that classification is marked AGENT-INFERRED by its author,
reproducible from the file, indicative rather than certified).

**The 79% / 21% figures are this plan's own AGENT-INFERRED derivation, and no percentage
appears in the article** (added in round 6, `gate5-claims.md` G5-S5). "At most ~21%
comparator-eligible" is an absence claim about the other 79%, expressed as a number, sitting
in the section a builder reads while drafting the article's opening; "instead" below scopes it
but does not forbid it, and §5 got an explicit prohibition (rule 4) where this section had
only an implication. The article carries the bold sentence below and no figure from this
paragraph. §11's round-4 note records that this 79% is AGENT-INFERRED and is about a different
quantity than the claim it was once used to support.

**Reworded in round 5, and this is the load-bearing sentence of the whole scope change.**
Round 4's version read: *"these models were chosen because they can be compared, and most of
drmTMB's implemented surface cannot be."* The second half is an absence claim about drmTMB's
whole surface, in the article's opening, with no searched set and no run status — the exact
shape §8.5 forbids, sitting in the one paragraph the article cannot drop. The article must
instead say, in its own words, that **these eight models were chosen because a package in
this article's dependency set fits them too, and that set is small relative to what drmTMB
implements — the design documents record the rest.** That claim is about *this article's
coverage*, which the article can support, rather than about *what exists elsewhere*, which it
cannot. The coverage table in §5 carries the same fact in tabular form under the same
constraint.

**Deleted in round 4:** the "eight of these ten models have a comparator that produces a
usable fit" sentence, and the nine-versus-eight distinction behind it. Both existed to keep
the article honest about the two frontier models it was showing. With those models gone,
there is one count in the article — **eight comparisons** — and no second count to confuse
it with. The nine-versus-eight fact survives where it is still load-bearing, in §1.2's
classification warrant.

---

## 2. Article architecture

Rose A1 (BLOCKING, round 1): each frontier model was paired with an agreeing overlap cell on
the same dataset — sleepstudy then sleepstudy, penguins then penguins — with the same
narrative voice and the same escalating reader question. `docs/design/242-…:86-91` (re-read
in place this round) does not say *label* the two; it says a design that **blurs** them is
credibility-laundering, and same-dataset sequential presentation blurs by construction.

Round 2 answered this with a disclaimer. Round 3 answered it with architecture — eight
structural rules and a claim-class vocabulary. **Round 4 answers it by removing the
frontier fits**, which is the answer the plan itself had already identified as the strongest
available (round 3's §2.4, "the strongest possible answer to A1") and left open to the
maintainer. The maintainer took it.

### 2.1 The two-part shape

**Changed in round 5: there is no Part 3.**

```
Part 1  Why this article exists          purpose · boundary paragraph · composition
                                          disclosure (§1.3) · coverage table (§5)
Part 2  Eight models both packages fit    three strength-labelled blocks (§2.2)
        ── closing summary: what Part 2 established and its exact scope (§6.3) ──
        ── the article ends here ──
```

The article ends on its own scope summary. That summary is now doing the job Part 3's opening
non-transfer sentence used to do — stating what these eight agreements are evidence for and
what they are not — and it does it without asserting anything about models nobody compared.

**Why ending on the comparisons is not a softer ending.** The worry Part 3 answered was that a
reader would finish an article full of agreements believing drmTMB's models generally have
counterparts elsewhere. Round 5 answers that with three devices that make no absence claim:
§1.3's composition disclosure in the opening (these eight were chosen because a dependency
fits them too), Comparison 4's demonstrated asymmetry in the comparator's favour
(`ordinal::clm(scale = ~ temp)` fits a model drmTMB rejects), and §6.3's closing scope
summary. None of the three says a comparator is missing anywhere.

### 2.2 Part 2 is ordered by independence strength, not by dataset or by drama

This is the A3 fix. Three sub-headed blocks:

| Block | Heading (draft) | Cells | Independence |
| --- | --- | --- | --- |
| 2a | "Checked against a separate estimation engine" | 1 (c08), 2 (c04), 3 (c05) | STRONG — `lme4`, `metafor` |
| 2b | "Checked against `ordinal`" | 4 (c06), 5 (c07) | not yet classified in doc 242 (§10.3) |
| 2c | "Checked against a package built on the same machinery" | 6 (c01), 7 (c09), 8 (c03) | WEAK — `glmmTMB` |

Two consequences, both deliberate:

1. **Opening position, the heaviest rhetorical slot, goes to a STRONG agreement** (`lme4` on
   `cbpp`), not to the WEAK glmmTMB location-scale flagship.
2. **The WEAK block is framed before it is read.** Its heading and its opening sentence state
   the shared TMB/AD stack. A reader cannot arrive at c01's `1e-7` without having been told
   what kind of check it is.

Article order is therefore **c08, c04, c05, c06, c07, c01, c09, c03**, then §6.3's closing
scope summary, and that is the end of the article (§2.1).

**Deleted in round 4: consequence 3 and the whole adjacency calculation behind it.** Round 3
traced how many comparisons separated each frontier model from its overlap twin, swapped
Part 3's subsections to widen the gap, and recorded the separations dataset by dataset (Rose
R5). None of that has anything to describe now: there is no frontier model to be adjacent to.
The ordering above stands on independence strength alone, which is the reason it was chosen
in the first place.

Within each block, order by conversion difficulty so the pedagogy survives: identity first,
then the traps. Block 2c therefore runs c01 (identity) → c09 (identity with a Jacobian and a
`meanlog` trap) → c03 (non-identity `-2×`, and the trap that c01's rule does not transfer).

### 2.3 Part 3 build rules — P1 to P5, all retired in round 5

**Round 4's P1–P5 governed a Part 3 the article no longer has.** They are recorded here with
what each guarded, because a rule deleted without its rationale is a rule that gets
reinvented badly. The replacement is a single rule, §2.5's A1, which forbids the surface
rather than governing it.

| Round-4 rule | What it guarded | Why it is gone |
| --- | --- | --- |
| **P1** — no numbers, no enumeration in Part 3 | stopping Part 3's classes from reading as a fifth, sixth, … comparison | No Part 3. |
| **P2** — Part 2 closed by a scope summary before Part 3 opens | a stated boundary rather than a heading between agreement and frontier | The scope summary survives and is now the article's ending (§2.1, §6.3). Nothing follows it to be bounded from. |
| **P3** — Part 3 contains no model, dataset, chunk, estimate or digit | stopping a classification turning back into a demonstration | Subsumed by A1: the section it constrained does not exist. The prohibition survives verbatim as the builder-prohibition list in §4, which now governs **this plan's** frontier record rather than any article text. |
| **P4** — every Part 3 sentence obeys §8.5 | stopping an unscoped absence claim in the article | The article has no absence claim to scope. §8.5 still binds this plan, the PR body, the after-task report and every source document §11 corrects — see §8.5's "where the rule is enforced". |
| **P5** — Part 3 closes on the frontier, not on a win | stopping the article ending on a package comparison | Replaced by §6.3's closing summary, which ends on scope rather than on a win and makes no absence claim. |

**Deleted in round 4, with what each was for** (retained for the same reason):

| Round-3 rule | What it guarded | Why it is gone |
| --- | --- | --- |
| F2's mandated heading *"Where drmTMB has no comparator"* | naming Part 3 | The heading was itself a blanket class-A framing over a mixed list — `gate3-claims.md` G-B2, BLOCKING. Round 4 replaced it with *"The frontier: what has no comparator, and what we did not check"*, which **failed the same rule twice over** (`gate4-claims.md` G4-B4, BLOCKING): it names no searched set, and its first conjunct has no referent, since no Part 3 class was class A. **Round 5 mandates no article heading at all**, because there is no article section to head. §4's heading is retitled for the same finding. |
| F3's *"Two of these four are shown below"* | telling the reader which classes were illustrated | False for the second model (`gate3-claims.md` G-S4: `rho12 ~ x` was inside class 4's *neighbourhood*, not an instance of it). Nothing is shown below now, so the sentence has no referent. |
| F4's no-agreement-arithmetic rule and its draft gate | keeping Part 2's tolerance figures out of Part 3 | Subsumed by P3, which forbids every digit rather than every *comparative* digit. |
| F5's restart rule and its banned back-references | stopping Part 3 from leaning on Part 2's narrative | There is no Part 3 narrative to lean. |
| F6's per-subsection governing ledger cell | stopping an ungoverned drmTMB estimate | No drmTMB estimate appears in Part 3. |
| F7's per-model non-transfer sentence | stopping Part 2's agreements from reading as support | Round 4 replaced it with a non-transfer sentence in Part 3's opening plus §8.2's boundary paragraph. **Round 5 re-homes it**: with Part 3 gone, the non-transfer statement lives in §8.2's boundary paragraph (Part 1) and in §6.3's closing summary (the article's last words). Both are §2.5-compliant — they say what the agreements do *not* license, which is a statement about this article's evidence, not about what exists elsewhere. |
| §4.2 and §4.3's interval guards (`mc-0266`, `mc-0181`) | stopping two `interval_feasible` tiers from reading as calibrated intervals | Both existed only to constrain a displayed estimate. No estimate, no guard needed. **The underlying facts are not deleted** — they are recorded in §15 as live constraints on any future write-up of those capabilities. |
| The `0.506` vs `1.233e-06` matched-scale pairing | a compliant-but-provocative comparison F4 permitted | Deleted by P3. |

### 2.4 The escalation, taken

Round 3 recorded three options against Rose A1 and took the weakest of the three that
preserved the cells. Recording the disposition of all three so a reviewer does not re-derive
it:

- **Rejected: substitute a different dataset for the frontier models.** Forbidden by the
  standing rule that only cells verified VIABLE by an actual fit may appear. A
  `sigma = ~ (1 | Nest)` fit on `Owls` was never run; proposing it would put an unfitted
  model in a reader vignette.
- **Rejected: drop c01 and c09 from Part 2 instead.** This also breaks the adjacency, but it
  costs the two clearest location-scale reader stories and the only two demonstrations of
  drmTMB's stated differentiator, leaving c03 as the sole residual-scale comparison — still
  WEAK, so it does not even fix A3. Net loss.
- **TAKEN 2026-08-15 (maintainer decision): drop the frontier fits from the article
  entirely** and let Part 3 name and classify the frontier without demonstrating any of it.

**What this costs.** Two reader stories: "can the residual spread itself have a random
effect?" and "does bill shape co-vary differently across species?". Both were frontier
illustrations that round 3's own §4.2 and §4.3 already forbade the reader from trusting
quantitatively. The article loses two vivid pages and keeps every claim it can support.

**What this buys, beyond the two reader stories.** The recurring defect is structural, not
stylistic: three rounds of repair each closed the false-absence claim at every named site and
it reappeared elsewhere (`gate3-claims.md` Part D's table). The claim kept being *needed*
because the article kept showing a frontier model and then having to say what does and does
not exist about it. Without the demonstrations, the frontier is stated once, classified once,
and checked once. The residual A1 risk that three rounds named and none fixed — `sleepstudy`
and `penguins` each appearing twice in one document — is also gone, because each now appears
once (§1.1).

**No build gate remains for this.** Round 3 carried a conditional gate ("if Part 3 cannot
satisfy F4 while remaining readable, drop the frontier fits"). The condition has been decided
in advance; §14 step 6 now checks compliance against the draft rather than deciding scope at
draft review.

### 2.5 The second escalation, taken 2026-08-15 — the frontier narrative leaves the article

**Maintainer decision, round 5.** The reader article makes **presence claims only**: the eight
verified comparisons and nothing else. The "what has no comparator" narrative is cut from the
article entirely and lives only in the design and planning documents — this plan's §4 and
§8.3, `expressible-vs-comparator.md`, and `docs/design/158-…` / `242-…`.

**A1 — the one rule that replaces P1–P5.**

> **No sentence in the vignette may assert, imply, or classify the absence of a comparator
> for any capability.** Not in a heading, a table cell, a footnote, a caption, a chunk
> comment, or a closing paragraph. The article states what it compared and what those
> comparisons license; it states nothing about what does or does not exist outside them.

**The one permitted scope acknowledgment, and its exact bounds.** The article may say that
this survey compared eight models against packages listed in drmTMB's `DESCRIPTION`
`Suggests`, and may point to the design documents for the rest of the implemented surface.
That sentence **names the set searched**, which is what makes it sayable. It may not add
"and nothing fits the rest", "the rest has no comparator", "most of it cannot be compared",
or any variant. The distinction is between *what this article covered* — supportable — and
*what exists elsewhere* — not searched, not run, and now not the article's subject.

**Why this is a structural change and not a fifth rewording.** The recurring defect needs a
place to live: a sentence in a reader document that classifies the comparator landscape.
Rounds 2–4 governed that sentence with, successively, a disclaimer, a five-string blacklist,
and a required-clause rule; each was correct and each was applied by a sweep that missed
something. Round 5 removes the sentence's habitat from the deliverable. What remains
governed by §8.5 is a set of design and planning documents, which is a bounded surface with a
structural check of its own (`expressible-vs-comparator.md`'s three per-row columns).

**What this costs, stated plainly.** A reader of the vignette alone will not learn from it
that most of drmTMB's implemented surface **was not compared against any package in
`DESCRIPTION` `Suggests`, and that nothing beyond that set was searched** (rescoped in round
6, `gate5-claims.md` G5-S2 — the unclaused form of this sentence is the one §1.3 removed from
the article, and this plan asserted it three times while removing it). That fact is true, it
matters, and it is now recorded only where a reader has to follow a pointer to find it. Two partial
compensations, neither equivalent: §1.3's composition disclosure tells the reader these eight
were *selected* for comparability, and Comparison 4 demonstrates an asymmetry in the
comparator's favour. The maintainer accepted this cost on 2026-08-15 in exchange for an
article that cannot carry the defect. **Record it in the PR body**, so a later session does
not read the omission as an oversight and restore Part 3 without the reasoning.

---

## 3. Part 2 — cell-by-cell build specification

Every drmTMB call is fitted with `devtools::load_all()` against this 0.7.0 worktree, never
the installed 0.6.0. Every number quoted below came from an executed fit recorded in the
feasibility batches or in §11.1; the building session must re-run them and use its own
output, not transcribe these.

### Block 2a — checked against a separate estimation engine (STRONG)

Block opening sentence, draft: *"The three comparisons in this section are against `lme4`
and `metafor`, which share no estimation code with drmTMB
(`docs/design/242-external-comparator-evidence-class.md:108-109`). Agreement here is a
genuine cross-implementation check."*

#### Comparison 1 (c08) — Contagious bovine pleuropneumonia risk across periods and herds

- **Reader question.** "This is the `glmer` binomial example I learned mixed models on.
  Does drmTMB reproduce it?"
- **Dataset.** `lme4::cbpp`, 56 rows, 15 `herd`.
- **drmTMB.**
  ```r
  drmTMB(bf(mu = cbind(incidence, size - incidence) ~ period + (1 | herd)),
         data = cbpp, family = binomial())
  ```
- **Comparator.**
  ```r
  lme4::glmer(cbind(incidence, size - incidence) ~ period + (1 | herd),
              family = binomial, data = cbpp)
  ```
- **Matched quantities and exact conversion.** None — logit coefficients directly, and the
  herd RE SD against `attr(VarCorr(gm)$herd, "stddev")`. Both are `nAGQ = 1` Laplace.
- **Tolerance, stated honestly at ~1e-3, not 1e-4.** Differences are `-1.9e-04` to
  `-5.8e-04` on the fixed effects, `1.9e-04` on the RE SD, `2.9e-04` on `logLik`. This gap
  is **not** rounding and **not** under-convergence: refitting `glmer` with
  `optCtrl = list(maxfun = 2e5, xtol_abs = 1e-12, ftol_abs = 1e-12)` reproduces the loose
  fit to six decimals. It is a stable package-level difference between TMB's AD inner
  Laplace solve and lme4's PIRLS Laplace solve, and it sits well inside the
  Laplace-versus-`nAGQ = 25` gap that both packages share
  (`feasibility-batch-3.md:107-127`). Report the tolerance; do not round it down to match
  Comparisons 5 and 7.
- **Reader's conclusion.** Infection risk falls monotonically after period 1, and the two
  packages agree at the level a Laplace-vs-Laplace comparison actually supports.
- **Limitation to name.** `binomial()` here is `stats::binomial()` re-exported, with no
  dispersion parameter. `cbpp`'s known extra-binomial variation is unmodelled on **both**
  sides — symmetric, not a discrepancy. Point the reader at `beta_binomial()` or
  `nbinom2()`.
- **Independence: STRONG** (`lme4`).

#### Comparison 2 (c04) — Pooled BCG vaccine effect and its heterogeneity

- **Reader question.** "I run meta-analysis in `metafor`. If I write the same model in
  drmTMB, do I get the same pooled log risk ratio and the same `tau^2`?"
- **Dataset.** `metadat::dat.bcg`, 13 trials (Colditz et al. 1994), effect sizes built with
  `metafor::escalc(measure = "RR", ai = tpos, bi = tneg, ci = cpos, di = cneg)`.
- **drmTMB.**
  ```r
  drmTMB(bf(mu = yi ~ 1 + meta_V(V = vi), sigma = ~ 1), data = dat, family = gaussian())
  ```
- **Comparator.**
  ```r
  metafor::rma.uni(yi, vi, data = dat, method = "ML")
  ```
  **`method = "ML"` is mandatory.** `rma.uni()` defaults to REML; the default gives
  `b = -0.7145323`, `tau2 = 0.3132433` against drmTMB's ML `-0.7111990`, `0.2800281` — a
  silent estimator mismatch, confirmed by running it (`feasibility-batch-2.md:34-38`).
  Doc 158's matched-scale table has no estimator column at all, so this has to be said in
  the article, not assumed.
- **Matched quantities and exact conversion.** `V` is known input data on both sides.
  drmTMB reports `log(tau)` as the `sigma` intercept; metafor reports `tau^2`. Convert with
  **`tau^2 = exp(2 * coef(fit, "sigma"))`**. Verified beyond parameter agreement: the two
  log-likelihoods are identical at `-12.66507635`, so the two packages are maximising the
  same function, and the conversion is forced rather than merely consistent
  (`adversarial-scales.md:145-162`; source `R/methods.R:5433-5435`,
  `drm_total_obs_sd(v_known, sigma) = sqrt(v_known + sigma^2)` — verified in place in round 3).
- **Reader's conclusion.** BCG reduces TB risk on average, with substantial between-trial
  heterogeneity, and drmTMB reproduces the tool the reader already trusts before being
  asked to trust anything new.
- **Independence: STRONG** (`metafor`, `docs/design/242-…:108-109`).
- **Non-duplication.** `vignettes/meta-analysis.Rmd:83` fits the same grammar on
  **simulated** data (`dataset-inventory.md:55-59`). This is the first real, citable
  meta-analysis dataset in the corpus.

#### Comparison 3 (c05) — Is heterogeneity itself different between allocation designs?

- **Reader question.** "Randomised and systematically-allocated trials feel like different
  populations. Can I let each allocation type have its own `tau` from one fit, instead of
  splitting the dataset into three meta-analyses?"
- **Dataset.** `metadat::dat.bcg`, `alloc` a 3-level factor: `alternate` n=2, `random` n=7,
  `systematic` n=4.
- **drmTMB.**
  ```r
  drmTMB(bf(mu = yi ~ 1 + meta_V(V = vi), sigma = ~ alloc), data = dat, family = gaussian())
  ```
- **Comparator.**
  ```r
  dat$id <- seq_len(nrow(dat))
  metafor::rma.mv(yi, vi, random = ~ alloc | id, struct = "DIAG", data = dat, method = "ML")
  ```
- **Matched quantities and exact conversion — two steps stack.**
  1. **Contrast to cell mean** on the `log(tau)` scale: level `k`'s value is
     `intercept + coef_k`. Reference level `alternate` on both sides.
  2. **`exp()`** to reach `tau`, and square it to reach `rma.mv`'s `tau^2`. `rma.mv` prints
     `tau` and `tau^2` on the *response* scale; drmTMB's `sigma` linear predictor is on the
     log scale. The first pass through this conversion asserted "no `exp()` needed" and was
     wrong, caught only by computing it (`feasibility-batch-2.md:106-116`). The article must
     not repeat that error.
- **Evidence to state — upgrade from what batch 2 wrote.** Do not present this as
  "agreement to `rma.mv`'s printed 4 significant figures". The two log-likelihoods are
  identical to `1.05e-12`, `tau^2` differences are `3.4e-08 / 3.4e-07 / 1.6e-08`, and there
  is a structural identity behind it: with one row per `id`, `~ alloc | id` under
  `struct = "DIAG"` puts one random effect per study with variance `tau^2_{alloc(i)}`, so
  the marginal variance is `v_i + tau^2_{alloc(i)}`, which is literally
  `drm_total_obs_sd()^2` with a per-level `sigma` (`adversarial-scales.md:186-214`,
  `R/methods.R:5433-5435`). **These are the same model, not two close models.**
- **Reader's conclusion — REWRITTEN. The original is not licensed.** The
  `tau ≈ 0.19 / 0.61 / 0.53` comparative-heterogeneity sentence in
  `candidate-cells.md:172-174` must **not** ship. `evidence.tsv` row `ev-mc-0260m-meta-v`
  records: "At K=12 with true tau = 0.10 the fitted tau pins near 1e-6 and `confint()`
  returns [0, Inf] for heterogeneity, so the heterogeneity interval must not be reported as
  usable at small K" — read directly from `evidence.tsv` in round 3 — and
  `mc-0260m`'s cell boundary in `cells.tsv` records the same withdrawal as still binding
  (`adversarial-claims.md:240-264`). The `alternate` level here carries **two studies** —
  one below that regime. Ship instead: *"drmTMB's per-level `tau` estimates reproduce
  `metafor`'s to eight decimal places, and the two fits have the same log-likelihood. Do
  not read the differences between these three `tau` values as a finding: with 2, 7 and 4
  studies per level, drmTMB's own recorded boundary for this route says heterogeneity
  intervals are not usable at this K."* The point agreement is the result; the substantive
  comparison is not.
- **Independence: STRONG.** Note for §6: this is the **only** STRONG-independence check on
  a `sigma` linear predictor in the whole set, and its `sigma` is a between-study
  heterogeneity SD under `meta_V` (`sqrt(v_known + sigma^2)`), **not** a residual scale.

### Block 2b — checked against `ordinal` (independence not yet classified)

Block opening sentence, draft: *"`ordinal` is a separate estimation engine, but
`docs/design/242-external-comparator-evidence-class.md` has not yet classified its
independence strength, so these two comparisons are reported without one."* If the §10.3
doc 242 edit is signed off before ship, replace with the STRONG framing used in block 2a.

#### Comparison 4 (c06) — Does serving temperature shift wine bitterness ratings?

- **Reader question.** "I use `ordinal::clm()` for proportional-odds models. Does drmTMB's
  `cumulative_logit()` give me the same cutpoints and slopes?"
- **Dataset.** `ordinal::wine`, 72 rows, 5-level `rating` (Randall 1989).
- **drmTMB.** `drmTMB(bf(mu = rating ~ temp + contact), data = wine, family = cumulative_logit())`
- **Comparator.** `ordinal::clm(rating ~ temp + contact, data = wine)`
- **Matched quantities and exact conversion.** **None — no transform.** Same logit link,
  same cumulative direction, and — verified rather than assumed — the same sign convention:
  both write `logit P(Y <= j) = alpha_j - x'beta`. Rebuilding `clm`'s likelihood under that
  convention reproduces `logLik = -86.49192337`, identical to drmTMB's to 10 significant
  figures, with same-signed coefficients; `MASS::polr` agrees too
  (`adversarial-scales.md:164-184`). Compare the two slopes and the four cutpoints as an
  ordered set. This convention is currently undocumented in doc 158 — see §10.2.
- **Reader's conclusion.** Warm serving and contact both push ratings toward "more bitter",
  on a dataset the reader can look up.
- **The boundary that makes this comparison valuable — keep it prominent, not buried.**
  drmTMB *rejects* a scale submodel here, verbatim: `` `cumulative_logit()` models
  currently support only a `mu` location formula. ✖ Unsupported parameter: "sigma". `` and
  `ordinal::clm(rating ~ temp + contact, scale = ~ temp, data = wine)` **does** fit
  (`logLik = -86.439`) (`feasibility-batch-2.md:162-191`). `cumulative_logit()`'s `dpars`
  is `c("mu")` only (`R/family.R:415-418`, verified in place in round 3). A comparison where
  the comparator can do something drmTMB cannot is the cheapest available defence against
  the one-to-one impression issue #60 forbids (`adversarial-claims.md:152-157`).

  **This carries more weight in the narrowed article than it did before, and more again after
  round 5.** Round 3 relied on Part 3's two frontier models to stop the reader inferring a
  one-to-one correspondence between the packages; round 4 relied on Part 3's classified list.
  **After round 5 there is no Part 3 at all**, so this is the only place in the article where
  the reader sees the two packages' surfaces failing to coincide — and it runs in the
  direction that costs drmTMB something, which is the direction a reader will believe. Do not
  compress it. Per the repo's writing rule for unsupported syntax, tell
  the reader what to try instead: `ordinal::clm(scale = ~ temp)`.
- **Independence: `ordinal` is UNCLASSIFIED in doc 242** — see §10.3.

#### Comparison 5 (c07) — Do judges differ, and does that change the temperature effect?

- **Reader question.** "Nine judges each rated eight bottles. If I add a judge random
  intercept, do my conclusions move — and does drmTMB match `clmm()`?"
- **Dataset.** `ordinal::wine`.
- **drmTMB.** `drmTMB(bf(mu = rating ~ temp + contact + (1 | judge)), data = wine, family = cumulative_logit())`
- **Comparator.** `ordinal::clmm(rating ~ temp + contact + (1 | judge), data = wine)`
- **Matched quantities and exact conversion.** No transform on slopes or cutpoints (as
  Comparison 4). For the random effect, compare **SD to SD**: drmTMB's
  `summary(fit)$parameters` row `sd:mu:(1 | judge)` = `1.131139` against
  `attr(VarCorr(cmp)$judge, "stddev")` = `1.131133` — **not** against `clmm`'s variance
  `1.279461`. Both sides are ML-Laplace on the same random-intercept ordinal likelihood;
  every quantity agrees to 1e-5 or better, including `logLik`
  (`feasibility-batch-3.md:40-58`).
- **Reader's conclusion.** Ignoring judge identity attenuates the temperature effect: the
  conditional slope (3.063) is larger than Comparison 4's marginal slope (2.503). That is
  the expected conditional-vs-marginal shift, and the comparator makes it checkable.
- **Boundary, mandatory.** This licenses **point-fit parity only**. It does not license any
  REML or interval claim for this family. The only REML comparator study on
  `cumulative_logit()` (`mc-0227`, validated against `glmer`/brute force at M>=80) is
  package-private technical evidence with no public interval or reporting permission
  (`expressible-vs-comparator.md`, "OVERLAP region, summarized";
  `feasibility-batch-3.md:62-68`).
- **Independence: `ordinal` UNCLASSIFIED** — see §10.3.

### Block 2c — checked against a package built on the same machinery (WEAK)

Block opening sentence, draft and **mandatory** — it must appear before the first number in
this block: *"The three comparisons in this section are against `glmmTMB`, which is built
on the same TMB/AD stack and outer optimizer as drmTMB
(`docs/design/242-external-comparator-evidence-class.md:110-111`). Agreement here is a
consistency check between related implementations, not a cross-implementation check. It is
also, uncomfortably, where drmTMB's stated differentiator lives: no separate estimation
engine checked a residual-scale submodel anywhere in this article."*

#### Comparison 6 (c01) — Does reaction-time *variability* grow with sleep deprivation?

- **Reader question.** "I already fit `lmer(Reaction ~ Days + (Days | Subject))`. I suspect
  the spread widens as well as the mean. Can I model that, and do I still get the mean
  model I already trust?"
- **Dataset.** `lme4::sleepstudy`, 180 rows, 18 `Subject` (`dataset-inventory.md:68`).
- **drmTMB.**
  ```r
  drmTMB(bf(mu = Reaction ~ Days + (1 + Days | Subject), sigma = ~ Days),
         data = sleepstudy, family = gaussian())
  ```
- **Comparator.**
  ```r
  glmmTMB(Reaction ~ Days + (Days | Subject), dispformula = ~ Days, data = sleepstudy)
  ```
- **Matched quantities and exact conversion.** `mu` coefficients directly. For scale:
  **both sides put the dispersion linear predictor on `log(SD)`; no transform, no
  squaring.** Compare `coef(fit, "sigma")` to `fixef(g)$disp` element-wise.

  **Two pieces of evidence, on two different models. Do not merge them — this is the
  Noether R1 repair, and round 2 got it wrong.** Round 2 cited
  `logLik = -938.7163657` as if it belonged to the random-effect model displayed above. It
  does not, and the density identity it asserted **provably fails** there: with a random
  effect, `logLik()` is the Laplace marginal and `sum(dnorm(...))` is a conditional
  quantity. A builder following that text verbatim would have printed a fabricated number
  or silently dropped `(1 + Days | Subject)`. Measured in round 3 on both models:

  1. **The conversion itself, verified from the density on the fixed-effect variant**
     (`bf(mu = Reaction ~ Days, sigma = ~ Days)`, no `(1 + Days | Subject)`), where the
     likelihood is exact and no Laplace step intervenes on either side. Hand
     `dnorm(sd = exp(eta))` gives `-938.716365658985` against `logLik() = -938.716365658989`;
     `sd = sqrt(exp(eta))` gives `-4647.81685139013`. The wrong alternative is off by 3,709
     log-likelihood units, so this is not two scales that happen to sit close together.
     The link is structural, not fit-dependent, so it carries to the displayed model.
  2. **On the displayed random-effect model, the two packages share the marginal
     log-likelihood** — drmTMB `-870.000347731500`, glmmTMB `-870.000347731517`, absolute
     difference `1.63e-11`. That is stronger evidence than the coefficient table and round 2
     left it unused. Report it.

  The article must say which model the density check used and why. Draft: *"The conversion
  was checked on a fixed-effect version of this model, where the likelihood is exact: hand
  `dnorm(sd = exp(eta))` reproduces drmTMB's reported log-likelihood and `sd = sqrt(exp(eta))`
  misses it by about 3,700 units. On the random-effect model shown here `logLik()` is a
  Laplace marginal, so no row-by-row density identity holds; what the two packages share
  there is the marginal log-likelihood itself, `-870.0003477` on both sides."*

  Measurement provenance: round 3's own fits (§11.1), independently reproduced by Rose
  (`gate3-claims.md:256-269`) — **not** `adversarial-scales.md:48-68`, whose numbers are the
  fixed-effect variant's and were correctly qualified there as "fixed effects only, so no
  Laplace step on either side".
- **Reader's conclusion.** The `sigma` slope on `Days` is positive: residual spread grows
  with each day of deprivation. A mean-only model cannot represent that, because it carries
  a single residual SD for every observation. The mean model is unchanged, so this is an
  addition to what the reader already believes, not a replacement.
- **Independence: WEAK.** Vocabulary rule §6.2 applies to every sentence in this
  subsection.
- **Build note.** Do **not** copy the agreement table from `feasibility-batch-1.md:31-38`;
  its `sigma:(Intercept)` `abs diff` of `1e-6` is wrong by an order of magnitude. **The
  correct value is `1.6e-7`, not the `1.1e-7` round 2 carried** — Noether's own N3
  replacement was itself derived by differencing batch 1's *rounded* printed values and he
  self-corrected it in `regate-scales.md:325-349` (S1). Re-measured in round 3 on the
  displayed random-effect model:

  ```
  sigma:(Intercept)  drmTMB 2.8118490879933  glmmTMB 2.8118492449559  abs 1.5696e-07
  sigma:Days         drmTMB 0.0846339353160  glmmTMB 0.0846338976379  abs 3.7678e-08
  ```

  Recompute the column. The same table's "agreement to 4-5 significant figures" is also
  wrong, but **do not replace it with "agree to 8 significant figures"** — that was round 2's
  text and it is false for the `Days` coefficient, whose relative difference is `4.5e-7`
  (≈ 6 figures) against the intercept's `5.6e-8` (≈ 7–8 figures). **Write the two measured
  absolute differences, `1.6e-7` and `3.8e-8`**, and no figure count. Batch 1's own `4e-8`
  for `sigma:Days` was correct.
- **Round-4 note for the builder.** Round 3 carried an "A1 note" here warning that
  `sleepstudy` reappears in Part 3 and that nothing in this subsection may anticipate it.
  **That constraint is retired**: `sleepstudy` appears once in the article, and after round 5
  there is no Part 3 for it to reappear in. Write this subsection as a self-contained
  comparison with no forward reference of any kind.

#### Comparison 7 (c09) — Are male penguins more variable in body mass than females?

- **Reader question.** "I want the mean difference between species *and* whether one sex is
  more variable. Can one model give me both?"
- **Dataset.** `palmerpenguins::penguins`, complete cases on `species`/`sex`/`body_mass_g`,
  n = 333.
- **drmTMB.**
  ```r
  drmTMB(bf(mu = body_mass_g ~ species, sigma = ~ sex), data = pen, family = lognormal())
  ```
- **Comparator.**
  ```r
  glmmTMB(log(body_mass_g) ~ species, dispformula = ~ sex, data = pen, family = gaussian())
  ```
- **Matched quantities and exact conversion.** Compare on the **log scale**,
  coefficient-for-coefficient, `sigma` unsquared. Two things the article must say plainly:
  1. **`mu` here is `E[log y]`, not `log E[y]`.** Verified from the density: hand
     `dlnorm(meanlog = mu)` reproduces `logLik = -2511.448175`, while
     `meanlog = mu - sigma^2/2` gives `-2517.47` (`adversarial-scales.md:123-143`;
     `R/family-dpq.R:427-434`, `stats::dlnorm(y, meanlog = params$mu, sdlog = params$sigma)`
     — verified in place in round 3). This trap survives a coefficient-by-coefficient
     eyeball precisely because `sigma ~ sex` makes the offset vary by row.
  2. **Do not compare raw `logLik` across the two packages.** drmTMB reports the likelihood
     on the original `body_mass_g` scale (including the log-Jacobian); glmmTMB reports it
     for `log(body_mass_g)`. The gap is exactly `sum(-log(y)) = -2772.780261`
     (`feasibility-batch-3.md:193-200`, confirmed to the last digit at
     `adversarial-scales.md:129-135`).

  Agreement on coefficients is 1e-7 to 1e-8 — essentially exact, since neither side
  involves a Laplace approximation here.
- **Reader's conclusion.** Gentoo penguins are heavier than Adélie on the log scale, and
  males are about 55% more variable in log body mass than females (`exp(0.4374)`). The
  sex-variance result comes from the `sigma` submodel; a model with one residual SD has no
  parameter for it.
- **Independence: WEAK.**
- **Non-duplication.** `vignettes/bivariate-nongaussian.Rmd:80-105` uses `biv_lognormal()`
  on `body_mass_g` + `flipper_length_mm`. This is univariate, a different family, a
  different second axis, and a different question — the reuse `dataset-inventory.md:47-51`
  explicitly permits.
- **Round-4 note for the builder.** Round 3's "A1 note" warned that `penguins` reappears in
  Part 3. **Retired** — it appears once, and after round 5 there is no Part 3. No forward
  reference.

#### Comparison 8 (c03) — Are satiated owl broods *more variable*, not just quieter?

- **Reader question.** "I fit this in `glmmTMB` with one overdispersion parameter. Does
  food treatment change the overdispersion as well as the mean call rate?"
- **Dataset.** `glmmTMB::Owls`, 599 rows, 27 `Nest` (`dataset-inventory.md:70`).
- **drmTMB.**
  ```r
  drmTMB(bf(mu = SiblingNegotiation ~ FoodTreatment * SexParent + (1 | Nest),
            sigma = ~ FoodTreatment),
         data = Owls, family = drmTMB::nbinom2())
  ```
  **The `drmTMB::` prefix is mandatory, not stylistic.** `glmmTMB` also exports
  `nbinom2()`; after `library(glmmTMB)` a bare `family = nbinom2()` silently hands drmTMB
  glmmTMB's family object, and `drm_family_type()` rejects it
  (`feasibility-batch-1.md:106-122`). This will bite any reader following the article
  verbatim, so the article must show the prefix **and** say why once.
- **Comparator.**
  ```r
  glmmTMB(SiblingNegotiation ~ FoodTreatment * SexParent + (1 | Nest),
          dispformula = ~ FoodTreatment, family = nbinom2, data = Owls)
  ```
- **Matched quantities and exact conversion — the load-bearing one.** drmTMB's `sigma`
  maps to `size = 1 / sigma^2` (`R/family-dpq.R:902-904`,
  `drm_nbinom2_size <- function(sigma) 1 / sigma^2` — verified in place in round 3);
  glmmTMB's `dispformula` predictor is `log(size)` directly. Therefore
  **`log(theta) = -2 * log(sigma)`** — compare `-2 * coef(fit, "sigma")` to
  `fixef(g)$disp`.

  **Same two-model split as Comparison 6 (Noether R1). Round 2 made the same error here.**
  It cited `logLik = -1725.172156` as the displayed model's; that number belongs to a
  **fixed-effect** variant (`mu ~ FoodTreatment`, `sigma ~ FoodTreatment`, no `(1 | Nest)`).
  Measured in round 3:

  1. **The conversion, from the density on the fixed-effect variant:** hand
     `dnbinom(size = 1/sigma^2)` gives `-1725.17215645118` against
     `logLik() = -1725.1721564513`; `size = 1/sigma` gives `-1735.68990059604`; `size = sigma`
     gives `-1822.90463179193`. Source re-read in place: `R/family-dpq.R:902-904`,
     `drm_nbinom2_size <- function(sigma) 1 / sigma^2`.
  2. **On the displayed random-effect model, the two packages share the marginal
     log-likelihood:** drmTMB `-1716.217678074193`, glmmTMB `-1716.217678074613`, absolute
     difference `4.20e-10`. The converted `sigma` coefficients on that model are
     `-2 * coef(fit, "sigma") = (0.377592192555, -1.208174014747)` against
     `fixef(g)$disp = (0.377593346066, -1.208175329769)`, absolute differences `1.15e-6` and
     `1.32e-6` — which confirms batch 1's `1.1e-6` / `1e-6` as correct to the digit shown,
     unlike c01's.

  Say in the article which model the density check used, exactly as in Comparison 6. Do not
  print a density identity for the random-effect model; none holds.
- **The trap the article must show, because it is why this comparison is last.**
  Comparison 6's no-transform gaussian rule does **not** transfer. Applied naively here it
  misses by ~0.57 and ~1.81 in absolute terms (`feasibility-batch-1.md:145-149`). And the
  factor is signed by family: it is `-2 *` for nbinom2 and `+2 *` for tweedie
  (`adversarial-scales.md:76-97`), same magnitude, opposite sign — the hardest kind of error
  to notice because it lands in the right order of magnitude. Show the raw side-by-side
  first, then the conversion.
- **Reader's conclusion.** Satiated broods have higher NB2 `sigma`, i.e. lower `size`, i.e.
  *more* overdispersion — and the two packages agree once, and only once, the conversion is
  applied.
- **Independence: WEAK.**

---

## 4. The frontier classification — what we checked, what we did not, and where it now lives

**Retitled in round 5** (`gate4-claims.md` G4-B4). The previous title, *"Part 3 — the
frontier, named and classified"*, mandated an article heading — *"The frontier: what has no
comparator, and what we did not check"* — that failed §8.5 on two counts. It named no
searched set, and its first conjunct had **no referent in the section it titled**: class 1 is
B, classes 2–4 and the tail are C, so **no item here is class A**. A heading is the
highest-salience sentence in a section, and that one was refuted by its own contents. The
title above asserts no absence, so it needs no clause.

**Repurposed in round 5.** This section is no longer an article specification. Part 3 is
removed from the vignette (§2.5), so nothing below is drafted for a reader. What survives is
the **classification itself**, recorded in this plan because it is true, it was expensive to
establish, and the next session must not re-derive it or restore it to the article without
reading §2.5 first.

**Two things this section is still for:**

1. **The source of record for the four classes and their claim classes**, alongside
   `expressible-vs-comparator.md`'s per-family table. The PR body and the after-task report
   may draw on it; the vignette may not.
2. **The constraint set on any future write-up** that does bring the frontier back to a
   reader — §8.5's required clause per sentence, the builder prohibitions in §4.2, and the
   neighbour-versus-instance distinction in class 4.

Cite `expressible-vs-comparator.md` **by section heading, not by line range**
(`gate3-claims.md` G-S1). Round 3 cited `expressible-vs-comparator.md:102-133` four times as
"the complete four-class list"; by the time the citation shipped, that file's own edit had
moved the classes. Round 5 moved them again. Heading citations do not go stale when lines
shift.

### 4.1 Retired: the drafted Part 3 opening

Round 4's draft framing for Part 3 is deleted, not rewritten, because there is no Part 3.
Recording what it did, since two of its three jobs still need doing somewhere:

| What the draft opening did | Where it lives now |
| --- | --- |
| Stated the non-transfer principle — the agreements do not bear on models only one package fits | §8.2's boundary paragraph (Part 1) and §6.3's closing summary. Both are presence-side statements about what this article's evidence licenses. |
| Named the four frontier classes to the reader | **Nowhere in the article.** §4.2 below, and `expressible-vs-comparator.md`, are the record. |
| Scoped the search (`Suggests`, never CRAN) before making any absence claim | **Not needed in the article**, which makes no absence claim. The one permitted scope sentence (§2.5) names the set for a different reason: to bound what the article covered. |

### 4.2 The four classes, each with its claim class — plan record, not article text

One short paragraph per class. Each names the set searched and whether a comparator was run
(§8.5). **The builder prohibitions below still bind any future reader-facing use of this
material**, which is why they are kept rather than deleted with Part 3.

1. **Random effects on the residual scale** — present for Gaussian, lognormal, Gamma and
   NB2. **A comparator exists and was run.** `glmmTMB`'s `dispformula` accepts a random
   effect, and on the one dataset we tried it returned a variance component but did not
   converge. So this is not a capability nothing else expresses; it is one we have no
   *working* comparison for, from one run on one dataset. `gamlss`, doc 158's other
   nominated scale-side comparator, is **absent from this machine** (measured 2026-08-15;
   command and results in `expressible-vs-comparator.md`, "Installed status of the
   non-`Suggests` packages this document names") and was not tried.

   Permitted phrasings and the forbidden claim: this class may **never** be described as
   having no comparator, no implementation, or nothing to compare against. That sentence is
   false and it is the specific error four rounds of audit kept finding
   (`gate3-claims.md` Part D, `gate4-claims.md` Part D).

2. **Structured correlation on any parameter** — `phylo()`, `phylo_interaction()`,
   `spatial()`, `animal()`, `relmat()`, on `mu`, on `sigma`, or on a zero-inflation or
   hurdle parameter. **No comparator was run for any of these**, and no package-by-package
   search was made. We know of no established R package that fits them the same way; that is
   a statement about what we know, not about what exists.

3. **Regression on a group's standard deviation itself** — the `sd(group)` /
   `sd(..., level =)` grammar. **Not searched, not run**, same as class 2.

4. **Bivariate location-scale-scale models with structured covariance.** **Not searched, not
   run — for the structured-covariance form itself.** What *was* run is a neighbour of it,
   not an instance: a two-response model whose *correlation* varies with a predictor, with no
   structured covariance at all. Within the packages this article depends on, one could in
   principle take a two-response model, and when we ran it, it rejected a two-column response
   outright. So for that neighbouring model we found nothing in the set we searched; for
   class 4 proper we did not look. `brms` and `MCMCglmm` fit multivariate mixed models, are
   not dependencies of drmTMB, use a different inferential framework, and were not tried —
   and note that **both are installed on this machine** (measured 2026-08-15), which changes
   nothing about the claim except to remove "unavailable" as an excuse for not running them.

   **Keep the neighbour-versus-instance distinction** (`gate3-claims.md` G-S4). A
   predictor-dependent correlation is not a structured-covariance model, and round 3's
   article draft lost that distinction while trying to present the two as one class. Do not
   write a sentence in which the run stands for the class.

**Also frontier, and stated the same way:** `zero_one_beta()`'s zero-and-one-inflation
random-effect cells, and any zero-inflation or hurdle random effect beyond the two
diagnostic-only structured intercepts. `DESCRIPTION` `Suggests` was read, nothing beyond it
was searched, and nothing was run — **both conjuncts, not just the first**
(`gate4-claims.md` G4-S2; `expressible-vs-comparator.md`'s "Also frontier" tail was the
weaker source and is now scoped to match).

**The builder prohibitions — retained, and now governing any *future* reader-facing use.**
If frontier material ever returns to a reader document, that write-up must not: name the
dataset either run used, quote the rejection message or the convergence warning verbatim,
give a variance, or say which drmTMB model was fitted alongside. Each of those turns a
classification back into a demonstration. The runs are evidence for the classification
(§1.2); their outputs live in the reproducibility script and in this plan at §11.1. **In
PR 2 these prohibitions are not load-bearing**, because §2.5's A1 forbids the classification
itself in the article — but they are what a future session needs, and they are also invoked
by §5 rule 5 for the coverage table's comparator-status column.

### 4.3 Retired: the drafted Part 3 closing paragraph

Round 4's closing draft is deleted with Part 3. It is worth recording *why it was hard to
write*, because that difficulty is the argument for §2.5. Its own note said: *"the failure
mode is a closing sentence that reaches for a clean line and merges the claims back
together."* A paragraph whose job is to summarise a three-class distinction in a reader's
voice is under constant pressure to collapse it — and the draft itself contained
*"Most of them do not [have counterparts elsewhere]"*, an unscoped absence claim, in the
sentence immediately after the one warning against exactly that. A rule that has to be
re-applied by every writer at every draft is not a structural fix. Removing the paragraph is.

The one durable claim it carried survives outside the article, in §8.2's boundary paragraph
and in the PR body: **where drmTMB is genuinely novel, its evidence comes from its own
recovery and coverage studies, not from agreement with another package.** That is a statement
about drmTMB's evidence base, not about what other packages contain, so it needs no
searched-set clause.

---

## 5. The coverage table — split, per Rose A2

Rose A2 (SERIOUS): `candidate-cells.md:48` merges four fixed-effect scale submodels with one
random-effect scale submodel under a single "distributional submodel" heading, making
drmTMB's distributional submodel read as one validated thing with five supporting cells. It
is two things: four fixed-effect submodels that were compared against a running comparator,
and one random-effect submodel that was not compared at all here — the only comparator tried
for it, `glmmTMB`'s `dispformula`, accepted the model and did not converge on the one dataset
tested, and `gamlss` is absent from this machine and was not tried (§8.5's clause, since this
plan is bound by it too). **No prose caveat elsewhere repairs a summary table**, so the table
is fixed at source.

**Restructured in round 5.** Round 4's version of this table had a "Comparator status" column
whose three "none" rows classified the comparator landscape — *"no working comparator …"*,
*"none found in the packages this article depends on …"*, *"no search was run beyond
`Suggests`"*. Those cells were §8.5-compliant and they are still the most compressed absence
claims in the article, which is why `gate4-claims.md` G4-S5 flagged that §4.2's concrete
prohibitions were written for Part 3 and not for them. **§2.5 settles it differently: the
article makes no absence claim anywhere, so the column changes from what exists to what this
article compared.**

The column is renamed **"Compared in this article?"** and every cell answers that question and
only that question. A row with no comparison says **"not compared here"** — which asserts
nothing about the world and therefore needs no searched-set clause, because it makes no
claim that requires one.

The article's own coverage table, placed in Part 1 — note the split rows in bold:

| drmTMB capability | Comparisons in Part 2 | Compared in this article? | Independence |
| --- | --- | --- | --- |
| Location (`mu`) submodel, fixed effects | 1–8 (all) | yes, eight times | 1–3 STRONG · 4–5 unclassified · 6–8 WEAK |
| Location (`mu`) submodel, ordinary random intercept / slope | 1, 5, 6, 8 | yes, four times | 1 STRONG · 5 unclassified · 6, 8 WEAK |
| **Distributional (`sigma` / dispersion) submodel — fixed effects** | **3, 6, 7, 8** | **yes, four times** | **3 STRONG, and its `sigma` is a between-study heterogeneity SD, not a residual scale · 6, 7, 8 WEAK** |
| **Distributional (`sigma`) submodel — ordinary random effect** | **none** | **not compared here** | **nothing to classify** |
| Residual correlation `rho12` with a predictor | none | not compared here | nothing to classify |
| The rest of the implemented model surface (§1.3) | none | not compared here; the design documents record what it contains | nothing to classify |

Rules for this table:

1. It may not carry a total row, a count of agreements, or an "8 of 8" style summary — those
   average WEAK into STRONG (§6.2). Per-row counts ("yes, four times") are the comparisons
   named in the adjacent column, not a cross-strength total.
2. The three "not compared here" rows must show "none" in the comparisons column and must not
   point anywhere. Round 4's rule barred pointing into Part 3, which would have re-created the
   merge A2 objects to; round 5 removes the destination as well.
3. The same split must be applied to `candidate-cells.md:48` before that document is cited
   (§11).
4. **The status column may state only what this article compared.** It may not say a
   comparator is absent, unavailable, non-working, unsearched, or unknown — those are the
   claims §2.5 removes from the article, and this column is where a builder would most
   naturally smuggle one back in, because a table invites a verdict per row. "Not compared
   here" is the complete permitted answer. Round 4's rule 4 required the searched-set clause
   to survive compression into a cell; round 5 removes the claim that needed the clause.
5. **The column also obeys §4.2's builder prohibitions** (`gate4-claims.md` G4-S5, which found
   those prohibitions written for Part 3 and silently not binding here): no dataset name from
   either classification run, no verbatim rejection message or convergence warning, no
   variance, no number from a run the article does not show. A cell that reads "not compared
   here" satisfies this trivially; a cell that starts explaining *why* does not, and that is
   the tell.

**Footnote the table must carry.** Rows 1 and 2 assign the `mu` submodel of every
comparison, including **Comparisons 6, 7 and 8**, which are joint location-scale fits. The
agreement in those was obtained inside a joint fit spanning two ledger cells and does **not**
license either submodel in isolation. §8.4 applies this caveat to hypothetical ledger rows;
it applies to this table for the same reason.

**Corrected in round 4** (`gate3-claims.md` G-S6): round 3's footnote read "Comparisons 6, 8
and 9". Article numbers run 1–8 and there is no Comparison 9 — the footnote had transcribed
build id `c09` as an article number. The joint location-scale fits are Comparisons 6 (c01),
7 (c09) and 8 (c03), which is what §8.4 already said in build ids.

---

## 6. Independence strength — the A3 fix, made operational

Rose A3 (SERIOUS): the scale-side agreement is almost entirely WEAK independence, and WEAK
must not read like STRONG. Doc 242 classifies `lme4` and `metafor` as strong (separate
estimation engines) and `glmmTMB` as weak ("built on the same TMB/AD stack and outer
optimizer as `drmTMB`") at `docs/design/242-…:108-111`, re-read in place this round.

Four mechanisms, in decreasing structural weight:

### 6.1 Structural (already done in §2.2)

Part 2 is **sectioned** by strength. A reader cannot encounter a WEAK number without having
read the block heading and its mandatory opening sentence. This is the primary fix; the
rest are reinforcement.

### 6.2 Vocabulary rule, enforceable by grep at review

| Strength | Permitted phrasing | Forbidden |
| --- | --- | --- |
| STRONG (`lme4`, `metafor`) | "independent implementation", "cross-implementation check", "a separate estimation engine" | — |
| WEAK (`glmmTMB`) | "a consistency check between related implementations" (doc 242:111's own words), "the two packages agree" | **"independent implementation", "independently validated", "external validation", "independent confirmation", "cross-implementation"** |
| Unclassified (`ordinal`) | "the two packages agree; drmTMB has not yet classified `ordinal`'s independence" | any strength word |

No agreement anywhere may use the unqualified phrase "validated against an independent
implementation". No sentence may count or total agreements across strengths.

### 6.3 The sentence Part 2's closing summary must carry — and, after round 5, the article's ending

**Round 5 gives this paragraph a second job.** It is no longer a boundary between Part 2 and
Part 3; it is the last thing the reader reads (§2.1). It therefore has to close the article
without reaching for the frontier, which is precisely the reach §2.5 forbids. The draft below
is unchanged in substance — it was always a scope statement rather than a win — with one
addition marked below.

Draft:

> Three of the comparisons above — the `lme4` and `metafor` ones —
> are against separate estimation engines. Three of them are against `glmmTMB`, which is
> built on the same TMB/AD stack and outer optimizer as drmTMB, so they check consistency
> between related implementations rather than across independent ones. Two are against
> `ordinal`, whose independence drmTMB has not yet classified. And it is worth naming
> where that falls: **every comparison of a residual-scale submodel in this article — the
> capability drmTMB exists for — is in the `glmmTMB` group.** The one separate-engine check
> on a `sigma` linear predictor is the meta-analysis comparison, where `sigma` is a
> between-study heterogeneity SD, not a residual scale.

**The closing addition, new in round 5 — and the only place the article names its own
scope besides §1.3.** Append to the draft above, and stop there:

> These eight models were compared against packages listed in drmTMB's `DESCRIPTION` under
> `Suggests`, because those are the packages this article can call. drmTMB implements a
> great deal more than eight models; what it implements, and what evidence stands behind
> each capability, is recorded in the package's design documents and capability ledger
> rather than here.

**What that sentence does and does not say.** It names the set searched, which is what makes
it sayable at all (§2.5). It says the rest of the surface is *not covered by this article*.
It does **not** say the rest of the surface has no comparator, that nothing else fits it, or
that nobody looked — those are absence claims, they are barred from the vignette by §2.5's
A1, and they live in §4 and `expressible-vs-comparator.md`. A builder who finds this ending
unsatisfying is feeling the cost §2.5 records and accepts; the answer is not one more clause.

**Why the opening clause was deleted (Rose R3).** Round 2 opened this mandatory draft with
*"Eight models, eight agreements."* §6.2's rule directly above it says *"No sentence may
count or total agreements across strengths"*, and §5 rule 1 forbids the same thing in the
table for the stated reason that totals average WEAK into STRONG. A build session facing a
flat prohibition and a mandatory draft that breaks it would have resolved the conflict
arbitrarily. The decomposition was always the substance; the total was decoration. The rule
stands unamended and the draft obeys it.

**Refinement of A3, stated openly.** Rose writes "Every residual-scale agreement in the set
is weak-independence", while Rose's own A3 table lists Comparison 3 (c05) as metafor/strong
on "per-level `tau`". Both are right at different resolutions: c05's `sigma` enters the
likelihood as the between-study component of `sqrt(v_known + sigma^2)`
(`R/methods.R:5433-5435`, verified in place in round 3), so it is a `sigma`-side linear
predictor but not a residual scale. The article uses the precise form above rather than
either loose version. This sharpens A3; it does not contest it.

### 6.4 Inline tagging

Every agreement carries its strength at first mention in its own subsection (already in §3),
and the §5 coverage table carries the strength column. Belt and braces on top of §6.1.

---

## 7. Every cell rejected at feasibility, with its blocker

This section is as load-bearing as the survivors. It exists so nobody re-derives these.

| Rejected | Blocker | Source |
| --- | --- | --- |
| **c02 as a comparison cell** | `glmmTMB` accepts `dispformula = ~ (1\|Subject)` but returns non-PD Hessian, `NA` AIC/BIC/logLik, dispersion-RE variance `1.521e-12`. Comparator exists but is unusable on this dataset — **never** describe this as "no comparator exists". **Round 4: also dropped from the article entirely** (§2.4); its run survives only as the warrant for the class-1 classification recorded in this plan's §4 and in `expressible-vs-comparator.md`'s `gaussian()` row (§1.2). **Round 5: the classification itself is out of the article too** (§2.5), so this run warrants nothing a reader sees. | `feasibility-batch-1.md:66-90` |
| **c10 as a comparison cell** | No comparator **found** within `DESCRIPTION` `Suggests`. `glmmTMB(cbind(bill_length_mm, bill_depth_mm) ~ species)` returns `"matrix-valued responses are not allowed"`; it is the only `Suggests` package that could take a two-column response. `brms` and `MCMCglmm` are absent from `Suggests` and were **not tested**. **Round 4: also dropped from the article entirely**; its run survives only as the warrant for the class-4 classification recorded in this plan's §4 and in `expressible-vs-comparator.md`'s `biv_gaussian()` row (§1.2). **Round 5: the classification itself is out of the article too** (§2.5). | `feasibility-batch-4.md:52-73` |
| **`cumulative_logit()` with `sigma ~ temp`** (`ordinal::wine`) — proposed by `dataset-inventory.md:73` | **Not expressible in drmTMB 0.7.0.** Rejected with an explicit error: "`cumulative_logit()` models currently support only a `mu` location formula. ✖ Unsupported parameter: \"sigma\"." `cumulative_logit()`'s `dpars` is `c("mu")` only (`R/family.R:415-418`, verified). The comparator `ordinal::clm(scale = ~ temp)` does fit (`logLik = -86.439`). **Kept in the article as Comparison 4's asymmetry**, not as a cell. | `feasibility-batch-2.md:162-191` |
| **`beta_binomial()` with `sigma ~ period`** (`lme4::cbpp`) | Fitted and failed: "false convergence (8)", `NaN` standard errors, implausible `sigma` coefficient `-7.09`. | `candidate-cells.md:322-325` |
| **Any `gamlss` comparator** (doc 158 nominates `gamlss` for the gaussian `sigma` row and for scale-side random effects) | `gamlss` is **not installed on this machine at all**. Doc 158's own gaussian/`gamlss` half is already flagged unverified in the doc (`158-plan-of-record.md:34-39`); nothing here changes that. | `candidate-cells.md:39-42`, `adversarial-scales.md:318-319` |
| **Any `betareg` beta-regression cell** (proposed by `reader-gap-audit.md:115-118`) | `betareg` 3.2.5 is installed locally but is **not** in `DESCRIPTION` `Suggests` (verified in place in round 3: the Suggests list is `ape, callr, detectseparation, emmeans, extraDistr, fmesher, glmmTMB, ggplot2, JuliaCall, knitr, lme4, MASS, metafor, mvtnorm, numDeriv, ordinal, palmerpenguins, pkgload, rmarkdown, sf, spelling, statmod, testthat, tweedie, withr`). Adding it is a dependency decision, not a side effect of a vignette. | `candidate-cells.md:39-42`, `DESCRIPTION` Suggests |
| **c05's comparative-heterogeneity conclusion** (the fit is VIABLE; the *claim* is rejected) | Contradicts a boundary already recorded in the ledger: `ev-mc-0260m-meta-v` and `mc-0260m`'s cell boundary say heterogeneity intervals are unusable at small K (K=12, tau=0.10 → `[0, Inf]`). c05's `alternate` level has **two** studies. | `adversarial-claims.md:240-264`, `evidence.tsv` |
| **Any drmTMB-vs-comparator speed claim** | Single-run wall times vary **40×** on identical refits (0.028–1.132 s over five reps of c09), the three source documents already disagree with each other by up to 18× on the same fits, and drmTMB is source-loaded via `devtools::load_all()` while every comparator is an installed binary. | `adversarial-claims.md:169-216` |

**Also never fitted, and therefore not verified — must not be implied (Noether N6).** Doc
158's scale-conversion table has ten rows. This phase exercised five (`gaussian()`,
`lognormal()`, `stats::binomial()`, `nbinom2()`, `meta_V(V=V)`), of which three are identity
conversions. **Only two non-identity conversions were tested**: nbinom2's `-2×` and the
meta-analysis `exp(2×)`. Never fitted: `student()`, `Gamma(link="log")`, `tweedie()`,
`beta()`, `beta_binomial()` — and three of those five (`Gamma` shape `= 1/sigma^2`, `beta`
precision `= 1/sigma^2`, `tweedie` `phi = sigma^2`) are precisely the non-identity ones. Say
"two conversion shapes verified against densities", never "the conversion table is
verified" (`adversarial-scales.md:292-304`).

---

## 8. The claim boundary, in doc 242's words

### 8.1 The governing sentences (quote these, do not paraphrase)

> **Licensed.** That `drmTMB`'s likelihood and optimizer reach the same optimum as an
> independent implementation of the same model, on the dataset tested.
> — `docs/design/242-external-comparator-evidence-class.md:44-45`

> **Not licensed.** Any interval, coverage, bias, recovery or small-sample calibration
> claim. Every comparator test in the repo is single-seed and single-dataset, and none
> asserts standard-error or confidence-interval equality across packages.
> — `docs/design/242-…:47-49`

> **The governing constraint.** Agreement licenses the **overlap** region only, never the
> **frontier**. […] A design that blurs the two is credibility-laundering.
> — `docs/design/242-…:86-91`

### 8.2 The boundary paragraph the article must carry

Draft, to be placed in Part 1, not in a closing note:

> Every comparison in this article is single-seed and single-dataset. It shows that
> drmTMB's likelihood and optimizer reach the same optimum as another implementation of the
> same model, on the data shown. It is **not** evidence about interval calibration,
> coverage, bias, or small-sample behaviour, and no standard error or confidence interval is
> compared anywhere here. Agreement licenses the models both packages fit, and it does not
> transfer to a model this article did not compare — for those, drmTMB's evidence is its own
> recovery and coverage studies, recorded per capability in the package's capability ledger.
> The eight models here were chosen because a package this article already depends on fits
> them too.

**Round 4 makes this paragraph easier to keep true.** Round 3 had to add "note the count:
eight, not ten" here, because the article showed ten models and compared eight. It now shows
eight and compares eight. There is one count.

**Round 5 changes its last sentence and its middle clause, and both changes are the same
change.** Round 4's draft read *"never the frontier, which is where drmTMB's own recovery
studies have found real small-sample bias"* and closed with *"most of drmTMB's implemented
model surface cannot be [compared]"*. The first names a region the article no longer
discusses; the second is an unscoped absence claim (§2.5). The replacement says what the
agreements license and where drmTMB's other evidence lives — both statements about drmTMB's
own evidence base, neither a claim about what other packages contain. **Doc 242's
overlap/frontier vocabulary stays in this plan and in the PR body and does not enter the
vignette**, because the word "frontier" cannot be used in a reader document without
immediately owing the reader a definition, and that definition is an absence claim.

### 8.3 Comparator status per capability — searched, run, and what that supports

**Retitled in round 6** (`gate5-claims.md` G5-S3). The previous title, *"What has no *working*
comparator — explicit statement"*, is the same defect §4's title was retitled for at round 5
(G4-B4): §8.5 counts a section heading as a sentence, and that one asserted an absence while
naming neither the searched set nor the run status. It was also refuted by its own body —
item 1 says a comparator exists and was run. The title above asserts no absence, so it needs
no clause.

Every item carries its claim status, and every status names its searched set and run status
(§8.5).

1. **`sigma`-side random effects** — **a comparator exists and was run.** `glmmTMB` accepts
   `dispformula = ~ (1|Subject)`, runs, and returns a variance-component object for it, but
   the fit is degenerate and non-convergent on the one dataset tested. Say that, not "no
   package can express this". `gamlss`, doc 158's nominated scale-RE comparator, is not
   installed and **was not tested**.
2. **Predictor-dependent `rho12 ~ x` on `biv_gaussian()`** — **nothing found within
   `DESCRIPTION` `Suggests`, which was searched and run against.** The one `Suggests` package
   that could take a two-response model rejects the call outright; the two named Bayesian
   alternatives are not dependencies and were not tried.

   **Corrected in round 4** (`gate3-claims.md` G-S5): round 3 supported this item by quoting
   doc 158 — *"predictor-dependent `rho12 ~ x` has essentially no frequentist comparator"*
   (verified in place at `docs/design/158-phase-19-comparator-matrix.md:79` and
   `158-plan-of-record.md:58`). That sentence is unscoped: doc 158 searched no more of CRAN
   than Phase 19 did, and §15 says so for this very claim. Citing an unscoped claim as
   corroboration for a claim we spent a paragraph scoping is the import mechanism §8.5
   exists to stop. **The appeal to doc 158 is dropped here**; `feasibility-batch-4.md:52-73`
   is the real evidence and it is already cited. Doc 158's own sentence is scheduled for
   scoping in §10.2 item 6.
3. **The wider frontier, recorded in this plan only** (**re-led in round 6**,
   `gate5-claims.md` G5-S3 — the previous lead-in, *"the wider frontier the article names
   without demonstrating"*, described a Part 3 that §2.5 removed; after round 5 the article
   names nothing) — the complete four-class
   list of `expressible-vs-comparator.md`'s "FRONTIER region, summarized" section (as
   corrected, §11), which is also doc 242's own frontier sentence at
   `docs/design/242-…:86-88`:
   1. **scale-side (`sigma`) random effects** — *this class is item 1 above: a comparator
      exists and was run*;
   2. **structured providers** (`phylo()`, `phylo_interaction()`, `spatial()`, `animal()`,
      `relmat()`) on any parameter, including residual log-SD — **not searched, not run**;
   3. **`sd(group)` / `sd(..., level=)` regression** — **not searched, not run**;
   4. **bivariate location-scale-scale with structured covariance** — **not searched, not
      run**, except that item 2 above is one predictor-dependent `rho12` instance within its
      neighbourhood where `Suggests` *was* searched and a comparator *was* run.

   Listing all four and then asserting "no comparator exists" for the list is the exact
   error three rounds repaired. Name the list; state the search and run status per item.
4. **The reverse direction, which the article must also show** (Comparison 4):
   `ordinal::clm(scale = ~ temp)` fits a model drmTMB cannot express. The one-to-one
   impression is forbidden in both directions, and after the narrowing this is the article's
   only demonstrated asymmetry — see Comparison 4's build note.

### 8.4 Ledger-row boundary vocabulary (only if a row is ever minted)

Recorded here so a future session does not have to re-derive it. Line references
**re-verified in place in round 3**. An `external_comparator` row in `evidence.tsv` must:

- name a package from `COMPARATOR_PACKAGES` (`tools/capability_ledger.py:3875-3878`) in
  `run_id`/`result` (detection at `tools/capability_ledger.py:2328-2333`; detection never
  scans `claim_boundary`);
- declare **STRONG INDEPENDENCE** or **WEAK INDEPENDENCE** in `claim_boundary`
  (`tools/capability_ledger.py:2334-2341`);
- contain the tokens **"interval"**, **"coverage"** and **"single-seed"** in
  `claim_boundary` (`tools/tests/test_capability_ledger.py:3009-3014`; the same test
  re-asserts the independence token at `:3018-3022`);
- resolve its `path_or_url` (`tools/tests/test_capability_ledger.py:3023-3026`) and key to
  a `cell_id` present in `cells.tsv` (`:3037-3041`, inside
  `test_external_comparator_never_becomes_a_family_level_badge`).

A row for c01, c03 or c09 must additionally state that the agreement was obtained **inside
a joint location-scale fit** spanning two ledger cells, and does not license either cell in
isolation (`adversarial-claims.md:306-314`).

### 8.5 The comparator-absence rule — a required clause, not a banned list

**Replaced in round 4.** Round 3's version of this section was the right idea with the wrong
enforcement: three claim classes plus **a list of five forbidden strings**, checked by grep
over the draft article only. Both new instances found at gate 3 walked straight through it —
one was a sixth string nobody had thought of (a mandated section heading), the other lived in
a source document the article cites rather than contains
(`gate3-claims.md` Part D: *"a blacklist cannot close an open class"*).

**The rule, made two-way in round 5** (`gate4-claims.md` G4-S1):

> **No sentence may assert that a comparator is absent, and no sentence may assert that a
> comparator exists and fits, unless the same sentence names (a) the set that was searched or
> the package relied on and (b) whether a comparator was actually run against the
> capability.**

It binds everywhere a Phase 19 claim can be read: the PR body, the after-task report,
`docs/design/158-phase-19-comparator-matrix.md`, this plan, and every source document §11
corrects. **A section heading, a table cell, a table column entry, a figure caption, a bullet
and a footnote are each a sentence for this rule.** A sentence missing either clause is not
re-worded around a forbidden phrase — it is missing evidence, and it must either acquire the
evidence or be downgraded until it is true.

**Why presence needed governing too.** The rule was one-way for four rounds: absence was
constrained, presence was free. `expressible-vs-comparator.md` accumulated presence claims
naming `gamlss`, `sn` and `cplm` — **none of which is installed on this machine** — and
`VGAM`, `brms` and `MCMCglmm`, which are installed but outside `Suggests` and were never run.
One sentence told the reader `gamlss` "can serve as an oracle" for a package that cannot be
loaded. An unverified presence claim is the same defect pointed the other way: it advertises
a check nobody performed and it **shrinks the apparent frontier**, so the boundary doc 242
cares about moves whichever direction the error runs. That file now carries the measured
installed status and per-row run status; the measurement command is recorded there.

**Where the article sits under this rule after round 5.** It makes **no absence claim at all**
(§2.5 A1), so the absence half binds it vacuously. The presence half binds it fully and is
easy to satisfy: every presence claim in the vignette is backed by a fit the article shows.
That is the intended end state — the article asserts only what it demonstrates.

**The three classes are how a compliant sentence gets built**, not a list of approved
strings:

| Class | The claim | What the required clause looks like | Instances here |
| --- | --- | --- | --- |
| **A** | **No comparator found.** A named set was searched and nothing in it fits. | Names the set *and* says the search was run. "we found no package in this article's dependencies that fits this — we ran the only candidate and it rejected the model" | `rho12 ~ x` against `Suggests` |
| **B** | **A comparator fits, or fits and fails.** Something accepts the syntax; it is not usable here. | Names the package *and* the run. "`glmmTMB` accepts this syntax; we ran it on one dataset and it did not converge" | scale-side `sigma` random effects |
| **C** | **A comparator may fit; we did not check.** Not installed, not a dependency, not run, or a different inferential framework. | Names what was *not* done. "not installed here, not tried"; "Bayesian, not a dependency, not run" | `gamlss`; `brms`, `MCMCglmm`; every frontier class not exercised in Phase 19 |

**Downgrade direction.** When uncertain between A and C, write C. Class A is the strongest of
the three and the hardest to support: it requires having looked. Nothing in this article
searched CRAN.

**How it is checked — restated in round 5, because round 4 stated it correctly and then did
not do it.** The check is an **enumeration over a closed set of units**, not a search over
text:

- **In a table:** enumerate every row, and for each row ask (i) does this row assert absence
  or presence, and (ii) does the row carry both clauses. Terminating, one answer per row, no
  search string. `expressible-vs-comparator.md`'s three per-row columns make this a read of
  the table rather than a judgement about it — an empty cell is the answer.
- **In prose:** enumerate every sentence of the deliverable and ask the same two questions.

A grep for absence-shaped wording is a **finding aid** for that enumeration and is explicitly
*not* the test. Round 4 adopted this paragraph and then executed its sweep by searching for
the phrase `"no comparator fits …"`; three table rows asserted absence with nothing but a
bolded token and were invisible to it, and the definition of that token was invisible to it
too (`gate4-claims.md` G4-B2, Part D). **A phrase search cannot see a claim made without a
phrase.** That is the whole lesson of four rounds, and it is why round 5's fix is columns and
a redefinition rather than a fifth pass.

**Why the surface shrank twice.** Enforcement alone was judged insufficient at gate 3, which
is why round 4 dropped the frontier fits (§2.4); it was judged insufficient again at gate 4,
which is why round 5 dropped the frontier narrative from the article (§2.5). The rule and the
two narrowings are one answer with three parts: the rule catches an absence claim wherever it
appears, the narrowings remove the places in the *deliverable* where one was needed, and the
columns make the remaining places — the design documents — auditable without a sweep.

**Where the rule is enforced:** §1.2 (classification warrants), §1.3 (composition
disclosure), §4 (the plan's frontier record), §5 (coverage table, rules 4 and 5), §7 (rejected cells),
§8.3 (frontier list), §10.2 (doc 158 edits), and §11 (source-document corrections).

---

## 9. Reader-article registration checklist

New vignette basename: **`comparing-with-other-packages.Rmd`** (reader audience).

### 9.1 The four coupled edits

1. **`vignettes/comparing-with-other-packages.Rmd`** — the article itself, reader-audience
   prose and code obeying §9.2 and the architecture in §2. Each comparator block gated on
   `requireNamespace("<pkg>", quietly = TRUE)`, following the existing convention at
   `vignettes/bivariate-nongaussian.Rmd:12`.
2. **`_pkgdown.yml`** — add the basename (no `.Rmd`) under an `articles:` `contents:`
   block. **Decision: a new top-level section titled "Comparison with Established
   Packages", inserted after "Applied Family Tutorials" (`_pkgdown.yml:256-261`, verified
   in place in round 3)** — this is a distinct reader journey, not a workflow tool, and
   burying it under "Model Checking and Practical Workflow" (`:262-268`) would hide it from
   the reader arriving from `glmmTMB`/`lme4`.
3. **`inst/reader-contracts/vignette-manifest.csv`** — one new row. For a reader vignette:
   `audience = "reader"`, `permitted_private_fields = ""` (empty — the linter fails closed
   if a reader row declares any, `tools/check-reader-contracts.R:234-239`, verified in
   place), rationale empty. Exact line to add, matching the existing
   `structural-dependence.Rmd,reader,,` pattern at
   `inst/reader-contracts/vignette-manifest.csv:36`:
   ```
   comparing-with-other-packages.Rmd,reader,,
   ```
   `reader_contract_lint()` fails with "Missing manifest row(s)"
   (`tools/check-reader-contracts.R:178`) the moment the `.Rmd` exists without this row.
4. **`tests/testthat/test-reader-vignette-contracts.R:224`** — bump the hard-coded
   `expect_equal(nrow(manifest), 37L)` to `38L`. **Verified present at that exact line in
   round 3.** The manifest currently has 38 lines = 1 header + 37 rows, consistent. This file
   is **not** one of the byte-pinned files, so it may be edited. The linter would pass
   without this edit; the test would not — and `expect_setequal(manifest$vignette,
   source_vignettes)` at `:226` also fails without edit 3.

**Re-verify all four against the worktree before editing.** §9 was written in round 2 and
carried unrevised through rounds 3 and 4 (§15); its line numbers are two rounds old.

### 9.2 Private-field vocabulary the linter forbids in prose

`tools/check-reader-contracts.R:7-10` (**corrected from `:6-8`**) forbids these ten field
names:

```
opt, sdr, sdpars, corpars, optimizer_used, optimizer_attempts,
obj, model, missing_data, random_effects
```

Three patterns are matched, **case-sensitively, in prose and code chunks alike**:

1. `$field` on any object — `fit$opt`, `x$sdr`. The object name is irrelevant.
2. `[["field"]]` bracket access — `x[["sdpars"]]`.
3. A bare or backticked mention of the name **immediately followed by `$` or `[[`**
   (`route_pattern`, `tools/check-reader-contracts.R:98-100`, **corrected from
   `:106-109`**) — so `` `sdpars`$mu `` in narrative Markdown is caught even if
   `fit$sdpars` is never written. Plain prose that only says "the model", with no following
   `$`/`[[`, is not flagged. The three patterns are applied together at
   `tools/check-reader-contracts.R:132`.

**Live hazard for this article specifically.** The feasibility batches this article draws
from use `fit$sdr$pdHess`, `g$sdr$pdHess` and `fit$obj$env$parList()` as evidence. **None of
those may be copied into the vignette, in prose or code.** Use `is_converged(fit)` for
drmTMB convergence. Comparator objects are not exempt: the scanner "operates on source text
rather than fit-object names" (`tools/check-reader-contracts.R:3-5`, **corrected from
`:2-4`**), so a `glmmTMB` fit named `g` with `g$sdr` is flagged identically. Public
accessors are unaffected — `summary(fit)$parameters`, `summary(fit)$covariance`,
`ranef(fit)$terms` all pass.

**Round 4 lowers this risk.** The two fits that most needed `pdHess` as evidence were the
frontier pair, and they are gone from the article. The hazard remains live for the
reproducibility script (§14 step 2), which is not a vignette and is not scanned.

`private-access-exceptions.csv` needs no edit: ordinary comparator prose calling
`glmmTMB()` / `lme4::glmer()` / `metafor::rma.uni()` and reading their public output
requires no documented exception.

### 9.3 A fifth edit this vignette needs, beyond the standard four

**`DESCRIPTION` `Suggests` must gain `metadat`.** Comparisons 2 and 3 call
`data(dat.bcg, package = "metadat")`, and `metadat` is **absent** from `DESCRIPTION`'s
`Suggests` (verified in place in round 3; full list quoted in §7). Mitigating fact:
metafor 5.0-1 `Depends:` on `metadat`, so it is installed transitively wherever `metafor`
is — but an undeclared package used in a vignette is still a declaration defect.
`candidate-cells.md:15-17`'s claim that every dataset is "already reachable from
`DESCRIPTION` `Suggests` … no new dependency" is **false for these two comparisons** and
must be corrected wherever it is cited (`adversarial-claims.md:334-343`).

This is the **only** new dependency this PR needs, and it is a `Suggests` declaration for a
package already present transitively — not a new dependency in substance.

---

## 10. Ledger and design-doc decisions

### 10.1 Recommendation: no new ledger rows in PR 2

Rationale, all from `adversarial-claims.md:266-303`:

- **The two frontier models have nothing to record.** Three states exist —
  licensable-and-recorded, licensable-but-withheld, and nothing-to-record. These are the
  third. A write-up saying "no ledger row was added" without saying *which* state invites
  the reader to infer that evidence exists and was merely not filed. Say it explicitly —
  **in the PR body and the after-task report**. **Not in the article**, which discusses no
  ledger rows at all and should not start. **Rounds 4 and 5 make this statement more
  important, not less**: the PR body must record that the two models were fitted during
  feasibility and deliberately dropped from the article (§2.4), **and** that the frontier
  narrative was deliberately cut from the article and left in the design documents (§2.5), so
  a later reader does not reconstruct either omission as an oversight.
- **Comparisons 2 and 3 largely duplicate `ev-mc-0260m-meta-v`**, which already records
  five passing `metafor` comparator tests at 1e-4 to 1e-6 with STRONG INDEPENDENCE
  declared (read directly from `evidence.tsv` in round 3). The genuine increment is
  *real trial data instead of simulated* — a real reader gain, but not an axis the ledger
  records. **If the provenance matters, extend `ev-mc-0260m-meta-v`'s `result` field with
  Comparison 2 only** (c04 → `mc-0260m`, `mu`-side, real-data provenance) rather than
  opening a new row.
- **Comparison 3 must not be added to that row, and has no cell to attach to.** The only
  `route_modifier == "meta_V"` cell is `mc-0260m` (`dpar = mu`, fixed). There is no `meta_V`
  `sigma` cell, and attaching it to `mc-0262` (plain gaussian `sigma`) would badge a
  non-meta cell with a result obtained under a `meta_V` likelihood.

  Comparison 3 is a **`sigma`-side** result and `mc-0260m` is a **`mu`-side, fixed** cell, so
  folding it into that row badges the wrong dpar. `result` is not an inert notes field — it
  is one of the two fields package detection scans
  (`tools/capability_ledger.py:2328-2333`, and doc 242 states the same at `:100-101`:
  detection scans `run_id` and `result` only, never `claim_boundary`). **Record Comparison
  3's real-data provenance in the vignette and the after-task report only.**
- **The live precedent is zero rows**: the just-landed external-oracle harness carries none
  (`docs/design/242-…:78-84`).

If the maintainer wants rows, `adversarial-claims.md:316-332` lists the six cleanly
licensable cells and their candidate `cell_id`s (c01→`mc-0268`/`mc-0262`;
c03→`mc-0401`/`mc-0398`; c06→`mc-0223`; c07→`mc-0225`; c08→`mc-0059`;
c09→`mc-0374`/`mc-0376`), with the joint-fit caveat from §8.4 and c08's honest ~1e-3
tolerance. **Two caveats, restored at the point of use:**

1. **c01's candidate rows must be checked against the existing
   `ev-mc-0260-external-comparator` row before minting**, or the same overlap is recorded
   twice.
2. **c06 and c07 are blocked on §10.3.** `ordinal`'s independence strength is undeclared in
   doc 242, and the enforcement only checks that a strength *token* is **present**
   (`tools/capability_ledger.py:2334-2341`;
   `tools/tests/test_capability_ledger.py:3018-3022`). A builder minting a c06 row would
   therefore type "STRONG INDEPENDENCE", pass every check, and amend doc 242 by side effect
   — the exact outcome §10.3 exists to prevent. **No c06/c07 row until §10.4.2 is signed.**

### 10.2 Doc 158 edits PR 2 should make

1. **Executed Comparator Artifacts (doc 158 L96-118)** currently lists only the binomial
   `glm()` parity bundle. Add the external-oracle artifact and a cross-reference to doc
   242's 2026-08-15 amendment for the interval-evidence policy; note that this second
   artifact-storage location is `docs/dev-log/external-oracle/`, not
   `docs/dev-log/comparator-results/` (`158-plan-of-record.md:131-186`).
2. **`cumulative_logit()` row** (`docs/design/158-phase-19-comparator-matrix.md:90`) — add
   the sign convention: `logit P(Y <= j) = alpha_j - x'beta`, shared by `ordinal::clm`,
   `clmm` and `MASS::polr`, verified in `adversarial-scales.md:164-184`. Without it, a
   future comparator using the plus form would produce a clean sign flip with identical
   magnitudes — the failure most likely to be read as "documented somewhere".
3. **Mark which conversion rows are density-verified** (Noether N6). Verified:
   `gaussian()`, `lognormal()`, `stats::binomial()`, `nbinom2()`, `meta_V(V=V)`. Never
   fitted: `student()`, `Gamma`, `tweedie()`, `beta()`, `beta_binomial()`.
4. **Close doc 158's own flagged `glmmTMB::sigma()` gap** (`:51-64`): the accessor returns
   the **SD** for gaussian (`sigma(g) = exp(fixef(g)$disp[[1]]) = 47.44887999`) and the
   **dispersion `phi`** for tweedie (`= 1.480683096`). It does not generalise across
   families (`adversarial-scales.md:70-97`).
5. **If doc 158 states the `rho12` link anywhere, it must read `0.999999 * tanh(eta)`**
   with the inverse `atanh(rho12 / 0.999999)`. Check before shipping; the plain-`tanh`
   error propagated from `feasibility-batch-4.md` and may have travelled further. (The
   article no longer states the link at all, so doc 158 is now the only place PR 2 can leave
   it wrong.)
6. **NEW in round 4 — scope doc 158's `rho12` cell** (`gate3-claims.md` G-S5).
   `docs/design/158-phase-19-comparator-matrix.md:79` reads *"predictor-dependent
   `rho12 ~ x` has essentially no frequentist comparator"* (verified in place this round;
   quoted identically at `158-plan-of-record.md:58`). That fails §8.5's required clause: it
   names no searched set and no run. Rewrite to the tested scope — the one `Suggests`
   package that could take a two-response model was run and rejected the call; `brms` and
   `MCMCglmm` are not dependencies and were not tried; no CRAN search was made. Until this
   edit lands, **no Phase 19 document may cite doc 158 as corroboration for this claim**
   (§8.3 item 2 no longer does).
7. **NEW in round 4 — record the frontier fits' disposition where doc 158 nominated them.**
   Doc 158 nominates comparators for the gaussian `sigma` random-effect row and the `rho12`
   row. PR 2 fitted both cells and shows neither. Add one line to each row saying the cell
   was exercised in Phase 19, what the comparator did, and that the article deliberately
   does not display it (§2.4), so a future session does not re-run them assuming they were
   never tried.

### 10.3 `ordinal` independence strength — a doc 242 decision, not a PR 2 side effect

`docs/design/242-…:106-111` classifies only `lme4`/`metafor` (strong) and `glmmTMB` (weak).
`ordinal` is in `COMPARATOR_PACKAGES` (`tools/capability_ledger.py:3876`, verified) with
**no declared strength**, and Comparisons 4 and 5 need one. Deciding it inside a Phase 19
write-up would amend doc 242 by side effect (`adversarial-claims.md:296-303`).

**Action:** PR 2 proposes a one-line doc 242 edit classifying `ordinal::clm`/`clmm` as
**STRONG** (a separate estimation engine sharing no code with drmTMB), flagged for
maintainer sign-off. Marked AGENT-INFERRED — it is Rose's inference and mine, not
repo-grounded. If unsigned when the article ships, block 2b's opening sentence (§3) is used
as drafted, and Comparisons 4 and 5 say "independence strength not yet classified in
`docs/design/242`" rather than silently assuming STRONG.

### 10.4 Maintainer sign-offs required before merge

1. Zero ledger rows (§10.1).
2. `ordinal` = STRONG in doc 242 (§10.3).
3. `metadat` added to `Suggests` (§9.3).
4. Dropping the timing/speed claim while #60's Definition of Done says "timing summaries"
   (§12).
5. **The A1 remedy — SIGNED 2026-08-15.** The maintainer took the escalation: drop the
   frontier fits from the article entirely (§2.4). This item is recorded as decided, not
   asked again. What it costs and what it buys is in §2.4; what it deleted is in §2.3.

   **Item 5a — the article scope change — SIGNED 2026-08-15 (round 5).** Numbered `5a` rather
   than `6` so every existing `§10.4.n` reference in this plan keeps its target. The
   maintainer took the second escalation: the article makes **presence claims only**, Part 3
   is removed, and the frontier narrative lives only in the design and planning documents
   (§2.5). Recorded as decided, not asked again. **The cost is real and is recorded in
   §2.5** — a reader of the vignette alone will not learn from it that most of drmTMB's
   implemented surface was not compared against any package in `DESCRIPTION` `Suggests`, and
   that nothing beyond that set was searched (rescoped in round 6, `gate5-claims.md` G5-S2) —
   and the PR body must state the decision so a later session does not restore Part 3 as a
   correction.

6. **Whether the frontier list should be doc 242's own four-item sentence
   (`242:87-88`) verbatim, or `expressible-vs-comparator.md`'s four classes as corrected.**
   **Moot for the article after round 5** — no frontier list appears in it. The question
   survives for §4, the PR body and the after-task report, where the plan uses the latter:
   same four classes at more useful resolution, from the corrected file. **The warning below
   is why this item is kept rather than struck**, since option (b) remains available for those
   documents.

   **The consequence of the other branch, stated before the signature is asked for**
   (`gate3-claims.md` G-S3). Doc 242's sentence, read in place at
   `docs/design/242-external-comparator-evidence-class.md:86-91` and re-read this round, is:
   *"Where `drmTMB` is genuinely novel — scale-side random effects, `sd()` regression,
   bivariate LSS, phylogenetic structure on residual log-SD — **no established
   implementation exists** to borrow credibility from …"*. That is an unqualified absence
   assertion with no searched set and no run status, and **its first named item is the one
   capability where a comparator demonstrably fits** (§1.2, §8.3 item 1). Taking option (b)
   verbatim would put exactly the sentence three rounds of audit removed back into the
   article, under a maintainer signature. **If option (b) is chosen, doc 242's wording may
   be used only with §8.5's class split appended in the same paragraph.**
7. §8.5's required-clause rule as a standing rule for this article. It constrains prose the
   maintainer may want written differently, and it is half of the mechanism keeping the
   false-absence claim from recurring — the other half is the narrowing in §2.4.

### 10.5 A finding to report upward: doc 242's frontier sentence is too strong for its first item

Not a PR 2 edit, and not something a Phase 19 write-up may fix by side effect — but it should
not be discovered a fourth time by a fourth auditor.

`docs/design/242-…:86-91` names four novel capabilities and says "no established
implementation exists" for them as a group. Phase 19 ran a comparator against the first one:
`glmmTMB` accepts a formula-driven random effect on dispersion and returns a variance
component for it (`feasibility-batch-1.md:66-73`, re-read in place this round; re-run in
round 3 at §11.1 and independently reproduced at `gate3-claims.md:256-269`). The governing
design document's own sentence therefore over-claims for its first item, and every document
that quotes it inherits the over-claim — which is how the claim reached the drafted article
in the first place.

**Recommended (maintainer's call, doc 242 is a design document):** amend that sentence to
name the search and the run, per §8.5's rule. Report it in the PR body regardless of whether
the amendment is made in this PR.

---

## 11. Corrections required in the source documents before they are cited

These are errors in the Phase 19 survey documents, found by the adversarial passes. PR 2
must fix them, because the article cites these files as its evidence trail.

| File:line | Error | Fix | Audit id |
| --- | --- | --- | --- |
| `candidate-cells.md:52` | "No comparator can fit the same thing \| 2, 10" — false for cell 2; the same document contradicts it at `:101-104`. | Split the row; state c02 as "comparator runs and fails". | Rose B2 |
| `candidate-cells.md:15-17` | "no new dependency" — false, `metadat` is not in `Suggests` (re-verified). | Correct the claim; add `metadat` (§9.3). | Rose D8 |
| `candidate-cells.md:48` | Coverage row merges four fixed-effect scale submodels with one random-effect one under a single "distributional submodel" heading. | Split into fixed-effect and random-effect halves, per the table in §5. A prose caveat elsewhere does not repair a summary table. | Rose A2 |
| `candidate-cells.md:172-174` | The `tau ≈ 0.19 / 0.61 / 0.53` comparative-heterogeneity sentence. | Replace with the §3 Comparison 3 wording; it contradicts `ev-mc-0260m-meta-v`. | Rose D1 |
| `candidate-cells.md:298-300` | `(0.4068807, +0.3745636, +0.3754125)` labelled as per-species correlations; they are link-scale coefficients. | Relabel as link-scale; give response-scale values via `predict(type = "response")`. | Noether (via batch 4) |
| `candidate-cells.md:97-99` | Quotes the refuted `expressible-vs-comparator.md` class-1 sentence approvingly ("classifies scale-side random effects as frontier: `glmmTMB` treats dispersion as a fixed nuisance parameter…"). | Requote the corrected sentence, or drop the quotation and cite the corrected classification. **Still not corrected — carried to the build session** (§15). | Rose R7.3 |
| `expressible-vs-comparator.md`, class 1 of "FRONTIER region, summarized" | "No comparator package models residual-scale as a random effect the way drmTMB does; `glmmTMB` treats dispersion as a fixed nuisance parameter, not a formula-driven random-effect target." **False** — refuted by `feasibility-batch-1.md:66-73`. **This is the upstream source of the recurring claim; if it is not fixed, every later document re-imports it.** | Restated as class B with the run named; the refuted sentence quoted inside a superseded block so the record survives. **Corrected in place in round 3.** | Rose R7.1 |
| `expressible-vs-comparator.md`, head of the FRONTIER list | Cited `docs/design/242-…:79-80` for the frontier quote. Verified: `242:79-80` is inside the 2026-08-15 amendment, about whether the `lme4` point-agreement block was withheld from the ledger. The frontier passage is at `242:86-91` (its example list at `:87-88`). | Repointed to `:86-91`. **Corrected in place in round 3.** | Rose R7.2 |
| **`expressible-vs-comparator.md` per-family table, Gamma row** | *"sigma random intercept is FRONTIER (glmmTMB has no formula for dispersion-as-random-effect)"* — the parenthetical is **false**, refuted by `feasibility-batch-1.md:66-73`. Round 3 fixed this proposition in the FRONTIER section and left it standing, unhedged, in the table above it. | Parenthetical deleted; the row now says `glmmTMB`'s `dispformula` does accept a random effect, that it was not run for Gamma, and that the claim is therefore "not tested", not "no comparator". **Corrected in place in round 4.** | **G-B1** |
| **`expressible-vs-comparator.md` per-family table, nbinom2 row** | *"FRONTIER for sigma random effects (fixed dispersion in glmmTMB)"* — same false parenthetical, same refutation. | Same fix as the Gamma row. **Corrected in place in round 4.** | **G-B1** |
| **`expressible-vs-comparator.md` per-family table, gaussian / lognormal / zero_one_beta / biv_gaussian rows** | Four unclassified absence claims — "no established package fits location-scale mixed models with residual-SD random effects the same way", "no package fits lognormal sigma-RE the same way", "**FRONTIER throughout** — no established package fits a four-parameter zero-one-inflated beta … the same way", "**FRONTIER throughout** — … has no established-package analogue". None names a searched set or a run, and the last is **already cited as authority** by `feasibility-batch-4.md`'s `biv_gaussian()`/`rho12` FRONTIER verdict (the "Verdict: UNCERTAIN, unchanged from the pre-filled cell" sentence — **identified by claim in round 6**, `gate5-claims.md` G5-S1; this row previously named `:126-127`). | Each row now carries the search-and-run clause §8.5 requires: the gaussian `sigma`-RE half becomes class B, the lognormal and zero_one_beta rows become "not tested", and the biv_gaussian row splits into the tested `rho12` instance (class A within `Suggests`) and the untested structured-covariance remainder. A document-wide scope note is added **above** the table so no row can fall outside it. **Corrected in place in round 4.** | **G-B1** |
| **`feasibility-batch-4.md`, the `biv_gaussian()`/`rho12` FRONTIER verdict** — section *"3/4. Matched scale + verdict"*, the sentence beginning **"Verdict: UNCERTAIN, unchanged from the pre-filled cell, and for the same reason:"** (**identified by claim in round 6, `gate5-claims.md` G5-S1; round 5 named `:126-127`, which is innocuous convergence prose**) | *"`expressible-vs-comparator.md:79` classes formula-capable `biv_gaussian()` `rho12` as FRONTIER — expressible by drmTMB but with no comparator to check it against"* — cites a line number that the round-4 edit moves, and states the absence with no searched set and no run status. | Repoint to `expressible-vs-comparator.md`'s per-family table by **row** (`biv_gaussian()`), not by line, and add the scope clause: nothing was found within `DESCRIPTION` `Suggests`, which was searched, and the one candidate was run and rejected the model. **Round 5 adds a quarantine until this lands** — see §15.9. | **G-B1 / §8.5 / G4-S3** |
| **`expressible-vs-comparator.md:5-7`, the definition of FRONTIER** | The document defined FRONTIER as *"the region where none can [fit the same model]"* — an unqualified class-A assertion, inherited by all fifteen uses of the token in the per-family table and by the four frontier classes. Round 4 corrected ten *instances* while leaving the term defined as an absence. **Correcting instances of a term is not correcting the term.** | **The term is redefined**: FRONTIER now means the region where this survey found no comparator in the set it searched, and the definition names that set (`DESCRIPTION` `Suggests`, never CRAN) and the run status in its own sentence, so it satisfies the rule it is quoted next to. **Done in place in round 5.** | **G4-B1** |
| **`expressible-vs-comparator.md` per-family table, all seventeen rows** | Three rows (`student()`, `tweedie()`, `cumulative_logit()`) asserted FRONTIER with a bare bolded token and **no clause of any kind**, so four consecutive phrase-searches could not see them. The defect is the sweep method, not the three rows. | **Three columns added — claim class (A/B/C), set searched, actually run? — and filled by enumerating all seventeen rows.** Verified mechanically: 17 data rows, 8 cells each, no empty or dash-only cell. An empty cell is now a defect on sight and no sweep is needed to find one. **Done in place in round 5.** | **G4-B2** |
| **`expressible-vs-comparator.md:95-97`, the blanket default** | *"Read every FRONTIER verdict below that carries no explicit class marker as class C"* — a prose caveat repairing table cells, installed 25 lines below a rule requiring the clause in the cell, and the reason nobody looked for unmarked rows. It contradicted §5's own standard (`:771`, "**No prose caveat elsewhere repairs a summary table**"). | **Deleted.** Replaced by the column contract: every row carries its own marker, and an incomplete cell is visibly incomplete. **Done in place in round 5.** | **G4-B3** |
| **`expressible-vs-comparator.md:114, :115, :118, :119, :121, :136-138`** — presence claims | Six unverified OVERLAP claims: `gamlss` and `brms` for Student-t, `sn` for skew-normal, `cplm` for tweedie, `gamlss` for beta, `VGAM` for beta-binomial, and the summary sentence saying those packages *"can serve as an oracle"*. **`gamlss`, `sn` and `cplm` are not installed on this machine**; `VGAM` and `brms` are installed but outside `Suggests`; none was ever run. `:115` is simultaneously an absence claim about `sn`'s capability. | §8.5 extended to presence, and each claim marked with the package's installed status and run status. A measured installed-status table (with the exact command, run 2026-08-15) is added to the source file. **Done in place in round 5.** | **G4-S1** |
| **`expressible-vs-comparator.md:243`, the "also frontier" tail** | Second conjunct — *"any zero-inflation/hurdle random effect beyond the two diagnostic-only intercepts"* — asserted absence bare, while `PR2-build-plan.md:734-736` stated the same fact correctly. The plan was right and its cited source was weaker. | Scoped to match the plan: `Suggests` read, nothing beyond it searched, nothing run. **Done in place in round 5.** | **G4-S2** |
| `feasibility-batch-1.md:35` | `sigma:(Intercept)` `abs diff` reported as `1e-6`. **Actual, measured in round 3 on the displayed RE model: `1.5696e-07` → report `1.6e-7`.** Round 2 carried `1.1e-7`, which Noether self-corrected (`regate-scales.md:325-349`): he had obtained it by differencing batch 1's *rounded* printed values, the same mistake he was charging batch 1 with. | Recompute the column to `1.6e-7`. Also correct "4-5 significant figures" — but **not** to "agree to 8 significant figures", which is false for `sigma:Days` (relative `4.5e-7`, ≈ 6 figures). Write the two measured absolute differences, `1.6e-7` and `3.8e-8`. | **N3**, corrected by **S1** |
| `feasibility-batch-1.md:155-158` | "good coverage evidence that the scale-conversion table is being read correctly." | Narrow to "two conversion shapes verified against densities" (§7). | **N6** |
| `feasibility-batch-2.md:118-129` | c05 evidence stated as "matches `rma.mv`'s printed 4 s.f." | Upgrade to the log-likelihood identity (`1.05e-12`), full-precision `tau^2` diffs (`3.4e-08`, `3.4e-07`, `1.6e-08`), and the structural argument. | Noether check F |
| `feasibility-batch-3.md:43-44, :104, :177` | "doc 158 L69 / L30 / L25" point at the phase19 *extract*, not `docs/design/158-…`, where the same rows are at `:90`, `:47`, `:42`. | Repoint at `158-plan-of-record.md` explicitly, or renumber to the design-doc lines. | **N4** |
| `feasibility-batch-4.md:111-115` | `rho12` link stated as plain `atanh`/`tanh`. | State `rho12 = 0.999999 * tanh(eta_rho12)`, citing **`src/drmTMB.cpp:4260`** as primary — the `model_type == 2` branch this fit executes (`R/drmTMB.R:20456`) — with `:670` noted as the byte-identical line in the `model_type == 95/96/97` covariance-probe branch that no R code reaches. Inverse `atanh(rho12 / 0.999999)`. Note that ~6e-7 of the quoted residual is the guard, not optimiser noise. **Still required even though the article no longer states the link** — doc 158 item 5 depends on this file being right. | **N1 (REFUTED)**, citation corrected by **Noether R3** |
| **`feasibility-batch-4.md`, the second link statement — clause (c) of the `biv_gaussian()`/`rho12` verdict paragraph: *"the internal `rho12` link is `atanh`/`tanh`, so any reader comparing raw coefficients to a correlation must transform first"*** (**added in round 6, `gate5-claims.md` G5-S1**) | Same plain-`atanh`/`tanh` error as the row above, in a **second** sentence that the scheduled range for the first one does not reach. Repairing only the first leaves the file still asserting the wrong link. | Same fix as the row above: state `rho12 = 0.999999 * tanh(eta_rho12)`, inverse `atanh(rho12 / 0.999999)`, citing `src/drmTMB.cpp:4260` (the `model_type == 2` branch this fit executes) with `:670` as the byte-identical covariance-probe branch. Both sentences must be repaired in the same edit; find this one by its "(c)" clause, not by line. | **N1 (REFUTED)** / **G5-S1** |
| `feasibility-batch-4.md:113-115` | `tanh(0.4068807)` written as `0.3860` and the Chinstrap value as `0.6536`. | Restate the three **response-scale** values `0.385820534655`, `0.653534293224`, `0.654020308386`. **Do not write `0.3858209`/`0.6535349`** — round 2 put those in this row's "Fix" column, but they are **plain-`tanh`** values, i.e. the unguarded link this same table declares wrong (Noether R2). The divergence is 4e-7, the exact quantity the guard exists to get right. | **N2**, corrected by **Noether R2** |
| `feasibility-batch-4.md:137-139` | Cites `docs/design/242-…:82-84` for credibility-laundering; the passage is at `:86-91`. Lines 82-84 are about whether `lme4` point agreement was withheld from the ledger. | Repoint to `:86-91`. | **N5** |

**Corrections to earlier revisions of this plan itself** (Rose principle — the same class of
citation error was present here too; all re-verified in place in round 3):

| Was | Is | Where |
| --- | --- | --- |
| `tools/check-reader-contracts.R:6-8` | `:7-10` | §9.2 |
| `tools/check-reader-contracts.R:106-109` (`route_pattern`) | `:98-100` | §9.2 |
| `tools/check-reader-contracts.R:210-215` (reader row fails closed) | `:234-239` | §9.1 |
| `tools/check-reader-contracts.R:2-4` (scanner keys on field name) | `:3-5` | §9.2 |
| `tools/capability_ledger.py:2329-2333` (package detection) | `:2328-2333` | §8.4 |
| `tools/tests/test_capability_ledger.py:3016-3021` (required tokens) | `:3009-3014` | §8.4 |
| `tools/tests/test_capability_ledger.py:3022-3025` (`path_or_url`) | `:3023-3026` | §8.4 |
| `tools/tests/test_capability_ledger.py:3037-3040` (`cell_id` in `cells.tsv`) | `:3037-3041` | §8.4 |
| `expressible-vs-comparator.md:102-133` cited four times as "the complete four-class list" | The four classes span roughly `:116-174` and will move again; **all four citations now name the section heading** ("FRONTIER region, summarized") instead of a line range | §4.1, §8.3 item 3 — **G-S1** |
| `feasibility-batch-1.md:77-90` cited for the `glmmTMB` dispersion-RE run | `:66-73` is the run and its output; `:74-90` is the verdict discussion. Both are true; the narrower range is what the classification actually rests on | §1.2, §8.3, §10.5 |

**Round-4 corrections to this plan** (from `gate3-claims.md`):

| Was | Is | Where | Finding |
| --- | --- | --- | --- |
| Part 3 heading mandated as *"Where drmTMB has no comparator"* | Heading retired with the register; Part 3 is *"The frontier: what has no comparator, and what we did not check"* | §2.3, §4 | **G-B2** |
| `expressible-vs-comparator.md:102-133` cited as "the complete four-class list" in four places | Cited by section heading; line ranges are stale and will restale | §4.1, §8.3 | **G-S1** |
| §11.1's provenance given as `scratchpad/ada-round3-verify.R` | **That path does not exist** in this worktree or the repo (`find … -name "ada-round3*"` returns nothing). Provenance is restated as: round-3 session scratchpad, not preserved; **independently reproduced by Rose and recorded at `gate3-claims.md:256-269`**; and §14 step 2 now requires the committed harness to re-emit these values | §11.1, §14 | **G-S2** |
| §10.4.6 offering doc 242's sentence verbatim with no warning | The consequence is stated before the signature is asked for, and the over-claim is reported upward as §10.5 | §10.4.6, §10.5 | **G-S3** |
| "Two of these four are shown below" | Deleted — nothing is shown below | §4.1 | **G-S4** |
| §8.3 item 2 citing doc 158's unscoped `rho12` sentence as corroboration | Appeal dropped; doc 158's own sentence scheduled for scoping as §10.2 item 6 | §8.3, §10.2 | **G-S5** |
| §5's footnote naming "Comparisons 6, 8 and 9" | "Comparisons 6, 7 and 8" — there is no Comparison 9; `c09` is article number 7 | §5 | **G-S6** |
| §4.1's draft: "Four kinds of model make up **most of the rest**" | "recur across nearly every family in the rest of it" — the source claims recurrence across family rows, not a majority share; §1.3's 79% is AGENT-INFERRED and about a different quantity | §4.1 | **Note 1** |
| §8.5 enforced by a five-string blacklist grepped over the article only | A required-clause rule checked by reading, binding on every document the PR touches; the grep is a finding aid and is explicitly not the test | §8.5, §14 | **Part D** |

**Round-5 corrections to this plan** (from `gate4-claims.md`):

| Was | Is | Where | Finding |
| --- | --- | --- | --- |
| Part 3 mandated in the article, headed *"The frontier: what has no comparator, and what we did not check"* | **Part 3 removed from the article** (maintainer decision, §2.5); §4 retitled *"The frontier classification — what we checked, what we did not, and where it now lives"* and repurposed as a plan record. The old heading named no searched set and its first conjunct had no referent — **no Part 3 class was class A** | §2.1, §2.3, §2.5, §4 | **G4-B4** |
| §8.5 governs absence only | Two-way: presence claims name the package and whether it was run. Six unverified presence claims in `expressible-vs-comparator.md` were the live instances | §8.5, §11 | **G4-S1** |
| §8.5's "how it is checked" says *read, do not grep*, without saying what a read enumerates | The check is an **enumeration over a closed set of units** — every table row, every sentence — with one answer per unit. Round 4 held the right rule and executed a phrase search anyway | §8.5, §14 step 7 | **Part D** |
| §14 step 2: *"The article's chunks are written from this script's output"*, where the output includes the two classification checks | *"…from this script's **eight-comparison** output"*; the classification checks are recorded in the script and quoted nowhere in the article | §14 step 2 | **G4-S4** |
| §5's comparator-status column classified what exists, in three "none" cells | Column renamed **"Compared in this article?"**; every cell answers only that. New rule 5 binds it to §4.2's builder prohibitions, which had been written for Part 3 and did not reach Part 1 | §5 | **G4-S5** |
| `feasibility-batch-4.md`'s `biv_gaussian()`/`rho12` FRONTIER verdict scheduled for repair but not quarantined, while `candidate-cells.md` was | Added to the do-not-cite list until §11's repair lands, matching `candidate-cells.md`'s treatment. **Round 6: the quarantine names the claim — the "Verdict: UNCERTAIN, unchanged from the pre-filled cell" sentence — not a line range, which round 5 got wrong (`gate5-claims.md` G5-S1)** | §15.9 | **G4-S3 / G5-S1** |
| §1.3's disclosure: *"most of drmTMB's implemented surface cannot be [compared]"* | A claim about this article's coverage, not about what exists elsewhere. Same change in §8.2's boundary paragraph | §1.3, §8.2 | **§2.5** |

### 11.1 Round-3 measurements

Run in this repository under `R_PROFILE_USER=/dev/null Rscript --no-init-file`,
`devtools::load_all()`, drmTMB 0.7.0, glmmTMB 1.1.14, R 4.6.0.

**Provenance, corrected in round 4** (`gate3-claims.md` G-S2). Round 3 cited these to a
script at `scratchpad/ada-round3-verify.R`. **No such file exists** — not in this worktree,
not anywhere in the repository; it lived only in an ephemeral session scratchpad that was not
preserved, and it contained no c02 comparator fit even though a c02 measurement is reported
below. The values are nonetheless sound: **Rose re-fitted them independently at gate 3 and
every one reproduced exactly**, with her output recorded at `gate3-claims.md:256-269`. Treat
that as the provenance until §14 step 2's committed harness re-emits them.

```
c01 DISPLAYED (mu = Reaction ~ Days + (1 + Days | Subject), sigma = ~ Days)
  drmTMB  logLik  -870.000347731500      glmmTMB logLik  -870.000347731517   abs 1.63e-11
  drm sigma coefs  2.8118490879933  0.0846339353160
  gtmb disp coefs  2.8118492449559  0.0846338976379
  sigma abs diff   1.5696e-07       3.7678e-08
  sigma rel diff   5.58e-08         4.45e-07
c01 FIXED-EFFECT VARIANT (mu = Reaction ~ Days, sigma = ~ Days)
  drmTMB logLik                    -938.716365658989
  hand dnorm(sd = sigma)           -938.716365658985   <- accepted
  hand dnorm(sd = sqrt(sigma))    -4647.81685139013    <- rejected

c03 DISPLAYED (mu = SiblingNegotiation ~ FoodTreatment * SexParent + (1 | Nest), sigma = ~ FoodTreatment)
  drmTMB  logLik -1716.217678074193      glmmTMB logLik -1716.217678074613   abs 4.20e-10
  -2 * drm sigma   0.377592192555  -1.208174014747
  gtmb disp        0.377593346066  -1.208175329769
  sigma abs diff   1.15e-06         1.32e-06
c03 FIXED-EFFECT VARIANT (mu = SiblingNegotiation ~ FoodTreatment, sigma = ~ FoodTreatment)
  drmTMB logLik                   -1725.1721564513
  hand dnbinom(size = 1/sigma^2)  -1725.17215645118   <- accepted
  hand dnbinom(size = 1/sigma)    -1735.68990059604   <- rejected
  hand dnbinom(size = sigma)      -1822.90463179193   <- rejected

CLASSIFICATION CHECK, not an article fit (§1.2):
glmmTMB(Reaction ~ Days, dispformula = ~ (1|Subject), data = sleepstudy)   [c02 comparator]
  VarCorr(g)$disp  Subject (Intercept) Variance 1.521243e-12, Std.Dev. 1.233387e-06
  g$sdr$pdHess = FALSE
```

**Round 4 relabels the last block and nothing else.** The c01 and c03 measurements support
Comparisons 6 and 8, which are still in the article. The c02 block is no longer evidence for
a displayed model; it is the warrant for the class-1 claim class recorded in §4 (§1.2), and no
digit from it may appear in the article. **Round 5:** the article carries neither the digits
nor the classification (§2.5).

**Two places where round 3 stated the measurement more narrowly than Noether did.** He
reported the c01 and c03 marginal log-likelihoods as "identical" on both sides; measured to
full double precision they differ by `1.63e-11` and `4.20e-10`. "Identical to printed
precision" is accurate; "identical" is not. Quote the differences.

---

## 12. Reproducibility block

Recorded 2026-08-14 under `R_PROFILE_USER=/dev/null Rscript --no-init-file`. These values are
**as recorded by the feasibility and audit runs**; the building session must re-emit them
from its own session rather than copying this block:

```
R version 4.6.0 (2026-04-24)
platform      aarch64-apple-darwin23   (macOS Tahoe 26.6.1)
BLAS          libRblas.0.dylib          (reference BLAS; not Accelerate, not OpenBLAS)
cores         parallel::detectCores() = 20
drmTMB        0.7.0  (worktree source, devtools::load_all — NOT the installed 0.6.0)
TMB           1.9.21          Matrix     1.7.5
glmmTMB       1.1.14          lme4       2.0.1
metafor       5.0.1           metadat    1.6.0
ordinal       2025.12.29      MASS       7.3.65
palmerpenguins 0.1.1
gamlss        ABSENT          betareg    3.2.5 (installed, not in Suggests, unused)
```

**Seeds — the field must be answered, not left silent** (`adversarial-claims.md:218-224`).
Every model in the article and both classification checks use fixed real datasets with **no
stochastic component**: no simulation, no resampling, no bootstrap. State that explicitly as
the answer to #60's seed requirement, and record comparator optimizer control settings in its
place (all comparators run at package defaults except Comparisons 2 and 3's mandatory
`method = "ML"`, and Comparison 1's optional tightened `optCtrl`, used only as a diagnostic
and not for the reported fit).

**Threading.** Not pinned in the feasibility runs. Set `OPENBLAS_NUM_THREADS=1` in the
reproducibility script for determinism, and record it.

**Timing — dropped as a claim, with reasons recorded.** No drmTMB-vs-comparator speed
sentence may be written from this evidence:

- single-run wall times vary **40×** on identical refits (c09, five consecutive reps in one
  session: 0.191, 1.132, 0.031, 0.028, 0.028 s);
- the source documents already disagree on the same fits by 18× (c09: 0.9 s vs 0.049 s),
  1.5× (c03), and one stated upper bound is falsified (c05: "<1 s" vs 1.254 s);
- timer scope was chosen post hoc from two observed values rather than fixed in advance
  (`feasibility-batch-4.md:24-29`);
- drmTMB is source-loaded while every comparator is an installed binary, so TMB template
  compilation flags are not guaranteed equal.

What PR 2 records instead: the environment block above, the model options, and a sentence
saying no speed comparison is made and why. This satisfies #60's actual guardrail ("keep
timing comparisons reproducible") by making none; it does **not** literally satisfy the
Definition of Done's "timing summaries", so it needs the sign-off in §10.4.4. If the
maintainer wants timings, the protocol must be fixed *before* measuring: repetition count,
warm-up discard, timer scope, an installed drmTMB build, and BLAS/thread pinning.

---

## 13. Runtime estimate

Per D-139, an estimate is stated before anything runs.

| Step | Estimate | Basis |
| --- | --- | --- |
| The 8 article drmTMB fits | **≤ ~6 s total, order of magnitude** | The feasibility runs timed ten single fits summing to ~6 s (0.246, 0.259, 1.95, 0.209, 1.254, 0.020, 0.358, 1.067, 0.049, 0.313 s). The eight retained are a subset of those ten, so ~6 s is an upper bound. |
| The 8 article comparator fits | **~1 s total, order of magnitude** | Single-run wall times (batch 3: 0.054 / 0.188 / 0.035 s; others sub-second) |
| The 2 classification checks (§1.2) | **~1 s** | One `glmmTMB` fit that fails to converge, one `glmmTMB` call that errors at parse |
| Package load, data prep, `escalc()` | ~20 s | `devtools::load_all()` dominates |
| Reproducibility script end-to-end | **< 2 min** | Sum of the above with margin |
| Knitting the single vignette | **~2 min** | 8 fits plus chunk overhead; one fewer dataset thread than round 3's estimate assumed |
| `Rscript tools/check-reader-contracts.R` | seconds | Static scan |
| `devtools::test(filter = "reader-vignette-contracts")` | seconds | One test file |

**These are the timings §12 disowns as claims.** They are fit for a D-139 order-of-magnitude
estimate and for nothing else — a 40× spread on identical refits is harmless when the
question is "minutes or hours" and fatal when the question is "which package is faster". Do
not let them be re-read later as measurements.

**Under the 30-minute line — just run these.** No approval needed.

**Two items flagged as likely to exceed 30 minutes; approval required before running
(D-139):**

1. **`pkgdown::build_site()`** — rebuilds all 38 articles, every one of which fits models. I
   cannot estimate this from anything measured in this survey; the executing session must
   time a single-article build first
   (`pkgdown::build_article("comparing-with-other-packages")`, ~3 min expected) and
   extrapolate before committing to a full site build.
2. **`devtools::check()` / `rcmdcheck(args = "--as-cran")`** — TMB template compilation plus
   the full test suite plus 38 vignettes. Historically well beyond 30 minutes for this
   package. Estimate from the last recorded `--as-cran` run in
   `docs/dev-log/check-log.md` before starting, and get approval.

If either overruns its estimate, stop and re-report rather than continuing.

---

## 14. Build order

1. Apply the source-document corrections in §11, including the corrections to this plan's own
   citations. **Do this as an enumeration, in one pass over all files listed, in one
   commit** — four rounds of partial sweeps have produced four generations of correction
   tables, and a fifth partial sweep would produce a fifth. **Enumerate rows and sentences,
   do not search for phrases** (§8.5, "how it is checked"). For
   `expressible-vs-comparator.md` the enumeration is already structural: read its seventeen
   table rows and confirm all three claim columns are filled in every one.
2. **Write the reproducibility harness first, and commit it to the worktree at a path this
   plan can cite.** One script that fits the 8 article drmTMB models and their 8 comparators,
   runs the 2 classification checks from §1.2, prints full-precision output, and emits §12's
   environment block. It must re-emit §11.1's values from its own run; §11.1's current
   provenance is a lost scratchpad script plus Rose's independent reproduction
   (`gate3-claims.md:256-269`), and this step is what replaces it. **The article's chunks are
   written from this script's eight-comparison output; the two classification checks are
   recorded in the script and quoted nowhere in the article** (`gate4-claims.md` G4-S4 —
   round 4's wording read literally gave a builder permission to put `Variance = 1.521243e-12`
   into a chunk, which §2.5, §4 and §11.1 all forbid).
3. Draft Part 1: purpose, boundary paragraph (§8.2), composition disclosure (§1.3),
   coverage table (§5).
4. Draft Part 2 in the §2.2 order — block 2a (c08, c04, c05), block 2b (c06, c07), block 2c
   (c01, c09, c03) — each block opening with its mandatory strength sentence. Close Part 2
   with the §6.3 summary, **which is now the end of the article** (§2.1).
5. **There is no step 5. Part 3 is not drafted** (§2.5). Kept as a numbered gap rather than
   renumbered, so a session working from an older copy of this plan notices the change instead
   of drafting a section this one silently dropped.
6. **Draft review gate — the A1 check.** Enumerate every sentence of the drafted vignette and
   confirm **none** asserts, implies, or classifies the absence of a comparator (§2.5 A1).
   Two mechanical aids, neither of which is the test: the vignette should contain no
   occurrence of "frontier", and §5's status column should contain no cell other than a
   comparison count or "not compared here". The scope question round 3 left to this gate was
   decided in round 4 (§2.4) and again in round 5 (§2.5); this gate only verifies compliance.

   **The enumeration MUST include §3's eight Reader's-conclusion bullets, one at a time.**
   Do not treat §3 as settled because it predates the rule — that is exactly how this failed.
   Gate 5 found two of the eight asserting a named package's incapacity ("a claim `lmer()`
   cannot make at all"; "the part `lm()`/`lmer()` cannot deliver"). Both were TRUE and both
   still breached A1, because `lme4` is a comparator in this very article and no `lmer` or
   `lm` fit was run anywhere in Phase 19. Both are now restated as facts about a MODEL — "a
   mean-only model cannot represent that, because it carries a single residual SD" — which is
   the licensed form. Neither mechanical aid above could see them: they contain no "frontier"
   token and are not in §5's column. A claim made without the phrase the aid searches for is
   the recurring failure mode of rounds 2 through 5; the enumeration is the only control that
   catches it.
7. **The §8.5 read — an enumeration, not a grep, and now two-way.** Over the vignette, the PR
   body, the after-task report and the doc 158 edits: enumerate every sentence and confirm
   that (a) no sentence asserts absence unless it names the searched set and the run status,
   and (b) **no sentence asserts a comparator exists and fits unless it names the package and
   whether it was run**. In the vignette (a) should return zero sentences by construction;
   if it does not, §2.5 A1 has been breached. A grep for absence- or presence-shaped wording
   is a finding aid for this read; passing a grep is not passing the rule, and round 4 failed
   on exactly that substitution. Then run `Rscript tools/check-reader-contracts.R` before
   knitting (fail-closed, catches §9.2's vocabulary in prose) and grep for §6.2's forbidden
   independence vocabulary.
8. Apply the four coupled edits (§9.1) plus `DESCRIPTION` (§9.3), **re-verifying §9's line
   numbers first** — that section is two rounds old (§15).
9. Knit the vignette; run `devtools::test(filter = "reader-vignette-contracts")`.
10. Doc 158 edits (§10.2, seven items); doc 242 proposal (§10.3); doc 242 finding reported
    upward (§10.5).
11. Full checks (§13) — the two D-139 items.
12. After-task report in `docs/dev-log/after-task/`; check-log entry per `AGENTS.md` rule 7.
    Both must record **two** deliberate exclusions and why, so neither is later read as an
    oversight: two feasibility-verified frontier fits are excluded from the article (§2.4),
    and the frontier narrative itself is excluded (§2.5), with the cost §2.5 names stated
    plainly.

---

## 15. What round 5 did not fix

Stated so the next reviewer does not have to find it. Items 1-8 carry over from round 4 unless
marked otherwise; item 9 is new.

1. **`candidate-cells.md:97-99` is still not corrected.** It quotes the refuted class-1
   sentence approvingly. Round 3 corrected the upstream instance in
   `expressible-vs-comparator.md`; round 4 corrected that file's per-family table; the
   quotation in `candidate-cells.md` remains scheduled in §11 for the build session. **Do
   not cite `candidate-cells.md` until it is done.**
2. **`ordinal`'s independence strength is still undecided** and must be settled in doc 242,
   not here (§10.3). Until it is, two of eight comparisons ship without a strength.
3. **The two ledger-cell constraints that round 3 discovered are no longer enforced by the
   article, because the article no longer makes the claims they constrained.** They remain
   true and they will bind any future write-up of those capabilities, so they are recorded
   here rather than deleted:
   - `mc-0266` (`sigma` random intercept) is `interval_feasible` only for its own tested
     design — **48 groups × 20 observations**, per its `claim_boundary` in `cells.tsv`, which
     also excludes coverage, calibration, REML and other group designs. `sleepstudy` is
     18 × 10. No interval claim may be made for that fit.
   - Whether `mc-0181` covers a **predictor-dependent** `rho12 ~ x` as opposed to `rho12 ~ 1`
     is **not established** by this survey. Its `claim_boundary` records that no CI-coverage
     simulation was found for `biv_gaussian` fixed effects, so it "stops short of
     'supported'".
4. **Timing** remains dropped rather than measured (§12), pending §10.4.4.
5. **Neither round 4 nor round 5 ran a model fit.** Both are scope changes plus prose,
   citation and structure corrections. Every number in this plan remains Gauss's, Noether's or
   round 3's, cited as theirs, with round 3's independently reproduced by Rose at
   `gate3-claims.md:256-269`. **Round 5 ran exactly one measurement**, and it is not a fit: the
   installed status of `gamlss`, `sn`, `VGAM`, `cplm`, `brms`, `MCMCglmm`, `betareg` and
   `metadat` on this machine, via `system.file(package = ...)`, with the command and results
   recorded in `expressible-vs-comparator.md`. Source facts re-read in place across the two
   rounds: `feasibility-batch-1.md:66-73`, `feasibility-batch-4.md:52-73` and `:126-127`,
   `docs/design/158-phase-19-comparator-matrix.md:79`, `docs/design/242-…:86-91` and
   `:108-111`, `DESCRIPTION`'s `Suggests` list, `expressible-vs-comparator.md` in full, and
   the absence of any `ada-round3-verify.R` in the repository.
6. **Both frontier claims still rest on a search of `DESCRIPTION` `Suggests`, not of CRAN.**
   §8.5's class A is written to that scope deliberately. Nobody has established that no
   package anywhere fits `rho12 ~ x`, and no document in this phase may imply it.
7. **§9 (registration checklist) and §12 (reproducibility) have not been re-audited since
   round 2.** Their line numbers are two rounds old; §14 step 8 requires re-verifying them
   before editing. A defect there would be two rounds old and unfound by anyone.
8. **The c04–c09 build specifications have not been re-audited since round 2 either**, beyond
   the specific corrections in §11 and round 3's re-measurement of c01 and c03.
   `gate3-claims.md` and `gate4-claims.md` both declare the same limit from the audit side, so
   these specifications are now **three rounds unaudited**.
9. **NEW in round 5 — one claim in `feasibility-batch-4.md` is quarantined, not repaired.
   Corrected in round 6 (`gate5-claims.md` G5-S1): the quarantine is on the CLAIM, not on a
   line range.** The quarantined claim is the **`biv_gaussian()`/`rho12` FRONTIER verdict** in
   that file's *"3/4. Matched scale + verdict"* section — the sentence beginning **"Verdict:
   UNCERTAIN, unchanged from the pre-filled cell, and for the same reason:"**, which continues
   *"`expressible-vs-comparator.md:79` classes formula-capable `biv_gaussian()` `rho12` as
   FRONTIER — expressible by drmTMB but with no comparator to check it against"*. Round 5
   quarantined `:126-127` instead, which is innocuous prose about convergence and about the
   `Suggests` check; a builder opening that range finds nothing wrong and concludes the
   quarantine is spurious or already discharged.
   `gate4-claims.md` G4-S3: the quarantined sentence asserts absence with no searched set and
   no run status, and cites `expressible-vs-comparator.md:79`, a line number that round 4 and
   round 5 both moved. §11 schedules the repair for the build session and the corrected
   `biv_gaussian()` row carries a matching note. Until the repair lands, **no Phase 19 document
   may cite that verdict sentence as authority for a comparator-absence claim** — the same
   treatment `candidate-cells.md` gets in item 1. Locate it by that quoted opening, never by
   line number: this file has now moved under three consecutive rounds, and citing it by range
   is the very defect `gate5-claims.md` G5-S1 found inside this quarantine. Measured at gate 4:
   the plan's only references to it are inside §11's correction tables, i.e. references to the
   defect rather than appeals to it, so nothing live is contaminated today. The quarantine
   closes the asymmetry before something does.
10. **NEW in round 5 — the frontier record now lives in documents with no reader.**
    §2.5 removes the frontier narrative from the vignette; §4 and
    `expressible-vs-comparator.md` keep it. That is the right home for a classification this
    survey cannot fully support, but it means the fact that most of drmTMB's implemented
    surface was not compared against any package in `DESCRIPTION` `Suggests`, and that nothing
    beyond that set was searched (rescoped in round 6, `gate5-claims.md` G5-S2), is now
    reachable only by a reader who follows a pointer. This is
    a cost, it was accepted knowingly (§10.4 item 5a), and it should be revisited if a future
    phase ever runs a wider search — at which point the frontier could return to a reader
    document on evidence rather than on an unscoped assertion.

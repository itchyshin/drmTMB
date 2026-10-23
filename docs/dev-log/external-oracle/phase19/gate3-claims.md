# Phase 19 gate 3 — third adversarial audit of the PR 2 build plan

Author: Rose (`systems_auditor`), third pass, 2026-08-14.
Worktree: `.worktrees/external-oracle`, branch `claude/external-oracle-intervals`,
HEAD `4530fd71a` (`git log --oneline -1`), drmTMB 0.7.0 (`DESCRIPTION:3`).
Reader: the maintainer deciding whether PR 2 may be built, and — because of the answer in
Part D — whether it should be built in its current scope at all.

Audited in full: `PR2-build-plan.md` (1,593 lines, all of it),
`expressible-vs-comparator.md` (198 lines, all of it), `plan-repair-changelog.md`'s round-3
block, my own `regate-claims.md`, and the four feasibility batches at every line the two
target documents cite. Source facts re-read in place: `cells.tsv` rows `mc-0181` and
`mc-0266` in full, `docs/design/242-external-comparator-evidence-class.md:86-101`,
`docs/design/158-phase-19-comparator-matrix.md:79`, `tools/capability_ledger.py:2326-2341`.

**Unlike rounds 1 and 2 of the audit, this pass ran R.** Round 3's numbers are the first in
this phase that belong to the plan's own author, so I re-fitted them independently rather
than accept them. Script: `rose-gate3-verify.R` (session scratchpad), run as
`R_PROFILE_USER=/dev/null Rscript --no-init-file` against `devtools::load_all()` on this
worktree. Output is in Part C, finding S2. **They reproduce exactly.**

---

## Overall verdict: NOT-DONE — two blocking, six serious.

Seven of my eight prior findings are closed at the sites I named, several by structural
remedies, and the round's new measurements survive independent re-fitting. That is real
progress and I record it as such in "What round 3 got right".

The verdict is NOT-DONE because **the same class of error reopened for the third
consecutive round**, and this time round 3's own repair generated one new instance of each
of the two recurring classes:

- the false-comparator-absence class (B2 → R1 → **G-B1, G-B2**), now surviving in the
  source file round 3 declared "fixed upstream", and in a *mandatory article heading* the
  plan itself writes;
- the stale-line-citation class (N4, N5, R7.2 → **G-S1**), now present in the four citations
  that carry the R1 fix itself, because the round-3 edit to the cited file moved the lines
  it cites and the citation was not re-measured.

Part D answers the question the brief asks directly: this is **converging on instances and
churning on classes**, and a fourth prose round is the wrong move.

---

## Part A — the eight prior findings

| Prior | Verdict now | One-line basis |
| --- | --- | --- |
| **R1** (BLOCKING) false non-existence claim in Part 3's frame | **STILL-OPEN** — both named sites CLOSED, class reopened at three new sites | `:664-679`, `:860-868` are correct now; `:128`/`:187-188`, `expressible:69`, `expressible:76` are not |
| R2 "eight of ten have a comparator" | **CLOSED** | `:92-97` |
| R3 §6.3's summary breaks §6.2's rule | **CLOSED** | `:946-962` |
| R4 F4's `1e-5/1e-6` carve-out | **CLOSED** | `:210-219`, `:837-845`, `:1545-1546` |
| R5 `penguins` adjacency arithmetic | **CLOSED** | `:151-171`, arithmetic re-checked below |
| R6 §4.2 lacked §4.3's interval guard | **CLOSED** | `:781-794`, quote verified against `cells.tsv` |
| R7 §11's sweep incomplete in cited sources | **STILL-OPEN** — the two named instances are fixed; the finding as stated is true again | `expressible:69`, `:76`; new instance `G-S1` |
| R8 `result` extension mis-attributes a `sigma` result | **CLOSED** | `:1236-1253`, `capability_ledger.py:2328-2329` re-verified |
| Notes 1–5 | **CLOSED** (all five) | `:711-716`, `:1261-1272`, `:1228-1231`, `:908-912`, `:1504-1507` |

### R1 — STILL-OPEN, and why the two halves differ

**Closed at both sites I named.** `:653-660` quotes the old opening in place and says why it
was wrong; the replacement draft at `:664-679` carries the three-way split explicitly
("read that as 'none found here', not 'none exists'", "For one of them … a comparator does
exist and does accept the syntax"). `:855-858` does the same for the closing paragraph, and
the replacement at `:860-868` states that the two frontier models "are not in the same
position as each other" and names the weaker claim as weaker. F3 is re-sourced to the
four-class frontier with scale-side random effects **first** (`:196-206`) and carries the
explicit prohibition "F3 may not state that the whole list has no comparator" (`:208-209`).
§8.3 is retitled and completed with a class per item (`:1041-1075`).

**The structural remedy is the right shape.** §8.5 (`:1099-1128`) is the mechanism this
document lacked: three named classes, an evidence requirement each, permitted phrasings,
a downgrade direction ("when uncertain between A and C, write C"), and the binding rule that
a list mixing classes may not take a single class-A framing. §14 step 7 (`:1547-1551`) makes
the grep mandatory. I asked for a repair; I was given a rule. That is the better answer.

**Why it is still open anyway.** §8.5's enforcement is a **fixed list of forbidden strings**
(`:1121-1124`). Both new instances evade it — one because it is a different string, one
because it lives in a document the draft-review grep never reads. See G-B1 and G-B2.

### R5 — closed, and the arithmetic re-checked independently

Article order is c08, c04, c05, c06, c07, c01, c09, c03, then the register opening, then
§4.2 (`sleepstudy`), then §4.3 (`penguins`) (`:154-158`, `:645-647`, `:1540-1542`).

- `sleepstudy`: c01 is 6th; c09 and c03 intervene, then the register opening. **Two
  comparisons.** Matches `:164-165`.
- `penguins`: c09 is 7th; c03 intervenes, then the register opening, then the whole §4.2
  subsection. **One comparison plus one frontier subsection.** Matches `:166-168`.

Note for the record: my own round-2 "free fix" asserted the swap would give *both* pairs two
intervening comparisons. That was wrong for `penguins` in the same way the text I was
correcting was wrong. The plan did not adopt my overstatement; it traced the separations
one dataset at a time and said what they actually are. That is the correct handling of a
reviewer's error and I want it on the record, since I inherited one to R8 last round too.

### R7 — the two named instances are fixed; the finding is true again

`expressible-vs-comparator.md:106-114` carries the correction block; `:128-144` restates
class 1 as class B with the run, and quotes the refuted sentence in a superseded block so
the record survives; `:105`'s stale `242:79-80` is repointed to `:86-91`. Round 3 also found
and fixed a third instance of the citation defect at `:92` on its own initiative
(`plan-repair-changelog.md:323`). `candidate-cells.md:97-99` is declared carried with a
gate (`:1349`, `:1584-1587`) — an honest carry, not a miss.

But R7's finding was *"the sweep is incomplete — the same two error classes survive in cited
sources"*. That sentence is true today, of the same file, for the same claim. See G-B1.

---

## Part B — the class sweep the brief asked for

I grepped both target documents for every blanket non-existence phrasing and checked each
against the feasibility batches. Commands:

```
grep -n -E "no (established|comparator|package|other|frequentist|analogue)|none exists|nothing else|no analogue|essentially no" PR2-build-plan.md
grep -n -i -E "no (established|comparator|package|frequentist|analogue)|none (exists|can)|has no " expressible-vs-comparator.md
```

### `PR2-build-plan.md` — 24 hits, 23 clean, 1 violation

Every hit in §4.1, §4.3, §4.4, §5, §7, §8.5 and §11 is either correctly scoped ("we found no
frequentist package **here**", `:810`, `:849`; "treat as 'none found', not 'none exists'",
`:893`) or is the plan quoting a forbidden phrasing in order to ban it. The one violation is
`:128` / `:187-188` — G-B2 below. One further hit, `:1056-1057`, imports an unscoped claim
from doc 158 — G-S5.

### `expressible-vs-comparator.md` — the correction stopped at the section boundary

The three-class preamble round 3 added is at `:122-126` and its scope sentence reads
*"Nothing **below** was searched beyond `DESCRIPTION` `Suggests`."* It governs the four
numbered classes at `:128-169`. It does not reach the **per-family table at `:63-81`**,
which is above it and which round 3 did not touch. That table still contains six
class-A-framed claims, two of them the identical refuted proposition — G-B1.

### `candidate-cells.md`, `158-plan-of-record.md`, `reader-gap-audit.md`, `dataset-inventory.md`

Four hits total. `candidate-cells.md:52` and `:97-99` are scheduled in §11. `:102` is the
*correct* statement and contradicts `:52`, as noted last round. `:289` and
`158-plan-of-record.md:58` quote doc 158's sentence — G-S5.

---

## Part C — what round 3 introduced or left

### G-B1 [BLOCKING] The refuted claim survives, unhedged, in the file round 3 declared fixed

`plan-repair-changelog.md:271-273` says of `expressible-vs-comparator.md`: *"Upstream fixed,
not just downstream … This is the part that stops later documents re-importing the error."*
The fix reached `:110-113`. It did not reach the same file's own per-family table, where the
same proposition appears **twice without any hedge**:

- `expressible-vs-comparator.md:69` (Gamma row): *"**sigma random intercept is FRONTIER**
  (glmmTMB has no formula for dispersion-as-random-effect)"*
- `expressible-vs-comparator.md:76` (nbinom2 row): *"**FRONTIER** for sigma random effects
  (fixed dispersion in glmmTMB)"*

Both are the same claim as the sentence the same file now quotes in a superseded block at
`:140-142` — *"glmmTMB treats dispersion as a fixed nuisance parameter, not a formula-driven
random-effect target"* — and both are refuted by the same evidence: `glmmTMB` accepts
`dispformula = ~ (1 | Subject)`, runs, and returns a dispersion variance component
(`feasibility-batch-1.md:66-73`; re-run by me, Part C/S2 below). They are not hedged by "the
same way" or "known to this survey"; `:69` states a capability absence about a named package
that demonstrably has the capability.

Four further rows carry class-A framing with no class marker, outside the preamble's stated
scope: `:65` ("no established package fits location-scale mixed models with residual-SD
random effects the same way"), `:68` ("no package fits lognormal sigma-RE the same way"),
`:72` ("**FRONTIER throughout** — no established package fits a four-parameter
zero-one-inflated beta … the same way"), `:79` ("**FRONTIER throughout** — … has no
established-package analogue").

**This is not hypothetical downstream risk. `:79` is already cited as authority**:
`feasibility-batch-4.md:126-127` reasons *"`expressible-vs-comparator.md:79` classes
formula-capable `biv_gaussian()` `rho12` as FRONTIER — expressible by drmTMB but with no
comparator to check it against"*. The uncorrected rows are load-bearing in exactly the way
`:110-113` was.

By the plan's own §8.5 (`:1106-1108`), the rule binds "a corrected source document". This
file is one. It fails the rule.

**Fix.** Either (a) extend §11's `expressible-vs-comparator.md` correction to rows `:65`,
`:68`, `:69`, `:72`, `:76`, `:79` with a class marker each — `:69` and `:76` must become
class B, the rest class C — or (b) move the three-class preamble above the table at `:57-62`
and change "Nothing below" to "Nothing in this document", then fix `:69` and `:76`, which no
preamble can rescue because they are false rather than unscoped.

### G-B2 [BLOCKING] The plan mandates a Part 3 heading that its own binding rule forbids

`:187-188` (F2): *"Draft heading for Part 3: **'Where drmTMB has no comparator'**."* The same
string is in the architecture diagram at `:128`.

Part 3 contains two models. For one of them a comparator exists, accepts the syntax, and
returns a variance-component object (`:734-742`). §8.5's binding rule (`:1116-1119`) reads:
*"No sentence anywhere may assert a blanket 'no comparator exists' for a capability where one
demonstrably fits … and a list mixing classes may not be given a single class-A framing —
that was the precise mechanism of the R1 failure."* A section heading over a two-item mixed
list is that framing, in the highest-salience position in the section, above both models and
above §4.1's careful three-way split.

Two aggravating details:

1. The forbidden-string grep at `:1121-1124` does **not** contain this string, so §14 step 7
   passes it. The enforcement mechanism built to stop R1 recurring cannot see the instance
   the same document mandates.
2. This is structurally the R3 defect over again — a flat prohibition (§8.5) and a mandatory
   draft (F2) that breaks it, with no resolution stated. R3 was closed by deleting the
   offending clause rather than amending the rule; the same remedy is available here.

**Fix.** Retitle. *"Where drmTMB has no working comparator"* matches §8.3's own retitled
heading (`:1041`) and §5's coverage-table wording (`:891`). Better still, and matching F3's
content: *"The frontier, and what we did and did not check"*.

### G-S1 [SERIOUS] The citation carrying the R1 fix no longer points at what it claims

The plan cites `expressible-vs-comparator.md:102-133` four times — `:198` (F3), `:681`
(§4.1), `:1060` (§8.3), `:1323` (§10.4.6) — each time as **"the complete four-class list"**.

Measured in the current file: `:104` is the section heading, `:106-114` the round-3
correction block, `:116-126` the preamble, **class 1 at `:128-144`**, class 2 at `:145-154`,
class 3 at `:155-158`, class 4 at `:159-169`. Line 133 falls inside class 1's `VarCorr`
evidence. **The cited range contains one of the four classes.** The four classes span
roughly `:116-174`.

The cause is mechanical and is the point: round 3 inserted ~24 lines into that file (the
correction block, the preamble, the superseded block) and then cited the file by a line range
carried over from my round-2 text, which was measured before the insertion. This is the N4 /
N5 / R7.2 defect class, generated by the repair, at the citation that implements the repair.

**Fix.** Repoint to `:116-174` and re-measure after every further edit — or, better, cite by
section heading ("the FRONTIER region, summarized") rather than by line range, since this
file is under active correction and will move again in the build session.

### G-S2 [SERIOUS] §11.1's provenance does not resolve, and does not cover its own c02 block

`:14`, `:1399` and `plan-repair-changelog.md:228` give the round-3 script as
`scratchpad/ada-round3-verify.R`.

- `ls .worktrees/external-oracle/scratchpad/ada-round3-verify.R` → no such file.
- `find "Github Local/drmTMB" -name "ada-round3*"` → nothing.
- The file exists only in an ephemeral session scratchpad under `/private/tmp/claude-503/…`,
  which the build session cannot reach and which is not preserved.

Second, and separately: the script that does exist fits c01 and c03 in both forms — and
**contains no c02 comparator fit**. §11.1's block at `:1425-1427` reports
`VarCorr(g)$disp Variance 1.521243e-12, Std.Dev. 1.233387e-06, pdHess = FALSE` under the
heading "Script: `scratchpad/ada-round3-verify.R`", and §15.6 (`:1574-1576`) lists the c02
comparator among the round's four re-fits. That measurement came from somewhere else and its
artifact is not named.

**I re-ran both, independently, and every number reproduces.** This is a provenance defect,
not an accuracy defect, and I want the distinction on the record:

```
== c02 comparator: glmmTMB(Reaction ~ Days, dispformula = ~ (1|Subject), data = sleepstudy) ==
Warning: Model convergence problem; non-positive-definite Hessian matrix
Variance:  1.52124307248313e-12      plan says 1.521243e-12   MATCH
Std.Dev.:  1.23338683002663e-06      plan says 1.233387e-06   MATCH
pdHess  :  FALSE                     plan says FALSE          MATCH
logLik  :  NA                        plan says NA             MATCH

== c01 displayed (random-effect) model ==
drm  logLik: -870.0003477315004      plan says -870.000347731500   MATCH
gtmb logLik: -870.0003477315166      plan says -870.000347731517   MATCH
abs diff   :  1.6257e-11             plan says 1.63e-11            MATCH
sigma abs diff: 1.56963e-07 3.76781e-08  plan says 1.5696e-07 / 3.7678e-08  MATCH
```

So the factual core of the R1 repair is sound, and `glmmTMB` demonstrably does return a
dispersion variance component. The defect is that a build session following the plan cannot
reproduce the c02 line from the artifact the plan names.

**Fix.** Commit the script into the worktree at the cited path, extend it to include the c02
comparator fit, and re-emit §11.1 from its output. §14 step 2 already requires a
reproducibility harness; make this its first content rather than a second, lost script.

### G-S3 [SERIOUS] §10.4.6 offers the maintainer a sign-off that reintroduces R1

`:1321-1326` asks the maintainer to choose between `expressible-vs-comparator.md:102-133`
"as corrected" and *"doc 242's own four-item sentence (`242:87-88`) **verbatim**"*, on the
stated ground that "they are the same four classes at more useful resolution".

They are not equivalent for this purpose. Doc 242's sentence, read in place
(`docs/design/242-external-comparator-evidence-class.md:86-91`), is:

> Where `drmTMB` is genuinely novel — scale-side random effects, `sd()` regression,
> bivariate LSS, phylogenetic structure on residual log-SD — **no established implementation
> exists** to borrow credibility from …

That is an unqualified class-A assertion whose first named item is the capability where a
comparator demonstrably fits. Taking option (b) verbatim puts the R1 sentence back into the
register's opening under a maintainer signature. The plan does not warn that one branch of
this choice is the defect it just repaired.

**Fix.** Keep the choice, but state the consequence: doc 242's wording may be used only with
the §8.5 class split appended, and note that doc 242's own sentence is now known to be too
strong for its first item — which is itself a design-doc finding worth reporting upward.

### G-S4 [SERIOUS] "Two of these four are shown below" is false for the second model

§4.1's draft (`:678`) tells the reader: *"Two of these four are shown below."* The four are
the F3 classes, of which class 4 is *"bivariate location-scale-scale models with structured
covariance"* (`:668`).

§4.3's model is `bf(mu1 = …, mu2 = …, sigma1 = ~ species, sigma2 = ~ species, rho12 = ~
species)` with `effect_type = fixed` (`:800-804`, `mc-0181` read from `cells.tsv`). It has no
structured covariance — no `phylo()`, `spatial()`, `animal()`, `relmat()`, no q4/q6/q8 block.
The source says so: `expressible-vs-comparator.md:165-169` calls `rho12 ~ x` *"the one member
of this **neighbourhood** that was tested"*, and the plan repeats the hedge twice — `:204-205`
("§4.3 is inside class 4's neighbourhood") and `:1069` ("item 2 above is the one instance of
this neighbourhood"). The drafted article sentence drops the hedge.

This is R1's defect (i) — the illustrated model is not an instance of the class the register
opens with — moved from the first model to the second. F3's stated purpose ("both illustrated
models are then genuine instances of that list", `:203-206`) is achieved for §4.2 and not for
§4.3. Note also that `:203-206` contradicts itself in one sentence: "genuine instances" then
"inside … neighbourhood".

**Fix.** One clause: *"One of these four is shown below, together with a fixed-effect case
from the fourth's neighbourhood — a correlation that varies with a predictor."* Or widen
class 4's wording so `rho12 ~ x` is inside it, and correct `expressible-vs-comparator.md:159`
to match.

### G-S5 [SERIOUS] Doc 158's blanket sentence is quoted approvingly and not scheduled for repair

§8.3 item 2 (`:1053-1057`) supports its class-A claim with: *"Doc 158's own matrix already
says 'predictor-dependent `rho12 ~ x` has essentially no frequentist comparator'."* Verified
in place at `docs/design/158-phase-19-comparator-matrix.md:79` and
`158-plan-of-record.md:58`.

That sentence is unscoped: doc 158 searched no more of CRAN than Phase 19 did, and §15.8
(`:1588-1590`) says so explicitly for this very claim. §8.5's rule binds statements "in doc
158" by name (`:1106-1108`), and §10.2 lists five doc-158 edits (`:1276-1295`) — none of them
this one. So the plan cites an unscoped claim as corroboration for a claim it spent a
paragraph scoping, and leaves the source sentence standing.

**Fix.** Add a sixth §10.2 edit scoping doc 158's `rho12` cell to the tested set, and drop
the appeal to it from §8.3 item 2 — `feasibility-batch-4.md:52-73` is the real evidence and
it is already cited.

### G-S6 [SERIOUS] §5's mandatory footnote names a Comparison 9, which F1 abolished

`:909`: *"Rows 1 and 2 assign the `mu` submodel of every comparison, including **Comparisons
6, 8 and 9**, which are joint location-scale fits."*

Article numbers run 1–8 (`:61-70`); F1 (`:183-185`) removes the number from both frontier
models precisely so no ninth item exists. The joint location-scale fits are Comparisons
**6 (c01), 7 (c09) and 8 (c03)**. The footnote transcribed build id `c09` as article number
9. §8.4 states the same caveat correctly, in build ids (`:1095`, "c01, c03 or c09").

This is a mandatory article footnote. It would print a reference to a comparison that does
not exist, and it would print it in the section whose entire purpose is to keep the frontier
models out of the enumeration.

**Fix.** "Comparisons 6, 7 and 8."

### Notes (fix while passing)

1. **`:665` over-claims coverage.** The draft says *"Four kinds of model make up **most of
   the rest**."* The source claims less: `expressible-vs-comparator.md:116` says the four
   classes *"recur across nearly every family row"*. §1.3's 79% figure is AGENT-INFERRED and
   is about the non-compared surface as a whole, not about these four classes' share of it.
   Write "Four kinds of model account for much of the rest" or drop the quantifier.
2. **`:753-756` is the last arithmetic-shaped text in Part 3.** The prose pairs drmTMB's
   `0.506` against `glmmTMB`'s collapsed `1.233e-06` on a matched scale. F4 permits it
   (comparator output where the failure is the point, `:212`) and the plan forbids building a
   table from it. It is compliant; it is also the first thing a draft-review reader will
   challenge, so decide it deliberately rather than discover it at the gate.

---

## Part D — converging or churning?

**Churning on the class; converging on the instances. Say it plainly: two rounds of repair
have now each closed the named sites and reopened the same class elsewhere, and round 3
additionally minted a fresh instance of the second recurring class inside the fix itself
(G-S1).**

The evidence for each half:

*Converging.* Round 2 → round 3 closed 7 of 8 findings at their named sites with verifiable
edits; the two remedies I would have called weak (a disclaimer, an instance kill) were both
replaced with stronger ones (article architecture in §2, a claim-class vocabulary in §8.5);
round 3 ran R for the first time, and its numbers reproduce **exactly** under my independent
re-fit (G-S2). Round 3 also self-corrected two of its authors' own errors — Noether's S1
rounding and my own R5 overstatement — rather than transcribing them. Nothing in this
document is being argued down.

*Churning.* Three rounds, one class:

| Round | Where the class was killed | Where it reappeared |
| --- | --- | --- |
| 1 → 2 | `candidate-cells.md:52`, §4.3's wording | Part 3's opening and closing prose (R1, 2 sites) + 2 uncorrected source lines (R7) |
| 2 → 3 | §4.1, §4.4, F3, §8.3; `expressible:110-113` | F2's mandated heading (G-B2) + `expressible:69`, `:76`, and four unclassified table rows (G-B1) |

The pattern is not carelessness. Each round fixed exactly what the audit named and the audit
named exactly what it found. The mechanism is that **the claim class is open-ended and the
enforcement is a closed list**: §8.5 forbids five strings (`:1121-1124`) and greps the draft
article only (`:1547-1551`). Both new instances are outside that intersection — one is a
sixth string, one is in a document the article cites rather than contains. A blacklist cannot
close an open class, and a fourth round of string-hunting will produce a fourth round of
"fixed at the named site".

The same is true of the citation class. §11 is now a 15-row correction table plus two
correction-of-the-corrections tables (`:1358-1394`), and the round that wrote them broke a
citation by editing the file it cites. Line-range citations into documents under active
correction cannot be kept true by re-checking harder.

### Recommendation — do not run a fourth prose round

Two structural moves, either of which ends the pattern. They are not alternatives to fixing
G-B1, G-B2, G-S1 and G-S6, which are one-line edits and should be made regardless.

**1. Narrow the scope — take §2.4's escalation (recommended).** Drop the two frontier fits
from the article; let Part 3 be F3's four-class list with a claim class per item, and nothing
else. This is already on the maintainer's sign-off list as §10.4.5 (`:1318-1320`) and the
plan already calls it "the strongest possible answer to A1" (`:247-249`).

It also deletes the surface the recurring class lives on. Gone in one move: the register's
heading (G-B2), the "two of these four are shown below" claim (G-S4), F4's entire risk
surface and its draft gate, both interval guards (§4.2/§4.3), the non-transfer sentences, the
`0.506`-vs-`1.233e-06` pairing, and A1's unresolved residual — `sleepstudy` and `penguins`
each appearing twice (`:1564-1565`), which three rounds have named and none has fixed. The
demonstrations are why the article keeps having to say what does and does not exist about a
model it is showing; without them, the four-class list can be stated once, classified once,
and checked once. Cost: two reader stories, both of which are frontier illustrations that
§4.2 and §4.3 already forbid the reader from trusting quantitatively (`:750-752`, `:781-784`).

**2. If the frontier demonstrations are kept, change the enforcement from a blacklist to a
required clause.** Replace "these five strings are forbidden" with: *no sentence may assert
comparator absence unless the same sentence names the set searched and whether it was run.*
That is checkable by reading rather than by grep, it catches strings nobody has thought of
yet, and it converts §8.5 from a list that must be extended after each failure into a rule
that holds at the first instance. Pair it with citing source documents by heading or quoted
phrase rather than by line range while those documents are under correction (G-S1), and with
a one-pass freeze of §11's corrections — all files, all lines, in one commit — instead of the
per-round partial sweeps that have now produced three generations of correction tables.

**churn_risk: HIGH.** Not because the work is bad — the plan is markedly better than the one
I audited last round — but because the failure mode is now measured, repeated, and
structural, and the remedy applied so far is of a kind that cannot close it.

---

## What round 3 got right

Recorded so the verdict is not read as a rejection.

1. **§8.5 is the right kind of answer.** It generalises from an instance to a rule with a
   vocabulary, an evidence requirement, a downgrade direction, and a named enforcement point.
   Its weakness is the blacklist, not the concept.
2. **It ran R rather than reasoning from documents**, and every number it produced survives
   an independent re-fit (G-S2's output block). Three rounds of this phase argued about
   whether `glmmTMB` can put a random effect on dispersion; round 3 settled it by running it.
3. **It narrowed two claims against their own authors** — Noether's "identical"
   log-likelihoods became `1.63e-11` and `4.20e-10` (`:1430-1434`), and my R5 "two in each
   case" became the separations the order actually delivers (`:164-168`). Both narrowings are
   correct and both cost the author something.
4. **It fixed R4 by removing the carve-out rather than defending it** (`:210-219`), and R3 by
   deleting the offending clause rather than amending the rule (`:956-962`). Those are the
   harder of the two available choices each time.
5. **§15 declares what it did not fix**, including `candidate-cells.md:97-99` (`:1584-1587`)
   and the fact that rounds 1–2's untouched sections were not re-audited (`:1591-1593`). Both
   declarations are accurate; I checked the first and accept the second as a stated limit.

---

## Gate conditions

1. **G-B1 (BLOCKING).** Correct `expressible-vs-comparator.md:69` and `:76` — both are false,
   not merely unscoped — and give `:65`, `:68`, `:72`, `:79` a §8.5 class each, or move the
   three-class preamble above the table and rescope it to the whole document. Add the rows to
   §11.
2. **G-B2 (BLOCKING).** Retitle Part 3. Add the new heading string to §8.5's forbidden list so
   the same phrasing cannot return, and add "a section heading is a sentence for this rule".
3. Fix G-S1 (`:198`, `:681`, `:1060`, `:1323` → `:116-174` or a heading citation), G-S4
   (`:678`), G-S6 (`:909` → "6, 7 and 8"). One line each.
4. G-S2: commit the round-3 script at the path §11.1 cites, extend it to the c02 comparator,
   and re-emit §11.1 from its output.
5. G-S3: state the consequence of §10.4.6's option (b) before asking for the signature.
6. G-S5: add the doc-158 `rho12` scoping edit to §10.2 and drop the appeal at `:1056-1057`.
7. Clear the two notes.
8. **Before any of this, put Part D's recommendation to the maintainer.** If §2.4's
   escalation is taken, items 2, 3 (G-S4), and most of §4 stop existing, and the two rounds of
   effort those sections would still need are not spent.

## Verification limits of this audit

I ran the fits in G-S2 and nothing else. Every other number in the plan remains Gauss's or
Noether's measurement, cited as theirs, and I did not re-verify any of them — including all
of c04–c09 and every c10 value, which §15.6 correctly declares. I read
`PR2-build-plan.md` and `expressible-vs-comparator.md` in full;
`plan-repair-changelog.md`'s round-3 block in full; the four feasibility batches at every
cited line plus `feasibility-batch-1.md` in full; and re-read in place `cells.tsv`
(`mc-0181`, `mc-0266`), `docs/design/242-…:78-105`,
`docs/design/158-phase-19-comparator-matrix.md:79`,
`tools/capability_ledger.py:2326-2341`. I did **not** re-audit §9, §12, §13 or the c04–c09
specifications, which §15.9 declares unrevised since round 2 — so a defect there would be
two rounds old and unfound by anyone. G-S4's classification question (whether `rho12 ~ x`
belongs inside "bivariate LSS with structured covariance") is a judgement about the source
document's taxonomy, not a repo-grounded fact; I state it as my reading of
`expressible-vs-comparator.md:159-169`, which uses "neighbourhood" rather than membership.

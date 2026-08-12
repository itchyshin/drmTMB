# Proposal: swap validation machinery between drmTMB and gllvmTMB

**Status:** discussion proposal only. It changes no package code, capability
status, public wording, release gate, or running campaign. Adoption is
Shinichi's decision.

**Relation to the cross-package governance packet.** This proposal responds to
the evidence-led validation doctrine packet (2026-08-11) and to its two sibling
drafts, `docs/dev-log/research/2026-08-11-evidence-led-development-principles-note.md`
in this repository and
`gllvmTMB/docs/dev-log/research/2026-08-11-draft-validation-development-principles.md`.
It accepts the packet's core rule and rejects its delivery vehicle.

**Relation to open issues.** This proposal is an answer to the question parked
in issue #1015 (internal validation-card pilot): the pilot should be three
schema transfers rather than two prose cards. It relies on issue #1011 (ledger
prose rots silently) for the structural argument in §5 and for the keyed-field
constraint in Transfer C. It proposes no new issues.

**Evidence state:** the inventory below is REPO-VERIFIED against both working
trees on 2026-08-11 (commands in §6). The recommendation is AGENT-INFERRED.

---

## 1. The core rule is not in dispute

> A converged fit is evidence that an algorithm returned a numerical result.
> It is not, by itself, evidence of identification, accurate estimation, or
> calibrated inference.

Both packages already act on this. The question this proposal answers is not
whether the doctrine is right but what artifact should carry it.

## 2. What the two packages actually have

The packet assumes both packages need the same new thing: a per-route
validation card in `docs/validation-cards/`. Reading both registers shows
something different — each package already holds, in production, close to
exactly what the other is missing.

| | `drmTMB` | `gllvmTMB` |
| --- | --- | --- |
| Form | three normalised TSVs plus `schema.json` under `docs/dev-log/dashboard/capability-ledger/` | one 830-line Markdown document, `docs/design/35-validation-debt-register.md` |
| Scale | 694 cells, 774 evidence receipts, 738 transitions | ~263 table rows; 228 `covered` / 109 `partial` / 53 `blocked` / 8 `opt-in` |
| Per-row fields | 30 in `cells.tsv`, 12 in `evidence.tsv` | 5 — ID, Capability, Status, Test evidence, Notes |
| Reproduction receipts | `commit_sha`, `run_id`, the exact `command`, `replicates` | 5 commit-like strings in the whole file; no commands, no replicate counts |
| Independent review | `reviewed_by` per receipt, `blocking_reviewers` per cell | section-level `Row-owner:` only |
| Claim boundary | per cell **and** per evidence receipt | free-text Notes |
| Demotion | `transitions.tsv` — a 738-row **log** | the overpromise-preventer — a standing **rule** |
| Machine validation | `schema.json` | none; `tools/` carries no ledger validator |
| Currency | `updated_commit` / `updated_date` per row | section-level snapshot dates plus append-only "Update —" blocks |

Neither register records literature or implementation provenance. `cells.tsv`
has no citation field; the gllvmTMB row schema has no citation column; neither
`docs/design/05-testing-strategy.md` mentions provenance.

## 3. The finding

**The asymmetry is representational, not a difference in diligence.** drmTMB
built a relational schema and left its maintenance rules implicit. gllvmTMB
wrote excellent maintenance rules and left them attached to a five-column
Markdown table.

Two consequences are already visible rather than predicted.

**gllvmTMB is accreting overrides instead of editing rows.** Section 2 of the
register carries an inline supersession note stating that historical sentences
describing the structured augmented-slope grid as "complete for every family"
mean complete only for the then-registered route-specific core cells. A reader
must reconcile the section snapshot date, the row, and any later override
paragraph to recover the current claim. A row-level `updated_date` and an
editable row would make the correction land where the claim lives.

**drmTMB can log a demotion but nothing makes one fire.** `transitions.tsv`
records 738 status changes after the fact. gllvmTMB's register states the rule
that produces them: if a row claims `covered` but the pre-publish audit cannot
point at a test file with concrete assertions, the row is downgraded before
publication. drmTMB has the ledger and the memo-blind D-43 review but no
written standing rule of this shape.

## 4. Proposed transfers

Three transfers, in priority order. Each is small, reversible, and independent
of the others.

### Transfer A — gllvmTMB gains the receipt schema

Add to the register's row contract: `commit_sha`, reproduction `command`,
`replicates`, `reviewed_by`, per-row `claim_boundary`, `updated_date`.

Preferably migrate the register to TSV plus a `schema.json`, mirroring
`capability-ledger/`, so that a validator can run in `tools/` and so that
corrections edit the row rather than accreting a paragraph above it. If the
migration is judged too disruptive to the live separation programme, the
columns can be added to the existing Markdown tables first and the migration
deferred; the columns are the substance, the format is the convenience.

*Acceptance:* every row touched after adoption carries a commit SHA and a
runnable command, and one `partial → covered` walk is reproducible from the row
alone.

*Non-goal:* retrospectively back-filling 263 historic rows.

### Transfer B — drmTMB gains the demotion rule

Write gllvmTMB's overpromise-preventer into drmTMB's testing strategy, adapted
to this package's tier vocabulary: a cell may not hold `inference_ready_with_caveats`
or `supported` if a pre-publish audit cannot point at an evidence receipt whose
`result` and `claim_boundary` cover the estimand being claimed; absent that, the
cell is walked down before publication.

This is stronger than the per-cell `demotion_trigger` field considered earlier,
because a standing rule applies to all 694 cells at once rather than to the
cells whose authors remembered to fill a field.

*Acceptance:* the rule is stated in `docs/design/05-testing-strategy.md` and
referenced from the ledger README; one existing `supported` or
`inference_ready_with_caveats` cell is audited against it as a smoke test.

*Non-goal:* re-auditing all 27 promoted cells as part of adoption.

### Transfer C — both packages gain provenance fields

This is the one genuinely novel contribution of the governance packet and the
only part of its card template not already implemented somewhere. Add to each
row schema:

- `source_citation` — BibTeX key into `REFERENCES.bib`, or explicit `none`;
- `provenance_relation` — one of `direct_implementation` | `adaptation` |
  `independent_derivation`;
- `assumption_anchor` — a design-document anchor (for example
  `docs/design/224#cox-reid-assumptions`) stating what the source assumes that
  this route inherits;
- `comparator_bridge` — an anchor into the bridge map recording the
  parameterisation link the evidence relies on (links, scales, constants,
  constraints, data layout).

**All four are keys, deliberately.** An earlier draft of this transfer proposed
`imported_assumptions` as free prose in the row. Issue #1011 documents three
production incidents in one session where exactly that shape failed: free-text
`claim_boundary` and `next_gate` strings cross-referenced other rows and a gate
predicate, a partial change falsified them, and all 67 ledger tests passed
because the strings stayed syntactically valid while their truth value changed.
Its structural conclusion governs this transfer — cross-references belong in
keyed fields, because `claim_boundary` is not part of the ledger key and no
join, filter, or aggregation can see what it asserts. A BibTeX key, an
enumerated relation, and two anchors are all joinable and all mechanically
checkable for existence; a paragraph about imported assumptions is not.

The packet's sharpest sentence belongs here: a literature citation records
provenance and is not a correctness certificate. `comparator_bridge` is second
priority to the first three; drmTMB has partial coverage already in
`docs/dev-log/dashboard/binomial-bridge-map.tsv` and
`bridge-provenance-fields.tsv`, gllvmTMB has none.

*Acceptance:* the fields exist in both schemas and are populated for the
method-bearing routes touched after adoption.

*Non-goal:* a provenance entry per utility helper, and any new simulation run
merely to populate a field.

## 5. What this proposal recommends against

**Do not create `docs/validation-cards/`.** Sections 1, 2, 5, and 6 of the
packet's card template restate fields that `cells.tsv` and `evidence.tsv`
already carry under `schema.json` validation. Re-encoding them as per-route
free-text Markdown converts machine-checkable records into prose, in a
repository whose sibling package is currently demonstrating how Markdown
registers drift. The residual value of the card is Transfer C, which is four
columns.

This is not a stylistic preference. Issue #1011 is the measured version of the
same argument, from three incidents in a single session: prose cross-references
inside ledger rows rot silently, survive every mechanical check, and were caught
only by reading rendered output or by a closeout audit — once twenty minutes
after the team had written down the lesson from the previous two. The card
template is six sections of exactly that material. Adopting it would multiply
the surface that #1011 asks the project to shrink.

**Do not add the A–U evidence taxonomy as a third vocabulary.** drmTMB already
carries claim tier in `evidence_tier` (`none` 373, `point_fit_recovery` 180,
`diagnostic_only` 70, `interval_feasible` 44, `inference_ready_with_caveats` 23,
`supported` 4) and evidence kind in `evidence_class`. gllvmTMB carries
`covered / partial / opt-in / blocked`. A third hand-maintained vocabulary with
no stated invariant binding it to the other two adds reconciliation work without
adding a check. If evidence kind needs sharpening, extend the existing
`evidence_class` vocabulary in place.

**Do not open one umbrella plus five child issues per package.** The three
transfers above are schema edits and one paragraph of doctrine. Issue
architecture at that scale should follow demonstrated need, not precede it.

## 6. Honest limitations of this inventory

- **drmTMB's receipt population is mostly legacy.** 668 of 774 `evidence.tsv`
  rows carry `evidence_class = legacy_model_evidence`; the fine-grained classes
  (`model_recovery` 24, `rejection_test` 18, `recovery_test` 18,
  `g2_contract_test` 18, `contract_test` 14, `coverage_study` 7,
  `admission_test` 6, `estimator_diagnostic` 1) cover about 14% of receipts.
  The claim in §2 is that drmTMB's receipt **schema** is stronger, not that its
  receipt **population** is uniformly rich. Existence is not validation, and
  the legacy bulk has not been audited here.
- **Depth is asymmetric.** This inventory read drmTMB's ledger schema and
  vocabulary distributions directly, and gllvmTMB's register structure,
  maintenance section, and status distribution. It did not audit whether any
  individual gllvmTMB row's cited test file contains the assertions it claims,
  nor re-audit drmTMB's promoted cells.
- **The gllvmTMB register is live, not stale.** Last modified 2026-08-03
  (`f5f89f53`). The override-accretion pattern in §3 is a representational
  observation, not evidence of neglect.
- **Nothing outside drmTMB was written.** The gllvmTMB working tree was read on
  branch `claude/design-117-separation-programme` and left untouched.

### Verification commands

```sh
cd drmTMB
head -1 docs/dev-log/dashboard/capability-ledger/cells.tsv | tr '\t' '\n' | nl
head -1 docs/dev-log/dashboard/capability-ledger/evidence.tsv | tr '\t' '\n' | nl
awk -F'\t' 'NR>1{print $17}' docs/dev-log/dashboard/capability-ledger/cells.tsv | sort | uniq -c | sort -rn
awk -F'\t' 'NR>1{print $3}'  docs/dev-log/dashboard/capability-ledger/evidence.tsv | sort | uniq -c | sort -rn
```

```sh
cd gllvmTMB
grep -c "^| " docs/design/35-validation-debt-register.md
grep -oE "\b(covered|partial|opt-in|blocked)\b" docs/design/35-validation-debt-register.md | sort | uniq -c
sed -n '54,78p' docs/design/35-validation-debt-register.md
```

## 7. Decision requested

Accept, revise, or reject each transfer independently. If accepted, the natural
sequence is B (one paragraph, this repository, no schema change), then C (four
columns, both repositories), then A (largest, and touches a repository with an
active separation programme lane).

No transfer requires new compute. If any later reveals a route whose provenance
or comparator bridge cannot be recorded without a new simulation, that
simulation is a separate proposal under the 30-minute estimate rule.

---

*Prepared by the Claude lane on branch `claude/handover-freshness-0718`, which
took the validation-governance documentation lane. Committed so that other lanes
can see it; the two sibling discussion drafts remain untracked and were not
staged, edited, or claimed.*

# After-task — evidence re-wiring, the tier contract, and the assertion gap

**Lane:** `claude/lane-irc-legacy-evidence` · **Platform:** Claude Code · **Date:** 2026-08-15
**Worktree:** `~/local-scratch/lanes/drmTMB-interval-truth-audit` (reused; compiled `.so` retained)

## 1. Goal

Close the follow-up the interval-claim truth audit (PR #1040) left open: the 16 cells at
`inference_ready_with_caveats` — the tier that tells a reader *"Yes — report the profile interval"* —
resting on a single `legacy_model_evidence` stub with no command, run_id or replicates. Then answer
the question that audit exposed: **what does `interval_feasible` actually claim?**

## 2. Implemented

- **Re-wired all 16 cells to their real campaigns** (`ev-<cell>-campaign-rewire` `coverage_study`
  rows; `primary_evidence_id` repointed). Four parallel audits agreed all 16 are class A — the runs
  exist, were reviewed, and were promoted; the 2026-07-11 schema migration dropped the link.
  **41/41** cells at that tier are now coverage-backed. **Zero demotions.**
- **Corrected the merged coverage map** (dated CORRECTION block): class (b) 21→31, class (c) 65→55,
  defects 189→179; the failure mode stated precisely (path-shaped sources were classified correctly,
  board-key sources were not followed through the join).
- **Recorded the SR475 staleness** (`docs/dev-log/dashboard/2026-08-15-sr475-results-supersession.md`):
  the campaign TSV still says `do_not_promote` for rows a later review promoted. Pointer added; frozen
  decision columns left byte-intact.
- **Decided and implemented the tier contract** (Shinichi, 2026-08-15; memo
  `docs/design/255-interval-feasible-tier-contract.md`): `interval_feasible` claims **shape**;
  location is a new orthogonal `location_checked ∈ {passed, failed, not_applicable, unchecked}`
  column, added to `CELL_FIELDS`, the schema enum, and validation, and **derived** for all 740 cells.
  Of the 226 claiming cells: 145 passed · 75 unchecked · 6 not_applicable.
- **Closed the assertion gap at all 14 label-only confint sites** (7 test files): endpoints now
  asserted finite and ordered. Proven by deliberate mutation (red, then green on revert).
- **Restated the 7 demoted cells' boundaries**: the `"interval_feasible only for…"` prose contradicted
  their `diagnostic_only` tier, and the recorded ground prejudged the tier question. The operative
  ground under the adopted contract is that the fixture misspecification invalidates the **point**
  premise; `location_checked=failed` records the bracketing miss separately. Originals retained,
  quoted, inside the new text.

## 3a. Decisions and Rejected Alternatives

| Decision | Rejected | Why |
| --- | --- | --- |
| Shape + separate `location_checked` field (owner's call, from Fisher's memo) | Location-required; rename to `interval_located`/`interval_computed`; defer | Shape-only is what the largest owner-approved cohort decided in writing (108 cells), what the shipped reader surface says, and location-required is unsatisfiable by the Godambe route, which assigns the tier at runtime with no truth in scope. The rename remains the honest fallback if the category-error argument is later weighted higher. |
| `location_checked` **derived** from manifest + re-check + coverage rows | Hand-assign per cell | Hand-assignment recreates the hand-typed-truth defect one layer up. |
| Append/restate boundaries; never rewrite merged docs or frozen TSV columns | In-place edits | Same append-only discipline as the `mc-0248` correction; frozen decision columns are an audit trail. |
| Fix the 14 assertion sites now | Wait for the contract decision | They fail under **every** reading of the tier. |

## 4. Files Touched

**Ledger:** `cells.tsv` (16 primaries repointed · `location_checked` column added + populated ·
7 boundaries restated · 26 citation line-shifts) · `evidence.tsv` (+16 `coverage_study` rows) ·
`schema.json` (field + enum) · 31 regenerated outputs.
**Tools:** `tools/capability_ledger.py` (LOCATION_CHECKED enum, field, schema, validation) ·
`tools/integrate_b4_ci_c1.py` (two gated re-freezes, preconditions recorded beside the constants).
**Tests:** `test-beta-binomial.R`, `test-cumulative-logit.R`, `test-hurdle-nbinom2.R`,
`test-profile-targets.R`, `test-truncated-nbinom2-location-scale.R`, `test-zi-nbinom2.R`,
`test-zi-poisson.R` — finite/ordered endpoint assertions.
**Docs:** `docs/design/255-interval-feasible-tier-contract.md` (new) ·
`docs/dev-log/2026-08-15-interval-truth-coverage-map.md` (CORRECTION block) ·
after-task 2026-08-15 issue ledger (+2 rows) · `2026-08-15-sr475-results-supersession.md` (new) ·
this report · plan-actual · check-log entry.
**Scratchpad:** `irc-evidence-batch-{A,B,C,D}.md`, `irc-legacy-16.json`, `pilot-derived.json`,
`assert-gap-14.json`, `run-assert-tests.R`.

## 5. Checks Run

| Check | Result |
| --- | --- |
| Full CI python set (6 suites) | **6/6 OK** — after every commit, not a subset |
| `capability_ledger.py --check` | **OK (31 outputs)** |
| `emit-profile-truth-manifest.R --check` | OK (30 rows) |
| `check-capability-runtime.R` | OK (18 routes) |
| `check-profile-fence-integrity.R` | VIOLATIONS: none |
| `check-evidence-citations.R` | VIOLATIONS: none |
| 7 touched test files | FAIL=0 (81/96/60/986/78/59/57 passes) |
| Coverage recomputation | pilot rates recomputed from both TSVs; SR475 rates recomputed from raw replicates (0.970526, 0.978947) |

## 6. Tests of the Tests

**The mutation proof caught my own defect.** The first version of the new assertions used
`ci$conf.low`/`ci$conf.high` — the *receipt* column names. `confint()` returns `lower`/`upper`, so
`all(NULL < NULL)` = `all(logical(0))` = `TRUE`: the assertions **passed vacuously**, the exact
defect class being fixed, reproduced one level up. The deliberate red (flip `<` to `>`) exposed it —
FAIL stayed 0. After the column fix: mutant FAIL=1, revert FAIL=0. A guard proven only by passing has
not been shown to guard anything.

The two pinned ledger tests were re-run against every change; the `mc-0494` conditioning-sentence pin
survives inside the retained original boundary by construction, and both B4-CI re-freezes were gated
on field-level diffs proving no pre-existing field moved.

## 7a. Issue Ledger

| # | Issue | State |
| --- | --- | --- |
| 1 | 16 interval-permission cells on runless stubs | **FIXED** — re-wired, 41/41 coverage-backed |
| 2 | Merged class-(c) count overstated by 10 | **CORRECTED** on the map + after-task |
| 3 | SR475 TSV frozen pre-decision | **RECORDED** — supersession note |
| 4 | `interval_feasible` contract undefined (4 unreconciled cohort standards) | **DECIDED** — shape + `location_checked` |
| 5 | 14 label-only confint sites | **FIXED** + mutation-proven |
| 6 | 7 demoted cells' boundaries contradicted their tier / prejudged the contract | **RESTATED** |
| 7 | 3 `expect_true(all(...))` sites on other objects share the vacuous shape (`test-animal-relmat-gaussian.R:1612`, `test-phase18-biv-gaussian-q8-endpoint-recovery.R:68-69`, `test-julia-inference.R:155-156`) | **OPEN** — columns not verified |
| 8 | ~26 `interval_feasible` cells genuinely `unchecked` post-contract | **OPEN** — the honest residual population |
| 9 | Staleness class "results file frozen before its superseding decision" unswept repo-wide | **OPEN** |
| 10 | Fisher could not reproduce the audit's 112/105 split; 105/121 (or 126/100) derived instead | **RESOLVED** in the memo — my published figures were wrong |

## 8. Consistency Audit

Fix-the-class applied: after the vacuous-column mistake, the whole suite was swept for the same shape
(`any()` sites self-protect; `expect_true(is.na(NULL))` fails on length-0; three `all()` sites
flagged open). After the line-shift, **all** citations into the 7 touched files were shifted (21
cells), and the 5 ranges ending before their insertion point were extended. The B4-CI pins were
re-frozen only after proving byte-level innocence of every pre-existing field across all three pinned
cohorts.

**Memory receipt:** loaded repo `AGENTS.md` LOAD-FIRST, `CLAUDE.md`, hub `AGENTS.md`; guards that
fired: D-88/D-87 (lane named, no foreign files), D-43 (no completion claim without fresh review — the
tier decision went to the owner), append-only corrections, "a narrow or negative search is not proof"
(the phase2 `spec` column), and today's own lesson — the unit of a check must be the unit of the
claim — which the vacuous-column incident re-instantiated within hours. **Golden Set:** not in scope
— no R package source changed (`R/`, `src/`, `NAMESPACE`, `DESCRIPTION` untouched); the test edits
add assertions only.

## 9. What Did Not Go Smoothly

- **I reproduced the audited defect class in my own fix** (vacuous columns), caught only by the
  mutation proof. Recorded in the commit and here.
- My published 112/105 split was wrong (Fisher: 105/121); my "40–70 h programme" shrank to ~26 cells
  once the contract was decided.
- The first `sed`-based mutation ran against a pattern that matched yet "passed" — because the
  assertion itself was vacuous, not because the tooling failed. Diagnosing that took three probes.
- Backtick shell-interpolation ate two words of a commit message (amended via `-F`).

## 10. Known Residuals

- The **~26 genuinely-unchecked** `interval_feasible` cells (`location_checked=unchecked`, excluding
  the 2026-07-11 import, Godambe, and 135-trace rows) are the remaining honest gap; closing them is
  now optional-but-bounded work, not a 105-cell programme.
- The 44-cell 2026-07-11 import at `interval_feasible` remains evidence-weak under **any** contract.
- Issues 7 and 9 above; `mc-0596`; `binding_source_sha256`; the 31 no-truth re-check cells.
- The 7 restated boundaries still cap at `diagnostic_only`; re-promotion needs a repaired fixture and
  a converging multi-seed run.
- `location_checked` is populated but **no generated surface renders it yet**; the reader-facing
  display of the new field is future work.

## 11. Team Learning

The lesson from this morning — *the unit of a check must be the unit of the claim* — recurred
**within hours, in my own repair**: assertions joined to the wrong column names pass vacuously
exactly as truth joined to the wrong target does. The generalisation now proven twice in one day:
**`all()` over a silently-empty vector is the R-shaped form of the wrong-join defect; prove every new
guard can fail before trusting that it guards.** Candidate for LESSONS on the owner's word.

## 12. Cross-Product Coverage

**Cross-cutting thing — the `location_checked` field** (new column on all 740 cells).

Covers ✓ — schema field + enum + validation · derivation for all four values · the 226 claiming
cells' honest split (145/75/6) · consistency with the 7 demotions (`failed`) and the association axis
(`not_applicable`) · both B4-CI pins re-frozen with proof.

It does NOT cover ✗ — any generated reader surface (the field is stored, not yet rendered) · any
gate consuming it (the truth gate still keys on tier rank, not on `location_checked`) · the
`missing_response` axis's G-gates, which have their own evidence ladder · downstream consumers of
`cells.tsv` outside this repo · automatic maintenance (nothing yet forces a new cell to declare it —
the validator rejects unknown values but a future migration adding rows without the column would fail
loudly rather than default sensibly).

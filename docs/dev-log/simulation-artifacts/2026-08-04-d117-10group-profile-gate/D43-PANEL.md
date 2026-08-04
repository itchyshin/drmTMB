# D-43 completion panel — D-117 10-group profile gate

**Outcome: 2 of 3 NOT-DONE → the PASS claim is WITHHELD.** (Third also NOT-DONE,
but on inaccessibility rather than a defect — see below.)

**The panel fired late.** It was in the arc's approved plan, positioned at N6
*before* the claim, with the rule *"≥2 NOT-DONE verdicts withhold the claim."* It
did not run. The PASS was committed (`f7e822fbb`), written into `check-log.md`
(`b63bc44e1`), and opened as PR #919 before any reviewer existed. Plan-vs-actual
reconciliation caught the omission and the panel was convened afterwards. This is
recorded rather than quietly repaired: firing after publication inverts the burden
from *earn the claim* to *unpublish it*, which is strictly harder.

Three fresh reviewers, distinct lenses, each instructed to **default to NOT-DONE**.

| Reviewer | Lens | Model | Verdict |
|---|---|---|---|
| Fisher | statistical inference | Sonnet | **NOT-DONE** |
| Rose | claims / scope (load-bearing) | Opus | **NOT-DONE** |
| Noether | mathematical consistency | Sonnet | **NOT-DONE** (tool-limited) |

## What the panel agreed on

**The numbers are sound.** Both reviewers with data access re-derived every
headline figure from the raw per-replicate CSVs — one bypassing the stored
`profile_covers` column entirely and recomputing coverage from
`profile_lower`/`profile_upper`/`truth_sd`. Zero mismatches across 4,000 rows. No
rule-bending, no complete-case filtering, no fabrication. The pre-registration
genuinely precedes the results (17:35:16 vs 17:49:08 UTC, anchored by in-CSV
timestamps). The reproduction of the banked 2026-07-26 cell matches on five
independent statistics.

**This was never a numbers problem. It is a claim problem.**

## The findings that withheld the claim

1. **The pooled PASS averages two regimes with opposite verdicts, and the
   conditioning flag is user-observable.** Applying the arc's own gate to the
   `profile.boundary` sub-population gives BORDERLINE / FAIL / FAIL, with
   conditional coverage 0.8566 / 0.0732 / 0.2540 against non-boundary
   0.9703 / 0.9656 / 0.9829. At `sd_mu = 1.0` that is **worse than the 0.829 which
   disqualified the marginal route** in D-117's own framing. The arc reported the
   split but never gated it.
2. **A large, significant point-estimate bias went unreported** — −16.9% / −9.1% /
   −9.1% / −9.2%, p < 1e-23 in every cell — and it is the mechanism behind the
   upper-miss asymmetry the arc did report.
3. **"Not materially worse than the pooled figure" is contradicted by the arc's own
   numbers** at z ≈ 2.5 (worst cell 0.9140 vs 0.9368).
4. **D-97's provenance contradicts the arc's central premise** ("12 A1 cells,
   11,988 retained attempts" vs a bootstrap-only 12-cell campaign and a 3-cell
   profile campaign). Unresolved.
5. **The after-task report failed the hub's own validator** — 11 of 12 required
   headers absent, and the missing ones were exactly those that surface failure.
6. **No user-facing warning** for `profile.boundary = TRUE`, even though `confint()`
   actively warns on the analogous Wald case and steers users *into* this regime.

All were actioned: `VERDICT.md` rewritten, the after-task rebuilt to the 12
required headers and validated clean, and the check-log corrected. Items 4 and 6
remain open and are carried to the owner.

## On the third reviewer

The math-consistency lens was dispatched to an agent type with only Read/Grep/Glob
— no Bash, no git — so it could not read the branch and returned NOT-DONE on
inaccessibility rather than on any defect. **That is an orchestrator dispatch
error, not a finding**, and it is recorded so the verdict is not over-read. Its
independent recomputation from staged data matched every figure, and it
additionally confirmed the seed algebra analytically (six pairwise-disjoint
1000-wide blocks, 99,000 apart) and noted that the harder `SUPPORTED` tier fails on
all four cells — consistent with the arc's own disclaimer that no `supported` claim
is made.

**Lesson for future panels:** check that the agent type's tool set can actually
execute the brief before dispatching. A reviewer that cannot read the artifact
produces a verdict about the harness, not about the work.

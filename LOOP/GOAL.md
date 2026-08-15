# GOAL — every drmTMB cell claiming an interval has a verdict on whether that interval BRACKETS its true value

**IMMUTABLE for this run.** Re-read this file at the top of EVERY arc, before anything else.

## Mission

237 capability cells claim `evidence_tier` of `interval_feasible` or above. `tools/profile_truth_gate.py`
is the only thing that checks whether a profile interval actually **contains its true value**, rather
than merely having the right *shape* (conf_status, convergence, pdHess, boundary, clamp, trace). That
gate derives truth from `tools/profile-truth-manifest.tsv`, which reaches **30 cells — 27 of them at a
claiming tier**. So **209 cells make a location claim that nothing has ever checked for location.**

Verified against `origin/main` `82cd00560` on 2026-08-15 (not inherited from the plan):

| tier | population | in manifest | uncovered |
| --- | ---: | ---: | ---: |
| `interval_feasible` | 192 | 27 | 165 |
| `inference_ready_with_caveats` | 41 | **0** | 41 |
| `supported` | 4 | **0** | 4 |
| **total** | **237** | **27** | **210** |

210 are not in the manifest; **209** need classification (`mc-0282` is a documented `UNGATED`
exemption, `tools/tests/test_profile_truth_gate.py:62`). **209 is the workload; 237 is the tier
population.** The tiers *above* `interval_feasible` have **zero** location coverage — the
most-claimed cells are the least checked.

**Why now.** 0.7.0 is the CRAN target and is held. The defect class is proven, not hypothetical: on
2026-08-03 three cells reconciled 5/5 PASS while holding an interval that missed its own truth —
`mc-0423` `[0.137, 0.479]` vs `0.55`; `mc-0409` `[0.610, 0.902]` vs `0.6`; `mc-0292`
`[0.404, 0.694]` vs `0.7`. In one case the agent printed the correct endpoints and then wrote "YES".

## Definition of done

- [ ] Each of the **209** uncovered cells carries a recorded verdict: covered-and-passing,
      covered-and-demoted, or explicitly classified as checked by a stronger instrument.
- [ ] The manifest is **derived** from fixture builders, never hand-typed.
- [ ] The gate's coverage is extended via the sweep in `tools/tests/test_profile_truth_gate.py:97-120`,
      and CI is green.
- [ ] Every miss is adjudicated; every demotion carries a recorded reason.
- [ ] After-task report + plan-vs-actual filed.

## Invariants (never violate, even to finish faster)

- **The gate's tolerance is NEVER adjusted to keep a cell.** A genuine miss is demoted, with reason.
- **Demotion wording is fixed:** *"this claim is not currently supported"* — never *"this interval is
  proven mislocated."* The gate emits **screening statistics**. Arc 7b's own per-cell p-values were
  0.017–0.039 and **none survived multiplicity correction**.
- **Reuse Arc 7b's machinery; do not rebuild it.** It is present on `origin/main` and wired into CI
  (`R-CMD-check.yaml:115`).
- **Truth is derived, never hand-typed** — hand-typing recreates the exact defect one layer up.
- **Do NOT add gate calls to the four `reconcile-arc1-*.py` scripts.** They are frozen provenance
  checks by design (`tools/arc1_profile_reconcile.py:1-26`); a claim gate there would conflate
  *"these bytes are authentic"* with *"these bytes support the claim."*
- **Receipts are never a shortcut.** No committed receipt carries `true_value`/`brackets_truth`;
  truth comes from the manifest, which the gate recomputes bracketing against.
- **Four cells are cross-arc stale.** `mc-0595`, `mc-0596`, `mc-0321`, `mc-0653` were re-evidenced by
  the landed-but-unmerged response-mask arc (`codex/response-missing-formula-surface`, `a075ff2d0`).
  Read their rows from **that branch**, not `origin/main`, before classifying. **Never demote a cell
  that arc just re-evidenced without reading its recorded reason.** A genuine conflict is Shinichi's
  call (D-87).
- Never push, merge, or publish — those are HUMAN GATES. Land work on this branch only.
- **No compute without a measured pre-run (D-139)** and an explicit Totoro-vs-DRAC decision. Never
  GitHub Actions (D-50).
- Verification means reading the LOG and inspecting the ARTEFACT, never the exit code.
- A narrow or negative search is not proof. "No X exists" usually means the query missed X.
- Destructive or irreversible ⇒ STOP and surface, even if it feels urgent.

## Lane

```
PLATFORM: claude | LANE: interval-claim truth audit | BRANCH: claude/lane-interval-truth-audit
OTHER LANES: 9 live — codex direct-to-main (FOREIGN) · codex/response-missing-formula-surface ·
             codex #955 · codex #858 · 4x claude (#1032, #959, phase19-comparator-workflows,
             external-oracle-intervals). I touch none of their files.
```

Complementary to — not duplicative of — Claude's D-117 boundary-interval calibration lane
(`docs/dev-log/coordination-board.md:19-20`): **D-117 asks whether the interval is calibrated; this
arc asks whether it contains the truth.**

## Out of scope (the fence — do NOT drift here)

- Promoting any cell UP the ladder.
- New interval methods; coverage campaigns.
- The bivariate and REML response-mask harnesses; Arc 6 (bivariate flagship); GVA (post-0.7, D-127).
- Redoing any part of the landed response-mask arc.

## Authoritative WHAT

`LOOP/ultra-plan.md` (detail wins there). This file wins on what must never be lost.

## R entry point

The installed drmTMB is **stale (0.6.0)** — never `library()` it.

```bash
NOT_CRAN=true R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'suppressMessages(pkgload::load_all(".", compile = FALSE, quiet = TRUE))'
```

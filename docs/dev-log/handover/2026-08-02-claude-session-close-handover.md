# Session Handoff: drmTMB session close — C18, F5, mc-0615 diagnosis all landed

Meta: 2026-08-02 · from Claude to a fresh Claude session · session-close handoff

You are Claude, picking up drmTMB after a long session that closed three lanes. Read `AGENTS.md`,
this handover, and `docs/dev-log/active-lane-split.md` before acting. You inherit no authority from
the authoring chat. Run lane preflight and classify every item below as `OWED`, `DONE`,
`RETRACTED`, or `PROTECTED` against current repository and GitHub state before continuing.

Named per lane, not per date — two lanes collided on `2026-08-02-claude-handover.md` earlier today.
That path belongs to the interval-feasibility lane.

## State at handover

Canonical `main` = **`095b9e3b1`**. Model-surface census **337 implemented / 350 rejected by design
/ 10 not implemented = 697**.

`main` moved four times during this session (#895, #869, #897, then #896, then #902/#903 — the last
a Codex spatial q2 lane). **Re-read it before trusting any SHA in this document.**

Remaining `not_implemented`: `mc-0198`, `mc-0324`, `mc-0325`, `mc-0426`, `mc-0455`, `mc-0462`,
`mc-0537`, `mc-0606`, `mc-0615`, `mc-0616`.

## What landed — DONE, do not redo

| PR | Lane | Outcome |
| --- | --- | --- |
| **#898** | C18 structured zero-one-beta atom effects | Ledger split 687→697 (promoting nothing), then **seven** q1 atom cells to `point_fit_recovery` |
| **#899** | F5 | Five sigma-structured oracles now apply the log-sigma soft clamp |
| **#901** | mc-0615 diagnosis | The structured relmat path **exonerated** |

Each merged only after CI passed on an unchanged head.

**C18 in one line:** the ten collapsed structured `zoi`/`coi` rows became exact q1 leaves plus
paired q2-plus boundaries (`mc-0705:0714`), then seven were promoted. The load-bearing repair was
the `model_type == 15` dispatch, which was `if (dpar == 1) log_sigma else eta_mu` — a "not sigma"
test, not a code-to-endpoint map. Verified before the change: injecting a hypothetical code 5 gave
`nll(code=5) == nll(code=0)` **bit-for-bit**. It is now exhaustive over `0=mu, 1=sigma, 5=zoi,
6=coi` and errors otherwise, with the same tightening applied to `model_type` 3, 8 and 12.

**F5 in one line:** the five oracles had been evaluating a function **62% different** from the
engine outside the ±12 clamp band, while agreeing to `1e-8` inside it.

## THE ONE OPEN DECISION — this is Shinichi's, not yours

An eighth atom cell, `mc-0615` (coi × relmat), is **not** promoted. Do not try to close it without
an explicit owner decision. Three routes were investigated and all three are closed:

1. **Reseeding** — seed-shopping. Refused.
2. **A larger DGP** — refuted by our own pre-registered campaign, which validated `n_each = 50` for
   the `coi` arm at 20/20 seeds with zero separated groups. `mc-0615` failed at a setting the
   evidence said should work, so enlarging it post-failure is contradicted by that evidence.
3. **A structured-relmat bug** — PR #901 exonerated the path: 0 structured-only collapses in 20
   seeds; structured bias 18% versus ordinary 38%.

What remains is the **decision rule**. The C16 all-must-pass gate blocks roughly **18.5%** of
genuinely capable `coi` cells by construction (per-seed collapse ~5%, so P(block) = 1 − 0.95ⁿ).
`mc-0615` is a draw from that distribution, not a capability limit.

**Critically — adding seeds makes this WORSE, not better.** Under an all-must-pass rule the block
probability rises with n: 18.5% at 4 seeds, 33.7% at 8, 46.0% at 12. That measurement refutes the
"raise coi to 8–12 seeds" remedy proposed during C18 plan review. **Fix the decision rule, not the
seed count.** Relaxing it (tolerate a bounded failure fraction, or treat a boundary collapse as a
reported diagnostic) would promote `mc-0615` honestly — but it changes the C16 contract
**retroactively for every `coi` cell already promoted under it**. That is why it is an owner call.

## Next lane — already prepared

**`claude/f3-beta-shape-floor`**, handover committed at
[`docs/dev-log/handover/2026-08-02-claude-f3-beta-shape-floor-handover.md`](2026-08-02-claude-f3-beta-shape-floor-handover.md).
Read that document, not this section, before starting it.

Summary: the beta shape floor at `src/drmTMB.cpp` ~2997 (`model_type 10`) and ~3178
(`model_type 15`) floors `alpha` and `beta` **independently**, so when either binds the reported
`mu`/`sigma` no longer parameterize the density evaluated — and `CondExpLt` makes the gradient
**exactly zero** there, a flat plateau the optimizer can rest on while reporting `convergence = 0`.

Two constraints that document states and this one repeats because they are easy to lose:

- **Write the design note first.** The floor exists for numerical safety; the defect is that it
  *substitutes* silently. Three designs are defensible (substitute / penalise / detect-and-report).
- **Do not bundle any cell promotion into that lane.** 37 promoted cells rest on the likelihood it
  would change — 8 beta, 29 zero-one-beta, including 4 at `inference_ready_with_caveats` and 10 at
  `interval_feasible`. Promoting in the same change makes attribution impossible.

**NOTE:** that handover states `main` as `e35b45042`; it is now `095b9e3b1`. The branch was cut
from `095b9e3b1` and is current, but re-verify.

## Environment

```text
/private/tmp/drmtmb-c18-claude.gngYwq   (branch claude/f3-beta-shape-floor @ 79e771e19, one commit ahead of main)
```

Run R as `R_PROFILE_USER=/dev/null Rscript --no-init-file ...`.

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test(filter = "^zero-one-beta$")'
python3 tools/capability_ledger.py --check
python3 -m unittest tools/tests/test_capability_ledger.py
```

Baselines: zero-one-beta **1502 / 0**; full suite **43153 / 0** (~25 min); ledger unittest
**51/51**; `R CMD check` ~24 min, **1 NOTE** — installed size **31.1 Mb**, `doc` **11.5 Mb**. That
note has grown from the 27.8 / 9.4 the ledger records, and `cran-comments.md` still blames compiled
TMB, which the measurement contradicts. Fix before any CRAN work.

**Do not stage:** the dirty main checkout, foreign worktrees, unrelated untracked files. Explicit
paths only; never `git add -A`.

## Landing state

| Artifact | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| C18 #898, F5 #899, diagnosis #901 | yes | yes | merged | **LANDED** |
| `claude/f3-beta-shape-floor` @ `79e771e19` | yes | yes | none | **CARRIED-OVER** — next lane, handover only, no implementation |
| `claude/c18-structured-atoms-plan`, `claude/f5-sigma-oracle-clamp`, `claude/mc-0615-diagnosis` | yes | yes | merged | LANDED; retained, do not delete |
| Main checkout `~/Dropbox/Github Local/drmTMB` on `claude/handover-freshness-0718`, ~83 files | no | no | none | **CARRIED-OVER — PROTECTED.** Prior sessions' work; this is why `handoff_gate.sh` FAILs. Do not stage, commit, clean or attribute. |
| PR #858 Lane B E0 | foreign | foreign | open draft | CARRIED-OVER — preserve |

## Remaining work, ranked

1. **F3 + F4** — branch and handover ready. The hardest known defect left.
2. **`mc-0615`** — blocked on the owner decision above. Do not reseed.
3. **Spatial `mc-0606`/`mc-0616`** — deferred *and* refused in code; resume when the mesh/SPDE lane
   (PR #893) settles.
4. **Seven unrelated `not_implemented` cells** — a separate programme; each needs its own scoping,
   and it should wait until F3 settles rather than promoting under a likelihood about to change.
5. **CRAN installed-size note** — independent, do anytime.
6. **F6** — recorded but LOW VALUE (~2e-12 relative). Bundle it with other work in
   `test-zero-one-beta.R`; not worth its own CI cycle.

## Gotchas that cost time this session

- Filter ledger counts to `axis == "model_surface"`. Counting all axes gave 79 where the validator
  wanted 78 — the gotcha was already documented and was walked into anyway.
- The C17 gate has **two** failure modes: a fingerprint over model-15 source text, and a per-file
  git-blob provenance check. Read the actual error before naming which fired.
- Editing `R/drmTMB.R`, `src/drmTMB.cpp` or `tests/testthat/test-zero-one-beta.R` breaks that gate.
  Re-authenticate by **re-running** `tools/run-lane-c-c17c1-c14-model15-compatibility.R`, never by
  editing a hash.
- `test-estimator-surface-conformance.R` enforces detail strings **only** on `expected == "error"`
  rows, so other anchors drift silently. Audit all 37 rows, not just any that fail.
- That test does not evaluate under `R CMD check`. Run `devtools::test` **and** `check`.
- **A regression test that passes before its own repair is worthless.** Two shipped that way
  previously; F5 nearly made it three. Falsify first.
- A design doc can silently outrank a spoken owner decision — `docs/design/248` listed spatial
  in-scope while it was deferred, so it became fittable with zero evidence.

## How to resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-02-claude-session-close-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

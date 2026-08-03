# Session Handoff: F3 (+ F4) — the beta shape floor substitutes a model instead of penalising

Meta: 2026-08-02 · from Claude to a fresh Claude session · design-first handoff

You are Claude, starting the hardest remaining slice in this codebase that we know about. Read
`AGENTS.md`, this handover, and `docs/dev-log/active-lane-split.md` before acting. You inherit no
authority from the authoring chat. Classify every item below as `OWED`, `DONE`, `RETRACTED`, or
`PROTECTED` against current repository and GitHub state.

Named per lane, not per date — two lanes collided on `2026-08-02-claude-handover.md` earlier today.

## Critical context

Three lanes merged 2026-08-02. Canonical `main` is `e35b45042`; census
**337 implemented / 350 rejected by design / 10 not implemented = 697**.
C18 (#898), F5 (#899) and the mc-0615 diagnosis (#901) are all done. Do not redo them.

This lane addresses **findings F3 and F4** of
[`docs/design/248`](../../design/248-zero-one-beta-structured-atom-q1-symbolic-alignment.md).

## F3 — what is actually wrong

`src/drmTMB.cpp`, two sites: **line 2997** inside `model_type == 10` (beta) and **line 3178**
inside `model_type == 15` (zero_one_beta). Both do:

```cpp
Type beta_shape_floor = Type(1e-8);
alpha(i)      = CppAD::CondExpLt(alpha_raw, beta_shape_floor, beta_shape_floor, alpha_raw);
beta_shape(i) = CppAD::CondExpLt(beta_raw,  beta_shape_floor, beta_shape_floor, beta_raw);
```

Two consequences, both verified during C18:

1. **The floors are applied INDEPENDENTLY.** When either binds,
   `alpha + beta != phi` and `alpha/(alpha+beta) != mu`. So the `REPORT`ed `mu` and `sigma`
   (`src/drmTMB.cpp:3165`, `:3167`) **no longer parameterize the density that was evaluated**. The
   density is still proper, so nothing looks wrong.
2. **`CondExpLt` returns a constant in the floored region**, so `d(log f)/d(beta_mu) == 0`
   *exactly* there. That is a **flat plateau, not a barrier**: the optimizer can come to rest on it
   and report `convergence = 0` with `pdHess = TRUE`.

## Why this needs a design note before any edit

**Do not just change the floor.** It exists for numerical safety. There are at least three
defensible designs and they are not equivalent:

- **substitute** (current) — silently evaluates a different `(mu, phi)` than it reports;
- **penalise** — keep differentiability, push back smoothly, report nothing wrong;
- **detect and report** — leave the numerics, but surface `floor_active` the way
  `clamp_active` already is, so a fit that rested on the plateau is visible.

Write the symbolic alignment FIRST and pick deliberately, exactly as C18 did with
`docs/design/248`. Deriving the oracle from the C++ instead of from the note is how a shared error
survives a `1e-8` agreement check — that failure mode is documented in 248 §5.

## The blast radius — read this before scoping

F3 changes the **likelihood** for two families that already carry promoted evidence:

| model_type | family | implemented cells | tiers |
| --- | --- | ---: | --- |
| 10 | `beta` | 8 | 5 `interval_feasible`, 3 `inference_ready_with_caveats` |
| 15 | `zero_one_beta` | 29 | 23 `point_fit_recovery`, 5 `interval_feasible`, 1 `inference_ready_with_caveats` |

**37 promoted cells** were validated against the current floor behaviour, including **4 at
`inference_ready_with_caveats`** — the highest tier in the ladder — and **10 at
`interval_feasible`**. If the chosen design changes any fitted value, their evidence was earned
against a different function and must be re-checked. Budget for that; do not discover it late.

**Therefore: do NOT bundle this lane with any new cell promotion.** Promoting cells in the same
change that alters the likelihood makes it impossible to attribute which change moved which number,
and forces the C16 receipts to re-authenticate against a moving target. The seven unrelated
`not_implemented` cells (`mc-0198`, `mc-0324`, `mc-0325`, `mc-0426`, `mc-0455`, `mc-0462`,
`mc-0537`) are a separate programme and should wait until this settles.

## F4 — bundled because it is nearly free

`src/drmTMB.cpp:3119-3120` computes the reported `zoi`/`coi` as `1/(1+exp(-eta))` directly, so
`eta < -709` overflows and reports exactly `0` (and `1` above `+709`). The likelihood itself is
safe — it uses `logspace_add` at `:3126-3129` — and `mu` already gets the stable treatment via
`drm_log_inv_logit` (`src/drm_numeric.h:38-41`). The atoms simply never did. Reporting-only, but a
reported `zoi = 0` is exactly what a diagnostic reads as a degenerate fit.

Include it because you are already in the file and it shares one CI cycle and one compatibility
re-authentication. Keep it a separate commit.

## Goal / mission

```text
🎯 GOAL
PLATFORM: Claude (solo; run the live R/TMB toolchain yourself).
DELIVERABLE: A design note deciding how the beta shape floor should behave (substitute vs penalise
vs detect-and-report), then the chosen implementation at BOTH sites (model_type 10 line ~2997 and
model_type 15 line ~3178), a test that exercises the floored region and would fail today, and F4's
stable reported zoi/coi. NO cell promotion in this lane.
HEADLINE: Write the design note FIRST and derive the oracle FROM it, never from the C++. The floor
exists for a reason -- the defect is that it SUBSTITUTES a different model silently and hands the
optimizer a region of exactly zero gradient, not that it exists.
DEFER: all seven unrelated not_implemented cells; mc-0615; spatial; F6 (~2e-12 relative, bundle it
here only if trivially free); the CRAN installed-size note.
DISCIPLINE: 37 promoted cells across model_type 10 and 15 rest on the current floor behaviour, 4 of
them at inference_ready_with_caveats. If any fitted value moves, re-check their evidence before
claiming the lane is done. src/drmTMB.cpp is a pinned C17_C14_SOURCE_FILE, so editing it breaks the
per-file git-blob provenance check (a DIFFERENT gate from the fingerprint-over-source-text one) --
re-authenticate by RE-RUNNING tools/run-lane-c-c17c1-c14-model15-compatibility.R, never by editing a
hash. Run devtools::test AND devtools::check AND the ledger unittest on the exact commit gated.
Never `git add -A`. Merge only after unchanged-head CI.
```

## Environment

```text
/private/tmp/drmtmb-c18-claude.gngYwq   (branch claude/f3-beta-shape-floor, at 095b9e3b1 = origin/main)
```

Run R as `R_PROFILE_USER=/dev/null Rscript --no-init-file ...`.

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test(filter = "^zero-one-beta$")'
python3 tools/capability_ledger.py --check
python3 -m unittest tools/tests/test_capability_ledger.py
```

Baselines on `main`: zero-one-beta **1502 / 0**; full suite **43153 / 0** (~25 min); ledger
unittest **51/51**; `R CMD check` ~24 min, **1 NOTE** (installed size 31.1 Mb, `doc` 11.5 Mb).

**Do not stage:** the dirty main checkout, foreign worktrees, unrelated untracked files.

## Landing state

| Artifact | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| C18 #898, F5 #899, diagnosis #901 | yes | yes | merged | **LANDED** |
| `claude/f3-beta-shape-floor` | branch only | not yet | none | **CARRIED-OVER** — this lane, no work done |
| `claude/f5-sigma-oracle-clamp`, `claude/c18-structured-atoms-plan`, `claude/mc-0615-diagnosis` | yes | yes | merged | LANDED; retained, do not delete |
| Main checkout `~/Dropbox/Github Local/drmTMB` on `claude/handover-freshness-0718`, ~83 files | no | no | none | **CARRIED-OVER — PROTECTED.** Prior sessions' work. This is why `handoff_gate.sh` FAILs. Do not stage, commit, clean or attribute. |
| PR #893 mesh/SPDE, #858 Lane B, #891 | foreign | foreign | open | CARRIED-OVER — preserve |

## Next immediate steps

1. Lane preflight; reconcile this handover against current `origin/main`, open PRs, worktrees.
2. Re-derive the two floor sites (line numbers drift — grep `beta_shape_floor`).
3. **Write the design note**, deciding among substitute / penalise / detect-and-report, with the
   consequences for the 37 promoted cells stated explicitly.
4. **Build the falsifying test before the fix.** Drive a fit into the floored region and show the
   reported `mu`/`sigma` do not parameterize the evaluated density, and/or that the gradient is
   exactly zero there. Confirm it FAILS on unmodified `main`. A regression test that passes
   pre-repair is worthless — that cost this codebase real time twice.
5. Implement at both sites. Apply F4 as its own commit.
6. Re-authenticate the C17 receipts by re-running the campaign.
7. If any fitted value moved, re-check the 37 cells' evidence before claiming completion.
8. Full suite + `R CMD check` on the gated commit; PR; merge only after unchanged-head CI.

## Gotchas

- Filter ledger counts to `axis == "model_surface"`.
- The C17 gate has **two** failure modes: the fingerprint over model-15 source text, and a per-file
  git-blob provenance check. Read the actual error before describing which one fired.
- `test-estimator-surface-conformance.R` cites line anchors into `R/drmTMB.R` and `R/profile.R` and
  enforces detail strings **only** on `expected == "error"` rows, so other anchors drift silently.
  Editing `src/drmTMB.cpp` alone should not disturb it, but check.
- That test resolves source from a checkout, so it does **not** evaluate under `R CMD check`. Run
  both gates.
- Do not set `NOT_CRAN=true` for a claim-bearing check. Do not run campaigns on GitHub Actions.

## How to resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-02-claude-f3-beta-shape-floor-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

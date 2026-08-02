# Session Handoff: F5 — sigma-structured oracles omit the log-sigma soft clamp

Meta: 2026-08-02 · from Claude to a fresh Claude session · implementation handoff

You are Claude, starting a new, narrow drmTMB lane. Read `AGENTS.md`, this handover, and
`docs/dev-log/active-lane-split.md` before acting. You inherit no authority from the authoring
chat. Classify every item below as `OWED`, `DONE`, `RETRACTED`, or `PROTECTED` against current
repository and GitHub state before continuing.

**Named per lane, not per date.** On 2026-08-02 two lanes independently wrote
`2026-08-02-claude-handover.md` and collided in a merge. That path belongs to the
interval-feasibility lane. Do not reuse it.

## Critical context

C18 is **merged**. Canonical `main` is `aaf4d521b` (PR #898). The model-surface census is
**337 implemented / 350 rejected by design / 10 not implemented = 697**. Do not redo C18.

This lane implements **finding F5** from
[`docs/design/248-zero-one-beta-structured-atom-q1-symbolic-alignment.md`](../../design/248-zero-one-beta-structured-atom-q1-symbolic-alignment.md).
That document was independently verified during C18 and F5 was confirmed as real by a second
reviewer.

## The defect

`drm_control()` defaults `logsigma_clamp = c(-12, 12)` ([R/control.R:134](../../../R/control.R))
and `R/drmTMB.R:493-503` sets `use_logsigma_clamp <- 1L` for any non-`NULL` band, so **the clamp
is ON by default**. The engine applies it at `src/drmTMB.cpp:3114-3117`, *after* the structured
contribution is added.

Five dense-R oracles in `tests/testthat/test-zero-one-beta.R` never call
`softclamp_logsigma_drm`. Verified on `aaf4d521b`:

| oracle | lines | clamp | eps compression |
| --- | --- | --- | --- |
| `zoib_sigma_phylo_nll` | 309–320 | **MISSING** | present |
| `zoib_sigma_animal_nll` | 355–363 | **MISSING** | present |
| `zoib_sigma_relmat_nll` | 364–372 | **MISSING** | present |
| `zoib_sigma_spatial_nll` | 436–445 | **MISSING** | present |
| `zoib_sigma_phylo_interaction_nll` | 461–471 | **MISSING** | present |

They agree with the engine today **only because their test values sit inside the ±12 band**.
Outside it they evaluate a different function than the engine computes, while still reporting
agreement to `1e-8`.

The correct pattern already exists in the same file — the atom oracles apply it conditionally on
`use_logsigma_clamp == 1` (`softclamp_logsigma_drm` calls at lines 329, 346, 502, 523). Copy that,
do not invent a new form. The helper itself is at `test-zero-one-beta.R:50`.

## Read this before you start — the edit alone proves nothing

`S(x) = x` inside the band. So adding the clamp to these five oracles is a **no-op for every
existing test**, and a green suite afterwards is not evidence that anything was fixed.

**The entire value of this lane is a new test that drives `log_sigma` OUTSIDE ±12 and shows the
oracle and the engine still agreeing there.** Without it, F5 is bookkeeping. Build that test
first, confirm it FAILS against the unpatched oracles, then patch them. A regression test that
passes before the repair is worthless — this exact trap cost the C18 lane real time (three
attempts, two of which passed pre-repair).

## Goal / mission

```text
🎯 GOAL
PLATFORM: Claude (solo; run the live R/TMB toolchain yourself).
DELIVERABLE: The five sigma-structured oracles in tests/testthat/test-zero-one-beta.R apply the
log-sigma soft clamp conditionally on use_logsigma_clamp, matching the engine and the atom-oracle
precedent, PLUS a new test that exercises the OUT-OF-BAND region and would fail without the fix.
HEADLINE: Build the falsifying out-of-band test FIRST and confirm it fails against the unpatched
oracles. The five edits are no-ops inside the band, so a green suite proves nothing on its own.
DEFER: findings F3, F4, F7 and F8 of doc 248; the seven unrelated not_implemented cells; mc-0615;
spatial mc-0606/mc-0616; anything touching the ledger census.
DISCIPLINE: tests/testthat/test-zero-one-beta.R is one of five pinned C17_C14_SOURCE_FILES
(tools/capability_ledger.py:70-76), so editing it invalidates the model-15 fingerprint and BREAKS
the CI ledger unittest. Re-authenticate by RE-RUNNING tools/run-lane-c-c17c1-c14-model15-compatibility.R
and regenerating both c17c1-/c17c2- TSVs -- never by editing a hash. Run devtools::test AND the
ledger unittest on the exact commit gated. Never `git add -A`. Merge only after unchanged-head CI.
```

## Environment

Fresh worktree already cut and ready:

```text
/private/tmp/drmtmb-c18-claude.gngYwq   (branch claude/f5-sigma-oracle-clamp, at aaf4d521b)
```

Run R as `R_PROFILE_USER=/dev/null Rscript --no-init-file ...`.

Safe verification:

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test(filter = "^zero-one-beta$")'
python3 tools/capability_ledger.py --check
python3 -m unittest tools/tests/test_capability_ledger.py
```

Baseline on `aaf4d521b`: zero-one-beta **1496 pass / 0 fail**; ledger check OK; ledger unittest
**51/51**. Full suite is 43147 / 0 and takes ~25 min; `R CMD check` ~24 min and reports **1 NOTE**
(installed size 31.1 Mb, `doc` 11.5 Mb) — pre-existing, and growing.

**Do not stage:** the dirty main checkout, any foreign worktree, or unrelated untracked files. Use
explicit paths.

## Landing state

| Artifact | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| C18, PR #898, merge `aaf4d521b` | yes | yes | merged | **LANDED** |
| `claude/c18-structured-atoms-plan` | yes | yes | #898 merged | LANDED; branch retained, do not delete |
| `claude/f5-sigma-oracle-clamp` | n/a | not yet | none | **CARRIED-OVER** — this lane, no work done yet |
| Main checkout `~/Dropbox/Github Local/drmTMB` on `claude/handover-freshness-0718`, 83 modified/untracked files | no | no | none | **CARRIED-OVER — PROTECTED.** Written by PRIOR sessions, not this one. This is why `handoff_gate.sh` reports FAIL. Do not stage, commit, clean or attribute it. |
| PR #893 mesh/SPDE | foreign | foreign | open draft | CARRIED-OVER — mesh owner |
| PR #858 Lane B E0, PR #891 | foreign | foreign | open | CARRIED-OVER — preserve |

## Next immediate steps

1. Run lane preflight and reconcile this handover against current `origin/main`, open PRs and
   worktrees. Classify every item above.
2. Re-verify the five oracles still lack the clamp at the cited lines (line numbers drift — re-grep
   `softclamp_logsigma_drm` and re-derive the function spans).
3. **Write the out-of-band test first.** Drive `log_sigma` beyond ±12 — either via a DGP with an
   extreme residual scale or by evaluating `obj$fn` at a hand-set parameter vector (the Arc B house
   style: drive the compiled kernel directly rather than fitting and hoping the optimizer reaches
   the region). Confirm it **FAILS** against the current oracles.
4. Patch the five oracles, conditionally on `use_logsigma_clamp == 1`, following lines 329/346.
5. Re-run the out-of-band test; it must now pass. Re-run the whole zero-one-beta file.
6. **Re-authenticate the C17 receipts** — see Discipline above. This is not optional and not a hash
   edit; `mc-0568`, `mc-0569` and `mc-0576` must pass 4/4 against the new source.
7. Run the full suite and `R CMD check` on the exact commit you gate, then open a PR and merge only
   after unchanged-head CI.

## Gotchas

- Filter ledger counts to `axis == "model_surface"`. Counting all axes gives a different frozen-census
  number; this is listed as a gotcha and was still walked into during C18.
- `test-estimator-surface-conformance.R` cites line anchors into `R/profile.R` and `R/drmTMB.R`. It
  enforces detail strings **only** for `expected == "error"` rows, so other anchors drift silently.
  If you touch those files, audit all 37 rows, not just any that fail.
- That same conformance test resolves source from a checkout, so it does **not** evaluate under
  `R CMD check`. Run `devtools::test` and `check` — each hides failures the other catches.
- Do not set `NOT_CRAN=true` for a claim-bearing check.
- Do not run campaigns on GitHub Actions.

## Open question for Shinichi

Doc 248 records F5 as a *test-layer* defect. Worth deciding whether the five sigma oracles should
also gain the `beta_mu_eps` audit that finding F6 raised for a sixth oracle
(`zoib_sigma_random_intercept_nll` at line 448 uses bare `plogis(eta_mu)`), or whether F6 is a
separate slice. They are adjacent and touch the same file, so doing both at once would halve the
fingerprint re-authentication cost.

## How to resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-02-claude-f5-sigma-oracle-clamp-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

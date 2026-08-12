# Handover → Codex — missing-response G5 and the interval-availability arc (2026-08-11)

You are Codex, taking the drmTMB lane. You inherit no chat context; this document, the three open PRs,
and the repository are authoritative. `main` moves fast here — it advanced four times during the
session that produced this.

## Mission, in one line

Two arcs closed: the missing-response G4/G5 campaign was completed and promoted, and the G5 calibration
gate was replaced. **Three PRs are open and none is merged.** Everything below is either landed on a
branch or filed as an issue; nothing important lives only in this document.

## The three PRs — MERGE ORDER IS NOT FREE

| PR | branch | contents |
|---|---|---|
| [#1004](https://github.com/itchyshin/drmTMB/pull/1004) | `claude/interval-availability` | `mr-g5-calibration-v2` + tests, four diagnoses, re-score, after-task, reconciliation, closeout audit |
| [#1005](https://github.com/itchyshin/drmTMB/pull/1005) | `claude/g5-panel-and-promotion` | 8 routes G3→G5, three panel reports + addenda, campaign closure |
| [#1016](https://github.com/itchyshin/drmTMB/pull/1016) | `claude/1009-profile-below-fit-detector` | the #1009 detector |

**#1004 must land before or with #1005.** #1005's ledger text names `mr-g5-calibration-v2`, a policy
defined only in #1004. Merged alone it leaves the ledger asserting a gate a reader cannot find in the
codebase. **No tooling detects this** — it is a cross-branch semantic dependency.

#1016 is independent (touches `R/profile.R` only).

All three were based on `a2c4941db`–`4e4a915aa`; `main` has moved. **Merge `main` into each before
merging.** No `R CMD check --as-cran` has been run on any of them — that is your first job and the
reason this lane is yours.

## Where G5 actually stands

Campaign is **294/294 complete**. Under the shipped v2 gate, **277 of 294 cells pass**.

**11 routes at G5:** gaussian, biv_gaussian, gamma, beta_binomial, binomial, zero_one_beta,
zi_poisson, lognormal (first panel, 3/3) — plus **beta, tweedie, skew_normal** (second panel, 3/3).

**The second panel's grounds matter and must not be misquoted.** It explicitly **declined to promote
on `mr-g5-calibration-v2`**, because that availability floor was authored post hoc in the same session.
Both the build and ceiling lenses independently derived a **threshold-free worst-case bound** instead:
because the fate of the `k` unusable draws is unobserved, unconditional coverage lies in
`[c/1200, (c+k)/1200]`; under the worst case — every unusable draw assigned non-covering — **all 45
cells remain inside [0.925, 0.975]**. The promoted rows state that bound, not an availability
threshold, so the claim holds under the most adversarial assignment and never appeals to the floor.

Tightest cell in the whole set, named explicitly in its own boundary: **skew_normal
`fixef:nu:(Intercept)` 0.5x, worst case 0.9258 — 0.0008 above the band floor.** Treat that one as the
first thing to re-check if anything about the DGP or the resume is ever revised.

**1 route held on the container, not the evidence:** `cumulative_logit`. Its 3 measured cells pass
cleanly and its estimand was verified against `MASS::polr` (slopes agree to 1.35e-06). The blocker is
that the per-route row asserts `dpar = "all fitted dpars"` while both `ordinal:theta_ord:*` targets
carry zero evidence. **This needs a per-target ledger key, not more science.** See #967's comment.

**6 routes with real remaining failures**, concentrated: student 6, truncated_nbinom2 5, nbinom2 3, and
one cell each in poisson, zi_nbinom2, hurdle_nbinom2. **Only 3 of the 17 are coverage failures**
(poisson's 0.9217 and two in student); the rest are availability, and three of the four worst cells are
diagnosed as **genuine identifiability limits, not defects** — no engine fix would flip them.

## Filed and unimplemented

[#1007](https://github.com/itchyshin/drmTMB/issues/1007) vacuous completeness check ·
[#1008](https://github.com/itchyshin/drmTMB/issues/1008) unguarded runtime `interval_method` ·
[#1009](https://github.com/itchyshin/drmTMB/issues/1009) **fix open as #1016** ·
[#1010](https://github.com/itchyshin/drmTMB/issues/1010) `TMB::tmbprofile()` bracket overflow, possibly
upstream · [#1011](https://github.com/itchyshin/drmTMB/issues/1011) ledger prose rot ·
[#967](https://github.com/itchyshin/drmTMB/issues/967) has a decision memo recommending a three-way
split.

## The finding worth carrying, above any individual fix

Seven defects this session share one shape: **a guard that certifies what was declared rather than what
happened.** The centring switch (#982, fixed), the vacuous completeness check, runtime-derived
`interval_method`, a below-fit detector at **0.7% sensitivity**, and ledger prose that rotted in five
separate places. Every one passed every test. Every one was found by reading output or recomputing a
number, never by the gate.

If you do one architectural thing here, make campaign artifacts **carry what they assert** — the
expected cell count, the fitted objective, the interval method — so they can be falsified from the
inside.

## Gotchas that cost real time

- **The primary checkout is dirty and ~900 commits behind.** Never stage from it. Use a worktree off
  `origin/main`.
- **R locally:** `R_PROFILE_USER=/dev/null Rscript --no-init-file` — the `.Rprofile` R-4.5 lib segfaults
  R 4.6.
- **RDS hashes are not portable across R versions.** Use `design_state` for provenance.
- **rorqual:** `~/g5run/`, R 4.5.0, `module load StdEnv/2023 r-bundle-bioconductor/3.21`,
  `export R_LIBS_USER=$HOME/R/g4g5-lib`. ControlMaster sockets live; no Duo needed. **Write R scripts to
  a file — inline `-e` breaks on `$` quoting.**
- **The campaign records store no fitted objective**, which is why #1009's calibration used the first
  trace value as a proxy. Persisting it would let the runtime predicate be scored directly.
- `claude/mi-response-leaves` is unblocked by #979's closure but is ~123 commits behind.
- `claude/979-c17-narrow-pin` holds ~244 uncommitted insertions in a scratch worktree, **deliberately
  not committed** — #979 was closed by PR #998 with a better answer, and committing a rejected approach
  would put it in the history looking viable.

## What the session got wrong, so you weight it correctly

Four orchestrator claims were wrong and each was caught by a reviewer, not by the author: `n_attempt`
described as asserted when it is measured; "profile intervals only" called false when the data said 0
of 348,000 used Wald; a non-convergence mechanism adopted then refuted by reprofiling; and a
sensitivity table that scored a predicate the gate never used. A fifth — the 0.99 floor justified
circularly — was caught by a closeout audit that the plan had scheduled and the orchestrator skipped.

The pattern: **the analytical work that went unreviewed is where the errors were.** Treat the
threshold evidence and the after-task with the same suspicion you would treat any single-author claim.

## ⚠ MULTI-LANE — this is NOT a project census

Do **not** treat this document as the project's state. Read
[`docs/dev-log/coordination-board.md`](../coordination-board.md) for the live lane split. As of
2026-08-11 the board shows:

- **A different Claude lane owns the 0.7 CRAN ladder** (reassigned in-session 2026-08-11), with its
  own handover: `handover/2026-08-11-070-gate-truth-handover.md`. `main` now carries
  `Version: 0.7.0` via #996. **`platform-clean` is NOT authorised and is mechanically blocked** —
  the gate rejects it while `platform_matrix` and `external_logs` are absent and win-builder has not
  run against the candidate.
- **Codex holds #858 (Lane B E0) and #955 — PROTECTED FOREIGN.** Do not push, clean, or reconcile.
- **Cursor** has unmerged carried-over branches (`cursor/handover-0807`, `cursor/07-tarball-clean`,
  `cursor/07-cran-readiness`).
- **[#1012](https://github.com/itchyshin/drmTMB/pull/1012) (mspl Jeffreys weight)** is another lane's
  open PR. This session did not touch it.

The `AGENTS.md` snapshot pointer was deliberately **not** repointed at this document, because a single
pointer cannot represent four lanes and repointing would orphan the others.

## Files created / modified

`claude/interval-availability` (PR #1004) — `git diff --name-only origin/main...`:
```
inst/sim/R/sim_missing_response_g4g5.R
tests/testthat/test-missing-response-g4g5-foundation.R
docs/dev-log/interval-availability/2026-08-11-availability-threshold-evidence.md
docs/dev-log/interval-availability/2026-08-11-diagnosis-concentrated-failures.md
docs/dev-log/interval-availability/2026-08-11-point-estimate-outside-interval.md
docs/dev-log/interval-availability/2026-08-11-967-ordinal-cutpoint-decision-memo.md
docs/dev-log/interval-availability/2026-08-11-rescore-old-vs-new.{md,csv}
docs/dev-log/after-task/2026-08-11-g5-promotion-and-interval-availability.md
docs/dev-log/plan-actual/2026-08-11-interval-availability-and-g5-promotion.md
docs/dev-log/release-audits/2026-08-11-rose-closeout-audit.md
docs/dev-log/handover/2026-08-11-codex-handover.md   (this file)
```

`claude/g5-panel-and-promotion` (PR #1005) — ledger TSVs (`cells`/`evidence`/`transitions`),
`schema.json`, `tools/capability_ledger.py`, `tools/tests/test_capability_ledger.py`,
`vignettes/includes/capability-ledger-*.md`, generated dashboard surfaces, three D-43 panel reports
under `docs/dev-log/release-audits/`, and `docs/dev-log/2026-08-11-g5-admission-set-exhaustiveness.md`.

`claude/1009-profile-below-fit-detector` (PR #1016) — `R/profile.R`,
`tests/testthat/test-profile-targets.R`.

## Rehydration — Codex

`AGENTS.md` is native; read it, then this document, then the after-task report and Rose's closeout
audit. Team mirror is `.codex/agents/*.toml`; **Rose's audit is mandatory before any public claim** —
this session's own analytical work failed that audit and had to be corrected.

**You run the live toolchain. That is why this lane is yours.** None of the three PRs has had
`R CMD check --as-cran`.

```bash
cd <fresh worktree off origin/main>          # NEVER the primary checkout: dirty, ~900 commits behind
export NOT_CRAN=true
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test()'
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'rcmdcheck::rcmdcheck(args = "--as-cran")'
python3 tools/capability_ledger.py --write && python3 tools/capability_ledger.py --check
python3 -m unittest tools/tests/test_capability_ledger.py
```

`R_PROFILE_USER=/dev/null` is not optional — the `.Rprofile` R-4.5 library segfaults R 4.6.

rorqual (campaign artifacts, ControlMaster live, no Duo):
```bash
SOCK=$(ls ~/.ssh/cm-*rorqual* | head -1)
ssh -o ControlPath="$SOCK" -o ControlMaster=no -o BatchMode=yes rorqual \
  'module load StdEnv/2023 r-bundle-bioconductor/3.21; export R_LIBS_USER=$HOME/R/g4g5-lib; Rscript <script>'
```
Write R scripts to a file — inline `-e` breaks on `$` quoting.

## Mission control

| Repo | Branch / main | CI | What shipped | Plan by leverage |
|---|---|---|---|---|
| drmTMB | `main` @ 0.7.0; 3 PRs open | **no `--as-cran` run on any PR** | 11 of 18 missing_response routes at G5 · `mr-g5-calibration-v2` + tests · campaign 294/294 · 5 issues filed | (1) `--as-cran` then merge #1004 → #1005 → #1016 · (2) #1007 + #1008 · (3) `cumulative_logit` per-target key · (4) leave student/truncated_nbinom2 |

## How to resume — one command

```
Read AGENTS.md, docs/dev-log/coordination-board.md, and docs/dev-log/handover/2026-08-11-codex-handover.md. Run --as-cran on PRs #1004, #1005 and #1016 in a fresh worktree off origin/main, merge them in that order (#1004 before #1005 — hard dependency), then continue the Next Steps in the handover.
```

## Suggested order

1. Merge `main` into all three branches; run `--as-cran`; land #1004, then #1005, then #1016.
2. Run the panel for beta/tweedie/skew_normal if it did not conclude → 11 of 18 at G5.
3. #1007 and #1008 — both small, both close the "certify what happened" gap.
4. `cumulative_logit`'s per-target key — unblocks a promotion the evidence already earns.
5. Leave student and truncated_nbinom2 alone unless you want a research arc; their failures are real.

# Session Handoff — MSPL finiteness evidence closed, 0.7.0 at `tarball-clean`, probit/cloglog scoped

Meta: 2026-08-10 → 2026-08-11 · Claude → Claude · **cite by branch + SHA, never by path**

## The one-paragraph version

Seven PRs merged. drmTMB now has **its own** TMB-Laplace finiteness evidence for MSPL logit —
31,000 fits across three campaigns, replacing a reliance on the authors' glmer numerics. Emmy's last
Arc D condition is discharged, the C17 guard's two failure modes are now distinguishable and its
re-certification is one command, and issue #979 is closed. 0.7.0 sits at **`tarball-clean`** with a
verified-fresh artifact, blocked on **win-builder**, which is the owner's to run. One claim of mine
was **retracted on inspection of the source** — see §5, it changes the next arc.

## 0. Landing State — `handoff_gate.sh` FAILS; here is why, and what is mine

The gate fails. **None of it is my lane.** Declared per option (b):

| artifact | landed | state |
|---|---|---|
| `claude/handover-2026-08-11` (this doc, **#1001**) | pushed | **CARRIED-OVER** — PR open, not merged. Resume: `cd /Users/z3437171/local-scratch/worktrees/drmTMB-links` |
| `claude/0.7.0-freshness-record` (**#999**) | pushed | **CARRIED-OVER** — PR open, CI running at handoff |
| #988 · #991 · #993 · #995 · #997 · #998 | **merged to `main`** | branches deleted, each verified `0` commits outside `main` |
| `scratchpad/*.md` in this worktree | **NO** | **CARRIED-OVER** — working notes, conventionally untracked here. Never stage them. |
| ~18 `codex/*`, `hopper/*`, `shannon-install` and sibling `claude/*` branches with unpushed commits | — | **PROTECTED — foreign lanes. Do not touch, push, or clean.** |

My two branches have **0 unpushed commits**. The gate's entire failure surface is other lanes'.

## 0.1 Multi-lane — and why the AGENTS.md pointer was deliberately NOT refreshed

`lane_preflight.sh` at handoff: **FOREIGN LANE ACTIVE (codex)** plus **7 live `claude` lanes besides
this one**.

The protocol's snapshot step says a **single** pointer cannot represent 8 lanes, and refreshing
`AGENTS.md`'s `▶ Latest` block to *this* doc would orphan the siblings. Preflight additionally
reports **another ref already has work on `docs/dev-log/coordination-board.md`**, so appending there
would be bleed-through into a lane mid-edit.

**So neither file was touched.** This document stands alone. The live lane split is
[`docs/dev-log/coordination-board.md`](../coordination-board.md) → `active-lane-split.md`, which is
committed to `origin/main` and therefore reaches every lane. Read it before claiming any subject.

`PLATFORM: claude | ON BRANCH: claude/handover-2026-08-11 | LANE: MSPL finiteness evidence + C17
guard tooling | OTHER LANES: codex (#955, #858) + 7x claude`

**From the board, dated today:** the live **0.7 CRAN ladder is now owned by Claude** (Shinichi, in
session), superseding the 2026-08-07 Codex line. Ownership only — it does **not** authorise a rung
advance, a submission, or the merge of any open PR.

## 0.2 Files created or modified this session

Merged to `main`:

- `src/drm_response_kernels.h`, `src/drmTMB.cpp` — `link_code` default removed, 21 call sites (#988)
- `tools/capability_ledger.py`, `tools/tests/test_capability_ledger.py` — C17 failure-mode messages + the decoupling fix (#991, #993)
- `tools/recertify-c17.py` — **new**, closes #979 (#998)
- `docs/dev-log/simulation-artifacts/2026-08-10-mspl-laplace-finiteness/` — F1 prereg, runner, scorer, raw 20,000 rows, verdict (#995)
- `docs/dev-log/simulation-artifacts/2026-08-11-mspl-rare-prevalence/` — F2 + F2b prereg, two runners, scorer, raw 8,000 + 3,000 rows, verdict (#997)
- `docs/dev-log/simulation-artifacts/README.md` — **new**, the keep-raw-data convention (#997)
- `docs/dev-log/after-task/2026-08-10-emmy-condition-1-link-code.md`, `docs/dev-log/check-log.md`, `AGENTS.md` banner (#988)
- `docs/dev-log/dashboard/capability-ledger/2026-08-08-c17c2-c14-final-source-compatibility.tsv` + 4 receipt dirs under `docs/dev-log/implementation-recovery/` — six C17 re-certifications

Open, not merged:

- `docs/dev-log/release/0.7.0-cran-gate/FRESHNESS-2026-08-11.md` — **new** (#999)
- `docs/dev-log/handover/2026-08-11-claude-handover.md` — **new**, this file (#1001)

On Totoro (not in the repo): `~/R/f1lib`, `~/f1_runner.R`, `~/f1_launch.sh`, `~/f2_runner.R`,
`~/f2b_runner.R`, `~/f1_out/`, `~/f2_out/`, `~/f2b_out/`.

## 1. Landed

| PR | what |
|---|---|
| #988 | Emmy condition 1 — `link_code` default removed, 21/21 call sites explicit |
| #991 | C17's two failure modes made distinguishable in the error text |
| #993 | fixed a test #991 shipped that failed on exactly the stale trees it explained |
| #995 | **F1** — TMB-Laplace finiteness, logit: 20/20 cells, 20,000 fits |
| #997 | **F2 + F2b** — rare prevalence: 4/8 + the clean cell at 8.11e−4 |
| #998 | `tools/recertify-c17.py` — closes **#979** |
| #999 | candidate freshness re-verified (open at time of writing) |

All merged branches deleted after confirming `0` commits outside `main`.

## 2. The evidence position on MSPL

**Discharged:** drmTMB's own TMB-Laplace finiteness evidence for **logit**. F1 + F2 + F2b =
**31,000 fits**, designs from 120 to 5,000 observations, expected event counts from **0.25 upward**
in cells where ML demonstrably diverges or fails, **no non-finite MSPL estimate**. Previously this
rested on Sterzinger & Kosmidis's numerical evidence, obtained on **lme4/glmer** — a different
implementation.

**The finding worth carrying:** difficulty tracks the **absolute number of events**, not prevalence.
Monotone across all eight F2 cells; cells at identical prevalence (8.5e−4 vs 8.0e−4) show ML
diverging in 98% versus 37% because one expects 0.25 events and the other 4. **A prevalence threshold
is therefore the wrong filtering instrument for rare species** — two species at identical prevalence
can sit on opposite sides of estimability.

**Still open, and this is the sharper question:** gllvmTMB blocks `vcov()` and `standard_errors()`
under MSPL, not only intervals, citing KF2021 that finiteness licenses neither. **drmTMB ships those
SEs.** Of the two designs ours is the more exposed. gllvmTMB flags its own citation as not yet
verified against the primary (`docs/design/117-…:139-144`, "⚠️ VERIFY AGAINST THE PRIMARY"). This is
a public-surface decision and it affects the **shipped logit route**, not a future one.

## 3. 0.7.0 — `tarball-clean`, blocked on one action

**#996 MERGED as `a3217da93` while this handover was being written.** `main` now carries
`DESCRIPTION: Version: 0.7.0`, and its shipped surface is **byte-equal to the frozen tarball's** —
`git diff a75c3c901 origin/main` over every shipped path is empty. The candidate landing is the one
tarball-visible change that moves `main` *onto* the artifact rather than away from it. #999 records
the re-check.

Artifact `2176e4b81b887e8d9…`, commit `a75c3c901`, 937 paths, forbidden-path scan empty.

**Verified fresh on 2026-08-11** (#999): `main` moved 13 commits and the candidate branch 5 since the
cut, and **every changed path is under `docs/` or `tools/`** — proven from the tarball's own inventory
(0 of 937 paths), not from `.Rbuildignore`. All three stored copies byte-identical. The predecessor
candidate went stale in three hours; this one has not.

**Next unproven: `platform-clean`.** Blocked on:

1. **win-builder — ABSENT.** Agent upload path is classifier-blocked; **owner's to run.**
2. **Windows CRAN-lane time — UNMEASURED**, projected **~11 min** against CRAN's ~10-minute incoming
   threshold, which the protocol treats as a **blocker for a first submission even when the status is
   only a NOTE**. Only win-builder measures it (`NOT_CRAN=false`).

**A win-builder result does exist — for a PREDECESSOR.** The coordination board records it ERROR-free
on `f9b9588e…` with #946 merged. That is *predecessor evidence only*: it describes different bytes
than `2176e4b8…`, so it does not advance this candidate's rung. Do not cite it as though it does —
that substitution is the exact failure the release protocol was written to stop.

**These are one action.** Nothing else advances the rung. Do not read a green 3-OS run, sanitizer, or
the clean valgrind subset as `platform-clean` — each proves only its own class.

## 4. gllvmTMB — what the sister repo decided

Scouted 2026-08-11 from `claude/design-117-separation-programme` @ `9518d1bf`.

- **Design 117 is a PLAN, not an implementation**, authorised 2026-08-08. Three arcs: penalty
  sensitivity reporting, interval construction (unsolved, options listed, none chosen), and a
  **both-tail prevalence sweep** sized for Totoro and **not yet run**.
- **Design 88 + PR #952 are the implementation** — draft, open, unmerged, on
  `codex/lane-b-mspl-reconcile-951`. A B2 campaign was still `RUNNING` as of 2026-08-09.
- **`aghq_ridge` is already merged to their `main`** — a different, landed mitigation (47% → 0%
  runaway), not MSPL.
- **They too have not answered the rare-species/shared-latent question.** They state it more
  precisely — symmetric, both-tail, "ubiquitous may be *more* damaging than rare" (flagged
  `AGENT-INFERRED`) — with a registered but unrun test. Their stance on rarity is **detect, don't
  filter**.

## 5. RETRACTED — a claim of mine, corrected by reading the source

I stated that admitting probit/cloglog to MSPL would mean shipping a **"known-wrong constant."**
**That is wrong, and the correction changes the next arc.**

`R/mspl.R` already implements the **link-general** form, structurally identical to gllvmTMB's:

```r
mspl_c_n(p, n_eff)      ->  c_n = 2 * sqrt(p / n_eff)     # link-INDEPENDENT scalar
mspl_log_weight(eta, n_trials, link)                       # link-SPECIFIC expected-information
penalty = c_n * (1/2) * log det(X' W X)
```

Correct probit (`φ²/[Φ(η)Φ(−η)]`) and cloglog weights are present. **Link-specificity is handled
inside `W`, where it belongs.** The penalty *shape* is right for all three links, and KF2021 Thm 1
proves finiteness is link-general for any link with `ω(η) → 0` in the tails.

What is actually unproven is narrower: `c_n = 2√(p/n_eff)` was calibrated by a delta-method argument
**at β = 0** for logit (`ω(0) = ¼`). Probit's `ω(0) = 2/π` gives `1.2533`; cloglog `≈1.3108` (my
arithmetic, **unverified against a source**). **Both have the same rate `√(p/n)`**, so the asymptotic
"penalty vanishes" argument survives untouched. The difference is a **finite-sample factor of ~1.6×
(probit) / ~1.53× (cloglog)**: the penalty is that much stronger relative to the sampling scale than
the logit calibration intended.

**Not a broken guarantee. A finite-sample over-softness of known size.** Whether it matters is an
empirical question nobody has answered.

Note also `R/mspl.R:7-10`: the `link` argument is "internal scaffolding for a future link-general
MSPL adapter", and the public entry point rejects non-logit at `R/mspl-estimator.R:179-184`.
**The fence is policy, not an implementation gap.**

## 6. The next arc — two campaigns, both cheap, harness already built

Three independent gates. **(1) penalty shape** — DONE, proved link-general. The other two:

**P1 — finiteness for probit/cloglog.** Extend F1 verbatim: same endpoints
(`fixed_information_finite_positive` ∧ finite `logdet` ∧ finite β̂), same control (ML must diverge),
same cells, with `link ∈ {logit, probit, cloglog}`. Logit is the control arm and must reproduce F1.
Answers whether TMB-Laplace finiteness holds for the non-logit composite — currently unevidenced for
*any* implementation.

**P2 — does the 1.6× matter?** Fit probit data at `c_n = 2√(p/n)` (shipped) against
`c_n = 1.2533√(p/n)` (the delta-method value for probit) across `n`, measuring bias, RMSE, and
ML-agreement as `n` grows. If the difference is immaterial at practical `n`, the fence can open on
evidence. If it is material, we ship the per-link constant or keep the fence — either way it is the
first evidence anyone has.

**Mechanics.** Both need the guard bypassed to *fit*. Do it on an **evidence-only branch whose source
change is never merged** — the VERDICT and data merge, the bypass does not. That keeps `main` and the
0.7.0 candidate untouched. Reuse `f1_runner.R`, `analyse.R`, `f1_launch.sh`, and `~/R/f1lib` on
Totoro (rebuild only if shipped source moved). F1 was 20,000 fits in 43 s; expect minutes.

**Estimate:** ~2 h, most of it prereg and writing. Freeze a prereg before any replicate, and run the
calibration probe **first** — F2's probe rejected its own planned grid, and P1's cells may need
different separation depths per link since `ω(0)` differs.

**Why cloglog is not the marginal case.** It is the natural link for occupancy and incidence data with
an exposure interpretation — precisely the rare-species setting where separation bites. Of the three
links it arguably has the strongest applied case *in the regime MSPL exists for*.

## 7. Do NOT

- **Do not open the MSPL guard without P1 + P2.** Simulating is not shipping; the fence waits on
  evidence, and this section is not licence to remove it.
- **Do not merge a guard-bypass to `main`.** Evidence-only branch, discarded after.
- Do not quote the retracted "conservative/harmless" SE-calibration reading, the unpaired engine
  ratios, or the first-pass MCSE.
- Do not treat the halted E1 probe as something to work around — its criterion needed revising, and
  F1 revised it by measuring at the optimum instead of along rays.
- Do not read any single platform class as `platform-clean`.
- **Do not touch** `claude/07-candidate-freeze-2` (#996), `claude/07-gate-truth` (#1000),
  `codex/lane-b-e0-readiness` (#858), or `codex/handover-07-candidate-prep-0809` (#955).

## 8. Environment

```sh
cd /Users/z3437171/local-scratch/worktrees/drmTMB-links   # this lane, detached on main
# Totoro: ssh via the cm- ControlMaster socket; ~/R/f1lib holds drmTMB built from the F1 source
#         ~/f1_runner.R ~/f1_launch.sh ~/f2_runner.R ~/f2b_runner.R all present
```

**Totoro gotchas, each paid for:** `library(drmTMB)` loads the *installed* package, which may predate
a merge — `estimator=` then falls into `...` and every fit errors with *"does not use arguments in
`...` yet"*. The F2 runner asserts the formal and aborts with `STALE BUILD`. `bf()` uses NSE, so a
formula **variable** fails and the literal must appear. And multi-line `cli` messages written with
`quote = FALSE` shatter a TSV — check row count *and* field-count uniformity before analysing.

## 9. Carried over

| item | state |
|---|---|
| #999 freshness record | open, CI running at handoff |
| 0.7.0 | `tarball-clean`; **win-builder is the single next action, owner's** |
| P1 + P2 | scoped in §6, not started |
| MSPL Wald SEs vs gllvmTMB's stricter line | **undecided, public-surface, affects the shipped logit route** |
| probit/cloglog MSPL fence | closed, deliberately, pending P1 + P2 |
| cloglog `ω(0) ≈ 0.582 → 1.3108` | **my arithmetic, unverified against a source** |

## 10. How to resume

You are Claude, picking this up in a fresh session. First run `tools/lane_preflight.sh`, then compare
this document against the live repository and classify every item here as **OWED**, **DONE**,
**RETRACTED**, or **PROTECTED** before acting. §5 is already marked RETRACTED — do not re-derive it.

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-11-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

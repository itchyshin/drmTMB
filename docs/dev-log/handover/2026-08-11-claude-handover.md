# Session Handoff — MSPL finiteness evidence closed, 0.7.0 at `tarball-clean`, probit/cloglog scoped

Meta: 2026-08-10 → 2026-08-11 · Claude → Claude · **cite by branch + SHA, never by path**

## The one-paragraph version

Seven PRs merged. drmTMB now has **its own** TMB-Laplace finiteness evidence for MSPL logit —
31,000 fits across three campaigns, replacing a reliance on the authors' glmer numerics. Emmy's last
Arc D condition is discharged, the C17 guard's two failure modes are now distinguishable and its
re-certification is one command, and issue #979 is closed. 0.7.0 sits at **`tarball-clean`** with a
verified-fresh artifact, blocked on **win-builder**, which is the owner's to run. One claim of mine
was **retracted on inspection of the source** — see §5, it changes the next arc.

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

# drmTMB Agent Instructions

`drmTMB` is an R package for fast univariate and bivariate distributional
regression using Template Model Builder.

> **▶ Latest — start here (2026-08-08; 0.7 issue sweep complete on focused branch).**
> The 29/29 open-issue sweep against `main@efb5af4f` found one issue-derived
> candidate blocker: **#61**, the procedural exact-candidate gate, not a new code defect.
> **#870** is the sole owner-policy decision and is not a demonstrated blocker. All other
> 27 issues are non-blocking post-0.7 or backlog work; five bounded status comments were
> posted and no issue was closed. D-93 and D-117 remain independent owner holds.
> DESCRIPTION remains **0.6.0**; current main is neither `tarball-clean` nor
> `platform-clean`. The exact predecessor `ad475cc39` / `2e5234bd…` retains only its
> historical `tarball-clean` proof. **NO-GO for exact-candidate work until Shinichi separately
> authorizes candidate preparation; no upload and no release-rung advance.**
> Preserve #858, #937, historical #947, and the protected dirty primary checkout. Multi-lane
> board (read every live row — do not orphan siblings):
> [`docs/dev-log/active-lane-split.md`](docs/dev-log/active-lane-split.md). Primary checkout
> on `claude/handover-freshness-0718` remains dirty/stale — **PROTECTED, never work there**.
> START HERE:
> [`docs/dev-log/release-audits/2026-08-08-0.7-issue-sweep.md`](docs/dev-log/release-audits/2026-08-08-0.7-issue-sweep.md).
>
> **▶ Prior — (2026-08-05, 135-TRACE CAMPAIGN LANDED ON MAIN via #930).**
> Totoro 135/135; **5/14 cells** promoted to `interval_feasible`. Post-campaign doc
> [`2026-08-05-cursor-handover-post-135.md`](docs/dev-log/handover/2026-08-05-cursor-handover-post-135.md)
> is historical — land step is DONE on `main`. **Do not re-run Totoro under the old prereg.**
>
> **▶ Prior — (2026-08-04, PRONG B STACK LANDED; CI CEILING SET FROM MEASUREMENT).**
> `main` = `71ce9e544`. All three stacked branches merged in order — #915
> `claude/prong-b-tier1` (`12e94657f`), #916 `claude/citation-durability` (`c976e7316`),
> #917 `claude/mc0653-fixture` (`71ce9e544`). **The census is UNCHANGED at 182
> `interval_feasible` / 60 `point_fit_recovery`**, re-verified on merged `main` after every
> merge. This stack **promotes nothing** — it makes `confint(method="profile")` *reachable*
> for 14 cells, which earns no interval or coverage claim. **196 / 46 needs the campaign,
> not this.**
> **The CI ceiling was a repo-wide latent failure, not this arc's regression.** Six completed
> ubuntu jobs on 2026-08-04 ran 43m35s / 43m51s / 44m34s / 44m36s / 45m49s / 46m34s: the suite
> **straddles** 45 rather than exceeding it, so every run was a coin flip. `main` itself was
> killed at 45.1 min on 2026-08-03 (run `30847977891` at `95b8ea34e`), and **two of today's
> six — including `main`'s own post-#915 check — would have died under the old cap.**
> It went unnoticed because **GitHub logs a timeout kill as `conclusion: cancelled`**, the same
> string as a concurrency cancel, which this repo also genuinely suffers. **Distinguish them by
> comparing job duration against the limit, never by reading the conclusion.** Ceiling now
> **75**, measured (~28 min over the observed maximum), after an interim 120 used purely to let
> a run finish and be measured. `drmSEM` carries the identical 45 — same fault, not yet fired.
> **Merge mechanics worth knowing:** `gh pr merge` is refused for lack of `workflow` OAuth scope
> whenever the merge must *synthesise* a new workflow blob (head and base differ there). Fix is
> the ordinary **update-branch** step — merge `main` into the branch, push over SSH, then merge —
> after checking the updated branch's tree hash matches the merge result CI already passed.
> **NEXT = the 135-trace interval campaign — UNFENCED by the owner, 2026-08-05.** 14 cells → 24
> targets → ~120 fits, Totoro, D-50; moves **182→196** and `FROZEN_CENSUS_POINT_FIT_RECOVERY` 59→45.
> It was fenced earlier the same day pending the D-117 boundary question; **Shinichi unfenced it
> directly, which supersedes that condition.** D-117's *discharge* remains an open owner call, but
> it no longer blocks this campaign — the boundary behaviour is now characterised (measured), warned
> about at the user surface (`drmTMB_profile_boundary_warning`, PR #924), and correctly attributed
> (not a drmTMB defect; the χ̄² cutoff was measured and REJECTED, PR #925).
> **This campaign PROMOTES ledger cells — the first census move in this programme.** So: run the
> truth gate, keep the pre-registration discipline, and do not promote a cell whose interval
> evidence does not clear its own contract. Before planning it, read
> `docs/dev-log/after-task/2026-08-04-prong-b-stack-landing-and-ci-ceiling.md` §9: **two of the
> ten contract clauses are currently enforced by code that cannot fail** — `clamp_limited` is
> hard-coded `FALSE` in every arc1/arc2 runner, and the unimodality / two-sided LR-crossing
> check does not exist anywhere in `tools/`.
> **D-117 — MEASURED 2026-08-04; the measurement stands, the PASS claim is WITHHELD.**
> All four 10-group cells now exist (`n_rep = 1000` each, Totoro, D-50): coverage **0.9140**
> (`n_per=4, sd=0.5`, N=40 — the worst corner, previously unmeasured), **0.9290**, **0.9310**,
> and **0.9370** (reproducing the banked 2026-07-26 cell on five statistics). All four clear the
> pre-registered floor `ss_floor(10) = 0.918`.
> **But a D-43 panel returned 2 of 3 NOT-DONE and the claim is withheld.** `profile.boundary` is
> a column `confint()` RETURNS — a user sees it. Gating that sub-population with the arc's own
> rule gives **BORDERLINE / FAIL / FAIL**: conditional coverage **0.8566 / 0.0732 / 0.2540**
> against non-boundary 0.9703 / 0.9656 / 0.9829. At `sd_mu = 1.0` that is **worse than the 0.829
> which disqualified the marginal route** in D-117's own framing, and at N=40 the boundary is
> **495/1000 fits**. Also newly reported: RE-SD point bias **−16.9% / −9.1% / −9.1% / −9.2%**
> (p < 1e-23), the mechanism behind the upper-miss asymmetry.
> **RETRACTED:** "the corner is not materially worse than D-97's pooled 0.9368" — contradicted at
> **z ≈ 2.5**. The supported claim is narrower: the profile route does not inherit the marginal
> route's *collapse*, and the gradient the gate was built to detect **is present at 1–2 pp**.
> **BUT IT IS NOT A drmTMB DEFECT — settled by comparator.** `lme4` on the **same DGP with the
> same seeds** (paired, `REML = FALSE` to match drmTMB's ML default) reproduces the behaviour
> essentially exactly: boundary incidence agrees on **4000/4000** replicates (495/41/63/0 in
> both), conditional coverage is **identical to four decimals** including the 0.0732, and
> coverage outcomes agree on 3999/4000. The single divergence goes **drmTMB's way** — lme4
> returned an interval excluding its own MLE. So the finding stands as a *statistical fact about
> profile intervals near a variance boundary*, and **the remedy is the user-facing warning, not
> an engine fix**. General principle, now in the brain: *imperfect coverage is the norm — very
> famous packages undercover too*; never infer our bug from a sub-nominal number without a
> paired reference run. See `COMPARATOR.md`.
> **D-97's 0.9368 HAS NO COMMITTED EVIDENCE — resolved, and it is the provenance that is wrong.**
> The committed profile campaign is **3 cells / 3,000 attempts pooling to 0.9400**, not 12 cells
> / 11,988 / 0.9368. "12 A1 cells" describes the **bootstrap-only** campaign (0.8714, n=12,000),
> and 11,988 = 12 × 999 where **999 is the bootstrap *resample* count**, not retained attempts.
> The figure traces to one after-task report existing **only in the brain vault**, from a
> now-deleted temp dir, via a script matching nothing here. This arc's premise **survives**
> (`n_per=4`, `sd_mu=1.0` genuinely were unmeasured) and §2.3's gap **widens to z ≈ 2.63** against
> the real number. D-97's *direction* is not overturned. **CORRECTED by the owner (brain
> `bbe643b`), additively, with the original paragraph preserved.** Cite **0.9400 / 3 cells /
> committed and hashed**; **do not cite 0.9368 again**. See `D97-PROVENANCE.md`.
> **CLOSED (2026-08-05) — the `profile.boundary` warning shipped.** `confint(method = "profile")`
> now warns (class `drmTMB_profile_boundary_warning`) when it returns a *usable* interval at a
> boundary, with a `NEWS.md` entry and a **Boundary intervals** section in `?confint.drmTMB`.
> The Wald path no longer steers users into an unflagged 7–25% regime. Deliberately narrower than
> `profile.boundary == TRUE`: `profile_failed` and `clamp_limited` rows carry the same flag but
> return NA endpoints and report through `conf.status`, so they are not warned about.
> The 2026-07-26 evidence on `codex/sd-bootstrap-r999-diagnosis` (`4cc837a85`) is now **PUSHED to
> origin** — all 29 evidence files fetchable; no longer single-disk. Note
> `claude/profile-coverage-remeasure-20260718`, cited in the brain's `DECISIONS.md:1628`,
> **does not exist**.
> **D-117 status: every *item* is closed; the DISCHARGE is still an open owner call** — a judgement,
> because the conditional finding stays adverse. **The withheld PASS remains withheld either way —
> do NOT reinstate it.** This no longer blocks the 135-trace campaign (unfenced above, and that
> campaign is the actual NEXT arc).
> **REFUTED AND NOW MEASURED (2026-08-05) — do NOT rebuild.** 4×1000 replicates on D-117's exact
> DGP and seeds: the χ²₁ arm reproduces D-117 **exactly** (boundary 495/41/63/0, conditional
> 0.8566/0.0732/0.2540), and the χ̄² arm is **WORSE everywhere** — the headline **0.0732 → 0.0488**,
> and 0.2540 → 0.0159. Nesting held **4000/4000**, so coverage(χ̄²) ≤ coverage(χ²₁) is guaranteed
> replicate-by-replicate. The identity that made this two `confint()` calls rather than a prototype:
> **the χ̄²-corrected 95% interval IS the ordinary 90% interval** (both are the level set at
> `qchisq(0.90,1)/2`). Evidence:
> [`2026-08-05-d117-chibar-cutoff-arm/VERDICT.md`](docs/dev-log/simulation-artifacts/2026-08-05-d117-chibar-cutoff-arm/VERDICT.md).
> **D-117's "not a drmTMB defect" is STRENGTHENED — it survived a measured challenge.** The
> reasoning that predicted this, committed before the run:
> **REFUTED — do NOT rebuild (see the arc report §10b).** The `qchisq(level, 1)` cutoff at
> `R/profile.R:3117` is *not* a Self–Liang χ̄² bug. The mixture is the null for **testing** a VC at
> zero; a CI inverts the LR at *interior* values where χ²₁ is right. The "corrected" cutoff
> `qchisq(2*level-1, 1)` is **smaller** (2.706 vs 3.841 at 0.95), so it narrows intervals and makes
> conditional coverage **worse**. And the 0.0732 is a **selection effect** — conditioning on
> `profile.boundary` picks replicates whose SD collapsed — i.e. post-selection inference, which no
> cutoff repairs. This challenge **strengthens** D-117's "not a drmTMB defect". Issue **#680**
> (`qchisq → qt²`, small-sample *width*) is a DIFFERENT problem; D-12 separates them — do not merge.
> **Separate live lead — and it is NOT D-117's mechanism.** The vault note *"Log-parameterised
> variances have an attracting boundary at zero — warm starts can inherit a collapse"*
> (gllvmTMB, 2026-08-03) is real and generic to `exp(log_sd)`. But it does **not** explain D-117:
> `lme4` does not parameterise the SD on the log scale, yet matched boundary incidence 4000/4000
> and conditional coverage to four decimals. A log-coordinate optimiser artifact would have made
> the engines diverge; they did not. **Read D-117's bias and undercoverage as genuine small-sample
> ML behaviour, not an optimiser pathology.** The note's real bite here is elsewhere:
> `R/profile.R:3303-3308`'s endpoint solver warm-starts from a bracket point and retries from the
> free optimum **only when convergence is not accepted** — and an attracting-boundary collapse
> *reports clean convergence*, so that fallback cannot see it. Structural blind spot, untested,
> independent of D-117.
> **▶ LANE HANDED TO CURSOR — 2026-08-05. START HERE if you are Cursor:**
> [`docs/dev-log/handover/2026-08-05-cursor-handover.md`](docs/dev-log/handover/2026-08-05-cursor-handover.md)
> — the interval-evidence lane (the **135-trace campaign**, unfenced) now belongs to **Cursor**;
> the Claude lane has STOPPED. **Sequential, never concurrent (D-87/D-88).** Sibling lanes are
> UNCHANGED and are listed in [`docs/dev-log/active-lane-split.md`](docs/dev-log/active-lane-split.md)
> — Lane B E0 (#858, codex), Mesh/SPDE (#893, codex), missing-data cross brief (#869). This pointer
> does **not** supersede them.
> **⚠ The primary checkout is 715 commits behind `main` on a July branch with 88 uncommitted files —
> work in a fresh worktree, and read files with `git show origin/main:<path>`.**
>
> **START HERE (Claude lane) — 2026-08-05 EVENING, the prior session's record:**
> [`docs/dev-log/handover/2026-08-05-claude-handover-evening.md`](docs/dev-log/handover/2026-08-05-claude-handover-evening.md)
> · arcs: [`2026-08-05-d117-profile-boundary-warning.md`](docs/dev-log/after-task/2026-08-05-d117-profile-boundary-warning.md)
> · [`2026-08-05-d117-chibar-cutoff-measured.md`](docs/dev-log/after-task/2026-08-05-d117-chibar-cutoff-measured.md)
> · [`2026-08-05-reml-interval-coverage.md`](docs/dev-log/after-task/2026-08-05-reml-interval-coverage.md)
> · superseded morning handover:
> [`docs/dev-log/handover/2026-08-05-claude-handover.md`](docs/dev-log/handover/2026-08-05-claude-handover.md)
> · evidence: [`VERDICT.md`](docs/dev-log/simulation-artifacts/2026-08-04-d117-10group-profile-gate/VERDICT.md)
> · panel record: [`D43-PANEL.md`](docs/dev-log/simulation-artifacts/2026-08-04-d117-10group-profile-gate/D43-PANEL.md)
> · comparator: [`COMPARATOR.md`](docs/dev-log/simulation-artifacts/2026-08-04-d117-10group-profile-gate/COMPARATOR.md)
> · provenance: [`D97-PROVENANCE.md`](docs/dev-log/simulation-artifacts/2026-08-04-d117-10group-profile-gate/D97-PROVENANCE.md)
> · CI ceiling arc: [`2026-08-04-prong-b-stack-landing-and-ci-ceiling.md`](docs/dev-log/after-task/2026-08-04-prong-b-stack-landing-and-ci-ceiling.md)
> · **warning arc (2026-08-05):** [`2026-08-05-d117-profile-boundary-warning.md`](docs/dev-log/after-task/2026-08-05-d117-profile-boundary-warning.md).

> **▶ Prior (2026-08-03, ARC 7b COMPLETE; PRONG B TIER 1 WAS THE NEXT ARC).**
> `main` = `b1b5ade3d`. The `model_surface` surface moved **184 interval_feasible / 58
> point_fit_recovery → 182 / 60** through PR #912. **The count went DOWN on purpose** — that
> is the truth gate working, not a regression. `FROZEN_CENSUS_POINT_FIT_RECOVERY` 58 → 59; the
> deliberately-independent whole-model literal 58 → 60. The two diverge for the first time
> because `mc-0260m` (source_order 694) sits outside the frozen ≤676 window.
> **What Arc 7b installed.** `tools/profile_truth_gate.py` checks interval LOCATION across the
> 31-cell contract surface (26 arc2 `CELL_CONTRACTS` + 5 arc1). Truth is **derived** from the
> fixture builders into `tools/profile-truth-manifest.tsv` (30 rows) by
> `tools/emit-profile-truth-manifest.R`, never declared twice. Cohorts pin
> `(information_rung, seeds)` — seeds alone are insufficient, because `mc-0409`'s superseded
> `each8` and repaired `each24` families reuse the same seed numbers.
> **CI now runs 6 of the 9 files in `tools/tests/`.** Five cells had reached review holding an
> interval that excluded their own true value; three were caught by a human, **two were not** —
> `mc-0424` and `mc-0260m`, now withdrawn to `point_fit_recovery` with their point evidence
> intact. `mc-0292` remains deliberately withheld — **do not re-add it**.
> The standing lesson from 7a still holds and 7b paid for it twice: **a guard's definition of
> done includes the line in CI that runs it** — and a guard that cannot fail is not a guard.
> An adversarial review of 7b's own gate found it defeatable by promoting a failing cell
> *upward*; red-test every guard against the thing it protects before trusting its green.
> **NEXT = Prong B Tier 1** — the first `R/` source change of the programme (`R/profile.R`
> E1–E4), unfencing `confint(method="profile")` for 14 cells, target **196 / 46**. The brief is
> refreshed and turnkey at
> [`docs/dev-log/handover/2026-08-03-prong-b-next-lane-brief.md`](docs/dev-log/handover/2026-08-03-prong-b-next-lane-brief.md);
> ship the code change and its tests as one arc, the 135-trace Totoro campaign as the next.
> Owner decisions outstanding: **the truth gate's tolerance units** (`0.05 × |truth|` gives a
> 6.8× spread in strictness across cells; scaling by interval half-width fixes it in one line
> but changes which cells pass, so it changes the census); q12 (16 cells behind a policy fence,
> not a capability limit); the B4-CI `SOURCE_COMMIT` route (note
> `codex/lane-b-q1-preflight-admission` has 226 unpushed commits, so publishing it is an option
> alongside porting c1's no-git pattern); the 89 stale "Parked … preserving the existing tier"
> parity rationales; and a stale `.git/index.lock` in the primary checkout needing a human `rm`.
> START HERE:
> [`docs/dev-log/handover/2026-08-03-arc7b-close-prong-b-handover.md`](docs/dev-log/handover/2026-08-03-arc7b-close-prong-b-handover.md).

> **▶ ACTIVE CODEX HANDOVER — start here (2026-08-03, Q2 CONFIDENCE EYE COMPLETE).**
> PR **#893** is merged and supplied the fixed-kappa mesh point-recovery
> prerequisite. The separate dense coordinate-spatial Gaussian q2 Confidence
> Eye campaign retained all 1,500 datasets and 4,500 direct target outcomes.
> Exact tested M = 36 sites x 3 and H = 36 x 8 baseline-ring configurations
> pass jointly; L = 12 x 3 fails. Only `mc-0199` and `mc-0672` advance to
> `inference_ready_with_caveats`; `mc-0673` and all broader spatial surfaces
> remain protected. Noether/Fisher/Grace, the same D43 panel, and Florence have
> approved the evidence-complete packet. START HERE:
> [`docs/dev-log/handover/2026-08-03-spatial-q2-confidence-eye-codex-handover.md`](docs/dev-log/handover/2026-08-03-spatial-q2-confidence-eye-codex-handover.md).

> **▶ ACTIVE LANE SPLIT — start here (2026-08-02).** C17 is closed through PR
> #894 at `c8e04258d`, with canonical `330 implemented / 340 rejected by design /
> 17 not implemented`. Current lanes and ownership boundaries are listed in
> [`docs/dev-log/active-lane-split.md`](docs/dev-log/active-lane-split.md).
> The C18 structured zero-one-beta atom programme has **LANDED on its lane**
> (PR #898): seven exact q1 structured ATOM cells promoted to
> `point_fit_recovery` — `zoi`/`coi` x {phylo, animal, relmat} plus both
> phylo_interaction cells. `mc-0615` (coi x relmat) is withheld at 3/4 after a
> variance-component boundary collapse, and spatial `mc-0606`/`mc-0616` are
> deferred to the mesh/SPDE lane **and refused in code** so they cannot be fitted
> without evidence. Lane census 337/350/10 = 697.
> START HERE:
> [`docs/dev-log/handover/2026-08-02-claude-c18-structured-atoms-handover.md`](docs/dev-log/handover/2026-08-02-claude-c18-structured-atoms-handover.md).
> The 2026-07-26 lane split below is retained as historical context, not the
> current coordination entrypoint.

> **▶ INTERVAL-FEASIBILITY LANE (2026-08-02, ARC 0 + CURRENT-SOURCE INTERVAL ARC 1 LANDED).** One of
> the two lanes named in the split above — read that first for ownership boundaries, then this.
> Draft PR **#896** on `codex/q1-interval-contracts-arc1` freezes the complete
> 82-cell current-source candidate denominator and promotes five exact direct
> targets from `point_fit_recovery` to `interval_feasible` using 15 immutable
> Totoro receipts. The ledger is now 161 `interval_feasible` / 77
> `point_fit_recovery`. `mc-0438` remains STOP because both tested profiles had
> nonfinite endpoints. Codex execution stops here; Claude starts with exactly one
> Rank-2 target packet from the frozen manifest. No q12, coverage/calibration,
> missing-response, B4-source reuse, or public-claim expansion. START HERE:
> [`docs/dev-log/handover/2026-08-02-claude-handover.md`](docs/dev-log/handover/2026-08-02-claude-handover.md).

> **▶ ACTIVE LANE SPLIT — start here (2026-07-26). TWO independent lanes; read YOUR lane's handover.**
> Shinichi split these on 2026-07-26 because they kept bleeding into each other
> (brain **`D-87`**: the "one platform at a time per repo" rule was already written down and
> was violated anyway on 2026-07-25/26 — **at orient, check `gh pr list` and recent
> `origin/main` commits for the other lane's activity; nothing warns you**).
>
> | Lane | Subject | Current handover |
> | --- | --- | --- |
> | **A — ASSOCIATION** | bivariate `y1`/`y2` dependence, Arc 6, staged-eta, the private sandwich engine (#846, #844) | [`2026-07-25-codex-general-association-sandwich-handover.md`](docs/dev-log/handover/2026-07-25-codex-general-association-sandwich-handover.md) |
> | **B — `sd()` SCALE & INTERVALS** | `sd(group) ~ x`, scale clamps, profile endpoints, RE coverage (#842/#843/#845/#848/#849, open #851), and B1 execution evidence | [`2026-07-26-b1-codex-handover.md`](docs/dev-log/handover/2026-07-26-b1-codex-handover.md) |
>
> **Do not merge the lanes.** Association must not touch `sd()` clamps or Arc D; this lane
> must not expose #846's engine through `vcov()`/`confint()`/profiles/docs.
>
> **Lane B status:** Arc B, A1, Arc C, A2 and the coverage campaign are all **MERGED**.
> **Arc D is BLOCKED on Shinichi's written contract decision** — PR **#851** delivers D0+D1
> and stops. Headline evidence: the pre-A1 bootstrap covered a nominal 95% random-effect-SD
> interval **50.9%** of the time; the fix reaches **87.1%** — necessary, **not sufficient**,
> so `confint(method = "bootstrap")` is **not** inference-ready for RE SDs
> (`docs/design/246`). `mc-0017`'s profile sits **9.371** from the clamp band and the clamp is
> exactly identity inside it, so **no certified cell is at risk from any Arc D design**.
>
> **▶ Prior (2026-07-25, ARC B MERGED; ARC A1 VERIFIED — MARGINAL SIMULATION; ARC C NOW DONE).**
> **Arc B — the C++/numerical audit — is MERGED** (PR #842, `main` `12d971f1`): five standing
> conformance suites (kernel oracle · FD-vs-AD gradient · score consistency · `CondExp`
> branch continuity · link/boundary), **58 blocks, 516 assertions, zero skips**, full suite
> 39708/1/124 against a 39192/1/124 baseline, `R CMD check` **OK**. Eight findings were
> **reported, none repaired** — the audit observes. Headline: **`simulate.drmTMB()` simulated
> CONDITIONALLY on the fitted MAP `û`**, so `confint(method = "bootstrap")` produced
> **anticonservative** intervals for every RE model. **No certified ledger cell was affected**
> (`bootstrap_R = 0` across 151 evidence artifacts; `mc-0227` profile, `mc-0242` Wald+profile).
> **Arc A1 fixes it** on branch `claude/a1-simulate-marginal-re`: `simulate()` gains
> **`re.form`** (`NULL` = marginal, the **new default**; `NA` = old conditional), `confint()`
> gains `bootstrap_re_form`. Marginal draws cover ordinary/correlated/labelled REs and
> `phylo`/`spatial`/`relmat`/`animal` at `q = 1`; `phylo_interaction`, cross-trait `q > 1`,
> covariance blocks, `corpair`, and modelled RE scale **abort rather than silently falling back**.
> **A1's evidence, stated against the commit it was measured on** (PR #843). On `5c7b9574`:
> CI `ubuntu-latest (release)` **pass** (`R CMD check`, clean checkout, 31m24s) and the local
> full suite **39722 pass / 1 fail / 0 error / 124 skip** against a 39708/1/124 baseline —
> **no new skips**. That one failure was A1's own: editing `R/profile.R` shifted conformance
> anchors, caught by `test-estimator-surface-conformance.R`. **Six anchors drifted, not one**
> (`R/profile.R` `:867→:878`, `:848→:860` ×4, `:3054→:3078`); only the `:867` row was
> *enforced* (the test checks detail strings solely for `expected == "error"` rows), so the
> other five were silent. All six are repaired, and **both gates must be re-read on the
> repaired tip before any merge claim** — the green above does NOT cover it.
> **CI could not see any of this**: that test resolves `R/profile.R` from a source checkout, so
> under `R CMD check` it does not evaluate. Arc B was green under `test_dir` and ERRORed under
> `R CMD check`; A1 is the exact mirror. **Run both gates, always, and on the commit you gate.**
> Design: `docs/design/243-marginal-simulation-and-re-form.md`.
>
> **ARC C IS DONE — and read this before touching F5.** **A5** shipped: beta was the sole
> outlier of the three `mi()`-capable families (`model_type` 1 and 7 already clamped before
> `mi()`), so the clamp moved to the top of the `model_type == 10` branch and the old site was
> removed — the soft clamp saturates outside the band, so applying it twice compresses an
> already-clamped value. **A7** shipped, and it was **19 rotted citations, not six**; rather
> than re-pin numbers that rotted *three times in one session*, every citation dropped its
> fragile line range and kept its durable `model_type == N` label (19 line-numbered citations
> → 0). **F9** was never in scope — the audit calls the 12 dead `sigma_i` locals evidence
> *against* drift.
>
> **⚠ F5 WAS ATTEMPTED AND REVERTED. Do NOT retry "reuse `drm_softclamp_log_sigma()` and the
> existing `logsigma_clamp`" — that exact approach is falsified.** It is 9 sites, not the 5 the
> audit listed, and clamping them made the Arc 7B dense-LSS **negative control** go green for
> the wrong reason: at the K=12 cell it turned a genuinely non-identified heterogeneity slope
> into a finite, vacuous profile interval `[-4.14, 27.79]`, and widening the band to
> `c(-200, 200)` restored `profile_failed`. The endpoint was the **bound**, not the data — worse
> than the `[0, Inf]` it replaced, because it passes any "is the interval finite" gate. Fisher's
> framing: the real defect is that `interval_status` cannot distinguish *ok because identified*
> from *ok because clamped*. **NEXT = Arc D**, which decides that contract before any code:
> `docs/design/245-f5-sd-regression-clamp-and-identifiability.md` (three candidate designs).
> **DEFERRED, scheduled before 0.7:** the interval-grade campaign (177 `point_fit_recovery`
> cells — the real prize, but it BLOCKS on Arc D, since coverage gathered while clamps may
> shape endpoints measures the clamp), Arc A2 capability (the five aborting structures;
> `phylo_interaction` is the cheapest — its Kronecker precision is already assembled), and
> audit A2/tweedie + A3/A4/ridge.
> **Release: `0.6` is the DEV CYCLE; the first CRAN submission is `0.7`** (owner, 2026-07-25;
> brain `D-86`, mirroring gllvmTMB's `D-66`).
> START HERE:
> [`docs/dev-log/handover/2026-07-25-arc-b-a1-claude-handover.md`](docs/dev-log/handover/2026-07-25-arc-b-a1-claude-handover.md)
>
> **▶ Prior (2026-07-25, ARC A CLOSED PARTIAL; NEXT = C++ / NUMERICAL AUDIT).**
> Arc A built the instrument, not the sweep. **Two of its four slices shipped; two were
> deliberately dropped** — no overlap sweep, no vignette. **Do not call Arc A complete.**
> Shipped: `evidence_class = "external_comparator"` in `capability-ledger/evidence.tsv`
> (4 rows — metafor, lme4 ×2, glmmTMB), the `mc-0260m` `meta_V` route row landed from its
> approved draft, a per-cell External-comparator surface column carrying independence
> strength, `docs/design/242` recording the policy, a correction to doc 158's Gaussian
> scale-conversion row, and a 177-cell triage. Fisher and Rose both signed off (Rose after
> a NOT-DONE first pass). **Why it closed early: the brief's arithmetic was false.** Of the
> 176-cell pool, 122 are `structured`, 18 `response_missingness` and 7 non-structured
> bivariate — **none has any external comparator in existence**; parity can reach ~15 cells
> ever, and 4 are wired. **NEXT = the C++ / numerical audit**, correctness-first
> (log-sum-exp and overflow paths, link edge cases, boundary parameterizations,
> finite-difference vs AD gradients); **no efficiency claim without a profiler**. It is the
> only instrument aimed at the frontier, which is 80% of the stuck pool. **Guard, do not
> "fix":** the frozen census (`source_order <= 676`) must hold exactly **158**
> `point_fit_recovery` cells permanently; the total (159) grows only by an approved insert.
> Raising 158 is how a promotion gets laundered. **`schema.json` is a source file, not a
> generated output** — `--write` never touches it. **START HERE:**
> [`docs/dev-log/handover/2026-07-25-arc-a-closed-claude-handover.md`](docs/dev-log/handover/2026-07-25-arc-a-closed-claude-handover.md).
> **FOREIGN, do not touch:** `codex/arc6-6-bernoulli-nb2-plan` (2 unpushed),
> `codex/pkgdown-formal-closeout` (1 unpushed, **still needs an owner**), the dirty root
> checkout on `claude/handover-freshness-0718`, PR #829, PR #836. **Never merge #828.**

> **▶ Prior (2026-07-25, → CLAUDE, CLEANUP LANE CLOSED — SUPERSEDED BY ARC A's CLOSE).**
> `main` = `eabca4fd`, **green** (`os-matrix` + `ubuntu-latest (release)`). Merged this lane:
> #832 Arc 8 meta-`V` (`d8888cfa`), #835 next-days overview (`247611c6`), #838 Arc A brief
> (`1e572197`), #837 anchor hygiene (`eabca4fd`). **Baseline test signal restored:** the seven
> `test-estimator-surface-conformance.R` failures were *drifted line anchors, none semantic* —
> every cited `cli_abort()` message still existed verbatim; now 147 expectations / 0 failures
> with `NOT_CRAN=true`. **NEXT = ultra-plan Arc A: cross-package parity as a new
> `parity_validated` evidence tier.** Driving finding: `test-comparators.R` is 1,245 lines of
> lme4/glmmTMB agreement tests, yet only **2 of 306** implemented cells cite comparator
> evidence — the validation exists and is invisible to the ledger. Load-bearing constraint:
> **parity licenses the OVERLAP region, not the FRONTIER** (scale-side REs, `sd()` regression,
> bivariate LSS, phylo residual log-SD have no external comparator and are where mc-0242 /
> mc-0227 found real bias). metafor 5.0.1 is installed, so `rma.mv` known-`V` parity for
> `meta_V(V = V)` is the first target with no install. Plan only; Fisher + Rose before anything
> runs. **START HERE:**
> [`docs/dev-log/handover/2026-07-25-cleanup-close-arc-a-claude-handover.md`](docs/dev-log/handover/2026-07-25-cleanup-close-arc-a-claude-handover.md).
> **MULTI-LANE — these are foreign; do not modify, merge, resolve, or clean them from the Arc A
> lane:** #829 eta/bivariate (conflict is *solely* `docs/dev-log/check-log.md`; its one-line
> `_pkgdown.yml` change merges clean); #836 the inbound Codex handover (still DRAFT);
> `codex/arc6-6-bernoulli-nb2-plan` (2 unpushed); `codex/pkgdown-formal-closeout` (1 unpushed,
> **undeclared by any prior handover — needs an owner**); the dirty root checkout on
> `claude/handover-freshness-0718` (65 uncommitted AGHQ/REML files, ~170 commits behind `main` —
> **work from a fresh worktree, never the root checkout**). **Never merge #828.**

> **▶ Prior (2026-07-25, → CLAUDE, MULTI-LANE CLEANUP TRANSFER — SUPERSEDED).**
> `main` is `e4f392f3` after documentation-only eta handoff PR #831; Julia
> xfam extractor PR #833 is also merged at `2e5e224a`. The active carried-over
> work is deliberately split: Arc 8 meta-`V` gate PR #832 has its focused
> surface-label repair pushed (`a19911fe`) and awaits only the running Ubuntu
> release check; the next-days overview is draft PR #835 and also awaits its
> Ubuntu check; PR #829 is conflict-dirty and belongs to the separate bivariate
> lane. PR #828 must not be merged. Two foreign local lanes are declared, not
> repaired: dirty `claude/handover-freshness-0718` and the two unpushed
> `codex/arc6-6-bernoulli-nb2-plan` commits. **START HERE:**
> [`docs/dev-log/handover/2026-07-25-claude-handover.md`](docs/dev-log/handover/2026-07-25-claude-handover.md),
> which carries every lane, exact merge conditions, and the next-days sequence.

> **▶ Prior (2026-07-24, → CODEX, ARC 7 B0 CARRIED OVER).**
> Arc 6 closed on `main` at `d7359df2` (PRs #826/#827; R-CMD-check and pkgdown
> green). Arc 7 B0 is a clean-current-main, **negative-evidence integration**
> lane for `meta_V`, on `codex/arc7-metav-b0`: it selectively carries the B3
> small-K contract, not the stale branch wholesale. The staged core patch adds
> K=12/dense-control fixtures, `confint()` interval recording, and all-attempt
> accounting; focused `phase18-meta-v|comparators` tests passed. Do **not** run
> remote compute, promote a tier, or claim interval validity/coverage. The next
> session must inspect the staged patch, run the two-cell local sentinel, then
> obtain Fisher/Rose review before committing a scoped PR. **START HERE:**
> [`docs/dev-log/handover/2026-07-24-codex-handover.md`](docs/dev-log/handover/2026-07-24-codex-handover.md).
> The dirty `claude/handover-freshness-0718` AGHQ/non-Gaussian-REML lane and
> legacy unpushed `codex/arc6-6-bernoulli-nb2-plan` commits are foreign; do not
> modify, merge, or clean them from this lane.

> **⚠ Compute & CI — D-50 (2026-07-12).** Simulation / recovery / power / coverage campaigns run on
> **Totoro or DRAC**, **never GitHub Actions**, and their outputs are **never stored as GitHub
> artifacts** (Actions storage is a hard 2 GB/month cap that this repo's `phase18-simulation-grid`-style
> workflows had nearly filled). Campaign results stay **local** + in the repo dev-log. GitHub Actions here
> is for **package checks + docs only**, with **short artifact retention**. (Hub `AGENTS.md` Compute
> section · shinichi-brain `DECISIONS.md` D-50.)

> **▶ Current staged-eta coordination (2026-07-25, → CODEX, PR #844 DRAFT).**
> PR #844 (`codex/staged-eta-godambe-se`) contains the developer-only, fixed-effect
> Bernoulli × ordinary-NB2 candidate two-stage Godambe diagnostic. It is **not** a
> public SE, `vcov()`, Wald/profile/`confint()` route, or validation claim. PR #843
> merged to `main` as `ac0d3e55` and owns `docs/design/243-*`; #844 is rebased on
> that `main` and its design record is now `244`. Rerun the focused tests and obtain
> narrow review before treating #844 as a resolved reference. A
> later general latent-normal engine is a **separate fresh lane**: common sandwich
> assembly plus explicit pair adapters, with pair-specific validation still required.
> The former 24 × 200 × 399 staged bootstrap campaign remains stopped; direct
> `biv_lognormal()` `rho12` evidence remains separate. **START HERE:**
> [`docs/dev-log/handover/2026-07-25-codex-general-association-sandwich-handover.md`](docs/dev-log/handover/2026-07-25-codex-general-association-sandwich-handover.md).

> **▶ Latest — start here (2026-07-24, → CODEX, ARC 6 DIRECT ASSOCIATION EVIDENCE LANDED; NEXT = STAGED-ETA PLAN ONLY).**
> `main` = `d0ac907f`; GitHub Actions R-CMD-check run
> [30126489352](https://github.com/itchyshin/drmTMB/actions/runs/30126489352)
> is green. Exact direct fixed-effect `biv_lognormal()` constant log-residual
> `rho12` now has guarded Wald, direct-likelihood profile, and joint
> parametric-bootstrap intervals, calibrated in the retained-all-attempts
> Totoro n-ladder (2,700 outer fits; 537,300 bootstrap refits). Profile is the
> primary interval only at the tested `n >= 300`, `rho12 = 0, 0.5, 0.85`
> domain; Wald/bootstrap remain calibrated comparators. The Palmer Penguins
> tutorial is live in source and names its limited 43/99 real-data bootstrap
> diagnostic. **Do not transfer this claim to staged `eta`:** its current
> two-stage curvature conditions on fitted margins, so `vcov()`, Wald/profile
> CIs and `confint()` remain unavailable. **NEXT:** a fresh `$ultra-plan`,
> then approval, for the reviewed Bernoulli x ordinary-NB2 full-refit bootstrap
> lane; DRAC only after smoke + fresh compute approval. Student-t, generic
> cross-family, random-effect, missingness, and association-predictor expansion
> remain deferred. **START HERE:**
> [`docs/dev-log/handover/2026-07-24-codex-staged-eta-handover.md`](docs/dev-log/handover/2026-07-24-codex-staged-eta-handover.md).
> The foreign `claude/handover-freshness-0718`, `codex/arc6-6-bernoulli-nb2-plan`,
> and pkgdown audit lanes remain separate; do not modify them from this lane.

> **▶ Latest — start here (2026-07-23, → CODEX, ARC 6.1–6.2 MERGED TO `main`).**
> PR #817 merged as `85cff6fa`: `d9dc3116` (Gaussian × Bernoulli) and
> `0e512b22` (Gaussian × ordinary NB2) provide two bounded, fixed-effect, ML,
> complete-pair frozen-margin `associate_pairs()` slices. They estimate only
> conditional latent-normal `eta`, never `rho12`, observed correlation,
> joint-MLE inference, intervals, recovery, or a capability tier. Arc 6.2 uses
> the exact NB2 CDF jump interval with tail-safe diagnostics; 32 new focused
> NB2 tests and 26 Arc 6.1 regression tests (2 expected CRAN skips) passed;
> separately retained Arc 6.1/6.2 smoke receipts matched on a final rerun.
> No campaign, capability promotion, `meta_V`, Julia, or CRAN work occurred.
> **NEXT IS A DECISION, NOT IMPLEMENTATION:** open a fresh plan-only Arc 6.3
> lognormal × lognormal demand/API/oracle review only if Shinichi approves it;
> otherwise choose a direct-kernel research branch or return to the Q-series.
> **START HERE:**
> [`docs/dev-log/handover/2026-07-23-codex-arc6-handover.md`](docs/dev-log/handover/2026-07-23-codex-arc6-handover.md).
> The foreign `claude/handover-freshness-0718` AGHQ/non-Gaussian-REML lane
> remains separate; do not attribute or modify it from this Arc 6 branch.

> **▶ Latest — start here (2026-07-22, → CODEX, 0.6 DEV ARC TRACK A **MERGED** to `main`).**
> `claude/0.6-dev-arc` is **MERGED** (was +15 / −6, tree clean). Track A is verified: newcomer sweep
> **17/17 FITS or CLEAN**, full suite **264 files / 39,320 passing**, **zero added failures** — proved
> by re-running every failing file at `aa237a28` for byte-identical counts. Landed: `||` desugaring
> (#776), `||` intercept resolving last-wins to match lme4, `coef()` documented, `impute_model()`
> formula guard, phase18 D-50 guard inversion, task-to-seed registry, beta-phylo runner path fix,
> meta_V ADEMP amendment. The session-2 blocker *"sequence the merges — pkgdown owner first"* had
> already CLEARED (`1a972b8e` = pkgdown reader-surface repair #816), and the Codex `julia-bridge`
> roxygen lane landed with that same PR.
> **✅ THE Q-SERIES RED IS FIXED (Shinichi, 2026-07-22, `e46ba36d`).** It was never
> branch-introduced — `tools/qseries_v1_claim_guard.py` exited 1 on `main` itself because README had
> lost its q-series status link and its `q=12` mention while four q12 cells stayed admitted (22
> failures in `test-structured-re-conversion-contracts.R`). Repaired the right way — by restoring the
> README catalog, **not** by retargeting the guard: the landing page now names the exact Gaussian
> `q=12` all-four two-slope `phylo()` / `spatial()` / `animal()` / `relmat()` cells **at
> point-fit/recovery grade and explicitly withholds interval and coverage claims**, and links the
> row-level ledger. Guard now **exits 0**; that test file passes 237 tests, 0 failures.
> CRAN stays **PARKED, not failed** — no re-freeze, no platform matrix, no submission.
> START HERE:
> [`docs/dev-log/handover/2026-07-22-codex-handover.md`](docs/dev-log/handover/2026-07-22-codex-handover.md)
> **Open lanes:** (a) 0.6 dev arc → **MERGED**; (b) pkgdown reader surface → **LANDED** (#816);
> (c) Codex `julia-bridge` → **landed with #816**; (d) **`claude/handover-freshness-0718`** (AGHQ +
> non-Gaussian REML) → 1 commit unpushed, **foreign lane, still open**.
> The 11-item maintainer action list is NOT duplicated — it stays in
> [`docs/dev-log/handover/2026-07-21-0.6-dev-arc-session2-handover.md`](docs/dev-log/handover/2026-07-21-0.6-dev-arc-session2-handover.md).
> **NEXT:** with the q-series red closed, the queue reverts to the ultra-plan — **meta_V** is the
> priority (Shinichi, 2026-07-21): reconcile the existing `docs/design/48-phase-18-meta-v-ademp.md`,
> do **not** author a new spec. Track B stays compute-gated behind B3 approval.
> **Housekeeping:** the stale `.git/index.lock` was **cleared 2026-07-22**. The entire branch estate
> is now on `origin` — **zero unpushed commits anywhere** (`git log --branches --not --remotes` = 0),
> including `claude/handover-freshness-0718` at `85e78223`.
> **⚠ THREE BRANCHES HAVE DIVERGED HISTORY — NEVER `--force` THEM.** Each holds local-only *and*
> remote-only commits, so forcing destroys remote work. Local tips were rescued to new refs (originals
> untouched): `codex/q8-endpoint-precode-gate` (4 local / 2 remote) →
> `codex/q8-endpoint-precode-gate-local-20260722`; `codex/nb2-poisson-structured-gates-actions`
> (10 / 13) → `nb2-poisson-gates-local-20260722`;
> `codex/truncated-nb2-mu-ri-artifacts-2026-05-26` (1 / 2) →
> `truncated-nb2-mu-ri-artifacts-local-20260722`. Reconciling them is a maintainer decision.
> FYI for future pushes: no workflow here triggers on a feature-branch push — `R-CMD-check` fires only
> on `main`/`master` and tags, `pkgdown` only via `workflow_run` on those, and `rhub` +
> `phase18-simulation-grid` are `workflow_dispatch`-only (D-50 compliant).
>
> **▶ Prior (2026-07-21, → Claude, 0.6 DEV ARC — CRAN SUBMISSION PARKED).**
> **Shinichi decided 2026-07-21: drmTMB 0.6 will NOT be submitted to CRAN.** It needs
> substantially more work first. The CRAN release gate is **PARKED, not failed** — the
> tarball re-freeze, platform matrix (win-builder / R-hub / 3-OS), `cran-comments.md`
> rewrite and submission are all **out of scope**. Do not restart them.
> PR #810 **MERGED** (squash `e7ac5896`) and pkgdown auto-deployed, so
> `codex/precran-review-20260721` is a **squash-merge orphan** — do not open a PR from it.
> An approved, **plan-reviewed** ultra-plan (Fisher / Rose / Ada) now governs, in three
> tracks: **A** quality/API · **B** capability breadth (the headline) · **C** reader depth.
> **NEXT = Track A at A0, then A1 — the `||` desugaring** (`(1 + x || g)` currently falls
> through to the *fixed-effect* design matrix and aborts with a raw
> `'length = N' in coercion to 'logical(1)'`; desugaring to `(1|g) + (0+x|g)` closes #776
> and carries **no evidence burden**, since it lands on an already-certified route).
> **Track B is compute-gated:** no campaign fit until its pre-registered spec is
> plan-reviewed AND Shinichi approves (B3); Totoro for the rho12 study, DRAC array for the
> multi-cell batch, **never GitHub Actions** (D-50). Honest ceiling: coverage certification
> **cannot** produce a `supported` cell — the deliverable is "+N `inference_ready_with_caveats`".
> Two traps recorded: **squash merges break `git merge-base --is-ancestor`** (verify landed
> work by CONTENT), and **row-specific coverage denominators are FITS, not fits × rows**.
> START HERE:
> [`docs/dev-log/2026-07-21-0.6-dev-arc-ultra-plan.md`](docs/dev-log/2026-07-21-0.6-dev-arc-ultra-plan.md)
> then [`docs/dev-log/handover/2026-07-21-0.6-dev-arc-claude-handover.md`](docs/dev-log/handover/2026-07-21-0.6-dev-arc-claude-handover.md)
>
> **▶ Prior (2026-07-21, → Claude, pre-CRAN review + `rho12` AUDIT REVERSAL).**
> PR #810 (`codex/precran-review-20260721`) carries the compact Pat/Rose-approved
> pkgdown landing page and three sound Julia/cross-family corrections — but **four of
> its seven "blocker" fixes were FALSE POSITIVES and have been REVERTED.** A
> predictor-dependent `rho12 ~ x` **does** yield row-specific intervals:
> `conf.status = "newdata_required"` is an *instruction to supply `newdata`*
> (`R/predict-parameters.R:238`), not a denial. Verified by fitting a real
> `rho12 ~ x` model — profile and Wald routes both returned finite bounds and agreed
> to 3 dp. The same `newdata` route serves `sigma`/`sigma1`/`sigma2`/`corpair()`
> (`R/profile.R:3844`). **Manifest §3/§5 were wrong and are corrected**; the omitted
> Gamma cell `mc-0242` was added as §1b-2; issue **#802 needs reframing** (the
> interval exists — its *coverage* is what is deferred). Restored statements now say
> *computed, not coverage-certified*. `julia-engine.Rmd` gained the up-front deferred
> fence `cross-family.Rmd` already had.
> **Release rung: `tarball-clean` is STALE** — the frozen candidate `323d820f` was
> built at `c3b9ad49`, and PR #809 has since added a vignette + a 1.37 MB PNG, so a
> **re-freeze + re-check** is required before the platform matrix, not after. Also
> open: `cran-comments.md` understates installed size (27.8 Mb; `doc` = 9.4 Mb) and
> justifies only `libs`; Windows vignette timing across 34 vignettes is unmeasured.
> #806 Julia extractor repair stays post-0.6. START HERE:
> [`docs/dev-log/after-task/2026-07-21-rho12-interval-audit-reversal.md`](docs/dev-log/after-task/2026-07-21-rho12-interval-audit-reversal.md)
> then [`docs/dev-log/handover/2026-07-21-claude-handover.md`](docs/dev-log/handover/2026-07-21-claude-handover.md)
>
> **▶ Prior (2026-07-21, PHASE 20 CRAN RC — drmTMB 0.6.0 MERGED at the tarball-clean rung).**
> The Phase-20 CRAN release-candidate lane is complete: drmTMB **0.6.0** is merged to `main` at the
> **tarball-clean + local clang-UBSAN** rung (RC PR #804 → honesty-sweep #805 → consolidation follow-up).
> This is **NOT** "CRAN-ready": the REMOTE platform matrix (win-builder / R-hub UBSAN·valgrind·rchk / 3-OS
> GitHub) and the CRAN submission (G6) are the declared **NEXT** gates (a separate future lane). 0.5.0 was
> ditched and never accepted → **0.6.0 is a first/new submission.** Evidence: local `R CMD check --as-cran`
> = 0 err / 0 warn / 1 NOTE (new-submission) + installed-size INFO; CRAN-lane `FAIL 0 | PASS 12011`; local
> clang-UBSAN 0 runtime errors on the six `(int)asDouble()` casts. The D-43 panel ran **four** rounds
> (rounds 1–3 plus a 6-lens adversarial review caught and fixed several release-surface honesty defects —
> **none a code regression**; round 4 = 3× READY from three genuinely fresh agents on the current frozen
> artifact `323d820f0a0ca444`). PRs #804 → #805 → #807 all merged; `origin/main` = `78b89d3f`.
> **NEXT, and handed to Codex: the pre-CRAN CODE + CONTENT review.** This lane changed **no executable
> code** (`src/` 0 files, `tests/` 0 files, `R/` only 77 roxygen lines), so the code and the science are
> genuinely unreviewed while the packaging is audited four times over. Do that review **before** the
> platform matrix. Capabilities + every deferred future-work item (with its owning issue) are catalogued in
> the release manifest (`docs/dev-log/release-audits/2026-07-20-0.6.0-release-scope-manifest.md`). Open
> follow-ups: Julia xfam extractors **#806**; sigma-slope start **#710.2**. START
> HERE: [`docs/dev-log/handover/2026-07-21-codex-handover.md`](docs/dev-log/handover/2026-07-21-codex-handover.md)
>
> **▶ Prior (2026-07-19, AGHQ + non-Gaussian REML ARC DONE; mc-0227 PROMOTED).**
> The AGHQ + non-Gaussian REML arc is BUILT + validated + landed on branch
> `claude/handover-freshness-0718` (`1ed90599` + `4956c754`, pushed; **no PR yet — open one**).
> **mc-0227** (cumulative_logit `mu` random-SLOPE RE-SD) PROMOTED `point_fit_recovery →
> inference_ready_with_caveats`: Totoro N=1200/cell coverage nominal at every M{40,80,160,320}
> (0.9515 / 0.9457 / 0.9596 / 0.9508, all CIs overlap `[0.925,0.975]`), memo-blind D-43 **3/3
> PROMOTE**, certified floor **M=80** (M=40 exploratory/boundary-heavy). Two levers in-package +
> oracle-validated: **O2** binomial Cox-Reid REML == `glmmTMB(REML=TRUE)` 7.3e-9 (relaxed 2 gates in
> `R/drmTMB.R`); **O3** nested AGHQ+Cox-Reid (`R/aghq-coxreid.R`, **pure R**) == glmer 3.6e-5 /
> brute-force 6.4e-9. Architecture: the recombination is **nested + external**, NOT a joint TMB
> `random=` fold (design doc `docs/design/224`). Ledger regenerated, unittest **37/37**, estimator
> KEPT `ML` (a new token would flip the family-map slope to "absent"). **NEXT = the 3-cell mu-slope
> batch** (skew_normal `mc-0464`, tweedie `mc-0539`, zero_one_beta `mc-0575`) as a **DRAC job array**
> (mc-0242 ML-Laplace coverage machinery; only the 3 DGPs are new) — plan-review then STOP for compute
> approval. Cross-repo FYI left in gllvmTMB. **Handover TO CODEX** (live toolchain runs the PR + campaign).
> START HERE:
> [`docs/dev-log/handover/2026-07-19-codex-handover.md`](docs/dev-log/handover/2026-07-19-codex-handover.md)
>
> **▶ Prior (2026-07-18, mc-0242 GAMMA σ-RE PROMOTED + AGHQ/REML ARC SCOPED).**
> Gamma sigma random-intercept cell `mc-0242` promoted to `inference_ready_with_caveats` and MERGED to
> `main` (PR #791; test-freshness follow-up PR #792); certified floor M>=32, M=16 borderline, M=8
> excluded. (Sibling beta-phylo `mc-0017` promoted via PR #789.) Then the DIAGNOSTIC scoping that framed
> the arc above: the small-cluster non-Gaussian RE-SD bias is TWO orthogonal levers — AGHQ (integral,
> ~2pt) + Cox-Reid non-Gaussian REML (ML variance bias, ~4pt, the bigger lever), measured on
> cumulative_logit vs glmmTMB/glmer/lme4. Scoping on `claude/aghq-reml-scoping` (PR #793, MERGED
> `ff4fd145`). Parked capability-surface tooling → draft PR #794 (rebase+regenerate before merge).
>
> **▶ Prior (2026-07-16, BETA PHYLOGENETIC q1 STOPPED).**
> The approved two-PR Beta phylogenetic LSS goal stopped at PR 1's recovery
> gate on branch `codex/beta-phylo-q1-constant-sd`. The narrow constant-SD
> implementation and exact likelihood/gradient tests remain branch-only; no PR
> was opened and no ledger row was promoted. The original `m = 2` and valid
> within-block `m = 4` campaigns are HOLD at moderate `g`. After repairing seed
> independence, complete-DGP RNG provenance, source/artifact authentication,
> and output guards, a genuinely disjoint 30-fit Totoro pilot again gave
> `g = 256` mean log-latent-SD bias `-0.2214` (MCSE `0.0861`) against the frozen
> absolute `0.10` gate. Noether, Fisher, and Rose returned STOP; the 1,200-fit
> certification was not launched. Do not open PR 1, begin PR 2, rescore raw SD,
> change the gate, or omit `g = 256` without Shinichi's explicit new goal.
> Family `sigma` (`phi = sigma^(-2)`) remains distinct from the latent
> phylogenetic location-effect SD. START HERE:
> [`docs/dev-log/handover/2026-07-16-beta-phylo-q1-pilot-abort-codex-handover.md`](docs/dev-log/handover/2026-07-16-beta-phylo-q1-pilot-abort-codex-handover.md)

> **▶ Prior (2026-07-15, BETA PHYLOGENETIC LSS PLANNING TRANSFER; PR #785 MERGED).**
> Arc 1b-S2R is merged through PR #784 at
> `b8aa6d701389aad617a4ad8203bdfa3dc1f01495`; its exact reviewed head
> `24016bf36242e35c7098a9336fa216d17f4a3ad4` passed GitHub run 29434103188.
> This planning transfer established the queued two-PR Beta phylogenetic
> location-scale-scale sequence: first the constant-SD q1 phylogenetic `mu`
> prerequisite, then the exact
> `sd(spp_id, level = "phylogenetic") ~ 1 + x` regression, both capped at
> `point_fit_recovery`. Keep family `sigma` (`phi = 1 / sigma^2`) distinct from
> latent-target `sd()`. Hierarchical random effects inside `sd()` remain a later
> separate subarc. Shinichi subsequently approved and restarted the goal; the
> current 2026-07-16 block above supersedes the planning-stage stop. PR #781
> and unrelated worktrees remain outside scope. START HERE:
> [`docs/dev-log/handover/2026-07-15-beta-phylo-lss-codex-handover.md`](docs/dev-log/handover/2026-07-15-beta-phylo-lss-codex-handover.md)

> **▶ Prior (2026-07-15, ARC 1b-S2R CLOSEOUT; PR #784 SUBSEQUENTLY MERGED).**
> PR #783 is merged at `d210439187f2a49922de8bcf8c183d164d7bd0dc`. Branch
> `codex/arc1b-s2r-relmat-q2-reml` now admits native REML for one exact
> bivariate-Gaussian supplied-relatedness cell: matching labelled
> `relmat(1 | p | id, K = K)` location intercepts in `mu1` and `mu2`. Its
> independent dense oracle and predeclared Totoro campaign retained all 2,400
> attempts; every fit converged with `pdHess = TRUE`, and all recovery gates
> passed. The maximum claim is `point_fit_recovery`: supplied `Q`, `animal()`,
> slopes, scale-side blocks, q4+, intervals, and coverage remain unsupported.
> Finish this arc's closeout before starting the next queue item. The queue is
> Beta phylogenetic q1 `mu` prerequisite, then a bounded Beta q1
> location-scale-scale gate, then a separate hierarchical-`sd()` subarc. That
> future subarc may first consider only random RHS terms at a genuinely coarser
> replicated grouping level; same-level and highest-level-without-a-higher-group
> forms remain rejected. Keep family `sigma` distinct from latent-target
> `sd()`, and do not bundle these arcs. PR #781 remains unrelated. START HERE:
> [`docs/dev-log/handover/2026-07-15-arc1b-s2r-relmat-q2-reml-codex-handover.md`](docs/dev-log/handover/2026-07-15-arc1b-s2r-relmat-q2-reml-codex-handover.md)

> **▶ Prior (2026-07-14, ARC 1b-S1 COMPLETE; PR #783 THEN OPEN).**
> Branch `codex/arc1b-s1-spatial-q2-reml` admits native REML for one exact
> bivariate-Gaussian fixed-covariance spatial q2 location-intercept cell. The
> independent dense oracle, 41-expectation boundary matrix, 1,200 retained Totoro
> fits, ledger/runtime/pkgdown checks, and Fisher/Noether/Rose review support only
> `mc-0199` and `mc-0672` at `point_fit_recovery`; `mc-0673` preserves the rejected
> remainder. Verified ancestor `38c57f6c` passed GitHub run 29392088529. PR #783
> was subsequently merged; PR #781 remained unrelated and untouched. Historical
> handover:
> [`docs/dev-log/handover/2026-07-14-arc1b-s1-codex-handover.md`](docs/dev-log/handover/2026-07-14-arc1b-s1-codex-handover.md)

> **▶ Prior (2026-07-14, Arc 3a complete; PR #782 merged).** See
> [`docs/dev-log/handover/2026-07-14-arc3a-codex-handover.md`](docs/dev-log/handover/2026-07-14-arc3a-codex-handover.md).

> **▶ Prior (2026-07-14, PR #780 repair disposition).** PR #780's verified Arc 1a
> implementation ancestor is `1dd79228`; see
> [`docs/dev-log/handover/2026-07-14-codex-handover.md`](docs/dev-log/handover/2026-07-14-codex-handover.md).

> **▶ Prior (2026-07-13, → CLAUDE, Arc 4a closeout landed; mirror pending).**
> Branch `feature/arc4a-profile-coverage` now contains the `has_sigma_random_effects()` repair,
> fitted lognormal/Gamma sigma-prediction regression tests, and a corrected iid-un­centered
> Totoro campaign (14,400 fits; zero failures). Fresh Noether/Fisher/Pat D-43 review supports
> promoting `mc-0382` and `mc-0061` only to `inference_ready_with_caveats`, over the exact tested
> domains recorded in the ledger. The live-ledger capability generator and tracked HTML surface
> are refreshed branch-locally. The isolated TMB 1.9.21 adaptive marginal Gauss-Kronrod probe is
> **negative/inconclusive**: its normalized objective misses the direct oracle's numerical-error
> envelope and the frozen fixture is boundary-singular, so package integration remains deferred.
> Full package/site checks and Rose's repaired-tree audit are DONE. Implementation commit
> `2806f00b` is pushed and PR #779 remains open. Only Claude's external `a1bf21a1` mirror is
> pending; do not claim it refreshed before exact HTML/hash read-back. Task C remains deferred.
> START HERE:
> [`docs/dev-log/handover/2026-07-13-arc4a-claude-handover.md`](docs/dev-log/handover/2026-07-13-arc4a-claude-handover.md)
>
> **▶ Prior (2026-07-13, → Claude, ARC 2b/2c COMPLETE — mu slope everywhere + sigma intercept for lognormal/Gamma; Arc 4a ratified next).**
> `main` = `43c1a321` (Arc 2b/2c + DG3 evidence merged, PRs #775/#777) · every fitted
> univariate family now has a `mu` random intercept **and** an independent slope; lognormal +
> Gamma also a `sigma` random intercept. All `point_fit_recovery` (ML-Laplace) · `--as-cran`
> 0/0/1-benign · ledger 295/333/40 · artifact `a1bf21a1` refreshed. Two evidence studies:
> Laplace-vs-AGHQ + DG3 RE-SD coverage (Totoro, 7200 fits) — the RE-SD downward bias is the
> expected finite-sample Laplace effect (AGHQ fixes the per-n integral half, REML the per-M df
> half; drmTMB-Laplace matches lme4 exactly). **Next arc RATIFIED (5-agent design workflow):
> Arc 4a — the profile-CI DG3 rerun → interval_feasible promotion**
> (`docs/dev-log/2026-07-13-arc4a-profile-interval-plan.md`; honest catch: profile fixes the
> ∞-width, not the M=8 coverage gap). Totoro reachable (no MFA); DRAC is not.
> START HERE:
> [`docs/dev-log/handover/2026-07-13-claude-handover.md`](docs/dev-log/handover/2026-07-13-claude-handover.md)
>
> **▶ Prior (2026-07-12, → Claude, ARC 2a COMPLETE — mu random intercept for every family).**
> `main` = `0ba88fd8` (Arc 2a merged + pushed) · five families (binomial,
> cumulative_logit, skew_normal, tweedie, zero_one_beta) now accept `(1 | group)`
> on `mu`; every fitted univariate family has at least a mean random intercept.
> Per-family DG2 recovery evidence; `--as-cran` 0/0 (11593 tests); ledger cells
> mc-0059/0225/0463/0538/0567 → verified. pkgdown reference-index build FIXED
> (`_pkgdown.yml` #747/#748 topics). ML-Laplace only, intercept-only; slopes/
> sigma-RE (Arc 2b/2c), AGHQ/REML, and the tweedie fix-`p` API remain carried over.
> START HERE:
> [`docs/dev-log/handover/2026-07-12-arc2a-claude-handover.md`](docs/dev-log/handover/2026-07-12-arc2a-claude-handover.md)
>
> **▶ Prior (2026-07-12, → Claude, missing-response arc COMPLETE).**
> `main` = `d06bf015` (synced) · tag **`v0.5.0`** remains frozen at `095409c0` ·
> CRAN remains a separate external decision. MR-T0–MR-T7 are merged through
> PR #771: all 18 fitted response routes have independent G3 missing-response
> evidence; the ledger/runtime oracle report 18 verified / 0 G0–G2; local full
> test, genuine `--as-cran`, pkgdown, three fresh reviews, final-main 3-OS CI,
> final sanitizer matrix, live Pages, and issue #761 closeout are complete.
> G4/G5, MNAR, response-plus-`mi()`, non-Gaussian
> REML, and blanket random/structured support remain outside the claim. START
> HERE:
> [`docs/dev-log/handover/2026-07-12-claude-handover.md`](docs/dev-log/handover/2026-07-12-claude-handover.md)
>
> **▶ Prior — (2026-07-12, → Codex, missing-response implementation 18/18; MR-T7 active).**
> `main` = `843f276f` (synced) · tag **`v0.5.0`** remains frozen at `095409c0` ·
> CRAN resubmission is awaiting an external decision. MR-T0–MR-T6 are merged
> through PR #770: all 18 fitted response routes have independent G3
> missing-response evidence and the live oracle reports 18 verified / 0 G0.
> This is not G4/G5, REML, MNAR, response-plus-`mi()`, or blanket
> random/structured support. **Only MR-T7 certification remains:** full local
> test/document/`--as-cran`/pkgdown, three fresh reviewers, closeout PR,
> final-main 3-OS CI, clang-ASAN/clang-UBSAN/GCC-ASAN, live Pages, issue #761,
> handover, and tracked-clean synchronized `main`. START HERE:
> [`docs/dev-log/handover/2026-07-12-missing-response-arc-closeout.md`](docs/dev-log/handover/2026-07-12-missing-response-arc-closeout.md)
>
> **▶ Prior — (2026-07-11, → Claude, drmTMB 0.5.0 first-CRAN-release SHIPPED; R-hub blocker).**
> `main` = `97ba0042` (synced) · tag **`v0.5.0`** = `09d44c7c` · tag CI **GREEN 3-OS** · **NOT on CRAN yet**.
> Missing-data non-Gaussian arc (P0–P5) COMPLETE; release-eng portability gate closed
> (`skip_fragile_recovery()` greened the red tag; `TMB(>=1.9.6)`/`Matrix(>=1.6.0)` floors; ROADMAP fix).
> **Live blocker: R-hub `valgrind` + `rchk` FAILED** (run 29156817171) — investigate real-vs-noise
> before `submit_cran()` (maintainer's call). win-builder R-release+devel submitted (emails pending).
> Next arc (post-CRAN): missing-RESPONSE masking → ALL families; pigauto↔drmTMB MI bridge for
> predictors; DROP broad predictor catalogue + bivariate mi(). START HERE:
> [`docs/dev-log/handover/2026-07-11-claude-handover.md`](docs/dev-log/handover/2026-07-11-claude-handover.md)
>
> **▶ Prior — (2026-07-08 night, → Claude, board HONEST + Ayumi-derived work queued).**
> `main` = `15d4412b` (pushed) · tag `v0.2.0.9001`. **The 8 `inference_ready` cells are CORRECT — do
> NOT demote them.** An initial "5/8 FAIL" audit applied the `supported` bar (nominal-exact) to the
> `inference_ready` tier; at small `g`, ~0.90 coverage + upper-tail skew is EXPECTED, not a defect
> (banked; re-confirmed N=600: g8 profile ~0.91). Two-tier gate now enforces it
> (`tools/gate-inference-ready.R` + `-driver.R`; all 8 `inference_ready=PASS`, `supported=no`).
> **Ayumi's 48 GB `sdreport()` ceiling is FIXED and validated at her 10,440-tip scale** (`se_group_sd`
> opt-in default). Next mission (all LOCAL, no Codex): #16 fix `phylo_mu_diagnostics` false positive
> (`R/check.R:2554`), #18 point-6 inflated-SE-with-clean-`pdHess`, #17 Ayumi fixture test, #20 ML/REML
> doc, then C1 (REML provider unlock) + C2 (loc-scale-scale, off Ayumi's path). START HERE:
> [`docs/dev-log/handover/2026-07-08-night-claude-handover.md`](docs/dev-log/handover/2026-07-08-night-claude-handover.md)
>
> **▶ Prior (2026-07-08, → Claude, ML/REML parity COMPLETE; next arc = crosses→ticks).**
> Branch `drmtmb/biv-scale-side-reml` (pushed, 25 ahead of `main`, FF-mergeable). **Every combination
> ML fits, REML now fits** — no REML-without-ML, no ML-without-REML. Shipped: q2 matched mean+scale,
> block-diagonal biv location-scale, `sd(..., level=)` grammar (legacy `sd_phylo*` soft-deprecated),
> ordinary sigma REs (uni+biv), **dense q4 + biv mu-sigma cors + q>2 blocks**, and a new **C++
> correlated residual-scale slope block** (`sigma ~ x + (1+x|id)`). **Two prior verdicts OVERTURNED
> by evidence:** q2 "needs Cox-Reid" (small-N artefact) and dense-q4 "sign-flip" (under-powered-fit
> artefact — mapping proven correct; REML strictly beats ML there). Standing caveat: scale-side
> variance components need **within-group replication**; `pdHess` is a want, not a gate.
> **Next arc = turn every ✗ to ✓ on the q-series matrix.** Authority = the TSV
> (`docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`); **doc 210 is STALE**.
> Excluding the 9 `multiple_slope` rows (**two-slope DEFERRED per Shinichi**): **95 v1.0 cells —
> 94 fit, but only 8 interval-ready / 8 coverage-ready.** Fitting is done; **inference is the arc.**
> Target `inference_ready` ONLY — `supported` stays deferred (doc 218 §5: the biased-centre wall
> needs a research-grade bias-correction derivation). Workstreams: (c) interval campaign Track A1
> [already scoped + method-decided], (a) univariate labelled structured slope block, (b) non-Gaussian
> labelled/bivariate structured slopes. START HERE:
> [`docs/dev-log/handover/2026-07-08-claude-handover.md`](docs/dev-log/handover/2026-07-08-claude-handover.md)
>
> **▶ Prior (2026-07-06, → Claude, 104/104 CLOSED; intervals/coverage arc scoped + started).**
> The Q-Series is **closed at 104/104** on `main` (`6f3ca841`): row 87 admitted recovery-only
> (PR #736) + the cell_id rename & closure-triage reconciliation (PR #737); all 4 validators +
> full `devtools::test()` (36380) green. The **next arc — intervals + coverage +
> structured-covariance** — is approved + researched; **method DECIDED (Shinichi): profile-likelihood
> CIs are the star, one plain bootstrap fallback, `supported` DEFERRED (cap at `inference_ready`),
> BCa banked.** Track A1 (Gaussian profile extension) is the first slice — candidate cells
> identified, NOT yet spiked. START HERE:
> [`docs/dev-log/handover/2026-07-06-claude-handover.md`](docs/dev-log/handover/2026-07-06-claude-handover.md)
> (plan: [`docs/dev-log/2026-07-06-next-arc-ultraplan.md`](docs/dev-log/2026-07-06-next-arc-ultraplan.md);
> research: [`docs/dev-log/2026-07-06-arc-interval-method-research-memo.md`](docs/dev-log/2026-07-06-arc-interval-method-research-memo.md)).
>
> **▶ Prior (2026-07-05, → Claude, 104/104 arc: M1 done, start M2).**
> Started the Q-Series **94→104/104 completion arc** (ultra-plan:
> [`docs/dev-log/2026-07-05-qseries-104-completion-ultra-plan.md`](docs/dev-log/2026-07-05-qseries-104-completion-ultra-plan.md)).
> **M1 verdict: the covariance engine already works — no rewrite needed.** q4 all-four is
> clean at Santi-scale (n≥512: conv=0, pdHess=TRUE, rmse ~0.05); q8 recovers (rmse→0.116 at
> 1024 groups) but `pdHess=FALSE` persists (genuine weak-ID) → route q8 inference through
> **parallel profile + bootstrap** (ELR excluded); q8→pdHess=TRUE is a deferred reduced-rank-FA
> arc. The documented "q8 blocker" (doc 220) was a **data-size misdiagnosis** (36 params / 16
> groups). ⇒ Phase 2/3 are **parser admission + recovery-gating + profile intervals, not engine
> surgery.** Next: **M2 = q6 admitted (4 providers, recovery)**. Branch
> `drmtmb/fix-family-conventions`; draft PR #730 (94/104 + regression fix) unchanged, ubuntu CI
> green; Mission Control truth 94/104 / 8/104 / 0/104 / 10/104. START HERE:
> [`docs/dev-log/handover/2026-07-05-claude-m1-to-m2-handover.md`](docs/dev-log/handover/2026-07-05-claude-m1-to-m2-handover.md).
>
> **▶ Prior — (2026-07-05, → Claude, regression fix).** Draft PR
> #730's ubuntu CI revealed a **122-test regression** the branch carried (hidden
> by focused-tests-only runs). Root cause: two model-type-blind structured-RE
> naming changes from the q-series non-Gaussian admit work — `split_tmb_sdpars`
> switched the biv_gaussian branch to per-endpoint SD blocks (broke the flat-`$mu`
> q4/summary/profile/dashboard contract), and `structured_mu_random_effect_key`
> became endpoint-aware and renamed Gaussian `spatial_mu`->`spatial_sigma` (broke
> `ranef()`). **Fixed** (commits `ce4b8b97`, `e87ce23c`): both gated on model type
> — Gaussian/biv_gaussian keep flat `$mu`/generic `_mu`; non-Gaussian keep
> per-endpoint. Plus one stale nbinom2 rejection-message test. Full local suite
> green (122->0); ubuntu CI re-run on the pushed head — confirm green on #730.
> Mission Control truth unchanged (94/104 / 8/104 / 0/104 / 10/104). See
> [`docs/dev-log/after-task/2026-07-05-structured-re-gaussian-naming-regression-fix.md`](docs/dev-log/after-task/2026-07-05-structured-re-gaussian-naming-regression-fix.md).
>
> **▶ Prior — (2026-07-05, → Claude, Day 1 takeover).**
> Q-Series v1 practical-surface arc, Day 1-2 executed. Branch
> `drmtmb/fix-family-conventions` @ `0ce8b919`; **draft PR #730** open into
> `main` with a corrected 94/104 body. CI trimmed: routine `pull_request`/push
> runs `ubuntu-latest` only, 3-OS matrix on release tags (`v*`) + `workflow_dispatch`.
> Rose/Fisher/Ada/Grace release-candidate audit clean (no boundary violations;
> `inference_ready` recounted = 8). Last-ten triage: **0 finish-now, 10 post-v1**
> (all design/engine-blocked; q8 rows policy-barred). Truth unchanged: 104 rows,
> practical 94/104, inference_ready 8/104, supported 0/104, post_v1 10/104. No
> q4/q8 promotion, no new coverage, no REML/AI-REML expansion, no public-support
> wording; Julia optional/later. Pre-ready-for-review debt (Codex lane): local
> `--as-cran` + pkgdown + one 3-OS `workflow_dispatch` R-CMD-check. START HERE:
> [`docs/dev-log/handover/2026-07-05-claude-takeover-day1-handover.md`](docs/dev-log/handover/2026-07-05-claude-takeover-day1-handover.md).
>
> **▶ Prior handover (2026-07-05, → Claude).** Q-Series v1
> practical-surface checkpoint and multi-day takeover. The active branch is
> `drmtmb/fix-family-conventions`, pushed at
> `3262655f59c1da69eef1a1950a94ea1a6698eb33` after recovering exact Gaussian
> q2 scale-only point-fit/extractor rows for `spatial`, `animal`, and `relmat`.
> Current Q-Series v1 truth is 104 rows, practical v1 surface 94/104 (90.4%),
> Gaussian core 59/67 (88.1%), basic distribution recovery 35/37 (94.6%),
> exact `inference_ready` still 8/104, structured `supported` still 0/104, and
> post-v1 rows 10/104. This is not a full Q-Series completion claim: no q4/q8
> promotion, no new coverage authorization, no REML/AI-REML expansion, and no
> public-support wording. Product decision recorded: finish `drmTMB` as the
> primary R/TMB package first; keep `DRM.jl`/Julia optional and later, not
> required for v1. `gh` was unavailable in the shell, so the branch is pushed
> but draft PR creation may need the browser compare page. START HERE:
> [`docs/dev-log/handover/2026-07-05-claude-handover.md`](docs/dev-log/handover/2026-07-05-claude-handover.md).
>
> **▶ Latest handover — start here (2026-07-01, → Codex).** Q-Series Tranche 3 clean start.
> Tranche 2 is done and merged: PR #684 and PR #685 landed on `main`, with local
> `HEAD` and `origin/main` verified at `4d6d2339eb48`, no open drmTMB PRs, a clean
> worktree, `mission_control_ok`, and final-base R-CMD-check success for #685 on
> macOS/Ubuntu/Windows (`https://github.com/itchyshin/drmTMB/actions/runs/28492010510`).
> The current Q-Series support-cell truth is 104 rows, 8 interval/coverage
> `inference_ready` rows, 0 structured `supported` rows, 0 high-q
> (`q4`/`q6`/`q8`) `inference_ready` rows, and 0 non-Gaussian interval/coverage
> `inference_ready` rows. Do **not** claim the Q-Series is finished. The next
> work is Tranche 3: q4 admission before coverage, with Rose/Fisher/Gauss/Noether
> review before any status claim.
> START HERE:
> [`docs/dev-log/handover/2026-07-01-codex-handover.md`](docs/dev-log/handover/2026-07-01-codex-handover.md).
>
> **▶ Prior handover (2026-06-29, → Codex).** Q-Series evidence board continuation.
> The active branch is `codex/qseries-sigma-inference-ready` at local
> `HEAD=77b634ed` with a large dirty working tree. The 104-row support-cell widget is present
> and separates fit, interval, coverage, stability, recovery, diagnostic, blocked, and planned
> states. `tools/validate-mission-control.py` is green after the q2-plus-q2 local-smoke
> contract cleanup; Fisher/Rose signed off the next q2-plus-q2 smoke as a tiny
> Totoro/FIIA `n=5` run for only the six within-block targets, and also signed off
> the q2 intercept local-smoke gate for only the 12 q2 intercept targets. The
> q1 `mu` intercept rows also have Fisher/Rose-reviewed Totoro/FIIA `n=5` smoke
> contracts, but those rows remain `point_fit/planned/planned`. Do **not**
> claim the Q-Series is finished: only 5 rows are
> interval+coverage `inference_ready`; Gaussian q4/q6/q8, all q8, and all non-Gaussian
> interval/coverage claims remain unfinished. Nibi/Rorqual are reachable; the latest
> non-interactive host check found Totoro auth denied, no `fiia` alias, and reachable `fir`
> without a `drmTMB` checkout, so resolve host access/checkout before running either smoke.
> START HERE:
> [`docs/dev-log/handover/2026-06-29-codex-handover.md`](docs/dev-log/handover/2026-06-29-codex-handover.md).
>
> **▶ Prior handover (2026-06-28, → Codex).** Small-sample interval arc.
> The bias correction is now the **DEFAULT** for location-axis structured-RE SD targets:
> `confint(fit)` applies a t(g−1) width + a `+log(g/(g−1))` centre shift (simulation-calibrated,
> ~2× the leading-order REML SD term — *not* "REML in closed form"). Engine-validated nominal
> coverage at the deployment default **g=8 (0.954, all four providers)**; **q2 mu-slope (phylo,
> relmat) promoted to `inference_ready`** (interval + coverage). `supported` is **withheld** —
> measured 6:1 right-tail miss asymmetry + g-dependence → a REML-unblock or skew-aware-interval
> arc. **Supersession note:** the old "15 commits at `9ae75bf1` are unpushed"
> warning is no longer current. The consolidation branch
> `claude/local-coverage-grids-sigma-q2` has been pushed, and the active Q-Series
> widget/status continuation is PR #685 from `codex/qseries-sigma-inference-ready`.
> Verify the current branch/head with `git status --short --branch` before editing.
> Run R with
> `R_PROFILE_USER=/dev/null Rscript --no-init-file` (the `.Rprofile` R-4.5 lib segfaults R 4.6).
> START HERE:
> [`docs/dev-log/handover/2026-06-28-codex-handover.md`](docs/dev-log/handover/2026-06-28-codex-handover.md).
>
> **▶ Prior handover (2026-06-27).** Q-series structured-RE completion lane.
> 4 PRs banked (draft, stacked): #675 (relmat-NB2, CI recorded) · #676 (count-sigma rejection) ·
> #677 (sigma-slope coverage scaffolding — **deploy-ready**) · #678 (non-Gaussian family
> rejection; q-series cells 90→98). q2-slope coverage runner verified-ready (MCSE fix pending);
> q4-location runner HELD (defects). Coverage execution is **maintainer-run on fir** (agent is
> exfiltration-blocked from transferring code to the cluster). See:
> [`docs/dev-log/handover/2026-06-27-claude-handover.md`](docs/dev-log/handover/2026-06-27-claude-handover.md).
>
> **▶ Prior handover (2026-06-14).** The Ayumi σ-phylo arc just closed
> (DRM.jl#289 REML on all four among-axis axes; drmTMB#542/#543; reply posted to
> `Ayumi-495/LS_ecogeographical-rules#2`). Rehydration anchor:
> [`docs/dev-log/codex-handover-2026-06-14-ayumi-arc-closeout.md`](docs/dev-log/codex-handover-2026-06-14-ayumi-arc-closeout.md).
> **Top open task: #544** (bridge-gate-drift audit + a gate-vs-engine CI guard; sister
> mirror gllvmTMB#488). **No CRAN.** Decisions pending the maintainer: DRM.jl#280, #270.

## Core Scope

- Support one-response and two-response models only.
- Use one formula per distributional parameter.
- Prioritize location, scale, shape, zero inflation, random-effect scale, and
  residual correlation.
- Higher-dimensional multivariate models belong to `gllvmTMB`, not `drmTMB`.
- Meta-analysis is Gaussian regression with known sampling covariance; do not
  introduce `meta_gaussian()` or `tau ~` syntax without an explicit design
  decision.
- `rho12` is the canonical residual bivariate correlation parameter. `rho` may
  become an alias later, but docs and tests should use `rho12`.
- Bivariate models should prefer separate response formulas (`mu1 = y1 ~ ...`,
  `mu2 = y2 ~ ...`). `mvbind()` is only shorthand for identical location
  formulas.

## Design Rules

1. Do not add a new family without simulation tests.
2. Do not add user-facing functions without roxygen2 documentation.
3. Do not change formula grammar without updating
   `docs/design/01-formula-grammar.md`.
4. Do not change likelihood parameterization without updating
   `docs/design/03-likelihoods.md`.
5. Do not add random effects before fixed-effect likelihoods are tested.
6. Keep pull requests small and focused.
7. Every meaningful change should update `docs/dev-log/check-log.md`.
8. Every completed task or phase should create an after-task or after-phase
   report following `docs/design/10-after-task-protocol.md`.
9. If code is ported from `gllvmTMB` or another package, document provenance in
   `inst/COPYRIGHTS` before treating the change as complete.

## Standard Commands

```r
devtools::document()
devtools::test()
devtools::check()
pkgdown::check_pkgdown()
```

## Recovery Checkpoints

For long Codex runs, stream failures, or handoffs, create a compact recovery
checkpoint before continuing:

```sh
Rscript tools/codex-checkpoint.R --goal "current task" --next "next command or edit"
```

The script writes a Markdown snapshot under
`docs/dev-log/recovery-checkpoints/` with git status, changed files, diff stat,
the newest check-log evidence, newest after-task reports, and exact commands for
the next agent to rerun. A checkpoint is only a handoff aid: repository state is
authoritative, so always rerun `git status` and `git diff` before editing.

## Definition of Done

A feature is done only when implementation, tests, documentation, examples,
check logs, after-task notes, and review are all present.

## Writing Style

For user-facing prose, developer notes, after-task reports, and release text,
write for a named reader and keep the prose concrete. The main readers are
applied ecology, evolution, and environmental-science users, plus statistical
method developers and R package contributors.

- Name the purpose before mechanics.
- Pair symbolic equations, R syntax, and interpretation when explaining models.
- Use concrete terms, files, equations, functions, or numerical results rather
  than vague phrases such as "various factors" or "significant improvements".
- Use active voice when the agent matters.
- Do not turn prose into bullets unless the content is a genuine list.
- Keep terms stable: `sigma`, `rho12`, `sd(group)`, `meta_V(V = V)`,
  `phylo()`, `spatial()`, `mu`, and `nu` should not drift across documents.
  Mention deprecated `meta_known_V(V = V)` only as a compatibility alias.
  Mention `tau` only when explaining a second shape parameter or when
  contrasting drmTMB's `sigma` with meta-analysis notation.
- Support factual, statistical, or literature claims with a citation, local
  evidence, or a clear note that the statement is a design assumption.
- Define location, scale, shape, and coscale at first use; connect coscale to
  residual correlation `rho12`.
- For tutorials and error-message docs, tell the reader what to try next when a
  model or syntax is unsupported.

Use the project-local `prose-style-review` skill for substantial README,
vignette, pkgdown, after-task, release, or paper-oriented text. This skill was
adapted from lessons in `yzhao062/agent-style`; do not copy that project into
this repository or add it as a package dependency without a separate decision.

## Multi-Agent Collaboration

Codex and Claude Code may both contribute to this repository. All agent work
must follow the same project rules:

- preserve the univariate/bivariate scope;
- avoid unreviewed likelihood or formula-grammar changes;
- update design docs when architecture changes;
- add tests with implementation;
- do not revert changes made by another agent or human unless explicitly asked;
- prefer small, reviewable commits or pull requests.

When an agent hands work to another agent, leave enough context in
`docs/dev-log/check-log.md` or the relevant issue/PR for the next agent to
continue without rediscovering the whole problem.

Claude Code should read this file first. It should not introduce a parallel
agent configuration system inside the package unless the project owner asks for
one.

The launchable team agents live in two mirrored directories: `.codex/agents/`
for Codex and `.claude/agents/` for Claude Code. The two sets are one-to-one and
share verbatim instruction bodies. When an agent is added or its instructions
change, update both directories in the same change so the runtimes do not drift.
Every standing review name below now has a launchable agent: the job-function
agents carry the named perspectives (Gauss = `tmb_engineer`, Curie =
`simulation_tester`, Rose = `systems_auditor`, Grace =
`reproducibility_engineer`, Jason = `landscape_scout`, Pat = `user_tester`), and
the review-only perspectives have dedicated files (Ada = `integration_reviewer`,
Boole = `formula_reviewer`, Noether = `math_consistency_reviewer`, Darwin =
`audience_reviewer`, Florence = `figure_reviewer`, Emmy = `architecture_reviewer`,
Fisher = `inference_reviewer`). These review agents are still launched only for
bounded tasks, not run continuously.

## Standing Review Roles

These names are shorthand for recurring review perspectives. They do not run
continuously; the orchestrator should launch them only for bounded tasks. Use
these canonical names when reporting team perspectives; do not rename them in
status updates or project notes.

| Name | Role | Primary questions |
| --- | --- | --- |
| Ada | Orchestrator and integrator | What should happen next, and are code, math, docs, tests, pkgdown, and git consistent? |
| Boole | R API and formula reviewer | Is the syntax memorable, parseable, and internally consistent? |
| Gauss | TMB likelihood and numerical reviewer | Is the likelihood correct and numerically stable? |
| Noether | Mathematical consistency reviewer | Do the symbolic equations, R syntax, and TMB implementation match exactly? |
| Darwin | Ecology/evolution audience reviewer | Does the example answer a real biological question for the target audience? |
| Florence | Scientific figure editor and visualization reviewer | Are plots publication-quality, interpretable, accessible, and honest about uncertainty? |
| Fisher | Statistical inference reviewer | Do simulations, comparator checks, likelihood profiles, and identifiability diagnostics support the claim? |
| Pat | Applied PhD student user tester | Can a new applied user follow the tutorial, interpret output, recover from errors, and avoid hidden jargon? |
| Jason | Landscape and source-map scout | What do related packages and papers already do, and what should `drmTMB` learn or avoid? |
| Curie | Simulation and testing specialist | Do recovery tests cover ordinary, edge, and malformed-input cases without becoming too slow? |
| Emmy | R package architecture reviewer | Are S3 methods, object structures, extractors, and internal APIs coherent? |
| Grace | CI, pkgdown, CRAN, and reproducibility engineer | Will this pass on all platforms, deploy cleanly, and avoid compiled-code or dependency risk? |
| Rose | Systems auditor | What discrepancies, repeated mistakes, stale wording, unsupported claims, and missing feedback loops are accumulating? |

Figure quality is shared work. Florence leads the final scientific-figure
standard, but Pat, Fisher, Rose, Darwin, Grace, Boole, and Noether should help
before a figure reaches her: they should notice missing uncertainty, wrong data
grain, unsupported-looking syntax, weak reader guidance, stale claims, failed
render evidence, and figures that are technically present but visually
unhelpful. Use the project-local `figure-visual-audit` skill when plots,
figure galleries, simulation graphics, or rendered pkgdown pages are under
review. A good figure should help users understand the model and help the team
catch wrong assumptions.

## Team Improvement Loop

When a task exposes a better way for the team to work, record it in
`docs/dev-log/team-improvements.md`. Low-risk documentation, process, and local
skill improvements can be implemented immediately. Product, architecture, or
validation-policy changes need a normal task, evidence, and review.

## pkgdown Policy

The pkgdown site is a first-class project artifact. User-facing features should
include reference documentation and, when substantial, an article or tutorial.
Keep `_pkgdown.yml` synchronized with exported functions and vignettes.

## Hermes Policy

Hermes is optional external lab orchestration. It is not a package dependency
and should not be installed inside this repository or required for development.

<!-- shinichi-hub -->
> Read first — personal operating contract & second brain (house rules, memory, agents): /Users/z3437171/Dropbox/Github Local/Shinichi/AGENTS.md  (repo rules override the hub where they differ)
<!-- shinichi-hub -->
> Read \`~/shinichi-brain/AGENTS.md\` first; this repository's rules override the personal hub where they differ.

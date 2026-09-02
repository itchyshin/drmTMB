# Coordination Board — drmTMB

Pointer for humans and agents. Detailed lane rows live in
[`active-lane-split.md`](active-lane-split.md). Do not treat this board as a
census; capability counts belong in the ledger and Mission Control.

## Active Lane Split
- **2026-09-01 (evening) — Claude parity lane HANDED OVER to a fresh Claude session.**
  START HERE for this lane: [`handover/2026-09-01-claude-handover-575-fixed.md`](handover/2026-09-01-claude-handover-575-fixed.md).
  #575 FIXED (exact REML gradient; DRM.jl PR #579 draft; suite 9203/0/0; D-43 panel verified).
  Three reviews await Shinichi: drmTMB #1112, DRM.jl #579, DRM.jl #576. Promotion wave 1 (4 rows)
  fires on the #1112 merge; q4 stays out pending an SE-axis receipt. Other lanes keep their own
  pointers above/below — this entry does not represent them.
- **2026-09-01 (later) — Arc P1 plateau checkpoint (SUPERSEDED same evening: the "basin selection" diagnosis below was itself FD-gradient noise; #575 was fixed by the exact REML gradient — see the entry above).**
  Mechanism proven three ways (receipts in `evidence/julia-r-parity/ayumi-target/2026-09-01-matched-q4/`):
  DRM.jl's own objective at the TMB point beats its solver's result; polish/multistart shave ≤0.006 and
  violate the gradient contract (reverted, not shipped — regressed #484); warm-started AT the TMB point the
  same solver reaches −219.6034, better than TMB's −219.6140. Branches pushed: `fix/575-q4-optimum`
  (test-first, @test_broken pin, no src change), `feat/575-objective-at` (diagnostic evaluator, TDD).
  Rose V2 verified 7/8 and her one demote (durable evidence paths) is applied. Latent cache-corruption
  hazard documented on #575. Prepared and GATED: bridge-promotion wave 1 (4 receipt-verified rows →
  partial) awaiting #1112 merge; reverse-parity lane brief committed for the new Claude drmTMB lane.
  Basin-selection over the warm start was then ATTEMPTED (K=5 incl. structured Λ0, cheap pre-screen) and PLATEAUED twice more: candidates re-find the same basin (Δ 7e-5, within noise) or violate the engine-level g-contract (0.0026 > 1e-3); src reverted both times (receipts: p12a-basin-summary.md). Sharpened hypothesis: certifying convergence in the better basin needs the exact REML gradient (the mode-finder converges on FD-gradient grounds, and run noise ~1e-3 sits AT g_tol) — a derivation-level slice, not a solver tweak. The owner said keep going: the exact-REML-gradient slice then ran (Opus, derivation-first) and FIXED #575 — DRM.jl PR #579 (draft), exact-vs-FD ≤6.2e-8, both routes at −219.6140 (2e-5 from TMB), bridge re-measure GATE-PASS on coef/logLik (1.9e-05/1.7e-04), full suite 9203/0/0 with the new tests wired, D-43 panel verified with its two blockers fixed. SE axis unmeasured — q4 stays out of promotion wave 1; coverage fence stands. Follow-ups: DRM.jl#577 (ML-path gradient degeneracy), #578 (missing-response mask consistency).
- **2026-09-01 — R–Julia true-parity programme lane is active in Claude (Fable), continuing
  `codex/rebase-julia-optimizer-controls` per the 2026-09-01 handover.** Landed on the branch:
  Ayumi reply DRAFTS (unsent — 205 gate holds), matched-control q4 fixture receipts
  (`evidence/julia-r-parity/ayumi-target/2026-09-01-matched-q4/`), and a frozen-manifest programme
  re-estimate (`plan/2026-09-01-parity-programme-estimate.md`, ~92–159 agent-h replacing the
  un-receipted 157–297). Findings of record: the handover's "inconclusive" q4 fixture run HAD
  completed; the matched re-run reproduces |Δ logLik| ≈ 1.6e-2 and diagnosis shows TMB at the
  better optimum, g_tol-insensitive → **DRM.jl#575** (blocks q4 bridge promotion). Ayumi's exact
  343-tip subset recipe located (deterministic, `R/51_batch_clade_revised_spec.R`). Public
  scoreboard page opened on DRM.jl branch `docs/drmtmb-parity-scoreboard`; Parity Standing artifact
  + Mission Control refreshed. No reply posted, no release motion, no campaign launched.
- **2026-08-19 — exact 0.7.0 evidence closeout is active in Codex.** Final
  immutable candidate: source `6170fbeeea65f22444d7b0934f4e808c40744d22`,
  SHA-256 `1d6445db583d4e4586d177ce9a6ada78b27373e104a2f6754926b61a188ed9f3`,
  4,368,396 bytes. Exact-byte local and three-arm win-builder checks pass;
  exact-source 3-OS CI and sanitizers pass. Grace, Rose, and Pat are READY and
  the executable ledger proves `submission-ready`. PR #1076 merged its
  build-excluded evidence as `7fd86d031`; the real Ubuntu release job then
  passed. No candidate rebuild is required. The
  complete packet is
  [`release/0.7.0-cran-gate/candidate-6170fbeee/`](release/0.7.0-cran-gate/candidate-6170fbeee/)
  and the ledger is
  [`release-audits/2026-08-19-070-cran-release-ledger-1d6445db.json`](release-audits/2026-08-19-070-cran-release-ledger-1d6445db.json).
  No submission is authorized; #1033 and `_julia_skip2_artifacts/` remain
  protected.
- **2026-08-18 — current-main 0.7.0 refreeze repair is active in Codex.**
  Shinichi selected current `main`; the exact `6b45164b…` candidate completed
  local, 3-OS, R-hub, and three-arm win-builder evidence, then failed the fresh
  panel as a final candidate. It is predecessor evidence, not the bytes to
  submit. Repair scope is limited to shipped release-identity contradictions,
  the still-excessive CRAN test lane, and governance sync;
  then cut new bytes and repeat the full ladder. **Superseded by the
  2026-08-19 final candidate above.** No `submit_cran()`, no
  submission on 19 August, and no #1033 or `_julia_skip2_artifacts/` changes.
- **2026-08-18 — #1072 MERGED; predecessor Ligges wait lane closed.**
  All three `5153ae7e…` Windows arms were filed as predecessor evidence; they
  do not certify the final candidate. The waiting claim is superseded. The
  original historical handover remains at:
  [`handover/2026-08-18-codex-handover.md`](handover/2026-08-18-codex-handover.md).
- **⚡ 2026-08-16 — PLATFORM MOVE: the authoring Claude session CLOSED; Shinichi is moving fully
  to CURSOR. Its automation loop (win-builder polling + the platform-clean cascade) died with it —
  the cascade is now a MANUAL checklist.** Two live lanes, each with its own Cursor handover;
  neither pointer covers the other:
  - **0.7.0 release lane** → [`handover/2026-08-16-cursor-handover-070-release.md`](handover/2026-08-16-cursor-handover-070-release.md)
    — **Cursor owns the win-builder → platform-clean unlock (2026-08-16).** R-devel filed and
    clean (`Status: 1 NOTE`, `winbuilder-devel.txt` + `00check.log`). R-release and
    R-oldrelease emails are **absent** from `itchyshin@gmail.com` (incl. Trash; positive
    control OK); both lanes **re-uploaded** at 14:47Z against immutable bytes
    (`winbuilder-reupload-2026-08-16.md`) — awaiting Ligges mail. `status_claim` stays
    `tarball-clean`; `platform-clean` advance remains PRE-AUTHORISED only when R-release +
    R-devel are filed clean and the gate passes; **submission remains withheld**. The QUIESCE
    below still stands until `external_logs` lands. Peer facts (not this lane's work): held
    test-guard `4699cf934` on `claude/eloquent-driscoll-521fa1` belongs to the **next**
    candidate; PR **#1050** merged shipped files during the quiesce (breach recorded;
    adjudication is Shinichi's). `DESCRIPTION` still reads `Version: 0.7.0` while `main` has
    drifted from `302ac2579` — **re-bump to `0.7.0.9000` awaits Shinichi's word** (do not bump).
  - **MSPL boundary lane** → [`handover/2026-08-16-cursor-handover-mspl-boundary.md`](handover/2026-08-16-cursor-handover-mspl-boundary.md)
    — S0+S1 complete on `claude/mspl-boundary-s0-s1`; **S2 gated** on design 256's two unchecked
    sign-off boxes (independent Noether + Fisher re-checks).
  - **THIRD lane, not this session's:** the interval-truth programme also handed to Cursor today —
    `origin/claude/cursor-handover-0816` carries
    `handover/2026-08-16-cursor-handover.md` (unmerged at this writing). That lane's pointer is its
    own; listed here so no split reader orphans it.
  - **Docs-only ADEMP freeze, not those lanes:** `cursor/mc0576-ademp-freeze` freezes
    `mc-0576` (ZO-beta ordinary `sigma` slope) at SD 0.45 / `n_each` 50 /
    `M ∈ {8,16,32,64}`. **Do not launch** coverage. Stays off #1033 / #1059 / #1060.
    Sheet: [`research/2026-08-16-mc-0576-zo-beta-sigma-slope-ademp-freeze.md`](research/2026-08-16-mc-0576-zo-beta-sigma-slope-ademp-freeze.md).
- **2026-08-16 — the `se = TRUE` PSOCK worker leak is NOT drmTMB's; stop chasing it.** (peer lane
  `claude/eloquent-driscoll-521fa1` @ `4699cf934`, held out of `main` under the quiesce — adds a
  `tests/` file.) The 2026-08-15 report did not reproduce: drmTMB has no cluster constructor in
  `R/`; the captured worker traced to a concurrent `pigauto` lane. Receipts:
  [`after-task/2026-08-16-se-path-worker-leak-nonrepro.md`](after-task/2026-08-16-se-path-worker-leak-nonrepro.md).
  Merge after the platform matrix completes.
- **⚠ 2026-08-15 (evening) — QUIESCE: the 0.7.0 re-freeze is IN PROGRESS (Shinichi: "merge all
  three PRs and start the re-freeze", after lifting BOTH D-93 and D-117 the same evening).**
  PRs #1039/#1041/#1042 are merged; the cut point is the `claude/07-freeze-3` merge on `main`
  (DESCRIPTION back to `0.7.0`). **Until the new candidate's platform matrix completes, do NOT
  merge to `main` anything that changes shipped files** (`R/ src/ tests/ man/ vignettes/
  NAMESPACE DESCRIPTION inst/ data/ NEWS.md`) — a post-cut shipped-file merge invalidates the
  candidate and forces another freeze (the exact failure the 2026-08-12 re-freeze notice
  documents). Docs-only merges under `docs/` are safe. Decision records:
  `docs/dev-log/release-audits/2026-08-15-d93-decision-reading-b.md` ·
  `…/2026-08-15-d117-discharge.md` · freeze lane: Claude, `claude/07-cran-ladder`.
- **2026-08-11 reassignment (Shinichi, in session):** the live 0.7 CRAN ladder is
  now owned by **Claude**, superseding the 2026-08-07 Codex-ownership line below.
  That reassignment covered lane ownership only.
  **Later the same day Shinichi authorised the merges**, and both landed on `main`:
  **#1000** (`5a225378d`, the CRAN-gate docs) and **#996** (`a3217da93`, the candidate
  freeze), which is what put `Version: 0.7.0` on `main`.
  **Still NOT authorised by any of the above:** advancing `status_claim` past
  `tarball-clean`, writing `platform-clean`, or uploading to CRAN. `platform-clean`
  additionally remains mechanically blocked — the release gate rejects the claim while
  `platform_matrix` and `external_logs` are absent, and win-builder has not run against
  the candidate.
- **Claude** — **owns the 0.7 CRAN ladder** (reassigned above). Also holds the prior
  interval-feasibility / D-117 lane; see handovers under `docs/dev-log/handover/`.
  Start here: [`handover/2026-08-11-070-gate-truth-handover.md`](handover/2026-08-11-070-gate-truth-handover.md).
  Optional GVA docs #937 remains open and non-blocking.
- **Codex** — ~~owns the live 0.7 CRAN ladder through `submission-ready`~~ **SUPERSEDED
  2026-08-11** by the reassignment above; the 2026-08-07 handover
  ([`handover/2026-08-07-codex-handover.md`](handover/2026-08-07-codex-handover.md)) is now a
  historical record of that lane, not a live claim. Codex still holds **#858** (Lane B E0) and
  **#955**; both are **PROTECTED FOREIGN** — do not push, clean, or reconcile them.
- **Cursor** — #946 win-builder adjudication **merged** (`5affb962b`). #945 closed. Receipts now
  on `main`; do not rewrite them. **Carried-over:** `cursor/handover-0807`,
  `cursor/07-tarball-clean` and `cursor/07-cran-readiness` are **unmerged** (2026-08-07) and each
  rewrites ~60 lines of *this* section. Read before merging, because they are **not** wholly in
  conflict with it: their version already retires Codex's CRAN-ladder claim and demotes Codex to
  Lane B E0, which **agrees** with this board. The single genuine conflict is ownership of the live
  0.7 slices — they say **Cursor**, this board says **Claude** per the 2026-08-11 reassignment.
  **Rebase, do not straight-merge:** a straight merge drops the reassignment and the merge record
  below. Resolving that one conflict is Shinichi's call (D-87), not a rebaser's.

## Current Rule
- One owner per subject across Cursor / Claude / Codex; hand off explicitly.
- Never stage from the dirty primary checkout on `claude/handover-freshness-0718`.
- Do not re-run Totoro under the closed 135-trace prereg; WITHHOLD cells stay PFR.
- Never claim `platform-clean` or CRAN-ready from local macOS `--as-cran` alone.
- Evidence ≠ ledger: ERROR-free win-builder does not auto-advance `status_claim`.

## Status
- **2026-08-11 — `origin/main` @ `aa76c2399`; `DESCRIPTION` is now `0.7.0`.** Rung unchanged:
  **`tarball-clean` proven, `platform-clean` unproven.** Merged today: **#1000** (the CRAN gate now
  names the live candidate), **#996** (candidate freeze + the 0.7.0 bump), **#1002** (NEWS stops
  claiming a CRAN release drmTMB has not had), **#1003** (all 42 open issues triaged — **0
  BLOCKING**), **#1006** (the one user-surface fix + four documented limits + C17 re-certification),
  **#1013** (CI receipts). Post-merge `R-CMD-check` and `pkgdown` on `aa76c2399` both **green**.
- **The candidate no longer matches `main`.** `NEWS.md` and today's source fixes are shipped files,
  so a **re-freeze is required before submission**. Recorded as
  `known_evidence_gaps.candidate_no_longer_matches_main` in the 0.7.0 ledger.
- **What actually gates the release — none of it engineering.** **D-93** holds 0.7.0, undischarged.
  **D-117** was re-run 2026-08-09 (400,000 attempts, pooled 0.9248, clearing `ss_floor(10)=0.918`);
  discharge is **RECOMMENDED, NOT DECIDED**. **win-builder is ABSENT** for the candidate. The rights
  re-review and the source-clean re-cut are owed before `submission-ready`.
- START HERE: [`handover/2026-08-11-070-gate-truth-handover.md`](handover/2026-08-11-070-gate-truth-handover.md).
  The 2026-08-07 Codex handover is historical.
- Superseded and kept for the record: 2026-08-08 morning verify — `origin/main` @ `5affb962b`
  (#946), rung `tarball-clean`, #942 / #941 / #946 merged, draft **#947** (do not auto-merge).

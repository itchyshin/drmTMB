# After-task: drmTMB 0.6.0 CRAN-RC gate — S8 D-43 panel (3 rounds) + S9 close-out

**Lane:** drmTMB_final (single continuous Claude Code lane, Phase 20). **Date:** 2026-07-20.
**Branch:** `claude/release-0.6.0-cran-rc` (pushed, tip `ded65071`).

## 1. Goal

Deliver the drmTMB 0.6.0 release candidate to the **tarball-clean + local-UBSAN** rung and run the
D-43 review panel on the frozen artifact (S8), then produce the rung report + manifest self-check +
after-task (S9), before opening the RC PR (S10, pauses at G4). This report covers S8 and S9.

## 2. Implemented (the RUNG REPORT)

**Proven rung: TARBALL-CLEAN + LOCAL clang-UBSAN.** NOT "ready", NOT platform-clean, NOT submitted.

- **Final frozen artifact:** `~/worktrees/drmTMB-rc-frozen/9ca4d07ca403b6c2/drmTMB_0.6.0.tar.gz`
  — sha256 `9ca4d07ca403b6c20d21b00759af1231ffaca988f3f8170467f68da485662602`, 6980912 bytes,
  source commit `74bdb37c`, 825-entry inventory (forbidden-path scan clean).
- **`R CMD check --as-cran --run-donttest`** (NOT_CRAN unset): **Status 1 NOTE** (new-submission) +
  installed-size INFO 27.8Mb; **0 errors / 0 warnings**.
- **CRAN-lane proof:** `cran-lane-testthat.Rout` = `FAIL 0 | WARN 52 | SKIP 122 | PASS 12011`,
  reproduced **byte-identically across all three re-freeze rounds**; heavy phase18/structured-re-conversion
  suites skip-gated (absent from the CRAN lane); incoming feasibility ran (New-submission NOTE) → the
  real lane, not a NOT_CRAN cheat.
- **Dev-mode corroboration:** `devtools::test(filter="phase18|structured-re-conversion-contracts",
  invert=TRUE)` = `FAIL 0 | WARN 62 | SKIP 24 | PASS 13476`. This legitimately EXCEEDS the CRAN-lane
  12011 because `devtools::test()` sets `NOT_CRAN=true` (skip_on_cran tests run) — a "zero hidden
  failures" corroboration, **NOT a scalar match** to the CRAN lane. (Round-1's handover had loosely
  described the invert count as "12011"; this report corrects that to the mode-aware truth.)
- **Local clang-UBSAN:** 0 runtime errors on the six `(int)asDouble()` casts. Carried forward from the
  round-1 probe — valid because `src/` is byte-identical across every round (`git diff 091d0a13 74bdb37c
  -- src/` empty; only vignette prose ever changed).
- **Install smoke:** temp-lib install of the frozen tarball + correct-API extractor exercise → PASSED
  (SMOKE_EXIT=0).
- **`cran_release_gate.py`** on the ledger = **READY FOR CLAIMED RUNG** (tarball-clean), with the D-43
  panel votes recorded.

**Declared NEXT gates (out of this lane):** the REMOTE platform matrix (win-builder R-release/R-devel;
R-hub UBSAN·valgrind·rchk; 3-OS GitHub) and the CRAN submission (G6). 0.5.0 was ditched → 0.6.0 is a
first/new submission.

## 3. The S8 D-43 panel — three rounds (the panel worked)

Default NOT-READY; two NOT-READY withhold. None of the findings across any round was a package/C++
regression — every one was a release-surface honesty defect.

- **Round 1** (artifact `afd4600a`): **3× NOT-READY → rung WITHHELD.** (1) frozen `install-smoke.log`
  ended `SMOKE_EXIT=1` from an **ad-hoc** `round(coef(fit)[1],3)` line (`coef.drmTMB(dpar=NULL)` returns
  a named list, not a flat vector; the canonical `tools/install-smoke.R` has no such call) — yet the
  handover/ledger called it "PASSED"; (2) `ROADMAP.md` still recommended **v0.5.0** + showed
  `0.6.0.9000`; (3) `cross-family.Rmd` table over-promised the Julia xfam extractors. Shinichi approved
  a **full fix + one re-freeze**.
- **Round 2** (artifact `e818e165`, commit `00ec3914`): **Grace READY, Rose READY, Pat NOT-READY.**
  Only 1 dissent (below the 2-vote threshold) — but the rung was **NOT taken**, because Pat was right:
  the round-1 cross-family fix had patched only the extractor *table cell* and left two *prose* passages
  (`:199-203` "fitted values", `:292-295` "bring the fitted means back to R") still asserting the same
  over-promise. **Honesty over vote math.** Rose also flagged two stale pointers (policy-consult note;
  the mission-control dashboard).
- **Round 3** (artifact `9ca4d07c`, commit `74bdb37c`): swept the *whole* vignette (Rose principle) and
  removed **both** prose over-promises + added honest hedges pointing to the native `engine="tmb"` path;
  fixed Rose's two stale pointers. **Pat (fresh) READY**; Grace/Rose = their round-2 READY plus the
  round-3 delta orchestrator-verified (Shinichi opted to skip re-dispatch — every Grace/Rose checklist
  item was independently machine-verified on the final artifact). **Outcome: 3× READY, rung MET.**

## 3a. Decisions and Rejected Alternatives

- **Re-freeze scope (Shinichi):** chose full-fix + re-freeze over deferring the cross-family fix as a
  logged follow-up. Rationale: the whole lane exists to ship an honest surface; a known contradiction in
  a shipped vignette is exactly what to fix, and the re-freeze is the plan's own foreseen rollback.
- **Did NOT take the rung on the round-2 2-1 vote.** The withhold threshold is a floor, not a licence to
  ship a correct single dissent's defect.
- **UBSAN carried forward, not re-run.** `src/` byte-identical across rounds → the sanitizer result is
  for identical compiled code; re-running would add nothing. Recorded with explicit provenance.
- **Pat's 3 round-3 items → follow-ups, not a 4th re-freeze.** Pat marked them non-blocking; the primary
  reader surface (the vignette) is now fully consistent. See §10.

## 4. Files Touched (this arc)

Shipped/tarball surface: `vignettes/cross-family.Rmd` (the only tarball-affecting change — prose only).
Non-tarball surfaces: `ROADMAP.md`, `cran-comments.md`,
`docs/dev-log/release-audits/2026-07-20-0.6.0-release-scope-manifest.md` (§0 + basis + #710 factual
corrections), `docs/dev-log/release-audits/2026-07-20-cran-policy-consult.md` (frozen-evidence pointer),
`docs/dev-log/handover/2026-07-20-cran-rc-s3-to-g3-handover.md` (install-smoke correction),
`docs/dev-log/release-audits/2026-07-20-0.6.0-cran-rc-ledger.json` (artifact + evidence + panel).
Commits: `00ec3914` · `231c3306` · `74bdb37c` · `ef9fd358` · `ded65071`.

## 5. Checks Run

- 3× `R CMD build` + `R CMD check --as-cran --run-donttest` (NOT_CRAN unset) → each 0/0/1 NOTE + size INFO.
- 3× CRAN-lane count `PASS 12011` (identical); 2× dev-mode invert `PASS 13476` (FAIL 0).
- 3× install-smoke via a correct-API driver → SMOKE_EXIT=0.
- Local clang-UBSAN: 0 runtime errors (carried forward; src byte-identical, verified by empty `git diff`).
- `cran_release_gate.py` → READY FOR CLAIMED RUNG (tarball-clean) with panel votes.
- Manifest 7-field self-check (Noether, S9): the literal `git diff 919a0b3a..HEAD` on the manifest touches
  only the version reconciliation, the basis header, and the #710.5→past/#710.2-open factual corrections —
  **no estimator / interval / tested-domain / evidence-tier / negative-space field, no tier count, and not
  the zero-one-beta claim** changed. **Ceiling intact; nothing moved.**

## 6. Tests of the Tests

The CRAN-lane vs dev-mode count divergence (12011 vs 13476) was itself interrogated rather than
smoothed over: traced to `devtools::test()`'s `NOT_CRAN=true` and `skip_on_cran()` semantics, and recorded
as expected — a guard against the round-1-style "matching scalar" over-claim.

## 7a. Issue Ledger (follow-ups — G2, propose-first; do NOT fix inline)

Carried from the plan: function-level worm/qq figure fix; `coef()` doc; animal-models h²; **Julia xfam
extractor gap** (draft `scratchpad/xfam-extractor-issue-draft.md`); README ledger-jargon trim;
phase18-simulation-grid.yaml (D-50); #59; #61 (kept OPEN); #710.2. **New from Pat round-3:** (a) a NEWS
entry for the xfam-doc fix; (b) an xfam-subclass caveat on `man/predict.drmTMB_julia.Rd`; (c) a direct
README link to `capability-and-limits`. Fold (b)/(c)/xfam into one issue.

## 8. Consistency Audit

README / NEWS / ROADMAP / `_pkgdown.yml` / cran-comments / manifest / capability-and-limits all now agree:
Version `0.6.0`, v0.5.0 not a supported install target, first submission, platform-matrix future-tense,
zero-one-beta fenced generator-qualified. The three frozen dirs (`afd4600a`, `e818e165`, `9ca4d07c`) carry
SUPERSEDED / FREEZE-NOTES markers so exactly one current candidate is identifiable.

## 9. What Did Not Go Smoothly

The cross-family fix took **two passes** (round 1 patched the table cell, missing two prose siblings in
the same file). This is the Rose-principle failure mode: fixing one instance without grepping for the rest.
Pat's round-2 dissent caught it; round-3 swept the whole vignette. Net cost: one extra re-freeze
(~12 min local) that a first exhaustive grep would have avoided.

## 9a. Zero-one-beta (mc-0575) — carried, not re-opened

Ships as the fenced **generator-qualified**, `inference_ready_with_caveats`, ML-only, no-Wald/no-point-bias
claim (2-1 promotion split; Noether WITHHELD). Not re-run, not re-opened — no compute. Unchanged by this arc.

## 10. Known Residuals

Pat's 3 non-blocking follow-ups (§7a). All four known limitations (corpairs rho12 #802; sd_hat-NA; #710.2;
Julia xfam NULL) remain discoverable + honest on `capability-and-limits.Rmd`. Compiler dead-store warnings
(unused `sigma_i` ×10 etc.) are pre-existing, not check-forced → a follow-up cleanup, not this lane.

## 11. Team Learning

When a review finds one instance of a class of defect, grep the whole file/surface for its siblings
**before** re-freezing — otherwise the panel bounces it and you pay another rebuild. A single dissent that
is *correct* withholds the rung regardless of the vote count.

## 12. Cross-Product Coverage

Only `drmTMB` touched. No gllvmTMB, no `Github Local/`. No compute (G5). Vault (local-only, D-37) updated:
LOOP checkpoint + Mission Control dashboard.

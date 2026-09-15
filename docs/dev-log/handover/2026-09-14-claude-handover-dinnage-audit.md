# Session handover: Claude → next Claude session — Dinnage audit, after the second arc

**From:** Claude (Fable orchestrating), 2026-09-14.  **Branch:** `claude/audit-dinnage-wave1-20260913`
in `/Users/z3437171/local-scratch/lanes/drmTMB-audit-dinnage-wave1`, pushed to draft PR #1361
(head `666c1865a` at the first push of this arc; later commits listed below).  **Supersedes**
`2026-09-13-claude-handover-dinnage-audit.md`, whose four OWED items this arc paid.

## Critical context

Every finding of Russell Dinnage's evaluation is an issue (#1306–#1360, label `audit-dinnage`); the
map is `docs/dev-log/audits/2026-09-13-dinnage-independent-evaluation-response.md`. This arc's record
is `docs/dev-log/after-task/2026-09-14-dinnage-audit-wave3.md` (read it before anything else) and the
review file `docs/dev-log/audits/2026-09-14-dinnage-wave3-review.md` (six fresh-context Opus reviews;
every diff has a verdict). Decisions: D-266 (S3 = document the log-scale MAP), D-267 (M4 mask
confirmed), and the routing rule "Fable is never a parallel child" in the vault's MODEL-ROUTING.

**Two review verdicts changed code after the push.** Fisher rejected clamping `predict_parameters()`
endpoints (coverage 0 at saturated rows) — replaced by `NA` + `clamp_limited` (`e86359fe2`,
accepted with wording changes, applied in `1540d95fe`). Fisher then rejected `4ae2f5d99`'s
measured-diagonal check because it inverted the whole tips-plus-nodes precision and so refused
`phylo()` on sigma alone (tip diagonal is exactly 1) — the repair (tip-row indexing, three-direction
tests, and refusing the marginal residual variance on a clamp-active fit with reason `clamp_limited`)
landed as `1c44d2f12` (NEWS `a16ce24b6`): tip-row diagonal measured, three-direction tests, marginal
residual variance refused with reason `clamp_limited` on a clamp-active fit. Its fresh Opus review and
the third clean-export as-cran were running when this handover was last edited; see Landing state.

## What was accomplished (commits on the branch, oldest first)

`fc461aae4` M1 eleven sites · `0526baa2f` M2 · `d44a495be` S3 help page · `37b5d7ce6` notes 274/275 ·
`3192db3f6` S2b · `2a5b0665e` M2 follow-up (half rejected) · `e86359fe2` M2 follow-up 2 ·
`4ae2f5d99` S2b follow-up (rejected, repair pending) · `d61f65183` residual_sd clamp consistency +
Rd links · `b49ce9f70` zi-nbinom2 contract + `.Rbuildignore` · `1540d95fe` NEWS + clamp_limited docs ·
`666c1865a` check-log · after-task `ee0f9d60c`. `R CMD check --as-cran` on a clean export of
`d61f65183`: 0 errors, 0 package warnings, 1 NOTE (new submission).

## OWED next steps (in order)

1. **Close the S2b follow-up-2 review**: read the "### S2b follow-up 2 (1c44d2f12)" section of the
   review file (if absent, the review did not finish — dispatch a fresh Opus Fisher on `1c44d2f12`);
   apply any REQUIRED items red-first; confirm the third clean-export as-cran result
   (`scratchpad/ascran3/check.log` if the session survived, else re-run
   `NOT_CRAN=false R CMD check --as-cran --no-manual` on a `git archive` export); push.
2. **Post the five issue comments** (pre-authorised by Shinichi's G0 envelope; drafted at
   `docs/dev-log/issue-drafts/2026-09-14-dinnage-wave3/` for #1307, #1308, #1312, #1315, #1301) —
   re-read #1301's draft against the repaired S2b code first.
3. Fill the last after-task markers (Fisher S2b follow-up-2 verdict, Melissa path) and the ledger's
   `REVIEW:G-R-2`.

## Recorded, not fixed (candidates for a third arc; none blocks the PR)

- Gaussian latent `mi()` route weight invariance (`mi_family == 0`, `has_mi2`): observed rows are a
  one-line change; missing rows need a design (exact Gaussian marginal, then weighted).
- Tweedie imputation model's start-value-frozen quadrature support (silent truncation risk; a
  `cli_warn` when the fitted scale outgrows the support is the cheap detector).
- Raw-predictor consumers still unaligned with the clamp: `profile()` response-scale sigma, the
  Julia-bridge scale target, `summary_parameter_delta_derivative()`, `check_drm()`'s clamp detector
  (never reads a modelled `sd(group)` scale).
- Variance-ratio accessors' Wald interval covers 0.910/0.928, not 0.95 (predates this arc).
- S6 code (basic/BC bootstrap intervals opt-in) and its Totoro pre-run (design 274 §7); S3 option B
  campaign (D-266); Eq 4 latent-scale support for non-Gaussian families (design 275, feature decision).
- The Moderates/Minors #1316–#1360.

## Do not

Merge or release; touch the 071 lane (PR #1304); message Russell; spawn a Fable child; run campaigns.

## How to resume

```sh
cd /Users/z3437171/local-scratch/lanes/drmTMB-audit-dinnage-wave1 && git pull && \
  ~/shinichi-brain/tools/lane_preflight.sh . && cat LOOP/checkpoint.md
```
Toolchain: R 4.6 (arm64), TMB compiled `.so` in `src/` (recompile ≈ 30 s here via `pkgload::load_all`);
`NOT_CRAN=false R CMD check --as-cran --no-manual` on a `git archive` export is the check of record.
Never stage `.unlazy/`, `LOOP/notes/`, or scratch files. Ledger: `.unlazy/dinnage-2/` (git-excluded).

## Landing state

CARRIED-OVER: `claude/audit-dinnage-wave1-20260913` · draft PR #1361 · why: the S2b follow-up-2 repair `1c44d2f12` is committed but its fresh Opus review and third as-cran were still running at handover time, and the five issue comments are drafted (posting pre-authorised); merge awaits Shinichi · resume: `cd /Users/z3437171/local-scratch/lanes/drmTMB-audit-dinnage-wave1 && git pull && cat docs/dev-log/handover/2026-09-14-claude-handover-dinnage-audit.md`
FINDING-OF-RECORD: a "single choke point" is a hypothesis to measure, not a plan line — M2 had four surfaces and one repair was rejected at measured coverage 0  vault-note: [[journal/2026-09-14]]
FINDING-OF-RECORD: the unlazy checker matches EXPECT literally; regex gates never pass  vault-note: [[journal/2026-09-14]]

---
Read AGENTS.md and docs/dev-log/handover/2026-09-14-claude-handover-dinnage-audit.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.

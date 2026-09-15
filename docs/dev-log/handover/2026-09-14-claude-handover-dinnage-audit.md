# Session handover: Claude → next Claude session — Dinnage audit, after the second arc

**From:** Claude (Fable orchestrating), 2026-09-14.  **Branch:** `claude/audit-dinnage-wave1-20260913`
in `/Users/z3437171/local-scratch/lanes/drmTMB-audit-dinnage-wave1`, pushed to draft PR #1361
(head `666c1865a` at the first push of this arc; later commits listed below).  **Supersedes**
`2026-09-13-claude-handover-dinnage-audit.md`, whose four OWED items this arc paid. **Rewritten 2026-09-15 after the merge:** §OWED is PAID and §Landing state is LANDED; read those two sections first.

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

## Next steps: none owed (the 14 September OWED list was PAID; section rewritten 2026-09-15)

The three items this section listed on 2026-09-14 were paid by the same lane later that day and on the
15th, and this section was rewritten so that a reader is not sent to redo them:

1. **S2b follow-up-2 review — closed.** Fisher's fresh-context review of `1c44d2f12` (ACCEPT-WITH-CHANGES)
   and of its repair `19849f0dc` (ACCEPT-WITH-CHANGES; two stale comment sentences, applied in
   `e2d41def9`) are in `docs/dev-log/audits/2026-09-14-dinnage-wave3-review.md` under
   `### S2b follow-up 2` and `### S2b follow-up 3`. Clean-export `R CMD check --as-cran` runs 3 and 4
   (on `a16ce24b6` and `19849f0dc`): 0 errors, 0 package warnings, 1 NOTE.
2. **Five issue comments — posted.** #1307, #1308, #1312, #1315 at 2026-09-15T03:44Z; #1301 at 04:04Z
   (<https://github.com/itchyshin/drmTMB/issues/1301#issuecomment-5674554700>).
3. **After-task markers and `REVIEW:G-R-2` — filled.** Addendum in
   `docs/dev-log/after-task/2026-09-14-dinnage-audit-wave3.md`; ledger 27/27; Melissa row
   `docs/dev-log/plan-actual/2026-09-14-dinnage-wave3.md`.

**And the CI red that followed (2026-09-15).** Every wave-3 push failed the four `ubuntu-latest (release)`
shards for one cause: the capability-ledger validator pins the `R/methods.R` blob for `mc-0568/0569/0576`,
and eight audit commits (`0526baa2f` … `e2d41def9`) changed that file after the 13 Sep recert — "stale,
not wrong", in the validator's own words. Recertified the prescribed way in `1410c27f8` (runner re-run,
three TSV rows repointed, `source_fingerprint` untouched; the new receipt's graded fields are
byte-identical to the 13 Sep receipt). CI run 34965581817 on `c612ee284`: ledger step passed.

**Then shard 1 of the recert run (34965581817) failed on three tests** — not the ledger: the S2
phylo-on-sigma fixture (20 tips × 8, true omega 0.4) returned `convergence = 1` on the Linux runner
(locally it needed the "careful" optimizer escalation), and `test-dinnage-audit-s2.R`'s
`skip_if_not_installed("ape")` sites were missing from `inst/extdata/env-skip-census.tsv`. Fixed
tests-only in `6d63da083`: fixture re-sized to 30 × 12, omega 0.6 (first preset converges, max
|gradient| 1.7e-9, interior estimate; assertions unchanged) and the census re-derived with
`tools/write-env-skip-census.R`. CI run 34968481794 on `6d63da083` green; merged as 8195b1215
under Shinichi's instruction "merge #1361 when green" (`tools/pr_merge_when_green.sh`).

**Rule carried forward:** any branch that edits `R/methods.R` or `R/drmTMB.R` trips the same check and
needs `tools/recertify-c17.py` run LAST before its receipt (DECISIONS, C17 note); making that blob pin
robust is a design question, not a workflow bug.

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

LANDED: `claude/audit-dinnage-wave1-20260913` · PR #1361 merged as 8195b1215 on 2026-09-15 · CI run 34968481794 green on `6d63da083` · nothing carried over from this handover. Open gates are Shinichi's alone: whether to send Russell the response map (`docs/dev-log/audits/2026-09-13-dinnage-independent-evaluation-response.md`), and whether to open a third arc from the "Recorded, not fixed" list above.
FINDING-OF-RECORD: a "single choke point" is a hypothesis to measure, not a plan line — M2 had four surfaces and one repair was rejected at measured coverage 0  vault-note: [[journal/2026-09-14]]
FINDING-OF-RECORD: the unlazy checker matches EXPECT literally; regex gates never pass  vault-note: [[journal/2026-09-14]]
FINDING-OF-RECORD: a paid OWED list must be rewritten in place — left standing, it sent the next session to redo finished work; and `lane_preflight` cannot see a sibling Claude session's in-flight run in the same worktree (probe `list_sessions` + `pgrep`)  vault-note: [[memory/LESSONS]] (2026-09-15)

---
Read AGENTS.md and docs/dev-log/handover/2026-09-14-claude-handover-dinnage-audit.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.

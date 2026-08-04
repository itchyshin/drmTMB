# Plan vs actual — Prong B Tier 1: open the profile fences in `R/profile.R`

Reconciler: Melissa · Sonnet 5 · 2026-08-03.

**Plan:** `~/.claude/plans/snug-sleeping-river.md` ("Ultra-Plan — Prong B Tier 1"). **Actual:** worktree
`/private/tmp/drmtmb-prongb`, branch `claude/prong-b-tier1`, `HEAD = origin/main = 25768833b` exactly
(no commits made — confirmed via `git rev-parse HEAD`/`git rev-parse origin/main`), all work
uncommitted. A second worktree, `/private/tmp/drmtmb-s3` (detached HEAD, same base), carries the S3/S4
evidence trail; its four edited test files are byte-identical to the copies now sitting in
`drmtmb-prongb` (`diff -q` on all four, zero differences) — the cross-worktree sync held.

## Verdict

The arc delivered what the plan promised, inside the stated scope, with receipts that mostly reproduce
exactly against raw logs and TSVs I re-derived independently rather than trusted. Every number I checked
against a file — the 182/60 census, the `R CMD check` 0/0/1 result (both runs), the collateral-verdict
2-vs-14-failing-tests count down to the exact test names, the 3136-PASS/93.4s combined run, the
`FROZEN_CENSUS_POINT_FIT_RECOVERY = 59` guard, the `AGENTS.md` D-97/D-117/D-88 line citations, the DRM.jl
sister-repo file count, the two "brain" note titles — reproduced exactly. I found three genuine drift
items, all minor and all in the same family the arc's own after-task report spends two paragraphs
warning about: a stale citation (`AGENTS.md:369`) that S7's own review flagged and nobody then fixed or
declared open, one sub-citation inside the "fixed" fixture file that is itself still stale by about 50
lines, and an evidence trail (S3/S4's probes) stranded in a second non-durable worktree the handover
mentions but does not flag as an evidence-loss risk. None of the three touches the code, the guard, the
census, or a public claim. Nothing in "Explicitly NOT in this arc" was violated.

## The Phase 0.25 sweep receipt — is the corrected "brain (deterministic grep)" row non-vacuous?

**Yes.** I re-ran every citation in that row against the live files rather than trusting the prose:

| Claim in the corrected row | Re-checked | Result |
|---|---|---|
| `grep -in "prong b" memory/AGENT_LOG.md` → no matches | `grep -in "prong b" ~/shinichi-brain/memory/AGENT_LOG.md` | zero matches — confirmed |
| `grep -rin "prong b\|prong-b" journal/` → no matches | same command | zero matches — confirmed |
| `grep -in "prong\|interval_feasible\|truth gate" memory/DECISIONS.md` → L883, L3235 | same command | returns lines **883, 3235** exactly — confirmed |
| "'truth gate' has zero matches in the file" | `grep -in "truth gate" ~/shinichi-brain/memory/DECISIONS.md` | zero matches — confirmed |
| Corrected attribution: D-97 at `DECISIONS.md:2746`, D-117 at `:3425`, the D-88 lane note at `:3454` | `grep -n "^### D-97 —\|^### D-117 —"` and `grep -n "Lane note (D-88)"` | **2746, 3425, 3454 exactly** — confirmed |

The "brain (semantic)" row's three reused notes also verify as real, existing files, not paraphrased
vault hits:

- `docs/dev-log/after-task/2026-05-15-slice-53-direct-profile-robustness.md` — exists in the primary
  drmTMB checkout.
- `docs/dev-log/after-task/2026-05-11-profile-sd-correlation-intervals.md` — exists.
- `docs/design/68-gllvmtmb-profile-ci-audit.md` — exists (this is a **drmTMB** design doc about
  auditing/comparing to gllvmTMB, not a gllvmTMB-repo file under gllvmTMB's own numbering; my first
  attempt to verify it against `gllvmTMB/docs/design/68-*` was a wrong guess at its location, not a
  problem with the plan's citation).

The sister-repo row also reproduces exactly: `grep -rln "profile" DRM.jl/src/` returns **24** files, and
`locscale_profile.jl` / `profile_q4_phylo.jl` are both present. The corrected receipt is grounded, not a
rationalized restatement — every surface line names a re-runnable command or an existing path, and every
one I ran returned what the plan says it returned.

## Axis 1 — Scope

**Matches, verified against the diff, not the prose:** `git diff -- R/profile.R` shows exactly the four
described edits (E1-E4): `count_labelled_q2_profile_restricted()`,
`count_labelled_q2_profile_restricted_status()`, and `count_sigma_interaction_profile_restricted()`
deleted outright with the `eta_cor_phylo` branch that called them; `zero_one_beta_sigma_q1_profile_restricted()`
deleted; `count_point_fit_only_profile_restricted()`'s `zero_one_beta` `dpar` set narrowed from
`c("mu","sigma","zoi","coi")` to `c("mu","zoi","coi")`; the final fall-through replaced by `cli::cli_abort()`.
`zi_nbinom2_sigma_q1_profile_restricted()`, `zero_one_beta_zoi_q1_profile_restricted()`, and
`zero_one_beta_coi_q1_profile_restricted()` are untouched in the diff — **no `coi` fence opened, no
Tier-2 (`zoi`/structured-`mu`) fence opened**, matching "Explicitly NOT in this arc." No campaign ran
(handover: "NOT STARTED"). Census: I computed `model_surface` `evidence_tier` counts directly from
`docs/dev-log/dashboard/capability-ledger/cells.tsv` — **182 `interval_feasible` / 60
`point_fit_recovery`**, unchanged from the plan's stated pre-arc baseline. `FROZEN_CENSUS_POINT_FIT_RECOVERY`
in `tools/capability_ledger.py:218` is still `59`, not moved to `45`.

**S-1 [ADAPTIVE].** `R/family.R` and `vignettes/formula-grammar.Rmd` carry diffs the SLICE TABLE never
named. Both close S7's R1 finding (SHOULD-FIX: shipped docs asserted the pre-edit fence for routes this
change opened) — confirmed by reading both diffs: `R/family.R`'s roxygen now says the two ordinary
`zero_one_beta` `sigma` routes "now admit direct profiling... makes an interval computable, not
calibrated"; the two `formula-grammar.Rmd` rows got matching corrections. Justified and recorded
(after-task report §4, §6 item 2). Not a scope violation — it is a doc-accuracy fix triggered by the
plan's own adversarial-verify slice (S7) and reported as such.

**S-2 [ADAPTIVE].** `docs/dev-log/dashboard/capability-ledger/{cells,evidence}.tsv`,
`capability-census/{_master,skew_normal,student}.tsv`, and `estimator-surface-conformance.tsv` carry
diffs the SLICE TABLE never named. These close part of S7's R3 finding (stale `R/profile.R:LINE`
citations after the edit's own line-shift). Verified directly: only `evidence_source`/`notes` citation
text changed in these files; `status` and `evidence_tier` are unchanged in every row (spot-checked
against the live 182/60 count above, which would have moved if a frozen cell had been touched). Justified
and recorded (after-task report §6 item 1).

**S-3 [DRIFT].** S7's own R3 table named **five** files with the same stale-citation defect:
`cells.tsv`, `evidence.tsv`, `capability-census/_master.tsv` + `student.tsv`/`skew_normal.tsv`, and
**`AGENTS.md:369`** (citing `R/profile.R:3844`, which should have moved to `:3852`). Only the first four
were fixed. `git diff --stat -- AGENTS.md` is empty — the file was never touched. I confirmed the
citation is still wrong: `R/profile.R:3844` in the current tree is the middle of the `allowed_notes`
list (`"mesh_field_scale_intervals_unvalidated"`), not the "same `newdata` route serves
`sigma`/`sigma1`/`sigma2`/`corpair()`" content `AGENTS.md:369` claims lives there. Neither the after-task
report's Known Limitations (§11) nor the handover's Next Immediate Steps/Blockers names this as an open
item — it is not deferred-and-declared, it is silently missed. Low stakes (a contributor-facing doc, not
a CRAN-facing claim) but it is a live, uncaught instance of the exact pattern the same after-task report
devotes §7 to warning about. **Owner: Rose** (closeout completeness — same class as the report's own
recommendation to build a durable citation mechanism).

> **CORRECTION (orchestrator, verified after this reconciliation was written).** The finding stands
> that `AGENTS.md:369` carries a wrong citation, but its stated cause does not: the number did **not**
> "move to `:3852`", because it never pointed at the claimed content in the first place. Checked
> against the pristine baseline — `git show origin/main:R/profile.R | sed -n '3844p'` is `)`, the
> closing paren of the `cli_abort()` inside `validate_profile_targets()`'s note check, and
> `sed -n '3830,3860p'` over the baseline file contains **zero** occurrences of `newdata` or
> `corpair`. So `AGENTS.md:369`'s pointer was already wrong on `origin/main` and this arc's line shift
> did not break it. Disposition changes accordingly: **pre-existing rot, not arc drift**, and
> deliberately left unedited — substituting a plausible-looking new line number would fabricate a
> pointer the note never had, inside a dated historical block. Folded into the citation-durability
> task instead. This correction is itself the reconciliation working: the drift was real, the
> attribution was not, and the difference decides who owns it.

## Axis 2 — Evidence / verification

All eight items in the plan's Verification list have a receipt, and I reproduced the load-bearing ones
against raw artifacts rather than the prose:

1. `devtools::document()` regenerates `profile_targets.Rd` — diff is coherent roxygen output (drops the
   four retired tokens, matches the R/profile.R `@return` edit); indirectly corroborated by the
   zero-warning `R CMD check` result below (a broken Rd would have surfaced there).
2. Unmodified suite, pre- vs post-edit — **reproduced exactly** from `/private/tmp/prongb-baseline-suite.log`
   (files with failures: 2 | failing tests: 2 — `test-estimator-surface-conformance.R` 4 failed
   expectations, `test-phase18-structured-workflow-registry.R` 1) and `/private/tmp/prongb-collateral.log`
   (TOTAL files with failures: 5, listing exactly `test-count-structured-mu.R` ×3,
   `test-estimator-surface-conformance.R`, `test-phase18-structured-workflow-registry.R`,
   `test-phylo-interaction.R` ×2, `test-zero-one-beta.R` ×7 = 14 tests). The after-task report's own
   "timing caveat" (the conformance test's failed-expectation count differs 4-vs-5 because the collateral
   log's mtime precedes the citation-anchor fix) reproduces to the minute: `estimator-surface-conformance.tsv`
   mtime `19:23:49` is after `prongb-collateral.log`'s mtime `19:20:31`.
3. Targeted 4-file run — **reproduced exactly** from `/private/tmp/drmtmb-s3/scratchpad/final-combined.log`:
   `[ FAIL 0 | WARN 6 | SKIP 0 | PASS 3136 ]`, elapsed 93.40844s.
4. S2 guard, both proofs + red-test — the `scratchpad/pf-*` directories (`pf-diff-run-1`, `pf-test-old`,
   `pf-redtest-run`, `pf-guard-run-1/2`, `pf-guard-final`) each contain real `enumeration.tsv`/
   `battery.tsv`/`provenance.tsv` outputs consistent with the S2 report's narrated sequence (initial
   two-library diff, baseline cross-check, the mutate-and-revert red-test, the final live
   re-confirmation). The `.github/workflows/R-CMD-check.yaml` diff matches the S2 report's own quoted
   diff verbatim.
5. NEWS-diff scope check — see E-2 below.
6. Full `devtools::test()` → `R CMD check --as-cran` — **reproduced exactly** from
   `/private/tmp/prongb-ascran.log` and `/private/tmp/prongb-ascran-final.log`: both show `ERRORS: 0`,
   `WARNINGS: 0`, `NOTES: 1` (the benign CRAN-incoming-feasibility note).
7. `capability_ledger.py --check` still 182/60 — **reproduced by direct computation** from
   `cells.tsv` (see Axis 1).
8. Tests via `tests/testthat.R` → `test_check` against a freshly installed package — structurally
   satisfied by `R CMD check --as-cran`, which installs fresh and runs `tests/testthat.R` (item 6).

**E-1 [DRIFT].** The after-task report's own closing claim in §6 item 4 — "only 1 line-numbered
test-file citation remains in `tools/profile-fence-fixtures.R`, and it is a seed/DGP-derivation comment
inside a single self-contained helper, not a cross-file provenance pin" — does not fully reproduce. That
one remaining comment block (`tools/profile-fence-fixtures.R:647-652`) cites five things; I checked all
five against the current test file:

| cited | claimed location | actual location (grep on the seed/function) | status |
|---|---|---|---|
| nbinom2 phylo, seed `2026072801` | `test-count-structured-mu.R:936-951` | **line 986** | **stale, ~50 lines off** |
| poisson phylo, seed `2026072811` | `:842-857` | line 844 | within range |
| poisson spatial/animal/relmat, seed `2026072908` | `:1119-1186` | line 1169 | within range |
| `expect_count_labelled_q2_profile_restriction()` | `:583-634` | line 583 | matches |
| `expect_poisson_labelled_q2_provider_fit()` | `:702-735` | line 701 | off by 1, negligible |

Four of five sub-citations hold; the first does not. This is the same defect class the "fix" it belongs
to was created to close (S7 finding R4), recurring inside the fix itself, and it is presented in the
closeout as fully resolved. Low stakes — it is a derivation comment, not a claim the guard depends on
programmatically — but the report's own verification language overstates how clean it is. **Owner:
Rose.**

**E-2 [ADAPTIVE].** Verification item 5 ("NEWS-diff scope check... a NEWS diff touching any route
outside the 14 is a defect") has no discretely labeled receipt, but its substance is covered by S7's R6
("no validity or coverage claim anywhere," read line-by-line) and R7/R8 (bias-claim sourcing, the
14-cell enumeration). Equivalent coverage under a different label, not a skipped check.

## Axis 3 — Model routing

Matched against report bylines and document structure, not assumed from the SLICE TABLE alone:

| Slice | Plan | Evidence found | Call |
|---|---|---|---|
| S1 (R/profile.R + roxygen) | fable, inline | No separate report; diff present. Consistent with inline execution | MATCH (no contrary evidence) |
| S2 (fence-integrity guard) | Curie, sonnet, high | `scratchpad/2026-08-03-prong-b-s2-guard-report.md`, byline "Curie (simulation/testing specialist)" | MATCH |
| S3 + S4 (reuse) | Curie, sonnet, med; S4 reuses S3's agent | One combined report, `/private/tmp/drmtmb-s3/scratchpad/2026-08-03-prong-b-s3s4-report.md`, both sections in one document — no separate S4-only artifact | MATCH |
| S5 (NEWS + roxygen + check-log) | fable, inline, high | `NEWS.md`/`check-log.md` diffs present; no separate byline | MATCH (no contrary evidence) |
| S6 (mechanical-verify) | scout, haiku, low | No distinctly-titled artifact or byline. The checks it owns (full test, `--as-cran`, ledger `--check`, NEWS-diff scope) all have receipts, and the after-task report repeatedly says it "re-ran live for this report" — implying a prior run existed | **UNCLEAR** |
| S7 (adversarial verify) | opus, high | `scratchpad/2026-08-03-prong-b-s7-adversarial-review.md`, all four lenses (Fisher/Rose/Grace/Boole) in one document, consistent with the single opus ceiling slot | MATCH |
| S8 (consolidate) | Rose, sonnet, med | After-task report, explicit byline "Author of this report: Rose (systems auditor)" | MATCH |
| S9 (this reconcile) | Melissa, sonnet, med | This document | MATCH |

**R-1 [UNCLEAR].** I cannot independently confirm from repo artifacts alone whether S6 ran as its own
dispatched child (as the FAN-OUT BUDGET's "6/6 (4 sonnet, 1 haiku, 1 opus)" accounting implies) or was
folded into the orchestrator's inline work or absorbed into S7/S8's later re-verification passes. Unlike
the comparable Arc 8 reconcile (`docs/dev-log/plan-actual/2026-08-03-arc7b-truth-gate.md`), where the
launching agent explicitly stated a planned Haiku dispatch ran inline instead, I found no equivalent
statement here either way — only the absence of a dedicated artifact, which a bounded read-only
mechanical slice would not necessarily produce. Not tagged drift because there is no positive evidence of
a budget violation (no extra dispatched-agent artifact exists beyond the ones matched above, and the
opus ceiling was used exactly once, by S7). **Owner: Ada**, to confirm routing intent if it matters for
future budget accounting.

No evidence of ceiling overrun, unrecorded escalation, or more than six post-checkpoint children.

## Axis 4 — Safety gates

All matched, no deviations found:

- **Red-test discipline.** The S2 report's transcript (mutate one disjunct → 10 violations, exit 1;
  revert → 0 violations, exit 0) is corroborated by the after-task report's independent live re-run and
  by matching `scratchpad/pf-redtest-run/*.tsv` / `pf-guard-run-2/*.tsv` artifacts.
- **Fit errors are gate failures, not skips.** Confirmed structurally (S2 report §1: both `route$build()`
  and `profile_targets()` wrapped in `tryCatch()`, any error written as a violation) and empirically (0
  `build_error`/`fit_error`/`profile_targets_error` rows across 48 fits in the S2 battery; 0 ABORT rows
  in S7's 3.76M-point sweep). S7's G6 explicitly confirms no `skip_if_not_installed()`-style escape
  exists.
- **Targeted tests then full `--as-cran` locally.** Confirmed via the log sequence: targeted 4-file run
  first (93.4s), then two full `R CMD check --as-cran` runs (0/0/1 both times).
- **No compute off this Mac; no campaign on GitHub Actions.** No Totoro/DRAC reference in the after-task
  report, the S2 report, or the S7 review outside "next arc"/"campaign" framing (checked by grep,
  excluding those contexts — zero hits). No campaign ran at all.
- **Do not merge while main's CI run `30861623528` is in flight.** Trivially honored — nothing was
  committed, staged, or pushed (`HEAD == origin/main` exactly). For the next session's benefit: I checked
  that run directly and it is now `completed`/`success` (`createdAt` 23:15:20Z, `updatedAt` 23:51:32Z),
  so the constraint has since lifted.

## Axis 5 — Public claims

`NEWS.md`, the new `R/profile.R` roxygen `@section` (→ `man/confint.drmTMB.Rd`), and every new
`test_that()` description carry the "reachability, not inference" framing and the structured-`sigma`
ML-low-bias caveat, matching Fisher's DECISIONS-LOCKED #4 requirement to ship the caveat at
computability, not just at promotion. I independently read the `NEWS.md` diff and found no coverage,
calibration, or promotion claim — consistent with S7's R6. `grep` for "196/46" (the post-promotion
target figure) in `NEWS.md` returns nothing — no premature promotion language shipped. The R1 SHOULD-FIX
stale-claim findings are fixed (Axis 1, S-1). One S7 finding remains open but was never committed to
closure: **R8 (NOTE, not SHOULD-FIX)** — `NEWS.md`'s "the labelled intercept-slope covariance blocks of
`poisson()` and `nbinom2()` `mu`" line reads as 11 cells to a literal count, not 14, and does not spell
out that `nbinom2` covers `phylo` only while `poisson` covers four providers. Since S7 tagged this NOTE
rather than SHOULD-FIX, its non-closure is not a deviation from the plan's own bar — recorded here only
because it is the one adversarial-review finding still visible in the shipped `NEWS.md` text.

## Axis 6 — Handoff state

The handover (`docs/dev-log/handover/2026-08-03-prong-b-tier1-to-campaign-handover.md`) is explicit that
nothing is committed, staged, or pushed, and names `/private/tmp/drmtmb-prongb` as the worktree to
resume in. It also names `/private/tmp/drmtmb-s3` once, under "Gotchas & Failed Approaches"
("Concurrent multi-worktree collaboration is fragile but was not destructive here... ran across at least
three worktrees").

**H-1 [DRIFT, minor].** The handover does not flag that the S3/S4 evidentiary trail — the
`2026-08-03-prong-b-s3s4-report.md` report plus 13 `probe*.R`/`probe_s4_*.R` scripts and several `.rds`
fixtures that document how the four new `se = TRUE` interval numbers (e.g. "Profile 70% CI `[0.2945,
0.4886]` vs Wald `[0.2912, 0.4862]`") were derived — lives **only** in `/private/tmp/drmtmb-s3`. The
shipped diff itself (the test files) is safe, byte-identical in both worktrees (verified). But the
worktree holding the *evidence for how those numbers were produced* is not called out as an evidence-loss
risk distinct from the already-flagged "a worktree at `/private/tmp/...` is not a durable location"
warning that the handover applies to `drmtmb-prongb`. If `drmtmb-s3` is cleaned up before this
reconciliation or a future audit reads it, the derivation trail for the S3/S4 numbers is gone even though
the code that depends on them is not. **Owner: Rose** (closeout completeness).

No other undeclared state found: `git worktree list` shows the expected set (`drmtmb-prongb` on
`claude/prong-b-tier1`, `drmtmb-s3` detached at the same base); no stray commits on the branch; the
`.bak`/`.git/index.lock` items the plan carried over from Arc 7b are explicitly marked "CARRIED-OVER,"
not this arc's responsibility, and were not touched.

## Recurring drift classes

`~/shinichi-brain/memory/PLAN-DRIFT-LEDGER.md` exists (2,752 bytes, one recorded class: "Multi-lane
handover single-pointer trap," owner Ada, not directly applicable here — that class concerns concurrent
lanes orphaning a rolling deferred-item menu, not citation drift).

**Candidate new class, not yet in the ledger: citation/line-number anchor rot.** This arc's own
after-task report (§7) already names this pattern as recurring within drmTMB — a 2026-07-25 report
(`docs/dev-log/after-task/2026-07-25-estimator-surface-anchor-hygiene.md`) repaired 7 anchors in
`estimator-surface-conformance.tsv` and recommended a durable citation form over another manual
line-number refresh; this arc needed a further 6-span repair in the same file plus a brand-new file
(`tools/profile-fence-fixtures.R`) that shipped with 29 fragile line pins already stale by the time it
landed. My own findings above (S-3, E-1) add two more live instances **within this arc's own closeout**:
`AGENTS.md:369` (never fixed) and one sub-citation inside the fixture file's own "fixed" state (still
stale). That is at least four occurrences of the same class across two arcs nine days apart, one of them
recurring twice inside a single arc's remediation of itself. This clears the ledger's own ">=2x" bar for
promoting a class to a standing guard. Recommend Rose add "citation/line-number anchor rot" to the
ledger's recurring-drift table, with the fix already named by both this arc and its predecessor: a
grep-based locator or stable named-anchor comment, checked by a test, rather than another manual
line-number refresh.

## Tagged-deviation summary

| ID | Axis | Tag | Owner |
|---|---|---|---|
| S-1 | Scope | ADAPTIVE | — |
| S-2 | Scope | ADAPTIVE | — |
| S-3 | Scope | DRIFT | Rose |
| E-1 | Evidence | DRIFT | Rose |
| E-2 | Evidence | ADAPTIVE | — |
| R-1 | Model routing | UNCLEAR | Ada |
| H-1 | Handoff | DRIFT | Rose |

**Counts: 3 adaptive, 3 drift, 1 unclear.**

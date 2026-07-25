# Session Handoff: Arc B CLOSED (merged) · Arc A1 in flight

**Meta:** 2026-07-25 · from Claude · target **Claude** · two arcs in one session

You are Claude, picking up a lane that ran two arcs back to back. Read `AGENTS.md`
first, then this. **This doc stands alone** — you will not see the authoring chat.

---

## Mission (the durable why)

drmTMB is univariate and bivariate distributional regression on TMB. Arc A (closed
2026-07-25) established the strategic fact this lane is built on: of the 176-cell
`point_fit_recovery` pool, **122 are `structured`, 18 are `response_missingness`,
7 are non-structured bivariate — none has any external comparator in existence.**
Cross-package parity can reach ~15 cells, ever. **~80% of the stuck pool is
frontier**, where parity is structurally incapable of reaching.

Everything below follows from that: the way to license the frontier is *internal*
correctness evidence — analytic oracles, derivative agreement, score identities —
not more comparators.

---

## Mission control

| Item | State | Notes |
| --- | --- | --- |
| **Arc B — C++/numerical audit** | **MERGED** (PR #842, `main` @ `12d971f1`) | 5 suites, 58 blocks, 516 assertions, 0 skips. `R CMD check` OK. CI green. |
| **Arc A1 — marginal simulation** | **PR #843 OPEN**, pushed, mergeable, **not merged** | Implemented + documented. **Verification PENDING at handoff — no green has been seen.** Version stays 0.6.0 (bump made then reverted). |
| Issue #710 | correction posted | comment `5080196319`; #710.2 still open |
| Arc B findings A2–A8, F3/F5/F6/F9/F10 | **reported, none fixed** | next natural lane |
| Aborting RE structures | known gap | owner approved a **separate arc** |

---

## What was accomplished

### Arc B — C++/numerical audit (MERGED, PR #842)

Five standing suites now live on `main`:
`test-numeric-kernel-oracle.R` (17/18 univariate families vs independent R
references over `eta ∈ {-700…700}` × `log_sigma ∈ {-15…15}`) ·
`test-gradient-conformance.R` (`obj$gr` vs `numDeriv` over 14 structures) ·
`test-score-consistency.R` (Bartlett identities) ·
`test-guard-branch-continuity.R` (all 26 `CondExp` sites vs a pre-declared
smoothness class) · `test-link-conformance.R`.

Verification: **39708 pass / 1 fail / 124 skip** against a **39192 / 1 / 124**
baseline — zero pre-existing status changes, zero skips in the new suites,
`R CMD check` **Status OK**.

Full findings: `docs/dev-log/after-task/2026-07-25-arc-b-cpp-numerical-audit.md`
and `docs/dev-log/2026-07-25-arc-b-frontier-hazard-read.md`.

### Arc A1 — marginal simulation (IN FLIGHT)

Fixes the audit's highest-severity finding. `simulate.drmTMB()` gained
**`re.form`** (`NULL` = marginal, the **new default**; `NA` = the old
conditional behaviour), and `confint()` gained **`bootstrap_re_form`**.
Design record: `docs/design/243-marginal-simulation-and-re-form.md`.

---

## Current working state

**Working:** everything on `main` (Arc B). A1's implementation, docs, NEWS, and
design doc are complete on the branch.

**In progress at handoff:** verification of PR #843 — both the local full suite
and CI were still pending. **No result was seen before this handover was
written; do not assume it passed.** Read `gh pr checks 843` yourself.

**Blocked:** nothing. A1 is complete work awaiting evidence, not awaiting a
decision. The version question is settled (stays 0.6.0).

---

## Files created / modified

**Arc B — already on `main`** (`git show 12d971f1`): five `tests/testthat/test-*.R`;
`docs/dev-log/2026-07-25-arc-b-frontier-hazard-read.md`;
`docs/dev-log/after-task/2026-07-25-arc-b-cpp-numerical-audit.md`; `DESCRIPTION`
(+`numDeriv`); `.gitignore`.

**Arc A1 — UNCOMMITTED on `claude/a1-simulate-marginal-re` at handoff:**

| Path | Change |
| --- | --- |
| `R/methods.R` | `simulate.drmTMB` `re.form` + all 16 family branches; new draw helpers (~5886-6165) |
| `R/profile.R` | `confint.drmTMB(bootstrap_re_form=)` → `drm_bootstrap_confint(re_form=)` → `simulate()` |
| `inst/sim/run/sim_run_meta_v_lss_smoke.R` | `bootstrap_re_form = NA` (plumbing only) |
| `man/simulate.drmTMB.Rd`, `man/confint.drmTMB.Rd` | regenerated |
| `tests/testthat/test-simulate-re-form.R` | **new** — the `re.form` contract |
| `tests/testthat/test-score-consistency.R` | **the proof flip** (see below) |
| `tests/testthat/test-{biv-gaussian,phylo-gaussian,spatial-gaussian,profile-targets}.R` | `re.form = NA` at unsupported-structure sites |
| `NEWS.md` | entry under `0.6.0` — corrected before first release, NOT a post-release break |
| `docs/design/243-marginal-simulation-and-re-form.md` | **new** — design record |
| `docs/dev-log/handover/2026-07-25-arc-b-a1-claude-handover.md` | this doc |

---

## Key decisions & rationale

- **Marginal is the DEFAULT, not an opt-in.** Owner call ("correct first"). A
  silent under-dispersing default is worse than a contained migration.
- **`predict()` deliberately unchanged.** Conditional prediction at the original
  data is correct; the defect was `simulate()` inheriting it.
- **Unsupported structures ABORT — never silently fall back to conditional.** A
  fallback would recreate the exact defect being fixed.
- **Bootstrap stays marginal by default.** The easy fix (`re.form = NA` inside
  `drm_bootstrap_confint`) would have restored the anticonservative intervals the
  arc exists to eliminate.
- **The tier fence is asymmetric** (Fisher, Arc B): correctness evidence may
  **never promote** a ledger cell but **can compel a demotion**. Two triggers
  arose in Arc B; both were checked against the interval method that actually
  produced each certified cell's coverage, and both cleared.

---

## Gotchas (paid for in this session)

- **Score identities must be evaluated at `fit$opt$par` (the OPTIMUM), never
  `fit$obj$par` (the START vector).** This produced a bogus `z = 19` during
  scoping. `test-score-consistency.R` now guards it with
  `expect_lt(max(abs(fit$obj$gr(fit$opt$par))), 1e-3)`.
- **`R CMD check` can disagree with `test_dir` — and did.** Arc B's S3 suite
  passed under `test_dir` and ERRORed under `R CMD check` because it resolved
  `src/` relative to a source checkout. Tests run from `<pkg>.Rcheck/tests/`;
  sources live at `00_pkg_src/<pkg>/src/`. **Always run both.**
- **`test-phase18-structured-workflow-registry.R` fails in a worktree and passes
  on CI.** Pre-existing, path-resolution, out of scope. Do not "fix" it.
- **The entry point is `drmTMB()`, not `drm()`.**
- **Don't trust a truncated build log.** "3 dead `sigma_i` variables" was
  actually **12**.
- **Three of the audit's four top hypotheses were refuted by measurement.** The
  Cholesky NaN is unreachable; the NB2 reverse-sweep NaN is double-guarded (one
  guard is CppAD's own `div_op.hpp:389-395`); the `log1mexp` threshold is
  well-placed. The finding that mattered came from a slice added at the review
  gate, not from the plan.

---

## Next immediate steps

1. **Finish A1.** Re-run the full suite and `R CMD check` (below), read the
   result yourself, then commit → push → PR → merge. Do not claim a green you
   did not see.
2. **Fisher + Rose completion gate** before any completion claim; default NOT-DONE.
3. **Then pick ONE of two approved lanes** (owner approved both):
   - **Arc A2 — marginal draws for the aborting structures**: `phylo_interaction`,
     cross-trait `q > 1`, covariance blocks (q4/qgt2), `corpair`, modelled RE
     scale. Owner explicitly approved this as a new arc.
   - **Arc C — the Arc B hardening bundle**: A5 (beta `mi()` clamp ordering, a
     one-line move), F5 (`sd()` regression exponentiates an unbounded predicted
     log-SD with no guard while residual `log_sigma` is clamped), the 12 dead
     `sigma_i` locals, A7 (rotted line-anchors in `R/family-dpq.R`).
   Leave A2/tweedie (upstream TMB) and A3/A4 (the ridge — needs a
   scale-heterogeneous fixture first) alone for now.

---

## Blockers / open questions

- **Version: DECIDED — stays `0.6.0`, no bump.** 0.6.0 was never released or
  tagged, so it is a release *candidate*; correcting `simulate()` inside the RC
  is what an RC is for, and the first CRAN submission then ships correct from
  day one. A 0.7.0 bump was made and then reverted on the owner's call. NEWS
  frames this as *corrected before first release*, not a post-release break,
  and warns that bootstrap intervals from an earlier GitHub development build
  are anticonservative and should be recomputed.
- **#710.2** still open; the sign-error correction is posted but not applied.

---

## How to resume

```bash
cd "/Users/z3437171/Dropbox/Github Local/drmTMB"
git fetch origin && git worktree add /private/tmp/drmtmb-a1 claude/a1-simulate-marginal-re
```

Verification (C++ unchanged from Arc B — **do not recompile**, reuse the lib):

```r
.libPaths(c("/private/tmp/drmtmb-arc-b-lib", .libPaths()))
pkgload::load_all("/private/tmp/drmtmb-a1")
testthat::test_dir("tests/testthat", reporter = "silent", package = "drmTMB")
```

Then, from `/private/tmp`:

```bash
R CMD build --no-build-vignettes --no-manual drmtmb-a1
_R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-manual --ignore-vignettes drmTMB_0.6.0.tar.gz
```

**Baseline to beat: 39708 pass / 1 fail / 124 skip; `R CMD check` Status OK.**
No new skips. Spawn **Rose** (`systems_auditor`) and **Fisher**
(`inference_reviewer`) before any completion claim.

**One-command resume** (paste in your own authenticated terminal, from the repo root):

```
claude "Rehydrate from docs/dev-log/handover/2026-07-25-arc-b-a1-claude-handover.md + the AGENTS.md snapshot, then continue with the Next Immediate Steps."
```

---

## ⚠ Landing state — READ THIS FIRST

**A1 is COMMITTED and PUSHED. [PR #843](https://github.com/itchyshin/drmTMB/pull/843)
is OPEN against `main`, MERGEABLE, and NOT merged.** Four commits on
`claude/a1-simulate-marginal-re`: the fix · a 0.7.0 bump · its revert · the RC
reframing. Nothing is at risk.

**What is NOT done: verification.** At handoff, both the local full suite and
PR #843's CI (`ubuntu-latest (release)`) were still **pending**. **No one has
seen a green.** Do not merge on the strength of this document.

**Do this first:**

1. `gh pr checks 843` — CI is the stronger signal; it runs `R CMD check` from a
   clean checkout. Arc B's suite was green under `test_dir` and **ERRORed under
   `R CMD check`**, so `test_dir` alone is not sufficient evidence.
2. Re-run the local suite (commands above) if CI is ambiguous.
3. **Baseline: 39708 pass / 1 fail / 124 skip. No new skips.** The 1 failure is
   the pre-existing worktree-only `test-phase18-structured-workflow-registry.R`
   — it passes on CI; do not fix it.
4. Spawn **Fisher** and **Rose** for the completion gate; default NOT-DONE.
5. Merge only then.

**Unverified detail worth checking:** the close-out agent that edited the three
bootstrap-plumbing sites (`test-profile-targets.R` ×2,
`inst/sim/run/sim_run_meta_v_lss_smoke.R`) **returned without reporting its
suite result** — it stopped while waiting on its own background run. Those
three edits have not been confirmed green by anything. Check them specifically.

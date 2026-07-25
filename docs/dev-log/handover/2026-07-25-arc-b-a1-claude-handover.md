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
| **Arc A1 — marginal simulation** | **IN FLIGHT**, branch `claude/a1-simulate-marginal-re` | Implemented + documented; final full-suite/`R CMD check` verification was RUNNING at handoff. **UNPUSHED.** |
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

**In progress at handoff:** the A1 close-out agent was running the full suite +
`R CMD check`. **Its result was not seen before this handover was written — do
not assume it passed.** Re-run and read it yourself (commands below).

**Blocked:** nothing.

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
| `NEWS.md` | BREAKING entry |
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

- **Version bump?** A1 is a breaking change to a public method against a
  CRAN-facing 0.6.0. NEWS documents it; the version decision is the owner's.
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

## ⚠ Landing state

**At the time this doc was written, the A1 branch was UNPUSHED and its work
UNCOMMITTED.** If the authoring session did not complete the commit/push, the
work exists only in the local worktree `/private/tmp/drmtmb-a1` — check before
assuming it is safe, and push it first thing.

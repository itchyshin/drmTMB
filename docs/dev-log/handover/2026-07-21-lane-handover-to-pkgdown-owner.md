# Lane handover — simulation/testing lane → pkgdown reader-surface owner

Date 2026-07-21 · From: Claude Code session on `claude/0.6-dev-arc` · Status: **lane accepted, docs work stopped**

## 1. Accepted

I am confined to the simulation/testing lane for the duration of the audit epoch. I will not edit
`vignettes/`, `README.md`, `_pkgdown.yml`, generated documentation, shared article inputs,
navigation, or release-audit evidence. I will not push, deploy, or merge any reader-surface change.

**Stopped as a result:** I was about to apply verified over-claim corrections to three reader
surfaces. Those edits are **not being made**. The evidence is handed to you in §3 instead.

## 2. PRIOR ENCROACHMENT — read before you start

This predates your message; disclosing so it does not surprise you mid-audit.

**Branch `claude/0.6-dev-arc` @ `0b48b94b`. Pushed to `origin/claude/0.6-dev-arc`. NOT merged to
main.** Fork point from main is `e7ac5896`.

Four files in your lane already differ from main on that branch — **45 insertions, 1 deletion**:

| File | Change |
|---|---|
| `NEWS.md` | +30 — one new section, "First-impression formula surface (issue #776)" |
| `README.md` | +3 — one navigational line pointing at `articles/missing-data.html` |
| `man/fixef.Rd` | +12/-1 — **regenerated** by `devtools::document()`, not hand-edited, after `coef.drmTMB()` gained `@rdname fixef` |
| `vignettes/function-map-cheatsheet.Rmd` | +1 — one Quick-reference table row for the missing-data axis |

Also touched, in case "release-audit evidence" covers them:
`docs/dev-log/release-audits/2026-07-21-newcomer-syntax-sweep.md`,
`docs/dev-log/release-audits/2026-07-21-0.6.0-pre-cran-worklist.md`,
plus `docs/dev-log/after-task/`, `handover/`, and the arc plan.

All four reader-surface changes are additive and navigational; none widens a capability claim, and
none touches a ledger-generated include. **Your call entirely** whether to adopt, redo, or discard
them — the branch is unmerged, so discarding costs nothing. If you would rather I revert them on my
branch so main-based work is unambiguous, say so and I will.

## 3. CLAIM-BOUNDARY TRIGGER — evidence, not edits

Per your protocol. **Source: worktree `/private/tmp/drmtmb-precran-review-7abdd7e9`, branch
`claude/0.6-dev-arc`, SHA `0b48b94b004dbd616155258cb73d9204a2e32112`.** All claims below were
re-derived live from `cells.tsv` (695 lines = 694 data rows) by two independent reviewers.

### 3a. A false certification claim is shipping on three pages

The word **"certified"** is attached to the **constant `rho12 ~ 1` profile interval**, which is
cell **`mc-0181`, tier `interval_feasible`** — not certified. `mc-0181`'s own `claim_boundary`
reads: *"No committed CI-coverage simulation found for biv_gaussian fixed effects specifically."*
Only three ledger rows carry `dpar ~ rho12` — `mc-0181` (interval_feasible), `mc-0186`
(point_fit_recovery), `mc-0193` (none) — so **no certified rho12 cell exists anywhere.**

Verbatim sites:

- `vignettes/bivariate-coscale.Rmd:422-425` — *"Treat both as computed but not coverage-certified …
  Fit `rho12 ~ 1` when you want the constant residual-correlation profile interval, which is the
  certified reporting target."*  ← **Shinichi-owned file, excluded from your lane. Needs routing to him.**
- `vignettes/figure-gallery.Rmd:1845-1847` — *"Only the constant `rho12 ~ 1` profile interval is a
  certified reporting target; the row-specific intervals are computed but their coverage has not
  been established."*
- `vignettes/model-workflow.Rmd:423-425` — *"these row-specific intervals are computed but not
  coverage-certified; the certified residual-correlation target is the constant `rho12 ~ 1` profile
  interval."*

**Important nuance, and the reason I am not sending you a patch:** the surrounding prose is
*correct*. It honestly disclaims the row-specific regression rho12. The defect is narrow — the
reader is steered *away* from an honestly-disclosed uncertified interval and *toward* a second
interval described as certified, which is not. A careless fix would delete the correct hedging. The
minimal repair is to the referent, not to the disclaimers.

### 3b. VERIFICATION COMPLETE — both further triggers CONFIRMED

Each was independently verified with a mandatory refutation attempt first. **In all three cases the
original report's framing was wrong in a way that matters.** Details below.

#### (i) `confint` "nominal" claim — CONFIRMED, HIGH severity

**The real fix site is `R/profile.R:140`, the roxygen source — NOT `man/confint.drmTMB.Rd:141`.**
Editing the `.Rd` alone is overwritten by the next `devtools::document()`.

Text: *"lifting small-`g` coverage of location-axis structured-RE SD targets to nominal."*

Every backing cell **explicitly forbids that word**. `mc-0272`/`mc-0285`/`mc-0309` (gaussian mu,
phylo/spatial/relmat, q1) carry verbatim: *"this is inference-ready with caveats, **not nominal or
supported**."* `mc-0085`/`mc-0086`/`mc-0153`/`mc-0154` (biv_gaussian, q2 slope-only) add *"supported
is withheld for measured right-tail miss asymmetry and g-dependence."*

The refutation attempt was that these cells *are* `inference_ready_with_caveats`, so the tier bar is
cleared. It was defeated on a principle worth carrying into your audit: **tier is a ceiling, not a
licence — the binding text is the `claim_boundary`.** Here the boundaries do not merely stop short of
"nominal"; they name and forbid the exact word.

It also **contradicts the package's own `vignettes/capability-and-limits.Rmd:141`**, which describes
the same default channel correctly. And part of the class the sentence quantifies over
(`mc-0210`/`mc-0211`, biv_gaussian phylo q4 REML) is only `interval_feasible` — *"no coverage
simulation found"* — so the sentence generalises over cells with no coverage evidence at all.

#### (ii) rho12 "certified" — CONFIRMED, MEDIUM. **A fourth site found: the propagation source**

`docs/dev-log/release-audits/2026-07-20-0.6.0-release-scope-manifest.md:229` carries the same
over-claim and is, per
`docs/dev-log/after-task/2026-07-21-rho12-interval-audit-reversal.md`, the **origin from which the
three vignette sites were propagated.** Fixing the three pages without the manifest leaves the source
intact.

The defect is **one word wide**. The `model-workflow.Rmd:424` instance is the tightest: *"intervals
are computed but not coverage-certified; the certified residual-correlation target is …"* — the two
terms sit in one sentence separated by a semicolon, so the second is unavoidably read as the positive
of the first.

#### (iii) meta-analysis — CONFIRMED, HIGH, **but half the original report is false**

**The vignette shows NO interval for tau.** The only `confint()` in the file is on `mu` (line 148);
heterogeneity is reported as point quantities only (lines 164-165, 181-190). Anyone acting on the
original report would go hunting for a tau `confint()` that does not exist. Please do not repair a
defect that is not there.

**What does reproduce** is the degeneracy itself, at the exact configuration: K=12, tau_true=0.10,
seeds 1-10 — seed 4 gives `tau_hat = 7.748e-06` with `confint()` sigma `[0, Inf]`; seed 10 gives
`tau_hat = 2.857e-06`, same. Two more are degenerate in substance (`[1.19e-10, 8.95e+06]`). So the
*estimator* behaviour is real and worth a reader-facing caveat; the *claimed vignette text* is not.

### 3c. Structural finding that constrains any repair

**The ledger has no `meta_V` cell at all.** All 694 rows enumerated; no
`family_route`/`route_variant`/`route_modifier` matches `/meta/`. `mc-0260`'s boundary says verbatim
that `meta_V` is *"outside this census's effect_type/provider axes"*. So any meta-analysis page
repair cannot cite a ledger tier for the `meta_V` route — **there is nothing to cite.** Both B3
reviewers returned NO-GO on the meta_V campaigns for exactly this reason: the evidence would have
nowhere to be recorded. This is a maintainer decision (create a cell, or scope the page's claims),
not something a page repair can resolve locally.

## 3d. NEW CLAIM-BOUNDARY TRIGGER — a red test is correctly detecting a README defect

Found while working the pre-existing test failures in my own lane. **This one is yours, and it is the
highest-value item in this handover**, because a guard is already failing over it on every test run.

`tests/testthat/test-structured-re-conversion-contracts.R` fails 22 assertions in a single test,
"q-series v1 readiness reset separates basic-working from support". It shells out to
`tools/qseries_v1_claim_guard.py` and `tools/qseries_v1_release_check.py`; both exit 1.

**Classified as a REAL DEFECT, not a stale test — and the adversarial reviewer returned SOUND.**
The guard is working exactly as designed. `README.md` fails two of its requirements:

1. it no longer links `docs/dev-log/release-audits/q-series-v1-release-status.md`, and
2. it contains no `q=12` capability mention, while **four q12 cells sit admitted in the ledger**
   (`qseries_{phylo,spatial,animal,relmat}_q12_all_four_two_slope`, all `fit_status=point_fit`,
   `interval_status=planned`, `coverage_status=planned`).

`ROADMAP.md`, `NEWS.md`, and `docs/dev-log/known-limitations.md` all still satisfy both. **README is
the sole outlier.**

**Provenance, and why this should interest you:** `git log -S` shows the link was last present before
`e7ac5896` — *"docs: correct pre-CRAN capability claims (#810)"* — whose landing-page compaction
deleted the README capability matrix wholesale, taking the q12 rows with it. A later commit in that
same PR restored only the subset the Python ledger unittest enforces, and its own message records the
state as open: *"The guard tests were NOT modified. They are the repo's anti-erasure protection and
they did their job here… Whether capability detail should ultimately live on the maps instead of
README is a separate, reviewable decision."* **No decision has since superseded it.** So this is the
same landing-page rewrite that started this whole arc, still leaking.

**The required change is entirely in your lane (README.md):** restore the status-document link;
restore a q=12 statement covering the four admitted cells *at their ledger tier* (point-fit/recovery
only, intervals and coverage planned — `ROADMAP.md:588-590` already carries usable wording); and
ensure any line containing "Q-Series" also carries a boundary term, or the guard's inflation check
fires. Those three edits reportedly take the cluster from 22 failures to 0.

**Do not "fix" it from the tooling side.** Removing `README.md` from `PUBLIC_STATUS_PATHS` /
`CATALOG_CAPABILITY_FILES`, emptying the `q12` dimension pattern, or retargeting the guard at
`ROADMAP.md` would clear the red by deleting the repo's only automated tie between the public README
and both the Q-Series release-boundary document and the set of high-q cells actually admitted. That
guard already caught one real erasure — this one. I have proposed no tooling change and made none.

The open question the #810 commit flagged — whether capability detail belongs on the maps rather than
README — is a maintainer decision. If it goes in favour of the maps, the guard should be retargeted
**deliberately, with a recorded rationale**, not as a way to clear a red test.

## 4. Conflict you should know about

Earlier today I wrote a Codex prompt for a **Julia-engine method documentation + pkgdown reference
index** pass, at
`scratchpad/codex-pkgdown-prompt.md`. It grants Codex `R/julia-bridge.R` (roxygen only), `man/`, and
**`_pkgdown.yml`** — the last two overlap your lane. It fences Codex *out* of `vignettes/`,
`README.md`, `NEWS.md`, `tests/`, and `tools/`.

If that session has started, you have a second writer in `man/` and `_pkgdown.yml`. **Recommend it be
paused or re-scoped to `R/julia-bridge.R` only until your epoch closes.** I have not started it; it
was handed to Shinichi to run.

## 5. What I continue doing (in-lane)

- Track B is **halted at the B3 compute gate** by design. Both reviewers returned NO-GO on the two
  meta_V campaigns and conditional GO / smoke-only on `mc-0181`. No compute started, none will start
  without maintainer authorization.
- Read-only verification of 3b, which produces evidence only.
- Simulation/test-side residuals: `test-phase18-actions-runner.R` (46 fail + 1 error, asserting a
  workflow deliberately stubbed under D-50), `test-structured-re-conversion-contracts.R` (22 fail,
  q-series readiness), two `beta-phylo-q1-sd-*-runner.R` setup errors. All pre-existing at
  `aa237a28`; Track A added zero failures.
- **Suite measurement caveat you will hit:** testthat's failure display caps at 10 and cannot be
  lifted by `options(testthat.progress.max_fails=)` or `TESTTHAT_MAX_FAILS`. A plain
  `devtools::test()` reports "10 failures" regardless of the true count. Use
  `as.data.frame(testthat::test_local(".", reporter = "silent"))`. True baseline is **68 failures +
  3 errors**.

## 6. Open question for you

Do you want my four reader-surface changes on `claude/0.6-dev-arc` reverted, left for you to adopt,
or left unmerged and ignored? Until you answer I will leave them exactly as they are and touch
nothing further in your lane.

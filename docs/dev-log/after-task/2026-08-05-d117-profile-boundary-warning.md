# After-task — the `profile.boundary` user warning, D-117's last open item

**Date:** 2026-08-05 · **Platform:** Claude (Claude Code), solo ·
**Lane:** drmTMB D-117 close-out — the profile boundary warning ·
**Foreign lane:** codex, draft PR #858 — no overlap; see §7.

## 1. Goal

Continue only the OWED Next Immediate Steps of
`docs/dev-log/handover/2026-08-05-claude-handover.md`. Reconciliation left exactly
one executable item: the `profile.boundary` user warning, the single thing gating a
"D-117 discharged" verdict. Promote nothing; change no census cell; leave the
withheld PASS withheld.

## 2. Outcome

`confint(method = "profile")` now warns when it returns a **usable** interval that
sits at a variance-component or correlation boundary, with condition class
`drmTMB_profile_boundary_warning`. Shipped with tests, a `NEWS.md` entry, and a
**Boundary intervals** section in `?confint.drmTMB`.

The asymmetry this closes: the Wald path warned at a boundary and told users to
switch to `method = "profile"`, and the profile path — measured at 0.0732–0.8566
conditional coverage against a nominal 0.95 — said nothing. The package was routing
users out of one unreliable regime into a worse one, silently.

Census **182 `interval_feasible` / 60 `point_fit_recovery`, unchanged**;
`capability_ledger.py --check` OK before and after.

## 3. Rehydration — the handover reconciled against git

`origin/main` had advanced from the handover's `a7ef0d33c` to `8086c3ee1`, so step 1
(merge PR #922) was already **DONE** — `8086c3ee1` *is* that merge. Of the five
Next Immediate Steps, one was OWED to this lane; two were resolved by the owner
mid-session (see §5); one is a different repository; one is owner-only.

A discrepancy worth recording: the primary checkout's local `main` ref is **593
commits behind** `origin/main` and sits on a July-18 branch. Every claim in the
handover verified correctly against `origin/main` and would have read as *missing*
against the local ref. This is the checkout-versus-repo trap the cross-repo guards
name; work was done in a fresh worktree, and files were read with
`git show origin/main:<path>`.

## 4. What was built

A single helper, `warn_profile_boundary()`, called from the tails of
`drm_profile_confint()` and `drm_profile_response_newdata_confint()` — the two
choke points every profile engine (`tmbprofile`, `endpoint`, `clamp_limited`) flows
through, so no engine can route around it.

The predicate is deliberately **narrower** than `profile.boundary == TRUE`:

```r
!is.na(profile.boundary) & profile.boundary &
  conf.status == "profile" & is.finite(lower) & is.finite(upper)
```

`profile_interval_diagnostics()` sets `boundary = TRUE` for four distinct cases.
Two of them (`nonfinite_interval`, `point_estimate_outside_interval`) become
`conf.status = "profile_failed"` with missing endpoints, and `clamp_limited`
likewise. Warning about the *coverage* of an interval that was never returned is
noise, and those rows already report themselves through `conf.status`. The warning
therefore fires on exactly the population `VERDICT.md` measured: a usable interval
resting on a boundary.

## 5. Decisions

1. **Warn, do not discard.** The interval is still returned, matching the Wald
   path's existing contract that a boundary is a warning rather than an
   auto-discard.
2. **Attribute honestly in the user-facing text.** The warning and its docs say
   coverage is poor *there*; they do not imply a drmTMB defect, because `lme4`
   reproduces the same numbers on the same seeds.
3. **The warning points at documentation that exists.** The message references the
   **Boundary intervals** section of `?confint.drmTMB`, and that section was written
   in the same change rather than left as a dangling cross-reference.
4. **Do not discharge D-117.** Landing this closes the last *item*; whether the
   gate is satisfied is the owner's judgement (§10).

## 6. Verification

- `test-profile-targets.R` — **all pass, 0 failures**. Two new unit tests cover the
  predicate and its four silent cases; the pre-existing `near_sd_boundary`
  animal/relmat test now asserts `expect_warning(class =
  "drmTMB_profile_boundary_warning")`, which proves the warning fires from a real
  `confint()` on a real fit, not only on a synthetic row.
- **Red proof:** `warn_profile_boundary()` does not exist on `8086c3ee1`, so
  `drmTMB:::warn_profile_boundary` errors there. The tests cannot pass without the
  change.
- `devtools::document()` — clean; only `man/confint.drmTMB.Rd` changed (+29).
- Full `test_dir()` suite — see §8.
- Census 182/60 verified from
  `docs/dev-log/dashboard/capability-census/_master.tsv`; ledger check OK.

## 7. Lane check

`lane_preflight.sh` reported **FOREIGN LANE ACTIVE (codex)**, draft PR #858. Its
files are `AGENTS.md`, docs, `inst/sim/`,
`tests/testthat/test-interval-campaign-readiness.R`, and `tools/` — no intersection
with `R/profile.R`, `test-profile-targets.R`, `NEWS.md`, or
`man/confint.drmTMB.Rd`. The owner separately established that #858 is a
**fail-closed pre-flight builder** that could not have collided regardless. Only
`AGENTS.md` is shared, and #858 is a week-stale draft needing a rebase either way.

## 8. Test-suite result

Full `test_dir("tests/testthat")` over **308 test files: 0 failures, 0 errors.**

20 warnings surfaced, **all pre-existing and none from this change**: bootstrap
non-convergence under an unsupported RE structure
(`test-simulate-re-form.R:183`), a Tweedie false-convergence
(`test-tweedie-location-scale.R:343`), and two `log(sigma)` upper-clamp warnings
(`test-zi-nbinom2.R:164`, `:281`). The new
`drmTMB_profile_boundary_warning` appears **zero** times as an unhandled warning —
the only place it fires is the animal/relmat boundary test, which now asserts it.

Also green: six Python CI guards (`test_capability_ledger` 54 tests,
`test_arc1_profile_reconcilers`, `test_b3_q6_target_promotion`, `test_b4_ci_guard`,
`test_b4_ci_c1`, `test_profile_truth_gate`), and
`tools/check-evidence-citations.R` (37 rows, 0 violations).

## 9. Deferred, explicitly

Unchanged and untouched: the 135-trace interval campaign (182→196); the `predict()`
scale-axis defect (its gate test **pins** current behaviour and must fail when
`predict()` is fixed — update it then, never relax it); the CI guard/check split;
the B4-CI `SOURCE_COMMIT` port; mc-0282's runner contract (PROTECTED).

Also not done here: extending the gate to the 14 newly-reachable Prong B routes
(this measured the A1 **scalar Gaussian** corner only), and the identical
`timeout-minutes: 45` latent fault in
`drmSEM/.github/workflows/R-CMD-check.yaml:22` — a different repository, so a
separate lane.

## 10. Open for the owner

- **Is D-117 discharged?** The measurement exists, the last item is closed, and the
  conditional finding remains adverse. The withheld PASS stays withheld either way;
  discharge is a separate judgement about whether the *gate* is satisfied.
- **A separate live lead — which the evidence says is NOT D-117's mechanism.** A vault
  note from another session, *"Log-parameterised variances have an attracting boundary
  at zero — warm starts can inherit a collapse"* (gllvmTMB, 2026-08-03), describes a
  real and generic property of `exp(log_sd)`: the chain rule gives
  `∂f/∂(log σ) = (∂f/∂σ)·σ`, so the gradient flattens as `σ → 0` and the optimiser
  stops while reporting clean convergence.

  My first reading was that this explained D-117's 9.1–16.9% low RE-SD bias. **The
  comparator argues against it.** `lme4` does not parameterise the SD on the log scale,
  yet agreed on boundary incidence 4000/4000 and matched conditional coverage to four
  decimal places. A log-coordinate optimiser artifact should have made the two engines
  diverge; they did not. The honest reading is that D-117's bias and undercoverage are
  **genuine small-sample ML behaviour** — a real point mass at zero and real profile
  undercoverage there — not an optimiser pathology.

  Where the note *does* bite is separate and untested: `R/profile.R:3303-3308`'s
  endpoint solver warm-starts from a bracket point and retries from the free optimum
  **only when convergence is not accepted** (issue #705). An attracting-boundary
  collapse converges *cleanly*, so that fallback cannot detect it by construction. That
  is a structural blind spot worth a targeted test, independent of D-117. The note is
  left uncommitted, as it belongs to another session.

## 10b. A hypothesis raised and REFUTED — do not rebuild it

Recorded so a future session does not spend a Totoro campaign on it.

**The hypothesis.** `R/profile.R:3117` uses `stats::qchisq(level, df = 1) / 2`. A variance
component *at a boundary* has a chi-bar-square LR reference, not χ²₁ (Self & Liang 1987;
Stram & Lee 1994). The brain has documented this since 2026-07-22 and had already flagged the
identical `qchisq(level, 1)` as a defect in **gllvmTMB**; drmTMB was never connected to it
(`grep -rin "self-liang\|chi-bar" R/ docs/design/ NEWS.md` → zero hits). That made the lme4
agreement look like two engines sharing one wrong assumption rather than exoneration.

**Why it does not hold.** Three reasons, increasingly decisive:

1. **Scope.** The 50:50 χ²₀:χ²₁ mixture is the null for *testing* a variance component at zero.
   A confidence interval inverts the LR test at *interior* candidate values, where the null is not
   on the boundary and ordinary χ²₁ applies. The sources treat it as an LRT property and never
   warrant the transfer to interval inversion.
2. **Direction.** Even granting the transfer, the corrected cutoff is
   `qchisq(2 * level - 1, df = 1)` — at 0.95 that is `qchisq(0.90, 1) = 2.706` against the current
   `qchisq(0.95, 1) = 3.841`. It is **smaller**, so intervals get **narrower** and conditional
   coverage gets **worse**. The proposed fix moves the number the wrong way.
3. **It is a selection effect, not a calibration error.** Conditioning on
   `profile.boundary = TRUE` selects replicates whose SD estimate collapsed toward zero; those same
   replicates have low upper endpoints and so miss a non-zero truth almost by construction.
   Unconditional coverage is fine (0.914–0.937) *because* the interior over-covers (0.966–0.983)
   while the boundary sub-population under-covers. `VERDICT.md` §2.1 already framed this correctly.
   This is post-selection inference; no cutoff choice repairs it.

**What this does to D-117's verdict: it strengthens it.** "Not a drmTMB defect" has now survived a
concrete mechanistic challenge naming a specific line and a specific correction. It also confirms
the user-facing warning is the *right* remedy rather than a stopgap — the boundary sub-population
genuinely cannot be handed a nominal interval by adjusting the cutoff.

**Still open, and NOT this:** the small-sample *width* correction
(`qchisq(1-a,1) -> qt(1-a,df)^2`, issue **#680**, D-12(b)) is a different fix for a different
problem. D-12 separates them deliberately; do not merge them. Separately, gllvmTMB's flagged
`qchisq(level, 1)` is untouched by this finding — whether it is a real defect there depends on
whether that call sits in a test or an interval, which nobody has checked.

## 11. Resolved during this session by the owner

- `codex/sd-bootstrap-r999-diagnosis` (`4cc837a85`) **pushed** — the release-gating
  evidence is no longer on a single disk. Handover step 4 closed.
- **D-97's provenance corrected** (brain `bbe643b`), additively, with the original
  paragraph preserved verbatim. The decision itself was never at risk: both 0.9368
  and the reproducible 0.9400 sit far above the marginal route's 0.8714, so
  "profile beats marginal" survives either figure. Only the citation was wrong.
  Cite **0.9400, 3 cells, committed and hashed**.
- D-117's brain entry and its D-88 lane note closed.

# Handover (2026-07-20): 0.6.0 truth-freeze ready for PR-2; zero-one-beta Totoro rerun at the approval line

Continuing the drmTMB pre-release close-out in one Claude lane. Read `AGENTS.md`, then this, then
`~/.claude/plans/cosmic-foraging-quail.md`.

## State at handover

- **Arc A (D2, #58): DONE & MERGED** — PR #801 merged to `origin/main` @ `ac378024`; #58 closed.
- **Arc B (0.6.0 truth-freeze): content COMPLETE, gates GREEN, PR-2 opening.**
- **Zero-one-beta strictly-interior rerun: ADJUDICATED AGAINST (no compute).** Spec was written,
  Fisher/Noether/Rose-reviewed; Fisher showed no faithful strictly-interior rendering of the intended
  DGP exists, so Shinichi decided the generator-qualified fence is the principled terminal answer. The
  couple/decouple question is therefore moot — PR-2 carries the final claim.

## Workspace

Standalone clone OUTSIDE Dropbox: `~/worktrees/drmTMB-release-arcs`. Arc B branch:
`claude/release-0.6.0-truth-freeze` (pushed). Never `git worktree add` under `Github Local/` (D-69).

## Arc B — what is committed on the branch (7 commits ahead of main)

1. Version reconciliation — README / `_pkgdown.yml` / ROADMAP (dev 0.6.0.9000 vs latest tag v0.5.0).
2. `capability-and-limits.Rmd` — added the 5 promoted ordinary mu-slope cells + zero-one-beta caveat.
3. Release-scope manifest — `docs/dev-log/release-audits/2026-07-20-0.6.0-release-scope-manifest.md`.
4. Manifest issue-action record + link to #802.
5. Noether overclaim fix — cumulative-logit floor M=40 → **M=80** (M=40 exploratory) in manifest +
   vignette; §1c Wald line to seven fields.
6. After-task report.
7. (this handover).

Gates: `rcmdcheck(--as-cran)` = 0 errors / 0 warnings / 1 benign NOTE (dev-version suffix).
Full site build on corrected content — **confirm 33 articles before merge** (was running at handover).
Ledger verified consistent (`--check` OK, unittest 37/37, runtime 18 routes).

GitHub actions already applied (Shinichi pre-authorized "approve"): closed #58/#342/#747/#748;
D-50 comment on #59; Phase-20 gate list on #61; filed #802 (regression-`rho12` interval gap).

## Two overclaims caught this arc (both corrected)

- Author-caught: the 5 promoted mu-slope cells have THREE distinct floors, not one — skew-normal/
  Tweedie/zero-one-beta M≥16 (SD 0.50, ML-Laplace); binomial M≥32 (SD 0.6); cumulative-logit M≥80
  (SD 0.50, AGHQ+Cox-Reid).
- Noether-caught: cumulative-logit floor was written M=40 (grid minimum) not M=80 (certified). Fixed.

## Zero-one-beta rerun — CLOSED (adjudicated against)

Fully resolved this session; nothing to resume. The strictly-interior rerun was specified
(`scratchpad/arcB-zeroonebeta-rerun-SPEC.md`) and Fisher/Noether/Rose-reviewed **before any compute**.
Fisher's probe (`scratchpad/leak_shape2_probe.R`, confirmed analytically) showed no strictly-interior
sampler can faithfully render the intended beta — the intended law puts ~16–69% of its mass within one
machine ULP of the boundary at the leaked shapes, at the identifying tail. Shinichi decided: **don't
run** — the generator-qualified fence is the principled terminal characterization. Recorded in manifest
§2a/§6 and the vignette caveat. Zero compute. Rose's "campaign never ran" flag was a verified false
alarm (mc-0575 IS promoted; artifact exists; #800 certified it).

If ever revisited: a *different intended design* (a `phi` that keeps the interior representable) is the
only path to a "design-clean" claim, and it is a new DGP/estimand — a separate future arc, not a rerun.

## Resume command

```
Rehydrate from docs/dev-log/handover/2026-07-20-release-freeze-and-zeroonebeta-rerun-handover.md plus
~/.claude/plans/cosmic-foraging-quail.md. In ~/worktrees/drmTMB-release-arcs on
claude/release-0.6.0-truth-freeze: confirm the site build is 33/33, then either open PR-2 (decouple) or
hold for the rerun (couple) per Shinichi. For the Totoro rerun: fold the three spec reviews, present to
Shinichi, and STOP for explicit run-approval before any compute.
```

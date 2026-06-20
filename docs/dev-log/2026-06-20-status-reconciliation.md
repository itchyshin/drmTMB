# Status Reconciliation — can we reduce the partial/planned cells? (Ada, 2026-06-20)

**Question (maintainer):** the mission-control widget still shows a lot of
`partial`/`planned`; can we reduce it?

**Method:** an evidence-driven reconciliation (4 mappers + Rose/Fisher
adversarial verification + Ada synthesis) examined every `partial`/`planned`
cell across the finish matrix, the finish-board, the Julia bridge capability
and gate rows, and the queued phases — **132 cells**. Each cell was checked for
concrete gate-meeting evidence *in its own lane* (native R/TMB, direct DRM.jl,
or Julia-via-R bridge).

## Verdict: the statuses are honest. 0 legitimate promotions tonight.

- **132 cells → 2 promote-candidates → 0 confirmed by Rose+Fisher.** The two
  candidates were no-ops (cells already `covered`). No status is meaningfully
  *too* conservative.
- The boundaries are working as designed. Reducing `partial`/`planned` is not a
  status-flip; it requires **producing the gated evidence** (recovery/coverage/
  power simulations for native cells; R-to-Julia parity tests for bridge cells).
- The DRM.jl full suite passing tonight (228 testsets, 0 failures; Aqua 10/10)
  is **direct-DRM.jl engine-health evidence**. It is banked on the DRM.jl lane,
  but by the lane-separation boundary it does **not** promote any Julia-via-R
  bridge cell or native-TMB cell. The bridge capability rows correctly stay
  `experimental`/`planned` (parity is smoke-only; real R-to-Julia parity tests
  exist for just Route C and Route B).
- Genuinely blocked (do not touch as quick wins): q8 covariance intervals (zero
  pdHess — needs transform + gradient + interval-method rework), cross-family /
  `engine_control` / AI-REML cells (owner decision + design gates), all Phase 6
  missing-value cells (each needs a design-gate doc that does not yet exist).

*(Caveat: the synthesis agent's shell defaulted to the stale primary checkout
`b4a4d7be` and reported `status.json` as "stale / 7-row". On the working tree
`540b` (= `origin/main` `bd1f3e46` + this branch) the dashboard is current
(updated 2026-06-20, 17 matrix rows) and the banked binomial evidence is on
main. That "off-main / stale" framing is a cwd artifact; the 0-promotion verdict
is unaffected.)*

## Prioritized evidence-path to actually reduce partial/planned

Highest leverage first; lane in brackets. Items 1–4 are cheap (merge/sync/one
sim); 5–9 are bounded ADEMP/test work; 10 is genuinely blocked.

1. **Merge the already-banked binomial evidence + this branch to main** [logistics].
   The 500-rep Wald interval calibration and glm-parity comparator already exist;
   landing them firms the binomial `wald`/`simulation` cells on main. Pure logistics
   (held for owner push).
2. **Binomial fixed-effect profile-interval calibration sim** [native]. One
   ADEMP on the `mu` coefficients promotes the cluster of binomial `profile`
   cells (matrix + 3 finish-board rows) — highest cell-count per sim.
3. **Binomial coverage visual** (Wald-vs-empirical + heatmap) [native, Florence].
4. **Sync status.json + a cell-id→row crosswalk** [infra] so future promotions
   are mechanically applicable.
5. **rho12 ~ predictors fixed-effect recovery ADEMP** [native] — the lead-novelty
   row; unblocks the whole rho12 profile/bootstrap/bridge chain.
6. **Student-t nu profile/bootstrap consolidation** [native] — evidence largely
   exists (2026-06-19 diagnostics); add a coefficient-recovery grid.
7. **Skew-normal guard-grid → recovery** [native] — convert the diagnostic-hold
   grid into a recovery lane.
8. **One Julia bridge per-cell parity sim** [bridge] — native vs `engine="julia"`
   vs direct DRM.jl on one supported cell (Gaussian phylo mu or q4 rho12),
   recording point/SE/logLik/pdHess max-diff. Proof-of-pattern that unblocks the
   bridge registry simulation cell.
9. **q2 ordinary-hardening PSD / name-alignment test suite** [native].
10. **q8 transform+gradient+interval rework** [native] — deferred; genuinely
    blocked, not a quick win.

## Net

The dashboard is honest; its near-term ceiling is suppressed mainly by
un-merged evidence (item 1) and bounded sim work (items 2, 5–9), not by missing
science. About a third of the backlog is cheap, a third is bounded simulation,
and a third is legitimately blocked behind design gates or owner decisions.

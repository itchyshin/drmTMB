# arcs.md — parity-joint-20260905 (status-marked; gates flagged)

Legend: [ ] pending · [~] in progress · [x] landed (verified) · [!] OPEN GATE (needs Shinichi) · [-] abandoned (reason in checkpoint)

## Foundation (serial)
- [~] A0   re-pin e0a65f96b → 430ef64cc — sweep running (~/local-scratch/parity-joint/a0-sweep.log); then breakage conversion (if any), receipt LAST, PR. Ledger leaf-a0.
- [~] A0.5 family registry (R/julia-family-registry.R) — DONE + pinned 462/0/0; PR drmTMB #1162 in merge gate. Ledger: the registry test IS the gate.
- [~] A0.v vendor Totoro run_suite.sh — DRM.jl PR #638 in merge gate.

## The fan-out (ULTRACODE; launches when A0 + A0.5 are on main)
- [ ] A1  CI trust (#1083 #1081 #1150) — leaf-a1
- [ ] A2  THE MATRIX generator + admitted-needs-row test — leaf-a2
- [ ] A3  ledger the 9 working-but-unledgered routes (student, lognormal, FE gamma/poisson/nbinom2/beta, ZIP, ZINB, hurdle) — leaf-a3
- [ ] A4  admit the 6 refused families: tweedie · skew_normal(needs DRM.jl case) · zero_one_beta · beta_binomial · truncated_nbinom2 · cumulative_logit — leaf-a4-<family> ×6
- [ ] A5  ordinary RE census + rows — leaf-a5
- [ ] A6  formula constructs (#467 + #609 factors) — leaf-a6, DRM.jl PR first
- [ ] A7  U ports: #1116 lrt-boundary · #1117 model-comparison · #1118 coevolution-accessors — leaf-a7-<slug> ×3
INTEGRATION ORDER: A3 rows → A4 rows → A2 last (regenerates over everything) → tip-identity receipt once, by the integrator.

## Qualification
- [ ] A8  G3 bridge-side inference (profile + bootstrap, small cells, LOCAL) — unblocks TSV rows 2/3/5/12
- [ ] A9  remaining P: DRM.jl #620 two-SD slope · #609 varying-scale · #1156 profile_targets · #1144 cutpoint polish · #569/#1108 diagnostics consumer
- [ ] A10 P4 warm-workflow grid — PRE-RUN on Totoro (<10 min) then [!] FULL GRID = OPEN GATE, ask in the morning

## Closure
- [ ] A11 matrix regenerated · scoreboard · capability-status join · NEWS both · DESCRIPTION 0.7.1 PREPARED (not tagged) · Melissa · Rose · handover

## Corrections to the plan made by measurement (so the morning report is honest)
- A4 was "9 families"; it is 6. ZIP/ZINB/hurdle are zi/hu dpars on poisson/nbinom2 and ALREADY FIT through the bridge (ZIP logLik −176.9550 on both engines). Moved to A3 as unledgered routes. The scout's List A1 was built from the family-tag list without executing — the same error class as the bivariate blocker.
- DRM.jl's bridge already accepts 5 of the 6 (tweedie, zero_one_beta, beta_binomial, truncated_nbinom2, cumulative_logit); only skew_normal needs a Julia-side case.

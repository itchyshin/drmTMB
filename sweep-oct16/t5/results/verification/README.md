# t5 verification record

Four DRModels.jl candidate findings (C1 Union-eltype predictor, C2 NaN predictor,
C3 missing group label, C4 `g_tol` on the ordinary-Laplace route) were each
checked by two independent agents: a reproduce-and-trace lens and a
skeptic/triage lens that tried to refute them. A completeness critic then
reconciled the two lenses and audited the lane's coverage. `verdicts.json` holds
the eight structured verdicts. `critic.md` holds the reconciliation and the
venue decisions that were acted on: C1 → DRModels.jl#1111, C2 → #1113,
C3 → #1112, C4 → comment on #947.

The verifiers' scratch scripts lived in the session scratchpad (shown here as
`<scratchpad>`) and were not committed. The committed repro scripts under
`../../repro/` regenerate every number the issues cite.

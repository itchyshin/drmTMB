# 0.7.1 ordinary-Laplace task provenance guard

The four-fixture runner now emits one immutable-looking provenance row beside
each engine--target task. It records the clean drmTMB and DRM.jl heads, runtime
identities and thread settings, requested and effective routes, the
family-specific marginal-objective convention, and the runner digest.

Reconciliation requires the exact schema, current clean source heads, and the
declared route for every returned fit. A failed fit retains its request and
objective convention but has no invented effective route; it remains in the
denominator as `fit_failed`. This preserves a classified failure without
mistaking a failed invocation for a completed integrator route.

Checks run on 2026-09-09:

- `Rscript -e '... parse(file = "run-four-fixture-receipt.R"); parse(file = "reconcile-four-fixture-receipt.R") ...'` printed `RECEIPT_PARSE_PASS`.
- Reconciling the retained pre-guard `nb2_coupled` sidecars failed closed with
  `missing TMB provenance receipt`; it did not generate an aggregate receipt.
- A bounded native Binomial intercept task completed in 11 seconds and wrote a
  current task sidecar with clean heads, `TMB 1.9.21`, and
  `tmb_joint_laplace`. Its native profile endpoint was finite
  (`[-0.8745019, 0.1289323]`). This smoke test exercises the receipt writer,
  not R--Julia parity: no paired Julia task or aggregate receipt exists.

This is receipt-infrastructure evidence only. No current-pin point/profile
receipt, parity matrix, cost estimate, or coverage result has been produced.

The writer/validator schema-order regression was found by the first complete
Binomial reconciliation and repaired before widening. Its current-pin receipt
then reconciled all six engine--target tasks: both fixed-effect profiles were
finite and close (intercept endpoint differences about `1.3e-5`; slope about
`3.3e-5` lower and `2.5e-5` upper), while native `sd:mu:(1 | group)` returned
`nonfinite_endpoint` and Julia returned `[0, 1.1270975]`. This is an adverse,
retained target classification, not a Binomial profile-parity pass; the other
three fixtures, matrix, cost probe, and coverage campaign remain unrun.

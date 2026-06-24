# After Task: Ayumi Native ML Summary

## 1. Goal

Bank A029-A030 by rechecking scale-side diagnostic evidence and writing a short
native ML balance summary for the Ayumi arc.

## 2. Implemented

Re-ran the scale-side phylo identifiability tests, which cover the existing
`scale-phylo-diagnostics.tsv` rows, including the clamp-active diagnostic row.
Added `docs/design/198-ayumi-native-ml-balance-summary.md`, which explains
what native TMB ML supports today, what it does not claim, and what an applied
reader can try without confusing ML, REML, bridge, q4, or interval claims.

## 3a. Decisions and Rejected Alternatives

The summary stays local and does not draft public issue prose. It names native
ML as balanced for the univariate Gaussian mean-only, scale-only, and matched
mean-plus-scale `phylo()` layouts, but it explicitly rejects native REML,
coverage, q4 REML, and 10,440-tip interval promotion.

## 4. Files Touched

- `docs/design/198-ayumi-native-ml-balance-summary.md`
- `docs/dev-log/dashboard/ayumi-phylo-balance-100-slices.tsv`
- `docs/dev-log/after-task/2026-06-22-ayumi-native-ml-summary.md`

## 5. Checks Run

```sh
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "scale-phylo-identifiability", reporter = "summary")'
```

The focused scale-phylo identifiability tests passed.

## 6. Tests of the Tests

The scale-phylo test file exercises the null mean-only branch, positive
`pdHess` branch, non-positive-Hessian guidance branch, clamp-active coexistence
branch, and no-`sdreport` branch. The A029 claim depends specifically on the
clamp-active coexistence row.

## 7a. Issue Ledger

No GitHub issue was edited. The summary supports the local Ayumi balance arc
and remains below the explicit reply gate.

## 8. Consistency Audit

The summary cites local dashboard and after-task evidence and keeps native ML,
native REML, bootstrap accounting, recovery smokes, q4, and bridge routes
separate. It does not use release-ready or public bridge-promotion wording.

## 9. What Did Not Go Smoothly

No new technical blocker appeared in this slice. The main risk was prose drift,
so the summary was kept short and evidence-linked.

## 10. Known Residuals

Native REML asymmetry is the next wave. The summary does not solve scale-side
native REML, matched native REML, q4 REML, Julia speed, beak rescue, or
Ayumi-scale interval inference.

## 11. Team Learning

The applied-reader answer should start from route and estimator. "Native ML is
balanced for these univariate Gaussian layouts" and "native REML is not
balanced" can both be true when the evidence rows are kept separate.

# After-task — Lane C Z7 zero-one-beta sigma phylo-interaction q1

## 1. Goal

Recover only `mc-0597`: ordinary ML zero-one-beta with one unlabelled q1
phylo-interaction random intercept on `sigma`.

## 2. Implemented

The exact parser, active carrier, extraction, target fence, dense Kronecker
oracle, and retained four-seed local recovery fixture are present.

## 3a. Decisions and Rejected Alternatives

Only the intercept-only `plant:pollinator` formula with two supplied trees is
admitted; slopes, labels, other dpars/providers, and covariance remain closed.

## 4. Files Touched

The scoped R/parser/test commits and the interaction recovery runner/receipt
provide the candidate evidence. Ledger transition awaits review.

## 5. Checks Run

Focused zero-one-beta tests passed; the independent Kronecker oracle agreed
with objective and AD/FD gradient; all four retained local attempts passed.

## 6. Tests of the Tests

The oracle independently creates `Q2 %x% Q1`, checks latent ordering and log
determinant, and includes zero/one/interior likelihood terms.

## 7a. Issue Ledger

No ledger move occurs in this receipt. A later reviewed move may claim only
technical point-fit recovery.

## 8. Consistency Audit

Formula, DGP, oracle, and fitted carrier all order plant within pollinator and
put the latent field on log-sigma.

## 9. What Did Not Go Smoothly

This singleton requires a separate Kronecker DGP and oracle; no provider
evidence was reused.

## 10. Known Residuals

This does NOT cover profiles, intervals, coverage, slopes, labels, covariance,
other providers/dpars, or inference readiness.

## 11. Team Learning

Kronecker routes must specify the cross-factor ordering explicitly in both DGP
and oracle; matching dimensions alone is not sufficient.

## 12. Cross-Product Coverage

This Z7 phylo-interaction q1 receipt covers only sigma with two fixed trees; it does NOT cover Lane A association, Lane B scale/interval work, the Future-extension audit, other dpars/providers, public defaults, or API surface.

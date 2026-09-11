# Phylogenetic temporal OU planning closeout

## 1. Goal

Produce a reviewable Ultra Plan and Unlazy acceptance ledger for drmTMB's next
temporal extension: a phylogenetically correlated stable intercept combined
with the completed independent-series OU process, with a separately scoped
future phylogeny-by-OU field and an evidence-based temporal covariance roadmap.

## 2. Implemented

The plan fixes the first slice as a phylogenetically correlated stable
intercept plus independent within-species OU process. It supplies its formula,
covariance, admissions, reductions, uncertainty boundary, calibration design,
execution route, documentation scope, and 19-gate Unlazy ledger.

## 3a. Decisions and Rejected Alternatives

The first slice excludes the separable phylogeny-by-OU field. That field is a
later model with cross-species temporal covariance and must not enter as an
undocumented option. Homogeneous Toeplitz is the next purely temporal candidate
after the phylogenetic-OU programme; heterogeneous structures and seasonal,
trend, ARMA and Matérn models need their own scientific cases.

## 4. Files Touched

- `docs/dev-log/plans/2026-09-09-phylo-temporal-ou/PLAN.md`
- `docs/dev-log/plans/2026-09-09-phylo-temporal-ou/unlazy/GATES.md`
- `docs/dev-log/check-log.md`
- this report

## 5. Checks Run

The bundled Node runtime parsed the ledger with
`gate-check.mjs --status`. It found exactly 19 uniquely identified, intentionally
unmet gates and did not execute or approve any future gate command. `git diff
--check` passed.

## 6. Tests of the Tests

The ledger’s G3/G6 require a fixture where the phylogenetic off-diagonal,
temporal SD, positive decay and cross-species time gap are all nonzero. Their
wrong separable covariance must fail. G11 requires the campaign assessor to
reject incomplete denominators, forged provenance and a known failing coverage
fixture.

## 7a. Issue Ledger

Open [#1302](https://github.com/itchyshin/drmTMB/issues/1302) already tracks
this exact phylogenetic temporal OU programme. No duplicate issue or external
message was created.

## 8. Consistency Audit

The plan reuses the completed independent-series OU provider and the existing
phylogenetic precision provider, but does not treat either as evidence for the
new combined covariance or its profile intervals. The plan’s dense oracle and
calibration campaign therefore have separate gates.

## 9. What Did Not Go Smoothly

The first plan review exposed an ambiguous AR1 reduction and a calibration
contract too weak to support its claimed profile requirement. Both were repaired
before this closeout and independently re-reviewed.

## 10. Known Residuals

G0 is pending user approval of the exact execution source pin and campaign
boundary. All implementation, simulation, rendering, campaign and package gates
remain pending by design. The current plan does not authorize remote submission,
push, merge, release or a gllvmTMB port.

## 11. Team Learning

For a covariance model that resembles a future separable model, one cross-term
must be chosen so the intended and wrong covariance differ numerically; a
named mutation then prevents the two scientific estimands from silently
collapsing into one implementation.

## 12. Cross-Product Coverage

This plan covers one univariate Gaussian ML, constant-residual-scale,
phylogenetic-stable-plus-independent-OU intercept model. It does not cover the
separable phylogeny-by-time field, AR1 in this new paired provider, temporal
slopes, ordinary same-species intercepts, non-Gaussian families, REML,
forecasts, `newdata`, variance/decay intervals or generalized temporal
covariance structures.

# Curie M1 fixtures and comparator receipt

## 1. Goal

Retain independent literal datasets, designs, fixed coefficients, a state-path enumeration truth and an external CJS comparator. This receipt was completed by the parent after the fixture worker returned ownership without its requested report.

## 2. Implemented

Shared CSV fixtures cover irregular intervals, survey masks, administrative endpoints, different first captures, a final-first history, factor coding, offsets and integer frequencies. Base and shuffled-key cases use the same numbers. The eight-history marked comparison expands to 44 individuals.

## 3a. Decisions and Rejected Alternatives

Compare native likelihoods at fixed supplied coefficients rather than requiring identical optimizer paths. The marked comparator is narrower than the masked fixture. Only generated numerical outputs are retained; no comparator source enters either package.

## 4. Files Touched

Parity CSVs and manifests under `docs/dev-log/cmr/fixtures`; R `tools/check-cmr-parity.R`; Julia `tools/cmr_parity.jl`; the draft recovery manifest; this parent receipt.

## 5. Checks Run

The parent ran both native adapters. R gives -14.007848332069448 and Julia -14.007848332069447 in both key-order cases. Each passes the independent truth tolerance of 1e-10. Cross-language difference is 1.7763568394002505e-15, below 1e-8. Both native likelihoods match marked 1.2.8 at its saved coefficients with difference zero, log likelihood -86.998737757672856. Logs are `r-parity-parent.log` and `julia-parity-parent.log` in their respective roots.

The initial marked compilation and fit took 2.222 seconds; warm optimization took 0.219 seconds. Parent parity fits had a five-minute cap and finished within it. Version, source and DLL hashes are retained in `parity-marked-reference.json`. Compiler artifacts live only in `/private/tmp/cmr-programme/marked-backend`.

## 6. Tests of the Tests

Each adapter checks its native model columns and offsets against literal columns before checking likelihood. The R adapter independently enumerates absorbing alive/dead paths. Earlier runs failed on NULL CSV column classes, inherited gate arguments and a detection column-type count; parent repaired the adapter before its accepted run. These are checking-script failures, not likelihood disagreements.

## 7a. Issue Ledger

No public issues were created. Native fitted-optimizer equivalence, recovery and uncertainty remain pending. The recovery manifest is a draft, not run evidence.

## 8. Consistency Audit

Detection schemas use surveyed post-capture rows. Omitted emissions have neutral layout placeholders. Units are labels; lengths are already in those units. The same CSV bytes are supplied to both languages and file hashes are retained. Seed ranges in the recovery draft were separated by stage to avoid recycling screening datasets for qualification.

## 9. What Did Not Go Smoothly

The marked call compiled its backend despite compile=FALSE. Its files were relocated from the R root to an owned scratch directory; the original first-fit path remains disclosed in the provenance receipt. The CLI selector rejected the planned Luna model, so native explicit-model dispatch was used. The fixture worker omitted its report, which the parent supplied here.

## 10. Known Residuals

One external comparator cell does not validate every mask or interval convention. No simulations, coverage campaigns, random effects or selection fitting ran.

## 11. Team Learning

Test model-builder output before likelihood equality, and keep fixtures literal across languages. Memory receipt: parent-frozen contract and primary-source notes were inputs; no new second-brain claims were inferred. GoldenSet: independent enumeration and the wrong-likelihood controls remain the numerical fences.

## 12. Cross-Product Coverage

This receipt covers fixed-parameter native likelihood parity and a pinned constant CJS comparator. It does NOT cover native optimizer equivalence, prediction, simulation, calibrated inference, heterogeneity, selection, bridge transport, full package regression or publication readiness.

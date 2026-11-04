# ML-first SD article and gaps: plan versus current execution

Reader: Shinichi and the maintainer completing integration. Status: WORK IN PROGRESS, 4 November 2026. This record concerns the first delivery; the broader SD programme remains open.

## Provenance

The approved plan is `LOOP/lanes/sd-article-ml/ultra-plan.md`, with its source plan retained at `/Users/z3437171/Documents/Codex/2026-11-04-sd-article-plan/PLAN.md`. The execution lane is `codex/sd-article-ml`, based on R `9e2c03f6fdcb9091418cb629f2ca7f30da695e3d`. Numerical probes use Julia `f4fa3aed451636b6ffa442ce2632515513d23b1f`. The evidence prefix records current byte snapshots and explicitly separates them from final source-freeze execution proof.

## Material differences

| Planned work | Current result | Classification and consequence |
|:--|:--|:--|
| Audit source and evidence separately for every required row | All 21,246 rows preserved; six exact source-admission grants for the three article scopes; runtime/output/calibration fields remain separate | As planned; unlinked rows are unresolved evidence, not an implementation absence count |
| Consume existing structured stored-row exports | R bridge stored `mu` predictions now use validated structured fields; an adjacent Binomial inverse-link bug was found and repaired for explicit newdata too | Bounded neighbour repair; no new family, provider, predictor API or estimator |
| Reproduce numerical issues before prescribing fixes | Four NB2 seeds retain two nonconverged plain fits with worse objectives; two ZeroOneBeta seeds have mixed current outcomes; historical Binomial -26.9 lacks a seed/log | Probes completed within their stated scope; numerical defects are not declared fixed |
| Reuse the stored-loglik repair | Fix `8646e8d14` already exists; eight original NB2 probe fits have zero stored/current objective differences; accepted frozen regression passes 38/38 | Reuse and regression, with no new implementation |
| Admit continuous-predictor Gamma example only after checks | Native and bridge each match their own independent Laplace objective at `1e-5`; estimated ratio about 1.073 versus generating 1.492 | Admitted one-draw example; weak recovery remains visible rather than changing the seed |
| Match public native and bridge calls | Initial Julia call copied native `control(se=FALSE)` and was refused; default-control rerun passed | API correction with failed attempt retained; no tolerance or data change |
| Show matched R and direct-Julia guidance | R article expanded; Julia docs built twice and math/layout inspected; raw data pinned to immutable documentation ref e8a666769fc436e73c7121a4c49b1d9c92866776 | HTTP readback and final deployed-page checks await push/integration |
| Freeze source and binary through final focused checks | First batch's jobs all exited zero, but the LSS runner rebuilt the DLL; the guard rejected that binary transition. A fresh five-job batch exited zero with source and DLL unchanged | Predecessor retained; final batch accepted, without describing the predecessor as a functional-test failure |
| Walk the neighbours after the first prediction repair | Extreme cancelling fields exposed fitted/residual reconstruction loss; retained-link and retained-response repairs now pass 66 payload expectations plus neighbours/live checks | Bounded numerical-output repair; no changed likelihood or tolerance |
| Refresh canonical source receipt and complete independent review | Canonical LSS receipt refreshed against Julia c037268c76d29234a2174354ae4319b4d98e7c29; current-source checker PASS. Mechanical, reader and source/math completion reviews report no blockers in scope | Passed within the first delivery; broader programme and integration remain open |
| Close package and integration gates | Full package check, CI, PR merge, main and public-URL verification remain pending | Open, with no completion claim |

## Boundaries retained

G5 calibration and D-342 REML policy stay deferred. Structured stored conditional output does NOT cover fresh-data conditional extrapolation, conditional standard errors, every family/provider/block combination or direct-Julia conditional fitted values. The six source grants do not replace the original programme's remaining work. No campaign, release or external issue post was started by this report slice.

## Next action

Finish the full package check and CI, then verify gated merges plus main and public URLs before changing this record to complete. The canonical LSS refresh and three bounded completion reviews have passed their stated scopes. The accepted frozen batch and predecessor are retained separately in the evidence prefix; the numerical ledger retains all six ZeroOneBeta attempts.

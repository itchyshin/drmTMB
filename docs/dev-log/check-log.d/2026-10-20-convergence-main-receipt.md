# Main receipt refresh after the convergence documentation merge

The receipt-staleness guard failed on main 86814d69 before documentation PR #1596 and again on aa33f1e9 after it. Both runs report only R/julia-bridge.R as stale against the lss-tip-identity receipt. The source changed in #1586 and #1587; the convergence PR changed no R/ file.

Reran the unchanged tools/run-julia-phylo-labels-public.R on aa33f1e9 with Julia 1.13.0 and the original DRModels.jl pin da8b3f8711beb5ef3186b890544c2e7850c7f194, one Julia and BLAS thread. The 72-row, 12-label native/bridge/direct workflow passed all eight checks in 77.215 seconds. All coefficients and log likelihoods in the three fits exactly match the prior receipt. Data and labels are unchanged. The sole changed source-manifest entry is R/julia-bridge.R; runtime paths, DLL provenance and elapsed time are measured anew.

The receipt checker passed --current --self-test and rejected all 12 injected faults. The full staleness script passed with all 57 R/ and 95 backend source entries verified. No fitting source, runner, checker, tolerance or workflow was changed. CI and the new main guard are pending at commit time. This refresh addresses the pre-existing red main guard discovered while publishing the convergence table; it makes no wider interoperability claim.

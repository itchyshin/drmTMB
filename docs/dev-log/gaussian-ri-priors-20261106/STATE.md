# Gaussian random-intercept coefficient priors: current state

The approved slice is implemented in both isolated branches, `codex/gaussian-ri-priors-20261106`. No merge or release is authorized. Targeted random-effect SD/correlation priors remain a future proposal in NEXT-SD-COR.md.

## Source and protection

The validated R engine is commit `251d103b310cde7df68d0db439888f8c16177fbb`, based on `34c907e1c0be19553fa2e9153e2d3c2a72c86274`. The Julia engine is `f60eb88eebdaebc3b1ac1babb81aeb942f7dc8e8`, based on `86ee1c2a38cd79c55dbbd71afd7374a3095aad3c`. Both exact committed trees were staged on Totoro as shallow Git checkouts. Subsequent local edits concern documentation, evidence and the native R validation adapter's recorded multi-start configuration. Production engine code remains unchanged.

The four preexisting settings/hook files retain their initial SHA256 values and remain unstaged. Protected drmTMB PR #1651 was verified open and unmerged at head `1bf51e2d61bd1ce0a2fb3fad914a9888544af491`. Historical cleanup and C17 receipts remain untouched. No push, merge or release has occurred in this slice.

## Completed numerical qualification

Independent oracle self-tests, mutation controls and frozen manifest checks passed. Manifest SHA256: `c88140ec4222a3bf5a25b5132e6f05a0dd1183692db28540a76e1a93f3fa6474`. Fitted reference SHA256: `85db00122f23a2d9fc408cfc11ec85d4a1ca62d1f822dd3f544c36249603833f`. All 72 independent optimization attempts are retained.

All 36 configured fixture/route checks passed the unchanged independent oracle. Native R used the uniform policy in R-MULTISTART-POLICY.md. Native Julia and the bridge retained their original settings. The default run passed 35/36: native R ri_10 reached a genuine inferior local boundary minimum. Its failed result remains separate. No global optimization guarantee or default single-start 12/12 claim is made.

Selected raw results, the aggregate comparison and maximum errors are in final-numerical-evidence/. Each native engine has nine positive-group-SD point derivative checks and three exact-zero point value checks; fitted optima include six boundary cases. Exact-zero log-SD derivatives and arbitrary-point bridge derivatives are unavailable. Numeric indicator transport preserves the frozen matrices; the raw-factor bridge refusal remains.

## Reviews, examples and regression runs

Independent source and boundary-minimum reviews passed within their stated scope; see final-source-review.md and ri10-math-diagnosis.md. The final claims audit is in progress. The revised R article rendered successfully. Both current Julia prior-guide code blocks executed successfully against the pinned source. The full Documenter site has not been rebuilt. The numerical sparse-engine baseline returned log likelihood -256.5059 and converged under its existing tolerance. No paired speed claim is made.

The original Julia harness selected 560 files. Eight disjoint partitions of 70 files cover that selection exactly. Seven shards have exit0; shard8 remains live under `/home/snakagaw/hsq_work/ri-priors-final-julia-suite-20261106`. Each shard has a 10,200-second cap. JET checks passed in completed shards; optional R-parity is off.

R installation and full package build passed. Full R CMD check is running its package tests, with NOT_CRAN=true and no shard selection verified in the actual process environment. Source-tree manifest and test commands are queued in the same bounded runner. Receipts are under `/home/snakagaw/hsq_work/ri-priors-final-r-validation-20261106`. The final pinned live bridge-control test passed 63 expectations in 35.05 seconds, including selector/refusal and zero-ridge controls. Its raw log, source heads, test hash and loaded DLL hash are in final-focused-live/.

Next: finish regression and live-control checks, adjudicate any failures, update the final reports, and prepare one prior-only PR per package. Gates G5 and G6 remain open. Superseded checkpoint text is preserved in STATE-history-before-closeout.md.

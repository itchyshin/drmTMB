# Gaussian random-intercept coefficient priors: current state

The approved slice is being qualified in both isolated branches, `codex/gaussian-ri-priors-20261106`. No merge or release is authorized. Targeted random-effect SD/correlation priors remain a future proposal in NEXT-SD-COR.md.

## Source and protection

The validated R engine is commit `251d103b310cde7df68d0db439888f8c16177fbb`, based on `34c907e1c0be19553fa2e9153e2d3c2a72c86274`. The Julia engine is `f60eb88eebdaebc3b1ac1babb81aeb942f7dc8e8`, based on `86ee1c2a38cd79c55dbbd71afd7374a3095aad3c`. Both exact committed trees were staged on Totoro as shallow Git checkouts. Subsequent commits record documentation, evidence, the native R validation adapter configuration and one generated skip-census row. The guard repair starts from R 0abc7a5d and Julia ae521414. The fitting and likelihood code remains unchanged. A subsequently discovered derived-interval guard gap is being repaired in both heritability modules; the repaired source requires new qualification.

The four preexisting settings/hook files retain their initial SHA256 values and remain unstaged. Protected drmTMB PR #1651 was verified open and unmerged at head `1bf51e2d61bd1ce0a2fb3fad914a9888544af491`. Historical cleanup and C17 receipts remain untouched. No push, merge or release has occurred in this slice.

## Earlier-candidate numerical qualification

Independent oracle self-tests, mutation controls and frozen manifest checks passed. Manifest SHA256: `c88140ec4222a3bf5a25b5132e6f05a0dd1183692db28540a76e1a93f3fa6474`. Fitted reference SHA256: `85db00122f23a2d9fc408cfc11ec85d4a1ca62d1f822dd3f544c36249603833f`. All 72 independent optimization attempts are retained.

All 36 configured fixture/route checks passed the unchanged independent oracle. Native R used the uniform policy in R-MULTISTART-POLICY.md. Native Julia and the bridge retained their original settings. The default run passed 35/36: native R ri_10 reached a genuine inferior local boundary minimum. Its failed result remains separate. No global optimization guarantee or default single-start 12/12 claim is made.

Selected raw results, the aggregate comparison and maximum errors are in final-numerical-evidence/. Each native engine has nine positive-group-SD point derivative checks and three exact-zero point value checks; fitted optima include six boundary cases. Exact-zero log-SD derivatives and arbitrary-point bridge derivatives are unavailable. Numeric indicator transport preserves the frozen matrices; the raw-factor bridge refusal remains.

## Reviews, examples and regression runs

Earlier source and boundary-minimum reviews passed their inspected paths; see final-source-review.md and ri10-math-diagnosis.md. A fresh post-fit inventory then found reachable R variance-ratio Wald intervals and Julia ratio profile intervals for active fixed priors. The original inference audit missed these accessors. The independent reviewer confirmed a blocking contract gap. See derived-ratio-guard-review.md; earlier full-source inference signoff is superseded. The revised R article rendered successfully. Both current Julia prior-guide code blocks executed successfully against the pinned source. The full Documenter site has not been rebuilt. The numerical sparse-engine baseline returned log likelihood -256.5059 and converged under its existing tolerance. No paired speed claim is made.

The original Julia harness selected 560 files. Eight disjoint partitions of 70 files cover that selection exactly. Seven shards have exit0; shard8 remains live under `/home/snakagaw/hsq_work/ri-priors-final-julia-suite-20261106`. Each shard has a 10,200-second cap. JET checks passed in completed shards; optional R-parity is off.

R installation and the first full package build passed. The first full check completed with 42,100 passing assertions and two failures, both caused by the missing generated census row for the new optional Julia test. Its source-tree lane passed 26,516 assertions with zero failures in 134 seconds; the manifest check passed. Original receipts are under `/home/snakagaw/hsq_work/ri-priors-final-r-validation-20261106`. Commit 0abc7a5d adds exactly that one census row, with no test or harness change; the generator check and five focused expectations passed. A fresh exact-source build, full check and source-tree rerun is live under `/home/snakagaw/hsq_work/ri-priors-full-r-census-final-0abc-20261106-v2`, runner PID2793824. Its preflight and census check passed. A prior setup attempt stopped before build because the generator was invoked outside the package root; its separate receipt directory is retained. The measured first check took about 60 minutes, supporting a 70–80 minute rerun estimate including build and source checks. The final pinned live bridge controls passed63 expectations in35.05 seconds; raw source/DLL receipts are in final-focused-live/.

Next: finish regression and live-control checks, adjudicate any failures, update the final reports, and prepare one prior-only PR per package. Gates G5 and G6 remain open. Superseded checkpoint text is preserved in STATE-history-before-closeout.md.

## Derived-interval guard repair

The minimum repairs add the existing fixed-prior refusal at each shared ratio-interval entry. They preserve point-only summaries, no-prior and zero-ridge behavior, and other MAP-penalty behavior. R TDD reproduced six failures; repaired focused tests passed 24 expectations and existing heritability tests passed 62. Julia TDD reproduced three profile failures; repaired focused tests passed 23 and existing affected tests passed 43. The likelihood, fixtures and frozen oracle remain unchanged. Final source-pinned numerical and full regression qualification will be repeated for the repaired candidates. Current immutable older-candidate jobs continue and their outcomes will be retained separately.
